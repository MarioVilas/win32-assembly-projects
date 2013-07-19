; Import header for WAAddInLib.lib version 1.4.2.1
; Covers up to WinAsm Studio 3.0.2.7

ACCELERATOR STRUCT
	fVirt	WORD ? 
	key		WORD ? 
	cmd		WORD ?
ACCELERATOR ENDS

BUILD_MODE_RELEASE		equ 1	; Release build mode.
BUILD_MODE_DEBUG		equ 2	; Debug build mode.

INSTALL_STATE_CLEAR		equ 0	; Sets the install state to FALSE.
INSTALL_STATE_SET		equ 1	; Sets the install state to TRUE.
INSTALL_STATE_QUERY		equ 2	; Gets the install state.

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

; Docking windows
CreateDockingWindow		proto :PTR DOCKINGDATA, :DWORD, :PTR BYTE, :PTR BYTE
DestroyDockingWindow	proto :HWND, :PTR DOCKINGDATA, :PTR BYTE, :PTR BYTE

; CodeHi control
CHAppendText			proto :HWND, :PTR BYTE
CHInsertLine			proto :HWND, :PTR BYTE, :DWORD

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
