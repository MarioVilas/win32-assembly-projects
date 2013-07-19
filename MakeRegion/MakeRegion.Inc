include \masm32\macros\macros.inc

AppModel .486

include \masm32\include\windows.inc

incl kernel32,user32,gdi32,advapi32
incl ole32,oleaut32,comctl32,comdlg32
incl masm32

include Res.inc

MsgError        proto :dword
MsgWarning      proto :dword
MuestraCaption  proto :dword
SetBusy         proto
ResetBusy       proto
MakeRegion      proto
DlgProc         proto :dword,:dword,:dword,:dword
DlgProc2        proto :dword,:dword,:dword,:dword
DlgProc3        proto :dword,:dword,:dword,:dword
DlgProc4        proto :dword,:dword,:dword,:dword
DlgProc5        proto :dword,:dword,:dword,:dword
DlgProc6        proto :dword,:dword,:dword,:dword
DlgProc7        proto :dword,:dword,:dword,:dword
DlgProc8        proto :dword,:dword,:dword,:dword
Start           proto

MY_WIDTH_MAX    equ 280

transcolor  equ <cc.rgbResult>
backcolor   equ <cc2.rgbResult>

.data?
align DWORD
hinst       dd ?
hIconOn     dd ?
hIconOff    dd ?
hbmp        dd ?
hrgn        dd ?
tmprgn      dd ?
selrgn      dd ?

bitmap      BITMAP <>
DibSection  DIBSECTION <>
wp          WINDOWPLACEMENT <>

CustomColor dd 16 dup (?) 

RegionFile  db MAX_PATH dup (?)
ImageFile   db MAX_PATH dup (?)
TempFile    db (MAX_PATH + 12) dup (?)

CustFilter1 db MAX_PATH dup (?)
CustFilter2 db MAX_PATH dup (?)
CustFilter3 db MAX_PATH dup (?)

.data
fbusy       dd FALSE
fresize     dd FALSE
fmodified	dd FALSE

tolR        real4 0.0	;porcentajes de tolerancia
tolG        real4 0.0
tolB        real4 0.0

wc          WNDCLASS <CS_BYTEALIGNCLIENT or CS_BYTEALIGNWINDOW or CS_OWNDC,offset DefDlgProc,0,DLGWINDOWEXTRA,,0,0,COLOR_BTNFACE+1,0,offset szMRDlgClass>
mbp         MSGBOXPARAMS <sizeof MSGBOXPARAMS,,,,offset szError,MB_OK or MB_USERICON,IDI_ICON2,0,0,0>
mbp2        MSGBOXPARAMS <sizeof MSGBOXPARAMS,,,,offset szWarning,MB_YESNO or MB_USERICON,IDI_ICON3,0,0,0>
mbp3        MSGBOXPARAMS <sizeof MSGBOXPARAMS,,,,offset szWarning,MB_YESNOCANCEL or MB_USERICON,IDI_ICON3,0,0,0>
mbp4        MSGBOXPARAMS <sizeof MSGBOXPARAMS,,,offset szAltAbout,offset szAbout,MB_OK or MB_USERICON,IDI_ICON1,0,0,0>
ofn1        OPENFILENAME <sizeof OPENFILENAME,,,offset szFilter1,offset CustFilter1,sizeof CustFilter1,0,offset RegionFile,sizeof RegionFile,NULL,0,NULL,NULL,OFN_EXPLORER or OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST,,,offset szRgn>
ofn2        OPENFILENAME <sizeof OPENFILENAME,,,offset szFilter2,offset CustFilter2,sizeof CustFilter2,0,offset RegionFile,sizeof RegionFile,NULL,0,NULL,NULL,OFN_EXPLORER or OFN_HIDEREADONLY or OFN_OVERWRITEPROMPT or OFN_PATHMUSTEXIST,,,offset szRgn>
ofn3        OPENFILENAME <sizeof OPENFILENAME,,,offset szFilter3,offset CustFilter3,sizeof CustFilter3,0,offset ImageFile,sizeof ImageFile,NULL,0,NULL,NULL,OFN_EXPLORER or OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST>
cc          CHOOSECOLOR <sizeof CHOOSECOLOR,,,CLR_NONE,offset CustomColor,CC_FULLOPEN or CC_RGBINIT>
cc2         CHOOSECOLOR <sizeof CHOOSECOLOR,,,CLR_NONE,offset CustomColor,CC_FULLOPEN or CC_RGBINIT>
lf          LOGFONT <,,,,400,,,,,,,,,"Courier New">
rectVer     RECT <160,180,240,200>

