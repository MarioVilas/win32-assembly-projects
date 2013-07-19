;DEBUG_BUILD equ 1		;Uncomment for debug builds

include macros.inc

AppModel .386

include \masm32\include\WINDOWS.INC
include \WinAsm\Inc\WAAddIn.inc
include imagehlp.inc

incl kernel32,user32,gdi32,comctl32,comdlg32,shell32,advapi32,ole32,oleaut32,masm32

IFDEF DEBUG_BUILD
	incl debug			;VKim's debug library
ENDIF

include WAAgent.inc
include RunDll32.inc

.code
align DWORD
DllEntryPoint proc hinstDLL:HINSTANCE, fdwReason:DWORD, lpvReserved:LPVOID

	; DLL entry point. LEAVE IT AS IT IS. Put initialization code in WAAddInLoad.

	.if fdwReason == DLL_PROCESS_ATTACH
		push hinstDLL	; You can comment out this two lines if 
		pop hInstance	; you don't use the DLL instance handle
		invoke DisableThreadLibraryCalls,hinstDLL
	.endif
	push TRUE
	pop eax
	ret

DllEntryPoint endp

align DWORD
LoadConfig proc

	mov iIcon,$invoke(GetPrivateProfileInt,offset szAppName,offset szIcon,0,offset szIniPath)
	mov bLoadExe,$invoke(GetPrivateProfileInt,offset szAppName,offset szLoadExe,FALSE,offset szIniPath)
	mov bLoadUsed,$invoke(GetPrivateProfileInt,offset szAppName,offset szLoadUsed,FALSE,offset szIniPath)
	mov bLoadUnused,$invoke(GetPrivateProfileInt,offset szAppName,offset szLoadUnused,FALSE,offset szIniPath)
	mov bLoadProject,$invoke(GetPrivateProfileInt,offset szAppName,offset szLoadProject,FALSE,offset szIniPath)
	mov bLoadWords,$invoke(GetPrivateProfileInt,offset szAppName,offset szLoadWords,FALSE,offset szIniPath)
	ret

LoadConfig endp

align DWORD
SaveBool proc bBool:DWORD, pszBool:DWORD

	mov eax,bBool
	and eax,TRUE
	add eax,eax
	add eax,offset sz0
	invoke WritePrivateProfileString,offset szAppName,pszBool,eax,offset szIniPath
	ret

SaveBool endp

align DWORD
SaveConfig proc

	invoke wsprintf,offset buffer,offset szFmtInt,iIcon
	invoke WritePrivateProfileString,offset szAppName,offset szIcon,offset buffer,offset szIniPath
	invoke SaveBool,bLoadExe,offset szLoadExe
	invoke SaveBool,bLoadUsed,offset szLoadUsed
	invoke SaveBool,bLoadUnused,offset szLoadUnused
	invoke SaveBool,bLoadProject,offset szLoadProject
	invoke SaveBool,bLoadWords,offset szLoadWords
	ret

SaveConfig endp

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
WAAddInLoad proc uses ebx pWinAsmHandles:PTR HANDLES, features:PTR FEATURES
	local bIncrement	:DWORD

	; When the addin is loaded, WinAsm will call this function.
	; Remember that addins can be loaded and unleaded at user's request any time.

	IFDEF DEBUG_BUILD
		PrintText "Loading AddIn."
	ENDIF

	; pWinAsmHandles is a pointer to the HANDLES structure.
	mov ebx,pWinAsmHandles
	mov pHandles,ebx

	; features is a pointer to the FEATURES structure.
	; Use it to get WinAsm version number (decimal, for example version 1.2.3.4 is 1234).
