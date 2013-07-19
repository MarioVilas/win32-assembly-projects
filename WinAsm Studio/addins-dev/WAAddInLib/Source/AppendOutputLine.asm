;------------------------------------------------------------------------------
; AppendOutputLine
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Appends a given line (ASCIIZ string) to the text in WinAsm's output window.
;
; Parameters:
;	pszText		Pointer to an ASCIIZ string to append.
;	dwColor		Background color of text to insert (see remarks below).
;
; Return values:
;	No return value.
;
; Remarks:
;	The caret position in the output window will be preserved.
;
;	The text will always be appended in a new line. The string doesn't need to
;	 have any CR/LF pairs.
;
;	This are some possible values for dwColor and their meanings:
;	 	0:		Editor back color			(usually white)
;	 	1:		Error line back color		(usually red)
;	 	2:		No errors line back color	(usually green)
;
; See also:
;	ClearOutputWindow
;------------------------------------------------------------------------------

include Common.inc

.code
align DWORD
AppendOutputLine proc uses ebx pszText:PTR BYTE, dwColor:DWORD
	
	; Validate the parameters
	mov edx,pHandles
	xor eax,eax
	.if edx && pszText
		
		; Get the output window handle
		mov ebx,[edx].HANDLES.hOut
		.if ebx
			
			; Append the text line
			invoke SendMessage,ebx,EM_GETLINECOUNT,0,0
			invoke CHInsertLine,ebx,pszText,eax
			
			; Set the background color for the new line
			invoke SendMessage,ebx,CHM_SETHILITELINE,eax,dwColor
			
		.endif
		
	.endif
	ret
	
AppendOutputLine endp

end
