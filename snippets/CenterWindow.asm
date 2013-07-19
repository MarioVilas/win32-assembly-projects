; http://www.madwizard.org/programming/snippets?id=67

; CenterWindow
;   by QvasiModo

; Centers a window relative to it's owner window.
; Tipically used to center a dialog box to it's parent window, or a main window to the desktop.

; Centra una ventana (relativo a su ventana padre).
; Típicamente se usa para centrar un cuadro de diálogo a su ventana padre, o la ventana principal
;  al escritorio.

CenterWindow proto :dword

.code
CenterWindow proc hwnd:dword
    local rect:RECT
    local rect2:RECT
    invoke GetWindow,hwnd,GW_OWNER
    lea edx,rect
    invoke GetWindowRect,eax,edx
    invoke GetWindowRect,hwnd,addr rect2
    mov eax,rect.right
    mov edx,rect2.right
    sub eax,rect.left
    sub edx,rect2.left
    mov rect.right,edx
    sub eax,edx
    sar eax,1
    add rect.left,eax
    mov eax,rect.bottom
    mov edx,rect2.bottom
    sub eax,rect.top
    sub edx,rect2.top
    mov rect.bottom,edx
    sub eax,edx
    sar eax,1
    add rect.top,eax
    invoke MoveWindow,hwnd,rect.left,rect.top,rect.right,rect.bottom,TRUE
    ret
CenterWindow endp
