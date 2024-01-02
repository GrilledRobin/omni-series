#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import numbers
import datetime as dt
import pandas as pd
import itertools as itt
#Quote: https://stackoverflow.com/questions/847936/how-can-i-find-the-number-of-arguments-of-a-python-function
from inspect import signature
from collections.abc import Iterable
from copy import deepcopy
from omniPy.AdvOp import thisFunction, vecStack, vecUnstack

def asDatetimes(
    indate
    , fmt : Iterable = list(map(
        ''.join
        ,list(itt.product(
            ['%Y%m%d', '%Y-%m-%d', '%Y/%m/%d']
            , [':', ' ', '-']
            , ['%H%M%S', '%H-%M-%S', '%H:%M:%S', '%H %M %S']
        ))
    )) + ['%Y%m%d', '%Y-%m-%d', '%Y/%m/%d']
    , origin = dt.datetime(1960,1,1)
    , unit = 'seconds'
) -> dt.datetime | Iterable[dt.datetime]:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to convert any type of input values into valid datetime (with type as [datetime.datetime])               #
#   |[IMPORTANT] When the input is an empty [pd.Series] or [pd.DataFrame], make sure to use either of below forms to assign the         #
#   |             column(s) in the type of [dt.datetime] to ensure a dedicated result, i.e. below methods create the columns in the     #
#   |             same [dtype] as [object] no matter the input is empty or not:                                                         #
#   |            [1] [pd.Series.apply(asDatetimes).astype('object')] or [pd.DataFrame.map(asDatetimes).astype('object')]                #
#   |            [2] [asDatetimes(pd.Series)] or [asDatetimes(pd.DataFrame)]                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |indate      :   Date-like values, can be list/tuple of date values, character strings, integers or date column of a data frame     #
#   |fmt         :   Alternative format to be passed to function [strptime] when the input is a character string                        #
#   |                Re-introduced at v1.4, requiring caller to provide specific format, or spend lots of time during parsing           #
#   |                 [ <list>     ] <Default> Try to match these formats for any input strings, see function definition                #
#   |origin      :   Date-like scalar, as origin, to convert the values in the type of [int], [float], [np.integer] or [np.floating]    #
#   |                See official document of [pd.to_datetime]                                                                          #
#   |                 [ 1960-01-01 ] <Default> Also the default origin of SAS for easy conversion                                       #
#   |unit        :   Unit by which to convert the values in the type of [int], [float], [np.integer] or [np.floating]                   #
#   |                See official document of [datetime.timedelta]                                                                      #
#   |                 [ seconds    ] <Default> Also the default unit of SAS datetime storage for easy conversion                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<Any>       :   The returned value may be <dt.datetime | Iterable[dt.datetime]> depending on the input type                        #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210309        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
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
#   |      |[2] Add methods to convert [pd.Timestamp] to [dt.datetime] and store the values as the type [object] for [pandas] input,    #
#   |      |     to ensure type consistency of the output, esp. when the date values that are beyond/within the limit of [pd.Timestamp] #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210909        | Version | 1.30        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Remove the argument [asnat] as the function no longer raise errors for invalid inputs, but output [pd.NaT]              #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230608        | Version | 1.40        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fix a bug when input valus is <str> while <fmt> is not applied                                                          #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230815        | Version | 1.50        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce the imitated <recall> to make the recursion more intuitive                                                    #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230819        | Version | 1.60        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Remove <recall> as it always fails to search in RAM when the function is imported in another module                     #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230821        | Version | 1.70        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <thisFunction> to actually find the current callable being called instead of its name                         #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230902        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Replace <pd.DataFrame.applymap> with <pd.DataFrame.map> as the former is deprecated since pandas==2.1.0                 #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20231013        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Rewrite the function to reduce the time consumption by 60%                                                              #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20231102        | Version | 3.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Improve efficiency when all input values are already of the dedicated type or NATType                                   #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20231107        | Version | 3.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug when converting the result into datetime.datetime                                                           #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240102        | Version | 3.30        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Added logic for <float> types                                                                                           #
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
#   |   |sys, numbers, datetime, pandas, itertools, inspect, collections, copy                                                          #
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
    floattypes = [
        'float'
        ,'float16','float32','float64'
    ]

    #100. Standardize the formats to be used to try converting the date-like values
    if isinstance(fmt, str):
        fmt_fnl = [fmt]
    elif isinstance(fmt, Iterable):
        fmt_fnl = list(fmt)
    else:
        raise TypeError(f'[{LfuncName}][fmt] must be [str], or [Iterable] of the previous')

    #200. Conver the [origin] to [dt.datetime] and meanwhile prevent the infinite recursion
    if not isinstance(origin, dt.datetime):
        if isinstance(origin, numbers.Number):
            origin = dt.datetime.min + dt.timedelta(**{unit:int(origin)})
        else:
            origin = recall(origin, fmt = fmt_fnl, origin = None)

    #200. Helper functions
    #210. Function to process the unstacked data before type conversion
    def h_dtype(df):
        #100. Find all columns of above data that are stored as [datetime64[ns]], i.e. [pd.Timestamp]
        conv_dtcol = (
            df.dtypes
            .reset_index(drop = True)
            .apply(str)
            .loc[lambda x: x.str.startswith('datetime')]
            .index
        )

        #300. Create a copy of the input data to avoid unexpected result
        #[ASSUMPTION]
        #[1] [pd.DataFrame.fillna(pd.NaT)] will imperatively change the [dtype] of [datetime] into [pd.Timestamp]
        df_out = df.copy(deep = True).astype('object')

        #500. Re-assign the output values in terms of the request
        #[ASSUMPTION]
        #[1] [pd.DataFrame.unstack()] will imperatively change the [dtype] of [datetime] into [pd.Timestamp]
        #[2] [pd.Series.dt.to_pydatetime()] creates a [list] as output, hence we need to set proper indexes for it
        for i in conv_dtcol:
            df_out.iloc[:, i] = pd.Series(df.iloc[:, i].dt.to_pydatetime(), dtype = 'object', index = df.index)

        #999. Purge
        return(df_out)

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
    vtype_dt = vec_types.eq('datetime')
    if vtype_dt.all():
        return(deepcopy(indate))

    vtype_nat = ~vec_types.isin(['datetime','Timestamp','date','str'] + inttypes + floattypes)
    if (vtype_dt | vtype_nat).all():
        rstOut = vec_in.copy(deep = True).assign(**{col_eval : lambda x: x[col_eval].astype('object')})
        rstOut.loc[vtype_nat, col_eval] = pd.NaT
        return(h_rst(rstOut, col_eval))

    vtype_ts = vec_types.eq('Timestamp')
    vtype_d = vec_types.eq('date')
    #[ASSUMPTION]
    #[1] <Series.str.startswith()> is 4x slower than <Series.isin()>
    # vtype_int = vec_types.str.startswith('int')
    vtype_int = vec_types.isin(inttypes)
    vtype_float = vec_types.isin(floattypes)
    vtype_str = vec_types.eq('str')

    #500. Convert to the dedicated values for different scenarios
    #520. Convert timestamp values
    out_ts = pd.Series(
        vec_in[col_eval].loc[vtype_ts].astype('datetime64[ns]').dt.to_pydatetime()
        ,dtype = 'object'
        ,index = vtype_ts.loc[vtype_ts].index
    )

    #530. Convert integer-like values
    #Quote: https://stackoverflow.com/questions/36361849/is-there-an-as-date-equivalent-r-in-python
    #Quote: https://stackoverflow.com/questions/50265288/
    #Quote: https://pandas.pydata.org/pandas-docs/stable/user_guide/timeseries.html
    out_int = (
        vec_in[col_eval]
        .loc[vtype_int]
        .astype('object')
        .apply(lambda d: origin + dt.timedelta(**{unit:int(d)}))
        .where(lambda x: x.le(dt.datetime.max), dt.datetime.max)
        .where(lambda x: x.ge(dt.datetime.min), dt.datetime.min)
    )
    if pd.api.types.is_datetime64_any_dtype(out_int.dtype):
        out_int = pd.Series(out_int.dt.to_pydatetime(), dtype = 'object', index = out_int.index)

    #540. Convert float values
    tmp_float = (
        vec_in[col_eval]
        .loc[vtype_float]
        .astype('object')
    )
    fl_int = tmp_float.astype(int)
    fl_dec = tmp_float.mod(1).mul(100000).astype(int)
    out_float = (
        fl_int
        .apply(lambda d: origin + dt.timedelta(**{unit:int(d)}))
        .add(fl_dec.apply(lambda x: dt.timedelta(**{'microseconds':int(x)})))
        .where(lambda x: x.le(dt.datetime.max), dt.datetime.max)
        .where(lambda x: x.ge(dt.datetime.min), dt.datetime.min)
    )
    if pd.api.types.is_datetime64_any_dtype(out_float.dtype):
        out_float = pd.Series(out_float.dt.to_pydatetime(), dtype = 'object', index = out_float.index)

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
            .dt.to_pydatetime()
        )
        ,dtype = 'object'
        ,index = vtype_str.loc[vtype_str].index
    )

    #570. Convert dates
    out_d = vec_in[col_eval].loc[vtype_d].astype('object').apply(lambda x: dt.datetime.combine(x, dt.time(0,0,0)))

    #580. Initialize NULL values
    out_nat = vec_in[col_eval].loc[vtype_nat].astype('object')
    out_nat.loc[:] = pd.NaT

    #600. Combine the results
    vec_out = pd.concat(
        [
            vec_in[col_eval].loc[vtype_dt].astype('object')
            ,out_ts
            ,out_int
            ,out_float
            ,out_str
            ,out_d
            ,out_nat
        ]
        ,axis = 0
        ,ignore_index = False
    )

    #800. Prepare the structure for output
    rstOut = vec_in.copy(deep = True).assign(**{col_eval : vec_out})

    #900. Export in the same shape as the input
    return(h_rst(rstOut, col_eval))
