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
#   |   |   |   |[2] With the Signature Expansion functionality, one can obtain its correct signature at runtime in below way           #
#   |   |   |   |    [1] Type <args(func)> in the console to see its full argument list expanded from those retained from the ancestors #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[dateBgn      ]   :   Beginning date of the user calendar, provided by any object that can be coerced to <Date> class      #
#   |   |   |                      [NULL                ]<Default> Same as <clnBgn>                                                     #
#   |   |   |[dateEnd      ]   :   Ending date of the user calendar, provided by any object that can be coerced to <Date> class         #
#   |   |   |                      [NULL                ]<Default> Same as <clnEnd>                                                     #
#   |   |   |...               :   Any other arguments to expand from its ancestor; see its official document                           #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<NULL>            :   This method does not return values, but will assign values to variables for <private> object         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |400.   Private method                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |[.getBoundOfPeriod]                                                                                                            #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to get the <first/last> of <workdays/tradedays> for the specified period                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[daytype      ]   :   <chr> Type of the date to retrieve                                                                   #
#   |   |   |                      [W                   ]<Default> Extract Workday                                                      #
#   |   |   |                      [T                   ]          Extract Tradeday                                                     #
#   |   |   |[.bound       ]   :   <chr> Determine whether to retrieve the beginning or ending of the period                            #
#   |   |   |                      [head                ]<Default> Extract the beginning                                                #
#   |   |   |                      [tail                ]          Extract the end                                                      #
#   |   |   |[.period      ]   :   <chr> Period name to extract the date                                                                #
#   |   |   |                      [MONTH               ]<Default> Extract the bound of each month                                      #
#   |   |   |                      [QUARTER             ]          Extract the bound of each QUARTER                                    #
#   |   |   |                      [WEEK                ]          Extract the bound of each workweek/tradeweek                         #
#   |   |   |                      [YEAR                ]          Extract the bound of each YEAR                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<Date>            :   Vector of the extraction result for the entire period of user calendar                               #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |500.   Read-only properties.                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |100.   Description.                                                                                                            #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
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
#   |   |   | usrCalendar                 | <data.frame> data frame of the user calendar defined by <dateBgn> and <dateEnd>             #
#   |   |   | kYear                       | <2> # of years that the period covers                                                       #
#   |   |   | kMth                        | <19> # of months that the period covers                                                     #
#   |   |   | yearlist                    | <2015,2016> numeric vector of years that the period covers                                  #
#   |   |   | mthlist                     | <'201501',...,'201607'> vector of months that the period covers                             #
#   |   |   | qtrlist                     | <'2015Q1',...,'2016Q3'> vector of quarters that the period covers                           #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | kClnDay                     | <550> # of Calendar Days within the period                                                  #
#   |   |   | d_AllCD                     | <date(2015-01-01),...,date(2016-07-03)> vector of all Clndr days                            #
#   |   |   | kWorkDay                    | <373> # of Work Days within the period                                                      #
#   |   |   | d_AllWD                     | <date(20150104),...,date(20160701)> vector of All Work days                                 #
#   |   |   | kTradeDay                   | <365> # of Trade Days within the period                                                     #
#   |   |   | d_AllTD                     | <date(20150105),...,date(20160701)> vector of All Trade days                                #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | cd_of_months                | <list> names represent all months; values represent Calendar Days of each month             #
#   |   |   | FirstCDofMon                | <date(20150101),...,date(20160701)> First Calendar Days of each month                       #
#   |   |   | LastCDofMon                 | <date(20150131),...,date(20160703)> Last Calendar Days of each month                        #
#   |   |   | kCDofMon                    | <31,...,3> # of Calendar Days of each month                                                 #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | wd_of_months                | <list> names represent all months; values represent Work Days of each month                 #
#   |   |   | FirstWDofMon                | <date(20150104),...,date(20160701)> First Workdays of each month                            #
#   |   |   | LastWDofMon                 | <date(20150130),...,date(20160701)> Last Workdays of each month                             #
#   |   |   | kWDofMon                    | <21,...,1> # of Workdays of each month                                                      #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | td_of_months                | <list> names represent all months; values represent Trade Days of each month                #
#   |   |   | FirstTDofMon                | <date(20150105),...,date(20160701)> First Tradedays of each month                           #
#   |   |   | LastTDofMon                 | <date(20150130),...,date(20160701)> Last Tradedays of each month                            #
#   |   |   | kTDofMon                    | <20,...,1> # of Tradedays of each month                                                     #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | kWorkWeek                   | <77> # of Work Weeks within the period                                                      #
#   |   |   | workweeks                   | <list> names represent all Work Weeks; values represent Work Days of each Week              #
#   |   |   | FirstWDofWeek               | <date(20150104),...,date(20160701)> First Workdays of each work week                        #
#   |   |   | LastWDofWeek                | <date(20150109),...,date(20160701)> Last Workdays of each work week                         #
#   |   |   | kWDofWeek                   | <6,...,5> # of Workdays of each work week                                                   #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | kTradeWeek                  | <77> # of Trade Weeks within the period                                                     #
#   |   |   | tradeweeks                  | <list> names represent all Trade Weeks; values represent Trade Days of each Week            #
#   |   |   | FirstTDofWeek               | <date(20150105),...,date(20160701)> First Tradedays of each trade week                      #
#   |   |   | LastTDofWeek                | <date(20150109),...,date(20160701)> Last Tradedays of each trade week                       #
#   |   |   | kTDofWeek                   | <5,...,5> # of Tradedays of each trade week                                                 #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | cd_of_quarters              | <list> names represent all quarters; values represent Calendar Days of each quarter         #
#   |   |   | FirstCDofQtr                | <date(20150101),...,date(20160701)> First Calendar Days of each quarter                     #
#   |   |   | LastCDofQtr                 | <date(20150331),...,date(20160703)> Last Calendar Days of each quarter                      #
#   |   |   | kCDofQtr                    | <90,...,3> # of Calendar Days of each quarter                                               #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | wd_of_quarters              | <list> names represent all quarters; values represent Work Days of each quarter             #
#   |   |   | FirstWDofQtr                | <date(20150104),...,date(20160701)> First Workdays of each quarter                          #
#   |   |   | LastWDofQtr                 | <date(20150331),...,date(20160701)> Last Workdays of each quarter                           #
#   |   |   | kWDofQtr                    | <60,...,1> # of Workdays of each quarter                                                    #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | td_of_quarters              | <list> names represent all quarters; values represent Trade Days of each quarter            #
#   |   |   | FirstTDofQtr                | <date(20150105),...,date(20160701)> First Tradedays of each quarter                         #
#   |   |   | LastTDofQtr                 | <date(20150331),...,date(20160701)> Last Tradedays of each quarter                          #
#   |   |   | kTDofQtr                    | <57,...,1> # of Tradedays of each quarter                                                   #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | cd_of_years                 | <list> names represent all years; values represent Calendar Days of each year               #
#   |   |   | FirstCDofYear               | <date(20150101),...,date(20160101)> First Calendar Days of each year                        #
#   |   |   | LastCDofYear                | <date(20151231),...,date(20160703)> Last Calendar Days of each year                         #
#   |   |   | kCDofYear                   | <365,185> # of Calendar Days of each year                                                   #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | wd_of_years                 | <list> names represent all years; values represent Work Days of each year                   #
#   |   |   | FirstWDofYear               | <date(20150104),...,date(20160104)> First Workdays of each year                             #
#   |   |   | LastWDofYear                | <date(20151231),...,date(20160701)> Last Workdays of each year                              #
#   |   |   | kWDofYear                   | <249,124> # of Workdays of each year                                                        #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |   | td_of_years                 | <list> names represent all years; values represent Trade Days of each year                  #
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
#   |   |   |   |[1] When <set> is called, it changes <private$.dateBgn>                                                                #
#   |   |   |   |[2] When <return> is called, it returns the last value of <private$.dateBgn>                                           #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[udate        ]   :   Vector/list of dates, or character strings which can be coerced to <Date> class                      #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<vec/list>        :   The same values as the previous input by the user                                                    #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[dateEnd]                                                                                                                      #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |   |001.   Introduction.                                                                                                       #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |This method is intended to set or return the ending date of the subset of universal calendar, e.g. for loop usage      #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |NOTE                                                                                                                   #
#   |   |   |   |-----------------------------------------------------------------------------------------------------------------------#
#   |   |   |   |[1] When <set> is called, it changes <private$.dateEnd>                                                                #
#   |   |   |   |[2] When <return> is called, it returns the last value of <private$.dateEnd>                                           #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |100.   Parameters.                                                                                                         #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[udate        ]   :   Vector/list of dates, or character strings which can be coerced to <Date> class                      #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |<vec/list>        :   The same values as the previous input by the user                                                    #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210205        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210904        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Set default <clnBgn> as Jan 1st of the previous year to current one, and <clnEnd> as Dec 31st of the next year to       #
#   |      |     current one, given none of the dates is provided. This is the minimum reasonable period for processing.                #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230114        | Version | 2.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce a function <match.arg.x> to enable matching args after mutation, e.g. case-insensitive match                  #
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
#   |   |R6, magrittr, lubridate, dplyr                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |Dates                                                                                                                          #
#   |   |   |asDates                                                                                                                    #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |match.arg.x                                                                                                                #
#   |   |   |ExpandSignature                                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Parent classes                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |Dates                                                                                                                          #
#   |   |   |CoreUserCalendar                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	R6, magrittr, lubridate, dplyr
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

