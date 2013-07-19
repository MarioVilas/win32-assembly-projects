;DEBUG_BUILD equ TRUE	;Comment this out for final version.

include PackAddIn.inc

.code
align DWORD
DllEntryPoint proc hinstDLL:DWORD,fdwReason:DWORD,lpvReserved:DWORD

    .if fdwReason == DLL_PROCESS_ATTACH
        push hinstDLL
        pop hInst
    .endif
    xor eax,eax
    inc eax
    ret

DllEntryPoint endp

align DWORD
Add_Profiles proc uses ebx esi pProfiles:DWORD, iProfiles:DWORD
	
	mov esi,pProfiles
	mov ebx,iProfiles
	.repeat
		;Profile name
		invoke lstrcpy,offset szProfile,esi
		;IFDEF DEBUG_BUILD
		;	PrintString szProfileSection
		;ENDIF
		invoke lstrlen,esi
		add esi,eax
		inc esi
		;Command line
		invoke WritePrivateProfileString,offset szProfileSection,offset szCommandLine,
				esi,offset szINI
		invoke lstrlen,esi
		add esi,eax
		inc esi
		;List of extensions
		invoke WritePrivateProfileString,offset szProfileSection,offset szSupportedExtensions,
				offset szDefExt,offset szINI
		;List?
		invoke WritePrivateProfileString,offset szProfileSection,offset szUseListOfExtensions,
				offset sz0,offset szINI
		;Hide?
		invoke WritePrivateProfileString,offset szProfileSection,offset szTryToHideWindow,
				offset sz0,offset szINI
		;Wait?
		xor eax,eax
		lodsb
		add eax,eax
		add eax,offset sz0
		invoke WritePrivateProfileString,offset szProfileSection,offset szWaitForCompletion,
				eax,offset szINI
		;Quotes?
		invoke WritePrivateProfileString,offset szProfileSection,offset szUseQuotesForFile,
				offset sz1,offset szINI
		;Run?
		invoke WritePrivateProfileString,offset szProfileSection,offset szAutoRunAfterBuild,
				offset sz0,offset szINI
		dec ebx
	.until zero?
	ret
	
Add_Profiles endp

align DWORD
Updater_Copy proc pFile:DWORD,pSection:DWORD

	invoke GetPrivateProfileString,pSection,offset szCommandLine,offset szCmdLine,
									offset szCmdLine,sizeof szCmdLine,pFile
	invoke GetPrivateProfileInt,pSection,offset szHideOutput,FALSE,pFile
	and eax,1
	mov bHide,eax
	ret

Updater_Copy endp

align DWORD
Updater proc dwVersion:DWORD

	IFDEF DEBUG_BUILD
		PrintText "Updating config from old versions"
	ENDIF

	; Save addin version
	invoke WritePrivateProfileString,offset szPackAddIn,offset szAddInVersion,
										offset szThisVersion,offset szINI

	; Evaluate last executed addin version
	mov eax,dwVersion
	cmp eax,02000000h	;versions prior to 2.0.0.0
	jb upd0
	cmp eax,02000100h	;versions prior to 2.0.1.0
	jb upd1
	cmp eax,02000200h	;versions prior to 2.0.2.0
	jb upd2
	test eax,eax
	jnz quit

upd0:
	; Move 1.00 - 1.01 config data if found
	invoke Updater_Copy,offset szOldINI + 1,offset szUPXaddin
	invoke GetWindowsDirectory,offset buffer,sizeof buffer
	.if eax <= sizeof buffer
		invoke lstrcat,offset buffer,offset szOldINI
		invoke DeleteFile,offset buffer
	.endif

	; Move 1.02 config data if found
	invoke Updater_Copy,offset szINI,offset szUPXaddinWA
	invoke WritePrivateProfileSection,offset szUPXaddinWA,NULL,offset szINI

upd1:
	; Add default profiles (2.0.1.0 and higher)
	invoke Add_Profiles,offset Def_Profiles,DEF_PROFILES

upd2:
	; Add more defaults (2.0.2.0 and above)
	invoke Add_Profiles,offset Def_Profiles2,DEF_PROFILES2

	; Return
quit:
	ret

Updater endp

align DWORD
ReadBool proc pKey:DWORD,pData:DWORD

	mov eax,pData
	invoke GetPrivateProfileInt,offset szPackAddIn,pKey,dword ptr [eax],offset szINI
	mov edx,pData
	and eax,1
	mov [edx],eax
	ret

ReadBool endp

