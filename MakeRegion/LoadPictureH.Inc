comment ® ---------------------------------------------

Loads a picture from a file.
05-Aug-04

Parameters:
    - pFile     Pointer to ASCIIZ string with full or relative pathname.
    - rgbBack   COLORREF with RGB components of background color.
                Used with transparent images (for example transparent GIF pictures).
    - pdib      Pointer to DIBSECTION structure to be filled on function return.
                It is not necessary to set the DIBSECTION.dsBmih.biSize member.

When the "pdib" parameter is supplied, the created bitmap is always a 24-bit DIB.
  A file mapping object is used (this minimizes kernel memory usage).
  The calling application should free the file mapping object before deleting the bitmap.

When the "pdib" parameter is NULL, a screen compatible bitmap is created.

----------------------------------------------------- ®

IFNDEF IUnknown
IUnknown struct
    QueryInterface          DWORD   ?
    AddRef                  DWORD   ?
    Release                 DWORD   ?
IUnknown ends
ENDIF

IFNDEF IPicture
IPicture struct
    QueryInterface          DWORD   ?   ; IUnknown
    AddRef                  DWORD   ?
    Release                 DWORD   ?
    get_Handle              DWORD   ?   ; IPicture
    get_hPal                DWORD   ?
    get_Type                DWORD   ?
    get_Width               DWORD   ?
    get_Height              DWORD   ?
    Render                  DWORD   ?	
    set_hPal                DWORD   ?
    get_CurDC               DWORD   ?
    SelectPicture           DWORD   ?
    get_KeepOriginalFormat  DWORD   ?
    put_KeepOriginalFormat  DWORD   ?
    PictureChanged          DWORD   ?
    SaveAsFile              DWORD   ?
    get_Attributes          DWORD   ?
IPicture ends
ENDIF

IFNDEF HIMETRIC_INCH
HIMETRIC_INCH equ 2540
ENDIF

IFNDEF IID_IPicture
.data
IID_IPicture GUID {07BF80980h,0BF32h,0101Ah,{08Bh,0BBh,000h,0AAh,000h,030h,00Ch,0ABh}}
ENDIF

