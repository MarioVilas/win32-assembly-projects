.386
.model flat,stdcall
option casemap:none

include windows.inc
include ..\WAAddIn.inc
include ..\WAAddInLib.inc

include kernel32.inc
include user32.inc
include comctl32.inc
include shell32.inc
include shlwapi.inc

includelib kernel32.lib
includelib user32.lib
includelib comctl32.lib
includelib shell32.lib
includelib shlwapi.lib

externdef hInstDll		:DWORD
externdef pHandles		:DWORD
externdef pFeatures		:DWORD
externdef szIniFile		:BYTE	;MAX_PATH
externdef pszSection	:DWORD

GetWAAddInData		proto :PTR BYTE, :PTR BYTE
WAAddInLoad			proto :PTR HANDLES, :PTR FEATURES
WAAddInUnload		proto
FrameWindowProc		proto :HWND, :UINT, :WPARAM, :LPARAM
ChildWindowProc		proto :HWND, :UINT, :WPARAM, :LPARAM
ProjectExplorerProc	proto :HWND, :UINT, :WPARAM, :LPARAM
OutWindowProc		proto :HWND, :UINT, :WPARAM, :LPARAM

sz macro arg:req
	sz&arg& db "&arg&",0
endm
