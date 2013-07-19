; http://www.madwizard.org/programming/snippets?id=76

; RegWriteStr
;   by QvasiModo

; Writes an ASCIIZ string from a value in a registry key

; Guarda una cadena ASCIIZ de un valor en una clave del registro

RegWriteStr proto :dword,:dword,:dword

.code
RegWriteStr proc hkey:dword,pszval:dword,lpstr:dword
    invoke lstrlen,lpstr
    inc eax
    invoke RegSetValueEx,hkey,pszval,0,REG_SZ,lpstr,eax
    ret
RegWriteStr endp
