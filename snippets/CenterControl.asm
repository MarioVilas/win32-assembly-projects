; http://www.madwizard.org/programming/snippets?id=78

; CenterControl
;   by QvasiModo

; Centers a child window (control) relative to it's parent window.
; Centra una ventana hija (control) en relación a su ventana padre.

CenterWindow proto :dword

.code
CenterControl proc hwnd:dword
    local rect:RECT
    local rect2:RECT

    invoke GetWindowRect,hwnd,addr rect
    invoke GetParent,hwnd
    lea edx,rect
    push edx
    push eax
    lea edx,rect.right
    push edx
    push eax
    lea edx,rect2
    invoke GetClientRect,eax,edx
    call ScreenToClient
    call ScreenToClient
    mov eax,rect.right
    mov edx,rect.bottom
    sub eax,rect.left
    sub edx,rect.top
    push 1          ;MW
    push edx        ;MW
    push eax        ;MW
    neg eax
    neg edx
    add eax,rect2.right
    add edx,rect2.bottom
    sar eax,1
    sar edx,1
    push edx        ;MW
    push eax        ;MW
    push hwnd       ;MW
    call MoveWindow
    ret
CenterControl endp
