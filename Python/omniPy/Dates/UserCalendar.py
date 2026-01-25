#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#001. Import necessary functions for processing.
import datetime as dt
import pandas as pd
from warnings import warn
from collections.abc import Iterable
from omniPy.AdvOp import ExpandSignature
from omniPy.Dates import asDates, asQuarters, CoreUserCalendar

eSig = ExpandSignature(CoreUserCalendar.__init__)

#100. Definition of the class.
class UserCalendar( CoreUserCalendar ):
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
#   |   |   |[dateBgn      ]   :   Beginning date of the user calendar, provided by any object that can be coerced to <dt.date>         #
#   |   |   |                      [None                ]<Default> Same as <self.clnBgn>                                                #
#   |   |   |[dateEnd      ]   :   Ending date of the user calendar, provided by any object that can be coerced to <dt.date>            #
#   |   |   |                      [None                ]<Default> Same as <self.clnEnd>                                                #
#   |   |   |*pos              :   All the arguments are from its ancestor, please check its document                                   #
#   |   |   |**kw              :   All the arguments are from its ancestor, please check its document                                   #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<None>            :   This method does not return values, but will assign values to variables for <private> object         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |400.   Private method                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |500.   Read-only properties.                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |100.   Description.                                                                                                            #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |This section lists all the read-only properties of the class. The examples listed are based on below provision                 #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |EXAMPLE                                                                                                                        #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[<dateBgn = date(2015,1,1)>]                                                                                                   #
#   |   |[<dateEnd = date(2016,7,3)>]                                                                                                   #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |       Property Name         |                             Value Examples and Property Description                         #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | params                      | <log> Display the key information for calculation within current instance                   #
#   |   |   | usrCalendar                 | <pd.DataFrame> data frame of the user calendar defined by <dateBgn> and <dateEnd>           #
#   |   |   | kYear                       | <2> # of years that the period covers                                                       #
#   |   |   | kMth                        | <19> # of months that the period covers                                                     #
#   |   |   | yearlist                    | <2015,2016> numeric values of years that the period covers                                  #
#   |   |   | mthlist                     | <'201501',...,'201607'> values of months that the period covers                             #
#   |   |   | qtrlist                     | <'2015Q1',...,'2016Q3'> values of quarters that the period covers                           #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | kClnDay                     | <550> # of Calendar Days within the period                                                  #
#   |   |   | d_AllCD                     | <date(2015-01-01),...,date(2016-07-03)> values of all Clndr days                            #
#   |   |   | kWorkDay                    | <373> # of Work Days within the period                                                      #
#   |   |   | d_AllWD                     | <date(20150104),...,date(20160701)> values of All Work days                                 #
#   |   |   | kTradeDay                   | <365> # of Trade Days within the period                                                     #
#   |   |   | d_AllTD                     | <date(20150105),...,date(20160701)> values of All Trade days                                #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | cd_of_months                | <dict> keys represent all months; values represent Calendar Days of each month              #
#   |   |   | FirstCDofMon                | <date(20150101),...,date(20160701)> First Calendar Days of each month                       #
#   |   |   | LastCDofMon                 | <date(20150131),...,date(20160703)> Last Calendar Days of each month                        #
#   |   |   | kCDofMon                    | <31,...,3> # of Calendar Days of each month                                                 #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | wd_of_months                | <dict> keys represent all months; values represent Work Days of each month                  #
#   |   |   | FirstWDofMon                | <date(20150104),...,date(20160701)> First Workdays of each month                            #
#   |   |   | LastWDofMon                 | <date(20150130),...,date(20160701)> Last Workdays of each month                             #
#   |   |   | kWDofMon                    | <21,...,1> # of Workdays of each month                                                      #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | td_of_months                | <dict> keys represent all months; values represent Trade Days of each month                 #
#   |   |   | FirstTDofMon                | <date(20150105),...,date(20160701)> First Tradedays of each month                           #
#   |   |   | LastTDofMon                 | <date(20150130),...,date(20160701)> Last Tradedays of each month                            #
#   |   |   | kTDofMon                    | <20,...,1> # of Tradedays of each month                                                     #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | kWorkWeek                   | <77> # of Work Weeks within the period                                                      #
#   |   |   | workweeks                   | <dict> keys represent all Work Weeks; values represent Work Days of each Week               #
#   |   |   | FirstWDofWeek               | <date(20150104),...,date(20160701)> First Workdays of each work week                        #
#   |   |   | LastWDofWeek                | <date(20150109),...,date(20160701)> Last Workdays of each work week                         #
#   |   |   | kWDofWeek                   | <6,...,5> # of Workdays of each work week                                                   #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | kTradeWeek                  | <77> # of Trade Weeks within the period                                                     #
#   |   |   | tradeweeks                  | <dict> keys represent all Trade Weeks; values represent Trade Days of each Week             #
#   |   |   | FirstTDofWeek               | <date(20150105),...,date(20160701)> First Tradedays of each trade week                      #
#   |   |   | LastTDofWeek                | <date(20150109),...,date(20160701)> Last Tradedays of each trade week                       #
#   |   |   | kTDofWeek                   | <5,...,5> # of Tradedays of each trade week                                                 #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | cd_of_quarters              | <dict> keys represent all quarters; values represent Calendar Days of each quarter          #
#   |   |   | FirstCDofQtr                | <date(20150101),...,date(20160701)> First Calendar Days of each quarter                     #
#   |   |   | LastCDofQtr                 | <date(20150331),...,date(20160703)> Last Calendar Days of each quarter                      #
#   |   |   | kCDofQtr                    | <90,...,3> # of Calendar Days of each quarter                                               #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | wd_of_quarters              | <dict> keys represent all quarters; values represent Work Days of each quarter              #
#   |   |   | FirstWDofQtr                | <date(20150104),...,date(20160701)> First Workdays of each quarter                          #
#   |   |   | LastWDofQtr                 | <date(20150331),...,date(20160701)> Last Workdays of each quarter                           #
#   |   |   | kWDofQtr                    | <60,...,1> # of Workdays of each quarter                                                    #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | td_of_quarters              | <dict> keys represent all quarters; values represent Trade Days of each quarter             #
#   |   |   | FirstTDofQtr                | <date(20150105),...,date(20160701)> First Tradedays of each quarter                         #
#   |   |   | LastTDofQtr                 | <date(20150331),...,date(20160701)> Last Tradedays of each quarter                          #
#   |   |   | kTDofQtr                    | <57,...,1> # of Tradedays of each quarter                                                   #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | cd_of_years                 | <dict> keys represent all years; values represent Calendar Days of each year                #
#   |   |   | FirstCDofYear               | <date(20150101),...,date(20160101)> First Calendar Days of each year                        #
#   |   |   | LastCDofYear                | <date(20151231),...,date(20160703)> Last Calendar Days of each year                         #
#   |   |   | kCDofYear                   | <365,185> # of Calendar Days of each year                                                   #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | wd_of_years                 | <dict> keys represent all years; values represent Work Days of each year                    #
#   |   |   | FirstWDofYear               | <date(20150104),...,date(20160104)> First Workdays of each year                             #
#   |   |   | LastWDofYear                | <date(20151231),...,date(20160701)> Last Workdays of each year                              #
#   |   |   | kWDofYear                   | <249,124> # of Workdays of each year                                                        #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | td_of_years                 | <dict> keys represent all years; values represent Trade Days of each year                   #
#   |   |   | FirstTDofYear               | <date(20150105),...,date(20160104)> First Tradedays of each year                            #
#   |   |   | LastTDofYear                | <date(20150130),...,date(20160701)> Last Tradedays of each year                             #
#   |   |   | kTDofYear                   | <244,121> # of Tradedays of each year                                                       #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Active-binding method                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |[dateBgn]                                                                                                                      #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to set or return the beginning date of the subset of universal calendar, e.g. for loop usage   #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |NOTE                                                                                                                   #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |[1] When <set> is called, it changes <self._dateBgn_>                                                                  #
#   |   |   |   |[2] When <return> is called, it returns the last value of <self._dateBgn_>                                             #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[udate        ]   :   values/list of dates, or character strings which can be coerced to <dt.date>                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<Any>             :   The same values as the previous input by the user                                                    #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[dateEnd]                                                                                                                      #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to set or return the ending date of the subset of universal calendar, e.g. for loop usage      #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |NOTE                                                                                                                   #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |[1] When <set> is called, it changes <self._dateEnd_>                                                                  #
#   |   |   |   |[2] When <return> is called, it returns the last value of <self._dateEnd_>                                             #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[udate        ]   :   values/list of dates, or character strings which can be coerced to <dt.date>                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<Any>             :   The same values as the previous input by the user                                                    #
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
#   | Date |    20210503        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Replace the usage of backslash as new-row-expansion with the officially recommended way <(multi-line-expr.)>, see PEP-8 #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210821        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Eliminate all <pd.DataFrame.merge> operations and the most of <.apply> methods to improve the overall efficiency, now   #
#   |      |     use indexing of data frames and the time expense reduced by 90%.                                                       #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20231016        | Version | 2.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Updated the usage of <asQuarters> to improve the efficiency                                                             #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20231107        | Version | 2.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug by replacing <pd.Series.at> with <pd.Series.iat> to avoid ambiguity                                         #
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
#   |   |datetime, pandas, collections, warnings                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
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
        ,dateBgn = None
        ,dateEnd = None
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
        int_dateBgn = asDates(pd.Series(dateBgn, dtype = 'object'), self.fmtDateIn).loc[lambda x: x.notnull()]
        int_dateEnd = asDates(pd.Series(dateEnd, dtype = 'object'), self.fmtDateIn).loc[lambda x: x.notnull()]

        #317. Raise exception for invalid input
        if len(int_dateBgn) > 1:
            raise ValueError(f'[{self.LClassName}]Multiple <dateBgn> provided!')
        if len(int_dateEnd) > 1:
            raise ValueError(f'[{self.LClassName}]Multiple <dateEnd> provided!')
        if len(int_clnBgn) > 1:
            raise ValueError(f'[{self.LClassName}]Multiple <clnBgn> provided!')
        if len(int_clnEnd) > 1:
            raise ValueError(f'[{self.LClassName}]Multiple <clnEnd> provided!')
        if (len(int_dateBgn) == 0) and (len(int_clnBgn) == 0):
            raise ValueError(f'[{self.LClassName}]Both <dateBgn> and <clnBgn> are invalid!')
        if (len(int_dateEnd) == 0) and (len(int_clnEnd) == 0):
            raise ValueError(f'[{self.LClassName}]Both <dateEnd> and <clnEnd> are invalid!')

        #319. Warn for invalid input that can be overridden
        if len(int_clnBgn) == 0:
            warn(f'[{self.LClassName}]<clnBgn> is invalid and deemed the same as <dateBgn>!')
        if len(int_clnEnd) == 0:
            warn(f'[{self.LClassName}]<clnEnd> is invalid and deemed the same as <dateEnd>!')

        #340. Transform the beginning when necessary
        if len(int_dateBgn) == 1:
            if fr_default_clnBgn or (len(int_clnBgn) == 0):
                int_clnBgn = int_dateBgn

        #370. Transform the ending when necessary
        if len(int_dateEnd) == 1:
            if fr_default_clnEnd or (len(int_clnEnd) == 0):
                int_clnEnd = int_dateEnd

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

        #700. Assign values to local variables
        #We cannot call methods to assign below values, for they are mutually bound to verification against each other.
        self._dateBgn_ = int_dateBgn.at[0] if len(int_dateBgn) else self.clnBgn
        self._dateEnd_ = int_dateEnd.at[0] if len(int_dateEnd) else self.clnEnd

        #709. Raise warning if the user required period exceeds the universal calendar
        if (self.dateBgn < self.clnBgn) | (self.dateEnd > self.clnEnd):
            raise ValueError(
                f'[{self.LClassName}]User requested period exceeds the universal calendar!'
                +'\n[dateBgn]=[{0}][dateEnd]=[{1}][clnBgn]=[{2}][clnEnd]=[{3}]'.format(
                    self.dateBgn.strftime('%Y%m%d')
                    ,self.dateEnd.strftime('%Y%m%d')
                    ,self.clnBgn.strftime('%Y%m%d')
                    ,self.clnEnd.strftime('%Y%m%d')
                )
            )

        #800. Create the user calendar
        self._usrclndr_ : pd.DataFrame = self._subCalendar( datebgn = self.dateBgn , dateend = self.dateEnd )
    #End of [__init__]

    #005. Define the attributes that can be accessed from inside
    #Double underscore makes the members difficult to access from outside the quosure
    __slots__ = (
        '_eSig_'
        , '_dateBgn_' , '_dateEnd_' , '_usrclndr_'
    )

    #010.   Define the document when printing an object instantiated from current class
    def __str__( self ) -> str:
        return('User Defined Calendar for [{0}] in period between [{1}] and [{2}]'.format(self.country , self.dateBgn , self.dateEnd))

    #011. Define the representation of the object
    __repr__ = __str__

    #050. Local variables at instantiation (before initialization)
    #Below variables cannot be set in [__slots__] due to conflict; hence they are neither able to be modified at runtime

    #501. Print the parameters into log
    @property
    def params( self ):
        print( 'Beginning of the User Calendar:[' + self.dateBgn.strftime('%Y-%m-%d') + ']' )
        print( 'Ending of the User Calendar:[' + self.dateEnd.strftime('%Y-%m-%d') + ']' )
        print( 'Country Code:[' + self.country + ']' )
        print( 'Calendar Adjustment:[' + self.clnAdj + ']' )
        print( 'How to input the strings into dates:[' + ']['.join(self.fmtDateIn) + ']' )
        print( 'How to display the results as formatted in string:[' + self.fmtDateOut + ']' )
        print( '# of days to extend the calculation before beginning and after ending:[' + str(self.datespan.days) + ']' )
    #End of [params]

    #505. Retrieve the User Defined Calendar
    @property
    def usrCalendar( self ) -> pd.DataFrame:
        return( self._usrclndr_ )

    #510. Number of years across the period
    @property
    def kYear( self ) -> int:
        return( len(self.yearlist) )

    #511. Number of months across the period
    @property
    def kMth( self ) -> int:
        return( len(self.mthlist) )

    #512. List of years that are covered in the period
    @property
    def yearlist( self ) -> list[int]:
        #Quote: https://stackoverflow.com/questions/23748995/pandas-dataframe-column-to-list
        return( self._usrclndr_['D_DATE'].sort_values().apply(lambda x: x.year).drop_duplicates().to_list() )

    #515. List of months in [YYYYMM] format that are covered in the period
    @property
    def mthlist( self ) -> list[str]:
        return( self._usrclndr_['D_DATE'].sort_values().apply(lambda x: x.strftime('%Y%m')).drop_duplicates().to_list() )

    #516. List of quarters in [YYYYQk] format that are covered in the period
    @property
    def qtrlist( self ) -> list[str]:
        dt_series = (
            self._usrclndr_['D_DATE']
            .apply( lambda x: x.year)
            .astype('str')
            .add('Q')
            .add(asQuarters(self._usrclndr_['D_DATE']).astype('str'))
        )
        return( dt_series.drop_duplicates().sort_values().to_list() )

    #520. Retrieve the Count of Calendar Days
    @property
    def kClnDay( self ) -> int:
        return( len(self._usrclndr_) )

    #521. Retrieve the list of Calendar Days as [dt.date]
    @property
    def d_AllCD( self ) -> list[dt.date | str]:
        dates_anchor = self._usrclndr_['D_DATE'].sort_values().tolist()
        return( [ v.strftime(self.fmtDateOut) for v in dates_anchor ] if self.DateOutAsStr else dates_anchor )

    #523. Retrieve the Count of Work Days
    @property
    def kWorkDay( self ) -> int:
        return( self._usrclndr_['F_WORKDAY'].sum() )

    #524. Retrieve the list of Work Days as [dt.date]
    @property
    def d_AllWD( self ) -> list[dt.date | str]:
        dates_anchor = self._usrclndr_[ self._usrclndr_['F_WORKDAY'] ]['D_DATE'].sort_values().tolist()
        return( [ v.strftime(self.fmtDateOut) for v in dates_anchor ] if self.DateOutAsStr else dates_anchor )

    #526. Retrieve the Count of Trade Days
    @property
    def kTradeDay( self ) -> int:
        return( self._usrclndr_['F_TradeDay'].sum() )

    #527. Retrieve the list of Trade Days as [dt.date]
    @property
    def d_AllTD( self ) -> list[dt.date | str]:
        dates_anchor = self._usrclndr_[ self._usrclndr_['F_TradeDay'] ]['D_DATE'].sort_values().tolist()
        return( [ v.strftime(self.fmtDateOut) for v in dates_anchor ] if self.DateOutAsStr else dates_anchor )

    #540. List of Calendar Days within the months in the period, comprising a dict of months
    @property
    def cd_of_months( self ) -> dict[str, list[dt.date | str]]:
        mths = {
            m : self._usrclndr_[
                self._usrclndr_['D_DATE'].apply( lambda x: x.strftime('%Y%m') == m )
            ]['D_DATE'].sort_values().apply( lambda x: x.strftime(self.fmtDateOut) if self.DateOutAsStr else x ).tolist()
            for m in self.mthlist
        }
        return( mths )

    #541. Retrieve the list of First Calendar Days of each month
    @property
    def FirstCDofMon( self ) -> list[dt.date | str]:
        #Quote: https://realpython.com/iterate-through-dictionary-python/
        return( [ v[0] for v in self.cd_of_months.values() ] )

    #542. Retrieve the list of Last Calendar Days of each month
    @property
    def LastCDofMon( self ) -> list[dt.date | str]:
        return( [ v[-1] for v in self.cd_of_months.values() ] )

    #549. Retrieve the Count of Calendar Days of each month
    @property
    def kCDofMon( self ) -> list[int]:
        return( [ len(v) for v in self.cd_of_months.values() ] )

    #550. List of Work Days within the months in the period, comprising a dict of months
    @property
    def wd_of_months( self ) -> dict[str, list[dt.date | str]]:
        mths = {
            m : self._usrclndr_[
                self._usrclndr_['D_DATE'].apply( lambda x: x.strftime('%Y%m') == m ) & self._usrclndr_['F_WORKDAY']
            ]['D_DATE'].sort_values().apply( lambda x: x.strftime(self.fmtDateOut) if self.DateOutAsStr else x ).tolist()
            for m in self.mthlist
        }
        return( mths )

    #551. Retrieve the list of First Work Days of each month
    @property
    def FirstWDofMon( self ) -> list[dt.date | str]:
        return( [ v[0] for v in self.wd_of_months.values() if v ] )

    #552. Retrieve the list of Last Work Days of each month
    @property
    def LastWDofMon( self ) -> list[dt.date | str]:
        return( [ v[-1] for v in self.wd_of_months.values() if v ] )

    #559. Retrieve the Count of Work Days of each month
    @property
    def kWDofMon( self ) -> list[int]:
        return( [ len(v) for v in self.wd_of_months.values() ] )

    #560. List of Trade Days within the months in the period, comprising a dict of months
    @property
    def td_of_months( self ) -> dict[str, list[dt.date | str]]:
        mths = {
            m : self._usrclndr_[
                self._usrclndr_['D_DATE'].apply( lambda x: x.strftime('%Y%m') == m ) & self._usrclndr_['F_TradeDay']
            ]['D_DATE'].sort_values().apply( lambda x: x.strftime(self.fmtDateOut) if self.DateOutAsStr else x ).tolist()
            for m in self.mthlist
        }
        return( mths )

    #561. Retrieve the list of First Trade Days of each month
    @property
    def FirstTDofMon( self ) -> list[dt.date | str]:
        return( [ v[0] for v in self.td_of_months.values() if v ] )

    #562. Retrieve the list of Last Trade Days of each month
    @property
    def LastTDofMon( self ) -> list[dt.date | str]:
        return( [ v[-1] for v in self.td_of_months.values() if v ] )

    #569. Retrieve the Count of Trade Days of each month
    @property
    def kTDofMon( self ) -> list[int]:
        return( [ len(v) for v in self.td_of_months.values() ] )

    #570. # of Work Weeks in the period
    @property
    def kWorkWeek( self ) -> int:
        return( max( self._usrclndr_['K_WorkWeek'] ) )

    #571. List of Work Days within the period, comprising a dict of Work Weeks
    @property
    def workweeks( self ) -> dict[int, list[dt.date | str]]:
        wks = {
            m : self._usrclndr_[
                self._usrclndr_['K_WorkWeek'] == m + 1
            ]['D_DATE'].sort_values().apply( lambda x: x.strftime(self.fmtDateOut) if self.DateOutAsStr else x ).tolist()
            for m in range(self.kWorkWeek)
        }
        return( wks )

    #572. Retrieve the list of First Work Days of each workweek
    @property
    def FirstWDofWeek( self ) -> list[dt.date | str]:
        return( [ v[0] for v in self.workweeks.values() ] )

    #573. Retrieve the list of Last Work Days of each workweek
    @property
    def LastWDofWeek( self ) -> list[dt.date | str]:
        return( [ v[-1] for v in self.workweeks.values() ] )

    #579. Retrieve the Count of Work Days of each workweek
    @property
    def kWDofWeek( self ) -> list[int]:
        return( [ len(v) for v in self.workweeks.values() ] )

    #580. # of Trade Weeks in the period
    @property
    def kTradeWeek( self ) -> int:
        return( max( self._usrclndr_['K_TradeWeek'] ) )

    #581. List of Work Days within the period, comprising a list of Work Weeks
    @property
    def tradeweeks( self ) -> dict[int, list[dt.date | str]]:
        wks = {
            m : self._usrclndr_[
                self._usrclndr_['K_TradeWeek'] == m + 1
            ]['D_DATE'].sort_values().apply( lambda x: x.strftime(self.fmtDateOut) if self.DateOutAsStr else x ).tolist()
            for m in range(self.kTradeWeek)
        }
        return( wks )

    #582. Retrieve the list of First Trade Days of each tradeweek
    @property
    def FirstTDofWeek( self ) -> list[dt.date | str]:
        return( [ v[0] for v in self.tradeweeks.values() ] )

    #583. Retrieve the list of Last Trade Days of each tradeweek
    @property
    def LastTDofWeek( self ) -> list[dt.date | str]:
        return( [ v[-1] for v in self.tradeweeks.values() ] )

    #589. Retrieve the Count of Trade Days of each tradeweek
    @property
    def kTDofWeek( self ) -> list[int]:
        return( [ len(v) for v in self.tradeweeks.values() ] )

    #600. List of Calendar Days within the quarters in the period, comprising a dict of quarters
    @property
    def cd_of_quarters( self ) -> dict[str, list[dt.date | str]]:
        mask_idx = (
            self._usrclndr_['D_DATE']
            .apply( lambda x: x.year)
            .astype('str')
            .add('Q')
            .add(asQuarters(self._usrclndr_['D_DATE']).astype('str'))
        )
        qtrs = {
            m : (
                self._usrclndr_[mask_idx == m]
                ['D_DATE'].sort_values().apply( lambda x: x.strftime(self.fmtDateOut) if self.DateOutAsStr else x ).tolist()
            )
            for m in self.qtrlist
        }
        return( qtrs )

    #601. Retrieve the list of First Calendar Days of each quarter
    @property
    def FirstCDofQtr( self ) -> list[dt.date | str]:
        return( [ v[0] for v in self.cd_of_quarters.values() ] )

    #602. Retrieve the list of Last Calendar Days of each quarter
    @property
    def LastCDofQtr( self ) -> list[dt.date | str]:
        return( [ v[-1] for v in self.cd_of_quarters.values() ] )

    #609. Retrieve the Count of Calendar Days of each quarter
    @property
    def kCDofQtr( self ) -> list[int]:
        return( [ len(v) for v in self.cd_of_quarters.values() ] )

    #610. List of Work Days within the quarters in the period, comprising a dict of quarters
    @property
    def wd_of_quarters( self ) -> dict[str, list[dt.date | str]]:
        mask_idx = (
            self._usrclndr_['D_DATE']
            .apply( lambda x: x.year)
            .astype('str')
            .add('Q')
            .add(asQuarters(self._usrclndr_['D_DATE']).astype('str'))
        )
        qtrs = {
            m : (
                self._usrclndr_[ (mask_idx == m) & self._usrclndr_['F_WORKDAY'] ]
                ['D_DATE'].sort_values().apply( lambda x: x.strftime(self.fmtDateOut) if self.DateOutAsStr else x ).tolist()
            )
            for m in self.qtrlist
        }
        return( qtrs )

    #611. Retrieve the list of First Work Days of each quarter
    @property
    def FirstWDofQtr( self ) -> list[dt.date | str]:
        return( [ v[0] for v in self.wd_of_quarters.values() if v ] )

    #612. Retrieve the list of Last Work Days of each quarter
    @property
    def LastWDofQtr( self ) -> list[dt.date | str]:
        return( [ v[-1] for v in self.wd_of_quarters.values() if v ] )

    #619. Retrieve the Count of Work Days of each quarter
    @property
    def kWDofQtr( self ) -> list[int]:
        return( [ len(v) for v in self.wd_of_quarters.values() ] )

    #620. List of Trade Days within the quarters in the period, comprising a dict of quarters
    @property
    def td_of_quarters( self ) -> dict[str, list[dt.date | str]]:
        mask_idx = (
            self._usrclndr_['D_DATE']
            .apply( lambda x: x.year)
            .astype('str')
            .add('Q')
            .add(asQuarters(self._usrclndr_['D_DATE']).astype('str'))
        )
        qtrs = {
            m : (
                self._usrclndr_[ (mask_idx == m) & self._usrclndr_['F_TradeDay'] ]
                ['D_DATE'].sort_values().apply( lambda x: x.strftime(self.fmtDateOut) if self.DateOutAsStr else x ).tolist()
            )
            for m in self.qtrlist
        }
        return( qtrs )

    #621. Retrieve the list of First Trade Days of each quarter
    @property
    def FirstTDofQtr( self ) -> list[dt.date | str]:
        return( [ v[0] for v in self.td_of_quarters.values() if v ] )

    #622. Retrieve the list of Last Trade Days of each quarter
    @property
    def LastTDofQtr( self ) -> list[dt.date | str]:
        return( [ v[-1] for v in self.td_of_quarters.values() if v ] )

    #629. Retrieve the Count of Trade Days of each quarter
    @property
    def kTDofQtr( self ) -> list[int]:
        return( [ len(v) for v in self.td_of_quarters.values() ] )

    #630. List of Calendar Days within the years in the period, comprising a dict of years
    @property
    def cd_of_years( self ) -> dict[str, list[dt.date | str]]:
        years = {
            m : (
                self._usrclndr_[ self._usrclndr_['D_DATE'].apply( lambda x: x.year == m ) ]
                ['D_DATE'].sort_values().apply( lambda x: x.strftime(self.fmtDateOut) if self.DateOutAsStr else x ).tolist()
            )
            for m in self.yearlist
        }
        return( years )

    #631. Retrieve the list of First Calendar Days of each year
    @property
    def FirstCDofYear( self ) -> list[dt.date | str]:
        return( [ v[0] for v in self.cd_of_years.values() ] )

    #632. Retrieve the list of Last Calendar Days of each year
    @property
    def LastCDofYear( self ) -> list[dt.date | str]:
        return( [ v[-1] for v in self.cd_of_years.values() ] )

    #639. Retrieve the Count of Calendar Days of each year
    @property
    def kCDofYear( self ) -> list[int]:
        return( [ len(v) for v in self.cd_of_years.values() ] )

    #640. List of Work Days within the years in the period, comprising a dict of years
    @property
    def wd_of_years( self ) -> dict[str, list[dt.date | str]]:
        years = {
            m : (
                self._usrclndr_[ self._usrclndr_['D_DATE'].apply( lambda x: x.year == m ) & self._usrclndr_['F_WORKDAY'] ]
                ['D_DATE'].sort_values().apply( lambda x: x.strftime(self.fmtDateOut) if self.DateOutAsStr else x ).tolist()
            )
            for m in self.yearlist
        }
        return( years )

    #641. Retrieve the list of First Work Days of each year
    @property
    def FirstWDofYear( self ) -> list[dt.date | str]:
        return( [ v[0] for v in self.wd_of_years.values() if v ] )

    #642. Retrieve the list of Last Work Days of each year
    @property
    def LastWDofYear( self ) -> list[dt.date | str]:
        return( [ v[-1] for v in self.wd_of_years.values() if v ] )

    #649. Retrieve the Count of Work Days of each year
    @property
    def kWDofYear( self ) -> list[int]:
        return( [ len(v) for v in self.wd_of_years.values() ] )

    #650. List of Trade Days within the years in the period, comprising a dict of years
    @property
    def td_of_years( self ) -> dict[str, list[dt.date | str]]:
        years = {
            m : (
                self._usrclndr_[ self._usrclndr_['D_DATE'].apply( lambda x: x.year == m ) & self._usrclndr_['F_TradeDay'] ]
                ['D_DATE'].sort_values().apply( lambda x: x.strftime(self.fmtDateOut) if self.DateOutAsStr else x ).tolist()
            )
            for m in self.yearlist
        }
        return( years )

    #651. Retrieve the list of First Trade Days of each year
    @property
    def FirstTDofYear( self ) -> list[dt.date | str]:
        return( [ v[0] for v in self.td_of_years.values() if v ] )

    #652. Retrieve the list of Last Trade Days of each year
    @property
    def LastTDofYear( self ) -> list[dt.date | str]:
        return( [ v[-1] for v in self.td_of_years.values() if v ] )

    #659. Retrieve the Count of Trade Days of each year
    @property
    def kTDofYear( self ) -> list[int]:
        return( [ len(v) for v in self.td_of_years.values() ] )

    #702. Get and set the beginning of the User Calendar
    @property
    def dateBgn( self ) -> dt.date | str:
        return( self._dateBgn_ )
    @dateBgn.setter
    def dateBgn( self , udate : ( dt.date , dt.datetime , pd.Timestamp ) ):
        #100. Reset the user requested beginning to that of the universal calendar if it is provided but with no value
        if not udate:
            warn('[' + self.LClassName + ']No value is provided for [User Calendar Beginning], reset it to lower bound.')
            udate = self.clnBgn

        #300. Translate the input values if any
        tmpdate = asDates( udate , self.fmtDateIn )
        if isinstance( tmpdate , Iterable ):
            warn('[' + self.LClassName + ']Multiple values provided for [User Calendar Beginning], only the first one is used.')
            tmpdate = tmpdate[0]

        #700. Reset it if it exceeds the boundary of the calendar
        if (tmpdate < self.clnBgn) | (tmpdate > self._dateEnd_):
            warn('[' + self.LClassName + ']Input value for [User Calendar Beginning] exceeds the boundary, reset it to lower bound.')
            tmpdate = self.clnBgn

        #990. Update the environment as per request
        #991. Set the beginning date of user calendar
        self._dateBgn_ = tmpdate

        #995. Refresh the user calendar
        self._usrclndr_ : pd.DataFrame = self._subCalendar( datebgn = self._dateBgn_ , dateend = self._dateEnd_ )
    #End of [dateBgn]

    #704. Get and set the ending of the User Calendar
    @property
    def dateEnd( self ) -> dt.date | str:
        return( self._dateEnd_ )
    @dateEnd.setter
    def dateEnd( self , udate : ( dt.date , dt.datetime , pd.Timestamp ) ):
        #100. Reset the user requested ending to that of the universal calendar if it is provided but with no value
        if not udate:
            warn('[' + self.LClassName + ']No value is provided for [User Calendar Ending], reset it to upper bound.')
            udate = self.clnEnd

        #300. Translate the input values if any
        tmpdate = asDates( udate , self.fmtDateIn )
        if isinstance( tmpdate , Iterable ):
            warn('[' + self.LClassName + ']Multiple values provided for [User Calendar Ending], only the first one is used.')
            tmpdate = tmpdate[0]

        #700. Reset it if it exceeds the boundary of the calendar
        if (tmpdate > self.clnEnd) | (tmpdate < self._dateBgn_):
            warn('[' + self.LClassName + ']Input value for [User Calendar Ending] exceeds the boundary, reset it to upper bound.')
            tmpdate = self.clnEnd

        #990. Update the environment as per request
        #991. Set the beginning date of user calendar
        self._dateEnd_ = tmpdate

        #995. Refresh the user calendar
        self._usrclndr_ : pd.DataFrame = self._subCalendar( datebgn = self._dateBgn_ , dateend = self._dateEnd_ )
    #End of [dateEnd]