.code
align DWORD
LoadPictureH proc uses ebx esi edi pFile,rgbBack,pdib
    local pName     :dword
    local dwName    :dword
    local pPicture  :dword
    local hWndDesk  :dword
    local hDC1      :dword
    local hDC2      :dword
    local hiWidth   :dword
    local hiHeight  :dword
    local bmWidth   :dword
    local bmHeight  :dword
    local LogPixels :dword
    local HiMetric  :dword
    local hBmp      :dword
    local hOldBmp   :dword
    local pbits     :dword
    local rect      :RECT

    mov HiMetric,HIMETRIC_INCH
    xor edi,edi
    ;invoke CoInitialize,0
    invoke GetFullPathName,pFile,0,NULL,NULL
    inc eax
    add eax,eax
    mov dwName,eax
    invoke CoTaskMemAlloc,eax
    mov pName,eax
    .if eax
        invoke MultiByteToWideChar,CP_ACP,0,pFile,-1,pName,dwName
        .if eax
            invoke GetFullPathNameW,pName,dwName,pName,NULL
            .if eax
                invoke OleLoadPicturePath,pName,0,0,0,offset IID_IPicture,addr pPicture
                test eax,eax
                .if ! sign?
                    mov eax,pPicture
                    mov ebx,[eax]
                    mov hWndDesk,$invoke(GetDesktopWindow)
                    mov hDC1,$invoke (GetDC,eax)
                    mov hDC2,$invoke (CreateCompatibleDC,eax)
                    ; ------------------------------
                    ; (IPicture)pPicture::get_Width(*bmWidth)
                    ; ------------------------------
                    lea eax,hiWidth
                    push eax
                    push pPicture
                    call [ebx].IPicture.get_Width
                    ; ------------------------------
                    ; (IPicture)pPicture::get_Height(*bmHeight)
                    ; ------------------------------
                    lea eax,hiHeight
                    push eax
                    push pPicture
                    call [ebx].IPicture.get_Height
                    mov LogPixels,$invoke(GetDeviceCaps,hDC2,LOGPIXELSX)
                    invoke GetDeviceCaps,hDC2,LOGPIXELSY
                    fild hiWidth
                    fimul LogPixels
                    fidiv HiMetric
                    mov LogPixels,eax
                    fistp bmWidth
                    fild hiHeight
                    fimul LogPixels
                    fidiv HiMetric
                    fistp bmHeight
                    fwait
                    mov esi,pdib
                    .if !esi
                        mov hBmp,$invoke(CreateCompatibleBitmap,hDC1,bmWidth,bmHeight)
                    .else
                    	invoke RtlZeroMemory,addr [esi].DIBSECTION.dsBmih,sizeof BITMAPINFO
                        mov [esi].DIBSECTION.dsBmih.biSize,sizeof BITMAPINFOHEADER
                        m2m [esi].DIBSECTION.dsBmih.biWidth,bmWidth
                        mov eax,bmHeight
                        ;neg eax		;top-down bitmap
                        mov [esi].DIBSECTION.dsBmih.biHeight,eax
                        mov [esi].DIBSECTION.dsBmih.biPlanes,1
                        mov [esi].DIBSECTION.dsBmih.biBitCount,32
                        mov [esi].DIBSECTION.dsBmih.biCompression,BI_RGB	;BI_BITFIELDS
                        mov [esi].DIBSECTION.dsBmih.biSizeImage,0
                        mov [esi].DIBSECTION.dsBmih.biXPelsPerMeter,0
                        mov [esi].DIBSECTION.dsBmih.biYPelsPerMeter,0
                        mov [esi].DIBSECTION.dsBmih.biClrUsed,0
                        mov [esi].DIBSECTION.dsBmih.biClrImportant,0
                        mov [esi].DIBSECTION.dsBitfields[0],000000FFh   ;blue
                        mov [esi].DIBSECTION.dsBitfields[1],0000FF00h   ;green
                        mov [esi].DIBSECTION.dsBitfields[2],00FF0000h   ;red
                        fild [esi].DIBSECTION.dsBmih.biWidth
                        mov HiMetric,32
                        fimul [esi].DIBSECTION.dsBmih.biHeight
                        fimul HiMetric
                        fistp HiMetric
                        fwait
                        invoke CreateFileMapping,-1,0,PAGE_READWRITE,0,HiMetric,0
                        push eax
                        invoke CreateDIBSection,hDC1,addr [esi].DIBSECTION.dsBmih,DIB_RGB_COLORS,addr pbits,eax,0
                        mov hBmp,eax
                        push eax
                        invoke GetObject,eax,sizeof DIBSECTION,pdib
                        pop eax
                        pop [esi].DIBSECTION.dshSection
                        .if !eax
        	            	xor eax,eax
        	                xchg eax,[esi].DIBSECTION.dshSection
        	                .if eax
        	                    invoke CloseHandle,eax
        	                .endif
                        .endif
                    .endif
                    mov hOldBmp,$invoke(SelectObject,hDC2,eax)
                    mov rect.left,0
                    mov rect.top,0
                    push bmWidth
                    pop rect.right
                    push bmHeight
                    pop rect.bottom
                    invoke CreateSolidBrush,rgbBack
                    push eax
                    invoke FillRect,hDC2,addr rect,eax
                    call DeleteObject
                    invoke SetStretchBltMode,hDC2,HALFTONE
                    invoke SetBrushOrgEx,hDC2,0,0,NULL
                    ; ------------------------------
                    ; (IPicture)pPicture::Render(hdc, x, y, cx, cy,                            \
                    ;                            xpos_himetric, ypos_himetric,                 \
                    ;                            xsize_himetric, ysize_himetric, *rectBounds)
                    ; ------------------------------
                    push 0              ;*rectBounds
                    mov eax,hiHeight
                    neg eax
                    push eax            ;ysize_himetric
                    push hiWidth        ;xsize_himetric
                    push hiHeight       ;ypos_himetric
                    push 0              ;xpos_himetric
                    push bmHeight       ;cy
                    push bmWidth        ;cx
                    push 0              ;y
                    push 0              ;x
                    push hDC2           ;hdc
                    push pPicture
                    call [ebx].IPicture.Render
                    ;xor edi,edi
                    test eax,eax
                    .if ! sign?
                        mov edi,hBmp
                    .endif
                    push pPicture
                    call [ebx].IPicture.Release
                    invoke SelectObject,hDC2,hOldBmp
                    invoke DeleteDC,hDC2
                    invoke ReleaseDC,hWndDesk,hDC1
                .endif
            .endif
        .endif
        invoke CoTaskMemFree,pName
    .endif
    ;invoke CoUninitialize
    mov eax,edi
    ret

LoadPictureH endp
