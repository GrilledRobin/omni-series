#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#001. Import necessary functions for processing.
import datetime as dt
import math
import pandas as pd
from typing import Any
from warnings import warn
from collections.abc import Iterable
from omniPy.AdvOp import vecStack, vecUnstack, ExpandSignature
from omniPy.Dates import asDates, asQuarters, CoreUserCalendar

eSig = ExpandSignature(CoreUserCalendar.__init__)

#100. Definition of the class.
class ObsDates( CoreUserCalendar ):
    #000. Info.
    '''
#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This Class is intended to create Calendar object with abundant methods to manipulate Business/Trade dates given any specific       #
#   | adjustment on public holidays and workdays announced by the government                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Methods                                                                                                                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Public method                                                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |[__init__]                                                                                                                     #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to instantiate a User Calender object                                                          #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |[Signature Expansion]                                                                                                  #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |[1] Signature of this function is expanded from <CoreUserCalendar>, see its documents for detailed argument list       #
#   |   |   |   |[2] With the Signature Expansion functionality, one can obtain the correct signature at runtime in below ways          #
#   |   |   |   |    [1] Type <help(func)> in the console to see its full documents including the docstring brought from the ancestors  #
#   |   |   |   |    [2] Type <print(func.__doc__)> in the console for the similar result as above                                      #
#   |   |   |   |    [3] Type <print(inspect.signature(func).parameters)> in the console to see its full signature                      #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |obsDate           :   Vector/list of observing dates to evaluate                                                           #
#   |   |   |                      [<dt.date.today()>   ]<Default> System date at class instantiation                                   #
#   |   |   |*pos              :   All the arguments are from its ancestor, please check its document                                   #
#   |   |   |**kw              :   All the arguments are from its ancestor, please check its document                                   #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   This method does not return values, but will assign values to variables for <private> object         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[shiftDays]                                                                                                                    #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to obtain the <kshift>th workday/tradeday (by <daytype>) counting from the provided <obsDate>  #
#   |   |   |   | per requested, or return themselves if they are workday/tradeday as indicated by <preserve>                           #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[obsDate      ]   :   <pd.DataFrame> of observing dates to evaluate                                                        #
#   |   |   |                      [self.obs_df         ]<Default> Default internal data frame containing observing dates               #
#   |   |   |[kshift       ]   :   <int> Number of workdays/tradedays to shift                                                          #
#   |   |   |                      [int <0>             ]<Default> Return itself if it is workday/tradeday, or return its Previous      #
#   |   |   |                                                       Workday/Tradeday if it is not                                       #
#   |   |   |[preserve     ]   :   <bool> Whether to force returning itself if it is workday/tradeday; no effect if <obsDate> is NOT    #
#   |   |   |                       workday or tradeday, for that the function will always shift days against them as requested         #
#   |   |   |                      [True                ]<Default> Return <obsDate> if it is workday/tradeday in any case               #
#   |   |   |                      [False               ]          Shift the days no matter <obsDate> is workday/tradeday or not        #
#   |   |   |[daytype      ]   :   <str> Which of the types of dates to shift; Calendar Date is not an option, for there is no need to  #
#   |   |   |                       call this function for calculation                                                                  #
#   |   |   |                      [W                   ]<Default> Workday                                                              #
#   |   |   |                      [T                   ]<Default> Tradeday                                                             #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<various>         :   Vector of the shifted dates in the same sequence as the input <obsDate>                              #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |400.   Private method                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |[.isBoundOfPeriod]                                                                                                             #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to verify <obsDate> on whether it is the <first/last> of <workdays/tradedays> within specified #
#   |   |   |   | period                                                                                                                #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[daytype      ]   :   <str> Type of the date to verify                                                                     #
#   |   |   |                      [W                   ]<Default> Whether the input date is Workday                                    #
#   |   |   |                      [T                   ]          Whether the input date is Tradeday                                   #
#   |   |   |[_bound       ]   :   <str> Verify whether the date is at the beginning or ending of the period                            #
#   |   |   |                      [head                ]<Default> Whether the input date is at the beginning                           #
#   |   |   |                      [tail                ]          Whether the input date is at the end                                 #
#   |   |   |[_period      ]   :   <str> Period name to verify the date                                                                 #
#   |   |   |                      [MONTH               ]<Default> Verify the bound of each month                                       #
#   |   |   |                      [QUARTER             ]          Verify the bound of each QUARTER                                     #
#   |   |   |                      [WEEK                ]          Verify the bound of each workweek/tradeweek                          #
#   |   |   |                      [YEAR                ]          Verify the bound of each YEAR                                        #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<various>         :   Logical values of the verification result for each <obsDate> respectively in the same sequence       #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |500.   Read-only properties.                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |100.   Description.                                                                                                            #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |This section lists all the read-only properties of the class. The examples listed are based on below provision                 #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |EXAMPLE                                                                                                                        #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[<cln.values = ['20210104', '20210102', '20201030', '20210207']>]                                                              #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |NOTE                                                                                                                           #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[1] <work week> represents the block of consecutive workdays                                                                   #
#   |   |[2] <trade week> represents the block of consecutive tradedays                                                                 #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |       Property Name         |                             Value Examples and Property Description                         #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | params                      | <log> Display the key information for calculation within current instance                   #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | isWorkDay                   | <T,F,T,T> Whether the provided dates are workdays respectively                              #
#   |   |   | isFirstWDofMon              | <T,F,F,F> Whether the provided dates are the first workdays of their respective months      #
#   |   |   | isLastWDofMon               | <F,F,T,F> Whether the provided dates are the last workdays of their respective months       #
#   |   |   | isFirstWDofQtr              | <T,F,F,F> Whether the provided dates are the first workdays of their respective quarters    #
#   |   |   | isLastWDofQtr               | <F,F,F,F> Whether the provided dates are the last workdays of their respective quarters     #
#   |   |   | isFirstWDofWeek             | <T,F,F,T> Whether the provided dates are the first of their respective work weeks           #
#   |   |   | isLastWDofWeek              | <F,F,T,F> Whether the provided dates are the last of their respective work weeks            #
#   |   |   | isFirstWDofYear             | <T,F,F,F> Whether the provided dates are the first workdays of their respective years       #
#   |   |   | isLastWDofYear              | <F,F,F,F> Whether the provided dates are the last workdays of their respective years        #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | isTradeDay                  | <T,F,T,F> Whether the provided dates are tradedays respectively                             #
#   |   |   | isFirstTDofMon              | <T,F,F,F> Whether the provided dates are the first tradedays of their respective months     #
#   |   |   | isLastTDofMon               | <F,F,T,F> Whether the provided dates are the last tradedays of their respective months      #
#   |   |   | isFirstTDofQtr              | <T,F,F,F> Whether the provided dates are the first tradedays of their respective quarters   #
#   |   |   | isLastTDofQtr               | <F,F,F,F> Whether the provided dates are the last tradedays of their respective quarters    #
#   |   |   | isFirstTDofWeek             | <T,F,F,F> Whether the provided dates are the first of their respective trade weeks          #
#   |   |   | isLastTDofWeek              | <F,F,T,F> Whether the provided dates are the last of their respective trade weeks           #
#   |   |   | isFirstTDofYear             | <T,F,F,F> Whether the provided dates are the first tradedays of their respective years      #
#   |   |   | isLastTDofYear              | <F,F,F,F> Whether the provided dates are the last tradedays of their respective years       #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | prevYearLCD                 | <date(20201231),...,date(20201231)> Last Calendar Day of the Previous Year to the           #
#   |   |   |                             |                                      observing date                                         #
#   |   |   | prevYearLWD                 | <date(20201231),...,date(20201231)> Last Workday of the Previous Year to the                #
#   |   |   |                             |                                      observing date                                         #
#   |   |   | prevYearLTD                 | <date(20201231),...,date(20201231)> Last Tradeday of the Previous Year to the               #
#   |   |   |                             |                                      observing date                                         #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | prevQtrLCD                  | <date(20201231),...,date(20201231)> Last Calendar Day of the Previous Quarter to the        #
#   |   |   |                             |                                      observing date                                         #
#   |   |   | prevQtrLWD                  | <date(20201231),...,date(20201231)> Last Workday of the Previous Quarter to the             #
#   |   |   |                             |                                      observing date                                         #
#   |   |   | prevQtrLTD                  | <date(20201231),...,date(20201231)> Last Tradeday of the Previous Quarter to the            #
#   |   |   |                             |                                      observing date                                         #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | prevMon                     | <'202012',...,'202101'> Previous month to the observing date                                #
#   |   |   | prevMonLCD                  | <date(20201231),...,date(20210131)> Last Calendar Day of the Previous Month to the          #
#   |   |   |                             |                                      observing date                                         #
#   |   |   | prevMonLWD                  | <date(20201231),...,date(20210129)> Last Workday of the Previous Month to the               #
#   |   |   |                             |                                      observing date                                         #
#   |   |   | prevMonLTD                  | <date(20201231),...,date(20210129)> Last Tradeday of the Previous Month to the              #
#   |   |   |                             |                                      observing date                                         #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | prevWorkDay                 | <date(20201231),...,date(20210205)> Previous Workday of the observing date                  #
#   |   |   | prevWorkDay2                | <date(20201230),...,date(20210204)> 2nd Previous Workday in line of the observing date      #
#   |   |   | prevMonToPWD                | <'202011',...,'202101'> Previous month to the Previous Workday of the observing date        #
#   |   |   | prevMonLCDToPWD             | <date(20201130),...,date(20210131)> Last Calendar Day of the Previous Month to the Previous #
#   |   |   |                             |                                      Workday of the observing date                          #
#   |   |   | prevMonLWDToPWD             | <date(20201130),...,date(20210129)> Last Workday of the Previous Month to the Previous      #
#   |   |   |                             |                                      Workday of the observing date                          #
#   |   |   | nextWorkDay                 | <date(20210105),...,date(20210208)> Next Workday of the observing date                      #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | prevTradeDay                | <date(20201231),...,date(20210205)> Previous Tradeday of the observing date                 #
#   |   |   | prevTradeDay2               | <date(20201230),...,date(20210204)> 2nd Previous Tradeday in line of the observing date     #
#   |   |   | prevMonToPTD                | <'202011',...,'202101'> Previous month to the Previous Tradeday of the observing date       #
#   |   |   | prevMonLCDToPTD             | <date(20201130),...,date(20210131)> Last Calendar Day of the Previous Month to the Previous #
#   |   |   |                             |                                      Tradeday of the observing date                         #
#   |   |   | prevMonLTDToPTD             | <date(20201130),...,date(20210129)> Last Tradeday of the Previous Month to the Previous     #
#   |   |   |                             |                                      Tradeday of the observing date                         #
#   |   |   | nextTradeDay                | <date(20210105),...,date(20210208)> Next Tradeday of the observing date                     #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Active-binding method                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |[values]                                                                                                                       #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to set or return the user requested dates for observation within the universal calendar        #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |NOTE                                                                                                                   #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |[1] When <set> is called, it changes <self.obsdates>                                                                   #
#   |   |   |   |[2] When <return> is called, it returns the last value of <self.obsdates>                                              #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[udate        ]   :   Vector/list of dates, or character strings which can be coerced to <dt.date>                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<pd.Series>       :   The same values as the previous input by the user                                                    #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210217        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210308        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Abandon the usage of <pd.Timestamp> for all date-like columns as its lower/upper bounds are much less than <dt.date>    #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210821        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Eliminate all <pd.DataFrame.merge> operations and the most of <.apply> methods to improve the overall efficiency, now   #
#   |      |     use indexing of data frames and the time expense reduced by 90%.                                                       #
#   |      |[2] Now treat all invalid inputs as <pd.NaT> and maintain their positions in the output result                              #
#   |      |[3] Output <pd.NaT> or <empty string> as the shifted ones for invalid inputs                                                #
#   |      |[4] Output <False> as boundary detector for invalid inputs                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210921        | Version | 2.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Now support input as a data frame (2-D)                                                                                 #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230612        | Version | 2.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce functions <vecStack> and <vecUnstack> to simplify the program                                                 #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230902        | Version | 2.30        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Replace <pd.Series.fillna(method=)> with <pd.Series.__getattribute__('ffill'/'bfill')()> as the former will be          #
#   |      |     deprecated in the future version                                                                                       #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20231016        | Version | 2.40        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Updated the usage of <asQuarters> to improve the efficiency                                                             #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20250323        | Version | 2.50        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Remove the usage of <inplace> in terms of the FutureWarning of <pandas>                                                 #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20251231        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <ExpandSignature> to simplify the initialization arguments                                                    #
#   |      |[2] Enhance the logic when <clnBgn> or <clnEnd> is not provided at initialization                                           #
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
#   |   |datetime, math, pandas, collections, warnings, typing                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |vecStack                                                                                                                   #
#   |   |   |vecUnstack                                                                                                                 #
#   |   |   |ExpandSignature                                                                                                            #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |Dates                                                                                                                          #
#   |   |   |asDates                                                                                                                    #
#   |   |   |asQuarters                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Parent classes                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |Dates                                                                                                                          #
#   |   |   |CoreUserCalendar                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Identify the qualified name of current class (for logging purpose at large)
    #Quote: https://www.python.org/dev/peps/pep-3155/
    #[1] [__qualname__] attribute is valid for a [class] or [function], but invalid for an [object] instantiated from a [class]
    LClassName = __qualname__

    #002. Constructor
    #[ASSUMPTION]
    #[1] We cannot define <eSig> inside the body of class definition, as in such case it is created after the initialization of
    #     the class; while we need it to be called at the initialization

    @eSig
    def __init__(
        self
        ,obsDate = dt.date.today()
        ,*pos
        ,**kw
    ):
        #001. Handle parameters
        self._eSig_ = eSig
        args_share = {'self' : self}
        eSig.vfyConflict(args_share)

        #050. Reshape the parameters passed for the call
        pos_int, kw_int = self._eSig_.insParams(args_share, pos, kw)

        #100. Assign values to local variables
        self.fmtDateIn = self._eSig_.getParam('fmtDateIn', pos_int, kw_int, inc_default = True)
        self._map_stack_ : dict = {
            'idRow' : '_obsKRow_'
            ,'idCol' : '_obsKCol_'
        }
        int_obs = self._obsDate_T(obsDate)['D_DATE']
        fr_default_clnBgn = self._eSig_.isDefault('clnBgn', scope_ = 'src')
        fr_default_clnEnd = self._eSig_.isDefault('clnEnd', scope_ = 'src')

        #300. Determine the bounds of the internal calendar, given either of them is not provided at initialization
        #310. Identify the valid dates from the input
        int_clnBgn = (
            asDates(
                pd.Series(self._eSig_.getParam('clnBgn', pos_int, kw_int, inc_default = True), dtype = 'object')
                ,self.fmtDateIn
            )
            .loc[lambda x: x.notnull()]
        )
        int_clnEnd = (
            asDates(
                pd.Series(self._eSig_.getParam('clnEnd', pos_int, kw_int, inc_default = True), dtype = 'object')
                ,self.fmtDateIn
            )
            .loc[lambda x: x.notnull()]
        )
        int_obsDate = int_obs.loc[lambda x: x.notnull()]

        #317. Raise exception for invalid input
        if len(int_clnBgn) > 1:
            raise ValueError(f'[{self.LClassName}]Multiple <clnBgn> provided!')
        if len(int_clnEnd) > 1:
            raise ValueError(f'[{self.LClassName}]Multiple <clnEnd> provided!')
        if (len(int_obsDate) == 0) and (len(int_clnBgn) == 0):
            raise ValueError(f'[{self.LClassName}]Both <obsDate> and <clnBgn> are invalid!')
        if (len(int_obsDate) == 0) and (len(int_clnEnd) == 0):
            raise ValueError(f'[{self.LClassName}]Both <obsDate> and <clnEnd> are invalid!')

        #319. Warn for invalid input that can be overridden
        if len(int_clnBgn) == 0:
            warn(f'[{self.LClassName}]<clnBgn> is invalid and will be calculated from the minimum among <obsDate>!')
        if len(int_clnEnd) == 0:
            warn(f'[{self.LClassName}]<clnEnd> is invalid and will be calculated from the maximum among <obsDate>!')

        #340. Transform the calendar when necessary
        if len(int_obsDate) > 0:
            #100. Determine the beginning
            if fr_default_clnBgn or (len(int_clnBgn) == 0):
                #900. Set it to the beginning of its previous year, which is earlier than that all existing methods can calculate
                #[ASSUMPTION]
                #[1] For [pandas == 1.2.1],the method [pd.Series.min(skipna = True)] cannot ignore [pd.NaT]
                tmpdate = int_obsDate.min(skipna = True)
                int_clnBgn = tmpdate.replace(year = tmpdate.year - 1, month = 1, day = 1)

            #700. Determine the ending
            if fr_default_clnEnd or (len(int_clnEnd) == 0):
                #900. Set it to the end of its next year, which is later than that all existing methods can calculate
                tmpdate = int_obsDate.max(skipna = True)
                int_clnEnd = tmpdate.replace(year = tmpdate.year + 1, month = 12, day = 31)

        #500. Instantiate parent class
        args_upd = {
            'clnBgn' : int_clnBgn
            ,'clnEnd' : int_clnEnd
        }
        pos_sup, kw_sup = self._eSig_.updParams(args_upd, pos_int, kw_int)

        #[ASSUMPTION]
        #[1] <self> is the first POSITIONAL_ONLY or POSITIONAL_OR_KEYWORD argument in the parent class
        #[2] Should it exist in [pos_sup, kw_sup], it can only exist in either of them
        #[3] We should eliminate it from being passed on to the parent call
        if pos_sup:
            pos_super = pos_sup[1:]
        else:
            pos_super = pos_sup
        if 'self' in kw_sup:
            kw_super = {k:v for k,v in kw_sup.items() if k != 'self'}
        else:
            kw_super = kw_sup

        super().__init__(*pos_super, **kw_super)

        #700. Verify the input values
        #Quote: https://stackoverflow.com/questions/38254290/pass-two-arguments-in-python-property-setter
        self.values = obsDate

        #800. Create the user calendar, for it contains more columns that are required for calculation in this class
        self._uniclndr_ : pd.DataFrame = self._subCalendar( datebgn = self.clnBgn , dateend = self.clnEnd )
    #End of [__init__]

    #005. Define the attributes that can be accessed from inside
    __slots__ = (
        '_eSig_'
        , '_uniclndr_' , '_inputs_' , '_obs_df_' , '_v_struct_' , '_v_index_' , '_map_stack_'
    )

    #010. Define the document when printing an object instantiated from current class
    def __str__( self ):
        return(f'Date Shifting and Verification tool in accordance with User Defined Calendar for [{self.country}]')

    #011. Define the representation of the object
    __repr__ = __str__

    #050. Local variables at instantiation (before initialization)
    #Below variables cannot be set in [__slots__] due to conflict; hence they are neither able to be modified at runtime

    #100. Prepare helper functions
    #110. Function to process the unstacked data before type conversion
    def _chg_dtype(self, df) -> pd.DataFrame:
        #010. Create a copy of the input data to avoid unexpected result
        #[ASSUMPTION]
        #[1] [pd.DataFrame.fillna(pd.NaT)] will imperatively change the [dtype] of [datetime] into [pd.Timestamp]
        #[2] For scenarios other than <date> output, the caller functions will have filled NA values, hence there is no
        #     need to worry about the <fillna> result here
        df_out = df.copy(deep = True).fillna(pd.NaT)

        #100. Find all columns of above data that are stored as [datetime64[ns]], i.e. [pd.Timestamp]
        conv_dtcol = [ c for c in df_out.columns if str(df_out.dtypes[c]).startswith('datetime') ]

        #500. Re-assign the output values in terms of the request
        #[ASSUMPTION]
        #[1] [pd.DataFrame.unstack()] will imperatively change the [dtype] of [datetime] into [pd.Timestamp]
        #[2] [pd.Series.dt.to_pydatetime()] creates a [list] as output, hence we need to set proper indexes for it
        for c in conv_dtcol:
            df_out[c] = pd.Series(df_out[c].dt.to_pydatetime(), dtype = 'object', index = df_out.index)

        #999. Purge
        return(df_out)

    #150. Prepare the helper function to return proper results
    def _rst(self, df, col) -> Any:
        #500. Unstack the underlying data to the same shape as the input one
        #[ASSUMPTION]
        #[1] <col-id> and <row-id> do not have <NA> values
        #[2] There can only be <NA> values in the <col>
        #[3] Hence we have to convert them to <NaT> where necessary
        rstOut = vecUnstack(df, valName = col, modelObj = self._inputs_, funcConv = self._chg_dtype, **self._map_stack_)

        #999. Purge
        #For compatibility purpose, we often refer <obj.values> as an Iterable
        if isinstance(rstOut, Iterable) and (not isinstance(rstOut, str)):
            return(rstOut)
        else:
            return([rstOut])

    #170. Function to transform the input values
    def _obsDate_T(self, udate) -> pd.DataFrame:
        tmpdate = (
            vecStack(udate, valName = 'D_DATE', **self._map_stack_)
            .assign(**{
                '_obsKey_' : lambda x: range(len(x))
                ,'D_DATE' : lambda x: asDates(x['D_DATE'], self.fmtDateIn)
            })
        )

        return(tmpdate)

    #200. Method to shift the provided dates by certain scale
    def shiftDays(
        self
        ,obsDate = None
        ,kshift : ( int , float ) = 0
        ,preserve : bool = False
        ,daytype : str = 'W'
    ) -> dt.date | Iterable[dt.date]:
        #001. Handle parameters
        if obsDate is None: obsDate = self._obs_df_
        if not isinstance(kshift , ( int , float ) ):
            raise TypeError(f'[self.LClassName][kshift]:[{type(kshift)}] must be provided a number!')
        if preserve is None: preserve = False
        if not isinstance(preserve , bool ):
            raise TypeError(f'[self.LClassName][preserve]:[{type(preserve)}] must be provided a boolean value!')
        if not isinstance(daytype , str ):
            raise TypeError(f'[self.LClassName][daytype]:[{type(daytype)}] must be provided a character string!')
        daytype = daytype[0].upper()
        if daytype not in ['W','T']:
            raise ValueError(f'[self.LClassName][daytype]:[{daytype}] must be among [W,T]!')

        #100. Local variables
        #We set the actual shift days as [-1] if [kshift] is not provided or provided as [0]
        kdays : int = math.ceil(kshift) or -1
        fmethod : str = 'ffill' if kdays > 0 else 'bfill'
        col_filter: dict = { 'W' : 'F_WORKDAY' , 'T' : 'F_TradeDay' }
        DateFlag : str = col_filter.get(daytype)

        #200. Prepare the calendar with the least requested columns and set the correct index
        cal_shift = (
            self._uniclndr_
            .copy(deep=True)
            [['D_DATE', DateFlag]]
            .set_index('D_DATE', drop = False)
        )

        #300. Prepare the shifted days by requested type
        df_shift = cal_shift.loc[cal_shift[DateFlag]].copy(deep=True).sort_index(ascending = False)
        df_shift.loc[:, 'D_ShiftedDay'] = df_shift.copy(deep=True)['D_DATE'].shift(kdays).set_axis(df_shift.index, axis = 0)
        cal_shift['D_ShiftedDay'] = df_shift['D_ShiftedDay']
        cal_shift['D_ShiftedDay'] = cal_shift['D_ShiftedDay'].__getattribute__(fmethod)()

        #500. Match the shifted days to the observed dates
        df_out = obsDate.copy(deep=True)
        df_out[['D_ShiftedDay', DateFlag]] = (
            cal_shift
            .reindex(df_out['D_DATE'])
            .set_axis(df_out.index, axis = 0)
            [['D_ShiftedDay', DateFlag]]
        )

        #700. Calculate the shift of days for [obsDate]
        #710. Create a mask on the input data which indicates the records to be shifted or not
        mask_indate = ~( df_out[DateFlag] & preserve )

        #750. Shift the values of [D_DATE] where applicable
        df_out.loc[mask_indate, 'D_DATE'] = df_out.loc[mask_indate, 'D_ShiftedDay']

        #790. Set the invalid dates as [pd.NaT]
        df_out['D_DATE'] = df_out['D_DATE'].fillna(pd.NaT)

        #800. Convert the result into list for output
        #810. Create a mask on the output data which indicates the records to be formatted or not
        mask_null = df_out['D_DATE'].isnull()

        #890. Format as string when required
        if self.DateOutAsStr:
            df_out.loc[mask_null, 'D_DATE'] = ''
            df_out.loc[~mask_null, 'D_DATE'] = df_out.loc[~mask_null, 'D_DATE'].apply(lambda x: x.strftime(self.fmtDateOut))

        #999. Return the values
        return(self._rst(df_out, 'D_DATE'))
    #End of [shiftDays]

    #300. Method to verify whether the observing dates are at the lower/upper bound of the certain period
    def _isBoundOfPeriod(
        self
        ,daytype : str = 'W'
        ,_bound : str = 'head'
        ,_period : str = 'MONTH'
    ) -> bool | Iterable[bool]:
        #001. Handle parameters
        if not isinstance(daytype , str ):
            raise TypeError(f'[self.LClassName][daytype]:[{type(daytype)}] must be provided a character string!')
        daytype = daytype[0].upper()
        if daytype not in ['W','T']:
            raise ValueError(f'[self.LClassName][daytype]:[{daytype}] must be among [W,T]!')
        if not isinstance(_bound , str ):
            raise TypeError(f'[self.LClassName][_bound]:[{type(_bound)}] must be provided a character string!')
        _bound = _bound[0].lower()
        if _bound not in [ v[0] for v in ['head','tail'] ]:
            raise ValueError(f'[self.LClassName][_bound]:[{_bound}] must be among [head,tail]!')
        if not isinstance(_period , str ):
            raise TypeError(f'[self.LClassName]][_period]:[{type(_period)}] must be provided a character string!')
        _period = _period[0].upper()
        if _period not in [ v[0] for v in ['MONTH','QUARTER','WEEK','YEAR'] ]:
            raise ValueError(f'[self.LClassName][_period]:[{_period}] must be among [MONTH,QUARTER,WEEK,YEAR]!')

        #100. Local variables
        col_filter: dict = { 'W' : 'F_WORKDAY' , 'T' : 'F_TradeDay' }
        DateFlag : str = col_filter.get(daytype)
        wk_filter: dict = { 'W' : 'K_WorkWeek' , 'T' : 'K_TradeWeek' }
        WeekFlag : str = wk_filter.get(daytype)
        sort_filter: dict = { 'h' : True , 't' : False }
        SortFlag : str = sort_filter.get(_bound)

        #300. Prepare the data
        #Quote: https://stackoverflow.com/questions/44028898/a-value-is-trying-to-be-set-on-a-copy-of-a-slice-from-a-dataframe-pandas
        #We have to create a copy of the slice, otherwise there will be a warning issued by [pandas]
        cal_bound = (
            self._uniclndr_
            .copy(deep=True)
            .loc[lambda x: x[DateFlag]]
            .set_index('D_DATE', drop = False)
            [['D_DATE', WeekFlag]]
        )

        #500. Conduct different filtration as per request
        if _period=='M':
            cal_bound['C_PRD'] = cal_bound['D_DATE'].apply( lambda x: x.strftime('%Y%m') )
        elif _period=='Q':
            cal_bound['C_PRD'] = (
                cal_bound['D_DATE']
                .apply( lambda x: x.year)
                .astype('str')
                .add('Q')
                .add(asQuarters(cal_bound['D_DATE']).astype('str'))
            )
        elif _period=='W':
            cal_bound['C_PRD'] = cal_bound[WeekFlag]
        elif _period=='Y':
            cal_bound['C_PRD'] = cal_bound['D_DATE'].apply( lambda x: x.year )
        else:
            raise ValueError('[' + self.LClassName + '][_period]:[{0}] is not recognized!'.format( _period ))

        #700. Filter the result
        #710. Identify the requested bound of the period as anchors for further calculation
        #Quote: https://stackoverflow.com/questions/27842613/pandas-groupby-sort-within-groups
        #Quote: https://stackoverflow.com/questions/20122521/is-there-an-ungroup-by-operation-opposite-to-groupby-in-pandas
        #Quote: https://pandas.pydata.org/pandas-docs/stable/user_guide/groupby.html#groupby-sorting
        prd_bound = (
            cal_bound
            .drop(columns = 'D_DATE')
            .sort_index(ascending = SortFlag)
            .groupby('C_PRD', sort = False, as_index = False)
            .head(1)
        )

        #750. Prepare to match the observing dates to above anchors
        df_out = self._obs_df_.copy(deep=True).set_index('D_DATE')

        #790. Identify the boundaries
        #Below variable is a [np.ndarray]
        df_out.loc[:, '_flag_'] = df_out.index.isin(prd_bound.index)

        #800. Prepare the result as a list
        df_out['_flag_'] = df_out['_flag_'].fillna(False)

        #999. Return the result
        return(self._rst(df_out, '_flag_'))
    #End of [_isBoundOfPeriod]

    #501. Print the parameters into log
    @property
    def params( self ):
        print( 'Beginning of the Universal Calendar:[' + self.clnBgn.strftime('%Y-%m-%d') + ']' )
        print( 'Ending of the Universal Calendar:[' + self.clnEnd.strftime('%Y-%m-%d') + ']' )
        print( 'Observing dates (first 5 ones at most):' )
        tmpval = self.values
        if self._v_struct_:
            print( tmpval.info() )
        elif self._v_index_:
            print( tmpval.take(range(min(5, len(tmpval)))) )
        else:
            print( tmpval[:min(5, len(tmpval))] )
        print( 'Country Code:[' + self.country + ']' )
        print( 'Calendar Adjustment:[' + self.clnAdj + ']' )
        print( 'How to input the strings into dates:[' + ']['.join(self.fmtDateIn) + ']' )
        print( 'How to display the results as formatted in string:[' + self.fmtDateOut + ']' )
        print( '# of days to extend the calculation before beginning and after ending:[' + str(self.datespan.days) + ']' )
    #End of [params]

    #510. Whether the observing dates are Work Days
    @property
    def isWorkDay( self ) -> bool | Iterable[bool]:
        df_out = self._obs_df_.copy(deep=True)
        df_out.loc[:, 'F_WORKDAY'] = (
            self._uniclndr_
            [['D_DATE' , 'F_WORKDAY']]
            .set_index('D_DATE')
            .reindex(df_out['D_DATE'])
            .set_axis(df_out.index, axis = 0)
            ['F_WORKDAY']
        )
        df_out['F_WORKDAY'] = df_out['F_WORKDAY'].fillna(False)
        return(self._rst(df_out, 'F_WORKDAY'))

    #511. Whether the observing dates are bounds of certain periods
    @property
    def isFirstWDofMon( self ) -> bool | Iterable[bool]:
        return( self._isBoundOfPeriod( daytype = 'w', _bound = 'h', _period = 'm' ) )

    @property
    def isLastWDofMon( self ) -> bool | Iterable[bool]:
        return( self._isBoundOfPeriod( daytype = 'w', _bound = 't', _period = 'm' ) )

    @property
    def isFirstWDofQtr( self ) -> bool | Iterable[bool]:
        return( self._isBoundOfPeriod( daytype = 'w', _bound = 'h', _period = 'q' ) )

    @property
    def isLastWDofQtr( self ) -> bool | Iterable[bool]:
        return( self._isBoundOfPeriod( daytype = 'w', _bound = 't', _period = 'q' ) )

    @property
    def isFirstWDofWeek( self ) -> bool | Iterable[bool]:
        return( self._isBoundOfPeriod( daytype = 'w', _bound = 'h', _period = 'w' ) )

    @property
    def isLastWDofWeek( self ) -> bool | Iterable[bool]:
        return( self._isBoundOfPeriod( daytype = 'w', _bound = 't', _period = 'w' ) )

    @property
    def isFirstWDofYear( self ) -> bool | Iterable[bool]:
        return( self._isBoundOfPeriod( daytype = 'w', _bound = 'h', _period = 'y' ) )

    @property
    def isLastWDofYear( self ) -> bool | Iterable[bool]:
        return( self._isBoundOfPeriod( daytype = 'w', _bound = 't', _period = 'y' ) )

    #520. Whether the observing dates are Trade Days
    @property
    def isTradeDay( self ) -> bool | Iterable[bool]:
        df_out = self._obs_df_.copy(deep=True)
        df_out.loc[:, 'F_TradeDay'] = (
            self._uniclndr_
            [['D_DATE' , 'F_TradeDay']]
            .set_index('D_DATE')
            .reindex(df_out['D_DATE'])
            .set_axis(df_out.index, axis = 0)
            ['F_TradeDay']
        )
        df_out['F_TradeDay'] = df_out['F_TradeDay'].fillna(False)
        return(self._rst(df_out, 'F_TradeDay'))

    #521. Whether the observing dates are bounds of certain periods
    @property
    def isFirstTDofMon( self ) -> bool | Iterable[bool]:
        return( self._isBoundOfPeriod( daytype = 't', _bound = 'h', _period = 'm' ) )

    @property
    def isLastTDofMon( self ) -> bool | Iterable[bool]:
        return( self._isBoundOfPeriod( daytype = 't', _bound = 't', _period = 'm' ) )

    @property
    def isFirstTDofQtr( self ) -> bool | Iterable[bool]:
        return( self._isBoundOfPeriod( daytype = 't', _bound = 'h', _period = 'q' ) )

    @property
    def isLastTDofQtr( self ) -> bool | Iterable[bool]:
        return( self._isBoundOfPeriod( daytype = 't', _bound = 't', _period = 'q' ) )

    @property
    def isFirstTDofWeek( self ) -> bool | Iterable[bool]:
        return( self._isBoundOfPeriod( daytype = 't', _bound = 'h', _period = 'w' ) )

    @property
    def isLastTDofWeek( self ) -> bool | Iterable[bool]:
        return( self._isBoundOfPeriod( daytype = 't', _bound = 't', _period = 'w' ) )

    @property
    def isFirstTDofYear( self ) -> bool | Iterable[bool]:
        return( self._isBoundOfPeriod( daytype = 't', _bound = 'h', _period = 'y' ) )

    @property
    def isLastTDofYear( self ) -> bool | Iterable[bool]:
        return( self._isBoundOfPeriod( daytype = 't', _bound = 't', _period = 'y' ) )

    #531. Last Calendar Day of previous year
    @property
    def prevYearLCD( self ) -> dt.date | Iterable[dt.date]:
        #100. Identify the first calendar dates of the years of current dates and roll them back by one day respectively
        df_out = (
            self._obs_df_
            .copy(deep=True)
            .assign(**{
                'D_DATE' : lambda x: x['D_DATE'].apply(lambda y: y.replace(month = 1, day = 1) - dt.timedelta(days=1))
            })
        )

        #500. Format as string when required
        if self.DateOutAsStr:
            mask_null = df_out['D_DATE'].isnull()
            df_out.loc[mask_null, 'D_DATE'] = ''
            df_out.loc[~mask_null, 'D_DATE'] = df_out.loc[~mask_null, 'D_DATE'].apply(lambda x: x.strftime(self.fmtDateOut))

        #999. Return the values
        return(self._rst(df_out, 'D_DATE'))

    #532. Last Work Day of previous year
    @property
    def prevYearLWD( self ) -> dt.date | Iterable[dt.date]:
        #100. Identify the first calendar dates of the years of current dates
        l_df = self._obs_df_.copy(deep=True)
        l_df['D_DATE'] = l_df['D_DATE'].apply(lambda x: x.replace(month = 1, day = 1))

        #999. Return the Previous Workdays of above dates
        return( self.shiftDays( kshift = -1, preserve = False, daytype = 'w', obsDate = l_df ) )

    #533. Last Trade Day of previous year
    @property
    def prevYearLTD( self ) -> dt.date | Iterable[dt.date]:
        #100. Identify the first calendar dates of the years of current dates
        l_df = self._obs_df_.copy(deep=True)
        l_df['D_DATE'] = l_df['D_DATE'].apply(lambda x: x.replace(month = 1, day = 1))

        #999. Return the Previous Tradedays of above dates
        return( self.shiftDays( kshift = -1, preserve = False, daytype = 't', obsDate = l_df ) )

    #534. Last Calendar Day of previous quarter
    @property
    def prevQtrLCD( self ) -> dt.date | Iterable[dt.date]:
        #100. Find the first months of the same quarter to current dates and roll them back by one day respectively
        #Quote:(Floor #0) https://stackoverflow.com/questions/16864201/calculate-the-end-of-the-previous-quarter
        df_out = (
            self._obs_df_
            .copy(deep=True)
            .assign(**{
                'D_DATE' : lambda x: x['D_DATE'].apply(
                    lambda y: y.replace(month = ((y.month - 1) // 3) * 3 + 1, day = 1) - dt.timedelta(days=1)
                )
            })
        )

        #500. Format as string when required
        if self.DateOutAsStr:
            mask_null = df_out['D_DATE'].isnull()
            df_out.loc[mask_null, 'D_DATE'] = ''
            df_out.loc[~mask_null, 'D_DATE'] = df_out.loc[~mask_null, 'D_DATE'].apply(lambda x: x.strftime(self.fmtDateOut))

        #999. Return the values
        return(self._rst(df_out, 'D_DATE'))

    #535. Last Work Day of previous quarter
    @property
    def prevQtrLWD( self ) -> dt.date | Iterable[dt.date]:
        #100. Find the first month of the same quarter to current date
        l_df = self._obs_df_.copy(deep=True)
        l_df['D_DATE'] = l_df['D_DATE'].apply(
            lambda x: x.replace(month = ((x.month - 1) // 3) * 3 + 1, day = 1)
        )

        #999. Return the Previous Workdays of above dates
        return( self.shiftDays( kshift = -1, preserve = False, daytype = 'w', obsDate = l_df ) )

    #536. Last Trade Day of previous quarter
    @property
    def prevQtrLTD( self ) -> dt.date | Iterable[dt.date]:
        #100. Find the first month of the same quarter to current date
        l_df = self._obs_df_.copy(deep=True)
        l_df['D_DATE'] = l_df['D_DATE'].apply(
            lambda x: x.replace(month = ((x.month - 1) // 3) * 3 + 1, day = 1)
        )

        #999. Return the Previous Tradedays of above dates
        return( self.shiftDays( kshift = -1, preserve = False, daytype = 't', obsDate = l_df ) )

    #540. Previous month
    @property
    def prevMon( self ) -> dt.date | Iterable[dt.date]:
        #100. Find the first day of the same month to current dates and roll them back by one day respectively
        df_out = (
            self._obs_df_
            .copy(deep=True)
            .assign(**{
                'D_DATE' : lambda x: x['D_DATE'].apply(lambda y: y.replace(day = 1) - dt.timedelta(days=1))
            })
        )

        #500. Format as string when required
        mask_null = df_out['D_DATE'].isnull()
        df_out.loc[mask_null, 'D_DATE'] = ''
        df_out.loc[~mask_null, 'D_DATE'] = df_out.loc[~mask_null, 'D_DATE'].apply(lambda x: x.strftime('%Y%m'))

        #999. Return the values
        return(self._rst(df_out, 'D_DATE'))

    #541. Last Calendar Day of the previous month
    @property
    def prevMonLCD( self ) -> dt.date | Iterable[dt.date]:
        #100. Find the first day of the same month to current dates and roll them back by one day respectively
        df_out = (
            self._obs_df_
            .copy(deep=True)
            .assign(**{
                'D_DATE' : lambda x: x['D_DATE'].apply(lambda y: y.replace(day = 1) - dt.timedelta(days=1))
            })
        )

        #500. Format as string when required
        if self.DateOutAsStr:
            mask_null = df_out['D_DATE'].isnull()
            df_out.loc[mask_null, 'D_DATE'] = ''
            df_out.loc[~mask_null, 'D_DATE'] = df_out.loc[~mask_null, 'D_DATE'].apply(lambda x: x.strftime(self.fmtDateOut))

        #999. Return the values
        return(self._rst(df_out, 'D_DATE'))

    #542. Last Work Day of the previous month
    @property
    def prevMonLWD( self ) -> dt.date | Iterable[dt.date]:
        #100. Find the first day of the same month to current dates
        l_df = self._obs_df_.copy(deep=True)
        l_df['D_DATE'] = l_df['D_DATE'].apply(
            lambda x: x.replace(day = 1)
        )

        #999. Return the Previous Workdays of above dates
        return( self.shiftDays( kshift = -1, preserve = False, daytype = 'w', obsDate = l_df ) )

    #543. Last Trade Day of the previous month
    @property
    def prevMonLTD( self ) -> dt.date | Iterable[dt.date]:
        #100. Find the first day of the same month to current dates
        l_df = self._obs_df_.copy(deep=True)
        l_df['D_DATE'] = l_df['D_DATE'].apply(
            lambda x: x.replace(day = 1)
        )

        #999. Return the Previous Tradedays of above dates
        return( self.shiftDays( kshift = -1, preserve = False, daytype = 't', obsDate = l_df ) )

    #550. Previous Work Day
    @property
    def prevWorkDay( self ) -> dt.date | Iterable[dt.date]:
        return( self.shiftDays( kshift = -1, preserve = False, daytype = 'w' ) )

    #551. Second Previous Work Day in line
    @property
    def prevWorkDay2( self ) -> dt.date | Iterable[dt.date]:
        return( self.shiftDays( kshift = -2, preserve = False, daytype = 'w' ) )

    #552. Previous month to the Previous Work Day of current date
    @property
    def prevMonToPWD( self ) -> dt.date | Iterable[dt.date]:
        #100. Store the current parameters
        int_flag = self.DateOutAsStr
        int_value = self.values

        #300. Find the previous work days to current dates
        self.DateOutAsStr = False
        self.values = self.prevWorkDay

        #500. Find the Previous Months to above dates
        self.DateOutAsStr = int_flag
        valout = self.prevMon

        #700. Restore the parameters
        self.values = int_value

        #999. Return the values
        return( valout )

    #553. Last Calendar Day of previous month to the Previous Work Day of current date
    @property
    def prevMonLCDToPWD( self ) -> dt.date | Iterable[dt.date]:
        #100. Store the current parameters
        int_flag = self.DateOutAsStr
        int_value = self.values

        #300. Find the previous work days to current dates
        self.DateOutAsStr = False
        self.values = self.prevWorkDay

        #500. Find the Last Calendar Days of the Previous Months to above dates
        self.DateOutAsStr = int_flag
        valout = self.prevMonLCD

        #700. Restore the parameters
        self.values = int_value

        #999. Return the values
        return( valout )

    #554. Last Work Day of previous month to the Previous Work Day of current date
    @property
    def prevMonLWDToPWD( self ) -> dt.date | Iterable[dt.date]:
        #100. Store the current parameters
        int_flag = self.DateOutAsStr
        int_value = self.values

        #300. Find the previous work days to current dates
        self.DateOutAsStr = False
        self.values = self.prevWorkDay

        #500. Find the Last Work Days of the Previous Months to above dates
        self.DateOutAsStr = int_flag
        valout = self.prevMonLWD

        #700. Restore the parameters
        self.values = int_value

        #999. Return the values
        return( valout )

    #560. Next Work Day
    @property
    def nextWorkDay( self ) -> dt.date | Iterable[dt.date]:
        return( self.shiftDays( kshift = 1, preserve = False, daytype = 'w' ) )

    #570. Previous Trade Day
    @property
    def prevTradeDay( self ) -> dt.date | Iterable[dt.date]:
        return( self.shiftDays( kshift = -1, preserve = False, daytype = 't' ) )

    #571. Second Previous Trade Day in line
    @property
    def prevTradeDay2( self ) -> dt.date | Iterable[dt.date]:
        return( self.shiftDays( kshift = -2, preserve = False, daytype = 't' ) )

    #572. Previous month to the Previous Trade Day of current date
    @property
    def prevMonToPTD( self ) -> dt.date | Iterable[dt.date]:
        #100. Store the current parameters
        int_flag = self.DateOutAsStr
        int_value = self.values

        #300. Find the previous trade days to current dates
        self.DateOutAsStr = False
        self.values = self.prevTradeDay

        #500. Find the Previous Months to above dates
        self.DateOutAsStr = int_flag
        valout = self.prevMon

        #700. Restore the parameters
        self.values = int_value

        #999. Return the values
        return( valout )

    #573. Last Calendar Day of previous month to the Previous Trade Day of current date
    @property
    def prevMonLCDToPTD( self ) -> dt.date | Iterable[dt.date]:
        #100. Store the current parameters
        int_flag = self.DateOutAsStr
        int_value = self.values

        #300. Find the previous trade days to current dates
        self.DateOutAsStr = False
        self.values = self.prevTradeDay

        #500. Find the Previous Months to above dates
        self.DateOutAsStr = int_flag
        valout = self.prevMonLCD

        #700. Restore the parameters
        self.values = int_value

        #999. Return the values
        return( valout )

    #574. Last Trade Day of previous month to the Previous Trade Day of current date
    @property
    def prevMonLTDToPTD( self ) -> dt.date | Iterable[dt.date]:
        #100. Store the current parameters
        int_flag = self.DateOutAsStr
        int_value = self.values

        #300. Find the previous trade days to current dates
        self.DateOutAsStr = False
        self.values = self.prevTradeDay

        #500. Find the Previous Months to above dates
        self.DateOutAsStr = int_flag
        valout = self.prevMonLTD

        #700. Restore the parameters
        self.values = int_value

        #999. Return the values
        return( valout )

    #580. Next Trade Day
    @property
    def nextTradeDay( self ) -> dt.date | Iterable[dt.date]:
        return( self.shiftDays( kshift = 1, preserve = False, daytype = 't' ) )

    #702. Get and set the values of the observing dates
    @property
    def values( self ) -> dt.date | Iterable[dt.date]:
        return(self._rst(self._obs_df_, 'D_DATE'))
    @values.setter
    def values( self , udate ):
        #100. Reset it to [today] if it is provided but with no value
        if udate is None:
            warn(f'[{self.LClassName}]No value is provided for [Observing Dates], reset it to today.')
            udate = dt.date.today()

        #300. Translate the input values if any
        tmpdate = self._obsDate_T(udate)

        #500. Detect all values that exceed the boundaries of the universal calendar
        mask_date = (tmpdate['D_DATE'] < self.clnBgn) | (tmpdate['D_DATE'] > self.clnEnd)
        tmpdate.loc[mask_date, 'D_DATE'] = pd.NaT

        #900. Update the environment as per request
        #910. Retrieve the attribute of the input
        self._inputs_ = udate
        self._v_struct_ = isinstance(udate, (pd.DataFrame, pd.Series))
        self._v_index_ = isinstance(udate, pd.Index)

        #995. Refresh the data frame with the [obsDate] for calculation
        self._obs_df_ = tmpdate
    #End of [values]

#End Class

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #100.   Create envionment.
    import datetime as dt
    import pandas as pd
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.Dates import ObsDates, asDates

    #100. Setup the Calendar.
    thisday = ObsDates()
    # Check parameters.
    thisday.params
    #Assign special dates for calculation (Note the sequence of the dates)
    thisday.values = [ dt.date(2021,2,14) , pd.NaT , '2021-02-21' ]
    # Check parameters again.
    thisday.params

    #100. Apply public function for customized shift
    thisday.DateOutAsStr = True
    ttt = thisday.shiftDays( kshift = -1, preserve = True, daytype = 'W' )
    thisday.DateOutAsStr = False

    #200. Retrieve the active-binding methods for the above dates
    #Last Tradeday of the Previous Month to the Previous Tradeday of the input dates
    thisday.prevMonLTDToPTD

    #300. Provide a data frame as input values
    dt_df = pd.DataFrame({
        'a' : asDates(pd.Series([dt.date.today(), '20190412', '20200925'], dtype = 'object'))
        ,'b' : asDates(pd.Series([ '20181122', '20200214', pd.NaT ], dtype = 'object'))
    }).set_index(pd.Index([1,3,5]))
    thisday = ObsDates(obsDate = dt_df)
    thisday.values
    thisday.isWorkDay
    thisday.prevMonLCDToPWD

    #700. Test invalid input
    #710. Provide no parameter
    #[ASSUMPTION]
    #[1] In such case, <obsDate> is not provided and the instance falls back to the respective default values of <clnBgn>
    #     and <clnEnd>, hence there is no warning message
    #[2] It has the same behavior as when <obsDate> is provided while <clnBgn> and <clnEnd> are not
    thisday = ObsDates('20260103')
    datevalues = pd.Series(thisday.values, dtype = 'O').apply(lambda x: x.strftime('%Y%m%d')).to_list()
    print(f'thisday.values={datevalues}, {thisday.clnBgn=:%Y%m%d}, {thisday.clnEnd=:%Y%m%d}')
    # thisday.values=['20260103'], thisday.clnBgn=20250101, thisday.clnEnd=20271231

    #730. Provide invalid parameters
    #[ASSUMPTION]
    #[1] In such case, <clnBgn> and/or <clnEnd> are provided with invalid dates, the instance tries to overwrite them with the
    #     requested dates with a warning message
    warnday = ObsDates('20260103', clnBgn = None, clnEnd = None)
    # UserWarning: [ObsDates]<clnBgn> is invalid and will be calculated from the minimum among <obsDate>!
    # UserWarning: [ObsDates]<clnEnd> is invalid and will be calculated from the maximum among <obsDate>!

    datevalues = pd.Series(warnday.values, dtype = 'O').apply(lambda x: x.strftime('%Y%m%d')).to_list()
    print(f'warnday.values={datevalues}, {warnday.clnBgn=:%Y%m%d}, {warnday.clnEnd=:%Y%m%d}')
    # warnday.values=['20260103'], warnday.clnBgn=20250101, warnday.clnEnd=20271231

    #750. Provide invalid value for <obsDate>
    defday = ObsDates(None)
    # UserWarning: [ObsDates]No value is provided for [Observing Dates], reset it to today.
#-Notes- -End-
'''
