;DEBUG_BUILD equ 1		; Comment out this line for release builds

.386
.model flat,stdcall
option casemap:none

include windows.inc
include WAAddIn.inc

include kernel32.inc
include user32.inc
include shlwapi.inc
include shell32.inc
include comctl32.inc
include comdlg32.inc
includelib kernel32.lib
includelib user32.lib
includelib shlwapi.lib
includelib shell32.lib
includelib comctl32.lib
includelib comdlg32.lib

include masm32.inc
includelib masm32.lib

IFDEF DEBUG_BUILD
	include debug.inc
	includelib debug.lib
ENDIF

include WAAddInLib.inc
includelib WAAddInLib.lib

IFNDEF TPM_HORPOSANIMATION
	TPM_HORPOSANIMATION equ 400h
ENDIF
IFNDEF TPM_VERPOSANIMATION
	TPM_VERPOSANIMATION equ 1000h
ENDIF
IFNDEF TBSTYLE_EX_HIDECLIPPEDBUTTONS
	TBSTYLE_EX_HIDECLIPPEDBUTTONS equ 10h
ENDIF

DllEntryPoint		proto hinstDLL:HINSTANCE, fdwReason:DWORD, lpvReserved:LPVOID

GetWAAddInData		proto lpFriendlyName:PTR BYTE, lpDescription:PTR BYTE
WAAddInLoad			proto pWinAsmHandles:PTR HANDLES, pWinAsmFeatures:PTR FEATURES
WAAddInUnload		proto
WAAddInConfig		proto pWinAsmHandles:PTR HANDLES, pWinAsmFeatures:PTR FEATURES
FrameWindowProc		proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

SaveColumnWidth		proto hCtrl:HWND, iCol:DWORD
LoadColumnWidth		proto iCol:DWORD, pCol:PTR LVCOLUMN
ResizeDockingChild	proto
ResizeControls		proto
EnableButtons		proto bEnabled:BOOL
SetListViewExStyles	proto
RefreshList			proto
LoadSelected		proto
UnloadSelected		proto
ToogleSelected		proto
InstallSelected		proto dwAction:DWORD
RemoveSelected		proto
IniToCheckBox		proto hWnd:HWND, dwID:DWORD, pKey:PTR BYTE, bDefault:BOOL
CheckBoxToIni		proto hWnd:HWND, dwID:DWORD, pKey:PTR BYTE
ReadIniBool			proto pKey:PTR BYTE, bDefault:BOOL

FolderNotifyThread	proto lParam:LPARAM
DockingProc			proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
DlgProc				proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
ConfigProc			proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

IDI_ICON1		equ 100
IDB_BITMAP1		equ 200
IDB_BITMAP2		equ 201
IDM_MENU1		equ 300
IDD_DIALOG1		equ 400
IDD_DIALOG2		equ 401
IDC_TOOLBAR1	equ 1001
IDC_LISTVIEW1	equ 1002
IDC_CHECKBOX1	equ 1003
IDC_CHECKBOX2	equ 1004
IDC_CHECKBOX3	equ 1005
IDC_CHECKBOX4	equ 1006
IDC_CHECKBOX5	equ 1007
IDC_CHECKBOX6	equ 1008
ID_REFRESH		equ 10000
ID_ADD			equ 10001
ID_REMOVE		equ 10002
ID_LOAD			equ 10003
ID_UNLOAD		equ 10004
ID_INSTALL		equ 10005
ID_UNINSTALL	equ 10006
ID_CONFIGURE	equ 10007

.data?
hInstance		dd ?	;DLL instance handle
pHandles		dd ?	;Pointer to HANDLES structure
pFeatures		dd ?	;Pointer to FEATURES structure
pIniFile		dd ?	;Pointer to the addins INI filename
pOldDockingProc	dd ?	;Old docking window procedure
hDocking		dd ?	;Handle of the docking window
hChild			dd ?	;Handle of the child dialog box
hThread			dd ?	;Folder change notification thread handle
bInternalChange	dd ?	;TRUE if we're changing the folder, FALSE when change is external
bFirstTime		dd ?	;TRUE if we haven't shown the docking window at least once
bAutoDev		dd ?	;TRUE if we need to reload an automatically unloaded add-in

; This two must be consecutive!
hFCNotify		dd ?	;Folder change notification handle
hEvent			dd ?	;"Close folder change notification thread" event handle

szAddInsFolder	db MAX_PATH dup (?)
szFilename		db MAX_PATH dup (?)
szTemp			db MAX_PATH dup (?)

.data
; Docking window config
xDocking	DOCKINGDATA < offset szAppName, NODOCK, <200,200,500,400>, 300,300,300,300 >

; Browse for new add-ins
ofn OPENFILENAME <sizeof OPENFILENAME,,,offset szFilter,NULL,0,0,offset szFilename,sizeof szFilename,\
	NULL,0,offset szAddInsFolder,offset szBrowseForAddIn,OFN_ALLOWMULTISELECT or OFN_EXPLORER or \
	OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_NOCHANGEDIR,,,NULL,,NULL,>
; or OFN_ENABLEHOOK

; Copy new add-ins to the add-ins folder
shfop_copy	SHFILEOPSTRUCT <,FO_COPY,offset szFilename,offset szAddInsFolder,FOF_ALLOWUNDO or \
	 		FOF_FILESONLY or FOF_NOCONFIRMATION or FOF_RENAMEONCOLLISION or FOF_SILENT,,,>

; List view control columns
lvc0		LVCOLUMN \
	 		<LVCF_FMT or LVCF_ORDER or LVCF_SUBITEM or LVCF_TEXT or LVCF_WIDTH,\
	 		LVCFMT_LEFT,160,offset szCol0,,0,,0>
lvc1		LVCOLUMN \
	 		<LVCF_FMT or LVCF_ORDER or LVCF_SUBITEM or LVCF_TEXT or LVCF_WIDTH,\
	 		LVCFMT_LEFT,52,offset szCol1,,1,,1>
lvc2		LVCOLUMN \
	 		<LVCF_FMT or LVCF_ORDER or LVCF_SUBITEM or LVCF_TEXT or LVCF_WIDTH,\
	 		LVCFMT_LEFT,52,offset szCol2,,2,,2>
lvc3		LVCOLUMN \
	 		<LVCF_FMT or LVCF_ORDER or LVCF_SUBITEM or LVCF_TEXT or LVCF_WIDTH,\
	 		LVCFMT_LEFT,100,offset szCol3,,3,,3>
lvc4		LVCOLUMN \
	 		<LVCF_FMT or LVCF_ORDER or LVCF_SUBITEM or LVCF_TEXT or LVCF_WIDTH,\
	 		LVCFMT_LEFT,0,offset szCol4,,4,,4>

