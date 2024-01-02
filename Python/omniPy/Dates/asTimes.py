#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import pandas as pd
import datetime as dt
import itertools as itt
#Quote: https://stackoverflow.com/questions/847936/how-can-i-find-the-number-of-arguments-of-a-python-function
from inspect import signature
from collections.abc import Iterable
from copy import deepcopy
from omniPy.AdvOp import vecStack, vecUnstack

def asTimes(
    indate
    , fmt : Iterable = list(map(
        ''.join
        ,list(itt.product(
            ['%Y%m%d', '%Y-%m-%d', '%Y/%m/%d']
            , [':', ' ', '-']
            , ['%H%M%S', '%H-%M-%S', '%H:%M:%S', '%H %M %S']
        ))
    )) + ['%H%M%S', '%H-%M-%S', '%H:%M:%S', '%H %M %S']
    , unit = 'seconds'
) -> dt.time | Iterable[dt.time]:
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to convert any type of input values into valid [datetime.time], i.e. time of day                         #
#   |[IMPORTANT] When the input is an empty [pd.Series] or [pd.DataFrame], make sure to use either of below forms to assign the         #
#   |             column(s) in the type of [dt.date] to ensure a dedicated result, i.e. below methods create the columns in the same    #
#   |             [dtype] as [object] no matter the input is empty or not:                                                              #
#   |            [1] [pd.Series.apply(asTimes).astype('object')] or [pd.DataFrame.map(asTimes).astype('object')]                        #
#   |            [2] [asTimes(pd.Series)] or [asTimes(pd.DataFrame)]                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |indate      :   Time-like values, can be list/tuple of date values, character strings, integers or date column of a data frame     #
#   |fmt         :   Alternative format to be passed to function [strptime] when the input is a character string                        #
#   |                Re-introduced at v1.4, requiring caller to provide specific format, or spend lots of time during parsing           #
#   |                 [ <list>     ] <Default> Try to match these formats for any input strings, see function definition                #
#   |unit        :   Unit by which to convert the values in the type of [int], [float], [np.integer] or [np.floating]                   #
#   |                See official document of [datetime.timedelta]                                                                      #
#   |                 [ seconds    ] <Default> Also the default unit of SAS time/datetime storage for easy conversion                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<Any>       :   The returned value may be <dt.time | Iterable[dt.time]> depending on the input type                                #
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
#   | Date |    20230902        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Replace <pd.DataFrame.applymap> with <pd.DataFrame.map> as the former is deprecated since pandas==2.1.0                 #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20231016        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Rewrite the function to reduce the time consumption by 90%                                                              #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20231102        | Version | 3.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Improve efficiency when all input values are already of the dedicated type or NATType                                   #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240102        | Version | 3.20        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, numbers, datetime, pandas, inspect, itertools, collections, copy                                                          #
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

    #015. Function local variables
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
    #Quote: { <args of dt.timedelta()> : <units of pd.to_datetime()> }
    map_unit = {
        'days' : 'D'
        ,'seconds' : 's'
        ,'milliseconds' : 'ms'
        ,'microseconds' : 'us'
        ,'nanoseconds' : 'ns'
    }
    if unit in map_unit:
        unit_short = map_unit.get(unit)
        unit_long = unit
    elif unit in map_unit.values():
        unit_short = unit
        unit_long = { v:k for k,v in map_unit.items() }.get(unit)
    else:
        raise ValueError(f'[{LfuncName}][unit][{unit}] is not recognized! Try any among: [{str(map_unit)}]')

    #100. Standardize the formats to be used to try converting the date-like values
    if isinstance(fmt, str):
        fmt_fnl = [fmt]
    elif isinstance(fmt, Iterable):
        fmt_fnl = list(fmt)
    else:
        raise TypeError(f'[{LfuncName}][fmt] must be [str], or [Iterable] of the previous')

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
    vtype_t = vec_types.eq('time')
    if vtype_t.all():
        return(deepcopy(indate))

    vtype_nat = ~vec_types.isin(['datetime','Timestamp','time','str'] + inttypes + floattypes)
    if (vtype_t | vtype_nat).all():
        rstOut = vec_in.copy(deep = True).assign(**{col_eval : lambda x: x[col_eval].astype('object')})
        rstOut.loc[vtype_nat, col_eval] = pd.NaT
        return(h_rst(rstOut, col_eval))

    vtype_dt = vec_types.isin(['datetime','Timestamp'])
    #[ASSUMPTION]
    #[1] <Series.str.startswith()> is 4x slower than <Series.isin()>
    # vtype_int = vec_types.str.startswith('int')
    vtype_int = vec_types.isin(inttypes)
    vtype_float = vec_types.isin(floattypes)
    vtype_str = vec_types.eq('str')

    #500. Convert to the dedicated values for different scenarios
    #510. Convert datetime-like values
    out_dt = vec_in[col_eval].loc[vtype_dt].astype('object').apply(lambda d: d.time())

    #530. Convert integer-like values
    #Quote: https://stackoverflow.com/questions/34501930/how-to-convert-timedelta-to-time-of-day-in-pandas
    out_int = (
        pd.to_datetime(vec_in[col_eval].loc[vtype_int], unit = unit_short)
        .dt.time
    )

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
        .apply(lambda d: dt.datetime(1970,1,1) + dt.timedelta(**{unit_long:int(d)}))
        .add(fl_dec.apply(lambda x: dt.timedelta(**{'microseconds':int(x)})))
        .astype('datetime64[ns]')
        .dt.time
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
            .dt.time
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
            vec_in[col_eval].loc[vtype_t].astype('object')
            ,out_dt
            ,out_int
            ,out_float
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
#End asTimes

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
    from omniPy.Dates import asTimes
    print(asTimes.__doc__)

    #100. Convert a time
    a1 = dt.time()
    a1_rst = asTimes( a1 )

    #200. Convert a datetime
    a2 = dt.datetime.today()
    a2_rst = asTimes( a2 )

    #250. Convert a float value
    float_rst = asTimes( 18981.99483 )

    #300. Convert a string
    a3 = '12:34:56'
    a3_rst = asTimes( a3 )

    #400. Convert a list of dates
    a4 = [ '22 15 01' , a2 ]
    a4_rst = asTimes( a4 )

    #500. Convert a datetime column to date
    df = pd.DataFrame(
        data = pd.date_range( dt.datetime.strptime('20210101','%Y%m%d') , dt.datetime.strptime('20210131','%Y%m%d') )
        , columns = [ 'DT_DATE' ]
    )
    df['d_time'] = asTimes( df['DT_DATE'] )
    df['d_time2'] = df['DT_DATE'].apply(asTimes).astype('object')
    #Quote: https://www.geeksforgeeks.org/display-the-pandas-dataframe-in-table-style/
    df.head()
    df.dtypes

    #600. Test if the data frame has no row
    df2 = df.loc[ df['DT_DATE'] == dt.datetime.today() ]
    df2['d_time'] = asTimes( df2['DT_DATE'] )
    #[IMPORTANT] In below case, make sure to use [astype('object')] to avoid any subsequent problems (conflicting that when the
    #             input data frame is NOT empty)
    df2['d_date2'] = df2['DT_DATE'].apply(asTimes).astype('object')
    df2.dtypes

    #700. Convert the raw values into dates from SAS dataset
    CFG_KPI, meta_kpi = pyr.read_sas7bdat(dir_omniPy + r'omniPy\AdvDB\test_loadsasdat.sas7bdat', encoding = 'GB2312')
    CFG_KPI[['T_TEST']] = CFG_KPI[['T_TEST']].apply(asTimes).astype('object')
    CFG_KPI.head()
    CFG_KPI.dtypes

    #720. Same as above
    CFG_KPI2 = CFG_KPI.copy(deep=True)
    CFG_KPI2[['DT_TEST2','D_TEST2']] = asTimes(CFG_KPI[['DT_TEST','D_TEST']])

    #800. Convert an integer into date, as it represents a [Time: 10:10:10] in SAS
    a5 = 36610
    a5_rst = asTimes( a5 )

    # [CPU] AMD Ryzen 5 5600 6-Core 3.70GHz
    # [RAM] 64GB 2400MHz
    #900. Test timing
    vvv = vecStack([
        '2021-02-16 12:34:56'
        ,'20210101 54:32:01'
        ,19754
        ,dt.date.today()
        ,dt.datetime.now()
        ,np.int64(19854)
        ,pd.Timestamp('2017-01-01T12:34:55')
        ,pd.NaT
        ,''
    ])
    d_smpl = vvv['.val.'].sample(1000000, replace = True).reset_index(drop=True)
    time_bgn = dt.datetime.now()
    df_trns = asTimes(d_smpl, fmt = ['%Y%m%d %H:%M:%S', '%Y-%m-%d %H:%M:%S'])
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # 0:00:00.921938
#-Notes- -End-
'''
