#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, re
import datetime as dt
import pandas as pd
import numpy as np
from copy import deepcopy
from collections.abc import Iterable
#Quote: https://stackoverflow.com/questions/847936/how-can-i-find-the-number-of-arguments-of-a-python-function
from inspect import signature
from itertools import repeat
from omniPy.AdvOp import vecStack, vecUnstack, get_values
from omniPy.Dates import asDates, asDatetimes, asTimes, UserCalendar, ObsDates, getDateIntervals, intCalendar

def intck(
    interval : str
    ,date_bgn
    ,date_end
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
) -> 'Calculates the number of interval periods between a date, time, or datetime value to another':
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to resemble the same one in SAS to return the number of interval boundaries of a given kind that lie     #
#   | between two dates, times, or datetime values                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[IMPORTANT]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[01] Although this function supports [e.apply(f,...)] or [map(f,e)] methods to apply to an Iterable, it is strongly recommended    #
#   |      to call it directly by [f(e,...)] as it internally uses Table Join processes to facilitate bulk data massage                 #
#   |[02] Similar to above, it is strongly recommended to pass an existing [User Calendar] to the argument [cal] if one insists to call #
#   |      it by means of [e.apply(f,...)] or [map(f,e)], to minimize the system calculation effort                                     #
#   |[03] To align the behavior of the same function in [R], we ignore the [pd.index] of both inputs during the calculation by          #
#   |      regarding them as pairwise, then determine the [index] and [columns] by that of [M] if [M] is a [pd.DataFrame] or            #
#   |      [pd.Series], otherwise by that of [N] if still applicable. (M.shape is always equal to N.shape, or N.shape == 1)             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[FEATURE]                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[01] Support different types of [date_*], i.e. pd.DataFrame, pd.Series, strings indicating dates, dt.date, dt.datetime, dt.time    #
#   |[02] Does not support [.starting-point] in [interval] as that in SAS, as it is useless and ambiguous under most circumstances      #
#   |[03] Calculate on [DISCRETE] method, in spite of that in SAS, as there are other simpler ways to calculate on [CONTINUOUS] method  #
#   |[04] Support the increment by Calendar Days, Working Days, or Trade Days                                                           #
#   |[05] [WEEKDAY] as [interval] has different definition to that in SAS, see below definition of [omniPy.Dates.getDateIntervals]      #
#   |[06] [WEEK] starts with Sunday=0 and ends with Saturday=6, to align that in SAS                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |interval    :   Character string as a time interval such as WEEK, SEMIYEAR, QTR, or HOUR, case insensitive. It has no default      #
#   |                 value, while the functions raises error if it is NOT provided.                                                    #
#   |                See definition of [omniPy.Dates.getDateIntervals] for accepted values                                              #
#   |date_bgn    :   Date-like values, will be converted by [asDates], [asDatetimes] or [asTimes] as per request                        #
#   |date_end    :   Date-like values, will be converted by [asDates], [asDatetimes] or [asTimes] as per request                        #
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
#   |<various>   :   The return type depends on the input arguments, while each returned value is [float], for [np.nan] could exist     #
#   |                [1] For case of pairs as (M,1):                                                                                    #
#   |                    [1] If [M] is pd.DataFrame or pd.Series, return the same type as [M]                                           #
#   |                    [2] When [M] is provided a [str], return a single integer, or np.NaN where applicable                          #
#   |                    [3] When [M] is an [Iterable] except [str], return a [list] of integers or np.NaN                              #
#   |                [2] For case of pairs as (M,N), [M.shape] must be the same as [N.shape] :                                          #
#   |                    [1] If either is pd.DataFrame or pd.Series, return the same type as it                                         #
#   |                    [2] Return a [list] in other cases                                                                             #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210920        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210925        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Re-write the function to convert the input values only once, which reduces the time consumption by 60%                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210927        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Re-launch the full calendar so that this function covers all special scenarios for work/trade/week days                 #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20211120        | Version | 3.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug: [multiple] is not implemented when [dtt] is triggered                                                      #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20211204        | Version | 3.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Unify the effect of [col_rowidx] and [col_period] when [span]==1, hence [col_rowidx] is no longer used                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230610        | Version | 3.30        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce functions <vecStack> and <vecUnstack> to simplify the program                                                 #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230815        | Version | 3.40        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |sys, re, datetime, pandas, numpy, collections, inspect, itertools                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |get_values                                                                                                                 #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.Dates                                                                                                                   #
#   |   |   |intCalendar                                                                                                                #
#   |   |   |getDateIntervals                                                                                                           #
#   |   |   |asDates                                                                                                                    #
#   |   |   |asDatetimes                                                                                                                #
#   |   |   |asTimes                                                                                                                    #
#   |   |   |UserCalendar                                                                                                               #
#   |   |   |ObsDates                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name
    recall = get_values(LfuncName, instance = callable)

    #012. Handle the parameter buffer
    if not isinstance(daytype, str):
        raise ValueError(f'[{LfuncName}][daytype]:[{type(daytype)}] must be character string!')
    daytype = daytype[0].upper()
    if daytype not in ['C','W','T']:
        raise ValueError(f'[{LfuncName}][daytype]:[{daytype}] must be among [C,W,T]!')

    #015. Function local variables
    col_rowidx : str = '_ical_row_'
    col_period : str = '_ical_prd_'
    col_prdidx : str = '_ical_rprd_'
    col_keys : str = '_intckRec_'
    col_calc : str = '_intckCol_'
    col_idxcol : str = '_intckKCol_'
    col_idxrow : str = '_intckKRow_'
    col_rst : str = '_intckRst_'
    map_stack : dict = {
        'idRow' : col_idxrow
        ,'idCol' : col_idxcol
    }

    #020. Remove possible items that conflict the internal usage from the [kw_cal]
    kw_cal_fnl = kw_cal.copy()
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

    #060. Get the attributes for the requested time interval
    #The result of below function is [dict], while current input has only one element, hence we use the first among the result
    dict_attr = getDateIntervals(interval)[0]

    #080. Define interim column names for call of helper functions
    if dict_attr['itype'] in ['d', 'dt']:
        col_merge : str = '_intckDate_'
        col_out : str = 'D_DATE'
    else:
        col_merge : str = '_intckTime_'
        col_out : str = 'T_TIME'

    #100. Reshape of the input datetime values
    #110. Extract information of [date_bgn]
    f_bgn_df = isinstance(date_bgn, pd.DataFrame)
    f_bgn_srs = isinstance(date_bgn, pd.Series)
    f_bgn_idx = isinstance(date_bgn, pd.Index)

    if f_bgn_df | f_bgn_srs | isinstance(date_bgn, np.ndarray):
        bgn_shape = date_bgn.shape
        if len(bgn_shape) == 1:
            bgn_shape += (1,)
    elif f_bgn_idx:
        bgn_shape = (date_bgn.size, date_bgn.nlevels)
    elif isinstance(date_bgn, Iterable) and (not isinstance(date_bgn, str)):
        #We do not verify the dimensions of such object, which may lead to unexpected result
        bgn_shape = (len(date_bgn),1)
    elif date_bgn is None:
        #<NoneType> has the size of 1, whic means its dimension is as below:
        bgn_shape = (0,1)
    else:
        bgn_shape = (1,1)

    #[ASSUMPTION]
    #[1] <NoneType> value is considered as single
    #[2] We also verify the number of columns if the input is a [pd.DataFrame]
    f_bgn_single = (bgn_shape == (1,1)) or date_bgn is None
    f_bgn_empty = (bgn_shape[0] == 0) | (bgn_shape[-1] == 0)

    #120. Extract information of [date_end]
    f_end_df = isinstance(date_end, pd.DataFrame)
    f_end_srs = isinstance(date_end, pd.Series)
    f_end_idx = isinstance(date_end, pd.Index)

    if f_end_df | f_end_srs | isinstance(date_end, np.ndarray):
        end_shape = date_end.shape
        if len(end_shape) == 1:
            end_shape += (1,)
    elif f_end_idx:
        end_shape = (date_end.size, date_end.nlevels)
    elif isinstance(date_end, Iterable) and (not isinstance(date_end, str)):
        #We do not verify the dimensions of such object, which may lead to unexpected result
        end_shape = (len(date_end),1)
    elif date_end is None:
        end_shape = (0,1)
    else:
        end_shape = (1,1)

    f_end_single = (end_shape == (1,1)) or date_end is None
    f_end_empty = (end_shape[0] == 0) | (end_shape[-1] == 0)

    #140. Verify the shapes of the input values
    #Quote: https://pythonspot.com/binary-numbers-and-logical-operators/
    f_Mto1 = f_bgn_single ^ f_end_single
    f_1to1 = f_bgn_single & f_end_single
    f_MtoN = (not f_1to1) & (bgn_shape == end_shape)
    f_comp_err = not (f_Mto1 | f_1to1 | f_MtoN)

    #145. Abort if the shapes of the input values are not the same
    #After this step, if neither of the input has only one element, they must be in the same shape (e.g. both empty)
    if f_comp_err:
        raise ValueError(f'[{LfuncName}]Input values must be in the same shape!')

    #148. Create the flag of whether to change the position of [date_bgn] and [date_end] for standardization
    f_switch = f_Mto1 & f_bgn_single

    #150. Verify the shapes of the input values
    f_single_empty = f_bgn_empty ^ f_end_empty

    #159. Raise error if the [Iterable] among them has zero length
    if (not f_1to1) & f_single_empty:
        raise ValueError('[' + LfuncName + ']Non-empty values vs Empty iterables is not accepted!')

    #160. Determine the attributes of the output
    f_out_df = f_bgn_df | f_end_df
    f_out_srs = f_bgn_srs | f_end_srs
    f_out_idx = f_bgn_idx | f_end_idx

    #165. Translate the input values to [M] and [N]
    if f_switch:
        df_M = deepcopy(date_end)
        df_N = deepcopy(date_bgn)
        f_M_df = f_end_df
        f_M_srs = f_end_srs
        f_M_idx = f_end_idx
        shape_M = end_shape
        shape_N = bgn_shape
    else:
        df_M = deepcopy(date_bgn)
        df_N = deepcopy(date_end)
        f_M_df = f_bgn_df
        f_M_srs = f_bgn_srs
        f_M_idx = f_bgn_idx
        shape_M = bgn_shape
        shape_N = end_shape

    #167. Identify the model of [columns] and [index] for output
    #[ASSUMPTION]
    #[1] Till now, shapes of both inputs only differ in below scenarios:
    #    [a] M and N have the same shape
    #    [b] N has only one element, including <NoneType>
    #[2] If M is longer than N, we model M as the output shape, e.g. when <3-tuple> vs <1-element pd.Series>, output <3-tuple>
    #[3] Otherwise we prioritize the scenarios of pandas types
    #[4] If no pandas structure is involved, we use the shape of M, e.g. when <1-scalar> vs <1-element array>, output <1-scalar>
    f_force_M = shape_M[0] > shape_N[0]
    if f_force_M:
        mdl_out = df_M
    elif f_out_df and (not f_M_df):
        mdl_out = df_N
    elif f_out_srs and (not f_M_srs):
        mdl_out = df_N
    elif f_out_idx and (not f_M_idx):
        mdl_out = df_N
    else:
        mdl_out = df_M

    #170. Helper function to process the unstacked data before type conversion
    def h_dtype(df):
        return(df.copy(deep = True).astype(float))

    #190. Prepare the helper function to return proper results
    def h_rst(rst, col):
        #500. Unstack the underlying data to the same shape as the input one
        #[ASSUMPTION]
        #[1] <col-id> and <row-id> do not have <NA> values
        #[2] There can only be <NA> values in the <col>
        #[3] Hence we have to convert <col> to <float> type as output
        rstOut = vecUnstack(rst, valName = col, modelObj = mdl_out, funcConv = h_dtype, **map_stack)

        #999. Purge
        return(rstOut)
    #End [h_rst]

    #200. Re-shape the input values for calculation at later steps
    #210. Transform [M] for standardized calculation
    df_M = (
        vecStack(df_M, valName = col_calc, **map_stack)
        .assign(**{
            col_keys : lambda x: range(len(x))
            ,col_calc : lambda x: dict_dates[dict_attr['itype']]['func'](
                x[col_calc]
                ,**dict_dates[dict_attr['itype']]['kw']
            )
        })
    )

    #250. Transform [N] for standardized calculation
    #[ASSUMPTION]
    #[1] For the scenario Mto1, we handle it via a helper function, see below process
    df_N = (
        vecStack(df_N, valName = col_calc, **map_stack)
        .assign(**{
            col_keys : lambda x: range(len(x))
            ,col_calc : lambda x: dict_dates[dict_attr['itype']]['func'](
                x[col_calc]
                ,**dict_dates[dict_attr['itype']]['kw']
            )
        })
    )

    #255. Return placeholder if N has zero length
    if len(df_N) == 0:
        df_rst = df_M.copy(deep=True).assign(**{ col_rst : np.nan })
        return(h_rst(df_rst, col_rst))

    #259. Return placeholder if M has zero length
    if len(df_M) == 0:
        df_rst = df_N.copy(deep=True).assign(**{ col_rst : np.nan })
        return(h_rst(df_rst, col_rst))

    #290. Calculate the incremental for [datetime] when [type] in [dt(second|minute|hour)] by calling this function in recursion
    if dict_attr['itype'] in ['dtt']:
        #100. Conduct the calculation for [date] and [time] parts respectively
        #101. We ensure both inputs are [pd.Series]
        dtt_Mdate = df_M[col_calc].apply( lambda x: x.date() )
        dtt_Mdate.name = '_dtt_Mdate_'
        dtt_Ndate = df_N[col_calc].apply( lambda x: x.date() )
        dtt_Ndate.name = '_dtt_Ndate_'
        dtt_Mtime = df_M[col_calc].apply( lambda x: pd.NaT if pd.isnull(x) else x.time() )
        dtt_Mtime.name = '_dtt_Mtime_'
        dtt_Ntime = df_N[col_calc].apply( lambda x: pd.NaT if pd.isnull(x) else x.time() )
        dtt_Ntime.name = '_dtt_Ntime_'
