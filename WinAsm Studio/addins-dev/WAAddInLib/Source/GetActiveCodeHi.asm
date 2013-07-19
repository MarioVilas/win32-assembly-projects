;------------------------------------------------------------------------------
; GetActiveCodeHi
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Retrieves the handle of the active CodeHi control, if any.
;
; Return values:
;	On success, the handle of the active CodeHi control.
;	On failure, NULL.
;
; Remarks:
;	Additionally, the MDI child window that hosts the CodeHi control is
;	 returned in EDX.
;
; See also:
;	CHAppendText, CHInsertLine
;------------------------------------------------------------------------------

include Common.inc

.code
align DWORD
GetActiveCodeHi proc
	
	mov eax,pHandles
	xor edx,edx
	.if eax
		invoke SendMessage,[eax].HANDLES.hClient,WM_MDIGETACTIVE,0,0
		.if eax
			push eax
			invoke GetWindowLong,eax,0
			pop edx
			.if eax
				mov eax,[eax].CHILDDATA.hEditor
			.endif
		.endif
	.endif
	ret
	
GetActiveCodeHi endp

end