#End asDatetimes

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import datetime as dt
    import sys
    import pandas as pd
    import pyreadstat as pyr
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.Dates import asDatetimes
    from omniPy.AdvOp import vecStack
    print(asDatetimes.__doc__)

    #100. Convert a date
    a1 = dt.date.today()
    a1_rst = asDatetimes( a1 )

    #200. Convert a datetime
    a2 = dt.datetime.today()
    a2_rst = asDatetimes( a2 )

    #250. Convert a float value
    #[ASSUMPTION]
    #[1] Many methods collecting file information would return a float value
    #[2] China is in timezone +8, hence the returned result should be added by 8 to represent correct value in China
    float_rst = asDatetimes( 1704198122.6569407, origin = dt.datetime(1970,1,1) ) + dt.timedelta(hours = 8)

    #300. Convert a string
    a3 = '2021-02-16 12:34:56'
    a3_rst = asDatetimes( a3 )

    #400. Convert a list of dates
    a4 = [ a3 , a2 ]
    a4_rst = asDatetimes( a4 )

    #500. Convert a datetime column to date
    df = pd.DataFrame(
        data = pd.date_range( dt.datetime.strptime('20210101','%Y%m%d') , dt.datetime.strptime('20210131','%Y%m%d') )
        , columns = [ 'DT_DATE' ]
    )
    df['d_date'] = asDatetimes( df['DT_DATE'] )
    df['d_date2'] = df['DT_DATE'].apply(asDatetimes).astype('object')
    #Quote: https://www.geeksforgeeks.org/display-the-pandas-dataframe-in-table-style/
    df.head()
    df.dtypes

    #600. Test if the data frame has no row
    df2 = df.loc[ df['DT_DATE'] == dt.datetime.today() ]
    df2['d_date'] = asDatetimes( df2['DT_DATE'] )
    #[IMPORTANT] In below case, make sure to use [astype('object')] to avoid any subsequent problems (conflicting that when the
    #             input data frame is NOT empty)
    df2['d_date2'] = df2['DT_DATE'].apply(asDatetimes).astype('object')
    df2.dtypes

    #700. Convert the raw values into dates from SAS dataset
    CFG_KPI, meta_kpi = pyr.read_sas7bdat(dir_omniPy + r'omniPy\AdvDB\test_loadsasdat.sas7bdat', encoding = 'GB2312')
    CFG_KPI[['DT_TEST']] = CFG_KPI[['DT_TEST']].apply(asDatetimes).astype('object')
    CFG_KPI.head()
    CFG_KPI.dtypes

    #720. Same as above
    CFG_KPI2 = CFG_KPI.copy(deep=True)
    CFG_KPI2[['DT_TEST2','D_TEST2']] = asDatetimes(CFG_KPI[['DT_TEST','D_TEST']])

    #800. Convert an integer, as it represents a [Date: 2021-03-09 12:34:56] in SAS with the default origin as [1960-01-01]
    a5 = 1930912496
    a5_rst = asDatetimes( a5 )

    # [CPU] AMD Ryzen 5 5600 6-Core 3.70GHz
    # [RAM] 64GB 2400MHz
    #900. Test timing
    test_sample = CFG_KPI[['DT_TEST','D_TEST']].copy(deep=True).sample(100000, replace = True)
    time_bgn = dt.datetime.now()
    df_trns_old = asDatetimes(test_sample)
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # 0:00:00.338204

    #Full speed test
    #Quote: https://ehmatthes.com/blog/faster_than_strptime/
    aaa = CFG_KPI['DT_TEST'].sample(100000, replace = True).apply(lambda x: x.strftime('%Y/%m/%d-%H %M %S'))

    time_bgn = dt.datetime.now()
    bbb = asDatetimes(aaa)
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # 0:00:00.543917

    time_bgn = dt.datetime.now()
    bbb2 = asDatetimes(aaa, fmt = '%Y/%m/%d-%H %M %S')
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # 0:00:00.105585

    time_bgn = dt.datetime.now()
    bbb3 = pd.to_datetime(aaa)
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # DateParseError: Unknown datetime string format

    time_bgn = dt.datetime.now()
    bbb3 = pd.to_datetime(aaa, format = '%Y/%m/%d-%H %M %S')
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # 0:00:00.010003

    #Various inputs
    vvv = vecStack([
        '2021-02-16 08:12:34'
        ,'20210101 13:24:35'
        ,1930912496
        ,dt.date.today()
        ,dt.datetime.now()
        ,np.int64(1930912496)
        ,pd.Timestamp('2017-01-01T12')
        ,pd.NaT
        ,''
    ])
    d_smpl = vvv['.val.'].sample(1000000, replace = True).reset_index(drop=True)
    time_bgn = dt.datetime.now()
    df_trns = asDatetimes(d_smpl, fmt = ['%Y%m%d %H:%M:%S', '%Y-%m-%d %H:%M:%S'])
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # 0:00:01.562605
#-Notes- -End-
'''