; Toolbar buttons
tbButtons	label TBBUTTON
	 		TBBUTTON <0,ID_REFRESH,TBSTATE_ENABLED,TBSTYLE_BUTTON,,offset szTB_Refresh>		; Refresh
	 		TBBUTTON <-1,-1,TBSTATE_INDETERMINATE,TBSTYLE_SEP,,NULL>						; ---
	 		TBBUTTON <1,ID_ADD,TBSTATE_ENABLED,TBSTYLE_BUTTON,,offset szTB_Add>				; Add
	 		TBBUTTON <2,ID_REMOVE,TBSTATE_ENABLED,TBSTYLE_BUTTON,,offset szTB_Remove>		; Remove
	 		TBBUTTON <-1,-1,TBSTATE_INDETERMINATE,TBSTYLE_SEP,,NULL>						; ---
	 		TBBUTTON <3,ID_LOAD,TBSTATE_ENABLED,TBSTYLE_BUTTON,,offset szTB_Load>			; Load
	 		TBBUTTON <4,ID_UNLOAD,TBSTATE_ENABLED,TBSTYLE_BUTTON,,offset szTB_Unload>		; Unload
	 		TBBUTTON <-1,-1,TBSTATE_INDETERMINATE,TBSTYLE_SEP,,NULL>						; ---
	 		TBBUTTON <5,ID_INSTALL,TBSTATE_ENABLED,TBSTYLE_BUTTON,,offset szTB_Install>		; Install
	 		TBBUTTON <6,ID_UNINSTALL,TBSTATE_ENABLED,TBSTYLE_BUTTON,,offset szTB_Install>	; Uninstall
	 		TBBUTTON <-1,-1,TBSTATE_INDETERMINATE,TBSTYLE_SEP,,NULL>						; ---
	 		TBBUTTON <7,ID_CONFIGURE,TBSTATE_ENABLED,TBSTYLE_BUTTON,,offset szTB_Configure>	; Configure

; Toolbar button info tip
szIT_Ptr	dd offset szIT_Refresh, offset szIT_Add, offset szIT_Remove,\
	 		   offset szIT_Load, offset szIT_Unload, offset szIT_Install,\
	 		   offset szIT_Uninstall, offset szIT_Configure

; List view control column text
szCol0		db "Available Add-Ins",0
szCol1		db "Loaded",0
szCol2		db "Installed",0
szCol3		db "Add-In Filename",0
szCol4		db "Add-In Description",0

; Toolbar button strings
szTBStrings	label byte
szTB_Refresh	db "Refresh",0		; 0
	 			; ---
szTB_Add		db "Add",0			; 1
szTB_Remove		db "Remove",0		; 2
	 			; ---
szTB_Load		db "Load",0			; 3
szTB_Unload		db "Unload",0		; 4
	 			; ---
szTB_Install	db "Install",0		; 5
szTB_Uninstall	db "Uninstall",0	; 6
	 			; ---
szTB_Configure	db "Configure",0	; 7
	 			db 0

; Toolbar button info tip strings
szIT_Refresh	db "Refresh the add-ins list",0
szIT_Add		db "Add a new add-in to the list",0
szIT_Remove		db "Remove all currently selected add-ins from the list",0
szIT_Load		db "Load all currently selected add-ins",0
szIT_Unload		db "Unload all currently selected add-ins",0
szIT_Install	db "Install all currently selected add-ins",0
szIT_Uninstall	db "Uninstall all currently selected add-ins",0
szIT_Configure	db "Configure all currently selected add-ins",0

; Messagebox strings
szConfirmDelete	db "You are about to REMOVE an add-in from the list!",13,10
	 			db "Click ",34,"Yes",34," to proceed.",13,10
	 			db "Click ",34,"No",34," to abort.",0
szAreYouSure	db "Are you sure?",0

; Add-In information
IFDEF DEBUG_BUILD
	szFriendlyName	db "Enhanced Add-In Manager v1.0.0.2 DEBUG",0		;Friendly add-in name
ELSE
	szFriendlyName	db "Enhanced Add-In Manager v1.0.0.2",0				;Friendly add-in name
ENDIF
szDescription	db "Provides a new GUI to manage your add-ins.",13,10	;Add-in description
	 			db "(C) 2004 by Mario Vilas (aka QvasiModo)",0

szAppName		db "Enhanced Add-In Manager",0	;Section in the addins INI file
szWindowPos		db "WindowPos",0				;Key for the docking window position
szWindowStyle	db "WindowStyle",0				;Key for the docking window style

; Add-In config procedure name
szWAAddInConfig	db "WAAddInConfig",0

; Add-In INI file key names
szColumnOrder			db "ColumnOrder",0
szRefreshOnNotify		db "RefreshOnNotify",0
szRefreshOnShow			db "RefreshOnShow",0
szDoubleClickSensitive	db "DoubleClickSensitive",0
szShowIcons				db "ShowIcons",0
szShowHot				db "ShowHot",0
szShowGrid				db "ShowGrid",0

; Crude BOOL -> ASCIIZ conversion
szNo	db "No",0,0
szYes	db "Yes",0

; Misc strings
szFmtInt	db "%i",0
szFmtKey	db "ColumnWidth_%i",0

szBrowseForAddIn	db "Browse for new add-ins...",0

szFilter	db "WinAsm Studio Add-Ins (*.dll)",0,"*.dll",0
	 		db "All files (*.*)",0,"*.*",0
	 		db 0

.code
; -----------------------------------------------------------------------------
; Entry point
; -----------------------------------------------------------------------------

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

; -----------------------------------------------------------------------------
; WinAsm callbacks
; -----------------------------------------------------------------------------

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
	
	mov bFirstTime,TRUE
	
	; Initialize WAAddInLib.lib
	invoke InitializeAddIn,hInstance,pWinAsmHandles,pWinAsmFeatures,offset szAppName
	test eax,eax
	jz fail
	mov pIniFile,eax	; Keep the pointer to the addins INI filename if needed.
	
	; Infer the add-ins folder from the INI pathname
	invoke lstrcpyn,offset szAddInsFolder,eax,MAX_PATH
	test eax,eax
	jz fail
	invoke PathRemoveFileSpec,offset szAddInsFolder
	test eax,eax
	jz fail
	
	; Keep pWinAsmHandles and pWinAsmFeatures.
	; pWinAsmHandles is a pointer to the HANDLES structure.
	; pWinAsmFeatures is a pointer to the FEATURES structure.
	push pWinAsmHandles
	pop pHandles
	push pWinAsmFeatures
	pop pFeatures
	
	; Ensure the current version of WinAsm Studio is compatible with our addin (if needed).
	invoke CheckWAVersion,3025	;For example, version 3.0.1.4 is 3014 (decimal).
	test eax,eax
	jz fail
	
	; You can create a docking window here.
	invoke CreateDockingWindow,offset xDocking,
		WS_CLIPCHILDREN or WS_CLIPSIBLINGS or STYLE_GRADIENTTITLE,
		offset szWindowPos,offset szWindowStyle
	test eax,eax
	jz fail
	mov hDocking,eax
	invoke ShowWindow,eax,SW_HIDE
	invoke EnableWindow,hDocking,TRUE
	
	; Subclass our docking window to catch resize notifications.
	invoke SetWindowLong,hDocking,GWL_WNDPROC,offset DockingProc
	test eax,eax
	jz clean
	mov pOldDockingProc,eax
	
	; You'll need to create a child window (or dialog) of the docking window here...
	invoke CreateDialogParam,hInstance,IDD_DIALOG1,hDocking,offset DlgProc,0
	test eax,eax
	jz clean
	
	; Set up folder change notification
	invoke CreateEvent,NULL,TRUE,FALSE,NULL
	mov hEvent,eax
	push eax
	invoke CreateThread,NULL,0,offset FolderNotifyThread,0,0,esp
	pop edx
	mov hThread,eax
	
	IFDEF DEBUG_BUILD
		PrintText "Loaded."
	ENDIF
	
	; Return 0 if successful, -1 on error (addin will be unloaded WITHOUT calling WAAddInUnload).
	xor eax,eax
