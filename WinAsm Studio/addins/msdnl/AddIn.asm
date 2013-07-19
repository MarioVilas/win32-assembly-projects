.386

.MODEL FLAT,STDCALL

OPTION CASEMAP:NONE

Include WINDOWS.INC

; -----------------------------------------------------------------------
uselib	MACRO	libname
	include		libname.inc
	includelib	libname.lib
ENDM
; -----------------------------------------------------------------------

uselib	user32
uselib	kernel32
;uselib  masm32
;uselib  debug
 
Include	\WinAsm\Inc\WAAddIn.inc
Include	data.inc


ACCELERATOR STRUCT
	fVirt	WORD ? 
	key		WORD ? 
	cmd		WORD ?
ACCELERATOR ENDS

.CODE

DllEntry Proc hInst:HINSTANCE, reason:DWORD, reserved1:DWORD
	.If reason==DLL_PROCESS_ATTACH
		push hInst
		pop hInstance
	.EndIf
	MOV EAX,TRUE
	RET
DllEntry EndP

GetWAAddInData Proc lpFriendlyName:PTR BYTE, lpDescription:PTR BYTE
	Invoke lstrcpy, lpDescription, Offset szDescription
	Invoke lstrcpy, lpFriendlyName, Offset szFriendlyName      ; Name of Add-In
	RET
GetWAAddInData EndP
AddNewAcceleratorEntry Proc Uses ESI EDI EBX
Local hOldAccelAcceleratorTable:HWND

	MOV ECX,pHandles
	MOV EAX,[ECX].HANDLES.phAcceleratorTable
	;Now EAX is phAcceleratorTable
	MOV ECX,[EAX]	;Now ECX is the handle to the Original AcceleratorTable
	
	.If ECX	;<---------In case any other loaded Add-In """Disabled all Add-Ins"""
		MOV hOldAccelAcceleratorTable,ECX
		
		Invoke CopyAcceleratorTable,ECX,0,0
		;Now EAX is the number of of accelerator-table entries in the original table
		
		INC EAX		;i.e add one more entry
		MOV EBX,EAX
		
		MOV ECX,SizeOf ACCELERATOR
		MUL ECX
		
		;Now EAX is the number of bytes of the new table we will create
		MOV ESI,EAX
		
		Invoke GetProcessHeap
		Invoke HeapAlloc,EAX,HEAP_ZERO_MEMORY,ESI
		MOV EDI,EAX
		
		Invoke CopyAcceleratorTable,hOldAccelAcceleratorTable,EDI,EBX
		
		;Go to the last position of the accelerator table
		SUB ESI,SizeOf ACCELERATOR
		ADD ESI,EDI
		
		MOV EAX,MenuID
		MOV [ESI].ACCELERATOR.cmd,AX
		;PrintDec eAX
		MOV [ESI].ACCELERATOR.key,VK_F1			;<-----Use the key you want
		MOV [ESI].ACCELERATOR.fVirt,FSHIFT or FVIRTKEY;Specify the accelerator flags you want. FALT, FCONTROL, FNOINVERT, FSHIFT, FVIRTKEY
		
		Invoke CreateAcceleratorTable,EDI,EBX
		;Now EAX is hNewAccelAcceleratorTable
		
		MOV ECX,pHandles
		MOV ECX,[ECX].HANDLES.phAcceleratorTable
		MOV [ECX],EAX	;Point to the new AcceleratorTable handle
		
		;Destroy the original Accelerator Table
		Invoke DestroyAcceleratorTable,hOldAccelAcceleratorTable
		
		Invoke GetProcessHeap
		Invoke HeapFree,EAX,HEAP_ZERO_MEMORY,EDI
	;Else
	;	In this sample Add-In I choose not to create a new accelarator table
	;	You may want to """bypass""" the Add-In that already disabled all Add-Ins
	;	and thus create a new accelarator table.
	.EndIf
	
	RET
AddNewAcceleratorEntry EndP

