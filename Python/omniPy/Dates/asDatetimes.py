#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import numbers
import datetime as dt
import pandas as pd
import itertools as itt
from collections.abc import Iterable
from omniPy.AdvOp import get_values

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
) -> 'Translate date-like values into datetime in the type of [datetime.datetime]':
    #000.   Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to convert any type of input values into valid datetime (with type as [datetime.datetime])               #
#   |[IMPORTANT] When the input is an empty [pd.Series] or [pd.DataFrame], make sure to use either of below forms to assign the         #
#   |             column(s) in the type of [dt.datetime] to ensure a dedicated result, i.e. below methods create the columns in the     #
#   |             same [dtype] as [object] no matter the input is empty or not:                                                         #
#   |            [1] [pd.Series.apply(asDatetimes).astype('object')] or [pd.DataFrame.applymap(asDatetimes).astype('object')]           #
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
#   |[ list  ]   :   The mapped result stored in a list (not a tuple as a tuple cannot be added as a column in a data frame if needed)  #
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
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |See the [Full Test Program] section                                                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |sys, numbers, datetime, pandas, itertools, collections                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |get_values                                                                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name
    recall = get_values(LfuncName, instance = callable)

    #012. Handle the parameter buffer.
    if indate is None: return()
    if fmt is None: fmt = list(map(
        ''.join
        ,list(itt.product(
            ['%Y%m%d', '%Y-%m-%d', '%Y/%m/%d']
            , [':', ' ', '-']
            , ['%H%M%S', '%H-%M-%S', '%H:%M:%S', '%H %M %S']
        ))
    )) + ['%Y%m%d', '%Y-%m-%d', '%Y/%m/%d']
    if unit is None: unit = 'seconds'

    #100. Standardize the formats to be used to try converting the date-like values
    if isinstance(fmt, str):
        fmt_fnl = [fmt]
    elif isinstance(fmt, Iterable):
        fmt_fnl = list(fmt)
    else:
        raise TypeError('[' + LfuncName + '][fmt] must be [str], or [Iterable] of the previous')

    #200. Conver the [origin] to [dt.datetime] and meanwhile prevent the infinite recursion
    if isinstance(origin, numbers.Number):
        origin = dt.datetime.min + dt.timedelta(**{unit:int(origin)})
    else:
        origin = recall(origin, fmt = fmt_fnl, origin = None)

    #300. Prepare the function to convert a single value as helper
    def trnsdate(d):
        #[IMPORTANT] The verification for [datetime] should be ahead of that for [date], as the latter is [True] on both cases.
        if isinstance(d, dt.datetime):
            return(d)
        elif isinstance(d, dt.date):
            return(dt.datetime.combine(d, dt.time(0,0,0)))
        elif isinstance(d, pd.Timestamp):
            return(dt.to_pydatetime())
        elif isinstance(d, numbers.Number):
            #Quote: https://stackoverflow.com/questions/25141789/remove-dtype-datetime-nat
            if pd.isnull(d): return(pd.NaT)
            #Quote: https://stackoverflow.com/questions/36361849/is-there-an-as-date-equivalent-r-in-python
            #Quote: https://stackoverflow.com/questions/50265288/how-to-work-around-python-pandas-dataframes-out-of-bounds-nanosecond-timestamp
            #Quote: https://pandas.pydata.org/pandas-docs/stable/user_guide/timeseries.html
            return(max(dt.datetime.min, min(dt.datetime.max, origin + dt.timedelta(**{unit:int(d)}))))
        elif isinstance(d, str):
            for f in fmt_fnl:
                try:
                    return(pd.to_datetime(d, errors = 'raise', format = f).to_pydatetime())
                except:
                    continue

            return(pd.NaT)
        else:
            return(pd.NaT)


    #900. Translate the values
    if isinstance(indate, pd.DataFrame):
        #100. Convert the full input
        df_interim = indate.applymap(trnsdate)

        #300. Find all columns of above data that are stored as [datetime64[ns]], i.e. [pd.Timestamp]
        conv_dtcol = [ c for c in df_interim.columns if str(df_interim.dtypes[c]).startswith('datetime') ]

        #500. Convert the storage of above columns into the type of [object]
        #[pd.Series.dt.to_pydatetime()] creates a [list] as output, hence we need to set proper indexes for it
        for c in conv_dtcol:
            df_interim[c] = pd.Series(
                df_interim[c].dt.to_pydatetime()
                ,dtype = 'object'
                ,index = indate.index
            )

        #999. Return the data
        return(df_interim)
    elif isinstance(indate, pd.Series):
        #100. Convert the full input
        srs_interim = indate.apply(trnsdate)

        #500. Convert the storage of this series into the type of [object]
        if str(srs_interim.dtype).startswith('datetime'):
            srs_interim = pd.Series(
                srs_interim.dt.to_pydatetime()
                ,dtype = 'object'
                ,index = indate.index
            )

        #999. Return the data
        return(srs_interim)
    elif isinstance(indate, str):
        return(trnsdate(indate))
    elif isinstance(indate, Iterable):
        return(list(map(trnsdate, indate)))
    else:
        return(trnsdate(indate))
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
    print(asDatetimes.__doc__)

    #100. Convert a date
    a1 = dt.date.today()
    a1_rst = asDatetimes( a1 )

    #200. Convert a datetime
    a2 = dt.datetime.today()
    a2_rst = asDatetimes( a2 )

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

    #900. Test timing
    test_sample = CFG_KPI[['DT_TEST','D_TEST']].copy(deep=True).sample(100000, replace = True)
    time_bgn = dt.datetime.now()
    print(time_bgn)
    df_trns = asDatetimes(test_sample)
    time_end = dt.datetime.now()
    print(time_end)
    print(time_end - time_bgn)
    # 1.33s on average

    #Full speed test
    #Quote: https://ehmatthes.com/blog/faster_than_strptime/
    aaa = CFG_KPI['DT_TEST'].sample(100000, replace = True).apply(lambda x: x.strftime('%Y/%m/%d-%H %M %S'))

    t0 = time.time()
    bbb = asDatetimes(aaa)
    print(time.time() - t0)
    # 257.26s

    t0 = time.time()
    bbb2 = asDatetimes(aaa, fmt = '%Y/%m/%d-%H %M %S')
    print(time.time() - t0)
    # 9.22s

    t0 = time.time()
    bbb3 = pd.to_datetime(aaa)
    print(time.time() - t0)
    # ParserError: Unknown string format

    t0 = time.time()
    bbb3 = pd.to_datetime(aaa, format = '%Y/%m/%d-%H %M %S')
    print(time.time() - t0)
    # 0.012s
#-Notes- -End-
'''
