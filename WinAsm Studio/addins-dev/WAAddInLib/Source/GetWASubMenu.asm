;------------------------------------------------------------------------------
; GetWASubMenu
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Returns the handle to one of WinAsm's submenus.
;
; Parameters:
;	iMenuPos		Submenu position, see remarks below.
;
; Return values:
;	The handle on success, NULL on failure.
;
; Remarks:
;	This are the possible values for iMenuPos, and their meanings:
;	 	 0: 	File
;	 	 1: 	Edit
;	 	 2: 	View
;	 	 3: 	Project
;	 	 4: 	Format
;	 	 5: 	Dialog
;	 	 6: 	Make
;	 	 7:		Set Active Build	(in "Make")
;	 	 8: 	Tools
;	 	 9: 	Add-Ins
;	 	10: 	Window
;	 	11: 	Help
;	 	12:		New File			(in "File")
;	 	13:		Convert				(in "Format")
;
;	Previous versions of this library had a different meaning for the iMenuPos
;	 parameter, make sure to update your code if needed.
;
;	Under versions 3.0.2.7 and above of WinAsm Studio, the POPUPMENUS structure
;	 is used instead of the APIs. The iMenuPos parameter is treated as an index
;	 into this structure, with NO bounds checking. If you're storing the menu
;	 index in the INI file, make sure to validate it before calling this
;	 function.
;
; See also:
;	AddMenuItem
;------------------------------------------------------------------------------

include Common.inc

.code
align DWORD
GetWASubMenu proc iMenuPos:DWORD
	local bIncrement:DWORD
	
	mov eax,pHandles
	.if eax
		
		; Get the submenu handle from the POPUPMENUS structure, if available
		mov eax,pFeatures
		.if eax && [eax].FEATURES.Version >= 3027
			
			; NO BOUNDS CHECKING!
			; This is so to allow more menu handles in future versions without a rebuild.
			; Make sure to validate the iMenuPos parameter if you got it from the user!
			mov edx,pHandles
			mov ecx,iMenuPos
			mov eax,dword ptr [edx].HANDLES.PopUpMenus[ecx * 4]
			
		.else	; Versions prior to 3.0.2.7
			
			; Find out if an MDI child is maximized
			mov eax,[eax].HANDLES.hClient
			.if eax
				mov bIncrement,0
				lea edx,bIncrement
				invoke SendMessage,eax,WM_MDIGETACTIVE,0,edx
				
				; ECX == Menu position / index into POPUPMENUS
				; EDX -> WinAsm version number, or 0
				mov edx,pFeatures
				mov ecx,iMenuPos
				.if edx
					mov edx,[edx].FEATURES.Version
				.endif
				
				.if ecx == 11					; Set Active Build (in "Make")
					
					mov ecx,6
					call gsm
					.if eax
						invoke GetSubMenu,eax,0
					.endif
					
				.elseif ecx == 12				; New File (in "File")
					
					xor ecx,ecx
					call gsm
					.if eax
						invoke GetSubMenu,eax,7
					.endif
					
				.elseif ecx == 13				; Convert (in "Format")
					
					mov ecx,4
					call gsm
					.if eax
						invoke GetSubMenu,eax,6
					.endif
					
				.else							; Top-level menues (0-6, 8-11)
					
					call gsm
					
				.endif
				
			.endif
			
		.endif
		
	.endif
	
	; Return
	ret
	
	
	; Small routine to get a submenu handle from it's position
	; ECX == Popup item position
	; EDX == WinAsm version, or 0
	; bIncrement must be initialized
	; Returns NULL or menu handle in EAX
gsm:
	; Calculate the correct submenu position
	.if ecx > 4
		.if ecx > 7
			dec ecx		;-1 skip "Set active build" submenu
		.endif
		.if edx < 3023
			dec ecx		;-1 no "Dialog" menu until version 3.0.2.3
		.endif
	.endif
	add ecx,bIncrement	;+1 if the active MDI child is maximized
	
	; Get the submenu handle from it's position
	mov edx,pHandles
	mov eax,[edx].HANDLES.hMenu
	.if eax
		invoke GetSubMenu,eax,ecx
	.endif
	
	; Return
	retn 0
	
GetWASubMenu endp
end
