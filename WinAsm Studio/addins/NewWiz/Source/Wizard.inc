; New Project Wizard Add-In for WinAsm Studio
; Copyright (C) 2004 Mario Vilas (aka QvasiModo)
; All rights reserved.
; Freeware for any use. See readme.txt for licensing details.

IFNDEF TVINSERTSTRUCT
	TVINSERTSTRUCT equ <TV_INSERTSTRUCT>
ENDIF

;typedef enum _FINDEX_INFO_LEVELS {
;	FindExInfoStandard,
;	FindExInfoMaxInfoLevel
;} FINDEX_INFO_LEVELS;
IFNDEF FindExInfoStandard
	FindExInfoStandard equ 0
ENDIF
IFNDEF FindExInfoMaxInfoLevel
	FindExInfoMaxInfoLevel equ 1
ENDIF

;typedef enum _FINDEX_SEARCH_OPS {
;	FindExSearchNameMatch,
;	FindExSearchLimitToDirectories,
;	FindExSearchLimitToDevices,
;	FindExSearchMaxSearchOp
;} FINDEX_SEARCH_OPS;
IFNDEF FindExSearchNameMatch
	FindExSearchNameMatch equ 0
ENDIF
IFNDEF FindExSearchLimitToDirectories
	FindExSearchLimitToDirectories equ 1
ENDIF
IFNDEF FindExSearchLimitToDevices
	FindExSearchLimitToDevices equ 2
ENDIF
IFNDEF FindExSearchMaxSearchOp
	FindExSearchMaxSearchOp equ 3
ENDIF

NUM_OF_PAGES	equ 9

; Resource IDs
IDI_ICON1		EQU 100
IDI_ICON2		EQU 101
IDI_ICON3		EQU 102
IDI_ICON4		EQU 103
IDI_ICON5		EQU 104
IDI_ICON6		EQU 105
IDB_BITMAP1		EQU 150
IDB_BITMAP3		EQU 152
IDB_BITMAP4		EQU 153
IDB_BITMAP6		EQU 154
IDB_BITMAP7		EQU 155
IDB_BITMAP8		EQU 156
IDB_BITMAP9		EQU 157
IDB_BITMAP10	EQU 158
IDB_BITMAP11	EQU 159
IDB_BITMAP12	EQU 160
IDB_BITMAP13	EQU 161
IDD_PAGE1		EQU 200
IDD_PAGE2_1		EQU 201
IDD_PAGE2_2		EQU 202
IDD_PAGE2_3		EQU 203
IDD_PAGE2_4		EQU 204
IDD_PAGE3_2		EQU 205
IDD_PAGE3_3		EQU 206
IDD_PAGE3_4		EQU 207
IDD_PAGE4		EQU 208
IDD_PROP1		EQU 300
IDD_PROP2		EQU 301
IDD_PROP3		EQU 302
IDD_DIALOG1		EQU 400
IDD_DIALOG2		EQU 401
IDM_MENU1		EQU 500
IDC_BUTTON1		EQU 1000
IDC_BUTTON2		EQU 1001
IDC_BUTTON3		EQU 1002
IDC_BUTTON4		EQU 1003
IDC_BUTTON5		EQU 1004
IDC_BUTTON6		EQU 1005
IDC_BUTTON7		EQU 1006
IDC_BUTTON8		EQU 1007
IDC_BUTTON9		EQU 1008
IDC_BUTTON10	EQU 1009
IDC_BUTTON11	EQU 1010
IDC_BUTTON12	EQU 1011
IDC_BUTTON13	EQU 1012
IDC_BUTTON15	EQU 1013
IDC_BUTTON14	EQU 1014
IDC_BUTTON16	EQU 1015
IDC_BUTTON17	EQU 1016
IDC_BUTTON18	EQU 1017
IDC_BUTTON20	EQU 1019
IDC_BUTTON21	EQU 1020
IDC_CHECK1		EQU 1100
IDC_CHECK2		EQU 1101
IDC_CHECK3		EQU 1102
IDC_CHECK4		EQU 1103
IDC_CHECK5		EQU 1104
IDC_CHECK6		EQU 1105
IDC_COMBO1		EQU 1106
IDC_COMBO2		EQU 1107
IDC_COMBO3		EQU 1108
IDC_COMBO4		EQU 1109
IDC_EDIT1		EQU 1200
IDC_EDIT3		EQU 1202
IDC_EDIT4		EQU 1203
IDC_EDIT5		EQU 1204
IDC_EDIT6		EQU 1205
IDC_EDIT7		EQU 1206
IDC_EDIT8		EQU 1207
IDC_EDIT9		EQU 1208
IDC_EDIT10		EQU 1209
IDC_EDIT11		EQU 1210
IDC_EDIT12		EQU 1211
IDC_LIST1		EQU 1300
IDC_LIST2		EQU 1301
IDC_LIST3		EQU 1302
IDC_RADIO1		EQU 1400
IDC_RADIO2		EQU 1401
IDC_RADIO3		EQU 1402
IDC_RADIO4		EQU 1403
IDC_TREE1		EQU 1500
IDC_TREE2		EQU 1501
IDC_TREE3		EQU 1502
IDC_TREE4		EQU 1503
IDC_TREE5		EQU 1504
IDC_STATIC1		EQU 1600
IDC_CHECK10		EQU 1710
IDC_CHECK11		EQU 1711
IDC_COMBO5		EQU 1712
ID_CONTEXT_REMOVE	EQU 10000
ID_COMMAND_CLASSIC	EQU 10001

