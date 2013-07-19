
;Prototypes
DllEntryPoint		proto hinstDLL:HINSTANCE, fdwReason:DWORD, lpvReserved:LPVOID
LoadConfig			proto
SaveConfig			proto
SaveBool			proto bBool:DWORD, pszBool:DWORD

GetWAAddInData		proto lpFriendlyName:PTR BYTE, lpDescription:PTR BYTE
WAAddInLoad			proto pWinAsmHandles:PTR HANDLES, features:PTR FEATURES
WAAddInUnload		proto
FrameWindowProc		proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

DlgProc				proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

;Resources
IDD_DIALOG1	equ 100
IDM_MENU1	equ 101
IDI_ICON0	equ 102
IDI_ICON1	equ 103
IDI_ICON2	equ 104
IDI_ICON3	equ 105
IDI_ICON4	equ 106
IDI_ICON5	equ 107
IDI_ICON6	equ 108
IDI_ICON7	equ 109
IDC_RADIO1	equ 1001
IDC_RADIO2	equ 1002
IDC_RADIO3	equ 1003
IDC_CHECK1	equ 1004
IDC_CHECK2	equ 1005
IDC_CHECK3	equ 1006
IDC_CHECK4	equ 1007
IDC_CHECK5	equ 1008
IDC_IMAGE1	equ 1009
IDC_UPDOWN1	equ 1010
ID_LAUNCH	equ 10001
ID_CLOSE	equ 10002

.data?

hInstance		dd ?	;DLL instance
pHandles		dd ?	;Pointer to HANDLES structure
hMenu			dd ?	;Main menu handle
ItemID			dd ?	;Our menu item ID

iIcon			dd ?	;Icon number (0-6)
bLoadExe		dd ?	;Load exe?
bLoadUsed		dd ?	;Load used addins?
bLoadUnused		dd ?	;Load unused addins?
bLoadProject	dd ?	;Load last project?
bLoadWords		dd ?	;Load apis and keywords?

;Save your config in WAAddIns.Ini
szIniPath		db MAX_PATH+20 dup (?)

.data

;Strings for quick bool to asciiz conversion
sz 0
sz 1

;Registry keys
szNTStart		db "Software\Microsoft\Windows NT\CurrentVersion\Run",0
sz9XStart		db "Software\Microsoft\Windows\CurrentVersion\Run",0
szValueName		equ offset szAppName	;szValueName db "WinAsm Studio Agent",0

;Save your config in WAAddIns.Ini
szIniFile		db "WAAddIns.Ini",0				;Ini filename
szAppName		db "WinAsm Studio Agent",0		;Section (should be your addin name)
sz Icon
sz LoadExe
sz LoadUsed
sz LoadUnused
sz LoadProject
sz LoadWords

;Your addin's menu item string
szMenuString	db "WinAsm Studio Agent Options",0

;Addin name and description (REQUIRED)
IFDEF DEBUG_BUILD
	szFriendlyName	db "WinAsm Studio Agent v1.00 DEBUG",0
ELSE
	szFriendlyName	db "WinAsm Studio Agent v1.00",0
ENDIF
szDescription	db "Pre-loads part of WinAsm Studio on Windows startup to speed its loading.",13,10,\
				   "® 2004 Mario Vilas (aka QvasiModo)",0
