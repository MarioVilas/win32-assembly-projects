.386
.model flat,stdcall
option casemap:none

; Program version string to show in the caption bar.
VERSION_STRING equ <"1.2.2">

; Main header.
include windows.inc

; Some definitions missing in old versions of windows.inc.
IFNDEF TVINSERTSTRUCT
	TVINSERTSTRUCT equ <TV_INSERTSTRUCT>
ENDIF
IFNDEF TVHITTESTINFO
	TVHITTESTINFO equ <TV_HITTESTINFO>
ENDIF
IFNDEF TPM_HORPOSANIMATION
	TPM_HORPOSANIMATION equ 400h
ENDIF
IFNDEF TPM_HORNEGANIMATION
	TPM_HORNEGANIMATION equ 800h
ENDIF
IFNDEF TPM_VERPOSANIMATION
	TPM_VERPOSANIMATION equ 1000h
ENDIF
IFNDEF TPM_VERNEGANIMATION
	TPM_VERNEGANIMATION equ 2000h
ENDIF

; Headers.
include kernel32.inc
include user32.inc
include gdi32.inc
include comctl32.inc
include comdlg32.inc
include shlwapi.inc

; Libraries.
includelib kernel32.lib
includelib user32.lib
includelib gdi32.lib
includelib comctl32.lib
includelib comdlg32.lib
includelib shlwapi.lib

; Prototypes.
AllocBinResLabel	proto pData:PTR BYTE
AllocData			proto pszText:PTR BYTE, dwID:DWORD
AllocDisplayString	proto pData:PTR BYTE
BinaryProc			proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
BuildArray			proto
CalcFontHeight		proto dwPtSize:DWORD
CalcLangHandleAndID	proto dwAbsID:DWORD
CopyLanguage		proto hItem:HTREEITEM, pszText:PTR BYTE, dwID:DWORD
EditStringProc		proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
FindByID			proto hParent:HTREEITEM, dwID:DWORD
FindCorrectLangID	proto dwAbsID:DWORD
FindLangID			proto hItem:HTREEITEM
GetItemID			proto hItem:HTREEITEM
GetMaxLangID		proto
GetMaxRelativeID	proto
InsertItem			proto hParent:HTREEITEM, pszText:PTR BYTE, lParam:LPARAM, iImage:DWORD
IntegrityCheck		proto
IsCaretHere			proto hParent:HTREEITEM
IsChildItem			proto hParent:HTREEITEM, hItem:HTREEITEM
LoadResFile			proto hParent:HWND
LoadUIFile			proto hCtrl:HWND
LoadUIResources		proto hCtrl:HWND
LoadUIStrings		proto hCtrl:HWND
MainProc			proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
NewLangProc			proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
NewStringProc		proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
PickResProc			proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
SaveResFile			proto hParent:HWND
SaveUIData			proto hCtrl:HWND, hParent:HTREEITEM, dwStartingID:DWORD, pTempFile:PTR BYTE
SaveUIFile			proto hCtrl:HWND
ShowContextMenu		proto hWnd:HWND, hMenu:HMENU, xPos:DWORD, yPos:DWORD
Start				proto
VerifyID			proto hItem:HTREEITEM, dwNewID:DWORD

; Resource IDs.
IDI_ICON1			EQU 100
IDB_ICONS			EQU 101
IDM_MENU1			EQU 500

; Main dialog IDs.
IDD_MAIN			EQU 1000
IDC_TREE1			EQU 1001

; New Language dialog IDs.
IDD_NEWLANG			EQU 1100
IDC_EDIT1			EQU 1101
IDC_EDIT2			EQU 1102
IDC_COMBO1			EQU 1103

; Edit Language or String dialog IDs.
IDD_STRING			EQU 1200
IDC_EDIT3			EQU 1201
IDC_EDIT4			EQU 1202
IDC_EDIT5			EQU 1203
IDC_STATIC1			EQU 1204
IDC_STATIC2			EQU 1205
IDC_STATIC3			EQU 1206

; Binary Resource dialog IDs.
IDD_BINARY			EQU 1300
IDC_STATIC4			EQU 1301
IDC_EDIT6			EQU 1302
IDC_BUTTON1			EQU 1303
IDC_BUTTON2			EQU 1304
IDC_EDIT7			EQU 1305

; Pick Resource dialog IDs.
IDD_RESFILE			EQU 1400
IDC_LIST1			EQU 1401
IDC_BUTTON3			EQU 1402

; New String dialog IDs.
IDD_NEWSTRING		EQU 1500
IDC_EDIT8			EQU 1501
IDC_EDIT9			EQU 1502
IDC_STATIC5			EQU 1504
IDC_STATIC6			EQU 1505
IDC_CHECK1			EQU 1506

; Menu item IDs.
ID_FILE_NEW			EQU 10000
ID_FILE_OPEN		EQU 10001
ID_FILE_SAVE		EQU 10002
ID_FILE_SAVEAS		EQU 10003
ID_RES_NEWLANG		EQU 10010
ID_RES_NEWSTRING	EQU 10011
ID_RES_NEWBIN		EQU 10012
ID_RES_EDIT			EQU 10013
ID_RES_DELETE		EQU 10014

; Custom window messages.
WM_UPDATECAPTION	equ WM_USER + 100h
WM_SETINITDIR		equ WM_USER + 101h
WM_PROMPTSAVE		equ WM_USER + 102h
WM_REFRESH			equ WM_USER + 103h

; .RES file header (part 1).
RES_HEADER_1 struct
	
	dwDataSize			DWORD ?
	dwHeaderSize		DWORD ?
	
RES_HEADER_1 ends

; .RES file header (part 2).
RES_HEADER_2 struct
	
	dwDataVersion		DWORD ?
	wFlags				WORD ?
	wLanguage			WORD ?
	dwVersion			DWORD ?
	dwCharacteristics	DWORD ?
	
RES_HEADER_2 ends

.data?
hInst			dd ?
hMain			dd ?
hFont			dd ?

bUseExtraMem	dd ?

bHasName		dd ?
bChanged		dd ?
dwUntitled		dd ?

pArray			dd ?	; Array of language starting IDs.
iArray			dd ?

szFilename		db MAX_PATH dup (?)
szResFile		db MAX_PATH dup (?)
szCustomFilter	db MAX_PATH dup (?)
szInitialDir	db MAX_PATH dup (?)
szCustomFilter2	db MAX_PATH dup (?)
szInitialDir2	db MAX_PATH dup (?)

szSection		db 32767 dup (?)

.data

; RES files signature (32 bytes).
xResSign		dd 0,20h,0FFFFh,0FFFFh,0,0,0,0

; Listview columns for the "Pick resource" dialog (name, type, language, size).
LVC_MASK equ (LVCF_FMT or LVCF_SUBITEM or LVCF_TEXT or LVCF_WIDTH)
lvc0 LVCOLUMN <LVC_MASK,LVCFMT_LEFT,100,offset szName,,0,,>
lvc1 LVCOLUMN <LVC_MASK,LVCFMT_LEFT,100,offset szType,,0,,>
lvc2 LVCOLUMN <LVC_MASK,LVCFMT_LEFT,100,offset szLanguage,,0,,>
lvc3 LVCOLUMN <LVC_MASK,LVCFMT_LEFT,100,offset szSize,,0,,>

;logfont LOGFONT <0,0,0,0,FW_DONTCARE,FALSE,FALSE,FALSE,DEFAULT_CHARSET,OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,\
;	 			DEFAULT_QUALITY,FIXED_PITCH or FF_MODERN,<"Courier New",0>>
logfont LOGFONT <,,,,,,,,,,,,,"Courier New">

; Initialized on runtime: hWndOwner, hInstance and lpstrFile.
ofn1 OPENFILENAME <sizeof OPENFILENAME,,,offset szFilter,offset szCustomFilter,\
	sizeof szCustomFilter,0,,MAX_PATH,NULL,0,offset szInitialDir,NULL,\
	OFN_FILEMUSTEXIST or OFN_HIDEREADONLY>
; Initialized on runtime: hWndOwner and hInstance.
ofn2 OPENFILENAME <sizeof OPENFILENAME,,,offset szFilter,offset szCustomFilter,\
	sizeof szCustomFilter,0,offset szFilename,MAX_PATH,NULL,0,offset szInitialDir,NULL,\
	OFN_HIDEREADONLY or OFN_OVERWRITEPROMPT or OFN_PATHMUSTEXIST,,,offset szDefExt>
; Initialized on runtime: hWndOwner and hInstance.
ofn3 OPENFILENAME <sizeof OPENFILENAME,,,offset szFilter2,offset szCustomFilter2,\
	sizeof szCustomFilter2,0,offset szResFile,sizeof szResFile,NULL,0,offset szInitialDir,\
	NULL,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY>
; Initialized on runtime: hWndOwner and hInstance.
ofn4 OPENFILENAME <sizeof OPENFILENAME,,,offset szFilter2,offset szCustomFilter2,\
	sizeof szCustomFilter2,0,offset szResFile,sizeof szResFile,NULL,0,offset szInitialDir,\
	NULL,OFN_HIDEREADONLY or OFN_OVERWRITEPROMPT or OFN_PATHMUSTEXIST,,,offset szDefExt2>

szCaption0		db "UI File Editor ",VERSION_STRING,0
szCaption1		db " - [ ",0
szCaption2		db " ]",0
szCaption3		db " *",0
szUntitled		db "Untitled %i",0

szFilter		db "UI Language Files (*.ui)",0,	"*.ui",0
	 			db "All Files (*.*)",0,				"*.*",0
	 			db 0
szFilter2		db "Resource (*.res)",0
szSpecRes		db 									"*.res",0
	 			db "Animation (*.avi)",0,			"*.avi",0
	 			db "Bitmap (*.res)",0,				"*.bmp",0
	 			db "Cursor (*.cur)",0,				"*.cur",0
	 			db "Dialog (*.dlg)",0,				"*.dlg",0
	 			db "Icon (*.ico)",0,				"*.ico",0
	 			db "Manifest (*.manifest)",0,		"*.manifest",0
	 			db "XML Script (*.xml)",0,			"*.xml",0
	 			db "Raw Binary Data",0,				"*.bin",0
	 			db "All Files (*.*)",0,				"*.*",0
	 			db 0
szDefExt		db ".ui",0
szDefExt2		db ".res",0

;szNewString		db "New String",0
szDescription	db "Description:",0
szStartingID	db "Starting ID:",0
szEditLang		db "Language Properties",0
szString		db "String:",0
szRelativeID	db "Relative ID:",0
szEditString	db "String Properties",0

szName			db "Name",0
szType			db "Type",0
;szLanguage		db "Language",0
szSize			db "Size",0

szAreYouSure	db "Are you sure?",0
szSaveChanges	db "Changes have been made to the current file. Do you want to save?",0
szDeleteLang	db "Do you want to REMOVE ALL resources for this language?",0
;szDeleteRes 	db "Do you want to REMOVE this resource for ALL languages?",0
szDeleteRes 	db "Deleting resources:",13,10
	 			db "Select YES to remove this resource from ALL languages.",13,10
	 			db "Select NO to remove it only from the CURRENT language.",13,10
	 			db "Select CANCEL to abort the operation.",0

szError			db "Error",0
szSaveHasFailed db "The save operation has failed. The data was NOT saved!",0
szCantReadRes	db "Error reading the specified resource file!",0

szUI			db "UI",0
szFmtInt		db "%i",0
szFmtDispStr	db "{%03i}: %s",0
szFmtBinLabel	db "{%03i}: < %i bytes >",0
szPrefixString	db "UIE",0

