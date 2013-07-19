;------------------------------------------------------------------------------
; AddMenuItemEx
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Adds a given item to WinAsm's main menu.
;
; Parameters:
;	pItemLabel		Pointer to the new item's label (ASCIIZ)
;	iMenuPos		Submenu position, see remarks below
;	iItemPos		Item position within submenu, see remarks below
;	iSeparatorPos	Optional separator position, see remarks below
;
; Return values:
;	New item's ID in EAX, or NULL if it wasn't inserted in the menu.
;	The separator's ID in EDX, or NULL if it wasn't inserted in the menu.
;
; Remarks:
;	When ItemPos equals -1 the item is appended at the bottom of the popup
;	 menu. When SeparatorPos is -1 it will be inserted at the bottom of the
;	 popup menu. When SeparatorPos and if it's -2 the separator won't be
;	 inserted at all.
;
;	To know what are the possible values for iMenuPos, and their meanings,
;	 please see the reference for the GetWASubMenu function.
;
;	Since the separator is inserted before the item, when both the item and
;	 separator have the same position the item is placed above the separator.
;
;	Note that the way this procedure inserts menu items may not be adequate for
;	 all kinds of addins. For example, you might want to insert the separator
;	 only if certain conditions are given.
;
;	Both the new item and separator can be removed with DeleteMenu by ID.
;
; See Also:
;	GetWASubMenu, RemoveMenuItem
;------------------------------------------------------------------------------

include Common.inc

.code
align DWORD
AddMenuItemEx proc pItemLabel:PTR BYTE, iMenuPos:DWORD, iItemPos:DWORD, iSeparatorPos:DWORD
	local hSubMenu		:DWORD
	local bIncrement	:DWORD
	local SeparatorID	:DWORD
	local cpi			:CURRENTPROJECTINFO
	
	mov SeparatorID,NULL
	
	; Get the submenu handle
	invoke GetWASubMenu,iMenuPos
	.if eax
		mov hSubMenu,eax
		
		; Insert the separator
		mov eax,iSeparatorPos
		.if eax != -2
			mov edx,pHandles
			mov edx,[edx].HANDLES.hMain
			.if edx
				invoke SendMessage,edx,WAM_GETNEXTMENUID,0,0
				mov SeparatorID,eax
				invoke InsertMenu,hSubMenu,iSeparatorPos,MF_SEPARATOR or MF_BYPOSITION,eax,NULL
			.endif
		.endif
		
		; Insert the menu item
		invoke AddMenuItem,hSubMenu,pItemLabel,iItemPos
		
		; Return both IDs in EDX:EAX
		mov edx,SeparatorID
	.endif
	ret
	
AddMenuItemEx endp
end
