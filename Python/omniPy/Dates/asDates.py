#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import numbers
import datetime as dt
import pandas as pd
#Quote: https://stackoverflow.com/questions/847936/how-can-i-find-the-number-of-arguments-of-a-python-function
from inspect import signature
from collections.abc import Iterable
from copy import deepcopy
from omniPy.AdvOp import thisFunction, vecStack, vecUnstack

def asDates(
    indate
    , fmt : Iterable = ['%Y%m%d', '%Y-%m-%d', '%Y/%m/%d']
    , origin = dt.date(1960,1,1)
    , unit : str = 'days'
) -> 'Translate date-like values into dates in the type of [datetime.date]':
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to convert any type of input values into valid dates (with type as [datetime.date])                      #
#   |[IMPORTANT] When the input is an empty [pd.Series] or [pd.DataFrame], make sure to use either of below forms to assign the         #
#   |             column(s) in the type of [dt.date] to ensure a dedicated result, i.e. below methods create the columns in the same    #
#   |             [dtype] as [object] no matter the input is empty or not:                                                              #
#   |            [1] [pd.Series.apply(asDates).astype('object')] or [pd.DataFrame.map(asDates).astype('object')]                        #
#   |            [2] [asDates(pd.Series)] or [asDates(pd.DataFrame)]                                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[NOTE]                                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<strftime> on Windows OS is different from that on Mac OS at syntax <%-m> and the likes:                                           #
#   |[1] On Win OS, use <%#m> to remove leading zeros (however, when using <strptime> this syntax still fails)                          #
#   |[2] On Mac OS, use <%-m> to remove leading zeros (not tested when using <strptime>)                                                #
#   |[3] Quote: https://stackoverflow.com/questions/904928/python-strftime-date-without-leading-0                                       #
#   |[4] Quote: https://msdn.microsoft.com/en-us/library/fe06s4ak.aspx                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[EFFICIENCY]                                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Time comparison of various functions to a pd.Series                                                                            #
#   |    Quote: https://stackoverflow.com/questions/49371629                                                                            #
#   |[2] How to cast types of elements in a pd.Series                                                                                   #
#   |    Quote: https://note.nkmk.me/en/python-pandas-dtype-astype/                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |indate      :   Date-like values, can be list/tuple of date values, character strings, integers or date column of a data frame     #
#   |fmt         :   Alternative format to be passed to function [strptime] when the input is a character string                        #
#   |                 [ <list>     ] <Default> Try to match these formats for any input strings, see function definition                #
#   |origin      :   Date-like scalar, as origin, to convert the values in the type of [int], [float], [np.integer] or [np.floating]    #
#   |                See official document of [pd.to_datetime]                                                                          #
#   |                 [ 1960-01-01 ] <Default> Also the default origin of SAS for easy conversion                                       #
#   |unit        :   Unit by which to convert the values in the type of [int], [float], [np.integer] or [np.floating]                   #
#   |                See official document of [datetime.timedelta]                                                                      #
#   |                 [ days       ] <Default> Also the default unit of SAS date storage for easy conversion                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[ list  ]   :   The mapped result stored in a list (not a tuple as a tuple cannot be added as a column in a data frame if needed)  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210216        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210307        | Version | 1.01        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Add the date conversion method from SAS to Python, esp. for the package [pyreadstat]                                    #
#   |      |    [IMPORTANT] Since the lower and upper bounds as nanoseconds for [pd.Timestamp] is too small, we have to seek for other  #
#   |      |                 solutions to coerce the date-like values and store them in [pd.Series] or [pd.DataFrame]                   #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210619        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce [Iterable] to support more iterable input types for the arguments                                             #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210816        | Version | 1.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Add new argument [asnat] to indicate whether to accept invalid input values                                             #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210909        | Version | 1.30        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Remove the argument [asnat] as the function no longer raise errors for invalid inputs, but output [pd.NaT]              #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230815        | Version | 1.40        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce the imitated <recall> to make the recursion more intuitive                                                    #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230819        | Version | 1.50        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Remove <recall> as it always fails to search in RAM when the function is imported in another module                     #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230821        | Version | 1.60        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <thisFunction> to actually find the current callable being called instead of its name                         #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230902        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Replace <pd.DataFrame.applymap> with <pd.DataFrame.map> as the former is deprecated since pandas==2.1.0                 #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20231016        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Rewrite the function to reduce the time consumption by 60%                                                              #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20231102        | Version | 3.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Improve efficiency when all input values are already of the dedicated type or NATType                                   #
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
#   |   |sys, numbers, datetime, pandas, inspect, collections, copy                                                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |thisFunction                                                                                                               #
#   |   |   |vecStack                                                                                                                   #
#   |   |   |vecUnstack                                                                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name
    recall = thisFunction()

    #012. Handle the parameter buffer.
    if indate is None: return(None)
    col_eval = signature(vecStack).parameters['valName'].default
    inttypes = [
        'int'
        ,'int8','int16','int32','int64'
        ,'uint8','uint16','uint32','uint64'
        #Quote: https://stackoverflow.com/questions/11548005/numpy-or-pandas-keeping-array-type-as-integer-while-having-a-nan-value
        ,'Int8','Int16','Int32','Int64'
        ,'UInt8','UInt16','UInt32','UInt64'
    ]

    #050. Standardize the formats to be used to try converting the date-like values
    if isinstance(fmt, str):
        fmt_fnl = [fmt]
    elif isinstance(fmt, Iterable):
        fmt_fnl = list(fmt)
    else:
        raise TypeError(f'[{LfuncName}][fmt] must be [str], or [Iterable] of the previous')

    #100. Convert the [origin] to [dt.date] and meanwhile prevent the infinite recursion
    if not isinstance(origin, dt.date):
        if isinstance(origin, numbers.Number):
            origin = dt.date.fromordinal(int(origin))
        else:
            origin = recall(origin, fmt = fmt_fnl, origin = None)

    #200. Helper functions
    #210. Function to process the unstacked data before type conversion
    def h_dtype(df):
        return(df)

    #290. Function to return the result in the same shape as input
    def h_rst(rst, col):
        #500. Unstack the underlying data to the same shape as the input one
        #[ASSUMPTION]
        #[1] <col-id> and <row-id> do not have <NA> values
        #[2] There can only be <NA> values in the <col>
        #[3] Hence we have to convert them to <NaT> as output
        rstOut = vecUnstack(rst, valName = col, modelObj = indate, funcConv = h_dtype)

        #999. Purge
        return(rstOut)

    #300. Flatten the input
    vec_in = vecStack(indate)

    #400. Identify different sections to process
    #410. Identify the types of respective input values
    vec_types = vec_in[col_eval].apply(lambda x: type(x).__name__)

    #450. Locate different sections to process
    #Quote: https://stackoverflow.com/questions/55718601/pandas-fixing-datetime-time-and-datetime-datetime-mix
    vtype_d = vec_types.eq('date')
    if vtype_d.all():
        return(deepcopy(indate))

    vtype_nat = ~vec_types.isin(['datetime','Timestamp','date','str'] + inttypes)
    if (vtype_d | vtype_nat).all():
        rstOut = vec_in.copy(deep = True).assign(**{col_eval : lambda x: x[col_eval].astype('object')})
        rstOut.loc[vtype_nat, col_eval] = pd.NaT
        return(h_rst(rstOut, col_eval))

    vtype_dt = vec_types.isin(['datetime','Timestamp'])
    #[ASSUMPTION]
    #[1] <Series.str.startswith()> is 4x slower than <Series.isin()>
    # vtype_int = vec_types.str.startswith('int')
    vtype_int = vec_types.isin(inttypes)
    vtype_str = vec_types.eq('str')

    #500. Convert to the dedicated values for different scenarios
    #510. Convert datetime-like values
    out_dt = vec_in[col_eval].loc[vtype_dt].astype('object').apply(lambda d: d.date())

    #530. Convert integer-like values
    #Quote: https://stackoverflow.com/questions/36361849/is-there-an-as-date-equivalent-r-in-python
    #Quote: https://stackoverflow.com/questions/50265288/
    #Quote: https://pandas.pydata.org/pandas-docs/stable/user_guide/timeseries.html
    out_int = (
        vec_in[col_eval]
        .loc[vtype_int]
        .astype('object')
        .apply(lambda d: origin + dt.timedelta(**{unit:int(d)}))
        .where(lambda x: x.le(dt.date.max), dt.date.max)
        .where(lambda x: x.ge(dt.date.min), dt.date.min)
    )

    #550. Convert strings
    #Quote: https://stackoverflow.com/questions/17134716/convert-dataframe-column-type-from-string-to-datetime
    out_str = pd.Series(
        (
            pd.concat(
                [pd.to_datetime(vec_in[col_eval].loc[vtype_str], errors = 'coerce', format = f) for f in fmt_fnl]
                ,axis = 1
            )
            .bfill(axis = 1)
            .iloc[:, 0]
            .dt.date
        )
        ,dtype = 'object'
        ,index = vtype_str.loc[vtype_str].index
    )

    #580. Initialize NULL values
    out_nat = vec_in[col_eval].loc[vtype_nat].astype('object')
    out_nat.loc[:] = pd.NaT

    #600. Combine the results
    vec_out = pd.concat(
        [
            vec_in[col_eval].loc[vtype_d].astype('object')
            ,out_dt
            ,out_int
            ,out_str
            ,out_nat
        ]
        ,axis = 0
        ,ignore_index = False
    )

    #800. Prepare the structure for output
    rstOut = vec_in.copy(deep = True).assign(**{col_eval : vec_out})

    #900. Export in the same shape as the input
    return(h_rst(rstOut, col_eval))