;Function prototypes
GetTreePath			proto hWnd:HWND, dwID:DWORD, hItem:DWORD
ExpandTreeFolder	proto hWnd:HWND, dwID:DWORD, hItem:DWORD
ExpandTreePath		proto hWnd:HWND, dwID:DWORD
GetDrives			proto hWnd:HWND, dwID:DWORD
CenterWindow		proto hWnd:HWND
BuildCmdsToEdit		proto hWnd:HWND
BuildCmdsFromEdit	proto hWnd:HWND
DlgProc1			proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
DlgProc21			proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
DlgProc22			proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
DlgProc23			proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
DlgProc24			proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
DlgProc32			proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
DlgProc33			proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
DlgProc34			proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
DlgProc4			proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
PropDlgProc1		proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
PropDlgProc2		proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
SwitchProc			proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
ConfigProc			proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

.data?
hProjPropPage1	dd ?	;Handle of "Build" dialog (page) at project properties
hProjPropPage2	dd ?	;Handle of "Run" dialog (page) at project properties
hProjPropPage3	dd ?	;Handle of "Misc" dialog (page) at project properties
hSysIml			dd ?	;Handle of system imagelist (normal icons)
hSysSmIml		dd ?	;Handle of system imagelist (small icons)

bProjHasFilename	dd ?					; Project was saved at least once
dwWizChoice			dd ?					; "Next" page chosen at IDD_PAGE1
dwProjectType		equ <lvi.iItem>			; Project type (0-6)
bDoIt				dd ?					; If TRUE the user clicked on "Finish"
bSaveWap			dd ?					; If TRUE save the WAP file
bGoAll				dd ?					; If TRUE emulate click on "Go All"
bRemember			dd ?					; If TRUE save last taken choices

pFilesToAdd			dd ?					; Pointer to ASCIIZ string of files to
	 										; add to the project (full pathnames)
	 										; MUST be freed with LocalFree!

;IDs of private messages (to notify all addins)
dwWANewWizAddInBegin	dd ?
dwWANewWizAddInEnd		dd ?
dwProjPropMsg			dd ?
dwWANWSetEnvVars		dd ?

shfi	SHFILEINFO <>

szChosenTemplate	db MAX_PATH dup (?)		; Full path to last chosen project template
szChosenCloneSrc	db MAX_PATH dup (?)		; Full path to last chosen project to be cloned
szUseTemplate		db MAX_PATH dup (?)		; Full path to source project template
szUseTemplateWap	db MAX_PATH dup (?)		; Full path to source project file in template
szTemplateTitle		db MAX_PATH dup (?)		; Title of template project
szTargetTitle		db MAX_PATH dup (?)		; Title for the new project
szTemplateMask		db MAX_PATH dup (?)		; Filemask of template project files to rename
szTargetFolder		db MAX_PATH dup (?)		; Full path to target project folder
szProjectFile 		db MAX_PATH dup (?)		; Full path to target project file
szTemplatesPath		db MAX_PATH dup (?)		; Path to template folders
szTargetWap			db MAX_PATH dup (?)		; Target project filename

szDefProjectFolder	db MAX_PATH dup (?)		; WinAsm's default project folder
szCustFilter		db MAX_PATH dup (?)
szCurrentFolder		db MAX_PATH dup (?)
szGlobalCurrDir		db MAX_PATH dup (?)
szChangeFolder		db MAX_PATH*5 dup (?)

.data
OFN_FLAGS equ OFN_ALLOWMULTISELECT or OFN_EXPLORER or OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_NOCHANGEDIR
OUTOFN_FLAGS equ OFN_EXPLORER or OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_NOCHANGEDIR
ofn		OPENFILENAME <sizeof OPENFILENAME,,,offset szFilter,offset szCustFilter,sizeof szCustFilter,0,offset szChangeFolder,sizeof szChangeFolder,0,0,offset szDefProjectFolder,offset szTitle,OFN_FLAGS>
outofn	OPENFILENAME <sizeof OPENFILENAME,,,offset szOutFilter,0,0,0,offset szChangeFolder,sizeof szChangeFolder,0,0,offset szDefProjectFolder,offset szOutTitle,OUTOFN_FLAGS>

; Project types
ptype0	LVITEM <LVIF_TEXT or LVIF_IMAGE,0,0,,,offset szType0,,0,>	; Standard EXE
ptype1	LVITEM <LVIF_TEXT or LVIF_IMAGE,1,0,,,offset szType1,,1,>	; Standard DLL
ptype2	LVITEM <LVIF_TEXT or LVIF_IMAGE,2,0,,,offset szType2,,2,>	; Console Application
ptype3	LVITEM <LVIF_TEXT or LVIF_IMAGE,3,0,,,offset szType3,,3,>	; Static Library
ptype4	LVITEM <LVIF_TEXT or LVIF_IMAGE,4,0,,,offset szType4,,4,>	; Other (EXE)
ptype5	LVITEM <LVIF_TEXT or LVIF_IMAGE,5,0,,,offset szType5,,5,>	; Other (Non-EXE)
ptype6	LVITEM <LVIF_TEXT or LVIF_IMAGE,6,0,,,offset szType6,,6,>	; DOS Project

