; http://www.madwizard.org/programming/snippets?id=87

; GetFeaturesFlags
;  Coded by Mario Vilas (aka QvasiModo)
;  Gets the CPU features flags, as returned in EDX by the CPUID instruction.
;  Under processors that don't support this instruction (previous to Pentium), the returned value is 0.

GetFeaturesFlags    proto
ExceptionHandler    proto C pExcept:DWORD, pFrame:DWORD, pContext:DWORD, pDispatch:DWORD

SEH struct

    PrevLink        DWORD ?        ; Address of the previous SEH record.
    CurrentHandler  DWORD ?        ; Address of the exception handler.
    SafeOffset      DWORD ?        ; Address where it's safe to continue execution.
    PrevEsp         DWORD ?        ; Old value in ESP.
    PrevEbp         DWORD ?        ; Old value in EBP.

SEH ends

.code

align DWORD
ExceptionHandler proc C pExcept:DWORD, pFrame:DWORD, pContext:DWORD, pDispatch:DWORD

    mov     edx, pFrame
    mov     eax, pContext
    push    [edx].SEH.SafeOffset
    pop     [eax].CONTEXT.regEip
    push    [edx].SEH.PrevEsp
    pop     [eax].CONTEXT.regEsp
    push    [edx].SEH.PrevEbp
    pop     [eax].CONTEXT.regEbp
    mov     eax, ExceptionContinueExecution
    ret

ExceptionHandler endp

align DWORD
GetFeaturesFlags proc uses ebx
    local seh   :SEH

    pushcontext assumes
    assume      fs:nothing

    lea     eax, seh
    push    fs:[0]
    pop     seh.PrevLink
    mov     seh.CurrentHandler, offset ExceptionHandler
    mov     seh.SafeOffset,     offset EndTry
    mov     seh.PrevEsp, esp
    mov     seh.PrevEbp, ebp
    mov     fs:[0], eax
Try:
    push    1
    pop     eax
    cdq
    xor     ebx, ebx
    xor     ecx, ecx
    cpuid
EndTry:
    xchg    eax, edx
    push    seh.PrevLink
    pop     fs:[0]
    ret

    popcontext assumes

GetFeaturesFlags endp
