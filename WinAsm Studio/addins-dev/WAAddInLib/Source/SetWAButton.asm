;------------------------------------------------------------------------------
; SetWAButton
; (C) Mario Vilas (aka QvasiModo)
;------------------------------------------------------------------------------
; Description:
;	Adds or replaces a single button from WinAsm image lists with the given
;	 bitmap.
;
; Parameters:
;	dwIndex		Index to the button to be replaced or added to the image list.
;	bColor		TRUE for color images, FALSE for monochrome.
;	bmImage		Bitmap handle of the new button image.
;
; Return values:
;	Nonzero on success, zero on failure.
;
; Remarks:
;	WinAsm Studio version 3.0.5.0 or higher is required.
;
; See also:
;	CountWAButtons, GetWAButton
;------------------------------------------------------------------------------

include Common.inc

.code
align DWORD
SetWAButton proc dwIndex:DWORD, bColor:BOOL, bmImage:HBITMAP
	
	
	ret
	
SetWAButton endp
end
