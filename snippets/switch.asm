; http://www.madwizard.org/programming/snippets?id=81

; This is another example on how to implement switch macros
; using the built-it masm macros .if/.elseif/.endif.

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

; .switch {register or variable}
.switch macro regname:req
    ifndef SwitchNesting
        SwitchNesting = 1
    else
        SwitchNesting = SwitchNesting + 1
    endif
    @CatStr ( <SwitchRegister_>, %SwitchNesting ) textequ <®name&>
    @CatStr ( <SwitchFirstCase_>, %SwitchNesting ) = 1
    @CatStr ( <SwitchLastCase_>, %SwitchNesting ) = 0
    @CatStr ( <SwitchNeedDefault_>, %SwitchNesting ) = 0
    .repeat
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
; Remember to escape angle brackets with an exclamation point.
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

.default macro
    ifndef SwitchNesting
        .err <.default cannot be outside of a .switch/.endswitch block.>
        exitm
    endif
    if SwitchNesting lt 1
        .err <Bad .switch/.endswitch block.>
        exitm
    endif
    ifndef SwitchCount
        SwitchCount = 0
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
    @CatStr ( <SwitchDefault_>, %SwitchCount, <:> )
    SwitchCount = SwitchCount + 1
endm

.breakdef macro
    ifndef SwitchNesting
        .err <.breakdef cannot be outside of a .switch/.endswitch block.>
        exitm
    endif
    if SwitchNesting lt 1
        .err <Bad .switch/.endswitch block.>
        exitm
    endif
    ifndef SwitchCount
        SwitchCount = 0
    endif
    @CatStr ( <SwitchNeedDefault_>, %SwitchNesting ) = 1
    jmp @CatStr ( <SwitchDefault_>, %SwitchCount )
endm

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
    if @CatStr ( <SwitchNeedDefault_>, %SwitchNesting ) ne 0
        .err <Unmatched .breakdef, could branch to unexpected location!>
    endif
    .until TRUE
    SwitchNesting = SwitchNesting - 1
    if SwitchNesting lt 0
        .err <Bad .switch/.endswitch block.>
    endif
endm
