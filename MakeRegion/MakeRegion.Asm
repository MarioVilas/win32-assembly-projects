include MakeRegion.Inc

.code
align DWORD
MsgError proc lptext:DWORD
	
	m2m mbp.lpszText,lptext
	invoke MessageBoxIndirect,offset mbp
	ret
	
MsgError endp

align DWORD
MsgWarning proc lptext:DWORD
	
	m2m mbp2.lpszText,lptext
	invoke MessageBoxIndirect,offset mbp2
	ret
	
MsgWarning endp

align DWORD
MsgWarning2 proc lptext:DWORD
	
	m2m mbp3.lpszText,lptext
	invoke MessageBoxIndirect,offset mbp3
	ret
	
MsgWarning2 endp

align DWORD
MuestraCaption proc uses ebx hwnd:DWORD
	
	invoke lstrlen,offset RegionFile
	add eax,sizeof szCapBegin + sizeof szDefCap + sizeof szCapEnd - 2
	invoke LocalAlloc,LPTR,eax
	.if eax
		xchg ebx,eax
		invoke lstrcpy,ebx,offset szCapBegin
		.if RegionFile[0] != 0
			push offset RegionFile
		.else
			push offset szDefCap
		.endif
		push ebx
		call lstrcat
		invoke lstrcat,ebx,offset szCapEnd
		invoke SetWindowText,hwnd,ebx
		invoke LocalFree,ebx
	.endif
	ret
	
MuestraCaption endp

align DWORD
SetBusy proc
	
	inc fbusy
	invoke LoadCursor,NULL,IDC_WAIT
	invoke SetCursor,eax
	ret
	
SetBusy endp

align DWORD
ResetBusy proc
	
	dec fbusy
	invoke LoadCursor,NULL,IDC_ARROW
	invoke SetCursor,eax
	ret
	
ResetBusy endp

align DWORD
BorraBitmap proc
	
	xor eax,eax
	xchg eax,hbmp
	.if eax
		invoke DeleteObject,eax
	.endif
	xor eax,eax
	xchg eax,DibSection.dshSection
	.if eax
		invoke CloseHandle,eax
	.endif
	ret
	
BorraBitmap endp

align DWORD
MakeRegion proc uses ebx esi edi
	local heap			:DWORD		; heap donde guardamos la lista de RECTs
	local mem			:DWORD		; puntero a la lista de RECTs
	local tamanio		:DWORD		; tamaño en bytes de la lista de RECTs
	local cantidad		:DWORD		; cantidad de rectángulos en la lista
	local trans			:DWORD		; color transparente (como RGBQUAD)
	local ancho			:DWORD		; ancho del mapa de bits
	local incremento	:DWORD		; +1: top-down, -1: bottom-up
;	local rojo			:DWORD		; componente rojo del píxel actual
;	local verde			:DWORD		; componente verde del píxel actual
;	local azul			:DWORD		; componente azul del píxel actual
	local t_rojo		:DWORD		; componente rojo del color transparente
	local t_verde		:DWORD		; componente verde del color transparente
	local t_azul		:DWORD		; componente azul del color transparente
	local d_rojo		:DWORD		; desviación permitida para el componente rojo
	local d_verde		:DWORD		; desviación permitida para el componente verde
	local d_azul		:DWORD		; desviación permitida para el componente azul
	local rect			:RECT		; el próximo rectángulo a agregar a la lista
	local boundbox		:RECT		; mínimo rectángulo que cubra toda la región
	
	push 100						; precalculamos las desviaciones permitidas
	push 255						; para cada componente
	fild dword ptr [esp]
	fld st(0)
	fld st(0)
	fld tolR
	fmulp st(1),st(0)
	fild dword ptr [esp + 4]
	fdivp st(1),st(0)
	fistp d_rojo
	fld tolG
	fmulp st(1),st(0)
	fild dword ptr [esp + 4]
	fdivp st(1),st(0)
	fistp d_verde
	fld tolB
	fmulp st(1),st(0)
	fild dword ptr [esp + 4]
	fdivp st(1),st(0)
	fistp d_azul
	pop eax
	pop eax
	
	mov eax,transcolor				; convertimos el COLORREF en RGBQUAD
	cmp eax,CLR_NONE
	je err
	bswap eax
	shr eax,8
	mov trans,eax
	mov ecx,eax						; extraemos los componentes por separado
	mov edx,eax
	shr eax,16
	shr ecx,8
	and edx,0FFh
	and eax,0FFh
	and ecx,0FFh
	mov t_azul,edx
	mov t_verde,ecx
	mov t_rojo,eax
	
	push DibSection.dsBm.bmHeight	; inicializamos lo que va a ser el "bounding rectangle"
	push DibSection.dsBm.bmWidth
	pop boundbox.left
	pop boundbox.top
	mov boundbox.right,0
	mov boundbox.bottom,0
	
	mov esi,DibSection.dsBm.bmBits	; ESI -> mapa de bits
	test esi,esi
	jz err
	xor ebx,ebx						; EBX == 0
	mov edi,esi						; EDI -> fin del mapa de bits
	mov edx,DibSection.dsBm.bmWidth
	mov ancho,edx
	mov eax,DibSection.dsBmih.biSizeImage
	.if eax == 0
		mov eax,DibSection.dsBm.bmHeight
		mul edx
		test edx,edx
		jz err
		add eax,eax
		jc err
		add eax,eax
		jc err
	.endif
	add edi,eax
	
	mov rect.left,0					; averiguamos si el mapa de bits es top-down o bottom-up
	mov rect.right,0				; e inicializamos "rect" e "incremento" en consecuencia
	mov eax,DibSection.dsBm.bmHeight
	xor edx,edx
	neg eax
	rcl eax,1
	sbb eax,eax
	add eax,eax
	add eax,1
	mov incremento,eax
	.if sign?
		mov edx,DibSection.dsBm.bmHeight
		sub edx,1
	.endif
	mov rect.top,edx
	add edx,1
	mov rect.bottom,edx
	
	mov cantidad,0					; preparamos la lista de RECTs
	mov tamanio,sizeof RGNDATAHEADER
	invoke HeapCreate,HEAP_NO_SERIALIZE,sizeof RGNDATAHEADER + sizeof RECT,0
	mov heap,eax
	test eax,eax
	jz err
	invoke HeapAlloc,eax,HEAP_NO_SERIALIZE or HEAP_ZERO_MEMORY,sizeof RGNDATAHEADER + sizeof RECT
	test eax,eax
	jz err
	mov mem,eax
	mov [eax].RGNDATAHEADER.dwSize,sizeof RGNDATAHEADER
	mov [eax].RGNDATAHEADER.iType,RDH_RECTANGLES
	
	invoke GdiFlush					; sincronizamos GDI (necesario para NT, 2K, y XP)
	
	; EBX == 0
	; ESI -> mapa de bits
	; EDI -> fin del mapa de bits
	
	align DWORD
ciclo:								; salimos al superar el tamaño del mapa de bits
	cmp esi,edi
	jge fin
	
	mov eax,[esi]					; evaluamos el color del píxel en la posición actual
	and eax,00FFFFFFh
	cmp eax,trans					; vemos si es idéntico al color transparente
	je transparente
	mov ecx,eax						; extraemos los componentes por separado
	mov edx,eax
	shr eax,16
	shr ecx,8
	and edx,0FFh
	and eax,0FFh
	and ecx,0FFh
;	mov azul,edx
;	mov verde,ecx
;	mov rojo,eax
	add edx,d_azul					; vemos si están dentro de los límites de tolerancia
	cmp edx,t_azul
	jl opaco
	sub edx,d_azul
	sub edx,d_azul
	cmp edx,t_azul
	jg opaco
	add eax,d_rojo
	cmp eax,t_rojo
	jl opaco
	sub eax,d_rojo
	sub eax,d_rojo
	cmp eax,t_rojo
	jg opaco
	add ecx,d_verde
	cmp ecx,t_verde
	jl opaco
	sub ecx,d_verde
	sub ecx,d_verde
	cmp ecx,t_verde
	jle transparente
	
opaco:								; el píxel actual es opaco
	test ebx,ebx
	jnz proximo_pixel
	
	mov edx,rect.right				; comenzamos un nuevo rectángulo
	or ebx,-1
	mov rect.left,edx
	
	align DWORD
proximo_pixel:						; pasamos al siguiente píxel
	mov eax,ancho
	add esi,4
	add rect.right,1
	cmp rect.right,eax				; averiguamos si ya llegamos al final de la fila
	jl ciclo
	test ebx,ebx					; llegamos al final de la fila
	jz proxima_fila
	call agregar
	
	align DWORD
proxima_fila:						; bajamos a la fila siguiente
	mov eax,incremento
	mov rect.left,0
	add rect.top,eax
	mov rect.right,0
	add rect.bottom,eax
	jmp ciclo
	
	align DWORD
transparente:						; el píxel actual es transparente
	test ebx,ebx
	jz proximo_pixel
	xor ebx,ebx
	call agregar
	jmp proximo_pixel

