;------------------------------------------------------------------------------
; DestroyDockingWindow
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Destroys a docking window, saving it's position and style bits into the
;	 addin's INI file.
;
; Parameters:
;	hWnd				Optional handle to the docking window.
;	pDockingData		Optional pointer to a DOCKINGDATA structure. Must be
;	 					 allocated in static memory.
;	pszDockingDataKey	Optional pointer to ASCIIZ string with the keyname in
;	 					 the addins INI file from which to take the docking
;	 					 window's initial position.
;	pszDockingStyleKey	Optional pointer to ASCIIZ string with the keyname in
;	 					 the addins INI file from which to take the docking
;	 					 window's style bits.
;
; Return values:
;	Nonzero on success, zero on error.
;
; Remarks:
;	All four parameters can't be NULL at the same time. Also if hWnd is NULL
;	 then pDockingData and pszDockingDataKey must be non-NULL.
;
;	The pszDockingDataKey and pszDockingStyleKey parameters are used to store
;	 the docking window style and position, to be read by CreateDockingWindow.
;	 This feature won't work unless you have provided the pszSection parameter to
;	 InitializeAddIn.
;
; See also:
;	CreateDockingWindow
;------------------------------------------------------------------------------

include Common.inc

; How DOCKINGDATA is processed:
;
;	lpCaption			DWORD ?				; } Ignored (4 bytes)
;
;	fDockedTo			DWORD ?				; \
;	NoDock				POSANDSIZE <?>		; |
;	DockTopHeight		DWORD ?				; | Saved to the INI file
;	DockBottomHeight	DWORD ?				; | (36 bytes)
;	DockLeftWidth		DWORD ?				; |
;	DockRightWidth		DWORD ?				; /
;
;	reserved1			DWORD ?				; \
;	reserved2			DWORD ?				; | Ignored
;	reserved3			RECT <?>			; | (32 bytes)
;	reserved4			POINT <?>			; /

.const
szFmtDword db "%d",0

.code
align DWORD
DestroyDockingWindow proc hWnd:HWND, pDockingData:PTR DOCKINGDATA, pszDockingDataKey:PTR BYTE, pszDockingStyleKey:PTR BYTE
	local szNum[20]:BYTE
	
	xor eax,eax
	.if pFeatures
		
		; Save the window position
		mov ecx,pszDockingDataKey
		mov edx,pDockingData
		.if ecx && edx
			add edx,4
			invoke WritePrivateProfileStruct,pszSection,ecx,edx,36,offset szIniFile
		.endif
		
		; Destroy the window
		mov ecx,hWnd
		.if ecx
			push 0
			push 0
			push WAM_DESTROYDOCKINGWINDOW
			push ecx
			.if pszDockingStyleKey
				
				; But first save it's style bits
				invoke GetWindowLong,ecx,GWL_STYLE
				.if eax
					lea edx,szNum
					invoke wsprintf,edx,offset szFmtDword,eax
					.if eax
						invoke WritePrivateProfileString,pszSection,pszDockingStyleKey,addr szNum,offset szIniFile
					.endif
				.endif
				
			.endif
			call SendMessage
			
			; WAM_DESTROYDOCKINGWINDOW returns always zero???
			push TRUE
			pop eax
		.endif
	.endif
	ret
	
DestroyDockingWindow endp
end
