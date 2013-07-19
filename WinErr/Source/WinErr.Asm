include ..\macros.inc
AppModel .386
include \masm32\include\windows.inc
include ..\resource.inc
incl kernel32,user32,gdi32,comctl32,riched20,winmm,masm32

.data?
hInst       dd ?
AddinPopup  dd ?
fActive     dd ?

szINI		db (MAX_PATH + 20) dup (?)
wp          WINDOWPLACEMENT <>

include ..\Errors.inc

include LoadFilteredIcon.inc

STANDALONE_VERSION equ TRUE
include ..\DlgProc.Inc

.const
sz WinErr
sz WindowPlacement
sz LastCode

szIniFile db "WinErr.Ini",0

.code
start:
; ------------------------------
; Read config
; ------------------------------
invoke GetModuleFileName,NULL,offset szINI,MAX_PATH
invoke lstrlen,offset szINI
mov ecx,eax
lea edi,[offset szINI + eax]
mov al,'\'
std
repne scasb
cld
add edi,2
invoke lstrcpy,edi,offset szIniFile
invoke GetPrivateProfileStruct,offset szWinErr,offset szWindowPlacement,
                               offset wp,sizeof wp,offset szINI
invoke GetPrivateProfileString,offset szWinErr,offset szLastCode,offset buffer,
                               offset buffer,sizeof buffer,offset szINI
; ------------------------------
; Show dialog box
; ------------------------------
mov hInst,$invoke(GetModuleHandle,0)
invoke DialogBoxParam,eax,IDD_DIALOG1,HWND_DESKTOP,offset DlgProc,eax
; ------------------------------
; Write config
; ------------------------------
.if wp.iLength == sizeof WINDOWPLACEMENT
    invoke WritePrivateProfileStruct,offset szWinErr,offset szWindowPlacement,
                                     offset wp,sizeof wp,offset szINI
.endif
invoke WritePrivateProfileString,offset szWinErr,offset szLastCode,offset buffer,offset szINI
; ------------------------------
; Quit
; ------------------------------
invoke ExitProcess,0

.const
dd offset CreateTextServices    ;This forces LINK to import Riched20.dll

end start
