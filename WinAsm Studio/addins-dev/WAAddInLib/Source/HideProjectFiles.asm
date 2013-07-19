;------------------------------------------------------------------------------
; HideProjectFiles
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Closes (hides) all MDI child windows associated with a file that belongs to
;	 the current project.
;
; Parameters:
;	No parameters.
;
; Return values:
;	No return value.
;
; Remarks:
;	WinAsm Studio version 3.0.0.0 or higher is required.
;
; See also:
;	HideExternalFiles
;------------------------------------------------------------------------------

include Common.inc

HideProjectFilesCallback proto hMDIChildWindow:DWORD, lParam:LPARAM

.code
align DWORD
HideProjectFilesCallback proc hMDIChildWindow:DWORD, lParam:LPARAM
	
	; Closes all MDI child windows that belong to the project.
	
	invoke GetWindowLong,hMDIChildWindow,0
	.if eax && ([eax].CHILDDATA.TypeOfFile <= 100)
		invoke SendMessage,hMDIChildWindow,WM_SYSCOMMAND,SC_CLOSE,0
	.endif
	push TRUE
	pop eax
	ret
	
HideProjectFilesCallback endp

align DWORD
HideProjectFiles proc
	
	mov eax,pHandles
	.if eax
		mov eax,[eax].HANDLES.hMain
		.if eax
			invoke SendMessage,eax,WAM_ENUMCURRENTPROJECTFILES,offset HideProjectFilesCallback,0
		.endif
	.endif
	ret
	
HideProjectFiles endp

end
