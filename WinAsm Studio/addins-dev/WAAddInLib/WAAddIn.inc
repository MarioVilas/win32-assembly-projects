;WinAsm Studio Add-Ins Header (WAAddIn.inc)
;Updated for up to V3.0.5.xxx

;Use it to get a menu ID for your addin
WAM_GETNEXTMENUID			EQU WM_USER+100	;hWnd   = hMain
                                            ;wParam = 0
                                            ;lParam = 0

;Fills the CURRENTPROJECTINFO structure: only if there's an open project (3.0.0.0 to 3.0.1.3)
;	 									 always (3.0.1.4+)
;Returns 0 if there is no open project, nonzero otherwise
WAM_GETCURRENTPROJECTINFO	EQU WM_USER+101	;hWnd   = hMain
                                            ;wParam = LPCURRENTPROJECTINFO
                                            ;lParam = 0
CURRENTPROJECTINFO STRUCT
	pszFullProjectName 			LPSTR ?
	pbModified					DWORD ? ;pointer to modified flag (TRUE/FALSE)
	pszCompileRCCommand			LPSTR ?
	pszResToObjCommand			LPSTR ?
	pszReleaseAssembleCommand	LPSTR ?
	pszReleaseLinkCommand		LPSTR ?
	pszReleaseOUTCommand		LPSTR ?
	pProjectType				DWORD ?	;pointer to project type (0-6)
	pszDebugAssembleCommand		LPSTR ? ;(3.0.1.4+)
	pszDebugLinkCommand			LPSTR ? ;(3.0.1.4+)
	pszDebugOUTCommand			LPSTR ? ;(3.0.1.4+)
	pszProjectTitle				LPSTR ? ;(3.0.1.4+)
	
	pszReleaseCommandLine		LPSTR ? ;(3.0.2.7+)	;optional command line to be passed by WinAsm Studio when runs executable project and active build is Release Version
	pszDebugCommandLine			LPSTR ? ;(3.0.2.7+)	;optional command line to be passed by WinAsm Studio when runs executable project and active build is Debug Version
CURRENTPROJECTINFO ENDS
LPCURRENTPROJECTINFO TYPEDEF PTR CURRENTPROJECTINFO

;Enumerate all files of current project
WAM_ENUMCURRENTPROJECTFILES	EQU WM_USER+102	;hWnd   = hMain
                                            ;wParam = pointer to EnumProc
                                            ;lParam = 0

;Adds an existing file to the project, or opens an external file
;lParam: TRUE to Add File to the current project, FALSE to Open File external to the current project
WAM_ADDOPENEXISTINGFILE		EQU WM_USER+103	;hWnd   = hMain
                                            ;wParam = lpFileName
                                            ;lParam = TRUE/FALSE  

;Opens an entire project
WAM_OPENPROJECT				EQU WM_USER+104	;hWnd   = hMain
                                            ;wParam = lpProjectFileName
                                            ;lParam = reserved

;Enumerate all external files
WAM_ENUMEXTERNALFILES		EQU WM_USER+105	;hWnd   = hMain
                                            ;wParam = pointer to EnumProc
                                            ;lParam = 0

WAM_ENABLEALLDOCKWINDOWS	EQU WM_USER+106	;hWnd   = hMain
                                            ;wParam = 0
                                            ;lParam = TRUE/FALSE 

WAM_DIFFERENTCURRENTPROJECT	EQU WM_USER+107	;hWnd   = hMain
                                            ;wParam = 0
                                            ;lParam = 0
                                            
;After every WM_COMMAND WinAsm Studio processes, sends WAE_COMMANDFINISHED
;back to all Add-Ins in the FrameWindowProc Procedure therefore wParam
;and lParam are equal to those of the WM_COMMAND message WinAsm Studio
;just processed.
WAE_COMMANDFINISHED			EQU WM_USER+200	;hWnd   = hMain (FrameWindowProc)
                            	            ;wParam = (?)
                                	        ;lParam = (?)

;******************************************************************************
;Docking Windows
POSANDSIZE STRUCT
	dLeft	DD ?
	dTop	DD ?
	dWidth	DD ?
	dHeight	DD ?
POSANDSIZE ENDS

;Title Styles
STYLE_GRADIENTTITLE		EQU 000h
STYLE_TWOLINESTITLE		EQU 001h
STYLE_ONELINETITLE		EQU 002h

