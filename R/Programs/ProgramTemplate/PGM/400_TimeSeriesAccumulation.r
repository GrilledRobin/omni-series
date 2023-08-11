#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This script is to demonstrate the processes as below:                                                                              #
#   |[1] Prioritize retrieval of the data files with the same name in the same folders on different drives                              #
#   |[2] Concatenate the customer information files from different platforms (such as T1, T2, etc.)                                     #
#   |[3] Leverage KPI data structure for data retrieval                                                                                 #
#   |[4] Minimize the RAM usage by reading the least data files at the same time                                                        #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20230429        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230811        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <rlang::exec> to simplify the function call with spliced arguments in the examples                            #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |magrittr, dplyr, rlang, glue, stringr, lubridate                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvDB                                                                                                                    #
#   |   |   |parseDatName                                                                                                               #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$Dates                                                                                                                    #
#   |   |   |intnx                                                                                                                      #
#   |   |   |asDates                                                                                                                    #
#   |   |   |UserCalendar                                                                                                               #
#---------------------------------------------------------------------------------------------------------------------------------------#

logger.info('Accumulate the snapshot on time series')

#Identify the reporting date as the end of the previous month to current execution date
L_curdate <- intnx('month', G_obsDates$values, -1, 'e', daytype = 'w') %>% strftime('%Y%m%d')
L_srcflnm1 <- 'cust_T1_&L_curdate..sas7bdat'
L_srcflnm2 <- 'cust_T2_&L_curdate..sas7bdat'
L_srcflnm3 <- 'D:\\R\\omniR\\SampleKPI\\KPI\\K1\\cfg_kpi.sas7bdat'
L_srcflnm4 <- 'D:\\R\\omniR\\SampleKPI\\KPI\\K1\\cfg_lib.sas7bdat'
L_stpflnm1 <- file.path(dir_data_db, glue::glue('EverQ{L_curdate}.RData'))
key_hdf_cust <- 'MaxAUM_MonthEnd_cust'
key_hdf_acct <- 'MaxAUM_MonthEnd_acct'
bgn_Proj <- asDates('20160501')
cond_Q <- 800000.0
ex_env <- new.env()
#The sequence of drives in below list determines the priority to search for the same file name
drives <- paste0(c('D', 'E', 'F'), ':')
#Keys in below dicts should exist in the field [C_KPI_ID] of [L_srcflnm3]
map_pdtname <- list(
	'100100' = 'ProdA'
	,'100101' = 'ProdB'
)
map_pdttype <- list(
	'100100' = 'Type1'
	,'100101' = 'Type2'
)

logger.info('100. Import the KPI configuration')
cfg_kpi <- haven::read_sas(L_srcflnm3, encoding = 'GB2312') %>%
	dplyr::left_join(
		haven::read_sas(L_srcflnm4, encoding = 'GB2312')
		,by = 'C_KPI_DAT_LIB'
		,suffix = c('','.y')
	) %>%
	dplyr::mutate(
		!!rlang::sym('C_KPI_FILE_TYPE') := 'SAS'
		,!!rlang::sym('C_KPI_FILE_NAME') := paste0(!!rlang::sym('C_KPI_DAT_NAME'), '.sas7bdat')
	)

logger.info('300. Determine the calculation period')
#310. Prepare the pattern of the source data paths
#Below paths are from [main.r]
relPath_T1 <- dir_DM_T1 %>% splitDrive() %>% sapply('[[', 2)
relPath_T2 <- dir_DM_T2 %>% splitDrive() %>% sapply('[[', 2)
df_cust_ptn <- do.call(data.frame, rlang::list2(!!rlang::sym('drive') := drives, stringsAsFactors = F)) %>%
	dplyr::mutate(!!rlang::sym('priority') := dplyr::row_number()) %>%
	#Quote: https://stackoverflow.com/questions/10600060/how-to-do-cross-join-in-r
	dplyr::full_join(
		do.call(
			data.frame
			,rlang::list2(
				!!rlang::sym('relpath') := c(relPath_T1, relPath_T2)
				,!!rlang::sym('datname') := c(L_srcflnm1, L_srcflnm2)
				,stringsAsFactors = F
			)
		)
		,by = character(0)
	) %>%
	dplyr::mutate(
		!!rlang::sym('fullpath') := file.path(!!rlang::sym('drive'), !!rlang::sym('relpath'), !!rlang::sym('datname'))
	) %>%
	dplyr::select(-dplyr::any_of('drive'))

