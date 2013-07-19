;------------------------------------------------------------------------------
; GetOutputFile
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Retrieves the build output filename for the current project.
;
; Parameters:
;	pszFile			Pointer to a buffer that will receive the filename.
;	dwSize			Size of the buffer pointed to by pszFile.
;
; Return values:
;	The return value is the number of bytes actually copied to the buffer, not
;	 including the terminating NULL.
;------------------------------------------------------------------------------

include Common.inc

.data
szASMFiles		db "ASM Files",0
szDotExe		db ".exe",0
szExtensions 	label BYTE
	 			db ".dll",0
	 			db ".lib",0
	 			db ".bin",0		;Not sure about this one...

.code
align DWORD
GetOutputFile proc pszFile:PTR BYTE, dwSize:DWORD
	local dwMode				:DWORD				; Current build mode
	local pFile					:PTR BYTE			; Pointer to output filename
	local hCtrl					:HWND				; Handle to Project Explorer treeview
	local tvi					:TVITEM				; Used to browse treeview items
	local cpi					:CURRENTPROJECTINFO	; Current project info
	local szCurrDir[MAX_PATH]	:BYTE				; Current directory
	local szPath[MAX_PATH]		:BYTE				; Target output folder
	local szTitle[MAX_PATH]		:BYTE				; Default output file title
	
	; Validate the parameters
	xor eax,eax
	.if pszFile && dwSize
		
		; Get the current build mode
		invoke GetBuildMode
		test eax,eax
		jz @F
		mov dwMode,eax
		
		; Get the current project info
		mov edx,pHandles
		invoke SendMessage,[edx].HANDLES.hMain,WAM_GETCURRENTPROJECTINFO,addr cpi,0
		test eax,eax
		jz @F
		mov eax,cpi.pszFullProjectName
		test eax,eax
		jz @F
		
		; Get the target output folder for the project
		invoke PathFindFileName,eax
		test eax,eax
		jz @F
		sub eax,cpi.pszFullProjectName
		jz @F
		.if eax > MAX_PATH
			mov eax,MAX_PATH
		.endif
		invoke lstrcpyn,addr szPath,cpi.pszFullProjectName,eax
		
		; Get the /OUT command for the current build mode
		.if dwMode == BUILD_MODE_RELEASE
			mov eax,cpi.pszReleaseOUTCommand
		.else
			mov eax,cpi.pszDebugOUTCommand
		.endif
		
		; If no /OUT command was given, deduce the output filename.
		; Note: If the /OUT: field is not specified, WinAsm Studio will use
		; the name of the first assembly source file listed in the Explorer
		; to create and/or execute an exe file, not the ProjectName.
		.if !eax
			; Get the Project Explorer treeview
			mov eax,pHandles
			test eax,eax
			jz @F
			mov eax,[eax].HANDLES.hProjTree
			test eax,eax
			jz @F
			mov hCtrl,eax
			; Find the "ASM Files" folder
			invoke SendMessage,eax,TVM_GETNEXTITEM,TVGN_ROOT,NULL
			test eax,eax
			jz @F
			invoke SendMessage,hCtrl,TVM_GETNEXTITEM,TVGN_CHILD,eax
			test eax,eax
			jz @F
			lea edx,szTitle
			mov tvi._mask,TVIF_TEXT
			mov tvi.pszText,edx
			mov tvi.cchTextMax,sizeof szTitle
			.repeat
				mov tvi.hItem,eax
				.break .if !eax
				invoke SendMessage,hCtrl,TVM_GETITEM,0,addr tvi
				.if eax
					invoke lstrcmp,addr szTitle,offset szASMFiles
					.break .if eax
				.endif
				invoke SendMessage,hCtrl,TVM_GETNEXTITEM,TVGN_NEXT,tvi.hItem
			.until FALSE
			mov eax,tvi.hItem
			test eax,eax
			jz @F
			; Find the first .asm file in the project
			invoke SendMessage,hCtrl,TVM_GETNEXTITEM,TVGN_CHILD,eax
			test eax,eax
			jz @F
			mov tvi.hItem,eax
			invoke SendMessage,hCtrl,TVM_GETITEM,0,addr tvi
			test eax,eax
			jz @F
			; Remove the .asm extension
			invoke PathRemoveExtension,addr szTitle
			test eax,eax
			jz @F
			; Append the correct extension, based on the project type
			mov eax,cpi.pProjectType
			test eax,eax
			jz @F
			mov eax,[eax]
			xor edx,edx		;clears the carry flag
			rcr eax,1
			.if !carry?
				mov eax,offset szDotExe		; .exe for types 0,2,4,6
			.else
				mov edx,5					; .dll,.lib,.bin for types 1,3,5
				mul edx
				add eax,offset szExtensions
			.endif
			invoke PathAddExtension,addr szTitle,eax
			test eax,eax
			jz @F
			; Get the pointer to the output filename
			lea eax,szTitle
		.endif
		
		; Keep the pointer to the filename
		mov pFile,eax
		
		; Parse the output file's full pathname
		invoke GetCurrentDirectory,sizeof szCurrDir,addr szCurrDir
		test eax,eax
		jz @F
		invoke SetCurrentDirectory,addr szPath
		test eax,eax
		jz @F
		invoke GetFullPathName,pFile,MAX_PATH * 2,addr szPath,addr pFile
		push eax
		invoke SetCurrentDirectory,addr szCurrDir
		pop eax
		test eax,eax
		jz @F
		
		; Copy the requested chars into the output buffer
		invoke lstrcpyn,pszFile,addr szPath,dwSize
		
	.endif
@@:	ret
	
GetOutputFile endp

end
