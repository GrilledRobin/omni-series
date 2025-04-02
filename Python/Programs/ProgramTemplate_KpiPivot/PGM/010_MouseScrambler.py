#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This is to demonstrate how to stop the screen saver from locking current Windows User by moving the mouse to pretend that the user #
#   | is operating Windows                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Some RPA process requires taking over the control of mouse and keyboard, but when Windows is locked and showing screen saver,  #
#   |     such process would fail to operate on the correct modules                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20250402        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#

print('Determine whether to run all subsequent scripts')
#We have to import [pywintypes] to activate the DLL required by [pywin32]
#It is weird but works!
#Quote: (#12) https://stackoverflow.com/questions/3956178/cant-load-pywin32-library-win32gui
import pywintypes
import win32api, win32con, win32gui
import time
import datetime as dt
import numpy as np
from ctypes import windll, Structure, c_long, byref
from omniPy.Dates import asDatetimes, intck, intnx

#010. Local environment
move_choices = [-1,1]
dt_interval = 60.0

print('100. Helper functions')
#110. Function to obtain position of the mouse on screen
class PosScreen(Structure):
    _fields_ = [('x', c_long), ('y', c_long)]

def getMousePos():
    pos = PosScreen()
    windll.user32.GetCursorPos(byref(pos))
    return({'x' : pos.x, 'y' : pos.y})

#150. Function to move the mouse
def mouseScrambler():
    #100. Get current cursor position
    pos = getMousePos()

    #500. Calculate the new position
    #[ASSUMPTION]
    #[1] If the cursor is at the edge of the screen, we should avoid setting its new position on the same point,
    #     otherwise the cursor may stop for an iteration which fails to block the screen saver
    x_shift, y_shift = np.random.choice(move_choices, 2)
    if pos['x'] == 0:
        x_shift = 1
    elif pos['x'] == SCREEN_WIDTH:
        x_shift = -1

    if pos['y'] == 0:
        y_shift = 1
    elif pos['y'] == SCREEN_HEIGHT:
        y_shift = -1

    x_new, y_new = pos['x'] + x_shift, pos['y'] + y_shift

    #900. Move the cursor
    win32api.mouse_event(
        win32con.MOUSEEVENTF_MOVE | win32con.MOUSEEVENTF_ABSOLUTE
        ,int(x_new/SCREEN_WIDTH*65535.0)
        ,int(y_new/SCREEN_HEIGHT*65535.0)
    )

print('300. Get current screen size')
SCREEN_WIDTH = windll.user32.GetSystemMetrics(0)
SCREEN_HEIGHT = windll.user32.GetSystemMetrics(1)

print('700. Determine the period for loop')
dt_bgn = dt.datetime.now()
dt_end = asDatetimes(
    intnx('day', dt_bgn, 90, daytype = 'c').strftime('%Y%m%d') + '183000'
    ,fmt = '%Y%m%d%H%M%S'
)
k_clicks = int(intck(f'dtsecond{int(dt_interval)}', dt_bgn, dt_end, daytype = 'c'))

#900. Declare the beginning
print('<Timer Start> ' + dt_bgn.strftime('%Y-%m-%d %H:%M:%S'))
print('<Timer End  > ' + dt_end.strftime('%Y-%m-%d %H:%M:%S'))
print('Begin to scramble mouse position on screen...')
for i in range(k_clicks):
    mouseScrambler()
    time.sleep(dt_interval)
