#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to resemble the same one in SAS to return the number of interval boundaries of a given kind that lie     #
#   | between two dates, times, or datetime values                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[IMPORTANT]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[01] Although this function supports [sapply(e,f)] or [lapply(e,f)] methods to apply to an Iterable, it is strongly recommended    #
#   |      to call it directly by [f(e,...)] as it internally uses Table Join processes to facilitate bulk data massage                 #
#   |[02] Similar to above, it is strongly recommended to pass an existing [User Calendar] to the argument [cal] if one insists to call #
#   |      it by means of [sapply(e,f)] or [lapply(e,f)], to minimize the system calculation effort                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[FEATURE]                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[01] Support different types of [date_*], i.e. table-like, Date, POSIXt, lubridate::Period as time, strings indicating datetimes   #
#   |[02] Does not support [.starting-point] in [interval] as that in SAS, as it is useless and ambiguous under most circumstances      #
#   |[03] Calculate on [DISCRETE] method, in spite of that in SAS, as there are other simpler ways to calculate on [CONTINUOUS] method  #
#   |[04] Support the increment by Calendar Days, Working Days, or Trade Days                                                           #
#   |[05] [WEEKDAY] as [interval] has different definition to that in SAS, see below definition of [omniR$Dates$getDateIntervals]       #
#   |[06] [WEEK] starts with Sunday=0 and ends with Saturday=6, to align that in SAS                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |interval    :   Character string as a time interval such as WEEK, SEMIYEAR, QTR, or HOUR, case insensitive. It has no default      #
#   |                 value, while the functions raises error if it is NOT provided.                                                    #
#   |                See definition of [omniR$Dates$getDateIntervals] for accepted values                                               #
#   |date_bgn    :   Date-like values, will be converted by [asDates], [asDatetimes] or [asTimes] as per request                        #
#   |date_end    :   Date-like values, will be converted by [asDates], [asDatetimes] or [asTimes] as per request                        #
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
#   |                [1] For case of pairs as (M,1):                                                                                    #
#   |                    [1] If [M] is table-like, return a data.frame in the same shape as [M]                                         #
#   |                    [2] If [M] is a vector, return a vector in the same length                                                     #
#   |                [2] For case of pairs as (M,N), [M.shape] must be the same as [N.shape] :                                          #
#   |                    [1] If either is table-like, return a data.frame in the same shape as [M]                                      #
#   |                    [2] In other cases, Return a vector in the same length as [M]                                                  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20211009        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20211122        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug: [multiple] is not implemented when [dtt] is triggered                                                      #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20211204        | Version | 1.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Unify the effect of [col_rowidx] and [col_period] when [span]==1, hence [col_rowidx] is no longer used                  #
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

