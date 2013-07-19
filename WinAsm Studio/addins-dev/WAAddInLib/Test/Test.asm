;DEBUG_BUILD equ 1		; Comment out this line for release builds

.386
.model flat,stdcall
option casemap:none

include windows.inc

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

include ..\WAAddIn.inc
include ..\WAAddInLib.inc
includelib ..\WAAddInLib.lib

.data
hInstance	dd ?	;DLL instance handle
pHandles	dd ?	;Pointer to HANDLES structure
pFeatures	dd ?	;Pointer to FEATURES structure
pIniFile	dd ?	;Pointer to the addins INI filename
hDocking	dd ?	;Handle of the docking window
AddinID		dd ?	;ID of the menu item under the "Add-Ins" submenu
AboutID		dd ?	;ID of the menu item under the "Help" submenu
ViewID		dd ?	;ID of the menu item under the "View" submenu
ProjectID	dd ?	;ID of the menu item under the "Project" submenu
OneMoreID	dd ?	;ID of the last menu item sample
SeparatorID	dd ?	;ID of the separator above the aforementioned item

; Sample keyboard accelerator
xAccel		ACCELERATOR < FVIRTKEY, VK_F5, 0 >	;fVirt, key, cmd

; Sample docking window config
xDocking	DOCKINGDATA < offset szAppName, NODOCK, <100,100,100,100>, 100,100,100,100 >

szAddinItem		db "Test add-in manipulation",0			;Caption of the menu item under the "Add-Ins" submenu
szAboutItem		db "About Test...",0					;Caption of the menu item under the "Help" submenu
szViewItem		db "Show/hide test docking window",0	;Caption of the menu item under the "View" submenu
szProjectItem	db "Test project item",0				;Caption of the menu item under the "Project" submenu
szOneMoreItem	db "Test CodeHi in Output window",0		;Caption of the last menu item sample

szFriendlyName	db "Test Add-In for WAAddInLib.lib",0		;Friendly add-in name
szDescription	db "It doesn't really do anything...",13,10	;Add-in description
	 			db "Just take a look at the source ;)",0

szAppName		db "Test Add-In",0		;Section in the addins INI file
szWindowPos		db "WindowPos",0		;Key for the docking window position
szWindowStyle	db "WindowStyle",0		;Key for the docking window style

.code
align DWORD
DllEntryPoint proc hinstDLL:HINSTANCE, fdwReason:DWORD, lpvReserved:LPVOID
	
	; DLL entry point. LEAVE IT AS IT IS. Put initialization code in WAAddInLoad.
	
	.if fdwReason == DLL_PROCESS_ATTACH
		
		push hinstDLL	; You can comment out this two lines if 
		pop hInstance	; you don't use the DLL instance handle
		
		; Comment out this line if you have multithreaded code
;		invoke DisableThreadLibraryCalls,hinstDLL
		
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
	; Remember that addins can be loaded and unloaded at user's request any time.
	
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
	invoke CheckWAVersion,3025	;For example, version 3.0.1.4 is 3014 (decimal).
	.if !eax
		dec eax		;return -1 to cancel loading this addin
		ret
	.endif
	
	; You can load your addin's config here.
;	invoke GetPrivateProfileString,offset szAppName,offset szKeyName,offset szDefault,
;	 							   offset szBuffer,sizeof szBuffer,pIniFile
	
	; You can create a docking window here.
	invoke CreateDockingWindow,offset xDocking,
		WS_VISIBLE or WS_CLIPCHILDREN or WS_CLIPSIBLINGS or STYLE_TWOLINESTITLE,
		offset szWindowPos,offset szWindowStyle
	mov hDocking,eax
	
	; You'll need to create a child window (or dialog) of the docking window here...
;	invoke CreateDialogParam,hInstance,IDD_DLG1000,hDocking,offset DlgProc,0
;	mov hChild,eax
	
	; You can add a menu item for your addin here.
	invoke GetWASubMenu,11	;Help submenu
	invoke AddMenuItem,eax,offset szAboutItem,-1
	mov AboutID,eax
	; A sample "Add-Ins" submenu item
	invoke NewAddinMenuItem,offset szAddinItem
	mov AddinID,eax
	; A sample "View" submenu item
	invoke IsWindowVisible,hDocking
	invoke NewViewMenuItem,offset szViewItem,eax
	mov ViewID,eax
	; A sample "Project" submenu item
	invoke NewProjectMenuItem,offset szProjectItem,-1
	mov ProjectID,eax
	; One last sample...
	invoke AddMenuItemEx,offset szOneMoreItem,8,-1,-1
	mov OneMoreID,eax
	mov SeparatorID,edx
	
	; You can add an accelerator for your menu item here.
	; In this sample I choose not to add it if another addin disabled all the accelerators.
	mov edx,pHandles
	.if [edx].HANDLES.phAcceleratorTable != NULL
		mov eax,ViewID
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
WAAddInUnload proc uses ebx
	
	; When the addin is unloaded, WinAsm will call this function.
	
	IFDEF DEBUG_BUILD
		PrintText "Unloading AddIn."
	ENDIF
	
