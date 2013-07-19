.386
.model flat,stdcall
option casemap:none

include windows.inc
include WAAddIn.inc

include kernel32.inc
include user32.inc
include shlwapi.inc
includelib kernel32.lib
includelib user32.lib
includelib shlwapi.lib

IFDEF DEBUG_BUILD
	include masm32.inc
	include debug.inc
	includelib masm32.lib
	includelib debug.lib
ENDIF

include WAAddInLib.inc
includelib WAAddInLib.lib

IFNDEF STIF_SUPPORT_HEX
	STIF_SUPPORT_HEX equ 1
ENDIF

IFNDEF STIF_DEFAULT
	STIF_DEFAULT equ 0
ENDIF

LoadConfig		proto
SaveConfig		proto
BreakLines		proto pszText:PTR CHAR
ParseDefine		proto pszLine:PTR CHAR, prid:PTR RESID
BuildListProc	proto hMDIChildWindow:DWORD, lParam:LPARAM
BuildSrc		proto
DestroyList		proto
DllEntryPoint	proto hinstDLL:HINSTANCE, fdwReason:DWORD, lpvReserved:LPVOID
GetWAAddInData	proto lpFriendlyName:PTR BYTE, lpDescription:PTR BYTE
WAAddInLoad		proto pWinAsmHandles:PTR HANDLES, pWinAsmFeatures:PTR FEATURES
WAAddInUnload	proto
WAAddInConfig	proto pWinAsmHandles:PTR HANDLES, pWinAsmFeatures:PTR FEATURES
FrameWindowProc	proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
ConfigDlgProc	proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

IDI_ICON1                   EQU 100
IDD_CONFIG                  EQU 1001
IDC_ALIGN                   EQU 1002
IDC_LOWER                   EQU 1003
IDC_DEFAULT                 EQU 1004
IDC_UPPER                   EQU 1005

RESID_NAME_LENGTH equ 32	; Max. length currently supported by WinAsm

RESID struct
	
	dwID	DWORD ?
	szName	CHAR RESID_NAME_LENGTH dup (?)
	
RESID ends

RESIDLIST struct
	
	pNext	DWORD ?
	rid		RESID <>
	
RESIDLIST ends

.data?
hInstance	dd ?	;DLL instance handle
pHandles	dd ?	;Pointer to HANDLES structure
pFeatures	dd ?	;Pointer to FEATURES structure
pIniFile	dd ?	;Pointer to the addins INI filename
ItemID		dd ?	;ID of the menu item under the "Dialog" submenu
SeparatorID	dd ?	;Separator item ID

pList		dd ?	;Pointer to list of resource IDs (linked list)
pCurrent	dd ?	;Pointer to last block in linked list
iListCount	dd ?	;Number of blocks in linked list

iCase		dd ?	;Case for the word "equ"
bAlign		dd ?	;Align equate definitions

szLine		db 256 dup (?)
	 		db ?	;just in case ;)

.data
; Sample keyboard accelerator
xAccel		ACCELERATOR < FVIRTKEY or FCONTROL, VK_I, -1 >	;fVirt, key, cmd

; Auxiliary strings
szFmtInt		db "%i",0
szDefine		db "DEFINE",0

; Misc
szAppName		db "ResID",0									;Section in the addins INI file
szCase			db "Case",0											;Case for the word "equ"
szAlign			db "Align",0										;Align equate definitions

szItemText		db "&Insert resource IDs",9,"Ctrl + I",0		;Caption of the menu item

szFriendlyName	db "ResID 1.0.0.1",0							;Friendly add-in name
szDescription	db "Insert resource IDs automatically",13,10	;Add-in description
	 			db "in your assembly source files",0

.code
align DWORD
LoadConfig proc
	
	invoke GetPrivateProfileInt,offset szAppName,offset szCase,1,pIniFile
	.if eax > 2
		mov eax,1
	.endif
	mov iCase,eax
	invoke GetPrivateProfileInt,offset szAppName,offset szAlign,1,pIniFile
	and eax,1
	mov bAlign,eax
	ret
	