#350. Find all output data files and locate the latest one BEFORE current reporting date
ptn_dates <- '\\d{8}'
ptn_PM <- glue::glue('EverQ({ptn_dates}).RData')
parse_PM <- list.files(
	dir_data_db
	,pattern = ptn_PM
	,full.names = T
)
#Quote: https://stackoverflow.com/questions/49304142/sort-variable-according-to-multiple-regex-substrings
all_PM_dates <- stringr::str_extract(parse_PM, ptn_PM) %>%
	stringr::str_extract(ptn_dates)
filter_PM <- parse_PM[all_PM_dates < L_curdate]
filter_dates <- all_PM_dates[all_PM_dates < L_curdate]
all_PM_order <- order(filter_dates)
all_PM <- filter_PM[all_PM_order]

#370. Set the period beginning as the next working day to above data if it exists
if (length(all_PM) == 0) {
	output_PM <- NULL
	prd_bgn <- bgn_Proj
} else {
	output_PM <- all_PM[[length(all_PM)]]
	prd_bgn <- intnx('day', max(filter_dates), 1, daytype = 'w')
}

#390. Define the dates to retrieve all time series files
L_clndr <- UserCalendar$new( clnBgn = prd_bgn, clnEnd = L_curdate )

logger.info('500. Calculate maximum AUM on daily basis')
#510. Locate all source data files
#Below options are from [autoexec.r]
parse_data <- rlang::exec(
	parseDatName
	,datPtn = df_cust_ptn
	,parseCol = 'fullpath'
	,dates = L_clndr$LastWDofMon
	,outDTfmt = getOption('fmt.parseDates')
	,inRAM = F
	,chkExist = T
	,dict_map = getOption('fmt.def.GTSFK')
	,!!!getOption('fmt.opt.def.GTSFK')
)

#520. Filter the locations in terms of the priority of harddrives
loop_data <- parse_data %>%
	dplyr::filter_at('fullpath.chkExist', ~.) %>%
	dplyr::arrange_at(c('relpath', 'datname', 'dates', 'priority')) %>%
	dplyr::group_by_at(c('relpath', 'datname', 'dates')) %>%
	dplyr::slice_head(n = 1) %>%
	dplyr::ungroup()

#530. Prepare the base of the calculation
if (!is.null(output_PM)) {
	db_env <- new.env()
	load(output_PM, envir = db_env)
	cust_maxAUM <- db_env$cust_maxAUM
	acct_maxAUM <- db_env$acct_maxAUM
	rm(db_env)
} else {
	cust_maxAUM <- do.call(
		data.frame
		,rlang::list2(
			!!rlang::sym('custID') := character(0)
			,!!rlang::sym('d_table') := lubridate::Date(0)
			,!!rlang::sym('a_aum') := numeric(0)
			,stringsAsFactors = F
		)
	)
	acct_maxAUM <- do.call(
		data.frame
		,rlang::list2(
			!!rlang::sym('custID') := character(0)
			,stringsAsFactors = F
		)
	)
}

