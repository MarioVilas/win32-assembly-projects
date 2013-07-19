; New Project Wizard Add-In for WinAsm Studio
; Copyright (C) 2004 Mario Vilas (aka QvasiModo)
; All rights reserved.
; Freeware for any use. See readme.txt for licensing details.

;DEBUG_BUILD equ 1		;Uncomment for debug builds

.386
.model flat,stdcall
option casemap:none

include windows.inc
include kernel32.inc
include user32.inc
include gdi32.inc
include comctl32.inc
include comdlg32.inc
include shell32.inc
include shlwapi.inc
include ole32.inc
includelib kernel32.lib
includelib user32.lib
includelib gdi32.lib
includelib comctl32.lib
includelib comdlg32.lib
includelib shell32.lib
includelib shlwapi.lib
includelib ole32.lib

IFDEF DEBUG_BUILD
	include masm32.inc
	include debug.inc
	includelib masm32.lib
	includelib debug.lib
ENDIF

include WAAddIn.inc
include WAAddInLib.inc
includelib WAAddInLib.lib

include NewWiz.inc
include Wizard.asm

.code
align DWORD
DllEntryPoint proc hInstDLL:HINSTANCE, fdwReason:DWORD, lpvReserved:DWORD
	
	.if fdwReason == DLL_PROCESS_ATTACH
		mov eax,hInstDLL
		mov ppsph.hInstance,eax
		mov psp1.hInstance,eax
		mov psp21.hInstance,eax
		mov psp22.hInstance,eax
		mov psp23.hInstance,eax
		mov psp24.hInstance,eax
		mov psp32.hInstance,eax
		mov psp33.hInstance,eax
		mov psp34.hInstance,eax
		mov psp4.hInstance,eax
		mov projpph.hInstance,eax
		mov projp1.hInstance,eax
		mov projp2.hInstance,eax
		mov projp3.hInstance,eax
		mov ofn.hInstance,eax
		invoke DisableThreadLibraryCalls,eax
	.endif
	push TRUE
	pop eax
	ret
	
DllEntryPoint endp

; -----------------------------------------------------------------------------
; Auxiliary Procedures
; -----------------------------------------------------------------------------

align DWORD
GetLastTakenChoices proc
	
	; Get some last taken choices
	invoke GetPrivateProfileInt,offset szAppName,offset szWizChoice,0,pIniFile
	and eax,3			;four possible choices
	add eax,IDD_PAGE2_1
	mov dwWizChoice,eax
	invoke GetPrivateProfileInt,offset szAppName,offset szProjectType,0,pIniFile
	and eax,7
	.if eax == 7
		dec eax
	.endif
	mov dwProjectType,eax
	invoke GetPrivateProfileString,offset szAppName,offset szUTKey,offset szNull,
	 								offset szChosenTemplate,sizeof szChosenTemplate,pIniFile
	invoke GetPrivateProfileString,offset szAppName,offset szCPKey,offset szNull,
	 								offset szChosenCloneSrc,sizeof szChosenCloneSrc,pIniFile
	invoke GetPrivateProfileString,offset szAppName,offset szTFKey,offset szNull,
	 								offset szTargetFolder,sizeof szTargetFolder,pIniFile
	invoke GetPrivateProfileInt,offset szAppName,offset szSaveWap,FALSE,pIniFile
	and eax,TRUE
	mov bSaveWap,eax
	invoke GetPrivateProfileInt,offset szAppName,offset szGoAll,FALSE,pIniFile
	and eax,TRUE
	mov bGoAll,eax
	invoke GetPrivateProfileInt,offset szAppName,offset szRemember,TRUE,pIniFile
	and eax,TRUE
	mov bRemember,eax
	ret
	
GetLastTakenChoices endp

align DWORD
SaveLastTakenChoices proc
	
	; Save some last taken choices
	mov eax,bRemember
	and eax,1
	add eax,eax
	add eax,offset sz0
	invoke WritePrivateProfileString,offset szAppName,offset szRemember,eax,pIniFile
	.if bRemember
		mov eax,dwWizChoice
		sub eax,IDD_PAGE2_1
		and eax,3
		add eax,eax
		add eax,offset sz0
		invoke WritePrivateProfileString,offset szAppName,offset szWizChoice,eax,pIniFile
		mov eax,dwProjectType
		and eax,7
		add eax,eax
		add eax,offset sz0
		invoke WritePrivateProfileString,offset szAppName,offset szProjectType,eax,pIniFile
		invoke WritePrivateProfileString,offset szAppName,offset szUTKey,offset szChosenTemplate,pIniFile
		invoke WritePrivateProfileString,offset szAppName,offset szCPKey,offset szChosenCloneSrc,pIniFile
		invoke WritePrivateProfileString,offset szAppName,offset szTFKey,offset szTargetFolder,pIniFile
		mov eax,bSaveWap
		and eax,1
		add eax,eax
		add eax,offset sz0
		invoke WritePrivateProfileString,offset szAppName,offset szSaveWap,eax,pIniFile
		mov eax,bGoAll
		and eax,1
		add eax,eax
		add eax,offset sz0
		invoke WritePrivateProfileString,offset szAppName,offset szGoAll,eax,pIniFile
	.endif
	ret
	
SaveLastTakenChoices endp

align DWORD
GetDefBldString proc pszKey:PTR BYTE, pszDef:PTR BYTE, pszBuffer:PTR BYTE
	local szKey[256]:BYTE
	
	invoke lstrcpyn,addr szKey,pszKey,252
	invoke lstrlen,addr szKey
	mov edx,dwProjectType
	and edx,7
	shl edx,8
	add edx,'0_'
	mov dword ptr szKey[eax],edx
	invoke GetPrivateProfileString,offset szAppName,addr szKey,pszDef,pszBuffer,MAX_PATH,pIniFile
	ret
	
GetDefBldString endp

align DWORD
WriteDefBldString proc pszKey:PTR BYTE, pszBuffer:PTR BYTE
	local szKey[256]:BYTE
	
	invoke lstrcpyn,addr szKey,pszKey,252
	invoke lstrlen,addr szKey
	mov edx,dwProjectType
	and edx,7
	shl edx,8
	add edx,'0_'
	mov dword ptr szKey[eax],edx
	invoke WritePrivateProfileString,offset szAppName,addr szKey,pszBuffer,pIniFile
	ret
	
WriteDefBldString endp

