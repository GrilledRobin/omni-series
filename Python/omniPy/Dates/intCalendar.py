#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import datetime as dt
import pandas as pd
from typing import Union
#Quote: https://stackoverflow.com/questions/847936/how-can-i-find-the-number-of-arguments-of-a-python-function
from inspect import signature
from omniPy.Dates import UserCalendar, getDateIntervals

def intCalendar(
    interval : Union[str, dict]
    ,cal_bgn : Union[dt.date, dt.datetime]
    ,cal_end : Union[dt.date, dt.datetime]
    ,daytype : str = 'C'
    ,col_rowidx : str = '_ical_row_'
    ,col_period : str = '_ical_prd_'
    ,col_prdidx : str = '_ical_rprd_'
    ,col_weekday : str = '_ical_wday_'
    ,kw_cal : dict = {
        s.name : s.default
        for s in signature(UserCalendar).parameters.values()
        if s.name not in ['dateBgn', 'dateEnd', 'clnBgn', 'clnEnd']
    }
) -> 'Create the calendar split by date/time intervals for [interval]-related functions':
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to split the gregorian calendar by the provided [interval], to facilitate the [interval]-related         #
#   | functions, such as [intnx] and [intck]                                                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |interval    :   Either character string or a valid [dict] holding items generated by function [omniPy.Dates.getDateIntervals]      #
#   |                 value, while the functions raises error if it is NOT provided.                                                    #
#   |                 [<str>       ]           See definition of [omniPy.Dates.getDateIntervals] for accepted values                    #
#   |                 [<dict>      ]           Dictionary generated by above function                                                   #
#   |cal_bgn     :   Beginning of the dedicated calendar BEFORE being split by the interval                                             #
#   |cal_end     :   End of the dedicated calendar BEFORE being split by the interval                                                   #
#   |daytype     :   Type of days for the calculation                                                                                   #
#   |                 [C           ] <Default> Calendar Days                                                                            #
#   |                 [W           ]           Working Days                                                                             #
#   |                 [T           ]           Trading Days                                                                             #
#   |col_rowidx  :   Column name representing the record index within the whole output calendar                                         #
#   |                Column attributes:                                                                                                 #
#   |                 [dtype       ][int64       ]                                                                                      #
#   |                Valid inputs:                                                                                                      #
#   |                 [_ical_row_  ] <Default> The default column name                                                                  #
#   |                 [<str>       ]           Any valid character string as column name                                                #
#   |col_period  :   Column name representing the [period] in the output calendar                                                       #
#   |                Column attributes:                                                                                                 #
#   |                 [dtype       ][int64       ]                                                                                      #
#   |                Valid inputs:                                                                                                      #
#   |                 [_ical_prd_  ] <Default> The default column name                                                                  #
#   |                 [<str>       ]           Any valid character string as column name                                                #
#   |col_prdidx  :   Column name representing the record index within each [period] in the output calendar                              #
#   |                Column attributes:                                                                                                 #
#   |                 [dtype       ][int64       ]                                                                                      #
#   |                Valid inputs:                                                                                                      #
#   |                 [_ical_rprd_ ] <Default> The default column name                                                                  #
#   |                 [<str>       ]           Any valid character string as column name                                                #
#   |col_weekday :   Column name representing the record flag of [weekday] in the output calendar                                       #
#   |                Column attributes:                                                                                                 #
#   |                 [dtype       ][bool       ]                                                                                       #
#   |                Valid inputs:                                                                                                      #
#   |                 [_ical_wday_ ] <Default> The default column name                                                                  #
#   |                 [<str>       ]           Any valid character string as column name                                                #
#   |kw_cal      :   Arguments for instantiating the class [omniPy.Dates.UserCalendar] if [cal] is NOT provided                         #
#   |                 [<Default>   ] <Default> Use the default arguments for [UserCalendar]                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<DataFrame> :   Calendar literally grouped by the provided interval                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210919        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210927        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] No longer remove any dates from the full calendar, but only mark them by suitable flags or counters, to support all     #
#   |      |     possible scenarios                                                                                                     #
#   |      |[2] Add a special flag [col_weekday] as a new argument, as interface to external usage                                      #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20211204        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Now return the same data frame for all [itype]s, to unify the calculation for all [span]s in the related functions      #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20221017        | Version | 3.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug when Saturday is Workday and the requested interval is Workweek                                             #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230610        | Version | 3.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug when [itype == 't'] and [span > 1], the calculation results to NA when period reaches 0                     #
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
#   |   |sys, datetime, pandas, typing, inspect                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.Dates                                                                                                                   #
#   |   |   |getDateIntervals                                                                                                           #
#   |   |   |UserCalendar                                                                                                               #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Handle the parameter buffer
    if not isinstance(daytype, str):
        raise ValueError('[' + LfuncName + '][daytype]:[{0}] must be character string!'.format( type(daytype) ))
    daytype = daytype[0].upper()
    if daytype not in ['C','W','T']:
        raise ValueError('[' + LfuncName + '][daytype]:[{0}] must be among [C,W,T]!'.format( daytype ))

    #020. Remove possible items that conflict the internal usage from the [kw_cal]
    kw_cal_fnl = kw_cal.copy()
    kw_pop = [ k for k in kw_cal_fnl if k in ['dateBgn', 'dateEnd', 'clnBgn', 'clnEnd'] ]
    for k in kw_pop:
        kw_cal_fnl.pop(k)

    #040. Get the attributes for the requested time interval
    if isinstance(interval, dict):
        dict_attr = interval
    else:
        #The result of below function is [dict], while current input has only one element, hence we use the first among the result
        dict_attr = getDateIntervals(interval)[0]

    #050. Local parameters
    if dict_attr['itype'] in ['d', 'dt']:
        col_out : str = 'D_DATE'
    else:
        col_out : str = 'T_TIME'

    #057. Column names for different request types for dates
    dict_adjcol : dict = {
        'W' : 'F_WORKDAY'
        ,'T' : 'F_TradeDay'
    }

    #100. Prepare helper functions
    #110. Function to create period indexes and their respective relative date indexes
    def h_dateidx(df, firstrec):
        #001. Create a copy of the input data frame
        rst = df.copy(deep=True)

        #100. Set the starting date
        rst['_firstrec_'] = firstrec
        rst.iat[0, rst.columns.get_loc('_firstrec_')] = True
        rst[col_period] = rst['_firstrec_'].cumsum().astype(int)

        #300. Subtract the period beginning by 1 for time calculation
        #[ASSUMPTION]
        #[1] This function is always called when [span > 1]
        #[2] Above condition indicates <name> is not <second>
        #[3] Hence such period starts from 0 instead of 1
        if dict_attr['itype'] == 't':
            rst.loc[:, col_period] = rst.loc[:, col_period].sub(1)

        #500. Count the records per period by the requested type of days
        if (dict_attr['itype'] in ['d', 'dt']) & (daytype in ['W', 'T']):
            rst[col_prdidx] = rst.groupby(col_period)[dict_adjcol[daytype]].cumsum().astype(int)
        else:
            #We add this index by [1] to align the same function in [R], which starts from [1] instead of [0]
            rst[col_prdidx] = rst.groupby(col_period).cumcount().astype(int).add(1)

        #999. Return the data frame
        return(rst)

    #300. Create the full calendar
    if dict_attr['itype'] == 't':
        #100. Create the sequence
        outRst = pd.DataFrame({
            col_out : pd.date_range(cal_bgn, cal_end, freq = 's')
        })
    else:
        #100. Instantiate the User Calendar
        intcal_uc = UserCalendar(
            clnBgn = cal_bgn
            ,clnEnd = cal_end
            ,**kw_cal_fnl
        )

        #900. Extract the data frame of the User Calendar
        outRst = intcal_uc.usrCalendar.copy(deep=True)

    #500. Add necessary columns
    outRst[col_rowidx] = range(len(outRst))

    #700. Reshape the calendar for different scenarios
    if dict_attr['span'] == 1:
        #IMPORTANT: This date index may have duplicates
        #100. Reset date index within the entire period for work/trade days
        if (dict_attr['itype'] in ['d', 'dt']) & (daytype in ['W', 'T']):
            outRst[col_rowidx] = outRst[dict_adjcol[daytype]].cumsum()

        #300. Reset date index within the entire period for weekdays
        if dict_attr['name'] in ['weekday', 'dtweekday']:
            #500. Mark the dates which are [weekdays]
            outRst[col_weekday] = outRst[col_out].apply( lambda x: x.weekday() < 5 )
            if (dict_attr['itype'] in ['d', 'dt']) & (daytype in ['W', 'T']):
                outRst[col_weekday] &= outRst[dict_adjcol[daytype]]

            #900. Correct the default index by all weekdays
            outRst[col_rowidx] = outRst[col_weekday].cumsum().astype(int)

        #800. Create the field of [Period], which is the same as [Row Index] for such case
        outRst[col_period] = outRst[col_rowidx]
        outRst[col_prdidx] = outRst[col_rowidx].apply(lambda x: 0)
    elif (dict_attr['name'] in ['week', 'dtweek']) & (daytype in ['W', 'T']):
        outRst = h_dateidx(
            outRst
            ,outRst[dict_adjcol[daytype]].eq(True) & outRst[dict_adjcol[daytype]].shift(1, fill_value = False).eq(False)
        )
    else:
        #100. Create intervals for different scenarios
        if dict_attr['name'] in ['week', 'dtweek']:
            outRst = h_dateidx( outRst, outRst[col_out].apply( lambda x: x.isoweekday() == 7 ) )
        elif dict_attr['name'] in ['tenday', 'dttenday']:
            outRst = h_dateidx( outRst, outRst[col_out].apply( lambda x: x.day in [1,11,21] ) )
        elif dict_attr['name'] in ['semimonth', 'dtsemimonth']:
            outRst = h_dateidx( outRst, outRst[col_out].apply( lambda x: x.day in [1,16] ) )
        elif dict_attr['name'] in ['month', 'dtmonth']:
            outRst = h_dateidx( outRst, outRst[col_out].apply( lambda x: x.day in [1] ) )
        elif dict_attr['name'] in ['qtr', 'dtqtr']:
            outRst = h_dateidx( outRst, outRst[col_out].apply( lambda x: (x.day in [1]) and (x.month in [1,4,7,10]) ) )
        elif dict_attr['name'] in ['semiyear', 'dtsemiyear']:
            outRst = h_dateidx( outRst, outRst[col_out].apply( lambda x: (x.day in [1]) and (x.month in [1,7]) ) )
        elif dict_attr['name'] in ['year', 'dtyear']:
            outRst = h_dateidx( outRst, outRst[col_out].apply( lambda x: (x.day in [1]) and (x.month in [1]) ) )
        elif dict_attr['name'] in ['minute', 'dtminute']:
            outRst = h_dateidx( outRst, outRst[col_out].apply( lambda x: x.second in [0] ) )
        elif dict_attr['name'] in ['hour', 'dthour']:
            outRst = h_dateidx( outRst, outRst[col_out].apply( lambda x: (x.second in [0]) and (x.minute in [0]) ) )

    #999. Output
    return(outRst)
#End intCalendar

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.Dates import intCalendar
    print(intCalendar.__doc__)

    #100. Create an interval-bound calendar
    cal1 = intCalendar( 'SEMIMONTH3', '20210501', '20210531', 'w' )
#-Notes- -End-
'''
