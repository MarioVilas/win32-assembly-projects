;macros.inc
;collected by QvasiModo
;12 Jun 04

IFNDEF QvasiModo_Macros
QvasiModo_Macros equ TRUE

option dotname

; -------------------------------------------------------------------------
; Macros from various sources
; -------------------------------------------------------------------------

;From MASM32.HLP
@ArgI MACRO index:REQ, arglist:VARARG
	LOCAL count, retstr
	count = 0
	FOR arg, <arglist>
		count = count + 1
		IF count EQ index
			retstr textequ <arg>
		ENDIF
	ENDM
	EXITM <retstr>
ENDM

;From MASM32.HLP
@ArgRev MACRO arglist
	LOCAL txt, arg
	txt TEXTEQU <>
%	FOR arg, arglist
		txt CATSTR <arg>, <!,>, txt
	ENDM
 
	txt SUBSTR  txt, 1, @SizeStr( %txt ) - 1

	txt CATSTR  <!<>, txt, <!>>
	EXITM txt
ENDM

; This one comes with Hutch's Masm32 package
AppModel MACRO Processor
  Processor 			;; Processor type
  .model flat, stdcall  ;; 32 bit memory model
  option casemap :none  ;; case sensitive
ENDM

; From Ultrano's class.inc
CTEXT macro Text:VARARG
	local szText
	.data
	szText byte Text, 0
	.code
	exitm <offset szText>
endm

; This one comes with RadASM
m2m macro m1:REQ,m2:REQ
	push &m2&
	pop &m1&
endm

; I'm not sure where this one came from...
x2m macro m1:REQ,m2:REQ
	push &m1&
	push &m2&
	pop &m1&
	pop &m2&
endm

; This one was taken from CString 1.1 by NaN (Jaymeson Trudgen)
;$invoke MACRO Fun:REQ, A:VARARG
;  IFB <A>
;	invoke Fun
;  else
;	invoke Fun, A
;  endif
;  exitm <eax>
;ENDM

