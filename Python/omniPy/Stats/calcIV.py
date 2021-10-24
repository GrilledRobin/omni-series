#!/usr/bin/env python3
# -*- coding: utf-8 -*-

def calcIV( inDAT , dependent , response , event = 1 ) -> 'Calculate the Information Value for [response] variable in the dataset':
    #000.   Info.
    """
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to calculate the Information Value for the variable [response] in terms of [dependent] variable in the   #
#   | provided pd.DataFrame.                                                                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inDAT      :   The input pd.DataFrame for the calculation.                                                                         #
#   |dependent  :   The dependent variable in the procided dataset                                                                      #
#   |response   :   The independent variable, or the response variable, in the procided dataset                                         #
#   |event      :   The value that represents the Event                                                                                 #
#   |               DEFAULT : [1]                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values.                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[outRST]   :   [float64]The Information Value calculation result                                                                   #
#   |[dataWoE]  :   [pd.DataFrame]The dataset as calculation of WoE for validation                                                      #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20190330        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |omniPy.Stats                                                                                                                   #
#   |   |   |calcWoE                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
    """

    #001.   Import necessary functions for processing.
    #from imp import find_module
    import pandas as pd
    import sys
    from omniPy.Stats import calcWoE

    #010.   Check parameters.
    #011.   Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name
    __Err : str = "ERROR: [" + LfuncName + "]Process failed due to errors!"

    #012.   Handle the parameter buffer.
    if not isinstance( inDAT , pd.DataFrame ):
        raise TypeError( '[' + LfuncName +  ']Parameter [inDAT] should be of the type [pd.DataFrame]! Type of input value is [{0}]'.format( type(inDAT) ) )

    #013.   Define the local environment.

    #100.   Calculate the WoE to [response] for [dependent].
    dataWoE = calcWoE( inDAT , dependent , response , event = event )

    #500.   Calculate the IV to [response] for [dependent] at row level.
    mask : pd.Series = dataWoE.apply( lambda x : ( x.p_NonEvent - x.p_Event ) * x.WoE , axis = 1 )

    #600.   Calculate the IV to [response] for [dependent] in the entire dataframe.
    outRST : float64 = sum(mask)

    #800.   Purge the memory usage.
    LfuncName , __Err = None , None
    mask = None

    #900.   Output.
    return( outRST , dataWoE )
#End calcIV

"""
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=="__main__":
    #010.   Create envionment.
    import pandas as pd
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.Stats import calcIV

    #100.   Create the testing dataset.
    raw_x : list = [0,0,0,1,1,1,0,1,1,1]
    raw_y : list = [0,0,0,1,0,1,1,1,1,1]
    data : pd.DataFrame = pd.DataFrame( list(zip( raw_x , raw_y )) , columns = [ 'x' , 'y' ] )

    #200.   Calculate the WoE.
    IV , DatWoE = calcIV( data , 'x' , 'y' )
#-Notes- -End-
"""

"""
#-Explanation- -Begin-
#See IV calculation logic: https://blog.csdn.net/weixin_38940048/article/details/82316900
#See Case Study: http://ucanalytics.com/blogs/information-value-and-weight-of-evidencebanking-case/
#---------------------|-------------------------------------
#  Information Value  |      Predictive Power
#---------------------|-------------------------------------
#       < 0.02        |   useless for prediction
#    0.02 to 0.1      |   Weak predictor
#     0.1 to 0.3      |   Medium predictor
#     0.3 to 0.5      |   Strong predictor
#       >0.5          |   Suspicious or too good to be true
#---------------------|-------------------------------------
#若IV在（-∞，0.02]区间，视为无预测力变量
#若IV在（0.02，0.1]区间，视为较弱预测力变量
#若IV在（0.1，+∞）区间，视为预测力可以，而实际应用中，也是保留IV值大于0.1的变量进行筛选
#-Explanation- -End-
"""