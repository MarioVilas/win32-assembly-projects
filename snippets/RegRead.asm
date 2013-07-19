; http://www.madwizard.org/programming/snippets?id=73

; RegRead
;   by QvasiModo

; Reads a DWORD from a value in a registry key

; Lee un DWORD de un valor en una clave del registro

RegRead proto :dword,:dword,:dword

.code
RegRead proc hkey:dword,pszval:dword,dwdefval:dword
    local dwsize:dword
    mov dwsize,4
    invoke RegQueryValueEx,hkey,pszval,0,0,addr dwdefval,addr dwsize
    mov eax,dwdefval
    ret
RegRead endp
