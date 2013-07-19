; http://www.madwizard.org/programming/snippets?id=86

; IsExtensionInList
;  Checks if the extension of a given filename matches one in a list of extensions separated by semicolons.
;  ® Mario Vilas (aka QvasiModo)
;  Last updated 15 Feb 04
;  This snippet is freeware :)

.code
align DWORD
IsExtensionInList proc uses ebx esi edi pName,pList

    ; Ensure that the strings are not null
    mov esi,pList
    mov edi,pName
    cmp byte ptr [esi],0
    je quit
    cmp byte ptr [edi],0
    je quit
    ; Go to the end of both strings
    invoke lstrlen,esi
    add esi,eax
    invoke lstrlen,edi
    add edi,eax
    ; Case-insensitive compare
    mov ebx,edi
    add esi,1
    add edi,1
@@: sub esi,1
    sub edi,1
    cmp esi,pList
    jb @F
    cmp edi,pName
    jb found
    mov al,[esi]
    cmp al,';'
    je maybe
    cmp al,[edi]
    je @B
    or al,20h
    cmp al,[edi]
    je @B
    mov edi,ebx
    .repeat
        mov al,[esi]
        cmp al,';'
        je @B
        sub esi,1
        cmp esi,pList
        jb quit
    .until FALSE
maybe:
    cmp edi,ebx
    jne found
    jmp @B
@@: cmp edi,ebx
    jne found
quit:
    xor eax,eax
    jmp short @F
found:
    push TRUE
    pop eax
@@: ret

IsExtensionInList endp
