; New Project Wizard Add-In for WinAsm Studio
; Copyright (C) 2004 Mario Vilas (aka QvasiModo)
; All rights reserved.
; Freeware for any use. See readme.txt for licensing details.

DllEntryPoint				proto hInstDLL:HINSTANCE, fdwReason:DWORD, lpvReserved:DWORD

GetLastTakenChoices			proto
SaveLastTakenChoices		proto
GetDefBldString				proto pszKey:PTR BYTE, pszDef:PTR BYTE, pszBuffer:PTR BYTE
WriteDefBldString			proto pszKey:PTR BYTE, pszBuffer:PTR BYTE
GetDefBuildCmds				proto
WriteDefBuildCmds			proto
StringCopy					proto pszDest:PTR BYTE, pszSource:PTR BYTE
SetMyEnvVariables			proto
UseTitleAsOut				proto pszKey:PTR BYTE
FixWapEntry					proto pszSection:PTR BYTE, pszKey:PTR BYTE
FixProjectData				proto
FixProjectFiles				proto
FixMenuItems				proto
CopyProjectFolder			proto
GetIniVarLenString			proto pFile:PTR BYTE, pSection:PTR BYTE, pKey:PTR BYTE, pDefault:PTR BYTE
MakeTextReplacementsOnFile	proto pFile:PTR BYTE, bRename:DWORD
ParseProjectFiles			proto
RenameInWapFileList			proto pDest:PTR BYTE, pSrc:PTR BYTE
RenameProjectFiles			proto
CreateNewProject			proto hWnd:HWND
InferPathName				proto pBuffer:PTR BYTE, pszSuffix:PTR BYTE

GetWAAddInData				proto lpFriendlyName:PTR BYTE, lpDescription:PTR BYTE
WAAddInLoad					proto pWinAsmHandles:PTR HANDLES, pFeatures:PTR FEATURES
WAAddInUnload				proto
FrameWindowProc				proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

.data?
pHandles		dd ?	;Pointer to HANDLES structure
pFeatures		dd ?	;Pointer to FEATURES structure
pIniFile		dd ?	;Pointer to add-in's INI file full pathname 

pFindFirstFileEx dd ?	;Pointer to FindFirstFileEx, or NULL if not supported

bNotSaved		dd ?	;TRUE if some project files were not saved, FALSE otherwise

bEnableWizard	dd ?	;TRUE to enable the wizard, FALSE to use classic interface
bEnableProperties dd ?	;TRUE to enable the project properties dialog, FALSE to use classic interface
bUseTitleAsOut	dd ?	;TRUE to use the new project's title as the default /OUT build command

cpi				CURRENTPROJECTINFO <>

;szIniPath		db MAX_PATH+20 dup (?)	;Addins INI full pathname
szWAIniPath		db MAX_PATH+20 dup (?)	;WinAsm INI full pathname

;Build commands for newly created projects
pszCompileRCCommand			db MAX_PATH+20 dup (?)
pszResToObjCommand			db MAX_PATH+20 dup (?)
pszReleaseAssembleCommand	db MAX_PATH+20 dup (?)
pszReleaseLinkCommand		db MAX_PATH+20 dup (?)
pszReleaseOUTCommand		db MAX_PATH+20 dup (?)
pszDebugAssembleCommand		db MAX_PATH+20 dup (?)
pszDebugLinkCommand			db MAX_PATH+20 dup (?)
pszDebugOUTCommand			db MAX_PATH+20 dup (?)

.data
IFDEF DEBUG_BUILD
	shfops	SHFILEOPSTRUCT <,FO_COPY,offset szMaskAll,offset szTargetFolder,FOF_ALLOWUNDO,,,>
ELSE
	shfops	SHFILEOPSTRUCT <,FO_COPY,offset szMaskAll,offset szTargetFolder,FOF_ALLOWUNDO or FOF_NOERRORUI or FOF_NOCONFIRMMKDIR,,,>
	; or FOF_SIMPLEPROGRESS
	; offset szProgressTitle
ENDIF

;Menu items to enable and disable after a project was created
aMenuItemsToEnable dd\
	IDM_CLOSEPROJECT,IDM_SAVEPROJECT,IDM_SAVEPROJECTAS,IDM_PROJECT_ADDASM,IDM_PROJECT_ADDINC,\
	IDM_PROJECT_ADDRC,IDM_PROJECT_ADDOTHER,IDM_PROJECT_ADDEXISTINGFILE,IDM_PROJECT_REMOVEFILE,\
	IDM_PROJECT_PROPERTIES,IDM_PROJECT_RENAMEFILE,IDM_PROJECT_SETASMODULE,IDM_MAKE_ASSEMBLE,\
	IDM_MAKE_LINK,IDM_MAKE_GO,IDM_MAKE_COMPILERESOURCE,IDM_MAKE_RCTOOBJ,IDM_MAKE_EXECUTE,\
	IDM_MAKE_DEBUG,IDM_MAKEACTIVERELEASEVERSION,IDM_MAKEACTIVEDEBUGVERSION,IDM_MAKE_CLEAN

