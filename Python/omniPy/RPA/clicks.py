#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
#We have to import [pywintypes] to activate the DLL required by [win32api]
#It is weird but works!
#Quote: (#12) https://stackoverflow.com/questions/3956178/cant-load-pywin32-library-win32gui
import pywintypes
import win32api, win32con
import time

def clicks(
    *pos
    ,offset = (0,0)
    ,interval = 1
) -> 'Simulate the mouse clicks on various positions on the computer screen, with offset when necessary':
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to simulate the mouse clicks on computer screen, with certain offset, i.e. top-left of a specific window #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[REFERENCE]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   | https://www.programcreek.com/python/example/104592/win32api.mouse_event                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |pos         :   Various positions provided as [Iterable] with each set as a [tuple(x,y)], i.e. [(1,1),(500,500)]                   #
#   |offset      :   Offset all positions from this provided coordinate, which is provided a tuple (x,y)                                #
#   |                 [(0,0)       ] <Default> Do not offset, but set all positions as the absolute coordinates of current screen       #
#   |                 [<tuple>     ]           Offset from this coordinate                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<None>      :   This function does not return any value, but only controls the mouse to click on the OS screen                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20211110        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, pywintypes, win32api, win32con, time                                                                                      #
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
    chkpos = all([ isinstance(p, tuple) for p in pos ])
    if not chkpos:
        raise TypeError('[' + LfuncName + ']All input coordinates must be [tuple]!')
    chkoffset = isinstance(offset, tuple)
    if not chkoffset:
        raise TypeError('[' + LfuncName + '][offset] must be [tuple]!')

    #050. Local parameters
    pos_int = [ tuple(map(sum, zip(offset, p))) for p in pos ]

    #500. Loop to click each coordinate with certain interval
    for p in pos_int:
        #100. Sleep by interval
        time.sleep(interval)

        #300. Move mouse to current position
        win32api.SetCursorPos(p)

        #500. Set the left button down
        win32api.mouse_event(win32con.MOUSEEVENTF_LEFTDOWN,*p,0,0)

        #700. Sleep for a short period of time for the system to recognize
        time.sleep(0.01)

        #900. Release the left button to simulate the end of a click
        win32api.mouse_event(win32con.MOUSEEVENTF_LEFTUP,*p,0,0)
#End clicks

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )

    from omniPy.RPA import clicks
    print(clicks.__doc__)

    #100. Click (200,300) and (400,600) on the screen
    clicks((200,300),(400,600))
#-Notes- -End-
'''
