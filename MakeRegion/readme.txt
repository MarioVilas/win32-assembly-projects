MakeRegion - GDI region generating tool
Copyright ® Mario Vilas (aka QvasiModo)

Version: 1.03
Updated: 06-Aug-04

--------------------------------------oOo--------------------------------------

This is a programmers-oriented tool that helps when generating and editing GDI
 region objects from image files. It's main use is to precalculate region data
 needed for skinned windows and similar graphics operations.

The region data can be loaded from and saved to *.rgn files. Their format
 simply follows the RGNDATA structure, you can find it's description at the
 MSDN site (http://msdn.microsoft.com).

--------------------------------------oOo--------------------------------------

To integrate MakeRegion.exe with hutch's QuickEditor, follow this steps:

    1) Copy MakeRegion.exe to your MASM32 folder (typically C:\masm32)
    2) Open QuickEditor, then click on Edit -> Edit Menus
    2) Add the following entry in the [Tools] section:

        Launch Make&Region,C:\masm32\MakeRegion.exe

--------------------------------------oOo--------------------------------------

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the 
"Software"), to deal in the Software without restriction, including 
without limitation the rights to use, copy, modify, merge, publish, 
distribute, sublicense, and/or sell copies of the Software, and to 
permit persons to whom the Software is furnished to do so, subject to 
the following conditions:

The above copyright notice and this permission notice shall be included
 in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
