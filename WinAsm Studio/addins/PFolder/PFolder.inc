include macros.inc

AppModel .386

include WINDOWS.INC
include WAAddIn.inc

include kernel32.inc
include user32.inc
include shell32.inc
include shlwapi.inc

includelib kernel32.lib
includelib user32.lib
includelib shell32.lib
includelib shlwapi.lib

include WAAddInLib.inc
includelib WAAddInLib.lib

IFDEF DEBUG_BUILD
	;Masm32 library (required by VKDEBUG)
	include masm32.inc
	includelib masm32.lib
	;VKim's debug library
	include debug.inc
	includelib debug.lib
ENDIF

;Prototypes
DllEntryPoint		proto hinstDLL:HINSTANCE, fdwReason:DWORD, lpvReserved:LPVOID
GetWAAddInData		proto lpFriendlyName:PTR BYTE, lpDescription:PTR BYTE
WAAddInLoad			proto pWinAsmHandles:PTR HANDLES, features:PTR FEATURES
WAAddInUnload		proto
FrameWindowProc		proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

; -------------------------------------------------------------------------
.data?

hInstance		dd ?	;DLL instance
pHandles		dd ?	;Pointer to HANDLES structure
pIniFile		dd ?	;Pointer to add-ins ini file
ItemID			dd ?	;Our menu item ID
SeparatorID		dd ?	;We also need an ID for the separator,
                        ; so it can be found later for removal

cpi CURRENTPROJECTINFO <>

szFolderName	db MAX_PATH dup (?)

;Your addin's menu item string
szMenuString	db 1024 dup (?)

; -------------------------------------------------------------------------
.data

;Save your config in WAAddIns.Ini
szAppName		db "Show Project Folder Add-In",0	;Section
szCaption		db "Caption",0
szMenuPos		db "MenuPos",0
szSeparatorPos	db "SeparatorPos",0
szItemPos		db "ItemPos",0
szShowCmd		db "ShowCmd",0
szDefCaption	db "Show Project Folder",0

;Addin name and description (REQUIRED)
IFDEF DEBUG_BUILD
	szFriendlyName	db "Show Project Folder v1.0.0.4 DEBUG",0
ELSE
	szFriendlyName	db "Show Project Folder v1.0.0.4",0
ENDIF
;szFriendlyName	equ <szAppName>
szDescription	db "Shows the current project folder in a shell Explorer window.",13,10,\
				   "® 2004 by Mario Vilas (aka QvasiModo)",0
