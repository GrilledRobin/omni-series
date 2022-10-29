#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
from functools import reduce

def rgetattr(
    obj
    ,attr : str
    ,*default
    ,args : dict = {}
    ,sep : str = '.'
) -> 'Get the attribute of object in recursion':
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to get the attribute of the object in recursion, in case the provided attributes are nested; when any    #
#   | nested attribute is a [callable], also enable the requestor to provide arguments for it to call                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Provide a nested string of attributes for the object and try to obtain the value for the deepest attribute                     #
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
#   |default    :   [Optional] positional argument, in place of the default value in case the dedicated attribute is not obtainable     #
#   |               IMPORTANT: It represents the same argument in the native function [getattr()]                                       #
#   |args       :   A nested dict for any [callable] sub-attribute to call, see examples for the usage                                  #
#   |               [<see def.> ] <Default> Do not have to call any sub-attribute                                                       #
#   |               [dict       ]           In the form: {subattr1:{'pos':tuple(),'kw':dict()},...}                                     #
#   |                                       [<subattr1-n>] Any attribute name scanned by [sep] from within [attr]. (updated) Since some #
#   |                                                       attribute names may exist in the nested search, e.g. [aa.bb.cc.bb.dd], we   #
#   |                                                       should use their respective full names to identify the correct call, i.e.   #
#   |                                                       for above case [aa.bb] and [aa.bb.cc.bb] should be provided respectively    #
#   |                                                       for the correct call to them.                                               #
#   |                                       [pos         ] Positional arguments to current [callable], can be 0-tuple or None           #
#   |                                       [kw          ] Keyword arguments to current [callable], can be 0-dict or None               #
#   |sep        :   Separator to scan for sub-attributes from within [attr]                                                             #
#   |               [<see def.> ] <Default> See function definition                                                                     #
#   |               [<str>      ]           Single character to be used for separation                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<obj>      :   Value of the leaf attribute as obtained, or [default] if it is provided while the leaf attribute is unobtainable    #
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
#   |   |sys, functools                                                                                                                 #
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

    #050. Local parameters
    attrs = attr.split(sep)
    attrs_cum = [ sep.join(attrs[:(i+1)]) for i in range(len(attrs)) ]

    #100. Helper functions
    #110. Get attribute and call it when applicable
    def _getattr(obj, attr):
        #300. Identify whether it should be called during nesting
        f_call = args.get(attr, None) is not None
        prev, _, curr = attr.rpartition(sep)

        #500. Obtain current sub-attribute
        obj_curr = getattr(obj, curr)

        #700. Call it when applicable
        if callable(obj_curr) and f_call:
            #100. Obtain the possible arguments for current sub-attribute
            args_curr = args.get(attr, {})

            #900. Call with possible arguments
            obj_curr = obj_curr(*args_curr.get('pos', tuple()), **args_curr.get('kw', dict()))

        #900. Return the new object
        return(obj_curr)

    #900. Try to obtain the attribute and raise if otherwise
    try:
        return reduce(_getattr, attrs_cum, obj)
    except AttributeError:
        if default:
            return default[0]
        raise
#End rgetattr

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import os
    import sys
    import datetime as dt
    import xlwings as xw
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import rgetattr

    #100. Obtain the function [strptime] via the provided string
    usf = rgetattr(dt, 'datetime.strptime')

    #200. Obtain the font name from a cell in an EXCEL file
    xlfile = os.path.join(dir_omniPy, 'omniPy', 'FileSystem', 'CSIDL_values.xlsx')
    with xw.App( visible = False, add_book = False ) as xlapp:
        #010. Set options
        xlapp.display_alerts = False
        xlapp.screen_updating = False

        #100. Open the EXCEL workbook
        xlwb = xlapp.books.open(xlfile)

        #300. Define the sheet
        xlsh = xlwb.sheets[0]

        #400. Define the range
        xlrng = xlsh.range('A1')

        #500. Obtain its font name
        font_name = rgetattr(xlrng, 'api.Font.Name')

        #600. Obtain its top border line style
        #[ASSUMPTION]
        #[1] 'Borders' attribute is a callable, for which we should provide the BorderIndex as identification
        #[2] Usually we get the attribute by: xlrng.api.Borders(xw.constants.BordersIndex.xlEdgeTop).LineStyle
        #[3] Here we pass strings for its retrieval, which provides parametric functionality
        btm_bd_style = rgetattr(
            xlrng
            ,'api.Borders.LineStyle'
            ,args = {
                'api.Borders' : {
                    'pos' : (xw.constants.BordersIndex.xlEdgeTop,)
                }
            }
        )

        #999. Purge
        xlwb.close()
        xlapp.screen_updating = True

    print(font_name)
    print(btm_bd_style)
#-Notes- -End-
'''