agregar:							; actualizamos el "bounding rectangle"
	mov eax,rect.left
	mov edx,rect.top
	cmp eax,boundbox.left
	jge @F
	mov boundbox.left,eax
@@:	cmp edx,boundbox.top
	jge @F
	mov boundbox.top,edx
@@:	mov eax,rect.right
	mov edx,rect.bottom
	cmp eax,boundbox.right
	jle @F
	mov boundbox.right,eax
@@:	cmp edx,boundbox.bottom
	jle @F
	mov boundbox.bottom,edx
@@:	add tamanio,sizeof RECT		; agregamos el rectángulo actual a la región
	add cantidad,1
	invoke HeapReAlloc,heap,HEAP_NO_SERIALIZE,mem,tamanio
	test eax,eax
	jz err2
	mov mem,eax
	add eax,tamanio
	sub eax,sizeof RECT
	push rect.left
	push rect.top
	push rect.right
	push rect.bottom
	pop [eax].RECT.bottom
	pop [eax].RECT.right
	pop [eax].RECT.top
	pop [eax].RECT.left
	retn 0
	
err2:
	pop eax	; dirección de retorno de "agregar"
err:								; salimos de la función devolviendo NULL (error)
	invoke HeapDestroy,heap
	xor eax,eax
	jmp short rt
	
fin:								; salimos del ciclo devolviendo la región calculada
	mov eax,mem
	mov edx,tamanio
	mov ecx,cantidad
	sub edx,sizeof RGNDATAHEADER
	push boundbox.left
	push boundbox.top
	push boundbox.right
	push boundbox.bottom
	mov [eax].RGNDATAHEADER.nRgnSize,edx
	mov [eax].RGNDATAHEADER.nCount,ecx
	pop [eax].RGNDATAHEADER.rcBound.bottom
	pop [eax].RGNDATAHEADER.rcBound.right
	pop [eax].RGNDATAHEADER.rcBound.top
	pop [eax].RGNDATAHEADER.rcBound.left
	invoke ExtCreateRegion,NULL,tamanio,eax
	push eax
	invoke HeapDestroy,heap
	pop eax
rt:	ret
	
MakeRegion endp

align DWORD
DlgProc proc hwnd:DWORD, umsg:DWORD, wparam:DWORD, lparam:DWORD
	local hfile		:dword
	local dwsize	:dword
	local prgn		:dword
	local lrgn		:dword
	local leidos	:dword
	local faltan	:dword
	local hdc		:dword
	local hold		:dword
	local tdc		:dword
	local told		:dword
	local tbmp		:dword
	local sbx		:dword
	local sby		:dword
	local point		:POINT
	local rect		:RECT
	local rect2		:RECT
	local ps		:PAINTSTRUCT
	local buffer[20]:byte
	
	mov eax,umsg
	.switch eax
	
	.case WM_PAINT
		invoke GetClientRect,hwnd,addr rect
		invoke BeginPaint,hwnd,addr ps
		.if hbmp
			mov hdc, $invoke(CreateCompatibleDC,eax)
			mov hold,$invoke(SelectObject,eax,hbmp)
			mov tdc, $invoke(CreateCompatibleDC,ps.hdc)
			mov tbmp,$invoke(CreateCompatibleBitmap,ps.hdc,rect.right,rect.bottom)
			mov told,$invoke(SelectObject,tdc,eax)
			mov eax,backcolor
			.if eax == CLR_NONE
				invoke GetSysColor,COLOR_BTNFACE
			.endif
			invoke CreateSolidBrush,eax
			push eax
			invoke FillRect,tdc,addr rect,eax
			call DeleteObject
			mov sbx,$invoke(GetScrollPos,hwnd,SB_HORZ)
			mov sby,$invoke(GetScrollPos,hwnd,SB_VERT)
			invoke BitBlt,tdc,0,0,DibSection.dsBm.bmWidth,DibSection.dsBm.bmHeight,hdc,sbx,sby,SRCCOPY
			neg sbx
			neg sby
			mov lrgn,$invoke(CreateRectRgn,0,0,0,0)
			invoke GetCapture
			cmp eax,hwnd
			je norgn
			mov eax,selrgn
			test eax,eax
			jnz shrgn
			mov eax,tmprgn
			test eax,eax
			jnz shrgn
			mov eax,hrgn
			test eax,eax
			jz norgn
	shrgn:	invoke CombineRgn,lrgn,eax,eax,RGN_COPY
			invoke OffsetRgn,lrgn,sbx,sby
			invoke GetMenu,hwnd
			push eax
			invoke GetMenuState,eax,ID_REGION_SHOWTRANS,MF_BYCOMMAND
			pop edx
			test eax,MF_CHECKED
			jnz trans
			invoke GetMenuState,edx,ID_REGION_SHOWMASK,MF_BYCOMMAND
			test eax,MF_CHECKED
			jz norgn
			invoke GetSysColor,COLOR_BTNFACE
			invoke SetBkColor,tdc,eax
			invoke GetSysColor,COLOR_BTNTEXT
			invoke CreateHatchBrush,HS_DIAGCROSS,eax
			push eax
			invoke FillRgn,tdc,lrgn,eax
			call DeleteObject
			jmp norgn
	trans:	invoke CreateRectRgn,0,0,DibSection.dsBm.bmWidth,DibSection.dsBm.bmHeight
			mov prgn,eax
			push eax
			invoke OffsetRgn,eax,sbx,sby
			lea edx,rect2
			invoke GetRgnBox,lrgn,edx
			invoke CreateRectRgn,rect2.left,rect2.top,rect2.right,rect2.bottom
			push eax
			mov edx,prgn
			invoke CombineRgn,edx,edx,eax,RGN_OR
			call DeleteObject
			mov edx,prgn
			invoke CombineRgn,edx,lrgn,edx,RGN_XOR
			mov eax,backcolor
			.if eax == CLR_NONE
				invoke GetSysColor,COLOR_BTNFACE
			.endif
			invoke CreateSolidBrush,eax
			push eax
			invoke FillRgn,tdc,prgn,eax
			call DeleteObject
			call DeleteObject
	norgn:	invoke BitBlt,ps.hdc,0,0,rect.right,rect.bottom,tdc,0,0,SRCCOPY
			invoke SelectObject,tdc,told
			invoke DeleteObject,tbmp
			invoke DeleteDC,tdc
			invoke SelectObject,hdc,hold
			invoke DeleteDC,hdc
			invoke DeleteObject,lrgn
		.else
			invoke GetStockObject,DEFAULT_GUI_FONT
			.if !eax
				invoke GetStockObject,DEVICE_DEFAULT_FONT
			.endif
			invoke SelectObject,ps.hdc,eax
			mov hold,eax
			invoke DrawText,ps.hdc,offset szNoPic,-1,addr rect2,DT_CALCRECT or DT_EXTERNALLEADING or DT_NOPREFIX or DT_SINGLELINE
			.if eax
				mov eax,rect.right
				mov edx,rect.bottom
				sub eax,rect2.right
				sub edx,rect2.bottom
				add eax,rect2.left
				add edx,rect2.top
				sar eax,1
				sar edx,1
				mov rect.left,eax
				mov rect.top,edx
				invoke OffsetRect,addr rect2,eax,edx
				invoke SetTextAlign,ps.hdc,TA_LEFT or TA_TOP or TA_NOUPDATECP
				invoke SetBkMode,ps.hdc,TRANSPARENT
				invoke GetSysColor,COLOR_3DLIGHT
				invoke SetTextColor,ps.hdc,eax
				invoke lstrlen,offset szNoPic
				invoke TextOut,ps.hdc,rect.left,rect.top,offset szNoPic,eax
				invoke GetSysColor,COLOR_3DSHADOW
				invoke SetTextColor,ps.hdc,eax
				invoke lstrlen,offset szNoPic
				mov ecx,rect.left
				mov edx,rect.top
				sub ecx,1
				sub edx,1
				invoke TextOut,ps.hdc,ecx,edx,offset szNoPic,eax
			.endif
			invoke SelectObject,ps.hdc,hold
		.endif
		invoke EndPaint,hwnd,addr ps
		reti TRUE
	
	.case WM_ERASEBKGND
		.break .if !hbmp
		invoke SetWindowLong,hwnd,DWL_MSGRESULT,TRUE
		reti TRUE
	
	.case WM_MOUSEMOVE
		invoke GetCapture
		mov edx,IDC_CROSS
		.if eax != hwnd
			mov edx,IDC_ARROW
			.if fbusy
				mov edx,IDC_WAIT
			.endif
		.endif
		invoke LoadCursor,NULL,edx
		invoke SetCursor,eax
		.break
	
	.case WM_HSCROLL
		.break .if !hbmp || fresize
		invoke GetScrollRange,hwnd,SB_HORZ,addr sbx,addr sby
		.break .if !eax
		mov eax,sby
		sub eax,sbx
		.break .if zero?
		inc fresize
		invoke GetClientRect,hwnd,addr rect
		mov eax,wparam
		and eax,0FFFFh
		.switch eax
		.case SB_TOP
			;xor eax,eax
			mov eax,sbx
			jmp hscroll
		.case SB_BOTTOM
			;mov eax,DibSection.dsBm.bmHeight
			;sub eax,rect.right
			mov eax,sby
			jmp hscroll
		.case SB_LINEDOWN
			mov eax,10
			jmp hpage
		.case SB_LINEUP
			mov eax,-10
			jmp hpage
		.case SB_PAGEDOWN
			mov eax,rect.bottom
			jmp hpage
		.case SB_PAGEUP
			mov eax,rect.bottom
			neg eax
