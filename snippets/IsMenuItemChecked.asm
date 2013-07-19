; http://www.madwizard.org/programming/snippets?id=69

; IsMenuItemChecked
;    by QvasiModo

; Returns TRUE (1) or FALSE (0)

IsMenuItemChecked proto :dword,:dword

.code
IsMenuItemChecked proc imic_hmenu:dword,imic_id:dword
    invoke GetMenuState,imic_hmenu,imic_id,MF_BYCOMMAND
    shr eax,3
    and eax,TRUE
    ret
IsMenuItemChecked endp
