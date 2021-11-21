#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#We have to import [pywintypes] to activate the DLL required by [pywin32]
#It is weird but works!
#Quote: (#12) https://stackoverflow.com/questions/3956178/cant-load-pywin32-library-win32gui
import pywintypes
import win32api, win32con
import time
import datetime as dt
from omniPy.Dates import asTimes, intck

logger.info('Starting to scramble mouse positions on screen...')

#100. Set the bounds of the period of screen scrambling
#[1] We start to move mouse on creen, each 5 minutes, to avoid screen lock
#[2] We set 5 o'clock of the Next Workday as the beginning of the following steps
dt_bgn = dt.datetime.now()
t_end = asTimes('05:00:00')
dt_end = dt.datetime.combine( G_obsDates.nextWorkDay[0], t_end )

logger.info('<Timer Begin> ' + dt_bgn.strftime('%Y-%m-%d %H:%M:%S'))
logger.info('<Timer End  > ' + dt_end.strftime('%Y-%m-%d %H:%M:%S'))

#300. Define the number of moves to conduct during this period
#[1] Assume the screen is locked every 10 minutes
#[2] We set the interval as 5 minutes, or 300 seconds
#[3] The default interval calculation in [intck] is by [Calendar Days], which is just what we need
click_interval = 300
k_clicks = intck('dtsecond' + str(click_interval), dt_bgn, dt_end)

#500. Set the attributes of current screen
#[1] We only need two positions on the screen between which to move the mouse
SCREEN_WIDTH = 1920
SCREEN_HEIGHT = 1080
x = [320, 640]
y = [240, 480]
#Indexer to slice the axes of positions
i_init = { True : 0, False : -1 }
#We negate the cypher during the iterations, in order to switch the indexers
cypher = True

#700. Timer to prevent the screen from being locked
for i in range(k_clicks):
    #001. Sleep for the dedicated period of time
    time.sleep(click_interval)

    #100. Negate the cypher
    cypher = not cypher

    #500. Retrieve the new coordinates on the screen
    x_new, y_new = x[i_init[cypher]], y[i_init[cypher]]

    #800. Move the mouse to the new position
    #Quote [#352]: https://stackoverflow.com/questions/1181464/controlling-mouse-with-python
    win32api.mouse_event(
        win32con.MOUSEEVENTF_MOVE | win32con.MOUSEEVENTF_ABSOLUTE
        , int(x_new/SCREEN_WIDTH*65535.0)
        , int(y_new/SCREEN_HEIGHT*65535.0)
    )