#        sys._getframe(1).f_globals.update({ 'vfy_M' : dtt_Mdate.copy(deep=True) })
#        sys._getframe(1).f_globals.update({ 'vfy_N' : dtt_Ndate.copy(deep=True) })

        #110. Increment by [day]
        dtt_rst_date = recall(
            interval = 'day'
            ,date_bgn = dtt_Mdate
            ,date_end = dtt_Ndate
            ,daytype = daytype
            ,cal = cal
            ,kw_d = kw_d
            ,kw_dt = kw_dt
            ,kw_t = kw_t
            ,kw_cal = kw_cal
        )

        #150. Increment by different scenarios of [time]
        dtt_ntvl = re.sub(r'^dt', '', interval)
        dtt_rst_time = recall(
            interval = dtt_ntvl
            ,date_bgn = dtt_Mtime
            ,date_end = dtt_Ntime
            ,daytype = daytype
            ,cal = cal
            ,kw_d = kw_d
            ,kw_dt = kw_dt
            ,kw_t = kw_t
            ,kw_cal = kw_cal
        )

        #500. Correction on incremental for [Work/Trade Days]
        if daytype in ['W', 'T']:
            #050. Define local variables
            dict_obsDates = {
                'W' : 'isWorkDay'
                ,'T' : 'isTradeDay'
            }

            #100. Verify whether the input values are [Work/Trade Days]
            #130. Create separate identifiers for [M] and [N]
            dtt_obs_M = ObsDates( dtt_Mdate, **kw_cal_fnl )
            dtt_obs_N = ObsDates( dtt_Ndate, **kw_cal_fnl )

            #150. Re-shape the flags of [M] into comparable ones
            dtt_flag_M = ~dtt_obs_M.__getattribute__(dict_obsDates[daytype])

            #170. Re-shape the flags of [N] into comparable ones
            dtt_flag_N = ~dtt_obs_N.__getattribute__(dict_obsDates[daytype])
            #In other cases than [f_Mto1], [M] and [N] must have the same shape
            if f_Mto1:
                #100. Prepare a single value
                dtt_flag_N = dtt_flag_N.iat[0]

            #[IMPORTANT] Please keep the sequence of below steps, as [dtt_rst_date] is overwritten!
            #500. Correction by below conditions
            #[1] Incremental is 0 (other cases are handled in other steps)
            #[2] Both input dates are Public Holidays
            #510. Mark the records with both of below conditions
            dtt_mask_zero = dtt_rst_date.eq(0) & dtt_flag_M & dtt_flag_N

            #590. Set the above records as [np.nan] for good reason
            dtt_rst_date.loc[dtt_mask_zero] = np.nan

            #700. Correct the [day] by -1, given difference as any number of [Calendar Days]
            #710. Identify the correction on both sides
            dtt_d_corr = dtt_rst_date.copy(deep=True)
            dtt_mask_pos = dtt_flag_N & dtt_rst_date.ge(0)
            dtt_mask_neg = dtt_flag_M & dtt_rst_date.le(0)
            dtt_d_corr[dtt_mask_pos] = 1
            dtt_d_corr[dtt_mask_neg] = -1
            dtt_d_corr[~( dtt_mask_pos | dtt_mask_neg )] = 0

            #720. Only validate the correction when either [M] or [N] is Holiday
            dtt_mask = dtt_flag_M | dtt_flag_N

            #790. Correct the result by their difference
            dtt_rst_date.loc[dtt_mask] = dtt_rst_date[dtt_mask].add(dtt_d_corr[dtt_mask])

        #700. Transform the [date] part into the same [span] as [time] part, and combine both
        dtt_rst = df_M[[col_idxrow, col_idxcol]].copy(deep = True)

        #750. Combine the date and time parts
        dtt_srs_tmp = (
            dtt_rst_date
            .copy(deep=True)
            .mul(86400)
            #[IMPORTANT] We have to add the [time part] before dividing it!
            .add(dtt_rst_time.mul(dict_attr['span']).mul(dict_attr['multiple']))
        )

        #770. Divide the result by the span and multiple by the absolute values
        dtt_rst[col_rst] = (
            dtt_srs_tmp
            .abs()
            .div(dict_attr['span'])
            .floordiv(dict_attr['multiple'])
        )

        #800. Negate the values where necessary
        mask_mul = dtt_srs_tmp.lt(0)
        dtt_rst.loc[mask_mul, col_rst] *= -1

        #990. Return the final result
        return(h_rst(dtt_rst, col_rst))
    #End if [dtt]

    #300. Create necessary columns
    #310. Unanimous columns
    if dict_attr['itype'] in ['t']:
        #100. Convert into [np.array] for element-wise combination at later step
        arr_Mtime = np.array(df_M[col_calc])
        arr_Ntime = np.array(df_N[col_calc])

        #900. Create [datetime] for the calculation of [time]
        df_M[col_calc] = pd.Series(v_dt_combine(dt.date.today(), arr_Mtime), index = df_M.index)
        df_N[col_calc] = pd.Series(v_dt_combine(dt.date.today(), arr_Ntime), index = df_N.index)

    #320. Create [col_merge] as well as the bounds of the calendar
    #Quote: [0.11s] for 10K records
    if dict_attr['itype'] in ['d', 'dt']:
        #100. Create new column
        if dict_attr['itype'] in ['d']:
            df_M[col_merge] = df_M[col_calc]
            df_N[col_merge] = df_N[col_calc]
        else:
            df_M[col_merge] = df_M[col_calc].apply(lambda x: x.date())
            df_N[col_merge] = df_N[col_calc].apply(lambda x: x.date())

        #300. Concatenate the date values of both input values
        srs_indate = pd.concat([df_M[col_merge], df_N[col_merge]], ignore_index = True)

        #500. Define the bound of the calendar
        notnull_indate = srs_indate.notnull()
        if not notnull_indate.any():
            #100. Assign the minimum size of calendar data if none of the input is a valid date
            cal_bgn = dt.date.today()
            cal_end = cal_bgn
        else:
            #100. Retrieve the minimum and maximum values among the input values
            #For [pandas == 1.2.1],the method [pd.Series.min(skipna = True)] cannot ignore [pd.NaT]
            in_min = srs_indate.loc[notnull_indate].min(skipna = True)
            in_max = srs_indate.loc[notnull_indate].max(skipna = True)

            #500. Extend the period coverage by the provided span and multiple
            cal_bgn = in_min + dt.timedelta(days = -15)
            cal_end = in_max + dt.timedelta(days = 15)
    else:
        #100. Create new column
        df_M[col_merge] = df_M[col_calc].dt.floor('S', ambiguous = 'NaT')
        df_N[col_merge] = df_N[col_calc].dt.floor('S', ambiguous = 'NaT')

        #300. Concatenate the date values of both input values
        srs_indate = pd.concat([df_M[col_merge], df_N[col_merge]], ignore_index = True)

        #500. Define the bound of the calendar
        notnull_indate = srs_indate.notnull()
        #[ASSUMPTION]
        #[1] Only for calculation on [time], all numbers are recycled in one day
        cal_bgn = dt.datetime.combine(dt.date.today(), dt.time(0,0,0))
        if not notnull_indate.any():
            #100. Assign the minimum size of calendar data if none of the input is a valid date
            cal_end = cal_bgn
        else:
            cal_end = dt.datetime.combine(dt.date.today(), dt.time(23,59,59))

    #380. [time] part for [type == dt]
    #There is no need to append [time] part for [dt], as we will only calculate the incremental by [day]

    #400. Prepare calendar data
    if not vfy_cal:
        intck_calfull = intCalendar(
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
        intck_calfull = cal.copy(deep=True).sort_values(col_out).reset_index(drop = True)

    #700. Calculate the incremental
    #710. Create a subset of the requested data
    df_M_in = df_M[[col_keys]].copy(deep=True)
    df_N_in = df_N[[col_keys]].copy(deep=True)

    #720. Retrieve the corresponding columns from the calendar for non-empty dates
    calmrg_M = (
        intck_calfull
        .set_index(col_out)
        .reindex(df_M[col_merge])
        .set_axis(df_M_in.index, axis = 0)
    )
    df_M_in[[col_period,col_prdidx]] = calmrg_M[[col_period,col_prdidx]]

    calmrg_N = (
        intck_calfull
        .set_index(col_out)
        .reindex(df_N[col_merge])
        .set_axis(df_N_in.index, axis = 0)
    )
    df_N_in[[col_period,col_prdidx]] = calmrg_N[[col_period,col_prdidx]]
#    sys._getframe(1).f_globals.update({ 'vfy_dat' : df_M.copy(deep=True) })
#    sys._getframe(1).f_globals.update({ 'vfy_N' : df_N_in.copy(deep=True) })

    #730. We extract the single value for [N] and leave the broadcasting to [pandas]
    def h_chg_N():
        if f_Mto1:
            #100. Prepare a [dict]
            rst = {
                col_period : df_N_in.iat[0,df_N_in.columns.get_loc(col_period)]
                ,col_prdidx : df_N_in.iat[0,df_N_in.columns.get_loc(col_prdidx)]
            }

            #900. Return
            return(deepcopy(rst))
        else:
            return(df_N_in.copy(deep=True))

    df_N_comp = h_chg_N()

    #740. Direct subtraction
    #IMPORTANT: We use [df.rsub] which means to subtract [N] by [M]
    #Scenarios:
    #[1] Index of [df_M_in] is the same as [df_N_in]
    #[2] [df_N_in] is a [dict]
    df_M_in.loc[:, col_rst] = df_M_in[col_period].rsub(df_N_comp[col_period]).astype(float)
    mask_mul = df_M_in[col_rst].lt(0)
#    sys._getframe(1).f_globals.update({ 'vfy_dat' : df_M_in.copy(deep=True) })

    #770. Apply [multiple] if any
    df_M_in['_intckRst_wMul_'] = df_M_in[col_rst].abs().floordiv(dict_attr['multiple'])
    df_M_in.loc[mask_mul, '_intckRst_wMul_'] *= -1

    #790. Negate the incremental if the input values are switched
    if f_switch:
        df_M_in.loc[:, '_intckRst_wMul_'] *= -1

    #800. Transform the data backwards to the same as input
    #810. Merge the incremental back to the input data for later transformation
    col_dt = [col_keys, col_idxrow, col_idxcol]
    df_rst = df_M[col_dt].copy(deep=True)

    #[IMPORTANT] Till now the indexes of both data are exactly the same
    df_rst[col_rst] = df_M_in['_intckRst_wMul_']

    #990. Output in terms of different request types
    return(h_rst(df_rst, col_rst))
#End intck

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
    from omniPy.Dates import intck
    from omniPy.Dates import asDates, asDatetimes, asTimes, ObsDates, intnx
    print(intck.__doc__)

    #050. Load user defined functions
    #[getOption] is from [autoexec.py]
    exec_file( os.path.join(dir_omniPy , r'autoexec.py') )

    #100. Create dates for test
    d_anchor = dt.date.today()
    dt_anchor = dt.datetime.today()
    pair1_dt1, pair1_dt2 = d_anchor, d_anchor - dt.timedelta(days = 3)
    pair2_dt1 = asDates( [pair1_dt1, pair1_dt2, pair1_dt1 - dt.timedelta(days = 10)] )
    pair2_dt2 = asDates( [pair1_dt2 - dt.timedelta(days = 10), pair1_dt1, pair1_dt2] )
    pair3_dt1 = pd.Series(pair2_dt1, dtype = 'object', index = [1,3,5])
    pair3_dt2 = pd.Series(pair2_dt2, dtype = 'object', index = [2,4,6])
    pair4_dt1 = pd.DataFrame({ 'aa' : pair3_dt1, 'bb' : pair3_dt2.set_axis(pair3_dt1.index) })
    pair4_dt2 = pd.DataFrame({
        'c' : asDates(pd.Series([pair1_dt1 + dt.timedelta(days = 5), pair1_dt2 + dt.timedelta(days = 5), pair1_dt2], dtype = 'object'))
        ,'d' : asDates(pd.Series([pair1_dt2 - dt.timedelta(days = 5), pair1_dt1, pair1_dt1 - dt.timedelta(days = 7)], dtype = 'object'))
    }).set_index(pair3_dt2.index)
    pair5_dt1 = [ dt.time(14,53,28), dt.time(4,44,56), dt.time(20,6,49) ]
    pair5_dt2 = [ dt.time(10,13,42), dt.time(8,25,40), dt.time(18,9,32) ]
    pair5_dt3 = pd.DataFrame({
        'c' : pair5_dt1
        ,'d' : pair5_dt2
    }).set_index(pair3_dt2.index)
    pair6_dt1 = [ dt.datetime.combine(d, dt_anchor.time()) for d in pair2_dt1 ]
    pair6_dt2 = [ dt.datetime.combine(d, dt_anchor.time()) + dt.timedelta(minutes = int(np.random.randint(1,100,1))) for d in pair2_dt2 ]
    pair6_dt3 = [ d + dt.timedelta(minutes = int(np.random.randint(-1440,1440,1))) for d in pair6_dt1 ]
    pair6_dt4 = pair4_dt2.copy(deep=True)
    pair6_dt4.loc[:, 'c'] = pair6_dt4.loc[:, 'c'].combine(pair5_dt3['c'], dt.datetime.combine)
    pair6_dt4.loc[:, 'd'] = pair6_dt4.loc[:, 'd'].combine(pair5_dt3['d'], dt.datetime.combine)

    t_now = dt.datetime.now()
    t_end = dt.datetime.combine(ObsDates(t_now).nextWorkDay[0], asTimes('05:00:00'))

    #200. Calculate the incremental between dates
    dt1_intck1 = intck('day', pair1_dt1, pair1_dt2, daytype = 'w')
    dt1_intck2 = intck('day', pair1_dt2, pair1_dt1, daytype = 't')
    dt2_intck1 = intck('day3', pair2_dt1, pair2_dt2, daytype = 'w')
    dt2_intck2 = intck('week', pair2_dt2, pair2_dt1, daytype = 't')
    dt2_intck3 = intck('week', pair2_dt2, pair2_dt1, daytype = 'c')

    #210. Test the pairs of (M * 1)
    dt2_intck5 = intck('day', pair1_dt1, pair2_dt2, daytype = 'w')

    #220. Test if either of the inputs is [pd.Series]
    dt3_intck1 = intck('day', pair2_dt2, pair3_dt1, daytype = 'w')

    #230. Test if both of the inputs are [pd.Series] with different indexes
    dt3_intck3 = intck('day', pair3_dt1, pair3_dt2, daytype = 'w')
    dt3_intck4 = intck('day', pair3_dt2, pair3_dt1, daytype = 'w')

    #240. Test if either of the inputs is [pd.DataFrame]
    dt4_intck1 = intck('day', pair1_dt1, pair4_dt1, daytype = 't')
    dt4_intck2 = intck('day3', pair4_dt2, pair1_dt1, daytype = 'c')

    #250. Test if both of the inputs are [pd.DataFrame] with different indexes
    dt4_intck3 = intck('day', pair4_dt1, pair4_dt2, daytype = 'c')
    dt4_intck4 = intck('day3', pair4_dt2, pair4_dt1, daytype = 'w')

    #260. Test the multiple on [dtt]
    diff_min5 = intck('dtsecond300', t_now, t_end)
    t_chk = intnx('dtsecond300', t_now, diff_min5)

    #300. Calculate the incremental between times
    dt5_intck1 = intck('hour2', pair5_dt1, pair5_dt2)

    #310. Test if either of the inputs is [pd.DataFrame]
    dt5_intck3 = intck('hour2', pair5_dt3, dt.datetime.now())

    #400. Calculate the incremental between datetimes
    #410. Datetime with [interval] indicating [days]
    dt6_intck1 = intck('day', pair6_dt1, pair6_dt2, daytype = 'w')

    #420. Datetime with [interval] indicating [dthours]
    dt6_intck3 = intck('dthour', pair6_dt4, dt_anchor, daytype = 't')

    #500. Test special dates
    dt10_intck1 = intck('month', '20210731', '20210730', daytype = 'w')
    dt10_intck2 = intck('month', '20210801', '20210802', daytype = 'w')
    dt10_intck3 = intck('week', '20211002', '20210927', daytype = 't')
    dt10_intck4 = intck('day', '20211002', '20210930', daytype = 'w')
    dt10_intck5 = intck('week', '20211003', '20211008', daytype = 't')
    dt10_intck6 = intck('month', '20210925', '20210924', daytype = 'w')
    dt10_intck7 = intck('weekday', '20211008', '20210930', daytype = 't')
    dt10_intck8 = intck('weekday', '20211008', '20211011', daytype = 't')
    dt11_intck1 = intck('dthour', '20210926 23:42:15', '20210924 17:42:15', daytype = 't')
    dt11_intck2 = intck('dthour', '20210925 23:42:15', '20210927 5:42:15', daytype = 't')
    dt11_intck3 = intck('dthour', '20210926 23:42:15', '20210926 17:42:15', daytype = 't')

    # [CPU] AMD Ryzen 5 5600 6-Core 3.70GHz
    # [RAM] 64GB 2400MHz
    #700. Test the timing of 2 * 50K dates
    dt7_smp1 = pair4_dt1.copy(deep=True).sample(50000, replace = True)
    dt7_smp2 = pair4_dt2.copy(deep=True).sample(50000, replace = True)

    time_bgn = dt.datetime.now()
    dt7_intck1 = intck('day2', dt7_smp1, dt7_smp2, daytype = 'w')
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # 0.18s on average

    #800. Test the timing  of 2 * 50K datetimes
    dt8_smp1 = pair6_dt4.copy(deep=True).sample(50000, replace = True)
    dt8_smp2 = pair6_dt4[['d','c']].copy(deep=True).sample(50000, replace = True)

    time_bgn = dt.datetime.now()
    dt8_intck1 = intck('dthour', dt8_smp1, dt8_smp2, daytype = 'w')
    time_end = dt.datetime.now()
    print(time_end - time_bgn)
    # 1.19s on average

    #900. Test special cases
    #910. [None] vs [None]
    print(intck('dthour', None, None, daytype = 'w'))
    #Return: None

    #915. [None] vs [date]
    print(intck('dthour', d_anchor, None, daytype = 'w'))
    #Return: np.nan

    #920. [None] vs empty Iterable
    print(intck('dthour', [], None, daytype = 'w'))
    print(intck('dthour', None, pd.Series([], dtype = 'object'), daytype = 'w'))
    #Return: the same type as the [Iterable] with no element

    #930. Empty series
    emp1 = pair3_dt1.loc[[False for i in range(len(pair3_dt1))]].copy(deep=True)
    emp2 = pair3_dt2.loc[[False for i in range(len(pair3_dt2))]].copy(deep=True)
    print(intck('day', emp1, emp2, daytype = 'w'))
    print(intck('day', emp2, emp1, daytype = 'w'))
    #Return: the same type as the [date_bgn] with no element

    #940. Empty data frames
    emp3 = pair6_dt4.loc[pair6_dt4.index.isin(['']), :].copy(deep=True)
    emp4 = pair6_dt4[['d','c']].loc[pair6_dt4.index.isin(['']), :].copy(deep=True)
    print(intck('dthour', emp3, emp4, daytype = 't'))
    print(intck('dthour', emp4, emp3, daytype = 't'))
    #Return: the same type as the [date_bgn] with no element

    emp5 = pair6_dt4.loc[:, pair6_dt4.columns.isin([''])].copy(deep=True)
    emp6 = pair6_dt4[['d','c']].loc[:, pair6_dt4.columns.isin([''])].copy(deep=True)
    print(intck('dthour', emp5, emp6, daytype = 't'))
    print(intck('dthour', emp6, emp5, daytype = 't'))
    #Return: the same type as the [date_bgn] with no element

    #990. Test error cases
    if False:
        #900. Non-empty values vs Empty iterables
        intck('dthour', d_anchor, [], daytype = 'w')
#-Notes- -End-
'''
