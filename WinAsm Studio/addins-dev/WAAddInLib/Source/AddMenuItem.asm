;------------------------------------------------------------------------------
; AddMenuItem
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Inserts an item in one of WinAsm's submenus.
;
; Parameters:
;	hSubMenu		Submenu handle
;	iItemPos		Item position within submenu, see remarks below
;	pItemLabel		Pointer to the new item's label (ASCIIZ)
;
; Return values:
;	New item's ID, or NULL if it wasn't inserted in the menu.
;
; Remarks:
;	You can obtain a handle to one of WinAsm's submenu with the GetWASubMenu
;	 procedure.
;
;	When iItemPos equals -1 the item is appended at the bottom of the submenu.
;------------------------------------------------------------------------------

include Common.inc

.code
align DWORD
AddMenuItem proc hSubMenu:DWORD, pItemLabel:PTR BYTE, iItemPos:DWORD
	local ItemID	:DWORD
	
	; Get the handle to WinAsm's main window
	mov eax,pHandles
	.if eax
		mov eax,[eax].HANDLES.hMain
		.if eax
			
			; Get a new menu item ID
			invoke SendMessage,eax,WAM_GETNEXTMENUID,0,0
			.if eax
				mov ItemID,eax
				
				; Calculate the correct menu item flags
				mov edx,pFeatures
				mov ecx,MF_BYPOSITION
				.if edx && (dword ptr [edx] >= 1016)
					or ecx,MF_OWNERDRAW
				.endif
				
				; Insert the menu item
				invoke InsertMenu,hSubMenu,iItemPos,ecx,ItemID,pItemLabel
				
				; On success return the new item ID
				.if eax
					mov eax,ItemID
				.endif
				
			.endif
			
		.endif
	.endif
	ret
	
AddMenuItem endp
end