szLanguage		db "Language",0
szStrings		db "Strings",0
szResources		db "Resources",0

.code

align DWORD
CalcFontHeight proc dwPtSize:DWORD
	local hWnd:HWND
	local hDC:HDC
	
	invoke GetDesktopWindow
	mov hWnd,eax
	invoke GetDC,eax
	mov hDC,eax
	invoke GetDeviceCaps,eax,LOGPIXELSY
	invoke MulDiv,dwPtSize,eax,72
	push eax
	invoke ReleaseDC,hWnd,hDC
	pop eax
	neg eax
	ret
	
CalcFontHeight endp

align DWORD
ShowContextMenu proc hWnd:HWND, hMenu:HMENU, xPos:DWORD, yPos:DWORD
	local dwFlags:DWORD
	local rect:RECT
	
	; Get the main window rectangle.
	invoke GetWindowRect,hWnd,addr rect
	
	; Default flags for TrackPopupMenuEx.
	mov dwFlags,TPM_RIGHTBUTTON
	
	; Decide horizontal alignment and animation.
	mov eax,rect.right
	mov edx,rect.left
	neg eax
	sub edx,xPos
	add eax,xPos
	.if (SDWORD ptr eax) < (SDWORD ptr edx)
		or dwFlags,TPM_LEFTALIGN or TPM_HORPOSANIMATION
	.else
		or dwFlags,TPM_RIGHTALIGN or TPM_HORNEGANIMATION
	.endif
	
	; Decide vertical alignment and animation.
	mov eax,rect.bottom
	mov edx,rect.top
	neg eax
	sub edx,yPos
	add eax,yPos
	.if (SDWORD ptr eax) < (SDWORD ptr edx)
		or dwFlags,TPM_TOPALIGN or TPM_VERPOSANIMATION
	.else
		or dwFlags,TPM_BOTTOMALIGN or TPM_VERNEGANIMATION
	.endif
	
	; Show the context menu.
	invoke TrackPopupMenuEx,hMenu,dwFlags,xPos,yPos,hWnd,NULL
	ret
	
ShowContextMenu endp

align DWORD
IsChildItem proc hParent:HTREEITEM, hItem:HTREEITEM
	
	mov eax,hParent
	.if eax != hItem
		invoke SendDlgItemMessage,hMain,IDC_TREE1,TVM_GETNEXTITEM,TVGN_CHILD,eax
		.while eax
			cmp eax,hItem
			je short @F
			invoke SendDlgItemMessage,hMain,IDC_TREE1,TVM_GETNEXTITEM,TVGN_NEXT,eax
		.endw
	.else
@@:		push TRUE
		pop eax
	.endif
	ret
	
IsChildItem endp

align DWORD
IsCaretHere proc hParent:HTREEITEM
	
	invoke SendDlgItemMessage,hMain,IDC_TREE1,TVM_GETNEXTITEM,TVGN_CARET,TVI_ROOT
	.if eax
		invoke IsChildItem,hParent,eax
	.endif
	ret
	
IsCaretHere endp

align DWORD
BuildArray proc uses ebx edi
	local hCtrl	:HWND
	local tvi	:TVITEM
	
	; On entry:
	;	pArray == NULL
	;	iArray == Desired array element count, zero for automatic
	; No return value.
	
	; Get the treeview handle.
	invoke GetDlgItem,hMain,IDC_TREE1
	mov hCtrl,eax
	
	; Count the number of languages.
	.if iArray == 0
		invoke SendMessage,hCtrl,TVM_GETNEXTITEM,TVGN_CHILD,TVI_ROOT
		.while eax
			inc iArray
			invoke SendMessage,hCtrl,TVM_GETNEXTITEM,TVGN_NEXT,eax
		.endw
	.endif
	
	; Allocate a buffer for the array.
	mov ebx,iArray
	mov eax,ebx
	shl eax,3	; 8 bytes per element.
	.if ! zero?
		invoke LocalAlloc,LPTR,eax
		.if eax
			mov pArray,eax
			mov edi,eax
			
			; Enumerate each child of the treeview root.
			invoke SendMessage,hCtrl,TVM_GETNEXTITEM,TVGN_CHILD,TVI_ROOT
			mov tvi.hItem,eax
			.while eax
				
				; Get the item's lParam.
				mov tvi._mask,TVIF_PARAM
				mov tvi.lParam,NULL
				invoke SendMessage,hCtrl,TVM_GETITEM,0,addr tvi
				mov edx,tvi.lParam
				.if edx
					
					; Add it to the array.
					mov eax,[edx]
					stosd
					mov eax,tvi.hItem
					stosd
					dec ebx
					.break .if zero?
					
				.endif
				
				; Next child.
				invoke SendMessage,hCtrl,TVM_GETNEXTITEM,TVGN_NEXT,tvi.hItem
				mov tvi.hItem,eax
			.endw
			
			; Make the array smaller if we failed to retrieve some IDs.
			.if ebx
				mov eax,iArray
				sub eax,ebx
				mov iArray,eax
				shl eax,3	; 8 bytes per element.
				invoke LocalReAlloc,pArray,eax,LMEM_MOVEABLE or LMEM_ZEROINIT
				.if eax
					mov pArray,eax
				.endif
			.endif
			
		.endif
	.endif
	ret
	
BuildArray endp

align DWORD
CalcLangHandleAndID proc uses ebx esi edi dwAbsID:DWORD
	
	; Find to which treeview root child belongs a given string or resource ID.
	; Returns the item handle in EAX and the relative ID in EDX.
	; Uses the language IDs array.
	mov edi,pArray
	mov ecx,iArray
	xor ebx,ebx
	xor esi,esi
	test ecx,ecx
	.while ! zero?
		mov eax,[edi]
		.if (eax <= dwAbsID) && (ebx <= eax)
			mov ebx,eax
			mov esi,[edi + 4]
		.endif
		add edi,8
		dec ecx
	.endw
	mov eax,esi
	mov edx,dwAbsID
	sub edx,ebx
	ret
	
CalcLangHandleAndID endp

align DWORD
GetItemID proc hItem:HTREEITEM
	local tvi:TVITEM
	
	mov eax,hItem
	mov tvi._mask,LVIF_PARAM
	mov tvi.hItem,eax
	mov tvi.lParam,NULL
	invoke SendDlgItemMessage,hMain,IDC_TREE1,TVM_GETITEM,0,addr tvi
	mov eax,tvi.lParam
	.if eax
		mov eax,[eax]
	.endif
	ret
	
GetItemID endp

align DWORD
FindByID proc hParent:HTREEITEM, dwID:DWORD
	local hTree:HWND
	local tvi:TVITEM
	
	; Get the treeview handle.
	invoke GetDlgItem,hMain,IDC_TREE1
	mov hTree,eax
	
	; Enumerate the treeview item children until we find our ID.
	mov tvi._mask,TVIF_PARAM
	invoke SendMessage,hTree,TVM_GETNEXTITEM,TVGN_CHILD,hParent
	mov tvi.hItem,eax
	.while eax
		
		; Get the ID.
		mov tvi.lParam,NULL
		invoke SendMessage,hTree,TVM_GETITEM,0,addr tvi
		mov edx,tvi.lParam
		.if edx
			mov eax,[edx]
			
			; If it's the same ID we're looking for, return the handle.
			.break .if eax == dwID
			
		.endif
		
		; Next child.
		invoke SendMessage,hTree,TVM_GETNEXTITEM,TVGN_NEXT,tvi.hItem
		mov tvi.hItem,eax
	.endw
	
	; Return the item handle.
	mov eax,tvi.hItem
	ret
	
FindByID endp

align DWORD
FindLangID proc hItem:HTREEITEM
	local tvi:TVITEM
	
	; Get the parent item.
	invoke SendDlgItemMessage,hMain,IDC_TREE1,TVM_GETNEXTITEM,TVGN_PARENT,hItem
	.if eax
		
		; Get the ID.
		invoke GetItemID,eax
		
	.endif
	
	; Return the ID, or 0.
	ret
	
FindLangID endp

align DWORD
FindCorrectLangID proc dwAbsID:DWORD
	local dwLangID	:DWORD
	local hTree		:HWND
	local tvi		:TVITEM
	
	; Get the treeview handle.
	invoke GetDlgItem,hMain,IDC_TREE1
	mov hTree,eax
	
	; Initialize dwLangID to the default value of 0.
	mov dwLangID,0
	
	; Get the treeview root item.
	mov tvi._mask,TVIF_PARAM
	mov tvi.hItem,NULL
	invoke SendMessage,hTree,TVM_GETNEXTITEM,TVGN_CHILD,TVI_ROOT
	
	; Enumerate the treeview root's child items.
	.while eax
		mov tvi.hItem,eax
		
		; Get the ID.
		mov tvi.lParam,NULL
		invoke SendMessage,hTree,TVM_GETITEM,0,addr tvi
		mov edx,tvi.lParam
		.if edx
			mov eax,[edx]
			
			; If it seems to be the right language ID, store it and keep searching.
			.if (eax <= dwAbsID) && (eax >= dwLangID)
				mov dwLangID,eax
			.endif
		.endif
		
		; Next child.
		invoke SendMessage,hTree,TVM_GETNEXTITEM,TVGN_NEXT,tvi.hItem
	.endw
	
	; Return the language ID, or 0.
	mov eax,dwLangID
	ret
	
FindCorrectLangID endp

align DWORD
VerifyID proc hItem:HTREEITEM, dwNewID:DWORD
	local dwLangID:DWORD
	local tvi:TVITEM
	
	; Takes a proposed relative ID.
	; Returns 0 if it's consistent, nonzero if not.
	
	mov eax,hItem
	.if eax != NULL
		
		; If a treeview item is given...
		invoke FindLangID,eax
		mov dwLangID,eax
		add eax,dwNewID
		invoke FindCorrectLangID,eax
		sub eax,dwLangID
		
	.else
		
		; If not...
		invoke SendDlgItemMessage,hMain,IDC_TREE1,TVM_GETNEXTITEM,TVGN_CHILD,TVI_ROOT
		mov tvi._mask,LVIF_PARAM
		mov tvi.hItem,eax
		.while eax
			mov tvi.lParam,NULL
			invoke SendDlgItemMessage,hMain,IDC_TREE1,TVM_GETITEM,0,addr tvi
			mov eax,tvi.lParam
			.break .if !eax
			mov eax,[eax]
			mov dwLangID,eax
			add eax,dwNewID
			invoke FindCorrectLangID,eax
			sub eax,dwLangID
			.break .if !zero?
			invoke SendDlgItemMessage,hMain,IDC_TREE1,TVM_GETNEXTITEM,TVGN_NEXT,tvi.hItem
			mov tvi.hItem,eax
		.endw
		mov eax,tvi.hItem
		
	.endif
	ret
	
VerifyID endp

align DWORD
GetMaxRelativeID proc
	local hTree		:HWND
	local hLang		:HTREEITEM
	local hItem		:HTREEITEM
	local dwMaxID	:DWORD
	
	; Get the treeview handle.
	invoke GetDlgItem,hMain,IDC_TREE1
	mov hTree,eax
	
	; Set the max ID to zero.
	mov dwMaxID,0
	
	; For each language ID...
	invoke SendMessage,hTree,TVM_GETNEXTITEM,TVGN_CHILD,TVI_ROOT
	.while eax
		mov hLang,eax
		
		; For each resource...
		invoke SendMessage,hTree,TVM_GETNEXTITEM,TVGN_CHILD,hLang
		.while eax
			mov hItem,eax
			
			; Get the relative ID.
			invoke GetItemID,hItem
			
			; If this ID is the greatest we have so far, keep it.
			.if eax > dwMaxID
				mov dwMaxID,eax
			.endif
			
			; Next resource.
			invoke SendMessage,hTree,TVM_GETNEXTITEM,TVGN_NEXT,hItem
		.endw
		
		; Next language.
		invoke SendMessage,hTree,TVM_GETNEXTITEM,TVGN_NEXT,hLang
	.endw
	
	; Return the max ID.
	mov eax,dwMaxID
	ret
	
