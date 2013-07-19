;------------------------------------------------------------------------------
; CheckWAVersion
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Shows an error message box if the current version of WinAsm Studio is below
;	 the given value. Version numbers are decimal, for example version 1.2.3.4
;	 would have the value 1234.
;
; Parameters:
;	dwMinVersion	Minimum version required for the addin to run properly
;
; Return values:
;	TRUE if the current version is acceptable, FALSE otherwise.
;------------------------------------------------------------------------------

include Common.inc

.data
szError			db "Error",0
szNotSupported	db "This addin requires WinAsm Studio version "
Ver1			db "0."
Ver2			db "0."
Ver3			db "0."
Ver4			db "0 or above.",0

.code
align DWORD
CheckWAVersion proc dwMinVersion:DWORD
	
	mov edx,pFeatures
	mov eax,dwMinVersion
	mov ecx,2999			;Last version with no FEATURES pointer: 2.9.9.9
	.if edx
		mov ecx,[edx].FEATURES.Version
	.endif
	.if ecx >= eax
		push 1				;Return TRUE
		pop eax
	.else
		mov ecx,10			;Get 4th digit
		xor edx,edx
		div ecx
		add dl,'0'
		mov Ver4,dl
		xchg eax,edx		;Get 3rd digit
		xor edx,edx
		div ecx
		add dl,'0'
		mov Ver3,dl
		xchg eax,edx		;Get 2nd digit
		xor edx,edx
		div ecx
		add dl,'0'
		mov Ver2,dl
		xchg eax,edx		;Get 1st digit
		xor edx,edx
		div ecx
		add dl,'0'
		mov Ver1,dl
		mov eax,pHandles	;Show message box
		invoke MessageBox,
			[eax].HANDLES.hMain,offset szNotSupported,
			offset szError,MB_OK or MB_ICONERROR
		xor eax,eax			;Return FALSE
	.endif
	ret
	
CheckWAVersion endp
end
