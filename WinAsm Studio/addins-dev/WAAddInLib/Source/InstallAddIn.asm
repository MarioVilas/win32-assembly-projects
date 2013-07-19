;------------------------------------------------------------------------------
; InstallAddIn
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Gets or sets the install state of a given add-in, that is, if it's set to
;	 auto load on WinAsm startup or not. The file is assumed to exist, and to
;	 be located in the AddIns folder.
;
; Parameters:
;	pszFilename			Pointer to an ASCIIZ string with the add-in's filename.
;	 					 Path information will be ignored.
;	dwAction			Flags that indicate the action to take (see remarks).
;
; Return values:
;	On success, the return value is the old install state.
;	On failure, the return value is -1.
;
; Remarks:
;	The file is always assumed to be in the AddIns folder, so any path
;	 information will be ignored.
;
;	This are the possible values for dwAction, and their meanings:
;	 	INSTALL_STATE_CLEAR		Sets the install state to FALSE.
;	 	INSTALL_STATE_SET		Sets the install state to TRUE.
;	 	INSTALL_STATE_QUERY		Gets the install state.
;
; See also:
;	QueryAddIn
;------------------------------------------------------------------------------

include Common.inc

.data
szWAIniFile			db "WinAsm.ini",0
szADDINS			db "ADDINS",0
sz 0
sz 1

.data?
szWAIniPath	db MAX_PATH dup (?)

.code
align DWORD
InstallAddIn proc pszFilename:PTR BYTE, dwAction:DWORD
	local bInstalled:BOOL
	
	; Validate the parameters
	mov edx,pszFilename
	mov bInstalled,-1
	.if edx && szWAIniFile[0] != 0 && byte ptr [edx] != 0
		
		; Get WinAsm.ini full pathname (if needed)
		.if szWAIniPath[0] == 0
			invoke GetModuleFileName,
				NULL,offset szWAIniPath,sizeof szWAIniPath
			invoke PathRemoveFileSpec,offset szWAIniPath
			invoke PathAppend,offset szWAIniPath,offset szWAIniFile
		.endif
		
		; Ignore the path information
		invoke PathFindFileName,pszFilename
		.if eax && (byte ptr [eax] != 0)
			mov pszFilename,eax
			
			; Get the install state
			invoke GetPrivateProfileInt,
			 		offset szADDINS,pszFilename,FALSE,offset szWAIniPath
			.if eax
				push TRUE
				pop eax
			.endif
			mov bInstalled,eax
			
			; Set the new install state, if requested
			mov eax,dwAction
			.if eax == INSTALL_STATE_SET
				mov eax,offset sz1
				jmp short @F
			.endif
			.if eax == INSTALL_STATE_CLEAR
				xor eax,eax
			@@:	invoke WritePrivateProfileString,
				 		offset szADDINS,pszFilename,eax,offset szWAIniPath
			.endif
			
		.endif
	.endif
	
	; Return the old install state
	mov eax,bInstalled
	ret
	
InstallAddIn endp

end
