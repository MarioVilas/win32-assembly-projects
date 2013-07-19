;------------------------------------------------------------------------------
; QueryAddIn
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Retrieves the information strings of an add-in, given it's filename.
;	The add-in needs not be loaded previously.
;
; Parameters:
;	pszFilename			Pointer to an ASCIIZ string with the add-in's filename
;	 				 	(path information is optional).
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
;	Nonzero on success, zero on failure.
;
; Remarks:
;	All parameters except pszFilename are optional (can be NULL). If either
;	 pszFriendlyName or pszDescription are NULL, neither strings will be
;	 retrieved.
;
;	The file is assumed to be in the AddIns folder if no path information is
;	 given. The standard DLL file search strategy will NOT be used.
;
; See also:
;	FindFirstAddIn
;------------------------------------------------------------------------------

include Common.inc

.data
szGetWAAddInData	db "GetWAAddInData",0
szWAIniFile			db "WinAsm.ini",0
szADDINS			db "ADDINS",0

.data?
szWAIniPath	db MAX_PATH dup (?)

.code
align DWORD
QueryAddIn proc uses ebx pszFilename:PTR BYTE, pszFriendlyName:PTR BYTE, pszDescription:PTR BYTE, pbLoaded:PTR BOOL, pbInstalled:PTR BOOL
	local bSuccess				:BOOL
	local bLoaded				:BOOL
	local hLib					:HINSTANCE
	local pFilePart				:DWORD
	local szPathname[MAX_PATH]	:BYTE
	
	xor eax,eax
	.if pszFilename && (szIniFile[0] != 0)
		
		; Get the AddIns folder
		invoke PathFindFileName,offset szIniFile
		sub eax,offset szIniFile
		invoke lstrcpyn,addr szPathname,offset szIniFile,eax
		
		; Get the addin full pathname
		invoke PathIsFileSpec,pszFilename
		.if eax
			invoke PathAppend,addr szPathname,pszFilename
		.else
			invoke GetFullPathName,pszFilename,sizeof szPathname,addr szPathname,addr pFilePart
		.endif
		.if eax
			
			; Get the load state, if requested
			.if pbLoaded
				invoke GetModuleHandle,addr szPathname
				.if eax
					mov eax,TRUE
				.endif
				mov bLoaded,eax
			.endif
			
			; Load the add-in's DLL library
			invoke LoadLibrary,addr szPathname
			.if eax
				mov hLib,eax
				mov bSuccess,FALSE
				
				; Get the pointer to GetWAAddInData
				invoke GetProcAddress,eax,offset szGetWAAddInData
				.if eax
					mov bSuccess,TRUE
					
					; Get the add-in's information strings, if requested
					.if pszDescription && pszFriendlyName
						push pszDescription
						push pszFriendlyName
						call eax
					.endif
					
					; Copy the load state, if requested
					mov eax,pbLoaded
					.if eax
						push bLoaded
						pop dword ptr [eax]
					.endif
					
					; Get the install state, if requested
					mov eax,pbInstalled
					.if eax
						push eax
						invoke InstallAddIn,addr szPathname,INSTALL_STATE_QUERY
						pop edx
						mov [edx],eax
					.endif
					
				.endif
				
				; Unload the add-in's DLL library
				invoke FreeLibrary,hLib
				
				mov eax,bSuccess
			.endif
		.endif
	.endif
	ret
	
QueryAddIn endp
end
