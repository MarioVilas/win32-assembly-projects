; Import header for WAAddInLib.lib version 1.4.2.4
; Covers up to WinAsm Studio 4.0.0.x

; -----------------------------------------------------------------------------
; Prototypes
; -----------------------------------------------------------------------------

; Misc
AddInAboutBox			proto :PTR BYTE, :PTR BYTE, :HICON
CheckWAVersion			proto :DWORD
InitializeAddIn			proto :HINSTANCE, :PTR HANDLES, :PTR FEATURES, :PTR BYTE

; Menu items
AddMenuItem				proto :DWORD, :PTR BYTE, :DWORD
AddMenuItemEx			proto :PTR BYTE, :DWORD, :DWORD, :DWORD
GetWASubMenu			proto :DWORD
NewAddinMenuItem		proto :PTR BYTE
NewHelpMenuItem			proto :PTR BYTE
NewProjectMenuItem		proto :PTR BYTE, :DWORD
NewViewMenuItem			proto :PTR BYTE, :BOOL
RemoveAddinMenuItem		proto :DWORD
RemoveHelpMenuItem		proto :DWORD
RemoveViewMenuItem		proto :DWORD

; Keyboard accelerators
AddAccelerator			proto :PTR ACCELERATOR
RemoveAccelerator		proto :PTR ACCELERATOR

; Image lists
GetWAImageList			proto :BOOL

; Docking windows
CreateDockingWindow		proto :PTR DOCKINGDATA, :DWORD, :PTR BYTE, :PTR BYTE
DestroyDockingWindow	proto :HWND, :PTR DOCKINGDATA, :PTR BYTE, :PTR BYTE

; CodeHi control
CHAppendText			proto :HWND, :PTR BYTE
CHInsertLine			proto :HWND, :PTR BYTE, :DWORD
GetActiveCodeHi			proto

; Output window
AppendOutputLine		proto :PTR BYTE, :DWORD
ClearOutputWindow		proto

; Project management
GetBuildMode			proto
GetOutputFile			proto :PTR BYTE, :DWORD
HideNonProjectFiles		proto
HideProjectFiles		proto
MarkProjectFilesAsSaved	proto
WasProjectModified		proto

; Add-Ins management
FindAddInClose			proto :HANDLE
FindFirstAddIn			proto :PTR WIN32_FIND_DATA, :PTR BYTE, :PTR BYTE, :PTR BOOL, :PTR BOOL
FindNextAddIn			proto :HANDLE, :PTR WIN32_FIND_DATA, :PTR BYTE, :PTR BYTE, :PTR BOOL, :PTR BOOL
InstallAddIn			proto :PTR BYTE, :DWORD
LoadAddIn				proto :PTR BYTE
QueryAddIn				proto :PTR BYTE, :PTR BYTE, :PTR BYTE, :PTR BOOL, :PTR BOOL
UnloadAddIn				proto :HINSTANCE

; -----------------------------------------------------------------------------
; Structures
; -----------------------------------------------------------------------------

; Keyboard accelerator descriptor
ACCELERATOR STRUCT
	fVirt	WORD ?		; Virtual flags (VK_SHIFT, VK_CTRL, etc.)
	key		WORD ?		; Virtual keycode
	cmd		WORD ?		; Command code (menu item ID)
ACCELERATOR ENDS

; -----------------------------------------------------------------------------
; Constants
; -----------------------------------------------------------------------------

; Menu item positions
MENU_POS_FILE		equ 0
MENU_POS_EDIT		equ 1
MENU_POS_VIEW		equ 2
MENU_POS_PROJECT	equ 3
MENU_POS_FORMAT		equ	4
MENU_POS_DIALOG		equ 5
MENU_POS_MAKE		equ	6
MENU_POS_SAB		equ	7	; Make -> Set Active Build
MENU_POS_TOOLS		equ	8
MENU_POS_ADDIN		equ	9
MENU_POS_WINDOW		equ	10
MENU_POS_HELP		equ 11
MENU_POS_NEWFILE	equ	12	; File -> New File
MENU_POS_CONVERT	equ	13	; Format -> Convert

; Special menu item positions
MENU_POS_BOTTOM		equ -1	; Place new item (or separator) at the bottom of the submenu.
MENU_POS_NOSEP		equ	-2	; Don't add a separator.

; Build modes
BUILD_MODE_RELEASE		equ 1	; Release build mode.
BUILD_MODE_DEBUG		equ 2	; Debug build mode.

; Install states for add-ins
INSTALL_STATE_CLEAR		equ 0	; Sets the install state to FALSE.
INSTALL_STATE_SET		equ 1	; Sets the install state to TRUE.
INSTALL_STATE_QUERY		equ 2	; Gets the install state.

; Background colors for a text line in the Output window
OUTPUT_COLOR_OK			equ 2
OUTPUT_COLOR_ERROR		equ	1
OUTPUT_COLOR_BACK		equ 0
