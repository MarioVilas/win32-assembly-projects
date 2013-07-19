;------------------------------------------------------------------------------
; GetBuildMode
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Retrieves the build mode for the current project.
;
; Parameters:
;	No parameters.
;
; Return values:
;	On success, the return value is BUILD_MODE_DEBUG or BUILD_MORE_RELEASE.
;	On failure, the return value is NULL.
;------------------------------------------------------------------------------

include Common.inc

.code
align DWORD
GetBuildMode proc
	
	; Validate the parameters
	mov edx,pHandles
	xor eax,eax
	.if edx
		mov ecx,[edx].HANDLES.hMenu
		.if ecx
			
			; Get the build mode
			invoke GetMenuState,ecx,IDM_MAKEACTIVERELEASEVERSION,MF_BYCOMMAND
			test eax,MF_CHECKED		; eax == -1 on error (older versions of WA)
			.if zero?
				mov eax,BUILD_MODE_DEBUG
			.else
				mov eax,BUILD_MODE_RELEASE
			.endif
			
		.endif
	.endif
	ret
	
GetBuildMode endp

end