@@:	ret
	
clean:
	invoke WAAddInUnload
fail:
	or eax,-1	;return -1 to cancel loading this addin
	jmp short @B
	
WAAddInLoad endp

align DWORD
WAAddInUnload proc
	
	; When the addin is unloaded, WinAsm will call this function.
	
	IFDEF DEBUG_BUILD
		PrintText "Unloading AddIn."
	ENDIF
	
	; Close the folder notification thread.
	.if hEvent
		invoke SetEvent,hEvent
		.if hThread
			invoke WaitForSingleObject,hThread,INFINITE
		.endif
		invoke CloseHandle,hEvent
	.endif
	.if hThread
		invoke CloseHandle,hThread
	.endif
	
	.if hDocking
		
		; Restore the old docking window procedure.
		mov eax,pOldDockingProc
		.if eax
			invoke SetWindowLong,hDocking,GWL_WNDPROC,eax
		.endif
		
		; You must destroy the docking window(s) created in WAAddInLoad.
		invoke ShowWindow,hDocking,SW_HIDE
		invoke DestroyDockingWindow,
		 		hDocking,offset xDocking,offset szWindowPos,offset szWindowStyle
		
	.endif
	
	IFDEF DEBUG_BUILD
		PrintText "Unloaded."
	ENDIF
	
	; The return value is ignored by WinAsm.
	ret
	
WAAddInUnload endp

align DWORD
WAAddInConfig proc pWinAsmHandles:PTR HANDLES, pWinAsmFeatures:PTR FEATURES
	
	; We need the HANDLES to know the handle of hMain (our parent window).
	; We might need the FEATURES to know what version of WinAsm is running.
	invoke InitializeAddIn,hInstance,pWinAsmHandles,pWinAsmFeatures,offset szAppName
	.if eax
		mov pIniFile,eax	; Keep the pointer to the addins INI filename.
		; The dialog box MUST be modal to WinAsm's main window!
		mov eax,pWinAsmHandles
		.if eax
			mov eax,[eax].HANDLES.hMain
		.endif
		invoke DialogBoxParam,hInstance,IDD_DIALOG2,eax,offset ConfigProc,0
	.endif
	ret
	
WAAddInConfig endp

align DWORD
FrameWindowProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local cpi:CURRENTPROJECTINFO
	local szFile[MAX_PATH]:BYTE
	local szPath[MAX_PATH]:BYTE
	
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
			.if edx == IDM_ADDINS_ADDINSMANAGER
				IFDEF DEBUG_BUILD
					PrintText "Addin's menu item activated."
				ENDIF
				
				; Show or hide the docking window.
				invoke IsWindowVisible,hDocking
				.if eax
					push SW_HIDE
				.else
					push SW_SHOW
				.endif
				push hDocking
				call ShowWindow
				
				; Prevent WinAsm and other addins from processing this message.
				push 1
				pop eax
				ret
				
			.elseif (edx == IDM_MAKE_LINK) || (edx == IDM_MAKE_GO)
				IFDEF DEBUG_BUILD
					PrintText "Auto unload add-ins under development"
				ENDIF
				
				; Auto unload add-ins under development
				
				; Clear the flag
				mov bAutoDev,FALSE
				; Get the build output file
				invoke GetOutputFile,addr szFile,sizeof szFile
				.if eax
					; Get the current project info
					mov edx,pHandles
					invoke SendMessage,[edx].HANDLES.hMain,WAM_GETCURRENTPROJECTINFO,addr cpi,0
					.if eax
						; Is it a DLL project?
						mov eax,cpi.pProjectType
						.if eax && dword ptr [eax] == 1
							; Is it in the Add-Ins folder?
							invoke lstrcpy,addr szPath,addr szFile
							invoke PathRemoveFileSpec,addr szPath
							invoke lstrcmpi,addr szPath,offset szAddInsFolder
							.if eax == 0
								; Is the add-in loaded?
								invoke GetModuleHandle,addr szFile
								.if eax
									; Set the flag and unload the add-in
									IFDEF DEBUG_BUILD
										PrintString szFile
									ENDIF
									mov bAutoDev,TRUE
									invoke UnloadAddIn,eax
								.endif
							.endif
						.endif
					.endif
				.endif
				
			.endif
		.endif
	.elseif eax == WAE_COMMANDFINISHED
		mov eax,wParam
		mov edx,eax
		shr eax,16
		and edx,0FFFFh
		.if (eax == 0) || (eax == 1)	;0 for menu item or toolbar, 1 for accelerator.
			.if (edx == IDM_MAKE_LINK) || (edx == IDM_MAKE_GO)
				IFDEF DEBUG_BUILD
					PrintText "Auto reload add-ins under development"
				ENDIF
				
				; Auto reload add-ins under development
				.if bAutoDev
					invoke GetOutputFile,addr szFile,sizeof szFile
					.if eax
						IFDEF DEBUG_BUILD
							PrintString szFile
						ENDIF
						invoke LoadAddIn,addr szFile
					.endif
				.endif
				mov bAutoDev,FALSE
				
			.endif
		.endif
	.endif
	
	; Return 0 (FALSE) to allow other addins and WinAsm itself process this message.
	; Return 1 (TRUE) to... well, guess ;)
	xor eax,eax
	ret
	
FrameWindowProc endp

; -----------------------------------------------------------------------------
; Auxiliary functions
; -----------------------------------------------------------------------------

align DWORD
SaveColumnWidth proc hCtrl:HWND, iCol:DWORD
	local szKey[256]:BYTE
	local szVal[256]:BYTE
	
	mov eax,hCtrl
	.if eax
		invoke SendMessage,eax,LVM_GETCOLUMNWIDTH,iCol,0
		.if eax
			mov szKey[0],0
			mov szVal[0],0
			invoke wsprintf,addr szVal,offset szFmtInt,eax
			invoke wsprintf,addr szKey,offset szFmtKey,iCol
			invoke WritePrivateProfileString,
			 		offset szAppName,addr szKey,addr szVal,pIniFile
		.endif
	.endif
	ret
	
