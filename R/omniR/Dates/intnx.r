#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to resemble the same one in SAS to increment a date, time, datetime value, or an Iterable of the         #
#   | previous, by a given time interval                                                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[IMPORTANT]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[01] Although this function supports [sapply(f,...)] or [Map(f,e)] methods to apply to an Iterable, it is strongly recommended     #
#   |      to call it directly by [f(e,...)] as it internally uses Table Join processes to facilitate bulk data massage                 #
#   |[02] Similar to above, it is strongly recommended to pass an existing [User Calendar] to the argument [cal] if one insists to call #
#   |      it by means of [sapply(f,...)] or [Map(f,e)], to minimize the system calculation effort                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[FEATURE]                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[01] Support different types of [indate], i.e. table-like, Date, POSIXt, lubridate::Period as time, strings indicating datetimes   #
#   |[02] Does not support [.starting-point] in [interval] as that in SAS, as it is useless and ambiguous under most circumstances      #
#   |[03] Support the increment by Calendar Days, Working Days, or Trade Days                                                           #
#   |[04] Returned data type is [data.frame] if [indate is table-like]                                                                  #
#   |[05] Value type as output is determined by the [interval]                                                                          #
#   |[06] Holidays will be shifted to their respective Previous Work/Trade Days for calculation, given [daytype != C]. Therefore, the   #
#   |      returned value for holidays could be [NA] if the incremented value is less than 1 day                                        #
#   |[07] [WEEKDAY] as [interval] has different definition to that in SAS, see below definition of [omniR$Dates$getDateIntervals]       #
#   |[08] [WEEK] starts with Sunday=0 and ends with Saturday=6, to align that in SAS                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |interval    :   Character string as a time interval such as WEEK, SEMIYEAR, QTR, or HOUR, case insensitive. It has no default      #
#   |                 value, while the functions raises error if it is NOT provided.                                                    #
#   |                See definition of [omniR$Dates$getDateIntervals] for accepted values                                               #
#   |indate      :   Date-like values, can be list/vector of date values, character strings, integers or date column of a data frame    #
#   |increment   :   An integer to increment the [indate], float value is converted to integer by: int(abs(i)) * sign(i)                #
#   |                 [0           ] <Default> Return the same values                                                                   #
#   |                 [<Numeric>   ]           Unify the incremental for all element in [indate]. It will be converted to [int]         #
#   |                 [<Iterable>  ]           Iterable in the same shape as [indate] to differentiate incrementals for each element    #
#   |alignment   :   controls the position of dates/times within the interval, case insensitive                                         #
#   |                 [BEGINNING|B ] <Default> Align the values to the beginning of current interval after the increment                #
#   |                 [MIDDLE   |M ]           Align the values to the mean of beginning and ending of current interval after the       #
#   |                                           increment                                                                               #
#   |                 [END      |E ]           Align the values to the ending of current interval after the increment                   #
#   |                 [SAME     |S ]           Align the values to the same position of current interval after the increment            #
#   |daytype     :   Type of days for the calculation                                                                                   #
#   |                 [C           ] <Default> Calendar Days                                                                            #
#   |                 [W           ]           Working Days                                                                             #
#   |                 [T           ]           Trading Days                                                                             #
#   |cal         :   data.frame that is usually created by [omniR$Dates$intCalendar] object as the essential during the calculation     #
#   |                 [<None>      ] <Default> Function calls [intCalendar] with the arguments [**kw_cal]                               #
#   |kw_d        :   Arguments for function [omniR$Dates$asDates] to convert the [indate] where necessary                               #
#   |                 [<Default>   ] <Default> Use the default arguments for [asDates]                                                  #
#   |kw_dt       :   Arguments for function [omniR$Dates$asDatetimes] to convert the [indate] where necessary                           #
#   |                 [<Default>   ] <Default> Use the default arguments for [asDatetimes]                                              #
#   |kw_t        :   Arguments for function [omniR$Dates$asTimes] to convert the [indate] where necessary                               #
#   |                 [<Default>   ] <Default> Use the default arguments for [asTimes]                                                  #
#   |kw_cal      :   Arguments for instantiating the class [omniR$Dates$UserCalendar] if [cal] is NOT provided                          #
#   |                 [<Default>   ] <Default> Use the default arguments for [UserCalendar]                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<various>   :   The return value depends on the input arguments                                                                    #
#   |                [1] When [indate] is table-like, return [data.frame]                                                               #
#   |                [2] Return a [vector] for all other cases where applicable                                                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210912        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20211006        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Correct the behavior when [interval] indicates [t] if the incremented result is in another day                          #
#   |      |[2] Introduce a function [intCalendar] to create interval-bound calendar for interval-related functions                     #
#   |      |[3] Ensure the datetime conversion is only conducted once during the function call                                          #
#   |      |[4] Re-launch the full calendar so that this function covers all special scenarios for work/trade/week days                 #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20211122        | Version | 2.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug: [multiple] is not implemented when [dtt] is triggered                                                      #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20211204        | Version | 2.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Unify the effect of [col_rowidx] and [col_period] when [span]==1, hence [col_rowidx] is no longer used                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20220214        | Version | 2.30        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug: [intnx('day', '20211231', 1, daytype = 'w')] returns [NA]. This was due to the calendar span is not set    #
#   |      |     enough for calculation                                                                                                 #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230114        | Version | 2.40        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |magrittr, lubridate, rlang, dplyr, tidyr, tidyselect, vctrs                                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvOp                                                                                                                    #
#   |   |   |isDF                                                                                                                       #
#   |   |   |match.arg.x                                                                                                                #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$Dates                                                                                                                    #
#   |   |   |intCalendar                                                                                                                #
#   |   |   |getDateIntervals                                                                                                           #
#   |   |   |asDates                                                                                                                    #
#   |   |   |asDatetimes                                                                                                                #
#   |   |   |asTimes                                                                                                                    #
#   |   |   |UserCalendar                                                                                                               #
#   |   |   |ObsDates                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	magrittr, lubridate, rlang, dplyr, tidyr, tidyselect, vctrs
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

