.const
szTextName  db "Error name:",13,10,"    ",0
szTextHex   db 13,10,13,10,"Error value:",13,10,"    0x",0
szTextDec   db " (",0
szTextDesc  db ")",13,10,13,10,"Description:",13,10,"    ",0

.data?
ifdef STANDALONE_VERSION
hIconOn     dd ?
hIconOff    dd ?
endif
iLastLength dd ?
buffer      db 4096 dup (?)
buffer_dec  db 20 dup (?)
buffer_hex  db 20 dup (?)
buffer_desc db 4096 dup (?)
buffer_final db 4096*2+40+offset szTextName-offset szTextDesc-3 dup (?)

.code
align DWORD
DlgProc proc hWin,uMsg,wParam,lParam
    local iCode :DWORD
    local bTrans:DWORD
    local hEdit1:DWORD
    local rect  :RECT
    local rect2 :RECT

    mov eax,uMsg
    .switch eax

    .case WM_COMMAND
        mov eax,wParam
        cmp eax,(CBN_SELCHANGE shl 16) or IDC_COMBO1
        .if zero?
            mov iLastLength,0
            invoke PostMessage,hWin,WM_COMMAND,(CBN_EDITUPDATE shl 16) or IDC_COMBO1,lParam
            .break
        .endif
        cmp eax,(CBN_EDITUPDATE shl 16) or IDC_COMBO1
        .if zero?
            mov buffer,0
            invoke GetDlgItemText,hWin,IDC_COMBO1,offset buffer,sizeof buffer
            .if eax == 0
                mov iLastLength,eax
                .break
            .endif
            invoke lstrlen,offset buffer
            cmp iLastLength,eax
            mov iLastLength,eax
            .break .if zero?
            invoke GetDlgItemInt,hWin,IDC_COMBO1,addr bTrans,TRUE
            or bTrans,0
            .if ! zero?
@number:        mov dword ptr [buffer],")?("
                push eax
                push esi
                push ebx
                mov esi,offset ErrorTable
                mov ebx,NUMBER_OF_ERRORS
                .repeat
                    .if eax == [esi].ERROR_TABLE.iCode
                        invoke lstrcpy,offset buffer,[esi].ERROR_TABLE.pName
                        .break
                    .endif
                    add esi,sizeof ERROR_TABLE
                    dec ebx
                .until zero?
                pop ebx
                pop esi
                pop eax
                jmp @normal
            .endif
            cmp word ptr buffer,'x0'
            .if zero?
                invoke htodw,offset buffer + 2
                jmp @number
            .endif
            invoke SendDlgItemMessage,hWin,IDC_COMBO1,CB_FINDSTRINGEXACT,-1,offset buffer
            inc eax
            .if zero?
                invoke SendDlgItemMessage,hWin,IDC_COMBO1,CB_FINDSTRING,-1,offset buffer
                inc eax
                .break .if zero?
                dec eax
                invoke SendDlgItemMessage,hWin,IDC_COMBO1,CB_SETCURSEL,eax,0
                mov eax,iLastLength
                or eax,0FFFF0000h
                invoke SendDlgItemMessage,hWin,IDC_COMBO1,CB_SETEDITSEL,0,eax
                invoke GetDlgItemText,hWin,IDC_COMBO1,offset buffer,sizeof buffer
            .endif
            push esi
            push ebx
            mov esi,offset ErrorTable
            mov ebx,NUMBER_OF_ERRORS
@@:         invoke lstrcmpi,offset buffer,[esi].ERROR_TABLE.pName
            .if eax == 0
                invoke lstrcpy,offset buffer_desc,[esi].ERROR_TABLE.pDesc
                mov eax,[esi].ERROR_TABLE.iCode
                pop ebx
                pop esi
