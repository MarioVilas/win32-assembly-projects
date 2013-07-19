; This part will be executed by rundll32.exe, not WinAsm.

;Prototypes
DestroyTimer		proto hWnd:HWND, nIDEvent:DWORD
CheckForUpdates		proto lParam:LPARAM
AreWeScheduled		proto
TouchCached			proto pCached:PTR CACHED
CacheFile			proto pFile:PTR BYTE, pCached:PTR CACHED
UncacheFile			proto pCached:PTR CACHED
InitAgent			proto
QuitAgent			proto
UpdatesDlgProc		proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
WindowProc			proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
RunDll32			proto hwnd:HWND, hinst:HINSTANCE, lpCmdLine:LPSTR, cmdShow:SDWORD

FILETYPE struct

	dwID		DWORD ?		;Checkbox control ID
	dwIcon		DWORD ?		;Icon number
	pExt		DWORD ?		;File extension
	pName		DWORD ?		;Type name
	pDesc		DWORD ?		;Type description
	pNewName	DWORD ?		;ShellNew value name
	dwNewType	DWORD ?		;ShellNew value type
	pNewData	DWORD ?		;ShellNew data
	dwNewSize	DWORD ?		;ShellNew data size

FILETYPE ends

CACHED struct
	
	pNext	DWORD ?
	hFile	HANDLE ?
	hMap	HANDLE ?
	pBase	DWORD ?
	dwSize	DWORD ?
	
CACHED ends

LOADED struct
	
	pNext	dd ?
	hLib	dd ?
	
LOADED ends

.data
align DWORD

; Message window class
icce INITCOMMONCONTROLSEX <sizeof INITCOMMONCONTROLSEX,ICC_DATE_CLASSES or ICC_UPDOWN_CLASS>
wc WNDCLASS <CS_PARENTDC,offset WindowProc,0,DLGWINDOWEXTRA,,0,0,0,0,offset szWAA_Msg>
nid NOTIFYICONDATA <sizeof NOTIFYICONDATA,,1,NIF_ICON or NIF_MESSAGE or NIF_TIP,WM_USER+100h,,"WinAsm Agent">


sz WAA_Mutex
sz WAA_Msg
szNULL			equ offset $-1
szFmtInt		db "%i",0
szSpace			db " ",0

szRunDll32		db "RunDll32.exe",0
szCmd2			db ",RunDll32",0
szDllMask		db "*.dll",0
szExeFile		db "WinAsm.exe",0
szWAIniFile		db "WinAsm.ini",0

;szImageHelper	db "imagehlp",0
;sz <ImageLoad>
;sz <ImageUnload>

szFileTypes		db "FileTypes.dll",0
sz BeginPreserveTypes
sz EndPreserveTypes

szSection		db "FILES&PATHS",0
sz ADDINS
sz RECENT
sz FILES
sz KeyFile
sz APIFunctionsFile
sz APIStructuresFile
sz APIConstantsFile

szCaption				equ offset szAppName	;szCaption db "WinAsm Studio Agent",0
szAreYouSure			db "Are you sure you want to close the WinAsm Studio Agent?",13,10
						db "(It will restart automatically next time Windows starts).",0
szProgHasBeenUpdated	db "WinAsm Studio has been updated!",13,10
						db "Do you want to open a web browser window?",0
szAddinHasBeenUpdated	db "One or more WinAsm Studio add-ins have been updated!",13,10
						db "Do you want to open a web browser window?",0

.data?
align DWORD
msg				MSG <>
hMutex			dd ?

;hImageHelper	dd ?
;pImageLoad		dd ?
;pImageUnload	dd ?

hFileTypes		dd ?
pBeginPreserve	dd ?
pEndPreserve	dd ?

pAddins			dd ?
pProject		dd ?
pExe			dd ?
xExe			CACHED <>
xKeyfile		CACHED <>
xApi1			CACHED <>
xApi2			CACHED <>
xApi3			CACHED <>

