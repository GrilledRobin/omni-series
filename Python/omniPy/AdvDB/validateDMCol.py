#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import pandas as pd
from typing import Any
from collections.abc import Iterable

def validateDMCol(col : Any) -> list[Any]:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to validate the column names for Data Management process                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Scenarios]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] <pd.MultiIndex> is NOT recommended to be used as column names, see the assumptions in the program for explanation              #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |col         :   Column names for validation                                                                                        #
#   |               [<hashable>      ]           Hashable objects that can be set as values of <pd.Index>                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Any]       :   List of hashable objects                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20240209        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, pandas, typing, collections                                                                                               #
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

    #500. Validation
    #[ASSUMPTION]
    #[1] Column name, i.e. pd.Index, can be object of almost any type
    #[2] n-tuple is the representation of pd.MultiIndex
    #[3] We will hence not validate <aggrVar> and leave it to pandas
    #[4] However, we have to append the special name as KPI ID during the process, hence we have to validate <byVar>
    #[5] We will not validate the similar variables that are used in the call to other processes, and leave the validation to them
    #[6] It is strongly NOT recommended to use <pd.MultiIndex> during data management, as this brings unexpected results, such as:
    #    [1] Nested structures in column names
    #    [2] String case unification problems
    #    [3] n-tuple with hashable objects may not form a <pd.MultiIndex>, causing uncertainty during validation
    if isinstance(col, tuple):
        rstOut = [col]
    elif isinstance(col, (pd.Series, pd.Index)):
        rstOut = col.to_list()
    elif isinstance(col, Iterable) and (not isinstance(col, str)):
        rstOut = list(col)
    elif col is None:
        rstOut = []
    else:
        rstOut = [col]
    if any([ isinstance(v, tuple) for v in rstOut ]):
        raise ValueError(f'[{LfuncName}][col] should not be a tuple for data management due to ambiguity!')

    return(rstOut)
#End validateDMCol

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010. Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvDB import validateDMCol

    #100. Validate normal collumn names
    col_single = 'aaa'
    vld_single = validateDMCol(col_single)
    # ['aaa']

    col_list = ['aaa','bbb']
    vld_list = validateDMCol(col_list)
    # ['aaa', 'bbb']

    col_mix = [12, 'ccc']
    vld_mix = validateDMCol(col_mix)
    # [12, 'ccc']

    #900. Invalid columns
    col_tuple = (1,'a')
    vld_tuple = validateDMCol(col_tuple)
    # ValueError: [validateDMCol][col] should not be a tuple for data management due to ambiguity!
#-Notes- -End-
'''
