; Safe subclasser
; Copyright ® 2004 by Mario Vilas (aka QvasiModo)
; Please refer to the readme file for licensing and usage instructions.

.386
.model flat,stdcall
option casemap:none
include WINDOWS.INC
include kernel32.inc
include user32.inc
includelib kernel32.lib
includelib user32.lib

include SafeSubclass.inc

SubclassedProc		proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

SUBCLASSED struct
	
	; Linked list data
	pNext			DWORD ?		; Pointer to next node in list
	pPrev			DWORD ?		; Pointer to previous node in list
	
	; Structure specific data
	pfWindowProc	DWORD ?		; Pointer to original window procedure
	hWnd			DWORD ?		; Handle of subclassed window
	pfChain			DWORD ?		; Pointer to linked list of window procedures
	
SUBCLASSED ends

WPCHAIN struct
	
	; Linked list data
	pNext			DWORD ?		; Pointer to next node in list
	pPrev			DWORD ?		; Pointer to previous node in list
	
	; Structure specific data
	pfWindowProc	DWORD ?		; Pointer to window procedure
	
WPCHAIN ends

.data
pList	dd ?

.code
align DWORD
SubclassedProc proc uses ebx hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	pushcontext assumes
	assume ebx:ptr SUBCLASSED
	
	; Search our node in the linked list
	mov ebx,pList
	mov eax,hWnd
	.while ebx
		cmp eax,[ebx].hWnd
		je found
		mov ebx,[ebx].pNext
	.endw
	jmp @F
	
	; Call the first subclassed procedure
found:
	mov eax,[ebx].pfChain
	test eax,eax
	jz @F
	mov edx,[eax].WPCHAIN.pfWindowProc
	test edx,edx
	jz @F
	invoke CallWindowProc,edx,hWnd,uMsg,wParam,lParam
	
	; Return to caller
quit:
	ret
	
	; Call the default window procedure
@@:	invoke DefWindowProc,hWnd,uMsg,wParam,lParam
	jmp quit
	
	popcontext assumes
SubclassedProc endp

align DWORD
Subclass proc uses ebx hWnd:HWND, pfWindowProc:WNDPROC
	pushcontext assumes
	assume ebx:ptr SUBCLASSED
	
	; Check the parameters
	or pfWindowProc,0
	jz badarg
	invoke IsWindow,hWnd
	test eax,eax
	jz badarg
	
	; Search for existing node with the same hWnd
	mov ebx,pList
	mov eax,hWnd
	.while ebx
		cmp eax,[ebx].hWnd
		je found
		mov ebx,[ebx].pNext
	.endw
	
	; ---------------------------------------------
	
	; Allocate new SUBCLASSED structure
	invoke LocalAlloc,LPTR,sizeof SUBCLASSED
	test eax,eax
	jz @F
	xchg ebx,eax
	
	; Populate structure
	invoke GetWindowLong,hWnd,GWL_WNDPROC
	test eax,eax
	jz dealloc
	mov [ebx].pfWindowProc,eax
	push hWnd
	pop [ebx].hWnd
	
	; Add and populate first subclassed proc
	invoke LocalAlloc,LPTR,sizeof WPCHAIN
	test eax,eax
	jz dealloc
	push pfWindowProc
	pop [eax].WPCHAIN.pfWindowProc
	mov [ebx].pfChain,eax
	
	; Add node to the list
	mov eax,pList
	.if eax
		mov [ebx].pNext,eax
		mov [eax].SUBCLASSED.pPrev,ebx
	.endif
	mov pList,ebx
	
	; Subclass the target window
	invoke SetWindowLong,hWnd,GWL_WNDPROC,offset SubclassedProc
	jmp short true
	
	; ---------------------------------------------
	
	; Ensure the subclassed proc is not already in the chain
found:
	mov edx,[ebx].pfChain
	mov eax,pfWindowProc
	.while edx
		cmp eax,[edx].WPCHAIN.pfWindowProc
		je alreadyexists
		mov edx,[edx].WPCHAIN.pNext
	.endw
	
	; Add new subclassed proc to the chain
	invoke LocalAlloc,LPTR,sizeof WPCHAIN
	test eax,eax
	jz @F
	push pfWindowProc
	pop [eax].WPCHAIN.pfWindowProc
	mov edx,[ebx].pfChain
	.if edx
		mov [eax].WPCHAIN.pNext,edx
		mov [edx].WPCHAIN.pPrev,eax
	.endif
	mov [ebx].pfChain,eax
	
	; ---------------------------------------------
	
true:
	push 1
	pop eax
@@:	ret
	
dealloc:
	invoke LocalFree,ebx
	xor eax,eax
	jmp short @B

alreadyexists:
	push ERROR_ALREADY_EXISTS
	jmp short seterr
badarg:
	push ERROR_INVALID_PARAMETER