@normal:        push eax
                push offset buffer_hex
                push eax
                invoke dwtoa,eax,offset buffer_dec
                call dw2hex
                pop eax
                invoke FormatMessage,FORMAT_MESSAGE_FROM_SYSTEM,0,eax,0,offset buffer_desc,sizeof buffer_desc,0
                invoke lstrcpy,offset buffer_final,offset szTextName
                invoke lstrcat,offset buffer_final,offset buffer
                invoke lstrcat,offset buffer_final,offset szTextHex
                invoke lstrcat,offset buffer_final,offset buffer_hex
                invoke lstrcat,offset buffer_final,offset szTextDec
                invoke lstrcat,offset buffer_final,offset buffer_dec
                invoke lstrcat,offset buffer_final,offset szTextDesc
                invoke lstrcat,offset buffer_final,offset buffer_desc
                invoke SetDlgItemText,hWin,IDC_EDIT1,offset buffer_final
                .break
            .endif
            lea esi,[esi + sizeof ERROR_TABLE]
            dec ebx
            jnz @B
            pop ebx
            pop esi
            .break
        .endif
        .break .if eax != IDCANCEL
        ifdef STANDALONE_VERSION
            invoke EndDialog,hWin,eax
        else
            .if fModal
                invoke EndDialog,hWin,eax
                .break
            .endif
            invoke ShowWindow,hWin,SW_HIDE
        endif
        .break

    .case WM_SIZE
        .break .if wParam == SIZE_MINIMIZED
        invoke GetClientRect,hWin,addr rect
        mov hEdit1,$invoke(GetDlgItem,hWin,IDC_EDIT1)
        invoke GetDlgItem,hWin,IDC_COMBO1
        invoke MoveWindow,eax,0,0,rect.right,rect.bottom,TRUE
        lea edx,rect2
        push edx
        push hWin
        invoke GetWindowRect,hEdit1,edx
        call ScreenToClient
        mov edx,rect.bottom
        sub edx,rect2.top
        .if sign?
            neg edx
        .endif
        mov eax,rect.right
        sub eax,rect.left
        invoke SetWindowPos,hEdit1,0,0,0,eax,edx,SWP_NOMOVE or SWP_NOOWNERZORDER or SWP_NOZORDER
        .break

ifdef STANDALONE_VERSION
    .case WM_ACTIVATE
        .if wParam == WA_INACTIVE
            push hIconOff
        .else
            push hIconOn
        .endif
        push ICON_SMALL
        push WM_SETICON
        push hWin
        call SendMessage
        .break
endif

    .case WM_INITDIALOG
        push hWin
        pop AddinPopup
        push esi
        push ebx
        mov esi,offset ErrorTable
        mov ebx,NUMBER_OF_ERRORS
        .repeat
            lodsd
            lodsd
            invoke SendDlgItemMessage,hWin,IDC_COMBO1,CB_ADDSTRING,0,eax
            lodsd
            dec ebx
        .until zero?
        pop ebx
        pop esi
        ifdef STANDALONE_VERSION
            invoke GetSysColor,COLOR_ACTIVECAPTION
            mov hIconOn,$invoke(LoadFilteredIcon,hInst,IDI_ICON1,eax)
            invoke GetSysColor,COLOR_INACTIVECAPTION
            mov hIconOff,$invoke(LoadFilteredIcon,hInst,IDI_ICON1,eax)
        endif
        .if buffer != 0
            invoke SetDlgItemText,hWin,IDC_COMBO1,offset buffer
            invoke SendMessage,hWin,WM_COMMAND,(CBN_EDITUPDATE shl 16) or IDC_COMBO1,lParam
        .endif
        ifdef USE_DOCKING_WINDOWS
        .if (! fDocking) && (wp.iLength == sizeof WINDOWPLACEMENT)
        else
        .if wp.iLength == sizeof WINDOWPLACEMENT
        endif
            invoke GetFocus
            push eax
            invoke SetWindowPlacement,hWin,offset wp
            pop eax
            .if eax != hWin
                invoke SetFocus,eax
            .endif
        .endif
        ifdef STANDALONE_VERSION
            xor eax,eax
            inc eax
        else
            mov eax,lParam
        endif
        ret

    .case WM_DESTROY
        mov AddinPopup,0
        ifdef STANDALONE_VERSION
            invoke DestroyIcon,hIconOn
            invoke DestroyIcon,hIconOff
        endif
        ifdef USE_DOCKING_WINDOWS
            .if ! fDocking
                mov wp.iLength,sizeof WINDOWPLACEMENT
                invoke GetWindowPlacement,hWin,offset wp
                invoke GetWindowLong,hWin,GWL_STYLE
                and eax,3
                mov dwDockingStyle,eax
            .endif
        else
            mov wp.iLength,sizeof WINDOWPLACEMENT
            invoke GetWindowPlacement,hWin,offset wp
        endif
        mov buffer,0
        invoke GetDlgItemText,hWin,IDC_COMBO1,offset buffer,sizeof buffer

    .endswitch
    xor eax,eax
    ret

DlgProc endp