hpage:		push eax
			invoke GetScrollPos,hwnd,SB_HORZ
			pop edx
			add eax,edx
			jmp hbounds
	    .case SB_THUMBPOSITION, SB_THUMBTRACK
			mov eax,wparam
			shr eax,16
hbounds:	cmp eax,sbx
			jge @F
			mov eax,sbx
			jmp hscroll
@@:			cmp eax,sby
			jle hscroll
			mov eax,sby
hscroll:	invoke SetScrollPos,hwnd,SB_HORZ,eax,TRUE
			invoke InvalidateRect,hwnd,addr rect,TRUE
		.endswitch
		dec fresize
		.break
	
	.case WM_VSCROLL
		.break .if !hbmp || fresize
		invoke GetScrollRange,hwnd,SB_VERT,addr sbx,addr sby
		.break .if !eax
		mov eax,sby
		sub eax,sbx
		.break .if zero?
		inc fresize
		invoke GetClientRect,hwnd,addr rect
		mov eax,wparam
		and eax,0FFFFh
		.switch eax
		.case SB_TOP
			;xor eax,eax
			mov eax,sbx
			jmp vscroll
		.case SB_BOTTOM
			;mov eax,DibSection.dsBm.bmHeight
			;sub eax,rect.bottom
			mov eax,sby
			jmp vscroll
		.case SB_LINEDOWN
			mov eax,10
			jmp vpage
		.case SB_LINEUP
			mov eax,-10
			jmp vpage
		.case SB_PAGEDOWN
			mov eax,rect.bottom
			jmp vpage
		.case SB_PAGEUP
			mov eax,rect.bottom
			neg eax
vpage:		push eax
			invoke GetScrollPos,hwnd,SB_VERT
			pop edx
			add eax,edx
			jmp vbounds
		.case SB_THUMBPOSITION, SB_THUMBTRACK
			mov eax,wparam
			shr eax,16
vbounds:	cmp eax,sbx
			jge @F
			mov eax,sbx
			jmp vscroll
@@:			cmp eax,sby
			jle vscroll
			mov eax,sby
vscroll:	invoke SetScrollPos,hwnd,SB_VERT,eax,TRUE
			invoke InvalidateRect,hwnd,addr rect,TRUE
		.endswitch
		dec fresize
		.break
	
	.case WM_SIZE
		.break .if fresize || (wparam == SIZE_MINIMIZED)
		.if !hbmp
			invoke InvalidateRect,hwnd,NULL,TRUE
			.break
		.endif
		inc fresize
		invoke GetClientRect,hwnd,addr rect
		mov eax,DibSection.dsBm.bmWidth
		sub eax,rect.right
		.if sign?
			xor eax,eax
		.endif
		invoke SetScrollRange,hwnd,SB_HORZ,0,eax,TRUE
		mov eax,DibSection.dsBm.bmHeight
		sub eax,rect.bottom
		.if sign?
			xor eax,eax
		.endif
		invoke SetScrollRange,hwnd,SB_VERT,0,eax,TRUE
		;invoke CalculaZoom
		dec fresize
		.break
	
	.case WM_GETMINMAXINFO
		.break .if !hbmp
		mov eax,lparam
		mov [eax].MINMAXINFO.ptMinTrackSize.x,MY_WIDTH_MAX
		invoke GetSystemMetrics,SM_CYMENU
		push eax
		invoke GetSystemMetrics,SM_CYCAPTION
		pop edx
		add eax,edx
		add eax,eax
		mov edx,lparam
		mov [edx].MINMAXINFO.ptMinTrackSize.y,eax
		reti TRUE
	
	.case WM_LBUTTONDOWN
		invoke GetCapture
		.break .if eax != hwnd
		invoke ReleaseCapture
		invoke GetCursorPos,addr point
		.break .if !eax
		invoke ScreenToClient,hwnd,addr point
		.break .if !eax
		mov rect.left,0
		mov rect.top,0
		m2m rect.right,DibSection.dsBm.bmWidth
		m2m rect.bottom,DibSection.dsBm.bmHeight
		invoke PtInRect,addr rect,point.x,point.y
		.break .if !eax
		mov eax,point.x
		imul point.y
		sal eax,2
		.break .if carry?
		mov ecx,eax
		mov eax,DibSection.dsBmih.biWidth
		imul DibSection.dsBmih.biHeight
		mov edx,DibSection.dsBm.bmBits
		.break .if !edx
		sal eax,2
		.if !sign?
			neg ecx
			add ecx,eax
		.endif
		mov eax,[edx + ecx]
		bswap eax
		shr eax,8
		mov transcolor,eax
		jmp mkrgn
	
	.case WM_RBUTTONDOWN
		invoke GetCapture
		.break .if eax != hwnd
		invoke ReleaseCapture
		.break
	
	.case WM_COMMAND
		mov eax,wparam
		.switch eax
		.case IDCANCEL
			.if hrgn && fmodified
				invoke MsgWarning2,offset szWarnUnsaved
				.break .if eax == IDCANCEL
				.if eax != IDNO
					invoke SendMessage,hwnd,WM_COMMAND,ID_FILE_SAVE,0
				.endif
			.endif
			invoke EndDialog,hwnd,wparam
			.break
		.case ID_FILE_NEW
			.if hrgn
				.if fmodified
					invoke MsgWarning2,offset szWarnUnsaved
					.break .if eax == IDCANCEL
					.if eax != IDNO
						invoke SendMessage,hwnd,WM_COMMAND,ID_FILE_SAVE,0
					.endif
				.endif
				xor eax,eax
				xchg eax,hrgn
				invoke DeleteObject,eax
			.endif
			mov fmodified,FALSE
			xor eax,eax
			xchg eax,selrgn
			.if eax
				invoke DeleteObject,eax
			.endif
			xor eax,eax
			xchg eax,tmprgn
			.if eax
				invoke DeleteObject,eax
			.endif
			invoke BorraBitmap
			mov RegionFile[0],0
			mov ImageFile[0],0
			mov transcolor,CLR_NONE
			mov backcolor,CLR_NONE
			invoke MuestraCaption,hwnd
			invoke GetMenu,hwnd
			mov prgn,eax
			invoke EnableMenuItem,eax,ID_FILE_SAVE,MF_BYCOMMAND or MF_GRAYED
			invoke EnableMenuItem,prgn,ID_FILE_SAVEAS,MF_BYCOMMAND or MF_GRAYED
			invoke EnableMenuItem,prgn,ID_IMAGE_INFO,MF_BYCOMMAND or MF_GRAYED
			invoke EnableMenuItem,prgn,ID_IMAGE_SELECTCOLOR,MF_BYCOMMAND or MF_GRAYED
			invoke EnableMenuItem,prgn,ID_IMAGE_ENTERRGB,MF_BYCOMMAND or MF_GRAYED
			invoke EnableMenuItem,prgn,ID_REGION_VIEWRAWDATA,MF_BYCOMMAND or MF_GRAYED
			invoke EnableMenuItem,prgn,ID_IMAGE_INFO,MF_BYCOMMAND or MF_GRAYED
			invoke EnableMenuItem,prgn,ID_IMAGE_INFO,MF_BYCOMMAND or MF_GRAYED
			invoke ShowWindow,$invoke(GetDlgItem,hwnd,IDC_STATIC1),SW_SHOW
			invoke SetScrollPos,hwnd,SB_HORZ,0,TRUE
			invoke SetScrollPos,hwnd,SB_VERT,0,TRUE
			invoke ShowScrollBar,hwnd,SB_BOTH,FALSE
			invoke InvalidateRect,hwnd,NULL,TRUE
			.break
		.case ID_FILE_OPEN
			.if hrgn && fmodified
				invoke MsgWarning2,offset szWarnUnsaved
				.break .if eax == IDCANCEL
				.if eax != IDNO
					invoke SendMessage,hwnd,WM_COMMAND,ID_FILE_SAVE,0
				.endif
			.endif
			invoke GetOpenFileName,offset ofn1
			.break .if !eax
			invoke CreateFile,offset RegionFile,GENERIC_READ,FILE_SHARE_READ,0,OPEN_EXISTING,FILE_FLAG_SEQUENTIAL_SCAN,0
			.if eax != INVALID_HANDLE_VALUE
				mov hfile,eax
				invoke GetFileSize,eax,NULL
				.if eax != -1
					mov dwsize,eax
					invoke VirtualAlloc,NULL,eax,MEM_COMMIT,PAGE_READWRITE
					.if eax
						mov prgn,eax
						m2m faltan,dwsize
						mov leidos,0
						push ebx
						mov ebx,eax
						.repeat
							invoke ReadFile,hfile,ebx,faltan,addr leidos,NULL
							.break .if eax == 0
							mov eax,leidos
							add ebx,eax
							sub faltan,eax
						.until zero?
						pop ebx
						.if faltan == 0
							invoke ExtCreateRegion,NULL,dwsize,prgn
							.if eax
								mov fmodified,FALSE
								xchg eax,hrgn
								.if eax
									invoke DeleteObject,eax
								.endif
								.if hbmp
									invoke ShowWindow,$invoke(GetDlgItem,hwnd,IDC_STATIC1),SW_HIDE
								.endif
							.endif
						.endif
						invoke VirtualFree,prgn,dwsize,MEM_DECOMMIT
					.endif
				.endif
				invoke CloseHandle,hfile
			.endif
			invoke InvalidateRect,hwnd,NULL,TRUE
			.if hrgn
				invoke MuestraCaption,hwnd
				invoke GetMenu,hwnd
				mov prgn,eax
				invoke EnableMenuItem,eax,ID_FILE_SAVE,MF_BYCOMMAND or MF_ENABLED
				invoke EnableMenuItem,prgn,ID_FILE_SAVEAS,MF_BYCOMMAND or MF_ENABLED
				invoke EnableMenuItem,prgn,ID_REGION_VIEWRAWDATA,MF_BYCOMMAND or MF_ENABLED
				.break
			.endif
			mov RegionFile[0],0
			invoke MuestraCaption,hwnd
			invoke GetMenu,hwnd
			mov prgn,eax
			invoke EnableMenuItem,eax,ID_FILE_SAVE,MF_BYCOMMAND or MF_GRAYED
			invoke EnableMenuItem,prgn,ID_FILE_SAVEAS,MF_BYCOMMAND or MF_GRAYED
			invoke EnableMenuItem,prgn,ID_REGION_VIEWRAWDATA,MF_BYCOMMAND or MF_GRAYED
			invoke MsgError,offset szErrLoading
			.break
		.case ID_FILE_SAVEAS
			.break .if hrgn == 0