GetMaxRelativeID endp

align DWORD
GetMaxLangID proc
	local hTree		:HWND
	local hLang		:HTREEITEM
	local hItem		:HTREEITEM
	local dwMaxID	:DWORD
	
	; Get the treeview handle.
	invoke GetDlgItem,hMain,IDC_TREE1
	mov hTree,eax
	
	; Set the max ID to zero.
	mov dwMaxID,0
	
	; For each language ID...
	invoke SendMessage,hTree,TVM_GETNEXTITEM,TVGN_CHILD,TVI_ROOT
	.while eax
		mov hLang,eax
		
		; Get the language ID.
		invoke GetItemID,hLang
		
		; If this ID is the greatest we have so far, keep it.
		.if eax > dwMaxID
			mov dwMaxID,eax
		.endif
		
		; Next language.
		invoke SendMessage,hTree,TVM_GETNEXTITEM,TVGN_NEXT,hLang
	.endw
	
	; Return the max ID.
	mov eax,dwMaxID
	ret
	
GetMaxLangID endp

align DWORD
IntegrityCheck proc uses ebx esi
	local dwMaxID:DWORD
	
	; Return TRUE on success, FALSE on failure.
	
	; Get the max relative ID.
	invoke GetMaxRelativeID
	mov dwMaxID,eax
	
	; Build the language IDs array.
	invoke BuildArray
	.if eax
		
		; For each language...
		mov esi,pArray
		mov ebx,iArray
		test ebx,ebx
		.while !zero?
			
			; Verify the relative ID 0.
			invoke CalcLangHandleAndID,dword ptr [esi]
			.break .if edx != 0
			
			; Verify the max relative ID.
			mov eax,dword ptr [esi]
			add eax,dwMaxID
			invoke CalcLangHandleAndID,eax
			.break .if edx != dwMaxID
			
			; Next language.
			add esi,8
			dec ebx
		.endw
		
		; Release the language IDs array.
		invoke LocalFree,pArray
		mov pArray,NULL
		mov iArray,0
		
		; If ebx == 0, we reached successfully the end of the array.
		xchg eax,ebx
	.endif
	ret
	
IntegrityCheck endp

align DWORD
AllocData proc pszText:PTR BYTE, dwID:DWORD
	
	; Allocate a LocalAlloc chunk.
	invoke lstrlen,pszText
	add eax,5
	invoke LocalAlloc,LPTR,eax
	.if eax
		push eax
		
		; Put the ID in the first DWORD.
		push dwID
		pop dword ptr [eax]
		
		; The string begins in the second DWORD.
		add eax,4
		invoke lstrcpy,eax,pszText
		
		; Return the pointer.
		pop eax
	.endif
	ret
	
AllocData endp

align DWORD
AllocDisplayString proc pData:PTR BYTE
	local pStr:DWORD
	
	; Check the pointer to the data.
	mov eax,pData
	.if eax != NULL
		
		; [eax + 00]	Relative ID
		; [eax + 04]	ASCIIZ String
		
		; Allocate a memory block to parse the display string.
		add eax,4
		invoke lstrlen,eax
		add eax,20 + sizeof szFmtDispStr
		invoke LocalAlloc,LPTR,eax
		.if eax != NULL
			mov pStr,eax
			
			; Parse the display string.
			mov edx,pData
			lea ecx,[edx + 4]
			invoke wsprintf,eax,offset szFmtDispStr,dword ptr [edx],ecx
			
			; Return the pointer to the memory block.
			mov eax,pStr
			
		.endif
	.endif
	ret
	
AllocDisplayString endp

align DWORD
AllocBinData proc dwID:DWORD, dwSize:DWORD, pBin:PTR BYTE
	
	; Allocate a LocalAlloc chunk.
	mov eax,dwSize
	add eax,5
	invoke LocalAlloc,LPTR,eax
	.if eax
		push eax
		
		; Put the ID in the first DWORD.
		push dwID
		pop dword ptr [eax]
		
		; Put the data size in the second DWORD.
		push dwSize
		pop dword ptr [eax + 4]
		
		; The raw data begins in the third DWORD.
		add eax,8
		invoke RtlMoveMemory,eax,pBin,dwSize
		
		; Return the pointer.
		pop eax
	.endif
	ret
	
AllocBinData endp

align DWORD
AllocBinResLabel proc pData:PTR BYTE
	local pStr:DWORD
	
	; Check the pointer to the data.
	mov eax,pData
	.if eax != NULL
		
		; [eax + 00]	Relative ID
		; [eax + 04]	Size of Data
		; [eax + 08]	Binary Data
		
		; Allocate a memory block to parse the display string.
		mov edx,[eax + 4]
		add edx,20 + sizeof szFmtBinLabel
		invoke LocalAlloc,LPTR,edx
		.if eax
			mov pStr,eax
			
			; Parse the display string.
			mov edx,pData
			mov ecx,[edx + 4]
			invoke wsprintf,eax,offset szFmtBinLabel,dword ptr [edx],ecx
			
			; Return the pointer to the memory block.
			mov eax,pStr
			
		.endif
	.endif
	ret
	
AllocBinResLabel endp

align DWORD
InsertItem proc hParent:HTREEITEM, pszText:PTR BYTE, lParam:LPARAM, iImage:DWORD
	local tvis:TVINSERTSTRUCT
	
	; Initialize TVINSERTSTRUCT
	mov tvis.hInsertAfter,TVI_SORT
	push hParent
	pop tvis.hParent
	mov tvis.item._mask,TVIF_IMAGE or TVIF_PARAM or TVIF_SELECTEDIMAGE or TVIF_TEXT
	push pszText
	pop tvis.item.pszText
	push lParam
	pop tvis.item.lParam
	mov eax,iImage
	mov tvis.item.iImage,eax
	mov tvis.item.iSelectedImage,eax
	
	; Add the item.
	invoke SendDlgItemMessage,hMain,IDC_TREE1,TVM_INSERTITEM,0,addr tvis
	
	; Return the handle.
	ret
	
InsertItem endp

align DWORD
CopyLanguage proc hItem:HTREEITEM, pszText:PTR BYTE, dwID:DWORD
	local hTree:HWND
	local pData:PTR DWORD
	local hDest:HTREEITEM
	local tvi:TVITEM
	
	; Get the treeview handle.
	invoke GetDlgItem,hMain,IDC_TREE1
	.if eax
		mov hTree,eax
		
		; Add the root child item.
		invoke AllocData,pszText,dwID
		.if eax
			mov pData,eax
			invoke AllocDisplayString,eax
			.if eax
				mov pszText,eax
				invoke InsertItem,TVI_ROOT,eax,pData,0
				push eax
				invoke LocalFree,pszText
				pop eax
				test eax,eax
				jz freedata2
				mov hDest,eax
				
				; Check the consistency of the tree with the new language.
				invoke IntegrityCheck
				.if eax == 0
					
					; The consistency check has succeded.
					
					; For each child item...
					.if hItem != NULL
						invoke SendMessage,hTree,TVM_GETNEXTITEM,TVGN_CHILD,hItem
						.while eax
							mov tvi.hItem,eax
							
							; Get the item info.
							mov tvi._mask,TVIF_IMAGE or TVIF_PARAM
							mov tvi.iImage,0
							mov tvi.lParam,NULL
							invoke SendMessage,hTree,TVM_GETITEM,0,addr tvi
							.if tvi.lParam
								mov eax,tvi.iImage
								.if eax == 1
									
									; It's a string resource.
									mov eax,tvi.lParam
									add eax,4
									invoke AllocData,eax,dword ptr [eax - 4]
									.if eax
										mov pData,eax
										invoke AllocDisplayString,eax
							gotlabel:	test eax,eax
										jz freedata1
										mov pszText,eax
										invoke InsertItem,hDest,eax,pData,tvi.iImage
										push eax
										invoke LocalFree,pszText
										pop eax
										.if !eax
							freedata1:		invoke LocalFree,pData
										.endif
									.endif
									
								.elseif eax == 2
									
									; It's a binary resource.
									mov eax,tvi.lParam
									add eax,8
									invoke AllocBinData,
									 	dword ptr [eax - 8],dword ptr [eax - 4],eax
									.if eax
										mov pData,eax
										invoke AllocBinResLabel,eax
										jmp gotlabel
									.endif
									
								.endif
							.endif
							
							; Next sibling item.
							invoke SendMessage,hTree,TVM_GETNEXTITEM,TVGN_NEXT,tvi.hItem
						.endw
					.endif
					
				.else
					
					; The consistency check has failed, delete the root child item.
					; Remember that deleting the item also deletes it's data.
					; Don't delete the data twice!
					invoke SendMessage,hTree,TVM_DELETEITEM,0,hDest
					
				.endif
				
			.else
				
				; Free the memory to avoid leaks.
freedata2:		invoke LocalFree,pData
				
			.endif
		.endif
	.endif
	
	; Return.
	ret
	
CopyLanguage endp

align DWORD
LoadUIStrings proc uses edi hCtrl:HWND
	local pKey:PTR BYTE
	local dwAbsID:DWORD
	local dwID:DWORD
	local tvis:TVINSERTSTRUCT
	local szNum[20]:BYTE
	
	; Initialize the TVINSERTSTRUCT structure.
	mov tvis.hInsertAfter,TVI_SORT
	mov tvis.item._mask,TVIF_IMAGE or TVIF_PARAM or TVIF_SELECTEDIMAGE or TVIF_TEXT
	mov tvis.item.iImage,1
	mov tvis.item.iSelectedImage,1
	
	; Get the whole [Strings] section.
	invoke GetPrivateProfileSection,
	 	offset szStrings,offset szSection,sizeof szSection,offset szFilename
	.if eax
		
		; Load each string.
		mov edi,offset szSection
		.repeat
			invoke lstrlen,edi
			.break .if eax == 0
			mov ecx,eax
			inc eax
			add eax,edi
			push eax
			
			; Skip leading spaces.
			mov al,' '
			repe scasb
			.if !zero?
				
				; Skip comment lines.
				dec edi
				inc ecx
				.if byte ptr [edi] != ';'
					
					; Get the string's absolute ID.
					mov pKey,edi
					mov al,'='
					repne scasb
					.if zero?
						mov byte ptr [edi - 1],0
						invoke StrToInt,pKey
						mov dwAbsID,eax
						
						; Find the treeview root child for this ID.
						; Also get the relative ID.
						invoke CalcLangHandleAndID,eax
						mov tvis.hParent,eax
						mov dwID,edx
						
						; Allocate the custom data for this treeview item.
						invoke lstrlen,edi
						add eax,5
						invoke LocalAlloc,LPTR,eax
						.if eax
							mov tvis.item.lParam,eax
							
							; Store the ID.
							push dwID
							pop dword ptr [eax]
							
							; Get the string using the INI file APIs and store it.
							; We use this method to ensure compatibility.
							invoke wsprintf,addr szNum,offset szFmtInt,dwAbsID
							invoke lstrlen,edi
							inc eax
							mov edx,tvis.item.lParam
							add edx,4
							invoke GetPrivateProfileString,
							 	offset szStrings,addr szNum,edi,edx,eax,offset szFilename
							.if eax
								
								; Allocate the display string.
								invoke AllocDisplayString,tvis.item.lParam
								.if eax
									mov tvis.item.pszText,eax
									
									; Add the treeview item.
									invoke SendMessage,hCtrl,TVM_INSERTITEM,0,addr tvis
									
									; Free the display string.
									push eax
									invoke LocalFree,tvis.item.pszText
									pop eax
									
									; Continue on success.
									test eax,eax
									jnz cont
									
								.endif
							.endif
							
							; Free the memory block on error, to prevent leaks.
							invoke LocalFree,tvis.item.lParam
							
						.endif
					.endif
				.endif
			.endif
	cont:	pop edi
		.until FALSE
	.endif
	
	; Return.
	ret
	