SaveColumnWidth endp

align DWORD
LoadColumnWidth proc uses edi iCol:DWORD, pCol:PTR LVCOLUMN
	local szKey[256]:BYTE
	local szVal[256]:BYTE
	
	.if pCol
		mov szKey[0],0
		mov szVal[0],0
		invoke wsprintf,addr szKey,offset szFmtKey,iCol
		lea edi,szVal
		invoke GetPrivateProfileString,
		 		offset szAppName,addr szKey,edi,edi,sizeof szVal,pIniFile
		.if eax
			invoke atodw,addr szVal
			mov edx,pCol
			mov [edx].LVCOLUMN.lx,eax
		.endif
	.endif
	ret
	
LoadColumnWidth endp

align DWORD
ResizeDockingChild proc
	local rect:RECT
	
	; Resize the dialog box to fit into the parent docking window.
	invoke SendMessage,hDocking,WAM_GETCLIENTRECT,0,addr rect
	mov eax,rect.right
	mov edx,rect.bottom
	sub eax,rect.left
	sub edx,rect.top
	invoke MoveWindow,hChild,rect.left,rect.top,eax,edx,TRUE
	ret
	
ResizeDockingChild endp

align DWORD
ResizeControls proc
	local hCtrl:HWND
	local rectW:RECT
	local rectT:RECT
	
	; Resize the controls when the dialog box is resized.
	invoke GetClientRect,hChild,addr rectW
	invoke GetDlgItem,hChild,IDC_TOOLBAR1
	mov hCtrl,eax
	lea edx,rectT
	invoke GetWindowRect,eax,edx
	invoke ScreenToClient,hChild,addr rectT.right	;(right,bottom)
	invoke GetDlgItem,hChild,IDC_LISTVIEW1
	mov edx,rectW.bottom
	sub edx,rectT.bottom
	invoke MoveWindow,eax,0,rectT.bottom,rectW.right,edx,TRUE
	invoke MoveWindow,hCtrl,0,0,rectW.right,rectT.bottom,TRUE
	ret
	
ResizeControls endp

align DWORD
EnableButtons proc uses ebx bEnable:BOOL
	local hCtrl:HWND
	
	invoke GetDlgItem,hChild,IDC_TOOLBAR1
	.if eax
		mov hCtrl,eax
		mov ebx,ID_REMOVE
		.repeat
			invoke SendMessage,hCtrl,TB_ENABLEBUTTON,ebx,bEnable
			inc ebx
		.until ebx > ID_CONFIGURE
	.endif
	ret
	
EnableButtons endp

align DWORD
SetListViewExStyles proc
	local dwFlags:DWORD
	
	mov dwFlags,LVS_EX_INFOTIP or LVS_EX_FULLROWSELECT or LVS_EX_HEADERDRAGDROP
	invoke ReadIniBool,offset szShowHot,TRUE
	.if eax
		or dwFlags,LVS_EX_TWOCLICKACTIVATE
	.endif
	invoke ReadIniBool,offset szShowGrid,TRUE
	.if eax
		or dwFlags,LVS_EX_GRIDLINES
	.endif
	invoke SendDlgItemMessage,hChild,IDC_LISTVIEW1,LVM_SETEXTENDEDLISTVIEWSTYLE,
	 		LVS_EX_INFOTIP or LVS_EX_FULLROWSELECT or LVS_EX_HEADERDRAGDROP or \
	 		LVS_EX_GRIDLINES or LVS_EX_TWOCLICKACTIVATE,
	 		dwFlags
	ret
	
SetListViewExStyles endp

align DWORD
RefreshList proc
	local hFind				:HANDLE
	local hCtrl				:HWND
	local hIml				:HIMAGELIST
	local hIcon				:HICON
	local lvi				:LVITEM
	local bShowIcons		:BOOL
	local bLoaded			:BOOL
	local bInstalled		:BOOL
	local szPath[MAX_PATH]	:BYTE
	local w32fd				:WIN32_FIND_DATA
	local szName[MAX_PATH]	:BYTE
	local szDesc[MAX_PATH]	:BYTE
	
	IFDEF DEBUG_BUILD
		PrintText "Refreshing add-ins list."
	ENDIF
	
	; Refresh the add-ins list.
	
	invoke GetCursor
	push eax
	invoke LoadCursor,NULL,IDC_WAIT
	invoke SetCursor,eax
	invoke ReadIniBool,offset szShowIcons,TRUE
	mov bShowIcons,eax
	invoke GetDlgItem,hChild,IDC_LISTVIEW1
	.if eax
		mov hCtrl,eax
		invoke LockWindowUpdate,eax
		invoke SendMessage,hCtrl,LVM_DELETEALLITEMS,0,0
		invoke FindFirstAddIn,addr w32fd,addr szName,addr szDesc,addr bLoaded,addr bInstalled
		.if eax != INVALID_HANDLE_VALUE
			mov hFind,eax
			mov lvi.iItem,-1
			.repeat
				invoke SendMessage,hCtrl,LVM_GETIMAGELIST,LVSIL_SMALL,0
				mov hIml,eax
				lea eax,szName
				.if bShowIcons
					mov lvi.imask,LVIF_TEXT or LVIF_IMAGE
					mov lvi.iImage,-1
				.else
					mov lvi.imask,LVIF_TEXT
				.endif
				inc lvi.iItem
				mov lvi.iSubItem,0
				mov lvi.pszText,eax
				.if hIml
					invoke lstrcpy,addr szPath,offset szAddInsFolder
					invoke PathAppend,addr szPath,addr w32fd.cFileName
					IFDEF DEBUG_BUILD
						PrintString szPath
					ENDIF
					mov hIcon,NULL
					invoke ExtractIconEx,addr szPath,0,NULL,addr hIcon,1
					.if hIcon
						invoke ImageList_AddIcon,hIml,hIcon
						.if eax != -1
							mov lvi.iImage,eax
						.endif
						invoke DestroyIcon,hIcon
					.endif
				.endif
				invoke SendMessage,hCtrl,LVM_INSERTITEM,0,addr lvi
				.if eax != -1
					mov lvi.imask,LVIF_TEXT
					mov lvi.iItem,eax
					mov eax,bLoaded
					add eax,eax
					add eax,eax
					add eax,offset szNo
					inc lvi.iSubItem
					mov lvi.pszText,eax
					invoke SendMessage,hCtrl,LVM_SETITEM,0,addr lvi
					mov eax,bInstalled
					add eax,eax
					add eax,eax
					add eax,offset szNo
					inc lvi.iSubItem
					mov lvi.pszText,eax
					invoke SendMessage,hCtrl,LVM_SETITEM,0,addr lvi
					lea eax,w32fd.cFileName
					inc lvi.iSubItem
					mov lvi.pszText,eax
					invoke SendMessage,hCtrl,LVM_SETITEM,0,addr lvi
					lea eax,szDesc
					inc lvi.iSubItem
					mov lvi.pszText,eax
					invoke SendMessage,hCtrl,LVM_SETITEM,0,addr lvi
				.endif
				invoke FindNextAddIn,hFind,addr w32fd,
				 		addr szName,addr szDesc,addr bLoaded,addr bInstalled
			.until !eax
			invoke FindAddInClose,hFind
		.endif
		invoke LockWindowUpdate,NULL
	.endif
	call SetCursor
	ret
	
