#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to recognize the internal dtypes of the columns within the provided data frame, useful to convert R      #
#   | data frame to other storages via proper API                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inDF       :   Data frame to be inspected                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values.                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<chr>      :   Character vector that indicates the dtypes of each column in the data frame, choices are as below:                  #
#   |               [character   ] Character type of strings                                                                            #
#   |               [complex     ] Complex type                                                                                         #
#   |               [Date        ] Date type                                                                                            #
#   |               [datetime    ] Internal <POSIXct,POSIXt> type                                                                       #
#   |               [factor      ] Factor type                                                                                          #
#   |               [integer     ] Integer type                                                                                         #
#   |               [logical     ] Bool/logical type                                                                                    #
#   |               [numeric     ] Float type                                                                                           #
#   |               [raw         ] Raw type, displayed as hexadecimals                                                                  #
#   |               [time        ] Period type as indicated by package <lubridate>                                                      #
#   |               [unknown     ] Unrecognized types, e.g. <data.frame> stored in one column of another data frame                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20240212        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |glue                                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	glue
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

getDtypes <- function(
	inDF
){
	#010. Parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	if (!isDF(inDF)) {
		stop(glue::glue('[{LfuncName}]Type [{paste0(class(inDF), collapse = ",")}] of [inDF] is not recognized!'))
	}

	#015. Function local variables
	memclass <- c('logical','integer','double','complex','character','raw')

	#200. Helper functions
	#210. Standardize the dtypes of the vector
	h_dtypes <- function(vec) {
		#100. Retrieve the class of the input
		cls <- class(vec)
		typ <- typeof(vec)

		#300. Verify different types
		if (all(cls %in% c('POSIXct','POSIXt'))) {
			cls <- 'datetime'
		} else if (any(cls == 'Period')) {
			if (!is.null(attr(cls, 'package'))) if (attr(cls, 'package') == 'lubridate') {
				cls <- 'time'
			}
		} else if (!any(typ %in% memclass)) (
			cls <- 'unknown'
		)

		#999. Export
		return(cls)
	}

	#500. Retrieve all classes of the columns
	sapply(inDF, h_dtypes, USE.NAMES = T, simplify = T)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')
		if (nchar(Sys.getenv('TZ')) == 0) Sys.setenv(TZ = 'Asia/Shanghai')

		library(magrittr)

		#100. Create data for test
		testdf <- data.frame(
			var_str = c('abcde',NA)
			,var_raw = c(as.raw(40), charToRaw('A'))
			,var_int = c(5,7)
			,var_float = c(14.678,83.32)
			,var_date = c('2023-12-25','2023-12-32')
			,var_dt = c('2023-12-25 12:34:56.789012','2023-12-31 00:24:41.16812')
			,var_time = c('12:34:56.789012','789')
			,var_bool = c(T,F)
			,var_cat = as.factor(c('abc','def'))
			,var_complex = c(1 + 3i, 12.4 + 4.6i)
			,stringsAsFactors = F
		) %>%
			dplyr::mutate(
				var_int = as.integer(var_int)
				,var_date = asDates(var_date)
				,var_dt = asDatetimes(var_dt)
				,var_time = asTimes(var_time)
			)

		#200. Get the dtypes of the data
		dtypes <- getDtypes(testdf)

	}
}
