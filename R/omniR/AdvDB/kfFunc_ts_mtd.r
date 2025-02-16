#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to standardize the generation of KPI datasets by minimize the calculation effort and consumption of      #
#   | system resources                                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[TERMINOLOGY]                                                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Naming: <K>PI <F>actory <FUNC>tion for <T>ime <S>eries by <M>onth-<T>o-<D>ate algorithm                                        #
#   |[2] It is a high level interface of <kfCore_ts_agg>, which tweaks the date variables to facilitate various scenarios               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[FUNCTION]                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Map the MTD aggregation of KPIs listed on the left side of <mapper> to those on the right side of it                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[SCENARIO]                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Calculate MTD ANR of product holding balances along the time series, by recognizing the data on each weekend as the same as    #
#   |     its previous workday, also leveraging the aggregation result on its previous workday                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |150.   Calculation period control                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inDate        :   The date to which to calculate the MTD aggregation from the first calendar day in the same month                 #
#   |                  [NULL            ] <Default> Function will raise error if it is NOT provided                                     #
#   |dateBgn       :   The same argument in the ancestor function, which is a placeholder in this one, superseded by <inDate> so it no  #
#   |                   longer takes effect                                                                                             #
#   |                   [IMPORTANT] We always have to define such argument if it is also in the ancestor function, and if we need to    #
#   |                   supersede it by another argument. This is because we do not know the <kind> of it in the ancestor and that it   #
#   |                   may be POSITIONAL_ONLY and prepend all other arguments in the expanded signature, in which case it takes the    #
#   |                   highest priority during the parameter input. We can solve this problem by defining a shared argument in this    #
#   |                   function with lower priority (i.e. to the right side of its superseding argument) and just do not use it in the #
#   |                   function body; then inject the fabricated one to the parameters passed to the call of the ancestor.             #
#   |                  [<see def.>      ] <Default> Calculated out of <inDate>                                                          #
#   |dateEnd       :   The same argument in the ancestor function, which is a placeholder in this one, superseded by <inDate> so it no  #
#   |                   longer takes effect                                                                                             #
#   |                  [<see def.>      ] <Default> Calculated out of <inDate>                                                          #
#   |chkBgn        :   The same argument in the ancestor function, which is a placeholder in this one, superseded by <inDate> so it no  #
#   |                   longer takes effect                                                                                             #
#   |                  [<see def.>      ] <Default> Calculated out of <inDate>                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |190.   Process control                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |...           :   Any other arguments to expand from its ancestor; see its official document                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<Anno>        :   See the return result from the ancestor function                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20240310        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20250214        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <ExpandSignature> to expand the signature with those of the ancestor functions for easy program design        #
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
#   |   |rlang, glue                                                                                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |ExpandSignature                                                                                                            #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |Dates                                                                                                                          #
#   |   |   |asDates                                                                                                                    #
#   |   |   |intnx                                                                                                                      #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvDB                                                                                                                          #
#   |   |   |kfCore_ts_agg                                                                                                              #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	rlang, glue
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

kfFunc_ts_mtd <- local({
#[ASSUMPTION]
#[1] By instantiation of below class, we resemble a <class decorator> in Python
deco <- ExpandSignature$new(kfCore_ts_agg, instance = 'eSig')
myfunc <- deco$wrap(function(
	inDate = NULL
	,dateBgn = NULL
	,dateEnd = NULL
	,chkBgn = NULL
	,...
) {
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#100. Get the formals of the core function
	dots <- rlang::list2(...)

	#300. Retrieve the necessary inputs
	#310. Reshape the raw input
	args_dummy <- list(
		'dateBgn' = NULL
		,'dateEnd' = NULL
		,'chkBgn' = NULL
	)
	eSig$vfyConflict(args_dummy)
	args_in <- eSig$updParams(args_dummy, dots)

	#330. Retrieve the environment from the reshaped input
	fDebug <- eSig$getParam('fDebug', args_in) %>% eval()
	kw_d <- eSig$getParam('kw_d', args_in) %>% eval()
	kw_cal <- eSig$getParam('kw_cal', args_in) %>% eval()

	#350. Ending date
	dateEnd_d <- do.call(asDates, c(list(indate = inDate), kw_d))

	#370. Beginning date
	#[ASSUMPTION]
	#[1] MTD aggregation always starts from the first calendar day of a month
	dtBgn <- intnx('month', dateEnd_d, 0, 'b', daytype = 'c', kw_cal = kw_cal)

	#400. Identify the shared arguments between this function and its ancestor functions
	args_share <- list(
		'dateBgn' = dtBgn
		,'dateEnd' = dateEnd_d
		,'chkBgn' = dtBgn
	)

	#900. Finalize the parameters
	args_fnl <- eSig$updParams(args_share, dots)

	#989. Debug mode
	if (fDebug){
		message(glue::glue('[{LfuncName}]Debug mode...'))
		message(glue::glue('[{LfuncName}]Tweaked parameters are listed as below:'))
		message(glue::glue('[{LfuncName}][dateBgn]=[{dtBgn}]'))
		message(glue::glue('[{LfuncName}][dateEnd]=[{dateEnd_d}]'))
		message(glue::glue('[{LfuncName}][chkBgn]=[{dtBgn}]'))
	}

	#999. Call the core function
	return(do.call(eSig$src, args_fnl))
})
return(myfunc)
})