RefreshList endp

align DWORD
AddNewAddIn proc
	
	; Add new add-ins to the folder.
	
	mov bInternalChange,TRUE
	mov ofn.lStructSize,sizeof OPENFILENAME
	push hInstance
	pop ofn.hInstance
	mov eax,pHandles
	.if eax
		mov eax,[eax].HANDLES.hMain
	.endif
	mov shfop_copy.hwnd,eax
	mov ofn.hwndOwner,eax
	invoke GetOpenFileName,addr ofn
	.if eax
		invoke SHFileOperation,addr shfop_copy
		.if (eax == 0) && !shfop_copy.fAnyOperationsAborted
			invoke RefreshList
		.endif
	.endif
	mov bInternalChange,FALSE
	ret
	
AddNewAddIn endp

align DWORD
LoadSelected proc
	local bBeep				:BOOL
	local hCtrl				:HWND
	local lvi				:LVITEM
	local szFile[MAX_PATH]	:BYTE
	
	invoke GetDlgItem,hChild,IDC_LISTVIEW1
	.if eax
		mov bBeep,FALSE
		mov hCtrl,eax
		mov lvi.imask,LVIF_TEXT
		mov lvi.iItem,-1
		mov lvi.cchTextMax,MAX_PATH
		.repeat
			lea eax,szFile
			mov lvi.iSubItem,3
			mov lvi.pszText,eax
			invoke SendMessage,hCtrl,LVM_GETNEXTITEM,lvi.iItem,LVNI_ALL or LVNI_SELECTED
			.break .if eax == -1
			mov lvi.iItem,eax
			invoke SendMessage,hCtrl,LVM_GETITEM,0,addr lvi
			.if eax
				invoke LoadAddIn,lvi.pszText
				test eax,eax
				je beep
				mov lvi.iSubItem,1
				mov lvi.pszText,offset szYes
				invoke SendMessage,hCtrl,LVM_SETITEM,0,addr lvi
				.continue .if eax
			.endif
	beep:	mov bBeep,TRUE
		.until FALSE
		.if bBeep
			invoke MessageBeep,0FFFFFFFFh
		.endif
	.endif
	ret
	
LoadSelected endp

align DWORD
UnloadSelected proc
	local bBeep				:BOOL
	local hCtrl				:HWND
	local lvi				:LVITEM
	local szFile[MAX_PATH]	:BYTE
	
	invoke GetDlgItem,hChild,IDC_LISTVIEW1
	.if eax
		mov bBeep,FALSE
		mov hCtrl,eax
		mov lvi.imask,LVIF_TEXT
		mov lvi.iItem,-1
		mov lvi.cchTextMax,MAX_PATH
		.repeat
			lea eax,szFile
			mov lvi.iSubItem,3
			mov lvi.pszText,eax
			invoke SendMessage,hCtrl,LVM_GETNEXTITEM,lvi.iItem,LVNI_ALL or LVNI_SELECTED
			.break .if eax == -1
			mov lvi.iItem,eax
			invoke SendMessage,hCtrl,LVM_GETITEM,0,addr lvi
			.if eax
				invoke GetModuleHandle,lvi.pszText
				test eax,eax
				jz beep
				invoke UnloadAddIn,eax
				test eax,eax
				je beep
				mov lvi.iSubItem,1
				mov lvi.pszText,offset szNo
				invoke SendMessage,hCtrl,LVM_SETITEM,0,addr lvi
				.continue .if eax
			.endif
	beep:	mov bBeep,TRUE
		.until FALSE
		.if bBeep
			invoke MessageBeep,0FFFFFFFFh
		.endif
	.endif
	ret
	
UnloadSelected endp

align DWORD
ToogleSelected proc
	local bBeep				:BOOL
	local hCtrl				:HWND
	local lvi				:LVITEM
	local szFile[MAX_PATH]	:BYTE
	
	invoke GetDlgItem,hChild,IDC_LISTVIEW1
	.if eax
		mov bBeep,FALSE
		mov hCtrl,eax
		mov lvi.imask,LVIF_TEXT
		mov lvi.iItem,-1
		mov lvi.cchTextMax,MAX_PATH
		.repeat
			lea eax,szFile
			mov lvi.iSubItem,3
			mov lvi.pszText,eax
			invoke SendMessage,hCtrl,LVM_GETNEXTITEM,lvi.iItem,LVNI_ALL or LVNI_SELECTED
			.break .if eax == -1
			mov lvi.iItem,eax
			invoke SendMessage,hCtrl,LVM_GETITEM,0,addr lvi
			.if eax
				invoke GetModuleHandle,lvi.pszText
				.if eax
					mov lvi.pszText,offset szNo
					invoke UnloadAddIn,eax
				.else
					mov lvi.pszText,offset szYes
					invoke LoadAddIn,addr szFile
				.endif
				test eax,eax
				jz beep
				mov lvi.iSubItem,1
				invoke SendMessage,hCtrl,LVM_SETITEM,0,addr lvi
				.continue .if eax
			.endif
	beep:	mov bBeep,TRUE
		.until FALSE
		.if bBeep
			invoke MessageBeep,0FFFFFFFFh
		.endif
	.endif
	ret
	
ToogleSelected endp

align DWORD
InstallSelected proc dwAction:DWORD
	local bBeep				:BOOL
	local hCtrl				:HWND
	local lvi				:LVITEM
	local szFile[MAX_PATH]	:BYTE
	
	IFDEF DEBUG_BUILD
		PrintText "Un/installing AddIn."
	ENDIF
	
	and dwAction,1
	invoke GetDlgItem,hChild,IDC_LISTVIEW1
	.if eax
		mov bBeep,FALSE
		mov hCtrl,eax
		mov lvi.imask,LVIF_TEXT
		mov lvi.iItem,-1
		mov lvi.cchTextMax,MAX_PATH
		.repeat
			lea eax,szFile
			mov lvi.iSubItem,3
			mov lvi.pszText,eax
			invoke SendMessage,hCtrl,LVM_GETNEXTITEM,lvi.iItem,LVNI_ALL or LVNI_SELECTED
			.break .if eax == -1
			mov lvi.iItem,eax
			invoke SendMessage,hCtrl,LVM_GETITEM,0,addr lvi
			.if eax
				invoke InstallAddIn,lvi.pszText,dwAction
				cmp eax,-1
				je beep
				mov eax,dwAction
				add eax,eax
				add eax,eax
				add eax,offset szNo
				mov lvi.iSubItem,2
				mov lvi.pszText,eax
				invoke SendMessage,hCtrl,LVM_SETITEM,0,addr lvi
				.continue .if eax
			.endif
	beep:	mov bBeep,TRUE
		.until FALSE
		.if bBeep
			invoke MessageBeep,0FFFFFFFFh
		.endif
	.endif
	ret
	
