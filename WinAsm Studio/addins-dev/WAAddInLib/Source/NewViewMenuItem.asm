;------------------------------------------------------------------------------
; NewViewMenuItem
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Appends a given item to WinAsm's main menu, under the View submenu.
;
;	A separator will be added if there are only 5 items in the submenu (not
;	 counting the new one).
;
; Parameters:
;	pItemLabel		Pointer to the new item's label (ASCIIZ).
;	bChecked		TRUE if the new item should have a check mark, or FALSE
;	 				 otherwise.
;
; Return values:
;	New item's ID, or NULL if it wasn't inserted in the menu.
;
; See Also:
;	RemoveViewMenuItem
;------------------------------------------------------------------------------

include Common.inc

.code
align DWORD
NewViewMenuItem proc pItemLabel:PTR BYTE, bChecked:BOOL
	local hSubMenu	:DWORD
	local ItemID	:DWORD
	
	; Get the "View" submenu handle
	invoke GetWASubMenu,2
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
				.if eax == 5
					invoke AppendMenu,hSubMenu,MF_SEPARATOR,-1,NULL
				.endif
				
				; Calculate the correct menu item flags
				xor ecx,ecx
				.if bChecked
					or ecx,MF_CHECKED
				.endif
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
	
NewViewMenuItem endp

;------------------------------------------------------------------------------
; RemoveViewMenuItem
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Removes the given item to WinAsm's main menu, under the View submenu.
;
;	If after the removal only 5 items will remain in the submenu, the separator
;	 added by NewViewMenuItem will be removed.
;
; Parameters:
;	ItemID			Command ID for the item to remove.
;
; Return values:
;	Nonzero on success, zero on error.
;
; Remarks:
;	Typically you could use this procedure to remove the items and separator
;	 inserted by NewViewMenuItem.
;
; See Also:
;	NewViewMenuItem
;------------------------------------------------------------------------------

align DWORD
RemoveViewMenuItem proc ItemID:DWORD
	local hSubMenu:DWORD
	
	; Get the "View" submenu
	invoke GetWASubMenu,2
	.if eax
		mov hSubMenu,eax
		
		; If it only has 7 items, remove the separator
		invoke GetMenuItemCount,eax
		.if eax == 7
			invoke DeleteMenu,hSubMenu,5,MF_BYPOSITION
		.endif
		
		; Remove the item
		invoke DeleteMenu,hSubMenu,ItemID,MF_BYCOMMAND
	.endif
	ret
	
RemoveViewMenuItem endp

end
