;------------------------------------------------------------------------------
; WasProjectModified
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Determines if the current project and all of it's files were modified
;	 wihtout saving to disk.
;
; Parameters:
;	No parameters.
;
; Return values:
;	Returns TRUE if the project or at least one of it's files was modified and
;	 needs to be saved to disk, or FALSE otherwise.
;
; Remarks:
;	WinAsm Studio version 3.0.0.0 or higher is required.
;------------------------------------------------------------------------------

include Common.inc

WasProjectModifiedCallback proto hMDIChildWindow:DWORD, lParam:LPARAM

.code
align DWORD
WasProjectModifiedCallback proc hMDIChildWindow:DWORD, lParam:LPARAM
	
	; Checks if there's at least one project file modified but not saved.
	
	invoke GetWindowLong,hMDIChildWindow,0
	.if eax && ([eax].CHILDDATA.TypeOfFile < 100)
		invoke SendMessage,[eax].CHILDDATA.hEditor,EM_GETMODIFY,0,0
		.if eax
			mov edx,lParam
			xor eax,eax
			.if edx
				mov dword ptr [edx],TRUE
			.endif
			jmp short @F
		.endif
	.endif
	push TRUE
	pop eax
@@:	ret
	
WasProjectModifiedCallback endp

align DWORD
WasProjectModified proc
	local hMain		:HWND
	local bModified	:DWORD
	local cpi		:CURRENTPROJECTINFO
	
	mov eax,pHandles
	.if eax
		mov edx,[eax].HANDLES.hMain
		.if edx
			mov hMain,edx
			invoke SendMessage,edx,WAM_GETCURRENTPROJECTINFO,addr cpi,0
			.if eax
				mov eax,cpi.pbModified
				.if eax
					mov eax,[eax]
					.if !eax
						mov bModified,FALSE
						invoke SendMessage,
						 			hMain,WAM_ENUMCURRENTPROJECTFILES,
						 			offset WasProjectModifiedCallback,addr bModified
						mov eax,bModified
					.endif
				.endif
			.endif
		.endif
	.endif
	ret
	
WasProjectModified endp

end