;	 			<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
;	INT 3		<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
;	 			<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	
	; You can save your addin's config here.
;	invoke WritePrivateProfileString,offset szAppName,offset szKeyName,
;	 								 offset szBuffer,pIniFile
	
	; You must remove the menu item(s) added in WAAddInLoad.
	invoke RemoveAddinMenuItem,AddinID				; Add-Ins submenu (fixes separator)
	invoke RemoveViewMenuItem,ViewID				; View submenu (fixes separator)
	mov eax,pHandles								; The rest...
	mov ebx,[eax].HANDLES.hMenu
	invoke DeleteMenu,ebx,AboutID,MF_BYCOMMAND
	invoke DeleteMenu,ebx,ProjectID,MF_BYCOMMAND
	invoke DeleteMenu,ebx,OneMoreID,MF_BYCOMMAND
	invoke DeleteMenu,ebx,SeparatorID,MF_BYCOMMAND	; Don't forget the separator
	
	; You must remove the accelerator(s) added in WAAddInLoad.
	invoke RemoveAccelerator,offset xAccel
	
	; You must destroy the docking window(s) created in WAAddInLoad.
	invoke DestroyDockingWindow,hDocking,offset xDocking,offset szWindowPos,offset szWindowStyle
	
	IFDEF DEBUG_BUILD
		PrintText "Unloaded."
	ENDIF
	
	; The return value is ignored by WinAsm.
	ret
	
WAAddInUnload endp

