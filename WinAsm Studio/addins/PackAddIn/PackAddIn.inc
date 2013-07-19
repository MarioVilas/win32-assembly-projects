include macros.inc

AppModel .386

include WINDOWS.INC
include \WinAsm\Inc\WAAddIn.inc

incl kernel32,user32,comdlg32,shell32,version,masm32

IFDEF DEBUG_BUILD
	incl debug		;VKim's debug library
ENDIF

;Prototypes for internal functions
DllEntryPoint	proto :DWORD,:DWORD,:DWORD
Updater_Copy	proto :DWORD,:DWORD
Updater			proto :DWORD
ReadBool		proto :DWORD,:DWORD
ReadConfig		proto
ReadProfile		proto
SaveBool		proto :DWORD,:DWORD
SaveConfig		proto
SaveProfile		proto
EnumProc		proto :DWORD,:DWORD
GetDef			proto
LaunchPacker	proto
DialogProc		proto :DWORD,:DWORD,:DWORD,:DWORD

;Prototypes for exported functions
GetWAAddInData	proto :DWORD,:DWORD
WAAddInLoad		proto :DWORD,:DWORD
FrameWindowProc	proto :DWORD,:DWORD,:DWORD,:DWORD
WAAddInUnload	proto

;Version equates (change only for compatibility)
ADDIN_VERSION		equ 02000200h		;2.0.2.0
WINASM_VERSION		equ 3016			;3.0.1.6

;Resource IDs
IDI_ICON1 equ 100
IDI_ICON2 equ 101
IDI_ICON3 equ 102
IDI_ICON4 equ 103
IDD_DIALOG1 equ 200
IDC_BUTTON1 equ 2000
IDC_BUTTON2 equ 2001
IDC_BUTTON3 equ 2002
IDC_CHECK1 equ 2003
IDC_CHECK2 equ 2004
IDC_CHECK3 equ 2005
IDC_CHECK4 equ 2006
IDC_CHECK5 equ 2007
IDC_COMBO1 equ 2008
IDC_EDIT1 equ 2009
IDC_EDIT2 equ 2010

hInst		equ <ofn.hInstance>			;Handle to addin library
hDlg		equ <ofn.hwndOwner>			;Handle to the "Options" dialog

.data?
pHandles	dd ?						;Pointer to WinAsm handles
AddinMenu	dd ?						;Handle to the "AddIns" menu
AddinID		dd ?						;Item ID for "Options"
MakeMenu	dd ?						;Handle to the "Make" menu
MakeID		dd ?						;Item ID for "Pack"

cpi			CURRENTPROJECTINFO <>		;Buffer to receive project info

szINI		db MAX_PATH dup (?)			;Full pathname to INI file
szCmdLine	db MAX_PATH dup (?)			;Commandline to packer
szExt		db MAX_PATH dup (?)			;List of supported extensions
buffer		db MAX_PATH dup (?)			;Multi use buffer (1)
buffer2		db MAX_PATH dup (?)			;Multi use buffer (2)

.data
bList		dd FALSE					;Boolean: Use list of supported extensions?
bHide		dd FALSE					;Boolean: Try to hide window?
bWait		dd TRUE						;Boolean: Wait for completion?
bQuotes		dd TRUE						;Boolean: Use quotes for file?
bAuto		dd FALSE					;Boolean: Auto run after build?

ofn OPENFILENAME <sizeof OPENFILENAME,,,offset szFilter,0,0,2,offset buffer,sizeof buffer,0,0,0,\
				offset szBrowse,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_NOCHANGEDIR or OFN_NOVALIDATE>
sinfo STARTUPINFO <sizeof STARTUPINFO,,,,,,,,,,,STARTF_FORCEONFEEDBACK,SW_HIDE>
mbp MSGBOXPARAMS <sizeof MSGBOXPARAMS,,,offset szOldWinAsm,offset szError,MB_OK or MB_USERICON,IDI_ICON4>