LoadConfig endp

align DWORD
SaveConfig proc
	local buff[20]:CHAR
	
	invoke wsprintf,addr buff,offset szFmtInt,iCase
	invoke WritePrivateProfileString,offset szAppName,offset szCase,addr buff,pIniFile
	invoke wsprintf,addr buff,offset szFmtInt,bAlign
	invoke WritePrivateProfileString,offset szAppName,offset szAlign,addr buff,pIniFile
	ret
	
SaveConfig endp

align DWORD
BreakLines proc uses esi pszText:PTR CHAR
	
	; I know this code is really horrible, but I don't feel like doing something fancy today.
	mov esi,pszText
	.repeat
		lodsb
		.break .if al == 0
		.continue .if (al != 13) && (al != 10)
		mov byte ptr [esi - 1],0
	.until FALSE
	ret
	
BreakLines endp

align DWORD
ParseDefine proc uses edi pszLine:PTR CHAR, prid:PTR RESID
	local pStr	:DWORD
	
;	IFDEF DEBUG_BUILD
;		PrintText "ParseDefine()"
;		PrintStringByAddr pszLine
;	ENDIF
	
	mov edi,pszLine
	invoke lstrlen,edi
	lea ecx,[eax + 1]
	
	; #DEFINE
	call skipspaces
	mov al,'#'
	scasb
	jne no
	dec ecx
	mov pStr,edi
	call skipword
	jz no
	push ecx
	invoke lstrcmpi,pStr,offset szDefine
	pop ecx
	test eax,eax
	jnz no
	
	; ID Name
	call skipspaces
	mov pStr,edi
	call skipword
	jz no
	push ecx
	mov edx,prid
	invoke lstrcpyn,addr [edx].RESID.szName,pStr,sizeof RESID.szName
	pop ecx
	test eax,eax
	jz no
	
	; ID Value
	call skipspaces
	mov pStr,edi
	call skipword
	mov eax,prid
	lea edx,[eax].RESID.dwID
	push edx
	mov edx,pStr
	.if word ptr [edx] == 'x0'
		push STIF_SUPPORT_HEX
		add edx,2
	.else
		push STIF_DEFAULT
	.endif
	push edx
	call StrToIntEx
rt:	ret
	
no:	xor eax,eax
	jmp rt
	
skipspaces:
	mov al,[edi]
	cmp al,' '
	je cn
	cmp al,9
	jne br2
cn:	add edi,1
	sub ecx,1
	jg skipspaces
	pop eax
	jmp no
br2:retn 0
	
skipword:
	mov al,[edi]
	cmp al,' '
	je br
	cmp al,9
	je br
	cmp al,0
	je br
	add edi,1
	sub ecx,1
	jg skipword
	pop eax
	jmp no
br:	mov al,0
	stosb
	dec ecx
	retn 0
	
ParseDefine endp

align DWORD
BuildListProc proc uses edi hMDIChildWindow:DWORD, lParam:LPARAM
	local temp		:DWORD
	local hCodeHi	:HWND
	local pText		:DWORD
	local iCount	:DWORD
	local ridl		:RESIDLIST
	
	invoke GetWindowLong,hMDIChildWindow,0
	.if eax
;		IFDEF DEBUG_BUILD
;			lea edx,[eax].CHILDDATA.FileName
;			mov temp,edx
;			PrintStringByAddr temp
;		ENDIF
		.if [eax].CHILDDATA.TypeOfFile == 3
			push [eax].CHILDDATA.hEditor
			pop hCodeHi