align DWORD
GetDefBuildCmds proc uses ebx
	
	mov ebx,dwProjectType
	shl ebx,5	;eax *= 8 * 4
	invoke GetDefBldString,offset szCompileRC,	aBuildCommands[ebx + 0],offset pszCompileRCCommand
	invoke GetDefBldString,offset szRCToObj,	aBuildCommands[ebx + 4],offset pszResToObjCommand
	invoke GetDefBldString,offset szAssemble,	aBuildCommands[ebx + 8],offset pszReleaseAssembleCommand
	invoke GetDefBldString,offset szLink,		aBuildCommands[ebx + 12],offset pszReleaseLinkCommand
	invoke GetDefBldString,offset szOut,		aBuildCommands[ebx + 16],offset pszReleaseOUTCommand
	invoke GetDefBldString,offset szDebAssemble,aBuildCommands[ebx + 20],offset pszDebugAssembleCommand
	invoke GetDefBldString,offset szDebLink,	aBuildCommands[ebx + 24],offset pszDebugLinkCommand
	invoke GetDefBldString,offset szDebOut,		aBuildCommands[ebx + 28],offset pszDebugOUTCommand
	ret
	
GetDefBuildCmds endp

align DWORD
WriteDefBuildCmds proc
	
	invoke WriteDefBldString,offset szCompileRC,	offset pszCompileRCCommand
	invoke WriteDefBldString,offset szRCToObj,		offset pszResToObjCommand
	invoke WriteDefBldString,offset szAssemble,		offset pszReleaseAssembleCommand
	invoke WriteDefBldString,offset szLink,			offset pszReleaseLinkCommand
	invoke WriteDefBldString,offset szOut,			offset pszReleaseOUTCommand
	invoke WriteDefBldString,offset szDebAssemble,	offset pszDebugAssembleCommand
	invoke WriteDefBldString,offset szDebLink,		offset pszDebugLinkCommand
	invoke WriteDefBldString,offset szDebOut,		offset pszDebugOUTCommand
	ret
	
WriteDefBuildCmds endp

align DWORD
StringCopy proc pszDest:PTR BYTE, pszSource:PTR BYTE
	
	; This routine just does a strcpy, but I'm using it to
	;  prevent potential overflows or GPFs when writing to
	;  WinAsm's internal buffers.
	
	mov eax,pszDest
	.if eax
		invoke lstrcpyn,eax,pszSource,MAX_PATH
	.endif
	ret
	
StringCopy endp

align DWORD
SetMyEnvVariables proc
	
	; %project%					Project full pathname
	; %folder%					Project folder
	; %title%					Project title
	; %wafolder%				WinAsm folder
	; %waaddins%				Add-Ins folder
	; %wabin%					Bin folder
	; %wainc%					Include folder
	; %walib%					Library folder
	
	IFDEF DEBUG_BUILD
		PrintText "Setting special environment variables"
		PrintString szWAIniPath
		PrintString szTargetWap
		PrintString szTargetFolder
		PrintString szTargetTitle
	ENDIF
	invoke SetEnvironmentVariable,offset szEnvProject,offset szTargetWap
	invoke SetEnvironmentVariable,offset szEnvFolder,offset szTargetFolder
	invoke SetEnvironmentVariable,offset szEnvTitle,offset szTargetTitle
	invoke GetModuleHandle,NULL
	invoke GetModuleFileName,eax,offset szChangeFolder,sizeof szChangeFolder
	.if eax
		invoke PathMakePretty,offset szChangeFolder
		invoke PathFindFileName,offset szChangeFolder
		mov byte ptr [eax-1],0
		IFDEF DEBUG_BUILD
			PrintString szChangeFolder
		ENDIF
		invoke SetEnvironmentVariable,offset szEnvWafolder,offset szChangeFolder
	.endif
	invoke GetModuleFileName,ofn.hInstance,offset szChangeFolder,sizeof szChangeFolder
	.if eax
		invoke PathMakePretty,offset szChangeFolder
		invoke PathFindFileName,offset szChangeFolder
		mov byte ptr [eax-1],0
		IFDEF DEBUG_BUILD
			PrintString szChangeFolder
		ENDIF
		invoke SetEnvironmentVariable,offset szEnvAddins,offset szChangeFolder
	.endif
	invoke GetPrivateProfileString,offset szFILESANDPATHS,offset szBinaryPath,
		offset szNull,offset szChangeFolder,sizeof szChangeFolder,offset szWAIniPath
	IFDEF DEBUG_BUILD
		PrintString szChangeFolder
	ENDIF
	invoke SetEnvironmentVariable,offset szEnvBin,offset szChangeFolder
	invoke GetPrivateProfileString,offset szFILESANDPATHS,offset szIncludePath,
		offset szNull,offset szChangeFolder,sizeof szChangeFolder,offset szWAIniPath
	IFDEF DEBUG_BUILD
		PrintString szChangeFolder
	ENDIF
	invoke SetEnvironmentVariable,offset szEnvInc,offset szChangeFolder
	invoke GetPrivateProfileString,offset szFILESANDPATHS,offset szLibraryPath,
		offset szNull,offset szChangeFolder,sizeof szChangeFolder,offset szWAIniPath
	IFDEF DEBUG_BUILD
		PrintString szChangeFolder
	ENDIF
	invoke SetEnvironmentVariable,offset szEnvLib,offset szChangeFolder
	mov eax,pHandles
	invoke SendMessage,[eax].HANDLES.hMain,dwWANWSetEnvVars,0,0
	ret
	
SetMyEnvVariables endp

align DWORD
UseTitleAsOut proc pszKey:PTR BYTE
	local szOutputFile[256]	:BYTE
	
	IFDEF DEBUG_BUILD
		PrintText "Use the new project's title as the default output filename."
	ENDIF
	mov szOutputFile[0],0
	.if dwWizChoice != IDD_PAGE2_4	;Always overwrite /OUT of cloned projects
		invoke GetPrivateProfileString,
		 		offset szMAKE,pszKey,offset szNull,
		 		addr szOutputFile,sizeof szOutputFile,offset szTargetWap
	.endif
	.if szOutputFile[0] == 0
		invoke lstrcpyn,addr szOutputFile,offset szTargetTitle,sizeof szOutputFile
		invoke GetPrivateProfileInt,offset szPROJECT,offset szType,0,offset szTargetWap
		.if eax > 6
			mov eax,6
		.endif
		xor edx,edx		;clears the carry flag
		rcr eax,1
		.if !carry?
			mov eax,offset szDotExe		; .exe for types 0,2,4,6
		.else
			mov edx,5					; .dll,.lib,.bin for types 1,3,5
			mul edx
			add eax,offset szExtensions
		.endif
		invoke PathAddExtension,addr szOutputFile,eax
		IFDEF DEBUG_BUILD
			PrintString szOutputFile
		ENDIF
		invoke WritePrivateProfileString,
		 	offset szMAKE,pszKey,addr szOutputFile,offset szTargetWap
	.endif
	ret
	