#End Class

'''
#-Notes- -Begin-
#Full Test Program[1]:
if __name__=='__main__':
    #100. Create envionment.
    import datetime as dt
    import sys
    dir_omniPy : str = r'D:\Python\ '.strip()
    if dir_omniPy not in sys.path:
        sys.path.append( dir_omniPy )
    from omniPy.Dates import UserCalendar

    #110. Create the calendar object.
    cln = UserCalendar( '20201225' , '20210103' )
    # Check parameters.
    cln.params

    #200. Retrieve the dataset.
    testdata = cln.usrCalendar

    #302. Retrieve the # of years and the # of months across the period.
    print( 'The period covers {0} years, or {1} months equivalent.'.format(cln.kYear,cln.kMth) )
    cln.mthlist[:10]

    #310. Calendar Days of Months.
    cdlst = cln.cd_of_months

    #313. Retrieve all the Calendar Days of the provided month.
    cdlst['202012'][:]

    #400. Retrieve the Work Days within the period.
    print( 'There are {0} Work Days in this period'.format(cln.kWorkDay) )
    cln.d_AllWD[:10]
    cln.fmtDateOut = '%Y-%m-%d'
    cln.d_AllWD[:5]
    #Reset the format
    cln.fmtDateOut = '%Y%m%d'
    cln.DateOutAsStr = False
    print( 'There are {0} Trade Days in this period'.format(cln.kTradeDay) )

    #410. Work Days of Months.
    wdlst = cln.wd_of_months

    #611. Last Work days of all quarters in the period respectively.
    qtrlst = cln.FirstWDofQtr

    #700. Test invalid input
    #710. Provide no parameter
    #[ASSUMPTION]
    #[1] In such case, <clnBgn> and <clnEnd> are not provided and the instance falls back to their respective default values,
    #     hence there is no warning message
    #[2] It has the same behavior as when <dateBgn> and <dateEnd> are provided while <clnBgn> and <clnEnd> are not
    cln = UserCalendar()
    print(f'{cln.dateBgn=:%Y%m%d}, {cln.dateEnd=:%Y%m%d}')
    # cln.dateBgn=20210103, cln.dateEnd=20260202

    #730. Provide invalid parameters
    #[ASSUMPTION]
    #[1] In such case, <clnBgn> and/or <clnEnd> are provided with invalid dates, the instance tries to overwrite them with the
    #     requested dates with a warning message
    cln = UserCalendar(dateBgn = '20260101', dateEnd = '20260102', clnBgn = None, clnEnd = None)
    # UserWarning: [UserCalendar]<clnBgn> is invalid and deemed the same as <dateBgn>!
    # UserWarning: [UserCalendar]<clnEnd> is invalid and deemed the same as <dateEnd>!

    print(f'{cln.dateBgn=:%Y%m%d}, {cln.dateEnd=:%Y%m%d}')
    # cln.dateBgn=20260101, cln.dateEnd=20260102
#-Notes- -End-
'''
