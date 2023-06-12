#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#001. Import necessary functions for processing.
import datetime as dt
import math
import pandas as pd
from copy import deepcopy
from warnings import warn
from collections.abc import Iterable
from omniPy.AdvOp import vecStack, vecUnstack
from omniPy.Dates import asDates, asQuarters, CoreUserCalendar

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
#   |   |[initialize]                                                                                                                   #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to instantiate a User Calender object                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[obsDate      ]   :   Vector/list of observing dates to evaluate                                                           #
#   |   |   |                      [dt.date.today()     ]<Default> System date at class instantiation                                   #
#   |   |   |[clnBgn       ]   :   Beginning date of the universal calendar, provided by any object that can be coerced to [Date] class #
#   |   |   |                      [<obsDate - 1 year>  ]<Default> Beginning of the year before the minimum of [obsDate]                #
#   |   |   |[clnEnd       ]   :   Ending date of the universal calendar, provided by any object that can be coerced to [Date] class    #
#   |   |   |                      [<obsDate year end>  ]<Default> End of the year of the maximum of [obsDate]                          #
#   |   |   |[countrycode  ]   :   Country Code to select the weekday names from the internal mapping table                             #
#   |   |   |                      [CN                  ]<Default> China                                                                #
#   |   |   |[CalendarAdj  ]   :   CSV file that stores the adjustment instructions of holidays/workdays                                #
#   |   |   |                      [opt('ClndrAdj')     ]<Default> Retrieve the system option [via getOption[]] for the file path       #
#   |   |   |                       [IMPORTANT] The file must contain below columns (case sensitive to column names):                   #
#   |   |   |                                   [CountryCode ] Country Code for selection of adjustment and display of weekday names    #
#   |   |   |                                   [F_WORKDAY   ] [1/0] values indicating [workday/holiday] respectively                   #
#   |   |   |                                   [D_DATE      ] Strings to be imported as [Dates] by default option of [readr:read_csv]  #
#   |   |   |                                   [C_DESC      ] Description/Name of the special dates (compared to: Mon., Tue., etc.)    #
#   |   |   |[fmtDateIn    ]   :   Format of the [obsDate], [clnBgn] and [clnEnd] to be coerced to [Date] class                         #
#   |   |   |                      [<various>           ]<Default> Follow the rules set in [omniPy.asDates]                             #
#   |   |   |[fmtDateOut   ]   :   Format of the output date values to be translated into character strings when necessary              #
#   |   |   |                      [%Y%m%d              ]<Default> Only accept one string as format, see [strftime] convention          #
#   |   |   |[DateOutAsStr ]   :   Whether to convert the output date values into character strings                                     #
#   |   |   |                      [False               ]<Default> Output dates directly in the type of [datetime.date]                 #
#   |   |   |                      [True                ]          Convert dates into strings based on [fmtDateOut]                     #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[ None        ]   :   This method does not return values, but may assign values to variables for [private] object          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[shiftDays]                                                                                                                    #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to obtain the [kshift]th workday/tradeday (by [daytype]) counting from the provided [obsDate]  #
#   |   |   |   | per requested, or return themselves if they are workday/tradeday as indicated by [preserve]                           #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[obsDate      ]   :   Data.frame of observing dates to evaluate                                                            #
#   |   |   |                      [private$.obs_df     ]<Default> Default internal data frame containing observing dates               #
#   |   |   |[kshift       ]   :   Number of workdays/tradedays to shift                                                                #
#   |   |   |                      [0                   ]<Default> Return itself if it is workday/tradeday, or return its Previous      #
#   |   |   |                                                       Workday/Tradeday if it is not                                       #
#   |   |   |[preserve     ]   :   Whether to force returning itself if it is workday/tradeday; no effect if [obsDate] is NOT workday   #
#   |   |   |                       or tradeday, for that the function will always shift days against them as requested                 #
#   |   |   |                      [TRUE                ]<Default> Return [obsDate] if it is workday/tradeday in any case               #
#   |   |   |                      [FALSE               ]          Shift the days no matter [obsDate] is workday/tradeday or not        #
#   |   |   |[daytype      ]   :   Which of the types of dates to shift; Calendar Date is not an option, for there is no need to call   #
#   |   |   |                       this function for calculation                                                                       #
#   |   |   |                      [W                   ]<Default> Workday                                                              #
#   |   |   |                      [T                   ]<Default> Tradeday                                                             #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[ Date        ]   :   Vector of the shifted dates in the same sequence as the input [obsDate]                              #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |400.   Private method                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |[.isBoundOfPeriod]                                                                                                             #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to verify [obsDate] on whether it is the [first/last] of [workdays/tradedays] within specified #
#   |   |   |   | period                                                                                                                #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[daytype      ]   :   Type of the date to verify                                                                           #
#   |   |   |                      [W                   ]<Default> Whether the input date is Workday                                    #
#   |   |   |                      [T                   ]          Whether the input date is Tradeday                                   #
#   |   |   |[_bound       ]   :   Verify whether the date is at the beginning or ending of the period                                  #
#   |   |   |                      [head                ]<Default> Whether the input date is at the beginning                           #
#   |   |   |                      [tail                ]          Whether the input date is at the end                                 #
#   |   |   |[_period      ]   :   Period name to verify the date                                                                       #
#   |   |   |                      [MONTH               ]<Default> Verify the bound of each month                                       #
#   |   |   |                      [QUARTER             ]          Verify the bound of each QUARTER                                     #
#   |   |   |                      [WEEK                ]          Verify the bound of each workweek/tradeweek                          #
#   |   |   |                      [YEAR                ]          Verify the bound of each YEAR                                        #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[ list        ]   :   Logical values of the verification result for each [obsDate] respectively in the same sequence       #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |500.   Read-only properties.                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |100.   Description.                                                                                                            #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |This section lists all the read-only properties of the class.                                                                  #
#   |   |The examples listed are based on the provision of: [cln.values <- c('20210104', '20210102', '20201030', '20210207')]           #
#   |   |[NOTE:] <work week> represents the block of consecutive workdays                                                               #
#   |   |[NOTE:] <trade week> represents the block of consecutive tradedays                                                             #
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
#   |   |   |   |[1] When [set] is called, it changes [private$.obsdates]                                                               #
#   |   |   |   |[2] When [return] is called, it returns the last value of [private$.obsdates]                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[udate        ]   :   Vector/list of dates, or character strings which can be coerced to [Date] class                      #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[<pd.Series>  ]   :   The same values as the previous input by the user                                                    #
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
#   | Log  |[1] Abandon the usage of [pd.Timestamp] for all date-like columns as its lower/upper bounds are much less than [dt.date]    #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210821        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Eliminate all [pd.DataFrame.merge] operations and the most of [.apply] methods to improve the overall efficiency, now   #
#   |      |     use indexing of data frames and the time expense reduced by 90%.                                                       #
#   |      |[2] Now treat all invalid inputs as [pd.NaT] and maintain their positions in the output result                              #
#   |      |[3] Output [pd.NaT] or [empty string] as the shifted ones for invalid inputs                                                #
#   |      |[4] Output [False] as boundary detector for invalid inputs                                                                  #
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
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |See the [Full Test Program] section                                                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |datetime, math, pandas, collections, copy, warnings                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.AdvOp                                                                                                                   #
#   |   |   |vecStack                                                                                                                   #
#   |   |   |vecUnstack                                                                                                                 #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.Dates                                                                                                                   #
#   |   |   |asDates                                                                                                                    #
#   |   |   |asQuarters                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Parent classes                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.Dates                                                                                                                   #
#   |   |   |CoreUserCalendar                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Identify the qualified name of current class (for logging purpose at large)
    #Quote: https://www.python.org/dev/peps/pep-3155/
    #[1] [__qualname__] attribute is valid for a [class] or [function], but invalid for an [object] instantiated from a [class]
    LClassName = __qualname__

    #002. Constructor
    def __init__(
        self
        ,obsDate = dt.date.today()
        ,clnBgn = None
        ,clnEnd = None
        ,countrycode : str = 'CN'
        ,CalendarAdj : Iterable = None
        ,fmtDateIn : Iterable = ['%Y%m%d', '%Y-%m-%d', '%Y/%m/%d']
        ,fmtDateOut : str = '%Y%m%d'
        ,DateOutAsStr : bool = False
    ):
        #001. Handle parameters

        #100. Assign values to local variables
        self.fmtDateIn = fmtDateIn
        self._map_stack_ : dict = {
            'idRow' : '_obsKRow_'
            ,'idCol' : '_obsKCol_'
        }
        int_obs = self._obsDate_T(obsDate)['D_DATE'].copy(deep=True)

        #300. Determine the bounds of the internal calendar, given either of them is not provided at initialization
        #310. Identify the valid dates from the input
        int_clnBgn = asDates(pd.Series(clnBgn, dtype = 'object')).loc[lambda x: x.notnull()]
        int_clnEnd = asDates(pd.Series(clnEnd, dtype = 'object')).loc[lambda x: x.notnull()]

        #340. Transform the beginning when necessary
        if (len(int_clnBgn) != 1):
            #100. Seek help from the input values
            int_clnBgn = int_obs.loc[lambda x: x.notnull()]

            #500. Set it when the input values can neither help
            #For [pandas == 1.2.1],the method [pd.Series.min(skipna = True)] cannot ignore [pd.NaT]
            if len(int_clnBgn) == 0:
                int_clnBgn = dt.date.today()
            else:
                int_clnBgn = int_clnBgn.min(skipna = True)

            #900. Set it to the beginning of its previous year, which is earlier than that all existing methods can calculate
            int_clnBgn = int_clnBgn.replace(year = int_clnBgn.year - 1, month = 1, day = 1)
        else:
            int_clnBgn = int_clnBgn.iat[0]

        #370. Transform the ending when necessary
        if (len(int_clnEnd) != 1):
            #100. Seek help from the input values
            int_clnEnd = int_obs.loc[lambda x: x.notnull()]

            #500. Set it when the input values can neither help
            if len(int_clnEnd) == 0:
                int_clnEnd = dt.date.today()
            else:
                int_clnEnd = int_clnEnd.max(skipna = True)

            #900. Set it to the end of its next year, which is later than that all existing methods can calculate
            int_clnEnd = int_clnEnd.replace(year = int_clnEnd.year + 1, month = 12, day = 31)
        else:
            int_clnEnd = int_clnEnd.iat[0]

        #500. Instantiate parent class
        super(ObsDates,self).__init__(
            clnBgn = int_clnBgn
            ,clnEnd = int_clnEnd
            ,countrycode = countrycode
            ,CalendarAdj = CalendarAdj
            ,fmtDateIn = fmtDateIn
            ,fmtDateOut = fmtDateOut
            ,DateOutAsStr = DateOutAsStr
        )

        #700. Verify the input values
        #Quote: https://stackoverflow.com/questions/38254290/pass-two-arguments-in-python-property-setter
        self.values = obsDate

        #800. Create the user calendar, for it contains more columns that are required for calculation in this class
        self._uniclndr_ : pd.DataFrame = self._subCalendar( datebgn = self.clnBgn , dateend = self.clnEnd )
    #End of [__init__]

    #005. Define the attributes that can be accessed from inside
    __slots__ = (
        '_uniclndr_' , '_inputs_' , '_obs_df_' , '_v_struct_' , '_v_index_' , '_map_stack_'
    )

    #010. Define the document when printing an object instantiated from current class
    def __str__( self ):
        return( 'Date Shifting and Verification tool in accordance with User Defined Calendar for [{0}]'.format( self.country ) )

    #011. Define the representation of the object
    __repr__ = __str__

    #050. Local variables at instantiation (before initialization)
    #Below variables cannot be set in [__slots__] due to conflict; hence they are neither able to be modified at runtime

    #100. Prepare helper functions
    #110. Function to process the unstacked data before type conversion
    def _chg_dtype(self, df):
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
    def _rst(self, df, col) -> 'Return the result in terms of the shape of [values]':
        #500. Unstack the underlying data to the same shape as the input one
        #[ASSUMPTION]
        #[1] <col-id> and <row-id> do not have <NA> values
        #[2] There can only be <NA> values in the <col>
        #[3] Hence we have to convert them to <NaT> where necessary
        rstOut = vecUnstack(df, valName = col, modelObj = self._inputs_, funcConv = self._chg_dtype, **self._map_stack_)

        #999. Purge
        #For compatibility purpose, we often refer <obj.values> as an Iterable
        if isinstance(rstOut, Iterable):
            return(rstOut)
        else:
            return([rstOut])

    #170. Function to transform the input values
    def _obsDate_T(self, udate) -> 'Transform the input values':
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
    ) -> 'Shift the input dates by <kshift> (Default:-1) in terms of the user requested flag of Work Days or Trade Days':
        #001. Handle parameters
        if obsDate is None: obsDate = self._obs_df_
        if not kshift: kshift = 0
        if not isinstance(kshift , ( int , float ) ):
            raise TypeError('[' + self.LClassName + '][kshift]:[{0}] must be provided a number!'.format( type(kshift) ))
        if preserve is None: preserve = False
        if not isinstance(preserve , bool ):
            raise TypeError('[' + self.LClassName + '][preserve]:[{0}] must be provided a boolean value!'.format( type(preserve) ))
        if not daytype: daytype = 'W'
        if not isinstance(daytype , str ):
            raise TypeError('[' + self.LClassName + '][daytype]:[{0}] must be provided a character string!'.format( type(daytype) ))
        daytype = daytype[0].upper()
        if daytype not in ['W','T']:
            raise ValueError('[' + self.LClassName + '][daytype]:[{0}] must be among [W,T]!'.format( daytype ))

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
        cal_shift['D_ShiftedDay'] = cal_shift['D_ShiftedDay'].fillna( method = fmethod )

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
        df_out['D_DATE'].fillna(pd.NaT, inplace = True)

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
    ) -> 'Verify whether the observing dates are at the lower/upper bound of the certain period':
        #001. Handle parameters
        if not daytype: daytype = 'W'
        if not isinstance(daytype , str ):
            raise TypeError('[' + self.LClassName + '][daytype]:[{0}] must be provided a character string!'.format( type(daytype) ))
        daytype = daytype[0].upper()
        if daytype not in ['W','T']:
            raise ValueError('[' + self.LClassName + '][daytype]:[{0}] must be among [W,T]!'.format( daytype ))
        if not _bound: _bound = 'head'
        if not isinstance(_bound , str ):
            raise TypeError('[' + self.LClassName + '][_bound]:[{0}] must be provided a character string!'.format( type(_bound) ))
        _bound = _bound[0].lower()
        if _bound not in [ v[0] for v in ['head','tail'] ]:
            raise ValueError('[' + self.LClassName + '][_bound]:[{0}] must be among [head,tail]!'.format( _bound ))
        if not _period: _period = 'MONTH'
        if not isinstance(_period , str ):
            raise TypeError('[' + self.LClassName + '][_period]:[{0}] must be provided a character string!'.format( type(_period) ))
        _period = _period[0].upper()
        if _period not in [ v[0] for v in ['MONTH','QUARTER','WEEK','YEAR'] ]:
            raise ValueError('[' + self.LClassName + '][_period]:[{0}] must be among [MONTH,QUARTER,WEEK,YEAR]!'.format( _period ))

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
            cal_bound['C_PRD'] = cal_bound['D_DATE'].apply( lambda x: str(x.year) + 'Q' + str(asQuarters(x)) )
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
        df_out['_flag_'].fillna(False, inplace = True)

        #999. Return the result
        return(self._rst(df_out, '_flag_'))
    #End of [_isBoundOfPeriod]

    #501. Print the parameters into log
    @property
    def params( self ) -> 'Print the parameters into log':
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
    def isWorkDay( self ) -> 'Whether the observing dates are Work Days':
        df_out = self._obs_df_.copy(deep=True)
        df_out.loc[:, 'F_WORKDAY'] = (
            self._uniclndr_
            [['D_DATE' , 'F_WORKDAY']]
            .set_index('D_DATE')
            .reindex(df_out['D_DATE'])
            .set_axis(df_out.index, axis = 0)
            ['F_WORKDAY']
        )
        df_out['F_WORKDAY'].fillna(False, inplace = True)
        return(self._rst(df_out, 'F_WORKDAY'))

    #511. Whether the observing dates are bounds of certain periods
    @property
    def isFirstWDofMon( self ) -> 'Whether the observing dates are First Work Days of their respective months':
        return( self._isBoundOfPeriod( daytype = 'w', _bound = 'h', _period = 'm' ) )

    @property
    def isLastWDofMon( self ) -> 'Whether the observing dates are Last Work Days of their respective months':
        return( self._isBoundOfPeriod( daytype = 'w', _bound = 't', _period = 'm' ) )

    @property
    def isFirstWDofQtr( self ) -> 'Whether the observing dates are First Work Days of their respective quarters':
        return( self._isBoundOfPeriod( daytype = 'w', _bound = 'h', _period = 'q' ) )

    @property
    def isLastWDofQtr( self ) -> 'Whether the observing dates are Last Work Days of their respective quarters':
        return( self._isBoundOfPeriod( daytype = 'w', _bound = 't', _period = 'q' ) )

    @property
    def isFirstWDofWeek( self ) -> 'Whether the observing dates are First Work Days of their respective weeks':
        return( self._isBoundOfPeriod( daytype = 'w', _bound = 'h', _period = 'w' ) )

    @property
    def isLastWDofWeek( self ) -> 'Whether the observing dates are Last Work Days of their respective weeks':
        return( self._isBoundOfPeriod( daytype = 'w', _bound = 't', _period = 'w' ) )

    @property
    def isFirstWDofYear( self ) -> 'Whether the observing dates are First Work Days of their respective years':
        return( self._isBoundOfPeriod( daytype = 'w', _bound = 'h', _period = 'y' ) )

    @property
    def isLastWDofYear( self ) -> 'Whether the observing dates are Last Work Days of their respective years':
        return( self._isBoundOfPeriod( daytype = 'w', _bound = 't', _period = 'y' ) )

    #520. Whether the observing dates are Trade Days
    @property
    def isTradeDay( self ) -> 'Whether the observing dates are Trade Days':
        df_out = self._obs_df_.copy(deep=True)
        df_out.loc[:, 'F_TradeDay'] = (
            self._uniclndr_
            [['D_DATE' , 'F_TradeDay']]
            .set_index('D_DATE')
            .reindex(df_out['D_DATE'])
            .set_axis(df_out.index, axis = 0)
            ['F_TradeDay']
        )
        df_out['F_TradeDay'].fillna(False, inplace = True)
        return(self._rst(df_out, 'F_TradeDay'))

    #521. Whether the observing dates are bounds of certain periods
    @property
    def isFirstTDofMon( self ) -> 'Whether the observing dates are First Trade Days of their respective months':
        return( self._isBoundOfPeriod( daytype = 't', _bound = 'h', _period = 'm' ) )

    @property
    def isLastTDofMon( self ) -> 'Whether the observing dates are Last Trade Days of their respective months':
        return( self._isBoundOfPeriod( daytype = 't', _bound = 't', _period = 'm' ) )

    @property
    def isFirstTDofQtr( self ) -> 'Whether the observing dates are First Trade Days of their respective quarters':
        return( self._isBoundOfPeriod( daytype = 't', _bound = 'h', _period = 'q' ) )

    @property
    def isLastTDofQtr( self ) -> 'Whether the observing dates are Last Trade Days of their respective quarters':
        return( self._isBoundOfPeriod( daytype = 't', _bound = 't', _period = 'q' ) )

    @property
    def isFirstTDofWeek( self ) -> 'Whether the observing dates are First Trade Days of their respective weeks':
        return( self._isBoundOfPeriod( daytype = 't', _bound = 'h', _period = 'w' ) )

    @property
    def isLastTDofWeek( self ) -> 'Whether the observing dates are Last Trade Days of their respective weeks':
        return( self._isBoundOfPeriod( daytype = 't', _bound = 't', _period = 'w' ) )

    @property
    def isFirstTDofYear( self ) -> 'Whether the observing dates are First Trade Days of their respective years':
        return( self._isBoundOfPeriod( daytype = 't', _bound = 'h', _period = 'y' ) )

    @property
    def isLastTDofYear( self ) -> 'Whether the observing dates are Last Work Days of their respective years':
        return( self._isBoundOfPeriod( daytype = 't', _bound = 't', _period = 'y' ) )

    #531. Last Calendar Day of previous year
    @property
    def prevYearLCD( self ) -> 'Last Calendar Day of previous year':
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
    def prevYearLWD( self ) -> 'Last Work Day of previous year':
        #100. Identify the first calendar dates of the years of current dates
        l_df = self._obs_df_.copy(deep=True)
        l_df['D_DATE'] = l_df['D_DATE'].apply(lambda x: x.replace(month = 1, day = 1))

        #999. Return the Previous Workdays of above dates
        return( self.shiftDays( kshift = -1, preserve = False, daytype = 'w', obsDate = l_df ) )

    #533. Last Trade Day of previous year
    @property
    def prevYearLTD( self ) -> 'Last Trade Day of previous year':
        #100. Identify the first calendar dates of the years of current dates
        l_df = self._obs_df_.copy(deep=True)
        l_df['D_DATE'] = l_df['D_DATE'].apply(lambda x: x.replace(month = 1, day = 1))

        #999. Return the Previous Tradedays of above dates
        return( self.shiftDays( kshift = -1, preserve = False, daytype = 't', obsDate = l_df ) )

    #534. Last Calendar Day of previous quarter
    @property
    def prevQtrLCD( self ) -> 'Last Calendar Day of previous quarter':
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
    def prevQtrLWD( self ) -> 'Last Work Day of previous quarter':
        #100. Find the first month of the same quarter to current date
        l_df = self._obs_df_.copy(deep=True)
        l_df['D_DATE'] = l_df['D_DATE'].apply(
            lambda x: x.replace(month = ((x.month - 1) // 3) * 3 + 1, day = 1)
        )

        #999. Return the Previous Workdays of above dates
        return( self.shiftDays( kshift = -1, preserve = False, daytype = 'w', obsDate = l_df ) )

    #536. Last Trade Day of previous quarter
    @property
    def prevQtrLTD( self ) -> 'Last Trade Day of previous quarter':
        #100. Find the first month of the same quarter to current date
        l_df = self._obs_df_.copy(deep=True)
        l_df['D_DATE'] = l_df['D_DATE'].apply(
            lambda x: x.replace(month = ((x.month - 1) // 3) * 3 + 1, day = 1)
        )

        #999. Return the Previous Tradedays of above dates
        return( self.shiftDays( kshift = -1, preserve = False, daytype = 't', obsDate = l_df ) )

    #540. Previous month
    @property
    def prevMon( self ) -> 'Previous month in the format of [YYYYMM]':
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
    def prevMonLCD( self ) -> 'Last Calendar Day of the previous month':
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
    def prevMonLWD( self ) -> 'Last Work Day of the previous month':
        #100. Find the first day of the same month to current dates
        l_df = self._obs_df_.copy(deep=True)
        l_df['D_DATE'] = l_df['D_DATE'].apply(
            lambda x: x.replace(day = 1)
        )

        #999. Return the Previous Workdays of above dates
        return( self.shiftDays( kshift = -1, preserve = False, daytype = 'w', obsDate = l_df ) )

    #543. Last Trade Day of the previous month
    @property
    def prevMonLTD( self ) -> 'Last Trade Day of the previous month':
        #100. Find the first day of the same month to current dates
        l_df = self._obs_df_.copy(deep=True)
        l_df['D_DATE'] = l_df['D_DATE'].apply(
            lambda x: x.replace(day = 1)
        )

        #999. Return the Previous Tradedays of above dates
        return( self.shiftDays( kshift = -1, preserve = False, daytype = 't', obsDate = l_df ) )

    #550. Previous Work Day
    @property
    def prevWorkDay( self ) -> 'Previous Work Day':
        return( self.shiftDays( kshift = -1, preserve = False, daytype = 'w' ) )

    #551. Second Previous Work Day in line
    @property
    def prevWorkDay2( self ) -> 'Second Previous Work Day in line':
        return( self.shiftDays( kshift = -2, preserve = False, daytype = 'w' ) )

    #552. Previous month to the Previous Work Day of current date
    @property
    def prevMonToPWD( self ) -> 'Previous month to the Previous Work Day of current date':
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
    def prevMonLCDToPWD( self ) -> 'Last Calendar Day of previous month to the Previous Work Day of current date':
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
    def prevMonLWDToPWD( self ) -> 'Last Work Day of previous month to the Previous Work Day of current date':
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
    def nextWorkDay( self ) -> 'Next Work Day':
        return( self.shiftDays( kshift = 1, preserve = False, daytype = 'w' ) )

    #570. Previous Trade Day
    @property
    def prevTradeDay( self ) -> 'Previous Trade Day':
        return( self.shiftDays( kshift = -1, preserve = False, daytype = 't' ) )

    #571. Second Previous Trade Day in line
    @property
    def prevTradeDay2( self ) -> 'Second Previous Trade Day in line':
        return( self.shiftDays( kshift = -2, preserve = False, daytype = 't' ) )

    #572. Previous month to the Previous Trade Day of current date
    @property
    def prevMonToPTD( self ) -> 'Previous month to the Previous Trade Day of current date':
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
    def prevMonLCDToPTD( self ) -> 'Last Calendar Day of previous month to the Previous Trade Day of current date':
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
    def prevMonLTDToPTD( self ) -> 'Last Trade Day of previous month to the Previous Trade Day of current date':
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
    def nextTradeDay( self ) -> 'Next Trade Day':
        return( self.shiftDays( kshift = 1, preserve = False, daytype = 't' ) )

    #702. Get and set the values of the observing dates
    @property
    def values( self ) -> 'Get the values of the observing dates':
        return(self._rst(self._obs_df_, 'D_DATE'))
    @values.setter
    def values( self , udate ) -> 'Set the values of the observing dates':
        #100. Reset it to [today] if it is provided but with no value
        if udate is None:
            warn('[' + self.LClassName + ']No value is provided for [Observing Dates], reset it to today.')
            udate = dt.date.today()

        #300. Translate the input values if any
        tmpdate = self._obsDate_T(udate)

        #500. Detect all values that exceed the boundaries of the universal calendar
        mask_date = (tmpdate['D_DATE'] < self.clnBgn) | (tmpdate['D_DATE'] > self.clnEnd)
        tmpdate.loc[mask_date, 'D_DATE'] = pd.NaT

        #900. Update the environment as per request
        #910. Retrieve the attribute of the input
        self._inputs_ = deepcopy(udate)
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
#-Notes- -End-
'''
