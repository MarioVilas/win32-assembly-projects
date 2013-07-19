; http://www.madwizard.org/programming/snippets?id=71

; incl MACRO
;   by QvasiModo

; This macro is used to include all API libraries in a single line of code.

; Example:
;           incl kernel32,user32,gdi32
; assembles:
;           include \masm32\include\kernel32.inc
;           includelib \masm32\lib\kernel32.lib
;           include \masm32\include\user32.inc
;           includelib \masm32\lib\user32.lib
;           include \masm32\include\gdi32.inc
;           includelib \masm32\lib\gdi32.lib

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
    @CatStr ( <include \masm32\include\>, %incfile, <.inc> )
    @CatStr ( <includelib \masm32\lib\>, %incfile, <.lib> )
    if count eq countmax
        exitm
    endif
    count = count + 1
    goto incl_loop
endm
