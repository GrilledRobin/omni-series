#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#001.   Import necessary functions for processing.

#print( 'Importing [' + os.path.dirname( os.path.abspath(__file__) ) + ']' )

#100.   Import the local modules.
from .getMemberByStrPattern import getMemberByStrPattern
from .MSExcelSaveAs import MSExcelSaveAs
from .getMSDNKnownFolderIDDoc import getMSDNKnownFolderIDDoc
from .winKnownFolders import winKnownFolders
from .winUserShellFolders import winUserShellFolders

#200.   Define available resources.
__all__ = [
    'getMemberByStrPattern'
    ,'MSExcelSaveAs'
    ,'getMSDNKnownFolderIDDoc'
    ,'winKnownFolders'
    ,'winUserShellFolders'
]