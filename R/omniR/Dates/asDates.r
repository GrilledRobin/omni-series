#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to convert any type of input values into valid dates (with class [Date])                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |indate      :   Date-like values, can be list/vector of date values, character strings, integers or data.frame                     #
#   |fmt         :   Alternative format to be passed to function [as.Date] when the input is a character string                         #
#   |                 [ <vec>      ] <Default> Try to match these formats for any input strings, see function definition                #
#   |origin      :   Date-like scalar, as origin, to convert the values in the class of [Date]                                          #
#   |                See official document of [lubridate::make_date]                                                                    #
#   |                 [ 1960-01-01 ] <Default> Also the default origin of SAS for easy conversion                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[ vec   ]   :   The mapped result stored in a vector (or data.frame if the input is table-like)                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210104        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210831        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Remove the arguments [...] as all the dedicated arguments for [sapply] are now specified                                #
#   |      |[2] Introduce a new argument [origin] in order to convert [numeric] values by a given origin                                #
#   |      |[3] Now accepts a single table-like input, such as [data.frame], and return a [data.frame] in the same shape                #
#   |      |[4] Return a placeholder [Date(0)] given the input has zero length                                                          #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210903        | Version | 2.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Now conduct calculation for most of the internal types at vector level, to reduce the time elapse by 99%                #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230617        | Version | 2.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduced function <isVEC> to generalize the process                                                                   #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230815        | Version | 2.30        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce the imitated <recall> to make the recursion more intuitive                                                    #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230821        | Version | 2.40        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <sys.function> to complement the base <Recall> under certain circumstances                                    #
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
#   |   |lubridate, rlang, vctrs                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvOp                                                                                                                    #
#   |   |   |isDF                                                                                                                       #
#   |   |   |isVEC                                                                                                                      #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	lubridate, rlang, vctrs
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

asDates <- function(
	indate
	,fmt = c(
		do.call(
			paste0
			,expand.grid(
				c('%Y%m%d', '%Y-%m-%d', '%Y/%m/%d')
				,c(':', ' ', '-')
				,c('%H%M%S', '%H-%M-%S', '%H:%M:%S', '%H %M %S')
			)
		)
		#The order of such formats are taken for granted
		,c('%Y%m%d', '%Y-%m-%d', '%Y/%m/%d')
	)
	,origin = lubridate::make_date(1960,1,1)
){
	#010. Parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	recall <- sys.function()
	if(length(fmt)==0) fmt <- c(
		do.call(
			paste0
			,expand.grid(
				c('%Y%m%d', '%Y-%m-%d', '%Y/%m/%d')
				,c(':', ' ', '-')
				,c('%H%M%S', '%H-%M-%S', '%H:%M:%S', '%H %M %S')
			)
		)
		#The order of such formats are taken for granted
		,c('%Y%m%d', '%Y-%m-%d', '%Y/%m/%d')
	)
	#[Quote: https://www.r-bloggers.com/doing-away-with-%e2%80%9cunknown-timezone%e2%80%9d-warnings/ ]
	#[Quote: Search for the TZ value in the file: [<R Installation>/share/zoneinfo/zone.tab]]
	if (nchar(Sys.getenv('TZ')) == 0) Sys.setenv(TZ = 'Asia/Shanghai')
	is_flattenable <- function(x) vctrs::vec_is_list(x) && !rlang::is_named(x)

	#100. Separately calculate on a table-like input by calling the same function in recursion
	if (!is_flattenable(indate)) if (isDF(indate)) {
		if (ncol(indate) == 0) {
			return(indate)
		}
		rst <- data.frame(lapply(indate, recall, fmt = fmt, origin = origin))
		rownames(rst) <- rownames(indate)
		return(rst)
	}

	#199. Return a placeholder if the length of input is zero
	#This step should be after the verification of table-like input, as there could be data.frame with 0 column as input,
	# while [length()] function returns its number of columns which is just 0
	if (length(indate) == 0) return(
		as.Date(lubridate::make_date(double(0),double(0),double(0)))
	)

	#300. Create helper function for the calculation over single element among the input
	h_conv <- function(d){
		cls_obj <- class(d)
		if(any(cls_obj %in% c('character'))) {
			#Quote [#4]: https://stackoverflow.com/questions/59254390
			lubridate::date(lubridate::parse_date_time(d, orders = fmt, tz = Sys.getenv('TZ'), quiet = T))
		}
		else if(any(cls_obj %in% c('numeric', 'Date'))) {
			as.Date(d, origin = origin)
		}
		else if(any(cls_obj %in% c('POSIXct', 'POSIXlt', 'POSIXt'))){
			#[IMPORTANT] Normally below system option should be setup manually
			as.Date(d, tz = Sys.getenv('TZ'))
		}
		else
			rlang::rep_along(d, NA)
	}

	#500. Direct calculation if the input is a plain vector, i.e. the internal types, see [typeof]
	#This is to reduce the calculation time elapse by 99%
	if (isVEC(indate)) return(h_conv(indate))

	#700. Try to convert all elements from the input values, one by one
	#[IMPORTANT] Although we use [as.Date] to convert the values, the class of the result from [sapply] is still [numeric] instead of
	#             [Date], so we still need another round of conversion at below steps.
	#Function [sapply] generates a list when the input is a list and any among the results applied by the lambda function is multiple
	#Functions [sapply/lapply] remove the class [Date] from the output values
	date_conv <- sapply(
		indate
		,h_conv
		,simplify = F
		,USE.NAMES = F
	)

	#900. Generate the results
	return(do.call(c, date_conv))
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#100. Convert a date
		a1 <- lubridate::today()
		a1_rst <- asDates( a1 )

		#200. Convert a datetime
		a2 <- lubridate::now()
		a2_rst <- asDates( a2 )

		#300. Convert a string
		a3 <- c('2021-02-16','20210905')
		a3_rst <- asDates( a3 )

		#400. Convert a list of dates
		a4 <- list(a3 , a2)
		a4_rst <- asDates( a4 )

		#600. Test if the input has 0 length
		asDates( character(0) )
		asDates( NULL )

		#610. Test invalid input
		asDates( c('aa',a3,'bb',strftime(lubridate::today(),'%Y%m%d')) )

		#700. Convert the raw values into dates from SAS dataset
		CFG_KPI <- haven::read_sas(file.path('D:','R','omniR','AdvDB','test_loadsasdat.sas7bdat'), encoding = 'GB2312')
		CFG_KPI[['DT_TEST2']] <- asDates( CFG_KPI[['DT_TEST']] )
		View(CFG_KPI)
		str(CFG_KPI)

		#750. Convert a data.frame
		df_test <- CFG_KPI %>% dplyr::select(c('DT_TEST', 'D_TEST'))
		df_out <- asDates(df_test)
		str(df_out)
		View(df_out)

		#800. Convert an integer into date, as it represents a [Date: 2014-01-31] in SAS with the default origin as [1960-01-01]
		a5 <- 19754
		a5_rst <- asDates( a5 )

		#900. Test timing
		df_smpl <- CFG_KPI %>% dplyr::slice_sample(n = 100000, replace = T)
		t1 <- lubridate::now()
		df_timing <- df_smpl %>% dplyr::select(c('DT_TEST', 'D_TEST')) %>% asDates()
		t2 <- lubridate::now()
		print(t2 - t1)
		#0.06s
		View(df_timing)
	}
}
