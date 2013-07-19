;------------------------------------------------------------------------------
; GetWAButton
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Retrieves as a bitmap a single button from WinAsm image lists.
;
; Parameters:
;	dwIndex		Index to the button to be retrieved in the image list.
;	bColor		TRUE for color images, FALSE for monochrome.
;
; Return values:
;	Nonzero on success, zero on failure.
;
; Remarks:
;	WinAsm Studio version 3.0.5.0 or higher is required.
;
; See also:
;	CountWAButtons, SetWAButton
;------------------------------------------------------------------------------

include Common.inc

.code
align DWORD
GetWAButton proc dwIndex:DWORD, bColor:BOOL
	local hImgList	:HIMAGELIST
	local iiInfo	:IMAGEINFO
	local hBmp		:HBITMAP
	
	; Make sure the index is within range
	invoke CountWAButtons,bColor
	.if (eax != -1) && (eax > dwIndex)
		
		; Get the imagelist handle
		mov eax,pHandles
		.if bColor
			mov eax,[eax].HANDLES.phImlNormal
		.else
			mov eax,[eax].HANDLES.phImlMonoChrome
		.endif
		mov eax,[eax]
		mov hImgList,eax
		
		; Get the original bitmap handle
		invoke ImageList_GetImageInfo,hImgList,dwIndex,addr iiInfo
		.if eax
			
			; Create a new bitmap
			invoke CreateBitmap,
			
		.endif
	.else
		xor eax,eax
	.endif
	ret
	
GetWAButton endp
end
