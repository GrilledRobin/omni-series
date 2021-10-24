#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import datetime as dt
import pandas as pd
import numpy as np
from collections.abc import Iterable

def asQuarters(indate) -> 'Extract the [Quarter] part of a date, datetime or timestamp':
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to extract the [Quarter] of the provided [dt.date], [dt.datetime] or [pd.Timestamp], or the [pd.Series]  #
#   | or [pd.DataFrame] comprised of these value types                                                                                  #
#   |[IMPORTANT] Any one among the provided values should have the attribute [month] for calculation                                    #
#   |[IMPORTANT] When the input is an empty [pd.Series] or [pd.DataFrame], make sure to use either of below forms to assign the         #
#   |             column(s) in the type of [np.int8] to ensure a dedicated result, i.e. below methods create the columns in the same    #
#   |             [dtype] as [object] no matter the input is empty or not:                                                              #
#   |            [1] [pd.Series.apply(asQuarters).astype('object').astype(np.int8)]                                                     #
#   |                 or [pd.DataFrame.applymap(asQuarters).astype('object').astype(np.int8)]                                           #
#   |                This is because 'datetime64[ns]' cannot be coerced to 'np.int8' directly, and we have to walk around it            #
#   |            [2] [asQuarters(pd.Series)] or [asQuarters(pd.DataFrame)]                                                              #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |indate      :   [dt.date], [dt.datetime], [pd.Timestamp], or a [list], [tuple], [pd.Series] or [pd.DataFrame] comprised of them    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[np.int8  ] :   The mapped result stored in a list (not a tuple as a tuple cannot be added as a column in a data frame if needed)  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210308        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210619        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce [Iterable] to support more iterable input types for the arguments                                             #
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
#   |   |sys, datetime, pandas, numpy, collections                                                                                      #
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

    #012. Handle the parameter buffer.
    if indate is None: return()

    #300. Prepare the function to convert a single value as helper
    #We reduce the RAM usage by setting the type as [np.int8], or (-127 ~ 127); eventually there will only be (1 ~ 4) as output
    #The reason we do not just use [int] is that for compatibility to [pandas], the result converted can never be in the type [int]
    def trnsdate(d):
        return( np.int8( (d.month+2)//3 ) )
        #A more elegant value-at-glimpse is as below:
        #return( np.int8( (d.month-1)//3 + 1 ) )


    #900. Translate the values
    if isinstance( indate , pd.DataFrame ):
        return( indate.applymap(trnsdate).astype('object').astype(np.int8) )
    elif isinstance( indate , pd.Series ):
        return( indate.apply(trnsdate).astype('object').astype(np.int8) )
    elif isinstance( indate , ( dt.date , dt.datetime , pd.Timestamp ) ):
        return( trnsdate(indate) )
    elif isinstance( indate , Iterable ):
        return( list(map( trnsdate , indate )) )
    else:
        raise TypeError(
            '[' + LfuncName + ']Values should either be of the type [datetime.date], [datetime.datetime] or [pandas.Timestamp],'
            + ' or [Iterable] of the previous! Type of input [{0}] is [{1}]'.format( str(indate) , type(indate) )
        )
#End asQuarters

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import datetime as dt
    import sys
    import pandas as pd
    import numpy as np
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.Dates import asDates, asQuarters
    print(asQuarters.__doc__)

    #100. Convert a date
    a1 = dt.date.today()
    a1_rst = asQuarters( a1 )

    #200. Convert a datetime
    a2 = dt.datetime.today()
    a2_rst = asQuarters( a2 )

    #300. Convert a string
    a3 = '2021-02-16'
    a3_rst = asQuarters( asDates(a3) )

    #400. Convert a list of dates
    a4 = [ '2020-09-15' , a2 ]
    a4_rst = asQuarters( asDates(a4) )

    #500. Convert a datetime column to date
    df = pd.DataFrame(
        data = pd.date_range( dt.datetime.strptime('20201201','%Y%m%d') , dt.datetime.strptime('20210131','%Y%m%d') )
        , columns = [ 'DT_DATE' ]
    )
    df['qtr'] = asQuarters( df['DT_DATE'] )
    df['qtr2'] = df['DT_DATE'].apply(asQuarters).astype('object').astype(np.int8)
    #Quote: https://www.geeksforgeeks.org/display-the-pandas-dataframe-in-table-style/
    df.head()
    df.dtypes

    #600. Test if the data frame has no row
    df2 = df.loc[ df['DT_DATE'] == dt.datetime.today() ]
    df2['qtr'] = asQuarters( df2['DT_DATE'] )
    #[IMPORTANT] In below case, make sure to use [astype(np.int8)] to avoid any subsequent problems (conflicting that when the
    #             input data frome is NOT empty)
    df2['qtr2'] = df2['DT_DATE'].apply(asQuarters).astype('object').astype(np.int8)
    df2.dtypes

    #700. Convert several volumns at the same time
    CFG_KPI, meta_kpi = pyr.read_sas7bdat(r'D:\R\omniR\SampleKPI\KPI\K1\cfg_kpi.sas7bdat', encoding = 'GB2312')
    #[IMPORTANT] The SAS date [29991231] is set to the upper bound as [pd.Timestamp.max.date()]
    CFG_KPI[['qtr_BGN','qtr_END']] = asQuarters(CFG_KPI[['D_BGN','D_END']])
    CFG_KPI[['qtr_BGN2','qtr_END2']] = CFG_KPI[['D_BGN','D_END']].apply(asQuarters).astype('object').astype(np.int8)
    CFG_KPI.head()
    CFG_KPI.dtypes
#-Notes- -End-
'''
