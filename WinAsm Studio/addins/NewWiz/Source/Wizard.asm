; New Project Wizard Add-In for WinAsm Studio
; Copyright (C) 2004 Mario Vilas (aka QvasiModo)
; All rights reserved.
; Freeware for any use. See readme.txt for licensing details.

include Wizard.inc

.code
align DWORD
EnableChildCallback proc hWnd:HWND, lParam:LPARAM
	
	invoke EnableWindow,hWnd,lParam
	push TRUE
	pop eax
	ret
	
EnableChildCallback endp

align DWORD
GetTreePath proc hWnd:HWND, dwID:DWORD, hItem:DWORD
	local tvi				:TVITEM
	local buffer[MAX_PATH]	:BYTE
	
	mov szChangeFolder,0
	invoke SendDlgItemMessage,hWnd,dwID,TVM_GETNEXTITEM,TVGN_PARENT,hItem
	.if eax
		invoke GetTreePath,hWnd,dwID,eax
	.endif
	lea eax,buffer
	mov tvi._mask,TVIF_TEXT or TVIF_HANDLE
	push hItem
	pop tvi.hItem
	mov tvi.cchTextMax,sizeof buffer
	mov tvi.pszText,eax
	invoke SendDlgItemMessage,hWnd,dwID,TVM_GETITEM,0,addr tvi
	.if eax
		invoke lstrcat,offset szChangeFolder,addr buffer
		invoke PathAddBackslash,offset szChangeFolder
	.endif
	ret
	
GetTreePath endp

align DWORD
ExpandTreeFolder proc hWnd:HWND, dwID:DWORD, hItem:DWORD
	local hFind1				:DWORD
	local hFind2				:DWORD
	local tvc					:TVINSERTSTRUCT
	local w32fd1				:WIN32_FIND_DATA
	local w32fd2				:WIN32_FIND_DATA
	local szCurrentDir[MAX_PATH]:BYTE
	
	lea eax,w32fd1.cFileName
	push hItem
	pop tvc.hParent
	mov tvc.hInsertAfter,TVI_SORT
	mov tvc.item.pszText,eax
	invoke GetTreePath,hWnd,dwID,tvc.hParent
	invoke GetCurrentDirectory,sizeof szCurrentDir,addr szCurrentDir
	invoke SetCurrentDirectory,offset szChangeFolder
	.if eax
		mov edx,pFindFirstFileEx
		lea eax,w32fd1
		.if edx == NULL
			invoke FindFirstFile,offset szMaskAll,eax
		.else
			push 0								;dwAdditionalFlags
			push NULL							;lpSearchFilter
			push FindExSearchLimitToDirectories	;fSearchOp
			push eax							;lpFindFileData
			push FindExInfoStandard				;fInfoLevelId
			push offset szMaskAll				;lpFileName
			call edx							;*FindFirstFileEx()
		.endif
		.if eax != INVALID_HANDLE_VALUE
			mov hFind1,eax
			.repeat
				test w32fd1.dwFileAttributes,FILE_ATTRIBUTE_DIRECTORY
				.if (! zero?) && (w32fd1.cFileName != '.')
					mov tvc.item._mask,TVIF_CHILDREN or TVIF_TEXT
					mov tvc.item.cChildren,FALSE
					invoke SHGetFileInfo,addr w32fd1.cFileName,w32fd1.dwFileAttributes,
						offset shfi,sizeof shfi,
						SHGFI_SELECTED or SHGFI_SMALLICON or SHGFI_SYSICONINDEX ;or SHGFI_ADDOVERLAYS
					.if eax
						push shfi.iIcon
						or tvc.item._mask,TVIF_SELECTEDIMAGE
						pop tvc.item.iSelectedImage
					.endif
					invoke SHGetFileInfo,addr w32fd1.cFileName,w32fd1.dwFileAttributes,
						offset shfi,sizeof shfi,
						SHGFI_SMALLICON or SHGFI_SYSICONINDEX ;or SHGFI_ADDOVERLAYS
					.if eax
						push shfi.iIcon
						or tvc.item._mask,TVIF_IMAGE
						pop tvc.item.iImage
					.endif
					invoke SetCurrentDirectory,addr w32fd1.cFileName
					.if eax
						invoke FindFirstFile,offset szMaskAll,addr w32fd2
						.if eax
							mov hFind2,eax
							.repeat
								test w32fd2.dwFileAttributes,FILE_ATTRIBUTE_DIRECTORY
								.if (! zero?) && (w32fd2.cFileName != '.')
									mov tvc.item.cChildren,TRUE
									.break
								.endif
								invoke FindNextFile,hFind2,addr w32fd2
							.until eax == 0
							invoke FindClose,hFind2
						.endif
						invoke SetCurrentDirectory,offset szDotDot
					.endif
					invoke SendDlgItemMessage,hWnd,dwID,TVM_INSERTITEM,0,addr tvc
				.endif
				invoke FindNextFile,hFind1,addr w32fd1
			.until eax == 0
			invoke FindClose,hFind1
		.endif
		invoke SetCurrentDirectory,addr szCurrentDir
	.endif
	ret
	
ExpandTreeFolder endp

align DWORD
ExpandTreePath proc uses ebx esi edi hWnd:HWND, dwID:DWORD
	local nmtv				:NMTREEVIEW
	local buffer[MAX_PATH]	:BYTE
	local original[MAX_PATH]:BYTE
	
	invoke GetDlgItem,hWnd,dwID
	;push dwID
	mov nmtv.hdr.hwndFrom,eax
	;pop nmtv.hdr.idFrom
	mov ebx,TVI_ROOT
	lea edi,original
	invoke lstrcpyn,edi,offset szChangeFolder,sizeof original
	invoke PathRemoveBackslash,eax
	lea eax,buffer
	mov ecx,sizeof original
	;mov nmtv.action,TVE_EXPAND
	mov nmtv.itemNew._mask,TVIF_HANDLE or TVIF_TEXT ;or TVIF_STATE or TVIF_PARAM
	mov nmtv.itemNew.hItem,TVI_ROOT
	;mov nmtv.itemNew.state,0
	;mov nmtv.itemNew.stateMask,-1
	;mov nmtv.itemNew.lParam,0
	mov nmtv.itemNew.cchTextMax,sizeof buffer
	mov nmtv.itemNew.pszText,eax
	.while byte ptr [edi] != 0
		mov esi,edi
		mov al,'\'
		repne scasb
		.if zero?
			mov byte ptr [edi-1],0
		.endif
		push ecx
		invoke SendMessage,nmtv.hdr.hwndFrom,TVM_GETNEXTITEM,TVGN_CHILD,ebx
		.if eax == 0
			;mov nmtv.hdr.code,TVN_ITEMEXPANDING
			;invoke SendMessage,hWnd,WM_NOTIFY,dwID,addr nmtv
			invoke SendMessage,nmtv.hdr.hwndFrom,TVM_EXPAND,TVE_EXPAND,ebx
			;mov nmtv.hdr.code,TVN_ITEMEXPANDED
			;invoke SendMessage,hWnd,WM_NOTIFY,dwID,addr nmtv
			invoke SendMessage,nmtv.hdr.hwndFrom,TVM_GETNEXTITEM,TVGN_CHILD,ebx
			test eax,eax
			jz @F
		.endif
		.repeat
			mov nmtv.itemNew.hItem,eax
			invoke SendMessage,nmtv.hdr.hwndFrom,TVM_GETITEM,0,addr nmtv.itemNew
			test eax,eax
			jz @F
			invoke lstrcmpi,addr buffer,esi
			.break .if eax == 0
			invoke SendMessage,nmtv.hdr.hwndFrom,TVM_GETNEXTITEM,TVGN_NEXT,nmtv.itemNew.hItem
			test eax,eax
			jz @F
		.until FALSE
		pop ecx
		mov ebx,nmtv.itemNew.hItem
		jecxz @r
	.endw
@r:	invoke SendMessage,nmtv.hdr.hwndFrom,TVM_SELECTITEM,TVGN_CARET,ebx
	ret
	
@@:	pop ecx
	jmp short @r
	
ExpandTreePath endp

align DWORD
GetDrives proc hWnd:HWND, dwID:DWORD
	local tvc				:TVINSERTSTRUCT
	local buffer[4]			:BYTE
	
	mov (dword ptr buffer[0]),"\:A"
	lea edx,buffer
	mov tvc.hParent,TVI_ROOT
	mov tvc.hInsertAfter,TVI_LAST
	mov tvc.item.cChildren,TRUE
	mov tvc.item.pszText,edx
	.repeat
		invoke GetDriveType,addr buffer
		.if eax > 1
			mov tvc.item._mask,TVIF_CHILDREN or TVIF_TEXT
			invoke SHGetFileInfo,addr buffer,0,offset shfi,sizeof shfi,
				SHGFI_SELECTED or SHGFI_SMALLICON or SHGFI_SYSICONINDEX ;or SHGFI_ADDOVERLAYS
			.if eax
				push shfi.iIcon
				or tvc.item._mask,TVIF_SELECTEDIMAGE
				pop tvc.item.iSelectedImage
			.endif
			invoke SHGetFileInfo,addr buffer,0,offset shfi,sizeof shfi,
				SHGFI_SMALLICON or SHGFI_SYSICONINDEX ;or SHGFI_ADDOVERLAYS
			.if eax
				push shfi.iIcon
				or tvc.item._mask,TVIF_IMAGE
				pop tvc.item.iImage
			.endif
			mov buffer[2],0
			invoke SendDlgItemMessage,hWnd,dwID,TVM_INSERTITEM,0,addr tvc
			mov buffer[2],'\'
		.endif
		inc buffer[0]
	.until buffer[0] > 'Z'
	ret
	
GetDrives endp

align DWORD
IsSelectedWapFileInFolder proc hWnd:HWND, idCombo:DWORD
	local w32fd:WIN32_FIND_DATA
	
	; Expects the currently selected folder to be the current folder.
	
	mov w32fd.cFileName[0],0
	invoke GetDlgItemText,hWnd,idCombo,addr w32fd.cFileName,sizeof w32fd.cFileName
	invoke PathIsDirectory,addr w32fd.cFileName
	.if eax
		xor eax,eax
	.else
		invoke PathFindFileName,addr w32fd.cFileName
		invoke PathFileExists,eax
	.endif
	IFDEF DEBUG_BUILD
		PrintDec eax
	ENDIF
	ret
	
IsSelectedWapFileInFolder endp

align DWORD
ListWapFilesInFolder proc hWnd:HWND, idCombo:DWORD, bSelectFirst:DWORD
	local hFind:HANDLE
	local w32fd:WIN32_FIND_DATA
	
	; Expects the currently selected folder to be the current folder.
	
	mov w32fd.cFileName[0],0
	invoke GetDlgItemText,hWnd,idCombo,addr w32fd.cFileName,sizeof w32fd.cFileName
	invoke SendDlgItemMessage,hWnd,idCombo,CB_RESETCONTENT,0,0
	invoke SetDlgItemText,hWnd,idCombo,addr w32fd.cFileName
	invoke FindFirstFile,offset szMaskWap,addr w32fd
	.if eax != INVALID_HANDLE_VALUE
		mov hFind,eax
		.if bSelectFirst
			invoke SetDlgItemText,hWnd,idCombo,addr w32fd.cFileName
		.endif
		.repeat
			invoke SendDlgItemMessage,hWnd,idCombo,CB_ADDSTRING,0,addr w32fd.cFileName
			invoke FindNextFile,hFind,addr w32fd
		.until !eax
		invoke FindClose,hFind
	.endif
	ret
	
ListWapFilesInFolder endp

align DWORD
CenterWindow proc hWnd:HWND
	local rcOwner	:RECT
	local rcWnd		:RECT
	
	invoke GetWindow,hWnd,GW_OWNER
	.if eax == NULL
		invoke GetDesktopWindow
	.endif
	lea edx,rcOwner
	invoke GetWindowRect,eax,edx
	invoke GetWindowRect,hWnd,addr rcWnd
	mov eax,rcOwner.right
	mov edx,rcWnd.right
	sub eax,rcOwner.left
	sub edx,rcWnd.left
	sub eax,edx
	sar eax,1
	add rcOwner.left,eax
	mov eax,rcOwner.bottom
	mov edx,rcWnd.bottom
	sub eax,rcOwner.top
	sub edx,rcWnd.top
	sub eax,edx
	sar eax,1
	add rcOwner.top,eax
	invoke SetWindowPos,hWnd,0,rcOwner.left,rcOwner.top,0,0,
		SWP_NOACTIVATE or SWP_NOOWNERZORDER or SWP_NOREPOSITION or SWP_NOSIZE
	ret
	
CenterWindow endp

