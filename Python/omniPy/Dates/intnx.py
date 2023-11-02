#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, re
import numbers
import datetime as dt
import pandas as pd
import numpy as np
from copy import deepcopy
from collections.abc import Iterable
#Quote: https://stackoverflow.com/questions/847936/how-can-i-find-the-number-of-arguments-of-a-python-function
from inspect import signature
from omniPy.AdvOp import vecStack, vecUnstack, thisFunction
from omniPy.Dates import asDates, asDatetimes, asTimes, UserCalendar, getDateIntervals, intCalendar

def intnx(
    interval : str
    ,indate
    ,increment : int = 0
    ,alignment : str = 'b'
    ,daytype : str = 'C'
    ,cal : pd.DataFrame = None
    #Quote: https://docs.python.org/3/library/inspect.html#inspect.Parameter.kind
    ,kw_d : dict = { s.name : s.default for s in signature(asDates).parameters.values() if s.name not in ['indate'] }
    ,kw_dt : dict = { s.name : s.default for s in signature(asDatetimes).parameters.values() if s.name not in ['indate'] }
    ,kw_t : dict = { s.name : s.default for s in signature(asTimes).parameters.values() if s.name not in ['indate'] }
    ,kw_cal : dict = {
        s.name : s.default
        for s in signature(UserCalendar).parameters.values()
        if s.name not in ['dateBgn', 'dateEnd', 'clnBgn', 'clnEnd']
    }
) -> 'Increments a date, time, or datetime value by a given time interval, and returns the same type':
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to resemble the same one in SAS to increment a date, time, datetime value, or an Iterable of the         #
#   | previous, by a given time interval                                                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[IMPORTANT]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[01] Although this function supports [e.apply(f,...)] or [map(f,e)] methods to apply to an Iterable, it is strongly recommended    #
#   |      to call it directly by [f(e,...)] as it internally uses Table Join processes to facilitate bulk data massage                 #
#   |[02] Similar to above, it is strongly recommended to pass an existing [User Calendar] to the argument [cal] if one insists to call #
#   |      it by means of [e.apply(f,...)] or [map(f,e)], to minimize the system calculation effort                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[FEATURE]                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[01] Support different types of [indate], i.e. pd.DataFrame, pd.Series, strings indicating dates, dt.date, dt.datetime, dt.time    #
#   |[02] Does not support [.starting-point] in [interval] as that in SAS, as it is useless and ambiguous under most circumstances      #
#   |[03] Support the increment by Calendar Days, Working Days, or Trade Days                                                           #
#   |[04] Returned data type is the same as [indate] if [type(indate)==pd.DataFrame or pd.Series]                                       #
#   |[05] Value type as output is determined by the [interval]                                                                          #
#   |[06] Holidays will be shifted to their respective Previous Work/Trade Days for calculation, given [daytype != C]. Therefore, the   #
#   |      returned value for holidays could be [pd.NaT] if the incremented value is less than 1 day                                    #
#   |[07] [WEEKDAY] as [interval] has different definition to that in SAS, see below definition of [omniPy.Dates.getDateIntervals]      #
#   |[08] [WEEK] starts with Sunday=0 and ends with Saturday=6, to align that in SAS                                                    #
#   |[09] Apply this function to a Public Holiday with [increment==0] and [daytype in [W,T]] will result in [pd.NaT], as its [Previous] #
#   |      work/trade day and [Next] work/trade both result in [0] of incremental to it, which is ambiguous and thus it is removed      #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |interval    :   Character string as a time interval such as WEEK, SEMIYEAR, QTR, or HOUR, case insensitive. It has no default      #
#   |                 value, while the functions raises error if it is NOT provided.                                                    #
#   |                See definition of [omniPy.Dates.getDateIntervals] for accepted values                                              #
#   |indate      :   Date-like values, will be converted by [asDates], [asDatetimes] or [asTimes] as per request                        #
#   |increment   :   An integer to increment the [indate], float value is converted to integer by: int(abs(i)) * np.sign(i)             #
#   |                 [0           ] <Default> Return the same values                                                                   #
#   |                 [<Numeric>   ]           Unify the incremental for all element in [indate]. It will be converted to [int]         #
#   |                 [<Iterable>  ]           Iterable in the same shape as [indate] to differentiate incrementals for each element    #
#   |alignment   :   controls the position of dates/times within the interval, case insensitive                                         #
#   |                 [BEGINNING|B ] <Default> Align the values to the beginning of current interval after the increment                #
#   |                 [MIDDLE   |M ]           Align the values to the mean of beginning and ending of current interval after the       #
#   |                                           increment                                                                               #
#   |                 [END      |E ]           Align the values to the ending of current interval after the increment                   #
#   |                 [SAME     |S ]           Align the values to the same position of current interval after the increment            #
#   |daytype     :   Type of days for the calculation                                                                                   #
#   |                 [C           ] <Default> Calendar Days                                                                            #
#   |                 [W           ]           Working Days                                                                             #
#   |                 [T           ]           Trading Days                                                                             #
#   |cal         :   pd.DataFrame that is usually created by [omniPy.Dates.intCalendar] object as the essential during the calculation  #
#   |                 [<None>      ] <Default> Function calls [intCalendar] with the arguments [**kw_cal]                               #
#   |kw_d        :   Arguments for function [omniPy.Dates.asDates] to convert the [indate] where necessary                              #
#   |                 [<Default>   ] <Default> Use the default arguments for [asDates]                                                  #
#   |kw_dt       :   Arguments for function [omniPy.Dates.asDatetimes] to convert the [indate] where necessary                          #
#   |                 [<Default>   ] <Default> Use the default arguments for [asDatetimes]                                              #
#   |kw_t        :   Arguments for function [omniPy.Dates.asTimes] to convert the [indate] where necessary                              #
#   |                 [<Default>   ] <Default> Use the default arguments for [asTimes]                                                  #
#   |kw_cal      :   Arguments for instantiating the class [omniPy.Dates.UserCalendar] if [cal] is NOT provided                         #
#   |                 [<Default>   ] <Default> Use the default arguments for [UserCalendar]                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<various>   :   The return value depends on the input arguments                                                                    #
#   |                [1] When [indate] is pd.DataFrame or pd.Series, return the same type with [dtypes==object]                         #
#   |                [2] When [indate] is provided a [str], return a [dt] object as indicated by [interval]                             #
#   |                [3] When [indate] is an [Iterable] except [str], return a [list] of elements as indicated by [interval]            #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210814        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210817        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Add new type [dtt] to calculate the incrementals for [datetime] by [dtsecond], [dtminiute] or [dthour], to resemble the #
#   |      |     same function for [datetime] in SAS. See definition in [omniPy.Dates.getDateIntervals]                                 #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210821        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Eliminate all [pd.DataFrame.merge] operations and the most of [.apply] methods to improve the overall efficiency, now   #
#   |      |     use indexing of data frames and the time expense reduced by 90%. Below is the testing result:                          #
#   |      |    [CPU: FX6300 3.5GHz 3 Physical Cores 6 Logical Cores]                                                                   #
#   |      |    [date     ] 1.1s on average for 10K values                                                                              #
#   |      |    [datetime ] 5.7s on average for 10K values                                                                              #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210912        | Version | 4.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Correct the behavior when [interval] indicates [t] if the incremented result is in another day                          #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210919        | Version | 5.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce a function [intCalendar] to create interval-bound calendar for interval-related functions                     #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210922        | Version | 5.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Ensure the datetime conversion is only conducted once during the function call                                          #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210927        | Version | 6.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Re-launch the full calendar so that this function covers all special scenarios for work/trade/week days                 #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20211120        | Version | 6.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug: [multiple] is not implemented when [dtt] is triggered                                                      #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20211204        | Version | 6.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Unify the effect of [col_rowidx] and [col_period] when [span]==1, hence [col_rowidx] is no longer used                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20220214        | Version | 6.30        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug: [intnx('day', '20211231', 1, daytype = 'w')] returns [NaT]. This was due to the calendar span is not set   #
#   |      |     enough for calculation                                                                                                 #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230302        | Version | 7.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] [dt<interval>] now return the same results as the same function does in SAS                                             #
#   |      |[2] Slightly improve the efficiency, use [.mul(-1).floordiv(1).mul(-1)] to resemble [np.ceil] behavior                      #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230610        | Version | 7.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce functions <vecStack> and <vecUnstack> to simplify the program                                                 #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230618        | Version | 7.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed bugs during output for empty input                                                                                #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230815        | Version | 7.30        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce the imitated <recall> to make the recursion more intuitive                                                    #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230819        | Version | 7.40        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Remove <recall> as it always fails to search in RAM when the function is imported in another module                     #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230821        | Version | 7.50        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <thisFunction> to actually find the current callable being called instead of its name                         #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20231102        | Version | 7.60        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Remove dependency on [ObsDates] as it is too slow                                                                       #
#   |      |[2] Reduce time expense by 20% for large dataframe, e.g. 1 million records                                                  #
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
#   |   |sys, re, numbers, datetime, pandas, numpy, copy, collections, inspect                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |vecStack                                                                                                                   #
#   |   |   |vecUnstack                                                                                                                 #
#   |   |   |thisFunction                                                                                                               #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.Dates                                                                                                                   #
#   |   |   |intCalendar                                                                                                                #
#   |   |   |getDateIntervals                                                                                                           #
#   |   |   |asDates                                                                                                                    #
#   |   |   |asDatetimes                                                                                                                #
#   |   |   |asTimes                                                                                                                    #
#   |   |   |UserCalendar                                                                                                               #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name
    recall = thisFunction()

    #012. Handle the parameter buffer
    if isinstance(indate, Iterable):
        if not isinstance(indate, (str, list, tuple, pd.DataFrame, pd.Index, pd.Series, np.ndarray)):
            raise TypeError(f'[{LfuncName}]Iterable type [{type(indate)}] of [indate] is not recognized!')
    if isinstance(increment, Iterable):
        if not isinstance(increment, (str, list, tuple, pd.DataFrame, pd.Index, pd.Series, np.ndarray)):
            raise TypeError(f'[{LfuncName}]Iterable type [{type(increment)}] of [increment] is not recognized!')
    if not isinstance(daytype, str):
        raise ValueError(f'[{LfuncName}][daytype]:[{type(daytype)}] must be character string!')
    daytype = daytype[0].upper()
    if daytype not in ['C','W','T']:
        raise ValueError(f'[{LfuncName}][daytype]:[{daytype}] must be among [C,W,T]!')

    #015. Function local variables
    intnx_flags = re.I
    col_rowidx : str = '_ical_row_'
    col_period : str = '_ical_prd_'
    col_prdidx : str = '_ical_rprd_'
    col_weekday : str = '_ical_wday_'
    col_keys : str = '_intnxRec_'
    col_calc : str = '_intnxCol_'
    col_idxcol : str = '_intnxKCol_'
    col_idxrow : str = '_intnxKRow_'
    map_stack : dict = {
        'idRow' : col_idxrow
        ,'idCol' : col_idxcol
    }
    if isinstance(indate, pd.Index):
        in_shape = (indate.size, indate.nlevels)
    elif isinstance(indate, (pd.DataFrame, pd.Series, np.ndarray)):
        in_shape = indate.shape
        if len(in_shape) == 1:
            in_shape += (1,)
    elif isinstance(indate, Iterable) and (not isinstance(indate, str)):
        #We do not verify the dimensions of such object, which may lead to unexpected result
        in_shape = (len(indate),1)
    elif indate is None:
        #<NoneType> has the size of 1, whic means its dimension is as below:
        in_shape = (0,1)
    else:
        in_shape = (1,1)

    if isinstance(increment, pd.Index):
        incr_shape = (increment.size, increment.nlevels)
    elif isinstance(increment, (pd.DataFrame, pd.Series, np.ndarray)):
        incr_shape = increment.shape
        if len(incr_shape) == 1:
            incr_shape += (1,)
    elif isinstance(increment, numbers.Number):
        incr_shape = (1,1)
    elif isinstance(increment, Iterable) and (not isinstance(increment, str)):
        #We do not verify the dimensions of such object, which may lead to unexpected result
        incr_shape = (len(increment),1)
    elif increment is None:
        incr_shape = (0,1)
    else:
        incr_shape = (1,1)

    #019. Directly return for empty input
    if (in_shape[0] == 0) | (in_shape[-1] == 0):
        if isinstance(indate, (pd.DataFrame, pd.Series, pd.Index, np.ndarray)):
            rstOut = deepcopy(indate).astype('object')
            return(rstOut)
        elif isinstance(indate, Iterable):
            #<str> is not covered here, as empty string has shape (1,1) and thus is handled at main process
            return(deepcopy(indate))
        else:
            return(None)

    if increment is None:
        raise TypeError(
            f'[{LfuncName}][increment]:[{type(increment)}] must be of the same type as'
            + f' [indate]:[{type(indate)}], or a scalar integer!'
        )

    #020. Remove possible items that conflict the internal usage from the [kw_cal]
    kw_cal_fnl = deepcopy(kw_cal)
    kw_pop = [ k for k in kw_cal_fnl if k in ['dateBgn', 'dateEnd', 'clnBgn', 'clnEnd'] ]
    for k in kw_pop:
        kw_cal_fnl.pop(k)

    #030. Helper functions
    #031. Combine [date] and [time] parts into [datetime]
    def dt_combine(x,y):
        if pd.isnull(x) or pd.isnull(y):
            return(pd.NaT)
        else:
            return(dt.datetime.combine(x,y))

    #032. Vectorize the function to facilitate element-wise calculation between matrices
    v_dt_combine = np.vectorize(dt_combine)

    #035. Convert increment into integer
    def _convIncr(x):
        return( np.floor(np.abs(x)) * np.sign(x) )

    #037. Helper function to process the unstacked data before type conversion
    def h_dtype(df):
        #100. Find all columns of above data that are stored as [datetime64[ns]], i.e. [pd.Timestamp]
        conv_dtcol = (
            df.dtypes
            .apply(str)
            .loc[lambda x: x.str.startswith('datetime')]
            .reset_index(drop = True)
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

    #039. Return the result in the same shape as input
    def h_rst(rst, col):
        #500. Unstack the underlying data to the same shape as the input one
        #[ASSUMPTION]
        #[1] <col-id> and <row-id> do not have <NA> values
        #[2] There can only be <NA> values in the <col>
        #[3] Hence we have to convert them to <NaT> as output
        rstOut = vecUnstack(rst, valName = col, modelObj = indate, funcConv = h_dtype, **map_stack)

        #999. Purge
        return(rstOut)
    #End [h_rst]

    #050. Local parameters
    #053. Date and time intervals
    dict_dates = {
        'd' : {
            'func' : asDates
            ,'kw' : kw_d
        }
        ,'dt' : {
            'func' : asDatetimes
            ,'kw' : kw_dt
        }
        ,'t' : {
            'func' : asTimes
            ,'kw' : kw_t
        }
        ,'dtt' : {
            'func' : asDatetimes
            ,'kw' : kw_dt
        }
    }

    #055. Validate the input calendar
    vfy_cal = False
    if isinstance(cal, pd.DataFrame):
        if len(cal):
            vfy_cal = True

    #056. Dictionary for [alignment]
    dict_align = {
        'b' : 'beginning'
        ,'m' : 'middle'
        ,'e' : 'end'
        ,'s' : 'same'
    }

    #057. Column names for different request types for dates
    dict_adjcol : dict = {
        'W' : 'F_WORKDAY'
        ,'T' : 'F_TradeDay'
    }

    #060. Get the attributes for the requested time interval
    #The result of below function is [dict], while current input has only one element, hence we use the first among the result
    dict_attr = getDateIntervals(interval)[0]

    #070. Standardize the [alignment]
    #071. Combine all patterns into one, using [|] to minimize the system effort during matching
    str_align_match = '|'.join( [ i for i in dict_align.keys() ] + [ i for i in dict_align.values() ] )
    ptn_align_match = re.compile(str_align_match, intnx_flags)

    #078. Conduct substitution
    ptn_align_matchobj = ptn_align_match.fullmatch(alignment)
    if ptn_align_matchobj:
        for k,v in dict_align.items():
            #[matchobj[1]] represents the first capture group in the match object
            if re.fullmatch(k + '|' + v, ptn_align_matchobj[0], flags = intnx_flags):
                dict_attr.update({ 'alignment' : k })
    else:
        raise ValueError(
            f'[{LfuncName}][alignment]:[{str(alignment)}] is not accepted!'
            + '\n' + f'Valid alignments should match the pattern: {str_align_match}'
        )

    #080. Define interim column names for call of helper functions
    if dict_attr['itype'] in ['d', 'dt']:
        col_merge : str = '_intnxDate_'
        col_out : str = 'D_DATE'
    else:
        col_merge : str = '_intnxTime_'
        col_out : str = 'T_TIME'

    #100. Standardize input data
    #101. Verify the input values
    if (in_shape != incr_shape) and (incr_shape != (1,1)):
        raise ValueError(
            f'[{LfuncName}][indate]:[{str(in_shape)}] must be of the same shape as'
            + f' [increment]:[{str(incr_shape)}]!'
        )
    elif isinstance(increment, (pd.DataFrame, pd.Series)):
        if isinstance(indate, (pd.DataFrame, pd.Series)):
            if not indate.index.equals(increment.index):
                raise ValueError(
                    f'[{LfuncName}][indate] must have the same index as [increment]'
                )

    #110. Transform [indate]
    df_indate = (
        vecStack(indate, valName = col_calc, **map_stack)
        .assign(**{
            col_keys : lambda x: range(len(x))
            ,col_calc : lambda x: dict_dates[dict_attr['itype']]['func'](
                x[col_calc]
                ,**dict_dates[dict_attr['itype']]['kw']
            )
        })
    )

    #120. Transform [increment]
    if isinstance(increment, numbers.Number):
        l_incr = _convIncr(increment)
    else:
        l_incr = (
            vecStack(increment, valName = '_intnxIncr_', **map_stack)
            .assign(**{
                '_intnxIncr_' : lambda x: _convIncr(x['_intnxIncr_']).astype('int')
            })
            ['_intnxIncr_']
        )

        if incr_shape == (1,1):
            l_incr = int(l_incr.iat[0])

    #Till this step, [l_incr] can only be instance of either [pd.Series] or [np.int]
    if isinstance(l_incr, numbers.Number):
        l_cal_imin = l_incr
        l_cal_imax = l_incr
    else:
        l_cal_imin = l_incr.min()
        l_cal_imax = l_incr.max()

    l_cal_imin = 0 if pd.isnull(l_cal_imin) else min(0, l_cal_imin)
    l_cal_imax = 0 if pd.isnull(l_cal_imax) else max(0, l_cal_imax)

    #150. Calculate the incremental for [datetime] when [type] in [dt(second|minute|hour)] by calling this function in recursion
    #Till this step [indate] and [increment] have already been standardized
    if dict_attr['itype'] in ['dtt']:
        #100. Convert the incremental into [number of seconds] and set it as the same shape as [indate]
        dtt_incr = l_incr * dict_attr['multiple'] * dict_attr['span']

        #200. Convert the [time] part of the input data
        dtt_indat_sec = df_indate[col_calc].apply( lambda x: x.hour * 3600 + x.minute * 60 + x.second )

        #400. Calculate the arithmetical increment and determine the increment for [date] and [time] part respectively
        #[IMPORTANT] Calculation at this step is element-wise, which supports different increments for different datetime values
        #410. Overall incremental
        dtt_incr = dtt_indat_sec + dtt_incr

        #450. Set the [floor division] of above incremental over 86400 (total number of seconds in a day) as that of [date] part
        dtt_incr_date = dtt_incr.floordiv(86400)

        #600. Conduct the calculation for [date] and [time] parts respectively
        #610. Retrieve the parts as [pd.Series] for simplification
        dtt_indate = df_indate[col_calc].apply( lambda x: x.date() )
        dtt_indate.name = '_dtt_date_'
        #[ASSUMPTION]
        #[1] Any incremental upon <NULL> date is invalid, we ensure the <increment> for them is a valid integer to avoid
        #     type conversion error, since it will not impact the <NULL> result
        dtt_incr_date.loc[dtt_indate.isnull()] = 0

        #630. Increment by [day]
        dtt_rst_date = recall(
            interval = 'day'
            ,indate = dtt_indate
            ,increment = dtt_incr_date
            #[alignment] is useless for [interval == 'day']
            ,alignment = dict_attr['alignment']
            ,daytype = daytype
            ,cal = cal
            ,kw_d = kw_d
            ,kw_dt = kw_dt
            ,kw_t = kw_t
            ,kw_cal = kw_cal
        )

        #650. Increment by different scenarios of [time]
        dtt_ntvl = re.sub(r'^dt', '', interval)
        dtt_rst_time = recall(
            interval = dtt_ntvl
            ,indate = df_indate[col_calc]
            ,increment = l_incr
            ,alignment = dict_attr['alignment']
            ,daytype = daytype
            ,cal = cal
            ,kw_d = kw_d
            ,kw_dt = kw_dt
            ,kw_t = kw_t
            ,kw_cal = kw_cal
        )

        #700. Correction on incremental for [Work/Trade Days]
        if daytype in ['W', 'T']:
            #100. Verify whether the input values are [Work/Trade Days]
            #110. Instantiate the observed calendar
            vld_dates = dtt_indate.loc[lambda x: x.notnull()]
            dtt_obs = UserCalendar(
                clnBgn = vld_dates.min()
                ,clnEnd = vld_dates.max()
                ,**kw_cal_fnl
            )

            #150. Retrieve the flag in reversed value
            dtt_flag = ~(
                dtt_obs.usrCalendar
                .set_index('D_DATE')
                .reindex(dtt_indate)
                .set_index(dtt_indate.index)
                [dict_adjcol.get(daytype)]
                .fillna(False)
            )

            #500. Correction by below conditions
            #[1] Incremental is 0 (other cases are handled in other steps)
            #[2] The input date is Public Holiday
            #510. Mark the records with both of below conditions
            dtt_mask_zero = dtt_flag & dtt_incr_date.eq(0)

            #590. Set the above records as [pd.NaT] for good reason
            dtt_rst_date.loc[dtt_mask_zero] = pd.NaT

            #700. Correction by below conditions
            #[1] Incremental is below 0
            #710. Mark the records with above conditions
            dtt_mask_neg = dtt_flag & dtt_incr_date.lt(0)

            #590. Set the above records as [pd.NaT] for good reason
            dtt_rst_date.loc[dtt_mask_neg] += dt.timedelta(days = 1)

        #800. Combine the parts into [datetime]
        #810. Convert both parts into [np.array] for element-wise combination at later step
        dtt_arr_date = np.array(dtt_rst_date)
        dtt_arr_time = np.array(dtt_rst_time)

        #890. Combine both parts into [datetime]
        dtt_rst = df_indate[[col_idxrow, col_idxcol]].copy(deep = True)
        #It is 100 times faster than using [pd.Series.combine]!
        dtt_rst[col_out] = pd.Series(v_dt_combine(dtt_arr_date, dtt_arr_time), dtype = 'object', index = dtt_rst.index)

        #990. Reshape the result
        return(h_rst(dtt_rst, col_out))

    #200. Prepare necessary columns
    #220. Unanimous columns
    if dict_attr['itype'] in ['t']:
        dt_today = dt.date.today()
        df_indate[col_calc] = (
            df_indate[col_calc]
            .astype('object')
            .apply(lambda x: dt.datetime.combine(dt_today, x) if pd.notnull(x) else pd.NaT)
        )

    df_indate['_intnxIncr_'] = l_incr

    #230. Create [col_merge] as well as the bounds of the calendar
    #Quote: [0.11s] for 10K records
    if dict_attr['itype'] in ['d', 'dt']:
        #100. Create new column
        if dict_attr['itype'] in ['d']:
            df_indate[col_merge] = df_indate[col_calc]
        else:
            df_indate[col_merge] = df_indate[col_calc].apply(lambda x: x.date())
#        sys._getframe(1).f_globals.update({ 'vfy_df' : df_indate })

        #500. Define the bound of the calendar
        notnull_indate = df_indate[col_merge].notnull()
        if not notnull_indate.any():
            #100. Assign the minimum size of calendar data if none of the input is a valid date
            cal_bgn = dt.date.today()
            cal_end = cal_bgn
        else:
            #100. Retrieve the minimum and maximum values among the input values
            in_min = df_indate[col_merge].loc[notnull_indate].min(skipna = True)
            in_max = df_indate[col_merge].loc[notnull_indate].max(skipna = True)

            #500. Extend the period coverage by the provided span and multiple
            #For [pandas == 1.2.1],the method [pd.Series.min(skipna = True)] cannot ignore [pd.NaT]
            cal_bgn = (
                in_min.replace(year = in_min.year - 1, month = 1, day = 1)
                + dt.timedelta(days = l_cal_imin * dict_attr['multiple'] * dict_attr['span'])
            )
            cal_end = (
                in_max.replace(year = in_max.year + 1, month = 12, day = 31)
                + dt.timedelta(days = l_cal_imax * dict_attr['multiple'] * dict_attr['span'])
            )

            #800. Ensure the period cover the minimum and maximum of the input values
            cal_bgn = min(cal_bgn, in_min)
            cal_end = max(cal_end, in_max)
    else:
        #100. Create new column
        df_indate[col_merge] = df_indate[col_calc].dt.floor('S', ambiguous = 'NaT')

        #500. Define the bound of the calendar
        #[ASSUMPTION]
        #[1] Only for calculation on [time], all numbers are recycled in one day
        cal_bgn = dt.datetime.combine(dt.date.today(), dt.time(0,0,0))
        notnull_indate = df_indate[col_merge].notnull()
        if not notnull_indate.any():
            #100. Assign the minimum size of calendar data if none of the input is a valid date
            cal_end = cal_bgn
        else:
            cal_end = dt.datetime.combine(dt.date.today(), dt.time(23,59,59))

    #250. [time] part for [type == dt]
    if dict_attr['itype'] in ['dt']:
        df_indate['_intnx_dttime_'] = df_indate[col_calc].apply(lambda x: pd.NaT if pd.isnull(x) else x.time())

    #300. Prepare calendar data
    if not vfy_cal:
        intnx_calfull = intCalendar(
            interval = dict_attr
            ,cal_bgn = cal_bgn
            ,cal_end = cal_end
            ,daytype = daytype
            ,col_rowidx = col_rowidx
            ,col_period = col_period
            ,col_prdidx = col_prdidx
            ,kw_cal = kw_cal_fnl
        )
    else:
        intnx_calfull = cal.copy(deep=True).sort_values(col_out).reset_index(drop = True)

    #500. Define helper functions to calculate the incremental for different scenarios
    def h_intnx(cal_in, cal_full, multiple, alignment):
        #100. Create a copy of the input data
        rst = cal_in.copy(deep=True)

        #500. Calculate the incremented [col_period]
        rst['_gti_newprd_'] = rst[col_period].add(rst['_intnxIncr_'].mul(multiple))

        #510. Handle the scenario when the calculation is over [time], i.e. recycle the periods to minimize system effort
        if dict_attr['itype'] in ['t']:
            rst.loc[:, '_gti_newprd_'] = rst.loc[:, '_gti_newprd_'].mod(dict_attr['recycle'])

        #700. Calculate the alignment based on the request
        if dict_attr['span'] == 1:
            rst.loc[:, col_out] = (
                cal_full
                .set_index(col_period)
                .reindex(rst['_gti_newprd_'])
                .set_axis(rst.index, axis = 0)
                [col_out]
            )
        elif alignment == 'b':
            #100. Identify the beginning of each period
            prd_bgn = (
                cal_full
                #[pandas == 1.2.1]It is weird that the index will start from 0 if [as_index = True] instead of the value of [col_period]
                .groupby(col_period, as_index = False)
                .head(1)
                .set_index(col_period)
                [col_out]
            )

            #900. Add the special series to the result as a new column
            #Quote[#5]: https://stackoverflow.com/questions/61291741/
            #Quote: https://pandas.pydata.org/pandas-docs/stable/user_guide/indexing.html#reindexing
            #Passing list-likes to .loc or [] with any missing labels is no longer supported.
            rst.loc[:, col_out] = (
                prd_bgn
                .reindex(rst['_gti_newprd_'])
                .set_axis(rst.index, axis = 0)
            )
            # sys._getframe(3).f_globals.update({ 'vfy_rst' : rst, 'vfg_cal' : prd_bgn })
        elif alignment == 'e':
            #100. Identify the ending of each period
            prd_end = (
                cal_full
                .groupby(col_period, as_index = False)
                .tail(1)
                .set_index(col_period)
                [col_out]
            )

            #900. Add the special series to the result as a new column
            rst.loc[:, col_out] = (
                prd_end
                .reindex(rst['_gti_newprd_'])
                .set_axis(rst.index, axis = 0)
            )
        elif alignment == 's':
            #100. Identify the ending of each period and only retrieve the relative index of its unit
            #This is because we only have to compare its index to the one we calculated
            prd_end = (
                cal_full
                .groupby(col_period, as_index = False)
                .tail(1)
                .set_index(col_period)
                .reindex(rst['_gti_newprd_'])
                .set_axis(rst.index, axis = 0)
                [col_prdidx]
            )

            #500. Add the special series to the result as a new column
            rst['_gti_tmprow_'] = prd_end

            #700. Identify the same relative index in the same period of interval, or the one at period end if it exceeds the span
            #e.g. shift [Mar31] back to the [same] day in [Feb] will result to [Feb28] in a year or [Feb29] in a leap year
            #Quote [#133]: https://stackoverflow.com/questions/33975128/pandas-get-the-row-wise-minimum-value-of-two-or-more-columns
            rst[col_prdidx] = rst[[col_prdidx,'_gti_tmprow_']].min(axis=1)

            #900. Retrieve the row at the same index of the period of interval
            #Quote: https://stackoverflow.com/questions/53286882/how-to-reindex-a-multiindex-dataframe
            rst.loc[:, col_out] = (
                cal_full
                .set_index([col_period, col_prdidx])
                .reindex(rst.set_index(['_gti_newprd_', col_prdidx]).index)
                .set_axis(rst.index, axis = 0)
                [col_out]
            )
#            sys._getframe(2).f_globals.update({ 'vfy_rst' : rst })
#            sys._getframe(2).f_globals.update({ 'vfy_cal' : cal_full })
#            print(rst[[col_merge, '_gti_newprd_', col_prdidx]])
        else:
            #100. Count the units covered by each period of interval and identify the middle one
            #[1] Esp. for [month] as interval, we align the function in SAS by setting the [middle] of Feb as 14th
            prd_mid = cal_full[[col_period]].drop_duplicates().copy(deep=True).set_index(col_period)
            prd_mid.loc[:, col_prdidx] = (
                cal_full[[col_period, col_prdidx]]
                .groupby(col_period)
                .agg({ col_prdidx : 'count' })
                [col_prdidx]
                #Resemble the behavior of [np.ceil] while eliminate the usage of [series.apply]
                # .apply( lambda x: int(np.ceil(x / 2)) )
                .div(2).mul(-1).floordiv(1).mul(-1).astype(int)
                .set_axis(prd_mid.index, axis = 0)
            )
#            sys._getframe(2).f_globals.update({ 'vfy_mid' : prd_mid })

            #400. Correct above index as [second] starts from [0], while others starts from [1]
            if dict_attr['itype'] in ['t']:
                #To resemble the same result as in SAS, we no longer need to conduct such process
                pass
                # prd_mid.loc[:, col_prdidx] += 1

            #500. Add the special series to the result as a new column
            rst.loc[:, col_prdidx] = (
                prd_mid
                .reindex(rst['_gti_newprd_'])
                .set_axis(rst.index, axis = 0)
            )

            #900. Retrieve the row at the middle of the period of interval
            rst.loc[:, col_out] = (
                cal_full
                .set_index([col_period, col_prdidx])
                .reindex(rst.set_index(['_gti_newprd_', col_prdidx]).index)
                .set_axis(rst.index, axis = 0)
                [col_out]
            )

        #999. Return the result
        return(rst[[col_keys, col_out]])
    #End h_intnx

    #700. Prepare the calendar
    #710. Copy the full calendar
    intnx_cal = intnx_calfull.copy(deep=True)

    #730. Only retrieve valid days when necessary
    if dict_attr['itype'] in ['d', 'dt']:
        #100. Only retrieve work/trade days when necessary
        if daytype in ['W', 'T']:
            intnx_cal = intnx_cal[intnx_cal[dict_adjcol[daytype]]].copy(deep=True)

        #300. Only retrieve weekdays when necessary
        if dict_attr['name'] in ['weekday', 'dtweekday']:
            intnx_cal = intnx_cal[intnx_cal[col_weekday]].copy(deep=True)

    #800. Calculate the incremental
    #810. Create a subset of the requested data
    df_cal_in = df_indate[[col_keys, col_merge, '_intnxIncr_']].copy(deep=True)
#    sys._getframe(1).f_globals.update({ 'vfy_dat' : df_cal_in })
#    sys._getframe(1).f_globals.update({ 'vfy_cal' : intnx_cal.copy(deep=True) })

    #820. Retrieve the corresponding columns from the calendar for non-empty dates
    #[IMPORTANT] We keep all the calendar days at this step, to match the holidays
    #Quote: [0.04s] for 10K records
    df_cal_in[[col_period,col_prdidx]] = (
        intnx_calfull
        .set_index(col_out)
        .reindex(df_cal_in[col_merge])
        .set_axis(df_cal_in.index, axis = 0)
        [[col_period,col_prdidx]]
    )
#    sys._getframe(1).f_globals.update({ 'vfy_dat' : df_cal_in.copy(deep=True) })

    #830. Calculation
    #Quote: [0.06s] for 10K records
    df_incr = h_intnx(
        df_cal_in
        ,intnx_cal
        ,dict_attr['multiple']
        ,dict_attr['alignment']
    )
    # sys._getframe(2).f_globals.update({ 'vfy_cal_in' : df_cal_in.copy(deep=True) })

    #850. Merge the incremental back to the input data for later transformation
    col_dt = [col_keys, col_idxrow, col_idxcol]
    if dict_attr['itype'] in ['dt']:
        col_dt += ['_intnx_dttime_']
    df_rst = df_indate[col_dt].copy(deep=True)

    #[IMPORTANT] Till now the indexes of both data are exactly the same
    df_rst[col_out] = df_incr[col_out]

    #870. Handle [dt] and [t] respectively
    if dict_attr['itype'] in ['dt']:
        #Append the [time] part to the result for [type == dt]
        #810. Convert both parts into [np.array] for element-wise combination at later step
        arr_date = np.array(df_rst[col_out])
        arr_time = np.array(df_rst['_intnx_dttime_'])

        #890. Combine both parts into [datetime]
        df_rst[col_out] = pd.Series(v_dt_combine(arr_date, arr_time), dtype = 'object', index = df_rst.index)
    elif dict_attr['itype'] in ['t']:
        df_rst[col_out] = df_rst[col_out].dt.time

    # sys._getframe(2).f_globals.update({ 'vfy_rst' : df_rst.copy(deep = True) })

    #990. Return
    return(h_rst(df_rst, col_out))
#End intnx

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import datetime as dt
    import sys, os
    import pandas as pd
    import numpy as np
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )

    from omniPy.AdvOp import exec_file
    from omniPy.Dates import intnx
    from omniPy.Dates import asDates, asDatetimes, asTimes, ObsDates, intck

    #050. Load user defined functions
    #[getOption] is from [autoexec.py]
    exec_file( os.path.join(dir_omniPy , r'autoexec.py') )

    #100. Create dates for test
    dt1 = dt.date.today()
    dt2 = asDates( [dt1, '20190412', '20200925'] )
    dt3 = pd.Series( dt2, dtype = 'object' )
    dt3.set_axis(pd.Index([1,3,5]), axis = 0, copy = False)
    dt4 = pd.DataFrame({ 'aa' : dt3 })
    dt4.set_index(pd.Index([1,3,5]), inplace = True)
    dt4['bb'] = asDates(pd.Series([ '20181005', '20200214', '20210331' ], dtype = 'object', index = dt4.index))
    dt5 = pd.DataFrame({ 'aa' : dt3 })
    dt5.set_index(pd.Index([1,3,5]), inplace = True)
    dt5['bb'] = asDates(pd.Series([ '20181122', '20200214', pd.NaT ], dtype = 'object', index = dt5.index))
    dt6 = dt.datetime.today()
    dt7 = asDatetimes( [dt6, '20190512 10:12:23', '20200925 17:34:27'] )
    dt8 = pd.DataFrame({ 'a' : pd.Series( dt7, dtype = 'object' ) })
    dt8['b'] = asDatetimes(pd.Series([ '20181122 05:36:34', '20200214 18:06:38', '' ], dtype = 'object', index = dt8.index))
    dt9 = dt.time(8,25,40)

    t_now = dt.datetime.now()
    t_end = dt.datetime.combine(ObsDates(t_now).nextWorkDay[0], asTimes('05:00:00'))

    #200. Shift the values
    dt1_intnx1 = intnx('day', dt1, -2, daytype = 'w')
    dt2_intnx1 = intnx('day', dt2, -2, daytype = 'w')
    dt2_intnx2 = intnx('day', dt2, -2, daytype = 'c')
    dt3_intnx1 = intnx('week2', dt3, 2, 'b', daytype = 't')

    #210. Same month in the previous year, aligning to its Last Working Day
    dt4_intnx1 = intnx('month', dt4, -12, 'e', daytype = 'w')

    #215. Test if the index of the output is the same as the input (or whether the output can be assigned to the same data)
    dt4_copy = dt4.copy(deep=True)
    dt4_copy[['aa1','bb1']] = intnx('month', dt4, -12, 'e', daytype = 'w')

    #220. Same month in the previous year, aligning to its Last Calendar Day
    dt4_intnx2 = intnx('month', dt4, -12, 'e', daytype = 'c')

    #250. With invalid input values
    dt5_intnx1 = intnx('qtr', dt5, 2, 'b', daytype = 't')

    #260. Test the multiple on [dtt]
    diff_min5 = intck('dtsecond300', t_now, t_end)
    t_chk = intnx('dtsecond300', t_now, diff_min5)

    #270. Test multiple increments
    df_incr = pd.DataFrame(
        np.array(range(6)).reshape(3,2)
        ,index = dt4.index
        ,columns = dt4.columns
    )
    dt4_intnx3 = intnx('day', dt4, df_incr, 'e', daytype = 't')

    #300. Test datetime values
    dt6_intnx1 = intnx('dtday', dt6, -2, daytype = 'w')
    dt6_intnx2 = intnx('dthour', dt6, -20, daytype = 'w')

    #310. Test datetime list
    dt7_intnx1 = intnx('dtday', dt7, -2, daytype = 'w')
    dt7_intnx2 = intnx('dtminute', dt7, 600, daytype = 'w')
    dt8_intnx1 = intnx('dthour', dt8, -6, daytype = 't')
    dt8_intnx2 = intnx('dthour', dt8, -6, 's', daytype = 't')

    #400. Test time values
    dt9_intnx1 = intnx('hour2', dt9, 3, 's')
    dt9_intnx2 = intnx('hour2', dt9, 3, 'm')

    #500. Test special dates
    dt10_intnx1 = intnx('month', '20210731', 0, 'e', daytype = 'w')
    dt10_intnx2 = intnx('month', '20210801', 0, 'b', daytype = 'w')
    dt10_intnx3 = intnx('week', '20211002', 0, 'b', daytype = 't')
    dt10_intnx4 = intnx('day', '20211002', 0, daytype = 'w')
    dt10_intnx5 = intnx('week', '20211003', 0, 'b', daytype = 't')
    dt10_intnx6 = intnx('month', '20210925', 0, 's', daytype = 'w')
    dt10_intnx7 = intnx('weekday', '20211008', -1, daytype = 't')
    dt10_intnx8 = intnx('weekday', '20211008', 1, daytype = 't')
    dt11_intnx1 = intnx('dthour', '20210926 23:42:15', -30, 's', daytype = 't')
    dt11_intnx2 = intnx('dthour', '20210925 23:42:15', 6, 's', daytype = 't')
    dt11_intnx3 = intnx('dthour', '20210926 23:42:15', -6, 's', daytype = 't')

    # [CPU] AMD Ryzen 5 5600 6-Core 3.70GHz
    # [RAM] 64GB 2400MHz
    #700. Test the timing of 2 * 100K dates
    df_ttt = dt4.copy(deep=True).sample(100000, replace = True)

    time_bgn = dt.datetime.now()
    df_trns = intnx('month', df_ttt, -12, 'e', daytype = 'w')
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # 0:00:00.301172

    #800. Test the timing  of 2 * 100K datetimes
    df_ttt8 = dt8.copy(deep=True).sample(100000, replace = True)

    time_bgn = dt.datetime.now()
    df_trns8 = intnx('dthour', df_ttt8, 12, 's', daytype = 'w')
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # 0:00:01.712767

    time_bgn = dt.datetime.now()
    df_trns8_1 = intnx('dthour', df_ttt8, 12, 'm', daytype = 'w')
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # 0:00:01.688032

    #900. Test special cases
    #910. [None] vs [None]
    print(intnx('dthour', None, None, daytype = 'w'))
    #Return: None

    #915. [None] vs [int]
    print(intnx('day2', None, 1, daytype = 'w'))
    #Return: None

    #915. [date] vs [np.nan]
    print(intnx('day2', dt1, np.nan, daytype = 'w'))
    #Return: pd.NaT

    #930. Empty series
    emp1 = dt3.loc[dt3.index.isin([''])].copy(deep=True)
    print(intnx('day', emp1, 2, daytype = 'w'))
    #Return: the same type as the [indate] with no element

    #940. Empty data frames
    emp3 = dt5.loc[dt5.index.isin(['']), :].copy(deep=True)
    print(intnx('week', emp3, 1, daytype = 't'))
    #Return: the same type as the [indate] with no element

    emp4 = dt5.loc[:, dt5.columns.isin([''])].copy(deep=True)
    print(intnx('week', emp4, 1, daytype = 't'))
    #Return: the same type as the [indate] with no element

    #990. Test error cases
    if False:
        #100. [date] vs [None]
        print(intnx('day2', dt1, None, daytype = 'w'))
        #Error: different types
#-Notes- -End-
'''