LoadUIStrings endp

align DWORD
LoadUIResources proc hCtrl:HWND
	local pKey:PTR BYTE
	local dwAbsID:DWORD
	local dwID:DWORD
	local tvis:TVINSERTSTRUCT
	local szNum[20]:BYTE
	
	; Initialize the TVINSERTSTRUCT structure.
	mov tvis.hInsertAfter,TVI_SORT
	mov tvis.item._mask,TVIF_IMAGE or TVIF_PARAM or TVIF_SELECTEDIMAGE or TVIF_TEXT
	mov tvis.item.iImage,2
	mov tvis.item.iSelectedImage,2
	
	; Get the whole [Resources] section.
	invoke GetPrivateProfileSection,
	 	offset szResources,offset szSection,sizeof szSection,offset szFilename
	.if eax
		
		; Load each resource.
		mov edi,offset szSection
		.repeat
			invoke lstrlen,edi
			.break .if eax == 0
			mov ecx,eax
			inc eax
			add eax,edi
			push eax
			
			; Skip leading spaces.
			mov al,' '
			repe scasb
			.if !zero?
				
				; Skip comment lines.
				dec edi
				inc ecx
				.if byte ptr [edi] != ';'
					
					; Get the resource's absolute ID.
					mov pKey,edi
					mov al,'='
					repne scasb
					.if zero?
						mov byte ptr [edi - 1],0
						invoke StrToInt,pKey
						mov dwAbsID,eax
						
						; Find the treeview root child for this ID.
						; Also get the relative ID.
						invoke CalcLangHandleAndID,eax
						mov tvis.hParent,eax
						mov dwID,edx
						
						; Allocate the custom data for this treeview item.
						invoke lstrlen,edi
						add eax,4
						invoke LocalAlloc,LPTR,eax
						.if eax
							mov tvis.item.lParam,eax
							
							; Store the ID.
							push dwID
							pop dword ptr [eax]
							
							; Get the resource data using the INI file APIs.
							invoke wsprintf,addr szNum,offset szFmtInt,dwAbsID
							invoke lstrlen,edi
							mov edx,tvis.item.lParam
							add edx,4
							invoke GetPrivateProfileStruct,
							 	offset szResources,addr szNum,edx,eax,offset szFilename
							.if eax
								
								; Make sure the "size" field is within an acceptable range.
								invoke lstrlen,edi
								mov edx,tvis.item.lParam
								mov ecx,[edx + 4]
								.if ecx <= eax
									
									; Resize the custom data chunk.
									add ecx,8
									invoke LocalReAlloc,
									 	tvis.item.lParam,ecx,LMEM_MOVEABLE or LMEM_ZEROINIT
									.if eax
										mov tvis.item.lParam,eax
									.endif
									
									; Allocate the display string.
									invoke AllocBinResLabel,tvis.item.lParam
									.if eax
										mov tvis.item.pszText,eax
										
										; Add the treeview item.
										invoke SendMessage,hCtrl,TVM_INSERTITEM,0,addr tvis
										
										; Free the display string.
										push eax
										invoke LocalFree,tvis.item.pszText
										pop eax
										
										; Continue on success.
										test eax,eax
										jnz cont
										
									.endif
								.endif
							.endif
							
							; Free the memory block on error, to prevent leaks.
							invoke LocalFree,tvis.item.lParam
							
						.endif
					.endif
				.endif
			.endif
	cont:	pop edi
		.until FALSE
	.endif
	
	; Return.
	ret
LoadUIResources endp

align DWORD
LoadUIFile proc uses ebx edi hCtrl:HWND
	local tvis:TVINSERTSTRUCT
	
	; Initialize the TVINSERTSTRUCT structure.
	mov tvis.hParent,TVI_ROOT
	mov tvis.hInsertAfter,TVI_SORT
	mov tvis.item._mask,TVIF_IMAGE or TVIF_PARAM or TVIF_SELECTEDIMAGE or TVIF_TEXT
	mov tvis.item.iImage,0
	mov tvis.item.iSelectedImage,0
	
	; Get the [Language] section.
	mov szSection[0],0
	invoke GetPrivateProfileSection,
	 	offset szLanguage,offset szSection,sizeof szSection,offset szFilename
	test eax,eax
	jz @q
	
	; Prevent changes to be shown during load.
	invoke LockWindowUpdate,hCtrl
	
	; Clear the treeview.
	invoke SendMessage,hCtrl,TVM_DELETEITEM,0,TVI_ROOT
	
	; Load each language description and starting ID.
	mov pArray,NULL
	mov iArray,0
	mov edi,offset szSection
	.repeat
		invoke lstrlen,edi
		.break .if eax == 0
		mov ecx,eax
		add eax,edi
		add eax,1
		push eax
		mov al,' '		; Skip leading spaces.
		repe scasb
		.if !zero?
			dec edi
			inc ecx
			.if byte ptr [edi] != ';'	; Skip comment lines.
				mov ebx,edi
				mov al,'='
				repne scasb
				.if zero?
					mov byte ptr [edi - 1],0
					
					; Allocate memory to store the language info.
					invoke lstrlen,ebx
					add eax,5
					invoke LocalAlloc,LPTR,eax
					.if eax != NULL
						mov tvis.item.lParam,eax
						
						; Convert the second string to DWORD just like the system would.
						; It's not the fastest way, but we can be sure of it's compatibility.
						invoke GetPrivateProfileInt,offset szLanguage,ebx,0,offset szFilename
						
						; Store the ID and language string.
						mov edx,tvis.item.lParam
						mov [edx],eax
						invoke lstrcpy,addr [edx + 4],ebx
						
						; Allocate and parse the display string.
						invoke AllocDisplayString,tvis.item.lParam
						.if eax != NULL
							mov tvis.item.pszText,eax
							
							; Add the treeview item.
							invoke SendMessage,hCtrl,TVM_INSERTITEM,0,addr tvis
							
							; Free the display string.
							push eax
							invoke LocalFree,tvis.item.pszText
							pop eax
							
							; Continue on success.
							.if eax
								inc iArray
								jmp cont
							.endif
						.endif
						
						; On failure we must free the memory block to prevent leaks.
						invoke LocalFree,tvis.item.lParam
						
					.endif
				.endif
			.endif
		.endif
cont:	pop edi
	.until FALSE
	
	; Build an array of language starting IDs and their treeview items.
	invoke BuildArray
	.if pArray
		
		; Load all strings.
		invoke LoadUIStrings,hCtrl
		
		; Load all binary resources.
		invoke LoadUIResources,hCtrl
		
		; Free the array now that we don't need it anymore.
		invoke LocalFree,pArray
		mov pArray,NULL
		
	.endif
	
	; Enable treeview drawing again.
	invoke LockWindowUpdate,NULL
@q:	ret
	
LoadUIFile endp

align DWORD
SaveUIData proc hCtrl:HWND, hParent:HTREEITEM, dwStartingID:DWORD, pTempFile:PTR BYTE
	local tvi:TVITEM
	local szNum[20]:BYTE
	
	; For each child item...
	invoke SendMessage,hCtrl,TVM_GETNEXTITEM,TVGN_CHILD,hParent
	.while eax
		mov tvi.hItem,eax
		
		; Get the item's info.
		mov tvi._mask,TVIF_IMAGE or TVIF_PARAM
		mov tvi.lParam,NULL
		invoke SendMessage,hCtrl,TVM_GETITEM,0,addr tvi
		mov eax,tvi.lParam
		.if eax
			
			; Convert the relative ID to absolute ID.
			mov edx,dword ptr [eax]
			add edx,dwStartingID
			
			; Convert the ID integer to string.
			mov szNum[0],0
			invoke wsprintf,addr szNum,offset szFmtInt,edx
			test eax,eax
			jz @F			; Abort on error.
			
			; What type of resource is it?
			mov eax,tvi.iImage
			.if eax == 1
				
				; Save the string.
				mov eax,tvi.lParam
				add eax,4
				invoke WritePrivateProfileString,
				 	offset szStrings,addr szNum,eax,pTempFile
				test eax,eax
				jz @F			; Abort on error.
				
			.elseif eax == 2
				
				; Save the binary resource.
				mov eax,tvi.lParam
				add eax,4
				mov ecx,[eax]
				add ecx,4
				invoke WritePrivateProfileStruct,
				 	offset szResources,addr szNum,eax,ecx,pTempFile
				test eax,eax
				jz @F			; Abort on error.
				
			.endif
		.endif
		
		; Next item...
		invoke SendMessage,hCtrl,TVM_GETNEXTITEM,TVGN_NEXT,tvi.hItem
	.endw
	
	; Returns nonzero on success, zero on failure.
	push TRUE
	pop eax
@@:	ret
	
SaveUIData endp

align DWORD
SaveUIFile proc hCtrl:HWND
	local tvi:TVITEM
	local szTempName[MAX_PATH]:BYTE
	local szTempFolder[MAX_PATH]:BYTE
	local szNum[20]:BYTE
	
	; Generate a random filename.
	mov szTempFolder[0],0
	mov szTempName[0],0
	invoke GetTempPath,sizeof szTempFolder,addr szTempFolder
	invoke GetTempFileName,addr szTempFolder,offset szPrefixString,0,addr szTempName
	xor eax,eax
	.if szTempName[0] != 0
		
		; For each language...
		invoke SendMessage,hCtrl,TVM_GETNEXTITEM,TVGN_CHILD,TVI_ROOT
		.while eax
			mov tvi.hItem,eax
			
			; Get the item's info.
			mov tvi._mask,TVIF_PARAM
			mov tvi.lParam,NULL
			invoke SendMessage,hCtrl,TVM_GETITEM,0,addr tvi
			mov eax,tvi.lParam
			.if eax
				
				; Convert the ID int to string.
				mov szNum[0],0
				invoke wsprintf,addr szNum,offset szFmtInt,dword ptr [eax]
				test eax,eax
				jz @F			; Abort on error.
				
				; Save the language starting ID and description string.
				mov eax,tvi.lParam
				add eax,4
				lea ecx,szTempName
				lea edx,szNum
				invoke WritePrivateProfileString,offset szLanguage,eax,edx,ecx
				test eax,eax
				jz @F			; Abort on error.
				
				; Save all resources for this language.
				mov eax,tvi.lParam
				lea edx,szTempName
				invoke SaveUIData,hCtrl,tvi.hItem,dword ptr [eax],edx
				test eax,eax
				jz @F			; Abort on error.
				
			.endif
			
			; Next language...
			invoke SendMessage,hCtrl,TVM_GETNEXTITEM,TVGN_NEXT,tvi.hItem
		.endw
		
		; Flush the INI file cache to disk to prevent problems under Win9X.
		invoke WritePrivateProfileString,NULL,NULL,NULL,addr szTempName
		
		; Replace the original file with the temp one.
		invoke MoveFileEx,addr szTempName,offset szFilename,
		 	MOVEFILE_COPY_ALLOWED or MOVEFILE_REPLACE_EXISTING ;or MOVEFILE_WRITE_THROUGH
		
		; Win9X really sucks, doesn't it? :P
		.if !eax
			invoke GetLastError
			cmp eax,ERROR_CALL_NOT_IMPLEMENTED
			mov eax,0
			.if zero?
				invoke MoveFile,addr szTempName,offset szFilename
				.if !eax
					invoke CopyFile,addr szTempName,offset szFilename,FALSE
				.endif
			.endif
		.endif
		
	.endif
	
	; Delete the temp file.