lvi		LVITEM <LVIF_STATE,,0,LVIS_FOCUSED or LVIS_SELECTED,\
				LVIS_FOCUSED or LVIS_SELECTED or LVIS_DROPHILITED or LVIS_CUT>

; Listview columns (PAGE3_3)
lvc30	LVCOLUMN <LVCF_FMT or LVCF_SUBITEM or LVCF_TEXT or LVCF_WIDTH,LVCFMT_LEFT,100,offset szCol30,,0>
lvc31	LVCOLUMN <LVCF_FMT or LVCF_SUBITEM or LVCF_TEXT or LVCF_WIDTH,LVCFMT_LEFT,200,offset szCol31,,1>

; Property sheet pages (wizard)
ppsph	PROPSHEETHEADER <sizeof PROPSHEETHEADER,\
	 		PSH_USEICONID or PSH_PROPSHEETPAGE or PSH_WIZARD or \
	 		PSH_WIZARD97 or PSH_HEADER or PSH_WATERMARK,\
	 		0,0,<IDI_ICON1>,NULL,NUM_OF_PAGES,<0>,<offset psp1>,,<IDB_BITMAP1>,,<>>
	 		; or PSH_WIZARDCONTEXTHELP
psp1	PROPSHEETPAGE <sizeof PROPSHEETPAGE,\
	 		PSP_USEHEADERTITLE or PSP_USEHEADERSUBTITLE,\
	 		,<IDD_PAGE1>,<>,,offset DlgProc1,,,,offset szTitle1,offset szSubtitle1>
psp21	PROPSHEETPAGE <sizeof PROPSHEETPAGE,\
	 		PSP_USEHEADERTITLE or PSP_USEHEADERSUBTITLE,\
	 		,<IDD_PAGE2_1>,<>,,offset DlgProc21,,,,offset szTitle21,offset szSubtitle21>
psp22	PROPSHEETPAGE <sizeof PROPSHEETPAGE,\
	 		PSP_USEHEADERTITLE or PSP_USEHEADERSUBTITLE,\
	 		,<IDD_PAGE2_2>,<>,,offset DlgProc22,,,,offset szTitle22,offset szSubtitle22>
psp32	PROPSHEETPAGE <sizeof PROPSHEETPAGE,\
	 		PSP_USEHEADERTITLE or PSP_USEHEADERSUBTITLE,\
	 		,<IDD_PAGE3_2>,<>,,offset DlgProc32,,,,offset szTitle22,offset szSubtitle32>
psp23	PROPSHEETPAGE <sizeof PROPSHEETPAGE,\
	 		PSP_USEHEADERTITLE or PSP_USEHEADERSUBTITLE,\
	 		,<IDD_PAGE2_3>,<>,,offset DlgProc23,,,,offset szTitle23,offset szSubtitle23>
psp33	PROPSHEETPAGE <sizeof PROPSHEETPAGE,\
	 		PSP_USEHEADERTITLE or PSP_USEHEADERSUBTITLE,\
	 		,<IDD_PAGE3_3>,<>,,offset DlgProc33,,,,offset szTitle23,offset szSubtitle33>
psp24	PROPSHEETPAGE <sizeof PROPSHEETPAGE,\
	 		PSP_USEHEADERTITLE or PSP_USEHEADERSUBTITLE,\
	 		,<IDD_PAGE2_4>,<>,,offset DlgProc24,,,,offset szTitle24,offset szSubtitle24>
psp34	PROPSHEETPAGE <sizeof PROPSHEETPAGE,\
	 		PSP_USEHEADERTITLE or PSP_USEHEADERSUBTITLE,\
	 		,<IDD_PAGE3_4>,<>,,offset DlgProc34,,,,offset szTitle24,offset szSubtitle34>
psp4	PROPSHEETPAGE <sizeof PROPSHEETPAGE,\
	 		PSP_USEHEADERTITLE or PSP_USEHEADERSUBTITLE,\
	 		,<IDD_PAGE4>,<>,,offset DlgProc4,,,,offset szTitle1,offset szSubtitle4>
	 		; or PSP_PREMATURE

; Property sheet pages (project properties)
projpph	PROPSHEETHEADER <sizeof PROPSHEETHEADER,\
	 		PSH_NOAPPLYNOW or PSH_USEICONID  or PSH_PROPSHEETPAGE,,,\
	 		<IDI_ICON1>,offset szProjProp,3,<0>,<offset projp1>,,\
	 		<IDB_BITMAP1>,,<>>
projp1	PROPSHEETPAGE <sizeof PROPSHEETPAGE,PSP_DEFAULT or PSP_USEICONID or PSP_PREMATURE,,\
	 		<IDD_PROP1>,<>,,offset PropDlgProc1,,,,,>
projp2	PROPSHEETPAGE <sizeof PROPSHEETPAGE,PSP_DEFAULT or PSP_USEICONID or PSP_PREMATURE,,\
	 		<IDD_PROP2>,<>,,offset PropDlgProc2,,,,,>
