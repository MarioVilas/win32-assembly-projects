;------------------------------------------------------------------------------
; CreateDockingWindow
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Creates a docking window, reading it's position and style bits from the
;	 addin's INI file.
;
; Parameters:
;	pDockingData		Pointer to a DOCKINGDATA structure. Must be allocated
;	 					 in static memory, and initialized with default values.
;	dwStyle				Default style bits for the docking window.
;	pszDockingDataKey	Optional: pointer to ASCIIZ string with the keyname in
;	 					 the addins INI file from which to take the docking
;	 					 window's initial position.
;	pszDockingStyleKey	Optional: pointer to ASCIIZ string with the keyname in
;	 					 the addins INI file from which to take the docking
;	 					 window's style bits.
;
; Return values:
;	On success, the handle to the newly created window is returned.
;	On error, the return value is NULL.
;
; Remarks:
;	The pszDockingDataKey and pszDockingStyleKey parameters are used to get the
;	 docking window style and position as saved by DestroyDockingWindow. This
;	 feature won't work unless you have provided the pszSection parameter to
;	 InitializeAddIn.
;
;	Only the following window styles will be read from the INI file:
;	 	STYLE_GRADIENTTITLE
;	 	STYLE_TWOLINESTITLE
;	 	STYLE_ONELINETITLE
;	 	WS_DISABLED
;	 	WS_VISIBLE
;
; See also:
;	DestroyDockingWindow
;------------------------------------------------------------------------------

include Common.inc

; How DOCKINGDATA is processed:
;
;	lpCaption			DWORD ?				; } Ignored (4 bytes)
;
;	fDockedTo			DWORD ?				; \
;	NoDock				POSANDSIZE <?>		; |
;	DockTopHeight		DWORD ?				; | Loaded from the INI file
;	DockBottomHeight	DWORD ?				; | (36 bytes)
;	DockLeftWidth		DWORD ?				; |
;	DockRightWidth		DWORD ?				; /
;
;	reserved1			DWORD ?				; \
;	reserved2			DWORD ?				; | Filled with NULLs
;	reserved3			RECT <?>			; | (32 bytes)
;	reserved4			POINT <?>			; /
;
; How POSANDSIZE is processed (after it's read from the INI file):
;
;	dLeft	DD ?		; +2
;	dTop	DD ?		; +2
;	dWidth	DD ?		; no change
;	dHeight	DD ?		; no change

.code
align DWORD
CreateDockingWindow proc uses ebx pDockingData:PTR DOCKINGDATA, dwStyle:DWORD, pszDockingDataKey:PTR BYTE, pszDockingStyleKey:PTR BYTE
	
	; Validate the input
	xor eax,eax
	mov ebx,pHandles
	.if ebx && pFeatures && (szIniFile[0] != 0) && ([ebx].HANDLES.hMain != NULL)
		mov edx,pDockingData
		.if edx
			
			; Zero out the "reserved" fields in DOCKINGDATA
			mov eax,pDockingData
			add eax,4 + 36
			invoke RtlZeroMemory,eax,32
			
			; Read the default window position and style from the INI file
			mov eax,dwStyle
			.if pszSection
				mov edx,pszDockingDataKey
				.if edx
					push eax
					mov eax,pDockingData
					add eax,4
					invoke GetPrivateProfileStruct,pszSection,edx,eax,36,offset szIniFile
					mov eax,pDockingData
					add [eax].DOCKINGDATA.NoDock.dLeft,2
					add [eax].DOCKINGDATA.NoDock.dTop,2
					pop eax
				.endif
				mov edx,pszDockingStyleKey
				.if edx
					invoke GetPrivateProfileInt,pszSection,edx,eax,offset szIniFile
				.endif
			.endif
			
			; Validate the style bits
			and eax,3 or WS_DISABLED or WS_VISIBLE		; Styles read from ini file
			or eax,WS_CHILD
			mov edx,dwStyle								; All other styles set by the developer
			and edx,not (3 or WS_DISABLED or WS_VISIBLE or WS_POPUP or WS_OVERLAPPED)
			or eax,edx
			
			; Create the docking window and return the handle
			invoke SendMessage,[ebx].HANDLES.hMain,WAM_CREATEDOCKINGWINDOW,eax,pDockingData
		.endif
	.endif
	ret
	
CreateDockingWindow endp
end
