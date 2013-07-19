; Loads a picture from a resource.
; 27-09-03

; The created bitmap is compatible to the screen DC.


IUnknown struct
    QueryInterface          DWORD   ?
    AddRef                  DWORD   ?
    Release                 DWORD   ?
IUnknown ends

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

HIMETRIC_INCH equ 2540

ifndef IID_IPicture
.data
IID_IPicture GUID {07BF80980h,0BF32h,0101Ah,{08Bh,0BBh,000h,0AAh,000h,030h,00Ch,0ABh}}
endif

ifndef szIMAGE
szIMAGE db "IMAGE",0
endif

.code
LoadResPicture proc uses ebx edi hInstance,lpName,rgbBack
    local hGlobal   :dword
    local pStream   :dword
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
    local hmap      :dword
    local pbits     :dword
    local pdata     :dword
    local dwsize    :dword
    local rect      :RECT

    invoke FindResource,hInstance,lpName,offset szIMAGE
    push eax
    invoke LoadResource,hInstance,eax
    invoke LockResource,eax
    pop edx
    .if eax != 0
        mov pdata,eax
        invoke SizeofResource,hInstance,edx
        mov dwsize,eax
        mov HiMetric,HIMETRIC_INCH
        xor edi,edi
        mov pStream,edi
        mov pPicture,edi
        invoke CoInitialize,edi
        test eax,eax
        .if ! sign?
            invoke GlobalAlloc,GMEM_MOVEABLE,dwsize
            .if eax != 0
                mov hGlobal,eax
                invoke GlobalLock,eax
                .if eax != 0
                    invoke RtlMoveMemory,eax,pdata,dwsize
                    invoke GlobalUnlock,hGlobal
                    invoke CreateStreamOnHGlobal,hGlobal,FALSE,addr pStream
                    test eax,eax
                    .if ! sign?
                        invoke OleLoadPicture,pStream,dwsize,FALSE,offset IID_IPicture,addr pPicture
                        test eax,eax
                        .if ! sign?
                            movi hiWidth,1
                            movi hiHeight,1
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
                            mov hBmp,$invoke(CreateCompatibleBitmap,hDC1,bmWidth,bmHeight)
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
                            test eax,eax
                            .if ! sign?
                                mov edi,hBmp
                            .endif
                            invoke SelectObject,hDC2,hOldBmp
                            invoke DeleteDC,hDC2
                            invoke ReleaseDC,hWndDesk,hDC1
                            push pPicture       ;pPicture::IPicture.Release
                            call [ebx].IUnknown.Release
                        .endif
                        mov eax,pStream     ;pStream::IStream.Release
                        push eax
                        mov eax,[eax]
                        call [eax].IUnknown.Release
                    .endif
                .endif
                invoke GlobalFree,hGlobal
            .endif
            invoke CoUninitialize
        .endif
        mov eax,edi
    .endif
    ret

LoadResPicture endp