align DWORD
DefBuildCmdsToEdit proc hWnd:HWND
	
	invoke SetDlgItemText,hWnd,IDC_EDIT3,offset pszCompileRCCommand
	invoke SetDlgItemText,hWnd,IDC_EDIT4,offset pszResToObjCommand
	invoke SetDlgItemText,hWnd,IDC_EDIT5,offset pszReleaseAssembleCommand
	invoke SetDlgItemText,hWnd,IDC_EDIT6,offset pszReleaseLinkCommand
	invoke SetDlgItemText,hWnd,IDC_EDIT7,offset pszReleaseOUTCommand
	invoke SetDlgItemText,hWnd,IDC_EDIT8,offset pszDebugAssembleCommand
	invoke SetDlgItemText,hWnd,IDC_EDIT9,offset pszDebugLinkCommand
	invoke SetDlgItemText,hWnd,IDC_EDIT10,offset pszDebugOUTCommand
	ret
	
DefBuildCmdsToEdit endp

align DWORD
DefBuildCmdsFromEdit proc hWnd:HWND
	
	invoke GetDlgItemText,hWnd,IDC_EDIT3,offset pszCompileRCCommand,MAX_PATH
	invoke GetDlgItemText,hWnd,IDC_EDIT4,offset pszResToObjCommand,MAX_PATH
	invoke GetDlgItemText,hWnd,IDC_EDIT5,offset pszReleaseAssembleCommand,MAX_PATH
	invoke GetDlgItemText,hWnd,IDC_EDIT6,offset pszReleaseLinkCommand,MAX_PATH
	invoke GetDlgItemText,hWnd,IDC_EDIT7,offset pszReleaseOUTCommand,MAX_PATH
	invoke GetDlgItemText,hWnd,IDC_EDIT8,offset pszDebugAssembleCommand,MAX_PATH
	invoke GetDlgItemText,hWnd,IDC_EDIT9,offset pszDebugLinkCommand,MAX_PATH
	invoke GetDlgItemText,hWnd,IDC_EDIT10,offset pszDebugOUTCommand,MAX_PATH
	ret
	
DefBuildCmdsFromEdit endp

align DWORD
BuildCmdsToEdit proc hWnd:HWND
	
	invoke SetDlgItemText,hWnd,IDC_EDIT3,cpi.pszCompileRCCommand
	invoke SetDlgItemText,hWnd,IDC_EDIT4,cpi.pszResToObjCommand
	invoke SetDlgItemText,hWnd,IDC_EDIT5,cpi.pszReleaseAssembleCommand
	invoke SetDlgItemText,hWnd,IDC_EDIT6,cpi.pszReleaseLinkCommand
	invoke SetDlgItemText,hWnd,IDC_EDIT7,cpi.pszReleaseOUTCommand
	invoke SetDlgItemText,hWnd,IDC_EDIT8,cpi.pszDebugAssembleCommand
	invoke SetDlgItemText,hWnd,IDC_EDIT9,cpi.pszDebugLinkCommand
	invoke SetDlgItemText,hWnd,IDC_EDIT10,cpi.pszDebugOUTCommand
	ret
	
BuildCmdsToEdit endp

align DWORD
BuildCmdsFromEdit proc hWnd:HWND
	
	invoke GetDlgItemText,hWnd,IDC_EDIT3,cpi.pszCompileRCCommand,MAX_PATH
	invoke GetDlgItemText,hWnd,IDC_EDIT4,cpi.pszResToObjCommand,MAX_PATH
	invoke GetDlgItemText,hWnd,IDC_EDIT5,cpi.pszReleaseAssembleCommand,MAX_PATH
	invoke GetDlgItemText,hWnd,IDC_EDIT6,cpi.pszReleaseLinkCommand,MAX_PATH
	invoke GetDlgItemText,hWnd,IDC_EDIT7,cpi.pszReleaseOUTCommand,MAX_PATH
	invoke GetDlgItemText,hWnd,IDC_EDIT8,cpi.pszDebugAssembleCommand,MAX_PATH
	invoke GetDlgItemText,hWnd,IDC_EDIT9,cpi.pszDebugLinkCommand,MAX_PATH
	invoke GetDlgItemText,hWnd,IDC_EDIT10,cpi.pszDebugOUTCommand,MAX_PATH
	ret
	
BuildCmdsFromEdit endp

; #############################################################################
; #############################################################################
; #############################################################################

; Page 1 - choose action (empty project, template project, existing sources)
align DWORD
DlgProc1 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
	mov eax,uMsg
	.if eax == WM_NOTIFY
		mov edx,lParam
		mov eax,[edx].NMHDR.code
		.if eax == PSN_SETACTIVE
			invoke GetParent,hWnd
			invoke PostMessage,eax,PSM_SETWIZBUTTONS,0,PSWIZB_NEXT
		.elseif eax == PSN_WIZNEXT
			invoke IsDlgButtonChecked,hWnd,IDC_RADIO1
			.if eax == BST_CHECKED
				mov eax,IDD_PAGE2_1
			.else
				invoke IsDlgButtonChecked,hWnd,IDC_RADIO2
				.if eax == BST_CHECKED
					mov eax,IDD_PAGE2_2
				.else
					invoke IsDlgButtonChecked,hWnd,IDC_RADIO3
					.if eax == BST_UNCHECKED
						mov eax,IDD_PAGE2_4
					.else
						mov eax,IDD_PAGE2_3
					.endif
				.endif
			.endif
			mov dwWizChoice,eax
			push eax
			push 0
			push PSM_SETCURSELID
			invoke GetParent,hWnd
			push eax
			call PostMessage
			invoke SetWindowLong,hWnd,DWL_MSGRESULT,-1
			push TRUE
			pop eax
			ret
		.endif
	.elseif eax == WM_INITDIALOG
		IFDEF DEBUG_BUILD
			PrintText "Initializing IDD_PAGE1"
		ENDIF
		mov bDoIt,FALSE
		invoke GetParent,hWnd
		invoke CenterWindow,eax
		mov eax,dwWizChoice
		sub eax,IDD_PAGE2_1
		add eax,IDC_RADIO1
		invoke CheckRadioButton,hWnd,IDC_RADIO1,IDC_RADIO4,eax
		invoke GetCurrentDirectory,sizeof szGlobalCurrDir,offset szGlobalCurrDir
		invoke GetCurrentDirectory,sizeof szChangeFolder,offset szChangeFolder
		invoke GetPrivateProfileString,offset szGENERAL,offset szInitDir,
		 		offset szChangeFolder,offset szDefProjectFolder,
		 		sizeof szDefProjectFolder,offset szWAIniPath
	.endif
	xor eax,eax
	ret
	
DlgProc1 endp

; Page 2 - empty project - select project type
align DWORD
DlgProc21 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
	mov eax,uMsg
	.if eax == WM_NOTIFY
		mov edx,lParam
		mov eax,[edx].NMHDR.code
		.if eax == PSN_SETACTIVE
			invoke GetParent,hWnd
			invoke SendMessage,eax,PSM_SETWIZBUTTONS,0,PSWIZB_BACK or PSWIZB_FINISH
		.elseif eax == PSN_WIZFINISH
			invoke SendDlgItemMessage,hWnd,IDC_LIST1,LVM_GETNEXTITEM,-1,LVNI_ALL or LVNI_FOCUSED
			.if eax == -1
				invoke SetWindowLong,hWnd,DWL_MSGRESULT,eax
				push TRUE
				pop eax
				ret
			.endif
			mov dwProjectType,eax
			mov bDoIt,TRUE
			.if bRemember
				invoke SaveLastTakenChoices
			.endif
		.endif
	.elseif eax == WM_INITDIALOG
		IFDEF DEBUG_BUILD
			PrintText "Initializing IDD_PAGE2_1"
		ENDIF
		invoke ImageList_LoadImage,psp21.hInstance,IDB_BITMAP3,32,7,008000FFh,IMAGE_BITMAP,LR_CREATEDIBSECTION
		invoke SendDlgItemMessage,hWnd,IDC_LIST1,LVM_SETIMAGELIST,LVSIL_NORMAL,eax
		push esi
		mov esi,offset ptype0
		.repeat
			invoke SendDlgItemMessage,hWnd,IDC_LIST1,LVM_INSERTITEM,0,esi
			add esi,sizeof LVITEM
		.until esi > offset ptype6
		pop esi
		invoke SendDlgItemMessage,hWnd,IDC_LIST1,LVM_SETITEM,0,offset lvi
	.endif
	xor eax,eax
	ret
	
DlgProc21 endp

; Page 2 - template project - select template
align DWORD
DlgProc22 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local hFind1			:DWORD
	local hFind2			:DWORD
	local w32fd1			:WIN32_FIND_DATA
	local w32fd2			:WIN32_FIND_DATA
	local tvc1				:TVINSERTSTRUCT
	local tvc2				:TVINSERTSTRUCT
	local szname[MAX_PATH*4]:BYTE
	local szpath[MAX_PATH]	:BYTE
	
	mov eax,uMsg
	.if eax == WM_NOTIFY
		mov edx,lParam
		mov eax,[edx].NMHDR.code
		.if eax == TVN_ITEMEXPANDING
			mov eax,[edx].NMTREEVIEW.action
			.if eax == TVE_COLLAPSE
				mov eax,[edx].NMTREEVIEW.itemNew.hItem
				mov tvc1.item.hItem,eax
				invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_GETNEXTITEM,TVGN_PARENT,eax
				.if !eax
					mov tvc1.item._mask,TVIF_HANDLE or TVIF_IMAGE or TVIF_SELECTEDIMAGE
					mov tvc1.item.iImage,0
					mov tvc1.item.iSelectedImage,0
					invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_SETITEM,0,addr tvc1.item
				.endif
			.elseif eax == TVE_EXPAND
				mov eax,[edx].NMTREEVIEW.itemNew.hItem
				mov tvc1.item.hItem,eax
				invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_GETNEXTITEM,TVGN_PARENT,eax
				.if !eax
					mov tvc1.item._mask,TVIF_HANDLE or TVIF_IMAGE or TVIF_SELECTEDIMAGE
					mov tvc1.item.iImage,1
					mov tvc1.item.iSelectedImage,1
					invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_SETITEM,0,addr tvc1.item
				.endif
			.endif
		.elseif eax == PSN_SETACTIVE
			mov tvc1.hParent,TVI_ROOT
			mov tvc1.hInsertAfter,TVI_SORT
			mov tvc1.item._mask,TVIF_TEXT or TVIF_IMAGE or TVIF_SELECTEDIMAGE
			mov tvc1.item.iImage,0
			mov tvc1.item.iSelectedImage,0
			lea eax,w32fd1.cFileName
			mov tvc1.item.pszText,eax
			mov tvc2.hInsertAfter,TVI_SORT
			mov tvc2.item._mask,TVIF_CHILDREN or TVIF_TEXT or TVIF_IMAGE or TVIF_SELECTEDIMAGE
			mov tvc2.item.cChildren,FALSE
			lea eax,w32fd2.cFileName
			mov tvc2.item.pszText,eax
			mov szpath,0
			invoke GetCurrentDirectory,sizeof szpath,addr szpath
			invoke SetCurrentDirectory,offset szTemplatesPath
			.if eax
				invoke FindFirstFile,offset szMaskAll,addr w32fd1
				.if eax != INVALID_HANDLE_VALUE
					mov hFind1,eax
					.repeat
						test w32fd1.dwFileAttributes,FILE_ATTRIBUTE_DIRECTORY
						.if (! zero?) && w32fd1.cFileName != '.'
							invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_INSERTITEM,0,addr tvc1
							.if eax
								mov tvc2.hParent,eax
								invoke SetCurrentDirectory,addr w32fd1.cFileName
								invoke FindFirstFile,offset szMaskAll,addr w32fd2
								.if eax != INVALID_HANDLE_VALUE
									mov hFind2,eax
									.repeat
										test w32fd2.dwFileAttributes,FILE_ATTRIBUTE_DIRECTORY
										.if (! zero?) && w32fd2.cFileName != '.'
											invoke lstrcpy,addr szname,addr w32fd2.cFileName
											invoke PathAddBackslash,eax
											invoke lstrcat,addr szname,addr w32fd2.cFileName
											invoke lstrcat,eax,offset szDotWap
											invoke PathFileExists,eax
											.if eax
												invoke GetPrivateProfileInt,offset szPROJECT,offset szType,0,addr szname
												add eax,2
												mov tvc2.item.iImage,eax
												mov tvc2.item.iSelectedImage,eax
												invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_INSERTITEM,0,addr tvc2
												.if eax
													push eax
													invoke lstrcpy,addr szname,offset szTemplatesPath
													invoke PathAddBackslash,eax
													invoke lstrcat,addr szname,addr w32fd1.cFileName
													invoke PathAddBackslash,eax
													invoke lstrcat,addr szname,addr w32fd2.cFileName
													invoke lstrcmpi,eax,offset szChosenTemplate
													pop edx
													.if eax == 0
														invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_SELECTITEM,TVGN_CARET,edx
													.endif
												.endif
											.endif
										.endif
										invoke FindNextFile,hFind2,addr w32fd2
									.until eax == 0
									invoke FindClose,hFind2
								.endif
								invoke SetCurrentDirectory,offset szDotDot
							.endif
						.endif
						invoke FindNextFile,hFind1,addr w32fd1
					.until eax == 0
					invoke FindClose,hFind1
				.endif
			.endif
			invoke SetCurrentDirectory,addr szpath
			invoke GetParent,hWnd
			invoke PostMessage,eax,PSM_SETWIZBUTTONS,0,PSWIZB_BACK or PSWIZB_NEXT
		.elseif eax == PSN_KILLACTIVE
			invoke GetDlgItem,hWnd,IDC_TREE1
			push TVI_ROOT
			push 0
			push TVM_DELETEITEM
			push eax
			invoke LockWindowUpdate,eax
			call SendMessage
			invoke LockWindowUpdate,NULL
		.elseif eax == PSN_WIZBACK
			invoke GetParent,hWnd
			invoke PostMessage,eax,PSM_SETCURSELID,0,IDD_PAGE1
			invoke SetWindowLong,hWnd,DWL_MSGRESULT,-1
			push TRUE
			pop eax
			ret
		.elseif eax == PSN_WIZNEXT
			invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_GETNEXTITEM,TVGN_CARET,TVI_ROOT
			.if eax == NULL