@@:			invoke GetSaveFileName,offset ofn2
			test eax,eax
			jnz @F
			.break
		.case ID_FILE_SAVE
			.break .if hrgn == 0
			cmp RegionFile[0],0
			je @B
@@:			invoke MuestraCaption,hwnd
			invoke GetMenu,hwnd
			invoke EnableMenuItem,eax,ID_FILE_SAVE,MF_BYCOMMAND or MF_ENABLED
			invoke GetTempPath,sizeof TempFile - 12,offset TempFile
			invoke GetTempFileName,offset TempFile,offset szPrefix,0,offset TempFile
			invoke CreateFile,offset TempFile,GENERIC_WRITE,0,0,CREATE_ALWAYS,FILE_FLAG_WRITE_THROUGH,0
			.break .if eax == 0
			mov hfile,eax
			or faltan,-1
			invoke GetRegionData,hrgn,0,NULL
			.if eax
				mov dwsize,eax
				invoke VirtualAlloc,NULL,dwsize,MEM_COMMIT,PAGE_EXECUTE_READWRITE
				.if eax != 0
					mov prgn,eax
					mov [eax].RGNDATA.rdh.dwSize,sizeof RGNDATAHEADER
					invoke GetRegionData,hrgn,dwsize,eax
					.if eax
						mov eax,dwsize
						mov leidos,0
						mov faltan,eax
						push ebx
						mov ebx,prgn
						sub eax,sizeof RGNDATAHEADER
						mov [ebx].RGNDATA.rdh.nRgnSize,eax
						.repeat
							invoke WriteFile,hfile,ebx,faltan,addr leidos,NULL
							.break .if eax == 0
							mov eax,leidos
							add ebx,eax
							sub faltan,eax
						.until zero?
						pop ebx
					.endif
					invoke VirtualFree,prgn,dwsize,MEM_DECOMMIT
				.endif
			.endif
			invoke CloseHandle,hfile
			.if faltan == 0
				invoke DeleteFile,offset RegionFile
				invoke MoveFile,offset TempFile,offset RegionFile
				invoke DeleteFile,offset TempFile
				mov fmodified,FALSE
			.else
				invoke DeleteFile,TempFile
				invoke MsgError,offset szErrSaving
				mov fmodified,TRUE
			.endif
			.break
		.case ID_IMAGE_LOAD
			invoke GetOpenFileName,offset ofn3
			.break .if !eax
imgload:	invoke SetBusy
			mov eax,backcolor
			.if eax == CLR_NONE
			    invoke GetSysColor,COLOR_BTNFACE
			.endif
			invoke BorraBitmap
			invoke LoadPictureH,offset ImageFile,eax,offset DibSection
			mov hbmp,eax
			invoke ResetBusy
			.if !hbmp
				mov ImageFile[0],al
				invoke MsgError,offset szErrImage
			.else
				mov eax,hrgn
				.if eax
					lea edx,rect
					invoke GetRgnBox,eax,edx
					mov eax,rect.right
					mov edx,rect.bottom
					dec eax
					dec edx
					.if (eax > DibSection.dsBm.bmWidth) || (edx > DibSection.dsBm.bmHeight)
						mov eax,offset szWarnClip
						.if !hbmp
							mov eax,offset szWarnClip2
						.endif
						invoke MsgWarning,eax
						.if eax == IDYES
							invoke CreateRectRgn,0,0,DibSection.dsBm.bmWidth,DibSection.dsBm.bmHeight
							push eax
							invoke CombineRgn,hrgn,hrgn,eax,RGN_AND
							call DeleteObject
							mov fmodified,TRUE
						.endif
					.endif
				.endif
				invoke SetScrollPos,hwnd,SB_HORZ,0,TRUE
				invoke SetScrollPos,hwnd,SB_VERT,0,TRUE
				invoke ShowScrollBar,hwnd,SB_BOTH,FALSE
				invoke ShowWindow,$invoke(GetDlgItem,hwnd,IDC_STATIC1),SW_HIDE
				invoke GetMenu,hwnd
				mov prgn,eax
				invoke EnableMenuItem,eax,ID_IMAGE_INFO,MF_BYCOMMAND or MF_ENABLED
				invoke EnableMenuItem,prgn,ID_IMAGE_SELECTCOLOR,MF_BYCOMMAND or MF_ENABLED
				invoke EnableMenuItem,prgn,ID_IMAGE_ENTERRGB,MF_BYCOMMAND or MF_ENABLED
				mov wp.iLength,sizeof WINDOWPLACEMENT
				invoke GetWindowPlacement,hwnd,addr wp
				.if eax
					invoke GetClientRect,hwnd,addr rect
					m2m rect.right,DibSection.dsBm.bmWidth
					m2m rect.bottom,DibSection.dsBm.bmHeight
					invoke GetWindowLong,hwnd,GWL_EXSTYLE
					push eax
					push TRUE
					invoke GetWindowLong,hwnd,GWL_STYLE
					push eax
					lea eax,rect
					push eax
					call AdjustWindowRectEx
					invoke GetSystemMetrics,SM_CYMENU
					push eax
					invoke GetSystemMetrics,SM_CYCAPTION
					pop ecx
					add ecx,eax
					add ecx,ecx
					mov eax,rect.right
					mov edx,rect.bottom
					sub eax,rect.left
					sub edx,rect.top
					sub eax,MY_WIDTH_MAX
					.if sign?
					    add rect.right,eax
					.endif
					sub edx,ecx
					.if sign?
					    add rect.bottom,edx
					.endif
					mov ecx,wp.rcNormalPosition.left
					mov edx,wp.rcNormalPosition.top
					sub ecx,rect.left
					sub edx,rect.top
					invoke OffsetRect,addr rect,ecx,edx
					invoke SystemParametersInfo,SPI_GETWORKAREA,0,addr rect2,0
					mov eax,rect.left
					mov edx,rect2.left
					sub edx,eax
					jle @F
					add rect.left,edx
					add rect.right,edx
				@@:	mov eax,rect.top
					mov edx,rect2.top
					sub edx,eax
					jle @F
					add rect.top,edx
					add rect.bottom,edx
				@@:	mov eax,rect.right
					mov edx,rect2.right
					sub edx,eax
					jge @F
					add rect.left,edx
					add rect.right,edx
				@@:	mov eax,rect.bottom
					mov edx,rect2.bottom
					sub edx,eax
					jge @F
					add rect.top,edx
					add rect.bottom,edx
				@@:	mov eax,rect2.left
					cmp rect.left,eax
					jge @F
					mov rect.left,eax
				@@:	mov eax,rect2.top
					cmp rect.top,eax
					jge @F
					mov rect.top,eax
				@@:	invoke CopyRect,addr wp.rcNormalPosition,addr rect
					invoke SetWindowPlacement,hwnd,addr wp
				.endif
				;invoke ShowScrollBar,hwnd,SB_BOTH,FALSE
				invoke GetClientRect,hwnd,addr rect
				mov eax,rect.right
				neg eax
				add eax,DibSection.dsBm.bmWidth
				.if sign?
					xor eax,eax
				.endif
				invoke SetScrollRange,hwnd,SB_HORZ,0,eax,TRUE
				mov eax,rect.bottom
				neg eax
				add eax,DibSection.dsBm.bmHeight
				.if sign?
					xor eax,eax
				.endif
				invoke SetScrollRange,hwnd,SB_VERT,0,eax,TRUE
			.endif
			invoke InvalidateRect,hwnd,NULL,TRUE
			.break
		.case ID_IMAGE_INFO
			.break .if !hbmp
			invoke DialogBoxParam,hinst,IDD_DIALOG4,hwnd,offset DlgProc4,eax
			.break
		.case ID_IMAGE_SELECTCOLOR
			.break .if !hbmp
			invoke SetCapture,hwnd
			invoke InvalidateRect,hwnd,NULL,TRUE
			.break
		.case ID_IMAGE_ENTERRGB
			lea eax,hfile
			mov dword ptr [eax],0
			invoke RegCreateKey,HKEY_CURRENT_USER,offset szCustomColorsKey,eax
			.if eax == 0
				lea eax,faltan
				mov dword ptr [eax],sizeof COLORREF * 16
				invoke RegQueryValueEx,hfile,offset szCustomColors,0,0,offset CustomColor,eax
			.endif
			invoke ChooseColor,offset cc
			push eax
			.if eax
				mov edx,hfile
				.if edx
					invoke RegSetValueEx,edx,offset szCustomColors,0,REG_BINARY,offset CustomColor,sizeof COLORREF * 16
				.endif
			.endif
			invoke RegCloseKey,hfile
			pop eax
			.break .if !eax