#[Full Test Program;]
if (FALSE){
	#010. Load user defined functions
	dir_omniR <- 'D:\\R'
	source(file.path(dir_omniR,'autoexec.r'))

	safe_path <- function(fparent,fname) {
		psep <- '[\\\\/\\s]+'
		fname_int <- gsub(paste0('^', psep), '', fname)
		rstOut <- file.path(gsub(paste0(psep, '$'), '', fparent), fname_int)
		parent_empty <- nchar(fparent) == 0
		parent_empty[is.na(parent_empty)] <- T
		rstOut[parent_empty] <- fname_int[parent_empty]
		return(rstOut)
	}

	#100. Set parameters
	#[ASSUMPTION]
	#[1] Below date indicates the beginning of one KPI among those in the config table
	G_d_rpt <- '20160526'
	cfg_kpi_file <- file.path(dir_omniR, 'omniR', 'AdvDB', 'CFG_KPI_Example.xlsx')
	cfg_kpi <- openxlsx::readWorkbook(
		cfg_kpi_file
		,sheet = 'KPIConfig'
		,detectDates = T
	) %>%
		dplyr::mutate(
			!!rlang::sym('C_LIB_NAME') := !!rlang::sym('C_LIB_NAME') %>% tidyr::replace_na('')
		) %>%
		dplyr::left_join(
			openxlsx::readWorkbook(
				cfg_kpi_file
				,sheet = 'LibConfig'
			)
			,by = 'C_LIB_NAME'
		) %>%
		dplyr::mutate(
			!!rlang::sym('F_KPI_INUSE') := !!rlang::sym('F_KPI_INUSE') %>% as.integer()
			,!!rlang::sym('N_LIB_PATH_SEQ') := !!rlang::sym('N_LIB_PATH_SEQ') %>% tidyr::replace_na(0) %>% as.integer()
			,!!rlang::sym('C_LIB_PATH') := !!rlang::sym('C_LIB_PATH') %>% tidyr::replace_na('')
		)

	#150. Mapper to indicate the aggregation
	map_dict <- list(
		'130100' = '130101'
		,'140110' = '140111'
	)
	map_agg <- data.frame(
		'mapper_fr' = names(map_dict)
		,'mapper_to' = unlist(map_dict)
		,stringsAsFactors = F
	) %>%
		magrittr::set_rownames(seq_along(map_dict))

	#300. Call the factory to create MTD ANR
	#310. Prepare the modification upon the default arguments with current Business requirements
	args_ts_mtd <- rlang::list2(
		'inKPICfg' = cfg_kpi
		,'mapper' = map_agg
		,'inDate' = G_d_rpt
		,'.parallel' = F
		,'omniR.ini' = getOption('file.autoexec')
		,'cores' = 4
		,'aggrVar' = 'A_KPI_VAL'
		,'byVar' = c('nc_cifno','nc_acct_no')
		,'copyVar' = '_all_'
		,'genPHMul' = T
		,'calcInd' = 'C'
		,'funcAggr' = mean
		,'fDebug' = F
		,'fTrans' = getOption('fmt.def.GTSFK')
		,'fTrans.opt' = getOption('fmt.opt.def.GTSFK')
		,'outDTfmt' = getOption('fmt.parseDates')
		,'na.rm' = T
	)

	#350. Call the process
	time_bgn <- Sys.time()
	rst <- do.call(kfFunc_ts_mtd, args_ts_mtd)
	time_end <- Sys.time()
	print(time_end - time_bgn)
	# Time difference of 4.240244 secs

	#400. Verify the result
	#410. Retrieve the newly created data
	file_kpi1 <- glue::glue('D:\\Temp\\agg{G_d_rpt}.RData')
	rst_kpi1 <- std_read_R(file_kpi1, 'kpi1') %>%
		dplyr::filter(!!rlang::sym('C_KPI_ID') == '130101')
	rst_kpi2 <- get_values(glue::glue('kpi2agg_{G_d_rpt}'), mode = 'list', inplace = F) %>%
		dplyr::filter(!!rlang::sym('C_KPI_ID') == '140111')

	#420. Prepare unanimous arguments
	cln <- UserCalendar$new( intnx('month', G_d_rpt, 0, 'b', daytype = 'c'), G_d_rpt )
	byvar_kpis <- args_ts_mtd[['byVar']] %>% unlist() %>% unname() %>% c('C_KPI_ID')
	aggvar_kpis <- args_ts_mtd[['aggrVar']]

	#430. Modify the config table to adapt to <aggrByPeriod>
	cfg_agg <- cfg_kpi %>%
		dplyr::mutate(
			!!rlang::sym('FilePath') := safe_path(!!rlang::sym('C_LIB_PATH'), !!rlang::sym('C_KPI_FILE_NAME'))
			,!!rlang::sym('FileName') := !!rlang::sym('C_KPI_FILE_NAME')
			,!!rlang::sym('PathSeq') := !!rlang::sym('N_LIB_PATH_SEQ')
		)

	#440. Calculate the ANR manually for <kpi1>
	datptn_agg_kpi1 <- cfg_agg %>%
		dplyr::filter(!!rlang::sym('C_KPI_ID') == '130100')
	agg_opt_kpi1 <- datptn_agg_kpi1 %>%
		dplyr::pull('options') %>%
		tidyr::replace_na('') %>%
		unique() %>%
		dplyr::nth(1) %>%
		str2expression() %>%
		eval()
	args_agg_kpi1 <- args_ts_mtd %>%
		{.[(names(.) %in% formalArgs(aggrByPeriod)) | (names(.) %in% c('na.rm'))]} %>%
		modifyList(list(
			'inDatPtn' = datptn_agg_kpi1
			,'inDatType' = 'C_KPI_FILE_TYPE'
			,'in_df' = 'DF_NAME'
			,'fImp.opt' = agg_opt_kpi1
			,'dateBgn' = cln$d_AllCD[[1]]
			,'dateEnd' = G_d_rpt
			,'byVar' = byvar_kpis
			,'outVar' = aggvar_kpis
		))
	man_kpi1 <- do.call(aggrByPeriod, args_agg_kpi1)[['data']] %>%
		dplyr::mutate(
			!!rlang::sym('C_KPI_ID') := apply_MapVal(!!rlang::sym('C_KPI_ID'), map_dict)
		)

	#460. Calculate the ANR manually for <kpi2>
	datptn_agg_kpi2 <- cfg_agg %>%
		dplyr::filter(!!rlang::sym('C_KPI_ID') == '140110')
	agg_opt_kpi2 <- datptn_agg_kpi2 %>%
		dplyr::pull('options') %>%
		tidyr::replace_na('') %>%
		unique() %>%
		dplyr::nth(1) %>%
		str2expression() %>%
		eval()
	args_agg_kpi2 <- args_agg_kpi1 %>%
		modifyList(list(
			'inDatPtn' = datptn_agg_kpi2
			,'fImp.opt' = agg_opt_kpi2
			#[ASSUMPTION]
			#[1] Since <D_BGN> is set to the same as <G_d_rpt> (see the data <cfg_agg>), we should only involve data file
			#     on one date for identical calculation
			,'dateBgn' = G_d_rpt
		))
	man_kpi2 <- do.call(aggrByPeriod, args_agg_kpi2)[['data']] %>%
		dplyr::mutate(
			!!rlang::sym('C_KPI_ID') := apply_MapVal(!!rlang::sym('C_KPI_ID'), map_dict)
			,!!rlang::sym(aggvar_kpis) := !!rlang::sym(aggvar_kpis) / cln$kClnDay
		)

	#490. Assertion
	print(all.equal(rst_kpi1, man_kpi1, check.attributes = F, tolerance = 1e-4))
	# [1] TRUE
	print(all.equal(rst_kpi2, man_kpi2, check.attributes = F, tolerance = 1e-4))
	# [1] TRUE

	#600. Calculate MTD ANR for the next workday
	#[ASSUMPTION]
	#[1] Since <G_d_next> is later than <D_BGN> of <kpi2>, one should avoid calling the factory for <G_d_next> BEFORE the call
	#     to the factory for <G_d_rpt> is complete. i.e. the MTD calculation on the first data date should be ready
	G_d_next <- intnx('day', G_d_rpt, 1, daytype = 'w') %>% strftime('%Y%m%d')
	args_ts_mtd2 <- args_ts_mtd %>%
		modifyList(list(
			'inDate' = G_d_next
			#[ASSUMPTION]
			#[1] Check the log on whether the process leveraged the result on the previous workday
			,'fDebug' = T
		))

	#650. Call the process
	time_bgn <- Sys.time()
	rst2 <- do.call(kfFunc_ts_mtd, args_ts_mtd2)
	time_end <- Sys.time()
	print(time_end - time_bgn)
	# Time difference of 3.974745 secs

	#700. Verify the result for the next workday
	#710. Retrieve the newly created data
	file_kpi1_2 <- glue::glue('D:\\Temp\\agg{G_d_next}.RData')
	rst_kpi1_2 <- std_read_R(file_kpi1_2, 'kpi1') %>%
		dplyr::filter(!!rlang::sym('C_KPI_ID') == '130101')
	rst_kpi2_2 <- get_values(glue::glue('kpi2agg_{G_d_next}'), mode = 'list', inplace = F) %>%
		dplyr::filter(!!rlang::sym('C_KPI_ID') == '140111')

	#720. Prepare unanimous arguments
	cln2 <- UserCalendar$new( intnx('month', G_d_next, 0, 'b', daytype = 'c'), G_d_next )

	#740. Calculate the ANR manually for <kpi1>
	args_agg_kpi1_2 <- args_agg_kpi1 %>%
		modifyList(list(
			'dateBgn' = cln2$d_AllCD[[1]]
			,'dateEnd' = G_d_next
		))
	man_kpi1_2 <- do.call(aggrByPeriod, args_agg_kpi1_2)[['data']] %>%
		dplyr::mutate(
			!!rlang::sym('C_KPI_ID') := apply_MapVal(!!rlang::sym('C_KPI_ID'), map_dict)
		)

	#760. Calculate the ANR manually for <kpi2>
	args_agg_kpi2_2 <- args_agg_kpi1_2 %>%
		modifyList(list(
			'inDatPtn' = datptn_agg_kpi2
			,'fImp.opt' = agg_opt_kpi2
			,'dateBgn' = G_d_rpt
		))
	man_kpi2_2 <- do.call(aggrByPeriod, args_agg_kpi2_2)[['data']] %>%
		dplyr::mutate(
			!!rlang::sym('C_KPI_ID') := apply_MapVal(!!rlang::sym('C_KPI_ID'), map_dict)
			,!!rlang::sym(aggvar_kpis) := !!rlang::sym(aggvar_kpis) * 2 / cln2$kClnDay
		)

	#790. Assertion
	print(all.equal(rst_kpi1_2, man_kpi1_2, check.attributes = F, tolerance = 1e-4))
	# [1] TRUE
	print(all.equal(rst_kpi2_2, man_kpi2_2, check.attributes = F, tolerance = 1e-4))
	# [1] TRUE

	#900. Purge
	if (file.exists(file_kpi1)) file.remove(file_kpi1)
	if (file.exists(file_kpi1_2)) file.remove(file_kpi1_2)
}