#540. Prepare the helper function to loop the calculation
h_calc <- function(d, df_AUM = cust_MaxAUM, df_Prod = acct_MaxAUM){
	#001. Identify the source files on current date
	#[ASSUMPTION]
	#[1] Any among the source files could be missing on current date
	#[2] Columns may be different from different sources, hence we need to handle them respectively
	cfg_T1 <- loop_data %>%
		dplyr::filter_at('dates', ~. == d) %>%
		dplyr::filter_at('datname', ~. == L_srcflnm1)
	cfg_T2 <- loop_data %>%
		dplyr::filter_at('dates', ~. == d) %>%
		dplyr::filter_at('datname', ~. == L_srcflnm2)

	#100. Retrieve AUM from different platforms
	aum_T1 <- lapply(
		cfg_T1[['fullpath.Parsed']]
		,haven::read_sas
		,encoding = 'GB2312'
		,col_select = c('custID','a_aum')
	)

	#150. Helper function to handle the situation when a column may not exist in a time series
	procT2 <- function(f){
		#100. Determine whether to filter the input data by the possibly existing field
		df_model <- haven::read_sas(f, n_max = 0)
		if ('acct_type' %in% names(df_model)) accttype <- 'acct_type' else accttype <- NULL
		cols <- c('custID', 'a_aum', accttype)

		#500. Load the data with the possible filter
		df <- haven::read_sas(f, encoding = 'GB2312', col_select = cols)
		if (!is.null(accttype)){
			df %<>% dplyr::filter_at(accttype, ~. == 'N') %>% dplyr::select(-dplyr::any_of(accttype))
		}
		return(df)
	}

	#170. Load data from another platform
	aum_T2 <- lapply(
		cfg_T2[['fullpath.Parsed']]
		,procT2
	)

	#199. Combine the data
	aum_PFS <- c(aum_T1, aum_T2) %>%
		dplyr::bind_rows() %>%
		dplyr::group_by_at('custID') %>%
		dplyr::summarise_at('a_aum', sum, na.rm = T) %>%
		dplyr::ungroup() %>%
		dplyr::mutate(!!rlang::sym('d_table') := d)

	#300. Update the AUM history
	#310. [a10] New customers are to be added into the history
	#[ASSUMPTION]
	#[1] They have to be Qualified as a threshold to be registered
	aum_cust_add <- aum_PFS %>%
		dplyr::filter_at('custID', ~!(. %in% df_AUM[['custID']])) %>%
		dplyr::filter_at('a_aum', ~round(., 2) >= cond_Q)

	#350. [a20] AUM of existing customers are to be replaced with the larger one
	aum_cust_rep <- aum_PFS %>%
		dplyr::left_join(
			df_AUM %>% dplyr::select_at(c('custID','a_aum'))
			,by = 'custID'
			,suffix = c('','.y')
		) %>%
		dplyr::filter(round(!!rlang::sym('a_aum'), 2) > round(!!rlang::sym('a_aum.y'), 2))

	#370. Combine the customer list
	aum_upd <- dplyr::bind_rows(c(aum_cust_add, aum_cust_rep))

	#379. Directly return if this customer list is empty
	if (nrow(aum_upd) == 0) {
		return(list(df_AUM, df_Prod))
	}

	#390. Update the AUM database
	aum_hist <- df_AUM %>%
		dplyr::filter_at('custID', ~!(. %in% aum_upd[['custID']])) %>%
		dplyr::bind_rows(aum_upd)

	#500. Load the product balance for the customers to be updated
	#510. Prepare the customer base for the retireval
	cust_info <- aum_upd %>% dplyr::select_at('custID')

	#530. Prepare the modification upon the default arguments with current business requirements
	args_GTSFK <- modifyList(
		getOption('args.def.GTSFK')
		,list(
			'inKPICfg' = cfg_kpi
			,'InfDatCfg' = list(
				'InfDat' = 'cust_info'
				,'DatType' = 'RAM'
			)
			,'SingleInf' = TRUE
			,'dnDates' = d
			,'MergeProc' = 'SET'
			,'keyvar' = c('custID')
			,'SetAsBase' = 'i'
			,'KeepInfCol' = FALSE
			#Process in parallel for small number of small data files are MUCH SLOWER than sequential mode
			,'_parallel' = FALSE
		)
	)

	#550. Retrieve product balance
	#[ASSUMPTION]
	#[1] All column names including [custID] will be upcased by below function
	map_colnames <- c('custID' = 'CUSTID')
	bal_upd <- do.call(DBuse_GetTimeSeriesForKpi, args_GTSFK)[['data']] %>%
		#Quote: https://dplyr.tidyverse.org/reference/rename.html
		dplyr::rename(dplyr::any_of(map_colnames)) %>%
		dplyr::mutate(
			!!rlang::sym('ProdName') := apply_MapVal(!!rlang::sym('C_KPI_ID'), map_pdtname)
			,!!rlang::sym('ProdType') := apply_MapVal(!!rlang::sym('C_KPI_ID'), map_pdttype)
		)

	#700. Update the product balance history
	bal_hist <- df_Prod %>%
		dplyr::filter_at('custID', ~!(. %in% bal_upd[['custID']])) %>%
		dplyr::bind_rows(bal_upd)

	#999. Return the updated data
	return(list(aum_hist, bal_hist))
}

#570. Define the dates to loop over the period
loop_dates <- loop_data %>%
	dplyr::select_at('dates') %>%
	dplyr::distinct() %>%
	dplyr::arrange_all() %>%
	dplyr::pull()

#590. Loop the calculation
#[ASSUMPTION]
#[1] We avoid to load all Time Series data into RAM at the same time
#[2] Arguments [df_AUM] and [df_Prod] MUST be provided at each iteration, to validate the recursion
#[3] <for> statement removes the class of the iterator, hence we only loop the process by positions
for (i in seq_along(loop_dates)) {
	logger.info('Processing ', strftime(loop_dates[[i]], '%Y-%m-%d'))
	rst <- h_calc(loop_dates[[i]], df_AUM = cust_MaxAUM, df_Prod = acct_MaxAUM)
	cust_MaxAUM <- rst[[1]]
	acct_MaxAUM <- rst[[2]]
}

logger.info('999. Save the result to harddrive')
if (file.exists(L_stpflnm1)) file.remove(L_stpflnm1)
ex_env$cust_MaxAUM <- cust_MaxAUM
ex_env$acct_MaxAUM <- acct_MaxAUM
save(file = L_stpflnm1, envir = ex_env)
rm(ex_env)