@@:				invoke SetWindowLong,hWnd,DWL_MSGRESULT,-1
				push TRUE
				pop eax
				ret
			.endif
			lea edx,w32fd1.cFileName
			mov tvc1.item.hItem,eax
			mov tvc1.item._mask,TVIF_HANDLE or TVIF_TEXT or TVIF_CHILDREN
			mov tvc1.item.pszText,edx
			mov tvc1.item.cchTextMax,MAX_PATH
			invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_GETITEM,0,addr tvc1.item
			test eax,eax
			jz @B
			cmp tvc1.item.cChildren,FALSE
			jne @B
			invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_GETNEXTITEM,TVGN_PARENT,tvc1.item.hItem
			test eax,eax
			jz @B
			lea edx,w32fd2.cFileName
			mov tvc2.item.hItem,eax
			mov tvc2.item._mask,TVIF_HANDLE or TVIF_TEXT
			mov tvc2.item.pszText,edx
			mov tvc2.item.cchTextMax,MAX_PATH
			invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_GETITEM,0,addr tvc2.item
			test eax,eax
			jz @B
			mov szname,0
			invoke lstrcpy,addr szname,offset szTemplatesPath
			invoke PathAddBackslash,eax
			invoke lstrcat,addr szname,addr w32fd2.cFileName
			invoke PathAddBackslash,eax
			invoke lstrcat,addr szname,addr w32fd1.cFileName
			invoke PathFileExists,eax
			test eax,eax
			jz @B
			invoke lstrcpy,offset szChosenTemplate,addr szname
			invoke lstrcpy,offset szUseTemplate,addr szname
			invoke lstrcpy,offset szUseTemplateWap,eax
			invoke PathAppend,offset szUseTemplateWap,addr w32fd1.cFileName
			invoke PathAddExtension,offset szUseTemplateWap,offset szDotWap
		.endif
	.elseif eax == WM_INITDIALOG
		IFDEF DEBUG_BUILD
			PrintText "Initializing IDD_PAGE2_2"
		ENDIF
		invoke ImageList_LoadImage,psp22.hInstance,IDB_BITMAP4,16,7+2,008000FFh,IMAGE_BITMAP,LR_CREATEDIBSECTION
		invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_SETIMAGELIST,TVSIL_NORMAL,eax
	.elseif eax == WM_DESTROY
		invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_SETIMAGELIST,TVSIL_NORMAL,NULL
		.if eax
			invoke ImageList_Destroy,eax
		.endif
	.endif
	xor eax,eax
	ret
	
DlgProc22 endp

; Page 2 - existing sources - select project type
align DWORD
DlgProc23 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
	mov eax,uMsg
	.if eax == WM_NOTIFY
		mov edx,lParam
		mov eax,[edx].NMHDR.code
		.if eax == PSN_SETACTIVE
			invoke GetParent,hWnd
			invoke PostMessage,eax,PSM_SETWIZBUTTONS,0,PSWIZB_BACK or PSWIZB_NEXT
		.elseif eax == PSN_WIZBACK
			invoke GetParent,hWnd
			invoke PostMessage,eax,PSM_SETCURSELID,0,IDD_PAGE1
			invoke SetWindowLong,hWnd,DWL_MSGRESULT,-1
			push TRUE
			pop eax
			ret
		.elseif eax == PSN_WIZNEXT
			invoke SendDlgItemMessage,hWnd,IDC_LIST2,LVM_GETNEXTITEM,-1,LVNI_ALL or LVNI_FOCUSED
			test eax,eax
			.if sign?
				invoke SetWindowLong,hWnd,DWL_MSGRESULT,-1
				push TRUE
				pop eax
				ret
			.endif
			mov dwProjectType,eax
		.endif
	.elseif eax == WM_INITDIALOG
		IFDEF DEBUG_BUILD
			PrintText "Initializing IDD_PAGE2_3"
		ENDIF
		invoke ImageList_LoadImage,psp23.hInstance,IDB_BITMAP3,32,7,008000FFh,IMAGE_BITMAP,LR_CREATEDIBSECTION
		invoke SendDlgItemMessage,hWnd,IDC_LIST2,LVM_SETIMAGELIST,LVSIL_NORMAL,eax
		invoke SendDlgItemMessage,hWnd,IDC_LIST2,LVM_INSERTITEM,0,offset ptype0
		invoke SendDlgItemMessage,hWnd,IDC_LIST2,LVM_INSERTITEM,0,offset ptype1
		invoke SendDlgItemMessage,hWnd,IDC_LIST2,LVM_INSERTITEM,0,offset ptype2
		invoke SendDlgItemMessage,hWnd,IDC_LIST2,LVM_INSERTITEM,0,offset ptype3
		invoke SendDlgItemMessage,hWnd,IDC_LIST2,LVM_INSERTITEM,0,offset ptype4
		invoke SendDlgItemMessage,hWnd,IDC_LIST2,LVM_INSERTITEM,0,offset ptype5
		invoke SendDlgItemMessage,hWnd,IDC_LIST2,LVM_INSERTITEM,0,offset ptype6
		invoke SendDlgItemMessage,hWnd,IDC_LIST2,LVM_SETITEM,0,offset lvi
	.endif
	xor eax,eax
	ret
	
DlgProc23 endp

; Page 2 - clone project - select project to clone
align DWORD
DlgProc24 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local tvc:TVINSERTSTRUCT
	local buffer[MAX_PATH]:BYTE
	
	mov eax,uMsg
	.if eax == WM_NOTIFY
		mov edx,lParam
		mov eax,[edx].NMHDR.code
		.if eax == TVN_SELCHANGING
			invoke GetTreePath,hWnd,IDC_TREE4,[edx].NMTREEVIEW.itemOld.hItem
			invoke SetCurrentDirectory,offset szChangeFolder
			invoke SendDlgItemMessage,hWnd,IDC_COMBO4,WM_GETTEXTLENGTH,0,0
			.if eax == 0
				push TRUE
			.else
				invoke IsSelectedWapFileInFolder,hWnd,IDC_COMBO4
				push eax
				.if eax
					invoke SetDlgItemText,hWnd,IDC_COMBO4,offset szNull
				.endif
			.endif
			mov edx,lParam
			invoke GetTreePath,hWnd,IDC_TREE4,[edx].NMTREEVIEW.itemNew.hItem
			invoke SetCurrentDirectory,offset szChangeFolder
			push IDC_COMBO4
			push hWnd
			call ListWapFilesInFolder
		.elseif eax == TVN_ITEMEXPANDING
			mov eax,[edx].NMTREEVIEW.action
			.if eax == TVE_COLLAPSE
				mov eax,[edx].NMTREEVIEW.itemNew.hItem
				mov tvc.item._mask,TVIF_HANDLE
				mov tvc.item.hItem,eax
				invoke LoadCursor,NULL,IDC_WAIT
				invoke SetCursor,eax
				push eax
				invoke GetTreePath,hWnd,IDC_TREE4,tvc.item.hItem
				invoke PathRemoveBackslash,offset szChangeFolder
				invoke SHGetFileInfo,offset szChangeFolder,0,offset shfi,sizeof shfi,
				 			SHGFI_SELECTED or SHGFI_SMALLICON or SHGFI_SYSICONINDEX
				.if eax
					push shfi.iIcon
					or tvc.item._mask,TVIF_SELECTEDIMAGE
					pop tvc.item.iSelectedImage
				.endif
				invoke SHGetFileInfo,offset szChangeFolder,0,offset shfi,sizeof shfi,
				 			SHGFI_SMALLICON or SHGFI_SYSICONINDEX
				.if eax
					push shfi.iIcon
					or tvc.item._mask,TVIF_IMAGE
					pop tvc.item.iImage
				.endif
				.if tvc.item._mask != TVIF_HANDLE
					invoke SendDlgItemMessage,hWnd,IDC_TREE4,TVM_SETITEM,0,addr tvc.item
				.endif
				invoke SendDlgItemMessage,hWnd,IDC_TREE4,TVM_EXPAND,
				 						TVE_COLLAPSE or TVE_COLLAPSERESET,tvc.item.hItem
				call SetCursor
			.elseif eax == TVE_EXPAND
				mov eax,[edx].NMTREEVIEW.itemNew.hItem
				mov tvc.item._mask,TVIF_HANDLE
				mov tvc.item.hItem,eax
				invoke LoadCursor,NULL,IDC_WAIT
				invoke SetCursor,eax
				push eax
				invoke GetTreePath,hWnd,IDC_TREE4,tvc.item.hItem
				invoke PathRemoveBackslash,offset szChangeFolder
				invoke SHGetFileInfo,offset szChangeFolder,0,offset shfi,sizeof shfi,
					SHGFI_OPENICON or SHGFI_SELECTED or SHGFI_SMALLICON or SHGFI_SYSICONINDEX
				.if eax
					push shfi.iIcon
					or tvc.item._mask,TVIF_SELECTEDIMAGE
					pop tvc.item.iSelectedImage
				.endif
				invoke SHGetFileInfo,offset szChangeFolder,0,offset shfi,sizeof shfi,
					SHGFI_OPENICON or SHGFI_SMALLICON or SHGFI_SYSICONINDEX
				.if eax
					push shfi.iIcon
					or tvc.item._mask,TVIF_IMAGE
					pop tvc.item.iImage
				.endif
				.if tvc.item._mask != TVIF_HANDLE
					invoke SendDlgItemMessage,hWnd,IDC_TREE4,TVM_SETITEM,0,addr tvc.item
				.endif
				invoke ExpandTreeFolder,hWnd,IDC_TREE4,tvc.item.hItem
				call SetCursor
			.endif
		.elseif eax == PSN_SETACTIVE
			invoke LoadCursor,NULL,IDC_WAIT
			invoke SetCursor,eax
			push eax
			invoke GetDrives,hWnd,IDC_TREE4
			invoke GetParent,hWnd
			invoke PostMessage,eax,PSM_SETWIZBUTTONS,0,PSWIZB_BACK or PSWIZB_NEXT
			call SetCursor
		.elseif eax == PSN_KILLACTIVE
			invoke GetDlgItem,hWnd,IDC_TREE4
			push TVI_ROOT
			push 0
			push TVM_DELETEITEM
			push eax
			invoke LockWindowUpdate,eax
			call SendMessage
			invoke LockWindowUpdate,NULL
		.elseif eax == PSN_WIZBACK
			invoke GetParent,hWnd
			invoke PostMessage,eax,PSM_SETCURSELID,0,IDD_PAGE1
			invoke SetWindowLong,hWnd,DWL_MSGRESULT,-1
			push TRUE
			pop eax
			ret
		.elseif eax == PSN_WIZNEXT
			invoke SendDlgItemMessage,hWnd,IDC_COMBO4,WM_GETTEXTLENGTH,0,0
			.if eax
				invoke GetDlgItemText,hWnd,IDC_COMBO4,addr buffer,sizeof buffer
				.if eax
					invoke PathIsFileSpec,addr buffer
					.if eax
						invoke SendDlgItemMessage,hWnd,IDC_TREE4,TVM_GETNEXTITEM,TVGN_CARET,TVI_ROOT
						.if eax
							invoke GetTreePath,hWnd,IDC_TREE4,eax
							invoke lstrcat,offset szChangeFolder,addr buffer
						.endif
					.else
						invoke lstrcpy,offset szChangeFolder,addr buffer
					.endif
					invoke PathFileExists,offset szChangeFolder
					.if eax
						invoke PathIsDirectory,offset szChangeFolder
						.if !eax
							invoke lstrcpy,offset szChosenCloneSrc,offset szChangeFolder
							invoke lstrcpy,offset szUseTemplateWap,offset szChangeFolder
							invoke PathRemoveFileSpec,offset szChangeFolder
							invoke lstrcpy,offset szUseTemplate,offset szChangeFolder
							invoke GetParent,hWnd
							invoke PostMessage,eax,PSM_SETCURSELID,0,IDD_PAGE3_4
						.endif
					.endif
				.endif
			.endif
	@@:		invoke SetWindowLong,hWnd,DWL_MSGRESULT,-1
			push TRUE
			pop eax
			ret
		.endif
	.elseif eax == WM_COMMAND
		mov eax,wParam
		.if eax == IDC_BUTTON18
			invoke LoadCursor,NULL,IDC_WAIT
			invoke SetCursor,eax
			push eax
			invoke GetDlgItemText,hWnd,IDC_COMBO4,offset szChangeFolder,MAX_PATH
			.if eax
				mov buffer[0],0
				invoke PathIsDirectory,offset szChangeFolder
				.if !eax
					invoke PathFileExists,offset szChangeFolder
					.if eax
						invoke PathFindFileName,offset szChangeFolder
						invoke lstrcpyn,addr buffer,eax,sizeof buffer
					.endif
					invoke PathRemoveFileSpec,offset szChangeFolder
				.endif
				invoke GetFullPathName,offset szChangeFolder,sizeof szChangeFolder,
										offset szChangeFolder,addr tvc.hParent
				invoke ListWapFilesInFolder,hWnd,IDC_COMBO4,FALSE
				invoke ExpandTreePath,hWnd,IDC_TREE4
				invoke SetDlgItemText,hWnd,IDC_COMBO4,addr buffer
			.endif
			call SetCursor
		.endif
	.elseif eax == WM_INITDIALOG
		IFDEF DEBUG_BUILD
			PrintText "Initializing IDD_PAGE2_4"
		ENDIF
		.if !hSysSmIml
			invoke GetModuleHandle,offset szShell32		;should already be loaded...
			.if eax
				push 71
				push eax
				invoke GetProcAddress,eax,660	;FileIconInit (NT, 2K, XP)
				.if eax
					push TRUE
					call eax
				.endif
				call GetProcAddress				;Shell_GetImageLists (all)
				.if eax
					push offset hSysSmIml
					push offset hSysIml
					call eax
				.endif
			.endif
		.endif
		invoke SendDlgItemMessage,hWnd,IDC_TREE4,TVM_SETIMAGELIST,TVSIL_NORMAL,hSysSmIml
		invoke LoadImage,psp24.hInstance,IDB_BITMAP7,IMAGE_BITMAP,0,0,LR_CREATEDIBSECTION or LR_LOADMAP3DCOLORS or LR_LOADTRANSPARENT
		invoke SendDlgItemMessage,hWnd,IDC_BUTTON18,BM_SETIMAGE,IMAGE_BITMAP,eax
		invoke SendDlgItemMessage,hWnd,IDC_COMBO4,EM_SETLIMITTEXT,MAX_PATH,0
		.if szChosenCloneSrc[0] == 0
			push offset szDefProjectFolder
		.else
			push offset szChosenCloneSrc
		.endif
		push IDC_COMBO4
		push hWnd
		call SetDlgItemText
	.elseif eax == WM_DESTROY
		invoke SendDlgItemMessage,hWnd,IDC_TREE5,TVM_SETIMAGELIST,TVSIL_NORMAL,NULL
		invoke SendDlgItemMessage,hWnd,IDC_BUTTON18,BM_SETIMAGE,IMAGE_BITMAP,0
		invoke DeleteObject,eax
	.endif
	xor eax,eax
	ret
	