;			mov edi,pHandles
;			invoke SendMessage,[edi].HANDLES.hClient,WM_MDIACTIVATE,hMDIChildWindow,0
;			invoke GetMenuState,[edi].HANDLES.hMenu,IDM_PROJECT_VISUALMODE,MF_BYCOMMAND
;			IFDEF DEBUG_BUILD
;				PrintHex EAX
;			ENDIF
;			test eax,MF_CHECKED
;			.if !zero?
;				invoke SendMessage,[edi].HANDLES.hMain,WM_COMMAND,IDM_PROJECT_VISUALMODE,0
;			.endif
			invoke SendMessage,hCodeHi,WM_GETTEXTLENGTH,0,0
			.if eax != 0
				mov iCount,eax
				invoke LocalAlloc,LPTR,eax
				.if eax
					mov pText,eax
					mov edi,eax
					invoke SendMessage,hCodeHi,WM_GETTEXT,iCount,eax
					.if eax
						invoke BreakLines,edi
						mov ridl.pNext,NULL
						.repeat
							invoke lstrlen,edi
							.if eax != 0
								push eax
								invoke ParseDefine,edi,addr ridl.rid
								.if eax
;									IFDEF DEBUG_BUILD
;										PrintDec ridl.rid.dwID
;										PrintString ridl.rid.szName
;									ENDIF
									invoke LocalAlloc,LPTR,sizeof RESIDLIST
									.if eax
										mov edx,pCurrent
										.if edx != NULL
											mov [edx].RESIDLIST.pNext,eax
										.else
											mov pList,eax
										.endif
										mov pCurrent,eax
										lea edx,ridl
										invoke RtlMoveMemory,eax,edx,sizeof RESIDLIST
										inc iListCount
									.endif
								.endif
								pop eax
							.endif
							add eax,1
							add edi,eax
							sub iCount,eax
						.until zero?
					.endif
					invoke LocalFree,pText
				.endif
			.endif
		.endif
	.endif
	push TRUE
	pop eax
	ret
	
BuildListProc endp

align DWORD
BuildSrc proc uses ebx esi edi
	local pText:DWORD
	local iSize:DWORD
	local iStr1:DWORD
	local iStr2:DWORD
	local szNum[20]:CHAR
	
	; < RESID.szName (31) > EQU < szNum (19) >		(total 57)
	
	mov ebx,iListCount
	mov esi,pList
	mov eax,64	;57
	xor edx,edx
	mul ebx
	.if eax && !edx
		inc eax
		mov iSize,eax
		invoke LocalAlloc,LPTR,eax
		.if eax
			mov pText,eax
			mov edi,eax
			.repeat
				invoke wsprintf,addr szNum,offset szFmtInt,[esi].RESIDLIST.rid.dwID
				.if eax
					mov iStr1,eax
					invoke lstrlen,addr [esi].RESIDLIST.rid.szName
					.if eax
						mov iStr2,eax
						invoke lstrcpy,edi,addr [esi].RESIDLIST.rid.szName
;						IFDEF DEBUG_BUILD
;							PrintString [esi].RESIDLIST.rid.szName
;							PrintString szNum
;							PrintDec iStr1
;							PrintDec iStr2
;						ENDIF
						mov ecx,iStr2
						add edi,ecx
						.if bAlign
							neg ecx
							add ecx,sizeof RESID.szName
						.else
							mov ecx,1
						.endif
						mov eax,' '
						rep stosb
						mov edx,iCase
						.if edx == 0
							mov eax,' uqe'
						.elseif edx == 1
							mov eax,' uqE'
						.else
							mov eax,' UQE'
						.endif
						stosd
						invoke lstrcpy,edi,addr szNum
						add edi,iStr1
						mov eax,0A0Dh
						stosw
					.endif
				.endif
				mov esi,[esi].RESIDLIST.pNext
				sub ebx,1
			.until zero?
			mov eax,pText
		.endif
	.endif
	ret
	
BuildSrc endp

align DWORD
DestroyList proc uses ebx
	
	mov ebx,pList
	.while ebx
		push [ebx].RESIDLIST.pNext
		invoke LocalFree,ebx
		pop ebx
	.endw
	mov pList,NULL
	mov pCurrent,NULL
	mov iListCount,0
	ret
	
DestroyList endp