UseTitleAsOut endp

align DWORD
FixWapEntry proc pszSection:PTR BYTE, pszKey:PTR BYTE
	local bOk			:DWORD
	local szTxt[256]	:BYTE
	
	; Fixes a WAP file entry in the [MAKE] section
	
	; szChangeFolder:			Temp buffer
	; szUseTemplateWap:			Source project file
	; szTargetWap:				Target project file
	
	; Special environment variables:
	; %project%					Project filename
	; %folder%					Project folder
	; %title%					Project title
	; %wafolder%				WinAsm folder
	; %waaddins%				Add-Ins folder
	; %wabin%					Bin folder
	; %wainc%					Include folder
	; %walib%					Library folder
	; you can use any others as well...
	
	IFDEF DEBUG_BUILD
		PrintStringByAddr pszSection
		PrintStringByAddr pszKey
	ENDIF
	mov szTxt[0],0
	invoke GetPrivateProfileString,pszSection,pszKey,offset szNull,
	 			addr szTxt,sizeof szTxt,offset szUseTemplateWap
	.if eax
		IFDEF DEBUG_BUILD
			PrintString szTxt
		ENDIF
		invoke ExpandEnvironmentStrings,addr szTxt,
		 			offset szChangeFolder,sizeof szChangeFolder
		.if eax
			IFDEF DEBUG_BUILD
				PrintString szChangeFolder
			ENDIF
			invoke WritePrivateProfileString,pszSection,pszKey,
			 			offset szChangeFolder,offset szTargetWap
		.endif
	.endif
	ret
	
FixWapEntry endp

align DWORD
FixProjectData proc
	
	; Fix the build commands in the target project file
	
	; szChangeFolder:			Temp buffer
	; szUseTemplateWap:			Source project file
	; szTargetWap:				Target project file
	
	IFDEF DEBUG_BUILD
		PrintText "Fixing target project build commands"
		PrintString szTargetWap
	ENDIF
	invoke FixWapEntry,offset szPROJECT,offset szReleaseCommandLine
	invoke FixWapEntry,offset szPROJECT,offset szDebugCommandLine
	invoke FixWapEntry,offset szMAKE,offset szCompileRC
	invoke FixWapEntry,offset szMAKE,offset szRCToObj
	invoke FixWapEntry,offset szMAKE,offset szAssemble
	invoke FixWapEntry,offset szMAKE,offset szLink
	invoke FixWapEntry,offset szMAKE,offset szOut
	invoke FixWapEntry,offset szMAKE,offset szDebAssemble
	invoke FixWapEntry,offset szMAKE,offset szDebLink
	invoke FixWapEntry,offset szMAKE,offset szDebOut
	.if bUseTitleAsOut
		invoke UseTitleAsOut,offset szOut
		invoke UseTitleAsOut,offset szDebOut
	.endif
	ret
	
FixProjectData endp

align DWORD
FixProjectFiles proc
	local dwNum		:DWORD
	local szNum[20]	:BYTE
	local szTxt[256]:BYTE
	
	; Fixes the project filenames
	
	; szTargetWap:				Target project file
	IFDEF DEBUG_BUILD
		PrintText "Fixing project filenames"
		PrintString szTargetWap
	ENDIF
	mov dwNum,1
	invoke SetCurrentDirectory,offset szTargetFolder
	.while eax
		invoke wsprintf,addr szNum,offset szFmtInt,dwNum
		.break .if !eax
		invoke FixWapEntry,offset szFILES,addr szNum
		inc dwNum
	.endw
	ret
	
FixProjectFiles endp

align DWORD
FixMenuItems proc uses ebx esi
	pushcontext assumes
	assume ebx:PTR HANDLES
	
	; Enable and disable the corresponding menu items and toolbar buttons
	IFDEF DEBUG_BUILD
		PrintText "Enable and disable the corresponding menu items"
	ENDIF
	mov ebx,pHandles
	mov esi,offset aMenuItemsToEnable
	.repeat
		lodsd
		invoke EnableMenuItem,[ebx].hMenu,eax,MF_BYCOMMAND or MF_ENABLED
	.until esi >= offset aMenuItemsToEnable + sizeof aMenuItemsToEnable
	mov esi,offset aMenuItemsToDisable
	.repeat
		lodsd
		invoke EnableMenuItem,[ebx].hMenu,eax,MF_BYCOMMAND or MF_GRAYED
	.until esi >= offset aMenuItemsToDisable + sizeof aMenuItemsToDisable
	mov eax,dwProjectType
	.if (eax == 0) || (eax == 2) || (eax == 6)
		push TRUE
	.else
		push FALSE
	.endif
	push IDM_MAKE_EXECUTE
	push TB_ENABLEBUTTON
	push [ebx].hMakeTB
	call SendMessage
	invoke SendMessage,[ebx].hMakeTB,TB_ENABLEBUTTON,IDM_MAKE_ASSEMBLE,TRUE
	invoke SendMessage,[ebx].hMakeTB,TB_ENABLEBUTTON,IDM_MAKE_LINK,TRUE
	invoke SendMessage,[ebx].hMakeTB,TB_ENABLEBUTTON,IDM_MAKE_GO,TRUE
	invoke SendMessage,[ebx].hMainTB,TB_ENABLEBUTTON,IDM_PROJECT_ADDEXISTINGFILE,TRUE
	invoke SendMessage,[ebx].hMainTB,TB_ENABLEBUTTON,IDM_SAVEPROJECT,TRUE
	mov eax,cpi.pszResToObjCommand
	.if eax && (byte ptr [eax] == 0)
		invoke EnableMenuItem,[ebx].hMenu,IDM_MAKE_RCTOOBJ,MF_BYCOMMAND or MF_GRAYED
	.endif
	ret
	
	popcontext assumes
FixMenuItems endp

