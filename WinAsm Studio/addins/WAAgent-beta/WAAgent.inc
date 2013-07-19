
;Prototypes
DllEntryPoint		proto hinstDLL:HINSTANCE, fdwReason:DWORD, lpvReserved:LPVOID
LoadConfig			proto
DeleteObsoleteKeys	proto
SaveDates			proto
SaveConfig			proto
CanUpdate			proto hWnd:HWND

GetWAAddInData		proto lpFriendlyName:PTR BYTE, lpDescription:PTR BYTE
WAAddInLoad			proto pWinAsmHandles:PTR HANDLES, features:PTR FEATURES
WAAddInUnload		proto
FrameWindowProc		proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

DlgProc				proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
DlgProc2			proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

;Resources
IDD_DIALOG1	equ 100
IDD_DIALOG2	equ 102
IDD_DIALOG3	equ 103
IDM_MENU1	equ 104
IDI_ICON0	equ 105
IDI_ICON1	equ 106
IDI_ICON2	equ 107
IDI_ICON3	equ 108
IDI_ICON4	equ 109
IDI_ICON5	equ 110
IDI_ICON6	equ 111
IDI_ICON7	equ 112
IDC_BUTTON1	equ 1001
IDC_RADIO1	equ 1002
IDC_RADIO2	equ 1003
IDC_RADIO3	equ 1004
IDC_CHECK1	equ 1005
IDC_CHECK2	equ 1006
IDC_CHECK3	equ 1007
IDC_CHECK4	equ 1008
IDC_CHECK5	equ 1009
IDC_CHECK6	equ 1010
IDC_CHECK7	equ 1011
IDC_CHECK8	equ 1012
IDC_IMAGE1	equ 1013
IDC_UPDOWN1	equ 1014
IDC_EDIT1	equ 1015
IDC_EDIT2	equ 1016
IDC_DATE1	equ 1018
IDC_DATE2	equ 1019
IDC_LIST1	equ 1020
ID_LAUNCH	equ 10001
ID_UPDATES	equ 10002
ID_SETUP	equ 10003
ID_CLOSE	equ 10004

.data?

hInstance		dd ?	;DLL instance
pHandles		dd ?	;Pointer to HANDLES structure
hMenu			dd ?	;Main menu handle
ItemID			dd ?	;Our menu item ID

;DWORD values kept in INI file. MUST match xKeys!
xValues			label DWORD
iIcon			dd ?	;Icon number (0-6)
dwTimer			dd ?	;Timer value
dwFolderDate	dd ?	;Folder last modified date
xBooleans		label DWORD
bLoadExe		dd ?	;Load exe?
bLoadUsed		dd ?	;Load used addins?
bLoadUnused		dd ?	;Load unused addins?
bLoadProject	dd ?	;Load last project?
bLoadWords		dd ?	;Load apis and keywords?
bPreserveTypes	dd ?	;Preserve filetypes?
bUpdates		dd ?	;Check for updates?
xValues_end		label DWORD

qwLastCheck		FILETIME <>		;Last date we checked for updates (0 means never)
qwNextCheck		FILETIME <>		;Next date we'll check for updates (0 means never)
qwFolderDate	FILETIME <>		;Last modified date for updates folder (0 means unknown)

szFolderURL		db MAX_PATH dup (?)		;Updates folder URL
szIniPath		db MAX_PATH+20 dup (?)	;Full path to WAAddIns.Ini

.data

; Obsolete keys to be deleted
xObsolete		label DWORD
				dd offset szProgDate
				dd offset szAddinsDate
				dd offset szProgUpdates
				dd offset szAddinUpdates
				dd offset szProgUpdatesURL
				dd offset szAddinUpdatesURL
xObsolete_end	label DWORD

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

;Strings for INI file keynames. MUST match xValues!
xKeys			label BYTE
sz Icon
sz Timer
sz FolderLastModified
sz LoadExe
sz LoadUsed
sz LoadUnused
sz LoadProject
sz LoadWords
sz PreserveTypes
sz CheckForUpdates
xKeys_end		label BYTE

sz LastCheck
sz NextCheck
sz LastProg
sz LastAddins
sz UpdatesFolderURL

; Obsolete keys to be deleted
sz ProgDate
sz AddinsDate
sz ProgUpdates
sz AddinUpdates
sz ProgUpdatesURL
sz AddinUpdatesURL

;Default URLs
szDefFolderURL	db "http://winasm.code4u.net/files",0			;Updates folder URL

;Your addin's menu item string
szMenuString	db "WinAsm Studio Agent setup",0

;Addin name and description (REQUIRED)
IFDEF DEBUG_BUILD
	szFriendlyName	db "WinAsm Studio Agent v1.1.0.1 DEBUG",0
ELSE
	szFriendlyName	db "WinAsm Studio Agent v1.1.0.1",0
ENDIF
szDescription	db "Tray icon on startup, pre-loading, updates checking and filetypes preserving.",13,10,\
				   "® 2004 Mario Vilas (aka QvasiModo)",0
