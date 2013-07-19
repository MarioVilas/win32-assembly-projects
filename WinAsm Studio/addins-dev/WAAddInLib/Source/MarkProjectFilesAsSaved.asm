;------------------------------------------------------------------------------
; MarkProjectFilesAsSaved
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Marks all MDI child windows associated with a file that belongs to the
;	 current project, as saved to disk (not modified). Does NOT change the
;	 modify flag of the .wap file.
;
; Parameters:
;	No parameters.
;
; Return values:
;	No return value.
;
; Remarks:
;	WinAsm Studio version 3.0.0.0 or higher is required.
;------------------------------------------------------------------------------

include Common.inc

MarkProjectFilesAsSavedCallback proto hMDIChildWindow:DWORD, lParam:LPARAM

.code
align DWORD
MarkProjectFilesAsSavedCallback proc hMDIChildWindow:DWORD, lParam:LPARAM
	
	; Marks all project files as saved.
	
	invoke GetWindowLong,hMDIChildWindow,0
	.if eax && ([eax].CHILDDATA.TypeOfFile <= 100)
		invoke SendMessage,[eax].CHILDDATA.hEditor,EM_SETMODIFY,FALSE,0
	.endif
	push TRUE
	pop eax
	ret
	
MarkProjectFilesAsSavedCallback endp

align DWORD
MarkProjectFilesAsSaved proc
	
	mov eax,pHandles
	.if eax
		mov eax,[eax].HANDLES.hMain
		.if eax
			invoke SendMessage,eax,WAM_ENUMCURRENTPROJECTFILES,offset MarkProjectFilesAsSavedCallback,0
		.endif
	.endif
	ret
	
MarkProjectFilesAsSaved endp

end