projp3	PROPSHEETPAGE <sizeof PROPSHEETPAGE,PSP_DEFAULT or PSP_USEICONID or PSP_PREMATURE,,\
	 		<IDD_PROP3>,<>,,offset PropDlgProc3,,,,,>

; Property sheet strings (added some spaces in front to leave room for the picture)
szTitle1		db "                New project wizard",0
szSubtitle1		db "                Welcome to the new project wizard!",0

szTitle21		db "                Create new empty project",0
szSubtitle21	db "                Select project type to create",0

szTitle22		db "                Create new project from a template",0
szSubtitle22	db "                Select template to use",0

szTitle23		db "                Create new project from existing sources",0
szSubtitle23	db "                Select project type to convert",0

szTitle24		db "                Clone an existing project",0
szSubtitle24	db "                Select a project to clone",0

;szTitle32		db "                Create new project from a template",0
szSubtitle32	db "                Choose target project folder",0

;szTitle33		db "                Create new project from existing sources",0
szSubtitle33	db "                Include your project files",0

;szTitle34		db "                Clone an existing project",0
szSubtitle34	db "                Select a folder to save cloned project",0

;szTitle4		db "                Create new project",0
szSubtitle4		db "                The new project is about to be created.",0

szProjProp		db "                Project Properties",0

; Project type names
szType0			db "Standard EXE",0
szType1			db "Standard DLL",0
szType2			db "Console Application",0
szType3			db "Static Library",0
szType4			db "Other (EXE)",0
szType5			db "Other (Non-EXE)",0
szType6			db "DOS Project",0

; Listview columns (PAGE3_3)
szCol30			db "Filename",0
szCol31			db "Location",0

; Private messages to notify addins
szWANewWizAddInBegin	db "WANewWizAddInBegin",0
szWANewWizAddInEnd		db "WANewWizAddInEnd",0
szProjPropMsg			db "WAProjPropMsg",0
szWANWSetEnvVars		db "WANWSetEnvVars",0

; Command line history kept in .wap files
szCmdHistory	db "CmdHistory",0
szReleaseCmd	db "ReleaseCmd_"	;fall through
szReleaseCmdNum	db 20 dup (0)
szDebugCmd		db "DebugCmd_"		;fall through
szDebugCmdNum	db 20 dup (0)

; Misc strings
szNewProjectMainWindowCaption	db "WinAsm Studio: New Project",0
szNewProjectTitle				db "New Project",0
szNewProjectFile				db "New Project.wap",0

;szButton		db "Button",0
;szClassic		db "Classic",0

szShell32		db "Shell32.dll",0

szMaskAll		db "*.*",0,0	;Extra NULL for use with SHFileOperation
szMaskWap		db "*.wap",0
szDotDot		db "..",0
szDotWap		db ".wap",0		;Extension for project files
szDotAsm		db ".asm",0		;Extensions for source files
szDotInc		db ".inc",0
szDotRc			db ".rc",0
szDotTxt		db ".txt",0
szDotDef		db ".def",0
szDotBat		db ".bat",0
szDotExe		db ".exe",0		;Extensions for binary files
szExtensions 	label BYTE
	 			db ".dll",0
	 			db ".lib",0
	 			db ".bin",0		;Not sure about this one...
szTemplatesDir	db "Templates",0
szPROJECT		db "PROJECT",0
szType			db "Type",0
szTitle			db "Select source file to include in your project",0
szOutTitle		db "Select the name of the output binary file for your project",0
szFilter		label BYTE
	 			db "All assembly source files",0,"*.asm;*.inc;*.rc;*.txt;*.def;*.bat",0
	 			db "All files (*.*)",0,"*.*",0
	 			db "Assembly files (*.asm)",0,"*.asm",0
	 			db "Include files (*.inc)",0,"*.inc",0
	 			db "Resource files (*.rc)",0,"*.rc",0
	 			db "Text files (*.txt)",0,"*.txt",0
	 			db "Definition files (*.def)",0,"*.def",0
	 			db "Batch files (*.bat)",0,"*.bat",0
	 			db 0	;End of array
szOutFilter		label BYTE
	 			db "All binary files",0,"*.exe;*.dll;*.lib;*.ocx;*.com;*.sys;*.vxd;*.drv;*.bin",0
	 			db "All files (*.*)",0,"*.*",0
	 			db "Executable files (*.exe)",0,"*.exe",0
	 			db "Dynamic link libraries (*.dll)",0,"*.dll",0
	 			db "Static link libraries (*.lib)",0,"*.lib",0
	 			db "DOS executables (*.bin, *.com, *.exe, *.sys)",0,"*.bin;*.com;*.exe;*.sys",0
	 			db "Other files",0,"*.ocx;*.vxd;*.drv",0
	 			db 0	;End of array