;.const
lvc0        LV_COLUMN <LVCF_FMT or LVCF_SUBITEM or LVCF_TEXT or LVCF_WIDTH,LVCFMT_LEFT,70,offset szRectL,sizeof szRectL,0>
lvc1        LV_COLUMN <LVCF_FMT or LVCF_SUBITEM or LVCF_TEXT or LVCF_WIDTH,LVCFMT_LEFT,70,offset szRectT,sizeof szRectT,1>
lvc2        LV_COLUMN <LVCF_FMT or LVCF_SUBITEM or LVCF_TEXT or LVCF_WIDTH,LVCFMT_LEFT,70,offset szRectR,sizeof szRectR,2>
lvc3        LV_COLUMN <LVCF_FMT or LVCF_SUBITEM or LVCF_TEXT or LVCF_WIDTH,LVCFMT_LEFT,70,offset szRectB,sizeof szRectB,3>

sz RichEd32
sz MRDlgClass

szAbout     db "About...",0
szAltAbout  db "MakeRegion by QvasiModo (Mario Vilas)",13,10
szVer       db "v1.03 (06-Aug-04)",0

szCapBegin  db "MakeRegion - [",0
szDefCap    db "Untitled",0
szCapEnd    db "]",0

szNoPic     db "No picture loaded!",0
szSayWhat	db "???",0

sz OR
sz AND
sz XOR
sz DIFF

sz Error
szErrLoading db "An error occured, the region data was NOT loaded.",0
szErrSaving db "An error occured, the region data was NOT saved.",0
szErrImage  db "An error occured, the image could NOT be loaded.",0
szErrInt    db "An internal error occured.",0

sz Warning
szWarnClip  db "The new image is smaller than the previous one.",13,10,"Should the region data be clipped to the new size?",0
szWarnClip2 db "The new image is smaller than the one used to create the region.",13,10,"Should the region data be clipped to the new size?",0
szWarnBack  db "The background color has changed. If the image is a transparent GIF or PNG it should be reloaded.",13,10,"Reload the image?",0
szWarnRebuild db "Tolerance levels have been changed. Rebuild region data?",0
szWarnUnsaved db "The region data will be lost. Do you want to save it?",0

szCustomColorsKey db "Control Panel\Appearance",0
sz CustomColors

szPrefix    db "MR",0
szRgn       db "rgn",0

szRectL     db "RECT.left",0
szRectT     db "RECT.top",0
szRectR     db "RECT.right",0
szRectB     db "RECT.bottom",0

szFilter1   db "Region data files (*.rgn)",0
            db "*.rgn",0
            db "All files (*.*)",0
            db "*.*",0
            db 0
szFilter2   equ <szFilter1>
szFilter3   db "All supported image files",0
            db "*.gif;*.giff;*.jpg;*.jpeg;*.jpe;*.png;*.bmp",0
            db "Graphics Interchange Format (*.gif;*.giff)",0
            db "*.gif;*.giff",0
            db "JPEG File Interchange Format (*.jpg;*.jpeg;*.jpe)",0
            db "*.jpg;*.jpeg",0
            db "Portable Network Graphics (*.png)",0
            db "*.png",0
            db "Windows bitmap (*.bmp)",0
            db "*.bmp",0
            db "All files (*.*)",0
            db "*.*",0
            db 0

.code
;include LoadPicture.inc
include LoadPictureH.inc
include LoadResPicture.inc
include LoadFilteredIcon.inc
include CenterDialog.inc