#End asDates

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import datetime as dt
    import sys
    import pandas as pd
    import numpy as np
    import pyreadstat as pyr
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.Dates import asDates
    from omniPy.AdvOp import vecStack
    print(asDates.__doc__)

    #100. Convert a date
    a1 = dt.date.today()
    a1_rst = asDates( a1 )

    #200. Convert a datetime
    a2 = dt.datetime.today()
    a2_rst = asDates( a2 )

    #300. Convert a string
    a3 = '2021-02-16'
    a3_rst = asDates( a3 )

    #400. Convert a list of dates
    a4 = [ '2021-02-14' , a2 ]
    a4_rst = asDates( a4 )

    #500. Convert a datetime column to date
    df = pd.DataFrame(
        data = pd.date_range( dt.datetime.strptime('20210101','%Y%m%d') , dt.datetime.strptime('20210131','%Y%m%d') )
        , columns = [ 'DT_DATE' ]
    )
    df['d_date'] = asDates( df['DT_DATE'] )
    df['d_date2'] = df['DT_DATE'].apply(asDates).astype('object')
    #Quote: https://www.geeksforgeeks.org/display-the-pandas-dataframe-in-table-style/
    df.head()
    df.dtypes

    #600. Test if the data frame has no row
    df2 = df.loc[ df['DT_DATE'] == dt.datetime.today() ]
    df2['d_date'] = asDates( df2['DT_DATE'] )
    #[IMPORTANT] In below case, make sure to use [astype('object')] to avoid any subsequent problems (conflicting that when the
    #             input data frame is NOT empty)
    df2['d_date2'] = df2['DT_DATE'].apply(asDates).astype('object')
    df2.dtypes

    #700. Convert the raw values into dates from SAS dataset
    CFG_KPI, meta_kpi = pyr.read_sas7bdat(dir_omniPy + r'omniPy\AdvDB\test_loadsasdat.sas7bdat', encoding = 'GB2312')
    CFG_KPI[['DT_TEST','D_TEST']] = CFG_KPI[['DT_TEST','D_TEST']].apply(asDates).astype('object')
    CFG_KPI.head()
    CFG_KPI.dtypes

    #720. Same as above
    CFG_KPI2 = CFG_KPI.copy(deep=True)
    CFG_KPI2[['DT_TEST2','D_TEST2']] = asDates(CFG_KPI[['DT_TEST','D_TEST']])

    #800. Convert an integer into date, as it represents a [Date: 2014-01-31] in SAS with the default origin as [1960-01-01]
    a5 = 19754
    a5_rst = asDates( a5 , origin = '1960-01-01' )

    # [CPU] AMD Ryzen 5 5600 6-Core 3.70GHz
    # [RAM] 64GB 2400MHz
    #900. Test timing
    vvv = vecStack([
        '2021-02-16'
        ,'20210101'
        ,19754
        ,dt.date.today()
        ,dt.datetime.now()
        ,np.int64(19854)
        ,pd.Timestamp('2017-01-01T12')
        ,pd.NaT
        ,''
    ])
    d_smpl = vvv['.val.'].sample(1000000, replace = True).reset_index(drop=True)
    time_bgn = dt.datetime.now()
    df_trns = asDates(d_smpl, fmt = ['%Y%m%d', '%Y-%m-%d'])
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # 0:00:00.890400
#-Notes- -End-
'''