align DWORD
ReadConfig proc uses esi edi

	IFDEF DEBUG_BUILD
		PrintText "Reading config"
	ENDIF

	; Get addins INI filename
	invoke GetModuleFileName,NULL,offset szINI,MAX_PATH
	invoke lstrlen,offset szINI
	mov ecx,eax
	lea edi,[offset szINI + eax]
	mov al,'\'
	std
	repne scasb
	cld
	add edi,2
	mov esi,offset szAddinsINI
	mov ecx,sizeof szAddinsINI
	rep movsb

	; Set default config
	invoke lstrcpy,offset szCmdLine,offset szDefCmdLine
	invoke lstrcpy,offset szExt,offset szDefExt

	; Check if it's the first time the addin is loaded
	invoke GetPrivateProfileInt,offset szPackAddIn,offset szAddInVersion,0,offset szINI
	.if eax < ADDIN_VERSION
		invoke Updater,eax
	.endif
	
	;Load config
	invoke GetPrivateProfileString,offset szPackAddIn,offset szCommandLine,offset szCmdLine,
									offset szCmdLine,sizeof szCmdLine,offset szINI
	invoke GetPrivateProfileString,offset szPackAddIn,offset szSupportedExtensions,offset szExt,
									offset szExt,sizeof szExt,offset szINI
	invoke ReadBool,offset szUseListOfExtensions,offset bList
	invoke ReadBool,offset szTryToHideWindow,offset bHide
	invoke ReadBool,offset szWaitForCompletion,offset bWait
	invoke ReadBool,offset szUseQuotesForFile,offset bQuotes
	invoke ReadBool,offset szAutoRunAfterBuild,offset bAuto

    ; Return
    ret

ReadConfig endp

align DWORD
ReadProfile proc

	IFDEF DEBUG_BUILD
		PrintText "Reading profile"
	ENDIF

	; Get command line
	invoke GetDlgItemText,hDlg,IDC_EDIT1,offset buffer,sizeof buffer
	invoke GetPrivateProfileString,offset szProfileSection,offset szCommandLine,offset buffer,
									offset buffer,sizeof buffer,offset szINI
	invoke SetDlgItemText,hDlg,IDC_EDIT1,offset buffer

	; Get extensions list
	invoke GetDlgItemText,hDlg,IDC_EDIT2,offset buffer,sizeof buffer
	invoke GetPrivateProfileString,offset szProfileSection,offset szSupportedExtensions,offset buffer,
									offset buffer,sizeof buffer,offset szINI
	invoke SetDlgItemText,hDlg,IDC_EDIT2,offset buffer

	; Get boolean: UseListOfExtensions
	invoke IsDlgButtonChecked,hDlg,IDC_CHECK1
	and eax,1
	invoke GetPrivateProfileInt,offset szProfileSection,offset szUseListOfExtensions,eax,offset szINI
	and eax,1
	push eax
	invoke CheckDlgButton,hDlg,IDC_CHECK1,eax
	invoke GetDlgItem,hDlg,IDC_EDIT2
	push eax
	call EnableWindow

	; Get boolean: TryToHideWindow
	invoke IsDlgButtonChecked,hDlg,IDC_CHECK2
	and eax,1
	invoke GetPrivateProfileInt,offset szProfileSection,offset szTryToHideWindow,eax,offset szINI
	and eax,1
	invoke CheckDlgButton,hDlg,IDC_CHECK2,eax

	; Get boolean: WaitForCompletion
	invoke IsDlgButtonChecked,hDlg,IDC_CHECK3
	and eax,1
	invoke GetPrivateProfileInt,offset szProfileSection,offset szWaitForCompletion,eax,offset szINI
	and eax,1
	invoke CheckDlgButton,hDlg,IDC_CHECK3,eax

	; Get boolean: UseQuotesForFile
	invoke IsDlgButtonChecked,hDlg,IDC_CHECK4
	and eax,1
	invoke GetPrivateProfileInt,offset szProfileSection,offset szUseQuotesForFile,eax,offset szINI
	and eax,1
	invoke CheckDlgButton,hDlg,IDC_CHECK4,eax

	; Get boolean: AutoRunAfterBuild
	invoke IsDlgButtonChecked,hDlg,IDC_CHECK5
	and eax,1
	invoke GetPrivateProfileInt,offset szProfileSection,offset szAutoRunAfterBuild,eax,offset szINI
	and eax,1
	invoke CheckDlgButton,hDlg,IDC_CHECK5,eax

	; Return
	ret

ReadProfile endp

align DWORD
SaveBool proc pKey:DWORD,bData:DWORD

	mov eax,bData
	add eax,eax
	add eax,offset sz0
	invoke WritePrivateProfileString,offset szPackAddIn,pKey,eax,offset szINI
	ret

