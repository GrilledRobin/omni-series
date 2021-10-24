#!/usr/bin/env python3
# -*- coding: utf-8 -*-

def selNumVar( inDAT ) -> 'Select all numeric field names from the provided dataset and create a list of them':
    #000.   Info.
    """
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to create a list of all Numeric Field Names, searching from the provided dataset.                        #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inDAT      :   The input pd.DataFrame within which to initialize the variables.                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[varlist]  :   [list]The list of selected field names                                                                              #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20190401        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |sys, pandas                                                                                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
    """

    #001.   Import necessary functions for processing.
    #from imp import find_module
    import pandas as pd
    import sys

    #010.   Check parameters.
    #011.   Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name
    __Err : str = "ERROR: [" + LfuncName + "]Process failed due to errors!"

    #012.   Handle the parameter buffer.
    if not isinstance( inDAT , pd.DataFrame ):
        raise TypeError( '[' + LfuncName +  ']Parameter [inDAT] should be of the type [pd.DataFrame]! Type of input value is [{0}]'.format( type(inDAT) ) )

    #013.   Define the local environment.

    #100.   Retrieve the names of all numeric variables.
    #See official document: http://pandas.pydata.org/pandas-docs/stable/reference/api/pandas.DataFrame.select_dtypes.html#pandas.DataFrame.select_dtypes
    varlist : list = inDAT.select_dtypes( include = [ 'number' ] ).columns.tolist()

    #800.   Purge the memory usage.
    LfuncName , __Err = None , None

    #900.   Output.
    return( varlist )
#End selNumVar

"""
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=="__main__":
    #010.   Create envionment.
    import pandas as pd
    import numpy as np
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.AdvOp import *

    #100.   Create the testing dataset.
    testNaN : pd.DataFrame = pd.DataFrame( { 'Num':[ np.nan , 1 ] , 'Char':[ 'aa' , 'bb' ] } )

    #200.   Retrieve the list of Categorical Field Names.
    numvar : list = selNumVar( testNaN )
#-Notes- -End-
"""