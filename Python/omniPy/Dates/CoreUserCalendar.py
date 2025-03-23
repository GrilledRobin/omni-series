#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#001. Import necessary functions for processing.
import datetime as dt
import pandas as pd
from collections.abc import Iterable
from . import asDates, asQuarters, getCalendarAdj

#100. Definition of the class.
class CoreUserCalendar:
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
#   |   |   |[clnBgn       ]   :   Beginning date of the calendar, provided by any object that can be coerced to [Date] class           #
#   |   |   |                      [<today - 5 years>   ]<Default> 5 years counting back from the system date                           #
#   |   |   |[clnEnd       ]   :   Ending date of the calendar, provided by any object that can be coerced to [Date] class              #
#   |   |   |                      [<today + 30 days>   ]<Default> 30 days counting forward from the system date                        #
#   |   |   |[countrycode  ]   :   Country Code to select the weekday names from the internal mapping table                             #
#   |   |   |                      [CN                  ]<Default> China                                                                #
#   |   |   |[CalendarAdj  ]   :   CSV file that stores the adjustment instructions of holidays/workdays                                #
#   |   |   |                      [opt('ClndrAdj')     ]<Default> Retrieve the system option [via getOption()] for the file path       #
#   |   |   |                       [IMPORTANT] The file must contain below columns (case sensitive to column names):                   #
#   |   |   |                                   [CountryCode ] Country Code for selection of adjustment and display of weekday names    #
#   |   |   |                                   [F_WORKDAY   ] [1/0] values indicating [workday/holiday] respectively                   #
#   |   |   |                                   [D_DATE      ] Strings to be imported as [Dates] by default option of [readr:read_csv]  #
#   |   |   |                                   [C_DESC      ] Description/Name of the special dates (compared to: Mon., Tue., etc.)    #
#   |   |   |[fmtDateIn    ]   :   Format of the [datebgn] and [dateend] to be coerced to [Date] class                                  #
#   |   |   |                      [<various>           ]<Default> Follow the rules set in [omniR$asDates]                              #
#   |   |   |[fmtDateOut   ]   :   Format of the output date values to be translated into character strings when necessary              #
#   |   |   |                      [%Y%m%d              ]<Default> Only accept one string as format, see [strftime] convention          #
#   |   |   |[DateOutAsStr ]   :   Whether to convert the output date values into character strings                                     #
#   |   |   |                      [False               ]<Default> Output dates directly in the type of [datetime.date]                 #
#   |   |   |                      [True                ]          Convert dates into strings based on [fmtDateOut]                     #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[ NULL        ]   :   This method does not return values, but may assign values to variables for [private] object          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |400.   Private method                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |[_weekdayname]                                                                                                                 #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to create the mapping table for weekdays to their respective names in different languages      #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[ NULL        ]   :   This method does not take input arguments                                                            #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[ dict        ]   :   Dictionary storing the mapping table of weekdays in different languages                              #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[_crCalendar]                                                                                                                  #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to create the universal calendar within the enclosed environment as instantiated by the class  #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[datebgn      ]   :   Beginning date of the calendar, provided by any object that can be coerced to [Date] class           #
#   |   |   |                      [private$.clnBgn        ]<Default> The value at Calendar initialization                              #
#   |   |   |[dateend      ]   :   Ending date of the calendar, provided by any object that can be coerced to [Date] class              #
#   |   |   |                      [private$.clnEnd        ]<Default> The value at Calendar initialization                              #
#   |   |   |[countrycode  ]   :   Country Code to select the weekday names from the internal mapping table                             #
#   |   |   |                      [private$.countrycode   ]<Default> The value at Calendar initialization                              #
#   |   |   |[CalendarAdj  ]   :   CSV file that stores the adjustment instructions of holidays/workdays                                #
#   |   |   |                      [private$.clnAdj        ]<Default> The value at Calendar initialization                              #
#   |   |   |[infmt        ]   :   Format of the [datebgn] and [dateend] to be coerced to [Date] class                                  #
#   |   |   |                      [private$.fmtDateIn     ]<Default> The value at Calendar initialization                              #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[ df          ]   :   Data.frame storing the adjusted Calendar, yet without the Workweek/Tradeweek information, as they    #
#   |   |   |                       will be separately created when user calls the corresponding methods                                #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |100.   Field specifications for the dataset. (For field types please use [df.info()] for retrieval)                    #
#   |   |   |   |-------------------------|---------------------------------------------------------------------------------------------#
#   |   |   |   |          Field Name     |                                 Field Description                                           #
#   |   |   |   |-------------------------|---------------------------------------------------------------------------------------------#
#   |   |   |   | D_DATE                  | Calendar Date in the type of [Date]                                                         #
#   |   |   |   |-------------------------|---------------------------------------------------------------------------------------------#
#   |   |   |   | C_DESC                  | The description of current Calendar Date                                                    #
#   |   |   |   |-------------------------|---------------------------------------------------------------------------------------------#
#   |   |   |   | F_WORKDAY               | Flag of whether current date is Work Day in terms of user-defined holiday arrangements.     #
#   |   |   |   |-------------------------|---------------------------------------------------------------------------------------------#
#   |   |   |   | F_TradeDay              | Flag of whether current date is Trade Day in terms of user-defined holiday arrangements.    #
#   |   |   |   |                         | Its difference to [F_WORKDAY] is that the Shifted Work Days can often be Saturdays or       #
#   |   |   |   |                         |  Sundays while they are not always Trade Days around the world.                             #
#   |   |   |   |-------------------------|---------------------------------------------------------------------------------------------#
#   |   |   |   | D_PrevWorkDay           | The previous Work Day to current date (in terms of user-defined holiday arrangements)       #
#   |   |   |   |-------------------------|---------------------------------------------------------------------------------------------#
#   |   |   |   | D_NextWorkDay           | The next Work Day to current date (in terms of user-defined holiday arrangements)           #
#   |   |   |   |-------------------------|---------------------------------------------------------------------------------------------#
#   |   |   |   | D_PrevTradeDay          | The previous Trade Day to current date (in terms of user-defined holiday arrangements)      #
#   |   |   |   |-------------------------|---------------------------------------------------------------------------------------------#
#   |   |   |   | D_NextTradeDay          | The previous Trade Day to current date (in terms of user-defined holiday arrangements)      #
#   |   |   |   |-------------------------|---------------------------------------------------------------------------------------------#
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[_subCalendar]                                                                                                                 #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to subset the universal calendar by user request within current instance                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[datebgn      ]   :   Beginning date to subset the calendar, provided by any object that can be coerced to [Date] class    #
#   |   |   |                      [private$.dateBgn       ]<Default> The value per user request on the fly                             #
#   |   |   |[dateend      ]   :   Ending date to subset the calendar, provided by any object that can be coerced to [Date] class       #
#   |   |   |                      [private$.dateEnd       ]<Default> The value per user request on the fly                             #
#   |   |   |[inCln        ]   :   Universal calendar to subset                                                                         #
#   |   |   |                      [private$.uniClndr      ]<Default> The value at Calendar initialization                              #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[ df          ]   :   Data.frame storing the subset of the universal calendar, with the Workweek/Tradeweek information     #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |100.   Field specifications for the dataset. (For field types please use [df.info()] for retrieval)                    #
#   |   |   |   |-------------------------|---------------------------------------------------------------------------------------------#
#   |   |   |   |          Field Name     |                                 Field Description                                           #
#   |   |   |   |-------------------------|---------------------------------------------------------------------------------------------#
#   |   |   |   |<Other fields created as | Keep all other fields in [.crCalendar] with additional field created as below               #
#   |   |   |   | output of [.crCalendar]>|                                                                                             #
#   |   |   |   |-------------------------|---------------------------------------------------------------------------------------------#
#   |   |   |   | K_WorkWeek              | The number of Work Weeks in current period of time (Each Work Week represents a period of   #
#   |   |   |   |                         |  consecutive Work Days)                                                                     #
#   |   |   |   |-------------------------|---------------------------------------------------------------------------------------------#
#   |   |   |   | K_TradeWeek             | The number of Trade Weeks in current period of time (Each Trade Week represents a period of #
#   |   |   |   |                         |  consecutive Trade Days)                                                                    #
#   |   |   |   |-------------------------|---------------------------------------------------------------------------------------------#
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |500.   Read-only properties.                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |100.   Description.                                                                                                            #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |This section lists all the read-only properties of the class.                                                                  #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |       Property Name         |                             Value Examples and Property Description                         #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | uniCalendar                 | <data.frame> data frame of the universal calendar (enclosing the user calendar)             #
#   |   |   | clnAdj                      | <string> Full path of the adjustment file in use, for holidays/workdays                     #
#   |   |   | clnBgn                      | <datetime.date> Beginning date of the universal calendar                                    #
#   |   |   | clnEnd                      | <datetime.date> Ending date of the universal calendar                                       #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Active-binding method                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |[fmtDateIn]                                                                                                                    #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to set or return the user requested format to translate the character strings into dates       #
#   |   |   |   | within specific date input methods defined by this family of classes                                                  #
#   |   |   |   |[1] When [set] is called, it changes [private$.fmtDateIn]; while all methods that translate character strings into     #
#   |   |   |   |     dates will change the input format in accordance                                                                  #
#   |   |   |   |[2] When [return] is called, it returns the last value of [private$.fmtDateIn]                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[fmt          ]   :   Single character string to input the character strings into dates                                    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[<chr.>       ]   :   The same values as the previous input by the user                                                    #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[fmtDateOut]                                                                                                                   #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to set or return the user requested format to translate the dates into character strings       #
#   |   |   |   | within specific date retrieval methods defined by this family of classes                                              #
#   |   |   |   |[1] When [set] is called, it changes [private$.fmtDateOut]; while all methods that generate character string out of    #
#   |   |   |   |     dates will change the output format in accordance                                                                 #
#   |   |   |   |[2] When [return] is called, it returns the last value of [private$.fmtDateOut]                                        #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[fmt          ]   :   Single character string to format the dates                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[<chr.>       ]   :   The same values as the previous input by the user                                                    #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[datespan]                                                                                                                     #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to set or return the user requested span of date periods to calculate the Previous/Next        #
#   |   |   |   | Workdays/Tradedays for any specific dates; basically used to extend the universal calendar during calculation         #
#   |   |   |   |[1] When [set] is called, it changes [private$.datespan] and re-generate the universal calendar                        #
#   |   |   |   |[2] When [return] is called, it returns the last value of [private$.datespan]                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[tdelta       ]   :   The timespan for calculation, provided a class of [difftime]                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[<difftime>   ]   :   The same values as the previous input by the user                                                    #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[country]                                                                                                                      #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to set or return the user requested Country Code.                                              #
#   |   |   |   |[1] When [set] is called, it changes the Country Code and re-generate the universal calendar                           #
#   |   |   |   |[2] When [return] is called, it returns the last value of Country Country Code                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[cc           ]   :   Single character string indicating the country to apply the holiday/workday adjustment               #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[<chr.>       ]   :   The same values as the previous input by the user                                                    #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[DateOutAsStr]                                                                                                                 #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to set or return the indicator of whether to convert the output date values into character     #
#   |   |   |   | strings                                                                                                               #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[flag         ]   :   Bool value as indicator                                                                              #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[<bool>       ]   :   The same values as the previous input by the user                                                    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210216        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |      |[2] Introduce a separate function [getCalendarAdj] to search for the calendar adjustment in current environment             #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20211228        | Version | 2.01        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Refine the verification of arguments of [__init__]                                                                      #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20250323        | Version | 2.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Remove the usage of <inplace> in terms of the FutureWarning of <pandas>                                                 #
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
#   |   |datetime, pandas, collections                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniPy.Dates                                                                                                                   #
#   |   |   |getCalendarAdj                                                                                                             #
#   |   |   |asDates                                                                                                                    #
#   |   |   |asQuarters                                                                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
    '''

    #001. Identify the qualified name of current class (for logging purpose at large)
    #Quote: https://www.python.org/dev/peps/pep-3155/
    #[1] [__qualname__] attribute is valid for a [class] or [function], but invalid for an [object] instantiated from a [class]
    LClassName = __qualname__

    #002. Constructor
    def __init__(
        self
        #[1826 = 365 * 5 + 2 - 1] as there are 2 leap years within 5 years period
        ,clnBgn = dt.date.today() - dt.timedelta(days=1826)
        #30 days is enough to determine whether current date is the last workday/tradeday of current month
        ,clnEnd = dt.date.today() + dt.timedelta(days=30)
        ,countrycode : str = 'CN'
        ,CalendarAdj : Iterable = None
        ,fmtDateIn : Iterable = ['%Y%m%d', '%Y-%m-%d', '%Y/%m/%d']
        ,fmtDateOut : str = '%Y%m%d'
        ,DateOutAsStr : bool = False
    ):
        #001. Handle parameters
        if clnBgn is None: clnBgn = dt.date.today() - dt.timedelta(days=1826)
        if clnEnd is None: clnEnd = dt.date.today() + dt.timedelta(days=30)
        if countrycode is None: countrycode = 'CN'
        if not isinstance(fmtDateIn, Iterable): fmtDateIn = ['%Y%m%d', '%Y-%m-%d', '%Y/%m/%d']
        if not isinstance(fmtDateOut, str): fmtDateOut = '%Y%m%d'
        if not isinstance(DateOutAsStr, bool): DateOutAsStr = False

        #100. Assign values to private environment
        #110. There is no method to assign values to below private variables for safety concern
        self._clnBgn_ : dt.date = asDates(pd.Series(clnBgn, dtype = 'object'), fmt = fmtDateIn)
        if len(self._clnBgn_) != 1:
            raise ValueError('[' + self.LClassName + '][clnBgn] only accept single value!')
        else:
            self._clnBgn_ = self._clnBgn_.iat[0]

        self._clnEnd_ : dt.date = asDates(pd.Series(clnEnd, dtype = 'object'), fmt = fmtDateIn)
        if len(self._clnEnd_) != 1:
            raise ValueError('[' + self.LClassName + '][clnEnd] only accept single value!')
        else:
            self._clnEnd_ = self._clnEnd_.iat[0]

        if self._clnBgn_ > self._clnEnd_:
            raise ValueError(
                '[' + self.LClassName + '][clnBgn]:[{0}] is later than [clnEnd]:[{1}]!'.format( self._clnBgn_ , self._clnEnd_ )
            )

        if CalendarAdj is None:
            self._clnAdj_ = getCalendarAdj()
        else:
            self._clnAdj_ = CalendarAdj

        self._fmtDateOut_ = fmtDateOut

        #150. Call methods to assign values in a standard way
        self.country = countrycode
        self.fmtDateIn = fmtDateIn
        self.datespan = dt.timedelta(days=30)
        self.DateOutAsStr = DateOutAsStr

        #500. Create the universal calendar
        self._uniClndr_ = self._crCalendar()
    #End of [__init__]

    #005. Define the attributes that can be accessed from inside
    #Double underscore makes the members difficult to access from outside the quosure
    __slots__ = (
        '_clnBgn_' , '_clnEnd_' , '_uniClndr_'
        , '_countrycode_' , '_clnAdj_' , '_fmtDateIn_' , '_fmtDateOut_'
        , '_datespan_' , '_OutAsStr_'
    )

    #010. Define the document when printing an object instantiated from current class
    def __str__( self ):
        return( 'User Defined Calendar for [{0}]'.format( self.country ) )
    #End of [__str__]

    #011. Define the representation of the object
    __repr__ = __str__

    #050. Local variables at instantiation (before initialization)
    #Below variables cannot be set in [__slots__] due to conflict; hence they are neither able to be modified at runtime

    #201. Define the list of all weekday names under different settings (such as different languages).
    @property
    def _weekdayname( self ) -> 'Create the dict of all weekday names':
        #Below statements allow user not to use unicode input to define the text string in Chinese, such as [u'XXX']
        #import os
        #os.environ['NLS_LANG']='SIMPLIFIED CHINESE_CHINA.UTF8'
        wk : dict = {}
        wk.update( { 'CN' : { 0 : u'星期一' , 1 : u'星期二' , 2 : u'星期三' , 3 : u'星期四' , 4 : u'星期五' , 5 : u'星期六' , 6 : u'星期天' } } )
        return( wk )
    #End of [_weekdayname]

    #205. Generate the user-defined Universal Calendar
    def _crCalendar(
        self
        ,datebgn : dt.date = None
        ,dateend : dt.date = None
        ,countrycode : str = None
        ,CalendarAdj : str = None
    ) -> 'Create the Universal Calendar':
        #010. Set environment
        if not datebgn: datebgn = self.clnBgn
        if not dateend: dateend = self.clnEnd
        if not countrycode: countrycode = self.country
        if not CalendarAdj: CalendarAdj = self.clnAdj
        if not CalendarAdj: print('[' + self.LClassName + ']No adjustment is provided for holidays or workdays.')

        #100. Load the necessary resources.
        #101. Prepare the helper function for raw data import
        def infile_csv(path):
            tmpdf : pd.DataFrame = pd.read_csv( path )
            tmpdf['D_DATE'] = asDates(tmpdf['D_DATE'])
            tmpdf['F_WORKDAY'] = tmpdf['F_WORKDAY'] == 1
            tmpdf = tmpdf[tmpdf['CountryCode']==countrycode].copy(deep=True)
            return(tmpdf)

        #110. The list of calendar adjustment as a dataset.
        if isinstance( CalendarAdj , str ):
            shiftdata = infile_csv( CalendarAdj )
        elif isinstance( CalendarAdj , ( list , tuple ) ):
            if len(CalendarAdj) == 0:
                shiftdata = None
            else:
                #Quote: https://www.datasciencemadesimple.com/union-and-union-all-in-pandas-dataframe-in-python-2/
                shiftdata = pd.concat( [ infile_csv(f) for f in CalendarAdj ] , ignore_index=True ).drop_duplicates()
        else:
            shiftdata = None

        #120. The list of weekday names.
        wk_days : dict = self._weekdayname

        #150. Helper function to identify the weekdays
        def _setWeekDay(dt):
            return( dt.weekday() in range(0,5) )

        #160. Helper function to get the description of any date
        def _getDayDesc(dt):
            return( wk_days[countrycode][dt.weekday()] )

        #200. Create a dataset that contains the Calendar Days between (30 days before the [datebgn]) and (30 days after the [dateend]).
        clndrpre = pd.DataFrame(
            [ datebgn - self.datespan + dt.timedelta(days=i) for i in range( (dateend - datebgn + self.datespan * 2).days + 1 ) ]
            , columns = [ 'D_DATE' ]
            , dtype = 'object'
        ).set_index('D_DATE', drop = False)

        #201. Add the derivative fields.
        clndrpre['F_WEEKDAY'] = clndrpre['D_DATE'].apply(_setWeekDay)
        clndrpre['F_WORKDAY'] = clndrpre['F_WEEKDAY']
        clndrpre['Qtr'] = asQuarters(clndrpre['D_DATE'])
        clndrpre['C_DESC'] = clndrpre['D_DATE'].apply(_getDayDesc)

        #210. Load the adjustment of holidays/workdays if any
        if isinstance(shiftdata, pd.DataFrame):
            clndrpre.update((
                shiftdata
                .set_index('D_DATE')
                .reindex(clndrpre.index)
                .set_axis(clndrpre.index, axis = 0)
                [['C_DESC' , 'F_WORKDAY']]
            ))
            clndrpre['F_WORKDAY'] = clndrpre['F_WORKDAY'].astype('bool')

        #230. Identify the Trade days
        clndrpre['F_TradeDay'] = clndrpre['F_WEEKDAY'] & clndrpre['F_WORKDAY']

        #400. Only Retrieve all Work Days within above period
        wd_shift= clndrpre[ clndrpre['F_WORKDAY'] ].copy(deep=True)[['D_DATE']]
        wd_shift['D_PrevWorkDay'] = wd_shift['D_DATE'].shift(1)
        wd_shift['D_NextWorkDay'] = wd_shift['D_DATE'].shift(-1)

        #500.   Only Retrieve all Trade Days within above period
        td_shift= clndrpre[ clndrpre['F_TradeDay'] ].copy(deep=True)[['D_DATE']]
        td_shift['D_PrevTradeDay'] = td_shift['D_DATE'].shift(1)
        td_shift['D_NextTradeDay'] = td_shift['D_DATE'].shift(-1)

        #600. Append all necessary fields to the temporary Calendar Data.
        usrclndr = clndrpre.copy(deep=True)
        usrclndr[['D_PrevWorkDay', 'D_NextWorkDay']] = wd_shift[['D_PrevWorkDay', 'D_NextWorkDay']]
        usrclndr[['D_PrevTradeDay', 'D_NextTradeDay']] = td_shift[['D_PrevTradeDay', 'D_NextTradeDay']]

        #620. Correct previous/next workday/tradeday for all holidays
        usrclndr.loc[:, ['D_PrevWorkDay', 'D_PrevTradeDay']] = usrclndr[['D_PrevWorkDay', 'D_PrevTradeDay']].bfill()
        usrclndr.loc[:, ['D_NextWorkDay', 'D_NextTradeDay']] = usrclndr[['D_NextWorkDay', 'D_NextTradeDay']].ffill()

        #700. Only output the dates within the user defined period.
        # This step should be conducted at the last, for above steps would leverage the dates outside the provided date range.
        datemask = (datebgn <= usrclndr['D_DATE']) & (usrclndr['D_DATE'] <= dateend)
        usrclndr = usrclndr[datemask].copy(deep=True).reset_index(drop = True)

        #999. Output.
        return( usrclndr )
    #End of [_crCalendar]

    #207. Create the function to subset the universal calendar and create additional columns denoting to weeks
    def _subCalendar(
        self
        ,datebgn : dt.date = None
        ,dateend : dt.date = None
        ,inCln : pd.DataFrame = None
    ) -> 'Subset the Universal Data as per user request':
        #010. Set environment
        if not datebgn: datebgn = self.clnBgn
        if not dateend: dateend = self.clnEnd
        if not inCln: inCln = self.uniCalendar

        #100. Extract the requested part of the universal calendar
        datemask = (datebgn <= inCln['D_DATE']) & (inCln['D_DATE'] <= dateend)
        usrclndr = inCln[datemask].copy(deep=True).reset_index(drop = True)

        #300. Define the Workweeks
        #310. If current date is more than 1 Day later than its previous Work Day, we consider it the first one in current block
        usrclndr = usrclndr.assign( FirstDay = ( usrclndr['D_DATE'] - usrclndr['D_PrevWorkDay'] ) > dt.timedelta(days=1) )
        usrclndr['FirstDay'] = usrclndr['FirstDay'] & usrclndr['F_WORKDAY']

        #320. Correct the First Work Day at the top of the user calendar
        usrclndr.iat[0, usrclndr.columns.get_loc('FirstDay')] = usrclndr.iat[0, usrclndr.columns.get_loc('F_WORKDAY')]

        #370. Calculate the cumulative sum of the flag created above to resemble the "count of Work Weeks".
        usrclndr = usrclndr.assign( K_WorkWeek = usrclndr['FirstDay'].cumsum() ).drop(columns=['FirstDay'])

        #390. Correct the count on holidays
        #Quote: https://kanoki.org/2019/07/17/pandas-how-to-replace-values-based-on-conditions/
        #Quote: https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.where.html?highlight=where#pandas.DataFrame.where
        usrclndr['K_WorkWeek'] = usrclndr['K_WorkWeek'].where(usrclndr['F_WORKDAY'], 0)

        #400. Define the Tradeweeks
        #410. If current date is more than 1 Day later than its previous Trade Day, we consider it the first one in current block
        usrclndr = usrclndr.assign( FirstDay = ( usrclndr['D_DATE'] - usrclndr['D_PrevTradeDay'] ) > dt.timedelta(days=1) )
        usrclndr['FirstDay'] = usrclndr['FirstDay'] & usrclndr['F_TradeDay']

        #420. Correct the First Trade Day at the top of the user calendar
        usrclndr.iat[0, usrclndr.columns.get_loc('FirstDay')] = usrclndr.iat[0, usrclndr.columns.get_loc('F_TradeDay')]

        #470. Calculate the cumulative sum of the flag created above to resemble the "count of Trade Weeks".
        usrclndr = usrclndr.assign( K_TradeWeek = usrclndr['FirstDay'].cumsum() ).drop(columns=['FirstDay'])

        #490. Correct the count on holidays
        usrclndr['K_TradeWeek'] = usrclndr['K_TradeWeek'].where(usrclndr['F_TradeDay'], 0)

        #800. Purge the memory usage.

        #900. Output.
        return( usrclndr )
    #End of [_subCalendar]

    #505. Retrieve the Universal Calendar Dataset
    @property
    def uniCalendar( self ) -> 'Get the Universal Calendar Dataset':
        return( self._uniClndr_ )

    #507. Retrieve the full path to the calendar adjustment file
    @property
    def clnAdj( self ) -> 'Get the full path to the calendar adjustment file':
        return( self._clnAdj_ )

    #511. Retrieve the beginning date of the Universal Calendar
    @property
    def clnBgn( self ) -> 'Get the beginning date of the Universal Calendar':
        return( self._clnBgn_ )

    #512. Retrieve the ending date of the Universal Calendar
    @property
    def clnEnd( self ) -> 'Get the ending date of the Universal Calendar':
        return( self._clnEnd_ )

    #701. Define the format to input the date values if required
    @property
    def fmtDateIn( self ) -> 'Get the format to input the date values if required':
        return( self._fmtDateIn_ )
    @fmtDateIn.setter
    def fmtDateIn( self , strfmt : ( str , list, tuple ) ) -> 'Set the format to input the date values if required':
        self._fmtDateIn_ = strfmt

    #702. Define the format to output the date values if required
    @property
    def fmtDateOut( self ) -> 'Get the format to output the date values if required':
        return( self._fmtDateOut_ )
    @fmtDateOut.setter
    def fmtDateOut( self , strfmt : str ) -> 'Set the format to output the date values if required':
        #100. Validation
        try:
            dt.date.today().strftime(strfmt)
        except:
            raise ValueError('[' + self.LClassName + '][fmtDateOut]:[{0}] is invalid for [strftime]!'.format( strfmt ))

        #500. Assign values
        self._fmtDateOut_ = strfmt

        #700. Set the conversion flag for output
        self.DateOutAsStr = True
    #End of [fmtDateOut]

    #710. Define the method to extend the span of the user requested period of time
    #This is for the retrieval of Previous Work/Trade Days or Next Work/Trade Days.
    @property
    def datespan( self ) -> 'Get the time span to extend the user requested period':
        return( self._datespan_ )
    @datespan.setter
    def datespan( self , tdelta : dt.timedelta ) -> 'Set the time span to extend the user requested period':
        self._datespan_ : dt.timedelta = tdelta

    #720. Define the method to modify the country configuration at runtime
    @property
    def country( self ) -> 'Get the country code':
        return( self._countrycode_ )
    @country.setter
    def country( self , cc : str = 'CN' ) -> 'Set the country code':
        self._countrycode_ : str = cc.strip().upper()

    #730. Define the method to indicate whether to convert the output dates into character strings
    @property
    def DateOutAsStr( self ) -> 'Get the indicator of whether to convert the output dates into strings':
        return( self._OutAsStr_ )
    @DateOutAsStr.setter
    def DateOutAsStr( self , flag : bool ) -> 'Set the indicator of whether to convert the output dates into strings':
        if not flag: flag = False
        if not isinstance( flag , bool ):
            raise TypeError('[' + self.LClassName + '][DateOutAsStr]:[{0}] should be [bool]!'.format( type(flag) ))
        self._OutAsStr_ : bool = flag

#End Class

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #100.   Create envionment.
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.Dates import CoreUserCalendar

    #200.   Print the class information.
    print( CoreUserCalendar.__slots__ )

    #300.   Create an object for the class.
    cln = CoreUserCalendar()

    cln.fmtDateOut = '%Y-%m-%d'
    cln_data = cln.uniCalendar
    cln_data.head()
#-Notes- -End-
'''