DlgProc24 endp

; Page 3 - template project - select target folder
align DWORD
DlgProc32 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local hFind				:DWORD
	local tvc				:TVINSERTSTRUCT
	local buffer[MAX_PATH]	:BYTE
	local currdir[MAX_PATH]	:BYTE
	local w32fd				:WIN32_FIND_DATA
	
	mov eax,uMsg
	.if eax == WM_NOTIFY
		mov edx,lParam
		mov eax,[edx].NMHDR.code
		.if eax == TVN_SELCHANGING
			invoke GetTreePath,hWnd,IDC_TREE2,[edx].NMTREEVIEW.itemNew.hItem
			invoke SetDlgItemText,hWnd,IDC_EDIT1,offset szChangeFolder
		.elseif eax == TVN_ITEMEXPANDING
			mov eax,[edx].NMTREEVIEW.action
			.if eax == TVE_COLLAPSE
				mov eax,[edx].NMTREEVIEW.itemNew.hItem
				mov tvc.item._mask,TVIF_HANDLE
				mov tvc.item.hItem,eax
				invoke LoadCursor,NULL,IDC_WAIT
				invoke SetCursor,eax
				push eax
				invoke GetTreePath,hWnd,IDC_TREE2,tvc.item.hItem
				invoke SHGetFileInfo,offset szChangeFolder,0,offset shfi,sizeof shfi,
				 			SHGFI_SELECTED or SHGFI_SMALLICON or SHGFI_SYSICONINDEX
				.if eax
					push shfi.iIcon
					or tvc.item._mask,TVIF_SELECTEDIMAGE
					pop tvc.item.iSelectedImage
				.endif
				invoke SHGetFileInfo,offset szChangeFolder,0,offset shfi,sizeof shfi,
				 			SHGFI_SMALLICON or SHGFI_SYSICONINDEX
				.if eax
					push shfi.iIcon
					or tvc.item._mask,TVIF_IMAGE
					pop tvc.item.iImage
				.endif
				.if tvc.item._mask != TVIF_HANDLE
					invoke SendDlgItemMessage,hWnd,IDC_TREE2,TVM_SETITEM,0,addr tvc.item
				.endif
				invoke SendDlgItemMessage,hWnd,IDC_TREE2,TVM_EXPAND,
				 						TVE_COLLAPSE or TVE_COLLAPSERESET,tvc.item.hItem
				call SetCursor
			.elseif eax == TVE_EXPAND
				mov eax,[edx].NMTREEVIEW.itemNew.hItem
				mov tvc.item._mask,TVIF_HANDLE
				mov tvc.item.hItem,eax
				invoke LoadCursor,NULL,IDC_WAIT
				invoke SetCursor,eax
				push eax
				invoke GetTreePath,hWnd,IDC_TREE2,tvc.item.hItem
				invoke SHGetFileInfo,offset szChangeFolder,0,offset shfi,sizeof shfi,
				 			SHGFI_OPENICON or SHGFI_SELECTED or SHGFI_SMALLICON or SHGFI_SYSICONINDEX
				.if eax
					push shfi.iIcon
					or tvc.item._mask,TVIF_SELECTEDIMAGE
					pop tvc.item.iSelectedImage
				.endif
				invoke SHGetFileInfo,offset szChangeFolder,0,offset shfi,sizeof shfi,
				 			SHGFI_OPENICON or SHGFI_SMALLICON or SHGFI_SYSICONINDEX
				.if eax
					push shfi.iIcon
					or tvc.item._mask,TVIF_IMAGE
					pop tvc.item.iImage
				.endif
				.if tvc.item._mask != TVIF_HANDLE
					invoke SendDlgItemMessage,hWnd,IDC_TREE2,TVM_SETITEM,0,addr tvc.item
				.endif
				invoke ExpandTreeFolder,hWnd,IDC_TREE2,tvc.item.hItem
				call SetCursor
			.endif
		.elseif eax == PSN_SETACTIVE
			invoke GetDrives,hWnd,IDC_TREE2
			.if szTargetFolder[0] == 0
				invoke lstrcpy,offset szTargetFolder,offset szDefProjectFolder
			.endif
			invoke SetDlgItemText,hWnd,IDC_EDIT1,offset szTargetFolder
			invoke GetParent,hWnd
			invoke PostMessage,eax,PSM_SETWIZBUTTONS,0,PSWIZB_BACK or PSWIZB_NEXT
			;invoke GetDlgItem,hWnd,IDC_BUTTON1
			;invoke PostMessage,hWnd,WM_COMMAND,IDC_BUTTON1,eax
		.elseif eax == PSN_KILLACTIVE
			invoke GetDlgItem,hWnd,IDC_TREE2
			push TVI_ROOT
			push 0
			push TVM_DELETEITEM
			push eax
			invoke LockWindowUpdate,eax
			call SendMessage
			invoke LockWindowUpdate,NULL
		.elseif eax == PSN_WIZBACK
			invoke GetParent,hWnd
			invoke PostMessage,eax,PSM_SETCURSELID,0,IDD_PAGE2_2
			invoke SetWindowLong,hWnd,DWL_MSGRESULT,-1
			push TRUE
			pop eax
			ret
		.elseif eax == PSN_WIZNEXT
			invoke GetDlgItemText,hWnd,IDC_EDIT1,offset szTargetFolder,sizeof szTargetFolder
			.if eax && (szTargetFolder[0] != 0)
				invoke PathRemoveBackslash,offset szTargetFolder
				invoke PathIsDirectory,offset szTargetFolder
				.if !eax
					invoke CreateDirectory,offset szTargetFolder,NULL
					test eax,eax
					jz @F
					invoke PathIsDirectory,offset szTargetFolder
					test eax,eax
					jz @F
				.endif
				invoke lstrcpyn,addr buffer,offset szTargetFolder,sizeof buffer - sizeof szMaskAll
				invoke PathAddBackslash,addr buffer
				invoke lstrcat,addr buffer,offset szMaskAll
				invoke FindFirstFile,addr buffer,addr w32fd
				.if !eax
					invoke MessageBox,
						hWnd,offset szTFNotExist,
						offset szWarning,MB_YESNO or MB_ICONWARNING
					cmp eax,IDYES
					jne @F
				.endif
				mov hFind,eax
				.repeat
					mov eax,dword ptr w32fd.cFileName
					and eax,00FFFFFFh
					.if (eax != '..') && (ax != '.')
						invoke MessageBox,
							hWnd,offset szTFNotEmpty,
							offset szWarning,MB_YESNO or MB_ICONWARNING
						.break .if eax == IDYES
						invoke FindClose,hFind
						jmp short @F
					.endif
					invoke FindNextFile,hFind,addr w32fd
				.until !eax
				invoke FindClose,hFind
				invoke GetParent,hWnd
				invoke PostMessage,eax,PSM_SETCURSELID,0,IDD_PAGE4
			.endif
	@@:		invoke SetWindowLong,hWnd,DWL_MSGRESULT,-1
			push TRUE
			pop eax
			ret
		.endif
	.elseif eax == WM_COMMAND
		mov eax,wParam
		.if eax == IDC_BUTTON1
			invoke GetDlgItemText,hWnd,IDC_EDIT1,offset szChangeFolder,sizeof szChangeFolder
			.if eax
				invoke GetFullPathName,offset szChangeFolder,sizeof szChangeFolder,
										offset szChangeFolder,addr tvc.hParent
				invoke ExpandTreePath,hWnd,IDC_TREE2
			.endif
		.elseif eax == IDC_BUTTON2
			mov currdir,0
			invoke GetCurrentDirectory,sizeof currdir,addr currdir
			invoke GetDlgItemText,hWnd,IDC_EDIT1,addr buffer,sizeof buffer
			.if eax && (buffer[0] != 0)
				invoke SendDlgItemMessage,hWnd,IDC_TREE2,TVM_GETNEXTITEM,TVGN_CARET,TVI_ROOT
				.if eax
					invoke GetTreePath,hWnd,IDC_TREE2,eax
					invoke SetCurrentDirectory,offset szChangeFolder
				.else
					invoke lstrcpy,offset szChangeFolder,addr currdir
				.endif
				invoke ExpandTreePath,hWnd,IDC_TREE2
				invoke GetFullPathName,addr buffer,sizeof buffer,addr buffer,addr tvc.hParent
				push eax
				invoke SetCurrentDirectory,addr currdir
				pop eax
				.if eax
					invoke CreateDirectory,addr buffer,NULL
					.if eax
						invoke GetDlgItem,hWnd,IDC_TREE2
						invoke LockWindowUpdate,eax
						invoke SendDlgItemMessage,hWnd,IDC_TREE2,TVM_DELETEITEM,0,TVI_ROOT
						.if eax
							invoke GetDrives,hWnd,IDC_TREE2
							invoke lstrcpy,offset szChangeFolder,addr buffer
							invoke ExpandTreePath,hWnd,IDC_TREE2
						.endif
						invoke LockWindowUpdate,NULL
					.endif
				.endif
			.endif
		.endif
	.elseif eax == WM_INITDIALOG
		IFDEF DEBUG_BUILD
			PrintText "Initializing IDD_PAGE3_2"
		ENDIF
		.if !hSysSmIml
			invoke GetModuleHandle,offset szShell32		;should already be loaded...
			.if eax
				push 71
				push eax
				invoke GetProcAddress,eax,660	;FileIconInit (NT, 2K, XP)
				.if eax
					push TRUE
					call eax
				.endif
				call GetProcAddress				;Shell_GetImageLists (all)
				.if eax
					push offset hSysSmIml
					push offset hSysIml
					call eax
				.endif
			.endif
		.endif
		invoke SendDlgItemMessage,hWnd,IDC_TREE2,TVM_SETIMAGELIST,TVSIL_NORMAL,hSysSmIml
		invoke LoadImage,psp32.hInstance,IDB_BITMAP7,IMAGE_BITMAP,0,0,LR_CREATEDIBSECTION or LR_LOADMAP3DCOLORS or LR_LOADTRANSPARENT
		invoke SendDlgItemMessage,hWnd,IDC_BUTTON1,BM_SETIMAGE,IMAGE_BITMAP,eax
		invoke LoadImage,psp32.hInstance,IDB_BITMAP8,IMAGE_BITMAP,0,0,LR_CREATEDIBSECTION or LR_LOADMAP3DCOLORS or LR_LOADTRANSPARENT
		invoke SendDlgItemMessage,hWnd,IDC_BUTTON2,BM_SETIMAGE,IMAGE_BITMAP,eax
		invoke SendDlgItemMessage,hWnd,IDC_EDIT1,EM_SETLIMITTEXT,sizeof szTargetFolder,0
		.if szTargetFolder[0] != 0
			invoke PathRelativePathTo,offset szChangeFolder,
			 		offset szDefProjectFolder,FILE_ATTRIBUTE_DIRECTORY,
			 		offset szTargetFolder,FILE_ATTRIBUTE_DIRECTORY
			.if eax
				cmp szChangeFolder[0],'.'
				jne @F
			.endif
			push offset szTargetFolder
		.else
	@@:		push offset szDefProjectFolder
		.endif
		push IDC_EDIT1
		push hWnd
		call SetDlgItemText
	.elseif eax == WM_DESTROY
		invoke SendDlgItemMessage,hWnd,IDC_TREE2,TVM_SETIMAGELIST,TVSIL_NORMAL,NULL
		invoke SendDlgItemMessage,hWnd,IDC_BUTTON1,BM_SETIMAGE,IMAGE_BITMAP,0
		invoke DeleteObject,eax
		invoke SendDlgItemMessage,hWnd,IDC_BUTTON2,BM_SETIMAGE,IMAGE_BITMAP,0
		invoke DeleteObject,eax
	.endif
	xor eax,eax
	ret
	
