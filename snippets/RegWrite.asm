; http://www.madwizard.org/programming/snippets?id=75

; RegWrite
;   by QvasiModo

; Writes a DWORD from a value in a registry key

; Guarda un DWORD de un valor en una clave del registro

RegWrite proto :dword,:dword,:dword

.code
RegWrite proc hkey:dword,pszval:dword,dwval:dword
    invoke RegSetValueEx,hkey,pszval,0,REG_DWORD,addr dwval,4
    ret
RegWrite endp
