; 09-09-03

LoadFilteredIcon proto :dword,:dword,:dword

.code
LoadFilteredIcon proc uses ebx esi edi hInstance,lpResource,rgbColor
    ; Loads an icon, and combines it with the specified color.
    ; Written by QvasiModo
    ; Filtering algorithm by evwr and QvasiModo

    local hdc       :dword
    local hold      :dword
    local holdicon  :dword
    local iconinfo  :ICONINFO
    local ibitmap   :BITMAP

    invoke LoadIcon,hInstance,lpResource
    .if eax != 0
        mov holdicon,eax
        lea edx,iconinfo
        invoke GetIconInfo,eax,edx
        .if eax != 0
            mov eax,iconinfo.hbmColor
            .if eax != 0
                lea edx,ibitmap
                invoke GetObject,eax,sizeof BITMAP,edx
                .if eax != 0
                    invoke CreateCompatibleDC,0
                    .if eax != 0
                        mov hdc,eax
                        mov hold,$invoke (SelectObject,hdc,iconinfo.hbmColor)
                        mov esi,ibitmap.bmWidth
                        dec esi
                        .repeat
                            mov edi,ibitmap.bmHeight
                            dec edi
                            .repeat
                                invoke GetPixel,hdc,esi,edi
                                mov ebx,eax
                                mov ecx,3
                                mov edx,rgbColor
                                xor eax,eax
                                .repeat
                                    mov al,bl
                                    add al,dl
                                    adc ah,0
                                    shr ax,1
                                    mov bl,al
                                    ror edx,8
                                    ror ebx,8
                                .untilcxz
                                ror ebx,8
                                invoke SetPixel,hdc,esi,edi,ebx
                                sub edi,1
                            .until sign?
                            sub esi,1
                        .until sign?
                        invoke SelectObject,hdc,hold
                        invoke DeleteDC,hdc
                        invoke CreateIconIndirect,addr iconinfo
                    .endif
                .endif
            .endif
            push eax
            invoke DeleteObject,iconinfo.hbmMask
            invoke DeleteObject,iconinfo.hbmColor
            pop eax
        .endif
        push eax
        invoke DestroyIcon,holdicon
        pop eax
    .endif
    ret

LoadFilteredIcon endp
