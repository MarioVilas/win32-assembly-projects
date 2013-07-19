; -------------------------------------------------------------------------
; Common code
; -------------------------------------------------------------------------

USE_DOCKING_WINDOWS equ TRUE

include WinErr.Inc
include DlgProc.Inc

.code
align DWORD
DllEntryPoint proc hinstDLL,fdwReason,lpvReserved

    .if fdwReason == DLL_PROCESS_ATTACH
        push hinstDLL
        pop hInst
    .endif
    xor eax,eax
    inc eax
    ret

DllEntryPoint endp

align DWORD
WorkerProc proc lParam
    local msg       :MSG

    invoke PeekMessage,addr msg,0,0,0,PM_NOREMOVE
    invoke SetEvent,hEvent
    .if fActive
        invoke PostThreadMessage,IdWorker,WM_USER+100h,FALSE,0
    .endif
@@: ;begin message loop
    invoke GetMessage,addr msg,0,0,0
    inc eax
    jz @F
    dec eax
    jz @F
    .if (msg.hwnd == NULL) && (msg.message == WM_USER + 100h)
        .if ! AddinPopup
            invoke CreateDialogParam,hInst,IDD_DIALOG1,hMain,offset DlgProc,msg.wParam
;            invoke FindResource,hInst,IDD_DIALOG1,RT_DIALOG
;            invoke LoadResource,hInst,eax
;            invoke LockResource,eax
;            .if eax != 0
;                invoke CreateDialogIndirectParam,hInst,eax,hMain,offset DlgProc,msg.wParam
;            .endif
            jmp @B
        .endif
        invoke ShowWindow,AddinPopup,SW_SHOW
        invoke SendMessage,AddinPopup,DM_REPOSITION,0,0
        invoke SetFocus,AddinPopup
    .endif
    invoke IsDialogMessage,AddinPopup,addr msg
    test eax,eax
    jnz @B
    invoke TranslateMessage,addr msg
    invoke DispatchMessage,addr msg
    jmp @B
@@: ;end message loop
    ret

WorkerProc endp

align DWORD
CreateWorker proc

    mov hEvent,$invoke(CreateEvent,NULL,FALSE,FALSE,NULL)
    mov hWorker,$invoke(CreateThread,NULL,0,offset WorkerProc,0,0,offset IdWorker)
    invoke WaitForSingleObject,hEvent,INFINITE
    invoke CloseHandle,hEvent
    ret

CreateWorker endp

align DWORD
ReadConfig proc uses edi pFile

	invoke GetModuleFileName,NULL,offset szINI,MAX_PATH
	invoke lstrlen,offset szINI
	mov ecx,eax
	lea edi,[offset szINI + eax]
	mov al,'\'
	std
	repne scasb
	cld
	add edi,2
	invoke lstrcpy,edi,pFile
    ifdef USE_DOCKING_WINDOWS
        .if fDocking
            invoke GetPrivateProfileStruct,offset szWinErr,offset szDockingData,
                                           offset AddInDockData + OFFSET_DOCKINGDATA,
                                           SIZEOF_DOCKINGDATA,offset szINI
        	invoke GetPrivateProfileInt,offset szWinErr,offset szDockingStyle,dwDockingStyle,offset szINI
			and eax,3
			mov dwDockingStyle,eax
        .else
    	    invoke GetPrivateProfileStruct,offset szWinErr,offset szWindowPlacement,
	                                       offset wp,sizeof wp,offset szINI
        .endif
    else
	    invoke GetPrivateProfileStruct,offset szWinErr,offset szWindowPlacement,
                                       offset wp,sizeof wp,offset szINI
    endif
    invoke GetPrivateProfileInt,offset szWinErr,offset szIsActive,0,offset szINI
    and eax,1
    mov fActive,eax
	invoke GetPrivateProfileString,offset szWinErr,offset szLastCode,offset buffer,
                                   offset buffer,sizeof buffer,offset szINI
    ret

ReadConfig endp

