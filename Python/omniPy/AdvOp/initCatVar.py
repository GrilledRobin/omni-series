#!/usr/bin/env python3
# -*- coding: utf-8 -*-

def initCatVar(
    inDAT
    ,inplace : bool = False
    ,UniVal : str = ''
) -> 'Initialize all categorical variables in a DataFrame with the same NULL string':
    #000.   Info.
    """
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to replace the abnormal values of all categorical variables in the given DataFrame with a blank string.  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inDAT      :   The input pd.DataFrame within which to initialize the variables.                                                    #
#   |inplace    :   Boolean value that indicates whether to replace the input DataFrame with the output.                                #
#   |               [False]: Return a new pd.DataFrame object                                                                           #
#   |               [True] : Overwrite the input DataFrame                                                                              #
#   |               DEFAULT : [False]                                                                                                   #
#   |UniVal     :   The unified value at initialization. Only accepts a single value for all variables if any.                          #
#   |               DEFAULT : ['']                                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values as alternative output.                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[OutD]     :   [pd.DataFrame]The new pd.DataFrame within which the NULL values have been replaced by the provided one              #
#   |[inDAT]    :   [pd.DataFrame]The input DataFrame as replaced in terms of the indication at [inplace]                               #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20190331        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
    import numpy as np
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

    #100.   Retrieve the names of all categorical variables.
    cols : list = selCatVar( inDAT )

    #110.   Count the variables as found.
    ncol : int = len( cols )

    #200.   Create a list of values to be replaced during the initialization.
    reps : list = [ 'NaN' , None , np.nan , np.inf , -np.inf ]

    #500.    Value initialization.
    if ncol != 0:
        vals : dict = dict( zip( cols , [ { reps[i] : UniVal for i in range(len(reps)) } for j in range(ncol) ] ) )
        OutD : pd.DataFrame = inDAT.replace( vals , inplace = inplace )

    #800.   Purge the memory usage.
    LfuncName , __Err = None , None
    cols , ncol , vals = None , None , None

    #900.   Output.
    if inplace or ncol == 0:
        OutD = None
        return( inDAT )
    else:
        return( OutD )
#End initCatVar

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
    testBlank : pd.DataFrame = pd.DataFrame( { 'Num':[ np.nan , 1 ] , 'Char':[ 'aa' , np.nan ] } )

    #200.   Create a new dataset with the categorical fields initialized as blank string.
    testBlank_new = initCatVar( testBlank )

    #300.   Overwrite the input dataset with the numeric values initialized as 0.
    initCatVar( testBlank , inplace = True )
#-Notes- -End-
"""