;------------------------------------------------------------------------------
; NewAddinMenuItem
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Adds a given item to WinAsm's main menu, under the Add-Ins submenu. A
;	 separator will be added if only the Add-In Manager has an item there.
;
; Parameters:
;	pItemLabel		Pointer to the new item's label (ASCIIZ).
;
; Return values:
;	New item's ID, or NULL if it wasn't inserted in the menu.
;
; See Also:
;	RemoveAddinMenuItem
;------------------------------------------------------------------------------

include Common.inc

.code
align DWORD
NewAddinMenuItem proc pItemLabel:PTR BYTE
	local hSubMenu:DWORD
	
	; Get the "Add-Ins" submenu
	invoke GetWASubMenu,9
	.if eax
		mov hSubMenu,eax
		
		; If only the Add-Ins Manager has an item there, append a separator
		invoke GetMenuItemCount,eax
		.if eax == 1
			invoke AppendMenu,hSubMenu,MF_SEPARATOR,-1,NULL
		.endif
		
		; Append the menu item
		invoke AddMenuItem,hSubMenu,pItemLabel,-1
	.endif
	ret
	
NewAddinMenuItem endp

;------------------------------------------------------------------------------
; Description:
;	Removes the given item to WinAsm's main menu, under the Add-Ins submenu.
;	 If after the removal only the Add-In Manager has an item in the submenu,
;	 the separator added by NewAddinMenuItem will be removed.
;
; Parameters:
;	ItemID			Command ID for the item to remove.
;
; Return values:
;	Nonzero on success, zero on error.
;
; Remarks:
;	Typically you could use this procedure to remove the items and separator
;	 inserted by NewAddinMenuItem.
;
; See Also:
;	NewAddinMenuItem
;------------------------------------------------------------------------------

align DWORD
RemoveAddinMenuItem proc ItemID:DWORD
	local hSubMenu:DWORD
	
	; Get the "Add-Ins" submenu
	invoke GetWASubMenu,9
	.if eax
		mov hSubMenu,eax
		
		; If only the Add-Ins Manager will remain there, remove the separator
		invoke GetMenuItemCount,eax
		.if eax == 3
			invoke DeleteMenu,hSubMenu,1,MF_BYPOSITION
		.endif
		
		; Remove the item
		invoke DeleteMenu,hSubMenu,ItemID,MF_BYCOMMAND
	.endif
	ret
	
RemoveAddinMenuItem endp

end
