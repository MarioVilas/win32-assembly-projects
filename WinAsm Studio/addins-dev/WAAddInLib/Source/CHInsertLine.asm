;------------------------------------------------------------------------------
; CHInsertLine
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Inserts a given line of text (ASCIIZ string) in a CodeHi control.
;
; Parameters:
;	hCtrl		Window handle of a CodeHi control.
;	pszText		Pointer to an ASCIIZ string to insert.
;	iLine		Line index where the string will be inserted.
;
; Return values:
;	Returns the line index where the string was inserted.
;
; Remarks:
;	The caret position in the output window will be preserved.
;
;	The text will always be appended in a new line. The string doesn't need to
;	 have any CR/LF pairs.
;
; See also:
;	CHAppendText
;------------------------------------------------------------------------------

include Common.inc

.code
align DWORD
CHInsertLine proc hCtrl:HWND, pszText:PTR BYTE, iLine:DWORD
	local cr_orig	:CHARRANGE
	local cr_new	:CHARRANGE
	
	; Validate the parameters
	.if hCtrl && pszText
		
		; Make sure the requested line index is within the limits
		invoke SendMessage,hCtrl,EM_GETLINECOUNT,0,0
		.if iLine > eax
			mov iLine,eax
		.endif
		
		; Preserve the caret position
		mov cr_orig.cpMin,0
		mov cr_orig.cpMax,0
		invoke SendMessage,hCtrl,EM_EXGETSEL,0,addr cr_orig
		
		; Move the caret to the beginning of the requested line
		invoke SendMessage,hCtrl,EM_LINEINDEX,iLine,0
		mov cr_new.cpMin,eax
		mov cr_new.cpMax,eax
		invoke SendMessage,hCtrl,EM_EXSETSEL,0,addr cr_new
		
		; Append the new line's text
		invoke SendMessage,hCtrl,EM_REPLACESEL,FALSE,pszText
		
		; Append a CR/LF pair after the text if needed
		invoke SendMessage,hCtrl,EM_LINEINDEX,eax,0
		dec eax
		.if eax != iLine
			mov eax,0A0Dh	; Carrier Return (0Dh), Line Feed (0Ah), Null (00h), Null (00h)
			push eax
			invoke SendMessage,hCtrl,EM_REPLACESEL,FALSE,esp
			pop eax
		.endif
		
		; Restore the caret position
		invoke SendMessage,hCtrl,EM_EXSETSEL,0,addr cr_orig
		
	.endif
	
	; Return the line index
	mov eax,iLine
	ret
	
CHInsertLine endp

end