szCommandLine	db MAX_PATH dup (?)
szCommandOnly	db MAX_PATH dup (?)
szParamOnly		db MAX_PATH dup (?)
szDllMaskPath	db MAX_PATH dup (?)
szDllPath		db MAX_PATH dup (?)
szAppPath		db MAX_PATH dup (?)
szExePath		db MAX_PATH dup (?)
szWAIniPath		db MAX_PATH dup (?)
szWapPath		db MAX_PATH dup (?)
szTypesPath		db MAX_PATH dup (?)
buffer			db (MAX_PATH*2) dup (?)

.code
align DWORD
DestroyTimer proc hWnd:HWND, nIEEvent:DWORD
	local tempmsg:MSG

	;WARNING: This function works correctly only if there
	;         is ONE timer for the target window!

	invoke KillTimer,hWnd,nIEEvent
@@:	test eax,eax
	jz @F
	invoke PeekMessage,addr tempmsg,hWnd,WM_TIMER,WM_TIMER,PM_REMOVE
	mov edx,tempmsg.wParam
	cmp edx,nIEEvent
	je @B
@@:	ret

DestroyTimer endp

align DWORD
CheckForUpdates proc lParam:LPARAM

	mov eax,lParam
	or eax,bUpdates
	.if ! zero?
		invoke InternetAttemptConnect,0
		.if eax == ERROR_SUCCESS
			invoke DialogBoxParam,hInstance,IDD_DIALOG3,nid.hwnd,offset UpdatesDlgProc,0
		.endif
	.endif
	ret

CheckForUpdates endp

align DWORD
AreWeScheduled proc
	local qwTime	:FILETIME

	invoke GetSystemTimeAsFileTime,addr qwTime
	invoke CompareFileTime,addr qwNextCheck,addr qwTime
	pushcontext assumes
	assume eax:SDWORD
	.if eax <= 0
	popcontext assumes
		mov eax,qwNextCheck.dwLowDateTime
		mov edx,qwNextCheck.dwHighDateTime
		add eax,eax
		adc edx,edx
		sub eax,qwLastCheck.dwLowDateTime
		sbb edx,qwLastCheck.dwHighDateTime
		push qwNextCheck.dwLowDateTime
		push qwNextCheck.dwHighDateTime
		mov qwNextCheck.dwLowDateTime,eax
		mov qwNextCheck.dwHighDateTime,edx
		pop qwLastCheck.dwHighDateTime
		pop qwLastCheck.dwLowDateTime
		invoke SaveDates
		push 1
		pop eax
	.else
		xor eax,eax
	.endif
	ret

AreWeScheduled endp

align DWORD
TouchCached proc pCached:PTR CACHED

	mov eax,pCached
	test eax,eax
	jz @F
	mov ecx,[eax].CACHED.dwSize
	mov edx,[eax].CACHED.pBase
	jecxz @F
	add ecx,4095
	shr ecx,12
	test edx,edx
	.while ! zero?
		mov eax,[edx]
		add edx,4096
		dec ecx
	.endw
@@:	ret

TouchCached endp

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
		invoke GetFileSize,eax,NULL
		.if eax
			mov [esi].CACHED.dwSize,eax
			invoke CreateFileMapping,[esi].CACHED.hFile,0,PAGE_READONLY,0,0,0
			.if eax
				mov [esi].CACHED.hMap,eax
				invoke MapViewOfFile,eax,FILE_MAP_READ,0,0,0
				.if eax
					mov [esi].CACHED.pBase,eax
					invoke TouchCached,esi
				.endif
			.endif
		.endif
	.endif
	ret

CacheFile endp

align DWORD
UncacheFile proc uses esi pCached:PTR CACHED

	mov esi,pCached
	xor eax,eax
	mov [esi].CACHED.dwSize,eax
	xchg [esi].CACHED.pBase,eax
	.if eax
		invoke UnmapViewOfFile,eax
	.endif
	xor eax,eax
	xchg [esi].CACHED.hMap,eax
	.if eax
		invoke CloseHandle,eax
	.endif
	xor eax,eax
	xchg [esi].CACHED.hFile,eax
	.if eax
		invoke CloseHandle,eax
	.endif
	ret