InstallSelected endp

align DWORD
RemoveSelected proc
	local bBeep				:BOOL
	local hCtrl				:HWND
	local lvi				:LVITEM
	local szPath[MAX_PATH]	:BYTE
	local szFile[MAX_PATH]	:BYTE
	local shfop				:SHFILEOPSTRUCT
	
	mov bInternalChange,TRUE
	invoke GetDlgItem,hChild,IDC_LISTVIEW1
	.if eax
		mov bBeep,FALSE
		mov hCtrl,eax
		mov lvi.imask,LVIF_TEXT
		mov lvi.iItem,-1
		mov lvi.cchTextMax,MAX_PATH
		invoke LockWindowUpdate,hCtrl
		.repeat
			lea eax,szFile
			mov lvi.iSubItem,3
			mov lvi.pszText,eax
			invoke SendMessage,hCtrl,LVM_GETNEXTITEM,lvi.iItem,LVNI_ALL or LVNI_SELECTED
			.break .if eax == -1
			mov lvi.iItem,eax
			invoke SendMessage,hCtrl,LVM_GETITEM,0,addr lvi
			.if eax
				invoke GetModuleHandle,lvi.pszText
				.if eax
					invoke UnloadAddIn,eax
					test eax,eax
					je beep
				.endif
				mov lvi.iSubItem,1
				mov lvi.pszText,offset szNo
				invoke SendMessage,hCtrl,LVM_SETITEM,0,addr lvi
				test eax,eax
				jz beep
				invoke InstallAddIn,addr szFile,INSTALL_STATE_CLEAR
				cmp eax,-1
				je beep
				mov lvi.iSubItem,2
				mov lvi.pszText,offset szNo
				invoke SendMessage,hCtrl,LVM_SETITEM,0,addr lvi
				test eax,eax
				jz beep
				invoke lstrcpyn,addr szPath,offset szAddInsFolder,MAX_PATH
				test eax,eax
				jz beep
				invoke PathAppend,addr szPath,addr szFile
				test eax,eax
				jz beep
				invoke lstrlen,addr szPath
				mov szPath[eax + 1],0
				mov eax,pHandles
				.if eax
					mov eax,[eax].HANDLES.hMain
				.endif
				mov shfop.hwnd,eax
				mov shfop.wFunc,FO_DELETE
				lea eax,szPath
				mov shfop.pFrom,eax
				mov shfop.pTo,NULL
				mov shfop.fFlags,FOF_ALLOWUNDO or FOF_NOCONFIRMATION or FOF_SILENT
				mov shfop.fAnyOperationsAborted,FALSE
				mov shfop.hNameMappings,NULL
				mov shfop.lpszProgressTitle,NULL
				invoke SHFileOperation,addr shfop
				test eax,eax
				jnz beep
				invoke SendMessage,hCtrl,LVM_DELETEITEM,lvi.iItem,0
				test eax,eax
				jz beep
				dec lvi.iItem
				.continue
			.endif
	beep:	mov bBeep,TRUE
		.until FALSE
		invoke LockWindowUpdate,NULL
		.if bBeep
			invoke MessageBeep,0FFFFFFFFh
		.endif
	.endif
	mov bInternalChange,FALSE
	ret
	
RemoveSelected endp

align DWORD
ConfigureAddIn proc pszFile:PTR BYTE
	local szPath[MAX_PATH]:BYTE
	
	invoke lstrcpy,addr szPath,offset szAddInsFolder
	invoke PathFindFileName,pszFile
	invoke PathAppend,addr szPath,eax
	invoke LoadLibrary,addr szPath
	.if eax
		push eax
		invoke GetProcAddress,eax,offset szWAAddInConfig
		.if eax
			; WAAddInConfig(pHandles,pFeatures);
			push pFeatures
			push pHandles
			call eax
			; Dialog box (if any) MUST be modal, so on return we're sure
			; it doesn't exist anymore and we can unload the add-in's DLL.
		.endif
		call FreeLibrary
	.endif
	ret
	
ConfigureAddIn endp

align DWORD
ConfigureSelected proc
	local bBeep				:BOOL
	local hCtrl				:HWND
	local lvi				:LVITEM
	local szFile[MAX_PATH]	:BYTE
	
	IFDEF DEBUG_BUILD
		PrintText "Configuring AddIn."
	ENDIF
	
	invoke GetDlgItem,hChild,IDC_LISTVIEW1
	.if eax
		mov bBeep,FALSE
		mov hCtrl,eax
		mov lvi.imask,LVIF_TEXT
		mov lvi.iItem,-1
		mov lvi.cchTextMax,MAX_PATH
		.repeat
			lea eax,szFile
			mov lvi.iSubItem,3
			mov lvi.pszText,eax
			invoke SendMessage,hCtrl,LVM_GETNEXTITEM,lvi.iItem,LVNI_ALL or LVNI_SELECTED
			.break .if eax == -1
			mov lvi.iItem,eax
			invoke SendMessage,hCtrl,LVM_GETITEM,0,addr lvi
			.if eax
				invoke ConfigureAddIn,addr szFile
				.continue .if eax
			.endif
	beep:	mov bBeep,TRUE
		.until FALSE
		.if bBeep
			invoke MessageBeep,0FFFFFFFFh
		.endif
	.endif
	ret
	
ConfigureSelected endp

align DWORD
IniToCheckBox proc hWnd:HWND, dwID:DWORD, pKey:PTR BYTE, bDefault:BOOL
	
	invoke ReadIniBool,pKey,bDefault
	invoke CheckDlgButton,hWnd,dwID,eax
	ret
	
IniToCheckBox endp

align DWORD
CheckBoxToIni proc hWnd:HWND, dwID:DWORD, pKey:PTR BYTE
	local szNum[12]:BYTE
	
	invoke IsDlgButtonChecked,hWnd,dwID
	and eax,1
	lea edx,szNum
	invoke wsprintf,edx,offset szFmtInt,eax
	invoke WritePrivateProfileString,offset szAppName,pKey,addr szNum,pIniFile
	ret
	
CheckBoxToIni endp

align DWORD
ReadIniBool proc pKey:PTR BYTE, bDefault:BOOL
	
	invoke GetPrivateProfileInt,offset szAppName,pKey,bDefault,pIniFile
	and eax,1
	ret
	
ReadIniBool endp

; -----------------------------------------------------------------------------
; Other callbacks
; -----------------------------------------------------------------------------

