#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import ctypes
import win32api, win32con, win32gui

def controlIME(hwnd = None, ops = 0x0005, val = 0) -> int:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to control the status of the IME (Input Method Editor) on Windows OS for the specified application       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[ASSUMPTION]                                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] This function can only switch the Input Methods instead of the IME Modes                                                       #
#   |[2] Some IME holds different modes during input, such English mode and Chinese mode for Microsoft Pinyin; such modes cannot be     #
#   |     handled by this function                                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[REFERENCE]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] IME: https://learn.microsoft.com/zh-cn/windows/apps/design/input/input-method-editors                                          #
#   |[2] How to switch IME: https://blog.csdn.net/M_N_N/article/details/130586965                                                       #
#   |[3] How to switch modes for (Chinese) IME: https://www.zhihu.com/question/444869181/answer/5468947770                              #
#   |[4] Doc for <pywin32>: https://blog.csdn.net/freeking101/article/details/88231952                                                  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |hwnd        :   Handle of the window to manage                                                                                     #
#   |ops         :   Operation/instruction to control the IME                                                                           #
#   |                [0x0005          ] <Default> Set the purpose to get the status of IME                                              #
#   |                [0x0006          ]           Set the purpose to change the status of IME                                           #
#   |val         :   Message to send based on the instruction                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<int>       :   Differentiate when <ops> is provided on different purposes                                                         #
#   |                [1] Status code when <get>-ting the status of the IME                                                              #
#   |                [2] Return code when <set>-ting the status of the IME                                                              #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20241225        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, ctypes, win32api, win32con, win32gui                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Handle the parameter buffer.

    #050. Local parameters

    #100. Obtain the handle of the specified window
    if not hwnd:
        hwnd = win32gui.GetForegroundWindow()

    #200. Get the controller on the window
    imm32 = ctypes.WinDLL('imm32', use_last_error = True)
    hIME = imm32.ImmGetDefaultIMEWnd(hwnd)

    #500. Send the message to the controller
    status = win32api.SendMessage(hIME, win32con.WM_IME_CONTROL, ops, val)

    #900. Purge
    return(status)
#End controlIME

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )

    from omniPy.RPA import controlIME
    print(controlIME.__doc__)

    #100. Set the constants
    IMC_GETOPENSTATUS = 0x0005
    IMC_SETOPENSTATUS = 0x0006

    #200. Get the IME status of current window
    ime_curr = controlIME()
    # 0 for English as default value
    # 1 for Chinese on Windows CHS

    #300. Set the IME to English of current window
    ime_change = controlIME(ops = IMC_SETOPENSTATUS, val = 0)
#-Notes- -End-
'''