mkrgn:		invoke SetBusy
			invoke MakeRegion
			push eax
			invoke ResetBusy
			pop eax
			.if eax
				xchg eax,hrgn
				.if eax
					invoke DeleteObject,eax
				.endif
				invoke GetMenu,hwnd
				mov prgn,eax
				.if RegionFile[0] != 0
					invoke EnableMenuItem,eax,ID_FILE_SAVE,MF_BYCOMMAND or MF_ENABLED
				.endif
				invoke EnableMenuItem,prgn,ID_FILE_SAVEAS,MF_BYCOMMAND or MF_ENABLED
				invoke EnableMenuItem,prgn,ID_REGION_VIEWRAWDATA,MF_BYCOMMAND or MF_ENABLED
				mov fmodified,TRUE
			.else
				invoke MsgError,offset szErrInt
			.endif
			invoke InvalidateRect,hwnd,NULL,TRUE
			.break
		.case ID_IMAGE_TOLERANCE
			invoke DialogBoxParam,hinst,IDD_DIALOG2,hwnd,offset DlgProc2,0
			.break .if eax != IDOK
			.break .if !hbmp || !hrgn
			invoke MsgWarning,offset szWarnRebuild
			.break .if eax != IDYES
			jmp mkrgn
		.case ID_IMAGE_BACKCOLOR
			lea eax,hfile
			mov dword ptr [eax],0
			invoke RegCreateKey,HKEY_CURRENT_USER,offset szCustomColorsKey,eax
			.if eax == 0
				lea eax,faltan
				mov dword ptr [eax],sizeof COLORREF * 16
				invoke RegQueryValueEx,hfile,offset szCustomColors,0,0,offset CustomColor,eax
			.endif
			invoke ChooseColor,offset cc2
			.if eax
				mov edx,hfile
				.if edx
					invoke RegSetValueEx,edx,offset szCustomColors,0,REG_BINARY,offset CustomColor,sizeof COLORREF * 16
				.endif
			.endif
			invoke RegCloseKey,hfile
			invoke RedrawWindow,hwnd,NULL,NULL,RDW_ERASE or RDW_INVALIDATE or RDW_ERASENOW or RDW_NOCHILDREN
			.break .if ImageFile[0] == 0
			invoke MsgWarning,offset szWarnBack
			.break .if eax == IDNO
			jmp imgload
		.between ID_REGION_HIDE, ID_REGION_SHOWTRANS
			push MF_BYCOMMAND
			push eax
			invoke GetMenu,hwnd
			mov prgn,eax
			push eax
			call GetMenuState
			test eax,MF_CHECKED
			.break .if ! zero?
			invoke CheckMenuRadioItem,prgn,ID_REGION_HIDE,ID_REGION_SHOWTRANS,wparam,MF_BYCOMMAND
			invoke InvalidateRect,hwnd,NULL,TRUE
			.break
		.case ID_REGION_VIEWRAWDATA
			.break .if !hrgn
			invoke DialogBoxParam,hinst,IDD_DIALOG3,hwnd,offset DlgProc3,eax
			.break
		.case ID_HELP_README
			invoke DialogBoxParam,hinst,IDD_DIALOG8,hwnd,offset DlgProc8,eax
			.break
		.case ID_HELP_ABOUT
			;invoke DialogBoxParam,hinst,IDD_DIALOG7,hwnd,offset DlgProc7,INFINITE
			invoke CreateDialogParam,hinst,IDD_DIALOG7,hwnd,offset DlgProc7,INFINITE
		.endswitch
		.break
	
	.case WM_ACTIVATE
		mov eax,wparam
		and eax,0FFFFh
		.if eax == WA_INACTIVE
	@@:		push hIconOff
		.else
			invoke IsIconic,hwnd
			test eax,eax
			jnz @B
			push hIconOn
		.endif
		push ICON_SMALL
		push WM_SETICON
		push hwnd
		call SendMessage
		xor eax,eax
		mov rect.left,eax
		mov rect.top,eax
		mov rect.right,eax
		mov rect.bottom,eax
		invoke RedrawWindow,hwnd,eax,eax,RDW_FRAME or RDW_INVALIDATE
		.break
	
	.case WM_SYSCOLORCHANGE, WM_DISPLAYCHANGE, WM_SETTINGCHANGE
		invoke SendMessage,hwnd,WM_SETICON,ICON_SMALL,0
		push eax
		invoke DeleteObject,hIconOn
		invoke DeleteObject,hIconOff
		invoke GetSysColor,COLOR_ACTIVECAPTION
		mov hIconOn,$invoke (LoadFilteredIcon,hinst,IDI_ICON1,eax)
		invoke GetSysColor,COLOR_INACTIVECAPTION
		mov hIconOff,$invoke (LoadFilteredIcon,hinst,IDI_ICON1,eax)
		pop edx
		mov eax,hIconOn
		.if eax == edx
			mov edx,hIconOff
		.endif
		invoke SendMessage,hwnd,WM_SETICON,ICON_SMALL,edx
		invoke InvalidateRect,hwnd,NULL,TRUE
		.break
	
	.case WM_INITDIALOG
		mov eax,hwnd
		mov mbp.hwndOwner,eax
		mov mbp2.hwndOwner,eax
		mov mbp3.hwndOwner,eax
		mov mbp4.hwndOwner,eax
		mov ofn1.hwndOwner,eax
		mov ofn2.hwndOwner,eax
		mov ofn3.hwndOwner,eax
		mov cc.hwndOwner,eax
		mov cc2.hwndOwner,eax
		invoke LoadMenu,hinst,IDR_MENU1
		invoke SetMenu,hwnd,eax
		invoke GetSysColor,COLOR_ACTIVECAPTION
		invoke LoadFilteredIcon,hinst,IDI_ICON1,eax
		mov hIconOn,eax
		invoke GetSysColor,COLOR_INACTIVECAPTION
		invoke LoadFilteredIcon,hinst,IDI_ICON1,eax
		mov hIconOff,eax
		invoke ShowScrollBar,hwnd,SB_BOTH,FALSE
		;invoke DialogBoxParam,hinst,IDD_DIALOG7,hwnd,offset DlgProc7,1000		;1 segundo
		invoke CreateDialogParam,hinst,IDD_DIALOG7,hwnd,offset DlgProc7,1000    ;1 segundo
		reti TRUE
	
	.case WM_DESTROY
		xor eax,eax
		xchg eax,hrgn
		.if eax
			invoke DeleteObject,eax
		.endif
		xor eax,eax
		xchg eax,selrgn
		.if eax
			invoke DeleteObject,eax
		.endif
		xor eax,eax
		xchg eax,tmprgn
		.if eax
			invoke DeleteObject,eax
		.endif
		invoke BorraBitmap
		invoke SendMessage,hwnd,WM_SETICON,ICON_SMALL,NULL
		invoke DestroyIcon,hIconOn
		invoke DestroyIcon,hIconOff
		invoke GetMenu,hwnd
		push eax
		invoke SetMenu,hwnd,NULL
		call DestroyMenu
		xor eax,eax
		xchg eax,hrgn
		.if eax
			invoke DeleteObject,eax
		.endif
		invoke BorraBitmap
	
	.endswitch
	reti FALSE
	
