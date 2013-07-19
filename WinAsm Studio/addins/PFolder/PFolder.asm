;DEBUG_BUILD equ 1		;Uncomment for debug builds

include PFolder.inc

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
GetWAAddInData proc lpFriendlyName:PTR BYTE, lpDescription:PTR BYTE

	; Copy the addin's name and description into the buffers
	; pointed to by lpFriendlyName and lpDescription.
	; Both strings must be ASCIIZ (255 chars max.)

	invoke lstrcpy,lpFriendlyName,offset szFriendlyName
	invoke lstrcpy,lpDescription,offset szDescription
	ret

GetWAAddInData endp

align DWORD
WAAddInLoad proc uses ebx pWinAsmHandles:PTR HANDLES, pWinAsmFeatures:PTR FEATURES
	local iMenuPos		:SDWORD
	local iItemPos		:SDWORD
	local iSeparatorPos	:SDWORD

	; When the addin is loaded, WinAsm will call this function.
	; Remember that addins can be loaded and unleaded at user's request any time.

	IFDEF DEBUG_BUILD
		PrintText "Loading AddIn."
	ENDIF

	; Initialize WAAddInLib.lib
	invoke InitializeAddIn,hInstance,pWinAsmHandles,pWinAsmFeatures,offset szAppName
	test eax,eax
	jz fail
	mov pIniFile,eax	; Keep the pointer to the addins INI filename if needed.

	; pWinAsmHandles is a pointer to the HANDLES structure.
	; pFeatures is a pointer to the FEATURES structure.
	push pWinAsmHandles
	pop pHandles

	; Make sure we're running a compatible version.
	invoke CheckWAVersion,3000
	test eax,eax
	jz fail

	; Load the settings.
	invoke GetPrivateProfileString,offset szAppName,offset szCaption,offset szDefCaption,
	 							   offset szMenuString,sizeof szMenuString,pIniFile
	invoke GetPrivateProfileInt,offset szAppName,offset szMenuPos,3,pIniFile
	mov iMenuPos,eax
	invoke GetPrivateProfileInt,offset szAppName,offset szItemPos,-1,pIniFile
	mov iItemPos,eax
	invoke GetPrivateProfileInt,offset szAppName,offset szSeparatorPos,-2,pIniFile
	mov iSeparatorPos,eax
	
	; Add the menu item.
	invoke AddMenuItemEx,offset szMenuString,iMenuPos,iItemPos,iSeparatorPos
	.if !eax || (!edx && (iSeparatorPos != -2))
fail:	dec eax		;return -1 to cancel loading this addin
		ret
	.endif
	mov ItemID,eax
	mov SeparatorID,edx
	
	; Hide the item if no project is loaded.
	mov edx,pWinAsmHandles
	invoke SendMessage,[edx].HANDLES.hMain,WAM_GETCURRENTPROJECTINFO,addr cpi,0
	.if !eax
		mov eax,pWinAsmHandles
		invoke EnableMenuItem,[eax].HANDLES.hMenu,ItemID,MF_BYCOMMAND or MF_GRAYED
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

	; Remove the menu item added in WAAddInLoad.
	mov edx,pHandles
	mov eax,[edx].HANDLES.hMenu
	push MF_BYCOMMAND
	push SeparatorID
	push eax
	invoke DeleteMenu,eax,ItemID,MF_BYCOMMAND
	call DeleteMenu

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
	.if eax == WAE_COMMANDFINISHED	;WinAsm just finished processing a WM_COMMAND message.
		mov eax,wParam
		mov edx,eax
		shr eax,16
		and edx,0FFFFh
		.if (eax == 0) || (eax == 1)	;0 for menu item or toolbar, 1 for accelerator.
			.if (edx == IDM_NEWPROJECT) || \
				(edx == IDM_OPENPROJECT) || \
				(edx == IDM_CLOSEPROJECT) || \
				(edx == WAM_OPENPROJECT) || \
				((edx >= 10021) && (edx <= 10026))
				IFDEF DEBUG_BUILD
					PrintText "A project may have been created, opened or closed."
				ENDIF
				
				; Enable or disable our menu item.
				invoke SendMessage,hWnd,WAM_GETCURRENTPROJECTINFO,addr cpi,0
				.if eax
					push MF_ENABLED
				.else
					push MF_GRAYED
				.endif
				push ItemID
				mov eax,pHandles
				push [eax].HANDLES.hMenu
				call EnableMenuItem
				xor eax,eax
				ret
				 
			.endif
		.endif
	.elseif eax == WM_COMMAND
		mov eax,wParam
		mov edx,eax
		shr eax,16
		and edx,0FFFFh
		.if (eax == 0) || (eax == 1)	;0 for menu item or toolbar, 1 for accelerator
			.if edx == ItemID			;You can also use the IDM_* equates here.
				IFDEF DEBUG_BUILD
					PrintText "Addin's menu item activated."
				ENDIF
				invoke SendMessage,hWnd,WAM_GETCURRENTPROJECTINFO,offset cpi,0
				.if eax && cpi.pszFullProjectName
					invoke lstrcpyn,offset szFolderName,cpi.pszFullProjectName,sizeof szFolderName
					invoke PathFindFileName,offset szFolderName
					.if eax
						mov byte ptr [eax],0
						invoke GetPrivateProfileInt,
						 		offset szAppName,offset szShowCmd,SW_SHOWMAXIMIZED,pIniFile
						.if (eax > 4) && (eax != 7)		;1-4 and 7 are legal
							mov eax,SW_SHOWMAXIMIZED	;4 by default
						.endif
						invoke ShellExecute,hWnd,NULL,offset szFolderName,NULL,NULL,eax
						.if !eax
							.data
							szCantShowFolder db "ERROR: Can't show the current project folder!",0
							.code
							invoke ClearOutputWindow
							invoke AppendOutputLine,offset szCantShowFolder,1
							mov eax,pHandles
							invoke ShowWindow,[eax].HANDLES.hOutParent,SW_SHOW
						.endif
					.endif
				.endif
				push TRUE
				pop eax
				ret
			.endif
		.endif
	.endif

	; Return 0 (FALSE) to allow other addins and WinAsm itself process this message.
	; Return 1 (TRUE) to... well, guess ;)
	xor eax,eax
	ret

FrameWindowProc endp

end DllEntryPoint
