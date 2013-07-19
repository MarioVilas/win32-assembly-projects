;------------------------------------------------------------------------------
; LoadAddIn
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Loads an add-in, given it's filename.
;
; Parameters:
;	pszFilename			Pointer to an ASCIIZ string with the add-in's filename
;	 				 	(path information is optional).
;
; Return values:
;	The newly loaded add-in's instance handle on success, NULL on failure.
;
; Remarks:
;	WinAsm Studio version 3.0.2.4 or higher is required.
;
;	The file is assumed to be in the AddIns folder if no path information is
;	 given. The standard DLL file search strategy will NOT be used.
;
;	If the add-in was already loaded, the function just returns the module
;	 handle for that add-in, without incrementing the DLL load count.
;
; See also:
;	UnloadAddIn
;------------------------------------------------------------------------------

include Common.inc

.data
sz GetWAAddInData
sz WAAddInLoad
sz WAAddInUnload
sz FrameWindowProc
sz ChildWindowProc
sz ProjectExplorerProc
sz OutWindowProc

.code
align DWORD
LoadAddIn proc uses ebx edi pszFilename:PTR BYTE
	local hLib					:DWORD
	local pFilePart				:DWORD
	local pFrameProc			:DWORD
	local pChildProc			:DWORD
	local pExplProc				:DWORD
	local pOutProc				:DWORD
	local pFrameSlot			:DWORD
	local pChildSlot			:DWORD
	local pExplSlot				:DWORD
	local pOutSlot				:DWORD
	local szPathname[MAX_PATH]	:BYTE
	
	; Validate the parameters
	mov ebx,pFeatures
	.if ebx && pszFilename && (szIniFile[0] != 0) && ([ebx].FEATURES.Version >= 3024)
		
		; Get the AddIns folder
		invoke PathFindFileName,offset szIniFile
		sub eax,offset szIniFile
		invoke lstrcpyn,addr szPathname,offset szIniFile,eax
		
		; Get the addin full pathname
		invoke PathIsFileSpec,pszFilename
		.if eax
			invoke PathAppend,addr szPathname,pszFilename
		.else
			invoke GetFullPathName,pszFilename,sizeof szPathname,addr szPathname,addr pFilePart
		.endif
		test eax,eax
		jz badarg
		
		; The add-in shouldn't be already loaded,
		; but if it was just return the module handle
		invoke GetModuleHandle,addr szPathname
		.if !eax
			
			; Load the add-in's DLL library
			invoke LoadLibrary,addr szPathname
			.if eax
				mov hLib,eax
				
				; Make sure it's really an add-in
				invoke GetProcAddress,eax,offset szGetWAAddInData
				.if !eax
badlib:				invoke FreeLibrary,hLib
					jmp badarg
				.endif
				
				; Call WAAddInLoad, if it exists
				; Note: no messages will be received in FrameWindowProc, etc. during this call
				invoke GetProcAddress,hLib,offset szWAAddInLoad
				.if eax
					push pFeatures
					push pHandles
					call eax
					inc eax		; Abort on error
					jz badlib
				.endif
				
				; Get each procedure pointer
				invoke GetProcAddress,hLib,offset szFrameWindowProc
				mov pFrameProc,eax
				invoke GetProcAddress,hLib,offset szChildWindowProc
				mov pChildProc,eax
				invoke GetProcAddress,hLib,offset szProjectExplorerProc
				mov pExplProc,eax
				invoke GetProcAddress,hLib,offset szOutWindowProc
				mov pOutProc,eax
				
				; ----------- NO API CALLS MUST BE DONE DOWN HERE -----------
				
				; Note: use a critical section here if WinAsm goes multithreaded in the future
				
				; Browse the procedure pointers list looking for the next empty slot
				.if pFrameProc
					mov edx,[ebx].FEATURES.ppAddInsFrameProcedures
					call browse
					mov pFrameSlot,eax
				.endif
				.if pChildProc
					mov edx,[ebx].FEATURES.ppAddInsChildWindowProcedures
					call browse
					mov pChildSlot,eax
				.endif
				.if pExplProc
					mov edx,[ebx].FEATURES.ppAddInsProjectExplorerProcedures
					call browse
					mov pExplSlot,eax
				.endif
				.if pOutProc
					mov edx,[ebx].FEATURES.ppAddInsOutWindowProcedures
					call browse
					mov pOutSlot,eax
				.endif
				
				; Append the new procedure pointers in each list
				mov eax,pFrameProc
				.if eax
					mov edx,pFrameSlot
					mov [edx],eax
				.endif
				mov eax,pChildProc
				.if eax
					mov edx,pChildSlot
					mov [edx],eax
				.endif
				mov eax,pExplProc
				.if eax
					mov edx,pExplSlot
					mov [edx],eax
				.endif
				mov eax,pOutProc
				.if eax
					mov edx,pOutSlot
					mov [edx],eax
				.endif
				
				; ----------- NO API CALLS MUST BE DONE UP HERE -----------
				
				; Return the module handle
				mov eax,hLib
			.endif
		.endif
	.else
badarg:	invoke SetLastError,ERROR_BAD_ARGUMENTS
		xor eax,eax
	.endif
@@:	ret
	
	; Routine to browse the procedure pointers list looking for the next empty slot
	; EDX == pointer to pointer to list
	; trashes: EAX, ECX, EDI
browse:
	test edx,edx
	jz badlist
	mov edi,[edx]
	test edi,edi
	jz badlist
	mov ecx,256
	xor eax,eax
	repne scasd
	jne badlist
	.if ecx				; Unless we reached the end of the list,
		mov [edi],eax	; append a NULL after the empty slot just found
	.endif
	lea eax,[edi - 4]
	retn 0
	
	; We reach here if there was an error while browsing the lists
