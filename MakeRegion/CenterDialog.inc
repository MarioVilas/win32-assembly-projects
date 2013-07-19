;   28-08-03

; Centers a dialog box relative to it's owner window.

CenterDialog proto :dword

.code
CenterDialog proc hwnd:dword
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
    sub eax,edx
    sar eax,1
    add rect.left,eax
    mov eax,rect.bottom
    mov edx,rect2.bottom
    sub eax,rect.top
    sub edx,rect2.top
    sub eax,edx
    sar eax,1
    add rect.top,eax
    invoke SetWindowPos,hwnd,0,rect.left,rect.top,0,0,SWP_NOACTIVATE or SWP_NOOWNERZORDER or SWP_NOREPOSITION or SWP_NOSIZE
    invoke SendMessage,hwnd,DM_REPOSITION,0,0
    ret
CenterDialog endp