seterr:
	call SetLastError
	xor eax,eax
	jmp short @B
	
	popcontext assumes
Subclass endp

align DWORD
Unsubclass proc uses ebx esi hWnd:HWND, pfWindowProc:WNDPROC
	pushcontext assumes
	assume ebx:ptr SUBCLASSED
	assume esi:ptr WPCHAIN
	
	; Check the parameters
	or pfWindowProc,0
	jz badarg
	invoke IsWindow,hWnd
	test eax,eax
	jz badarg
	
	; Search for our node in the linked list
	mov ebx,pList
	mov eax,hWnd
	.while ebx
		cmp eax,[ebx].hWnd
		je found
		mov ebx,[ebx].pNext
	.endw
@@:	push ERROR_FILE_NOT_FOUND
	jmp seterror
	
	; Search for our procedure in the chain
found:
	mov esi,[ebx].pfChain
	mov eax,pfWindowProc
	test esi,esi
	jz removewin
	.repeat
		cmp eax,[esi].pfWindowProc
		je removeproc
		mov esi,[esi].pNext
	.until !esi
	jmp @B
	
	; Remove our procedure from the chain
removeproc:
	mov eax,[esi].pPrev
	mov edx,[esi].pNext
	.if eax
		mov [eax].WPCHAIN.pNext,edx
	.endif
	.if edx
		mov [edx].WPCHAIN.pPrev,eax
	.endif
	.if [ebx].pfChain == esi
		mov [ebx].pfChain,edx
	.endif
	invoke LocalFree,esi
	cmp [ebx].pfChain,0
	je removewin
	
	; Return to caller
true:
	push 1
	pop eax
@@:	ret
	
	; Remove our window from the linked list, and unsubclass
removewin:
	mov eax,[ebx].pPrev
	mov edx,[ebx].pNext
	.if eax
		mov [eax].SUBCLASSED.pNext,edx
	.endif
	.if edx
		mov [edx].SUBCLASSED.pPrev,eax
	.endif
	.if pList == ebx
		mov pList,edx
	.endif
	invoke SetWindowLong,hWnd,GWL_WNDPROC,[ebx].pfWindowProc
	invoke LocalFree,ebx
	jmp true
	
	; Error
badarg:
	push ERROR_INVALID_PARAMETER
seterror:
	call SetLastError
	xor eax,eax
	jmp short @B
	
	popcontext assumes
Unsubclass endp

align DWORD
GetNextWndProc proc uses ebx esi hWnd:HWND, pfWindowProc:WNDPROC
	pushcontext assumes
	assume ebx:ptr SUBCLASSED
	assume esi:ptr WPCHAIN
	
	; Check the parameters
	cmp pfWindowProc,0
	jz badarg
	
	; Search our node in the linked list
	mov ebx,pList
	mov eax,hWnd
	.while ebx
		cmp eax,[ebx].SUBCLASSED.hWnd
		je found
		mov ebx,[ebx].SUBCLASSED.pNext
	.endw
	jmp notfound
	
	; Search the next window procedure in the chain
found:
	mov esi,[ebx].SUBCLASSED.pfChain
	mov eax,pfWindowProc
	.while esi
		cmp eax,[esi].pfWindowProc
		mov esi,[esi].pNext
		jz found2
	.endw
	jmp original

	; Return the address of the next window procedure
found2:
	test esi,esi
	jz original
	mov eax,[esi].pfWindowProc
	jmp @F
	
	; Return the address of the original procedure
original:
	mov eax,[ebx].pfWindowProc
@@:	ret
	
badarg:
	push ERROR_INVALID_PARAMETER
	jmp short seterr
notfound:
	push ERROR_FILE_NOT_FOUND
seterr:
	call SetLastError
	xor eax,eax
	jmp short @B
	
	popcontext assumes
GetNextWndProc endp

align DWORD
CallNextWndProc proc uses ebx esi pfWindowProc:WNDPROC, hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
	; IMPORTANT: Requires GetNextWndProc
	
	; Get the next window procedure
	invoke GetNextWndProc,hWnd,pfWindowProc
	test eax,eax
	jz short @F
	
	; Call the window procedure
	invoke CallWindowProc,eax,hWnd,uMsg,wParam,lParam
	
	; Return to caller
quit:
	ret
	
	; On error, call the default window procedure
@@:	invoke DefWindowProc,hWnd,uMsg,wParam,lParam
	jmp short quit
	
CallNextWndProc endp

;align DWORD
;SafeSubclassEntryPoint proc hinstDLL:HINSTANCE, dwReason:DWORD, lpvReserved:DWORD
;	
;	; Default DLL entry point
;	
;	.if dwReason == DLL_PROCESS_ATTACH
;		invoke DisableThreadLibraryCalls,hinstDLL
;	.endif
;	push TRUE
;	pop eax
;	ret
;	
;SafeSubclassEntryPoint endp
;end SafeSubclassEntryPoint

end