DlgProc32 endp

; Page 3 - existing sources - add project files
align DWORD
DlgProc33 proc uses ebx esi edi hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local iCount	:DWORD
	local iSize		:DWORD
	local point		:POINT
	local ii		:ICONINFO
	local tlvi		:LVITEM
	
	mov eax,uMsg
	.if eax == WM_NOTIFY
		mov edx,lParam
		mov eax,[edx].NMHDR.code
		.if eax == LVN_KEYDOWN
			.if [edx].LV_KEYDOWN.wVKey == VK_DELETE
				invoke SendMessage,hWnd,WM_COMMAND,ID_CONTEXT_REMOVE,0
			.endif
		.elseif eax == NM_RCLICK
			.if [edx].NMHDR.idFrom == IDC_LIST3
				invoke GetCursorPos,addr point
				invoke LoadMenu,psp33.hInstance,IDM_MENU1
				push eax
				 invoke GetSubMenu,eax,0
				 invoke TrackPopupMenuEx,eax,TPM_LEFTALIGN or TPM_TOPALIGN or TPM_RIGHTBUTTON,
				 						 point.x,point.y,hWnd,NULL
				call DestroyMenu
			.endif
		.elseif eax == PSN_SETACTIVE
			invoke GetCurrentDirectory,sizeof szCurrentFolder,offset szCurrentFolder
			invoke GetParent,hWnd
			invoke PostMessage,eax,PSM_SETWIZBUTTONS,0,PSWIZB_BACK or PSWIZB_NEXT
		.elseif eax == PSN_KILLACTIVE
			invoke SetCurrentDirectory,offset szCurrentFolder
		.elseif eax == PSN_WIZBACK
			invoke GetParent,hWnd
			invoke PostMessage,eax,PSM_SETCURSELID,0,IDD_PAGE2_3
@@:			invoke SetWindowLong,hWnd,DWL_MSGRESULT,-1
			push TRUE
			pop eax
			ret
		.elseif eax == PSN_WIZNEXT
			mov eax,pFilesToAdd
			.if eax
				invoke LocalFree,eax
				mov pFilesToAdd,NULL
			.endif
			invoke SendDlgItemMessage,hWnd,IDC_LIST3,LVM_GETITEMCOUNT,0,0
			dec eax
			js @B
			mov iCount,eax
			mov tlvi.pszText,offset szChangeFolder
			mov tlvi.cchTextMax,MAX_PATH
			mov tlvi.iSubItem,0
			mov iSize,1
			push eax
			.repeat
				invoke SendDlgItemMessage,hWnd,IDC_LIST3,LVM_GETITEMTEXT,iCount,addr tlvi
				push eax
				inc tlvi.iSubItem
				invoke SendDlgItemMessage,hWnd,IDC_LIST3,LVM_GETITEMTEXT,iCount,addr tlvi
				pop edx
				dec tlvi.iSubItem
				add eax,edx
				add eax,2
				add iSize,eax
				dec iCount
			.until sign?
			pop iCount
			invoke LocalAlloc,LPTR,iSize
			test eax,eax
			jz @B
			mov pFilesToAdd,eax
			xor ebx,ebx
			xchg edi,eax
			.repeat
				inc tlvi.iSubItem
				mov szChangeFolder[0],0
				invoke SendDlgItemMessage,hWnd,IDC_LIST3,LVM_GETITEMTEXT,ebx,addr tlvi
				invoke lstrcpy,edi,offset szChangeFolder
				invoke PathAddBackslash,edi
				dec tlvi.iSubItem
				mov szChangeFolder[0],0
				invoke SendDlgItemMessage,hWnd,IDC_LIST3,LVM_GETITEMTEXT,ebx,addr tlvi
				invoke lstrcat,edi,offset szChangeFolder
				invoke lstrlen,edi
				lea edi,[edi + eax + 1]
				inc ebx
				dec iCount
			.until sign?
			mov al,0
			stosb
			invoke GetParent,hWnd
			invoke PostMessage,eax,PSM_SETCURSELID,0,IDD_PAGE4
			jmp @B
		.endif
	.elseif eax == WM_COMMAND
		mov eax,wParam
		.if eax == ID_CONTEXT_REMOVE
			.repeat
				invoke SendDlgItemMessage,hWnd,IDC_LIST3,LVM_GETNEXTITEM,-1,LVNI_SELECTED
				.break .if eax == -1
				invoke SendDlgItemMessage,hWnd,IDC_LIST3,LVM_DELETEITEM,eax,0
			.until eax == FALSE
		.elseif eax == IDC_BUTTON3
			mov szChangeFolder[0],0
			invoke GetOpenFileName,offset ofn
			.if eax
				invoke SendDlgItemMessage,hWnd,IDC_LIST3,LVM_GETITEMCOUNT,0,0
				mov tlvi.iItem,eax
				mov esi,offset szChangeFolder
				mov edi,offset szChangeFolder
				invoke lstrlen,esi
				inc eax
				movzx edx,ofn.nFileOffset
				.if eax != edx
					add esi,edx
					mov byte ptr [esi - 1],0
				.else
					add esi,eax
				.endif
				.while byte ptr [esi] != 0
					inc tlvi.iItem
					mov tlvi.iSubItem,0
					invoke lstrlen,esi
					push eax
					invoke lstrlen,edi
					pop edx
					add eax,edx
					add eax,2
					invoke LocalAlloc,LPTR,eax
					.if eax
						xchg ebx,eax
						invoke lstrcpy,ebx,edi
						invoke PathAddBackslash,ebx
						invoke lstrcat,ebx,esi
						invoke PathFileExists,ebx
						.if eax
							mov tlvi.imask,LVIF_TEXT or LVIF_IMAGE
							mov tlvi.pszText,esi
							mov tlvi.iImage,4
							invoke PathFindExtension,ebx
							.if eax
								push esi
								xchg esi,eax
								.repeat
									mov tlvi.iImage,0					;0: ASM
									invoke lstrcmpi,esi,offset szDotAsm
									.break .if eax == 0
									inc tlvi.iImage						;1: INC
									invoke lstrcmpi,esi,offset szDotInc
									.break .if eax == 0
									inc tlvi.iImage						;2: RC
									invoke lstrcmpi,esi,offset szDotRc
									.break .if eax == 0
									inc tlvi.iImage						;3: TXT
									invoke lstrcmpi,esi,offset szDotTxt
									.break .if eax == 0
									mov tlvi.iImage,5					;5: DEF
									invoke lstrcmpi,esi,offset szDotDef
									.break .if eax == 0
									inc tlvi.iImage						;6: BAT
									invoke lstrcmpi,esi,offset szDotBat
									.break .if eax == 0
									mov tlvi.iImage,4					;4: Other
								.until TRUE
								pop esi
							.endif
							invoke SendDlgItemMessage,hWnd,IDC_LIST3,LVM_INSERTITEM,0,addr tlvi
							.if eax != -1
								mov tlvi.imask,LVIF_TEXT
								mov tlvi.iItem,eax
								inc tlvi.iSubItem
								mov tlvi.pszText,edi
								invoke SendDlgItemMessage,hWnd,IDC_LIST3,LVM_SETITEM,0,addr tlvi
							.endif
						.endif
						invoke LocalFree,ebx
					.endif
					invoke lstrlen,esi
					lea esi,[esi + eax + 1]
				.endw
			.endif
		.endif
	.elseif eax == WM_INITDIALOG
		IFDEF DEBUG_BUILD
			PrintText "Initializing IDD_PAGE3_3"
		ENDIF
		push hWnd
		pop ofn.hwndOwner
		invoke SendDlgItemMessage,hWnd,IDC_LIST3,LVM_SETEXTENDEDLISTVIEWSTYLE,
					LVS_EX_GRIDLINES or LVS_EX_FULLROWSELECT or LVS_EX_FLATSB,
					LVS_EX_GRIDLINES or LVS_EX_FULLROWSELECT or LVS_EX_FLATSB
		invoke ImageList_LoadImage,psp33.hInstance,IDB_BITMAP6,16,7,00FF00FFh,IMAGE_BITMAP,LR_CREATEDIBSECTION
		invoke SendDlgItemMessage,hWnd,IDC_LIST3,LVM_SETIMAGELIST,LVSIL_SMALL,eax
		invoke SendDlgItemMessage,hWnd,IDC_LIST3,LVM_INSERTCOLUMN,0,offset lvc30
		invoke SendDlgItemMessage,hWnd,IDC_LIST3,LVM_INSERTCOLUMN,1,offset lvc31
	.endif
	xor eax,eax
	ret
	
DlgProc33 endp

; Page 3 - clone project - select target folder
align DWORD
DlgProc34 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local hFind				:DWORD
	local tvc				:TVINSERTSTRUCT
	local buffer[MAX_PATH]	:BYTE
	local currdir[MAX_PATH]	:BYTE
	local w32fd				:WIN32_FIND_DATA
	
	mov eax,uMsg
	.if eax == WM_NOTIFY
		mov edx,lParam
		mov eax,[edx].NMHDR.code
		.if eax == TVN_SELCHANGING
			invoke GetTreePath,hWnd,IDC_TREE5,[edx].NMTREEVIEW.itemNew.hItem
			invoke SetDlgItemText,hWnd,IDC_EDIT12,offset szChangeFolder
		.elseif eax == TVN_ITEMEXPANDING
			mov eax,[edx].NMTREEVIEW.action
			.if eax == TVE_COLLAPSE
				mov eax,[edx].NMTREEVIEW.itemNew.hItem
				mov tvc.item.hItem,eax
				mov tvc.item._mask,TVIF_HANDLE
				invoke LoadCursor,NULL,IDC_WAIT
				invoke SetCursor,eax
				push eax
				invoke GetTreePath,hWnd,IDC_TREE5,tvc.item.hItem
				invoke SHGetFileInfo,offset szChangeFolder,0,offset shfi,sizeof shfi,
				 			SHGFI_SELECTED or SHGFI_SMALLICON or SHGFI_SYSICONINDEX
				.if eax
					push shfi.iIcon
					or tvc.item._mask,TVIF_SELECTEDIMAGE
					pop tvc.item.iSelectedImage
				.endif
				invoke SHGetFileInfo,offset szChangeFolder,0,offset shfi,sizeof shfi,
				 			SHGFI_SMALLICON or SHGFI_SYSICONINDEX
				.if eax
					push shfi.iIcon
					or tvc.item._mask,TVIF_IMAGE
					pop tvc.item.iImage
				.endif
				.if tvc.item._mask != TVIF_HANDLE
					invoke SendDlgItemMessage,hWnd,IDC_TREE5,TVM_SETITEM,0,addr tvc.item
				.endif
				invoke SendDlgItemMessage,hWnd,IDC_TREE5,TVM_EXPAND,
				 						TVE_COLLAPSE or TVE_COLLAPSERESET,tvc.item.hItem
				call SetCursor
			.elseif eax == TVE_EXPAND
				mov eax,[edx].NMTREEVIEW.itemNew.hItem
				mov tvc.item._mask,TVIF_HANDLE
				mov tvc.item.hItem,eax
				invoke LoadCursor,NULL,IDC_WAIT
				invoke SetCursor,eax
				push eax
				invoke GetTreePath,hWnd,IDC_TREE5,tvc.item.hItem
				invoke SHGetFileInfo,offset szChangeFolder,0,offset shfi,sizeof shfi,
				 			SHGFI_OPENICON or SHGFI_SELECTED or SHGFI_SMALLICON or SHGFI_SYSICONINDEX
				.if eax
					push shfi.iIcon
					or tvc.item._mask,TVIF_SELECTEDIMAGE
					pop tvc.item.iSelectedImage
				.endif
				invoke SHGetFileInfo,offset szChangeFolder,0,offset shfi,sizeof shfi,
				 			SHGFI_OPENICON or SHGFI_SMALLICON or SHGFI_SYSICONINDEX
				.if eax
					push shfi.iIcon
					or tvc.item._mask,TVIF_IMAGE
					pop tvc.item.iImage
				.endif
				.if tvc.item._mask != TVIF_HANDLE
					invoke SendDlgItemMessage,hWnd,IDC_TREE5,TVM_SETITEM,0,addr tvc.item
				.endif
				invoke ExpandTreeFolder,hWnd,IDC_TREE5,tvc.item.hItem
				call SetCursor
			.endif
		.elseif eax == PSN_SETACTIVE
			invoke GetDrives,hWnd,IDC_TREE5
			.if szTargetFolder[0] == 0
				invoke lstrcpy,offset szTargetFolder,offset szDefProjectFolder
			.endif
			invoke SetDlgItemText,hWnd,IDC_EDIT12,offset szTargetFolder
			invoke GetParent,hWnd
			invoke PostMessage,eax,PSM_SETWIZBUTTONS,0,PSWIZB_BACK or PSWIZB_NEXT
			;invoke GetDlgItem,hWnd,IDC_BUTTON20
			;invoke PostMessage,hWnd,WM_COMMAND,IDC_BUTTON20,eax
		.elseif eax == PSN_KILLACTIVE
			invoke GetDlgItem,hWnd,IDC_TREE5
			push TVI_ROOT
			push 0
			push TVM_DELETEITEM
			push eax
			invoke LockWindowUpdate,eax
			call SendMessage
			invoke LockWindowUpdate,NULL
		.elseif eax == PSN_WIZBACK
			invoke GetParent,hWnd
			invoke PostMessage,eax,PSM_SETCURSELID,0,IDD_PAGE2_4
