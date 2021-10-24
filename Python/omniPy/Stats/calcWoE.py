#!/usr/bin/env python3
# -*- coding: utf-8 -*-

def calcWoE( inDAT , dependent , response , event = 1 ) -> 'Calculate the Weight of Evidence for [response] variable in the dataset':
    #000.   Info.
    """
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to calculate the Weight of Evidence for the variable [response] in terms of [dependent] variable in the  #
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
#   |[outDAT]   :   [pd.DataFrame]The dataset which denotes a new dataset that contains unique values of [dependent] as well as their   #
#   |                respective WoE to the [event] at the variable of [response].                                                       #
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
#   |   |sys, pandas, numpy                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.Stats                                                                                                                   #
#   |   |   |countEvent                                                                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
    """

    #001.   Import necessary functions for processing.
    #from imp import find_module
    import pandas as pd
    import numpy as np
    import sys
    from omniPy.Stats import countEvent

    #010.   Check parameters.
    #011.   Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name
    __Err : str = "ERROR: [" + LfuncName + "]Process failed due to errors!"

    #012.   Handle the parameter buffer.
    if not isinstance( inDAT , pd.DataFrame ):
        raise TypeError( '[' + LfuncName +  ']Parameter [inDAT] should be of the type [pd.DataFrame]! Type of input value is [{0}]'.format( type(inDAT) ) )

    #013.   Define the local environment.

    #100.   Count the Event and Non-Event per requested [response].
    k_Event , k_NonEvent = countEvent( inDAT[response] , event = event )

    #190.   Raise error if either of the counts is zero, as WoE means nothing if [dependent] has no effect upon [response].
    if k_Event == 0:
        raise ValueError( '[' + LfuncName +  ']Count of [event:{0}] is zero! WoE means nothing to the response:[{1}] in terms of the dependent:[{2}]!'.format( event , response , dependent ) )
    if k_NonEvent == 0:
        raise ValueError( '[' + LfuncName +  ']Count of [non-event:(other than: {0})] is zero! WoE means nothing to the response:[{1}] in terms of the dependent:[{2}]!'.format( event , response , dependent ) )

    #200.   Create the cross tabulation with row as [dependent] and column as a binary mask to [response].
    #210.   Create a binary mask to [responese].
    mask : pd.Series = inDAT[response].apply( lambda x : x == event )

    #250.   Cross-tabulation.
    tabfreq : pd.DataFrame = pd.crosstab( inDAT[dependent] , mask ).rename( columns = { False:'NonEvent' , True:'Event' } )

    #500.   Calculate the WoE at row level.
    #510.   Add a bias to avoid zero shows up in the denominator.
    eps : float64 = 0.0000001

    #520.   Calculate the percentage that [Event] and [NonEvent] at current row take up in the entire sample. (Stats: 计算当前组中[Event]与[NonEvent]分别占全样本中对应值的比重)
    #We do not have to initialize the NA values in [tabfreq] as it comes from a cross tabulation while no missing value can be create on both axes.
    tabdens : pd.DataFrame = ( tabfreq / tabfreq.sum() ).rename( columns = { 'NonEvent':'p_NonEvent' , 'Event':'p_Event' } ) + eps

    #590.   WoE.
    tabdens['WoE'] = np.log( tabdens['p_NonEvent'] / tabdens['p_Event'] )

    #800.   Purge the memory usage.
    LfuncName , __Err = None , None
    k_Event , k_NonEvent , mask , eps = None , None , None , None

    #900.   Output.
    return( tabfreq.merge( tabdens , on = dependent ) )
#End calcWoE

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
    from omniPy.Stats import calcWoE

    #100.   Create the testing dataset.
    raw_x : list = [0,0,0,1,1,1,0,1,1,1]
    raw_y : list = [0,0,0,1,0,1,1,1,1,1]
    data : pd.DataFrame = pd.DataFrame( list(zip( raw_x , raw_y )) , columns = [ 'x' , 'y' ] )

    #200.   Calculate the WoE.
    dataWoE = calcWoE( data , 'x' , 'y' )
#-Notes- -End-
"""

"""
#-Explanation- -Begin-
#Example package: https://blog.csdn.net/wyl2289/article/details/82497210
#代码实现: http://www.dataguru.cn/article-13352-1.html
#Keywords:
#[01] 上例中包含：卡方分箱
#-Explanation- -End-
"""