@@:	.if szTempName[0] != 0
		push eax
		invoke DeleteFile,addr szTempName
		pop eax
	.endif
	
	; Returns nonzero on success, zero on failure.
@q:	ret
	
SaveUIFile endp

align DWORD
LoadRawFile proc hWnd:HWND
	local hFile:HFILE
	local dwSizeLow:DWORD
	local dwSizeHi:DWORD
	
	; Open file.
	invoke CreateFile,
	 	offset szResFile,GENERIC_READ,FILE_SHARE_READ,NULL,
	 	OPEN_EXISTING,FILE_FLAG_SEQUENTIAL_SCAN,NULL
	inc eax
	.if !zero?
		dec eax
		mov hFile,eax
		
		; Get the file size.
		invoke GetFileSize,hFile,addr dwSizeHi
		
		; To do...
		
	.endif
	
	; Show error messagebox if needed.
	.if eax == 0
		invoke MessageBox,hWnd,offset szCantReadRes,offset szError,MB_ICONERROR or MB_OK
		xor eax,eax
	.endif
	ret
	
LoadRawFile endp

align DWORD
LoadResFile proc uses esi edi hParent:HWND
	local hFile:HFILE
	local dwRead:DWORD
	local xSignature[8]:DWORD
	
	; Open file.
	invoke CreateFile,
	 	offset szResFile,GENERIC_READ,FILE_SHARE_READ,NULL,
	 	OPEN_EXISTING,FILE_FLAG_SEQUENTIAL_SCAN,NULL
	inc eax
	.if !zero?
		dec eax
		mov hFile,eax
		
		; Make sure it's a real .RES file.
		invoke ReadFile,hFile,addr xSignature,sizeof xSignature,addr dwRead,NULL
		.if eax
			xor eax,eax
			.if dwRead == sizeof xSignature
				lea esi,xSignature
				lea edi,offset xResSign
				mov ecx,sizeof xSignature / sizeof DWORD
				repe cmpsd
				.if zero?
					
					; Ask the user which resource to load.
					invoke DialogBoxParam,hInst,IDD_RESFILE,hParent,offset PickResProc,hFile
					.if (eax != IDOK) && (eax != IDCANCEL)
						xor eax,eax
					.endif
				.endif
			.endif
		.endif
		
		; Close the file handle.
		push eax
		invoke CloseHandle,hFile
		pop eax
	.endif
	
	; Show error messagebox if needed.
	.if eax == 0
		invoke MessageBox,hParent,offset szCantReadRes,offset szError,MB_ICONERROR or MB_OK
		xor eax,eax
	.endif
	ret
	
LoadResFile endp

align DWORD
SaveResFile proc hParent:HWND
	
	; To do...
	
	xor eax,eax
	ret
	
SaveResFile endp

align DWORD
SaveRawFile proc hWnd:HWND
	
	; To do...
	
	xor eax,eax
	ret
	
SaveRawFile endp

align DWORD
NewLangProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local bTranslated:BOOL
	local dwID:DWORD
	local tvi:TVITEM
	local szText[MAX_PATH]:BYTE
	
	mov eax,uMsg
	.if eax == WM_COMMAND
		mov eax,wParam
		cmp eax,IDCANCEL
		je close
		.if eax == IDOK
			
			; Get the new language description string.
			invoke GetDlgItemText,hWnd,IDC_EDIT1,addr szText,sizeof szText
			.if eax
				
				; Get the new language starting ID.
				invoke GetDlgItemInt,hWnd,IDC_EDIT2,addr bTranslated,FALSE
				.if bTranslated
					mov dwID,eax
					
					; Make sure it didn't exist already.
					invoke FindByID,TVI_ROOT,eax
					.if eax == NULL
						
						; Get the language to copy from.
						mov tvi.hItem,NULL
						invoke SendDlgItemMessage,hWnd,IDC_COMBO1,CB_GETCURSEL,0,0
						.if eax != CB_ERR
							invoke SendDlgItemMessage,hWnd,IDC_COMBO1,CB_GETITEMDATA,eax,0
							.if eax != CB_ERR
								mov tvi.hItem,eax
							.endif
						.endif
						
						; Copy the language (or just create a new one).
						invoke CopyLanguage,tvi.hItem,addr szText,dwID
						
						; Close the dialog box.
		close:			invoke EndDialog,hWnd,wParam
						
					.endif
				.endif
			.endif
		.endif
	.elseif eax == WM_INITDIALOG
		
		; Set the edit boxes max. text length.
		invoke SendDlgItemMessage,hWnd,IDC_EDIT1,EM_SETLIMITTEXT,sizeof szText,0
		invoke SendDlgItemMessage,hWnd,IDC_EDIT2,EM_SETLIMITTEXT,12,0
		
		; Fill the combo box with the language list.
		invoke SendDlgItemMessage,hMain,IDC_TREE1,TVM_GETNEXTITEM,TVGN_CHILD,TVI_ROOT
		.while eax
			mov tvi._mask,TVIF_PARAM
			mov tvi.hItem,eax
			mov tvi.lParam,NULL
			invoke SendDlgItemMessage,hMain,IDC_TREE1,TVM_GETITEM,0,addr tvi
			mov eax,tvi.lParam
			.if eax
				invoke AllocDisplayString,eax
				.if eax
					push eax
					invoke SendDlgItemMessage,hWnd,IDC_COMBO1,CB_ADDSTRING,0,eax
					.if eax != CB_ERR
						mov dwID,eax
						invoke SendDlgItemMessage,
						 	hWnd,IDC_COMBO1,CB_SETITEMDATA,eax,tvi.hItem
						
						; If the caret is in this language, select it as default.
						invoke IsCaretHere,tvi.hItem
						.if eax
							invoke SendDlgItemMessage,hWnd,IDC_COMBO1,CB_SETCURSEL,dwID,0
						.endif
					.endif
					call LocalFree
				.endif
			.endif
			invoke SendDlgItemMessage,hMain,IDC_TREE1,TVM_GETNEXTITEM,TVGN_NEXT,tvi.hItem
		.endw
		
		; Select the first one on the list as default, if there was no selection.
		invoke SendDlgItemMessage,hWnd,IDC_COMBO1,CB_GETCURSEL,0,0
		.if eax == CB_ERR
			invoke SendDlgItemMessage,hWnd,IDC_COMBO1,CB_SETCURSEL,0,0
		.endif
		
		; Set the default new language ID.
		invoke SendDlgItemMessage,hMain,IDC_TREE1,TVM_GETCOUNT,0,0
		.if eax != 0
			invoke GetMaxLangID
			add eax,100
		.endif
		invoke SetDlgItemInt,hWnd,IDC_EDIT2,eax,TRUE
		
		; Return TRUE.
		push TRUE
		pop eax
		ret
		
	.endif
	xor eax,eax
	ret
	
NewLangProc endp

align DWORD
EditStringProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local bTranslated:BOOL
	local dwID:DWORD
	local pOldData:PTR DWORD
	local tvi:TVITEM
	local szText[MAX_PATH]:BYTE
	
	mov eax,uMsg
	.if eax == WM_COMMAND
		mov eax,wParam
		cmp eax,IDCANCEL
		je close
		.if eax == IDOK
			
			; Get the new language description, or string.
			invoke GetDlgItemText,hWnd,IDC_EDIT3,addr szText,sizeof szText
			.if eax
				
				; Get the new language starting ID, or string ID.
				invoke GetDlgItemInt,hWnd,IDC_EDIT4,addr bTranslated,FALSE
				.if bTranslated
					mov dwID,eax
					
					; Get the treeview item handle.
					invoke GetWindowLong,hWnd,DWL_USER
					.if eax
						mov tvi.hItem,eax
						
						; Verify that the new ID is consistent.
						invoke VerifyID,eax,dwID
						.if eax == 0
							
							; Get the treeview item info.
							mov tvi._mask,TVIF_PARAM
							mov tvi.lParam,NULL
							invoke SendDlgItemMessage,hMain,IDC_TREE1,TVM_GETITEM,0,addr tvi
							mov eax,tvi.lParam
							.if eax
								mov pOldData,eax
								
								; Allocate a new data chunk.
								invoke AllocData,addr szText,dwID
								.if eax
									mov tvi.lParam,eax
									
									; Allocate a new display string.
									invoke AllocDisplayString,eax
									.if eax
										mov tvi.pszText,eax
										
										; Set the new item info.
										mov tvi._mask,TVIF_PARAM or TVIF_TEXT
										invoke SendDlgItemMessage,
										 	hMain,IDC_TREE1,TVM_SETITEM,0,addr tvi
										push eax
										invoke LocalFree,tvi.pszText
										pop eax
										.if eax
											
											; On success free the old custom data chunk...
											invoke LocalFree,pOldData
											
											; ...and close the dialog box.
		close:								invoke EndDialog,hWnd,wParam
											xor eax,eax
											ret
											
										.endif
										
										; On error free the new custom data chunk.
										invoke LocalFree,tvi.lParam
										
									.endif
								.endif
							.endif
						.endif
					.endif
				.endif
			.endif
		.endif
	.elseif eax == WM_INITDIALOG
		
		; Set the edit boxes max. text length.
		invoke SendDlgItemMessage,hWnd,IDC_EDIT3,EM_SETLIMITTEXT,sizeof szText,0
		invoke SendDlgItemMessage,hWnd,IDC_EDIT4,EM_SETLIMITTEXT,12,0
		invoke SendDlgItemMessage,hWnd,IDC_EDIT5,EM_SETLIMITTEXT,sizeof szText,0
		
		; Get the treeview item handle.
		mov eax,lParam
		.if eax != NULL
			mov tvi.hItem,eax
			
			; Save the initialization parameter (the treeview item handle).
			invoke SetWindowLong,hWnd,DWL_USER,eax
			
			; Get the item's info.
			mov tvi._mask,TVIF_IMAGE or TVIF_PARAM
			mov tvi.iImage,0
			mov tvi.lParam,NULL
			invoke SendDlgItemMessage,hMain,IDC_TREE1,TVM_GETITEM,0,addr tvi
			mov eax,tvi.lParam
			.if eax
				
				; Get the ID.
				invoke SetDlgItemInt,hWnd,IDC_EDIT4,dword ptr [eax],TRUE
				
				; Get the description string.
				mov eax,tvi.lParam
				add eax,4
				push eax
				push IDC_EDIT5
				push hWnd
				invoke SetDlgItemText,hWnd,IDC_EDIT3,eax
				call SetDlgItemText
				
				; Set the correct caption and static text.
				.if tvi.iImage == 0
					push offset szDescription
					push offset szStartingID
					push offset szEditLang
				.else;if tvi.iImage == 1
					push offset szString
					push offset szRelativeID
					push offset szEditString
				.endif
				push hWnd
				call SetWindowText
				push IDC_STATIC2
				push hWnd
				call SetDlgItemText
				push IDC_STATIC1
				push hWnd
				call SetDlgItemText
				
			.endif
			
		.else
			
			; If the item handle is invalid, close the dialog box.
			invoke EndDialog,hWnd,IDCANCEL
			
		.endif
		
		; Return TRUE.
		push TRUE
		pop eax
		ret
		
	.endif
	xor eax,eax
	ret
	