@@:			invoke SetWindowLong,hWnd,DWL_MSGRESULT,-1
			push TRUE
			pop eax
			ret
		.elseif eax == PSN_WIZNEXT
			invoke GetDlgItemText,hWnd,IDC_EDIT12,offset szTargetFolder,sizeof szTargetFolder
			test eax,eax
			jz @B
			cmp szTargetFolder[0],0
			je @B
			invoke PathRemoveBackslash,offset szTargetFolder
			invoke PathIsDirectory,offset szTargetFolder
			.if !eax
				invoke CreateDirectory,offset szTargetFolder,NULL
				test eax,eax
				jz @B
				invoke PathIsDirectory,offset szTargetFolder
				test eax,eax
				jz @B
			.endif
			invoke lstrcpyn,addr buffer,offset szTargetFolder,sizeof buffer - sizeof szMaskAll
			invoke PathAddBackslash,addr buffer
			invoke lstrcat,addr buffer,offset szMaskAll
			invoke FindFirstFile,addr buffer,addr w32fd
			.if !eax
				invoke MessageBox,
					hWnd,offset szTFNotExist,
					offset szWarning,MB_YESNO or MB_ICONWARNING
				cmp eax,IDYES
				jne @B
			.endif
			mov hFind,eax
			.repeat
				mov eax,dword ptr w32fd.cFileName
				and eax,00FFFFFFh
				.if (eax != '..') && (ax != '.')
					invoke MessageBox,
						hWnd,offset szTFNotEmpty,
						offset szWarning,MB_YESNO or MB_ICONWARNING
					.break .if eax == IDYES
					invoke FindClose,hFind
					jmp @B
				.endif
				invoke FindNextFile,hFind,addr w32fd
			.until !eax
			invoke FindClose,hFind
		.endif
	.elseif eax == WM_COMMAND
		mov eax,wParam
		.if eax == IDC_BUTTON20
			invoke GetDlgItemText,hWnd,IDC_EDIT12,offset szChangeFolder,sizeof szChangeFolder
			.if eax
				invoke GetFullPathName,offset szChangeFolder,sizeof szChangeFolder,
										offset szChangeFolder,addr tvc.hParent
				invoke ExpandTreePath,hWnd,IDC_TREE5
			.endif
		.elseif eax == IDC_BUTTON21
			mov currdir,0
			invoke GetCurrentDirectory,sizeof currdir,addr currdir
			invoke GetDlgItemText,hWnd,IDC_EDIT12,addr buffer,sizeof buffer
			.if eax && (buffer[0] != 0)
				invoke SendDlgItemMessage,hWnd,IDC_TREE5,TVM_GETNEXTITEM,TVGN_CARET,TVI_ROOT
				.if eax
					invoke GetTreePath,hWnd,IDC_TREE5,eax
					invoke SetCurrentDirectory,offset szChangeFolder
				.else
					invoke lstrcpy,offset szChangeFolder,addr currdir
				.endif
				invoke ExpandTreePath,hWnd,IDC_TREE5
				invoke GetFullPathName,addr buffer,sizeof buffer,addr buffer,addr tvc.hParent
				push eax
				invoke SetCurrentDirectory,addr currdir
				pop eax
				.if eax
					invoke CreateDirectory,addr buffer,NULL
					.if eax
						invoke GetDlgItem,hWnd,IDC_TREE5
						invoke LockWindowUpdate,eax
						invoke SendDlgItemMessage,hWnd,IDC_TREE5,TVM_DELETEITEM,0,TVI_ROOT
						.if eax
							invoke GetDrives,hWnd,IDC_TREE5
							invoke lstrcpy,offset szChangeFolder,addr buffer
							invoke ExpandTreePath,hWnd,IDC_TREE5
						.endif
						invoke LockWindowUpdate,NULL
					.endif
				.endif
			.endif
		.endif
	.elseif eax == WM_INITDIALOG
		IFDEF DEBUG_BUILD
			PrintText "Initializing IDD_PAGE3_4"
		ENDIF
		.if !hSysSmIml
			invoke GetModuleHandle,offset szShell32		;should already be loaded...
			.if eax
				push 71
				push eax
				invoke GetProcAddress,eax,660	;FileIconInit (NT, 2K, XP)
				.if eax
					push TRUE
					call eax
				.endif
				call GetProcAddress				;Shell_GetImageLists (all)
				.if eax
					push offset hSysSmIml
					push offset hSysIml
					call eax
				.endif
			.endif
		.endif
		invoke SendDlgItemMessage,hWnd,IDC_TREE5,TVM_SETIMAGELIST,TVSIL_NORMAL,hSysSmIml
		invoke LoadImage,psp32.hInstance,IDB_BITMAP7,IMAGE_BITMAP,0,0,LR_CREATEDIBSECTION or LR_LOADMAP3DCOLORS or LR_LOADTRANSPARENT
		invoke SendDlgItemMessage,hWnd,IDC_BUTTON20,BM_SETIMAGE,IMAGE_BITMAP,eax
		invoke LoadImage,psp32.hInstance,IDB_BITMAP8,IMAGE_BITMAP,0,0,LR_CREATEDIBSECTION or LR_LOADMAP3DCOLORS or LR_LOADTRANSPARENT
		invoke SendDlgItemMessage,hWnd,IDC_BUTTON21,BM_SETIMAGE,IMAGE_BITMAP,eax
		invoke SendDlgItemMessage,hWnd,IDC_EDIT12,EM_SETLIMITTEXT,sizeof szTargetFolder,0
		.if szTargetFolder[0] != 0
			invoke PathRelativePathTo,offset szChangeFolder,
			 		offset szDefProjectFolder,FILE_ATTRIBUTE_DIRECTORY,
			 		offset szTargetFolder,FILE_ATTRIBUTE_DIRECTORY
			.if eax
				cmp szChangeFolder[0],'.'
				jne @F
			.endif
			push offset szTargetFolder
		.else
	@@:		push offset szDefProjectFolder
		.endif
		push IDC_EDIT12
		push hWnd
		call SetDlgItemText
	.elseif eax == WM_DESTROY
		invoke SendDlgItemMessage,hWnd,IDC_TREE5,TVM_SETIMAGELIST,TVSIL_NORMAL,NULL
		invoke SendDlgItemMessage,hWnd,IDC_BUTTON20,BM_SETIMAGE,IMAGE_BITMAP,0
		invoke DeleteObject,eax
		invoke SendDlgItemMessage,hWnd,IDC_BUTTON21,BM_SETIMAGE,IMAGE_BITMAP,0
		invoke DeleteObject,eax
	.endif
	xor eax,eax
	ret
	
DlgProc34 endp

; Page 4 - quit
align DWORD
DlgProc4 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local temp1:DWORD
	local temp2:DWORD
	
	mov eax,uMsg
	.if eax == WM_NOTIFY
		mov edx,lParam
		mov eax,[edx].NMHDR.code
		.if eax == PSN_SETACTIVE
			mov eax,dwWizChoice
			.if eax == IDD_PAGE2_3
				mov szTargetTitle[0],0
				invoke SetDlgItemText,hWnd,IDC_EDIT11,offset szNewProjectTitle
				push TRUE	;IDC_CHECK1 is meaningful for IDD_PAGE2_3
				push FALSE	;IDC_EDIT11 is meaningless for IDD_PAGE2_3
			.else
				; Creating a project from a template, or cloning an existing project...
				mov szChangeFolder[0],0
				invoke GetDlgItemText,hWnd,IDC_EDIT11,offset szChangeFolder,sizeof szChangeFolder
				mov temp1,FALSE
				cmp szChangeFolder[0],0
				je @F
				invoke lstrcmpi,offset szTargetTitle,offset szChangeFolder
				.if eax == 0
			@@:		mov temp1,TRUE
				.endif
				invoke lstrcpy,offset szTargetWap,offset szTargetFolder
				mov eax,offset szTargetFolder
				.repeat
					mov temp2,eax
					invoke PathFindNextComponent,eax
				.until !eax || byte ptr [eax] == 0
				invoke lstrcpy,offset szTargetTitle,temp2
				invoke PathAppend,offset szTargetWap,eax
				.if temp1
					invoke SetDlgItemText,hWnd,IDC_EDIT11,offset szTargetTitle
				.endif
				push FALSE	;IDC_CHECK1 is meaningless for IDD_PAGE2_2 and IDD_PAGE2_4
				push TRUE	;IDC_EDIT11 is meaningful for IDD_PAGE2_2 and IDD_PAGE2_4
			.endif
			invoke GetDlgItem,hWnd,IDC_EDIT11
			push eax
			call EnableWindow
			invoke GetDlgItem,hWnd,IDC_CHECK1
			push eax
			call EnableWindow
			invoke GetParent,hWnd
			invoke PostMessage,eax,PSM_SETWIZBUTTONS,0,PSWIZB_BACK or PSWIZB_FINISH
		.elseif eax == PSN_WIZBACK
			mov edx,dwWizChoice
			.if edx == IDD_PAGE2_2
				mov edx,IDD_PAGE3_2
			.elseif edx == IDD_PAGE2_3
				invoke SetDlgItemText,hWnd,IDC_EDIT11,offset szNull
				mov edx,IDD_PAGE3_3
			.else;if edx == IDD_PAGE2_4
				mov edx,IDD_PAGE3_4
			.endif
			push edx
			push 0
			push PSM_SETCURSELID
			invoke GetParent,hWnd
			push eax
			call PostMessage
			invoke SetWindowLong,hWnd,DWL_MSGRESULT,-1
			push TRUE
			pop eax
			ret
		.elseif eax == PSN_WIZFINISH
			mov bDoIt,TRUE
			mov eax,dwWizChoice
			.if (eax == IDD_PAGE2_2) || (eax == IDD_PAGE2_4)
				mov szTargetTitle[0],0
				invoke GetDlgItemText,hWnd,IDC_EDIT11,offset szTargetTitle,sizeof szTargetTitle
				.if szTargetTitle[0] != 0
					; Re-parse szTargetWap from szTargetTitle
					invoke PathFindFileName,offset szTargetWap
					invoke lstrcpy,eax,offset szTargetTitle
					invoke PathAddExtension,offset szTargetWap,offset szDotWap
				.else
					; Re-parse szTargetTitle from szTargetWap
					invoke PathFindFileName,offset szTargetWap
					invoke lstrcpy,offset szTargetTitle,eax
					invoke PathRemoveExtension,eax
				.endif
			.endif
			invoke IsDlgButtonChecked,hWnd,IDC_CHECK1
			mov bSaveWap,eax
			invoke IsDlgButtonChecked,hWnd,IDC_CHECK2
			mov bGoAll,eax
			invoke IsDlgButtonChecked,hWnd,IDC_CHECK3
			mov bRemember,eax
			invoke SaveLastTakenChoices
			invoke SetCurrentDirectory,offset szGlobalCurrDir
		.endif
	.elseif eax == WM_INITDIALOG
		IFDEF DEBUG_BUILD
			PrintText "Initializing IDD_PAGE4"
		ENDIF
		mov szTargetTitle[0],0
		invoke CheckDlgButton,hWnd,IDC_CHECK1,bSaveWap
		invoke CheckDlgButton,hWnd,IDC_CHECK2,bGoAll
		invoke CheckDlgButton,hWnd,IDC_CHECK3,bRemember
		invoke SendDlgItemMessage,hWnd,IDC_EDIT11,EM_SETLIMITTEXT,sizeof szTargetTitle,0
	.endif
	xor eax,eax
	ret
	