intck <- function(
	interval
	,date_bgn
	,date_end
	,daytype = 'C'
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
	if (vctrs::vec_is_list(date_bgn)) {
		stop('[',LfuncName,'][date_bgn] cannot be a plain list!')
	}
	if (vctrs::vec_is_list(date_end)) {
		stop('[',LfuncName,'][date_end] cannot be a plain list!')
	}

	#012. Handle the parameter buffer
	daytype <- match.arg(toupper(daytype), c('C','W','T'))

	#015. Function local variables
	col_rowidx <- '.ical_row.'
	col_period <- '.ical_prd.'
	col_prdidx <- '.ical_rprd.'
	col_keys <- '.intckRec.'
	col_calc <- '.intckCol.'
	col_idxcol <- '.intckKCol.'
	col_idxrow <- '.intckKRow.'
	col_rst <- '.intckRst.'

	#020. Remove possible items that conflict the internal usage from the [kw_cal]
	kw_cal_fnl <- kw_cal[!(names(kw_cal) %in% c('dateBgn', 'dateEnd', 'clnBgn', 'clnEnd'))]

	#030. Helper functions
	#031. Function to create [Period] out of [hour], [minute] and [second] from [POSIXt]
	h_cr_hms <- function(d){
		lubridate::hours(lubridate::hour(d)) +
		lubridate::minutes(lubridate::minute(d)) +
		lubridate::seconds(lubridate::second(d))
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

	#060. Get the attributes for the requested time interval
	#The result of below function is [list], while current input has only one element, hence we use the first among the result
	dict_attr <- getDateIntervals(interval)[[1]]

	#080. Define interim column names for call of helper functions
	if (dict_attr[['itype']] %in% c('d', 'dt')) {
		col_merge <- '.intckDate.'
		col_out <- 'D_DATE'
	} else {
		col_merge <- '.intckTime.'
		col_out <- 'T_TIME'
	}

	#100. Reshape of the input datetime values
	#110. Extract information of [date_bgn]
	if (isDF(date_bgn)) {
		f_bgn_df <- T
		bgn_len <- nrow(date_bgn)
		bgn_shape <- dim(date_bgn)
		f_bgn_single <- all(bgn_shape == c(1,1))
		f_bgn_srs <- F
	} else {
		f_bgn_df <- F
		bgn_len <- length(date_bgn)
		bgn_shape <- bgn_len
		f_bgn_single <- bgn_len %in% c(0,1)
		f_bgn_srs <- length(names(date_bgn)) != 0
	}

	#We also verify the number of columns if the input is table-like
	f_bgn_len <- (bgn_len > 0) & (bgn_shape[[length(bgn_shape)]] > 0)
	f_bgn_empty <- (bgn_len == 0) | (bgn_shape[[length(bgn_shape)]] == 0)

	#120. Extract information of [date_end]
	if (isDF(date_end)) {
		f_end_df <- T
		end_len <- nrow(date_end)
		end_shape <- dim(date_end)
		f_end_single <- all(end_shape == c(1,1))
		f_end_srs <- F
	} else {
		f_end_df <- F
		end_len <- length(date_end)
		end_shape <- end_len
		f_end_single <- end_len %in% c(0,1)
		f_end_srs <- length(names(date_end)) != 0
	}

	#We also verify the number of columns if the input is table-like
	f_end_len <- (end_len > 0) & (end_shape[[length(end_shape)]] > 0)
	f_end_empty <- (end_len == 0) | (end_shape[[length(end_shape)]] == 0)

	#140. Verify the shapes of the input values
	f_Mto1 <- xor(f_bgn_single, f_end_single)
	f_1to1 <- f_bgn_single & f_end_single
	f_MtoN <- (!f_1to1) & all(bgn_shape == end_shape)
	f_comp_err <- !(f_Mto1 | f_1to1 | f_MtoN)

	#145. Abort if the shapes of the input values are not the same
	#After this step, if neither of the input has only one element, they must be in the same shape (e.g. both empty)
	if (f_comp_err) {
		stop('[',LfuncName,']Input values must be in the same shape!')
	}

	#148. Create the flag of whether to change the position of [date_bgn] and [date_end] for standardization
	f_switch <- f_Mto1 & f_bgn_single

	#150. Verify the shapes of the input values
	f_out_len <- f_bgn_len | f_end_len
	f_single_empty <- xor(f_bgn_empty, f_end_empty)

	#159. Raise error if the [table-like] among them has zero length
	if ((!f_1to1) & f_single_empty) {
		stop('[',LfuncName,']Non-empty values vs Empty table-like object is not accepted!')
	}

	#160. Determine the attributes of the output
	f_out_df <- f_bgn_df | f_end_df
	#By defining below variable, we identify the [names] attribute of the output vector
	f_out_srs <- f_bgn_srs | f_end_srs

	#165. Translate the input values to [M] and [N]
	if (f_switch) {
		df_M <- date_end
		df_N <- date_bgn
		f_M_df <- f_end_df
		f_N_df <- f_bgn_df
		f_M_srs <- f_end_srs
		shape_M <- end_shape
		shape_N <- bgn_shape
	} else {
		df_M <- date_bgn
		df_N <- date_end
		f_M_df <- f_bgn_df
		f_N_df <- f_end_df
		f_M_srs <- f_bgn_srs
		shape_M <- bgn_shape
		shape_N <- end_shape
	}

	#167. Identify the model of [columns] and [index] for output
	if (f_out_df) {
		#In such case, [df_M] is already table-like
		mdl_columns <- names(df_M)
		mdl_index <- rownames(df_M)
	} else if (f_out_srs) {
		#In such case, at least one of [df_M] and [df_N] is already a [named vector]
		#We still have to verify which one is [named] and take [M] for granted if applicable
		if (f_M_srs) {
			mdl_index <- names(df_M)
		} else {
			mdl_index <- names(df_N)
		}
	}

	#170. Prepare the helper function to return proper results
	h_rst <- function(rst, col){
		if (f_out_df) {
			#100. Retrieve the data
			if (shape_M[[1]] == 0) {
				#Only copy the dataframe structure
				rstOut <- do.call(
					data.frame
					,modifyList(
						sapply(mdl_columns, function(m){numeric(0)})
						,list(row.names = character(0))
					)
				)
			} else if (shape_M[[length(shape_M)]] == 0) {
				#Quote: https://www.statology.org/create-empty-data-frame-in-r/
				rstOut <- data.frame(matrix(ncol = shape_M[[length(shape_M)]], nrow = shape_M[[1]]))
			} else if (shape_M[[length(shape_M)]] == 1) {
				#By doing this, the index of the output is exactly the same as the input
				rstOut <- rst %>% dplyr::select(tidyselect::all_of(col)) %>% as.data.frame()
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
			names(rstOut) <- mdl_columns
			#Quote: https://stackoverflow.com/questions/20643166
			rownames(rstOut) <- mdl_index

			#999. Return
			return(rstOut)
		} else {
			#100. Only retrieve the single column as a [vector]
			rstOut <- rst %>% dplyr::pull(tidyselect::all_of(col))

			#980. Add names to the vector if any
			if (f_out_srs) {
				names(rstOut) <- mdl_index
			}

			#999. Return
			return(rstOut)
		}
	}

	#200. Re-shape the input values for calculation at later steps
	#201. Output an empty result if [M] is empty in the first place
	if (f_out_df) if ((shape_M[[1]] == 0) | (shape_M[[length(shape_M)]] == 0)) return(h_rst(df_rst))

	#210. Transform [M] for standardized calculation
	if (f_M_df) {
		#010. Convert the input anyway as the underlying conversion function handles data.frame well
		tmp_M <- do.call(
			dict_dates[[dict_attr[['itype']]]][['func']]
			,modifyList(list('indate' = df_M), dict_dates[[dict_attr[['itype']]]][['kw']])
		)

		#100. Create the data frame
		if (shape_M[[length(shape_M)]] == 1) {
			df_M <- tmp_M %>% as.data.frame()
			names(df_M) <- col_calc
			df_M[[col_idxcol]] <- rep_len(1, shape_M[[1]])
			df_M[[col_idxrow]] <- seq_len(shape_M[[1]])
			df_M[[col_keys]] <- seq_len(shape_M[[1]])
		} else {
			df_M <- tmp_M %>%
				tidyr::pivot_longer(tidyselect::all_of(names(tmp_M)), names_to = '.name.', values_to = col_calc) %>%
				dplyr::mutate(
					!!rlang::sym(col_idxcol) := rep.int(seq_len(shape_M[[length(shape_M)]]), shape_M[[1]])
					,!!rlang::sym(col_idxrow) := do.call(
						c
						,sapply(
							seq_len(shape_M[[1]])
							,rep.int
							,shape_M[[length(shape_M)]]
							,simplify = F
						)
					)
					,!!rlang::sym(col_keys) := dplyr::row_number()
				) %>%
				as.data.frame()
		}
	} else {
		#500. Convert it into the requested value
		tmp_M <- do.call(
			dict_dates[[dict_attr[['itype']]]][['func']]
			,modifyList(list('indate' = df_M), dict_dates[[dict_attr[['itype']]]][['kw']])
		)

		#900. Standardize the internal data frame
		df_M <- data.frame(tmpval = tmp_M)
		names(df_M) <- col_calc
		df_M[[col_idxcol]] <- rep_len(1, shape_M[[1]])
		df_M[[col_idxrow]] <- seq_len(shape_M[[1]])
		df_M[[col_keys]] <- seq_len(shape_M[[1]])
	}

	#250. Transform [N] for standardized calculation
	if (f_N_df) {
		#010. Convert the input anyway as the underlying conversion function handles data.frame well
		tmp_N <- do.call(
			dict_dates[[dict_attr[['itype']]]][['func']]
			,modifyList(list('indate' = df_N), dict_dates[[dict_attr[['itype']]]][['kw']])
		)

		#100. Create the data frame
		if (shape_N[[length(shape_N)]] == 1) {
			df_N <- tmp_N %>% as.data.frame()
			names(df_N) <- col_calc
			df_N[[col_idxcol]] <- rep_len(1, shape_N[[1]])
			df_N[[col_idxrow]] <- seq_len(shape_N[[1]])
			df_N[[col_keys]] <- seq_len(shape_N[[1]])
		} else {
			df_N <- tmp_N %>%
				tidyr::pivot_longer(tidyselect::all_of(names(tmp_N)), names_to = '.name.', values_to = col_calc) %>%
				dplyr::mutate(
					!!rlang::sym(col_idxcol) := rep.int(seq_len(shape_N[[length(shape_N)]]), shape_N[[1]])
					,!!rlang::sym(col_idxrow) := do.call(
						c
						,sapply(
							seq_len(shape_N[[1]])
							,rep.int
							,shape_N[[length(shape_N)]]
							,simplify = F
						)
					)
					,!!rlang::sym(col_keys) := dplyr::row_number()
				) %>%
				as.data.frame()
		}
	} else {
		#500. Convert it into the requested value
		tmp_N <- do.call(
			dict_dates[[dict_attr[['itype']]]][['func']]
			,modifyList(list('indate' = df_N), dict_dates[[dict_attr[['itype']]]][['kw']])
		)

		#900. Standardize the internal data frame
		df_N <- data.frame(tmpval = tmp_N)
		names(df_N) <- col_calc
		df_N[[col_idxcol]] <- rep_len(1, shape_N[[1]])
		df_N[[col_idxrow]] <- seq_len(shape_N[[1]])
		df_N[[col_keys]] <- seq_len(shape_N[[1]])
	}

	#220. Ensure both inputs have the same index
	if (all(shape_M == shape_N)) {
		rownames(df_N) <- rownames(df_M)
	}

	#280. Return placeholder if [N] has zero length
	#After this step, there are only below pairs for the input values:
	#[1] M to 1 (where M has at least one element)
	#[2] M to N (where M.shape == N.shape, while M has more than one element)
	if ((!f_out_len) | (shape_N[[1]] == 0)) {
		df_rst <- df_M
		df_rst[[col_rst]] <- rep_len(NA, nrow(df_rst)) %>% as.numeric()
		return(h_rst(df_rst, col_rst))
	}

	#290. Calculate the incremental for [datetime] when [type] in [dt(second|minute|hour)] by calling this function in recursion
	if (dict_attr[['itype']] %in% c('dtt')) {
        #100. Conduct the calculation for [date] and [time] parts respectively
        #101. We ensure both inputs are [vectors]
		dtt_Mdate <- df_M %>% dplyr::pull(tidyselect::all_of(col_calc)) %>% lubridate::date()
		dtt_Mtime <- df_M %>% dplyr::pull(tidyselect::all_of(col_calc)) %>% h_cr_hms()
		dtt_Ndate <- df_N %>% dplyr::pull(tidyselect::all_of(col_calc)) %>% lubridate::date()
		dtt_Ntime <- df_N %>% dplyr::pull(tidyselect::all_of(col_calc)) %>% h_cr_hms()

		#110. Increment by [day]
		dtt_rst_date <- intck(
			interval = 'day'
			,date_bgn = dtt_Mdate
			,date_end = dtt_Ndate
			,daytype = daytype
			,cal = cal
			,kw_d = kw_d
			,kw_dt = kw_dt
			,kw_t = kw_t
			,kw_cal = kw_cal
		)

		#150. Increment by different scenarios of [time]
		dtt_ntvl <- gsub('^dt', '', dict_attr[['name']])
		dtt_rst_time <- intck(
			interval = dtt_ntvl
			,date_bgn = dtt_Mtime
			,date_end = dtt_Ntime
			,daytype = daytype
			,cal = cal
			,kw_d = kw_d
			,kw_dt = kw_dt
			,kw_t = kw_t
			,kw_cal = kw_cal
		)

		#500. Correction on incremental for [Work/Trade Days]
		if (daytype %in% c('W', 'T')) {
			#050. Define local variables
			dict_obsDates <- c('W' = 'isWorkDay', 'T' = 'isTradeDay')

            #100. Verify whether the input values are [Work/Trade Days]
            #130. Create separate identifiers for [M] and [N]
			dtt_obs_M <- do.call(
				ObsDates$new
				,modifyList(
					list(
						obsDate = dtt_Mdate
					)
					,kw_cal_fnl
				)
			)
			dtt_obs_N <- do.call(
				ObsDates$new
				,modifyList(
					list(
						obsDate = dtt_Ndate
					)
					,kw_cal_fnl
				)
			)

			#150. Re-shape the flags of [M] into comparable ones
			dtt_flag_M <- !dtt_obs_M[[dict_obsDates[[daytype]]]]

			#170. Re-shape the flags of [N] into comparable ones
			dtt_flag_N <- !dtt_obs_N[[dict_obsDates[[daytype]]]]

			#[IMPORTANT] Please keep the sequence of below steps, as [dtt_rst_date] is overwritten!
			#500. Correction by below conditions
			#[1] Incremental is 0 (other cases are handled in other steps)
			#[2] Both input dates are Public Holidays
			#510. Mark the records with both of below conditions
			dtt_mask_zero <- (dtt_rst_date == 0) & dtt_flag_M & dtt_flag_N
			dtt_mask_zero[is.na(dtt_mask_zero)] <- F

			#590. Set the above records as [np.nan] for good reason
			dtt_rst_date[dtt_mask_zero] <- NA

		    #700. Correct the [day] by -1, given difference as any number of [Calendar Days]
		    #710. Identify the correction on both sides
			dtt_d_corr <- dtt_rst_date
			dtt_mask_pos <- dtt_flag_N & (dtt_rst_date >= 0)
			dtt_mask_pos[is.na(dtt_mask_pos)] <- F
			dtt_mask_neg <- dtt_flag_M & (dtt_rst_date <= 0)
			dtt_mask_neg[is.na(dtt_mask_neg)] <- F
			dtt_d_corr[dtt_mask_pos] <- 1
			dtt_d_corr[dtt_mask_neg] <- -1
			dtt_d_corr[!( dtt_mask_pos | dtt_mask_neg )] <- 0

			#720. Only validate the correction when either [M] or [N] is Holiday
			dtt_mask <- dtt_flag_M | dtt_flag_N

			#790. Correct the result by their difference
			dtt_rst_date[dtt_mask] <- dtt_rst_date[dtt_mask] + dtt_d_corr[dtt_mask]
		}

		#700. Transform the [date] part into the same [span] as [time] part, and combine both
		dtt_rst <- df_M %>% dplyr::select(tidyselect::all_of(c(col_idxrow, col_idxcol)))

		#750. Combine the date and time parts
		dtt_srs_tmp <- dtt_rst_date * 86400 + dtt_rst_time

		#770. Divide the result by the span and multiple by the absolute values
		dtt_rst[[col_rst]] <- floor(abs(dtt_srs_tmp) / dict_attr[['span']] / dict_attr[['multiple']])

		#800. Negate the values where necessary
		mask_mul <- dtt_srs_tmp <= 0
		mask_mul[is.na(mask_mul)] <- F
		dtt_rst[mask_mul, col_rst] <- dtt_rst[mask_mul, col_rst] * (-1)

		#990. Return the final result
		return(h_rst(dtt_rst, col_rst))
	#End if [dtt]
	}

	#300. Create necessary columns
	#310. Unanimous columns
	if (dict_attr[['itype']] %in% c('t')) {
		df_M[[col_calc]] <- lubridate::today() + df_M[[col_calc]]
		df_N[[col_calc]] <- lubridate::today() + df_N[[col_calc]]
	}

	#320. Create [col_merge] as well as the bounds of the calendar
	if (dict_attr[['itype']] %in% c('d', 'dt')) {
		#100. Create new column
		if (dict_attr[['itype']] %in% c('d')) {
			df_M[[col_merge]] <- df_M[[col_calc]]
			df_N[[col_merge]] <- df_N[[col_calc]]
		} else {
			df_M[[col_merge]] <- lubridate::date(df_M[[col_calc]])
			df_N[[col_merge]] <- lubridate::date(df_N[[col_calc]])
		}

		#300. Concatenate the date values of both input values
		srs_indate <- c(
			df_M %>% dplyr::pull(tidyselect::all_of(col_merge))
			,df_N %>% dplyr::pull(tidyselect::all_of(col_merge))
		)

		#500. Define the bound of the calendar
		notnull_indate <- !is.na(srs_indate)
		if (!any(notnull_indate)) {
			#100. Assign the minimum size of calendar data if none of the input is a valid date
			cal_bgn <- lubridate::today()
			cal_end <- cal_bgn
		} else {
			#100. Retrieve the minimum and maximum values among the input values
			in_min <- min(srs_indate, na.rm = T)
			in_max <- max(srs_indate, na.rm = T)

			#500. Extend the period coverage by the provided span and multiple
			cal_bgn <- in_min + as.difftime(-15, units = 'days')
			cal_end <- in_max + as.difftime(15, units = 'days')
		}
	} else {
		#100. Create new column
		df_M[[col_merge]] <- df_M[[col_calc]]
		lubridate::second(df_M[[col_merge]]) <- floor(lubridate::second(df_M[[col_merge]]))
		df_N[[col_merge]] <- df_N[[col_calc]]
		lubridate::second(df_N[[col_merge]]) <- floor(lubridate::second(df_N[[col_merge]]))

		#300. Concatenate the date values of both input values
		srs_indate <- c(
			df_M %>% dplyr::pull(tidyselect::all_of(col_merge))
			,df_N %>% dplyr::pull(tidyselect::all_of(col_merge))
		)

		#500. Define the bound of the calendar
		notnull_indate <- !is.na(srs_indate)
		if (!any(notnull_indate)) {
			#100. Assign the minimum size of calendar data if none of the input is a valid date
			cal_bgn <- asDatetimes( lubridate::today() )
			cal_end <- cal_bgn
		} else {
			#100. Retrieve the minimum and maximum values among the input values
			in_min <- min(srs_indate, na.rm = T)
			in_max <- max(srs_indate, na.rm = T)

			#500. Extend the period coverage by the provided span and multiple
			cal_bgn <- in_min + as.difftime(-60, units = 'secs')
			cal_end <- in_max + as.difftime(60, units = 'secs')
		}
	}

	#380. [time] part for [type == dt]
	#There is no need to append [time] part for [dt], as we will only calculate the incremental by [day]

	#400. Prepare calendar data
	if (!vfy_cal) {
		intck_calfull <- intCalendar(
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
		intck_calfull <- cal %>% dplyr::arrange_at(tidyselect::all_of(col_out))
	}

	#700. Calculate the incremental
	#701. Determine the columns in the calendar to be used for calculation
	col_cal <- c(col_out, col_period, col_prdidx)
	by_var <- col_out
	names(by_var) <- col_merge

	#710. Create a subset of the requested data
	df_M_in <- df_M %>% dplyr::select(tidyselect::all_of(c(col_keys, col_merge)))
	df_N_in <- df_N %>% dplyr::select(tidyselect::all_of(c(col_keys, col_merge)))

	#720. Retrieve the corresponding columns from the calendar for non-empty dates
	df_M_in %<>%
		dplyr::left_join(
			intck_calfull %>% dplyr::select(tidyselect::all_of(col_cal))
			,by = by_var
		)

	df_N_in %<>%
		dplyr::left_join(
			intck_calfull %>% dplyr::select(tidyselect::all_of(col_cal))
			,by = by_var
		)

	#730. We extract the single value for [N] and leave the broadcasting to [dplyr]
	h_chg_N <- function(){
		if (f_Mto1) {
			#100. Prepare a [list]
			rst <- rlang::list2(
				!!col_period := df_N_in[1,col_period]
				,!!col_prdidx := df_N_in[1,col_prdidx]
			)

			#900. Return
			return(rst)
		} else {
			return(df_N_in)
		}
	}

	df_N_comp <- h_chg_N()

	#740. Direct subtraction
	#Scenarios:
	#[1] Index/rowname of [df_M_in] is the same as [df_N_in]
	#[2] [df_N_in] is a [list]
	col_intck <- col_period
	df_M_in[[col_rst]] <- df_N_comp[[col_intck]] - df_M_in[[col_intck]]

	#770. Apply [multiple] if any
	df_M_in[['.intckRst_wMul.']] <- abs(df_M_in[[col_rst]]) %/% dict_attr[['multiple']]
	mask_mul <- df_M_in[[col_rst]] <= 0
	mask_mul[is.na(mask_mul)] <- F
	df_M_in[mask_mul, '.intckRst_wMul.'] <- df_M_in[mask_mul, '.intckRst_wMul.'] * (-1)

	#790. Negate the incremental if the input values are switched
	if (f_switch) {
		df_M_in[['.intckRst_wMul.']] <- df_M_in[['.intckRst_wMul.']] * (-1)
	}

	#800. Transform the data backwards to the same as input
	#810. Merge the incremental back to the input data for later transformation
	col_dt <- c(col_keys, col_idxrow, col_idxcol)
	df_rst <- df_M %>% dplyr::select(tidyselect::all_of(col_dt))

	#[IMPORTANT] Till now the indexes of both data are exactly the same
	df_rst[[col_rst]] <- df_M_in[['.intckRst_wMul.']]

	#990. Output in terms of different request types
	return(h_rst(df_rst, col_rst))
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')
		if (nchar(Sys.getenv('TZ')) == 0) Sys.setenv(TZ = 'Asia/Shanghai')

		#050. Define helper function to extract [time] part from a datetime
		get_hms <- function(d){
			lubridate::hours(lubridate::hour(d)) +
			lubridate::minutes(lubridate::minute(d)) +
			lubridate::seconds(lubridate::second(d))
		}

		#100. Create dates for test
		d_anchor <- lubridate::today()
		dt_anchor <- lubridate::now()
		pair1_dt1 <- d_anchor
		pair1_dt2 <- d_anchor - as.difftime(3, units = 'days')
		pair2_dt1 <- asDates(c(pair1_dt1, pair1_dt2, pair1_dt1 - as.difftime(10, units = 'days')))
		pair2_dt2 <- asDates(c(pair1_dt2 - as.difftime(10, units = 'days'), pair1_dt1, pair1_dt2))
		pair3_dt1 <- pair2_dt1
		names(pair3_dt1) <- c(1,3,5)
		pair3_dt2 <- pair2_dt2
		names(pair3_dt2) <- c(2,4,6)
		pair4_dt1 <- data.frame(aa = pair3_dt1, bb = unname(pair3_dt2))
		rownames(pair4_dt1) <- names(pair3_dt1)
		pair4_dt2 <- data.frame(
			'c' = asDates(c(pair1_dt1 + as.difftime(5, units = 'days'), pair1_dt2 + as.difftime(5, units = 'days'), pair1_dt2))
			,'d' = asDates(c(pair1_dt2 - as.difftime(5, units = 'days'), pair1_dt1, pair1_dt1 - as.difftime(7, units = 'days')))
		)
		rownames(pair4_dt2) <- names(pair3_dt2)
		pair5_dt1 <- asTimes(c('14:53:28','04:44:56','20:06:49'))
		pair5_dt2 <- asTimes(c('10:13:42','08:25:40','18:09:32'))
		pair5_dt3 <- data.frame('c' = pair5_dt1, 'd' = pair5_dt2)
		rownames(pair5_dt3) <- names(pair3_dt2)
		pair6_dt1 <- pair2_dt1 + get_hms(dt_anchor)
		lubridate::tz(pair6_dt1) <- Sys.getenv('TZ')
		#Quote: https://stackoverflow.com/questions/19835662/generate-integer-random-numbers-from-range-01012
		pair6_dt2 <- pair2_dt2 + get_hms(dt_anchor) + as.difftime(ceiling(runif(length(pair2_dt2), 1, 100)), units = 'mins')
		lubridate::tz(pair6_dt2) <- Sys.getenv('TZ')
		pair6_dt3 <- pair6_dt1 + as.difftime(ceiling(runif(length(pair6_dt1), -1440, 1440)), units = 'mins')
		pair6_dt4 <- pair4_dt2
		pair6_dt4[['c']] <- pair6_dt4[['c']] + pair5_dt3[['c']]
		pair6_dt4[['d']] <- pair6_dt4[['d']] + pair5_dt3[['d']]

		t_now <- lubridate::now()
		t_end <- ObsDates$new(t_now)$nextWorkDay + asTimes('05:00:00')
		lubridate::tz(t_end) <- Sys.getenv('TZ')

		#200. Calculate the incremental between dates
		dt1_intck1 <- intck('day', pair1_dt1, pair1_dt2, daytype = 'w')
		dt1_intck2 <- intck('day', pair1_dt2, pair1_dt1, daytype = 't')
		dt2_intck1 <- intck('day3', pair2_dt1, pair2_dt2, daytype = 'w')
		dt2_intck2 <- intck('week', pair2_dt2, pair2_dt1, daytype = 't')
		dt2_intck3 <- intck('week', pair2_dt2, pair2_dt1, daytype = 'c')

		#210. Test the pairs of (M * 1)
		dt2_intck5 <- intck('day', pair1_dt1, pair2_dt2, daytype = 'w')

		#220. Test if either of the inputs is [named vector]
		dt3_intck1 <- intck('day', pair2_dt2, pair3_dt1, daytype = 'w')

		#230. Test if both of the inputs are [named vector] with different names
		dt3_intck3 <- intck('day', pair3_dt1, pair3_dt2, daytype = 'w')
		dt3_intck4 <- intck('day', pair3_dt2, pair3_dt1, daytype = 'w')

		#240. Test if either of the inputs is [table-like]
		dt4_intck1 <- intck('day', pair1_dt1, pair4_dt1, daytype = 't')
		dt4_intck2 <- intck('day3', pair4_dt2, pair1_dt1, daytype = 'c')

		#250. Test if both of the inputs are [table-like] with different row names
		dt4_intck3 <- intck('day', pair4_dt1, pair4_dt2, daytype = 'c')
		dt4_intck4 <- intck('day3', pair4_dt2, pair4_dt1, daytype = 'w')

		#260. Test the multiple on [dtt]
		diff_min5 <- intck('dtsecond300', t_now, t_end)
		t_chk <- intnx('dtsecond300', t_now, diff_min5)

		#300. Calculate the incremental between times
		dt5_intck1 <- intck('hour2', pair5_dt1, pair5_dt2)

		#310. Test if either of the inputs is [table-like]
		dt5_intck3 <- intck('hour2', pair5_dt3, dt_anchor)

		#400. Calculate the incremental between datetimes
		#410. Datetime with [interval] indicating [days]
		dt6_intck1 <- intck('day', pair6_dt1, pair6_dt2, daytype = 'w')

		#420. Datetime with [interval] indicating [dthours]
		dt6_intck3 <- intck('dthour', pair6_dt4, dt_anchor, daytype = 't')

		#500. Test special dates
		dt10_intck1 <- intck('month', '20210731', '20210730', daytype = 'w')
		dt10_intck2 <- intck('month', '20210801', '20210802', daytype = 'w')
		dt10_intck3 <- intck('week', '20211002', '20210927', daytype = 't')
		dt10_intck4 <- intck('day', '20211002', '20210930', daytype = 'w')
		dt10_intck5 <- intck('week', '20211003', '20211008', daytype = 't')
		dt10_intck6 <- intck('month', '20210925', '20210924', daytype = 'w')
		dt10_intck7 <- intck('weekday', '20211008', '20210930', daytype = 't')
		dt10_intck8 <- intck('weekday', '20211008', '20211011', daytype = 't')
		dt11_intck1 <- intck('dthour', '20210926 23:42:15', '20210924 17:42:15', daytype = 't')
		dt11_intck2 <- intck('dthour', '20210925 23:42:15', '20210927 05:42:15', daytype = 't')
		dt11_intck3 <- intck('dthour', '20210926 23:42:15', '20210926 17:42:15', daytype = 't')

		# [CPU] AMD Ryzen 5 5600 6-Core 3.70GHz
		# [RAM] 64GB 2400MHz
		#700. Test the timing of 2 * 100K dates
		dt7_smp1 <- pair4_dt1 %>% dplyr::slice_sample(n = 50000, replace = T)
		dt7_smp2 <- pair4_dt2 %>% dplyr::slice_sample(n = 50000, replace = T)

		t1 <- lubridate::now()
		dt7_intck1 <- intck('day2', dt7_smp1, dt7_smp2, daytype = 'w')
		t2 <- lubridate::now()
		print(t2 - t1)
		# 0.29s
		View(dt7_intck1)

		#800. Test the timing  of 2 * 100K datetimes
		dt8_smp1 <- pair6_dt4 %>% dplyr::slice_sample(n = 50000, replace = T)
		dt8_smp2 <- pair6_dt4[c('d','c')] %>% dplyr::slice_sample(n = 50000, replace = T)

		t1 <- lubridate::now()
		dt8_intck1 <- intck('dthour', dt8_smp1, dt8_smp2, daytype = 'w')
		t2 <- lubridate::now()
		print(t2 - t1)
		# 0.91s
		View(dt8_intck1)

		#900. Test special cases
		#910. [NULL] vs [NULL]
		print(intck('dthour', NULL, NULL, daytype = 'w'))
		#Return: numeric(0)

		#915. [NULL] vs [date]
		print(intck('dthour', d_anchor, NULL, daytype = 'w'))
		#Return: NA

		#917. [date] vs [NA]
		print(intck('day2', d_anchor, NA, daytype = 'w'))
		#Return: NA

		#940. Empty data frames
		emp1 <- pair4_dt1 %>% dplyr::select(-tidyselect::all_of(names(pair4_dt1)))
		emp2 <- pair4_dt2 %>% dplyr::select(-tidyselect::all_of(names(pair4_dt2)))
		emp3 <- pair6_dt4 %>% dplyr::filter(FALSE)
		emp4 <- pair6_dt4[c('d','c')] %>% dplyr::filter(FALSE)
		print(intck('dthour', emp1, emp2, daytype = 'c'))
		print(intck('dthour', emp2, emp1, daytype = 'c') %>% rownames())
		print(intck('dthour', emp3, emp4, daytype = 't'))
		print(intck('dthour', emp4, emp3, daytype = 't'))
		#Return: the same type as the [date_bgn] with no element

		#990. Test error cases
		if (FALSE) {
			#900. Non-empty values vs Empty tables
			intck('dthour', d_anchor, emp1, daytype = 'w')
			intck('dthour', emp3, d_anchor, daytype = 'w')
			#Error: different lengths
		}
	}
}