align DWORD
CopyProjectFolder proc
	
	invoke SetCurrentDirectory,offset szUseTemplate
	.if eax
		invoke PathRemoveBackslash,offset szTargetFolder
		invoke CreateDirectory,offset szTargetFolder,NULL
		IFDEF DEBUG_BUILD
			PrintString szTargetFolder
		ENDIF
		mov eax,pHandles
		push [eax].HANDLES.hMain
		pop shfops.hwnd
		mov shfops.fAnyOperationsAborted,FALSE
		invoke SHFileOperation,offset shfops
		test eax,eax
		mov eax,0
		.if zero?
			inc eax
		.endif
	.endif
	ret
	
CopyProjectFolder endp

align DWORD
GetIniVarLenString proc pFile:PTR BYTE, pSection:PTR BYTE, pKey:PTR BYTE, pDefault:PTR BYTE
	local iSize		:DWORD
	local pString	:DWORD
	
	invoke lstrlen,pDefault
	.if eax < 12
		mov eax,12
	.endif
	mov iSize,eax
	invoke LocalAlloc,LPTR,eax
	.if eax
		mov pString,eax
		.repeat
			invoke GetPrivateProfileString,pSection,pKey,pDefault,pString,iSize,pFile
			test eax,eax
			jz @F
			mov edx,iSize
			inc eax
			.break .if eax != edx
			add edx,16
			mov iSize,edx
			invoke LocalReAlloc,pString,edx,LMEM_MOVEABLE or LMEM_ZEROINIT
			.if !eax
		@@:		invoke LocalFree,pString
				xor eax,eax
				jmp @F
			.endif
			mov pString,eax
		.until FALSE
		mov eax,pString
	.endif
@@:	ret
	
GetIniVarLenString endp

align DWORD
RenameTargetWapFile proc
	local szOldName[MAX_PATH]:BYTE
	
	; This function returns TRUE on success, FALSE on failure, or IDNO on user cancel.
	
	invoke lstrcpyn,addr szOldName,offset szTargetFolder,sizeof szOldName
	invoke PathFindFileName,offset szUseTemplateWap
	invoke PathAppend,addr szOldName,eax
	invoke PathAddExtension,addr szOldName,offset szDotWap
	invoke WritePrivateProfileString,NULL,NULL,NULL,addr szOldName	;(required by Win9X)
	IFDEF DEBUG_BUILD
		PrintText "Renaming the target wap file to match it's title"
		PrintString szOldName
		PrintString szTargetWap
	ENDIF
	invoke PathFileExists,offset szTargetWap
	.if eax
		mov eax,pHandles
		invoke MessageBox,[eax].HANDLES.hMain,offset szTargetWapExists,
		 		offset szWarning,MB_YESNO or MB_ICONWARNING or MB_DEFBUTTON2
		cmp eax,IDNO
		je @F
		invoke DeleteFile,offset szTargetWap
	.endif
	invoke MoveFile,addr szOldName,offset szTargetWap
	.if eax
		push TRUE
		pop eax
	.endif
@@:	ret
	
RenameTargetWapFile endp

align DWORD
MakeTextReplacementsOnFile proc uses ebx esi pFile:PTR BYTE, bRename:DWORD
	local retval				:DWORD
	local hFile					:DWORD
	local pOrig					:DWORD
	local pDest					:DWORD
	local iLow					:DWORD
	local iHigh					:DWORD
	local iRead					:DWORD
	local iDest					:DWORD
	local pName					:DWORD
	local szBuffer[MAX_PATH]	:BYTE
	local szBuffer2[MAX_PATH]	:BYTE
	local szBuffer3[MAX_PATH]	:BYTE
	local szBuffer4[MAX_PATH]	:BYTE
	
	mov retval,FALSE
	mov pDest,NULL
	
	; Make environment string replacements
	invoke ExpandEnvironmentStrings,pFile,addr szBuffer,MAX_PATH
	.if eax
		lea eax,szBuffer
		mov pFile,eax
		
		; Change the file name if needed
		.if bRename
			invoke lstrcpy,addr szBuffer4,pFile
			invoke PathRemoveExtension,addr szBuffer4
			invoke PathFindExtension,pFile
			xchg ebx,eax
			invoke PathFindFileName,offset szUseTemplateWap
			invoke lstrcpy,offset szTemplateMask,eax
			invoke PathRemoveExtension,offset szTemplateMask
			invoke lstrcmpi,addr szBuffer4,offset szTemplateMask
			.if eax == 0
				.if ebx && ebx != pFile
					invoke PathAddExtension,addr szBuffer4,ebx
				.endif
				lea eax,szBuffer4
				mov pFile,eax
			.endif
		.endif
		
		IFDEF DEBUG_BUILD
			PrintStringByAddr pFile
		ENDIF
		
		; Make sure the file is within the project folder
		invoke GetFullPathName,addr szBuffer,MAX_PATH,addr szBuffer2,addr pName
		.if eax
			invoke lstrcpy,addr szBuffer,addr szBuffer2
			mov eax,pName
			mov byte ptr [eax - 1],0
			invoke PathCommonPrefix,addr szBuffer2,offset szTargetFolder,addr szBuffer3
			push eax
			invoke lstrlen,offset szTargetFolder
			pop edx
			.if edx >= eax
				
				; Read the file into memory
				invoke CreateFile,
					addr szBuffer,GENERIC_READ,FILE_SHARE_READ,NULL,
					OPEN_EXISTING,FILE_FLAG_SEQUENTIAL_SCAN,NULL
				.if eax != INVALID_HANDLE_VALUE
					mov hFile,eax
					lea edx,iHigh
					invoke GetFileSize,eax,edx
					.if eax
						mov iLow,eax
						mov ebx,eax
						mov edx,iHigh
						add eax,1
						adc edx,0
						.if zero?
							invoke VirtualAlloc,NULL,eax,MEM_COMMIT,PAGE_READWRITE
							.if eax
								mov pOrig,eax
								mov esi,eax
								invoke RtlZeroMemory,eax,iLow
								.repeat
									invoke ReadFile,hFile,esi,ebx,addr iRead,NULL
									test eax,eax
									jz @F
									mov eax,iRead
									.break .if !eax
									add esi,eax
									sub ebx,eax
								.until zero?
								
								; Replace all NULL chars with spaces
								mov ebx,pOrig
								mov ecx,iLow
								.repeat
									.if byte ptr [ebx] == 0
										mov byte ptr [ebx],32
									.endif
									add ebx,1
									sub ecx,1
								.until zero?
								
								; Allocate a buffer for the modified file data
								; and make the text replacements
								invoke ExpandEnvironmentStrings,pOrig,NULL,0
								.if eax
									mov iDest,eax
									invoke VirtualAlloc,NULL,eax,MEM_COMMIT,PAGE_READWRITE
									.if eax
										mov pDest,eax
										invoke ExpandEnvironmentStrings,pOrig,eax,iDest
										.if !eax
											invoke VirtualFree,pDest,iDest,MEM_RELEASE
											mov pDest,NULL
										.endif
									.endif
								.endif
								
						@@:		invoke VirtualFree,pOrig,0,MEM_RELEASE
							.endif
						.endif
					.endif
					invoke CloseHandle,hFile
				.endif
				
				; Save the output data, if any, and release the buffer
				mov eax,pDest
				.if eax
					mov esi,eax
					invoke lstrlen,eax
					.if eax
						xchg ebx,eax
						mov word ptr szBuffer2[0],'.'
						invoke GetTempPath,MAX_PATH - 12,addr szBuffer2
						invoke GetTempFileName,addr szBuffer2,offset szWA,0,addr szBuffer2
						mov hFile,NULL
						invoke CreateFile,addr szBuffer2,GENERIC_WRITE,0,NULL,CREATE_ALWAYS,0,NULL
						.if eax
							mov hFile,eax
							push eax
							.repeat
								invoke WriteFile,hFile,esi,ebx,addr iRead,NULL
								.if !eax
									mov hFile,eax
									.break
								.endif
								mov eax,iRead
								.break .if eax == 0
								add esi,eax
								sub ebx,eax
							.until zero?
							call CloseHandle
						.endif
						.if hFile != NULL
							; Doesn't work on my stupid Win9X box! >:(
							;invoke MoveFileEx,addr szBuffer2,addr szBuffer,
							;	MOVEFILE_COPY_ALLOWED or MOVEFILE_REPLACE_EXISTING
							invoke DeleteFile,addr szBuffer
							invoke MoveFile,addr szBuffer2,addr szBuffer
							.if eax
								mov retval,TRUE
							.else
								invoke DeleteFile,addr szBuffer2
							.endif
						.endif
					.endif
					invoke VirtualFree,pDest,0,MEM_RELEASE
				.endif
				
			.endif
		.endif
		
	.endif
	
	mov eax,retval
	ret
	
