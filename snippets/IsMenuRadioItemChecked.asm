; http://www.madwizard.org/programming/snippets?id=72

; IsMenuRadioItemChecked
;   by QvasiModo

; invoke IsMenuRadioItemChecked,{handle to menu},{first radio item ID},{last radio item ID}
; Returns the ID of the checked radio menu item in the specified group.
; Devuelve el ID del ítem del menú que está seleccionado en el grupo dado.

IsMenuRadioItemChecked proto :dword,:dword,:dword

.code
IsMenuRadioItemChecked proc uses ebx esi imric_hmenu:dword,imric_fid:dword,imric_lid:dword
    mov ebx,imric_lid
    mov esi,imric_fid
    sub ebx,esi
    test ebx,ebx
    .if sign?
        dec ebx
    .else
        inc ebx
    .endif
    .repeat
        invoke GetMenuState,imric_hmenu,esi,MF_BYCOMMAND
        test eax,MF_CHECKED
        .if ! zero?
            mov eax,esi
            .break
        .endif
        test ebx,ebx
        .if sign?
            dec esi
            inc ebx
        .else
            inc esi
            dec ebx
        .endif
        .if zero?
            xor eax,eax
            .break
        .endif
    .until FALSE
    ret
IsMenuRadioItemChecked endp