UncacheFile endp

align DWORD
InitAgent proc
	local hFind	:HANDLE
	local w32fd	:WIN32_FIND_DATA

	.if bLoadExe
;		invoke LoadLibrary,offset szImageHelper
;		.if eax
;			mov hImageHelper,eax
;			invoke GetProcAddress,eax,offset szImageUnload
;			test eax,eax
;			jz @F
;			mov pImageUnload,eax
;			invoke GetProcAddress,hImageHelper,offset szImageLoad
;			test eax,eax
;			jz @F
;			mov pImageLoad,eax
;			push NULL
;			push offset szExePath
;			call eax
;			test eax,eax
;			jz @F
;			mov pExe,eax
;		.else
@@:			invoke CacheFile,offset szExePath,offset xExe
;		.endif
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
	mov eax,bLoadExe
	or eax,bLoadUsed
	or eax,bLoadUnused
	or eax,bLoadProject
	or eax,bLoadWords
	.if ! zero?
		mov eax,dwTimer
		.if eax
			invoke SetTimer,nid.hwnd,1,eax,NULL
		.endif
	.endif
	.if bPreserveTypes
		invoke LoadLibrary,offset szTypesPath
		.if eax
			mov hFileTypes,eax
			invoke GetProcAddress,eax,offset szEndPreserveTypes
			.if eax
				mov pEndPreserve,eax
				invoke GetProcAddress,hFileTypes,offset szBeginPreserveTypes
				.if eax
					mov pBeginPreserve,eax
					call eax
				.endif
			.endif
		.endif
	.endif
	.if bUpdates
		invoke AreWeScheduled
		.if eax
			invoke CheckForUpdates,FALSE
		.endif
	.endif
	ret

InitAgent endp

align DWORD
QuitAgent proc

	invoke DestroyTimer,nid.hwnd,1
;	mov eax,pExe
;	mov edx,pImageUnload
;	.if eax && edx
;		push eax
;		call edx
;	.else
		invoke UncacheFile,offset xExe
;	.endif
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
	mov pProject,NULL
	mov esi,pAddins
	.while esi != NULL
		push [esi].LOADED.pNext
		invoke FreeLibrary,[esi].LOADED.hLib
		invoke LocalFree,esi
		pop esi
	.endw
	mov pAddins,NULL
	pop esi
	mov eax,hFileTypes
	.if eax
		push eax
		mov eax,pEndPreserve
		.if eax
			call eax
		.endif
		call FreeLibrary
	.endif
	mov hFileTypes,NULL
	mov pBeginPreserve,NULL
	mov pEndPreserve,NULL
;	mov eax,hImageHelper
;	.if eax
;		invoke FreeLibrary,eax
;	.endif
	ret

QuitAgent endp

align DWORD
UpdatesDlgProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local show	:DWORD
	local hinet	:DWORD
	local hconn	:DWORD
	local dwsize:DWORD
	local stime	:SYSTEMTIME
	local ftime	:FILETIME

	mov eax,uMsg
	.switch eax
	
	.case WM_COMMAND
		.break .if eax != IDCANCEL
		invoke EndDialog,hWnd,IDCANCEL
		.break
	
	.case WM_INITDIALOG
		and show,0
		invoke InternetOpen,offset szFriendlyName,INTERNET_OPEN_TYPE_PRECONFIG,NULL,NULL,0
		.if eax
			mov hinet,eax
			invoke InternetCheckConnection,offset szFolderURL,0,0
			.if eax == ERROR_SUCCESS
				invoke InternetOpenUrl,hinet,offset szFolderURL,NULL,0,
						INTERNET_FLAG_RELOAD or INTERNET_FLAG_NO_AUTH or \
						INTERNET_FLAG_NO_CACHE_WRITE or INTERNET_FLAG_NO_UI or \
						INTERNET_FLAG_PASSIVE or INTERNET_FLAG_PRAGMA_NOCACHE or \
						INTERNET_FLAG_RAW_DATA,addr lParam
				.if eax
					mov hconn,eax
					
					; TO DO ...
					
					;inc show
					
					invoke InternetCloseHandle,hconn
				.endif
			.endif
		.endif
		.if ! show
			invoke EndDialog,hWnd,0
		.endif
		push TRUE
		pop eax
		ret
	
	.endswitch
	xor eax,eax
	ret