align DWORD
WriteConfig proc

    ifdef USE_DOCKING_WINDOWS
        .if fDocking
            mov wp.iLength,sizeof WINDOWPLACEMENT
            invoke GetWindowPlacement,AddinPopup,offset wp
            .if eax
                invoke WritePrivateProfileStruct,offset szWinErr,offset szDockingData,
                                                 offset AddInDockData + OFFSET_DOCKINGDATA,
                                                 SIZEOF_DOCKINGDATA,offset szINI
            .endif
            invoke GetWindowLong,hDocking,GWL_STYLE
            and eax,3
            add eax,eax
            add eax,offset sz0
            invoke WritePrivateProfileString,offset szWinErr,offset szDockingStyle,eax,offset szINI
        .else
            invoke WritePrivateProfileStruct,offset szWinErr,offset szWindowPlacement,
                                             offset wp,sizeof wp,offset szINI
        .endif
    else
        invoke WritePrivateProfileStruct,offset szWinErr,offset szWindowPlacement,
                                         offset wp,sizeof wp,offset szINI
    endif
    ifdef STANDALONE_VERSION
        mov eax,fActive
    else
        invoke IsWindowVisible,AddinPopup
        .if eax
            mov eax,1
        .endif
    endif
    add eax,eax
    add eax,offset sz0
    invoke WritePrivateProfileString,offset szWinErr,offset szIsActive,eax,offset szINI
    invoke WritePrivateProfileString,offset szWinErr,offset szLastCode,offset buffer,offset szINI
    ret

WriteConfig endp

; -------------------------------------------------------------------------
; Chrome addin support
; -------------------------------------------------------------------------

align DWORD
AddInDescription proc
; In: N/A
; Out: Can return description string in eax or 0

    ;mov eax,offset szDesc
    mov eax,offset szName
    ret

AddInDescription endp

align DWORD
AddInAuthor proc
; In: N/A
; Out: Can return author string in eax or 0

    mov eax,offset szCopyright
    ret

AddInAuthor endp

align DWORD
AddInLoad proc WALIBStruct
; In: Pointer to WALIB structure
; Out: Must return ADDIN_FINISHED or ADDIN_PERSISTANT in eax

    pushad
    mov eax,WALIBStruct
    lea edx,AddInContext
    push edx
    call [eax].WALIB.WAMMGetContext
    m2m hMain,AddInContext.hMDI
    invoke ReadConfig,offset szChromeINI
    invoke CreateWorker
    popad
    movi eax,ADDIN_PERSISTANT
    ret

AddInLoad endp

align DWORD
AddInUnLoad proc
; In: N/A
; Out: N/A

    pushad
    mov fActive,FALSE
    mov eax,AddinPopup
    .if eax != 0
        invoke IsWindowVisible,eax
        .if eax
            inc fActive ;TRUE
        .endif
        invoke SendMessage,AddinPopup,WM_DESTROY,0,0
    .endif
    invoke PostThreadMessage,IdWorker,WM_QUIT,0,0
    invoke WaitForSingleObject,hWorker,INFINITE
    invoke CloseHandle,hWorker
    .if wp.iLength == sizeof WINDOWPLACEMENT
        invoke WriteConfig
    .endif
    popad
    ret

AddInUnLoad endp

align DWORD
AddInMenu		proc	WALIBStruct:dword
; In: Pointer to WALIB structure
; Out: Must return ADDIN_DIE or ADDIN_ZOMBIE in eax
    pushad
    .if IdWorker != NULL
        invoke PostThreadMessage,IdWorker,WM_USER+100h,TRUE,0
    .endif
    popad
    movi eax,ADDIN_ZOMBIE
    ret
AddInMenu		endp

; -------------------------------------------------------------------------
; AsmEdit addin support
; -------------------------------------------------------------------------

