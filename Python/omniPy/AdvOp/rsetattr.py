#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
from omniPy.AdvOp import rgetattr

def rsetattr(
    obj
    ,attr : str
    ,val
    ,*default
    ,args : dict = {}
    ,sep : str = '.'
) -> 'Set the leaf attribute of object in recursion':
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to set the leaf attribute of the object in recursion, in case the provided attributes are nested; when   #
#   | nested attribute is a [callable], also enable the requestor to provide arguments for it to call                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Provide a nested string of attributes for the object and try to set the value for the deepest attribute                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Quote:                                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] https://stackoverflow.com/questions/31174295/getattr-and-setattr-on-nested-subobjects-chained-properties                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |obj        :   Any object to obtain the attributes                                                                                 #
#   |attr       :   (Possibly nested) attributes to retrieve                                                                            #
#   |               IMPORTANT: When any sub-attributes are [callable], for instance [aaa.bbb(arg).ccc] is to be obtained, DO NOT        #
#   |                           provide the call, but provide [aaa.bbb.ccc] instead; the function handles such case via [args]          #
#   |val        :   Any object to assign to the attribute                                                                               #
#   |default    :   [Optional] positional argument, in place of the default value in case the dedicated attribute is not obtainable     #
#   |               IMPORTANT: It represents the same argument in the native function [getattr()]                                       #
#   |args       :   A nested dict for any [callable] sub-attribute to call, see examples for the usage                                  #
#   |               [<see def.> ] <Default> Do not have to call any sub-attribute                                                       #
#   |               [dict       ]           See arguments for function [omniPy.AdvOp.rgetattr]                                          #
#   |sep        :   Separator to scan for sub-attributes from within [attr]                                                             #
#   |               [<see def.> ] <Default> See function definition                                                                     #
#   |               [<str>      ]           Single character to be used for separation                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<obj>      :   Return code from the [setattr] process                                                                              #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20221027        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys                                                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |rgetattr                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Parameter buffer

    #050. Local parameters
    pre, _, post = attr.rpartition(sep)

    #900. Set the attribute
    return setattr(rgetattr(obj, pre, *default, args = args, sep = sep) if pre else obj, post, val)
#End rsetattr

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import os
    import sys
    import datetime as dt
    #We have to import [pywintypes] to activate the DLL required by [win32api] for [xlwings <= 0.27.15] and [Python <= 3.8]
    #It is weird but works!
    #Quote: (#12) https://stackoverflow.com/questions/3956178/cant-load-pywin32-library-win32gui
    import pywintypes
    import xlwings as xw
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import rsetattr

    #200. Set the font name from a cell in an EXCEL file
    xlfile = os.path.join(dir_omniPy, 'omniPy', 'AdvOp', 'test.xlsx')
    if os.path.isfile(xlfile): os.remove(xlfile)
    with xw.App( visible = False, add_book = True ) as xlapp:
        #010. Set options
        xlapp.display_alerts = False
        xlapp.screen_updating = False

        #100. Identify the EXCEL workbook
        xlwb = xlapp.books[0]

        #300. Define the sheet
        xlsh = xlwb.sheets[0]

        #400. Define the range
        xlrng = xlsh.range('B2:C4')

        #500. Set its font name
        rsetattr(xlrng, 'api.Font.Name', 'Segoe UI')

        #600. Set its top border line style
        #[ASSUMPTION]
        #[1] 'Borders' attribute is a callable, for which we should provide the BorderIndex as identification
        #[2] Usually we set the attribute by: xlrng.api.Borders(xw.constants.BordersIndex.xlEdgeTop).LineStyle
        #[3] Here we pass strings for its retrieval, which provides parametric functionality
        rsetattr(
            xlrng
            ,'api.Borders.LineStyle'
            ,xw.constants.LineStyle.xlSlantDashDot
            ,args = {
                'api.Borders' : {
                    'pos' : (xw.constants.BordersIndex.xlEdgeTop,)
                }
            }
        )

        #999. Purge
        xlwb.save(xlfile)
        xlwb.close()
        xlapp.screen_updating = True

    if os.path.isfile(xlfile): os.remove(xlfile)

#-Notes- -End-
'''
