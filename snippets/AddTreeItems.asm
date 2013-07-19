; http://www.madwizard.org/programming/snippets?id=66

; AddTreeItems
;   by QvasiModo

; Adds a group of items to a tree-view control in a single call
; As an opcion you can use pointers to a handle instead of an actual handle in hParent and hInsertAfter
; It needs read and write access to the memory block pointed to by pitems

; invoke AddTreeItems,
;                       {window handle to tree-view control},
;                       {pointer to array of TV_INSERTSTRUCT stucts},
;                       {number of items in array}

; Agrega un grupo de ítems a un control tree-view de a varios en una sola llamada
; Opcionalmente en hParent y hInsertAfter acepta punteros al handle en vez del handle
; Necesita acceso de lectura y escritura a la memoria apuntada por pitems

; invoke AddTreeItems,
;                       {handle de ventana al control tree-view},
;                       {puntero a un array de estructuras TV_INSERTSTRUCT},
;                       {número de ítems en el array}

; Example / Ejemplo:
; Warning: your have to use TV_ITEM or TV_ITEMEX depending on how TV_INSERTITEM is defined in your copy of WINDOWS.INC
; Atención: hay que usar TV_ITEM o TV_ITEMEX dependiendo de cómo está definido TV_INSERTITEM en tu copia de WINDOWS.INC
;
; .const
; szitemtext1 db "Item Text 1",0        ; |-Item 1
; szitemtext2 db "Item Text 2",0        ; |  |-Item 2
; szitemtext3 db "Item Text 3",0        ; |  |  \-Item 3
; szitemtext4 db "Item Text 4",0        ; |  |     \-Item 4
; szitemtext5 db "Item Text 5",0        ; |  \-Item 5
; szitemtext6 db "Item Text 6",0        ; \-Item 6
;
; .data
; myitems label TV_INSERTSTRUCT
;       dd TVI_ROOT,TVI_LAST
; item1 TV_ITEMEX <TVIF_CHILDREN or TVIF_TEXT,0,0,0,offset szitemtext1,0,0,0,1,0>
;       dd offset item1.hItem,TVI_LAST
; item2 TV_ITEMEX <TVIF_CHILDREN or TVIF_TEXT,0,0,0,offset szitemtext2,0,0,0,1,0>
;       dd offset item2.hItem,TVI_LAST
; item3 TV_ITEMEX <TVIF_CHILDREN or TVIF_TEXT,0,0,0,offset szitemtext3,0,0,0,1,0>
;       dd offset item3.hItem,TVI_LAST
; item4 TV_ITEMEX <TVIF_CHILDREN or TVIF_TEXT,0,0,0,offset szitemtext4,0,0,0,0,0>
;       dd offset item1.hItem,TVI_LAST
; item5 TV_ITEMEX <TVIF_CHILDREN or TVIF_TEXT,0,0,0,offset szitemtext5,0,0,0,0,0>
;       dd TVI_ROOT,TVI_LAST
; item6 TV_ITEMEX <TVIF_CHILDREN or TVIF_TEXT,0,0,0,offset szitemtext6,0,0,0,0,0>
; number_of_items equ ($ - offset myitems) / sizeof TV_INSERTSTRUCT
;
; .code
; invoke GetDlgItem,hDlg,IDC_LIST1  ;or whatever your tree-view ID is
; invoke AddTreeItems,eax,offset myitems,number_of_items

AddTreeItems proto :dword,:dword,:dword

.code
AddTreeItems proc uses ebx hwnd:dword,pitems:dword,dwnum:dword
    mov ebx,pitems
    assume ebx:ptr TV_INSERTSTRUCT
    .repeat
        mov eax,[ebx].hParent
        push eax
        mov edx,eax
        shr edx,16
        .if ! zero?
            inc dx
            .if ! zero?
                m2m [ebx].hParent,dword ptr [eax]
            .endif
        .endif
        mov eax,[ebx].hInsertAfter
        push eax
        mov edx,eax
        shr edx,16
        .if ! zero?
            inc dx
            .if ! zero?
                m2m [ebx].hInsertAfter,dword ptr [eax]
            .endif
        .endif
        and [ebx].item._mask,not TVIF_HANDLE
        invoke SendMessage,hwnd,TVM_INSERTITEM,0,ebx
        pop [ebx].hInsertAfter
        pop [ebx].hParent
        .break .if eax == 0
        mov [ebx].item.hItem,eax
        or [ebx].item._mask,TVIF_HANDLE
        add ebx,sizeof TV_INSERTSTRUCT
        dec dwnum
    .until zero?
    mov eax,ebx
    assume ebx:nothing
    ret
AddTreeItems endp
