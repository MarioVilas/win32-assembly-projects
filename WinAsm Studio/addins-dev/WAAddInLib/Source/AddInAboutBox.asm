;------------------------------------------------------------------------------
; AddInAboutBox
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Shows an "about" box for the current add-in.
;
; Parameters:
;	pAccel		Pointer to an ACCELERATOR structure
;
; Return values:
;	If the function succeeds, the return value is 0.
;	If the function fails, the return value is -1.
;------------------------------------------------------------------------------

include Common.inc

LaunchBrowser	proto :HWND
AboutBoxProc	proto :HWND, :UINT, :WPARAM, :LPARAM

IDD_DIALOG1	equ 1001
IDC_IMAGE1	equ 1002
IDC_IMAGE2	equ 1003
IDC_STATIC1	equ 1004

.data
AboutDialog label DLGTEMPLATE
db 001h, 000h, 0FFh, 0FFh, 000h, 000h, 000h, 000h, 084h, 000h, 001h, 000h, 050h, 009h, 0C8h, 090h
db 005h, 000h, 000h, 000h, 000h, 000h, 09Bh, 000h, 06Dh, 000h, 000h, 000h, 000h, 000h, 041h, 000h
db 062h, 000h, 06Fh, 000h, 075h, 000h, 074h, 000h, 02Eh, 000h, 02Eh, 000h, 02Eh, 000h, 000h, 000h
db 008h, 000h, 000h, 000h, 000h, 001h, 04Dh, 000h, 053h, 000h, 020h, 000h, 053h, 000h, 061h, 000h
db 06Eh, 000h, 073h, 000h, 020h, 000h, 053h, 000h, 065h, 000h, 072h, 000h, 069h, 000h, 066h, 000h
db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 00Fh, 001h, 050h
db 050h, 000h, 059h, 000h, 047h, 000h, 010h, 000h, 002h, 000h, 000h, 000h, 0FFh, 0FFh, 080h, 000h
db 043h, 000h, 06Ch, 000h, 06Fh, 000h, 073h, 000h, 065h, 000h, 020h, 000h, 074h, 000h, 068h, 000h
db 069h, 000h, 073h, 000h, 020h, 000h, 077h, 000h, 069h, 000h, 06Eh, 000h, 064h, 000h, 06Fh, 000h
db 077h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
db 000h, 00Fh, 001h, 040h, 003h, 000h, 059h, 000h, 047h, 000h, 010h, 000h, 001h, 000h, 000h, 000h
db 0FFh, 0FFh, 080h, 000h, 056h, 000h, 069h, 000h, 073h, 000h, 069h, 000h, 074h, 000h, 020h, 000h
db 074h, 000h, 068h, 000h, 065h, 000h, 020h, 000h, 077h, 000h, 065h, 000h, 062h, 000h, 020h, 000h
db 073h, 000h, 069h, 000h, 074h, 000h, 065h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
db 000h, 000h, 000h, 000h, 003h, 002h, 000h, 050h, 003h, 000h, 003h, 000h, 029h, 000h, 026h, 000h
db 0EAh, 003h, 000h, 000h, 0FFh, 0FFh, 082h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
db 000h, 000h, 000h, 000h, 003h, 002h, 000h, 050h, 003h, 000h, 02Eh, 000h, 029h, 000h, 026h, 000h
db 0EBh, 003h, 000h, 000h, 0FFh, 0FFh, 082h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 050h, 032h, 000h, 003h, 000h, 065h, 000h, 051h, 000h
db 0ECh, 003h, 000h, 000h, 0FFh, 0FFh, 082h, 000h, 000h, 000h, 000h, 000h

sz Jan
sz Feb
sz Mar
sz Apr
sz May
sz Jun
sz Jul
sz Aug
sz Sep
sz Oct
sz Nov
sz Dec

szFmt db "%s",13,10,13,10,"%s",13,10,13,10,"%s",13,10,13,10,"%s",13,10,"Last updated %i %s %i",0

.data?
szFriendlyName	db MAX_PATH dup (?)
szDescription	db MAX_PATH dup (?)
szAboutText		db MAX_PATH * 4 dup (?)

.code
align DWORD
LaunchBrowser proc hWnd:HWND
	
	invoke GetDlgItem,hWnd,IDOK
	.if eax
		push TRUE
		push eax
		invoke GetWindowLong,eax,GWL_USERDATA
		.if eax
			invoke ShellExecute,hWnd,NULL,eax,NULL,NULL,0
		.endif
		call EnableWindow
	.endif
	ret
	
LaunchBrowser endp