DlgProc endp

align DWORD
DlgProc2 proc hwnd:DWORD, umsg:DWORD, wparam:DWORD, lparam:DWORD
	local bTrans:dword
	
	mov eax,umsg
	.switch eax
	
	.case WM_COMMAND
		mov eax,wparam
		.if eax != IDCANCEL
			.break .if eax != IDOK
			invoke GetDlgItemInt,hwnd,IDC_EDIT1,addr bTrans,FALSE
			.if bTrans != 0
				.if (SDWORD ptr eax) < 0
					xor eax,eax
				.elseif (SDWORD ptr eax) > 100
					mov eax,100
				.endif
				mov bTrans,eax
				fild bTrans
				fstp tolR
			.endif
			invoke GetDlgItemInt,hwnd,IDC_EDIT2,addr bTrans,FALSE
			.if bTrans != 0
				.if (SDWORD ptr eax) < 0
					xor eax,eax
				.elseif (SDWORD ptr eax) > 100
					mov eax,100
				.endif
				mov bTrans,eax
				fild bTrans
				fstp tolG
			.endif
			invoke GetDlgItemInt,hwnd,IDC_EDIT3,addr bTrans,FALSE
			.if bTrans != 0
				.if (SDWORD ptr eax) < 0
					xor eax,eax
				.elseif (SDWORD ptr eax) > 100
					mov eax,100
				.endif
				mov bTrans,eax
				fild bTrans
				fstp tolB
			.endif
		.endif
		invoke EndDialog,hwnd,wparam
		.break
	
	.case WM_INITDIALOG
	invoke SendDlgItemMessage,hwnd,IDC_SPIN1,UDM_SETRANGE,0,100
	invoke SendDlgItemMessage,hwnd,IDC_SPIN2,UDM_SETRANGE,0,100
	invoke SendDlgItemMessage,hwnd,IDC_SPIN3,UDM_SETRANGE,0,100
	invoke SendDlgItemMessage,hwnd,IDC_EDIT1,EM_SETLIMITTEXT,3,0
	invoke SendDlgItemMessage,hwnd,IDC_EDIT2,EM_SETLIMITTEXT,3,0
	invoke SendDlgItemMessage,hwnd,IDC_EDIT3,EM_SETLIMITTEXT,3,0
	fld tolR
	fistp bTrans
	invoke SetDlgItemInt,hwnd,IDC_EDIT1,bTrans,FALSE
	fld tolG
	fistp bTrans
	invoke SetDlgItemInt,hwnd,IDC_EDIT2,bTrans,FALSE
	fld tolB
	fistp bTrans
	invoke SetDlgItemInt,hwnd,IDC_EDIT3,bTrans,FALSE
	invoke CenterDialog,hwnd
	reti TRUE
	
	.endswitch
	reti FALSE
	
DlgProc2 endp

align DWORD
DlgProc3 proc hwnd:DWORD, umsg:DWORD, wparam:DWORD, lparam:DWORD
	local prgn		:dword
	local lrgn		:dword
	local fcmd		:dword
	local rect		:RECT
	local lvi		:LV_ITEM
	local buffer[20]:byte
	
	mov eax,umsg
	.switch eax
	
	.case WM_MOUSEMOVE
		invoke GetCapture
		mov edx,IDC_CROSS
		.if eax != hwnd
			mov edx,IDC_ARROW
			.if fbusy
				mov edx,IDC_WAIT
			.endif
		.endif
		invoke LoadCursor,NULL,edx
		invoke SetCursor,eax
		.break
	
	.case WM_NOTIFY
		.break .if wparam != IDC_LIST1
		mov edx,lparam
		mov eax,[edx].NMHDR.code
		.if eax == LVN_ITEMCHANGED
			mov eax,[edx].NM_LISTVIEW.uChanged
			test eax,LVIF_STATE
			.break .if zero?
			mov eax,[edx].NM_LISTVIEW.uNewState
			mov edx,[edx].NM_LISTVIEW.uOldState
			and eax,LVIS_SELECTED
			and edx,LVIS_SELECTED
			xor edx,eax
			.break .if zero?
			.if !eax
			    movi eax,RGN_DIFF
			;.else
			;	movi eax,RGN_OR
			.endif
			mov fcmd,eax
			mov lrgn,0
			mov prgn,0
			invoke SetBusy
			mov lvi.imask,LVIF_TEXT
			mov eax,lparam
			m2m lvi.iItem,[eax].NM_LISTVIEW.iItem
			mov lvi.iSubItem,0
			lea eax,buffer
			mov lvi.pszText,eax
			mov lvi.cchTextMax,sizeof buffer
			invoke SendDlgItemMessage,hwnd,IDC_LIST1,LVM_GETITEM,0,addr lvi
			mov rect.left,$invoke(atodw,addr buffer)
			inc lvi.iSubItem
			invoke SendDlgItemMessage,hwnd,IDC_LIST1,LVM_GETITEM,0,addr lvi
			mov rect.top,$invoke(atodw,addr buffer)
			inc lvi.iSubItem
			invoke SendDlgItemMessage,hwnd,IDC_LIST1,LVM_GETITEM,0,addr lvi
			mov rect.right,$invoke(atodw,addr buffer)
			inc lvi.iSubItem
			invoke SendDlgItemMessage,hwnd,IDC_LIST1,LVM_GETITEM,0,addr lvi
			mov rect.bottom,$invoke(atodw,addr buffer)
			.if !selrgn
			    mov selrgn,$invoke(CreateRectRgn,0,0,0,0)
			    mov prgn,eax
			.endif
			invoke CreateRectRgnIndirect,addr rect
			mov lrgn,eax
			push eax
			mov edx,selrgn
			invoke CombineRgn,edx,edx,eax,fcmd
			invoke GetWindow,hwnd,GW_OWNER
			invoke InvalidateRgn,eax,lrgn,TRUE
			call DeleteObject
			invoke GetRgnBox,selrgn,addr rect
			invoke IsRectEmpty,addr rect
			.if eax
			    invoke DeleteObject,selrgn
			    mov selrgn,0
			.endif
			invoke ResetBusy
redraw:		;cmp lrgn,0
			;je redraw2
			cmp selrgn,0
			je redraw2
			cmp prgn,0
			jne redraw2
			invoke GetWindow,hwnd,GW_OWNER
			;invoke InvalidateRgn,eax,lrgn,TRUE
			invoke InvalidateRgn,eax,selrgn,TRUE
			.break
redraw2:	invoke GetWindow,hwnd,GW_OWNER
			lea edx,rect
			push TRUE
			push edx
			push eax
			invoke GetClientRect,eax,edx
			call InvalidateRect
			.break
        .endif
        .break .if (eax != LVN_KEYDOWN) || ([edx].LV_KEYDOWN.wVKey != VK_DELETE)
        jmp delete

    .case WM_COMMAND
		mov eax,wparam
		.switch eax
		.case IDCANCEL													;Cancel
			invoke DeleteObject,tmprgn
	@@:		invoke DeleteObject,selrgn
			mov tmprgn,0
			mov selrgn,0
			invoke EndDialog,hwnd,wparam
			.break
		.case IDOK														;Save
			mov fmodified,TRUE
			invoke DeleteObject,hrgn
			m2m hrgn,tmprgn
			jmp @B
		.case IDC_BUTTON1, IDC_BUTTON2, IDC_BUTTON4, IDC_BUTTON5		;OR, AND, XOR, DIFF
			invoke DialogBoxParam,hinst,IDD_DIALOG5,hwnd,offset DlgProc5,eax
			.break .if eax == IDCANCEL
			jmp reset2
		.case IDC_BUTTON6												;Move
			invoke DialogBoxParam,hinst,IDD_DIALOG6,hwnd,offset DlgProc6,eax
			.break .if eax == IDCANCEL
			jmp reset2
		.case IDC_BUTTON3												;Delete