align DWORD
FrameWindowProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local cpi:CURRENTPROJECTINFO
	
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
			.if edx == AddinID
				IFDEF DEBUG_BUILD
					PrintText "Addin's menu item activated."
				ENDIF
				
				; Just for testing purposes, show a list of add-ins,
				; load those unloaded and unload those loaded.
				.data
					hFind dd ?
					bLoaded dd ?
					bInstalled dd ?
					szName db 256 dup (?)
					szDesc db 256 dup (?)
					w32fd WIN32_FIND_DATA <>
					szInstalled db "Auto loads on startup.",0
					szNotInstalled db "Must be loaded by the user.",0
				.code
				invoke ClearOutputWindow
				invoke FindFirstAddIn,	offset w32fd,
					 					offset szName,offset szDesc,
					 					offset bLoaded,offset bInstalled
				.if eax != INVALID_HANDLE_VALUE
					mov hFind,eax
					.repeat
						mov eax,bLoaded
						and eax,1
						add eax,1
						invoke AppendOutputLine,addr w32fd.cFileName,eax
						invoke AppendOutputLine,offset szName,0
						invoke AppendOutputLine,offset szDesc,0
						.if bInstalled
							mov eax,offset szInstalled
						.else
							mov eax,offset szNotInstalled
						.endif
						invoke AppendOutputLine,eax,0
						
						; --- comment out this part to just enumerate the add-ins ---
						.if bLoaded
							invoke GetModuleHandle,addr w32fd.cFileName
							invoke UnloadAddIn,eax
						.else
							invoke LoadAddIn,addr w32fd.cFileName
						.endif
						; --- comment out this part to just enumerate the add-ins ---
						
						invoke FindNextAddIn,	hFind,offset w32fd,
						 						offset szName,offset szDesc,
						 						offset bLoaded,offset bInstalled
					.until !eax
					invoke FindAddInClose,hFind
				.endif
				push 1
				pop eax
				ret
				
			.endif
			.if edx == ProjectID
				IFDEF DEBUG_BUILD
					PrintText "Addin's project item activated."
				ENDIF
				
				; Ignore when no project is loaded.
				invoke SendMessage,hWnd,WAM_GETCURRENTPROJECTINFO,addr cpi,0
				.if eax
					
					; Let's notify the user that the item was selected...
					invoke MessageBox,	hWnd,
					 					offset szProjectItem,offset szAppName,
					 					MB_OK or MB_ICONINFORMATION
					
				.endif
				push 1
				pop eax
				ret
				
			.endif
			.if edx == AboutID
				IFDEF DEBUG_BUILD
					PrintText "Addin's about item activated."
				ENDIF
				
				; Show the add-in's about box here...
				.data
					szAboutCaption	db "About the Test add-in",0
					szAuthorsUrl	db "http://code4u.net/waforum",0
				.code
				invoke AddInAboutBox,offset szAboutCaption,offset szAuthorsUrl,NULL
				push 1
				pop eax
				ret
				
			.endif
			.if edx == ViewID
				IFDEF DEBUG_BUILD
					PrintText "Addin's view item activated."
				ENDIF
				
				; Show or hide our sample docking window...
				invoke GetWASubMenu,2
				push eax
				invoke GetMenuState,eax,ViewID,MF_BYCOMMAND
				pop edx
				and eax,MF_CHECKED
				xor eax,MF_CHECKED
				push eax
				invoke CheckMenuItem,edx,ViewID,eax
				pop eax
				.if eax
					mov eax,SW_SHOW
				.else
					mov eax,SW_HIDE
				.endif
				invoke ShowWindow,hDocking,eax
				push 1
				pop eax
				ret
				
			.endif
			.if edx == OneMoreID
				IFDEF DEBUG_BUILD
					PrintText "Addin's tools item activated."
				ENDIF
				
				; Just for testing purposes, we'll manipulate the output window.
				mov eax,pHandles
				.if eax
					push ebx
					mov ebx,[eax].HANDLES.hOut
					.if ebx
						
						; First, test clearing the output window
						invoke ClearOutputWindow
						
						; Now, test the warning messages
						.data
							szWarn0 db "This is a normal text line.",0
							szWarn1 db "This line has a red background.",0
							szWarn2 db "This line has a green background.",0
						.code
						invoke AppendOutputLine,offset szWarn0,0
						invoke AppendOutputLine,offset szWarn1,1
						invoke AppendOutputLine,offset szWarn2,2
						
						; Finally, try out the CodeHi manipulation functions
						.data
							szTextA db "This is an appended text, with no trailing CR/LF... ",0
							szTextB db "This is an appended line of text.",13,10,0
							szTextC db "This line of text was inserted.",0
						.code
						invoke CHAppendText,ebx,offset szTextA
						invoke CHAppendText,ebx,offset szTextB
						invoke CHInsertLine,ebx,offset szTextC,3	;line nr. is zero based
						
					.endif
					pop ebx
				.endif
				push 1
				pop eax
				ret
				
			.endif
		.endif
	.elseif eax == WAE_COMMANDFINISHED	;WinAsm just finished processing a WM_COMMAND message.
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
				
				; Enable or disable our sample Project item...
				invoke SendMessage,hWnd,WAM_GETCURRENTPROJECTINFO,addr cpi,0
				.if eax
					push MF_ENABLED
				.else
					push MF_GRAYED
				.endif
				push ProjectID
				invoke GetWASubMenu,3
				push eax
				call EnableMenuItem
				xor eax,eax
				ret
				 
			.endif
		.endif
	.endif
	
	; Return 0 (FALSE) to allow other addins and WinAsm itself process this message.
	; Return 1 (TRUE) to... well, guess ;)
	xor eax,eax
	ret
	
FrameWindowProc endp

align DWORD
ChildWindowProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
	; This procedure gets all messages for every MDI child window.
	; This procedure is optional. Make sure to add it to the .def file if you want to use it!
	
	; Put your code here...
	
	
	; Return 0 (FALSE) to allow other addins and WinAsm itself process this message.
	; Return 1 (TRUE) to... well, guess ;)
	xor eax,eax
	ret
	
ChildWindowProc endp

align DWORD
ProjectExplorerProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
	; This procedure gets all messages for the Project Explorer window.
	; This procedure is optional. Make sure to add it to the .def file if you want to use it!
	
	
	; Put your code here...
	
	
	; Return 0 (FALSE) to allow other addins and WinAsm itself process this message.
	; Return 1 (TRUE) to... well, guess ;)
	xor eax,eax
	ret
	
ProjectExplorerProc endp

align DWORD
OutWindowProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
	; This procedure gets all messages for the Output window.
	; This procedure is optional. Make sure to add it to the .def file if you want to use it!
	
	
	; Put your code here...
	
	
	; Return 0 (FALSE) to allow other addins and WinAsm itself process this message.
	; Return 1 (TRUE) to... well, guess ;)
	xor eax,eax
	ret
	
OutWindowProc endp

end DllEntryPoint
