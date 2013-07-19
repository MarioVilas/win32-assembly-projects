; http://www.madwizard.org/programming/snippets?id=68

; Exists
;   by QvasiModo

; Checks if a file exists
; Returns 0 if it doesn't exist, nonzero if it does.

; Se fija si un archivo existe
; Devuelve 0 si no existe, distinto de 0 si existe

Exists proto :dword

.code
Exists proc lpszFile
    local exists_w32fd:WIN32_FIND_DATA
    invoke FindFirstFile,lpszFile,addr exists_w32fd
    push eax
    invoke FindClose,eax
    pop eax
    inc eax
    ret
Exists endp
