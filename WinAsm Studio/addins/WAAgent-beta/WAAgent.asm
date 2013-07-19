;DEBUG_BUILD equ 1		;Uncomment for debug builds

include macros.inc

AppModel .386

include \masm32\include\WINDOWS.INC
include \WinAsm\Inc\WAAddIn.inc
include imagehlp.inc

incl kernel32,user32,gdi32,comctl32,comdlg32,shell32,advapi32,ole32,oleaut32,wininet

IFDEF DEBUG_BUILD
	incl debug,masm32	;VKim's debug library
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
LoadConfig proc uses esi edi

	mov esi,offset xKeys
	mov edi,offset xValues
	.repeat
		invoke GetPrivateProfileInt,offset szAppName,esi,0,offset szIniPath
		mov [edi],eax
		invoke lstrlen,esi
		add eax,1
		add edi,4
		add esi,eax
	.until edi >= offset xValues_end
	invoke GetPrivateProfileString,offset szAppName,offset szUpdatesFolderURL,
									offset szDefFolderURL,offset szFolderURL,
									sizeof szFolderURL,offset szIniPath
	invoke GetPrivateProfileStruct,offset szAppName,offset szLastCheck,offset qwLastCheck,
									sizeof qwLastCheck,offset szIniPath
	invoke GetPrivateProfileStruct,offset szAppName,offset szNextCheck,offset qwNextCheck,
									sizeof qwNextCheck,offset szIniPath
	invoke GetPrivateProfileStruct,offset szAppName,offset szFolderLastModified,offset qwFolderDate,
									sizeof qwFolderDate,offset szIniPath
	ret

LoadConfig endp

align DWORD
DeleteObsoleteKeys proc uses esi

	mov esi,offset xObsolete
	.repeat
		lodsd
		invoke WritePrivateProfileString,offset szAppName,eax,NULL,offset szIniPath
	.until esi >= offset xObsolete_end
	ret

DeleteObsoleteKeys endp

align DWORD
SaveDates proc

	invoke WritePrivateProfileStruct,offset szAppName,offset szLastCheck,offset qwLastCheck,
									sizeof qwLastCheck,offset szIniPath
	invoke WritePrivateProfileStruct,offset szAppName,offset szNextCheck,offset qwNextCheck,
									sizeof qwNextCheck,offset szIniPath
	ret

SaveDates endp

align DWORD
SaveConfig proc uses esi edi

	mov esi,offset xKeys
	mov edi,offset xValues
	.repeat
		invoke wsprintf,offset buffer,offset szFmtInt,dword ptr [edi]
		invoke WritePrivateProfileString,offset szAppName,esi,offset buffer,offset szIniPath
		invoke lstrlen,esi
		add eax,1
		add edi,4
		add esi,eax
	.until edi >= offset xValues_end
	invoke WritePrivateProfileString,offset szAppName,offset szUpdatesFolderURL,
									offset szFolderURL,offset szIniPath
	invoke SaveDates
	invoke DeleteObsoleteKeys
	ret

SaveConfig endp

align DWORD
CanUpdate proc hWnd:HWND

	mov eax,dword ptr qwLastCheck[0]
	or eax,dword ptr qwLastCheck[4]
	jz short @F
	mov eax,dword ptr qwNextCheck[0]
	or eax,dword ptr qwNextCheck[4]
	jz short @F
	mov eax,dword ptr qwLastCheck[0]
	mov edx,dword ptr qwLastCheck[4]
	cmp eax,dword ptr qwNextCheck[0]
	jne short @1
	cmp edx,dword ptr qwNextCheck[4]
	jne short @1
@@:	push FALSE
	push FALSE
	jmp short @2
@1:	push TRUE
	push TRUE
@2:	invoke GetDlgItem,hWnd,IDC_CHECK7
	push eax
	call EnableWindow
	invoke GetDlgItem,hWnd,IDC_CHECK8
	push eax
	call EnableWindow
	ret

CanUpdate endp

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
	invoke lstrcpy,offset szCommandOnly,offset szCommandLine
	invoke lstrcat,offset szCommandLine,offset szSpace
	invoke lstrcat,offset szCommandLine,offset szDllPath
	invoke lstrcat,offset szCommandLine,offset szCmd2
	invoke lstrcpy,offset szParamOnly,offset szDllPath
	invoke lstrcat,offset szParamOnly,offset szCmd2

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
			push eax
			push IMAGE_ICON
			push STM_SETIMAGE
			push IDC_IMAGE1
			push hWnd
			invoke SendDlgItemMessage,hWnd,IDC_IMAGE1,STM_GETIMAGE,IMAGE_ICON,0
			.if eax
				invoke DestroyIcon,eax
			.endif
			call SendDlgItemMessage
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
		.if eax == IDC_BUTTON1
			invoke DialogBoxParam,hInstance,IDD_DIALOG2,hWnd,offset DlgProc2,0
			invoke CanUpdate,hWnd
			.break
		.endif
		.if eax == IDOK
