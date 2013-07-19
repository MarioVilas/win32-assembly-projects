;------------------------------------------------------------------------------
; FindFirstAddIn
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Begins an enumeration of present add-ins in the AddIns folder.
;
; Parameters:
;	pFindData			Pointer to a WIN32_FIND_DATA structure that will
;	 					 receive the add-in's filename information.
;	pszFriendlyName		Pointer to a buffer that will receive the add-in's
;	 					 friendly name.
;	pszDescription		Pointer to a buffer that will receive the add-in's
;	 					 description.
;	pbLoaded			Pointer to a BOOL that will receive the load status
;	 					 (TRUE if the add-in was loaded, FALSE otherwise).
;	pbInstalled			Pointer to a BOOL that will receive the install status
;	 					 (TRUE if the add-in was installed, FALSE otherwise).
;
; Return values:
;	If the function succeeds, the return value is a search handle used in a
;	 subsequent call to FindNextAddIn or FindAddInClose.
;	If the function fails, the return value is INVALID_HANDLE_VALUE. If no
;	 add-ins can be found, GetLastError returns ERROR_NO_MORE_FILES.
;
; Remarks:
;	All parameters are optional (can be NULL). If either pszFriendlyName or
;	 pszDescription are NULL, neither strings will be retrieved.
;	You must use FindAddInClose to close the handle returned by FindFirstAddIn.
;
; See also:
;	FindNextAddIn, FindAddInClose
;------------------------------------------------------------------------------

include Common.inc

.data
szMaskDll db "*.dll",0

.code
align DWORD
FindFirstAddIn proc pFindData:PTR WIN32_FIND_DATA, pszFriendlyName:PTR BYTE, pszDescription:PTR BYTE, pbLoaded:PTR BOOL, pbInstalled:PTR BOOL
	local hFind					:HANDLE
	local szPathMask[MAX_PATH]	:BYTE
	local w32fd					:WIN32_FIND_DATA
	
	mov eax,INVALID_HANDLE_VALUE
	.if szIniFile[0] != 0
		.if pFindData == NULL
			lea eax,w32fd
			mov pFindData,eax
		.endif
		
		; Get the AddIns filename mask
		invoke PathFindFileName,offset szIniFile
		sub eax,offset szIniFile
		invoke lstrcpyn,addr szPathMask,offset szIniFile,eax
		invoke PathAppend,addr szPathMask,offset szMaskDll
		
		; Find the first add-in
		invoke FindFirstFile,addr szPathMask,pFindData
		.if eax != INVALID_HANDLE_VALUE
			mov hFind,eax
			.repeat
				
				; Query the data
				mov eax,pFindData
				add eax,offset WIN32_FIND_DATA.cFileName
				invoke QueryAddIn,eax,pszFriendlyName,pszDescription,pbLoaded,pbInstalled
				.if eax
					mov eax,hFind	; Return the find handle
					jmp @F
				.endif
				
				; Try with the next file if this wasn't an add-in
				invoke FindNextFile,hFind,pFindData
				
			.until !eax
			
			; No add-in was found
			invoke FindClose,hFind
			mov eax,INVALID_HANDLE_VALUE
		.endif
	.endif
@@:	ret
	
FindFirstAddIn endp

;------------------------------------------------------------------------------
; FindNextAddIn
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Continues an enumeration of present add-ins in the AddIns folder.
;
; Parameters:
;	hFind				Handle returned by FindFirstAddIn.
;	pFindData			Pointer to a WIN32_FIND_DATA structure that will
;	 					 receive the add-in's filename information.
;	pszFriendlyName		Pointer to a buffer that will receive the add-in's
;	 					 friendly name.
;	pszDescription		Pointer to a buffer that will receive the add-in's
;	 					 description.
;	pbLoaded			Pointer to a BOOL that will receive the load status
;	 					 (TRUE if the add-in was loaded, FALSE otherwise).
;	pbInstalled			Pointer to a BOOL that will receive the install status
;	 					 (TRUE if the add-in was installed, FALSE otherwise).
;
; Return values:
;	If the function succeeds, the return value is nonzero.
;	If the function fails, the return value is zero. If no more add-ins can be
;	 found, GetLastError returns ERROR_NO_MORE_FILES.
;
; Remarks:
;	All parameters are optional (can be NULL). If either pszFriendlyName or
;	 pszDescription are NULL, neither strings will be retrieved.
;
; See also:
;	FindFirstAddIn, FindAddInClose
;------------------------------------------------------------------------------
align DWORD
FindNextAddIn proc hFind:HANDLE, pFindData:PTR WIN32_FIND_DATA, pszFriendlyName:PTR BYTE, pszDescription:PTR BYTE, pbLoaded:PTR BOOL, pbInstalled:PTR BOOL
	local w32fd					:WIN32_FIND_DATA
	
	xor eax,eax
	.if (hFind != INVALID_HANDLE_VALUE) && (szIniFile[0] != 0)
		.if pFindData == NULL
			lea eax,w32fd
			mov pFindData,eax
		.endif
		
next:	; Find the next file
		invoke FindNextFile,hFind,pFindData
		.if eax
			
			; Query the add-in
			mov eax,pFindData
			add eax,offset WIN32_FIND_DATA.cFileName
			invoke QueryAddIn,eax,pszFriendlyName,pszDescription,pbLoaded,pbInstalled
			test eax,eax
			jz next		;Try the next file if this wasn't an add-in
			
			; Return TRUE
			push TRUE
			pop eax
			
		.endif
	.endif
	ret
	
FindNextAddIn endp

;------------------------------------------------------------------------------
; FindAddInClose
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Ends an enumeration of present add-ins in the AddIns folder.
; Parameters:
;	hFind				Handle returned by FindFirstAddIn.
; Return values:
;	Nonzero on success, zero on failure.
; See also:
;	FindFirstAddIn, FindNextAddIn
;------------------------------------------------------------------------------

align DWORD
FindAddInClose proc hFind:HANDLE
	
	; I know it looks stupid... but it's a wrapper so
	; we can change the three functions in the future.
	invoke FindClose,hFind
	ret
	
FindAddInClose endp

end
