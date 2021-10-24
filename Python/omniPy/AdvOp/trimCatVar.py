#!/usr/bin/env python3
# -*- coding: utf-8 -*-

def trimCatVar( inDAT , inplace : bool = True ) -> 'Remove the leading and trailing blanks from all records in all Categorical Variables':
    #000.   Info.
    """
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to remove the leading and trailing blanks from all records in all Categorical Variables in the provided  #
#   | dataframe.                                                                                                                        #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inDAT      :   The input pd.DataFrame for the calculation.                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values.                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[OutD]     :   [pd.DataFrame]The new pd.DataFrame as a mirror of the input one, with all categorical fields trimmed                #
#   |[inDAT]    :   [pd.DataFrame]The same dataset as replaced by this function                                                         #
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
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |omniPy.AdvOp                                                                                                               #
#   |   |   |   |selCatVar                                                                                                              #
#---------------------------------------------------------------------------------------------------------------------------------------#
    """

    #001.   Import necessary functions for processing.
    #from imp import find_module
    import pandas as pd
    import sys
    from omniPy.AdvOp import selCatVar

    #010.   Check parameters.
    #011.   Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name
    __Err : str = "ERROR: [" + LfuncName + "]Process failed due to errors!"

    #012.   Handle the parameter buffer.
    if not isinstance( inDAT , pd.DataFrame ):
        raise TypeError( '[' + LfuncName +  ']Parameter [inDAT] should be of the type [pd.DataFrame]! Type of input value is [{0}]'.format( type(inDAT) ) )

    #013.   Define the local environment.

    #090.   Create a copy of the input data.
    OutD : pd.DataFrame = inDAT.copy()

    #100.   Retrieve all categorical fields.
    cols : list = selCatVar( inDAT )

    #110.   Count the variables as found.
    ncol : int = len( cols )

    #500.   Trim the values.
    if ncol != 0:
        for col in cols:
            OutD[col] = OutD[col].str.strip()

    #700.   Decide whether to overwrite the input data.
    if inplace and cols:
        inDAT.update( OutD )

    #800.   Purge the memory usage.
    LfuncName , __Err = None , None
    cols , ncol = None , None

    #900.   Output.
    if inplace:
        OutD = None
        return( inDAT )
    else:
        return( OutD )
#End trimCatVar

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
    testtrim : pd.DataFrame = pd.DataFrame( { 'Num':[ np.nan , 1 ] , 'Char':[ ' aa' , 'bb  ' ] } )

    #200.   Encode the categorical fields while leave the input data not affected.
    dataTrim = trimCatVar( testtrim , inplace = False )

    #300.   Encode the categorical fields by replacing the original dataset.
    trimCatVar( testtrim )
#-Notes- -End-
"""

"""
#-Explanation- -Begin-
#-Explanation- -End-
"""