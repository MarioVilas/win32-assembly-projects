;------------------------------------------------------------------------------
; NewProjectMenuItem
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Inserts a given item to WinAsm's main menu, under the Project submenu.
;	The new item will be enabled if a project is loaded, or grayed otherwise.
;
; Parameters:
;	pItemLabel		Pointer to the new item's label (ASCIIZ).
;
; Return values:
;	New item's ID, or NULL if it wasn't inserted in the menu.
;
; Remarks:
;	When iItemPos equals -1 the item is appended at the bottom of the submenu.
;------------------------------------------------------------------------------

include Common.inc

.code
align DWORD
NewProjectMenuItem proc uses ebx pItemLabel:PTR BYTE, iItemPos:DWORD
	local hSubMenu	:DWORD
	local ItemID	:DWORD
	local cpi		:CURRENTPROJECTINFO
	
	; Get the "Project" submenu handle
	invoke GetWASubMenu,3
	.if eax
		mov hSubMenu,eax
		
		; Get the handle to WinAsm's main window
		mov ebx,pHandles
		mov eax,[ebx].HANDLES.hMain
		.if eax
			
			; Get a new menu item ID
			invoke SendMessage,eax,WAM_GETNEXTMENUID,0,0
			.if eax
				mov ItemID,eax
				
				; Calculate the correct menu item flags
				invoke SendMessage,[ebx].HANDLES.hMain,WAM_GETCURRENTPROJECTINFO,addr cpi,0
				mov ecx,MF_BYPOSITION
				.if !eax
					or ecx,MF_GRAYED
				.endif
				mov edx,pFeatures
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
	
NewProjectMenuItem endp
end