; Command line switches help
;szHlpSwitches_RC		db "The resource builder (RC.EXE) will add resources to your program."
;	 					db " This can be dialog boxes, pictures, sounds, etc.",13,10,13,10
;	 					db "Usage: RC [options] .RC input file",13,10,0
;szHlpSwitches_CVTRES	db "The resource converter can optionally be used to convert compiled"
;	 					db " resource files (*.res) into object files (*.obj).",13,10,13,10
;	 					db "Usage: CVTRES [options] ResFile",13,10,0
;szHlpSwitches_ML		db "The assembler (ML.EXE) will compile your sources (*.asm, *.inc)"
;	 					db " into object files (*.obj).",13,10,13,10
;	 					db "Usage: ML [ /options ] filelist [ /link linkoptions ]",13,10,0
;szHlpSwitches_LINK		db "The linker (LINK.EXE) will link object files (*.obj) and static"
;	 					db " libraries (*.lib) into your output file (usually *.exe).",13,10,13,10
;	 					db "Usage: LINK [options] [files] [@commandfile]",13,10,0
;szHlpSwitches_OUT		db "The is the filename to your project's output binary file."
;	 					db " For example, if you're building a standalone program this would"
;	 					db " be the name of the EXE file.",0

; Command line switches and their descriptions
szCmdSwitches_RC label BYTE		;----------------- RC.EXE
db "/r",0
	db "Emit .RES file (optional)",0
db "/v",0
	db "Verbose (print progress messages)",0
db "/d",0
	db "Define a symbol",0
db "/u",0
	db "Undefine a symbol",0
db "/fo",0
	db "Rename .RES file",0
db "/l",0
	db "Default language ID in hex",0
db "/i",0
	db "Add a path for INCLUDE searches",0
db "/x",0
	db "Ignore INCLUDE environment variable",0
db "/c",0
	db "Define a code page used by NLS conversion",0
db "/w",0
	db "Warn on Invalid codepage in .rc (default is an error)",0
db "/n",0
	db "Append null's to all strings in the string tables. Flags may be either upper or lower case",0
db 0	;End of array

szCmdSwitches_CVTRES label BYTE	;------------- CVTRES.EXE
; Could you believe I haven't found any info on CVTRES.EXE command line options?
db "/MACHINE:{ IX86 | ALPHA | ARM | AXP64 | IA64 | MIPS | MIPS16 | MIPSR41XX | PPC | SH3 | SH4 }",0
	db " ",0
		db 9,"/MACHINE:IX86",0
		db 9,"/MACHINE:ALPHA",0
		db 9,"/MACHINE:ARM",0
		db 9,"/MACHINE:AXP64",0
		db 9,"/MACHINE:IA64",0
		db 9,"/MACHINE:MIPS",0
		db 9,"/MACHINE:MIPS16",0
		db 9,"/MACHINE:MIPSR41XX",0
		db 9,"/MACHINE:PPC",0
		db 9,"/MACHINE:SH3",0
		db 9,"/MACHINE:SH4",0
db "/NOLOGO",0
	db " ",0
db "/OUT:filename",0
	db " ",0
db "/READONLY",0
	db " ",0
db "/VERBOSE",0
	db " ",0
db "/WINDOWSCE[:{ CONVERT | EMULATION }]",0
	db " ",0
		db 9,"/WINDOWSCE",0
		db 9,"/WINDOWSCE:CONVERT",0
		db 9,"/WINDOWSCE:EMULATION",0
db 0	;End of array

szCmdSwitches_ML label BYTE		;----------------- ML.EXE
db "/AT",0
	db "Enables tiny-memory-model support. Enables error messages for code constructs that violate the requirements for .com format files. Note that this is not equivalent to the .MODEL TINY directive.",0
db "/Bl filename",0
	db "Selects an alternate linker.",0
db "/c",0
	db "Assembles only. Does not link.",0
db "/coff",0
	db "Generates common object file format (COFF) type of object module. Generally required for Win32 assembly language development.",0
db "/Cp",0
	db "Preserves case of all user identifiers.",0
db "/Cu",0
	db "Maps all identifiers to upper case (default).",0
db "/Cx",0
	db "Preserves case in public and extern symbols.",0
db "/D symbol[[=value]]",0
	db "Defines a text macro with the given name. If value is missing, it is blank. Multiple tokens separated by spaces must be enclosed in quotation marks.",0
db "/EP",0
	db "Generates a preprocessed source listing (sent to STDOUT). See /Sf.",0
db "/F hexnum",0
	db "Sets stack size to hexnum bytes (this is the same as /link /STACK:number). The value must be expressed in hexadecimal notation. There must be a space between /F and hexnum.",0
db "/Fe filename",0
	db "Names the executable file.",0
db "/Fl [[filename]]",0
	db "Generates an assembled code listing. See /Sf.",0
		db 9,"/Fl",0
		db 9,"/Fl filename",0
db "/Fm [[filename]]",0
	db "Creates a linker map file.",0
		db 9,"/Fm",0
		db 9,"/Fm filename",0
db "/Fo filename",0
	db "Names an object file.",0
db "/FPi",0
	db "Generates emulator fix-ups for floating-point arithmetic (mixed language only).",0
db "/Fr [[filename]]",0
	db "Generates a source browser .sbr file.",0
		db 9,"/Fr",0
		db 9,"/Fr filename",0
db "/FR [[filename]]",0
	db "Generates an extended form of a source browser .sbr file.",0
		db 9,"/FR",0
		db 9,"/FR filename",0
db "/Gc",0
	db "Specifies use of FORTRAN- or Pascal-style function calling and naming conventions. Same as OPTION LANGUAGE:PASCAL.",0
db "/Gd",0
	db "Specifies use of C-style function calling and naming conventions. Same as OPTION LANGUAGE:C.",0