aMenuItemsToDisable	dd\
	IDM_PROJECT_RUNBATCH,IDM_PROJECT_USEEXTRCEDITOR,IDM_PROJECT_VISUALMODE

;Crude int->text conversion
sz0				db "0",0
sz1				db "1",0
sz2				db "2",0
sz3				db "3",0
sz4				db "4",0
sz5				db "5",0
sz6				db "6",0
sz7				db "6",0	;intentional! (there's no project type 7 yet)

;True int->text conversion using wsprintf
szFmtInt		db "%i",0

;Some dlls and functions loaded on runtime
szKernel32		db "kernel32",0
szFindFirstFileEx db "FindFirstFileEx",0

;Addins INI filename
;szIniFile		db "WAAddIns.Ini",0				;Ini filename
szAppName		db "New Project Wizard",0		;Section

;WinAsm INI filename and keynames
szWAIniFile		db "WinAsm.Ini",0
szGENERAL		db "GENERAL",0
szInitDir		db "InitDir",0
szFILESANDPATHS	db "FILES&PATHS",0
szBinaryPath	db "BinaryPath",0
szIncludePath	db "IncludePath",0
szLibraryPath	db "LibraryPath",0

;INI keynames
szEnableWizard		db "EnableWizard",0
szEnableProperties	db "EnableProperties",0
szUseTitleAsOut		db "UseTitleAsOut",0
szWizChoice			db "LastTakenWizardChoice",0
szProjectType		db "ProjectType",0
szUTKey				db "UseTemplate",0
szCPKey				db "CloneProject",0
szTFKey				db "TargetFolder",0
szSaveWap			db "AutoSaveNewProjectFile",0
szGoAll				db "AutoBuildNewProject",0
szRemember			db "RememberChoices",0

;WAP sections and keynames
;szPROJECT				db "PROJECT",0
szMAKE					db "MAKE",0
szFILES					db "FILES",0
;szType					db "Type",0
szCompileRC				db "CompileRC",0
szRCToObj				db "RCToObj",0
szAssemble				db "Assemble",0
szLink					db "Link",0
szOut					db "Out",0
szDebAssemble			db "DebAssemble",0
szDebLink				db "DebLink",0
szDebOut				db "DebOut",0
szReleaseCommandLine	db "ReleaseCommandLine",0
szDebugCommandLine		db "DebugCommandLine",0
szAutoIncFileVersion	db "AutoIncFileVersion",0
szRCSilent				db "RCSilent",0
szCompiler				db "Compiler",0
szMASM32				db "MASM32",0
szFASM					db "FASM",0

;Template WAP sections and keynames
szTEMPLATE		db "TEMPLATE",0
szParse			db "Parse",0		; List of files to parse, separated by commas
szRename		db "Rename",0		; Boolean (0: don't rename, 1: do rename)

;Special environment variables used in extended templates
szEnvProject	db "project",0	; %project%		Project full pathname
szEnvFolder		db "folder",0	; %folder%		Project folder
szEnvTitle		db "title",0	; %title%		Project title
szEnvWafolder	db "wafolder",0	; %wafolder%	WinAsm folder
szEnvAddins		db "waaddins",0	; %waaddins%	Add-Ins folder
szEnvBin		db "wabin",0	; %wabin%		Bin folder
szEnvInc		db "wainc",0	; %wainc%		Include folder
szEnvLib		db "walib",0	; %walib%		Library folder

;Error messages
szError				db "Error!",0
szWarning			db "Warning!",0
szAreYouSure		db "Are you sure?",0
szWasNotSaved		db "Some project files were not saved!",13,10
	 				db "Do you want to keep the changes?",13,10,13,10
	 				db "Click ",34,"Yes",34," to save the current project.",13,10
	 				db "Click ",34,"No",34," to discard the changes.",13,10
	 				db "Click ",34,"Cancel",34," to abort the operation.",0
szCantClose			db "The current project was not closed.",13,10
	 				db "The new project can't be created.",0
szErrorOccured		db "An error has occured, the new project was not created.",0
szCantComplete		db "An error has occured while creating the new project.",13,10
	 				db "The operation was NOT completed successfully.",0
szNotAllFiles		db "Not all project files were copied to the target folder.",13,10
	 				db "Do you want to proceed with project creation?",0
szTargetWapExists	db "The target project file already exists. Overwrite?",13,10
	 				db "Click ",34,"Yes",34," to overwrite the target project file.",13,10
	 				db "Click ",34,"No",34," to cancel project creation.",13,10,0
szErrorRenamingWap 	db "There was an error while setting the new project title.",13,10
	 				db "Project creation is most likely going to fail at this point...",13,10
	 				db "Do you want to proceed with project creation anyway?",0
szErrorParsing		db "There was an error while parsing the template files.",13,10
	 				db "Do you want to proceed with project creation?",0
szErrorRenaming		db "There was an error while renaming the target files.",13,10
	 				db "Do you want to proceed with project creation?",0
szTFNotExist		db "The target project folder does not exist or can't be accessed.",13,10
	 				db "Are you sure you want to use it?",0
szTFNotEmpty		db "The target project folder appears to contain some files!",13,10
	 				db "Project creation may fail. Are you sure you want to use it?",0

;Addin name and description (REQUIRED)
IFDEF DEBUG_BUILD
	szFriendlyName	db "New Project Wizard v1.3.4.1 DEBUG",0
ELSE
	szFriendlyName	db "New Project Wizard v1.3.4.1",0
ENDIF
szDescription	db "Wizard to create new WinAsm projects.",13,10,\
	 			   "® 2004-2005 by Mario Vilas (aka QvasiModo).",13,10,\
	 			   "Please see readme.txt for further details.",0

;Misc strings
szNull				db 0
;szCRLF				db 13,10,0
;szTab				db 9,0
szSpace				db 32,0
szWA				db "WA",0
szDotAsterisk		db ".*",0

;Default build commands for newly created projects
align DWORD
aBuildCommands		label DWORD
	; Project type 0
	dd offset pszCompileRCCommand_0
	dd offset pszResToObjCommand_0
	dd offset pszReleaseAssembleCommand_0
	dd offset pszReleaseLinkCommand_0
	dd offset pszReleaseOUTCommand_0
	dd offset pszDebugAssembleCommand_0
	dd offset pszDebugLinkCommand_0
	dd offset pszDebugOUTCommand_0
	; Project type 1
	dd offset pszCompileRCCommand_1
	dd offset pszResToObjCommand_1
	dd offset pszReleaseAssembleCommand_1
	dd offset pszReleaseLinkCommand_1
	dd offset pszReleaseOUTCommand_1
	dd offset pszDebugAssembleCommand_1
	dd offset pszDebugLinkCommand_1
	dd offset pszDebugOUTCommand_1
	; Project type 2
	dd offset pszCompileRCCommand_2
	dd offset pszResToObjCommand_2
	dd offset pszReleaseAssembleCommand_2
	dd offset pszReleaseLinkCommand_2
	dd offset pszReleaseOUTCommand_2
	dd offset pszDebugAssembleCommand_2
	dd offset pszDebugLinkCommand_2
	dd offset pszDebugOUTCommand_2
	; Project type 3
	dd offset pszCompileRCCommand_3
	dd offset pszResToObjCommand_3
	dd offset pszReleaseAssembleCommand_3
	dd offset pszReleaseLinkCommand_3
	dd offset pszReleaseOUTCommand_3
	dd offset pszDebugAssembleCommand_3
	dd offset pszDebugLinkCommand_3
	dd offset pszDebugOUTCommand_3
	; Project type 4
	dd offset pszCompileRCCommand_4
	dd offset pszResToObjCommand_4
	dd offset pszReleaseAssembleCommand_4
	dd offset pszReleaseLinkCommand_4
	dd offset pszReleaseOUTCommand_4
	dd offset pszDebugAssembleCommand_4
	dd offset pszDebugLinkCommand_4
	dd offset pszDebugOUTCommand_4
	; Project type 5
	dd offset pszCompileRCCommand_5
	dd offset pszResToObjCommand_5
	dd offset pszReleaseAssembleCommand_5
	dd offset pszReleaseLinkCommand_5
	dd offset pszReleaseOUTCommand_5
	dd offset pszDebugAssembleCommand_5
	dd offset pszDebugLinkCommand_5
	dd offset pszDebugOUTCommand_5
	; Project type 6
	dd offset pszCompileRCCommand_6
	dd offset pszResToObjCommand_6
	dd offset pszReleaseAssembleCommand_6
	dd offset pszReleaseLinkCommand_6
	dd offset pszReleaseOUTCommand_6
	dd offset pszDebugAssembleCommand_6
	dd offset pszDebugLinkCommand_6
	dd offset pszDebugOUTCommand_6

; Project type 0
pszCompileRCCommand_0		db "/v",0
pszResToObjCommand_0		equ <szNull>
pszReleaseAssembleCommand_0	db "/c /coff /Cp /nologo",0
pszReleaseLinkCommand_0		db "/SUBSYSTEM:WINDOWS /RELEASE /VERSION:4.0",0
pszReleaseOUTCommand_0		equ <szNull>
pszDebugAssembleCommand_0	db "/c /coff /Cp /nologo /Fm /Zi /Zd",0
pszDebugLinkCommand_0		db "/SUBSYSTEM:WINDOWS /DEBUG /VERSION:4.0",0
pszDebugOUTCommand_0		equ <szNull>
; Project type 1
pszCompileRCCommand_1		equ <pszCompileRCCommand_0>
pszResToObjCommand_1		equ <pszResToObjCommand_0>
pszReleaseAssembleCommand_1	equ <pszReleaseAssembleCommand_0>
pszReleaseLinkCommand_1		equ <pszReleaseLinkCommand_0>
pszReleaseOUTCommand_1		equ <pszReleaseOUTCommand_0>
pszDebugAssembleCommand_1	equ <pszDebugAssembleCommand_0>
pszDebugLinkCommand_1		equ <pszDebugLinkCommand_0>
pszDebugOUTCommand_1		equ <pszDebugOUTCommand_0>
; Project type 2
pszCompileRCCommand_2		equ <pszCompileRCCommand_0>
pszResToObjCommand_2		equ <pszResToObjCommand_0>
pszReleaseAssembleCommand_2	equ <pszReleaseAssembleCommand_0>
pszReleaseLinkCommand_2		db "/SUBSYSTEM:CONSOLE /RELEASE /VERSION:4.0",0
pszReleaseOUTCommand_2		equ <pszReleaseOUTCommand_0>
pszDebugAssembleCommand_2	equ <pszDebugAssembleCommand_0>
pszDebugLinkCommand_2		db "/SUBSYSTEM:CONSOLE /DEBUG /VERSION:4.0",0
pszDebugOUTCommand_2		equ <pszDebugOUTCommand_0>
; Project type 3
pszCompileRCCommand_3		equ <pszCompileRCCommand_0>
pszResToObjCommand_3		equ <pszResToObjCommand_0>
pszReleaseAssembleCommand_3	equ <pszReleaseAssembleCommand_0>
pszReleaseLinkCommand_3		db "-LIB",0
pszReleaseOUTCommand_3		equ <pszReleaseOUTCommand_0>
pszDebugAssembleCommand_3	equ <pszDebugAssembleCommand_0>
pszDebugLinkCommand_3		db "-LIB /DEBUG",0
pszDebugOUTCommand_3		equ <pszDebugOUTCommand_0>
; Project type 4
pszCompileRCCommand_4		equ <pszCompileRCCommand_0>
pszResToObjCommand_4		equ <pszResToObjCommand_0>
pszReleaseAssembleCommand_4	equ <pszReleaseAssembleCommand_0>
pszReleaseLinkCommand_4		equ <pszReleaseLinkCommand_0>
pszReleaseOUTCommand_4		equ <pszReleaseOUTCommand_0>
pszDebugAssembleCommand_4	equ <pszDebugAssembleCommand_0>
pszDebugLinkCommand_4		equ <pszDebugLinkCommand_0>
pszDebugOUTCommand_4		equ <pszDebugOUTCommand_0>
; Project type 5
pszCompileRCCommand_5		equ <pszCompileRCCommand_0>
pszResToObjCommand_5		equ <pszResToObjCommand_0>
pszReleaseAssembleCommand_5	equ <pszReleaseAssembleCommand_0>
pszReleaseLinkCommand_5		equ <pszReleaseLinkCommand_0>
pszReleaseOUTCommand_5		equ <pszReleaseOUTCommand_0>
pszDebugAssembleCommand_5	equ <pszDebugAssembleCommand_0>
pszDebugLinkCommand_5		equ <pszDebugLinkCommand_0>
pszDebugOUTCommand_5		equ <pszDebugOUTCommand_0>
; Project type 6
pszCompileRCCommand_6		equ <szNull>
pszResToObjCommand_6		equ <szNull>
pszReleaseAssembleCommand_6	db "/c",0
pszReleaseLinkCommand_6		equ <szNull>
pszReleaseOUTCommand_6		equ <szNull>
pszDebugAssembleCommand_6	equ <pszReleaseAssembleCommand_6>
pszDebugLinkCommand_6		equ <szNull>
pszDebugOUTCommand_6		equ <szNull>
