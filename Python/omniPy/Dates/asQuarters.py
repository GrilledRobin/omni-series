#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import datetime as dt
import pandas as pd
import numpy as np
#Quote: https://stackoverflow.com/questions/847936/how-can-i-find-the-number-of-arguments-of-a-python-function
from inspect import signature
from collections.abc import Iterable
from omniPy.AdvOp import vecStack, vecUnstack

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
#   |                 or [pd.DataFrame.map(asQuarters).astype('object').astype(np.int8)]                                                #
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
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230902        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Replace <pd.DataFrame.applymap> with <pd.DataFrame.map> as the former is deprecated since pandas==2.1.0                 #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20231016        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Rewrite the function to reduce the time consumption by 90%                                                              #
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
#   |   |sys, datetime, pandas, numpy, inspect, collections                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |vecStack                                                                                                                   #
#   |   |   |vecUnstack                                                                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Handle the parameter buffer.
    if indate is None: return(None)
    col_eval = signature(vecStack).parameters['valName'].default

    #200. Helper functions
    #210. Function to process the unstacked data before type conversion
    def h_dtype(df):
        return(df)

    #290. Function to return the result in the same shape as input
    def h_rst(rst, col):
        #500. Unstack the underlying data to the same shape as the input one
        rstOut = vecUnstack(rst, valName = col, modelObj = indate, funcConv = h_dtype)

        #999. Purge
        return(rstOut)

    #300. Flatten the input
    vec_in = vecStack(indate)

    #400. Identify different sections to process
    #410. Identify the types of respective input values
    vec_types = vec_in[col_eval].apply(lambda x: type(x).__name__)

    #450. Locate different sections to process
    vtype_dt = vec_types.isin(['datetime','date'])
    vtype_ts = vec_types.eq('Timestamp')
    vtype_nat = ~(vtype_dt | vtype_ts)

    #500. Convert to the dedicated values for different scenarios
    #510. Convert datetime-like values
    #A more elegant value-at-glimpse is as below:
    #return( np.int8( (d.month-1)//3 + 1 ) )
    #Quote: https://stackoverflow.com/questions/11548005/numpy-or-pandas-keeping-array-type-as-integer-while-having-a-nan-value
    out_dt = vec_in[col_eval].loc[vtype_dt].astype('object').apply(lambda d: d.month).astype('Int8').add(2).floordiv(3)

    #520. Convert timestamp values
    out_ts = vec_in[col_eval].loc[vtype_ts].astype('datetime64[ns]').dt.month.add(2).floordiv(3).astype('Int8')

    #580. Initialize NULL values
    out_nat = vec_in[col_eval].loc[vtype_nat].astype('object')
    out_nat.loc[:] = np.nan

    #600. Combine the results
    vec_out = pd.concat(
        [
            out_dt
            ,out_ts
            ,out_nat.astype('Int8')
        ]
        ,axis = 0
        ,ignore_index = False
    )

    #800. Prepare the structure for output
    rstOut = vec_in.copy(deep = True).assign(**{col_eval : vec_out})

    #900. Export in the same shape as the input
    return(h_rst(rstOut, col_eval))
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
    df['qtr2'] = df['DT_DATE'].apply(asQuarters).astype('Int8')
    #Quote: https://www.geeksforgeeks.org/display-the-pandas-dataframe-in-table-style/
    df.head()
    df.dtypes

    #600. Test if the data frame has no row
    df2 = df.loc[ df['DT_DATE'] == dt.datetime.today() ]
    df2['qtr'] = asQuarters( df2['DT_DATE'] )
    #[IMPORTANT] In below case, make sure to use [astype(np.int8)] to avoid any subsequent problems (conflicting that when the
    #             input data frome is NOT empty)
    df2['qtr2'] = df2['DT_DATE'].apply(asQuarters).astype('Int8')
    df2.dtypes

    #700. Convert several volumns at the same time
    CFG_KPI, meta_kpi = pyr.read_sas7bdat(r'D:\R\omniR\SampleKPI\KPI\K1\cfg_kpi.sas7bdat', encoding = 'GB2312')
    #[IMPORTANT] The SAS date [29991231] is set to the upper bound as [pd.Timestamp.max.date()]
    CFG_KPI[['qtr_BGN','qtr_END']] = asQuarters(CFG_KPI[['D_BGN','D_END']])
    CFG_KPI[['qtr_BGN2','qtr_END2']] = CFG_KPI[['D_BGN','D_END']].apply(asQuarters).astype('Int8')
    CFG_KPI.head()
    CFG_KPI.dtypes

    # [CPU] AMD Ryzen 5 4500 6-Core 3.60GHz
    # [RAM] 32GB 2666MHz
    #900. Test timing
    vvv = vecStack([
        '2021-02-16 08:12:34'
        ,'20210501 13:24:35'
        ,1930912496
        ,dt.date.today()
        ,dt.datetime.now()
        ,np.int64(1930912496)
        ,pd.Timestamp('2017-11-01T12')
        ,pd.NaT
        ,''
    ])
    d_smpl = vvv['.val.'].sample(1000000, replace = True).reset_index(drop=True)
    df_trns = asDatetimes(d_smpl, fmt = ['%Y%m%d %H:%M:%S', '%Y-%m-%d %H:%M:%S'])
    time_bgn = dt.datetime.now()
    q_trns = asQuarters(df_trns)
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # 0:00:00.710345
#-Notes- -End-
'''
