#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
#We have to import [pywintypes] to activate the DLL required by [pywin32]
#It is weird but works!
#Quote: (#12) https://stackoverflow.com/questions/3956178/cant-load-pywin32-library-win32gui
import pywintypes
import win32gui, win32com

def setForegroundWindow(hwnd) -> 'Set the window to foreground as indicated by the provided handle':
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to set the window to foreground as indicated by the provided handle, resembling the function             #
#   | [win32gui.SetForegroundWindow] which sometimes has no effect but causes an error                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[REFERENCE]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] This function is quoted by below article:                                                                                      #
#   | https://exceptionshub.com/python-win32gui-setasforegroundwindow-function-not-working-properly.html                                #
#   |[2] Mapping table of [shell.sendkeys] is in below website:                                                                         #
#   | https://devguru.com/content/technologies/wsh/wshshell-sendkeys.html                                                               #
#   |[3] Below forum discussed on [Start] button and [Shell_TrayWnd] (Task Bar) exceptions, but it works fine for me regardless of them #
#   | https://stackoverflow.com/questions/30200381/python-win32gui-setasforegroundwindow-function-not-working-properly                  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<hwnd>      :   Handle of the window to be brought to foreground                                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<None>      :   This function has no return value but has direct effect on the provided handle                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20211126        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, win32gui, win32com                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Handle the parameter buffer.

    #050. Local parameters

    #100. Call a dispatch to [WScript.Shell]
    shell = win32com.client.Dispatch('WScript.Shell')

    #200. Send a special key [Alt] to the shell to avoid the unnecessary error of [win32gui]
    shell.SendKeys('%')

    #500. Bring the window to foreground by the provided handle
    win32gui.SetForegroundWindow(hwnd)

    #800. Send another key to the shell to cancel the effect of the previously entered key
    #[1] It is tested that when we enter some other string right after above step, the first letter was 'eaten'';
    # hence we assume it is caused by the effect of the previous [Alt] key.
    #[2] We choose the key [DOWN ARROW] to avoid conflict to most of the scenarios
    shell.SendKeys('{DOWN}')
#End setForegroundWindow

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )

    from omniPy.RPA import getDesktopWindows, setForegroundWindow
    print(setForegroundWindow.__doc__)

    #100. Retrieve all available windows on current desktop
    win_desktop = getDesktopWindows()

    #190. Bring the second window to front, as we know that currently the first one is this debug window
    setForegroundWindow(list(win_desktop.keys())[1])
#-Notes- -End-
'''