RemoveNewAcceleratorEntry Proc Uses ESI EDI EBX
Local hOldAccelAcceleratorTable:HWND

	MOV ECX,pHandles
	MOV EAX,[ECX].HANDLES.phAcceleratorTable
	MOV ECX,[EAX]	;Now ECX is the handle to the AcceleratorTable
	
	.If ECX
		MOV hOldAccelAcceleratorTable,ECX	;<-----note:This might not be the same with hOldAccelAcceleratorTable in AddNewAcceleratorEntry
		
		Invoke CopyAcceleratorTable,ECX,0,0
		;Now EAX is the number of of accelerator-table entries in the original table
		
		.If EAX	;Look: in case any other loaded Add-In removed all entries
			;we are not decreasing number of entries YET
			MOV EBX,EAX
			INC EAX	;but leave room
			
			MOV ECX,SizeOf ACCELERATOR
			MUL ECX
			
			;Now EAX is the number of bytes in the existing accelerator table + SizeOf ACCELERATOR
			MOV ESI,EAX
			Invoke GetProcessHeap
			Invoke HeapAlloc,EAX,HEAP_ZERO_MEMORY,ESI
			MOV EDI,EAX
			
			Invoke CopyAcceleratorTable,hOldAccelAcceleratorTable,EDI,EBX
			MOV EAX,MenuID
			PUSH EDI
			.While WORD PTR [EDI]
				
				.If [EDI].ACCELERATOR.cmd==AX && [EDI].ACCELERATOR.key==VK_F1 && [EDI].ACCELERATOR.fVirt==(FSHIFT or FVIRTKEY)
					;We found our Accelator!!!!
        			DEC EBX	;i.e. decrease number of accelerators in new table we will create
					
					;Let's move all accelerator entries one position towards the table start
					;and fill the "gap"
					MOV ESI,EDI
					@@:
					ADD ESI,SizeOf ACCELERATOR					
					.If [ESI].ACCELERATOR.cmd && [ESI].ACCELERATOR.key
						Invoke RtlMoveMemory,EDI,ESI,SizeOf ACCELERATOR
						MOV EDI,ESI
						JMP @B
					.EndIf
					JMP AccFound
				.EndIf
				ADD EDI,SizeOf ACCELERATOR
			.EndW
			
			;Our Accelerator Entry was not found, therefore no need to do anything
			POP EDI
			JMP Ex
			
			AccFound:
			POP EDI
			
			Invoke CreateAcceleratorTable,EDI,EBX
			;Now EAX is hNewAccelAcceleratorTable
			
			MOV ECX,pHandles
			MOV ECX,[ECX].HANDLES.phAcceleratorTable
			MOV [ECX],EAX	;Point to the new AcceleratorTable handle
			
			;Destroy the original Accelerator Table
			Invoke DestroyAcceleratorTable,hOldAccelAcceleratorTable
			
			Ex:
			Invoke GetProcessHeap
			Invoke HeapFree,EAX,HEAP_ZERO_MEMORY,EDI
			
		.EndIf
	.EndIf
	RET
RemoveNewAcceleratorEntry EndP

WAAddInLoad Proc Uses EBX pWinAsmHandles:DWORD, features:PTR DWORD
	MOV EBX,pWinAsmHandles
	MOV pHandles,EBX
    M2M hMain,[EBX].HANDLES.hMain
    M2M hClient,[EBX].HANDLES.hClient
    mov eax,[EBX].HANDLES.PopUpMenus.hHelpMenu
    MOV hSubM,EAX
	invoke GetMenuItemCount,eax
    mov cntr,eax
    mov ItemData.MENUITEMINFO.cbSize,sizeof MENUITEMINFO
    mov ItemData.MENUITEMINFO.fMask,MIIM_ID
@@: sub cntr,1
    js  @F
    invoke GetMenuItemInfo,hSubM,cntr,TRUE,offset ItemData
	cmp ItemData.MENUITEMINFO.wID,IDM_HELP_HELPCONTENTS
	jne @B
	add cntr,1
