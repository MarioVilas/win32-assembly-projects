/*
** Safe subclasser
** Copyright ® 2004 by Mario Vilas (aka QvasiModo)
** Please refer to the readme file for licensing and usage instructions.
*/

#ifndef SAFE_SUBCLASSER_INCLUDE_GUARD
#define SAFE_SUBCLASSER_INCLUDE_GUARD

#ifdef __cplusplus
extern "C" __stdcall {
#endif

    bool InitSubclasser(void);
    bool CleanupSubclasser(void);
    bool Subclass( HWND hWnd, WNDPROC pfWindowProc );
    bool Unsubclass( HWND hWnd, WNDPROC pfWindowProc );
    bool UnsubclassAll(void);
    WNDPROC GetNextWndProc( HWND hWnd, WNDPROC pfWindowProc );
    LRESULT CallNextWndProc( WNDPROC pfWindowProc, HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam );

#ifdef __cplusplus
}                  /* extern "C" __stdcall { */
#endif

#endif             /* ifndef SAFE_SUBCLASSER_INCLUDE_GUARD */