align DWORD
AsmEditProc proc hWin,uMsg,wParam,lParam
    local hkey  :DWORD
    local dummy :DWORD

    ;Read config from AsmEdit registry key
    invoke SendMessage,hWin,IDM_GETDATA,0,0
    invoke lstrcpyn,offset AsmEditKey,[eax].ASMEDATA.lpRegKey,MAX_PATH
    invoke lstrlen,offset AsmEditKey
    .if byte ptr [eax - 1 + offset AsmEditKey] != '\'
        mov word ptr [eax - 1 + offset AsmEditKey],'\'
    .endif
    invoke lstrcat,offset AsmEditKey,offset szWinErr
    invoke RegOpenKeyEx,HKEY_CURRENT_USER,offset AsmEditKey,0,KEY_READ,addr hkey
    .if eax == ERROR_SUCCESS
        mov wp.iLength,sizeof wp
        invoke RegQueryValueEx,hkey,offset szWindowPlacement,0,0,offset wp,offset wp.iLength
        .if eax != 0
            mov wp.iLength,0
        .endif
;        mov dummy,4
;        invoke RegQueryValueEx,hkey,offset szIsActive,0,0,offset fActive,addr dummy
;        and fActive,1
        mov dummy,sizeof buffer
        invoke RegQueryValueEx,hkey,offset szLastCode,0,0,offset buffer,addr dummy
        invoke RegCloseKey,hkey
    .endif
    ;Load dialog box as modal
    invoke FindResource,hInst,IDD_DIALOG1,RT_DIALOG
    invoke LoadResource,hInst,eax
    invoke LockResource,eax
    .if eax != 0
        mov fModal,TRUE
        invoke DialogBoxIndirectParam,hInst,eax,hWin,offset DlgProc,TRUE
        ;Save config in AsmEdit registry key
        invoke RegCreateKeyEx,HKEY_CURRENT_USER,offset AsmEditKey,0,offset szREG_SZ,0,
                              KEY_WRITE,0,addr hkey,addr dummy
        .if eax == ERROR_SUCCESS
            invoke RegSetValueEx,hkey,offset szWindowPlacement,0,REG_BINARY,offset wp,sizeof wp
;            invoke RegSetValueEx,hkey,offset szIsActive,0,REG_DWORD,offset fActive,4
            invoke lstrlen,offset buffer
;            inc eax
            invoke RegSetValueEx,hkey,offset szLastCode,0,REG_SZ,offset buffer,eax
            invoke RegCloseKey,hkey
        .endif
    .endif
    xor eax,eax
    ret

AsmEditProc endp

; -------------------------------------------------------------------------
; RadAsm addin support
; -------------------------------------------------------------------------

align DWORD
InstallDll proc hWin,fOpt

    mov eax,fOpt
    and eax,1
    .if ! zero?
        invoke ReadConfig,offset szRAWinErrINI
        mov lpHandles,  $invoke(SendMessage,hWin,AIM_GETHANDLES,0,0)
        mov lpData,     $invoke(SendMessage,hWin,AIM_GETDATA,0,0)
        mov lpProc,     $invoke(SendMessage,hWin,AIM_GETPROCS,0,0)
        mov AddinID,    $invoke(SendMessage,hWin,AIM_GETMENUID,0,0)
        mov eax,lpHandles
        push [eax].ADDINHANDLES.hWnd
        pop hMain
        mov edx,4
        mov eax,lpData
        .if [eax].ADDINDATA.fMaximized != FALSE
            inc edx
        .endif
        mov eax,lpHandles
        mov AddinMenu,$invoke(GetSubMenu,[eax].ADDINHANDLES.hMenu,edx)
        invoke AppendMenu,eax,MF_STRING,AddinID,offset szMenuText
        invoke CreateWorker
        mov eax,RAM_COMMAND or RAM_CLOSE
    .endif
    xor ecx,ecx
    cdq
    ret

InstallDll endp

align DWORD
DllProc proc hWin,uMsg,wParam,lParam
    local iCode :DWORD

    mov eax,uMsg
    .switch eax
    .case AIM_COMMAND
        mov eax,wParam
        .break .if eax != AddinID
        invoke PostThreadMessage,IdWorker,WM_USER+100h,TRUE,0
        .break
    .case AIM_CLOSE
        invoke DeleteMenu,AddinMenu,AddinID,MF_BYCOMMAND
        mov fActive,FALSE
        mov eax,AddinPopup
        .if eax != 0
            invoke IsWindowVisible,eax
            .if eax
                inc fActive ;TRUE
            .endif
            invoke SendMessage,AddinPopup,WM_DESTROY,0,0
        .endif
        invoke PostThreadMessage,IdWorker,WM_QUIT,0,0
        invoke WaitForSingleObject,hWorker,INFINITE
        invoke CloseHandle,hWorker
        mov hWorker,0
        invoke WriteConfig
    .endswitch
    xor eax,eax
    ret

