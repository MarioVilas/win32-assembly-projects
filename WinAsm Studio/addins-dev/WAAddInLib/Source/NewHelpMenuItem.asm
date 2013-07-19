;------------------------------------------------------------------------------
; NewHelpMenuItem
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Appends a given item to WinAsm's main menu, under the Help submenu.
;
;	A separator will be added if there are only 4 items in the submenu (not
;	 counting the new one).
;
; Parameters:
;	pItemLabel		Pointer to the new item's label (ASCIIZ).
;
; Return values:
;	New item's ID, or NULL if it wasn't inserted in the menu.
;
; See Also:
;	RemoveHelpMenuItem
;------------------------------------------------------------------------------

include Common.inc

.code
align DWORD
NewHelpMenuItem proc pItemLabel:PTR BYTE
	local hSubMenu	:DWORD
	local ItemID	:DWORD
	
	; Get the "Help" submenu handle
	invoke GetWASubMenu,11
	.if eax
		mov hSubMenu,eax
		
		; Get the handle to WinAsm's main window
		mov eax,pHandles
		mov eax,[eax].HANDLES.hMain
		.if eax
			
			; Get a new menu item ID
			invoke SendMessage,eax,WAM_GETNEXTMENUID,0,0
			.if eax
				mov ItemID,eax
				
				; Insert a separator if needed
				invoke GetMenuItemCount,hSubMenu
				.if eax == 4
					invoke AppendMenu,hSubMenu,MF_SEPARATOR,-1,NULL
				.endif
				
				; Calculate the correct menu item flags
				xor ecx,ecx
				mov edx,pFeatures
				.if edx && (dword ptr [edx] >= 1016)
					or ecx,MF_OWNERDRAW
				.endif
				
				; Append the menu item
				invoke AppendMenu,hSubMenu,ecx,ItemID,pItemLabel
				
				; On success return the new item ID
				.if eax
					mov eax,ItemID
				.endif
				
			.endif
			
		.endif
		
	.endif
	ret
	
NewHelpMenuItem endp

;------------------------------------------------------------------------------
; RemoveHelpMenuItem
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Removes the given item to WinAsm's main menu, under the Help submenu.
;
;	If after the removal only 4 items will remain in the submenu, the separator
;	 added by NewHelpMenuItem will be removed.
;
; Parameters:
;	ItemID			Command ID for the item to remove.
;
; Return values:
;	Nonzero on success, zero on error.
;
; Remarks:
;	Typically you could use this procedure to remove the items and separator
;	 inserted by NewHelpMenuItem.
;
; See Also:
;	NewHelpMenuItem
;------------------------------------------------------------------------------

align DWORD
RemoveHelpMenuItem proc ItemID:DWORD
	local hSubMenu:DWORD
	
	; Get the "Help" submenu
	invoke GetWASubMenu,11
	.if eax
		mov hSubMenu,eax
		
		; If it only has 5 items, remove the separator
		invoke GetMenuItemCount,eax
		.if eax == 5
			invoke DeleteMenu,hSubMenu,4,MF_BYPOSITION
		.endif
		
		; Remove the item
		invoke DeleteMenu,hSubMenu,ItemID,MF_BYCOMMAND
	.endif
	ret
	
RemoveHelpMenuItem endp

end
