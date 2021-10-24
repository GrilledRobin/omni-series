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
#   |   |   |[fmtDateIn    ]   :   Format of the [clnBgn] and [clnEnd] to be coerced to [Date] class                                    #
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
#   |   |[.weekdayname]                                                                                                                 #
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
#   |   |   |[ df          ]   :   Data.frame storing the mapping table of weekdays in different languages                              #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |[.crCalendar]                                                                                                                  #
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
#   |   |[.subCalendar]                                                                                                                 #
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
#   |   |   | clnBgn                      | <date> Beginning date of the universal calendar                                             #
#   |   |   | clnEnd                      | <date> Ending date of the universal calendar                                                #
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
#   |   |   |[<logical>    ]   :   The same values as the previous input by the user                                                    #
#   |   |   |---------------------------------------------------------------------------------------------------------------------------#
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210203        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210904        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce a separate function [getCalendarAdj] to search for the calendar adjustment in current environment             #
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |See the [Full Test Program] section                                                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |R6, magrittr, tmcn, lubridate, dplyr, readr, tidyr, tidyselect                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$Dates                                                                                                                    #
#   |   |   |getCalendarAdj                                                                                                             #
#   |   |   |asDates                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	R6, magrittr, tmcn, lubridate, dplyr, readr, tidyr, tidyselect
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

library(magrittr)

#005. Enable Chinese characters to be displayed properly.
tmcn::setchs(rev=F)

#010. Activate required packages before defining the function
if (!require(R6)) install.packages(R6)