SaveBool endp

align DWORD
SaveConfig proc

	IFDEF DEBUG_BUILD
		PrintText "Saving config"
	ENDIF

	; Save addin version
	invoke WritePrivateProfileString,offset szPackAddIn,offset szAddInVersion,
										offset szThisVersion,offset szINI

	; Save command line to packer
	invoke WritePrivateProfileString,offset szPackAddIn,offset szCommandLine,
										offset szCmdLine,offset szINI

	; Save list of supported extensions
	invoke WritePrivateProfileString,offset szPackAddIn,offset szSupportedExtensions,
										offset szExt,offset szINI

	; Save options
	invoke SaveBool,offset szUseListOfExtensions,bList
	invoke SaveBool,offset szTryToHideWindow,bHide
	invoke SaveBool,offset szWaitForCompletion,bWait
	invoke SaveBool,offset szUseQuotesForFile,bQuotes
	invoke SaveBool,offset szAutoRunAfterBuild,bAuto

	; Return
	ret

SaveConfig endp

align DWORD
SaveProfile proc

	IFDEF DEBUG_BUILD
		PrintText "Saving profile"
	ENDIF

	; Save command line
	invoke GetDlgItemText,hDlg,IDC_EDIT1,offset buffer,sizeof buffer
	.if eax != 0
		invoke WritePrivateProfileString,offset szProfileSection,offset szCommandLine,offset buffer,offset szINI
	.endif

	; Save extensions list
	invoke GetDlgItemText,hDlg,IDC_EDIT2,offset buffer,sizeof buffer
	invoke WritePrivateProfileString,offset szProfileSection,offset szSupportedExtensions,offset buffer,offset szINI

	; Save boolean: UseListOfExtensions
	invoke IsDlgButtonChecked,hDlg,IDC_CHECK1
	and eax,1
	add eax,eax
	add eax,offset sz0
	invoke WritePrivateProfileString,offset szProfileSection,offset szUseListOfExtensions,eax,offset szINI

	; Save boolean: TryToHideWindow
	invoke IsDlgButtonChecked,hDlg,IDC_CHECK2
	and eax,1
	add eax,eax
	add eax,offset sz0
	invoke WritePrivateProfileString,offset szProfileSection,offset szTryToHideWindow,eax,offset szINI

	; Save boolean: WaitForCompletion
	invoke IsDlgButtonChecked,hDlg,IDC_CHECK3
	and eax,1
	add eax,eax
	add eax,offset sz0
	invoke WritePrivateProfileString,offset szProfileSection,offset szWaitForCompletion,eax,offset szINI

	; Save boolean: UseQuotesForFile
	invoke IsDlgButtonChecked,hDlg,IDC_CHECK4
	and eax,1
	add eax,eax
	add eax,offset sz0
	invoke WritePrivateProfileString,offset szProfileSection,offset szUseQuotesForFile,eax,offset szINI

	; Save boolean: AutoRunAfterBuild
	invoke IsDlgButtonChecked,hDlg,IDC_CHECK5
	and eax,1
	add eax,eax
	add eax,offset sz0
	invoke WritePrivateProfileString,offset szProfileSection,offset szAutoRunAfterBuild,eax,offset szINI

	; Return
	ret

SaveProfile endp

align DWORD
EnumProc proc hMDIChildWindow:DWORD,lParam:DWORD

	invoke GetWindowLong,hMDIChildWindow,0
	.if eax != NULL
		mov edx,[eax].CHILDDATA.TypeOfFile
		.if edx == 1		;asm file
			.if buffer == 0
				mov ecx,offset buffer
				jmp @F
			.endif
		.elseif edx == 5	;def file
			.if buffer2 == 0
				mov ecx,offset buffer2
@@:				lea edx,[eax].CHILDDATA.FileName
				invoke lstrcpy,ecx,edx
			.endif
		.endif
	.endif
	xor eax,eax
	.if (buffer == 0) || (buffer2 == 0)
		inc eax
	.endif
	ret

EnumProc endp