@@:
	Invoke SendMessage,hMain,WAM_GETNEXTMENUID, 0, 0
	MOV MenuID,EAX
	Invoke InsertMenu,hSubM,cntr,MF_BYPOSITION or MF_OWNERDRAW,eax,\
	                                                  offset menutxt
	
	;*******************************************
	Invoke AddNewAcceleratorEntry
	;*******************************************
	XOR EAX,EAX
	RET
WAAddInLoad EndP

FrameWindowProc Proc  hWnd:DWORD, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	.If uMsg == WM_COMMAND
		HIWORD wParam
		.If EAX == 0 || 1
			LOWORD wParam
			.If EAX == MenuID
              invoke SendMessage,hClient,WM_MDIGETACTIVE,0,0
                .if EAX
    	            Invoke GetWindowLong,EAX,0
                    mov eax,[eax].CHILDDATA.hEditor
                    mov hEditor,eax
                    mov wbuff[0],0		;In case CHM_GETWORD fails
                    invoke SendMessage,hEditor,CHM_GETWORD,63,ADDR wbuff
if QuasiModo
                    .if wbuff[0] != 0
                        call solver		;Only if there's actually a word
                        ret				;On error let WinAsm or other addins process the message
                    .endif
else
                    call solver ; if buffer empty - just switch to MSDN
endif                    
                .endif
				MOV EAX,TRUE
				RET
			.EndIf
		.EndIf
    .elseif uMsg == WM_INITMENUPOPUP
        mov eax,hSubM
        .if wParam == eax
          invoke SendMessage,hClient,WM_MDIGETACTIVE,NULL,NULL
          .if eax
            invoke IsWindowVisible,eax
            .if eax
              invoke EnableMenuItem,hSubM,MenuID,MF_ENABLED
              jmp ex1
            .endif
          .endif
        .endif
        invoke EnableMenuItem,hSubM,MenuID,MF_GRAYED
ex1:	
	.endif
	XOR EAX,EAX
	RET
FrameWindowProc EndP

if QuasiModo

solver proc
	
	; MSDN Library (January 2004, in english)
	; DEXPLORE.EXE
	;
	; MSDN IDE window:
	;	Class:		IDEOwner
	;	Caption:	MSDN Library - <library version goes here> - <page title goes here>
	;
	;	I don't really know what this one does. Perhaps some programs send messages to it.
	;
	; MSDN Desktop window:
	;	Class:		wndclass_desked_gsk
	;	Caption:	MSDN Library - <library version goes here> - <page title goes here>
	;
	;	It's the main window, all others (except IDEOwner) descend from it.
	;	Unfortunately it doesn't have a standard menu, so I couldn't obtain it's command IDs.
	;
	; Generic pane:
	;	Class:		GenericPane
	;	Captions:	"Contents", "Index", "Search" or "Favorites"
	;
	;	It has a default-class child dialog box, we need to manipulate it's controls.
	;
	; Controls in "Contents" pane by ID
	;	0995h		"Filtered by" combo box
	;	FEEDh		Contents treeview
	;
	; Controls in "Index" pane by ID
	;	0995h		"Filtered by" combo box
	;	0996h		"Look for" combo box
	;	F00Dh		Topics list (classname hx_winclass_vlist)
	;
	; Controls in "Search" pane by ID
	;	0995h		"Filtered by" combo box
	;	0996h		"Look for" combo box
	;	0997h		"Search in titles only" check box
	;	0998h		"Match related words" check box
	;	0999h		"Search on previous results" check box
	;	099Ah		"Highlight search hits (in topics)" check box
	;
	; Controls in "Favorites" pane by ID
	;	<no ID>		Toolbar (classname MsoCommandBar)
	;	0064h		Favorites treeview
	
	; Find the MSDN desktop window
	invoke FindWindow,offset msdnclass,0
	test eax,eax	;cmp eax,0
	jz @F			;je @F
	mov msdnw,eax
	; Maximize, activate, set focus and send to foregound