;Constants for fDockedTo
NODOCK					EQU 0
LEFTDOCK				EQU 1
RIGHTDOCK				EQU 2
TOPDOCK					EQU 3
BOTTOMDOCK				EQU 4

DOCKINGDATA STRUCT
	lpCaption			DWORD ?
	fDockedTo			DWORD ?		;Use one of the following: NODOCK,LEFTDOCK,RIGHTDOCK,TOPDOCK,BOTTOMDOCK
	NoDock				POSANDSIZE <?>
	DockTopHeight		DWORD ?
	DockBottomHeight	DWORD ?	
	DockLeftWidth		DWORD ?
	DockRightWidth		DWORD ?

	;Do not touch these!
	reserved1			DWORD ?
	reserved2			DWORD ?		
	reserved3			RECT <?>
	reserved4			POINT <?>
DOCKINGDATA ENDS
LPDOCKINGDATA TYPEDEF PTR DOCKINGDATA

;For docking windows use ONLY this messages, NOT their API counterparts
WAM_CREATEDOCKINGWINDOW		EQU WM_USER+151	;hWnd   = hMain
                                            ;wParam = Window Style, recommend (WS_VISIBLE OR WS_CLIPCHILDREN or WS_CLIPSIBLINGS or WS_CHILD or STYLE_xxx) --->WS_CHILD is a must!
                                            ;lParam = lpDockData (LPDOCKINGDATA)

WAM_GETCLIENTRECT			EQU WM_USER+152	;hWnd   = hAddInWindow
                                            ;wParam = 0
                                            ;lParam = lpRect (LPRECT)

WAM_DESTROYDOCKINGWINDOW	EQU WM_USER+153	;hWnd   = hAddInWindow
                                            ;wParam = 0
                                            ;lParam = 0


;End Of Docking windows
;******************************************************************************

;WinAsm Studio handles structures, get this at WAAddInLoad

POPUPMENUS STRUCT
	hFileMenu			HWND	?
	hEditMenu			HWND	?
	hViewMenu			HWND	?
	hProjectMenu		HWND	?
	hFormatMenu			HWND	?
	hDialogMenu			HWND	?
	hMakeMenu			HWND	?
	hSetActiveBuildMenu	HWND	?
	hToolsMenu			HWND	?
	hAddInsMenu			HWND	?
	hWindowMenu			HWND	?
	hHelpMenu			HWND	?
	hNewFileMenu		HWND	?		;in "File"
	hConvertMenu		HWND	?		;in "Format"
POPUPMENUS ENDS

HANDLES STRUCT
	hMain				HWND ?
	hMenu				HWND ?
	hClient				HWND ?
	hStatus				HWND ?
	hRebar				HWND ?
	hMainTB				HWND ?
	hEditTB				HWND ?
	hMakeTB				HWND ?
	Reserved1			HWND ?
	Reserved2			HWND ?
	hProjExplorer		HWND ?
	hProjTab			HWND ?
	hProjTree			HWND ?
	hBlocksList			HWND ?
	hOutParent			HWND ?
	hOut				HWND ?
	phImlNormal			DWORD ?
	phImlMonoChrome		DWORD ?
	phAcceleratorTable	DWORD ?	;Pointer to the Accelerator Table handle
	PopUpMenus			POPUPMENUS <?>
HANDLES ENDS

;WinAsm Studio features structures, get this at WAAddInLoad
FEATURES STRUCT
	Version								DWORD ?		;Decimal number, version 3.0.1.4 is 3014
	ppAddInsFrameProcedures				DWORD ?		;Pointer to pointer to AddInsFrameProcedures list
	ppAddInsChildWindowProcedures		DWORD ?		;Pointer to pointer to AddInsChildWindowProcedures list
	ppAddInsProjectExplorerProcedures	DWORD ?		;Pointer to pointer to AddInsProjectExplorerProcedures list
	ppAddInsOutWindowProcedures			DWORD ?		;Pointer to pointer to AddInsOutWindowProcedures list
FEATURES ENDS

Comment $
Example Usage:
--------------

In the WAAddInLoad Procedure
----------------------------
	MOV EBX,pWinAsmHandles
	M2M hClient,[EBX].HANDLES.hClient

Any procedure
----------------------------------------------
	Invoke SendMessage,hClient,WM_MDIGETACTIVE,0,0
	.If EAX
		Invoke GetWindowLong,EAX,0
		;Now CHILDDATA.TypeOfFile[EAX]=1 0r 2 or ...7
		.
		.
		.
	.EndIf
$

