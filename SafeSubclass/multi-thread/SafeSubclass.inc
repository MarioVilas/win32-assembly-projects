; Safe subclasser
; Copyright ® 2004 by Mario Vilas (aka QvasiModo)
; Please refer to the readme file for licensing and usage instructions.

InitSubclasser		proto
CleanupSubclasser	proto
Subclass			proto hWnd:HWND, pfWindowProc:WNDPROC
Unsubclass			proto hWnd:HWND, pfWindowProc:WNDPROC
UnsubclassAll		proto
GetNextWindowProc	proto hWnd:HWND, pfWindowProc:WNDPROC
CallNextWndProc		proto pfWindowProc:WNDPROC, hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
