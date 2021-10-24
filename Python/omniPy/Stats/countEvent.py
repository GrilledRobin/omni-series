#!/usr/bin/env python3
# -*- coding: utf-8 -*-

def countEvent( inDAT , event = 1 ) -> 'Count the Event and Non-Event from a DataFrame or Series':
    #000.   Info.
    """
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to count the Event and Non-Event from a pd.DataFrame or pd.Series.                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inDAT      :   The input pd.DataFrame or pd.Series, in which to count the Event as well as Non-Event in terms of the condition.    #
#   |               IMPORTANT: This input should be 1-Dimensional                                                                       #
#   |event      :   The value that represents the Event                                                                                 #
#   |               DEFAULT : [1]                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values.                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |k_Event    :   [int]The count of Event                                                                                             #
#   |k_NonEvent :   [int]The count of the rest observations/records except the Event                                                    #
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
    if not isinstance( inDAT , ( pd.DataFrame , pd.Series ) ):
        raise TypeError( '[' + LfuncName +  ']Parameter [inDAT] should be of the type [pd.DataFrame] or [pd.Series]! Type of input value is [{0}]'.format( type(inDAT) ) )

    #013.   Define the local environment.

    #100.   Retrieve the count of [Event] in the provided dataframe.
    k_Event : int64 = ( inDAT == event ).sum()

    #200.   Count the rest observations.
    k_NonEvent : int64 = inDAT.shape[0] - k_Event

    #800.   Purge the memory usage.
    LfuncName , __Err = None , None

    #900.   Output.
    return( k_Event , k_NonEvent )
#End countEvent

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
    from omniPy.Stats import countEvent

    #100.   Create the testing dataset.
    rawdata : dict = {'y_label':[1,1,1,1,1,1,0,0,0,0,0,0],'pred':[0.5,0.6,0.7,0.6,0.6,0.8,0.4,0.2,0.1,0.4,0.3,0.9]}
    data : pd.DataFrame = pd.DataFrame(rawdata)

    #200.   Retrieve the counts of True values and False values.
    k_True , k_False = countEvent( data['y_label'] )
#-Notes- -End-
"""