UpdatesDlgProc endp

align DWORD
WindowProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	local point	:POINT

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
	
	.case WM_TIMER
		.if wParam == 1
			invoke TouchCached,offset xExe
			invoke TouchCached,offset xKeyfile
			invoke TouchCached,offset xApi1
			invoke TouchCached,offset xApi2
			invoke TouchCached,offset xApi3
			push esi
			mov esi,pProject
			.while esi != NULL
				push [esi].CACHED.pNext
				invoke TouchCached,esi
				pop esi
			.endw
			pop esi
			.break
		.endif
		invoke KillTimer,hWnd,wParam
		.break
	
	.case WM_COMMAND
		mov eax,wParam
		.nested eax
		
		.case ID_LAUNCH
			invoke ShellExecute,hWnd,NULL,offset szExePath,NULL,offset szAppPath,0
			.break
		
		.case ID_UPDATES
			invoke CheckForUpdates,TRUE
			.break
		
		.case ID_SETUP
			invoke DialogBoxParam,hInstance,IDD_DIALOG1,hWnd,offset DlgProc,0
			.break
		
		.case ID_CLOSE
			invoke MessageBox,hWnd,offset szAreYouSure,offset szCaption,
						MB_YESNO or MB_DEFBUTTON2 or MB_ICONWARNING
			.break .if eax != IDYES
			invoke PostQuitMessage,0
		
		.endswitch
		.break
	
	.case WM_USER+101h
		invoke QuitAgent
		invoke LoadConfig
		mov eax,iIcon
		and eax,7
		add eax,IDI_ICON0
		invoke LoadImage,hInstance,eax,IMAGE_ICON,0,0,0
		.if eax
			push nid.hIcon
			mov nid.hIcon,eax
			invoke Shell_NotifyIcon,NIM_MODIFY,offset nid
			call DestroyIcon
		.endif
		invoke InitAgent
		.break
	
	.case WM_CREATE
		push hWnd
		pop nid.hwnd
		invoke InitAgent
		.break
	
	.case WM_CLOSE
		mov eax,hMutex
		.if eax
			invoke CloseHandle,eax
			and hMutex,0
		.endif
		invoke PostQuitMessage,0
		.break
	
	.case WM_DESTROY
		invoke QuitAgent
	
	.endswitch
	invoke DefWindowProc,hWnd,uMsg,wParam,lParam
	ret

WindowProc endp

align DWORD
RunDll32 proc uses edi hwnd:HWND, hinst:HINSTANCE, lpCmdLine:LPSTR, cmdShow:SDWORD

	invoke InitCommonControlsEx,offset icce
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
			invoke lstrcpyn,offset szTypesPath,offset szDllPath,MAX_PATH - sizeof szFileTypes
			invoke lstrcat,offset szDllMaskPath,offset szDllMask
			invoke lstrcat,offset szIniPath,offset szIniFile
			invoke lstrcat,offset szTypesPath,offset szFileTypes
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
					mov eax,iIcon
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
								.continue .if (msg.message == WM_TIMER) && (msg.lParam != NULL)
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
		mov eax,hMutex
		.if eax
			invoke CloseHandle,eax
		.endif
	.endif
	
	xor eax,eax
	ret

RunDll32 endp
