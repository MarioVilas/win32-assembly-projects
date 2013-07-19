New Project Wizard Add-In for WinAsm Studio
Copyright (C) 2004-2005 Mario Vilas (aka QvasiModo)
All rights reserved.

Original filename: NewWiz.dll
Current version:   1.3.4.1
Last updated:      30 Sep 05

--------------------------------------oOo--------------------------------------

Index:

Install instructions
Usage instructions
	1) The "New Project" Wizard
		1.1) Create a new empty project
		1.2) Create a new project from a template
		1.3) Create a new project from existing sources
		1.4) Clone an existing project
	2) The "Project Properties" dialog box
		2.1) The "Build" page
		2.2) The "Run" page
		2.3) The "Misc" page
Notes on project templates
	1) Environment variables substitutions
	2) The [TEMPLATE] section
Notes for add-in developers
Acknowledgments
Legal

--------------------------------------oOo--------------------------------------

Install instructions:

To install, follow this steps:

1. Copy NewWiz.dll to your addins folder (typically C:\WinAsm\Addins).
2. Open the Addins Manager (Add-Ins -> Add-In Manager)
3. Select the addin and enable it. You can also set it to load on startup.

This is only needed for manual installs. If you installed WinAsm Studio from
 the self installing package, this add-in is already there. :)

To configure the add-in, go to the Addins Manager, select this add-in an click
 on the "Configure" button. A config dialog box will pop up, there you can
 enable or disable the GUI enhancements provided by this add-in, and set some
 other options as well.

--------------------------------------oOo--------------------------------------

Usage instructions:

When the addin is installed, some dialog boxes will be replaced by new ones.
 This features can be enabled or disabled by editing the add-ins INI file: at
 the section [New Project Wizard], you can edit the keys "EnableWizard" and/or
 "EnableProperties", set to 1 to enable or 0 to disable the enhanced versions
 of the new project wizard and project properties dialogs respectively.

1) The "New Project" Wizard

The dialog box to create new projects is replaced by a wizard. In the first
 page, the user is presented with this three options:

    1. Create a new empty project
    2. Create a new project from a template
    3. Create a new project from existing sources

The add-in will remember the last taken choices for each page.

1.1) Create a new empty project

The wizard will prompt for a project type, and a new empty project is
 immediately created. No mistery here. ;)

1.2) Create a new project from a template

Choose a template project (projects found typically at C:\WinAsm\Templates)
 and a target folder (you can create a new one). Then the addin will copy
 all files from the template into the target directory. After that, the new
 project file will be opened. For more details on some extra features when
 creating projects from templates, please see the notes below.

1.3) Create a new project from existing sources

After choosing a project type, you will be prompted for a list of files to
 be automatically included in the new project. Use this option, for example,
 if you want to convert an existing project for another IDE to WinAsm Studio.

1.4) Clone an existing project

This mode of operation is identical in all aspects to 1.3 (create a project
 from a template), except that it will let you take any WinAsm Studio project
 as if it was a template.

2) The "Project Properties" dialog box

This new version of the project properties box has two pages:

2.1) The "Build" page

From here you can configure all the command line switches that WinAsm Studio
 will use when building your project. This are the items you can configure:

	Type:		This is the project type. It can be one of the following:
				. Standard EXE
				. Standard DLL
				. Console Application
				. Static Library
				. Other (EXE)
				. Other (Non-EXE)
				. DOS Project
				The "Load" button lets you revert all other settings in this
				page to the defaults for the current project type. The "Save"
				button lets you change this defaults. Note that this defaults
				will also be used when creating new projects!

	Compile RC:	This are the command line switches to pass to the resource
				compiler (RC.EXE), in case the current project has an resource
				scripts. You can click on the "Switches" button (next to the
				text box) to visually add command line switches.

	Res To Obj:	This are the command line switches to pass to the .res to .obj
				file converter. If you don't specify any switches, this
				program won't be called during project build. You can click on
				the "Switches" button (next to the text box) to visually add
				command line switches.

	Assemble:	This are the command line switches to pass to the assembler
				(ML.EXE). You can click on the "Switches" button (next to the
				text box) to visually add command line switches.

	Link:		This are the command line switches to pass to the linker
				(LINK.EXE). You can click on the "Switches" button (next to
				the text box) to visually add command line switches.

	/OUT:		This lets you override the build output filename for your
				project. If you don't specify any, WinAsm will use the default
				filename (based on the project name). You can click on the
				"Browse" button (next to the text box) to browse for an output
				filename.

2.2) The "Run" page

From here you can specify any optional command line switches you may want
 WinAsm to pass to your program when you run it from the IDE. This page will
 only be enabled if you run the add-in on WinAsm Studio 3.0.2.7 or above, and
 the current project builds an EXE.