db "/H number",0
	db "Restricts external names to number significant characters. The default is 31 characters.",0
;db "/help",0
;	db " Calls QuickHelp for help on ML.",0
db "/I pathname",0
	db "Sets path for include file. A maximum of 10 /I options is allowed.",0
db "/nologo",0
	db "Suppresses messages for successful assembly.",0
db "/omf",0
	db "Generates object module file format (OMF) type of object module.",0
db "/Sa",0
	db "Turns on listing of all available information.",0
db "/safeseh",0
	db "Marks the object as either containing no exception handlers or containing exception handlers that are all declared with .SAFESEH.",0
db "/Sc",0
	db "Adds instruction timings to listing file.",0
db "/Sf",0
	db "Adds first-pass listing to listing file.",0
db "/Sg",0
	db "Turns on listing of assembly-generated code.",0
db "/Sl",0
	db "width Sets the line width of source listing in characters per line. Range is 60 to 255 or 0. Default is 0. Same as PAGE width.",0
db "/Sn",0
	db "Turns off symbol table when producing a listing.",0
db "/Sp",0
	db "length Sets the page length of source listing in lines per page. Range is 10 to 255 or 0. Default is 0. Same as PAGE length.",0
db "/Ss text",0
	db "Specifies text for source listing. Same as SUBTITLE text.",0
db "/St text",0
	db "Specifies title for source listing. Same as TITLE text.",0
db "/Sx",0
	db "Turns on false conditionals in listing.",0
db "/Ta filename",0
	db "Assembles source file whose name does not end with the .asm extension.",0
db "/w",0
	db "Same as /W0.",0
db "/W level",0
	db "Sets the warning level, where level = 0, 1, 2, or 3.",0
db "/WX",0
	db "Returns an error code if warnings are generated.",0
db "/Zd",0
	db "Generates line-number information in object file.",0
db "/Zf",0
	db "Makes all symbols public.",0
db "/Zi",0
	db "Generates CodeView information in object file.",0
db "/Zm",0
	db "Enables M510 option for maximum compatibility with MASM 5.1.",0
db "/Zp [[alignment]]",0
	db "Packs structures on the specified byte boundary. The alignment can be 1, 2, or 4.",0
		db 9,"/Zp",0
		db 9,"/Zp alignment",0
db "/Zs",0
	db "Performs a syntax check only.",0
;db "/?",0
;	db "Displays a summary of ML command-line syntax.",0
db 0	;End of array

szCmdSwitches_LINK label BYTE	;--------------- LINK.EXE
db "@ :response_file",0
	db "Specifies a response file",0 
db "/ALIGN[:number]",0
	db "Specifies the alignment of each section",0
		db 9,"/ALIGN",0
		db 9,"/ALIGN:number",0
db "/ALLOWBIND[:NO]",0
	db "Specifies that a DLL cannot be bound",0
		db 9,"/ALLOWBIND",0
		db 9,"/ALLOWBIND:NO",0
db "/ASSEMBLYDEBUG[:DISABLE]",0
	db "Adds the DebuggableAttribute to a managed image.",0
		db 9,"/ASSEMBLYDEBUG",0
		db 9,"/ASSEMBLYDEBUG:DISABLE",0
db "/ASSEMBLYLINKRESOURCE:filename",0
	db "Create a link to a managed resource.",0
db "/ASSEMBLYMODULE:filename",0
	db "Specifies that a Microsoft Intermediate Language (MSIL) module should be imported into the assembly",0
db "/ASSEMBLYRESOURCE:filename",0
	db "Embeds a managed resource file to an assembly",0
db "/BASE:{address | @filename,key}",0
	db "Sets a base address for the program",0
		db 9,"/BASE:address",0
		db 9,"/BASE:@filename,key",0
db "/DEBUG",0
	db "Creates debugging information",0
db "/DEBUGTYPE:{CV | COFF | BOTH}",0
	db "Specifies the type of debugging information to generate",0
		db 9,"/DEBUGTYPE:CV",0
		db 9,"/DEBUGTYPE:COFF",0
		db 9,"/DEBUGTYPE:BOTH",0
db "/DEF:filename",0
	db "Passes a module-definition (.def) file to the linker",0
db "/DEFAULTLIB:library",0
	db "Searches the specified library when resolving external references",0
db "/DELAY[:UNLOAD | :NOBIND]",0
	db "Controls the delayed loading of DLLs",0
		db 9,"/DELAY",0
		db 9,"/DELAY:UNLOAD",0
		db 9,"/DELAY:NOBIND",0
db "/DELAYLOAD:dllname",0
	db "Causes the delayed loading of the specified DLL",0
db "/DELAYSIGN[:NO]",0
	db "Partially sign an assembly.",0
		db 9,"/DELAYSIGN",0
		db 9,"/DELAYSIGN:NO",0
db "/DLL",0
	db "Builds a DLL",0
db "/DRIVER[:UPONLY | :WDM]",0
	db "Creates a Windows NT kernel mode driver",0
		db 9,"/DRIVER",0
		db 9,"/DRIVER:UPONLY",0
		db 9,"/DRIVER:WDM",0
db "/ENTRY:function",0
	db "Sets the starting address",0
