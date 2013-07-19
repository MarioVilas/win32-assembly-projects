;------------------------------------------------------------------------------
; InitializeAddIn
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Initializes WAAddIns.lib.
;
; Parameters:
;	hInstDll		Instance handle of the addin's DLL (optional).
;	pHandles		Pointer to WinAsm's handles provided in WAAddInLoad.
;	pFeatures		Pointer to WinAsm's features provided in WAAddInLoad.
;	pszSection		Pointer to an ASCIIZ string with the section name to use
;	 				 in the addins INI file (optional).
;
; Return values:
;	On success, the return value is a pointer to the addins INI full pathname.
;	On error, the return value is NULL.
;
; Remarks:
;	MUST be the called before any other procedure in this library.
;
;	Although some parameters are optional, it is recommended to use them all,
;	 otherwise some functions may not work as expected.
;
;	Make sure to provide the addin's instance handle if you plan to use the
;	 UnloadAddIn function, or you might cause a GPF trying to unload your own
;	 add-in!
;
;	The string pointed to by pszSection must be allocated in a static buffer.
;
;	If pszSection is NULL, no data will be read from or saved to the addins
;	 INI file.
;------------------------------------------------------------------------------

include Common.inc

.data
szAddInsFolder	db "AddIns\"
szAddInsIniFile	db "WAAddIns.ini",0

.data?
hInstDll	dd ?
pHandles	dd ?
pFeatures	dd ?
pszSection	dd ?
szIniFile	db MAX_PATH dup (?)

.code
align DWORD
InitializeAddIn proc _hInstDll:HINSTANCE, _pHandles:PTR HANDLES, _pFeatures:PTR FEATURES, _pszSection:PTR BYTE
	
	; Save the global variables
	mov eax,_pHandles
	test eax,eax
	jz @F
	mov pHandles,eax
	mov eax,_pFeatures
	test eax,eax
	jz @F
	mov pFeatures,eax
	push _hInstDll
	pop hInstDll
	push _pszSection
	pop pszSection
	
	; Get the addins INI filename
	mov ecx,sizeof szIniFile - sizeof szAddInsIniFile
	.if !edx
		sub ecx,sizeof szAddInsFolder
	.endif
	invoke GetModuleFileName,hInstDll,offset szIniFile,ecx
	.if eax
		invoke PathFindFileName,offset szIniFile
		.if eax
			.if hInstDll
				push offset szAddInsIniFile
			.else
				push offset szAddInsFolder
			.endif
			push eax
			call lstrcpy
			.if eax
				mov eax,offset szIniFile
				jmp short @F
			.endif
		.endif
	.endif
	mov szIniFile[0],0
	
	; Return
@@:	ret
	
InitializeAddIn endp
end