EditStringProc endp

align DWORD
NewStringProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local bTranslated		:BOOL
	local bOverwrite		:BOOL
	local dwID				:DWORD
	local pData				:PTR DWORD
	local pText				:PTR BYTE
	local tvi				:TVITEM
	local szText[MAX_PATH]	:BYTE
	
	mov eax,uMsg
	.if eax == WM_COMMAND
		mov eax,wParam
		cmp eax,IDCANCEL
		je close
		.if eax == IDOK
			
			; Get the new string.
			invoke GetDlgItemText,hWnd,IDC_EDIT8,addr szText,sizeof szText
			.if eax
				
				; Get the new ID.
				invoke GetDlgItemInt,hWnd,IDC_EDIT9,addr bTranslated,FALSE
				.if bTranslated
					mov dwID,eax
					
					; Get the overwrite flag.
					invoke IsDlgButtonChecked,hWnd,IDC_CHECK1
					mov bOverwrite,eax
					
					; Verify that the new ID is consistent.
					invoke VerifyID,NULL,eax
					.if eax == 0
						
						; For each language...
						invoke SendDlgItemMessage,
						 	hMain,IDC_TREE1,TVM_GETNEXTITEM,TVGN_CHILD,TVI_ROOT
						.while eax
							mov tvi.hItem,eax
							
							; Was the new ID already defined for this language?
							invoke FindByID,tvi.hItem,dwID
							.if eax
								
								; Is the overwrite flag is clear, skip this language.
								cmp bOverwrite,FALSE
								je @F
								
								; Otherwise, delete the old treeview item.
								invoke SendDlgItemMessage,
								 	hMain,IDC_TREE1,TVM_DELETEITEM,0,eax
							
							.endif
							
							; Define the new treeview item.
							invoke AllocData,addr szText,dwID
							.if eax
								mov pData,eax
								invoke AllocDisplayString,eax
								.if eax
									mov pText,eax
									invoke InsertItem,tvi.hItem,eax,pData,1
									push eax
									invoke LocalFree,pText
									pop eax
									test eax,eax
									jnz @F
								.endif
								invoke LocalFree,pData
						@@:	.endif
							
							; Next language...
							invoke SendDlgItemMessage,
							 	hMain,IDC_TREE1,TVM_GETNEXTITEM,TVGN_NEXT,tvi.hItem
						.endw
						
					.endif
					
					; Close the dialog box.
		close:		invoke EndDialog,hWnd,wParam
					
				.endif
			.endif
		.endif
	.elseif eax == WM_INITDIALOG
		
		; Set the edit boxes max. text length.
		invoke SendDlgItemMessage,hWnd,IDC_EDIT8,EM_SETLIMITTEXT,sizeof szText,0
		invoke SendDlgItemMessage,hWnd,IDC_EDIT9,EM_SETLIMITTEXT,12,0
		
		; Set the caption and static text.
		invoke SetDlgItemText,hWnd,IDC_STATIC5,offset szString
		invoke SetDlgItemText,hWnd,IDC_STATIC6,offset szRelativeID
		
		; Set the default new ID.
		invoke SendDlgItemMessage,hMain,IDC_TREE1,TVM_GETCOUNT,0,0
		push eax
		invoke GetMaxRelativeID
		pop edx
		.if (eax != 0) || (edx > 1)
			inc eax
		.else
			xor eax,eax
		.endif
		invoke SetDlgItemInt,hWnd,IDC_EDIT9,eax,TRUE
		
		; Return.
		push TRUE
		pop eax
		ret
		
	.endif
	xor eax,eax
	ret
	
NewStringProc endp

align DWORD
BinaryProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local dwID			:DWORD
	local pText			:PTR CHAR
	local pData			:PTR DWORD
	local pTemp			:PTR DWORD
	local bTranslated	:BOOL
	local tvi			:TVITEM
	
	mov eax,uMsg
	.if eax == WM_COMMAND
		mov eax,wParam
		.if eax == IDCANCEL
			
			; Free the custom data and close the dialog box.
			invoke GetProp,hWnd,offset szResources
			.if eax
				invoke LocalFree,eax
			.endif
			jmp close
			
		.endif
		.if eax == IDOK
			
			; Get the new custom data.
			invoke GetProp,hWnd,offset szResources
			.if eax
				mov pData,eax
				
				; Get the new ID.
				invoke GetDlgItemInt,hWnd,IDC_EDIT4,addr bTranslated,FALSE
				.if bTranslated
					mov dwID,eax
					
					; Verify that the new ID is consistent.
					invoke VerifyID,NULL,eax
					.if eax == 0
						
						; Get the treeview item handle we're editing.
						invoke GetWindowLong,hWnd,DWL_USER
						.if eax == NULL
							
							; New binary resource.
							
							; For each language...
							invoke SendDlgItemMessage,
							 	hMain,IDC_TREE1,TVM_GETNEXTITEM,TVGN_CHILD,TVI_ROOT
							.while eax
								mov tvi.hItem,eax
								
								; If the ID was already defined, delete the old treeview item.
								invoke FindByID,tvi.hItem,dwID
								.if eax
									invoke SendDlgItemMessage,
									 	hMain,IDC_TREE1,TVM_DELETEITEM,0,eax
								.endif
								
								; Define the new treeview item.
								mov eax,pData
								invoke AllocBinData,dwID,dword ptr [eax + 4],eax
								.if eax
									mov pTemp,eax
									invoke AllocBinResLabel,eax
									.if eax
										mov pText,eax
										invoke InsertItem,tvi.hItem,eax,pTemp,2
										invoke LocalFree,pText
									.endif
									invoke LocalFree,pTemp
								.endif
								
								; Next language...
								invoke SendDlgItemMessage,
								 	hMain,IDC_TREE1,TVM_GETNEXTITEM,TVGN_NEXT,tvi.hItem
							.endw
							
							; Free the custom data.
							invoke LocalFree,pData
							
							; Close the dialog box.
							jmp close
							
						.endif
						
						; Edit binary resource.
						
						; Get the old custom data.
						mov tvi._mask,TVIF_PARAM
						mov tvi.hItem,eax
						mov tvi.lParam,NULL
						invoke SendDlgItemMessage,hMain,IDC_TREE1,TVM_GETITEM,0,addr tvi
						.if tvi.lParam
							
							; Allocate a new description string.
							invoke AllocBinResLabel,pData
							.if eax
								mov pText,eax
								
								; Update the treeview item's data.
								mov tvi._mask,TVIF_PARAM or TVIF_TEXT
								mov tvi.pszText,eax
								push pData
								pop tvi.lParam
								invoke SendDlgItemMessage,
								 	hMain,IDC_TREE1,TVM_SETITEM,0,addr tvi
								
								; Free the description string.
								push eax
								invoke LocalFree,pText
								pop eax
								
								; Did we succeed?
								.if eax
									
									; Free the old custom data.
									invoke LocalFree,tvi.lParam
									
									; Close the dialog box.
			close:					invoke EndDialog,hWnd,wParam
									
								.endif
							.endif
						.endif
						
					.endif
				.endif
			.endif
			
		.elseif eax == IDC_BUTTON1
			
			; Launch "Open Filename" box.
			invoke GetOpenFileName,offset ofn3
			.if eax
				
				; Determine the file type from the extension.
				invoke PathMatchSpec,offset ofn3,offset szSpecRes
				.if eax
					
					; Not supported yet.
					.data
					szNotSupp1 db "Loading .RES files are not supported yet. Sorry! :(",0
					.code
					invoke MessageBox,hWnd,offset szNotSupp1,offset szError,MB_OK or MB_ICONERROR
					
					; Try to load the file.
;					invoke LoadResFile,hWnd
					
				.else
					
					; Load anything else as a raw resource.
					invoke LoadRawFile,hWnd
					
				.endif
				
			.endif
			
		.elseif eax == IDC_BUTTON2
			
			; Launch "Save Filename" box.
			invoke GetSaveFileName,offset ofn4
			.if eax
				
				; Determine the file type from the extension.
				invoke PathMatchSpec,offset ofn4,offset szSpecRes
				.if eax
					
					; Not supported yet.
					.data
					szNotSupp2 db "Saving .RES files are not supported yet. Sorry! :(",0
					.code
					invoke MessageBox,hWnd,offset szNotSupp2,offset szError,MB_OK or MB_ICONERROR
						
					; Try to save the file.
;					invoke SaveResFile,hWnd
					
				.else
					
					; Save anything else as a raw resource.
					invoke SaveRawFile,hWnd
					
				.endif
			.endif
			
		.endif
		
	.elseif eax == WM_INITDIALOG
		
		; Store the window handle in ofn3 and ofn4.
		mov eax,hWnd
		mov ofn3.hwndOwner,eax
		mov ofn4.hwndOwner,eax
		
		; Set the edit boxes max. text length.
		invoke SendDlgItemMessage,hWnd,IDC_EDIT6,EM_SETLIMITTEXT,12,0
		invoke SendDlgItemMessage,hWnd,IDC_EDIT7,EM_SETLIMITTEXT,3 * 32767,0
		
		; Set the "hex" edit box font.
		invoke SendDlgItemMessage,hWnd,IDC_EDIT7,WM_SETFONT,hFont,TRUE
		
		; Save the treeview handle to edit.
		invoke SetWindowLong,hWnd,DWL_USER,lParam
		
		; Are we editing or creating?
		mov eax,lParam
		.if eax == NULL
			
			; Creating...
			
			; Set the default new ID.
			invoke SendDlgItemMessage,hMain,IDC_TREE1,TVM_GETCOUNT,0,0
			push eax
			invoke GetMaxRelativeID
			pop edx
			.if (eax != 0) || (edx > 1)
				inc eax
			.else
				xor eax,eax
			.endif
			invoke SetDlgItemInt,hWnd,IDC_EDIT6,eax,TRUE
			
		.else
			
			; Editing...
			
			; Get the treeview item custom data.
			mov tvi._mask,TVIF_PARAM
			mov tvi.hItem,eax
			mov tvi.lParam,NULL
			invoke SendDlgItemMessage,hMain,IDC_TREE1,TVM_GETITEM,0,addr tvi
			mov eax,tvi.lParam
			.if eax
				
				; Allocate a new memory chunk to make a copy.
				mov ecx,[eax + 4]
				add ecx,8
				push ecx
				invoke LocalAlloc,LPTR,ecx
				pop ecx
				test eax,eax
				jz oops
				mov pData,eax
				
				; Copy the custom data.
				invoke RtlMoveMemory,eax,tvi.lParam,ecx
				
				; Store it as a window property.
				invoke SetProp,hWnd,offset szResources,pData
				test eax,eax
				jnz ok
				
			.endif
			
			; Close the dialog box on error.
	oops:	invoke EndDialog,hWnd,IDCANCEL
			
		.endif
		
		; Return.
	ok:	push TRUE
		pop eax
		ret
		
	.endif
	xor eax,eax
	ret
	
BinaryProc endp

