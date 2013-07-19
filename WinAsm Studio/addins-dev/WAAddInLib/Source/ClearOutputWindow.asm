;------------------------------------------------------------------------------
; ClearOutputWindow
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Clears the text in WinAsm's output window.
;
; Parameters:
;	No parameters.
;
; Return values:
;	No return value.
;
; See also:
;	AppendOutputLine
;------------------------------------------------------------------------------

include Common.inc

.code
align DWORD
ClearOutputWindow proc
	
	mov eax,pHandles
	.if eax
		mov eax,[eax].HANDLES.hOut
		.if eax
			
			; The shorter way...
			push 0						; lParam
			push 0						; wParam
			push EM_SCROLLCARET			; uMsg
			push eax					; hWnd
			mov edx,offset $ + 7
			push edx						; lParam
			push 0							; wParam
			push WM_SETTEXT					; uMsg
			push eax						; hWnd
			call SendMessage				; SendMessage		WM_SETTEXT
			call SendMessage			; SendMessage			EM_SCROLLCARET
			
			; An alternative way...
;			xor edx,edx
;			push edx				; lParam
;			push edx				; wParam
;			push CHM_SETHILITELINE	; uMsg
;			push eax				; hWnd
;			push edx					; lParam
;			push edx					; wParam
;			push WM_CLEAR				; uMsg
;			push eax					; hWnd
;			push -1							; lParam
;			push edx						; wParam
;			push EM_SETSEL					; uMsg
;			push eax						; hWnd
;			call SendMessage				; SendMessage		EM_SETSEL
;			call SendMessage			; SendMessage			WM_CLEAR
;			call SendMessage		; SendMessage				CHM_SETHILITELINE
			
		.endif
	.endif
	ret
	
ClearOutputWindow endp

end