szFilter	label byte					;Filter for GetOpenFileName
			db "All files (*.*)",0,"*.*",0
			db "All PE files",0,"*.exe;*.bpl;*.dll;*.dpl;*.drv;*.ocx;*.scr;*.cpl",0
			db "Control Panel Applets (*.cpl)",0,"*.cpl",0
			db "Drivers (*.drv)",0,"*.drv",0
			db "Executables (*.exe)",0,"*.exe",0
			db "Libraries (*.dll)",0,"*.dll",0
			db "OCX Controls (*.ocx)",0,"*.ocx",0
			db "Screen Savers (*.scr)",0,"*.scr",0
			db 0

szProfileSection db "PackAddIn\"		;Profile key (fall through szProfile)
szProfile	db MAX_PATH dup (?)			;Current profile name

sz 0									;Digit 0 (for bool->asciiz string)
sz 1									;Digit 1 (for bool->asciiz string)
szSpace		db 32,0						;Space
szQuote		db 34,0						;Quote
szRoot		db "\",0					;Backslash
szNULL		equ $ - 1					;Null string
sz library								;The word "library" (used when reading DEF files)

szWAP		db ".wap",0					;WinAsm Studio Project
			db "."
szDLL		db "dll",0					;Dll project (type 1)
szEXE		db "exe",0					;Exe project (types 0,2,4)

sz PackAddIn							;New INI section
sz Error								;Error messagebox caption
sz Browse								;Browse popup caption
szPacking	db "Packing ...",0			;Status bar text when packing
szPossibleError	db "Packer finished, error status returned!",0

szAddinsINI		db "AddIns\WAAddIns.Ini",0						;Addins INI file
szDefCmdLine	db "upx.exe -v --best",0						;Default command line
szDefExt		db ".exe;.bpl;.dll;.dpl;.drv;.ocx;.scr;.cpl",0	;Default list of supported extensions

szThisVersion	db @CatStr( <!">, %ADDIN_VERSION, <!",0> )		;Decimal version string

; Old INI keys and file
sz UPXaddinWA							;Old INI section (v1.02)
sz HideOutput							;Equivalent to TryToHideWindow
szOldINI		db "\UPXaddin.Ini",0	;Old INI file (v1.00-1.01)
szUPXaddin 		db "UPX AddIn",0		;Old INI section (v1.00-1.01)

; INI file keys
sz AddInVersion							;Addin version
sz CommandLine							;Command line to packer
sz SupportedExtensions					;List of supported extensions
sz UseListOfExtensions					;Use list of supported extensions?
sz TryToHideWindow						;Try to hide window?
sz WaitForCompletion					;Wait for completion?
sz UseQuotesForFile						;Use quotes for file?
sz AutoRunAfterBuild					;Auto run after build?

; Addin description
IFDEF DEBUG_BUILD
	szName		db "EXE Packer AddIn v2.0.2.2 DEBUG",0
ELSE
	szName		db "EXE Packer AddIn v2.0.2.2",0
ENDIF
szDesc		db "Launches any PE packer of your choice after every successful build.",13,10,\
				"® 2004 Mario Vilas (aka QvasiModo)",0

; Menu items text
szMenuText1	db "EXE Packer AddIn Options",0
szMenuText2	db "Pack",0

; Error messages
szOldWinAsm db "You need WinAsm Studio version 3.0.1.6 or above to use this addin!",0

