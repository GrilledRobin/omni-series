#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import ctypes
from ctypes.wintypes import HWND, DWORD

def isWindowCloaked(hwnd) -> 'Verify whether a window is [Cloaked] by its handle':
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to verify whether the provided handle of a specific window has the property DWMWA_CLOAKED set as         #
#   | non-zero value as retrieved by [DwmGetWindowAttribute]                                                                            #
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
#   |hwnd        :   Handle of the window to investigate. A handle can be retrieved by [win32gui.EnumWindows]                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<bool>      :   Boolean/logical result                                                                                             #
#   |                [True    ] The provided window is cloaked                                                                          #
#   |                [False   ] The provided window is normal to operate from inside                                                    #
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
#   |   |sys, ctypes                                                                                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Handle the parameter buffer.

    #050. Local parameters
    DWMWA_CLOAKED = 14
    isCloacked = ctypes.c_int(0)

    #100. Initialize the Desktop Window Manager (DWM) through api
    dwmapi = ctypes.WinDLL('dwmapi')

    #500. Overwrite the ctypes object [isCloacked] by the exported attribute of [DwmGetWindowAttribute]
    dwmapi.DwmGetWindowAttribute(HWND(hwnd), DWORD(DWMWA_CLOAKED), ctypes.byref(isCloacked), ctypes.sizeof(isCloacked))

    #900. Return the flag
    return(isCloacked.value != 0)
#End isWindowCloaked

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import sys
    import win32gui
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )

    from omniPy.RPA import isWindowCloaked
    print(isWindowCloaked.__doc__)

    #100. Verify a [cloaked] window
    #110. Setup a simple handler to retrieve the cloaked windows of [Microsoft Store]
    def winEnumHandler(hwnd, rst):
        if win32gui.GetWindowText(hwnd) == 'Microsoft Store':
            rst.append(hwnd)

    #150. Retrieve these windows as they exist at the backend of Win10 in most of the cases
    hwnd_MSStore = []
    win32gui.EnumWindows(winEnumHandler, hwnd_MSStore)

    #190. Print the attribute of the last among them
    if hwnd_MSStore:
        print(isWindowCloaked(hwnd_MSStore[-1]))
#-Notes- -End-
'''
