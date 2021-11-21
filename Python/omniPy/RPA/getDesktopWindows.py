#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
#We have to import [pywintypes] to activate the DLL required by [pywin32]
#It is weird but works!
#Quote: (#12) https://stackoverflow.com/questions/3956178/cant-load-pywin32-library-win32gui
import pywintypes
import win32gui
from . import isWindowCloaked

def getDesktopWindows() -> 'Get the handles of all windows on current desktop':
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to get the handles of all visible windows on current desktop, even if they are minimized                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[REFERENCE]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   | https://stackoverflow.com/questions/61865399/win32gui-shows-some-windows-that-are-not-open                                        #
#   | https://stackoverflow.com/questions/64586371/filtering-background-processes-pywin32                                               #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<None>      :   This function does not take arguments                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<dict>      :   Dictionary with <keys> set as the [handles] of the windows found, while the <values> set as below for each:        #
#   |                [class   ] Class of the window by which to filter the dedicated one among these many                               #
#   |                [title   ] Title of the window by which to filter the dedicated one among these many                               #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20211120        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
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
#   |   |sys, win32gui                                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.RPA                                                                                                                     #
#   |   |   |isWindowCloaked                                                                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Handle the parameter buffer.

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
            rst.update({
                hwnd: {
                    'class' : win32gui.GetClassName(hwnd)
                    ,'title' : win32gui.GetWindowText(hwnd)
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