db "/EXETYPE[:DYNAMIC | :DEV386]",0
	db "Builds a virtual device driver",0
		db 9,"/EXETYPE",0
		db 9,"/EXETYPE:DYNAMIC",0
		db 9,"/EXETYPE:DEV386",0
db "/EXPORT:entryname[,@ordinal[,NONAME]][,DATA]",0
	db "Exports a function",0
		db 9,"/EXPORT:entryname",0
		db 9,"/EXPORT:entryname,DATA",0
		db 9,"/EXPORT:entryname,@ordinal",0
		db 9,"/EXPORT:entryname,@ordinal,NONAME",0
		db 9,"/EXPORT:entryname,@ordinal,DATA",0
		db 9,"/EXPORT:entryname,@ordinal,NONAME,DATA",0
db "/FIXED[:NO]",0
	db "Creates a program that can be loaded only at its preferred base address",0
		db 9,"/FIXED",0
		db 9,"/FIXED:NO",0
db "/FORCE:[MULTIPLE | UNRESOLVED]",0
	db "Forces a link to complete in spite of unresolved or symbols defined more than once",0
		db 9,"/FORCE",0
		db 9,"/FORCE:MULTIPLE",0
		db 9,"/FORCE:UNRESOLVED",0
db "/HEAP:reserve[,commit]",0
	db "Sets the size of the heap in bytes",0
		db 9,"/HEAP:reserve",0
		db 9,"/HEAP:reserve,commit",0
db "/IDLOUT:[path\]filename",0
	db "Specifies the name of the .idl file and other MIDL output files",0
		db 9,"/IDLOUT:filename",0
		db 9,"/IDLOUT:path\filename",0
db "/IGNOREIDL",0
	db "Prevents processing attribute information into an .idl file",0
db "/IMPLIB:filename",0
	db "Overrides the default import library name",0
db "/INCLUDE:symbol",0
	db "Forces symbol references",0
db "/INCREMENTAL[:NO]",0
	db "Controls incremental linking",0
		db 9,"/INCREMENTAL",0
		db 9,"/INCREMENTAL:NO",0
db "/KEYCONTAINER:name",0
	db "Specify a key container to sign an assembly.",0
db "/KEYFILE:filename",0
	db "Specify key or key pair to sign an assembly.",0
db "/LARGEADDRESSAWARE[:NO]",0
	db "Tells the compiler that the application supports addresses larger than two gigabytes",0
		db 9,"/LARGEADDRESSAWARE",0
		db 9,"/LARGEADDRESSAWARE:NO",0
db "/LIBPATH:dir",0
	db "Allows the user to override the environmental library path",0
db "/LTCG[:NOSTATUS | :STATUS]",0
	db "Specifies link-time code generation",0
		db 9,"/LTCG",0
		db 9,"/LTCG:NOSTATUS",0
		db 9,"/LTCG:STATUS",0
db "/MACHINE:{AM33|ARM|EBC|IA64|M32R|MIPS|MIPS16|MIPSFPU|MIPSFPU16|MIPSR41XX|SH3|SH3DSP|SH4|SH5|THUMB|X86}",0
	db "Specifies the target platform",0
		db 9,"/MACHINE:AM33",0
		db 9,"/MACHINE:ARM",0
		db 9,"/MACHINE:EBC",0
		db 9,"/MACHINE:IA64",0
		db 9,"/MACHINE:M32R",0
		db 9,"/MACHINE:MIPS",0
		db 9,"/MACHINE:MIPS16",0
		db 9,"/MACHINE:MIPSFPU",0
		db 9,"/MACHINE:MIPSFPU16",0
		db 9,"/MACHINE:MIPSR41XX",0
		db 9,"/MACHINE:SH3",0
		db 9,"/MACHINE:SH3DSP",0
		db 9,"/MACHINE:SH4",0
		db 9,"/MACHINE:SH5",0
		db 9,"/MACHINE:THUMB",0
		db 9,"/MACHINE:X86",0
db "/MAP[:filename]",0
	db "Creates a mapfile",0
		db 9,"/MAP",0
		db 9,"/MAP:filename",0
db "/MAPINFO:{EXPORTS|LINES}",0
	db "Includes the specified information in the mapfile",0
		db 9,"/MAPINFO:EXPORTS",0
		db 9,"/MAPINFO:LINES",0
db "/MERGE:from=to",0
	db "Combines sections",0
db "/MIDL",0
	db ":@file Specifies MIDL command line options",0
db "/NOASSEMBLY",0
	db "Suppresses the creation of a .NET Framework assembly",0
db "/NODEFAULTLIB[:library]",0
	db "Ignores all (or specified) default libraries when resolving external references",0
		db 9,"/NODEFAULTLIB",0
		db 9,"/NODEFAULTLIB:library",0
db "/NOENTRY",0
	db "Creates a resource-only DLL",0
db "/NOLOGO",0
	db "Suppresses startup banner",0
db "/OPT:{REF|NOREF}",0
	db "Controls LINK optimizations",0
		db 9,"/OPT:REF",0
		db 9,"/OPT:NOREF",0
db "/OPT:{ICF[=iterations]|NOICF}",0
	db "Controls LINK optimizations",0
		db 9,"/OPT:ICF",0
		db 9,"/OPT:ICF=iterations",0
		db 9,"/OPT:NOICF",0