MakeTextReplacementsOnFile endp

align DWORD
ParseProjectFiles proc uses esi edi
	local retval			:DWORD
	local pList				:DWORD
	local bRename			:DWORD
	local szExt[MAX_PATH]	:BYTE
	
	mov retval,TRUE
	
	IFDEF DEBUG_BUILD
		PrintText "Parse template files"
	ENDIF
	
	; Get the list of files to parse
	invoke GetIniVarLenString,offset szUseTemplateWap,offset szTEMPLATE,offset szParse,offset szNull
	.if eax
		mov pList,eax
		
		; Find out if we need to rename the file names in the list
		invoke GetPrivateProfileInt,offset szTEMPLATE,offset szRename,FALSE,offset szUseTemplateWap
		mov bRename,eax
		
		; Make the corresponding text replacements on each file
		mov edi,pList
		invoke lstrlen,edi
		xchg ecx,eax
		.while ecx
			push edi
			mov al,','
			repne scasb
			.if zero?
				dec edi
			.endif
			mov al,0
			stosb
			pop eax
			push ecx
			invoke MakeTextReplacementsOnFile,eax,bRename
			and retval,eax
			pop ecx
		.endw
		
		; Release the list of files
quit:	invoke LocalFree,pList
		
	.endif
	
	mov eax,retval
	ret
	
ParseProjectFiles endp

align DWORD
RenameInWapFileList proc pDest:PTR BYTE, pSrc:PTR BYTE
	local pFilePart				:DWORD
	local iNumber				:DWORD
	local szNumber[20]			:BYTE
	local szFilename[MAX_PATH]	:BYTE
	
	mov iNumber,1
	.repeat
		invoke wsprintf,addr szNumber,offset szFmtInt,iNumber
		invoke GetPrivateProfileString,
		 			offset szFILES,addr szNumber,offset szNull,
		 			addr szFilename,sizeof szFilename,offset szTargetWap
		.break .if eax == 0
		invoke lstrcmpi,addr szFilename,pSrc
		.if eax == 0
			IFDEF DEBUG_BUILD
				PrintText "Rename (in WAP file list)"
				PrintStringByAddr pSrc
				PrintStringByAddr pDest
				PrintDec iNumber
			ENDIF
			invoke WritePrivateProfileString,
			 			offset szFILES,addr szNumber,pDest,offset szTargetWap
			.break
		.endif
		inc iNumber
	.until FALSE
	ret
	
RenameInWapFileList endp

align DWORD
RenameProjectFiles proc uses ebx esi edi
	local retval			:DWORD
	local hFind				:DWORD
	local pList				:DWORD
	local w32fd				:WIN32_FIND_DATA
	local szExt[MAX_PATH]	:BYTE
	
	mov retval,TRUE
	
	; Do this only if "Rename" is TRUE.
	xor eax,eax
;	.if dwWizChoice == IDD_PAGE2_4
;		inc eax
;	.endif
	invoke GetPrivateProfileInt,offset szTEMPLATE,offset szRename,eax,offset szUseTemplateWap
	test eax,eax
	jz quit
	
	; Turn project WAP pathname into a mask
	invoke PathFindFileName,offset szUseTemplateWap
	xchg ebx,eax
	invoke lstrcpy,offset szTemplateMask,ebx
	invoke PathRemoveExtension,offset szTemplateMask
	invoke PathAddExtension,offset szTemplateMask,offset szDotAsterisk
	
	; Switch to the target folder
	invoke SetCurrentDirectory,offset szTargetFolder
	
	; Make a list of files to rename
	invoke LocalAlloc,LPTR,MAX_PATH
	.if eax
		mov pList,eax
		xor esi,esi
		xor edi,edi
		
		; Find all files matching the template title
		invoke FindFirstFile,offset szTemplateMask,addr w32fd
		.if eax != INVALID_HANDLE_VALUE
			mov hFind,eax
			.repeat
				invoke lstrlen,addr w32fd.cFileName
				lea edi,[esi + eax + 1]
				invoke LocalReAlloc,pList,edi,LMEM_MOVEABLE or LMEM_ZEROINIT
				.break .if !eax
				mov pList,eax
				add eax,esi
				lea edx,w32fd.cFileName
				invoke lstrcpy,eax,edx
				xchg esi,edi
				invoke FindNextFile,hFind,addr w32fd
			.until !eax
			invoke GetLastError
			.if eax != ERROR_NO_MORE_FILES
				mov retval,FALSE
			.endif
			invoke FindClose,hFind
		.endif
		
		; Rename each file in the list
		.if esi			; ESI had the list size in bytes
			mov edi,pList
			add esi,edi
			.repeat
				invoke lstrcpy,addr w32fd.cFileName,edi
				invoke PathFindExtension,addr w32fd.cFileName
				invoke lstrcpy,addr szExt,eax
				invoke lstrcpy,addr w32fd.cFileName,offset szTargetTitle
				invoke lstrcat,addr w32fd.cFileName,addr szExt
				; The target project file must not be renamed!
				invoke lstrcmpi,ebx,edi
				.if eax != 0
					IFDEF DEBUG_BUILD
						PrintText "Rename (in target project folder)"
						PrintStringByAddr EDI
						lea eax,w32fd.cFileName
						PrintStringByAddr EAX
					ENDIF
					; Rename the file
					invoke MoveFile,edi,addr w32fd.cFileName
					.if eax
						; Update the target WAP files list
						invoke RenameInWapFileList,addr w32fd.cFileName,edi
					.else
						mov retval,FALSE
					.endif
				.endif
				invoke lstrlen,edi
				lea edi,[edi + eax + 1]
			.until edi >= esi
		.endif
		
		; Destroy the list
		invoke LocalFree,pList
		