align DWORD
PickResProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local hFile		:HFILE
	local pDynamic	:DWORD
	local dwRead	:DWORD
	local dwDynamic	:DWORD
	local qwSize[2]	:DWORD
	local lvi		:LVITEM
	local xHeader1	:RES_HEADER_1
	local xHeader2	:RES_HEADER_2
	local szNum[20]	:CHAR
	
	mov eax,uMsg
	.if eax == WM_COMMAND
		mov eax,wParam
		cmp eax,IDCANCEL
		je close
		.if eax == IDOK
			
			
			
			; Close the dialog box.
	close:	invoke EndDialog,hWnd,wParam
			
		.endif
		
	.elseif eax == WM_REFRESH
		
		; Clear the listview control.
		invoke SendDlgItemMessage,hWnd,IDC_LIST1,LVM_DELETEALLITEMS,0,0
		
		; Get the file handle.
		invoke GetWindowLong,hWnd,DWL_USER
		mov hFile,eax
		
		; Skip the first 32 bytes of the .RES file.
		invoke SetFilePointer,hFile,20h,0,FILE_BEGIN
		
		; Get the file size.
		invoke GetFileSize,hFile,addr [qwSize + 4]
		sub eax,20h
		sbb [qwSize + 4],0
		mov [qwSize + 0],eax
		
		; For each resource...
		.repeat
			
			; Read the data and header sizes.
			invoke ReadFile,hFile,addr xHeader1,sizeof xHeader1,addr dwRead,NULL
			.break .if !eax || dwRead != sizeof xHeader1
			
			; Substract the header size from the file size.
			; This also acts as a boundary check.
			mov eax,xHeader1.dwHeaderSize
			sub [qwSize + 0],eax
			sbb [qwSize + 4],0
			jg @F
			jnz badfile
			cmp [qwSize + 0],0
			jne @F
badfile:	invoke EndDialog,hWnd,-1
			.break
@@:			
			; Allocate memory for the dynamic part of the header.
			sub eax,(sizeof xHeader1) + (sizeof xHeader2)
			jle badfile
			mov dwDynamic,eax
			invoke LocalAlloc,LPTR,eax
			test eax,eax
			jz badfile
			mov pDynamic,eax
			
			; Read the dynamic part of the header.
			lea edx,dwRead
			invoke ReadFile,hFile,eax,dwDynamic,edx,NULL
			mov edx,dwDynamic
			.if eax && dwRead == edx
				
				; Read the second part of the header.
				invoke ReadFile,hFile,addr xHeader2,sizeof xHeader2,addr dwRead,NULL
				test eax,eax
				jz badfile2
				cmp dwRead,sizeof xHeader2
				jne badfile2
				
				; Insert the new listview item (subitem 0 - name).
				mov lvi.imask,LVIF_TEXT or LVIF_PARAM
				invoke SendDlgItemMessage,hWnd,IDC_LIST1,LVM_GETITEMCOUNT,0,0
				mov lvi.iItem,eax
				mov lvi.iSubItem,0
				invoke SetFilePointer,hFile,0,0,FILE_CURRENT
				mov lvi.lParam,eax
				mov edx,pDynamic
				.if word ptr [edx] == 0FFFFh
					add edx,4
				.else
					invoke lstrlenW,edx
					add edx,2
					mov eax,LVM_INSERTITEMW
				.endif
				.if word ptr [edx] == 0FFFFh
					movzx eax,word ptr [edx + 2]
					lea edx,szNum
					push edx
					invoke wsprintf,edx,offset szFmtInt,eax
					pop edx
					mov eax,LVM_INSERTITEM
				.endif
				mov lvi.pszText,edx
				lea edx,lvi
				invoke SendDlgItemMessage,hWnd,IDC_LIST1,eax,0,edx
				test eax,eax
				js badfile2
				mov lvi.iItem,eax
				
				; Set subitem 1 - type.
				mov lvi.imask,LVIF_TEXT
				inc lvi.iSubItem
				mov edx,pDynamic
				.if word ptr [edx] == 0FFFFh
					movzx eax,word ptr [edx + 2]
					lea edx,szNum
					push edx
					invoke wsprintf,edx,offset szFmtInt,eax
					pop edx
					mov eax,LVM_SETITEMW
				.else
					mov eax,LVM_SETITEM
				.endif
				mov lvi.pszText,edx
				lea edx,lvi
				invoke SendDlgItemMessage,hWnd,IDC_LIST1,eax,0,edx
;				test eax,eax
;				jz badfile2
				
				; Set subitem 2 - lang.
				inc lvi.iSubItem
				movzx eax,xHeader2.wLanguage
				lea edx,szNum
				mov lvi.pszText,edx
				invoke wsprintf,edx,offset szFmtInt,eax
				invoke SendDlgItemMessage,hWnd,IDC_LIST1,LVM_SETITEM,0,addr lvi
;				test eax,eax
;				jz badfile2
				
				; Set subitem 3 - size.
				inc lvi.iSubItem
				lea eax,szNum
				mov lvi.pszText,eax
				invoke wsprintf,eax,offset szFmtInt,xHeader1.dwDataSize
				invoke SendDlgItemMessage,hWnd,IDC_LIST1,LVM_SETITEM,0,addr lvi
;				test eax,eax
;				jz badfile2
				
			.else
				
				; On error, release the memory and quit.
badfile2:		invoke LocalFree,pDynamic
				jmp badfile
				
			.endif
			
			; Free the dynamic part of the header.
			invoke LocalFree,pDynamic
			
			; Skip the resource data.
			invoke SetFilePointer,hFile,xHeader1.dwDataSize,0,FILE_CURRENT
			test eax,eax
			jz badfile
			mov eax,xHeader1.dwDataSize
			sub [qwSize + 0],eax
			sbb [qwSize + 4],0
			jg @F
			jnz badfile
			cmp [qwSize + 0],0
			.break .if zero?
@@:			
		.until FALSE
		
	.elseif eax == WM_INITDIALOG
		
		; Keep the file handle.
		invoke SetWindowLong,hWnd,DWL_USER,lParam
		
		; Insert the listview columns.
		invoke SendDlgItemMessage,hWnd,IDC_LIST1,LVM_INSERTCOLUMN,0,offset lvc0
		invoke SendDlgItemMessage,hWnd,IDC_LIST1,LVM_INSERTCOLUMN,1,offset lvc1
		invoke SendDlgItemMessage,hWnd,IDC_LIST1,LVM_INSERTCOLUMN,2,offset lvc2
		invoke SendDlgItemMessage,hWnd,IDC_LIST1,LVM_INSERTCOLUMN,3,offset lvc3
		
		; Load the .RES file.
		invoke SendMessage,hWnd,WM_REFRESH,0,0
		
		; Return.
		push TRUE
		pop eax
		ret
		
	.endif
	xor eax,eax
	ret
	
PickResProc endp

