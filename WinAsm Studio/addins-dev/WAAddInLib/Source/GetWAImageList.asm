;------------------------------------------------------------------------------
; GetWAImageList
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Returns a handle to the requested WinAsm image list (color or monochrome).
;
; Parameters:
;	bColor		TRUE for the color image list, FALSE for the monochrome one.
;
; Return values:
;	On success, returns the the requested image list handle.
;	On failure, returns NULL.
;
; Remarks:
;	WinAsm Studio version 3.0.5.0 or higher is required.
;------------------------------------------------------------------------------

include Common.inc

.code
align DWORD
GetWAImageList proc bColor:BOOL
	
	; Check WinAsm version.
	xor eax,eax
	mov edx,pFeatures
	test edx,edx
	.if ! zero?
		cmp [edx].FEATURES.Version,3050
		jl @F
		
		; Get the requested image list handle.
		mov edx,pHandles
		test edx,edx
		jz @F
		.if bColor
			mov ecx,[edx].HANDLES.phImlNormal
		.else
			mov ecx,[edx].HANDLES.phImlMonoChrome
		.endif
		jecxz @F
		mov eax,[ecx]
		test eax,eax
		jz @F
		
	.endif
@@:	ret
	
GetWAImageList endp
end