align DWORD
GetDef proc uses ebx edi
	local dwRetVal	:DWORD
	local hFile		:DWORD
	local pBase		:DWORD
	local dwSize	:DWORD
	local dwRead	:DWORD

	mov dwRetVal,0
	invoke CreateFile,offset buffer2,GENERIC_READ,FILE_SHARE_READ,NULL,
				OPEN_EXISTING,FILE_FLAG_SEQUENTIAL_SCAN,NULL
	inc eax
	.if ! zero?
		dec eax
		mov hFile,eax
		invoke GetFileSize,eax,NULL
		inc eax
		.if ! zero?
			inc eax
			push eax
			push LPTR
			sub eax,2
			mov dwSize,eax
			call LocalAlloc
			.if eax != NULL
				mov pBase,eax
				mov edi,pBase
				mov ebx,dwSize
				inc edi
				mov byte ptr [eax],9
				.repeat
					invoke ReadFile,hFile,edi,ebx,addr dwRead,NULL
					.break .if eax == NULL
					mov eax,dwRead
					add edi,eax
					sub ebx,eax
				.until zero?
				invoke CharLowerBuff,pBase,dwSize
				invoke InString,1,pBase,offset szlibrary
				.if eax != 0
					mov edi,pBase
					mov ecx,dwSize
					add edi,eax
					add edi,sizeof szlibrary - 2
					sub ecx,eax
					.repeat
						mov al,[edi]
						.if (al != 32) && (al != 9)
							mov dwRetVal,edi
							.if al == 34
								inc edi
								inc dwRetVal
								repne scasb
								.if zero?
									dec edi
								.endif
								dec edi
@@:								mov al,0
								stosb
							.else
								.repeat
									mov al,[edi]
									.break .if (al == 13) || (al == 10)
									inc edi
								.untilcxz
								jmp short @B
							.endif
							invoke lstrcpyn,offset buffer2,dwRetVal,sizeof buffer2 - sizeof szDLL + 1
							invoke lstrcat,offset buffer2,offset szDLL - 1
							jmp short @F
						.endif
						inc edi
						dec ecx
					.until zero?
				.endif
@@:				invoke LocalFree,pBase
			.endif
		.endif
		invoke CloseHandle,hFile
	.endif
	mov eax,dwRetVal
	ret

GetDef endp

align DWORD
LaunchPacker proc uses ebx esi edi
	local ptext	:DWORD
	local xcode	:DWORD
	local w32fd	:WIN32_FIND_DATA
	local pinfo	:PROCESS_INFORMATION

	IFDEF DEBUG_BUILD
		PrintText "Launching packer program"
	ENDIF

	; Get handles
	mov ebx,pHandles

	; Get project info
	invoke SendMessage,[ebx].HANDLES.hMain,WAM_GETCURRENTPROJECTINFO,addr cpi,0
	test eax,eax
	jz quit

	IFDEF DEBUG_BUILD
		PrintStringByAddr cpi.pszFullProjectName
	ENDIF

	; Get output filename
	mov eax,cpi.pszReleaseOUTCommand
	test eax,eax
	jz @F
	cmp byte ptr [eax],0
	.if zero?
