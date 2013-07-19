;------------------------------------------------------------------------------
; HideExternalFiles
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Closes (hides) all MDI child windows associated with a file that does not
;	 belong to the current project.
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
;	HideProjectFiles
;------------------------------------------------------------------------------

include Common.inc

HideExternalFilesCallback proto hMDIChildWindow:DWORD, lParam:LPARAM

.code
align DWORD
HideExternalFilesCallback proc hMDIChildWindow:DWORD, lParam:LPARAM
	
	; Closes all MDI child windows that do not belong to the project.
	
	invoke GetWindowLong,hMDIChildWindow,0
	.if eax && ([eax].CHILDDATA.TypeOfFile > 100)
		invoke SendMessage,hMDIChildWindow,WM_SYSCOMMAND,SC_CLOSE,0
	.endif
	push TRUE
	pop eax
	ret
	
HideExternalFilesCallback endp

align DWORD
HideExternalFiles proc
	
	mov eax,pHandles
	.if eax
		mov eax,[eax].HANDLES.hMain
		.if eax
			invoke SendMessage,eax,WAM_ENUMEXTERNALFILES,offset HideExternalFilesCallback,0
		.endif
	.endif
	ret
	
HideExternalFiles endp

end
