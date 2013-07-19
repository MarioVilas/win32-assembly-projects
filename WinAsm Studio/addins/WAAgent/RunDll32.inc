
;Prototypes
RunDll32			proto hwnd:HWND, hinst:HINSTANCE, lpCmdLine:LPSTR, cmdShow:SDWORD
WindowProc			proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

CACHED struct
	
	pNext	DWORD ?
	hFile	HANDLE ?
	hMap	HANDLE ?
	pBase	DWORD ?
	
CACHED ends

LOADED struct
	
	pNext	dd ?
	hLib	dd ?
	
LOADED ends

.data

; Message window class
align DWORD
wc WNDCLASS <CS_PARENTDC,offset WindowProc,0,DLGWINDOWEXTRA,,0,0,0,0,offset szWAA_Msg>
nid NOTIFYICONDATA <sizeof NOTIFYICONDATA,,1,NIF_ICON or NIF_MESSAGE or NIF_TIP,WM_USER+100h,,"WinAsm Agent">

sz WAA_Mutex
sz WAA_Msg
szNULL			equ offset $-1
szFmtInt		db "%i",0

szRunDll32		db "RunDll32.exe ",0
szCmd2			db ",RunDll32",0
szDllMask		db "*.dll",0
szExeFile		db "WinAsm.exe",0
szWAIniFile		db "WinAsm.ini",0

szImageHelper	db "imagehlp",0
sz <ImageLoad>
sz <ImageUnload>

szSection		db "FILES&PATHS",0
sz ADDINS
sz RECENT
sz FILES
sz KeyFile
sz APIFunctionsFile
sz APIStructuresFile
sz APIConstantsFile

szCaption		equ offset szAppName	;szCaption db "WinAsm Studio Agent",0
szAreYouSure	db "Are you sure you want to close the WinAsm Studio Agent?",13,10
				db "(It will restart automatically next time Windows starts).",0

.data?
align DWORD
msg				MSG <>
hMutex			dd ?

hImageHelper	dd ?
pImageLoad		dd ?
pImageUnload	dd ?

pAddins			dd ?
pProject		dd ?
pExe			dd ?
xExe			CACHED <>
xKeyfile		CACHED <>
xApi1			CACHED <>
xApi2			CACHED <>
xApi3			CACHED <>

szCommandLine	db MAX_PATH dup (?)
szDllMaskPath	db MAX_PATH dup (?)
szDllPath		db MAX_PATH dup (?)
szAppPath		db MAX_PATH dup (?)
szExePath		db MAX_PATH dup (?)
szWAIniPath		db MAX_PATH dup (?)
szWapPath		db MAX_PATH dup (?)
buffer			db (MAX_PATH*2) dup (?)

.code
align DWORD
CacheFile proc uses esi pFile:PTR BYTE, pCached:PTR CACHED

	mov esi,pCached
	invoke CreateFile,pFile,GENERIC_READ,
			FILE_SHARE_READ or FILE_SHARE_WRITE,
			0,OPEN_EXISTING,FILE_FLAG_SEQUENTIAL_SCAN,0	;FILE_SHARE_DELETE
	inc eax
	.if ! zero?
		dec eax
		mov [esi].CACHED.hFile,eax
		invoke CreateFileMapping,eax,0,PAGE_READONLY,0,0,0
		.if eax
			mov [esi].CACHED.hMap,eax
			invoke MapViewOfFile,eax,FILE_MAP_READ,0,0,0
			.if eax
				mov [esi].CACHED.pBase,eax
				.if eax
					invoke GetFileSize,[esi].CACHED.hFile,0
					.if eax
						mov edx,[esi].CACHED.pBase
						add eax,4095
						shr eax,12
						.repeat
							mov ecx,[edx]
							add edx,4096
							dec eax
						.until zero?
					.endif
				.endif
			.endif
		.endif
	.endif
	ret

CacheFile endp

align DWORD
UncacheFile proc uses esi pCached:PTR CACHED

	mov esi,pCached
	mov eax,[esi].CACHED.pBase
	.if eax
		invoke UnmapViewOfFile,eax
	.endif
	mov eax,[esi].CACHED.hMap
	.if eax
		invoke CloseHandle,eax
	.endif
	mov eax,[esi].CACHED.hFile
	.if eax
		invoke CloseHandle,eax
	.endif
	ret

UncacheFile endp