badlist:
	invoke GetProcAddress,hLib,offset szWAAddInUnload
	.if eax
		call eax
	.endif
	invoke FreeLibrary,hLib
	mov dword ptr [esp],ERROR_INTERNAL_ERROR
	call SetLastError
	xor eax,eax
	jmp @B
	
LoadAddIn endp

;------------------------------------------------------------------------------
; UnloadAddIn
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Unloads an add-in, given it's instance handle.
;
; Parameters:
;	hInstAddIn		Instance handle of the add-in to unload.
;
; Return values:
;	Nonzero on success, zero on failure.
;
; Remarks:
;	WinAsm Studio version 3.0.2.4 or higher is required.
;
;	The function fails if the handle matches the caller add-in, or if it does
;	 not match any other currently loaded add-in. If you haven't provided the
;	 DLL handle to InitializeAddIn, attempting to unload your own add-in will
;	 not cause this function to fail, but may crash WinAsm!
;
;	A single call to UnloadAddIn will unload an add-in, no matter how many
;	 calls to LoadAddIn have been made on it.
;
; See also:
;	LoadAddIn
;------------------------------------------------------------------------------

align DWORD
UnloadAddIn proc uses ebx esi edi hLib:HINSTANCE
	local pFrameProc			:DWORD
	local pChildProc			:DWORD
	local pExplProc				:DWORD
	local pOutProc				:DWORD
	local pFrameSlot			:DWORD
	local pChildSlot			:DWORD
	local pExplSlot				:DWORD
	local pOutSlot				:DWORD
	local iFrameSlots			:DWORD
	local iChildSlots			:DWORD
	local iExplSlots			:DWORD
	local iOutSlots				:DWORD
	
	; Validate the parameters
	mov ebx,pFeatures
	mov ecx,hInstDll
	mov edx,hLib
	.if ebx && ecx && edx && (ecx != edx) && ([ebx].FEATURES.Version >= 3024)
		
		; Make sure it's really an add-in
		invoke GetProcAddress,hLib,offset szGetWAAddInData
		test eax,eax
		jz badarg
		
		; Get each procedure pointer
		invoke GetProcAddress,hLib,offset szFrameWindowProc
		mov pFrameProc,eax
		invoke GetProcAddress,hLib,offset szChildWindowProc
		mov pChildProc,eax
		invoke GetProcAddress,hLib,offset szProjectExplorerProc
		mov pExplProc,eax
		invoke GetProcAddress,hLib,offset szOutWindowProc
		mov pOutProc,eax
		
		; ----------- NO API CALLS MUST BE DONE DOWN HERE -----------
		
		; Note: use a critical section here if WinAsm goes multithreaded in the future
		
		; Find each procedure pointer in the lists
		mov eax,pFrameProc
		.if eax
			mov edx,[ebx].FEATURES.ppAddInsFrameProcedures
			call find
			mov pFrameSlot,eax
			mov iFrameSlots,ecx
		.endif
		mov eax,pChildProc
		.if eax
			mov edx,[ebx].FEATURES.ppAddInsChildWindowProcedures
			call find
			mov pChildSlot,eax
			mov iChildSlots,ecx
		.endif
		mov eax,pExplProc
		.if eax
			mov edx,[ebx].FEATURES.ppAddInsProjectExplorerProcedures
			call find
			mov pExplSlot,eax
			mov iExplSlots,ecx
		.endif
		mov eax,pOutProc
		.if eax
			mov edx,[ebx].FEATURES.ppAddInsOutWindowProcedures
			call find
			mov pOutSlot,eax
			mov iOutSlots,ecx
		.endif
		
		; Remove each pointer from the lists
		.if pFrameProc
			mov edi,pFrameSlot
			mov ecx,iFrameSlots
			lea esi,[edi + 4]
			rep movsd
			xor eax,eax
			stosd
		.endif
		.if pChildProc
			mov edi,pChildSlot
			mov ecx,iChildSlots
			lea esi,[edi + 4]
			rep movsd
			xor eax,eax
			stosd
		.endif
		.if pExplProc
			mov edi,pExplSlot
			mov ecx,iExplSlots
			lea esi,[edi + 4]
			rep movsd
			xor eax,eax
			stosd
		.endif
		.if pOutProc
			mov edi,pOutSlot
			mov ecx,iOutSlots
			lea esi,[edi + 4]
			rep movsd
			xor eax,eax
			stosd
		.endif
		
		; ----------- NO API CALLS MUST BE DONE UP HERE -----------
		
		; Call WAAddInUnload, if it exists
		; Note: no messages will be received in FrameWindowProc, etc. during this call
		invoke GetProcAddress,hLib,offset szWAAddInUnload
		.if eax
			call eax
		.endif
		
		; Free the add-in's DLL
		invoke FreeLibrary,hLib
		
	.else
		
badarg:	invoke SetLastError,ERROR_BAD_ARGUMENTS
		xor eax,eax
		
	.endif
@@:	ret
	
	; Routine to search for a procedure pointer in a list
	; EAX == pointer to procedure
	; EDX == pointer to pointer to list
find:
	test edx,edx
	jz badlist
	mov edi,[edx]
	test edi,edi
	jz badlist
	mov ecx,256
	repne scasd
	jne badlist
	lea eax,[edi - 4]
	retn 0
	
	; We reach here if there was an error while browsing the lists
badlist:
	mov dword ptr [esp],ERROR_INTERNAL_ERROR
	call SetLastError
	xor eax,eax
	jmp @B
	
UnloadAddIn endp

end
