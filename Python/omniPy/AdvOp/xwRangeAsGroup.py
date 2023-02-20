#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import numpy as np
#We have to import [pywintypes] to activate the DLL required by [win32api] for [xlwings < 0.27.15] and [Python <= 3.7]
#It is weird but works!
#Quote: (#12) https://stackoverflow.com/questions/3956178/cant-load-pywin32-library-win32gui
import pywintypes
import xlwings as xw
from typing import Union, Optional
from collections.abc import Iterable
from xlwings.constants import Constants as xlc

def xwRangeAsGroup(
    rng : xw.Range
    ,method : Union[str, dict, Iterable] = 'Group'
    ,axis : Optional[int] = None
    ,posOutline : Union[str, dict, Iterable] = 'before'
    ,autoStyles : bool = False
) -> None:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to add group and outline on either/both axes of the given [xw.Range]                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Add groups to the details of a pivot-table-like range in MS EXCEL                                                              #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |rng         :   EXCEL range object, in which to pour the data                                                                      #
#   |method      :   Whether to group or ungroup current range, case sensitive                                                          #
#   |                [IMPORTANT   ] [Group()] method automatically chooses the proper level according to the [Range] size; [Ungroup()]  #
#   |                                method removes the smallest group one at a time, which indicates one has to call this method for   #
#   |                                enough times to remove all groups on the same [axis] of the same [Range]                           #
#   |                [Group       ] <Default> Add group for current range                                                               #
#   |                [Ungroup     ]           Remove group for current range                                                            #
#   |                [<dict>      ]           Dict-like, indicating on which [axis] to call the method                                  #
#   |                [<Iterable>  ]           2-item Iterable indicating the method for [axis-0,axis-1] respectively                    #
#   |axis        :   Axis along which to add the group and outline                                                                      #
#   |                [None        ] <Default> Add group along both axes                                                                 #
#   |                [0           ]           Add group along axis-0, i.e. rows                                                         #
#   |                [1           ]           Add group along axis-1, i.e. columns                                                      #
#   |posOutline  :   Position of the outline                                                                                            #
#   |                [IMPORTANT   ] If multiple times of [posOutline] are set for the same [axis] in the same [Sheet], only the last    #
#   |                                one takes effect                                                                                   #
#   |                [before      ] <Default> Display the outline above the range and/or left to it, as determined by [axis]            #
#   |                [after       ]           Display the outline below the range and/or right to it, as determined by [axis]           #
#   |                [<dict>      ]           Dict-like, indicating on which [axis] to display the outline(s)                           #
#   |                [<Iterable>  ]           2-item Iterable indicating the outline positions on [axis-0,axis-1] respectively          #
#   |autoStyles  :   Logical value indicating whether to allow automatic styles                                                         #
#   |                [False       ] <Default> Default settings for MS EXCEL                                                             #
#   |                [True        ]           See official documents for MS VBA [Sheet.Outline.AutomaticStyles]                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<None>      :   This function does not have return value                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20230218        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, numpy, xlwings, collections, typing                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Parameter buffer
    opt_method = ['Group','Ungroup']
    if method not in opt_method:
        raise ValueError('[{0}][method]:[{1}] must be among [{2}]!'.format(
            LfuncName
            ,str(method)
            ,','.join(map(str, opt_method))
        ))
    key_axis = { 0 : 'row', 1 : 'column' }
    opt_axis = [None] + list(key_axis.keys())
    if axis not in opt_axis:
        raise ValueError('[{0}][axis]:[{1}] must be among [{2}]!'.format(
            LfuncName
            ,str(axis)
            ,','.join(map(str, opt_axis))
        ))
    if not isinstance(autoStyles, (bool, np.bool_)):
        raise TypeError('[{0}][autoStyles]:[{1}] must be boolean!'.format(LfuncName, type(autoStyles)))

    #050. Local parameters
    rng_Sheet = rng.sheet
    rowGroup = axis in [None,0]
    colGroup = axis in [None,1]
    opt_method = ['Group','Ungroup']
    if isinstance(method, str):
        methodRow = method
        methodCol = method
    elif isinstance(method, dict):
        methodRow = method.get(0) if rowGroup else None
        methodCol = method.get(1) if colGroup else None
    elif isinstance(method, Iterable):
        if len(method) != 2:
            raise ValueError('[{0}][method]:[{1}] must be Iterable with exact 2 items!'.format(LfuncName, len(method)))
        methodRow = method[0]
        methodCol = method[-1]
    else:
        raise TypeError('[{0}][method]:[{1}] is not recognized!'.format(LfuncName, type(method)))
    if rowGroup and (methodRow not in opt_method):
        raise ValueError('[{0}][method]:[{1}] must be among [{2}]!'.format(
            LfuncName
            ,str(method)
            ,','.join(map(str, opt_method))
        ))
    if colGroup and (methodCol not in opt_method):
        raise ValueError('[{0}][method]:[{1}] must be among [{2}]!'.format(
            LfuncName
            ,str(method)
            ,','.join(map(str, opt_method))
        ))
    opt_pos = ['before','after']
    if isinstance(posOutline, str):
        poRow = posOutline
        poCol = posOutline
    elif isinstance(posOutline, dict):
        poRow = posOutline.get(0) if rowGroup else None
        poCol = posOutline.get(1) if colGroup else None
    elif isinstance(posOutline, Iterable):
        if len(posOutline) != 2:
            raise ValueError('[{0}][posOutline]:[{1}] must be Iterable with exact 2 items!'.format(LfuncName, len(posOutline)))
        poRow = posOutline[0]
        poCol = posOutline[-1]
    else:
        raise TypeError('[{0}][posOutline]:[{1}] is not recognized!'.format(LfuncName, type(posOutline)))
    if rowGroup and (poRow not in opt_pos):
        raise ValueError('[{0}][posOutline]:[{1}] must be among [{2}]!'.format(
            LfuncName
            ,str(posOutline)
            ,','.join(map(str, opt_pos))
        ))
    if colGroup and (poCol not in opt_pos):
        raise ValueError('[{0}][posOutline]:[{1}] must be among [{2}]!'.format(
            LfuncName
            ,str(posOutline)
            ,','.join(map(str, opt_pos))
        ))

    #300. Group by axis-0
    if rowGroup:
        #100. Retrieve the entire rows extended from current range
        #Quote: https://learn.microsoft.com/en-us/office/vba/api/excel.range.entirerow
        #[ASSUMPTION]
        #[1] Below object is a wrapper instead of a [Range] object
        rngToGroup = rng.api.EntireRow

        #300. Determine the outline position
        if poRow == 'before':
            sumDir = xlc.xlAbove
        else:
            sumDir = xlc.xlBelow

        #500. Add group
        #[ASSUMPTION]
        #[1] [Group()] is a method instead of a property
        #Quote: https://github.com/xlwings/xlwings/issues/2112
        if methodRow == 'Group':
            rngToGroup.Rows.Group()
        else:
            rngToGroup.Rows.Ungroup()

        #700. Set the outline position
        rng_Sheet.api.Outline.SummaryRow = sumDir

    #400. Group by axis-1
    if colGroup:
        #100. Retrieve the entire columns extended from current range
        rngToGroup = rng.api.EntireColumn

        #300. Determine the outline position
        if poCol == 'before':
            sumDir = xlc.xlLeft
        else:
            sumDir = xlc.xlRight

        #500. Add group
        if methodCol == 'Group':
            rngToGroup.Columns.Group()
        else:
            rngToGroup.Columns.Ungroup()

        #700. Set the outline direction
        rng_Sheet.api.Outline.SummaryColumn = sumDir

    #700. Set automatic styles
    rng_Sheet.api.Outline.AutomaticStyles = autoStyles