align DWORD
WindowProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local hFind	:HANDLE
	local point	:POINT
	local w32fd	:WIN32_FIND_DATA

	mov eax,uMsg
	.switch eax
	
	.case WM_USER+100h
		.break .if wParam != 1
		mov eax,lParam
		.nested eax
		
		.case WM_LBUTTONDBLCLK
			invoke SendMessage,hWnd,WM_COMMAND,ID_LAUNCH,0
			.break
		
		.case WM_RBUTTONUP
			invoke GetCursorPos,addr point
			invoke LoadMenu,hInstance,IDM_MENU1
			.break .if eax == NULL
			push eax
			invoke GetSubMenu,eax,0
			push 0
			push hWnd
			push point.y
			push point.x
			push TPM_BOTTOMALIGN or TPM_RIGHTALIGN or TPM_LEFTBUTTON
			push eax
			invoke SetForegroundWindow,hWnd
			call TrackPopupMenuEx
			invoke PostMessage,hWnd,WM_NULL,0,0
			call DestroyMenu
			.break
		
		.case WM_RBUTTONDBLCLK
			invoke PostQuitMessage,0
		
		.endswitch
		.break
	
	.case WM_COMMAND
		mov eax,wParam
		.nested eax
		
		.case ID_LAUNCH
			invoke ShellExecute,hWnd,NULL,offset szExePath,NULL,offset szAppPath,0
			.break
		
		.case ID_CLOSE
			invoke MessageBox,hWnd,offset szAreYouSure,offset szCaption,
						MB_YESNO or MB_DEFBUTTON2 or MB_ICONQUESTION
			.break .if eax != IDYES
			invoke PostQuitMessage,0
		
		.endswitch
		.break
	
	.case WM_CREATE
		.if bLoadExe
			invoke LoadLibrary,offset szImageHelper
			.if eax
				mov hImageHelper,eax
				invoke GetProcAddress,eax,offset szImageUnload
				.if eax
					mov pImageUnload,eax
					invoke GetProcAddress,hImageHelper,offset szImageLoad
					.if eax
						mov pImageLoad,eax
						push NULL
						push offset szExePath
						call eax
						.if eax
							mov pExe,eax
						.endif
					.endif
				.endif
			.else
				invoke CacheFile,offset szExePath,offset xExe
			.endif
		.endif
		mov eax,bLoadUnused
		or eax,bLoadUsed
		.if eax
			push edi
			xor edi,edi
			invoke FindFirstFile,offset szDllMaskPath,addr w32fd
			mov hFind,eax
			.while eax
				test w32fd.dwFileAttributes,FILE_ATTRIBUTE_DIRECTORY
				jnz @3
				invoke GetPrivateProfileInt,offset szADDINS,addr w32fd.cFileName,0,offset szWAIniPath
				test eax,eax
				jz @1
				or bLoadUsed,0
				je @3
				jmp @2
			@1:	or bLoadUnused,0
				je @3
			@2:	invoke lstrcpy,offset buffer,offset szDllPath
				invoke lstrcat,offset buffer,addr w32fd.cFileName
				invoke LocalAlloc,LPTR,sizeof LOADED
				.if edi
					mov [edi].LOADED.pNext,eax
				.else
					mov pAddins,eax
				.endif
				mov edi,eax
				invoke LoadLibrary,offset buffer
				mov [edi].LOADED.hLib,eax
			@3:	invoke FindNextFile,hFind,addr w32fd
			.endw
			invoke FindClose,hFind
			pop edi
		.endif
		.if bLoadProject
			invoke GetPrivateProfileString,offset szRECENT,offset sz1,offset szNULL,
											offset szWapPath,sizeof szWapPath,offset szWAIniPath
			.if eax
				invoke LocalAlloc,LPTR,sizeof CACHED
				.if eax
					mov pProject,eax
					push ebx
					push esi
					xor ebx,ebx
					mov esi,eax
					invoke CacheFile,offset szWapPath,eax
					.repeat
						invoke wsprintf,offset buffer,offset szFmtInt,ebx
						invoke GetPrivateProfileString,offset szFILES,offset buffer,
							offset szNULL,offset buffer,MAX_PATH,offset szWapPath
						.break .if eax == 0
						invoke LocalAlloc,LPTR,sizeof CACHED
						.if eax
							mov [esi].CACHED.pNext,eax
							mov esi,eax
							invoke CacheFile,offset buffer,eax
						.endif
						inc ebx
					.until FALSE
					pop esi
					pop ebx
				.endif
			.endif
		.endif
		.if bLoadWords
			invoke GetPrivateProfileString,offset szSection,offset szKeyFile,offset szNULL,
											offset buffer,sizeof buffer,offset szWAIniPath
			.if eax
				invoke CacheFile,offset buffer,offset xKeyfile
			.endif
			invoke GetPrivateProfileString,offset szSection,offset szAPIFunctionsFile,offset szNULL,
											offset buffer,sizeof buffer,offset szWAIniPath
			.if eax
				invoke CacheFile,offset buffer,offset xApi1
			.endif
			invoke GetPrivateProfileString,offset szSection,offset szAPIStructuresFile,offset szNULL,
											offset buffer,sizeof buffer,offset szWAIniPath
			.if eax
				invoke CacheFile,offset buffer,offset xApi2
			.endif
			invoke GetPrivateProfileString,offset szSection,offset szAPIConstantsFile,offset szNULL,
											offset buffer,sizeof buffer,offset szWAIniPath
			.if eax
				invoke CacheFile,offset buffer,offset xApi3
			.endif
		.endif
		.break
	
	.case WM_CLOSE
		invoke PostQuitMessage,0
		.break
	
	.case WM_DESTROY
		mov eax,hImageHelper
		.if eax
			push eax
			mov eax,pExe
			.if eax
				mov edx,pImageUnload
				.if edx
					push eax
					call edx
				.endif
			.endif
			call FreeLibrary
		.else
			invoke UncacheFile,offset xExe
		.endif
		invoke UncacheFile,offset xKeyfile
		invoke UncacheFile,offset xApi1
		invoke UncacheFile,offset xApi2
		invoke UncacheFile,offset xApi3
		push esi
		mov esi,pProject
		.while esi != NULL
			push [esi].CACHED.pNext
			invoke UncacheFile,esi
			invoke LocalFree,esi
			pop esi
		.endw
		mov esi,pAddins
		.while esi != NULL
			push [esi].LOADED.pNext
			invoke FreeLibrary,[esi].LOADED.hLib
			invoke LocalFree,esi
			pop esi
		.endw
		pop esi
	
	.endswitch
	invoke DefWindowProc,hWnd,uMsg,wParam,lParam
	ret

