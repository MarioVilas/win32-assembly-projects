; http://www.madwizard.org/programming/snippets?id=80
; The $RGB macro returns a COLORREF dword, and takes immediate values as params.

;needs immediate values as params
;returns 00bbggrr (COLORREF order)
$RGB MACRO red,green,blue
    EXITM %(((blue) SHL 16) OR ((green) SHL 8) OR (red))
ENDM
