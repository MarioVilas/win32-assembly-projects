Safe Subclasser
Copyright ® 2004 by Mario Vilas (aka QvasiModo)

Version:		1.02
Last updated:	15 Apr 04
Contact info:	http://board.win32asmcommunity.net

-oOo-

Description
~~~~~~~~~~~

This library allows programmers to safely subclass and unsubclass any
 windows, of any class, in any order, any time. The only restriction is
 that, when subclassing a window, it must belong to the calling thread.

It's particularly useful to do this in applications that support addins
 (also called plugins) that can be loaded or unloaded at arbitrary times.
 Using this library, the addins can subclass any windows belonging to the
 main application or other addins.

A linked list is mantained to keep the data belonging to each subclassed
 window. In turn, for each window there is a linked list of window
 procedures. In all lists items will be inserted in the beginning, so
 recently added window procedures will be executed first. This mimics the
 behavior of a "normal" subclassing chain.

Each thread has it's own linked list, independent from the others. Hence,
 you cannot call this functions to subclass a window in another thread.

It is REQUIRED to unsubclass a window if it's subclassed procedure resides
 in a dynamic link library about to be unmapped from memory. Failure to do
 so will cause a general protection failure (GPF).

-oOo-

Instructions
~~~~~~~~~~~~

First off, you need to initialize the library by calling InitSubclasser.
 When you are done with it, call CleanupSubclasser. You must not call any
 other functions from this library before InitSubclasser. Also you musn't
 make any other calls after CleanupSubclasser, except InitSubclasser again.
 This calls cannot be nested, that is, you can't call InitSubclasser twice
 without calling CleanupSubclasser in between.

Then, there are three functions you must use: Subclass and Unsubclass with
 their obvious meanings, and CallNextWndProc that finds and calls the next
 window procedure in the subclassing chain. You can also use GetNextWndProc
 to obtain the address for the next window procedure, and pass it to the
 CallWindowProc API function. To unsubclass ALL windows for the calling
 thread, use UnsubclassAll.

It is REQUIRED to unsubclass all windows from all threads before calling
 CleanupSubclasser. The function will not fail, but it won't unsubclass any
 windows either. This could cause problems from memory leaks to a GPF.

Here follows a more detailed description of each function, their parameters
 and return values:


1.	bool InitSubclasser(
 				void					// No parameters
 	);
 Description:
 	Initializes the safe subclasser library. No other calls to the library
 	 must be made before this one. Call CleanupSubclasser when you're done.
 Parameters:
 	No parameters.
 Return values:
 	If the function succeeds, the return value is TRUE.
 	If the function fails, the return value is FALSE. To get extended
 	 error information, call GetLastError.


2.	bool CleanupSubclasser(
 				void					// No parameters
 	);
 Description:
 	Uninitializes the safe subclasser library. No other calls to the
 	 library must be made after this one. You can call InitSubclasser
 	 if you want to use the library again.
 	Note that this function will NOT unsubclass any windows. The user
 	 is responsible for unsubclassing all windows from each thread
 	 BEFORE calling CleanupSubclasser.
 Parameters:
 	No parameters.
 Return values:
 	If the function succeeds, the return value is TRUE.
 	If the function fails, the return value is FALSE. To get extended
 	 error information, call GetLastError.


3.	bool Subclass(
 				HWND hWnd,				// Window handle
 				WNDPROC pfWindowProc	// Window procedure
 	);
 Description:
 	Subclasses a given window, adding the specified window procedure to
 	 the subclassing chain. Newly added procedures will be called first.
 	It is the caller's responsability to call the next procedures in the
 	 chain using CallNextWindowProc.
 Parameters:
 	hWnd:			Handle of window to be subclassed.
 	pfWindowProc:	Pointer to window procedure to use.
 Return values:
 	If the function succeeds, the return value is TRUE.
 	If the function fails, the return value is FALSE. To get extended
 	 error information, call GetLastError.


4.	bool Unsubclass(
 				HWND hWnd,				// Window handle
 				WNDPROC pfWindowProc	// Window procedure
 	);
 Description:
 	Unsubclasses a given window, removing the specified window procedure
 	 from the subclassing chain.
 Parameters:
 	hWnd:			Handle of window to be unsubclassed.
 	pfWindowProc:	Pointer to window procedure to remove.
 Return values:
 	If the function succeeds, the return value is TRUE.
 	If the function fails, the return value is FALSE. To get extended
 	 error information, call GetLastError.


5.	bool UnsubclassAll(
 				void					// No parameters
 	);
 Description:
 	Unsubclasses all windows for this thread.
 Parameters:
 	No parameters.
 Return values:
 	If the function succeeds, the return value is TRUE.
 	If the function fails, the return value is FALSE. To get extended
 	 error information, call GetLastError.


6.	WNDPROC GetNextWindowProc(
 				HWND hWnd,				// Window handle
 				WNDPROC pfWindowProc,	// Current window procedure
 	);
 Description:
 	Finds the next window procedure in the subclassing chain for the given
 	window.
 Parameters:
 	pfWindowProc:	Pointer to the current window procedure.
 	hWnd:			Handle of the subclassed window.
 	uMsg:			Message ID value passed to the window procedure.
 	wParam:			First message parameter passed to the window procedure.
 	lParam:			Second message parameter passed to the window procedure.
 Return values:
 	If the function succeeds, the return value is the address of the next
 	 window procedure. If none is found, the address of the original window
 	 procedure is given.
 	If the function fails, the return value is NULL. To get extended error
 	 information, call GetLastError.


7.	LRESULT CallNextWindowProc(
 				WNDPROC pfWindowProc,	// Current window procedure
 				HWND hWnd,				// Window handle
 				UINT uMsg,				// Message ID value
 				WPARAM wParam,			// First message parameter
 				LPARAM lParam			// Second message parameter
 	);
 Description:
 	Finds and calls the next window procedure in the subclassing chain for
 	 the given window.
 Parameters:
 	pfWindowProc:	Pointer to the current window procedure.
 	hWnd:			Handle of the subclassed window.
 	uMsg:			Message ID value passed to the window procedure.
 	wParam:			First message parameter passed to the window procedure.
 	lParam:			Second message parameter passed to the window procedure.
 Return values:
 	The return value specifies the result of the message processing and
 	 depends on the message sent.

-oOo-

License
~~~~~~~

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the 
"Software"), to deal in the Software without restriction, including 
without limitation the rights to use, copy, modify, merge, publish, 
distribute, sublicense, and/or sell copies of the Software, and to 
permit persons to whom the Software is furnished to do so.

Acknowledgement is appreciated, but not required. :)

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

