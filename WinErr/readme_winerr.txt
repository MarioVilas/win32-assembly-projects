WinErr 2.0.1.7
® 2003-2004 Mario Vilas (aka QvasiModo)
Last updated 19 Aug 04

--------------------------------------oOo--------------------------------------

Provides a quick lookup of system error codes and their descriptions. You can
 look for decimal numbers, hexadecimal numbers (preceded by "0x"), and equate
 names.

The list of errors currently supported includes system errors (GetLastError
 API), Winsock errors (WSAEGetLastError API), and OLE errors (as returned in
 EAX).

There are two versions (completely independent from each other):
    - WinErr.exe        Standalone version.
    - WinErr.dll      	AddIn version (see below).

The standalone version will store it's settings in WinErr.Ini, located at the
 same directory in wich WinErr.exe resides.

You can load the WinErr addin under the following IDEs:
    - AsmEdit, by Ewayne L. Wagner
    - Chrome (formerly known as MAsmEd), by Franck Charlet
    - QuickEditor, by Steve Hutchesson
    - RadAsm, by Ketil Olsen
    - WinAsm, by Antonis Kyprianou

If you want to know more about this programs, please follow this links:

    http://board.win32asmcommunity.net
    http://code4u.net/waforum
    http://radasm.visualassembler.com
    http://winasm.code4u.net
    http://www.masmforum.com

--------------------------------------oOo--------------------------------------

Integration with AsmEdit:

Copy WinErr.dll to your AddIns folder, and add it to the Addins menu. The call
 procedure name is "AsmEditProc". For a step-by-step explanation on how to do
 this, please refer to AsmEdit docs.

The settings will be saved in AddIns\WinErr.Ini. 

--------------------------------------oOo--------------------------------------

Integration with Chrome (v1.0 and above):

Copy WinErr.dll to your AddIns folder, and enable it from the Addins Manager.

You can install it under a previous version by just using "Update addin" in the
 context menu at the Addins Manager and selecting the last version of the dll
 (Chrome should handle the rest).

The settings will be saved in AddIns\WinErr.Ini. 

NOTE: This addin will NOT work with the old MAsmEd IDE, although it's shown in
 the Addins Manager. Attempting to load WinErr under MAsmEd will cause a GPF.

--------------------------------------oOo--------------------------------------

Integration with QuickEditor:
(http://www.masmforum.com)

Copy WinErr.dll in your masm32 folder, then open the menu editor (Edit -> Edit
 Menus) and add the following entry under the [Tools] section:

    Windows Error Descriptions,\masm32\WinErr.dll

To integrate the standalone version, add this entry instead:

    Windows Error Descriptions,\masm32\WinErr.exe

The Addin version will store it's settings in WinErr.Ini.

--------------------------------------oOo--------------------------------------

Integration with RadAsm (v2.0.3.0 and above):
(http://radasm.visualassembler.com)

Copy WinErr.dll to your AddIns folder and install it using Addin Manager.
To do it manually, add the following to the [AddIns] section of RadASM.ini:

    n=WinErr.dll,x,1

Where "n" is the next available addin number, and "x" is the option (0 to
 disable, 1 to enable).

For earlier versions of RadAsm, the following entry must be added instead:

    n=WinErr.dll,x

The settings will be stored in AddIns\WinErr.Ini.

--------------------------------------oOo--------------------------------------

Integration with WinAsm (v2.0.0.2 and above):
(http://winasm.code4u.net)

Copy WinErr.dll to your AddIns folder, and enable it from the Addins Manager.
The settings will be saved in AddIns\WAAddins.ini. 

--------------------------------------oOo--------------------------------------

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