delete:		invoke SendDlgItemMessage,hwnd,IDC_LIST1,LVM_GETSELECTEDCOUNT,0,0
			.break .if eax == 0
			push ebx
			xor ebx,ebx
			dec ebx
			mov lvi.imask,LVIF_TEXT
			lea eax,buffer
			mov lvi.pszText,eax
			mov lvi.cchTextMax,sizeof buffer
			.repeat
				invoke SendDlgItemMessage,hwnd,IDC_LIST1,LVM_GETNEXTITEM,ebx,LVNI_ALL or LVNI_SELECTED
				inc eax
				.break .if zero?
				dec eax
				mov lvi.iItem,eax
				mov ebx,eax
				mov lvi.iSubItem,0
				invoke SendDlgItemMessage,hwnd,IDC_LIST1,LVM_GETITEM,0,addr lvi
				.continue .if eax == 0
				mov rect.left,$invoke(atodw,lvi.pszText)
				inc lvi.iSubItem
				invoke SendDlgItemMessage,hwnd,IDC_LIST1,LVM_GETITEM,0,addr lvi
				.continue .if eax == 0
				mov rect.top,$invoke(atodw,lvi.pszText)
				inc lvi.iSubItem
				invoke SendDlgItemMessage,hwnd,IDC_LIST1,LVM_GETITEM,0,addr lvi
				.continue .if eax == 0
				mov rect.right,$invoke(atodw,lvi.pszText)
				inc lvi.iSubItem
				invoke SendDlgItemMessage,hwnd,IDC_LIST1,LVM_GETITEM,0,addr lvi
				.continue .if eax == 0
				mov rect.bottom,$invoke(atodw,lvi.pszText)
				invoke CreateRectRgnIndirect,addr rect
				push eax
				invoke CombineRgn,tmprgn,tmprgn,eax,RGN_DIFF
				call DeleteObject
			.until FALSE
			pop ebx
			jmp reset2
		.endswitch
		.break
	
	.case WM_INITDIALOG
		;invoke CenterDialog,hwnd
		invoke SendDlgItemMessage,hwnd,IDC_LIST1,LVM_INSERTCOLUMN,0,offset lvc0
		invoke SendDlgItemMessage,hwnd,IDC_LIST1,LVM_INSERTCOLUMN,1,offset lvc1
		invoke SendDlgItemMessage,hwnd,IDC_LIST1,LVM_INSERTCOLUMN,2,offset lvc2
		invoke SendDlgItemMessage,hwnd,IDC_LIST1,LVM_INSERTCOLUMN,3,offset lvc3
		invoke SendDlgItemMessage,hwnd,IDC_LIST1,LVM_SETCOLUMNWIDTH,3,LVSCW_AUTOSIZE_USEHEADER
		invoke SendDlgItemMessage,hwnd,IDC_LIST1,LVM_SETCOLUMNWIDTH,2,LVSCW_AUTOSIZE_USEHEADER
		invoke SendDlgItemMessage,hwnd,IDC_LIST1,LVM_SETCOLUMNWIDTH,1,LVSCW_AUTOSIZE_USEHEADER
		invoke SendDlgItemMessage,hwnd,IDC_LIST1,LVM_SETCOLUMNWIDTH,0,LVSCW_AUTOSIZE_USEHEADER
		invoke SendDlgItemMessage,hwnd,IDC_LIST1,LVM_SETEXTENDEDLISTVIEWSTYLE,LVS_EX_GRIDLINES or LVS_EX_FULLROWSELECT,LVS_EX_GRIDLINES or LVS_EX_FULLROWSELECT
reset:	invoke CreateRectRgn,0,0,0,0
		mov tmprgn,eax
		invoke CombineRgn,eax,hrgn,eax,RGN_COPY
reset2:	xor eax,eax
		xchg eax,selrgn
		.if eax
			invoke DeleteObject,eax
		.endif
		invoke SendDlgItemMessage,hwnd,IDC_LIST1,LVM_DELETEALLITEMS,0,0 
		invoke GetRegionData,tmprgn,0,0
		push eax
		invoke LocalAlloc,LPTR,eax
		pop edx
		.if eax
			mov prgn,eax
			mov [eax].RGNDATA.rdh.dwSize,sizeof RGNDATAHEADER
			mov ecx,edx
			sub ecx,sizeof RGNDATAHEADER
			mov [eax].RGNDATA.rdh.nRgnSize,ecx
			invoke GetRegionData,tmprgn,edx,eax
			.if eax
				push ebx
				push esi
				mov ebx,prgn
				mov esi,IDC_EDIT1
				.repeat
					invoke SetDlgItemInt,hwnd,esi,[ebx],TRUE
					add ebx,4
					inc esi
				.until esi > IDC_EDIT8
				mov ebx,prgn
				mov esi,[ebx].RGNDATA.rdh.nCount
				.if esi != 0
					mov lvi.imask,LVIF_TEXT
					lea eax,buffer
					mov lvi.pszText,eax
					mov lvi.iItem,0
					add ebx,[ebx].RGNDATA.rdh.dwSize
					.repeat
						mov lvi.iSubItem,0
						invoke dwtoa,[ebx].RECT.left,lvi.pszText
						invoke SendDlgItemMessage,hwnd,IDC_LIST1,LVM_INSERTITEM,0,addr lvi
						inc lvi.iSubItem
						invoke dwtoa,[ebx].RECT.top,lvi.pszText
						invoke SendDlgItemMessage,hwnd,IDC_LIST1,LVM_SETITEM,0,addr lvi
						inc lvi.iSubItem
						invoke dwtoa,[ebx].RECT.right,lvi.pszText
						invoke SendDlgItemMessage,hwnd,IDC_LIST1,LVM_SETITEM,0,addr lvi
						inc lvi.iSubItem
						invoke dwtoa,[ebx].RECT.bottom,lvi.pszText
						invoke SendDlgItemMessage,hwnd,IDC_LIST1,LVM_SETITEM,0,addr lvi
						add ebx,sizeof RECT
						inc lvi.iItem
						dec esi
					.until zero?
				.endif
				pop esi
				pop ebx
			.endif
			invoke LocalFree,prgn
		.endif
		invoke GetWindow,hwnd,GW_OWNER
		invoke RedrawWindow,eax,0,0,RDW_ERASE or RDW_INTERNALPAINT or RDW_INVALIDATE or RDW_ERASENOW or RDW_UPDATENOW or RDW_ALLCHILDREN
		reti TRUE
	
	.endswitch
	reti FALSE
	
DlgProc3 endp

align DWORD
DlgProc4 proc hwnd:DWORD, umsg:DWORD, wparam:DWORD, lparam:DWORD
	local aspratio	:qword
	local memused	:dword
	local buffer[20]:byte
	
	mov eax,umsg
	.switch eax
	
	.case WM_COMMAND
		mov eax,wparam
		.break .if eax != IDCANCEL
		invoke EndDialog,hwnd,eax
		.break
	
	.case WM_INITDIALOG
		.if hbmp
			fild DibSection.dsBm.bmWidth
			fidiv DibSection.dsBm.bmHeight
			fstp aspratio
			mov eax,DibSection.dsBmih.biSizeImage
			.if eax
				mov memused,eax
			.else
				mov memused,8
				fild DibSection.dsBm.bmWidth
				fimul DibSection.dsBm.bmHeight
				fimul DibSection.dsBm.bmBitsPixel
				fimul DibSection.dsBm.bmPlanes
				fild memused
				fdivp st(1),st(0)
				fistp memused
			.endif
			fwait
			invoke FloatToStr2,aspratio,addr buffer
			invoke SetDlgItemText,hwnd,IDC_EDIT1,offset ImageFile
			invoke SetDlgItemInt,hwnd,IDC_EDIT2,DibSection.dsBm.bmWidth,TRUE
			invoke SetDlgItemInt,hwnd,IDC_EDIT3,DibSection.dsBm.bmHeight,TRUE
			invoke SetDlgItemText,hwnd,IDC_EDIT4,addr buffer
			invoke SetDlgItemInt,hwnd,IDC_EDIT5,memused,FALSE
		.else
			invoke SetDlgItemText,hwnd,IDC_EDIT1,offset szSayWhat
			invoke SetDlgItemText,hwnd,IDC_EDIT2,offset szSayWhat
			invoke SetDlgItemText,hwnd,IDC_EDIT3,offset szSayWhat
			invoke SetDlgItemText,hwnd,IDC_EDIT4,offset szSayWhat
			invoke SetDlgItemText,hwnd,IDC_EDIT5,offset szSayWhat
		.endif
		invoke CenterDialog,hwnd
		reti TRUE
	
	.endswitch
	reti FALSE
	
DlgProc4 endp