align DWORD
DllEntryPoint proc hinstDLL:HINSTANCE, fdwReason:DWORD, lpvReserved:LPVOID
	
	; DLL entry point. LEAVE IT AS IT IS. Put initialization code in WAAddInLoad.
	
	.if fdwReason == DLL_PROCESS_ATTACH
		
		push hinstDLL	; You can comment out this two lines if 
		pop hInstance	; you don't use the DLL instance handle
		
		; Comment out this line if you have multithreaded code
		invoke DisableThreadLibraryCalls,hinstDLL
		
	.endif
	push TRUE
	pop eax
	ret
	
DllEntryPoint endp

align DWORD
GetWAAddInData proc lpFriendlyName:PTR BYTE, lpDescription:PTR BYTE
	
	; Copy the addin's name and description into the buffers
	; pointed to by lpFriendlyName and lpDescription.
	; Both strings must be ASCIIZ (255 chars max.)
	
	invoke lstrcpy,lpFriendlyName,offset szFriendlyName
	invoke lstrcpy,lpDescription,offset szDescription
	ret
	
GetWAAddInData endp

align DWORD
WAAddInLoad proc pWinAsmHandles:PTR HANDLES, pWinAsmFeatures:PTR FEATURES
	
	; When the addin is loaded, WinAsm will call this function.
	; Remember that addins can be loaded and unleaded at user's request any time.
	
	IFDEF DEBUG_BUILD
		PrintText "Loading AddIn."
	ENDIF
	
	; Initialize WAAddInLib.lib
	invoke InitializeAddIn,hInstance,pWinAsmHandles,pWinAsmFeatures,offset szAppName
	.if !eax
		dec eax		;return -1 to cancel loading this addin
		ret
	.endif
	mov pIniFile,eax	; Keep the pointer to the addins INI filename if needed.
	
	; Keep pWinAsmHandles and pWinAsmFeatures.
	; pWinAsmHandles is a pointer to the HANDLES structure.
	; pWinAsmFeatures is a pointer to the FEATURES structure.
	push pWinAsmHandles
	pop pHandles
	push pWinAsmFeatures
	pop pFeatures
	
	; Ensure the current version of WinAsm Studio is compatible with our addin (if needed).
	invoke CheckWAVersion,4000	;For example, version 3.0.1.4 is 3014 (decimal).
	.if !eax
		dec eax		;return -1 to cancel loading this addin
		ret
	.endif
	
	; Load addin's config here.
	invoke LoadConfig
	
	; Add a menu item for the addin here.
	invoke AddMenuItemEx,offset szItemText,MENU_POS_DIALOG,-1,-1
	mov ItemID,eax
	mov SeparatorID,edx
	
	; Add an accelerator for the menu item here.
	; Don't add it if another addin disabled all the accelerators.
	mov edx,pHandles
	.if [edx].HANDLES.phAcceleratorTable != NULL
		mov eax,ItemID
		mov xAccel.cmd,ax
		invoke AddAccelerator,offset xAccel
	.endif
	
	IFDEF DEBUG_BUILD
		PrintText "Loaded."
	ENDIF
	
	; Return 0 if successful, -1 on error (addin will be unloaded WITHOUT calling WAAddInUnload).
	xor eax,eax
	ret
	
WAAddInLoad endp

align DWORD
WAAddInUnload proc
	
	; When the addin is unloaded, WinAsm will call this function.
	
	IFDEF DEBUG_BUILD
		PrintText "Unloading AddIn."
	ENDIF
	
	; Remove the menu item(s) added in WAAddInLoad.
	mov eax,pHandles
	mov edx,[eax].HANDLES.hMenu
	push MF_BYCOMMAND
	push SeparatorID
	push edx
	invoke DeleteMenu,edx,ItemID,MF_BYCOMMAND
	call DeleteMenu
	
	; Remove the accelerator(s) added in WAAddInLoad.
	invoke RemoveAccelerator,offset xAccel
	
	IFDEF DEBUG_BUILD
		PrintText "Unloaded."
	ENDIF
	
	; The return value is ignored by WinAsm.
	ret
	
WAAddInUnload endp

