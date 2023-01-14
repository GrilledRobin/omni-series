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
#   |   |   |                      [lubridate::today()  ]<Default> System date at class instantiation                                   #
#   |   |   |[clnBgn       ]   :   Beginning date of the universal calendar, provided by any object that can be coerced to [Date] class #
#   |   |   |                      [<today - 1 year>    ]<Default> Beginning of the previous year to the system date                    #
#   |   |   |[clnEnd       ]   :   Ending date of the universal calendar, provided by any object that can be coerced to [Date] class    #
#   |   |   |                      [<today + 1 year>    ]<Default> End of the next year to the system date                              #
#   |   |   |[countrycode  ]   :   Country Code to select the weekday names from the internal mapping table                             #
#   |   |   |                      [CN                  ]<Default> China                                                                #
#   |   |   |[CalendarAdj  ]   :   CSV file that stores the adjustment instructions of holidays/workdays                                #
#   |   |   |                      [NULL                ]<Default> Automatically determined, see [omniR$Dates$CoreUserCalendar]         #
#   |   |   |                       [IMPORTANT] The file must contain below columns (case sensitive to column names):                   #
#   |   |   |                                   [CountryCode ] Country Code for selection of adjustment and display of weekday names    #
#   |   |   |                                   [F_WORKDAY   ] [1/0] values indicating [workday/holiday] respectively                   #
#   |   |   |                                   [D_DATE      ] Strings to be imported as [Dates] by default option of [readr:read_csv]  #
#   |   |   |                                   [C_DESC      ] Description/Name of the special dates (compared to: Mon., Tue., etc.)    #
#   |   |   |[fmtDateIn    ]   :   Format of the [obsDate], [clnBgn] and [clnEnd] to be coerced to [Date] class                         #
#   |   |   |                      [<various>           ]<Default> Follow the rules set in [omniR$asDates]                              #
#   |   |   |[fmtDateOut   ]   :   Format of the output date values to be translated into character strings when necessary              #
#   |   |   |                      [%Y%m%d              ]<Default> Only accept one string as format, see [strftime] convention          #
#   |   |   |[DateOutAsStr ]   :   Whether to convert the output date values into character strings                                     #
#   |   |   |                      [FALSE               ]<Default> Output dates directly in the type of [datetime.date]                 #
#   |   |   |                      [TRUE                ]          Convert dates into strings based on [fmtDateOut]                     #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[ NULL        ]   :   This method does not return values, but may assign values to variables for [private] object          #
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
#   |   |   |[.bound       ]   :   Verify whether the date is at the beginning or ending of the period                                  #
#   |   |   |                      [head                ]<Default> Whether the input date is at the beginning                           #
#   |   |   |                      [tail                ]          Whether the input date is at the end                                 #
#   |   |   |[.period      ]   :   Period name to verify the date                                                                       #
#   |   |   |                      [MONTH               ]<Default> Verify the bound of each month                                       #
#   |   |   |                      [QUARTER             ]          Verify the bound of each QUARTER                                     #
#   |   |   |                      [WEEK                ]          Verify the bound of each workweek/tradeweek                          #
#   |   |   |                      [YEAR                ]          Verify the bound of each YEAR                                        #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |900.   Return Values by position.                                                                                          #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |   |[ vec         ]   :   Logical vector of the verification result for each [obsDate] respectively in the same sequence       #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |500.   Read-only properties.                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |100.   Description.                                                                                                            #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |This section lists all the read-only properties of the class.                                                                  #
#   |   |The examples listed are based on the provision of: [cln$values <- c('20210104', '20210102', '20201030', '20210207')]           #
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
#   |   |   |[<vec/list>   ]   :   The same values as the previous input by the user                                                    #
#   |   |   |-----------------------------|---------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210206        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210904        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Now treat all invalid inputs as [NA] and maintain their positions in the output result                                  #
#   |      |[2] Output [NA] or [empty string] as the shifted ones for invalid inputs                                                    #
#   |      |[3] Output [FALSE] as boundary detector for invalid inputs                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20211005        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Now support input as a table-like object (W-D, can be flagged by [omniR$AdvOp$isDF])                                    #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230114        | Version | 3.40        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce a function [match.arg.x] to enable matching args after mutation, e.g. case-insensitive match                  #
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
#   |   |R6, magrittr, lubridate, dplyr, tidyselect, tidyr                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$Dates                                                                                                                    #
#   |   |   |asDates                                                                                                                    #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvOp                                                                                                                    #
#   |   |   |isDF                                                                                                                       #
#   |   |   |match.arg.x                                                                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |700.   Parent classes                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$Dates                                                                                                                    #
#   |   |   |CoreUserCalendar                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	R6, magrittr, lubridate, dplyr, tidyselect, tidyr
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
ObsDates <- R6::R6Class('ObsDates'
	,inherit = CoreUserCalendar
	,public = list(
		#Below link demonstrates the way to initialize an R6 Class together with its parent class generator
		#[Quote: https://stackoverflow.com/questions/35925664/change-initialize-method-in-subclass-of-an-r6-class ]
		#Below link demonstrates the way to find all ancestors of an R6 Class recursively
		#[Quote: https://stackoverflow.com/questions/37303552/r-r6-get-full-class-name-from-r6generator-object ]
		initialize = function(
			obsDate = lubridate::today()
			,clnBgn = NULL
			,clnEnd = NULL
			,countrycode = 'CN'
			,CalendarAdj = NULL
			,fmtDateIn = c('%Y%m%d', '%Y-%m-%d', '%Y/%m/%d')
			,fmtDateOut = '%Y%m%d'
			,DateOutAsStr = F
		){
			#001. Handle parameters

			#100. Assign values to local variables
			super$fmtDateIn = fmtDateIn
			int_obs <- private$.obsDate.T(obsDate) %>% dplyr::pull('D_DATE')

			#300. Determine the bounds of the internal calendar, given either of them is not provided at initialization
			#310. Identify the valid dates from the input
			int_clnBgn <- asDates(clnBgn, fmtDateIn)
			int_clnBgn <- int_clnBgn[!is.na(int_clnBgn)]
			int_clnEnd <- asDates(clnEnd, fmtDateIn)
			int_clnEnd <- int_clnEnd[!is.na(int_clnEnd)]

			#340. Transform the beginning when necessary
			if (length(int_clnBgn) != 1) {
				#100. Seek help from the input values
				int_clnBgn <- int_obs[!is.na(int_obs)]

				#500. Set it when the input values can neither help
				if (length(int_clnBgn) == 0) {
					int_clnBgn <- lubridate::today()
				} else {
					int_clnBgn <- min(int_clnBgn, na.rm = T)
				}

				#900. Set it to the beginning of its previous year, which is earlier than that all existing methods can calculate
				int_clnBgn <- lubridate::make_date(lubridate::year(int_clnBgn) - 1, 1, 1)
			}
			if (length(int_clnEnd) != 1) {
				#100. Seek help from the input values
				int_clnEnd <- int_obs[!is.na(int_obs)]

				#500. Set it when the input values can neither help
				if (length(int_clnEnd) == 0) {
					int_clnEnd <- lubridate::today()
				} else {
					int_clnEnd <- max(int_clnEnd, na.rm = T)
				}

				#900. Set it to the end of its next year, which is earlier than that all existing methods can calculate
				int_clnEnd <- lubridate::make_date(lubridate::year(int_clnEnd) + 1, 12, 31)
			}

			#500. Instantiate parent class
			#[For methods/variables (i.e. members) set in parent class]
			#[1] After the instantiation of parent class, all its [private] members will have been localized
			#[2] We have to use [private$] syntax for referencing the [private] members in parent class
			#[3] We have to use [super$] syntax for referencing the [public] and [active] members in parent class
			#[For members set in current class]
			#[1] We have to use [self$] syntax for referencing the [public] and [active] members in current class
			super$initialize(
				clnBgn = int_clnBgn
				,clnEnd = int_clnEnd
				,countrycode = countrycode
				,CalendarAdj = CalendarAdj
				,fmtDateIn = fmtDateIn
				,fmtDateOut = fmtDateOut
				,DateOutAsStr = DateOutAsStr
			)

			#700. Verify the input values
			self$values <- obsDate

			#800. Create the user calendar, for it contains more columns that are required for calculation in this class
			private$.uniclndr <- private$.subCalendar(datebgn = super$clnBgn, dateend = super$clnEnd)
		}
		,shiftDays = function(
			obsDate = private$.obs_df
			,kshift = 0
			,preserve = T
			,daytype = c('W','T')
		){
			#001. Handle parameters
			if (length(kshift)==0) kshift <- 0
			if (!is.numeric(kshift)) stop('[',private$classname,'][kshift=',kshift,'] must be provided a number!')
			if (length(kshift)>1) {
				warning('[',private$classname,']Multiple values provided for [kshift], only the first one is used.')
				kshift <- head(kshift, 1)
			}
			if (length(preserve)==0) preserve <- T
			if (!is.logical(preserve)) stop('[',private$classname,'][preserve=',preserve,'] must be provided a logical value [T/F]!')
			if (length(preserve)>1) {
				warning('[',private$classname,']Multiple values provided for [preserve], only the first one is used.')
				preserve <- head(preserve, 1)
			}
			daytype <- match.arg.x(daytype, arg.func = toupper)

			#100. Local variables
			#We set the actual shift days as [-1] if [kshift] is not provided or provided as [0]
			kdays <- ifelse(!kshift,-1,kshift)
			shift_func <- eval( parse( text = paste0('dplyr::', ifelse(kdays>0,'lead','lag')) ) )
			fill_method <- ifelse(kdays>0,'down','up')
			col_filter <- list('W' = 'F_WORKDAY', 'T' = 'F_TradeDay')
			DateFlag <- unname(col_filter[[daytype]])

			#200. Prepare the calendar with the least requested columns and set the correct index
			cal_shift <- private$.uniclndr %>% dplyr::select('D_DATE', tidyselect::all_of(DateFlag))

			#300. Prepare the shifted days by requested type
			df_shift <- cal_shift %>%
				dplyr::filter_at(DateFlag, ~.) %>%
				dplyr::select(D_DATE) %>%
				#No worry for value of [kdays==0] as it has been handled above.
				dplyr::mutate( shiftedday = shift_func(D_DATE, abs(kdays)) )

			#500. Match the shifted days to the observed dates
			df_out <- cal_shift %>%
				dplyr::left_join(df_shift, by = 'D_DATE') %>%
				dplyr::arrange(D_DATE) %>%
				tidyr::fill(shiftedday, .direction = fill_method) %>%
				dplyr::right_join(obsDate, by = 'D_DATE') %>%
				dplyr::mutate_at(DateFlag, ~ifelse(is.na(.), F, .)) %>%
				#Keep the sequence of the output values the same as the input ones
				dplyr::arrange_at('.obsKey.')

			#700. Create the shifted days and pull the result for output
			#710. Create a mask on the input data which indicates the records to be shifted or not
			mask_indate <- !( df_out[[DateFlag]] & preserve )

			#750. Shift the values of [D_DATE] where applicable
			#We conduct such calculation to retain the [class] of [D_DATE], in comparison to using [dplyr::mutate]
			df_out[mask_indate, 'D_DATE'] <- df_out[mask_indate, 'shiftedday']

			#800. Convert the date values into strings as per request
			if (super$DateOutAsStr) {
				df_out[['D_DATE']] <- df_out[['D_DATE']] %>% strftime(super$fmtDateOut) %>% dplyr::coalesce('')
			}

			#999. Return the values
			return(private$.rst(df_out, 'D_DATE'))
		}
	)
	,private = list(
		.uniclndr = NULL
		,.obs_df = NULL
		,.values_shp. = NULL
		,.values_df. = FALSE
		,.values_col. = NULL
		#100. Prepare helper functions
		#110. Prepare the helper function to return proper results
		,.rst = function(df, col){
			#100. Differentiate the scenarios
			if (private$.values_df.) {
				#100. Retrieve the data
				if (private$.values_shp.[[length(private$.values_shp.)]] == 1) {
					rstOut <- df %>% dplyr::select(col)
				} else {
					#100. Unstack the data
					rstOut <- df %>%
						dplyr::select('.obsKRow.', '.obsKCol.', tidyselect::all_of(col)) %>%
						tidyr::pivot_wider(
							id_cols = tidyselect::all_of('.obsKRow.')
							,names_from = tidyselect::all_of('.obsKCol.')
							,values_from = tidyselect::all_of(col)
							,values_fill = NA
						) %>%
						dplyr::select(-tidyselect::all_of('.obsKRow.')) %>%
						as.data.frame()
				}

				#300. Set the column names to the same as the input
				colnames(rstOut) <- private$.values_col.
			} else {
				#500. Prepare a vector as output
				rstOut <- df %>% dplyr::pull(tidyselect::all_of(col))
			}

			#999. Return the result
			return(rstOut)
		}
		#130. Function to transform the input values
		,.obsDate.T = function(udate){
			if (isDF(udate)) {
				#100. Convert the input
				tmpdate <- udate %>% asDates(super$fmtDateIn)

				#500. Add necessary columns
				if (ncol(udate) == 1) {
					colnames(tmpdate) <- 'D_DATE'
					tmpdate[['.obsKCol.']] <- 0
					tmpdate[['.obsKRow.']] <- seq_len(nrow(udate))
					tmpdate[['.obsKey.']] <- seq_len(nrow(udate))
				} else {
					tmpdate %<>%
						tidyr::pivot_longer(tidyselect::all_of(colnames(udate)), names_to = '.name.', values_to = 'D_DATE') %>%
						dplyr::mutate(
							'.obsKCol.' = rep.int(seq_len(ncol(udate)), nrow(udate))
							,'.obsKRow.' = do.call(c, sapply(seq_len(nrow(udate)), rep.int, ncol(udate), simplify = F))
							,'.obsKey.' = dplyr::row_number()
						) %>%
						dplyr::select(-'.name.')
				}
			} else {
				#500. Convert it into the requested value
				tmpsrs <- udate %>% asDates(super$fmtDateIn)

				#900. Standardize the internal data frame
				tmpdate <- data.frame(D_DATE = tmpsrs)
				tmpdate[['.obsKCol.']] <- 0
				tmpdate[['.obsKRow.']] <- seq_len(length(tmpsrs))
				tmpdate[['.obsKey.']] <- seq_len(length(tmpsrs))
			}

			#999. Return the result
			return(tmpdate)
		}
		#220. Method to verify whether the observing dates are at the lower/upper bound of the certain period
		,.isBoundOfPeriod = function(
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
			cal_bound <- private$.uniclndr %>%
				dplyr::filter_at(col_filter[[daytype]], ~.) %>%
				dplyr::select('D_DATE', tidyselect::all_of(wk_filter[[daytype]]))

			#500. Conduct different filtration as per request
			if (.period=='MONTH') cal_bound %<>% dplyr::mutate(C_PRD = strftime(D_DATE, '%Y%m'))
			else if (.period=='QUARTER') cal_bound %<>% dplyr::mutate(C_PRD = paste0(lubridate::year(D_DATE),'Q',Qtr))
			else if (.period=='WEEK') names(cal_bound)[[match(wk_filter[[daytype]],names(cal_bound))]] <- 'C_PRD'
			else if (.period=='YEAR') cal_bound %<>% dplyr::mutate(C_PRD = lubridate::year(D_DATE))
			else stop('[',private$classname,'][.period=',.period,'] is not defined!')

			#700. Filter the result
			df_out <- cal_bound %>%
				dplyr::group_by(C_PRD) %>%
				dplyr::arrange(D_DATE) %>%
				func_bound() %>%
				dplyr::ungroup() %>%
				dplyr::right_join(private$.obs_df, by = 'D_DATE') %>%
				dplyr::arrange_at('.obsKey.') %>%
				dplyr::mutate('.flag.' = ifelse(is.na(C_PRD), F, T))

			#999. Return the result
			return(private$.rst(df_out, '.flag.'))
		}
	)
	,active = list(
		#100. Output the parameters.
		params = function(){
			#Neglect the user calendar, while use the universal calendar
			cat(paste('Beginning of the Universal Calendar:',paste0('[',super$clnBgn,']\n')))
			cat(paste('Ending of the Universal Calendar:',paste0('[',super$clnEnd,']\n')))
			cat(paste('Observing dates (first 5 ones at most):'))
			if (private$.values_df.) dplyr::glimpse(self$values)
			else cat(paste0('[',paste0(head(self$values), collapse = ']['),']'))
			cat(paste('Country Code:',paste0('[',super$country,']\n')))
			cat(paste('Calendar Adjustment:',paste0('[',super$clnAdj,']\n')))
			cat(paste('How to input the strings into dates:',paste0('[',paste0(super$fmtDateIn, collapse = ']['),']\n')))
			cat(paste('How to display the results as formatted in string:',paste0('[',super$fmtDateOut,']\n')))
			cat(paste('# of days to extend the calculation before beginning and after ending:',paste0('[',super$datespan,']\n')))
		}
		,values = function(udate){
			#001. Return the value as requested
			if (missing(udate)) return(private$.rst(private$.obs_df, 'D_DATE'))

			#100. Reset it to [today] if it is provided but with no value
			if (length(udate)==0) {
				warning('[',private$classname,']No value is provided for [Observing Dates], reset it to today.')
				udate <- lubridate::today()
			}

			#300. Translate the input values if any
			tmpdate <- private$.obsDate.T(udate)

			#500. Detect all values that exceed the boundaries of the universal calendar
			mask_date <- (tmpdate[['D_DATE']] < super$clnBgn) | (tmpdate[['D_DATE']] > super$clnEnd)
			mask_date %<>% dplyr::coalesce(F)
			tmpdate[mask_date, 'D_DATE'] <- NA

			#990. Update the environment as per request
			#910. Retrieve the attribute of the input
			private$.values_df. <- isDF(udate)
			if (private$.values_df.) {
				private$.values_col. <- colnames(udate)
				private$.values_shp. <- dim(udate)
			}

			#995. Refresh the data frame with the [obsDate] for calculation
			private$.obs_df <- tmpdate
		}

		#Read-only properties
		,isWorkDay = function(){
			df_out <- private$.uniclndr %>%
				dplyr::select('D_DATE', 'F_WORKDAY') %>%
				dplyr::right_join(private$.obs_df, by = 'D_DATE') %>%
				dplyr::arrange_at('.obsKey.')
			df_out[['F_WORKDAY']] <- df_out[['F_WORKDAY']] %>% dplyr::coalesce(F)
			return(private$.rst(df_out, 'F_WORKDAY'))
		}
		,isFirstWDofMon = function(){
			private$.isBoundOfPeriod( daytype = 'w', .bound = 'h', .period = 'm' )
		}
		,isLastWDofMon = function(){
			private$.isBoundOfPeriod( daytype = 'w', .bound = 't', .period = 'm' )
		}
		,isFirstWDofQtr = function(){
			private$.isBoundOfPeriod( daytype = 'w', .bound = 'h', .period = 'q' )
		}
		,isLastWDofQtr = function(){
			private$.isBoundOfPeriod( daytype = 'w', .bound = 't', .period = 'q' )
		}
		,isFirstWDofWeek = function(){
			private$.isBoundOfPeriod( daytype = 'w', .bound = 'h', .period = 'w' )
		}
		,isLastWDofWeek = function(){
			private$.isBoundOfPeriod( daytype = 'w', .bound = 't', .period = 'w' )
		}
		,isFirstWDofYear = function(){
			private$.isBoundOfPeriod( daytype = 'w', .bound = 'h', .period = 'y' )
		}
		,isLastWDofYear = function(){
			private$.isBoundOfPeriod( daytype = 'w', .bound = 't', .period = 'y' )
		}

		,isTradeDay = function(){
			df_out <- private$.uniclndr %>%
				dplyr::select('D_DATE', 'F_TradeDay') %>%
				dplyr::right_join(private$.obs_df, by = 'D_DATE') %>%
				dplyr::arrange_at('.obsKey.')
			df_out[['F_TradeDay']] <- df_out[['F_TradeDay']] %>% dplyr::coalesce(F)
			return(private$.rst(df_out, 'F_TradeDay'))
		}
		,isFirstTDofMon = function(){
			private$.isBoundOfPeriod( daytype = 't', .bound = 'h', .period = 'm' )
		}
		,isLastTDofMon = function(){
			private$.isBoundOfPeriod( daytype = 't', .bound = 't', .period = 'm' )
		}
		,isFirstTDofQtr = function(){
			private$.isBoundOfPeriod( daytype = 't', .bound = 'h', .period = 'q' )
		}
		,isLastTDofQtr = function(){
			private$.isBoundOfPeriod( daytype = 't', .bound = 't', .period = 'q' )
		}
		,isFirstTDofWeek = function(){
			private$.isBoundOfPeriod( daytype = 't', .bound = 'h', .period = 'w' )
		}
		,isLastTDofWeek = function(){
			private$.isBoundOfPeriod( daytype = 't', .bound = 't', .period = 'w' )
		}
		,isFirstTDofYear = function(){
			private$.isBoundOfPeriod( daytype = 't', .bound = 'h', .period = 'y' )
		}
		,isLastTDofYear = function(){
			private$.isBoundOfPeriod( daytype = 't', .bound = 't', .period = 'y' )
		}

		,prevYearLCD = function(){
			#100. Identify the first calendar dates of the years of current dates
			df_out <- private$.obs_df %>%
				dplyr::mutate('D_DATE' = lubridate::make_date(lubridate::year(D_DATE), 1, 1) %>% lubridate::rollback())

			#500. Format as string when required
			if (super$DateOutAsStr) {
				df_out[['D_DATE']] <- df_out[['D_DATE']] %>% strftime(super$fmtDateOut) %>% dplyr::coalesce('')
			}

			#999. Return values
			return(private$.rst(df_out, 'D_DATE'))
		}
		,prevYearLWD = function(){
			#100. Identify the first calendar dates of the years of current dates
			l_df <- private$.obs_df %>%
				dplyr::mutate('D_DATE' = lubridate::make_date(lubridate::year(D_DATE), 1, 1))

			#999. Return the Previous Workdays of above dates
			return( self$shiftDays( kshift = -1, preserve = F, daytype = 'w', obsDate = l_df ) )
		}
		,prevYearLTD = function(){
			#100. Identify the first calendar dates of the years of current dates
			l_df <- private$.obs_df %>%
				dplyr::mutate('D_DATE' = lubridate::make_date(lubridate::year(D_DATE), 1, 1))

			#999. Return the Previous Tradedays of above dates
			return( self$shiftDays( kshift = -1, preserve = F, daytype = 't', obsDate = l_df ) )
		}

		,prevQtrLCD = function(){
			#100. Find the first month of current quarter
			df_out <- private$.obs_df %>%
				dplyr::mutate(
					'D_DATE' = lubridate::make_date(
						lubridate::year(D_DATE)
						,(lubridate::month(D_DATE) - 1) %/% 3 * 3 + 1
						,1
					) %>%
						lubridate::rollback()
				)

			#500. Format as string when required
			if (super$DateOutAsStr) {
				df_out[['D_DATE']] <- df_out[['D_DATE']] %>% strftime(super$fmtDateOut) %>% dplyr::coalesce('')
			}

			#999. Return values
			return(private$.rst(df_out, 'D_DATE'))
		}
		,prevQtrLWD = function(){
			#100. Find the first month of current quarter
			l_df <- private$.obs_df %>%
				dplyr::mutate(
					'D_DATE' = lubridate::make_date(
						lubridate::year(D_DATE)
						,(lubridate::month(D_DATE) - 1) %/% 3 * 3 + 1
						,1
					)
				)

			#999. Return the Previous Workdays of above dates
			return( self$shiftDays( kshift = -1, preserve = F, daytype = 'w', obsDate = l_df ) )
		}
		,prevQtrLTD = function(){
			#100. Find the first month of current quarter
			l_df <- private$.obs_df %>%
				dplyr::mutate(
					'D_DATE' = lubridate::make_date(
						lubridate::year(D_DATE)
						,(lubridate::month(D_DATE) - 1) %/% 3 * 3 + 1
						,1
					)
				)

			#999. Return the Previous Tradedays of above dates
			return( self$shiftDays( kshift = -1, preserve = F, daytype = 't', obsDate = l_df ) )
		}

		,prevMon = function(){
			df_out <- private$.obs_df
			df_out[['D_DATE']] <- df_out[['D_DATE']] %>% lubridate::rollback() %>% strftime('%Y%m') %>% dplyr::coalesce('')
			return(private$.rst(df_out, 'D_DATE'))
		}
		,prevMonLCD = function(){
			#500. Retrieve the Last Calendar Days of the previous months to current ones respectively
			df_out <- private$.obs_df
			df_out[['D_DATE']] <- df_out[['D_DATE']] %>% lubridate::rollback()

			#890. Convert the date values into strings as per request
			if (super$DateOutAsStr) {
				df_out[['D_DATE']] <- df_out[['D_DATE']] %>% strftime(super$fmtDateOut) %>% dplyr::coalesce('')
			}

			#999. Return values
			return(private$.rst(df_out, 'D_DATE'))
		}
		,prevMonLWD = function(){
			#100. Retrieve the Month Beginning of the [obsDate]
			l_df <- private$.obs_df
			l_df[['D_DATE']] <- l_df[['D_DATE']] %>% lubridate::rollback(roll_to_first = T)

			#999. Return the Previous Workday of above dates
			return( self$shiftDays( kshift = -1, preserve = F, daytype = 'w', obsDate = l_df ) )
		}
		,prevMonLTD = function(){
			#100. Retrieve the Month Beginning of the [obsDate]
			l_df <- private$.obs_df
			l_df[['D_DATE']] <- l_df[['D_DATE']] %>% lubridate::rollback(roll_to_first = T)

			#999. Return the Previous Tradeday of above dates
			return( self$shiftDays( kshift = -1, preserve = F, daytype = 't', obsDate = l_df ) )
		}

		,prevWorkDay = function(){
			self$shiftDays( kshift = -1, preserve = F, daytype = 'w' )
		}
		,prevWorkDay2 = function(){
			self$shiftDays( kshift = -2, preserve = F, daytype = 'w' )
		}
		,prevMonToPWD = function(){
			#100. Store the current parameters
			int_flag <- super$DateOutAsStr
			int_value <- self$values

			#300. Find the previous work days to current dates
			super$DateOutAsStr <- F
			self$values <- self$prevWorkDay

			#500. Find the Previous Months to above dates
			super$DateOutAsStr <- int_flag
			valout <- self$prevMon

			#700. Restore the parameters
			self$values <- int_value

			#999. Return the values
			return(valout)
		}
		,prevMonLCDToPWD = function(){
			#100. Store the current parameters
			int_flag <- super$DateOutAsStr
			int_value <- self$values

			#300. Find the previous work days to current dates
			super$DateOutAsStr <- F
			self$values <- self$prevWorkDay

			#500. Find the Last Calendar Days of the Previous Months to above dates
			super$DateOutAsStr <- int_flag
			valout <- self$prevMonLCD

			#700. Restore the parameters
			self$values <- int_value

			#999. Return the values
			return(valout)
		}
		,prevMonLWDToPWD = function(){
			#100. Store the current parameters
			int_flag <- super$DateOutAsStr
			int_value <- self$values

			#300. Find the previous work days to current dates
			super$DateOutAsStr <- F
			self$values <- self$prevWorkDay

			#500. Find the Last Work Days of the Previous Months to above dates
			super$DateOutAsStr <- int_flag
			valout <- self$prevMonLWD

			#700. Restore the parameters
			self$values <- int_value

			#999. Return the values
			return(valout)
		}
		,nextWorkDay = function(){
			self$shiftDays( kshift = 1, preserve = F, daytype = 'w' )
		}

		,prevTradeDay = function(){
			self$shiftDays( kshift = -1, preserve = F, daytype = 't' )
		}
		,prevTradeDay2 = function(){
			self$shiftDays( kshift = -2, preserve = F, daytype = 't' )
		}
		,prevMonToPTD = function(){
			#100. Store the current parameters
			int_flag <- super$DateOutAsStr
			int_value <- self$values

			#300. Find the previous trade days to current dates
			super$DateOutAsStr <- F
			self$values <- self$prevTradeDay

			#500. Find the Previous Months to above dates
			super$DateOutAsStr <- int_flag
			valout <- self$prevMon

			#700. Restore the parameters
			self$values <- int_value

			#999. Return the values
			return(valout)
		}
		,prevMonLCDToPTD = function(){
			#100. Store the current parameters
			int_flag <- super$DateOutAsStr
			int_value <- self$values

			#300. Find the previous trade days to current dates
			super$DateOutAsStr <- F
			self$values <- self$prevTradeDay

			#500. Find the Previous Months to above dates
			super$DateOutAsStr <- int_flag
			valout <- self$prevMonLCD

			#700. Restore the parameters
			self$values <- int_value

			#999. Return the values
			return(valout)
		}
		,prevMonLTDToPTD = function(){
			#100. Store the current parameters
			int_flag <- super$DateOutAsStr
			int_value <- self$values

			#300. Find the previous trade days to current dates
			super$DateOutAsStr <- F
			self$values <- self$prevTradeDay

			#500. Find the Previous Months to above dates
			super$DateOutAsStr <- int_flag
			valout <- self$prevMonLTD

			#700. Restore the parameters
			self$values <- int_value

			#999. Return the values
			return(valout)
		}
		,nextTradeDay = function(){
			self$shiftDays( kshift = 1, preserve = F, daytype = 't' )
		}
	)
)