DlgProc4 endp

; Project property sheet, page 1 (Build)
align DWORD
PropDlgProc1 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
	mov eax,uMsg
	.if eax == WM_NOTIFY
		mov edx,lParam
		.if [edx].NMHDR.code == PSN_APPLY
			mov edx,cpi.pbModified
			mov dword ptr [edx],TRUE
			invoke SendDlgItemMessage,hWnd,IDC_COMBO1,CB_GETCURSEL,0,0
			mov edx,cpi.pProjectType
			and eax,7
			mov [edx],eax
			invoke BuildCmdsFromEdit,hWnd
		.endif
	.elseif eax == WM_COMMAND
		mov eax,wParam
		mov edx,eax
		and eax,0FFFFh
		shr edx,16
		.if zero?	;BN_CLICKED
			.if eax == IDC_BUTTON4									;Load defaults
				invoke SendDlgItemMessage,hWnd,IDC_COMBO1,CB_GETCURSEL,0,0
				mov dwProjectType,eax
				invoke GetDefBuildCmds
				invoke DefBuildCmdsToEdit,hWnd
			.elseif eax == IDC_BUTTON5								;Save defaults
				invoke SendDlgItemMessage,hWnd,IDC_COMBO1,CB_GETCURSEL,0,0
				mov dwProjectType,eax
				invoke DefBuildCmdsFromEdit,hWnd
				invoke WriteDefBuildCmds
			.elseif (eax >= IDC_BUTTON6) && (eax <= IDC_BUTTON13)	;Other buttons
				add eax,IDC_EDIT3 - IDC_BUTTON6
				.if (eax == IDC_EDIT7) || (eax == IDC_EDIT10)
					push hWnd
					pop outofn.hwndOwner
					mov szGlobalCurrDir[0],0
					invoke GetCurrentDirectory,sizeof szGlobalCurrDir,offset szGlobalCurrDir
					invoke GetOpenFileName,offset outofn
					.if eax
						mov eax,wParam
						add eax,IDC_EDIT3 - IDC_BUTTON6
						invoke SetDlgItemText,hWnd,eax,offset szChangeFolder
					.endif
					invoke SetCurrentDirectory,offset szGlobalCurrDir
				.else
					invoke DialogBoxParam,projp1.hInstance,IDD_DIALOG1,hWnd,offset SwitchProc,eax
				.endif
			.endif
		.elseif edx == CBN_SELCHANGE
			invoke SendDlgItemMessage,hWnd,IDC_COMBO1,CB_GETCURSEL,0,0
			and eax,1
			xor eax,1
			invoke EnableWindow,hProjPropPage2,eax
		.endif
	.elseif eax == WM_DESTROY
		push ebx
		mov ebx,IDC_BUTTON4
		.repeat
			invoke SendDlgItemMessage,hWnd,ebx,BM_SETIMAGE,IMAGE_ICON,NULL
			invoke DestroyIcon,eax
			inc ebx
		.until ebx > IDC_BUTTON13
		pop ebx
	.elseif eax == WM_INITDIALOG
		push hWnd
		pop hProjPropPage1
		push ebx
		push esi
		invoke GetParent,hWnd
		.if eax
			invoke CenterWindow,eax
		.endif
		invoke LoadImage,projp1.hInstance,IDI_ICON2,IMAGE_ICON,0,0,LR_CREATEDIBSECTION
		invoke SendDlgItemMessage,hWnd,IDC_BUTTON4,BM_SETIMAGE,IMAGE_ICON,eax
		invoke LoadImage,projp1.hInstance,IDI_ICON3,IMAGE_ICON,0,0,LR_CREATEDIBSECTION
		invoke SendDlgItemMessage,hWnd,IDC_BUTTON5,BM_SETIMAGE,IMAGE_ICON,eax
		invoke LoadImage,projp1.hInstance,IDI_ICON4,IMAGE_ICON,0,0,LR_CREATEDIBSECTION
		xchg ebx,eax
		mov esi,IDC_BUTTON6
		.repeat
			invoke SendDlgItemMessage,hWnd,esi,BM_SETIMAGE,IMAGE_ICON,ebx
			inc esi
		.until esi > IDC_BUTTON12
		invoke LoadImage,projp1.hInstance,IDI_ICON2,IMAGE_ICON,0,0,LR_CREATEDIBSECTION
		xchg ebx,eax
		invoke SendDlgItemMessage,hWnd,IDC_BUTTON10,BM_SETIMAGE,IMAGE_ICON,ebx
		invoke SendDlgItemMessage,hWnd,IDC_BUTTON13,BM_SETIMAGE,IMAGE_ICON,ebx
		mov esi,IDC_EDIT3
		.repeat
			invoke SendDlgItemMessage,hWnd,esi,EM_SETLIMITTEXT,MAX_PATH,0
			inc esi
		.until esi > IDC_EDIT10
		invoke GetDlgItem,hWnd,IDC_COMBO1
		xchg eax,ebx
		invoke SendMessage,ebx,CB_ADDSTRING,0,offset szType0
		invoke SendMessage,ebx,CB_ADDSTRING,0,offset szType1
		invoke SendMessage,ebx,CB_ADDSTRING,0,offset szType2
		invoke SendMessage,ebx,CB_ADDSTRING,0,offset szType3
		invoke SendMessage,ebx,CB_ADDSTRING,0,offset szType4
		invoke SendMessage,ebx,CB_ADDSTRING,0,offset szType5
		invoke SendMessage,ebx,CB_ADDSTRING,0,offset szType6
		mov eax,cpi.pProjectType
		invoke SendMessage,ebx,CB_SETCURSEL,dword ptr [eax],0
		invoke BuildCmdsToEdit,hWnd
		pop esi
		pop ebx
		push 1
		pop eax
		jmp short @F
	.endif
	xor eax,eax
@@:	ret
	
PropDlgProc1 endp

; Project property sheet, page 2 (Run)
align DWORD
PropDlgProc2 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
	mov eax,uMsg
	.if eax == WM_NOTIFY
		mov edx,lParam
		.if [edx].NMHDR.code == PSN_APPLY
			mov eax,cpi.pszReleaseCommandLine
			.if eax
				invoke SendDlgItemMessage,hWnd,IDC_COMBO2,WM_GETTEXT,MAX_PATH,eax
			.endif
			mov eax,cpi.pszDebugCommandLine
			.if eax
				invoke SendDlgItemMessage,hWnd,IDC_COMBO3,WM_GETTEXT,MAX_PATH,eax
			.endif
			.if bProjHasFilename
				push ebx
				push esi
				push edi
				invoke SendDlgItemMessage,hWnd,IDC_COMBO2,CB_GETCOUNT,0,0
				xchg ebx,eax
				.if ebx != CB_ERR
					xor esi,esi
					xor edi,edi
					test ebx,ebx
					.while !zero?
						invoke wsprintf,offset szReleaseCmdNum,offset szFmtInt,edi
						invoke SendDlgItemMessage,hWnd,IDC_COMBO2,CB_GETLBTEXTLEN,esi,0
						.if eax < MAX_PATH
							invoke SendDlgItemMessage,hWnd,IDC_COMBO2,CB_GETLBTEXT,
								esi,offset szChangeFolder
							.if eax && (eax != CB_ERR)
								invoke WritePrivateProfileString,
									offset szCmdHistory,offset szReleaseCmd,
									offset szChangeFolder,cpi.pszFullProjectName
								.if eax
									add edi,1
								.endif
							.endif
						.endif
						add esi,1
						sub ebx,1
					.endw
				.endif
				invoke SendDlgItemMessage,hWnd,IDC_COMBO3,CB_GETCOUNT,0,0
				xchg ebx,eax
				.if ebx != CB_ERR
					xor esi,esi
					xor edi,edi
					test ebx,ebx
					.while !zero?
						invoke wsprintf,offset szDebugCmdNum,offset szFmtInt,edi
						invoke SendDlgItemMessage,hWnd,IDC_COMBO3,CB_GETLBTEXTLEN,esi,0
						.if eax < MAX_PATH
							invoke SendDlgItemMessage,hWnd,IDC_COMBO3,CB_GETLBTEXT,
								esi,offset szChangeFolder
							.if eax && (eax != CB_ERR)
								invoke WritePrivateProfileString,
									offset szCmdHistory,offset szDebugCmd,
									offset szChangeFolder,cpi.pszFullProjectName
								.if eax
									add edi,1
								.endif
							.endif
						.endif
						add esi,1
						sub ebx,1
					.endw
				.endif
				pop edi
				pop esi
				pop ebx
			.endif
		.endif
	.elseif eax == WM_ENABLE
		invoke EnumChildWindows,hWnd,offset EnableChildCallback,wParam
	.elseif eax == WM_COMMAND
		mov eax,wParam
		test eax,0FFFF0000h
		.if zero?	;BN_CLICKED
			.if eax == IDC_BUTTON14									;Release: Add to list
				invoke SendDlgItemMessage,hWnd,IDC_COMBO2,
					WM_GETTEXT,MAX_PATH,offset szChangeFolder
				.if eax
					invoke SendDlgItemMessage,hWnd,IDC_COMBO2,
						CB_FINDSTRINGEXACT,-1,offset szChangeFolder
					.if eax == CB_ERR
						invoke SendDlgItemMessage,hWnd,IDC_COMBO2,
							CB_ADDSTRING,0,offset szChangeFolder
					.endif
				.endif
			.elseif eax == IDC_BUTTON15								;Release: Remove from list
				invoke SendDlgItemMessage,hWnd,IDC_COMBO2,
					WM_GETTEXT,MAX_PATH,offset szChangeFolder
				.if eax
					invoke SendDlgItemMessage,hWnd,IDC_COMBO2,
						CB_FINDSTRINGEXACT,-1,offset szChangeFolder
					.if eax != CB_ERR
						invoke SendDlgItemMessage,hWnd,IDC_COMBO2,
							CB_DELETESTRING,eax,0
					.endif
				.endif
			.elseif eax == IDC_BUTTON16								;Debug: Add to list
				invoke SendDlgItemMessage,hWnd,IDC_COMBO3,
					WM_GETTEXT,MAX_PATH,offset szChangeFolder
				.if eax
					invoke SendDlgItemMessage,hWnd,IDC_COMBO3,
						CB_FINDSTRINGEXACT,-1,offset szChangeFolder
					.if eax == CB_ERR
						invoke SendDlgItemMessage,hWnd,IDC_COMBO3,
							CB_ADDSTRING,0,offset szChangeFolder
					.endif
				.endif
			.elseif eax == IDC_BUTTON17								;Debug: Remove from list
				invoke SendDlgItemMessage,hWnd,IDC_COMBO3,
					WM_GETTEXT,MAX_PATH,offset szChangeFolder
				.if eax
					invoke SendDlgItemMessage,hWnd,IDC_COMBO3,
						CB_FINDSTRINGEXACT,-1,offset szChangeFolder
					.if eax != CB_ERR
						invoke SendDlgItemMessage,hWnd,IDC_COMBO3,
							CB_DELETESTRING,eax,0
					.endif
				.endif
			.endif
		.endif
	.elseif eax == WM_DESTROY
		push ebx
		mov ebx,IDC_BUTTON14
		.repeat
			invoke SendDlgItemMessage,hWnd,ebx,BM_SETIMAGE,IMAGE_ICON,NULL
			invoke DestroyIcon,eax
			inc ebx
		.until ebx > IDC_BUTTON17
		pop ebx
	.elseif eax == WM_INITDIALOG
		push hWnd
		pop hProjPropPage2
		invoke LoadImage,projp2.hInstance,IDI_ICON5,IMAGE_ICON,0,0,LR_CREATEDIBSECTION
		push eax
		push IMAGE_ICON
		push BM_SETIMAGE
		push IDC_BUTTON16
		push hWnd
		invoke SendDlgItemMessage,hWnd,IDC_BUTTON14,BM_SETIMAGE,IMAGE_ICON,eax
		call SendDlgItemMessage
		invoke LoadImage,projp2.hInstance,IDI_ICON6,IMAGE_ICON,0,0,LR_CREATEDIBSECTION
		push eax
		push IMAGE_ICON
		push BM_SETIMAGE
		push IDC_BUTTON17
		push hWnd
		invoke SendDlgItemMessage,hWnd,IDC_BUTTON15,BM_SETIMAGE,IMAGE_ICON,eax
		call SendDlgItemMessage
		invoke SendDlgItemMessage,hWnd,IDC_COMBO2,EM_SETLIMITTEXT,MAX_PATH,0
		invoke SendDlgItemMessage,hWnd,IDC_COMBO3,EM_SETLIMITTEXT,MAX_PATH,0
		invoke SendDlgItemMessage,hWnd,IDC_COMBO2,WM_SETTEXT,0,cpi.pszReleaseCommandLine
		invoke SendDlgItemMessage,hWnd,IDC_COMBO3,WM_SETTEXT,0,cpi.pszDebugCommandLine
		.if bProjHasFilename
			push ebx
			xor ebx,ebx
			.repeat
				invoke wsprintf,offset szReleaseCmdNum,offset szFmtInt,ebx
				invoke GetPrivateProfileString,offset szCmdHistory,offset szReleaseCmd,
					offset szNull,offset szChangeFolder,MAX_PATH,cpi.pszFullProjectName
				.break .if !eax
				invoke SendDlgItemMessage,hWnd,IDC_COMBO2,CB_ADDSTRING,0,offset szChangeFolder
				add ebx,1
			.until FALSE
			xor ebx,ebx
			.repeat
				invoke wsprintf,offset szDebugCmdNum,offset szFmtInt,ebx
				invoke GetPrivateProfileString,offset szCmdHistory,offset szDebugCmd,
					offset szNull,offset szChangeFolder,MAX_PATH,cpi.pszFullProjectName
				.break .if !eax
				invoke SendDlgItemMessage,hWnd,IDC_COMBO3,CB_ADDSTRING,0,offset szChangeFolder
				add ebx,1
			.until FALSE
			pop ebx
		.endif
		mov edx,cpi.pProjectType
		mov eax,[edx]
		and eax,1
		xor eax,1
		invoke EnableWindow,hWnd,eax
		push 1
		pop eax
		jmp short @F
	.endif
	xor eax,eax
