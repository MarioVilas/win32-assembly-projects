; http://www.madwizard.org/programming/snippets?id=79

; BlitWindow
;   by QvasiModo

; Paints a bitmap into a window's client area. You can use four styles:
;   BW_COPY     Copies the bitmap at the upper left corner.
;   BW_CENTER   Centers the bitmap in the client area.
;   BW_STRETCH  Stretches the bitmap to cover the entire client area.
;   BW_TILE     Tiles the bitmap to cover the entire client area.

BlitWindow proto :dword,:dword,:dword,:dword

BW_COPY     equ 0
BW_CENTER   equ 1
BW_STRETCH  equ 2
BW_TILE     equ 3

.code
BlitWindow proc hwnd,hdc,hbmp,flags
    LOCAL hMemoryDC:HDC
    LOCAL hOldBmp:DWORD
    LOCAL rect:RECT
    LOCAL bitmap:BITMAP

    invoke GetClientRect,hwnd,addr rect
    invoke CreateCompatibleDC,hdc
    mov hMemoryDC,eax
    invoke SelectObject,eax,hbmp
    mov hOldBmp,eax
    invoke GetObject,hbmp,sizeof BITMAP,addr bitmap

    mov ecx,flags
    test ecx,ecx
    jnz @1          ;BW_COPY

    invoke BitBlt,hdc,0,0,bitmap.bmWidth,bitmap.bmHeight,hMemoryDC,0,0,SRCCOPY

@1: loop @2         ;BW_CENTER

    mov eax,rect.right
    sub eax,bitmap.bmWidth
    shr eax,1
    mov edx,rect.bottom
    sub edx,bitmap.bmHeight
    shr edx,1
    invoke BitBlt,hdc,eax,edx,bitmap.bmWidth,bitmap.bmHeight,hMemoryDC,0,0,SRCCOPY

    jmp @F
@2: loop @3         ;BW_STRETCH

    invoke StretchBlt,hdc,0,0,rect.right,rect.bottom,hMemoryDC,0,0,bitmap.bmWidth,bitmap.bmHeight,SRCCOPY

    jmp @F
@3: loop @4         ;BW_TILE

    push esi
    push edi
    xor edi,edi
    .repeat
        xor esi,esi
        .repeat
            invoke BitBlt,hdc,esi,edi,bitmap.bmWidth,bitmap.bmHeight,hMemoryDC,0,0,SRCCOPY
            add esi,bitmap.bmWidth
        .until esi >= rect.right
        add edi,bitmap.bmHeight
    .until edi >= rect.bottom
    pop edi
    pop esi

@4:
@@: invoke SelectObject,hMemoryDC,hOldBmp
    invoke DeleteDC,hMemoryDC
    ret
BlitWindow endp