;			invoke SendDlgItemMessage,hWnd,IDC_UPDOWN1,UDM_GETPOS,0,0
;			and eax,7
;			mov iIcon,eax
			push ebx
			push esi
			mov ebx,IDC_CHECK1
			mov esi,offset xBooleans
			.repeat
				invoke IsDlgButtonChecked,hWnd,ebx
				and eax,BST_CHECKED
				mov [esi],eax
				add ebx,1
				add esi,4
			.until esi >= offset xValues_end
			pop esi
			pop ebx
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
					mov eax,nid.hwnd
					.if eax == 0
						invoke FindWindow,offset szWAA_Msg,offset szCaption
						.if eax == 0
							invoke ShellExecute,0,0,offset szCommandOnly,offset szParamOnly,0,0
							jmp @F
						.endif
					.endif
					invoke SendMessage,eax,WM_USER+101h,0,0
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
		invoke CanUpdate,hWnd
		push ebx
		push esi
		mov ebx,IDC_CHECK1
		mov esi,offset xBooleans
		.repeat
			mov eax,[esi]
			and eax,BST_CHECKED
			invoke CheckDlgButton,hWnd,ebx,eax
			add ebx,1
			add esi,4
		.until esi >= offset xValues_end
		pop esi
		pop ebx
		invoke SendDlgItemMessage,hWnd,IDC_UPDOWN1,UDM_SETRANGE,0,70000h
		mov eax,iIcon
		and eax,7
		invoke SendDlgItemMessage,hWnd,IDC_UPDOWN1,UDM_SETPOS,0,eax
		invoke SendDlgItemMessage,hWnd,IDC_IMAGE1,STM_GETIMAGE,IMAGE_ICON,0
		.if eax
			invoke DestroyIcon,eax
		.endif
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
		invoke RegOpenKeyEx,HKEY_CURRENT_USER,edx,0,KEY_READ or KEY_WRITE,addr hKey
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
		invoke RegOpenKeyEx,HKEY_LOCAL_MACHINE,edx,0,KEY_READ or KEY_WRITE,addr hKey
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
	
	.case WM_DESTROY
		invoke SendDlgItemMessage,hWnd,IDC_IMAGE1,STM_GETIMAGE,IMAGE_ICON,0
		.if eax
			invoke DestroyIcon,eax
		.endif
	
	.default
		xor eax,eax
		ret
	
	.endswitch
	push TRUE
	pop eax
	ret

DlgProc endp

align DWORD
DlgProc2 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local stime	:SYSTEMTIME

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
		mov ecx,500
		imul ecx
		.if ! sign?
			invoke SetDlgItemInt,hWnd,IDC_EDIT1,eax,FALSE
			push FALSE
		.else
			push TRUE
		.endif
		push DWL_MSGRESULT
		push hWnd
		call SetWindowLong
		.break
	
	.case WM_COMMAND
		mov eax,wParam
		.if eax == IDOK
			mov dword ptr stime[0],0
			mov dword ptr stime[4],0
			invoke SendDlgItemMessage,hWnd,IDC_DATE1,DTM_GETSYSTEMTIME,0,addr stime
			invoke SystemTimeToFileTime,addr stime,offset qwLastCheck
			mov dword ptr stime[0],0
			mov dword ptr stime[4],0
			invoke SendDlgItemMessage,hWnd,IDC_DATE2,DTM_GETSYSTEMTIME,0,addr stime
			invoke SystemTimeToFileTime,addr stime,offset qwNextCheck
			invoke GetDlgItemText,hWnd,IDC_EDIT2,offset szFolderURL,sizeof szFolderURL
			push eax
			invoke GetDlgItemInt,hWnd,IDC_EDIT1,addr [esp + 4],FALSE
			pop edx
			.break .if edx == FALSE
			.if eax < 1000
				mov eax,1000
			.endif
			mov dwTimer,eax
			jmp short @F
		.endif
		cmp eax,IDCANCEL
		jnz $default
@@:		invoke EndDialog,hWnd,wParam
		.break
	
	.case WM_INITDIALOG
		invoke SendDlgItemMessage,hWnd,IDC_UPDOWN1,UDM_SETRANGE,0,UD_MAXVAL
		push 500
		fild dwTimer
		fild dword ptr [esp]
		fdivp st(1),st(0)
		fistp dword ptr [esp]
		push 0
		push UDM_SETPOS
		push IDC_UPDOWN1
		push hWnd
		fwait
		call SendDlgItemMessage
		.if (qwLastCheck.dwLowDateTime != 0) && (qwLastCheck.dwHighDateTime != 0)
			invoke FileTimeToSystemTime,offset qwLastCheck,addr stime
			invoke SendDlgItemMessage,hWnd,IDC_DATE1,DTM_SETSYSTEMTIME,GDT_VALID,addr stime
		.endif
		.if (qwNextCheck.dwLowDateTime != 0) && (qwNextCheck.dwHighDateTime != 0)
			invoke FileTimeToSystemTime,offset qwNextCheck,addr stime
			invoke SendDlgItemMessage,hWnd,IDC_DATE2,DTM_SETSYSTEMTIME,GDT_VALID,addr stime
		.endif
		invoke SendDlgItemMessage,hWnd,IDC_EDIT1,EM_SETLIMITTEXT,8,0
		invoke SendDlgItemMessage,hWnd,IDC_EDIT2,EM_SETLIMITTEXT,sizeof szFolderURL,0
		invoke SetDlgItemInt,hWnd,IDC_EDIT1,dwTimer,FALSE
		invoke SetDlgItemText,hWnd,IDC_EDIT2,offset szFolderURL
		.break
	
	.default
		xor eax,eax
		ret
	
	.endswitch
	push TRUE
	pop eax
	ret

DlgProc2 endp

end DllEntryPoint
