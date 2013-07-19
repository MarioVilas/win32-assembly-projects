; http://www.madwizard.org/programming/snippets?id=74

; RegReadStr
;   by QvasiModo

; Reads an ASCIIZ string from a value in a registry key

; Lee una cadena ASCIIZ de un valor en una clave del registro

RegReadStr proto :dword,:dword,:dword,:dword

.code
RegReadStr proc hkey:dword,pszval:dword,lpval:dword,dwsize:dword
    invoke RegQueryValueEx,hkey,pszval,0,0,lpval,addr dwsize
    ret
RegReadStr endp