DllProc endp

align DWORD
GetOptions proc

    mov eax,offset AddinOpt
    ret

GetOptions endp

; -------------------------------------------------------------------------
; WinAsm addin support
; -------------------------------------------------------------------------

align DWORD
GetWAAddInData proc lpFriendlyName,lpDescription

    invoke RtlMoveMemory,lpFriendlyName,offset szName,sizeof szName
    invoke RtlMoveMemory,lpDescription,offset szDesc,sizeof szDesc
    ret

GetWAAddInData endp

align DWORD
WAAddInLoad proc uses ebx pWinAsmHandles,features
    local IsActiveChildMaximized:DWORD

    ifdef USE_DOCKING_WINDOWS
        movi fDocking,TRUE
    endif
    invoke ReadConfig,offset szAddinsINI
	mov ebx,pWinAsmHandles
	mov pHandles,ebx
	push [ebx].HANDLES.hMain
	pop hMain
    invoke SendMessage,[ebx].HANDLES.hClient,WM_MDIGETACTIVE,0,addr IsActiveChildMaximized
    mov eax,2   ;2 for View menu
    .if IsActiveChildMaximized
        inc eax
    .endIf
	mov AddinMenu,$invoke(GetSubMenu,[ebx].HANDLES.hMenu,eax)
	invoke GetMenuItemCount,eax
	.if eax == 5
        invoke AppendMenu,AddinMenu,MF_SEPARATOR,0,0
	.endif
    mov AddinID,$invoke(SendMessage,[ebx].HANDLES.hMain,WAM_GETNEXTMENUID,0,0)
    invoke AppendMenu,AddinMenu,MF_OWNERDRAW,eax,offset szMenuText  ;MF_OWNERDRAW req. by 1.0.1.6+
    ifdef USE_DOCKING_WINDOWS
        mov eax,WS_CLIPCHILDREN or WS_CLIPSIBLINGS or WS_CHILD
        or eax,dwDockingStyle
        .if fActive
            or eax,WS_VISIBLE
            push eax
            invoke CheckMenuItem,AddinMenu,AddinID,MF_BYCOMMAND or MF_CHECKED
            pop eax
        .endif
        mov AddInDockData.lpCaption,offset szName
        mov hDocking,$invoke(SendMessage,hMain,WAM_CREATEDOCKINGWINDOW,eax,offset AddInDockData)
        mov pOldProc,$invoke(SetWindowLong,eax,GWL_WNDPROC,offset DockingProc)
        invoke SendMessage,hDocking,WM_USER+100h,0,0
        .if eax == 0
            invoke MessageBox,hMain,offset szOldWinAsm,offset szError,MB_OK or MB_ICONERROR
            invoke WAAddInUnload
            xor eax,eax
            dec eax
            ret
        .endif
    else
        invoke CreateWorker
    endif
    xor eax,eax
    ret

WAAddInLoad endp

align DWORD
WAAddInUnload proc

    ifdef USE_DOCKING_WINDOWS
        invoke WriteConfig
    else
        .if wp.iLength == sizeof WINDOWPLACEMENT
            invoke WriteConfig
        .endif
    endif
    mov fActive,FALSE
    mov eax,AddinPopup
    ifdef USE_DOCKING_WINDOWS
        .if fDocking
            mov eax,hDocking
        .endif
    endif
    .if eax != 0
        invoke IsWindowVisible,eax
        .if eax
            inc fActive ;TRUE
        .endif
        ifdef USE_DOCKING_WINDOWS
            .if fDocking