CHSELCHANGE STRUCT
	nmhdr		NMHDR <?>
	chrg		CHARRANGE <?>
	seltyp		DW ?		;SEL_TEXT or SEL_OBJECT
	linenr		DD ?		;Line number
	cpLine		DD ?		;Character position of first character
	lpLine		DD ?		;Pointer to line
	nlines		DD ?		;Total number of lines
	nhidden		DD ?		;Total number of hidden lines
	fchanged	DD ?		;TRUE if changed since last
	npage		DD ?		;Page number
	nWordGroup	DD ?		;Hilite word group
CHSELCHANGE ENDS

CHILDDATA STRUCT
	hEditor		DWORD ?
	hCombo		DWORD ?
	hTreeItem	DWORD ?
	TypeOfFile	DWORD ?		;1=asm, 2=inc, 3=rc, 4=txt, 5=def, 6=bat, 7=other
							;Similarly 101=external *.asm, 102=external *.inc etc
							;51=module 
	FileName	DB MAX_PATH DUP(?)
CHILDDATA ENDS

Comment $
Example Usage:
---------------
;e.g.1 Invoke SendMessage,hMain,WM_COMMAND,0 (or 1 it doesn't matter),IDM_ ....

;e.g.2 Probably In the FrameWindowProc:

		.If uMsg == WM_COMMAND
			HIWORD wParam
			.If EAX == 0 || 1 ; 0 is a menu, 1 is an accelerator. Toolbar messages act like menu messages...
				LOWORD wParam
				.If EAX == IDM_OPENPROJECT
					;Do something here
					;
					;
					
					MOV EAX,TRUE	;If you do not want WinAsm Studio or Other Add-Ins to process this message.
						OR
					XOR EAX,EAX		;If you want WinAsm Studio AND Other Add-Ins to process this message.
					
					
					RET
				.EndIf
			.EndIf
		.EndIf

$
;---------------------------------------------------------------------------
;Menu/Toolbar command identifiers
IDM_NEWPROJECT				EQU 10001
IDM_OPENPROJECT				EQU 10002
IDM_CLOSEPROJECT			EQU 10006
IDM_SAVEPROJECT				EQU 10003
IDM_SAVEPROJECTAS			EQU 10004
IDM_OPENFILES				EQU	10005

IDM_SAVEFILE				EQU 10007
IDM_SAVEFILEAS				EQU 10008
IDM_PRINT					EQU 10009
IDM_RECENTPROJECTSMANAGER	EQU 10010
IDM_EXIT					EQU 10011
IDM_RESTORE					EQU 10012

IDM_NEWASMFILE				EQU 10013
IDM_NEWINCFILE				EQU 10014
IDM_NEWRCFILE				EQU 10015
IDM_NEWOTHERFILE			EQU 10016

IDM_EDIT_UNDO				EQU 10101
IDM_EDIT_REDO				EQU 10102
IDM_EDIT_CUT				EQU 10103
IDM_EDIT_COPY				EQU 10104
IDM_EDIT_PASTE				EQU 10105
IDM_EDIT_DELETE				EQU 10106
IDM_EDIT_SELECTALL			EQU 10107
IDM_EDIT_FIND				EQU 10108
IDM_EDIT_FINDNEXT			EQU 10109
IDM_EDIT_REPLACE			EQU 10110
IDM_EDIT_GOTOLINE			EQU 10111
IDM_EDIT_GOTOBLOCK			EQU 10112
IDM_EDIT_GOBACK				EQU 10113
IDM_EDIT_TOGGLEBM			EQU 10114
IDM_EDIT_NEXTBM				EQU 10115
IDM_EDIT_PREVBM				EQU 10116
IDM_EDIT_CLEARBM			EQU 10117
IDM_EDIT_SMARTFIND			EQU 10118
IDM_EDIT_FINDPREVIOUS		EQU 10119

IDM_VIEW_PROJECTEXPLORER	EQU 10201
IDM_VIEW_OUTPUT				EQU 10202

IDM_PROJECT_ADDASM			EQU 10301
IDM_PROJECT_ADDINC			EQU 10302
IDM_PROJECT_ADDRC			EQU 10303
IDM_PROJECT_ADDOTHER		EQU 10304
IDM_PROJECT_ADDEXISTINGFILE	EQU 10305
IDM_PROJECT_REMOVEFILE		EQU 10306
IDM_PROJECT_PROPERTIES		EQU 10307
IDM_PROJECT_RUNBATCH		EQU 10308
IDM_PROJECT_RENAMEFILE		EQU 10309
IDM_PROJECT_USEEXTRCEDITOR	EQU 10310
IDM_PROJECT_VISUALMODE		EQU 10311
IDM_PROJECT_SETASMODULE		EQU 10312
IDM_PROJECT_TESTDIALOG		EQU 10313


IDM_FORMAT_INDENT			EQU 10401
IDM_FORMAT_OUTDENT			EQU 10402
IDM_FORMAT_COMMENT			EQU 10403
IDM_FORMAT_UNCOMMENT		EQU 10404
IDM_CONVERTTOUPPERCASE		EQU 10405
IDM_CONVERTTOLOWERCASE		EQU 10406
IDM_TOGGLECASE				EQU 10407

IDM_MAKE_COMPILERESOURCE	EQU 10501
IDM_MAKE_RCTOOBJ			EQU 10502
IDM_MAKE_ASSEMBLE			EQU 10503
IDM_MAKE_LINK				EQU 10504
IDM_MAKE_GO					EQU 10505
IDM_MAKE_EXECUTE			EQU 10506
IDM_MAKE_DEBUG				EQU 10507
IDM_MAKEACTIVERELEASEVERSION	EQU 10508
IDM_MAKEACTIVEDEBUGVERSION		EQU 10509
IDM_MAKE_CLEAN					EQU 10510

IDM_WINDOW_CLOSE			EQU 10701
IDM_WINDOW_NEXT				EQU 10702
IDM_WINDOW_PREVIOUS			EQU 10703
IDM_WINDOW_TILEHORIZONTALLY	EQU 10704
IDM_WINDOW_TILEVERTICALLY	EQU 10705
IDM_WINDOW_CASCADE			EQU 10706
IDM_WINDOW_CLOSEALL			EQU 10707

IDM_HELP_ABOUT				EQU 10801
IDM_HELP_HELPCONTENTS		EQU 10802
IDM_HELP_HELPKEY			EQU 10803
IDM_HELPONTHEWEB			EQU 10805
IDM_HELP_WINASMHELP			EQU 10804

IDM_TOOLS_CODEEDITORFONT	EQU 10901
IDM_TOOLS_LINENUMBERFONT	EQU 10902
IDM_TOOLS_OPTIONS			EQU 10903
IDM_TOOLS_TOOLSMANAGER		EQU 10904
;IDM_TOOLS_RESERVED			EQU 10905

IDM_COPYSELECTION			EQU 11001
IDM_COPYALLTEXT				EQU 11002
IDM_SAVEOUTTEXT				EQU 11003

;----------------------------------------
IDM_DIALOG_SHOWHIDEGRID		EQU 11301
IDM_DIALOG_SNAPTOGRID		EQU 11302

IDM_DIALOG_CUT				EQU 11304
IDM_DIALOG_COPY				EQU 11305
IDM_DIALOG_PASTE			EQU 11306
IDM_DIALOG_DELETE			EQU 11307


IDM_DIALOG_STYLE			EQU 11319
IDM_DIALOG_EXSTYLE			EQU 11320
IDM_DIALOG_DIALOGFONT		EQU 11321

IDM_DIALOG_SENDTOBACK		EQU 11325
IDM_DIALOG_BRINGONTOP		EQU 11326
IDM_DIALOG_RESERVED			EQU 11327
IDM_DIALOG_TESTDIALOG		EQU 11328
IDM_DIALOG_UNDO				EQU 11329
IDM_DIALOG_REDO				EQU 11330
;-----------------------------------------

IDM_ADDINS_ADDINSMANAGER	EQU 12001

IDM_STYLE_GRADIENTTITLE		EQU 13001
IDM_STYLE_TWOLINESTITLE		EQU 13002
IDM_STYLE_ONELINETITLE		EQU 13003

ADDINMENUITEM STRUCT
	hBitmapNormal	DWORD ?
	hBitmapDisabled	DWORD ?
	lpCaption		DWORD ?
ADDINMENUITEM ENDS

;NOTE1: 10021 (including) UP TO 10026 (including) are the 6 recent projects (all below File-Print).
;NOTE2: 30001 (including) UP TO 30020 (including) are the External tools commands (all below Tools-Tools Manager).
;NOTE2: 40001 (including) UP TO 50000 (including) are the Add-Ins menu items.
;NOTE3: 50001 (including) Upwards are the Opened External Files (in Window menu after Cascade)
;---------------------------------------------------------------------------


;--------------------------------------------------------------------------------
;CodeHi user messages
CHM_BASE				EQU WM_USER+1000
CHM_SETHILITEWORDS		EQU CHM_BASE+0		;wParam=Color			lParam=lpszWords
CHM_SETFONT				EQU CHM_BASE+1		;wParam=0				lParam=lpRAFONT
CHM_GETFONT				EQU CHM_BASE+2		;wParam=0				lParam=lpRAFONT
CHM_SETCOLOR			EQU CHM_BASE+3		;wParam=0				lParam=lpRACOLOR
CHM_GETCOLOR			EQU CHM_BASE+4		;wParam=0				lParam=lpRACOLOR
CHM_SETHILITELINE		EQU CHM_BASE+5		;wParam=Line			lParam=Color
CHM_GETHILITELINE		EQU CHM_BASE+6		;wParam=Line			lParam=0
CHM_SETBOOKMARK			EQU CHM_BASE+7		;wParam=Line			lParam=Type
CHM_GETBOOKMARK			EQU CHM_BASE+8		;wParam=Line			lParam=0
CHM_CLRBOOKMARKS		EQU CHM_BASE+9		;wParam=0				lParam=Type
CHM_NXTBOOKMARK			EQU CHM_BASE+10		;wParam=Line			lParam=Type
CHM_PRVBOOKMARK			EQU CHM_BASE+11		;wParam=Line			lParam=Type
CHM_FINDBOOKMARK		EQU CHM_BASE+12		;wParam=BmID			lParam=0
CHM_SETBLOCKS			EQU CHM_BASE+13		;wParam=[lpLINERANGE]	lParam=lpRABLOCKDEF
CHM_ISLINE				EQU CHM_BASE+14		;wParam=Line			lParam=lpszDef
CHM_GETWORD				EQU CHM_BASE+15		;wParam=BuffSize		lParam=lpBuff
CHM_COLLAPSE			EQU CHM_BASE+16		;wParam=Line			lParam=lpRABLOCKDEF
CHM_COLLAPSEALL			EQU CHM_BASE+17		;wParam=0				lParam=lpRABLOCKDEF
CHM_EXPAND				EQU CHM_BASE+18		;wParam=Line			lParam=lpRABLOCKDEF
CHM_EXPANDALL			EQU CHM_BASE+19		;wParam=0				lParam=lpRABLOCKDEF
CHM_LOCKLINE			EQU CHM_BASE+20		;wParam=Line			lParam=TRUE/FALSE
CHM_ISLINELOCKED		EQU CHM_BASE+21		;wParam=Line			lParam=0
CHM_HIDELINE			EQU CHM_BASE+22		;wParam=Line			lParam=TRUE/FALSE
CHM_ISLINEHIDDEN		EQU CHM_BASE+23		;wParam=Line			lParam=0
CHM_AUTOINDENT			EQU CHM_BASE+24		;wParam=0				lParam=TRUE/FALSE
CHM_TABWIDTH			EQU CHM_BASE+25		;wParam=nChars			lParam=TRUE/FALSE (Expand tabs)
CHM_SELBARWIDTH			EQU CHM_BASE+26		;wParam=nWidth			lParam=0
CHM_LINENUMBERWIDTH		EQU CHM_BASE+27		;wParam=nWidth			lParam=0
CHM_MOUSEWHEEL			EQU CHM_BASE+28		;wParam=nLines			lParam=0
CHM_SUBCLASS			EQU CHM_BASE+29		;wParam=0				lParam=lpWndProc
CHM_SETSPLIT			EQU CHM_BASE+30		;wParam=nSplit			lParam=0
CHM_GETSPLIT			EQU CHM_BASE+31		;wParam=0				lParam=0
CHM_VCENTER				EQU CHM_BASE+32		;wParam=0				lParam=0
CHM_REPAINT				EQU CHM_BASE+33		;wParam=0				lParam=TRUE/FALSE (Paint Now)
CHM_BMCALLBACK			EQU CHM_BASE+34		;wParam=0				lParam=lpBmProc
CHM_READONLY			EQU CHM_BASE+35		;wParam=0				lParam=TRUE/FALSE
CHM_INVALIDATELINE		EQU CHM_BASE+36		;wParam=Line			lParam=0
CHM_SETPAGESIZE			EQU CHM_BASE+37		;wParam=nLines			lParam=0
CHM_GETPAGESIZE			EQU CHM_BASE+38		;wParam=0				lParam=0
CHM_GETCHARTAB			EQU CHM_BASE+39		;wParam=nChar			lParam=0
CHM_SETCHARTAB			EQU CHM_BASE+40		;wParam=nChar			lParam=nValue
CHM_SETCOMMENTBLOCKS	EQU CHM_BASE+41		;wParam=lpStart			lParam=lpEnd
CHM_SETWORDGROUP		EQU CHM_BASE+42		;wParam=0				lParam=nGroup (0-15)
CHM_GETWORDGROUP		EQU CHM_BASE+43		;wParam=0				lParam=0
CHM_SETBMID				EQU CHM_BASE+44		;wParam=nLines			lParam=nBmID
CHM_GETBMID				EQU CHM_BASE+45		;wParam=nLines			lParam=0
CHM_ISCHARPOS			EQU CHM_BASE+46		;wParam=CP				lParam=0, returns 1 if comment block, 2 if comment, 3 if string
CHM_HIDELINES			EQU CHM_BASE+47		;wParam=nLine			lParam=nLines
CHM_SETDIVIDERLINE		equ CHM_BASE+48		;wParam=nLine, lParam=TRUE/FALSE
CHM_ISINBLOCK			equ CHM_BASE+49		;wParam=nLine, lParam=lpRABLOCKDEF
CHM_TRIMSPACE			equ CHM_BASE+50		;wParam=nLine, lParam=fLeft
CHM_SAVESEL				equ CHM_BASE+51		;wParam=0, lParam=0
CHM_RESTORESEL			equ CHM_BASE+52		;wParam=0, lParam=0
CHM_GETCURSORWORD		equ CHM_BASE+53		;wParam=BuffSize, lParam=lpBuff


Comment $
More CodeHi messages--> DO NOT UNCOMMENT SINCE THEY ARE STANDARD WINDOWS MESSAGES
--------------------
EM_EXLINEFROMCHAR
wParam=0
lParam=cp

EM_EXSETSEL
wParam=0
lParam=lpCHARRANGE

EM_EXGETSEL
wParam=0
lParam=lpCHARRANGE

EM_FINDTEXTEX
wParam=Flags
lParam=lpFINDTEXTEX

EM_GETTEXTRANGE
wParam=0
lParam=lpTEXTRANGE

EM_FINDWORDBREAK
wParam=uFlags
lParam=cp

EM_CANREDO
wParam=0
lParam=0

EM_REDO
wParam=0
lParam=0

EM_HIDESELECTION
wParam=TRUE/FALSE
lParam=0

EM_GETSELTEXT
wParam=0
lParam=lpBuff

EM_CANPASTE
wParam=CF_TEXT
lParam=0

EM_STREAMIN
wParam=SF_TEXT
lParam=lpStream

EM_STREAMOUT
wParam=SF_TEXT
lParam=lpStream

EM_CHARFROMPOS
wParam=0
lParam=lpPoint

EM_POSFROMCHAR
wParam=lpPoint
lParam=cp

EM_LINEFROMCHAR
wParam=cp
lParam=0

EM_LINEINDEX
wParam=line
lParam=0

EM_LINELENGTH
wParam=cp
lParam=0

EM_GETLINE
wParam=Line
lParam=lpBuff

EM_GETFIRSTVISIBLELINE
wParam=0
lParam=0

EM_LINESCROLL
wParam=cxScroll
lParam=cyScroll

EM_SCROLLCARET
wParam=0
lParam=0

EM_SETSEL
wParam=cpMin
lParam=cpMax

EM_GETSEL
wParam=lpcpMin
lParam=lpcpMax

EM_GETMODIFY
wParam=0
lParam=0

EM_SETMODIFY
wParam=TRUE/FALSE
lParam=0

EM_REPLACESEL
wParam=TRUE/FALSE
lParam=lpText

EM_GETLINECOUNT
wParam=0
lParam=0

EM_GETRECT
wParam=0
lParam=lpRECT

EM_CANUNDO
wParam=0
lParam=0

EM_UNDO
wParam=0
lParam=0

EM_EMPTYUNDOBUFFER
wParam=0
lParam=0

WM_COPY
wParam=0
lParam=0

WM_CUT
wParam=0
lParam=0

WM_PASTE
wParam=0
lParam=0

WM_CLEAR
wParam=0
lParam=0

WM_SETTEXT
wParam=0
lParam=lpszText

WM_GETTEXT
wParam=cbBuff
lParam=lpBuff

WM_GETTEXTLENGTH
wParam=0
lParam=0
$