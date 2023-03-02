#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, re
import pandas as pd
from collections.abc import Iterable
from omniPy.AdvOp import modifyDict

def getDateIntervals(
    interval : Iterable
) -> 'Get the attributes of date or datetime intervals for calculation of date incremental':
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to retrieve the attributes of date or datetime intervals for calculation of date incremental             #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |interval    :   Character string as a time interval such as WEEK, SEMIYEAR, QTR, or HOUR, case insensitive. It has no default      #
#   |                 value, while the functions raises error if it is NOT provided. Accepted values are as below:                      #
#   |                |------------------------------------------------------------------------------------------------------------------#
#   |                |Category |Interval  |Definition                                        |Example    |Description                   #
#   |                |---------+----------+--------------------------------------------------+-----------+------------------------------#
#   |                |Date     |DAY       |Daily intervals                                   |day3       |each 3-day starting on Sunday #
#   |                |         |WEEK      |Weekly intervals                                  |week2      |2 weeks from now              #
#   |                |         |WEEKDAY   |Daily intervals with Sat and Sun as holidays      |weekday2   |2 weekdays from now           #
#   |                |         |TENDAY    |10-day intervals cut by 1st, 11th and 21st of     |tenday2    |20 days from now              #
#   |                |         |          | each month                                       |           |                              #
#   |                |         |SEMIMONTH |Half-month intervals, cut at 15th                 |semimonth3 |3 half-months from now        #
#   |                |         |MONTH     |Monthly intervals                                 |month3     |3 months from now             #
#   |                |         |QTR       |Quarterly intervals, on Jan, Mar, Jul and Oct     |qtr2       |2 quarters from now           #
#   |                |         |SEMIYEAR  |Semiannual intervals, on Jan and Jul              |semiyear3  |3 semiyears from now          #
#   |                |         |YEAR      |Yearly intervals, on Jan                          |year2      |2 years from now              #
#   |                |---------+----------+--------------------------------------------------+-----------+------------------------------#
#   |                |Time     |SECOND    |Second intervals                                  |second2    |each 2 seconds                #
#   |                |         |MINUTE    |Minute intervals                                  |minute2    |each 2 minutes                #
#   |                |         |HOUR      |Hour intervals                                    |hour2      |each 2 hours                  #
#   |                |---------+----------+--------------------------------------------------+-----------+------------------------------#
#   |                |Datetime |DT+<DATE> |Add [DT] to any of the [Date] or [time] intervals |dtday3     |each 3-day starting on Sunday #
#   |                |------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<dict>      :   Dict of dicts with their respective [keys] set the same as the input Iterable of [interval] and values include:    #
#   |                [itype         ] Type of the interval among the choices: [d, dt, t]                                                #
#   |                [name          ] Name of the interval among the choices as defined for [interval]                                  #
#   |                [span          ] Date span to extend [omniPy.Dates.UserCalendar] for each of current interval during calculation   #
#   |                [multiple      ] Multiple as input for the calculation of date incremental, default as [1]                         #
#   |                [recycle       ] Indicator of how many periods will be recycled during the calculation, only affects the           #
#   |                                  calculation upon [time] intervals                                                                #
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
#   | Log  |[1] Add new type [dtt] to identify the groups: [dtsecond], [dtminiute] and [dthour], to resemble the same type in SAS       #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210902        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Now the return value is changed to a [dict] to facilitate multiple input at the same time                               #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210927        | Version | 3.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Correct the [span] for [weekday] as 1, instead of 5, to make it a type of incremental on single units instead of period #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20211120        | Version | 3.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug: [ptn_ntvl_matchobj.all()] fails on verification; change to [ptn_ntvl_matchobj.notnull().all()]             #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230302        | Version | 3.30        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Added attribute [recycle] in output result to indicate the span when recycling the periods                              #
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
#   |   |sys, re, pandas, collections                                                                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |modifyDict                                                                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Import necessary functions for processing.

    #010. Check parameters.
    #011. Prepare log text.
    #python 动态获取当前运行的类名和函数名的方法: https://www.cnblogs.com/paranoia/p/6196859.html
    LfuncName : str = sys._getframe().f_code.co_name

    #012. Handle the parameter buffer
    ntvl = pd.Series(interval, dtype = 'object')

    #050. Local parameters
    gti_flags = re.I

    #053. Date and time intervals
    dict_d = {
        'day' : {'span' : 1, 'recycle' : 0}
        ,'week' : {'span' : 7, 'recycle' : 0}
        ,'weekday' : {'span' : 1, 'recycle' : 0}
        ,'tenday' : {'span' : 10, 'recycle' : 0}
        ,'semimonth' : {'span' : 16, 'recycle' : 0}
        ,'month' : {'span' : 31, 'recycle' : 0}
        ,'qtr' : {'span' : 92, 'recycle' : 0}
        ,'semiyear' : {'span' : 183, 'recycle' : 0}
        ,'year' : {'span' : 366, 'recycle' : 0}
    }
    dict_dt = { ('dt' + k) : v for k,v in dict_d.items() }
    dict_t = {
        'second' : {'span' : 1, 'recycle' : 86400}
        ,'minute' : {'span' : 60, 'recycle' : 1440}
        ,'hour' : {'span' : 3600, 'recycle' : 24}
    }
    dict_dtt = { ('dt' + k) : v for k,v in dict_t.items() }
    dict_dates = {
        'd' : dict_d
        ,'dt' : dict_dt
        ,'t' : dict_t
        ,'dtt' : dict_dtt
    }

    #100. Create a list of candidates to be output in terms of successful matching at later steps
    cand_out = {
        y : {
            'itype' : x
            ,'name' : y
            ,'span' : dict_dates[x][y]['span']
            ,'recycle' : dict_dates[x][y]['recycle']
        }
        for x in dict_dates.keys()
        for y in dict_dates[x].keys()
    }

    #300. Combine all patterns into one, using [|] to minimize the system effort during matching
    str_ntvl_match = '(' + '|'.join( u for v in dict_dates.values() for u in v.keys() ) + r')(\d*)'
    ptn_ntvl_match = re.compile(str_ntvl_match, gti_flags)
    ptn_ntvl_matchobj = ntvl.apply(ptn_ntvl_match.fullmatch)

    #399. Stop if the input values is not recognized
    if not ptn_ntvl_matchobj.notnull().all():
        err_ntvl = ntvl[ptn_ntvl_matchobj.isnull()]
        raise ValueError(
            '[' + LfuncName + '][interval]:[{0}] cannot be recognized!'.format( ','.join(err_ntvl.apply(str)) )
            + '\n' + 'Valid intervals should match the pattern: {0}'.format( str_ntvl_match )
        )

    #500. Find all matches from the input
    #510. Extract the first groups as [Interval ID]
    ntvl_id = ptn_ntvl_matchobj.apply(lambda x: x[1].lower())

    #520. Extract the second groups as [Interval Multiple]
    ntvl_m = ptn_ntvl_matchobj.apply(lambda x: int(x[2]) if x[2] else 1)
    ntvl_m.loc[ntvl_m == 0] = 1

    #700. Prepare the output
    #710. Identify which among the candidates should be used
    outRst_pre = { i : cand_out[d] for i,d in enumerate(ntvl_id) }

    #750. Create a list of [multiples] to update above results
    ntvl_mult = { i : { 'multiple' : m } for i,m in enumerate(ntvl_m) }

    #799. Update the output result with the necessary information
    outRst = modifyDict(outRst_pre, ntvl_mult)

    #999. Output
    return(outRst)
#End getDateIntervals

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #010.   Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.Dates import getDateIntervals
    print(getDateIntervals.__doc__)

    #100. Parse the datetime interval
    a1 = getDateIntervals( 'SEMIMONTH3' )

    #200. Parse the datetime intervals (with potential duplicates)
    a2 = getDateIntervals( ['day', 'dthour2', 'day', 'SEMIMONTH3'] )
#-Notes- -End-
'''
