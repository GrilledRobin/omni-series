#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#001.   Import necessary functions for processing.

#print( 'Importing [' + os.path.dirname( os.path.abspath(__file__) ) + ']' )

#100.   Import the local modules.
from .isWindowCloaked import isWindowCloaked
from .getDesktopWindows import getDesktopWindows
from .setForegroundWindow import setForegroundWindow
from .setClipboard import setClipboard
from .clicks import clicks
from .controlIME import controlIME

#200.   Define available resources.
__all__ = [
    'isWindowCloaked'
    ,'getDesktopWindows'
    ,'setForegroundWindow'
    ,'setClipboard'
    ,'clicks'
    ,'controlIME'
]
