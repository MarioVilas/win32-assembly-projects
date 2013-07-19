HIWORD MACRO DoubleWord	 
	MOV EAX,DoubleWord
	SHR EAX,16
ENDM

LOWORD MACRO DoubleWord
	MOV EAX, DoubleWord
	AND EAX,0FFFFh
ENDM

M2M MACRO M1, M2
	PUSH M2
	POP M1
ENDM

; Helps to search selected text in the local MSDN console.
; MSDN console must be already run.
; Written to automate own usual "ritual" - select -> copy ->
; switch -> paste -> enter, now just shift+f1 -> enter ;)
; using "hack" way, so, use it on your own risk ;)
; you may "adjust" it to your own customs if you don't like something
; Puts current word in editor into the "Index" pane combobox or into
; the "Search" (QuasiModo mode). If nothing there just switch
; into MSDN or ignore (QuasiModo mode). Tested on july 2002 eng
; and jan 2004 eng versions of MSDN. Written by Shoorick, tested
; and improved by QuasiModo (Thanks to him!). To use feature QuasiModo
; likes set QuasiModo equ TRUE and recompile this AddIn ;)
; Hot-key adding based on WinAsm Studio Add-In By Antonis Kyprianou.
; Enjoy! Shoorick ;)

QuasiModo equ TRUE

.DATA?
pHandles	           		DWORD ?
hInstance					HINSTANCE ?	;DLL instance
hMain                       dd ?
hClient                     dd ?
hEditor                     dd ?
hMenu                       dd ?
hSubM                       dd ?
MenuID						dd ?
cntr                        dd ?
msdnw			            dd ?
msdnmenu		            dd ?
cmbbx			            dd ?
lstpn                       dd ?
lsdlg                       dd ?
wbuff                       db 128 dup(?)
ItemData                    MENUITEMINFO<?>            
rng                         CHARRANGE <?>

.DATA

; Specific constant data to find MSDN window:
cmbbxID         dd 996h
msdnclass		db "wndclass_desked_gsk",0
indx			db "Index",0
srch			db "Search",0
gpane			db "GenericPane",0

szFriendlyName	DB "Local MSDN Help Searcher",0
szDescription	DB "Helps search selected words.",13,10
                db "MSDN console must be running.",0
menutxt         db "MSDN Local Search",9,"Shift+F1",0
hello           db "MSDN Local Search Error",0,0
nfnd			db "Run MSDN before search!",0,0
nidx            db "MSDN Index Panel not found",0,0
