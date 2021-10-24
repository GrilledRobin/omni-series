#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to retrieve the attributes of date or datetime intervals for calculation of date incremental             #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |interval    :   Character string as a time interval such as WEEK, SEMIYEAR, QTR, or HOUR, case insensitive. It has no default      #
#   |                 value, while the functions raises error if it is NOT provided. Accepted values are as below:                      #
#   |                |------------------------------------------------------------------------------------------------------------------#
#   |                |Category |Interval  |Definition                                        |Example    |Description                   #
#   |                |---------+----------+--------------------------------------------------+-----------+------------------------------#
#   |                |Date     |DAY       |Daily intervals                                   |day3       |each 3-day starting on Sunday #
#   |                |         |WEEK      |Weekly intervals                                  |week2      |2 weeks from now              #
#   |                |         |WEEKDAY   |Daily intervals with Sat and Sun as holidays      |weekday2   |2 weekdays from now           #
#   |                |         |TENDAY    |10-day intervals cut by 1st, 11th and 21st of     |tenday2    |20 days from now              #
#   |                |         |          | each month                                       |           |                              #
#   |                |         |SEMIMONTH |Half-month intervals, cut at 15th                 |semimonth3 |3 half-months from now        #
#   |                |         |MONTH     |Monthly intervals                                 |month3     |3 months from now             #
#   |                |         |QTR       |Quarterly intervals, on Jan, Mar, Jul and Oct     |qtr2       |2 quarters from now           #
#   |                |         |SEMIYEAR  |Semiannual intervals, on Jan and Jul              |semiyear3  |3 semiyears from now          #
#   |                |         |YEAR      |Yearly intervals, on Jan                          |year2      |2 years from now              #
#   |                |---------+----------+--------------------------------------------------+-----------+------------------------------#
#   |                |Time     |SECOND    |Second intervals                                  |second2    |each 2 seconds                #
#   |                |         |MINUTE    |Minute intervals                                  |minute2    |each 2 minutes                #
#   |                |         |HOUR      |Hour intervals                                    |hour2      |each 2 hours                  #
#   |                |---------+----------+--------------------------------------------------+-----------+------------------------------#
#   |                |Datetime |DT+<DATE> |Add [DT] to any of the [Date] or [time] intervals |dtday3     |each 3-day starting on Sunday #
#   |                |------------------------------------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<list>      :   List of lists with their respective [names] set the same as the input vector of [interval] and values include:     #
#   |                [itype         ] Type of the interval among the choices: [d, dt, t]                                                #
#   |                [name          ] Name of the interval among the choices as defined for [interval]                                  #
#   |                [span          ] Date span to extend [omniR$Dates$UserCalendar] for each of current interval during calculation    #
#   |                [multiple      ] Multiple as input for the calculation of date incremental, default as [1]                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210901        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20211005        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Correct the [span] for [weekday] as 1, instead of 5, to make it a type of incremental on single units instead of period #
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
#   |   |stringr                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	stringr
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

getDateIntervals <- function(interval){
	#010. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	interval <- unname(unlist(interval))

	#050. Local parameters
	re.I <- re.S <- re.M <- re.X <- T
	gti_flags <- list(
		ignore_case = re.I
		# ,dotall = re.S
		# ,multiline = re.M
		# ,comments = re.X
	)

	#053. Date and time intervals
	dict_d <- list(
		'day' = list('span' = 1)
		,'week' = list('span' = 7)
		,'weekday' = list('span' = 1)
		,'tenday' = list('span' = 10)
		,'semimonth' = list('span' = 16)
		,'month' = list('span' = 31)
		,'qtr' = list('span' = 92)
		,'semiyear' = list('span' = 183)
		,'year' = list('span' = 366)
	)
	dict_dt <- dict_d
	names(dict_dt) <- paste0('dt', names(dict_d))
	dict_t <- list(
		'second' = list('span' = 1)
		,'minute' = list('span' = 60)
		,'hour' = list('span' = 3600)
	)
	dict_dtt <- dict_t
	names(dict_dtt) <- paste0('dt', names(dict_t))
	dict_dates <- list(
		'd' = dict_d
		,'dt' = dict_dt
		,'t' = dict_t
		,'dtt' = dict_dtt
	)

	#100. Create a list of candidates to be output in terms of successful matching at later steps
	cand_out <- do.call(c, lapply(
		names(dict_dates)
		,function(x){
			lapply(
				names(dict_dates[[x]])
				,function(y){
					list(
						'itype' = x
						,'name' = y
						,'span' = dict_dates[[x]][[y]][['span']]
					)
				}
			)
		}
	))
	names(cand_out) <- do.call(c, sapply(dict_dates, names))

	#300. Combine all patterns into one, using [|] to minimize the system effort during matching
	str_ntvl_match <- do.call(
		stringr::regex
		,append(
			list(
				pattern = paste0('^\\s*(', paste0(names(cand_out), collapse = '|'), ')(\\d*)\\s*$')
			)
			,gti_flags
		)
	)

	#399. Stop if the input values is not recognized
	ptn_ntvl_detect <- stringr::str_detect(interval, str_ntvl_match)
	if (!all(ptn_ntvl_detect)) {
		err_ntvl <- interval[!ptn_ntvl_detect]
		stop(
			'[',LfuncName,'][interval]:[',paste0(err_ntvl, collapse = ','),'] cannot be recognized!'
			,'\n','Valid intervals should match the pattern: ',str_ntvl_match
		)
	}

	#500. Find all matches from the input
	#501. Extract all capture groups into a matrix
	#Quote: https://stringr.tidyverse.org/reference/str_match.html
	ptn_ntvl_match <- stringr::str_match(interval, str_ntvl_match)

	#510. Extract the first groups as [Interval ID]
	ntvl_id <- tolower(ptn_ntvl_match[,2])

	#520. Extract the second groups as [Interval Multiple]
	ntvl_m <- as.integer(ptn_ntvl_match[,3])
	ntvl_m[is.na(ntvl_m) | (ntvl_m == 0)] <- 1

	#700. Prepare the output
	#710. Identify which among the candidates should be used
	outRst_pre <- cand_out[ntvl_id]
	names(outRst_pre) <- seq_along(outRst_pre)

	#750. Create a list of [multiples] to update above results
	ntvl_mult <- lapply(
		seq_along(outRst_pre)
		,function(i) list(multiple = ntvl_m[[i]])
	)
	names(ntvl_mult) <- seq_along(outRst_pre)

	#799. Update the output result with the necessary information
	outRst <- modifyList(outRst_pre, ntvl_mult)

	#999. Output
	# names(outRst) <- interval
	return(outRst)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#100. Parse the datetime interval
		a1 <- getDateIntervals( 'SEMIMONTH3' )

		#200. Parse the datetime intervals (with potential duplicates)
		a2 <- getDateIntervals( c('day', 'dthour2', 'day', 'SEMIMONTH3') )
	}
}