align DWORD
FolderNotifyThread proc lParam:LPARAM
	
	; When there's a change in the add-ins folder, refresh the list.
	
	invoke FindFirstChangeNotification,
	 		offset szAddInsFolder,FALSE,
	 		FILE_NOTIFY_CHANGE_FILE_NAME or FILE_NOTIFY_CHANGE_DIR_NAME
	.if eax != INVALID_HANDLE_VALUE
		mov hFCNotify,eax
		.repeat
			invoke WaitForMultipleObjects,2,offset hFCNotify,FALSE,INFINITE
			.break .if eax != WAIT_OBJECT_0
			.if bInternalChange
				invoke IsWindow,hDocking
				.if eax
					invoke PostMessage,hDocking,WM_COMMAND,ID_REFRESH,0
				.endif
			.endif
			invoke FindNextChangeNotification,hFCNotify
		.until !eax
		invoke FindCloseChangeNotification,hFCNotify
	.endif
	ret
	
FolderNotifyThread endp

align DWORD
DockingProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
	mov eax,uMsg
	.if eax == WM_SIZE
		
		; Adjust the child dialog when the docking window is resized.
		invoke ResizeDockingChild
		
	.elseif eax == WM_MOUSEWHEEL
		
		; Forward mousewheel messages to the listview control always.
		invoke GetDlgItem,hChild,IDC_LISTVIEW1
		.if eax
			invoke SendMessage,eax,WM_MOUSEWHEEL,wParam,lParam
		.endif
		
	.elseif eax == WM_SETFOCUS
		
		; Set keyboard focus on child dialog box.
		invoke SetFocus,hChild
		
	.elseif eax == WM_SHOWWINDOW
		
		; Auto refresh on display?
		.if wParam
			invoke ReadIniBool,offset szRefreshOnShow,FALSE
			.if eax || bFirstTime
				mov bFirstTime,FALSE
				invoke RefreshList
			.endif
		.endif
		
	.endif
	invoke CallWindowProc,pOldDockingProc,hWnd,uMsg,wParam,lParam
	ret
	
DockingProc endp

align DWORD
DlgProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local hCtrl				:HWND
	local point				:POINT
	local lvi				:LVITEM
	local iColOrderArray[5]	:DWORD
	local szFile[MAX_PATH]	:BYTE
	
	mov eax,uMsg
	.if eax == WM_SIZE
		
		; Resize the controls when the dialog box is resized.
		invoke ResizeControls
		
	.elseif eax == WM_NOTIFY
		mov edx,lParam
		.if edx
			mov eax,[edx].NMHDR.idFrom
			mov ecx,[edx].NMHDR.code
			.if ecx == TTN_GETDISPINFO
				
				; Show the corresponding toolbar button tooltip.
				test [edx].NMTTDISPINFO.uFlags,TTF_IDISHWND
				.if zero?
					mov eax,[edx].NMHDR.idFrom
					sub eax,ID_REFRESH
					.if eax <= 8
						push szIT_Ptr[eax * 4]
						or [edx].NMTTDISPINFO.uFlags,TTF_DI_SETITEM
						mov [edx].NMTTDISPINFO.hinst,NULL
						pop [edx].NMTTDISPINFO.lpszText
					.endif
				.endif
				
			.elseif eax == IDC_LISTVIEW1
				.if ecx == LVN_GETINFOTIP
					
					; Show the corresponding listview item info tip.
					mov lvi.imask,LVIF_TEXT
					push [edx].NMLVGETINFOTIP.iItem
					pop lvi.iItem
					mov lvi.iSubItem,4
					push [edx].NMLVGETINFOTIP.pszText
					pop lvi.pszText
					push [edx].NMLVGETINFOTIP.cchTextMax
					pop lvi.cchTextMax
					invoke SendDlgItemMessage,hWnd,IDC_LISTVIEW1,LVM_GETITEM,0,addr lvi
					
				.elseif ecx == LVN_ITEMCHANGED
					
					; Some toolbar buttons must be disabled if NO items are selected.
					invoke SendDlgItemMessage,hWnd,IDC_LISTVIEW1,LVM_GETNEXTITEM,-1,LVNI_SELECTED
					.if eax == -1
						invoke EnableButtons,FALSE
					.else
						mov edx,lParam
						.if edx
							mov ecx,[edx].NMLISTVIEW.iItem
							.if (ecx == eax) || (ecx == -1)
								invoke EnableButtons,TRUE
							.endif
						.endif
					.endif
					
				.elseif ecx == LVN_ITEMACTIVATE
					
					; Make sure this feature is enabled.
					invoke ReadIniBool,offset szDoubleClickSensitive,TRUE
					.if eax
						; Load/unload the selected add-ins.
						invoke ToogleSelected
					.endif
					
				.elseif ecx == NM_RCLICK
					
					; Show context menu
					mov point.x,0
					mov point.y,0
					invoke GetCursorPos,addr point
					invoke SetForegroundWindow,hWnd
					invoke LoadMenu,hInstance,IDM_MENU1
					invoke GetSubMenu,eax,0
					invoke TrackPopupMenuEx,eax,
					 		TPM_LEFTALIGN or TPM_TOPALIGN or TPM_RIGHTBUTTON or \
					 		TPM_HORIZONTAL or TPM_HORPOSANIMATION or TPM_VERPOSANIMATION,
					 		point.x,point.y,hWnd,NULL
					
				.endif
			.endif
		.endif
	.elseif eax == WM_COMMAND
		mov eax,wParam
		test eax,0FFFE0000h		; Test wNotifyCode highest 7 bits.
		.if zero?				; wNotifyCode equals 0 (menu) or 1 (toolbar).
			and eax,0000FFFFh	; Get wID.
			.if eax == IDCANCEL
				
				; Quickly hide the docking window.
				mov eax,pHandles
				invoke SendMessage,[eax].HANDLES.hMain,WM_COMMAND,IDM_ADDINS_ADDINSMANAGER,0
				
			.elseif eax == ID_REFRESH
				
				; Refresh the add-ins list.
				invoke RefreshList
				
			.elseif eax == ID_ADD
				
				; Add new add-ins to the folder.
				invoke AddNewAddIn
				
			.elseif eax == ID_REMOVE
				
				; Unload, uninstall and remove all selected add-ins from the folder.
				invoke MessageBox,
				 		hWnd,offset szConfirmDelete,offset szAreYouSure,
				 		MB_DEFBUTTON2 or MB_ICONWARNING or MB_YESNO
				.if eax == IDYES
					invoke RemoveSelected
				.endif
				
			.elseif eax == ID_LOAD
				
				; Load all selected add-ins.
				invoke LoadSelected
				
			.elseif eax == ID_UNLOAD
				
				; Unload all selected add-ins.
				invoke UnloadSelected
				
			.elseif eax == ID_INSTALL
				
				; Install all selected add-ins.
				invoke InstallSelected,INSTALL_STATE_SET
				
			.elseif eax == ID_UNINSTALL
				
				; Uninstall all selected add-ins.
				invoke InstallSelected,INSTALL_STATE_CLEAR
				
			.elseif eax == ID_CONFIGURE
				
				; Configure all selected add-ins.
				invoke ConfigureSelected
				
			.endif
		.endif
		
	.elseif eax == WM_DESTROY
		
		; Save the listview columns width and order.
		invoke GetDlgItem,hWnd,IDC_LISTVIEW1
		mov hCtrl,eax
		push ebx
		xor ebx,ebx
		.repeat
			invoke SaveColumnWidth,hCtrl,ebx
			inc ebx
		.until ebx > 4
		pop ebx
		lea edx,iColOrderArray
		invoke SendMessage,hCtrl,LVM_GETCOLUMNORDERARRAY,5,edx
		.if eax
			invoke WritePrivateProfileStruct,
			 		offset szAppName,offset szColumnOrder,
			 		addr iColOrderArray,sizeof iColOrderArray,
			 		pIniFile
		.endif
		
	.elseif eax == WM_INITDIALOG
		
		; Keep the dialog box handle.
		push hWnd
		pop hChild
		
		; Setup the toolbar control.
		invoke GetDlgItem,hWnd,IDC_TOOLBAR1
		.if !eax