db "/OPT:{WIN98|NOWIN98}",0
	db "Controls LINK optimizations",0
		db 9,"/OPT:WIN98",0
		db 9,"/OPT:NOWIN98",0
db "/ORDER:@filename",0
	db "Places COMDATs into the image in a predetermined order",0
db "/OUT:filename",0
	db "Specifies the output file name",0
db "/PDB:filename",0
	db "Creates a program database (PDB) file",0
db "/PDBSTRIPPED:pdb_file_name",0
	db "Creates a program database (PDB) file with no private symbols",0
db "/RELEASE",0
	db "Sets the Checksum in the .exe header",0
db "/SAFESEH[:NO]",0
	db "Specify that the image will contain a table of safe exception handlers.",0
		db 9,"/SAFESEH",0
		db 9,"/SAFESEH:NO",0
db "/SECTION:name,[E][R][W][S][D][K][L][P][X][,ALIGN=#]",0
	db "Overrides the attributes of a section",0
		db 9,"/SECTION:name",0
		db 9,"/SECTION:name,ERWSDKLPX",0
		db 9,"/SECTION:name,ERWSDKLPX,ALIGN=#",0
db "/STACK:reserve",0
	db "Sets the size of the stack in bytes",0
		db 9,"/STACK:reserve",0
		db 9,"/STACK:reserve,commit",0
db "/STUB:filename",0
	db "Attaches an MS-DOS stub program to a Win32 program",0
db "/SUBSYSTEM:{CONSOLE|EFI_APPLICATION|EFI_BOOT_SERVICE_DRIVER|EFI_ROM|EFI_RUNTIME_DRIVER|NATIVE|POSIX|WINDOWS|WINDOWSCE}[,major[.minor]]",0
	db "Tells the operating system how to run the .exe file",0
		db 9,"/SUBSYSTEM:CONSOLE",0
		db 9,"/SUBSYSTEM:CONSOLE,major",0
		db 9,"/SUBSYSTEM:CONSOLE,major.minor",0
		db 9,"/SUBSYSTEM:EFI_APPLICATION",0
		db 9,"/SUBSYSTEM:EFI_APPLICATION,major",0
		db 9,"/SUBSYSTEM:EFI_APPLICATION,major.minor",0
		db 9,"/SUBSYSTEM:EFI_BOOT_SERVICE_DRIVER",0
		db 9,"/SUBSYSTEM:EFI_BOOT_SERVICE_DRIVER,major",0
		db 9,"/SUBSYSTEM:EFI_BOOT_SERVICE_DRIVER,major.minor",0
		db 9,"/SUBSYSTEM:EFI_ROM",0
		db 9,"/SUBSYSTEM:EFI_ROM,major",0
		db 9,"/SUBSYSTEM:EFI_ROM,major.minor",0
		db 9,"/SUBSYSTEM:EFI_RUNTIME_DRIVER",0
		db 9,"/SUBSYSTEM:EFI_RUNTIME_DRIVER,major",0
		db 9,"/SUBSYSTEM:EFI_RUNTIME_DRIVER,major.minor",0
		db 9,"/SUBSYSTEM:NATIVE",0
		db 9,"/SUBSYSTEM:NATIVE,major",0
		db 9,"/SUBSYSTEM:NATIVE,major.minor",0
		db 9,"/SUBSYSTEM:POSIX",0
		db 9,"/SUBSYSTEM:POSIX,major",0
		db 9,"/SUBSYSTEM:POSIX,major.minor",0
		db 9,"/SUBSYSTEM:WINDOWS",0
		db 9,"/SUBSYSTEM:WINDOWS,major",0
		db 9,"/SUBSYSTEM:WINDOWS,major.minor",0
		db 9,"/SUBSYSTEM:WINDOWSCE",0
		db 9,"/SUBSYSTEM:WINDOWSCE,major",0
		db 9,"/SUBSYSTEM:WINDOWSCE,major.minor",0
db "/SWAPRUN:{NET|CD}",0
	db "Tells the operating system to copy the linker output to a swap file before running it",0
		db 9,"/SWAPRUN:NET",0
		db 9,"/SWAPRUN:CD",0
db "/TLBID:id",0
	db "Allows you to specify the resource ID of the linker-generated type library",0
db "/TLBOUT:[path\]filename",0
	db "Specifies the name of the .tlb file and other MIDL output files",0
		db 9,"/TLBOUT:filename",0
		db 9,"/TLBOUT:path\filename",0
db "/TSAWARE[:NO]",0
	db "Creates an application that is specifically designed to run under Terminal Server",0
		db 9,"/TSAWARE",0
		db 9,"/TSAWARE:NO",0
db "/VERBOSE[:LIB | SAFESEH]",0
	db "Prints linker progress messages",0
		db 9,"/VERBOSE:LIB",0
		db 9,"/VERBOSE:SAFESEH",0
db "/VERSION:major[.minor]",0
	db "Assigns a version number",0
		db 9,"/VERSION:major",0
		db 9,"/VERSION:major.minor",0
db "/VXD",0
	db "Creates a virtual device driver (VxD)",0
db "/WS:AGGRESSIVE",0
	db "Aggressively trims process memory",0
db 0	;End of array