You can set two different command line switches for both "release" and "debug"
 modes. Additionally, each has a set of alternative command line switches;
 these will NOT be used by WinAsm, they're just provided for your commodity.
 You can click on the "Add" button (the one with a "plus" sign) to add the
 current command line switches to the set. The "Remove" button (the one with a
 "minus" sign) will remove from the set all selected lines.

2.3) The "Misc" page

Here are all the settings that didn't belong to any of the other pages.

You can choose the compiler WinAsm will use for this project. Currently only
 MASM32 and FASM are supported (you'll need Shoorick's FASM add-in for the
 latter). Default is MASM32.

There are two more options: "Auto increment file version" and "Handle RC files
incompatible statements silently", with obvious meanings.

--------------------------------------oOo--------------------------------------

Notes on project templates:

Project templates are found typically at C:\WinAsm\Templates. They are ordinary
 projects, whose .wap file MUST be named after the directory they reside. They
 are used to quickly create new projects without having to start from scratch.
 For more information on WinAsm Studio project templates, please see the help
 file (Help -> WinAsm Studio Help).

This add-in provides some features to enhance the functionality of WinAsm
 Studio project templates:

1) Environment variables substitutions

If you use any environment variables in the template's WAP file, they will be
 expanded when creating the new project. There are also some "special"
 environment variables provided by the add-in: (folders don't have an ending
 backslash in this case)

    %project%         Project filename
    %folder%          Project folder
    %title%           Project title
    %wafolder%        WinAsm folder (usually C:\WinAsm)
    %waaddins%        Add-Ins folder (usually C:\WinAsm\AddIns)
    %wabin%           Bin folder (usually C:\masm32\bin)
    %wainc%           Include folder (usually C:\masm32\include)
    %walib%           Library folder (usually C:\masm32\lib)

You can use this variables in the make command line switches (under the [MAKE]
 section in the .wap file), the project filenames (under the [FILES] section),
 and/or the run command line switches (under the [PROJECT] section).

2) The [TEMPLATE] section

Project templates can have an extra section named [TEMPLATE], which will be
 automatically removed from the resulting .wap file when creating a new
 project. This section contains some extra info the add-in can use.

This section currently has two keys: "Parse" and "Rename".

The "Parse" key consists of a list of filenames, separated by commas, in which
 the add-in will search for environment variable names and replace them for
 their contents.

The "Rename" key is a boolean (0 for false, 1 for true) that enables another
 feature: when this key is set to true, any files in the newly created project
 that have the same name as the template will be renamed after the new project
 title. For example, if you have a template called "Test", and you create a
 project named "New", all files named "Test.*" will be renamed to "New.*". Note
 that the add-in will NOT recurse subdirectories.

--------------------------------------oOo--------------------------------------

Notes for add-in developers:

Some private messages are sent to all addins in their FrameWindow procedure, to
 notify of certain events. The numeric IDs of this messages can be obtained
 like this:

	invoke RegisterWindowMessage,CTEXT("MessageStringID")

where "MessageStringID" is a placeholder for the actual string ID.

This are the supported string IDs and their corresponding events:

	WANewWizAddInBegin	(+1.1.0.7) The "New Project Wizard" addin has been
						 loaded. You can edit WAAddIns.ini before the settings
						 are read.
	WANewWizAddInEnd	(+1.1.0.7) The "New Project Wizard" addin has been
						 unloaded. You can edit WAAddIns.ini after the settings
						 are saved.
	WAProjPropMsg		(+1.1.0.0) The new project properties dialog box was
						 opened. Since it's a standard property sheet you can
						 add new pages to it. The wParam value is the window
						 handle. The expected page size is 227 x 220 DBUs.

--------------------------------------oOo--------------------------------------

Acknowledgments

A very warm thank you for Antonis Kyprianou for making the WinAsm IDE
 and helping me a lot with bugfixes and the code to create new projects. I'd
 also like to thank JimG for making the WinAsm Studio help file, and including
 this "readme" text in it; PhoBos for kindly providing most of the images I used
 here, and all the folks at the WinAsm Studio board for your bug reports and
 suggestions. :)

The left bar image ("Bar.bmp") was taken from Wizard Images Collection
 for Inno Setup, copyright (C) 1999-2003 Kornél Pál.

All other images were either taken from WinAsm Studio, or publically
 available on the Internet.

--------------------------------------oOo--------------------------------------

Legal

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the 
"Software"), to deal in the Software without restriction, including 
without limitation the rights to use, copy, modify, merge, publish, 
distribute, sublicense, and/or sell copies of the Software, and to 
permit persons to whom the Software is furnished to do so.

Acknowledgement is appreciated, but not required. :)

The Software is provided "as is", without warranty of any kind, express
or implied, including but not limited to the warranties of 
merchantability, fitness for a particular purpose and noninfringement.
In no event shall the authors or copyright holders be liable for any 
claim, damages or other liability, whether in an action of contract, 
tort or otherwise, arising from, out of or in connection with the
Software or the use or other dealings in the Software.