error:		invoke EndDialog,hWnd,-1
			xor eax,eax
			ret
		.endif
		mov hCtrl,eax
		invoke SendMessage,eax,TB_BUTTONSTRUCTSIZE,sizeof TBBUTTON,0
		invoke SendMessage,hCtrl,TB_SETBITMAPSIZE,0,1010h
		invoke ImageList_LoadImage,hInstance,IDB_BITMAP1,16,8,0FF00FFh,IMAGE_BITMAP,LR_CREATEDIBSECTION
		invoke SendMessage,hCtrl,TB_SETHOTIMAGELIST,0,eax
		.if eax
			invoke ImageList_Destroy,eax
		.endif
		invoke ImageList_LoadImage,hInstance,IDB_BITMAP2,16,8,0FF00FFh,IMAGE_BITMAP,LR_CREATEDIBSECTION
		invoke SendMessage,hCtrl,TB_SETIMAGELIST,0,eax
		.if eax
			invoke ImageList_Destroy,eax
		.endif
		invoke SendMessage,hCtrl,TB_SETEXTENDEDSTYLE,0,TBSTYLE_EX_HIDECLIPPEDBUTTONS
		invoke SendMessage,hCtrl,TB_ADDBUTTONS,12,offset tbButtons
		invoke SendMessage,hCtrl,TB_AUTOSIZE,0,0
		invoke EnableButtons,FALSE
		
		; Setup the listview control.
		invoke GetDlgItem,hWnd,IDC_LISTVIEW1
		test eax,eax
		jz error
		mov hCtrl,eax
		invoke SetListViewExStyles
		invoke ReadIniBool,offset szShowIcons,TRUE
		.if eax
			invoke ImageList_Create,16,16,ILC_COLOR32 or ILC_MASK,0,256
			invoke SendMessage,hCtrl,LVM_SETIMAGELIST,LVSIL_SMALL,eax
			.if eax
				invoke ImageList_Destroy,eax
			.endif
		.endif
		push ebx
		push esi
		xor ebx,ebx
		mov esi,offset lvc0
		.repeat
			invoke LoadColumnWidth,ebx,esi
			invoke SendMessage,hCtrl,LVM_INSERTCOLUMN,ebx,esi
			inc ebx
			add esi,sizeof LVCOLUMN
		.until ebx > 4
		pop esi
		pop ebx
		invoke GetPrivateProfileStruct,
		 		offset szAppName,offset szColumnOrder,
		 		addr iColOrderArray,sizeof iColOrderArray,
		 		pIniFile
		.if eax
			invoke SendMessage,hCtrl,LVM_SETCOLUMNORDERARRAY,5,addr iColOrderArray
		.endif
		
		; Resize the dialog box to fit into the parent docking window.
		invoke ResizeDockingChild
		
		; Return.
		push 1
		pop eax
		ret
		
	.endif
	xor eax,eax
	ret
	
DlgProc endp

align DWORD
ConfigProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
	mov eax,uMsg
	.if eax == WM_COMMAND
		mov eax,wParam
		cmp eax,IDCANCEL
		je cancel
		.if eax == IDOK
			
			; Save the new settings
			invoke CheckBoxToIni,hWnd,IDC_CHECKBOX1,offset szRefreshOnNotify
			invoke CheckBoxToIni,hWnd,IDC_CHECKBOX2,offset szRefreshOnShow
			invoke CheckBoxToIni,hWnd,IDC_CHECKBOX3,offset szDoubleClickSensitive
			invoke CheckBoxToIni,hWnd,IDC_CHECKBOX4,offset szShowIcons
			invoke CheckBoxToIni,hWnd,IDC_CHECKBOX5,offset szShowHot
			invoke CheckBoxToIni,hWnd,IDC_CHECKBOX6,offset szShowGrid
			
			; Update the settings if the add-in is currently loaded
			mov eax,hChild
			.if eax
				; Clear the add-ins list
				invoke SendDlgItemMessage,eax,IDC_LISTVIEW1,LVM_DELETEALLITEMS,0,0
				; Update the listview extended style flags
				invoke SetListViewExStyles
				; Rebuild or remove the listview image list
				invoke IsDlgButtonChecked,hWnd,IDC_CHECKBOX4
				test eax,BST_CHECKED
				.if !zero?
					invoke ImageList_Create,16,16,ILC_COLOR32 or ILC_MASK,0,256
					push eax
				.else
					push NULL
				.endif
				push LVSIL_SMALL
				push LVM_SETIMAGELIST
				push IDC_LISTVIEW1
				push hChild
				call SendDlgItemMessage
				.if eax
					invoke ImageList_Destroy,eax
				.endif
				; Refresh the add-ins list
				invoke RefreshList
			.endif
			
			; Close the config box
cancel:		invoke EndDialog,hWnd,eax
			
		.endif
	.elseif eax == WM_INITDIALOG
		
		; Initialize the config box
		invoke IniToCheckBox,hWnd,IDC_CHECKBOX1,offset szRefreshOnNotify,TRUE
		invoke IniToCheckBox,hWnd,IDC_CHECKBOX2,offset szRefreshOnShow,FALSE
		invoke IniToCheckBox,hWnd,IDC_CHECKBOX3,offset szDoubleClickSensitive,TRUE
		invoke IniToCheckBox,hWnd,IDC_CHECKBOX4,offset szShowIcons,TRUE
		invoke IniToCheckBox,hWnd,IDC_CHECKBOX5,offset szShowHot,TRUE
		invoke IniToCheckBox,hWnd,IDC_CHECKBOX6,offset szShowGrid,TRUE
		push 1
		pop eax
		ret
		
	.endif
	xor eax,eax
	ret
	
ConfigProc endp

end DllEntryPoint