align DWORD
MainProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local pStr:DWORD
	local dwID:DWORD
	local tvi:TVITEM
	local tvh:TVHITTESTINFO
	local rect:RECT
	local szTemp[MAX_PATH + 32]:BYTE
	
	mov eax,uMsg
	.if eax == WM_NOTIFY
		mov edx,lParam
		mov eax,[edx].NMHDR.code
		.if eax == TVN_DELETEITEM
			
			; Get the item's info.
			mov eax,[edx].NMTREEVIEW.itemOld.hItem
			mov tvi._mask,TVIF_PARAM
			mov tvi.hItem,eax
			mov tvi.lParam,NULL
			invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_GETITEM,0,addr tvi
			.if eax
				
				; Free the memory block.
				mov eax,tvi.lParam
				.if eax
					invoke LocalFree,eax
				.endif
				
			.endif
			
		.elseif eax == TVN_KEYDOWN
			movzx eax,[edx].NMTVKEYDOWN.wVKey
			.if eax == VK_DELETE
				
				; Send a "delete" command message,
				; and process similarly to VK_SPACE.
				push 0
				push ID_RES_DELETE
				jmp @F
				
			.endif
			.if eax == VK_SPACE
				
				; Send an "edit" command message.
				push 0
				push ID_RES_EDIT
			@@:	push WM_COMMAND
				push hWnd
				call SendMessage
				
				; Prevent further processing of this message.
				invoke SetWindowLong,hWnd,DWL_MSGRESULT,TRUE
				push TRUE
				pop eax
				ret
				
			.endif
			
		.elseif (eax == NM_RCLICK) || (eax == NM_DBLCLK)
			
			; Did it happen in our treeview?
			.if [edx].NMHDR.idFrom == IDC_TREE1
				
				; Get the cursor coordinates on the screen.
				invoke GetCursorPos,addr rect
				
				; Did the user click an item? If so, select it.
				push rect.top
				push rect.left
				pop tvh.pt.x
				pop tvh.pt.y
				invoke GetDlgItem,hWnd,IDC_TREE1
				lea edx,tvh.pt
				invoke ScreenToClient,eax,edx
				mov tvh.flags,0
				mov tvh.hItem,NULL
				invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_HITTEST,0,addr tvh
				mov eax,tvh.hItem
				.if eax
					invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_SELECTITEM,TVGN_CARET,eax
				.endif
				
				; Was it a right click or a double click?
				mov edx,lParam
				.if [edx].NMHDR.code == NM_RCLICK		; Right click.
					
					; Get the context menu handle.
					invoke GetMenu,hWnd
					invoke GetSubMenu,eax,1
					
					; Show the context menu.
					invoke ShowContextMenu,hWnd,eax,rect.left,rect.top
					
				.else									; Double click.
					
					; Send an "edit" command message.
					invoke SendMessage,hWnd,WM_COMMAND,ID_RES_EDIT,0
					
				.endif
				
				; Prevent further processing of this message.
				invoke SetWindowLong,hWnd,DWL_MSGRESULT,TRUE
				push TRUE
				pop eax
				ret
				
			.endif
			
		.endif
	.elseif eax == WM_COMMAND
		mov eax,wParam
		.if eax == ID_FILE_NEW
			
			; Close the current file.
			invoke SendMessage,hWnd,WM_PROMPTSAVE,0,0
			.if eax != IDCANCEL
				
				; Clear the treeview.
				invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_DELETEITEM,0,TVI_ROOT
				
				; Reset the global variables.
				mov bHasName,FALSE
				mov bChanged,FALSE
				inc dwUntitled
				invoke wsprintf,offset szFilename,offset szUntitled,dwUntitled
				
				; Set the new main window caption.
				invoke SendMessage,hWnd,WM_UPDATECAPTION,0,0
				
				; Return TRUE to caller.
				invoke SetWindowLong,hWnd,DWL_MSGRESULT,TRUE
				push TRUE
				pop eax
				ret
				
			.endif
		.elseif eax == ID_FILE_OPEN
			
			; Get the file name to open.
			invoke SendMessage,hWnd,WM_SETINITDIR,0,0
			lea eax,szTemp
			mov ofn1.lpstrFile,eax
			mov szTemp[0],0
			.if bHasName
				invoke lstrcpyn,eax,offset szFilename,MAX_PATH
			.endif
			invoke GetOpenFileName,offset ofn1
			.if eax
				
				; Close the current file.
				invoke SendMessage,hWnd,WM_PROMPTSAVE,0,0
				.if eax != IDCANCEL
					
					; Set the global variables.
					mov bChanged,FALSE
					mov bHasName,TRUE
					invoke lstrcpyn,offset szFilename,addr szTemp,MAX_PATH
					
					; Set the new main window caption.
					invoke SendMessage,hWnd,WM_UPDATECAPTION,0,0
					
					; Load the file.
					invoke GetDlgItem,hWnd,IDC_TREE1
					invoke LoadUIFile,eax
					
				.endif
			.endif
		.elseif eax == ID_FILE_SAVE
			
			; Get the filename to save, if needed.
			.if !bHasName
				invoke SendMessage,hWnd,WM_SETINITDIR,0,0
				.if szFilename[0] != 0
					invoke PathFindFileName,offset szFilename
					.if eax != offset szFilename
						push eax
						push offset szFilename
						invoke lstrcpy,offset szInitialDir,offset szFilename
						call lstrcpy
					.endif
				.endif
				invoke GetSaveFileName,offset ofn2
				.if !eax
					
					; Return IDCANCEL on user cancel.
					invoke SetWindowLong,hWnd,DWL_MSGRESULT,IDCANCEL
					push TRUE
					pop eax
					ret
					
				.endif
			.endif
			
			; Set the global variables.
			mov bChanged,FALSE
			mov bHasName,TRUE
			
			; Save the file.
			invoke GetDlgItem,hWnd,IDC_TREE1
			invoke SaveUIFile,eax
			.if !eax
				mov bChanged,TRUE
				mov bHasName,FALSE
				invoke MessageBox,
				 	hWnd,offset szSaveHasFailed,offset szError,MB_OK or MB_ICONERROR
			.endif
			
			; Set the new main window caption.
			invoke SendMessage,hWnd,WM_UPDATECAPTION,0,0
			
			; Return IDYES.
			invoke SetWindowLong,hWnd,DWL_MSGRESULT,IDYES
			push TRUE
			pop eax
			ret
			
		.elseif eax == ID_FILE_SAVEAS
			
			; Invalidate the filename and save.
			push bHasName
			mov bHasName,FALSE
			invoke SendMessage,hWnd,WM_COMMAND,ID_FILE_SAVE,0
			pop eax
			or bHasName,eax
			
		.elseif eax == IDCANCEL
			
			; Close the current file.
			invoke SendMessage,hWnd,WM_PROMPTSAVE,0,0
			.if eax != IDCANCEL
				
				; Close the current file and quit.
				invoke EndDialog,hWnd,wParam
				
			.endif
		.elseif eax == ID_RES_NEWLANG
			
			; Launch dialog box.
			invoke DialogBoxParam,hInst,IDD_NEWLANG,hWnd,offset NewLangProc,0
			jmp changed
			
		.elseif eax == ID_RES_NEWSTRING
			
			; Only makes sense if there is at least one language.
			invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_GETCOUNT,0,0
			.if eax != 0
				
				; Launch dialog box.
				invoke DialogBoxParam,hInst,IDD_NEWSTRING,hWnd,offset NewStringProc,0
				jmp changed
				
			.endif
			
		.elseif eax == ID_RES_NEWBIN
			
			; Only makes sense if there is at least one language.
			invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_GETCOUNT,0,0
			.if eax != 0
				
				; Launch dialog box.
				invoke DialogBoxParam,hInst,IDD_BINARY,hWnd,offset BinaryProc,NULL
				jmp changed
				
			.endif
			
		.elseif eax == ID_RES_EDIT
			
			; Get the currently selected item.
			invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_GETNEXTITEM,TVGN_CARET,TVI_ROOT
			.if eax
				mov tvi.hItem,eax
				
				; Get the item's info.
				mov tvi._mask,TVIF_IMAGE
				invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_GETITEM,0,addr tvi
				.if eax
					
					; What are we trying to edit?
					mov eax,tvi.iImage
					.if eax == 2						; Binary
						
						; Launch dialog box.
						invoke DialogBoxParam,
						 		hInst,IDD_BINARY,hWnd,offset BinaryProc,tvi.hItem
						
					.else;if eax == 0 || eax == 1		; Language or String
						
						; Launch dialog box.
						invoke DialogBoxParam,
						 		hInst,IDD_STRING,hWnd,offset EditStringProc,tvi.hItem
						
					.endif
					
					; Did the user make changes?
		changed:	.if eax == IDOK
						
						; Mark the file as modified.
						mov bChanged,TRUE
						invoke SendMessage,hWnd,WM_UPDATECAPTION,0,0
						
					.endif
				.endif
			.endif
			
		.elseif eax == ID_RES_DELETE
			
			; Get the currently selected item.
			invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_GETNEXTITEM,TVGN_CARET,TVI_ROOT
			.if eax
				mov tvi.hItem,eax
				
				; Get the item's info.
				mov tvi._mask,TVIF_IMAGE or TVIF_PARAM
				mov tvi.lParam,NULL
				invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_GETITEM,0,addr tvi
				.if tvi.lParam
					
					; What are we trying to delete?
					.if tvi.iImage == 0					; Language
						
						; Confirm first.
						invoke MessageBox,
						 	hWnd,offset szDeleteLang,offset szAreYouSure,
						 	MB_YESNO or MB_DEFBUTTON2 or MB_ICONQUESTION 
						.if eax == IDYES
							
							; Just delete it.
							invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_DELETEITEM,0,tvi.hItem
							
							; Mark the file as modified.
							mov bChanged,TRUE
							invoke SendMessage,hWnd,WM_UPDATECAPTION,0,0
							
						.endif
						
					.else								; Resource
						
						; Confirm first.
						invoke MessageBox,
						 	hWnd,offset szDeleteRes,offset szAreYouSure,
						 	MB_YESNOCANCEL or MB_DEFBUTTON3 or MB_ICONQUESTION 
						.if eax == IDYES
							
							; We must delete the same resource in every language.
							mov eax,tvi.lParam
							push dword ptr [eax]
							pop dwID
							
							; For each language...
							invoke SendDlgItemMessage,
							 	hWnd,IDC_TREE1,TVM_GETNEXTITEM,TVGN_CHILD,TVI_ROOT
							.while eax
								mov tvi.hItem,eax
								
								; Delete the resource.
								invoke FindByID,eax,dwID
								.if eax
									invoke SendDlgItemMessage,
									 	hWnd,IDC_TREE1,TVM_DELETEITEM,0,eax
								.endif
								
								; Next language.
								invoke SendDlgItemMessage,
								 	hWnd,IDC_TREE1,TVM_GETNEXTITEM,TVGN_NEXT,tvi.hItem
								
							.endw
							
							; Mark the file as modified.
							mov bChanged,TRUE
							invoke SendMessage,hWnd,WM_UPDATECAPTION,0,0
							
						.elseif eax == IDNO
							
							; Delete this resource only form this language.
							invoke SendDlgItemMessage,
							 	hWnd,IDC_TREE1,TVM_GETNEXTITEM,TVGN_CARET,TVI_ROOT
							.if eax
								invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_DELETEITEM,0,eax
							.endif
							
						.endif
						
					.endif
				.endif
			.endif
			
		.endif
		
	.elseif eax == WM_SIZE
		
		; Resize child treeview when parent is resized.
		invoke GetClientRect,hWnd,addr rect
		.if eax
			invoke GetDlgItem,hWnd,IDC_TREE1
			.if eax
				invoke MoveWindow,eax,0,0,rect.right,rect.bottom,TRUE
			.endif
		.endif
		
	.elseif eax == WM_UPDATECAPTION
		
		; Set the new main window caption.
		invoke lstrcpy,addr szTemp,offset szCaption0
		invoke lstrcat,addr szTemp,offset szCaption1
		invoke lstrcat,addr szTemp,offset szFilename
		invoke lstrcat,addr szTemp,offset szCaption2
		.if bChanged
			invoke lstrcat,addr szTemp,offset szCaption3
		.endif
		invoke SetWindowText,hWnd,addr szTemp
		
	.elseif eax == WM_SETINITDIR
		
		; Set the initial directory.
		.if bHasName
			invoke lstrcpy,offset szInitialDir,offset szFilename
			invoke PathRemoveFileSpec,offset szInitialDir
		.elseif szInitialDir[0] == 0
			invoke GetModuleFileName,hInst,offset szInitialDir,sizeof szInitialDir
			invoke PathRemoveFileSpec,offset szInitialDir
			invoke PathAppend,offset szInitialDir,offset szUI
		.endif
		
	.elseif eax == WM_PROMPTSAVE
		
		; Prompt the user if the current file has changes.
		mov eax,IDYES
		.if bChanged
			invoke MessageBox,hWnd,offset szSaveChanges,offset szAreYouSure,MB_YESNOCANCEL
			.if eax == IDYES
				
				; Save the changes.
				invoke SendMessage,hWnd,WM_COMMAND,ID_FILE_SAVE,0
				
			.endif
		.endif
		
		; Return the user's answer.
		invoke SetWindowLong,hWnd,DWL_MSGRESULT,eax
		push TRUE
		pop eax
		ret
		
	.elseif eax == WM_INITDIALOG
		
		; Keep the window handle.
		mov eax,hWnd
		mov hMain,eax
		mov ofn1.hWndOwner,eax
		mov ofn2.hWndOwner,eax
		
		; Load and set the main dialog box icon.
		push LR_DEFAULTCOLOR
		invoke GetSystemMetrics,SM_CYSMICON
		push eax
		invoke GetSystemMetrics,SM_CXSMICON
		push eax
		push IMAGE_ICON
		push IDI_ICON1
		push hInst
		call LoadImage
		invoke SendMessage,hWnd,WM_SETICON,ICON_SMALL,eax
		
		; Load and set the treeview's image list.
		invoke ImageList_LoadImage,hInst,IDB_ICONS,16,3,00FF00FFh,IMAGE_BITMAP,0
		invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_SETIMAGELIST,TVSIL_NORMAL,eax
		
		; Get the commandline arguments.
		invoke GetCommandLine
		invoke PathGetArgs,eax
		.if eax
			mov pStr,eax
			invoke lstrlen,eax
			test eax,eax
			jz @F
			
			; Copy the filename and remove any extra parameters.
			invoke lstrcpyn,offset szFilename,pStr,sizeof szFilename
			invoke PathRemoveArgs,offset szFilename
			invoke PathUnquoteSpaces,offset szFilename
			invoke GetFullPathName,
			 	offset szFilename,sizeof szFilename,offset szFilename,addr dwID
			invoke PathMakePretty,offset szFilename
			
			; Is it an existent file?
			invoke PathFileExists,offset szFilename
			test eax,eax
			jz @F
			
			; Set the global variables.
			mov bChanged,FALSE
			mov bHasName,TRUE
			
			; Set the new main window caption.
			invoke SendMessage,hWnd,WM_UPDATECAPTION,0,0
			
			; Load the file.
			invoke GetDlgItem,hWnd,IDC_TREE1
			invoke LoadUIFile,eax
			
		.else
			
			; Start with a new file.
		@@:	invoke SendMessage,hWnd,WM_COMMAND,ID_FILE_NEW,0
			
		.endif
		
		; Set the window show state requested on program load.
		invoke ShowWindow,hWnd,SW_SHOWDEFAULT
		
		; Return.
		push TRUE
		pop eax
		ret
		
	.elseif eax == WM_DESTROY
		
		; Remove and destroy the treeview's image list.
		invoke SendDlgItemMessage,hWnd,IDC_TREE1,TVM_SETIMAGELIST,TVSIL_NORMAL,NULL
		invoke ImageList_Destroy,eax
		
	.endif
@q:	xor eax,eax
	ret
	
MainProc endp

align DWORD
Start proc
	
	; Initialize the common controls library.
	invoke InitCommonControls
	
	; Get the program's instance handle.
	invoke GetModuleHandle,NULL
	mov hInst,eax
	mov ofn1.hInstance,eax
	mov ofn2.hInstance,eax
	mov ofn3.hInstance,eax
	mov ofn4.hInstance,eax
	
	; Load the font for the "hex" edit box.
	invoke CalcFontHeight,10
	mov logfont.lfHeight,eax
	invoke CreateFontIndirect,offset logfont
	mov hFont,eax
	
	; Launch the main dialog box as modal.
	invoke DialogBoxParam,hInst,IDD_MAIN,0,offset MainProc,0
	
	; Delete the font object.
	invoke DeleteObject,hFont
	
	; Quit.
	invoke ExitProcess,0
	
Start endp

end Start