#-Notes- -Begin-
#Full Test Program[1]:
if (FALSE){
	if (T){
		#001. Establish environment
		#Below program provides the most initial environment and system options for best usage of [omniR]
		source('D:\\R\\autoexec.r')

		#100. Setup the Calendar.
		thisday <- ObsDates$new()
		# Check parameters.
		thisday$params
		#Assign special dates for calculation (Note the sequence of the dates)
		thisday$values <- c('20210214', NA, '20210221')
		# Check parameters again.
		thisday$params

		#100. Apply public function for customized shift
		thisday$DateOutAsStr <- T
		ttt <- thisday$shiftDays( kshift = -1, preserve = T, daytype = 'W' )
		thisday$DateOutAsStr <- F

		#200. Retrieve the active-binding methods for the above dates
		#Last Tradeday of the Previous Month to the Previous Tradeday of the input dates
		View(thisday$prevMonLTDToPTD)

		#300. Provide a data frame as input values
		dt_df <- data.frame(
			a = asDates(c('20190412', NA, '20200925'))
			,b = asDates(c('20181122', '20200214', NA))
		)
		thisday <- ObsDates$new(obsDate = dt_df)
		View(thisday$values)
		thisday$isWorkDay
		thisday$prevMonLCDToPWD
	}
}
#-Notes- -End-
