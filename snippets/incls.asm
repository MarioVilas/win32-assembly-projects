; http://www.madwizard.org/programming/snippets?id=70

; incls MACRO
;   by QvasiModo

; This macro is meant for placing all your snippets in a single folder (masm32snippets).
; The snippets files should end in ".inc" for the macro to work correctly.

; Example:
;           incls Sample
; assembles:
;           include \masm32\snippets\Sample.inc

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
    @CatStr ( <include \masm32\snippets\>, %incfile, <.inc> )
    if count eq countmax
        exitm
    endif
    count = count + 1
    goto incls_loop
endm