library(magrittr)

intnx <- function(
	interval
	,indate
	,increment = 0
	,alignment = c('beginning','middle','end','same')
	,daytype = c('C','W','T')
	,cal = NULL
	,kw_d = formals(asDates)[!(names(formals(asDates)) %in% c('indate'))]
	,kw_dt = formals(asDatetimes)[!(names(formals(asDatetimes)) %in% c('indate'))]
	,kw_t = formals(asTimes)[!(names(formals(asTimes)) %in% c('indate'))]
	,kw_cal = formals(UserCalendar$public_methods$initialize)[
		!(names(formals(UserCalendar$public_methods$initialize)) %in% c('dateBgn', 'dateEnd', 'clnBgn', 'clnEnd'))
	]
){
	#010. Parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	#[Quote: https://www.r-bloggers.com/doing-away-with-%e2%80%9cunknown-timezone%e2%80%9d-warnings/ ]
	#[Quote: Search for the TZ value in the file: [<R Installation>/share/zoneinfo/zone.tab]]
	if (nchar(Sys.getenv('TZ')) == 0) Sys.setenv(TZ = 'Asia/Shanghai')
	if (vctrs::vec_is_list(increment)) {
		stop('[',LfuncName,'][increment] cannot be a plain list!')
	}

	#012. Handle the parameter buffer
	daytype <- match.arg.x(daytype, arg.func = toupper)

	#015. Function local variables
	col_rowidx <- '.ical_row.'
	col_period <- '.ical_prd.'
	col_prdidx <- '.ical_rprd.'
	col_weekday <- '.ical_wday.'
	col_keys <- '.intnxRec.'
	col_calc <- '.intnxCol.'
	col_idxcol <- '.intnxKCol.'
	col_idxrow <- '.intnxKRow.'

	#020. Remove possible items that conflict the internal usage from the [kw_cal]
	kw_cal_fnl <- kw_cal[!(names(kw_cal) %in% c('dateBgn', 'dateEnd', 'clnBgn', 'clnEnd'))]

	#030. Helper functions
	#031. Function to create [Period] out of [hour], [minute] and [second] from [POSIXt]
	h_cr_hms <- function(d){
		lubridate::hours(lubridate::hour(d)) +
		lubridate::minutes(lubridate::minute(d)) +
		lubridate::seconds(lubridate::second(d))
	}

	#035. Convert increment into integer
	.convIncr <- function(x) return(floor(abs(x)) * sign(x))

	#039. Return the result in the same shape as input
	h_rst <- function(rst, col){
		if (isDF(indate)) {
			#100. Retrieve the data
			if (ncol(indate) == 1) {
				#By doing this, the index of the output is exactly the same as the input
				rstOut <- rst %>% dplyr::select(tidyselect::all_of(col))
			} else {
				#100. Unstack the data for output
				rstOut <- rst %>%
					dplyr::select(tidyselect::all_of(c(col_idxrow, col_idxcol, col))) %>%
					tidyr::pivot_wider(
						id_cols = tidyselect::all_of(col_idxrow)
						,names_from = tidyselect::all_of(col_idxcol)
						,values_from = tidyselect::all_of(col)
						,values_fill = NA
					) %>%
					dplyr::select(-tidyselect::all_of(col_idxrow)) %>%
					as.data.frame()
			}

			#300. Set the column names to the same as the input
			names(rstOut) <- names(indate)
			#Quote: https://stackoverflow.com/questions/20643166
			rownames(rstOut) <- rownames(indate)

			#999. Return
			return(rstOut)
		} else {
			#100. Only retrieve the single column
			rstOut <- rst %>% dplyr::pull(col)
			names(rstOut) <- names(indate)

			#999. Return
			return(rstOut)
		}
	}

	#050. Local parameters
	#053. Date and time intervals
	dict_dates <- list(
		'd' = list(
			'func' = asDates
			,'kw' = kw_d
		)
		,'dt' = list(
			'func' = asDatetimes
			,'kw' = kw_dt
		)
		,'t' = list(
			'func' = asTimes
			,'kw' = kw_t
		)
		,'dtt' = list(
			'func' = asDatetimes
			,'kw' = kw_dt
		)
	)

	#055. Validate the input calendar
	vfy_cal <- F
	if (isDF(cal)) if (nrow(cal) > 0) vfy_cal <- T

	#057. Column names for different request types for dates
	dict_adjcol <- c('W' = 'F_WORKDAY', 'T' = 'F_TradeDay')

	#060. Get the attributes for the requested time interval
	#The result of below function is [list], while current input has only one element, hence we use the first among the result
	dict_attr <- getDateIntervals(interval)[[1]]

	#069. Return a placeholder for NULL inputs
	if (isDF(indate)) {
		if (nrow(indate) == 0) {
			rstOut <- do.call(
				dict_dates[[dict_attr[['itype']]]][['func']]
				,modifyList(list('indate' = indate), dict_dates[[dict_attr[['itype']]]][['kw']])
			)
			return(rstOut)
		} else if (ncol(indate) == 0) {
			return(indate)
		}
	} else {
		if (vctrs::vec_is_list(indate)) {
			stop('[',LfuncName,'][indate] cannot be a plain list!')
		} else if (length(indate) == 0) {
			rstOut <- do.call(
				dict_dates[[dict_attr[['itype']]]][['func']]
				,modifyList(list('indate' = indate), dict_dates[[dict_attr[['itype']]]][['kw']])
			)
			return(rstOut)
		}
	}

	#070. Standardize the [alignment]
	dict_attr[['alignment']] <- match.arg.x(alignment, arg.func = tolower)

	#080. Define interim column names for call of helper functions
	if (dict_attr[['itype']] %in% c('d', 'dt')) {
		col_merge <- '.intnxDate.'
		col_out <- 'D_DATE'
	} else {
		col_merge <- '.intnxTime.'
		col_out <- 'T_TIME'
	}

	#100. Standardize input data
	#101. Verify the shape if both are provided a table-like object
	if (isDF(indate)) {
		if (isDF(increment)) {
			if (!all(dim(increment) == dim(indate))) {
				stop(
					'[',LfuncName,'][indate]:[(',paste0(dim(indate), collapse = ','),')] must be of the same shape as'
					,' [increment]:[(',paste0(dim(increment), collapse = ','),')]'
				)
			}
		} else {
			len_incr <- length(increment)
			if (len_incr != 1) {
				if ((ncol(indate) != 1) | (nrow(indate) != len_incr)) {
					stop(
						'[',LfuncName,'][increment] with the length of [',len_incr,']'
						,' cannot be broadcast to the same shape as [indate]:[(',paste0(dim(indate), collapse = ','),')]!'
					)
				}
			}
		}
	} else {
		if (isDF(increment)) {
			stop(
				'[',LfuncName,'][increment]:[',class(increment),'] must be of the same type as'
				,' [indate]:[',class(indate),']'
			)
		} else {
			len_incr <- length(increment)
			len_indate <- length(indate)
			if (len_incr != 1) {
				if (len_indate != len_incr) {
					stop(
						'[',LfuncName,'][increment]:[',len_incr,'] must be of the same length as'
						,' [indate]:[',len_indate,']'
					)
				}
			}
		}
	}

	#110. Transform [indate]
	if (isDF(indate)) {
		#010. Convert the input anyway as the underlying conversion function handles data.frame well
		df_indate <- do.call(
			dict_dates[[dict_attr[['itype']]]][['func']]
			,modifyList(list('indate' = indate), dict_dates[[dict_attr[['itype']]]][['kw']])
		)

		#100. Create the data frame
		if (ncol(indate) == 1) {
			names(df_indate) <- col_calc
			df_indate[[col_idxcol]] <- 1
			df_indate[[col_idxrow]] <- seq_len(nrow(indate))
			df_indate[[col_keys]] <- seq_len(nrow(indate))
		} else {
			df_indate %<>%
				tidyr::pivot_longer(tidyselect::all_of(names(df_indate)), names_to = '.name.', values_to = col_calc) %>%
				dplyr::mutate(
					!!rlang::sym(col_idxcol) := rep.int(seq_len(ncol(df_indate)), nrow(df_indate))
					,!!rlang::sym(col_idxrow) := do.call(c, sapply(seq_len(nrow(df_indate)), rep.int, ncol(df_indate), simplify = F))
					,!!rlang::sym(col_keys) := dplyr::row_number()
				)
		}
	} else {
		#500. Convert it into the requested value
		tmp_indate <- do.call(
			dict_dates[[dict_attr[['itype']]]][['func']]
			,modifyList(list('indate' = indate), dict_dates[[dict_attr[['itype']]]][['kw']])
		)

		#900. Standardize the internal data frame
		df_indate <- data.frame(tmpval = tmp_indate)
		names(df_indate) <- col_calc
		df_indate[[col_idxcol]] <- 1
		df_indate[[col_idxrow]] <- seq_len(nrow(df_indate))
		df_indate[[col_keys]] <- seq_len(nrow(df_indate))
	}

	#120. Transform [increment] into a vector instead of a data.frame
	#Till now all invalid pairs of inputs have been eliminated
	#A multi-element vector with all [NA]s is NOT [numeric]!
	if (is.numeric(increment) | all(is.na(increment))) {
		l_incr <- .convIncr(increment)
	} else if (ncol(increment) == 1) {
		l_incr <- increment %>% dplyr::pull(tidyselect::all_of(names(increment))) %>% .convIncr()
	} else {
		#We must conduct the conversion before pivoting, to avoid NA result out of different dtypes of input
		l_incr <- data.frame(lapply(increment, .convIncr)) %>%
			tidyr::pivot_longer(tidyselect::all_of(names(increment)), names_to = '.name.', values_to = '.intnxIncr.') %>%
			dplyr::pull('.intnxIncr.')
	}

	#Retrieve the bounds of the increment, while setting them as 0 if all are [NA]
	if (all(is.na(l_incr))) {
		l_cal_imin <- 0
		l_cal_imax <- 0
	} else {
		l_cal_imin <- min(0, l_incr, na.rm = T)
		l_cal_imax <- max(0, l_incr, na.rm = T)
	}

	#150. Calculate the incremental for [datetime] when [type] in [dt(second|minute|hour)] by calling this function in recursion
	#Till this step [indate] and [increment] have already been standardized
	if (dict_attr[['itype']] %in% c('dtt')) {
		#100. Convert the incremental into [number of seconds]
		dtt_incr <- l_incr * dict_attr[['multiple']] * dict_attr[['span']]

		#200. Convert the [time] part of the input data
		dtt_indat_sec <- df_indate %>%
			dplyr::mutate_at(
				col_calc
				,~lubridate::hour(.) * 3600 + lubridate::minute(.) * 60 + lubridate::second(.)
			) %>%
			dplyr::pull(tidyselect::all_of(col_calc))

		#400. Calculate the arithmetical increment and determine the increment for [date] and [time] part respectively
		#[IMPORTANT] Calculation at this step is element-wise, which supports different increments for different datetime values
		#510. Overall incremental
		dtt_incr <- dtt_indat_sec + dtt_incr

		#550. Set the [floor division] of above incremental over 86400 (total number of seconds in a day) as that of [date] part
		dtt_incr_date <- dtt_incr %/% 86400

		#600. Conduct the calculation for [date] and [time] parts respectively
		#610. Retrieve the parts as vectors for simplification
		dtt_indate <- df_indate %>% dplyr::pull(tidyselect::all_of(col_calc)) %>% lubridate::date()

		#630. Increment by [day]
		dtt_rst_date <- intnx(
			interval = 'day'
			,indate = dtt_indate
			,increment = dtt_incr_date
			#[alignment] is useless for [interval == 'day']
			,alignment = dict_attr[['alignment']]
			,daytype = daytype
			,cal = cal
			,kw_d = kw_d
			,kw_dt = kw_dt
			,kw_t = kw_t
			,kw_cal = kw_cal
		)

		#650. Increment by different scenarios of [time]
		dtt_rst_time <- asTimes(dtt_incr %% 86400)

		#700. Correction on incremental for [Work/Trade Days]
		if (daytype %in% c('W', 'T')) {
			#050. Define local variables
			dict_obsDates <- c('W' = 'isWorkDay', 'T' = 'isTradeDay')

			#100. Verify whether the input values are [Work/Trade Days]
			#110. Instantiate the observed calendar
			dtt_obs <- do.call(
				ObsDates$new
				,modifyList(
					list(
						obsDate = dtt_indate
					)
					,kw_cal_fnl
				)
			)

			#150. Retrieve the flag in reversed value
			dtt_flag <- !dtt_obs[[dict_obsDates[[daytype]]]]

			#500. Correction by below conditions
			#[1] Incremental is 0 (other cases are handled in other steps)
			#[2] The input date is Public Holiday
			#510. Mark the records with both of below conditions
			dtt_mask_zero <- dtt_flag & (dtt_incr_date == 0)
			dtt_mask_zero[is.na(dtt_mask_zero)] <- FALSE

			#590. Set the above records as [pd.NaT] for good reason
			dtt_rst_date[dtt_mask_zero] <- NA

			#700. Correction by below conditions
			#[1] Incremental is below 0
			#710. Mark the records with above conditions
			dtt_mask_neg <- dtt_flag & (dtt_incr_date < 0)
			dtt_mask_neg[is.na(dtt_mask_neg)] <- FALSE

			#590. Set the above records as [pd.NaT] for good reason
			dtt_rst_date[dtt_mask_neg] <- dtt_rst_date[dtt_mask_neg] + as.difftime(1, units = 'days')
		}

		#800. Combine the parts into [datetime]
		#810. Combine the vectors
		dtt_rst_vec <- dtt_rst_date + dtt_rst_time
		lubridate::tz(dtt_rst_vec) <- Sys.getenv('TZ')

		#890. Retrieve the attributes of the input data.frame
		dtt_rst <- df_indate %>% dplyr::select(tidyselect::all_of(c(col_idxrow, col_idxcol)))
		dtt_rst[[col_out]] <- dtt_rst_vec

		#990. Reshape the result
		return(h_rst(dtt_rst, col_out))
	}

	#200. Prepare necessary columns
	#220. Unanimous columns
	if (dict_attr[['itype']] %in% c('t')) {
		df_indate[[col_calc]] <- lubridate::today() + df_indate[[col_calc]]
	}
	df_indate[['.intnxIncr.']] <- l_incr

	#230. Create [col_merge] as well as the bounds of the calendar
	if (dict_attr[['itype']] %in% c('d', 'dt')) {
		#100. Create new column
		if (dict_attr[['itype']] %in% c('d')) {
			df_indate[[col_merge]] <- df_indate[[col_calc]]
		} else {
			df_indate[[col_merge]] <- lubridate::date(df_indate[[col_calc]])
		}

		#500. Define the bound of the calendar
		notnull_indate <- !is.na(df_indate[[col_merge]])
		if (!any(notnull_indate)) {
			#100. Assign the minimum size of calendar data if none of the input is a valid date
			cal_bgn <- lubridate::today()
			cal_end <- cal_bgn
		} else {
			#100. Retrieve the minimum and maximum values among the input values
			in_min <- min(df_indate[[col_merge]], na.rm = T)
			in_max <- max(df_indate[[col_merge]], na.rm = T)

			#500. Extend the period coverage by the provided span and multiple
			tmp_min <- in_min
			lubridate::year(tmp_min) <- lubridate::year(in_min) - 1
			lubridate::month(tmp_min) <- 1
			lubridate::day(tmp_min) <- 1
			cal_bgn <- tmp_min + as.difftime(l_cal_imin * dict_attr[['multiple']] * dict_attr[['span']], units = 'days')
			tmp_max <- in_max
			lubridate::year(tmp_max) <- lubridate::year(in_max) + 1
			lubridate::month(tmp_max) <- 12
			lubridate::day(tmp_max) <- 31
			cal_end <- tmp_max + as.difftime(l_cal_imax * dict_attr[['multiple']] * dict_attr[['span']], units = 'days')

			#800. Ensure the period cover the minimum and maximum of the input values
			cal_bgn <- min(cal_bgn, in_min)
			cal_end <- max(cal_end, in_max)
		}
	} else {
		#100. Create new column
		df_indate[[col_merge]] <- df_indate[[col_calc]]
		lubridate::second(df_indate[[col_merge]]) <- floor(lubridate::second(df_indate[[col_merge]]))

		#500. Define the bound of the calendar
		notnull_indate <- !is.na(df_indate[[col_merge]])
		if (!any(notnull_indate)) {
			#100. Assign the minimum size of calendar data if none of the input is a valid date
			cal_bgn <- asDatetimes( lubridate::today() )
			cal_end <- cal_bgn
		} else {
			#100. Retrieve the minimum and maximum values among the input values
			in_min <- min(df_indate[[col_merge]], na.rm = T)
			in_max <- max(df_indate[[col_merge]], na.rm = T)

			#500. Extend the period coverage by the provided span and multiple
			tmp_min <- in_min
			lubridate::minute(tmp_min) <- 0
			lubridate::second(tmp_min) <- 0
			cal_bgn <- tmp_min + as.difftime(l_cal_imin * dict_attr[['multiple']] * dict_attr[['span']], units = 'secs')
			tmp_max <- in_max
			lubridate::minute(tmp_max) <- 59
			lubridate::second(tmp_max) <- 59
			cal_end <- tmp_max + as.difftime(l_cal_imax * dict_attr[['multiple']] * dict_attr[['span']], units = 'secs')

			#800. Ensure the period cover the minimum and maximum of the input values
			cal_bgn <- min(cal_bgn, in_min)
			cal_end <- max(cal_end, in_max)
		}
	}

	#250. [time] part for [type == dt]
	if (dict_attr[['itype']] %in% c('dt')) {
		df_indate[['.intnx_dttime.']] <- h_cr_hms(df_indate[[col_calc]])
	}

	#300. Prepare calendar data
	if (!vfy_cal) {
		intnx_calfull <- intCalendar(
			interval = dict_attr
			,cal_bgn = cal_bgn
			,cal_end = cal_end
			,daytype = daytype
			,col_rowidx = col_rowidx
			,col_period = col_period
			,col_prdidx = col_prdidx
			,kw_cal = kw_cal_fnl
		)
	} else {
		intnx_calfull <- cal %>% dplyr::arrange_at(tidyselect::all_of(col_out))
	}

	#500. Define helper functions to calculate the incremental for different scenarios
	h_intnx <- function(cal_in, cal_full, multiple, alignment) {
		#100. Create a copy of the input data
		rst <- cal_in

		#500. Calculate the incremented [col_period]
		rst[['.gti_newprd.']] <- rst[[col_period]] + rst[['.intnxIncr.']] * multiple
		# print(rst[c(col_rowidx, col_period, '.gti_newprd.')])

		#700. Calculate the alignment based on the request
		if (dict_attr[['span']] == 1) {
			rst %<>% dplyr::left_join(cal_full, by = c('.gti_newprd.' = col_period))
		} else if (alignment == 'beginning') {
			#100. Identify the beginning of each period
			prd_bgn <- cal_full %>%
				dplyr::group_by_at(tidyselect::all_of(col_period)) %>%
				dplyr::slice_head(n = 1) %>%
				dplyr::ungroup() %>%
				dplyr::select_at(tidyselect::all_of(c(col_period, col_out)))

			#900. Add the special series to the result as a new column
			rst %<>% dplyr::left_join(prd_bgn, by = c('.gti_newprd.' = col_period))
		} else if (alignment == 'end') {
			#100. Identify the ending of each period
			prd_end <- cal_full %>%
				dplyr::group_by_at(tidyselect::all_of(col_period)) %>%
				dplyr::slice_tail(n = 1) %>%
				dplyr::ungroup() %>%
				dplyr::select_at(tidyselect::all_of(c(col_period, col_out)))
			# assign('ccc', prd_end, envir = .GlobalEnv)

			#900. Add the special series to the result as a new column
			rst %<>% dplyr::left_join(prd_end, by = c('.gti_newprd.' = col_period))
			# print(rst[c(col_keys, col_out)])
		} else if (alignment == 'same') {
			#100. Identify the ending of each period and only retrieve the relative index of its unit
			#This is because we only have to compare its index to the one we calculated
			prd_end <- cal_full %>%
				dplyr::group_by_at(tidyselect::all_of(col_period)) %>%
				dplyr::slice_tail(n = 1) %>%
				dplyr::ungroup() %>%
				dplyr::select_at(tidyselect::all_of(c(col_period, col_prdidx))) %>%
				dplyr::rename('.gti_tmprow.' = tidyselect::all_of(col_prdidx))

			#500. Add the special series to the result as a new column
			rst %<>% dplyr::left_join(prd_end, by = c('.gti_newprd.' = col_period))

			#700. Identify the same relative index in the same period of interval, or the one at period end if it exceeds the span
			#e.g. shift [Mar31] back to the [same] day in [Feb] will result to [Feb28] in a year or [Feb29] in a leap year
			rst[[col_prdidx]] <- pmin(rst[[col_prdidx]], rst[['.gti_tmprow.']])

			#900. Retrieve the row at the same index of the period of interval
			by_var <- c(col_period, col_prdidx)
			names(by_var) <- c('.gti_newprd.', col_prdidx)
			rst %<>%
				dplyr::left_join(
					#We have to [unname] the column names, otherwise the [name] of the vector is [select]ed
					cal_full %>% dplyr::select(tidyselect::all_of(unname(c(by_var, col_out))))
					,by = by_var
				)
		} else {
			#100. Count the units covered by each period of interval and identify the middle one
			#[1] Esp. for [month] as interval, we align the function in SAS by setting the [middle] of Feb as 14th
			prd_mid <- cal_full %>%
				dplyr::select(tidyselect::all_of(col_period)) %>%
				dplyr::group_by_at(tidyselect::all_of(col_period)) %>%
				dplyr::mutate('.tmpcnt.' = dplyr::row_number()) %>%
				dplyr::slice_tail(n = 1) %>%
				dplyr::ungroup() %>%
				dplyr::mutate(!!rlang::sym(col_prdidx) := floor(!!rlang::sym('.tmpcnt.') / 2))

			#400. Correct above index as [second] starts from [0], while others starts from [1]
			if (dict_attr[['itype']] %in% c('t')) {
				prd_mid[[col_prdidx]] <- prd_mid[[col_prdidx]] + 1
			}

			#900. Retrieve the row at the middle of the period of interval
			by_var <- c(col_period, col_prdidx)
			names(by_var) <- c('.gti_newprd.', col_prdidx)
			rst %<>%
				dplyr::select(-tidyselect::all_of(col_prdidx)) %>%
				dplyr::left_join(
					prd_mid
					,by = c('.gti_newprd.' = col_period)
				) %>%
				dplyr::left_join(
					#We have to [unname] the column names, otherwise the [name] of the vector is [select]ed
					cal_full %>% dplyr::select(tidyselect::all_of(unname(c(by_var, col_out))))
					,by = by_var
				)
		}

		#999. Return the result
		return(rst %>% dplyr::select(tidyselect::all_of(c(col_keys, col_out))))
	}

	#700. Prepare the calendar
	#710. Copy the full calendar
	intnx_cal <- intnx_calfull

	#730. Only retrieve valid days when necessary
	if (dict_attr[['itype']] %in% c('d', 'dt')) {
		#100. Only retrieve work/trade days when necessary
		if (daytype %in% c('W', 'T')) {
			intnx_cal %<>% dplyr::filter_at(dict_adjcol[[daytype]], ~.)
		}

		#300. Only retrieve weekdays when necessary
		if (dict_attr[['name']] %in% c('weekday', 'dtweekday')) {
			intnx_cal %<>% dplyr::filter_at(col_weekday, ~.)
		}
	}

	#800. Calculate the incremental
	#801. Determine the columns in the calendar to be used for calculation
	col_cal <- c(col_out, col_period, col_prdidx)

	#820. Retrieve the corresponding columns from the calendar for non-empty dates
	#[IMPORTANT] We keep all the calendar days at this step, to match the holidays
	by_var <- col_out
	names(by_var) <- col_merge
	df_cal_in <- df_indate %>%
		dplyr::select(tidyselect::all_of(c(col_keys, col_merge, '.intnxIncr.'))) %>%
		dplyr::left_join(
			intnx_calfull %>% dplyr::select(tidyselect::all_of(col_cal))
			,by = by_var
		)

	#830. Calculation
	df_incr <- h_intnx(
		df_cal_in
		,intnx_cal
		,dict_attr[['multiple']]
		,dict_attr[['alignment']]
	)

	#850. Merge the incremental back to the input data for later transformation
	col_dt <- c(col_keys, col_idxrow, col_idxcol)
	if (dict_attr[['itype']] %in% c('dt')) {
		col_dt <- c(col_dt, '.intnx_dttime.')
	}
	df_rst <- df_indate[col_dt] %>% dplyr::left_join(df_incr, by = col_keys)

	#870. Handle [dt] and [t] respectively
	if (dict_attr[['itype']] %in% c('dt')) {
		#Append the [time] part to the result for [type == dt]
		df_rst[[col_out]] <- df_rst[[col_out]] + df_rst[['.intnx_dttime.']]
		lubridate::tz(df_rst[[col_out]]) <- Sys.getenv('TZ')
	} else if (dict_attr[['itype']] %in% c('t')) {
		df_rst[[col_out]] <- h_cr_hms(df_rst[[col_out]])
	}

	#990. Return
	return(h_rst(df_rst, col_out))
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')
		if (nchar(Sys.getenv('TZ')) == 0) Sys.setenv(TZ = 'Asia/Shanghai')

		#100. Create dates for test
		dt1 <- lubridate::today()
		dt2 <- asDates( list(dt1, '20190412', '20200925') )
		names(dt2) <- c(1,3,5)
		dt4 <- data.frame(aa = dt2, bb = asDates(c('20181005', '20200214', '20210331')))
		rownames(dt4) <- c(1,3,5)
		dt5 <- data.frame(aa = dt2, bb = asDates(c('20181122', '20200214', NA)))
		rownames(dt5) <- c(1,3,5)
		dt6 <- lubridate::now()
		dt7 <- asDatetimes( list(dt6, '20190512 10:12:23', '20200925 17:34:27') )
		dt8 <- data.frame(a = dt7, b = asDatetimes(c('20181122 05:36:34', '20200214 18:06:38', '')))
		dt9 <- asTimes('08:25:40')

		t_now <- lubridate::now()
		t_end <- ObsDates$new(t_now)$nextWorkDay + asTimes('05:00:00')
		lubridate::tz(t_end) <- Sys.getenv('TZ')

		#200. Shift the values
		dt1_intnx1 <- intnx('day', dt1, -2, daytype = 'w')
		dt2_intnx1 <- intnx('day', dt2, -2, daytype = 'w')
		dt2_intnx2 <- intnx('day', dt2, -2, daytype = 'c')
		dt3_intnx1 <- intnx('week2', dt2, -2, 'b', daytype = 't')

		#210. Same month in the previous year, aligning to its Last Working Day
		dt4_intnx1 <- intnx('month', dt4, -12, 'e', daytype = 'w')

		#220. Same month in the previous year, aligning to its Last Calendar Day
		dt4_intnx2 <- intnx('month', dt4, -12, 'e', daytype = 'c')

		#250. With invalid input values
		dt5_intnx1 <- intnx('qtr', dt5, 2, 'b', daytype = 't')

		#260. Test the multiple on [dtt]
		diff_min5 <- intck('dtsecond300', t_now, t_end)
		t_chk <- intnx('dtsecond300', t_now, diff_min5)

		#300. Test datetime values
		dt6_intnx1 <- intnx('dtday', dt6, -2, daytype = 'w')
		dt6_intnx2 <- intnx('dthour', dt6, -20, daytype = 'w')

		#310. Test datetime list
		dt7_intnx1 <- intnx('dtday', dt7, -2, daytype = 'w')
		dt7_intnx2 <- intnx('dtminute', dt7, 600, daytype = 'w')
		dt8_intnx1 <- intnx('dthour', dt8, -6, daytype = 't')
		dt8_intnx2 <- intnx('dthour', dt8, -6, 's', daytype = 't')

		#400. Test time values
		dt9_intnx1 <- intnx('hour2', dt9, 3, 's')
		dt9_intnx2 <- intnx('hour2', dt9, -3, 'm')

		#500. Test special dates
		dt10_intnx1 <- intnx('month', '20210731', 0, 'e', daytype = 'w')
		dt10_intnx2 <- intnx('month', '20210801', 0, 'b', daytype = 'w')
		dt10_intnx3 <- intnx('week', '20211002', 0, 'b', daytype = 't')
		dt10_intnx4 <- intnx('day', '20211002', 0, daytype = 'w')
		dt10_intnx5 <- intnx('week', '20211003', 0, 'b', daytype = 't')
		dt10_intnx6 <- intnx('month', '20210925', 0, 's', daytype = 'w')
		dt10_intnx7 <- intnx('weekday', '20211008', -1, daytype = 't')
		dt10_intnx8 <- intnx('weekday', '20211008', 1, daytype = 't')
		dt11_intnx1 <- intnx('dthour', '20210926 23:42:15', -30, 's', daytype = 't')
		dt11_intnx2 <- intnx('dthour', '20210925 23:42:15', 6, 's', daytype = 't')
		dt11_intnx3 <- intnx('dthour', '20210926 23:42:15', -6, 's', daytype = 't')

		# [CPU] AMD Ryzen 5 5600 6-Core 3.70GHz
		# [RAM] 64GB 2400MHz
		#700. Test the timing of 2 * 100K dates
		df_ttt <- dt4 %>% dplyr::slice_sample(n = 100000, replace = T)

		t1 <- lubridate::now()
		df_trns <- intnx('month', df_ttt, -12, 'e', daytype = 'w')
		t2 <- lubridate::now()
		print(t2 - t1)
		# 0.33s
		View(df_trns)

		#800. Test the timing  of 2 * 100K datetimes
		df_ttt8 <- dt8 %>% dplyr::slice_sample(n = 100000, replace = T)

		t1 <- lubridate::now()
		df_trns8 <- intnx('dthour', df_ttt8, 12, 's', daytype = 'w')
		t2 <- lubridate::now()
		print(t2 - t1)
		# 1.0s
		View(df_trns8)

		#900. Test special cases
		#910. [NULL] vs [NULL]
		print(intnx('dthour', NULL, NULL, daytype = 'w'))
		#Return: POSIXct of length 0

		#915. [NULL] vs [numeric]
		print(intnx('day2', NULL, 1, daytype = 'w'))
		#Return: Date of length 0

		#915. [date] vs [NA]
		print(intnx('day2', dt1, NA, daytype = 'w'))
		#Return: NA

		#940. Empty data frames
		emp3 <- dt5 %>% dplyr::filter(FALSE)
		emp4 <- dt5 %>% dplyr::select(-tidyselect::all_of(names(dt5)))
		print(intnx('week', emp3, 1, daytype = 't'))
		print(intnx('week', emp4, 2, daytype = 'w'))
		#Return: the same type as the [indate] with no element

		#990. Test error cases
		if (FALSE) {
			#100. [date] vs [NULL]
			print(intnx('day2', dt1, NULL, daytype = 'w'))
			#Error: different lengths
		}
	}
}