;	invoke ShowWindow,eax,SW_SHOWMAXIMIZED
;	invoke SetActiveWindow,msdnw
	invoke SetForegroundWindow,msdnw
	invoke SetFocus,msdnw
	; Find the "Search" pane
	invoke FindWindowEx,msdnw,0,offset gpane,offset srch	;this won't work on non-english versions!
	test eax,eax
	jz @F
	mov lstpn,eax
	; If the "Search" pane was hidden, show it
;	invoke GetMenu,msdnw					;get main menu bar (DOESN'T WORK)
;	test eax,eax
;	jz @F
;	invoke GetSubMenu,eax,2					;"View" popup menu
;	test eax,eax
;	jz @F
;	invoke GetSubMenu,eax,1					;"Navigation" popup menu
;	test eax,eax
;	jz @F
;	push eax
;	invoke GetMenuState,eax,2,MF_BYPOSITION	;"Search" menu item
;	pop edx
;	test eax,MF_CHECKED
;	.if !zero?
;		invoke GetMenuItemID,edx,2
;		test eax,eax
;		jz @F
;		invoke SendMessage,msdnw,WM_COMMAND,eax,0
;	.endif
	; Find the dialog inside the pane
	invoke FindWindowEx,lstpn,0,32770,0
	test eax,eax
	jz @F
	mov lsdlg,eax
	; Put the keyword to search in the combo box
	invoke SendDlgItemMessage,eax,996h,WM_SETTEXT,0,offset wbuff
;	invoke SetDlgItemText,eax,996h,offset wbuff		;doesn't work on combo boxes (?)
	test eax,eax
	jz @F
	; Uncheck "Search on previous results"
	invoke CheckDlgButton,lsdlg,999h,BST_UNCHECKED
	; Click on the "Search" button
	invoke SendDlgItemMessage,lsdlg,993h,BM_CLICK,0,0
	; We're done :)
	push TRUE
	pop eax
@@:	ret
solver endp

else

solver proc
    mov dword ptr msdnw,0
    invoke FindWindow,ADDR msdnclass,0
    .if eax == 0
      invoke MessageBox,hMain,ADDR nfnd,ADDR hello,0
    .else 
	  mov msdnw,eax
      invoke ShowWindow,eax,SW_SHOWMAXIMIZED
      invoke SetForegroundWindow,msdnw
      invoke FindWindowEx,msdnw,0,offset gpane,ADDR indx
      .if eax == 0
        jmp @F
      .endif
      mov lstpn,eax
	  invoke SendMessage,eax,WM_ACTIVATE,WA_ACTIVE,0
      invoke FindWindowEx,lstpn,0,0,0
      .if eax == 0
        jmp @F
      .endif
      mov lsdlg,eax  
	  invoke SendMessage,eax,WM_ACTIVATE,WA_ACTIVE,0
	  invoke GetDlgItem,lsdlg,cmbbxID
      .if eax == 0
        jmp @F
      .endif
      mov cmbbx,eax
	  invoke SendMessage,cmbbx,WM_SETTEXT,0,ADDR wbuff
	  invoke SendMessage,cmbbx,WM_ACTIVATE,WA_ACTIVE,0
	  invoke SendMessage,msdnw,WM_ACTIVATEAPP,TRUE,0
      invoke SetActiveWindow,lstpn  
	  invoke SendMessage,cmbbx,WM_SETFOCUS,0,0
    .endif 
	ret
@@: invoke MessageBox,0,ADDR nidx,ADDR hello,0
    ret
solver endp

endif

WAAddInUnload Proc

	;*******************************
	Invoke RemoveNewAcceleratorEntry
	;*******************************	
	
	Invoke DeleteMenu,hSubM,MenuID,MF_BYCOMMAND
	RET
WAAddInUnload EndP

End DllEntry