WindowProc endp

align DWORD
RunDll32 proc uses edi hwnd:HWND, hinst:HINSTANCE, lpCmdLine:LPSTR, cmdShow:SDWORD

	; Allow only one instance
	invoke SetLastError,ERROR_SUCCESS
	invoke CreateMutex,NULL,TRUE,offset szWAA_Mutex
	.if eax
		mov hMutex,eax
		invoke GetLastError
		.if eax != ERROR_ALREADY_EXISTS
			
			; Parse files and paths
			mov edi,offset szDllPath
			invoke GetModuleFileName,hInstance,edi,MAX_PATH
			add edi,eax
			xchg ecx,eax
			std
			mov al,'\'
			repne scasb
			cld
			mov byte ptr [edi + 2],0
			mov edi,offset szExePath
			invoke lstrcpyn,edi,offset szDllPath,MAX_PATH - sizeof szDllMask
			invoke lstrcpyn,offset szDllMaskPath,offset szDllPath,MAX_PATH
			invoke lstrcpyn,offset szIniPath,offset szDllPath,MAX_PATH - sizeof szIniFile
			invoke lstrcat,offset szDllMaskPath,offset szDllMask
			invoke lstrcat,offset szIniPath,offset szIniFile
			invoke lstrlen,edi
			add edi,eax
			xchg eax,ecx
			sub edi,2
			std
			mov al,'\'
			repne scasb
			cld
			mov byte ptr [edi + 2],0
			invoke lstrcpyn,offset szWAIniPath,offset szExePath,MAX_PATH - sizeof szWAIniFile
			invoke lstrcpyn,offset szAppPath,offset szExePath,MAX_PATH
			invoke lstrcat,offset szExePath,offset szExeFile
			invoke lstrcat,offset szWAIniPath,offset szWAIniFile
			
			; Get config
			invoke LoadConfig
			
			; Start message window
			invoke GetModuleHandle,NULL
			mov wc.hInstance,eax
			invoke RegisterClass,offset wc
			.if eax != 0
				invoke CreateWindowEx,WS_EX_TRANSPARENT,eax,offset szCaption,
						WS_POPUP or WS_MINIMIZE,
						CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,
						hwnd,0,wc.hInstance,0		;HWND_MESSAGE
				.if eax != 0
					mov nid.hwnd,eax
					invoke GetPrivateProfileInt,offset szAppName,offset szIcon,0,offset szIniPath
					and eax,7
					add eax,IDI_ICON0
					invoke LoadImage,hInstance,eax,IMAGE_ICON,0,0,0
					.if eax != 0
						mov nid.hIcon,eax
						invoke Shell_NotifyIcon,NIM_ADD,offset nid
						.if eax != 0
							.repeat
								invoke GetMessage,offset msg,0,0,0
								inc eax
								.break .if zero?
								dec eax
								.break .if zero?
								invoke TranslateMessage,offset msg
								invoke DispatchMessage,offset msg
							.until FALSE
							invoke Shell_NotifyIcon,NIM_DELETE,offset nid
						.endif
						invoke DestroyIcon,nid.hIcon
					.endif
					invoke DestroyWindow,nid.hwnd
				.endif
				invoke UnregisterClass,offset szWAA_Msg,wc.hInstance
			.endif
			
		.endif
		invoke CloseHandle,hMutex
	.endif
	
	xor eax,eax
	ret

RunDll32 endp