@@:	ret
	
PropDlgProc2 endp

; Project property sheet, page 3 (Misc)
align DWORD
PropDlgProc3 proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local buffer[256]:BYTE
	
	mov eax,uMsg
	.if eax == WM_NOTIFY
		mov edx,lParam
		.if [edx].NMHDR.code == PSN_APPLY
			.if bProjHasFilename
				mov buffer[0],0
				invoke GetDlgItemText,hWnd,IDC_COMBO5,addr buffer,sizeof buffer
				push cpi.pszFullProjectName
				.if buffer[0] != 0
					lea eax,buffer
					push eax
				.else
					push NULL
				.endif
				push offset szCompiler
				push offset szPROJECT
				call WritePrivateProfileString
				invoke IsDlgButtonChecked,hWnd,IDC_CHECK10
				and eax,1
				add eax,eax
				add eax,offset sz0
				invoke WritePrivateProfileString,offset szPROJECT,offset szAutoIncFileVersion,eax,cpi.pszFullProjectName
				invoke IsDlgButtonChecked,hWnd,IDC_CHECK11
				and eax,1
				add eax,eax
				add eax,offset sz0
				invoke WritePrivateProfileString,offset szPROJECT,offset szRCSilent,eax,cpi.pszFullProjectName
			.endif
		.endif
	.elseif eax == WM_INITDIALOG
		push hWnd
		pop hProjPropPage3
		invoke SendDlgItemMessage,hWnd,IDC_COMBO5,EM_SETLIMITTEXT,sizeof buffer,0
		invoke SendDlgItemMessage,hWnd,IDC_COMBO5,CB_ADDSTRING,0,offset szMASM32
		invoke SendDlgItemMessage,hWnd,IDC_COMBO5,CB_ADDSTRING,0,offset szFASM
		.if bProjHasFilename
			invoke GetPrivateProfileString,offset szPROJECT,offset szCompiler,offset szMASM32,addr buffer,sizeof buffer,cpi.pszFullProjectName
			invoke SetDlgItemText,hWnd,IDC_COMBO5,addr buffer
			invoke GetPrivateProfileInt,offset szPROJECT,offset szAutoIncFileVersion,FALSE,cpi.pszFullProjectName
			and eax,1
			invoke CheckDlgButton,hWnd,IDC_CHECK10,eax
			invoke GetPrivateProfileInt,offset szPROJECT,offset szRCSilent,FALSE,cpi.pszFullProjectName
			and eax,1
			invoke CheckDlgButton,hWnd,IDC_CHECK11,eax
		.else
			invoke EnableChildCallback,hWnd,FALSE
		.endif
		invoke GetParent,hWnd	;Notify all other addins
		mov edx,pHandles
		invoke SendMessage,[edx].HANDLES.hMain,dwProjPropMsg,eax,NULL	;wParam == hPropSheet
		push TRUE
		pop eax
		jmp short @F
	.endif
	xor eax,eax
@@:	ret
	
PropDlgProc3 endp

; Build command switches popup
align DWORD
SwitchProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local ttvis			:TVINSERTSTRUCT
	
	mov eax,uMsg
	.if eax == WM_NOTIFY
		mov edx,lParam
		.if [edx].NMHDR.idFrom == IDC_TREE3
			mov eax,[edx].NMHDR.code
			.if eax == TVN_ITEMEXPANDING
				push [edx].NMTREEVIEW.itemNew.hItem
				pop ttvis.item.hItem
				mov eax,[edx].NMTREEVIEW.action
				.if eax == TVE_COLLAPSE
					mov ttvis.item.iImage,0
					mov ttvis.item.iSelectedImage,0
					jmp short @F
				.endif
				.if eax == TVE_EXPAND
					mov ttvis.item.iImage,1
					mov ttvis.item.iSelectedImage,1
			@@:		mov ttvis.item._mask,TVIF_HANDLE or TVIF_IMAGE or TVIF_SELECTEDIMAGE
					invoke SendDlgItemMessage,hWnd,IDC_TREE3,TVM_SETITEM,0,addr ttvis.item
				.endif
			.elseif eax == TVN_GETINFOTIP
				mov eax,[edx].NMTVGETINFOTIP.pszText
				.if eax
					mov ecx,[edx].NMTVGETINFOTIP.lParam
					.if ecx && (word ptr [ecx] != 0020h)
						invoke lstrcpyn,eax,ecx,[edx].NMTVGETINFOTIP.cchTextMax
					.endif
				.endif
			.endif
		.endif
	.elseif eax == WM_COMMAND
		mov eax,wParam
		.if eax == IDCANCEL
			invoke EndDialog,hWnd,IDCANCEL
		.elseif eax == IDOK		;Add
			invoke SendDlgItemMessage,hWnd,IDC_TREE3,TVM_GETNEXTITEM,TVGN_CARET,TVI_ROOT
			.if eax
				mov ttvis.item.hItem,eax
				mov ttvis.item._mask,TVIF_HANDLE or TVIF_TEXT
				mov ttvis.item.pszText,offset szTargetTitle
				mov ttvis.item.cchTextMax,sizeof szTargetTitle
				invoke SendDlgItemMessage,hWnd,IDC_TREE3,TVM_GETITEM,0,addr ttvis.item
				test eax,eax
				jz @F
				invoke GetWindowLong,hWnd,DWL_USER
				invoke GetDlgItem,hProjPropPage1,eax
				test eax,eax
				jz @F
				mov ttvis.hParent,eax
				invoke GetWindowText,ttvis.hParent,offset szChangeFolder,sizeof szChangeFolder
				test eax,eax
				jz @F
				invoke lstrcat,offset szChangeFolder,offset szSpace
				invoke lstrcat,offset szChangeFolder,offset szTargetTitle
				invoke SendMessage,ttvis.hParent,EM_GETSEL,addr ttvis.hInsertAfter,addr ttvis.item.lParam
				invoke SetWindowText,ttvis.hParent,offset szChangeFolder
				invoke SendMessage,ttvis.hParent,EM_SETSEL,ttvis.hInsertAfter,ttvis.item.lParam
			.else
		@@:		invoke MessageBeep,-1
			.endif
		.endif
	.elseif eax == WM_INITDIALOG
		invoke SetWindowLong,hWnd,DWL_USER,lParam
		invoke GetDlgItem,hWnd,IDC_TREE3
		.if eax == NULL
			invoke EndDialog,hWnd,-1
			ret
		.endif
		push ebx
		push esi
		xchg ebx,eax
		invoke ImageList_LoadImage,projp1.hInstance,IDB_BITMAP9,16,3,00FF00FFh,IMAGE_BITMAP,LR_CREATEDIBSECTION
		invoke SendMessage,ebx,TVM_SETIMAGELIST,TVSIL_NORMAL,eax
		mov eax,lParam
		.if eax == IDC_EDIT3
			mov esi,offset szCmdSwitches_RC
		.elseif eax == IDC_EDIT4
			mov esi,offset szCmdSwitches_CVTRES
		.elseif (eax == IDC_EDIT5) || (eax == IDC_EDIT8)
			mov esi,offset szCmdSwitches_ML
		.else;if (eax == IDC_EDIT6) || (eax == IDC_EDIT9)
			mov esi,offset szCmdSwitches_LINK
		.endif
		mov ttvis.hInsertAfter,TVI_LAST
		mov ttvis.item._mask,TVIF_CHILDREN or TVIF_IMAGE or TVIF_SELECTEDIMAGE or TVIF_TEXT or TVIF_PARAM
		mov ttvis.item.cchTextMax,0
		mov ttvis.item.cChildren,FALSE
		mov ttvis.item.iImage,2
		mov ttvis.item.iSelectedImage,2
		.repeat
			.if byte ptr [esi] == 9
				inc esi
				mov ttvis.item.pszText,esi
				.if ttvis.hParent == TVI_ROOT
					mov ttvis.item._mask,TVIF_CHILDREN or TVIF_IMAGE or TVIF_HANDLE or TVIF_SELECTEDIMAGE
					mov ttvis.item.cChildren,TRUE
					mov ttvis.item.iImage,0
					mov ttvis.item.iSelectedImage,0
					invoke SendMessage,ebx,TVM_SETITEM,0,addr ttvis.item
					push ttvis.item.hItem
					pop ttvis.hParent
					mov ttvis.item._mask,TVIF_CHILDREN or TVIF_IMAGE or TVIF_SELECTEDIMAGE or TVIF_TEXT or TVIF_PARAM
					mov ttvis.item.cChildren,FALSE
					mov ttvis.item.iImage,2
					mov ttvis.item.iSelectedImage,2
				.endif
			.else
				mov ttvis.hParent,TVI_ROOT
				mov ttvis.item.pszText,esi
				invoke lstrlen,esi
				.break .if eax == 0
				lea esi,[esi + eax + 1]
				mov ttvis.item.lParam,esi
			.endif
			invoke SendMessage,ebx,TVM_INSERTITEM,0,addr ttvis
			mov ttvis.item.hItem,eax
			invoke lstrlen,esi
			.break .if eax == 0
			lea esi,[esi + eax + 1]
		.until FALSE
		invoke SendMessage,ebx,TVM_EXPAND,TVE_EXPAND,TVI_ROOT
		pop esi
		pop ebx
		push 1
		pop eax
		jmp short @F
	.endif
	xor eax,eax
@@:	ret
	
SwitchProc endp

; Add-in's config dialog box
align DWORD
ConfigProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
	mov eax,uMsg
	.if eax == WM_COMMAND
		mov eax,wParam
		cmp eax,IDCANCEL
		je @F
		.if eax == IDOK
			invoke IsDlgButtonChecked,hWnd,IDC_CHECK4
			and eax,BST_CHECKED
			mov bEnableWizard,eax
			add eax,eax
			add eax,offset sz0
			invoke WritePrivateProfileString,offset szAppName,offset szEnableWizard,eax,pIniFile
			invoke IsDlgButtonChecked,hWnd,IDC_CHECK5
			and eax,BST_CHECKED
			mov bEnableProperties,eax
			add eax,eax
			add eax,offset sz0
			invoke WritePrivateProfileString,offset szAppName,offset szEnableProperties,eax,pIniFile
			invoke IsDlgButtonChecked,hWnd,IDC_CHECK6
			and eax,BST_CHECKED
			mov bUseTitleAsOut,eax
			add eax,eax
			add eax,offset sz0
			invoke WritePrivateProfileString,offset szAppName,offset szUseTitleAsOut,eax,pIniFile
	@@:		invoke EndDialog,hWnd,wParam
			push TRUE
			pop eax
			ret
		.endif
	.elseif eax == WM_INITDIALOG
		invoke GetPrivateProfileInt,offset szAppName,offset szEnableWizard,TRUE,pIniFile
		.if eax
			push BST_CHECKED
			pop eax
		.endif
		mov bEnableWizard,eax
		invoke CheckDlgButton,hWnd,IDC_CHECK4,eax
		invoke GetPrivateProfileInt,offset szAppName,offset szEnableProperties,TRUE,pIniFile
		.if eax
			push BST_CHECKED
			pop eax
		.endif
		mov bEnableProperties,eax
		invoke CheckDlgButton,hWnd,IDC_CHECK5,eax
		invoke GetPrivateProfileInt,offset szAppName,offset szUseTitleAsOut,TRUE,pIniFile
		.if eax
			push BST_CHECKED
			pop eax
		.endif
		mov bUseTitleAsOut,eax
		invoke CheckDlgButton,hWnd,IDC_CHECK6,eax
	.endif
	xor eax,eax
	ret
	
ConfigProc endp