;               invoke GetWindowLong,hDocking,0
;               .if eax != 0
;                   invoke MoveMemory,offset AddInDockData,eax,sizeof DOCKINGDATA
;               .endif
                invoke SendMessage,hDocking,WAM_DESTROYDOCKINGWINDOW,0,0
            .else
                invoke DestroyWindow,AddinPopup
            .endif
        else
            invoke DestroyWindow,AddinPopup
        endif
    .endif
    ifndef USE_DOCKING_WINDOWS
        invoke PostThreadMessage,IdWorker,WM_QUIT,0,0
        invoke WaitForSingleObject,hWorker,INFINITE
        invoke CloseHandle,hWorker
    endif
    invoke DeleteMenu,AddinMenu,AddinID,MF_BYCOMMAND
    invoke GetMenuItemCount,AddinMenu
    dec eax
    invoke GetMenuState,AddinMenu,eax,MF_BYPOSITION
    test eax,MF_SEPARATOR
    .if !zero?
        invoke DeleteMenu,AddinMenu,5,MF_BYPOSITION
    .endif
    xor eax,eax
    ret

WAAddInUnload endp

align DWORD
FrameWindowProc proc hWin,uMsg,wParam,lParam
    local iCode :DWORD

    .if uMsg == WM_COMMAND
        mov eax,wParam
        and eax,not 10000h
        .if eax == AddinID
            ifdef USE_DOCKING_WINDOWS
                invoke IsWindowVisible,hDocking
                .if eax == FALSE
                	push SW_SHOW
                	push MF_CHECKED or MF_BYCOMMAND
                .else
                	push SW_HIDE
                	push MF_UNCHECKED or MF_BYCOMMAND
                .endif
                push AddinID
                push AddinMenu
                call EnableMenuItem
                push hDocking
                call ShowWindow
            else
            	invoke GetMenuState,AddinMenu,AddinID,MF_BYCOMMAND
            	xor eax,MF_CHECKED
            	invoke EnableMenuItem,AddinMenu,AddinID,eax
                invoke PostThreadMessage,IdWorker,WM_USER+100h,TRUE,0
            endif
            xor eax,eax
            inc eax
            ret
        .endif
    .endif
    xor eax,eax
    ret

FrameWindowProc endp

ifdef USE_DOCKING_WINDOWS
align DWORD
DockingProc proc hWin,uMsg,wParam,lParam
    local rect:RECT

    mov eax,uMsg
    .switch eax

    .case WM_SIZE
        invoke SendMessage,hWin,WAM_GETCLIENTRECT,0,addr rect
        mov eax,rect.right
        mov edx,rect.bottom
        sub eax,rect.left
        sub edx,rect.top
        invoke MoveWindow,AddinPopup,rect.left,rect.top,eax,edx,TRUE
        .break

    .case WM_SHOWWINDOW
        mov eax,wParam
        shl eax,3
        invoke CheckMenuItem,AddinMenu,AddinID,eax
        .break

    .case WM_USER+100h
        invoke CreateDialogParam,hInst,IDD_DIALOG2,hWin,offset DlgProc,0
        .if eax != 0
            mov AddinPopup,eax
            invoke SendMessage,hWin,WAM_GETCLIENTRECT,0,addr rect
            mov eax,rect.right
            mov edx,rect.bottom
            sub eax,rect.left
            sub edx,rect.top
            invoke MoveWindow,AddinPopup,rect.left,rect.top,eax,edx,TRUE
        .else
            invoke PostMessage,hWin,WAM_DESTROYDOCKINGWINDOW,0,0
            xor eax,eax
        .endif
        ret

    .endswitch
    invoke CallWindowProc,pOldProc,hWin,uMsg,wParam,lParam
    ret

DockingProc endp
endif

; -------------------------------------------------------------------------
; QuickEditor plugin support
; -------------------------------------------------------------------------

QePlugIn proc hInstance,hMainWnd,hEd,hTool,hStat

    invoke ReadConfig,offset szWinErrINI
    invoke FindResource,hInst,IDD_DIALOG1,RT_DIALOG
    invoke LoadResource,hInst,eax
    invoke LockResource,eax
    .if eax != 0
        mov fModal,TRUE
        invoke DialogBoxIndirectParam,hInst,eax,hMainWnd,offset DlgProc,TRUE
        invoke WriteConfig
    .endif
    ret

QePlugIn endp

.const
dd offset CreateTextServices    ;This forces LINK to import Riched20.dll

end DllEntryPoint