quit:	mov eax,retval
	.endif
	ret
	
RenameProjectFiles endp

align DWORD
CreateNewProject proc uses ebx esi hWnd:HWND
	
	mov ebx,pHandles
	pushcontext assumes
	assume ebx:PTR HANDLES
	
	; Ask for confirmation if the current project was not saved
	; (Only for versions prior to 3.0.4.0)
	invoke SendMessage,[ebx].hMain,WAM_GETCURRENTPROJECTINFO,offset cpi,0
	.if eax
		mov eax,pFeatures
		.if !eax || [eax].FEATURES.Version < 3040
			IFDEF DEBUG_BUILD
				PrintText "Ask for confirmation if the current project was not saved"
			ENDIF
			mov eax,cpi.pbModified
			.if eax
				cmp dword ptr [eax],TRUE
				je @F
			.endif
			invoke WasProjectModified
			.if eax
		@@:		invoke MessageBox,hWnd,offset szWasNotSaved,
				 		offset szWarning,MB_YESNOCANCEL or MB_ICONWARNING or MB_DEFBUTTON3
				.if eax == IDNO
					invoke MarkProjectFilesAsSaved
				.else
					cmp eax,IDYES
					jne done	;IDCANCEL
					invoke SendMessage,[ebx].hMain,WM_COMMAND,IDM_SAVEPROJECT,0
				.endif
			.endif
			
			; Close the currently open project
			IFDEF DEBUG_BUILD
				PrintText "Close the currently open project"
			ENDIF
			invoke SendMessage,[ebx].hMain,WAM_GETCURRENTPROJECTINFO,offset cpi,0
			.if eax
				invoke SendMessage,[ebx].hMain,WM_COMMAND,IDM_CLOSEPROJECT,0
				invoke SendMessage,[ebx].hMain,WAM_GETCURRENTPROJECTINFO,offset cpi,0
				.if eax
					invoke MessageBox,hWnd,offset szCantClose,offset szError,MB_OK or MB_ICONERROR
					jmp done
				.endif
			.endif
		.endif
	.endif
	
	; Do we create a new project from a template, or clone an existing project?
	mov eax,dwWizChoice
	.if (eax == IDD_PAGE2_2) || (eax == IDD_PAGE2_4)
		IFDEF DEBUG_BUILD
			PrintText "Create a new project from a template, or clone an existing project"
		ENDIF
		
		; Needed data:
		;	szUseTemplate		Template to use
		;	szUseTemplateWap	Project filename for the template to use
		;	szTargetFolder		Target folder
		invoke CopyProjectFolder
		.if eax == 0
			invoke MessageBox,hWnd,offset szCantComplete,
				offset szError,MB_OK or MB_ICONERROR
			jmp done
		.endif
		.if (SDWORD ptr eax) < 0
			invoke MessageBox,hWnd,offset szNotAllFiles,
				offset szAreYouSure,MB_YESNO or MB_ICONQUESTION
			cmp eax,IDNO
			je done
		.endif
		invoke RenameTargetWapFile
		cmp eax,IDNO
		je done
		.if !eax
			invoke MessageBox,hWnd,offset szErrorRenamingWap,
				offset szAreYouSure,MB_YESNO or MB_ICONQUESTION
			cmp eax,IDNO
			je done
		.endif
		invoke WritePrivateProfileString,offset szTEMPLATE,NULL,NULL,offset szTargetWap
		invoke SetMyEnvVariables
		invoke FixProjectData
		invoke FixProjectFiles
		invoke ParseProjectFiles
		.if !eax
			invoke MessageBox,hWnd,offset szErrorParsing,
				offset szAreYouSure,MB_YESNO or MB_ICONQUESTION
			cmp eax,IDNO
			je done
		.endif
		invoke RenameProjectFiles
		.if !eax
			invoke MessageBox,hWnd,offset szErrorRenaming,
				offset szAreYouSure,MB_YESNO or MB_ICONQUESTION
			cmp eax,IDNO
			je done
		.endif
		invoke SendMessage,[ebx].hMain,WAM_OPENPROJECT,offset szTargetWap,0
		
	.else
		
		; Fill GETCURRENTPROJECTINFO members and set the new caption
		invoke SetWindowText,[ebx].hMain,offset szNewProjectMainWindowCaption
		mov edx,cpi.pbModified
		mov eax,cpi.pProjectType
		push TRUE
		pop dword ptr [edx]
		push dwProjectType
		pop dword ptr [eax]
		invoke StringCopy,cpi.pszFullProjectName,offset szNewProjectFile
		invoke StringCopy,cpi.pszProjectTitle,offset szNewProjectTitle
		invoke GetDefBuildCmds
		invoke StringCopy,cpi.pszCompileRCCommand,		offset pszCompileRCCommand
		invoke StringCopy,cpi.pszResToObjCommand,		offset pszResToObjCommand
		invoke StringCopy,cpi.pszReleaseAssembleCommand,offset pszReleaseAssembleCommand
		invoke StringCopy,cpi.pszReleaseLinkCommand,	offset pszReleaseLinkCommand
		invoke StringCopy,cpi.pszReleaseOUTCommand,		offset pszReleaseOUTCommand
		invoke StringCopy,cpi.pszDebugAssembleCommand,	offset pszDebugAssembleCommand
		invoke StringCopy,cpi.pszDebugLinkCommand,		offset pszDebugLinkCommand
		invoke StringCopy,cpi.pszDebugOUTCommand,		offset pszDebugOUTCommand
		
		; Let's see what was the user's choice...
		.if dwWizChoice == IDD_PAGE2_1				; Create a new empty project
			IFDEF DEBUG_BUILD
				PrintText "Create a new empty project"
			ENDIF
			
			invoke SendMessage,[ebx].hMain,WM_COMMAND,IDM_PROJECT_ADDASM,0
			
		.else										; Create a new project from existing files
			IFDEF DEBUG_BUILD
				PrintText "Create a new project from existing files"
			ENDIF
			
			; Needed data:
			;	pFilesToAdd			Pointer to list of project files (full pathnames)
			invoke RedrawWindow,hWnd,NULL,NULL,
				RDW_ERASE or RDW_FRAME or RDW_INTERNALPAINT or\
				RDW_INVALIDATE or RDW_UPDATENOW or RDW_ALLCHILDREN
			invoke LockWindowUpdate,[ebx].hMain
			xor esi,esi
			xchg esi,pFilesToAdd
			test esi,esi
			jz oops
			push esi
			.while byte ptr [esi] != 0
				invoke SendMessage,[ebx].hMain,
					WAM_ADDOPENEXISTINGFILE,esi,TRUE
				invoke lstrlen,esi
				lea esi,[esi + eax + 1]
			.endw
			call LocalFree
			invoke HideProjectFiles
			invoke LockWindowUpdate,NULL
			invoke RedrawWindow,hWnd,NULL,NULL,
				RDW_ERASE or RDW_FRAME or RDW_INTERNALPAINT or\
				RDW_INVALIDATE or RDW_UPDATENOW or RDW_ALLCHILDREN
			
		.endif
	.endif
	
	; Actions to take after project creation
	invoke SendMessage,[ebx].hMain,WAM_GETCURRENTPROJECTINFO,offset cpi,0
	.if eax
		
		; Change current directory to project folder
		invoke GetFullPathName,cpi.pszFullProjectName,sizeof szChangeFolder,
		 						offset szChangeFolder,NULL
		.if eax
			invoke PathFindFileName,offset szChangeFolder
			.if eax
				mov byte ptr [eax],0
				invoke SetCurrentDirectory,offset szChangeFolder
			.endif
		.endif
		
		; Enable and disable the corresponding menu items and toolbar buttons
		invoke FixMenuItems
		
		; Prompt to save WAP file (always for options #2 and #4)
		mov eax,dwWizChoice
		.if bSaveWap || (eax == IDD_PAGE2_2) || (eax == IDD_PAGE2_4)
			IFDEF DEBUG_BUILD
				PrintText "Prompt to save WAP file"
			ENDIF
			invoke SendMessage,[ebx].hMain,WM_COMMAND,IDM_SAVEPROJECT,0
		.endif
		
		; Auto build new project (never for option #1)
		.if bGoAll && (dwWizChoice != IDD_PAGE2_1)
			IFDEF DEBUG_BUILD
				PrintText "Auto build new project"
			ENDIF
			invoke RedrawWindow,hWnd,NULL,NULL,
				RDW_ERASE or RDW_FRAME or RDW_INTERNALPAINT or\
				RDW_INVALIDATE or RDW_UPDATENOW or RDW_ALLCHILDREN
			invoke SendMessage,[ebx].hMain,WM_COMMAND,IDM_MAKE_GO,0
		.endif
		
	.else
		
oops:	;Fatal error while creating new project
		invoke MessageBox,hWnd,offset szErrorOccured,offset szError,MB_OK or MB_ICONERROR
		xor eax,eax
		xchg eax,pFilesToAdd
		.if eax
			invoke LocalFree,eax
		.endif
		
	.endif
	popcontext assumes
done:
	ret
	
CreateNewProject endp

align DWORD
InferPathName proc pBuffer:PTR BYTE, pszSuffix:PTR BYTE
	local pFilePart:DWORD
	
	invoke lstrcpyn,pBuffer,pIniFile,MAX_PATH
	.if eax
		invoke PathFindFileName,eax
		.if eax
			mov byte ptr [eax],0
			invoke PathAppend,pBuffer,offset szDotDot
			.if eax
				invoke PathAppend,pBuffer,pszSuffix
				.if eax
					invoke GetFullPathName,pBuffer,MAX_PATH,pBuffer,addr pFilePart
				.endif
			.endif
		.endif
	.endif
	ret
	
InferPathName endp

; -----------------------------------------------------------------------------
; Callback procedures
; -----------------------------------------------------------------------------

align DWORD
GetWAAddInData proc lpFriendlyName:PTR BYTE, lpDescription:PTR BYTE
	
	invoke StringCopy,lpFriendlyName,offset szFriendlyName
	invoke StringCopy,lpDescription,offset szDescription
	ret
	
GetWAAddInData endp

align DWORD
WAAddInLoad proc pWinAsmHandles:PTR HANDLES, pWinAsmFeatures:PTR FEATURES
	
	; Keep pWinAsmHandles and pWinAsmFeatures.
	; pWinAsmHandles is a pointer to the HANDLES structure.
	; pWinAsmFeatures is a pointer to the FEATURES structure.
	push pWinAsmHandles
	pop pHandles
	push pWinAsmFeatures
	pop pFeatures
	
	; Initialize WAAddInLib.lib
	invoke InitializeAddIn,ppsph.hInstance,pWinAsmHandles,pWinAsmFeatures,offset szAppName
	.if !eax
@@:		dec eax		;return -1 to cancel loading this addin
		ret
	.endif
	mov pIniFile,eax	; Keep the pointer to the addins INI filename.
	
	; Infer the templates folder path from the add-in's path
	invoke InferPathName,offset szTemplatesPath,offset szTemplatesDir
	test eax,eax
	jz @B
	
	; Infer the WinAsm INI file full pathname from the add-in's path
	invoke InferPathName,offset szWAIniPath,offset szWAIniFile
	test eax,eax
	jz @B
	
	; Ensure the current version of WinAsm Studio is compatible with the addin.
	invoke CheckWAVersion,3016	;For example, version 3.0.1.4 is 3014 (decimal).
	test eax,eax
	jz @B
	
	; Fix built-in defaults for static library make commands
	mov eax,pWinAsmFeatures
	.if [eax].FEATURES.Version >= 3027
		add dword ptr aBuildCommands[4 * (3 * 8 + 3)],4
		add dword ptr aBuildCommands[4 * (3 * 8 + 6)],5
	.endif
	
	; Initialize the OLE libraries
	invoke CoInitialize,0
	
	; Register private messages (used to notify other addins)
	invoke RegisterWindowMessage,offset szWANewWizAddInBegin
	mov dwWANewWizAddInBegin,eax
	invoke RegisterWindowMessage,offset szWANewWizAddInEnd
	mov dwWANewWizAddInEnd,eax
	invoke RegisterWindowMessage,offset szProjPropMsg
	mov dwProjPropMsg,eax
	invoke RegisterWindowMessage,offset szWANWSetEnvVars
	mov dwWANWSetEnvVars,eax
	
	; Notify other addins
	mov eax,pWinAsmHandles
	invoke SendMessage,[eax].HANDLES.hMain,dwWANewWizAddInBegin,0,0
	
	; Get the addin's config
	invoke GetPrivateProfileInt,offset szAppName,offset szEnableWizard,TRUE,pIniFile
	.if eax
		push TRUE
		pop eax
	.endif
	mov bEnableWizard,eax
	invoke GetPrivateProfileInt,offset szAppName,offset szEnableProperties,TRUE,pIniFile
	.if eax
		push TRUE
		pop eax
	.endif
	mov bEnableProperties,eax
	invoke GetPrivateProfileInt,offset szAppName,offset szUseTitleAsOut,TRUE,pIniFile
	.if eax
		push TRUE
		pop eax
	.endif
	mov bUseTitleAsOut,eax
	
	; Get some last taken choices
	invoke GetLastTakenChoices
	
	; Try to get the pointer to FindFirstFileEx.
	mov pFindFirstFileEx,NULL
	invoke GetModuleHandle,offset szKernel32		;Must already be loaded...
	.if eax
		invoke GetProcAddress,eax,offset szFindFirstFileEx
		mov pFindFirstFileEx,eax
	.endif
	
	; Return
	xor eax,eax
	ret
	
WAAddInLoad endp

align DWORD
WAAddInUnload proc
	
	; Save the addin's config
	mov eax,bEnableWizard
	and eax,1
	add eax,eax
	add eax,offset sz0
	invoke WritePrivateProfileString,offset szAppName,offset szEnableWizard,eax,pIniFile
	mov eax,bEnableProperties
	and eax,1
	add eax,eax
	add eax,offset sz0
	invoke WritePrivateProfileString,offset szAppName,offset szEnableProperties,eax,pIniFile
	mov eax,bUseTitleAsOut
	and eax,1
	add eax,eax
	add eax,offset sz0
	invoke WritePrivateProfileString,offset szAppName,offset szUseTitleAsOut,eax,pIniFile
	
	; Save some last taken choices
;	invoke SaveLastTakenChoices
	
	; Notify other addins
	mov eax,pHandles
	invoke SendMessage,[eax].HANDLES.hMain,dwWANewWizAddInBegin,0,0
	
	; Destroying the system image list on Win9X is evil...
	; But failing to destroy it on XT, XP or 2K causes a memory leak.
	.if hSysSmIml
		invoke GetVersion
		rcl eax,1
		.if !carry?
			invoke ImageList_Destroy,hSysIml
			invoke ImageList_Destroy,hSysSmIml
		.endif
	.endif
	
	; Uninitialize the OLE libraries
	invoke CoUninitialize
	
	; Return
	xor eax,eax
	ret
	
WAAddInUnload endp

align DWORD
WAAddInConfig proc pWinAsmHandles:PTR HANDLES, pWinAsmFeatures:PTR FEATURES
	
	; Keep pWinAsmHandles and pWinAsmFeatures.
	; pWinAsmHandles is a pointer to the HANDLES structure.
	; pWinAsmFeatures is a pointer to the FEATURES structure.
	push pWinAsmHandles
	pop pHandles
	push pWinAsmFeatures
	pop pFeatures
	
	; Initialize WAAddInLib.lib
	invoke InitializeAddIn,ppsph.hInstance,pWinAsmHandles,pWinAsmFeatures,offset szAppName
	.if !eax
@@:		dec eax		;return -1 to indicate a failure condition
		ret
	.endif
	mov pIniFile,eax	; Keep the pointer to the addins INI filename.
	
	; Launch the config dialog box
	mov eax,pWinAsmHandles
	.if eax
		mov eax,[eax].HANDLES.hMain
	.endif
	invoke DialogBoxParam,ppsph.hInstance,IDD_DIALOG2,eax,offset ConfigProc,0
	
	xor eax,eax		;return 0 to indicate a success condition
	ret
	
WAAddInConfig endp

align DWORD
FrameWindowProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
	.if uMsg == WM_COMMAND
		mov eax,wParam
		and eax,not 10000h
		.if eax == IDM_PROJECT_PROPERTIES	; ---------------------------------------- Project properties
			cmp bEnableProperties,FALSE
			je ignore
			mov eax,pHandles
			invoke SendMessage,[eax].HANDLES.hMain,WAM_GETCURRENTPROJECTINFO,offset cpi,0
			test eax,eax
			jz ignore
			push hWnd
			pop projpph.hwndParent
			mov eax,cpi.pszFullProjectName
			.if eax
				invoke PathFindFileName,eax
				or projpph.dwFlags,PSH_PROPTITLE
				mov projpph.pszCaption,eax
				mov bProjHasFilename,TRUE
			.else
				and projpph.dwFlags,not PSH_PROPTITLE
				mov projpph.pszCaption,offset szProjProp
				mov bProjHasFilename,FALSE
			.endif
			invoke PropertySheet,offset projpph
			test eax,eax
			js ignore
			invoke FixMenuItems
			jmp prevent
		.endif
		.if eax == IDM_NEWPROJECT			; ---------------------------------------- Create new project
			cmp bEnableWizard,FALSE
			je ignore
			mov bDoIt,FALSE
			push hWnd
			pop ppsph.hwndParent
			invoke PropertySheet,offset ppsph
			test eax,eax
			js ignore
			.if bDoIt
				invoke CreateNewProject,hWnd
			.endif
prevent:	invoke PostMessage,hWnd,WAE_COMMANDFINISHED,wParam,lParam
			push 1
			pop eax
			ret
		.endif
	.endif
ignore:
	xor eax,eax
	ret
	
FrameWindowProc endp

end DllEntryPoint
