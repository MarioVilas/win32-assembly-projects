; -------------------------------------------------------------------------
; Common data
; -------------------------------------------------------------------------

include macros.inc
AppModel .386
include windows.inc
include resource.inc
incl kernel32,user32,comctl32,riched20,advapi32,masm32

include Errors.inc

DllEntryPoint   proto :DWORD,:DWORD,:DWORD
WorkerProc      proto :DWORD
ReadConfig      proto :DWORD
WriteConfig     proto
DlgProc         proto :DWORD,:DWORD,:DWORD,:DWORD

.const
sz Enabled
sz Error
sz WinErr
sz WindowPlacement
sz IsActive
sz LastCode
sz 0
sz 1
sz 2

;szMenuText  db "Windows Error Descriptions",0
szMenuText  equ <szName>
szName      db "Windows Error Descriptions",0
szDesc      db "This addin helps you lookup Windows error codes. Type the equate name, decimal or hexadecimal (prefixed ",34,"0x",34,") number.",0
szCopyright db "QvasiModo (Mario Vilas)",0

.data?
hInst       dd ?    ;Library instance handle
hMain       dd ?    ;MDI frame window handle
AddinMenu   dd ?    ;Addins menu handle
AddinID     dd ?    ;Addin menu ID
AddinPopup  dd ?    ;Addin popup handle
hWorker     dd ?    ;Worker thread handle
IdWorker    dd ?    ;Worker thread ID
hEvent      dd ?    ;Event signaled when worker thread can get messages
fActive     dd ?    ;TRUE when popup was visible on addin unloading
fModal      dd ?    ;TRUE when popup dialog should be modal

szINI		db (MAX_PATH + 20) dup (?)
wp          WINDOWPLACEMENT <>

; -------------------------------------------------------------------------
; AsmEdit addin support
; -------------------------------------------------------------------------

AsmEditProc     proto :DWORD,:DWORD,:DWORD,:DWORD

; Messages sent to AsmEdit
IDM_GETDWORDS           equ WM_USER+50
IDM_GETPROC             equ WM_USER+51
IDM_GETDATA             equ WM_USER+52

;IDM_NEW                 equ 6001
;IDM_OPEN                equ 6002
;IDM_CLOSE               equ 6004
;IDM_SAVEAS              equ 6006
;IDM_PRINT               equ 6010

ASMDWORDS struct
; IDM_GETDWORDS
      hWnd              dd 0   ; Handle of AsmEdit.
      hMenu             dd 0   ; Handle of AsmEdit Menu.
      hToolBar          dd 0   ; Handle of AsmEdit ToolBar.
      hStatus           dd 0   ; Handle of AsmEdit StatusBar.
      hREdit            dd 0   ; Handle of RichEdit window.
      MenuID            dd 0   ; Addin/Project menu item ID.
      ProjType          dd 0   ; Project type from create (.dll or .exe)
ASMDWORDS ends

ASMEPROC struct
; IDM_GETPROC
      lpBaseAscii       dd 0   ; Pointer to BaseAscii Proc.
      lpAsciiBase       dd 0   ; Pointer to AsciiBase Proc.
      lpEnaDisMenu      dd 0   ; Pointer to EnableDisableEditMenu Proc.
ASMEPROC ends

ASMEDATA struct
; IDM_GETDATA
      lpRootDir         dd 0   ; Pointer to root dir, ends with \.
      lpPathName        dd 0   ; Pointer to current full path.
      lpFileName        dd 0   ; Pointer to FileName.
      lpProjectName     dd 0   ; Pointer to Project Name.
      lpProjectPath     dd 0   ; Pointer to Project Path.
      lpRegKey          dd 0   ; AsmEdit registry key.
ASMEDATA ends

.const
szREG_SZ db "REG_SZ",0

.data?
;pHStruct    dd ?   ;Pointer to AsmEdit handles
;pPStruct    dd ?   ;Pointer to AsmEdit procedures
;pDStruct    dd ?   ;Pointer to AsmEdit data
;fAEInit     dd ?
AsmEditKey  db (MAX_PATH + sizeof szWinErr) dup (?)

; -------------------------------------------------------------------------
; Chrome addin support
; -------------------------------------------------------------------------

include AddInConst.inc

.data?
WAStructPtr     dd ?
FlagActive      dd ?
AddInContext    ADDINCONTEXT <>

; -------------------------------------------------------------------------
; QuickEditor plugin support
; -------------------------------------------------------------------------

QePlugIn proto :DWORD,:DWORD,:DWORD,:DWORD,:DWORD

; -------------------------------------------------------------------------
; RadAsm addin support
; -------------------------------------------------------------------------

include RadAsm.inc

InstallDll      proto :DWORD,:DWORD
DllProc         proto :DWORD,:DWORD,:DWORD,:DWORD

ifndef ADDINOPT
ADDINOPT struct
	lpStr	dd ?	;Pointer to CheckBox text
	nAnd	dd ?	;Option AND value
	nOr		dd ?	;Option OR value
ADDINOPT ends
endif

.data?
lpHandles   dd ?    ;Pointer to RadAsm handles
lpData      dd ?    ;Pointer to RadAsm data
lpProc      dd ?    ;Pointer to RadAsm procedures

.data
AddinOpt    ADDINOPT <offset szEnabled,1,1>
            ADDINOPT <0,0,0>

.const
szRAWinErrINI db "AddIns\"
szWinErrINI   db "WinErr.Ini",0
szChromeINI   db "Config\WinErr.Ini",0

; -------------------------------------------------------------------------
; WinAsm addin support
; -------------------------------------------------------------------------

include WAAddIn.inc

GetWAAddInData  proto :DWORD,:DWORD
WAAddInLoad     proto :DWORD,:DWORD
FrameWindowProc proto :DWORD,:DWORD,:DWORD,:DWORD
DockingProc     proto :DWORD,:DWORD,:DWORD,:DWORD
WAAddInUnload   proto

.const
szAddinsINI db "AddIns\WAAddIns.Ini",0

.data?
pHandles    dd ?    ;Pointer to WinAsm handles

ifdef USE_DOCKING_WINDOWS

SIZEOF_DOCKINGDATA equ 36   ;cannot use sizeof(DOCKINGDATA)
                            ; due to reserved fields in struct
OFFSET_DOCKINGDATA equ 4    ;skip the first dword (lpCaption)

.const
sz DockingData
sz DockingStyle
szOldWinAsm db "You need WinAsm version 2.0.0.2 or above to use this addin!",0

.data
AddInDockData DOCKINGDATA <offset szName,NODOCK,<120,120,320,200>,120,120,180,180>

.data?
dwDockingStyle dd ?
hDocking    dd ?    ;Handle to docking window
fDocking    dd ?    ;TRUE when using a docking window
pOldProc    dd ?    ;Pointer to old window proc for docking window

endif