; Default profiles data (used only when updating the config file)
DEF_PROFILES equ 15
Def_Profiles label byte

	; ASPack, by Alexey Solodovnikov (www.aspack.com)
	db "ASPack",0
	db "aspack.exe /M /R+ /B+ /E+ /D+ /Q",0
	db 1

	; Exe32pack, by SteelBytes (louis@SteelBytes.com)
	db "Exe32pack",0
	db "exe32pack.exe /M:0",0
	db 1

	; PE Compact, by Jeremy Collake (www.CollakeSoftware.com)
	db "PE Compact",0
	db "PECompact.exe",0
	db 0

	; PECRYPT32, by random and killa and acpizer
	db "PECRYPT32",0
	db "pe-crypt.exe",0
	db 0

	; PELock (www.pelock.prv.pl)
	db "PELock",0
	db "pelock.exe",0
	db 0

	; PELOCKnt, by MARQUIS and WIESEL
	db "PELOCKnt",0
	db "pelocknt.exe",0
	db 1

	; PE-PaCK, by ANAKiN (anakin__@gmx.net)
	db "PE-PaCK",0
	db "pepack.exe",0
	db 1

	; PE-PROTECT, by Christoph Gabler (ChristophG1@Hotmail.Com)
	db "PE-PROTECT",0
	db "pe-prot.exe",0
	db 1

	; Petite, by Ian Luck (www.un4seen.com/petite)
	db "Petite (Console)",0
	db "petite.exe -9 -e2 -y -p0 -r** -x23,24,2110",0
	db 1

	; Petite, by Ian Luck (www.un4seen.com/petite)
	db "Petite (GUI)",0
	db "petgui.exe -9 -e2 -y -p0 -r** -x23,24,2110",0
	db 0

	; StampVer, by Paul Dixon (www.elphin.com/products/stampver.html)
	db "StampVer",0
	db "StampVer.exe -k -i4",0
	db 1

	; Ultimate Packer for eXecutables, by Markus Oberhumer & Laszlo Molnar (upx.sourceforge.net)
	db "UPX",0
	db "upx.exe -v --best",0
	db 1

	; VGCrypt PE Encryptor, by Virogen (http://virogen.cjb.net)
	db "VGCrypt PE Encryptor",0
	db "vgcrypt.exe",0
	db 1

	; Virogen's PE Realigner, by Virogen (http://virogen.cjb.net)
	db "Virogen's PE Realigner",0
	db "vgalign.exe",0
	db 1

	; yoda's Crypter, by yoda (y0da.cjb.net)
	db "yoda's Crypter",0
	db "yC.exe",0
	db 0

; More default profiles (2.0.1.6 and above)
DEF_PROFILES2 equ 13
Def_Profiles2 label byte

	; EZIP, by Jonathan Clarke (www.jonathanclarke.com)
	db "EZIP",0
	db "ezip.exe",0
	db 0

	; JDPack, by Jiang Dong (www.tlz18.com)
	db "JDPack",0
	db "jdpack.exe",0
	db 0

	; Mew 5 packer, by Northfox (hcc.kenyer.hu)
	db "Mew 5 packer",0
	db "mew5.exe",0
	db 1

	; Mew 10 packer, by Northfox (hcc.kenyer.hu)
	db "Mew 10 packer",0
	db "mew10.exe",0
	db 1

	; PE Compact 2, by Jeremy Collake (www.CollakeSoftware.com)
	db "PE Compact 2 (Console)",0
	db "pec2.exe /Quiet /CompressionLevel=9 /CodecHost=pec2codec_crc32.dll,pec2codec_ffce.dll /HooksHost=pec2hooks_fastimport",0
	db 1

	; PE Compact 2, by Jeremy Collake (www.CollakeSoftware.com)
	db "PE Compact 2 (GUI)",0
	db "pec2gui.exe",0
	db 0

	; PE Insert, by Jeremy Collake (www.CollakeSoftware.com)
	db "PE Insert",0
	db "PEInsert /DataFile=file.dat",0
	db 1

	; PE Trim, by Jeremy Collake (www.CollakeSoftware.com)
	db "PE Trim",0
	db "PETrim.exe /Align=512 /StripFixups=A /StripDebug=Y",0
	db 1

	; PE Watermark, by Jeremy Collake (www.CollakeSoftware.com)
	db "PE Watermark",0
	db "PEWaterMark.exe /mark=0x12345678",0
	db 1

	; Shrinker, from Blink Inc (www.blinkinc.com)
	db "Shrinker (16 bits)",0
	db "Shrinker.exe -BQ -CF9 -CS -OB -OO",0
	db 1

	; Shrinker, from Blink Inc (www.blinkinc.com)
	db "Shrinker (32 bits)",0
	db "Shrink32.exe -BQ -CF9 -CS -OB -OO -RIF -RO-",0
	db 1

	; UPX Shell, by Ion Tek (upxshell.sf.net)
	db "UPX Shell",0
	db "UPXShell.exe",0
	db 0

	; WWPack32, by Piotr Warezak and Rafal Wierzbicki
	db "WWPack32",0
	db "WWPack.exe",0
	db 0