#End xwRangeAsGroup

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import os
    import sys
    import numpy as np
    import pandas as pd
    #We have to import [pywintypes] to activate the DLL required by [win32api] for [xlwings <= 0.27.15] and [Python <= 3.8]
    #It is weird but works!
    #Quote: (#12) https://stackoverflow.com/questions/3956178/cant-load-pywin32-library-win32gui
    import pywintypes
    import xlwings as xw
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import xwRangeAsGroup

    #300. Set the groups and outlines
    xlfile = os.path.join(dir_omniPy, 'omniPy', 'AdvOp', 'testGroup.xlsx')
    if os.path.isfile(xlfile): os.remove(xlfile)
    with xw.App( visible = False, add_book = True ) as xlapp:
        #010. Set options
        xlapp.display_alerts = False
        xlapp.screen_updating = False

        #100. Identify the EXCEL workbook
        xlwb = xlapp.books[0]

        #400. Settings for sheet 1
        #410. Define the sheet
        xlsh = xlwb.sheets[0]

        #430. Define the range
        xlrng = xlsh.range('B2:D4')

        #450. Set group on both axes
        xwRangeAsGroup(xlrng)

        #470. Add a new range
        xlrng2 = xlsh.range('B2:F6')

        #490. Set groups on top of the previous ones
        xwRangeAsGroup(
            xlrng2
            ,posOutline = { 0 : 'after', 1 : 'before' }
        )

        #500. Settings for sheet 2
        #510. Define the sheet
        xlsh = xlwb.sheets.add('sheet 2')

        #530. Define the range
        xlrng = xlsh.range('C3:G5')

        #550. Set group on axis-1
        xwRangeAsGroup(
            xlrng
            ,axis = 1
            ,posOutline = 'before'
        )

        #570. Add a new range
        #[ASSUMPTION]
        #[1] This [Range] is smaller than the previous one
        #[2] Even if this grouper is set after the previous one, it is still created below that one
        xlrng2 = xlsh.range('C3:E4')

        #590. Set group on axis-1 on top of the previous one
        #[ASSUMPTION]
        #[1] This [posOutline] overwrites the one in all the previous calls for the same [Sheet]
        xwRangeAsGroup(
            xlrng2
            ,axis = 1
            ,posOutline = 'after'
        )

        #595. Remove group on axis-1 for once
        #[ASSUMPTION]
        #[1] This [posOutline] overwrites the one in all the previous calls for the same [Sheet]
        #[2] [Ungroup()] method removes the smallest group one at a time,
        #     hence you have to call it enough times to remove all levels of groups on the same [Range]
        xwRangeAsGroup(
            xlsh.range('D3:D4')
            ,method = 'Ungroup'
            ,axis = 1
            ,posOutline = 'after'
        )

        #999. Purge
        xlwb.save(xlfile)
        xlwb.close()
        xlapp.screen_updating = True

    if os.path.isfile(xlfile): os.remove(xlfile)
#-Notes- -End-
'''
