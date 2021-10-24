#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to convert any type of input values into valid time (with class as [Period], see [lubridate])            #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |indate      :   Date-like values, can be list/vector of date values, character strings, integers or date column of a data frame    #
#   |fmt         :   Alternative format to be passed to function [strptime] when the input is a character string                        #
#   |                 [ <vec>      ] <Default> Try to match these formats for any input strings, see function definition                #
#   |origin      :   Datetime-like scalar, as origin, to convert the values in the class of [POSIXct]                                   #
#   |                See official document of [lubridate::make_datetime]                                                                #
#   |                 [ 1960-01-01 ] <Default> Also the default origin of SAS for easy conversion                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[ vec   ]   :   The mapped result stored in a vector (or data.frame if the input is table-like)                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210831        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210903        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Now conduct calculation for most of the internal types at vector level, to reduce the time elapse by 99%                #
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
#   |   |lubridate, rlang, vctrs, magrittr                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvOp                                                                                                                    #
#   |   |   |isDF                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	lubridate, rlang, vctrs, magrittr
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

asTimes <- function(
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
		,c('%H%M%S', '%H-%M-%S', '%H:%M:%S', '%H %M %S')
	)
	,origin = lubridate::make_datetime(1960,1,1,0,0,0,tz = Sys.getenv('TZ'))
){
	#010. Parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
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
		,c('%H%M%S', '%H-%M-%S', '%H:%M:%S', '%H %M %S')
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
		rst <- data.frame(lapply(indate, asTimes, fmt = fmt, origin = origin))
		rownames(rst) <- rownames(indate)
		return(rst)
	}

	#199. Return a placeholder if the length of input is zero
	#This step should be after the verification of table-like input, as there could be data.frame with 0 column as input,
	# while [length()] function returns its number of columns which is just 0
	if (length(indate) == 0) return(
		lubridate::seconds(numeric(0))
	)

	#300. Create helper functions
	#310. Function to create [Period] out of [hour], [minute] and [second] from [POSIXt]
	h_cr_hms <- function(d){
		lubridate::hours(lubridate::hour(d)) +
		lubridate::minutes(lubridate::minute(d)) +
		lubridate::seconds(lubridate::second(d))
	}

	#330. Function to handle [Period] directly
	h_prd <- function(d){
		#100. Remove the [day], [month] and [year] parts of the [Period] to extract the time part
		#[week] part is converted to [day], hence there is no need to remove [week] part of the input value
		#20211010 It is tested that we have to use the statement [1] for assignment instead of statement [2]
		#[1] lubridate::day(rstOut) <- rep_along(d, 0)
		#[2] lubridate::day(rstOut) <- 0
		#IMPORTANT:
		#[1] [Period] is a special class creating dynamic objects during execution
		#[2] To check the essentials of [Period] class, we can execute: message(prd)
		#[3] Above statement [#2] will provide the [Period] a [day] with value [c(0)] instead of c[(0,0,...)]
		#[4] Due to above reason, when [Period] created by statement [#2] is stored in a column of a data.frame,
		#     all cells except the first one will have the values of [NA]
		rstOut <- d
		lubridate::day(rstOut) <- rlang::rep_along(d, 0)
		lubridate::month(rstOut) <- rlang::rep_along(d, 0)
		lubridate::year(rstOut) <- rlang::rep_along(d, 0)

		#999. Return the result
		return(rstOut)
	}

	#390. Function for the calculation over single element among the input
	h_conv <- function(d){
		cls_obj <- class(d)
		if(any(cls_obj %in% c('character'))) {
			#Quote [#4]: https://stackoverflow.com/questions/59254390
			h_cr_hms(lubridate::parse_date_time(d, orders = fmt, tz = Sys.getenv('TZ'), quiet = T))
		}
		else if(any(cls_obj %in% c('numeric'))) {
			d_dt <- as.POSIXct(d, tz = Sys.getenv('TZ'), origin = origin)
			return(h_cr_hms(d_dt))
		}
		else if(any(cls_obj %in% c('Date'))) {
			lubridate::seconds(rlang::rep_along(d, 0))
		}
		else if(any(cls_obj %in% c('POSIXct', 'POSIXlt', 'POSIXt'))){
			h_cr_hms(d)
		}
		else if(any(cls_obj %in% c('Period'))){
			h_prd(d)
		}
		else if(any(cls_obj %in% c('hms'))){
			lubridate::as.period(d)
		}
		else
			rlang::rep_along(d, NA)
	}

	#400. Directly convert a vector in class of [Period] as [sapply] will remove its class at later steps
	if (any(class(indate) %in% 'Period')) return(h_prd(indate))

	#500. Direct calculation if the input is a plain vector, i.e. the internal types, see [typeof]
	#This is to reduce the calculation time elapse by 99%
	vec_internal <- c('logical','integer','double','complex','character','raw')
	type_indate <- typeof(indate)
	if (type_indate %in% vec_internal) return(h_conv(indate))

	#700. Try to convert all elements from the input values, one by one
	date_conv <- sapply(
		indate
		,h_conv
		,simplify = F
		,USE.NAMES = F
	)

	#900. Generate the results
	#999. The most common output
	#[1] We cannot use [unlist] to flatten it as its values may be of some [list-like] classes, which will be
	#     [unlist]ed in addition even when [recursive = FALSE]. Tested on [R 4.0.2]
	return(do.call(c, date_conv))
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#100. Convert a time
		a1 <- lubridate::hms('08:02:03', '18:22:33')
		a1_rst <- asTimes( a1 )

		#200. Convert a datetime
		a2 <- lubridate::now()
		a2_rst <- asTimes( a2 )

		#300. Convert a string
		a3 <- c('12:34:56','03-14-39')
		a3_rst <- asTimes( a3 )

		#400. Convert a list of dates
		a4 <- list(a3 , a2)
		a4_rst <- asTimes( a4 )

		#600. Test if the input has 0 length
		asTimes( character(0) )
		asTimes( NULL )

		#610. Test invalid input
		asTimes( c('aa',a3,'bb',strftime(lubridate::now(),'%Y-%m-%d %H%M%S')) )

		#700. Convert the raw values into dates from SAS dataset
		CFG_KPI <- haven::read_sas(file.path('D:','R','omniR','AdvDB','test_loadsasdat.sas7bdat'), encoding = 'GB2312')
		CFG_KPI[['DT_TEST2']] <- asTimes( CFG_KPI[['DT_TEST']] )
		View(CFG_KPI)
		str(CFG_KPI)

		#750. Convert a data.frame
		df_test <- CFG_KPI %>% dplyr::select(c('DT_TEST', 'T_TEST'))
		df_out <- asTimes(df_test)
		str(df_out)
		View(df_out)

		#800. Convert an integer into date, as it represents a [Time: 10:10:10] in SAS
		a5 <- 36610
		a5_rst <- asTimes( a5 )

		#900. Test timing
		df_smpl <- CFG_KPI %>% dplyr::slice_sample(n = 100000, replace = T)
		t1 <- lubridate::now()
		df_timing <- df_smpl %>% dplyr::select(c('DT_TEST', 'T_TEST')) %>% asTimes()
		t2 <- lubridate::now()
		print(t2 - t1)
		#0.31s
		View(df_timing)
	}
}