library(magrittr)

#010. Activate required packages before defining the function
if (!require(R6)) install.packages(R6)

#100. Prepare the Class.
UserCalendar <- local({
#100. Prepare a decorated initialization structure as parametric signature expansion
#[ASSUMPTION]
#[1] By instantiation of below class, we resemble a <class decorator> in Python
deco <- ExpandSignature$new(CoreUserCalendar$public_methods$initialize, instance = 'eSig')

.init. <- deco$wrap(function(
	dateBgn = NULL
	,dateEnd = NULL
	,...
){
	#020. Local environment
	dots <- rlang::list2(...)
	args_share <- list()
	eSig$vfyConflict(args_share)
	self$.eSig. <- eSig
	args_in <- self$.eSig.$updParams(args_share, dots)

	#100. Assign values to local variables
	private$classname <- head(class(self),1)
	super$fmtDateIn = self$.eSig.$getParam('fmtDateIn', args_in, inc_default = T) %>% eval()
	fr_default_clnBgn <- self$.eSig.$isDefault('clnBgn', scope_ = 'src') %>% eval()
	fr_default_clnEnd <- self$.eSig.$isDefault('clnEnd', scope_ = 'src') %>% eval()

	#300. Determine the bounds of the internal calendar, given either of them is not provided at initialization
	#310. Identify the valid dates from the input
	int_clnBgn <- asDates(self$.eSig.$getParam('clnBgn', args_in, inc_default = T) %>% eval(), super$fmtDateIn) %>%
		{.[!is.na(.)]}
	int_clnEnd <- asDates(self$.eSig.$getParam('clnEnd', args_in, inc_default = T) %>% eval(), super$fmtDateIn) %>%
		{.[!is.na(.)]}
	int_dateBgn <- asDates(dateBgn, super$fmtDateIn) %>%
		{.[!is.na(.)]}
	int_dateEnd <- asDates(dateEnd, super$fmtDateIn) %>%
		{.[!is.na(.)]}

	#317. Raise exception for invalid input
	if (length(int_dateBgn) > 1){
		stop('[',private$classname,']Multiple <dateBgn> provided!')
	}
	if (length(int_dateEnd) > 1){
		stop('[',private$classname,']Multiple <dateEnd> provided!')
	}
	if (length(int_clnBgn) > 1){
		stop('[',private$classname,']Multiple <clnBgn> provided!')
	}
	if (length(int_clnEnd) > 1){
		stop('[',private$classname,']Multiple <clnEnd> provided!')
	}
	if (length(int_dateBgn) == 0 && length(int_clnBgn) == 0){
		stop('[',private$classname,']Both <dateBgn> and <clnBgn> are invalid!')
	}
	if (length(int_dateEnd) == 0 && length(int_clnEnd) == 0){
		stop('[',private$classname,']Both <dateEnd> and <clnEnd> are invalid!')
	}

	#319. Warn for invalid input that can be overridden
	if (length(int_clnBgn) == 0){
		warning('[',private$classname,']<clnBgn> is invalid and deemed the same as <dateBgn>!')
	}
	if (length(int_clnEnd) == 0){
		warning('[',private$classname,']<clnEnd> is invalid and deemed the same as <dateEnd>!')
	}

	#340. Transform the beginning when necessary
	if (length(int_dateBgn) == 1){
		if (fr_default_clnBgn || (length(int_clnBgn) == 0)) {
			int_clnBgn <- int_dateBgn
		}
	}

	#370. Transform the ending when necessary
	if (length(int_dateEnd) == 1){
		if (fr_default_clnEnd || (length(int_clnEnd) == 0)) {
			int_clnEnd <- int_dateEnd
		}
	}

	#500. Instantiate parent class
	#[For methods/variables (i.e. members) set in parent class]
	#[1] After the instantiation of parent class, all its [private] members will have been localized
	#[2] We have to use [private$] syntax for referencing the [private] members in parent class
	#[3] We have to use [super$] syntax for referencing the [public] and [active] members in parent class
	#[For members set in current class]
	#[1] We have to use [self$] syntax for referencing the [public] and [active] members in current class
	args_upd = list(
		'clnBgn' = int_clnBgn
		,'clnEnd' = int_clnEnd
	)
	args_super <- self$.eSig.$updParams(args_upd, args_in)
	do.call(super$initialize, args_super)

	#700. Assign values to local variables
	#We cannot call methods to assign below values, for they are mutually bound to verification against each other.
	if (length(int_dateBgn)==0) private$.dateBgn <- super$clnBgn
	else private$.dateBgn <- int_dateBgn
	if (length(int_dateEnd)==0) private$.dateEnd <- super$clnEnd
	else private$.dateEnd <- int_dateEnd

	#709. Raise warning if the user required period exceeds the universal calendar
	if ( (self$dateBgn < super$clnBgn) | (self$dateEnd > super$clnEnd) ){
		stop(
			'[',private$classname,']User requested period exceeds the universal calendar!\n'
			,'[dateBgn]=[',self$dateBgn,'][dateEnd]=[',self$dateEnd,']'
			,'[clnBgn]=[',super$clnBgn,'][clnEnd]=[',super$clnEnd,']'
		)
	}

	#800. Create the user calendar
	private$.usrclndr <- private$.subCalendar(
		datebgn = self$dateBgn
		,dateend = self$dateEnd
	)
})

#900. Export the complete definition of the class
myclass <- do.call(R6::R6Class, list(
	classname = 'UserCalendar'
	,inherit = CoreUserCalendar
	,public = list(
		#Below link demonstrates the way to initialize an R6 Class together with its parent class generator
		#[Quote: https://stackoverflow.com/questions/35925664/change-initialize-method-in-subclass-of-an-r6-class ]
		#Below link demonstrates the way to find all ancestors of an R6 Class recursively
		#[Quote: https://stackoverflow.com/questions/37303552/r-r6-get-full-class-name-from-r6generator-object ]
		initialize = .init.
		,.eSig. = NULL
	)
	,private = list(
		.usrclndr = NULL
		,.dateBgn = NULL
		,.dateEnd = NULL
		,classname = NULL
		,.getBoundOfPeriod = function(
			daytype = c('W','T')
			,.bound = c('head','tail')
			,.period = c('MONTH','QUARTER','WEEK','YEAR')
		){
			#001. Handle parameters
			daytype <- match.arg.x(daytype, arg.func = toupper)
			.bound <- match.arg.x(.bound, arg.func = tolower)
			.period <- match.arg.x(.period, arg.func = toupper)

			#100. Local variables
			col_filter <- list('W' = 'F_WORKDAY', 'T' = 'F_TradeDay')
			wk_filter <- list('W' = 'K_WorkWeek', 'T' = 'K_TradeWeek')
			#[Quote: https://stackoverflow.com/questions/20535247/how-to-find-all-functions-in-an-r-package ]
			#[getNamespaceExports(pkgName)]
			#[ls(getNamespace(pkgName))]
			func_bound <- eval( parse( text = paste0('dplyr::slice_',.bound) ) )

			#300. Prepare the data
			df_cln <- private$.usrclndr %>% dplyr::filter_at(col_filter[[daytype]], ~.)

			#500. Conduct different filtration as per request
			if (.period=='MONTH') df_cln <- df_cln %>% dplyr::mutate(C_PRD = strftime(D_DATE, '%Y%m'))
			else if (.period=='QUARTER') df_cln <- df_cln %>% dplyr::mutate(C_PRD = paste0(lubridate::year(D_DATE),'Q',Qtr))
			else if (.period=='WEEK') names(df_cln)[[match(wk_filter[[daytype]],names(df_cln))]] <- 'C_PRD'
			else if (.period=='YEAR') df_cln <- df_cln %>% dplyr::mutate(C_PRD = lubridate::year(D_DATE))
			else stop('[',private$classname,'][.period=',.period,'] is not defined!')

			#700. Filter the result
			df_out <- df_cln %>%
				dplyr::group_by(C_PRD) %>%
				dplyr::arrange(D_DATE) %>%
				func_bound() %>%
				dplyr::ungroup()

			#800. Add names to the values
			val_out <- df_out %>% dplyr::pull(D_DATE, name = C_PRD)
			# names(val_out) <- df_out$C_PRD

			#890. Convert the date values into strings as per request
			if (super$DateOutAsStr) val_out <- strftime(val_out, super$fmtDateOut)

			#999. Return the result
			return(val_out)
		}
	)
	,active = list(
		#100. Output the parameters.
		params = function(){
			cat(paste('Beginning of the User Calendar:',paste0('[',self$dateBgn,']\n')))
			cat(paste('Ending of the User Calendar:',paste0('[',self$dateEnd,']\n')))
			cat(paste('Country Code:',paste0('[',super$country,']\n')))
			cat(paste('Calendar Adjustment:',paste0('[',super$clnAdj,']\n')))
			cat(paste('How to input the strings into dates:',paste0('[',paste0(super$fmtDateIn, collapse = ']['),']\n')))
			cat(paste('How to display the results as formatted in string:',paste0('[',super$fmtDateOut,']\n')))
			cat(paste('# of days to extend the calculation before beginning and after ending:',paste0('[',super$datespan,']\n')))
		}
		,usrCalendar = function(){
			return(private$.usrclndr)
		}
		,dateBgn = function(udate){
			#001. Return the value as requested
			if (missing(udate)) return(private$.dateBgn)

			#100. Reset the user requested beginning to that of the universal calendar if it is provided but with no value
			if (length(udate)==0) {
				warning('[',private$classname,']No value is provided for [Beginning], reset it to lower bound.')
				udate <- super$clnBgn
			}

			#300. Translate the input values if any
			tmpdate <- asDates(udate, fmt = super$fmtDateIn)
			if (length(tmpdate)>1) {
				warning('[',private$classname,']Multiple values provided for [Beginning], only the first one is used.')
				tmpdate <- head(tmpdate, 1)
			}

			#700. Reset it if it exceeds the boundary of the calendar
			if (tmpdate < super$clnBgn | tmpdate > private$.dateEnd) {
				warning('[',private$classname,']Input value for [Beginning] exceeds the boundary, reset it to lower bound.')
				tmpdate <- super$clnBgn
			}

			#990. Update the environment as per request
			#991. Set the beginning date of user calendar
			private$.dateBgn <- tmpdate

			#995. Refresh the user calendar
			private$.usrclndr <- private$.subCalendar(
				datebgn = private$.dateBgn
				,dateend = private$.dateEnd
			)
		}
		,dateEnd = function(udate){
			#001. Return the value as requested
			if (missing(udate)) return(private$.dateEnd)

			#100. Reset the user requested ending to that of the universal calendar if it is provided but with no value
			if (length(udate)==0) {
				warning('[',private$classname,']No value is provided for [Ending], reset it to upper bound.')
				udate <- super$clnEnd
			}

			#300. Translate the input values if any
			tmpdate <- asDates(udate, fmt = super$fmtDateIn)
			if (length(tmpdate)>1) {
				warning('[',private$classname,']Multiple values provided for [Ending], only the first one is used.')
				tmpdate <- head(tmpdate, 1)
			}

			#700. Reset it if it exceeds the boundary of the calendar
			if (tmpdate > super$clnEnd | tmpdate < private$.dateBgn) {
				warning('[',private$classname,']Input value for [Ending] exceeds the boundary, reset it to upper bound.')
				tmpdate <- super$clnEnd
			}

			#990. Update the environment as per request
			#991. Set the beginning date of user calendar
			private$.dateEnd <- tmpdate

			#995. Refresh the user calendar
			private$.usrclndr <- private$.subCalendar(
				datebgn = private$.dateBgn
				,dateend = private$.dateEnd
			)
		}

		#Read-only properties
		,kYear = function(){
			private$.usrclndr$D_DATE %>% lubridate::year() %>% unique() %>% length()
		}
		,kMth = function(){
			private$.usrclndr$D_DATE %>% strftime('%Y%m') %>% unique() %>% length()
		}
		,yearlist = function(){
			df_year <- private$.usrclndr %>%
				dplyr::distinct(lubridate::year(D_DATE)) %>%
				unlist() %>%
				unname()
			return( df_year )
		}
		,mthlist = function(){
			df_mth <- private$.usrclndr %>%
				dplyr::distinct(strftime(D_DATE, '%Y%m')) %>%
				unlist() %>%
				unname()
			return( df_mth )
		}
		,qtrlist = function(){
			df_qtr <- private$.usrclndr %>%
				dplyr::mutate(YearQ = paste0(lubridate::year(D_DATE),'Q',Qtr)) %>%
				dplyr::distinct(YearQ) %>%
				unlist() %>%
				unname()
			return( df_qtr )
		}

		,kClnDay = function(){
			return( nrow(private$.usrclndr) )
		}
		,d_AllCD = function(){
			#100. Calculation
			val_out <- private$.usrclndr %>% dplyr::pull(D_DATE)

			#890. Convert the date values into strings as per request
			if (super$DateOutAsStr) val_out <- strftime(val_out, super$fmtDateOut)

			#999. Return values
			return( val_out )
		}
		,kWorkDay = function(){
			return( nrow(dplyr::filter(private$.usrclndr, F_WORKDAY)) )
		}
		,d_AllWD = function(){
			#100. Calculation
			val_out <- private$.usrclndr %>%
				dplyr::filter(F_WORKDAY) %>%
				dplyr::pull(D_DATE)

			#890. Convert the date values into strings as per request
			if (super$DateOutAsStr) val_out <- strftime(val_out, super$fmtDateOut)

			#999. Return values
			return( val_out )
		}
		,kTradeDay = function(){
			return( nrow(dplyr::filter(private$.usrclndr, F_TradeDay)) )
		}
		,d_AllTD = function(){
			#100. Calculation
			val_out <- private$.usrclndr %>%
				dplyr::filter(F_TradeDay) %>%
				dplyr::pull(D_DATE)

			#890. Convert the date values into strings as per request
			if (super$DateOutAsStr) val_out <- strftime(val_out, super$fmtDateOut)

			#999. Return values
			return( val_out )
		}

		,cd_of_months = function(){
			l_mth <- sapply(
				self$mthlist
				,function(m){
					#100. Calculation
					val_out <- private$.usrclndr %>%
						dplyr::filter(strftime(D_DATE, '%Y%m') == m) %>%
						dplyr::pull(D_DATE)

					#890. Convert the date values into strings as per request
					if (super$DateOutAsStr) val_out <- strftime(val_out, super$fmtDateOut)

					#999. Return values
					return( val_out )
				}
				,USE.NAMES = T
				#Below option is to prevent the list from being flattened when the period only covers one month.
				#The same logic applies to all similar functions below.
				,simplify = F
			)
			return( l_mth )
		}
		,FirstCDofMon = function(){
			#100. Calculation
			val_out <- sapply(self$cd_of_months, function(m){m[[1]]}, USE.NAMES = T)

			#890. Convert the date values into strings as per request
			if (super$DateOutAsStr) return( val_out )
			else return( asDates(val_out, super$fmtDateOut) )
		}
		,LastCDofMon = function(){
			#100. Calculation
			val_out <- sapply(self$cd_of_months, function(m){m[[length(m)]]}, USE.NAMES = T)

			#890. Convert the date values into strings as per request
			if (super$DateOutAsStr) return( val_out )
			else return( asDates(val_out, super$fmtDateOut) )
		}
		,kCDofMon = function(){
			sapply(self$cd_of_months, function(m){length(m)}, USE.NAMES = T)
		}

		,wd_of_months = function(){
			l_mth <- sapply(
				self$mthlist
				,function(m){
					#100. Calculation
					val_out <- private$.usrclndr %>%
						dplyr::filter(strftime(D_DATE, '%Y%m') == m, F_WORKDAY) %>%
						dplyr::pull(D_DATE)

					#890. Convert the date values into strings as per request
					if (super$DateOutAsStr) val_out <- strftime(val_out, super$fmtDateOut)

					#999. Return values
					return( val_out )
				}
				,USE.NAMES = T
				,simplify = F
			)
			return( l_mth )
		}
		,FirstWDofMon = function(){
			#We cannot simply use [sapply] to create the list, as there could be no member within any of the elements
			# sapply(self$wd_of_months, function(m){m[[1]]}, USE.NAMES = T) %>% as.Date(lubridate::origin)
			private$.getBoundOfPeriod( daytype = 'w', .bound = 'h', .period = 'm' )
		}
		,LastWDofMon = function(){
			# sapply(self$wd_of_months, function(m){m[[length(m)]]}, USE.NAMES = T) %>% as.Date(lubridate::origin)
			private$.getBoundOfPeriod( daytype = 'w', .bound = 't', .period = 'm' )
		}
		,kWDofMon = function(){
			sapply(self$wd_of_months, function(m){length(m)}, USE.NAMES = T)
		}

		,td_of_months = function(){
			l_mth <- sapply(
				self$mthlist
				,function(m){
					#100. Calculation
					val_out <- private$.usrclndr %>%
						dplyr::filter(strftime(D_DATE, '%Y%m') == m, F_TradeDay) %>%
						dplyr::pull(D_DATE)

					#890. Convert the date values into strings as per request
					if (super$DateOutAsStr) val_out <- strftime(val_out, super$fmtDateOut)

					#999. Return values
					return( val_out )
				}
				,USE.NAMES = T
				,simplify = F
			)
			return( l_mth )
		}
		,FirstTDofMon = function(){
			private$.getBoundOfPeriod( daytype = 't', .bound = 'h', .period = 'm' )
		}
		,LastTDofMon = function(){
			private$.getBoundOfPeriod( daytype = 't', .bound = 't', .period = 'm' )
		}
		,kTDofMon = function(){
			sapply(self$td_of_months, function(m){length(m)}, USE.NAMES = T)
		}

		,kWorkWeek = function(){
			return( max(private$.usrclndr$K_WorkWeek) )
		}
		,workweeks = function(){
			l_wks <- sapply(
				seq_len(self$kWorkWeek)
				,function(w){
					#100. Calculation
					val_out <- private$.usrclndr %>%
						dplyr::filter(K_WorkWeek == w) %>%
						dplyr::pull(D_DATE)

					#890. Convert the date values into strings as per request
					if (super$DateOutAsStr) val_out <- strftime(val_out, super$fmtDateOut)

					#999. Return values
					return( val_out )
				}
				,USE.NAMES = F
				,simplify = F
			)
			names(l_wks) <- seq_len(self$kWorkWeek)
			return( l_wks )
		}
		,FirstWDofWeek = function(){
			private$.getBoundOfPeriod( daytype = 'w', .bound = 'h', .period = 'w' )
		}
		,LastWDofWeek = function(){
			private$.getBoundOfPeriod( daytype = 'w', .bound = 't', .period = 'w' )
		}
		,kWDofWeek = function(){
			sapply(self$workweeks, function(m){length(m)}, USE.NAMES = T)
		}

		,kTradeWeek = function(){
			return( max(private$.usrclndr$K_TradeWeek) )
		}
		,tradeweeks = function(){
			l_wks <- sapply(
				seq_len(self$kTradeWeek)
				,function(w){
					#100. Calculation
					val_out <- private$.usrclndr %>%
						dplyr::filter(K_TradeWeek == w) %>%
						dplyr::pull(D_DATE)

					#890. Convert the date values into strings as per request
					if (super$DateOutAsStr) val_out <- strftime(val_out, super$fmtDateOut)

					#999. Return values
					return( val_out )
				}
				,USE.NAMES = F
				,simplify = F
			)
			names(l_wks) <- seq_len(self$kTradeWeek)
			return( l_wks )
		}
		,FirstTDofWeek = function(){
			private$.getBoundOfPeriod( daytype = 't', .bound = 'h', .period = 'w' )
		}
		,LastTDofWeek = function(){
			private$.getBoundOfPeriod( daytype = 't', .bound = 't', .period = 'w' )
		}
		,kTDofWeek = function(){
			sapply(self$tradeweeks, function(m){length(m)}, USE.NAMES = T)
		}

		,cd_of_quarters = function(){
			l_qtr <- sapply(
				self$qtrlist
				,function(q){
					#100. Calculation
					val_out <- private$.usrclndr %>%
						dplyr::filter(paste0(lubridate::year(D_DATE),'Q',Qtr) == q) %>%
						dplyr::pull(D_DATE)

					#890. Convert the date values into strings as per request
					if (super$DateOutAsStr) val_out <- strftime(val_out, super$fmtDateOut)

					#999. Return values
					return( val_out )
				}
				,USE.NAMES = T
				,simplify = F
			)
			return( l_qtr )
		}
		,FirstCDofQtr = function(){
			#100. Calculation
			val_out <- sapply(self$cd_of_quarters, function(m){m[[1]]}, USE.NAMES = T)

			#890. Convert the date values into strings as per request
			if (super$DateOutAsStr) return( val_out )
			else return( asDates(val_out, super$fmtDateOut) )
		}
		,LastCDofQtr = function(){
			#100. Calculation
			val_out <- sapply(self$cd_of_quarters, function(m){m[[length(m)]]}, USE.NAMES = T)

			#890. Convert the date values into strings as per request
			if (super$DateOutAsStr) return( val_out )
			else return( asDates(val_out, super$fmtDateOut) )
		}
		,kCDofQtr = function(){
			sapply(self$cd_of_quarters, function(m){length(m)}, USE.NAMES = T)
		}

		,wd_of_quarters = function(){
			l_qtr <- sapply(
				self$qtrlist
				,function(q){
					#100. Calculation
					val_out <- private$.usrclndr %>%
						dplyr::filter(paste0(lubridate::year(D_DATE),'Q',Qtr) == q, F_WORKDAY) %>%
						dplyr::pull(D_DATE)

					#890. Convert the date values into strings as per request
					if (super$DateOutAsStr) val_out <- strftime(val_out, super$fmtDateOut)

					#999. Return values
					return( val_out )
				}
				,USE.NAMES = T
				,simplify = F
			)
			return( l_qtr )
		}
		,FirstWDofQtr = function(){
			private$.getBoundOfPeriod( daytype = 'w', .bound = 'h', .period = 'q' )
		}
		,LastWDofQtr = function(){
			private$.getBoundOfPeriod( daytype = 'w', .bound = 't', .period = 'q' )
		}
		,kWDofQtr = function(){
			sapply(self$wd_of_quarters, function(m){length(m)}, USE.NAMES = T)
		}

		,td_of_quarters = function(){
			l_qtr <- sapply(
				self$qtrlist
				,function(q){
					#100. Calculation
					val_out <- private$.usrclndr %>%
						dplyr::filter(paste0(lubridate::year(D_DATE),'Q',Qtr) == q, F_TradeDay) %>%
						dplyr::pull(D_DATE)

					#890. Convert the date values into strings as per request
					if (super$DateOutAsStr) val_out <- strftime(val_out, super$fmtDateOut)

					#999. Return values
					return( val_out )
				}
				,USE.NAMES = T
				,simplify = F
			)
			return( l_qtr )
		}
		,FirstTDofQtr = function(){
			private$.getBoundOfPeriod( daytype = 't', .bound = 'h', .period = 'q' )
		}
		,LastTDofQtr = function(){
			private$.getBoundOfPeriod( daytype = 't', .bound = 't', .period = 'q' )
		}
		,kTDofQtr = function(){
			sapply(self$td_of_quarters, function(m){length(m)}, USE.NAMES = T)
		}

		,cd_of_years = function(){
			l_year <- sapply(
				self$yearlist
				,function(y){
					#100. Calculation
					val_out <- private$.usrclndr %>%
						dplyr::filter(lubridate::year(D_DATE) == y) %>%
						dplyr::pull(D_DATE)

					#890. Convert the date values into strings as per request
					if (super$DateOutAsStr) val_out <- strftime(val_out, super$fmtDateOut)

					#999. Return values
					return( val_out )
				}
				,USE.NAMES = T
				,simplify = F
			)
			names(l_year) <- self$yearlist
			return( l_year )
		}
		,FirstCDofYear = function(){
			#100. Calculation
			val_out <- sapply(self$cd_of_years, function(m){m[[1]]}, USE.NAMES = T)

			#890. Convert the date values into strings as per request
			if (super$DateOutAsStr) return( val_out )
			else return( asDates(val_out, super$fmtDateOut) )
		}
		,LastCDofYear = function(){
			#100. Calculation
			val_out <- sapply(self$cd_of_years, function(m){m[[length(m)]]}, USE.NAMES = T)

			#890. Convert the date values into strings as per request
			if (super$DateOutAsStr) return( val_out )
			else return( asDates(val_out, super$fmtDateOut) )
		}
		,kCDofYear = function(){
			sapply(self$cd_of_years, function(m){length(m)}, USE.NAMES = T)
		}

		,wd_of_years = function(){
			l_year <- sapply(
				self$yearlist
				,function(y){
					#100. Calculation
					val_out <- private$.usrclndr %>%
						dplyr::filter(lubridate::year(D_DATE) == y, F_WORKDAY) %>%
						dplyr::pull(D_DATE)

					#890. Convert the date values into strings as per request
					if (super$DateOutAsStr) val_out <- strftime(val_out, super$fmtDateOut)

					#999. Return values
					return( val_out )
				}
				,USE.NAMES = T
				,simplify = F
			)
			names(l_year) <- self$yearlist
			return( l_year )
		}
		,FirstWDofYear = function(){
			private$.getBoundOfPeriod( daytype = 'w', .bound = 'h', .period = 'y' )
		}
		,LastWDofYear = function(){
			private$.getBoundOfPeriod( daytype = 'w', .bound = 't', .period = 'y' )
		}
		,kWDofYear = function(){
			sapply(self$wd_of_years, function(m){length(m)}, USE.NAMES = T)
		}

		,td_of_years = function(){
			l_year <- sapply(
				self$yearlist
				,function(y){
					val_out <- private$.usrclndr %>%
						dplyr::filter(lubridate::year(D_DATE) == y, F_TradeDay) %>%
						dplyr::pull(D_DATE)

					#890. Convert the date values into strings as per request
					if (super$DateOutAsStr) val_out <- strftime(val_out, super$fmtDateOut)

					#999. Return values
					return( val_out )
				}
				,USE.NAMES = T
				,simplify = F
			)
			names(l_year) <- self$yearlist
			return( l_year )
		}
		,FirstTDofYear = function(){
			private$.getBoundOfPeriod( daytype = 't', .bound = 'h', .period = 'y' )
		}
		,LastTDofYear = function(){
			private$.getBoundOfPeriod( daytype = 't', .bound = 't', .period = 'y' )
		}
		,kTDofYear = function(){
			sapply(self$td_of_years, function(m){length(m)}, USE.NAMES = T)
		}
	)
))
return(myclass)
})