align DWORD
DlgProc5 proc hwnd:DWORD, umsg:DWORD, wparam:DWORD, lparam:DWORD
	local lrgn:dword
	local rect:RECT
	
	mov eax,umsg
	.switch eax
	
	.case WM_COMMAND
		mov eax,wparam
		.if eax != IDCANCEL
			.break .if eax != IDOK
			mov rect.left,  $invoke(GetDlgItemInt,hwnd,IDC_EDIT1,NULL,TRUE)
			mov rect.top,   $invoke(GetDlgItemInt,hwnd,IDC_EDIT2,NULL,TRUE)
			mov rect.right, $invoke(GetDlgItemInt,hwnd,IDC_EDIT3,NULL,TRUE)
			mov rect.bottom,$invoke(GetDlgItemInt,hwnd,IDC_EDIT4,NULL,TRUE)
			mov lrgn,$invoke(CreateRectRgnIndirect,addr rect)
			push eax	;DeleteObject
			invoke GetWindowLong,hwnd,GWL_USERDATA
			.switch eax
			.case IDC_BUTTON1		;OR
				push RGN_OR
				.break
			.case IDC_BUTTON2		;AND
				push RGN_AND
				.break
			.case IDC_BUTTON4		;XOR
				push RGN_XOR
				.break
			.case IDC_BUTTON5		;DIFF
				push RGN_DIFF
			.endswitch
			invoke IsDlgButtonChecked,hwnd,IDC_CHECK1
			.if eax == BST_UNCHECKED
				push lrgn
				push tmprgn
			.else
				push tmprgn
				push lrgn
			.endif
			push tmprgn
			call CombineRgn
			call DeleteObject
		.endif
		invoke EndDialog,hwnd,wparam
		.break
	
	.case WM_INITDIALOG
		invoke SetWindowLong,hwnd,GWL_USERDATA,lparam
		mov eax,lparam
		.switch eax
		.case IDC_BUTTON1		;OR
			push offset szOR
			.break
		.case IDC_BUTTON2		;AND
			push offset szAND
			.break
		.case IDC_BUTTON4		;XOR
			push offset szXOR
			.break
		.case IDC_BUTTON5		;DIFF
			invoke EnableWindow,$invoke(GetDlgItem,hwnd,IDC_CHECK1),TRUE
			push offset szDIFF
		.endswitch
		push hwnd
		call SetWindowText
		invoke SetDlgItemInt,hwnd,IDC_EDIT1,0,FALSE
		invoke SetDlgItemInt,hwnd,IDC_EDIT2,0,FALSE
		invoke SetDlgItemInt,hwnd,IDC_EDIT3,0,FALSE
		invoke SetDlgItemInt,hwnd,IDC_EDIT4,0,FALSE
		reti TRUE
	
	.endswitch
	reti FALSE
	
DlgProc5 endp

align DWORD
DlgProc6 proc hwnd:DWORD, umsg:DWORD, wparam:DWORD, lparam:DWORD
	local lrgn  :dword
	local point :POINT
	
	mov eax,umsg
	.switch eax
	
	.case WM_COMMAND
		mov eax,wparam
		.if eax != IDCANCEL
			.break .if eax != IDOK
			mov point.x,$invoke(GetDlgItemInt,hwnd,IDC_EDIT1,NULL,TRUE)
			mov point.y,$invoke(GetDlgItemInt,hwnd,IDC_EDIT2,NULL,TRUE)
			invoke OffsetRgn,tmprgn,point.x,point.y
		.endif
		invoke EndDialog,hwnd,wparam
		.break
	
	.case WM_INITDIALOG
		invoke SetDlgItemInt,hwnd,IDC_EDIT1,0,FALSE
		invoke SetDlgItemInt,hwnd,IDC_EDIT2,0,FALSE
		reti TRUE
	
	.endswitch
	reti FALSE
	
DlgProc6 endp

align DWORD
DlgProc7 proc hwnd:DWORD, umsg:DWORD, wparam:DWORD, lparam:DWORD
	local hDC1		:dword
	local hDC2		:dword
	local hBmp		:dword
	local hOldBmp	:dword
	local hFont		:dword
	local hOldFont	:dword
	local Bitmap	:BITMAP
	local hSplashRgn:dword
	
	mov eax,umsg
	;cmp eax,WM_PAINT
	;je ignore
	cmp eax,WM_LBUTTONUP
	je ktim2
	.switch eax
	
	.case WM_NCPAINT
		mov hDC1,    $invoke(GetWindowDC,hwnd)
		mov hDC2,    $invoke(CreateCompatibleDC,eax)
		mov hBmp,    $invoke(GetWindowLong,hwnd,GWL_USERDATA)
		mov hOldBmp, $invoke(SelectObject,hDC2,eax)
		mov hFont,   $invoke(CreateFontIndirect,offset lf)
		mov hOldFont,$invoke(SelectObject,hDC1,eax)
		invoke GetObject,hBmp,sizeof BITMAP,addr Bitmap
		invoke BitBlt,hDC1,0,0,Bitmap.bmWidth,Bitmap.bmHeight,hDC2,0,0,SRCCOPY
		invoke SetBkMode,hDC1,TRANSPARENT
		invoke SetTextColor,hDC1,$RGB(0,0,255)
		invoke DrawText,hDC1,offset szVer,-1,offset rectVer,DT_CENTER or DT_EXPANDTABS or DT_NOCLIP or DT_NOPREFIX or DT_SINGLELINE or DT_VCENTER
		invoke SelectObject,hDC1,hOldFont
		invoke DeleteObject,hFont
		invoke SelectObject,hDC2,hOldBmp
		invoke DeleteDC,hDC2
		invoke ReleaseDC,hwnd,hDC1
		.break
	
	.case WM_ERASEBKGND
ignore:	invoke SetWindowLong,hwnd,DWL_MSGRESULT,TRUE
		reti TRUE
	
	.case WM_TIMER
ktim:	invoke KillTimer,hwnd,wparam
close:	;invoke EndDialog,hwnd,IDCANCEL
		invoke DestroyWindow,hwnd
		.break
	
	.case WM_COMMAND
		.break .if wparam != IDCANCEL
ktim2:	mov wparam,1
		jmp ktim
	
	.case WM_INITDIALOG
		invoke SetWindowLong,hwnd,GWL_USERDATA,NULL
		invoke GetDC,hwnd
		push eax	;RDC
		push hwnd	;RDC
		invoke GetDeviceCaps,eax,LOGPIXELSY
		xor edx,edx
		mov ecx,10	;font size
		mul ecx
		mov ecx,72
		div ecx
		mov lf.lfHeight,eax
		call ReleaseDC
		invoke FindResource,hinst,IDR_REGION1,RT_RCDATA
		invoke LoadResource,hinst,eax
		invoke LockResource,eax
		.if eax
			mov edx,[eax].RGNDATA.rdh.nRgnSize
			add edx,[eax].RGNDATA.rdh.dwSize
			invoke ExtCreateRegion,NULL,edx,eax
			.if eax
				mov hSplashRgn,eax
				invoke SetWindowRgn,hwnd,eax,FALSE
				.if eax
					;invoke BitmapFromResource,hinst,IDI_IMAGE1
					invoke LoadResPicture,hinst,IDI_IMAGE1,$RGB(0,0,255)
					.if eax
						mov hBmp,eax
						invoke SetWindowLong,hwnd,GWL_USERDATA,eax
						invoke GetObject,hBmp,sizeof BITMAP,addr Bitmap
						invoke MoveWindow,hwnd,0,0,Bitmap.bmWidth,Bitmap.bmHeight,FALSE
						invoke CenterDialog,hwnd
						mov eax,lparam
						.if eax != INFINITE
							invoke SetTimer,hwnd,1,eax,NULL
						.endif
						reti TRUE
					.endif
				.else
					invoke DeleteObject,hSplashRgn
				.endif
			.endif
		.endif
		invoke MessageBoxIndirect,offset mbp4
		jmp close
	
	.case WM_DESTROY
		invoke SetWindowLong,hwnd,GWL_USERDATA,NULL
		.if eax
			invoke DeleteObject,eax
		.endif
	
	.endswitch
	reti FALSE
	
DlgProc7 endp

align DWORD
DlgProc8 proc hwnd:DWORD, umsg:DWORD, wparam:DWORD, lparam:DWORD
	local rect:RECT
	
	mov eax,umsg
	.switch eax
	
	.case WM_SIZE
		invoke GetClientRect,hwnd,addr rect
		invoke GetDlgItem,hwnd,IDC_EDIT1
		invoke MoveWindow,eax,0,0,rect.right,rect.bottom,TRUE
		.break
	
	.case WM_COMMAND
		mov eax,wparam
		.break .if eax != IDCANCEL
@@:		invoke EndDialog,hwnd,eax
		.break
	
	.case WM_INITDIALOG
		invoke FindResource,hinst,IDR_TEXT1,RT_RCDATA
		invoke LoadResource,hinst,eax
		invoke LockResource,eax
		test eax,eax
		jz @B
		invoke SetDlgItemText,hwnd,IDC_EDIT1,eax
		invoke SendDlgItemMessage,hwnd,IDC_EDIT1,EM_SETSEL,-1,0
		reti TRUE
	
	.endswitch
	reti FALSE
	
DlgProc8 endp

align DWORD
Start proc
	
	invoke InitCommonControls
	invoke LoadLibrary,offset szRichEd32
	push eax
	mov hinst,$invoke (GetModuleHandle,0)
	mov wc.hInstance,eax
	mov mbp.hInstance,eax
	mov mbp2.hInstance,eax
	mov mbp3.hInstance,eax
	mov mbp4.hInstance,eax
	invoke RegisterClass,offset wc
	invoke DialogBoxParam,wc.hInstance,IDD_DIALOG1,0,offset DlgProc,eax
	pop eax
	.if eax != 0
		invoke FreeLibrary,eax
	.endif
	invoke ExitProcess,eax
	
Start endp
end Start
