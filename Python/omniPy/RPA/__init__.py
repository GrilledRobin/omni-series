#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#001.   Import necessary functions for processing.

#print( 'Importing [' + os.path.dirname( os.path.abspath(__file__) ) + ']' )

#100.   Import the local modules.
from .isWindowCloaked import isWindowCloaked
from .getDesktopWindows import getDesktopWindows
from .setClipboard import setClipboard
from .clicks import clicks

#200.   Define available resources.
__all__ = [
    'isWindowCloaked'
    ,'getDesktopWindows'
    ,'setClipboard'
    ,'clicks'
]