#-Notes- -Begin-
#Full Test Program[1]:
if (FALSE){
	if (T){
		#001. Establish environment
		#Below program provides the most initial environment and system options for best usage of [omniR]
		source('D:\\R\\autoexec.r')

		#100. Setup the Calendar.
		cln <- UserCalendar$new('20190301', '20190630')
		# Check parameters.
		cln$params

		#200. Retrieve the Calendar Data Frame.
		cln$usrCalendar %>% View()

		#302. Retrieve the # of years and the # of months across the period.
		sprintf( 'The period covers %s year(s), or %s month(s) equivalent.' , cln$kYear , cln$kMth )
		cln$mthlist[1:5]

		#310. Calendar Days of Months.
		cdlst <- cln$cd_of_months

		#313. Retrieve all the Calendar Days of the provided month.
		cdlst[[match('201905', cln$mthlist)]]

		#400. Retrieve the Work Days within the period.
		sprintf( 'There are %s Work Days in this period.' , cln$kWorkDay )
		cln$d_AllWD[1:10]
		cln$fmtDateOut <- '%Y-%m-%d'
		cln$d_AllWD[1:5]
		# Reset the format
		cln$fmtDateOut <- '%Y%m%d'
		cln$DateOutAsStr <- F
		sprintf( 'There are %s Trade Days in this period.' , cln$kTradeDay )

		#410. Work Days of Months.
		wdlst <- cln$wd_of_months

		#611. Last Work days of all quarters in the period respectively.
		cln2 <- UserCalendar$new('20201011', '20210103')
		cln2$usrCalendar %>% View()
		qtrlst <- cln2$wd_of_quarters

		#700. Test invalid input
		#710. Provide no parameter
		#[ASSUMPTION]
		#[1] In such case, <clnBgn> and <clnEnd> are not provided and the instance falls back to their respective default values,
		#     hence there is no warning message
		#[2] It has the same behavior as when <dateBgn> and <dateEnd> are provided while <clnBgn> and <clnEnd> are not
		cln <- UserCalendar$new()
		sprintf('cln$dateBgn=%s, cln$dateEnd=%s', cln$dateBgn %>% strftime('%Y%m%d'), cln$dateEnd %>% strftime('%Y%m%d'))
		# [1] "cln$dateBgn=20210104, cln$dateEnd=20260202"

		#730. Provide invalid parameters
		#[ASSUMPTION]
		#[1] In such case, <clnBgn> and/or <clnEnd> are provided with invalid dates, the instance tries to overwrite them with the
		#     requested dates with a warning message
		cln <- UserCalendar$new(dateBgn = '20260101', dateEnd = '20260102', clnBgn = NULL, clnEnd = NULL)
		# Warning messages:
		# 1: In (function (dateBgn = NULL, dateEnd = NULL, ...)  :
		#   [UserCalendar]<clnBgn> is invalid and deemed the same as <dateBgn>!
		# 2: In (function (dateBgn = NULL, dateEnd = NULL, ...)  :
		#   [UserCalendar]<clnEnd> is invalid and deemed the same as <dateEnd>!

		sprintf('cln$dateBgn=%s, cln$dateEnd=%s', cln$dateBgn %>% strftime('%Y%m%d'), cln$dateEnd %>% strftime('%Y%m%d'))
		# [1] "cln$dateBgn=20260101, cln$dateEnd=20260102"
	}
}
#-Notes- -End-