align DWORD
AboutBoxProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local hButton	:HWND
	local systime	:SYSTEMTIME
	local w32fd		:WIN32_FIND_DATA
	
	mov eax,uMsg
	.if eax == WM_COMMAND
		mov eax,wParam
		.if eax == IDOK
			
			; Visit author's web site
			invoke GetDlgItem,hWnd,eax
			.if eax
				mov hButton,eax
				invoke IsWindowEnabled,eax
				push eax
				invoke EnableWindow,hButton,FALSE
				pop eax
				.if eax
					push eax	;temp. variable
					invoke CreateThread,NULL,0,offset LaunchBrowser,hWnd,0,esp
					pop edx
					.if eax
						invoke CloseHandle,eax
					.endif
				.endif
			.endif
			
		.elseif eax == IDCANCEL
			
			; Close this window
			invoke EndDialog,hWnd,0
			
		.endif
	.elseif eax == WM_INITDIALOG
		push ebx
		mov ebx,lParam
		.if ebx
			; 	pszCaption	:PTR BYTE		[EBX + 0]
			;	pszURL		:PTR BYTE		[EBX + 4]
			;	hIcon		:HICON			[EBX + 8]
			
			; Set the about box caption
			mov eax,[ebx]
			.if eax
				invoke SetWindowText,hWnd,eax
			.endif
			
			; Remember author's web site URL
			invoke GetDlgItem,hWnd,IDOK
			.if eax
				mov edx,[ebx + 4]
				mov hButton,eax
				.if edx
					invoke SetWindowLong,eax,GWL_USERDATA,edx
					invoke EnableWindow,hButton,TRUE
					invoke ShowWindow,hButton,SW_SHOW
				.endif
			.endif
			
			; Load and set the WinAsm icon
			invoke GetModuleHandle,NULL
			invoke LoadImage,eax,1001,IMAGE_ICON,0,0,LR_DEFAULTCOLOR or LR_DEFAULTSIZE
			invoke SendDlgItemMessage,hWnd,IDC_IMAGE1,STM_SETIMAGE,IMAGE_ICON,eax
			
			; Set add-in's icon, if one was provided
			invoke SendDlgItemMessage,hWnd,IDC_IMAGE2,STM_SETIMAGE,IMAGE_ICON,dword ptr [ebx + 8]
			
			; Get add-in's full pathname and last modified date
			mov w32fd.cFileName[0],0
			invoke GetModuleFileName,hInstDll,addr w32fd.cFileName,sizeof w32fd.cFileName
			mov w32fd.ftCreationTime.dwLowDateTime,0
			mov w32fd.ftCreationTime.dwHighDateTime,0
			mov w32fd.ftLastWriteTime.dwLowDateTime,0
			mov w32fd.ftLastWriteTime.dwHighDateTime,0
			mov w32fd.ftLastAccessTime.dwLowDateTime,0
			mov w32fd.ftLastAccessTime.dwHighDateTime,0
			.if eax
				invoke FindFirstFile,addr w32fd.cFileName,addr w32fd
				.if eax != INVALID_HANDLE_VALUE
					invoke FindClose,eax
					.if (w32fd.ftLastWriteTime.dwLowDateTime == 0) && \
						(w32fd.ftLastWriteTime.dwHighDateTime == 0)
						mov eax,w32fd.ftCreationTime.dwLowDateTime
						mov edx,w32fd.ftCreationTime.dwHighDateTime
						.if (eax == 0) && (edx == 0)
							mov eax,w32fd.ftLastAccessTime.dwLowDateTime
							mov edx,w32fd.ftLastAccessTime.dwHighDateTime
						.endif
						mov w32fd.ftLastWriteTime.dwLowDateTime,eax
						mov w32fd.ftLastWriteTime.dwHighDateTime,edx
					.endif
				.endif
			.endif
			
			; Get the add-in's filename only
			invoke PathFindFileName,addr w32fd.cFileName
			.if eax
				push esi
				push edi
				mov esi,eax
				lea edi,w32fd.cFileName
				mov ecx,sizeof w32fd.cFileName
				sub eax,edi
				sub ecx,eax
				rep movsb
				pop edi
				pop esi
			.endif
			
			; Get add-in's friendly name and description
			invoke GetWAAddInData,offset szFriendlyName,offset szDescription
			
			; Parse the file time
			mov systime.wDay,0
			mov systime.wMonth,0
			mov systime.wYear,0
			invoke FileTimeToSystemTime,addr w32fd.ftLastWriteTime,addr systime
			
			; Merge it all into a single string
			movzx ecx,systime.wDay
			movzx eax,systime.wMonth
			movzx edx,systime.wYear
			shl eax,2
			add eax,offset szJan
			invoke wsprintf,offset szAboutText,offset szFmt,\
			 				offset szFriendlyName,offset szDescription,\
			 				dword ptr [ebx + 4],addr w32fd.cFileName,\
			 				ecx,eax,edx
			
			; Set the about box text
			invoke SetDlgItemText,hWnd,IDC_STATIC1,offset szAboutText
			
		.else
			
			; Close the dialog on error
			invoke EndDialog,hWnd,FALSE
			
		.endif
		pop ebx
	.endif
	xor eax,eax
	ret
	
AboutBoxProc endp

align DWORD
AddInAboutBox proc pszCaption:PTR BYTE, pszURL:PTR BYTE, hIcon:HICON
	
	invoke GetModuleHandle,NULL
	mov edx,pHandles
	.if edx
		mov edx,[edx].HANDLES.hMain
	.endif
	lea ecx,pszCaption	;Points to all parameters
	invoke DialogBoxIndirectParam,eax,offset AboutDialog,edx,offset AboutBoxProc,ecx
	ret
	
AddInAboutBox endp

end