; -----------------------------------------------------------
; String Invoke by NaN (June 2004)
; 
; Masm32 stringed invoke. Example:
;
;   @invoke MessageBox, NULL, "@invoke Demo", "Pretty Cool", MB_OK
; 
; -----------------------------------------------------------
@invoke macro funct:REQ, args:VARARG
	LOCAL sz1
	sz1 TEXTEQU <funct>
	for arg, <args>
		if @InStr(1,arg,<!">)
			sz1 CATSTR sz1, <,>, ____CStr(arg)
		else
			sz1 CATSTR sz1, <,>, <arg> 
		endif
	endm
	%invoke sz1
	sz1 TEXTEQU <>
endm

; -----------------------------------------------------------
; $ String Invoke by NaN (June 2004)
; 
; Masm32 stringed invoke. Example:
;
;   mov ReturnVal, $invoke( MessageBox, NULL, "@invoke Demo", "Pretty Cool", MB_OK )
; 
; -----------------------------------------------------------
$invoke macro funct:REQ, args:VARARG
	LOCAL sz1
	sz1 TEXTEQU <funct>
	for arg, <args>
		if @InStr(1,arg,<!">)
			sz1 CATSTR sz1, <,>, ____CStr(arg)
		else
			sz1 CATSTR sz1, <,>, <arg> 
		endif
	endm
	%invoke sz1
	sz1 TEXTEQU <>
	exitm <eax>
endm

; -----------------------------------------------------------
; String background macros, used by @invoke and $invoke
; by NaN (June 2004)
; -----------------------------------------------------------
____CStr macro Text:REQ
    local TextReference
    .const
		TextReference ____ConvertString(Text)
    .code
    exitm <offset TextReference>
endm
____ConvertString MACRO Text:REQ
	LOCAL sz1
	y = 2
	x = 1
	z = 1
	sz1 TEXTEQU <>
	while x ne 0	
		x = @InStr(x, <Text>, <\n>)
		if x ne 0
			if (x ne y)
				z = 0
				sz1 CATSTR sz1, <,!">, @SubStr(<Text>,y,x-y), <!">
			endif			
			sz1 CATSTR sz1, <,13,10>
			y = x + 2
			x = y
		else
			if (z eq 0)
				if @InStr(1, @SubStr(<Text>,y), <!">) gt 1
					sz1 CATSTR sz1, <,!">, @SubStr(<Text>,y)
				endif					
			else
				sz1 CATSTR sz1, <,>, <Text>
			endif
		endif		
	endm
	sz1 SUBSTR sz1, 2
	exitm <db sz1,0>
endm

.block  	equ <.repeat>
.endblock   equ <.until TRUE>
.forever	equ <.until FALSE>

;by Biterider
; ————————————————————————————————————————
; Macro: JumpOn
; Purpose: Creates a jump table and executes a jump to a label according the content of a register.
; Arguments: Arg1: case register.
; Arg2: Jump labels.
; Returns: Nothing.
; Example: JumpOn eax, @@10, @@20, @@30
JumpOn macro RegName:req, Labels:vararg
local JumpTable, Count, Arg, CaseElse

.data
Count = 0
for Arg, <&Labels>
	ife Count
		JumpTable dd offset Arg
	else
		dd offset Arg
	endif
	Count = Count + 1
endm
.code
cmp RegName, &Count
jae CaseElse
jmp [offset JumpTable + 4 * RegName]
CaseElse:
endm

; by Biterider
; ————————————————————————————————————————
; Macro:     @Lower
; Purpose:   Converts a symbol string to lowercase.
; Arguments: Symbol string.
@Lower macro String:req
    local LowerStr, Letter, Pos, Character

    LowerStr textequ <>
    % forc Letter, <String>
      Pos InStr <ABCDEFGHIJKLMNOPQRSTUVWXYZ>, <Letter>
      if Pos gt 0
        Character SubStr <abcdefghijklmnopqrstuvwxyz>, Pos, 1
      else
        Character textequ <Letter>
      endif
      LowerStr CatStr LowerStr, Character
    endm
    exitm LowerStr
endm

; by Biterider
; ————————————————————————————————————————
; Macro:     @Upper
; Purpose:   Converts a symbol string to uppercase.
; Arguments: Symbol string.
@Upper macro String:req
    local UpperStr, Letter, Pos, Character

    UpperStr textequ <>
    % forc Letter, <String>
      Pos InStr <abcdefghijklmnopqrstuvwxyz>, <Letter>
      if Pos gt 0
        Character SubStr <ABCDEFGHIJKLMNOPQRSTUVWXYZ>, Pos, 1
      else
        Character textequ <Letter>
      endif
      UpperStr CatStr LowerStr, Character
    endm
    exitm UpperStr
endm

; Returns IP address as DWORD in network byte order
; Usage: $IPADDR(192,168,0,1)
; by Exagone [Thomas Bleeker]
$IPADDR	MACRO IPP1:REQ,IPP2:REQ,IPP3:REQ,IPP4:REQ
LOCAL	@val
	@val = IPP1 + (IPP2 SHL 8) + (IPP3 SHL 16) + (IPP4 SHL 24)
	EXITM	<&@val>
ENDM

; Returns port number as WORD in network byte order
; Usage: $PORTNR(1234)
; by Exagone [Thomas Bleeker]
$PORTNR	MACRO PORTNUMBER:REQ
LOCAL	@val
	@val = (PORTNUMBER SHR 8) + ((PORTNUMBER AND 0FFh) SHL 8)
	EXITM	<&@val>
ENDM

;Size optimized MOV by The Svin
movri macro reg:req,imm:req
 if imm EQ 0
 xor reg,reg
 elseif imm EQ -1
 or reg,-1
 elseif imm LT -128
 mov reg,imm
 elseif imm GT 127
 mov reg,imm
 else
 push imm
 pop reg
 endif 
endm

;Size optimized MOV by The Svin
movmi macro mem:req,imm:req
	if imm EQ 0
	and mem,0
	elseif imm EQ -1
	or mem,-1
	else
	mov mem,imm
	endif
endm

; Size optimized MOV by bitRAKE
movi macro memreg:req,imm:req
 if imm EQ 0
  if (OPATTR (memreg)) AND 00010000y
   xor memreg,memreg
  else
   and memreg,0
  endif
 elseif imm EQ -1
  or memreg,-1
 elseif imm LT -128
  mov memreg,imm
 elseif imm GT 127
  mov memreg,imm
 else
  push imm
  pop memreg
 endif
endm

;Enum macros by NaN
;
;You would use it like so:
;	ENUM  Data1, Data2, Data3, Data4
;
;Will produce:
;	Data1 EQU 0
;	Data2 EQU 1
;	Data3 EQU 2
;	Data4 EQU 3
;
;To adjust the starting number, do the following:
;	ENUM Data5:=10, Data6, Data7:=20, Data8
;
;Which would then produce:
;	Data5 EQU 10
;	Data6 EQU 11
;	Data7 EQU 20
;	Data8 EQU 21
;
;Additionally, i made a copy of this routine specifically to WM_USER messages.
; The same 'features' apply. Only the generated equates would look like:
;	[Label]  EQU WM_USER + [autoValue]

ENUM    MACRO   args:VARARG
    LOCAL a1, x1, sz1, sz2, sz3
    x1 = 0
    for arg, <args>
        a1 equ @InStr(1,arg,<:=> )
        if a1 ne 0
          x1 = @SubStr(arg,a1+2)
          sz1 EQU @SubStr(arg,1,a1-1)
        else
          sz1 EQU arg
        endif
        sz3 TEXTEQU %x1
        sz2 EQU @CatStr(sz1,< EQU >, sz3)
        x1 = x1 + 1
;        %echo sz2
        sz2
    endm
endm

ENUM_MSG    MACRO   args:VARARG
    LOCAL a1, x1, sz1, sz2, sz3
    x1 = 0
    for arg, <args>
        a1 equ @InStr(1,arg,<:=> )
        if a1 ne 0
          x1 = @SubStr(arg,a1+2)
          sz1 EQU @SubStr(arg,1,a1-1)
        else
          sz1 EQU arg
        endif
        sz3 TEXTEQU %x1
        sz2 EQU @CatStr(sz1,< EQU WM_USER + >, sz3)
        x1 = x1 + 1
;        %echo sz2
        sz2
    endm
endm

; -------------------------------------------------------------------------
; Some macros of my own
; -------------------------------------------------------------------------

;needs immediate values as params
;returns 00bbggrr (COLORREF order)
$RGB MACRO red:req,green:req,blue:req
	EXITM %(((blue) SHL 16) OR ((green) SHL 8) OR (red))
ENDM

; Define ASCIIZ string
sz macro arg:req
	sz&arg& db "&arg&",0
endm

; Returns a single bit mask
bit macro arg:req
	exitm %(1 shl &arg&)
endm

; Include API library
incl macro var:VARARG
	local count,countmax
	countmax = 0
	for arg, <var>
		countmax = countmax + 1
	endm
	if countmax eq 0
		exitm
	endif
	count = 1
:incl_loop
	incfile textequ @ArgI ( count, <var> )
;	@CatStr ( <include \masm32\include\>, %incfile, <.inc> )	;hardcoded path!
;	@CatStr ( <includelib \masm32\lib\>, %incfile, <.lib> )		;hardcoded path!
	@CatStr ( <include >, %incfile, <.inc> )
	@CatStr ( <includelib >, %incfile, <.lib> )
	if count eq countmax
		exitm
	endif
	count = count + 1
	goto incl_loop
endm

; Include snippet
incls macro var:VARARG
	local count,countmax
	countmax = 0
	for arg, <var>
		countmax = countmax + 1
	endm
	if countmax eq 0
		exitm
	endif
	count = 1
:incls_loop
	incfile textequ @ArgI ( count, <var> )
	@CatStr ( <include \masm32\snippets\>, %incfile, <.inc> )	;hardcoded path!
	if count eq countmax
		exitm
	endif
	count = count + 1
	goto incls_loop
endm

; Return immediate value in EAX
reti MACRO imm:REQ
	movi eax,&imm&
	ret
ENDM

; -----------------------
;this macros are for switch/case support (similar to C)

; mov eax,uMsg
; .switch eax
; .case WM_COMMAND
;   (...)
;   .break
; .case WM_NOTIFY
;   (...)
;   .break
; .default
;   (...)
; .endswitch

; Returns the label for the default case of the current .switch/.endswitch block.
$default equ <@CatStr ( !<SwitchDefault_!>, !%SwitchCount )>

; .switch {register or variable, defaults to EAX}
; a .block will assemble a jump to the matching .endswitch.
.switch macro regname:=<EAX>
	ifndef SwitchNesting
		SwitchNesting = 1
	else
		SwitchNesting = SwitchNesting + 1
	endif
	ifndef SwitchCount
		SwitchCount = 0
	else
		SwitchCount = SwitchCount + 1
	endif
	@CatStr ( <SwitchRegister_>, %SwitchNesting ) textequ <&regname&>
	@CatStr ( <SwitchFirstCase_>, %SwitchNesting ) = 1
	@CatStr ( <SwitchLastCase_>, %SwitchNesting ) = 0
	@CatStr ( <SwitchNeedDefault_>, %SwitchNesting ) = 0
	@CatStr ( <SwitchHasBlock_>, %SwitchNesting ) = 1
	.repeat
endm

; .nested (register or variable, defaults to EAX)
; behaves just like .switch, but does not create a block or default case label.
.nested macro regname:=<EAX>
	ifndef SwitchNesting
		SwitchNesting = 1
	else
		SwitchNesting = SwitchNesting + 1
	endif
	@CatStr ( <SwitchRegister_>, %SwitchNesting ) textequ <&regname&>
	@CatStr ( <SwitchFirstCase_>, %SwitchNesting ) = 1
	@CatStr ( <SwitchLastCase_>, %SwitchNesting ) = 0
	@CatStr ( <SwitchNeedDefault_>, %SwitchNesting ) = 0
	@CatStr ( <SwitchHasBlock_>, %SwitchNesting ) = 0
endm

; .case {value 1}, [value 2], (...), [value n]
.case macro var:vararg
	local value,isfirst,cond

	ifndef SwitchNesting
		.err <.case cannot be outside of a .switch/.endswitch block.>
		exitm
	endif
	if SwitchNesting lt 1
		.err <Bad .switch/.endswitch block.>
		exitm
	endif
	ife @CatStr ( <SwitchLastCase_>, %SwitchNesting )
		ife @CatStr ( <SwitchFirstCase_>, %SwitchNesting )
			.endif
		else
			@CatStr ( <SwitchFirstCase_>, %SwitchNesting ) = 0
		endif
		isfirst = 1
		for value, <var>
			if isfirst ne 0
				cond catstr <( SwitchRegister_>, %SwitchNesting, < == &value& )>
				isfirst = 0
			else
				cond textequ @CatStr ( %cond, < || ( SwitchRegister_>, %SwitchNesting, < == >, <&value&>, < )> )
			endif
		endm
		if isfirst eq 0
			.if cond
		endif
	else
		.err <.case cannot follow .default.>
	endif
endm

; .between {min 1}, {max 1}, [min 2], [max 2], (...), [min n], [max n]
; values must always be given in pairs
.between macro var:vararg
	local value,isfirst,iseven,cond,cond2

	ifndef SwitchNesting
		.err <.between cannot be outside of a .switch/.endswitch block.>
		exitm
	endif
	if SwitchNesting lt 1
		.err <Bad .switch/.endswitch block.>
		exitm
	endif
	ife @CatStr ( <SwitchLastCase_>, %SwitchNesting )
		ife @CatStr ( <SwitchFirstCase_>, %SwitchNesting )
			.endif
		else
			@CatStr ( <SwitchFirstCase_>, %SwitchNesting ) = 0
		endif
		isfirst = 1
		iseven = 1
		for value, <var>
			if isfirst ne 0
				;( ( reg >= value )
				cond catstr <( ( SwitchRegister_>, %SwitchNesting, < !>= &value& )>
				isfirst = 0
			else
				if iseven eq 1
					; || ( ( reg >= value )
					cond2 catstr <cond>, < || ( ( SwitchRegister_>, %SwitchNesting, < !>= &value& )>
					cond textequ cond2
				else
					; && ( reg <= value ) )
					cond2 catstr <cond>, < && ( SwitchRegister_>, %SwitchNesting, < !<= &value& ) )>
					cond textequ cond2
				endif
			endif
			iseven = -iseven
		endm
		if isfirst eq 0
			.if cond
		endif
	else
		.err <.between cannot follow .default.>
	endif
endm

; .caseif {condition}
; The condition must be a text literal to be passed to the .if macro.
; Remember to escape angle brackets with an exclamation sign.
.caseif macro cond:req
	ifndef SwitchNesting
		.err <.caseif cannot be outside of a .switch/.endswitch block.>
		exitm
	endif
	if SwitchNesting lt 1
		.err <Bad .switch/.endswitch block.>
		exitm
	endif
	ife @CatStr ( <SwitchLastCase_>, %SwitchNesting )
		ife @CatStr ( <SwitchFirstCase_>, %SwitchNesting )
			.endif
		else
			@CatStr ( <SwitchFirstCase_>, %SwitchNesting ) = 0
		endif
		.if cond
	else
		.err <.caseif cannot follow .default.>
	endif
endm

;sets a "default" location for code that will be executed if no .case is matched.
;use .breakdef to jump to this location from within a .case.
.default macro
	ifndef SwitchNesting
		.err <.default cannot be outside of a .switch/.endswitch block.>
		exitm
	endif
	if SwitchNesting lt 1
		.err <Bad .switch/.endswitch block.>
		exitm
	endif
	ife @CatStr ( <SwitchLastCase_>, %SwitchNesting )
		ife @CatStr ( <SwitchFirstCase_>, %SwitchNesting )
			.endif
		else
			.err <There should be at least one .case before .default.>
		endif
		@CatStr ( <SwitchLastCase_>, %SwitchNesting ) = 1
	else
		.err <There cannot be more that one .default in a .switch/.endswitch block.>
	endif
	@CatStr ( <SwitchNeedDefault_>, %SwitchNesting ) = 0
	@CatStr ( <SwitchLastCase_>, %SwitchNesting ) = 1
	if @CatStr ( <SwitchHasBlock_>, %SwitchNesting )
		@CatStr ( <SwitchDefault_>, %SwitchCount, <:> )
	endif
endm

; Jumps to the default case.
.breakdef macro cond
	ifndef SwitchNesting
		.err <.breakdef cannot be outside of a .switch/.endswitch block.>
		exitm
	endif
	if SwitchNesting lt 1
		.err <Bad .switch/.endswitch block.>
		exitm
	endif
	if @CatStr ( <SwitchHasBlock_>, %SwitchNesting )
		@CatStr ( <SwitchNeedDefault_>, %SwitchNesting ) = 1
	endif
;	jmp @CatStr ( <SwitchDefault_>, %SwitchCount )
	jmp $default
endm

;ends a switch block.
.endswitch macro
	if SwitchNesting lt 1
		.err <Bad .switch/.endswitch block.>
		exitm
	endif
	ife @CatStr ( <SwitchFirstCase_>, %SwitchNesting )
		ife @CatStr ( <SwitchLastCase_>, %SwitchNesting )
			.endif
		endif
	else
		.err <Empty .switch/.endswitch block?>
	endif
	if @CatStr ( <SwitchHasBlock_>, %SwitchNesting ) ne 0
		if @CatStr ( <SwitchNeedDefault_>, %SwitchNesting ) ne 0
			.err <Unmatched .breakdef, could branch to unexpected location!>
		endif
		.until TRUE
	endif
	SwitchNesting = SwitchNesting - 1
	if SwitchNesting lt 0
		.err <Bad .switch/.endswitch block.>
	endif
endm

; -----------------------

;this 3 macros are for generating window message handlers using jump tables
;this can only be done ONCE per module!
;the AddTable and BuildTable macros MUST be used BEFORE the JumpTable macro!

AddTable macro arg:req
	.code
	mov Table[arg * 4],offset @&arg&
	ifndef Table_Min
		Table_Min = 0
	endif
	ifndef Table_Max
		Table_Max = 0
	endif
	if Table_Min GT arg
		Table_Min = arg
	endif
	if Table_Max LT arg
		Table_Max = arg
	endif
endm
BuildTable macro
	.data
	align DWORD
	if Table_Min LT 0
			dd (-Table_Min + 1)	dup (offset Table_Default)
	endif
	Table 	dd (Table_Max + 1)	dup (offset Table_Default)
	.code
endm
JumpTable macro mem
	.code
	ifnb <mem>
		ifdifi <eax>, <mem>
			mov eax,mem
		endif
	endif
	if Table_Min LT 0
		cmp eax,Table_Min
		jl Table_Default
		cmp eax,Table_Max
		jg Table_Default
	else
		cmp eax,Table_Max
		ja Table_Default
	endif
	jmp Table[eax * 4]
Table_Default::
endm

; -------------------------------------------------------------------------

ENDIF