;	mov eax,features
;	test eax,eax
;	jz @F
;	.if [eax].FEATURES.Version < 1000
;@@:
;		.data
;		szError db "Error",0
;		szNotSupported db "This addin requires WinAsm Studio version 1.0.0.0 or above.",0
;		.code
;		invoke MessageBox,[ebx].HANDLES.hMain,offset szNotSupported,offset szError,MB_OK or MB_ICONERROR
;	.endif

	; Get the addins INI filename, and DLL path.
	push edi
	mov edi,offset szIniPath
	invoke GetModuleFileName,hInstance,edi,MAX_PATH
	push eax
	invoke GetShortPathName,edi,offset szDllPath,MAX_PATH
	pop ecx
	add edi,ecx
	mov al,'\'
	std
	repne scasb
	cld
	mov byte ptr [edi + 2],0
	pop edi
	invoke lstrcat,offset szIniPath,offset szIniFile

	; Parse the command line to RunDll32.exe
	invoke GetWindowsDirectory,offset szCommandLine,MAX_PATH
	invoke lstrlen,offset szCommandLine
	.if byte ptr szCommandLine[eax-1] != '\'
		mov word ptr szCommandLine[eax],'\'
	.endif
	invoke lstrcat,offset szCommandLine,offset szRunDll32
	invoke lstrcat,offset szCommandLine,offset szDllPath
	invoke lstrcat,offset szCommandLine,offset szCmd2

	; You can add a menu item for your addin here.
	invoke SendMessage,[ebx].HANDLES.hMain,WAM_GETNEXTMENUID,0,0
	mov ItemID,eax
	invoke SendMessage,[ebx].HANDLES.hClient,WM_MDIGETACTIVE,0,addr bIncrement
	mov eax,7			;0:File,	1:Edit,		2:View,		3:Project,
						;4:Format,	5:Dialog,	6:Make,		7:Tools,
						;8:Add-Ins,	8:Window,	9:Help
	add eax,bIncrement	;+1 if the active MDI child is maximized
	mov edx,features
	.if edx && (dword ptr [edx] >= 3023)
		inc eax			;+1 after "Format" for 3.0.2.3+
	.endif
	invoke GetSubMenu,[ebx].HANDLES.hMenu,eax
	mov hMenu,eax
	invoke GetMenuItemCount,eax
	dec eax
	.if zero?			;Add a separator if needed, looks better :)
		invoke AppendMenu,hMenu,MF_SEPARATOR,-1,NULL
	.endif
	mov eax,MF_ENABLED or MF_STRING
	mov edx,features
	.if (edx != NULL) && ([edx].FEATURES.Version >= 1016)
		or eax,MF_OWNERDRAW		;Required for WinAsm 1.0.1.6 and above
	.endif
	invoke AppendMenu,hMenu,eax,ItemID,offset szMenuString

	; Place your one-time initialization code here...

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

	; You must remove the menu item added in WAAddInLoad.
	invoke DeleteMenu,hMenu,ItemID,MF_BYCOMMAND
	invoke GetMenuItemCount,hMenu
	.if eax == 2
		;Remove the separator too if needed.
		invoke DeleteMenu,hMenu,1,MF_BYPOSITION
	.endif

	; Release your addin's resources here...

	IFDEF DEBUG_BUILD
		PrintText "Unloaded."
	ENDIF

	; The return value is ignored by WinAsm.
	ret

WAAddInUnload endp

align DWORD
FrameWindowProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

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
		.if (eax == 0) || (eax == 1)	;0 for menu item or toolbar, 1 for accelerator
			.if edx == ItemID			;You can also use the IDM_* equates here.
				IFDEF DEBUG_BUILD
					PrintText "Addin's menu item activated."
				ENDIF
				invoke DialogBoxParam,hInstance,IDD_DIALOG1,hWnd,offset DlgProc,0
			.endif
		.endif
	.endif

	; Return 0 (FALSE) to allow other addins and WinAsm itself process this message.
	; Return 1 (TRUE) to... well, guess ;)
	xor eax,eax
	ret

FrameWindowProc endp

align DWORD
DlgProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local hKey		:DWORD
	local dwCreated	:DWORD

	mov eax,uMsg
	.switch eax
	
	.case WM_NOTIFY
		mov edx,lParam
		test edx,edx
		jz $default
		cmp [edx].NMHDR.idFrom,IDC_UPDOWN1
		jne $default
		cmp [edx].NMHDR.code,UDN_DELTAPOS
		jne $default
		mov eax,[edx].NM_UPDOWN.iPos
		add eax,[edx].NM_UPDOWN.iDelta
		test eax,not 7
		.if zero?
			mov iIcon,eax
			add eax,IDI_ICON0
			invoke LoadImage,hInstance,eax,IMAGE_ICON,0,0,0
			test eax,eax
			jz @F
			invoke SendDlgItemMessage,hWnd,IDC_IMAGE1,STM_SETIMAGE,IMAGE_ICON,eax
			push FALSE
		.else
@@:			push TRUE
		.endif
		push DWL_MSGRESULT
		push hWnd
		call SetWindowLong
		.break
	
	.case WM_COMMAND
		mov eax,wParam
		.if eax == IDOK