#100. Prepare the Class containing core functions.
CoreUserCalendar <- R6::R6Class('CoreUserCalendar'
	,public = list(
		#Below link demonstrates the way to initialize an R6 Class together with its parent class generator
		#[Quote: https://stackoverflow.com/questions/35925664/change-initialize-method-in-subclass-of-an-r6-class ]
		#Below link demonstrates the way to find all ancestors of an R6 Class recursively
		#[Quote: https://stackoverflow.com/questions/37303552/r-r6-get-full-class-name-from-r6generator-object ]
		initialize = function(
			clnBgn = lubridate::today() - as.difftime(1825, units = 'days')
			,clnEnd = lubridate::today() + as.difftime(30, units = 'days')
			,countrycode = 'CN'
			,CalendarAdj = NULL
			,fmtDateIn = c('%Y%m%d', '%Y-%m-%d', '%Y/%m/%d')
			,fmtDateOut = '%Y%m%d'
			,DateOutAsStr = F
		){
			#001. Handle parameters
			#Back date 5 years as default
			if (length(clnBgn)==0) clnBgn <- lubridate::today() - as.difftime(1825, units = 'days')
			if (length(clnEnd)==0) clnEnd <- lubridate::today() + as.difftime(30, units = 'days')
			if (length(countrycode)==0) countrycode <- 'CN'
			if (length(fmtDateIn)==0) fmtDateIn <- c('%Y%m%d', '%Y-%m-%d', '%Y/%m/%d')
			if (length(fmtDateOut)==0) fmtDateOut <- '%Y%m%d'
			if (length(DateOutAsStr)==0) DateOutAsStr <- F
			if (!is.logical(DateOutAsStr)) DateOutAsStr <- F

			#100. Assign values to private environment
			#110. There is no method to assign values to below private variables for safety concern
			private$.clnBgn <- asDates(clnBgn, fmt = fmtDateIn)
			if (length(private$.clnBgn)>1) {
				warning('[',private$classname,']Multiple values provided for [Calendar Beginning], only the first one is used.')
				private$.clnBgn <- head(private$.clnBgn, 1)
			}
			private$.clnEnd <- asDates(clnEnd, fmt = fmtDateIn)
			if (length(private$.clnEnd)>1) {
				warning('[',private$classname,']Multiple values provided for [Calendar Ending], only the first one is used.')
				private$.clnEnd <- head(private$.clnEnd, 1)
			}
			if (private$.clnEnd < private$.clnBgn) {
				stop('[',private$classname,'][Calendar Ending] is earlier than [Calendar Beginning], Failed to instantiate!')
			}
			if (length(CalendarAdj) == 0) private$.clnAdj <- getCalendarAdj()
			else private$.clnAdj <- CalendarAdj
			private$.fmtDateOut <- fmtDateOut
			private$.OutAsStr <- DateOutAsStr

			#150. Call methods to assign values in a standard way
			self$country <- countrycode
			self$fmtDateIn <- fmtDateIn

			#500. Create the universal calendar
			private$.uniClndr <- private$.crCalendar()
		}
	)
	,private = list(
		.clnBgn = NULL
		,.clnEnd = NULL
		,.countrycode = NULL
		,.clnAdj = NULL
		,.fmtDateIn = NULL
		,.fmtDateOut = NULL
		,.OutAsStr = NULL
		,.datespan = as.difftime(30,units = 'days')
		,.uniClndr = NULL
		,.weekdayname = function(){
			v_cc <- rep('CN',7)
			v_wkday <- c(0:6)
			v_name <- c( '星期天' , '星期一' , '星期二' , '星期三' , '星期四' , '星期五' , '星期六' )
			df_wkday <- data.frame( C_COUNTRY = v_cc , K_WKDAY = v_wkday , C_DESC = v_name , stringsAsFactors = F )
			return(df_wkday)
		}
		,.crCalendar = function(
			datebgn = self$clnBgn
			,dateend = self$clnEnd
			,countrycode = self$country
			,CalendarAdj = self$clnAdj
			,infmt = self$fmtDateIn
		){
			#010. Set environment
			#[Quote: https://www.r-bloggers.com/doing-away-with-%e2%80%9cunknown-timezone%e2%80%9d-warnings/ ]
			#[Quote: Search for the TZ value in the file: [<R Installation>/share/zoneinfo/zone.tab]]
			if (nchar(Sys.getenv('TZ')) == 0) Sys.setenv(TZ = 'Asia/Shanghai')
			if (length(CalendarAdj)==0) {
				message('[',private$classname,']No adjustment is provided for holidays or workdays.')
			}
			if (length(countrycode)!=1 | nchar(head(countrycode, 1))==0) {
				stop('[',private$classname,']Country code is not provided! See documents for class instantiation!')
			}

			#100. Read necessary resources.
			if (length(CalendarAdj)>0) {
				shiftdata <- suppressMessages( readr::read_csv( CalendarAdj , locale = readr::locale(encoding = 'UTF-8') ) ) %>%
					#In case there are many file paths provided within one character vector, we bind the data together
					dplyr::bind_rows() %>%
					dplyr::filter(CountryCode == countrycode) %>%
					dplyr::select(-CountryCode) %>%
					dplyr::mutate(F_WORKDAY = F_WORKDAY == 1)
			} else {
				shiftdata <- NULL
			}
			wk_days <- private$.weekdayname() %>%
				dplyr::filter(C_COUNTRY == countrycode) %>%
				dplyr::select(-C_COUNTRY)

			#200. Create a calendar between (30 days before the [datebgn]) and (30 days after the [dateend]).
			clndrpre <- data.frame(D_DATE = seq.Date( datebgn - private$.datespan, dateend + private$.datespan, 1 )) %>%
				dplyr::mutate(K_WKDAY = as.integer(strftime(D_DATE,'%w'))) %>%
				dplyr::mutate(F_WEEKDAY = ifelse(K_WKDAY %in% c(1:5),TRUE,FALSE)) %>%
				dplyr::mutate(F_WORKDAY = F_WEEKDAY) %>%
				# dplyr::mutate( Qtr = plyr::round_any(as.integer(strftime(D_DATE, format = '%m')), 3, f = ceiling) %/% 3 ) %>%
				dplyr::mutate( Qtr = lubridate::quarter(D_DATE) ) %>%
				dplyr::left_join( wk_days, by = 'K_WKDAY' ) %>%
				dplyr::select(-K_WKDAY)

			#210. Load the adjustment of holidays/workdays if any
			if (!is.null(shiftdata)) {
				clndrpre <- clndrpre %>%
					dplyr::left_join( shiftdata , by = 'D_DATE' , suffix = c( '' , '.y' ) ) %>%
					dplyr::mutate(F_WORKDAY = ifelse(is.na(F_WORKDAY.y), F_WORKDAY, F_WORKDAY.y)) %>%
					dplyr::mutate(C_DESC = ifelse(is.na(C_DESC.y), C_DESC, C_DESC.y)) %>%
					dplyr::select(-tidyselect::ends_with('.y'))
			}

			#230. Identify the Trade days
			clndrpre <- clndrpre %>% dplyr::mutate(F_TradeDay = F_WEEKDAY & F_WORKDAY)

			#400. Only Retrieve all Work Days within above period
			tmp_workweek <- clndrpre %>% dplyr::select(D_DATE,F_WORKDAY) %>% dplyr::filter(F_WORKDAY) %>% dplyr::arrange(D_DATE) %>%
				dplyr::mutate(D_PrevWorkDay = dplyr::lag(D_DATE)) %>%
				dplyr::mutate(D_NextWorkDay = dplyr::lead(D_DATE)) %>%
				dplyr::select(-F_WORKDAY)

			#500. Only Retrieve all Trade Days within above period
			tmp_tradeweek <- clndrpre %>% dplyr::select(D_DATE,F_TradeDay) %>% dplyr::filter(F_TradeDay) %>% dplyr::arrange(D_DATE) %>%
				dplyr::mutate(D_PrevTradeDay = dplyr::lag(D_DATE)) %>%
				dplyr::mutate(D_NextTradeDay = dplyr::lead(D_DATE)) %>%
				dplyr::select(-F_TradeDay)

			#600. Append all necessary fields to the temporary Calendar Data.
			usrclndr <- clndrpre %>%
				dplyr::left_join(tmp_workweek,by = 'D_DATE') %>%
				dplyr::left_join(tmp_tradeweek,by = 'D_DATE') %>%
				tidyr::fill(D_PrevWorkDay,.direction = 'up') %>%
				tidyr::fill(D_PrevTradeDay,.direction = 'up') %>%
				tidyr::fill(D_NextWorkDay) %>%
				tidyr::fill(D_NextTradeDay) %>%
				# This step should be conducted at the last, for above steps would leverage the dates outside the provided date range.
				dplyr::filter(datebgn<=D_DATE,D_DATE<=dateend)

			#900. Output.
			return(usrclndr)
		}
		,.subCalendar = function(
			datebgn = self$clnBgn
			,dateend = self$clnEnd
			,inCln = self$uniCalendar
		){
			#010. Set environment

			#100. Extract the requested part of the universal calendar
			usrclndr <- inCln %>%
				#100. Only keep the requested part of the universal calendar
				dplyr::filter(datebgn<=D_DATE, D_DATE<=dateend) %>%
				dplyr::arrange(D_DATE) %>%
				#300. Define the Workweeks
				#If current date is more than 1 Calendar Day later than its previous Work Day,
				# we consider it as the first one in current block.
				#[IMPORTANT] There is no [NA] values for column [D_PrevWorkDay] in the universal calendar
				dplyr::mutate(
					FirstDay = ifelse(
						(is.na(dplyr::lag(D_DATE)) & F_WORKDAY) | (D_DATE - D_PrevWorkDay > as.difftime(1, units = 'days'))
						, F_WORKDAY
						, FALSE
					)
				) %>%
				# Calculate the cumulative sum of the flag created above to resemble the 'count of Work Weeks'.
				dplyr::mutate(K_WorkWeek = cumsum(FirstDay)) %>%
				#500. Define the Tradeweeks
				#If current date is more than 1 Calendar Day later than its previous Trade Day,
				# we consider it as the first one in current block.
				#[IMPORTANT] There is no [NA] values for column [D_PrevTradeDay] in the universal calendar
				dplyr::mutate(
					FirstDay = ifelse(
						(is.na(dplyr::lag(D_DATE)) & F_TradeDay) | (D_DATE - D_PrevTradeDay > as.difftime(1, units = 'days'))
						, F_TradeDay
						, FALSE
					)
				) %>%
				# Calculate the cumulative sum of the flag created above to resemble the 'count of Trade Weeks'.
				dplyr::mutate(K_TradeWeek = cumsum(FirstDay)) %>%
				dplyr::mutate(K_WorkWeek = ifelse(F_WORKDAY ,K_WorkWeek, 0)) %>%
				dplyr::mutate(K_TradeWeek = ifelse(F_TradeDay, K_TradeWeek, 0)) %>%
				dplyr::select(-FirstDay)

			#900. Output.
			return(usrclndr)
		}
	)
	,active = list(
		uniCalendar = function(){
			return(private$.uniClndr)
		}
		,clnAdj = function(){
			return(private$.clnAdj)
		}
		,clnBgn = function(){
			return(private$.clnBgn)
		}
		,clnEnd = function(){
			return(private$.clnEnd)
		}
		,fmtDateIn = function(fmt){
			#We allow multiple formats for input translation.
			if (missing(fmt)) return(private$.fmtDateIn)
			else private$.fmtDateIn <- fmt
		}
		,fmtDateOut = function(fmt){
			#001. Return the value as requested
			if (missing(fmt)) return(private$.fmtDateOut)

			#300. Translate the input values if any
			if (length(fmt)>1) {
				warning('[',private$classname,']Multiple formats set for [Date Value Output], only the first one is used.')
				fmt <- fmt[[1]]
			}

			#500. Assign values
			private$.fmtDateOut <- fmt

			#700. Set the conversion flag for output
			self$DateOutAsStr <- T
		}
		,datespan = function(tdelta){
			#001. Return the value as requested
			if (missing(tdelta)) return(private$.datespan)

			#300. Translate the input values if any
			if (length(tdelta)>1) {
				warning('[',private$classname,']Multiple values provided for [Date Span], only the first one is used.')
				tdelta <- head(tdelta, 1)
			}

			#999. Update the environment as per request
			private$.datespan <- tdelta
		}
		,country = function(cc){
			#001. Return the value as requested
			if (missing(cc)) return(private$.countrycode)

			#300. Translate the input values if any
			if (length(cc)>1) {
				warning('[',private$classname,']Multiple values provided for [Country], only the first one is used.')
				cc <- head(cc, 1)
			}

			#999. Update the environment as per request
			private$.countrycode <- toupper(trimws(cc))
		}
		,DateOutAsStr = function(flag){
			#001. Return the value as requested
			if (missing(flag)) return(private$.OutAsStr)

			#300. Translate the input values if any
			if (length(flag)==0) flag <- F
			if (!is.logical(flag)) flag <- F

			#999. Update the environment as per request
			private$.OutAsStr <- flag
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

		cln <- CoreUserCalendar$new()

		cln$fmtDateIn
		View(cln$uniCalendar)
	}
}
#-Notes- -End-
