#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import numbers
import datetime as dt
import pandas as pd
import itertools as itt
from collections.abc import Iterable

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
) -> 'Translate time-like values into [datetime.time]':
    #000.   Info.
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
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Handle the parameter buffer.
    if indate is None: return()
    if fmt is None: fmt = list(map(
        ''.join
        ,list(itt.product(
            ['%Y%m%d', '%Y-%m-%d', '%Y/%m/%d']
            , [':', ' ', '-']
            , ['%H%M%S', '%H-%M-%S', '%H:%M:%S', '%H %M %S']
        ))
    )) + ['%H%M%S', '%H-%M-%S', '%H:%M:%S', '%H %M %S']
    if unit is None: unit = 'seconds'

    #100. Standardize the formats to be used to try converting the date-like values
    if isinstance(fmt, str):
        fmt_fnl = [fmt]
    elif isinstance(fmt, Iterable):
        fmt_fnl = list(fmt)
    else:
        raise TypeError('[' + LfuncName + '][fmt] must be [str], or [Iterable] of the previous')

    #300. Prepare the function to convert a single value as helper
    def trnsdate(d):
        if pd.isnull(d):
            return(pd.NaT)
        #[IMPORTANT] The verification for [datetime] should be ahead of that for [date], as the latter is [True] on both cases.
        if isinstance(d, (dt.datetime, pd.Timestamp)):
            return(d.time())
        elif isinstance(d, dt.time):
            return(d)
        elif isinstance(d, numbers.Number):
            #Quote: https://stackoverflow.com/questions/25141789/remove-dtype-datetime-nat
            if pd.isnull(d): return(pd.NaT)
            dt_anchor = dt.datetime.combine(dt.date.today(), dt.time(0,0,0))
            return((dt_anchor + dt.timedelta(**{unit:int(d)})).time())
        elif isinstance(d, str):
            for f in fmt_fnl:
                try:
                    rst = pd.to_datetime(d, errors = 'raise', format = f).to_pydatetime()
                    if pd.notnull(rst): rst = rst.time()
                    return(rst)
                except:
                    continue

            return(pd.NaT)
        else:
            return(pd.NaT)


    #900. Translate the values
    if isinstance(indate, pd.DataFrame):
        return(indate.map(trnsdate).astype('object'))
    elif isinstance(indate, pd.Series):
        return(indate.apply(trnsdate).astype('object'))
    elif isinstance(indate, str):
        return(trnsdate(indate))
    elif isinstance(indate, Iterable):
        return(list(map(trnsdate, indate)))
    else:
        return(trnsdate(indate))
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

    #900. Test timing
    test_sample = CFG_KPI[['DT_TEST','T_TEST']].copy(deep=True).sample(100000, replace = True)
    time_bgn = dt.datetime.now()
    print(time_bgn)
    df_trns = asTimes(test_sample)
    time_end = dt.datetime.now()
    print(time_end)
    print(time_end - time_bgn)
    # 0.9s on average
#-Notes- -End-
'''
