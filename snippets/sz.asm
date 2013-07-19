; http://www.madwizard.org/programming/snippets?id=77

; sz MACRO
;   by QvasiModo

; Example:
;               sz Sample
; assembles:
;               szSample db "Sample",0

sz macro arg
    sz&arg& db "&arg&",0
endm