@@:		mov cpi.pszReleaseOUTCommand,offset buffer
		mov buffer,0
		invoke SendMessage,[ebx].HANDLES.hMain,WAM_ENUMCURRENTPROJECTFILES,offset EnumProc,0

		IFDEF DEBUG_BUILD
			PrintString buffer
			PrintString buffer2
		ENDIF

		cmp buffer,0
		je quit
		;invoke GetPrivateProfileInt,offset szPROJECT,offset szType,0,cpi.pszFullProjectName
		mov eax,cpi.pProjectType
		mov eax,[eax]

		IFDEF DEBUG_BUILD
			PrintDec eax
		ENDIF

		dec eax
		.if zero?				;project type #1 (DLL)
			push offset szDLL
			mov al,'.'
			cmp buffer2,0
			je @F
			invoke GetDef
			.if eax != 0
				pop edx
				push offset buffer2
				mov al,'\'
				jmp @F
			.endif
			mov al,'.'
			jmp @F
		.endif
		test eax,1				;project types #0, #2 or #4 (EXE)
		jz quit					;(autodetect not supported for types #3 and #5)
		push offset szEXE
		mov al,'.'
@@:		mov edi,offset buffer
		push edi
		push eax
		invoke lstrlen,edi
		add edi,eax
		xchg ecx,eax
		pop eax
		std
		repne scasb
		cld
		jne quit
		mov byte ptr [edi + 2],0
		call lstrcat
	.endif

	IFDEF DEBUG_BUILD
		PrintStringByAddr cpi.pszReleaseOUTCommand
	ENDIF

	; Check if the extension is supported
	.if bList
		; Ensure that the strings are not null
		mov esi,offset szExt
		mov edi,cpi.pszReleaseOUTCommand
		cmp byte ptr [esi],0
		je quit
		cmp byte ptr [edi],0
		je quit
		; Go to the end of both strings
		invoke lstrlen,esi
		add esi,eax
		invoke lstrlen,edi
		add edi,eax
		; Case-insensitive compare
		mov ebx,edi
		add esi,1
		add edi,1
@@:		sub esi,1
		sub edi,1
		cmp esi,offset szExt
		jb @F
		cmp edi,cpi.pszReleaseOUTCommand
		jb found
		mov al,[esi]
		cmp al,';'
		je maybe
		cmp al,[edi]
		je @B
		or al,20h
		cmp al,[edi]
		je @B
		mov edi,ebx
		.repeat
			mov al,[esi]
			cmp al,';'
			je @B
			sub esi,1
			cmp esi,offset szExt
			jb quit
		.until FALSE
maybe:	cmp edi,ebx
		jne found
		jmp @B
@@:		cmp edi,ebx
		je quit
found:	mov ebx,pHandles
		IFDEF DEBUG_BUILD
			PrintText "The extension is supported"
		ENDIF
	.endif

	; Check if the file exists
	invoke FindFirstFile,cpi.pszReleaseOUTCommand,addr w32fd
	inc eax
	jz quit
	dec eax
	invoke FindClose,eax

	IFDEF DEBUG_BUILD
		PrintText "The file exists"
	ENDIF

	; Parse commandline
	push cpi.pszReleaseOUTCommand
	push offset buffer2
	invoke lstrcpy,offset buffer2,offset szCmdLine
	invoke lstrcat,offset buffer2,offset szSpace
	.if bQuotes
		invoke lstrcat,offset buffer2,offset szQuote
	.endif
	call lstrcat
	.if bQuotes
		invoke lstrcat,offset buffer2,offset szQuote
	.endif

	IFDEF DEBUG_BUILD
		PrintString buffer2
	ENDIF

	; Set status bar text
	invoke SendMessage,[ebx].HANDLES.hStatus,SB_SETTEXT,4,offset szPacking

	; Launch packer
	.if bHide
		or sinfo.dwFlags,STARTF_USESHOWWINDOW
	.else
		and sinfo.dwFlags,not STARTF_USESHOWWINDOW
	.endif
	invoke CreateProcess,NULL,offset buffer2,NULL,NULL,FALSE,0,NULL,NULL,addr sinfo,addr pinfo
	IFDEF DEBUG_BUILD
		.if eax == 0
			push eax
			PrintText "ERROR! Can't run packer"
			invoke GetLastError
			PrintHex EAX
			pop eax
		.endif
	ENDIF
	mov ptext,offset szNULL
	.if eax != 0
		.if bWait
			IFDEF DEBUG_BUILD
				PrintText "Waiting for packer program to finish"
			ENDIF
			invoke WaitForSingleObject,pinfo.hProcess,INFINITE
		.endif
		invoke GetExitCodeProcess,pinfo.hProcess,addr xcode
		.if !eax || xcode
			mov ptext,offset szPossibleError
			IFDEF DEBUG_BUILD
				PrintText "Possible error condition returned from packer program."
				PrintHex xcode
			ENDIF
		.endif
		invoke CloseHandle,pinfo.hThread
		invoke CloseHandle,pinfo.hProcess
	.endif

	; Clear status bar text
	invoke SendMessage,[ebx].HANDLES.hStatus,SB_SETTEXT,4,ptext

	; Return
	; (ebx may not equal pHandles here...)
quit:
	ret

LaunchPacker endp

align DWORD
DialogProc proc hWin:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD
	local isel	:DWORD
	local pstr	:DWORD
	local istr	:DWORD

	mov eax,uMsg
	.switch eax

	.case WM_COMMAND
		mov eax,wParam
		cmp eax,(CBN_EDITUPDATE shl 16) or IDC_COMBO1
		.if zero?						; User has changed the combo box text
			invoke SendMessage,lParam,CB_GETEDITSEL,NULL,NULL
			mov isel,eax
			invoke GetWindowText,lParam,offset szProfile,sizeof szProfile
			.break .if eax == 0
			;Filter out illegal characters
			push esi
			push edi
			mov esi,offset szProfile
			invoke lstrlen,esi
			xchg eax,ecx
			mov edi,esi
			.repeat
				lodsb
				.if (al != '=') && (al != ']') && (al != 13) && (al != 10)
					stosb
				.endif
			.untilcxz
			pop edi
			pop esi
			invoke SetWindowText,lParam,offset szProfile
			invoke SendMessage,lParam,CB_SETEDITSEL,0,isel
			.break
		.endif
		cmp eax,(CBN_SELENDOK shl 16) or IDC_COMBO1
		.if zero?						; Change profile
			IFDEF DEBUG_BUILD
				PrintText "Change profile"
			ENDIF
			mov szProfile,0
			invoke SendMessage,lParam,CB_GETCURSEL,0,0
			inc eax
			.break .if zero?
			dec eax
			push eax
			invoke SendMessage,lParam,CB_GETLBTEXTLEN,eax,0
			pop edx
			.break .if eax > sizeof szProfile
			mov szProfile,0
			invoke SendMessage,lParam,CB_GETLBTEXT,edx,offset szProfile
			.break .if szProfile == 0
			IFDEF DEBUG_BUILD
				PrintString szProfileSection
			ENDIF
			invoke ReadProfile
			.break
		.endif
		.if eax == IDC_CHECK1			; Enable / disable list of supported extensions
			invoke IsDlgButtonChecked,hWin,IDC_CHECK1
			and eax,1
			push eax
			invoke GetDlgItem,hWin,IDC_EDIT2
			push eax
			call EnableWindow
			.break
		.endif
		.if eax == IDC_BUTTON1			; Save profile
			IFDEF DEBUG_BUILD
				PrintText "Save profile"
			ENDIF
			invoke GetDlgItemText,hWin,IDC_COMBO1,offset szProfile,sizeof szProfile
			.break .if eax == 0
			invoke SaveProfile
			invoke SendDlgItemMessage,hWin,IDC_COMBO1,CB_ADDSTRING,0,offset szProfile
			.break
		.endif
		.if eax == IDC_BUTTON2			; Delete profile
			IFDEF DEBUG_BUILD
				PrintText "Delete profile"
			ENDIF
			invoke GetDlgItemText,hWin,IDC_COMBO1,offset szProfile,sizeof szProfile
			.break .if eax == 0
			invoke WritePrivateProfileSection,offset szProfileSection,NULL,offset szINI
			invoke SendDlgItemMessage,hWin,IDC_COMBO1,CB_GETCURSEL,0,0
			inc eax
			.break .if zero?
			dec eax
			invoke SendDlgItemMessage,hWin,IDC_COMBO1,CB_DELETESTRING,eax,0
			.break
		.endif
		.if eax == IDC_BUTTON3			; Browse for packer program
			IFDEF DEBUG_BUILD
				PrintText "Browse for packer program"
			ENDIF
			invoke GetDlgItemText,hWin,IDC_EDIT1,offset buffer,sizeof buffer
			invoke GetOpenFileName,addr ofn
			.break .if eax == 0
			invoke SetDlgItemText,hWin,IDC_EDIT1,offset buffer
			.break
		.endif
		.if eax == IDOK					; Keep new config
			IFDEF DEBUG_BUILD
				PrintText "Keep new config"
			ENDIF
			invoke GetDlgItemText,hWin,IDC_EDIT1,offset buffer,sizeof buffer
			.if eax == 0
				invoke MessageBeep,-1
				invoke GetDlgItem,hWin,IDC_EDIT1
				invoke SetFocus,eax
				.break
			.endif
			invoke lstrcpy,offset szCmdLine,offset buffer
			invoke GetDlgItemText,hWin,IDC_EDIT2,offset szExt,sizeof szExt
			invoke IsDlgButtonChecked,hWin,IDC_CHECK1
			and eax,1
			mov bList,eax
			invoke IsDlgButtonChecked,hWin,IDC_CHECK2
			and eax,1
			mov bHide,eax
			invoke IsDlgButtonChecked,hWin,IDC_CHECK3
			and eax,1
			mov bWait,eax
			invoke IsDlgButtonChecked,hWin,IDC_CHECK4
			and eax,1
			mov bQuotes,eax
			invoke IsDlgButtonChecked,hWin,IDC_CHECK5
			and eax,1
			mov bAuto,eax
			jmp @F
		.endif
		.break .if eax != IDCANCEL		; Close dialog
		IFDEF DEBUG_BUILD
			PrintText "Close dialog"
		ENDIF
@@:		invoke EndDialog,hWin,eax
		.break

	.case WM_INITDIALOG
		IFDEF DEBUG_BUILD
			PrintText "Initialize dialog"
		ENDIF
		push hWin
		pop hDlg
		invoke SendDlgItemMessage,hWin,IDC_COMBO1,EM_SETLIMITTEXT,sizeof szProfile,0
		invoke SendDlgItemMessage,hWin,IDC_EDIT1,EM_SETLIMITTEXT,sizeof szCmdLine,0
		invoke SendDlgItemMessage,hWin,IDC_EDIT2,EM_SETLIMITTEXT,sizeof szExt,0
		invoke SetDlgItemText,hWin,IDC_EDIT1,offset szCmdLine
		invoke SetDlgItemText,hWin,IDC_EDIT2,offset szExt
		invoke GetDlgItem,hWin,IDC_EDIT2
		invoke EnableWindow,eax,bList
		invoke CheckDlgButton,hWin,IDC_CHECK1,bList
		invoke CheckDlgButton,hWin,IDC_CHECK2,bHide
		invoke CheckDlgButton,hWin,IDC_CHECK3,bWait
		invoke CheckDlgButton,hWin,IDC_CHECK4,bQuotes
		invoke CheckDlgButton,hWin,IDC_CHECK5,bAuto
		invoke LoadImage,hInst,IDI_ICON1,IMAGE_ICON,0,0,0
		invoke SendDlgItemMessage,hWin,IDC_BUTTON1,BM_SETIMAGE,IMAGE_ICON,eax
		invoke LoadImage,hInst,IDI_ICON2,IMAGE_ICON,0,0,0
		invoke SendDlgItemMessage,hWin,IDC_BUTTON2,BM_SETIMAGE,IMAGE_ICON,eax
		invoke LoadImage,hInst,IDI_ICON3,IMAGE_ICON,0,0,0
		invoke SendDlgItemMessage,hWin,IDC_BUTTON3,BM_SETIMAGE,IMAGE_ICON,eax
		IFDEF DEBUG_BUILD
			PrintText "Read the profile names"
		ENDIF
		push esi
		invoke VirtualAlloc,NULL,32*1024,MEM_COMMIT,PAGE_READWRITE
		.if eax != 0
			mov esi,eax
			push MEM_RELEASE
			push 32*1024
			push eax
			invoke RtlZeroMemory,eax,32*1024
			invoke GetPrivateProfileSectionNames,esi,32*1024,offset szINI
			mov szProfile,0
			.repeat
				invoke lstrlen,esi
				.break .if eax == 0
				push eax
				invoke InString,1,esi,offset szProfileSection
				cmp eax,1
				jl @F
				lea eax,[esi + sizeof szProfileSection]
;				IFDEF DEBUG_BUILD
;					PrintStringByAddr eax
;				ENDIF
				invoke SendDlgItemMessage,hWin,IDC_COMBO1,CB_ADDSTRING,0,eax
@@:				pop ecx
				add esi,ecx
				inc esi
			.until FALSE
			call VirtualFree
		.endif
		pop esi
		push 1
		pop eax
		jmp short quit

	.endswitch
	xor eax,eax
quit:
	ret

DialogProc endp

align DWORD
GetWAAddInData proc lpFriendlyName:DWORD,lpDescription:DWORD

    invoke lstrcpy,lpFriendlyName,offset szName
    invoke lstrcpy,lpDescription,offset szDesc
    ret

GetWAAddInData endp

align DWORD
WAAddInLoad proc uses ebx pWinAsmHandles:DWORD,features:DWORD
	local bIncrement:DWORD

	IFDEF DEBUG_BUILD
		PrintText "Loading addin"
	ENDIF

	;Get WinAsm Studio handles
	mov ebx,pWinAsmHandles
	mov pHandles,ebx

	;Check WinAsm Studio version
	mov edx,features
	test edx,edx
	jz @F
	mov eax,[edx].FEATURES.Version
	IFDEF DEBUG_BUILD
		PrintHex EAX
	ENDIF
	.if eax < WINASM_VERSION
@@:		push [ebx].HANDLES.hMain
		pop mbp.hwndOwner
		push hInst
		pop mbp.hInstance
		invoke MessageBoxIndirect,offset mbp
		.if eax == 0
			invoke MessageBox,mbp.hwndOwner,offset szOldWinAsm,offset szError,MB_OK or MB_ICONERROR
		.endif
		push -1
		pop eax
		jmp quit2
	.endif

	;Read addins config file
	invoke ReadConfig

	;Set menu item in AddIns menu
	invoke SendMessage,[ebx].HANDLES.hClient,WM_MDIGETACTIVE,0,addr bIncrement
	mov edx,features
	mov eax,7					;7 for AddIns menu
	.if dword ptr [edx] >= 3023
		inc eax					;until 3.0.2.3 there was no "Dialog" menu
	.endif
	.if bIncrement				;+1 if MDI children are maximized
		inc eax
	.endIf
	mov AddinMenu,$invoke(GetSubMenu,[ebx].HANDLES.hMenu,eax)
	invoke GetMenuItemCount,eax
	dec eax
	.if zero?
		invoke AppendMenu,AddinMenu,MF_SEPARATOR,0,0
	.endif
	mov AddinID,$invoke(SendMessage,[ebx].HANDLES.hMain,WAM_GETNEXTMENUID,0,0)
	invoke AppendMenu,AddinMenu,MF_OWNERDRAW,eax,offset szMenuText1	;MF_OWNERDRAW req. by 1.0.1.6+

	;Set menu item in Make menu
	mov edx,features
	mov eax,5					;5 for Make menu
	.if dword ptr [edx] >= 3023
		inc eax					;until 3.0.2.3 there was no "Dialog" menu
	.endif
	.if bIncrement				;+1 if MDI children are maximized
		inc eax
	.endIf
	mov MakeMenu,$invoke(GetSubMenu,[ebx].HANDLES.hMenu,eax)
	mov MakeID,$invoke(SendMessage,[ebx].HANDLES.hMain,WAM_GETNEXTMENUID,0,0)
	invoke AppendMenu,MakeMenu,MF_OWNERDRAW,eax,offset szMenuText2	;MF_OWNERDRAW req. by 1.0.1.6+

	;Disable menu item in Make menu if no project is loaded
	invoke SendMessage,[ebx].HANDLES.hMain,WAM_GETCURRENTPROJECTINFO,addr cpi,0
	xor eax,MF_GRAYED	;MF_GRAYED == 1, MF_ENABLED == 0
	invoke EnableMenuItem,MakeMenu,MakeID,eax

	IFDEF DEBUG_BUILD
		PrintText "Addin loaded"
	ENDIF

	;Return NULL
quit:
	xor eax,eax
quit2:
	ret

WAAddInLoad endp

align DWORD
WAAddInUnload proc

	IFDEF DEBUG_BUILD
		PrintText "Unloading addin"
	ENDIF

	;Close popup dialog
	mov eax,hDlg
	.if eax != 0
		invoke SendMessage,eax,WM_COMMAND,IDCANCEL,0
	.endif

	;Remove menu item from Addins menu
	invoke GetMenuItemCount,AddinMenu
	.if eax == 3
		invoke DeleteMenu,AddinMenu,1,MF_BYPOSITION
	.endif
	invoke DeleteMenu,AddinMenu,AddinID,MF_BYCOMMAND

	;Remove menu item from Make menu
	invoke DeleteMenu,MakeMenu,MakeID,MF_BYCOMMAND

	;Save config
	invoke SaveConfig

	IFDEF DEBUG_BUILD
		PrintText "Addin unloaded"
	ENDIF

	;Return NULL
	xor eax,eax
	ret

WAAddInUnload endp

align DWORD
FrameWindowProc proc hWin:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD

	mov edx,uMsg
	.if edx == WM_COMMAND
		mov ecx,wParam
		and ecx,not 10000h
		.switch ecx

		.case AddinID
			IFDEF DEBUG_BUILD
				PrintText "Ready to open config dialog box"
			ENDIF
			invoke DialogBoxParam,hInst,IDD_DIALOG1,hWin,offset DialogProc,eax
			IFDEF DEBUG_BUILD
				PrintText "Config dialog box is closed"
			ENDIF
finish:		push 1
			pop eax
			jmp quit

		.case MakeID
launchme:	IFDEF DEBUG_BUILD
				PrintText "Ready to launch packer program"
			ENDIF
			invoke LaunchPacker
			IFDEF DEBUG_BUILD
				PrintText "Returning from packer program"
			ENDIF
			jmp finish

		.endswitch
	.elseif edx == WAE_COMMANDFINISHED
		mov ecx,wParam
		and ecx,not 10000h
		.if bAuto
			cmp ecx,IDM_MAKE_LINK
			je launchme
			cmp ecx,IDM_MAKE_GO
			je launchme
		.endif
		.if (ecx == IDM_NEWPROJECT) || \
			(ecx == IDM_OPENPROJECT) || \
			(ecx == IDM_CLOSEPROJECT) || \
			(ecx == WAM_OPENPROJECT) || \
			((ecx >= 10021) && (ecx <= 10026))
			IFDEF DEBUG_BUILD
				PrintText "Project changed"
			ENDIF
			mov eax,pHandles
			invoke SendMessage,[eax].HANDLES.hMain,WAM_GETCURRENTPROJECTINFO,addr cpi,0
			xor eax,MF_GRAYED	;MF_GRAYED == 1, MF_ENABLED == 0
			invoke EnableMenuItem,MakeMenu,MakeID,eax
		.endif
	.endif
	xor eax,eax
quit:
	ret

FrameWindowProc endp

end DllEntryPoint