;			invoke SendDlgItemMessage,hWnd,IDC_UPDOWN1,UDM_GETPOS,0,0
;			and eax,7
;			mov iIcon,eax
			mov bLoadExe,$invoke(IsDlgButtonChecked,hWnd,IDC_CHECK1)
			mov bLoadUsed,$invoke(IsDlgButtonChecked,hWnd,IDC_CHECK2)
			mov bLoadUnused,$invoke(IsDlgButtonChecked,hWnd,IDC_CHECK3)
			mov bLoadProject,$invoke(IsDlgButtonChecked,hWnd,IDC_CHECK4)
			mov bLoadWords,$invoke(IsDlgButtonChecked,hWnd,IDC_CHECK5)
			invoke SaveConfig
			invoke IsDlgButtonChecked,hWnd,IDC_RADIO1
			.if eax == 0
				lea eax,dwCreated
				lea edx,hKey
				push eax
				push edx
				push 0
				push KEY_WRITE
				push 0
				push 0
				push 0
				invoke GetVersion
				shr eax,31
				mov edx,offset szNTStart
				.if ! zero?
					mov edx,offset sz9XStart
				.endif
				push edx
				invoke IsDlgButtonChecked,hWnd,IDC_RADIO2
				test eax,eax
				mov eax,HKEY_LOCAL_MACHINE
				.if ! zero?
					mov eax,HKEY_CURRENT_USER
				.endif
				push eax
				call RegCreateKeyEx
				.if eax == 0
					invoke lstrlen,offset szCommandLine
					invoke RegSetValueEx,hKey,offset szValueName,0,REG_SZ,offset szCommandLine,eax
					invoke RegCloseKey,hKey
				.endif
				jmp @F
			.endif
			invoke GetVersion
			shr eax,31
			mov edx,offset szNTStart
			.if ! zero?
				mov edx,offset sz9XStart
			.endif
			lea eax,hKey
			push eax
			push KEY_WRITE
			push 0
			push edx
			push HKEY_LOCAL_MACHINE
			invoke RegOpenKeyEx,HKEY_CURRENT_USER,edx,0,KEY_WRITE,addr hKey
			.if eax == 0
				invoke RegDeleteValue,hKey,offset szValueName
				invoke RegCloseKey,hKey
			.endif
			call RegOpenKeyEx
			test eax,eax
			jnz short @F
			invoke RegDeleteValue,hKey,offset szValueName
			invoke RegCloseKey,hKey
			jmp short @F
		.endif
		cmp eax,IDCANCEL
		jnz $default
@@:		invoke EndDialog,hWnd,wParam
		.break
	
	.case WM_INITDIALOG
		invoke LoadConfig
		invoke CheckDlgButton,hWnd,IDC_CHECK1,bLoadExe
		invoke CheckDlgButton,hWnd,IDC_CHECK2,bLoadUsed
		invoke CheckDlgButton,hWnd,IDC_CHECK3,bLoadUnused
		invoke CheckDlgButton,hWnd,IDC_CHECK4,bLoadProject
		invoke CheckDlgButton,hWnd,IDC_CHECK5,bLoadWords
		invoke SendDlgItemMessage,hWnd,IDC_UPDOWN1,UDM_SETRANGE,0,70000h
		mov eax,iIcon
		and eax,7
		invoke SendDlgItemMessage,hWnd,IDC_UPDOWN1,UDM_SETPOS,0,eax
		mov eax,iIcon
		and eax,7
		add eax,IDI_ICON0
		invoke LoadImage,hInstance,eax,IMAGE_ICON,0,0,0
		invoke SendDlgItemMessage,hWnd,IDC_IMAGE1,STM_SETIMAGE,IMAGE_ICON,eax
		invoke CheckRadioButton,hWnd,IDC_RADIO1,IDC_RADIO3,IDC_RADIO1
		invoke GetVersion
		mov edx,offset szNTStart
		shr eax,31
		.if ! zero?
			mov edx,offset sz9XStart
		.endif
		push edx
		invoke RegOpenKeyEx,HKEY_CURRENT_USER,edx,0,KEY_READ,addr hKey
		.if eax == 0
			invoke RegQueryValueEx,hKey,offset szValueName,0,addr dwCreated,0,0
			.if eax == 0
				invoke CheckRadioButton,hWnd,IDC_RADIO1,IDC_RADIO3,IDC_RADIO2
			.endif
			invoke RegCloseKey,hKey
		.else
			invoke GetDlgItem,hWnd,IDC_RADIO2
			invoke EnableWindow,eax,FALSE
		.endif
		pop edx
		invoke RegOpenKeyEx,HKEY_LOCAL_MACHINE,edx,0,KEY_READ,addr hKey
		.if eax == 0
			invoke RegQueryValueEx,hKey,offset szValueName,0,addr dwCreated,0,0
			.if eax == 0
				invoke CheckRadioButton,hWnd,IDC_RADIO1,IDC_RADIO3,IDC_RADIO3
			.endif
			invoke RegCloseKey,hKey
			.break
		.endif
		invoke GetDlgItem,hWnd,IDC_RADIO3
		invoke EnableWindow,eax,FALSE
		.break
	
	.default
		xor eax,eax
		ret
	
	.endswitch
	push TRUE
	pop eax
	ret

DlgProc endp

end DllEntryPoint
