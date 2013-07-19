;------------------------------------------------------------------------------
; CHAppendText
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Appends a given ASCIIZ string to the text in a CodeHi control.
;
; Parameters:
;	pszText		Pointer to an ASCIIZ string to append.
;
; Return values:
;	No return value.
;
; Remarks:
;	The caret position in the output window will be preserved.
;
; See also:
;	CHInsertLine
;------------------------------------------------------------------------------

include Common.inc

.code
align DWORD
CHAppendText proc hCtrl:HWND, pszText:PTR BYTE
	local cr_orig	:CHARRANGE
	local cr_new	:CHARRANGE
	
	mov edx,pHandles
	.if edx && hCtrl && pszText
		mov cr_orig.cpMin,-1
		mov cr_orig.cpMax,-1
		invoke SendMessage,hCtrl,EM_EXGETSEL,0,addr cr_orig
		invoke SendMessage,hCtrl,WM_GETTEXTLENGTH,0,0
		mov cr_new.cpMin,eax
		mov cr_new.cpMax,eax
		invoke SendMessage,hCtrl,EM_EXSETSEL,0,addr cr_new
		invoke SendMessage,hCtrl,EM_REPLACESEL,FALSE,pszText
		invoke SendMessage,hCtrl,EM_EXSETSEL,0,addr cr_orig
	.endif
	ret
	
CHAppendText endp

end