align DWORD
WAAddInConfig proc pWinAsmHandles:PTR HANDLES, pWinAsmFeatures:PTR FEATURES
	
	push pWinAsmHandles
	pop pHandles
	push pWinAsmFeatures
	pop pFeatures
	mov eax,pWinAsmHandles
	.if eax
		mov eax,[eax].HANDLES.hMain
	.endif
	invoke DialogBoxParam,hInstance,IDD_CONFIG,eax,offset ConfigDlgProc,0
	ret
	
WAAddInConfig endp

align DWORD
FrameWindowProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
	local hCodeHi	:HWND
	local hMDI		:HWND
	local cpi		:CURRENTPROJECTINFO
	
	; This procedure gets all messages for the main (MDI frame) window.
	; After every processed WM_COMMAND, WinAsm also sends WAE_COMMANDFINISHED
	; to all addins, with the same wParam and lParam values.
	; This procedure is optional. Make sure to add it to the .def file if you want to use it!
	
	mov eax,uMsg
	.if eax == WM_COMMAND
		mov eax,wParam
		mov edx,eax
		shr eax,16
		and edx,0FFFFh
		.if (eax == 0) || (eax == 1)	;0 for menu item or toolbar, 1 for accelerator.
			.if edx == ItemID
				
				IFDEF DEBUG_BUILD
					PrintText "Addin's menu item activated."
				ENDIF
				
				; Get the active CodeHi control.
				invoke GetActiveCodeHi
				.if eax && edx
					mov hCodeHi,eax
					mov hMDI,edx
					
					; Build a list of resource IDs in the current project.
;					invoke LockWindowUpdate,hWnd
					invoke SendMessage,hWnd,WAM_ENUMCURRENTPROJECTFILES,offset BuildListProc,0
;					mov eax,pHandles
;					invoke SendMessage,[eax].HANDLES.hClient,WM_MDIACTIVATE,hMDI,0
;					invoke LockWindowUpdate,NULL
					
					; Export the list as assembly source.
					invoke BuildSrc
					.if eax
						push eax
						invoke SendMessage,hCodeHi,EM_REPLACESEL,TRUE,eax
						call LocalFree
					.endif
					
					; Destroy the list, we no longer need it.
					invoke DestroyList
					
				.endif
				push 1
				pop eax
				ret
				
			.endif
		.endif
	.elseif eax == WAM_DIFFERENTCURRENTPROJECT
		
		; Enable or disable the menu item.
		invoke SendMessage,hWnd,WAM_GETCURRENTPROJECTINFO,addr cpi,0
		.if eax
			push MF_ENABLED
		.else
			push MF_DISABLED
		.endif
		push ItemID
		mov eax,pHandles
		push [eax].HANDLES.hMenu
		call EnableMenuItem
		
	.endif
	
	; Return 0 (FALSE) to allow other addins and WinAsm itself process this message.
	; Return 1 (TRUE) to... well, guess ;)
	xor eax,eax
	ret
	
FrameWindowProc endp

align DWORD
ConfigDlgProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
	mov eax,uMsg
	.if eax == WM_COMMAND
		mov eax,wParam
		cmp eax,IDCANCEL
		je cancel
		.if eax == IDOK
			mov iCase,0
			invoke IsDlgButtonChecked,hWnd,IDC_LOWER
			test eax,BST_CHECKED
			.if zero?
				inc iCase
				invoke IsDlgButtonChecked,hWnd,IDC_DEFAULT
				test eax,BST_CHECKED
				.if zero?
					inc iCase
				.endif
			.endif
			invoke IsDlgButtonChecked,hWnd,IDC_ALIGN
			and eax,1
			mov bAlign,eax
			invoke SaveConfig
cancel:		invoke EndDialog,hWnd,eax
		.endif
	.elseif eax == WM_INITDIALOG
		invoke LoadConfig
		mov eax,iCase
		add eax,IDC_LOWER
		invoke CheckRadioButton,hWnd,IDC_LOWER,IDC_UPPER,eax
		invoke CheckDlgButton,hWnd,IDC_ALIGN,bAlign
		push TRUE
		pop eax
		ret
	.endif
	xor eax,eax
	ret
	
ConfigDlgProc endp

end DllEntryPoint
