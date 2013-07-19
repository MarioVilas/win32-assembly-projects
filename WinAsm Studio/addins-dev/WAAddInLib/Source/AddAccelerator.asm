;------------------------------------------------------------------------------
; AddAccelerator
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Adds a given entry to WinAsm's accelerator table.
;
; Parameters:
;	pAccel		Pointer to an ACCELERATOR structure
;
; Return values:
;	Nonzero on success, zero on failure.
;
; Remarks:
;	WinAsm Studio version 3.0.2.5 or higher is required.
;
; See also:
;	RemoveAccelerator
;------------------------------------------------------------------------------

include Common.inc

.code
align DWORD
AddAccelerator proc uses esi edi pAccel:PTR ACCELERATOR
	local hAccel	:DWORD		; Handle to previous table
	local hNewAccel	:DWORD		; Handle to new table
	local iNum		:DWORD		; Number of entries in table
	local iSize		:DWORD		; Size in bytes of table
	local pData		:DWORD		; Pointer to data in table
	
	mov edx,pFeatures
	mov ecx,pHandles
	xor eax,eax
	.if edx && ecx && pAccel && ([edx].FEATURES.Version >= 3025)
		mov eax,[ecx].HANDLES.phAcceleratorTable
		.if eax
			mov eax,[eax]
			.if !eax
				; No accelerator table found:
				; Create a new one and return it's handle
				invoke CreateAcceleratorTable,pAccel,1
			.else
				; A previous accelerator table was found:
				; Get it's size
				mov hAccel,eax
				invoke CopyAcceleratorTable,eax,NULL,0
				.if eax
					mov iNum,eax
					inc eax
					mov ecx,sizeof ACCELERATOR
					mul ecx
					mov iSize,eax
					; Allocate a memory buffer
					invoke LocalAlloc,LPTR,eax
					.if eax
						mov hNewAccel,NULL
						push eax
						mov pData,eax
						invoke CopyAcceleratorTable,hAccel,eax,iNum
						.if eax == iNum
							; Add a new entry
							mov eax,pData
							mov edx,iSize
							mov esi,pAccel
							lea edi,[eax + edx - sizeof ACCELERATOR]
							movsd	;mov ecx,sizeof ACCELERATOR
							movsw	;rep movsb
							; Create a new accelerator table
							mov eax,iNum
							inc eax
							invoke CreateAcceleratorTable,pData,eax
							.if eax
								mov hNewAccel,eax
								; Update WinAsm's handles
								mov edx,pHandles
								mov edx,[edx].HANDLES.phAcceleratorTable
								mov [edx],eax
								; Destroy the old table
								invoke DestroyAcceleratorTable,hAccel
							.endif
						.endif
						; Free the memory buffer
						call LocalFree
						; Return the new handle, or NULL on error
						mov eax,hNewAccel
					.endif
				.endif
			.endif
		.endif
	.endif
	ret
	
AddAccelerator endp

;------------------------------------------------------------------------------
; RemoveAccelerator
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Deletes an entry from WinAsm's accelerator table.
;
; Parameters:
;	pAccel		Pointer to an ACCELERATOR structure
;
; Return values:
;	Nonzero on success, zero on failure.
;
; Remarks:
;	WinAsm Studio version 3.0.2.5 or higher is required.
;
; See also:
;	AddAccelerator
;------------------------------------------------------------------------------

align DWORD
RemoveAccelerator proc uses esi edi pAccel:PTR ACCELERATOR
	local hAccel	:DWORD		; Handle to previous table
	local hNewAccel	:DWORD		; Handle to new table
	local iNum		:DWORD		; Number of entries in table
	local iSize		:DWORD		; Size in bytes of table
	local pData		:DWORD		; Pointer to data in table
	local bRemoved	:DWORD		; TRUE on success, FALSE on failure
	
	; Validate parameters
	mov edx,pFeatures
	mov ecx,pHandles
	xor eax,eax
	.if edx && ecx && pAccel && ([edx].FEATURES.Version >= 3025)
		mov eax,[ecx].HANDLES.phAcceleratorTable
		.if eax
			mov eax,[eax]
			.if eax
				mov hAccel,eax
				; Get the current accelerators
				invoke CopyAcceleratorTable,eax,NULL,0
				.if eax
					mov iNum,eax
					mov ecx,sizeof ACCELERATOR
					mul ecx
					mov iSize,eax
					invoke LocalAlloc,LPTR,eax
					.if eax
						push eax
						mov pData,eax
						mov hNewAccel,NULL
						invoke CopyAcceleratorTable,hAccel,eax,iNum
						.if eax == iNum
							; Search the table looking for our accelerator
							mov edi,pData
							mov edx,pAccel
							mov ecx,iNum
							mov eax,[edx]		; The whole struct fits in 3 words
							mov dx,[edx + 4]
							test ecx,ecx
							.while !zero?
								cmp eax,[edi]
								.if zero?
									cmp dx,[edi + 4]
									je found
								.endif
								add edi,sizeof ACCELERATOR
								sub ecx,1
							.endw
						.endif
						; The entry was not found, clean up and quit
cleanup:				call LocalFree
						mov eax,hNewAccel
					.endif
				.endif
			.endif
		.endif
	.endif
	ret
	
found:
	; The entry was found, remove it
	lea esi,[edi + sizeof ACCELERATOR]
	mov ecx,iSize
	add ecx,pData
	sub ecx,edi
	rep movsb
	mov eax,iNum
	dec eax
	.if !zero?
		invoke CreateAcceleratorTable,pData,eax
		test eax,eax
		jz @F
	.endif
	; At this point, in EAX we either have the new handle or NULL
	mov hNewAccel,eax
	; Update WinAsm's handles
	mov edx,pHandles
	mov edx,[edx].HANDLES.phAcceleratorTable
	mov [edx],eax
	; Destroy the old handle and quit
	invoke DestroyAcceleratorTable,hAccel
@@:	jmp cleanup
	
RemoveAccelerator endp

end
