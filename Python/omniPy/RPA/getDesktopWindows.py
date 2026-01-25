#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, re
#We have to import [pywintypes] to activate the DLL required by [pywin32]
#It is weird but works!
#Quote: (#12) https://stackoverflow.com/questions/3956178/cant-load-pywin32-library-win32gui
import pywintypes
import win32gui
from typing import Optional
from collections.abc import Iterable
from omniPy.RPA import isWindowCloaked

def getDesktopWindows(
    classes : Optional[str | Iterable[str]] = None
    ,titles : Optional[str | Iterable[str]] = None
    ,regex : bool = False
) -> dict:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to get the handles of all visible windows on current desktop, even if they are minimized                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[REFERENCE]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] https://stackoverflow.com/questions/61865399/win32gui-shows-some-windows-that-are-not-open                                     #
#   |[2] https://stackoverflow.com/questions/64586371/filtering-background-processes-pywin32                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |classes     :   Iterable of <class> strings to filter from the results                                                             #
#   |                 [<None>      ] <Default> Function does not filter out any class                                                   #
#   |titles      :   Iterable of <title> strings to filter from the results                                                             #
#   |                 [<None>      ] <Default> Function does not filter out any title                                                   #
#   |regex       :   <bool> Whether to search for the names using RegExp                                                                #
#   |                 [False       ] <Default> Direct match of the window names                                                         #
#   |                 [True        ]           Match the certain pattern to the names                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<dict>      :   Dictionary with <keys> set as the <handles> of the windows found, while the <values> set as below for each:        #
#   |                [class   ] Class of the window by which to filter the dedicated one among these many                               #
#   |                [title   ] Title of the window by which to filter the dedicated one among these many                               #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20211120        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20211126        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Add arguments <classes> and <titles> to filter the windows when required                                                #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20251102        | Version | 2.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce new argument <regex> to enable fuzzy search inside window titles                                              #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |See the [Full Test Program] section                                                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |sys, collections, win32gui, typing                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |RPA                                                                                                                            #
#   |   |   |isWindowCloaked                                                                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Handle the parameter buffer.
    if classes is not None:
        if not isinstance(classes, Iterable):
            raise ValueError(f'[{LfuncName}][classes] must be iterable of character strings!')
        if isinstance(classes, str):
            classes = [classes]
        if not all([ isinstance(s, str) for s in classes ]):
            raise ValueError(f'[{LfuncName}][classes] must be iterable of character strings!')
    if titles is not None:
        if not isinstance(titles, Iterable):
            raise ValueError(f'[{LfuncName}][titles] must be iterable of character strings!')
        if isinstance(titles, str):
            titles = [titles]
        if not all([ isinstance(s, str) for s in titles ]):
            raise ValueError(f'[{LfuncName}][titles] must be iterable of character strings!')

    #050. Local parameters
    rstOut = {}

    #100. Define helper functions
    #110. Function as handler to filter the handles
    def winEnumHandler(hwnd, rst):
        if (
            True
            and win32gui.IsWindowEnabled(hwnd)
            and win32gui.IsWindowVisible(hwnd)
            and (win32gui.GetWindowTextLength(hwnd) != 0)
            and (not isWindowCloaked(hwnd))
        ):
            h_class = win32gui.GetClassName(hwnd)
            h_title = win32gui.GetWindowText(hwnd)

            if classes:
                if h_class not in classes:
                    return(None)
            if titles:
                if regex:
                    if not any([re.search(pat, h_title) for pat in titles]):
                        return(None)
                else:
                    if h_title not in titles:
                        return(None)

            rst.update({
                hwnd: {
                    'class' : h_class
                    ,'title' : h_title
                }
            })

    #500. Overwrite the dict [rstOut] by handling all windows on current OS
    win32gui.EnumWindows(winEnumHandler, rstOut)

    #900. Return the flag
    return(rstOut)
#End getDesktopWindows

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )

    from omniPy.RPA import getDesktopWindows
    print(getDesktopWindows.__doc__)

    #100. Retrieve all available windows on current desktop
    win_desktop = getDesktopWindows()

    #190. Print the dict if there is at least one window
    print(win_desktop)
#-Notes- -End-
'''
