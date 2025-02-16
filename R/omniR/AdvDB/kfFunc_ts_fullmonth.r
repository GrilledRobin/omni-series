#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to standardize the generation of KPI datasets by minimize the calculation effort and consumption of      #
#   | system resources                                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[TERMINOLOGY]                                                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Naming: <K>PI <F>actory <FUNC>tion for <T>ime <S>eries by <FULL> <MONTH> algorithm                                             #
#   |[2] It is primarily designed for scenarios where <genPHMul == True> on the last workday/tradeday of a month                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[FUNCTION]                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Further aggregate MTD KPIs to their Full Month aggregations, useful when the last workday/tradeday is NOT the last calendar day#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[SCENARIO]                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Calculate Full Month ANR of product holding balances along the time series, by recognizing the data on each weekend as the same#
#   |     as its previous workday, also leveraging the aggregation result on the last workday of the month                              #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
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
#   | Date |    20240319        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |magrittr, rlang, dplyr, tidyr, tidyselect, glue                                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |Dates                                                                                                                          #
#   |   |   |asDates                                                                                                                    #
#   |   |   |intnx                                                                                                                      #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |apply_MapVal                                                                                                               #
#   |   |   |isDF                                                                                                                       #
#   |   |   |match.arg.x                                                                                                                #
#   |   |   |ExpandSignature                                                                                                            #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvDB                                                                                                                          #
#   |   |   |DataIO                                                                                                                     #
#   |   |   |parseDatName                                                                                                               #
#   |   |   |DBuse_GetTimeSeriesForKpi                                                                                                  #
#   |   |   |kfFunc_ts_mtd                                                                                                              #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	magrittr, rlang, dplyr, tidyr, tidyselect, glue
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

#We should use the pipe operands supported by below package
library(magrittr)
#We should use the big-bang operand [!!!] supported by below package
library(rlang)

kfFunc_ts_fullmonth <- local({
#[ASSUMPTION]
#[1] By instantiation of below class, we resemble a <class decorator> in Python
deco <- ExpandSignature$new(kfFunc_ts_mtd, instance = 'eSig')
myfunc <- deco$wrap(function(
	...
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#020. Local environment
	dots <- rlang::list2(...)
	args_share <- list()
	eSig$vfyConflict(args_share)
	args_in <- eSig$updParams(args_share, dots)

	inDate <- eSig$getParam('inDate', args_in) %>% eval()
	inKPICfg <- eSig$getParam('inKPICfg', args_in) %>% eval()
	mapper <- eSig$getParam('mapper', args_in) %>% eval()
	.parallel <- eSig$getParam('.parallel', args_in) %>% eval()
	omniR.ini <- eSig$getParam('omniR.ini', args_in) %>% eval()
	cores <- eSig$getParam('cores', args_in) %>% eval()
	aggrVar <- eSig$getParam('aggrVar', args_in) %>% eval()
	byVar <- eSig$getParam('byVar', args_in) %>% eval()
	copyVar <- eSig$getParam('copyVar', args_in) %>% eval()
	tableVar <- eSig$getParam('tableVar', args_in) %>% eval()
	genPHMul <- eSig$getParam('genPHMul', args_in) %>% eval()
	calcInd <- eSig$getParam('calcInd', args_in) %>% eval()
	fDebug <- eSig$getParam('fDebug', args_in) %>% eval()
	fTrans <- eSig$getParam('fTrans', args_in) %>% eval()
	fTrans.opt <- eSig$getParam('fTrans.opt', args_in) %>% eval()
	outDTfmt <- eSig$getParam('outDTfmt', args_in) %>% eval()
	kw_d <- eSig$getParam('kw_d', args_in) %>% eval()
	kw_cal <- eSig$getParam('kw_cal', args_in) %>% eval()
	kw_DataIO <- eSig$getParam('kw_DataIO', args_in) %>% eval()

	if (!isDF(inKPICfg)) {
		stop(glue::glue('[{LfuncName}][inKPICfg] must be a data frame, provided <{toString(class(inKPICfg))}>!'))
	}
	if (!isDF(mapper)) {
		stop(glue::glue('[{LfuncName}][mapper] must be a data frame, provided <{toString(class(mapper))}>!'))
	}

	if (length(byVar)==0) stop('[',LfuncName,']','[byVar] is not provided!')
	byVar <- byVar %>% unlist() %>% toupper()
	if (length(aggrVar)==0) stop('[',LfuncName,']','[aggrVar] is not provided!')
	aggrVar <- aggrVar %>% unlist() %>% toupper()
	if (length(copyVar)==0) stop('[',LfuncName,']','[copyVar] is not provided!')
	copyVar <- copyVar %>% unlist() %>% toupper()

	if (!is.logical(genPHMul)) {
		message(
			'[',LfuncName,']','[genPHMul] is not provided as logical value.'
			,' Program resembles the data on Public Holidays by their respective Previous Workdays.'
		)
		genPHMul <- T
	}
	calcInd <- match.arg.x(
		calcInd
		,choices = formals(eSig$src)[['calcInd']]
		,arg.func = toupper
		,choices.func = toupper
	)
	if (!is.logical(fDebug)) fDebug <- F

	#020. Local environment
	#[ASSUMPTION]
	#[1] 20240306 <R==4.1.1> It is tested that big-bang operator in <rlang> substitutes the expression and suppressed
	#     evaluation of the provided formals (extracted by the function <formals>)
	#[2] Hence we have to evaluate the list of arguments before splicing them during the call of <rlang::exec>
	#[3] As a classic practice, use <do.call> instead to ensure the first-level evaluation of arguments
	# kw_d %<>% sapply(eval, simplify = F, USE.NAMES = T)
	if ('_ALL_' %in% copyVar) {
		keep_all_col <- T
	} else {
		keep_all_col <- F
	}
	hasKeys <- c('R')
	mapper_chain <- c('mapper_daily','mapper_mtd','mapper_fm')
	cfg_unique_row <- c('C_KPI_ID','N_LIB_PATH_SEQ')
	dateChk_d <- do.call(asDates, c(list(indate = inDate), kw_d))
	int_sfx <- '&kffmdate.'
	if (!int_sfx %in% names(fTrans)) {
		fTrans <- c(fTrans, rlang::list2(!!int_sfx := 'kffm_curr___'))
		if (!'kffm_curr___' %in% names(outDTfmt)) {
			outDTfmt <- c(outDTfmt, list('kffm_curr___' = '%Y%m%d'))
		}
	}
	if (genPHMul) {
		if (calcInd == 'T') {
			indMod <- calcInd
		} else {
			indMod <- 'W'
		}
		benchofMon <- intnx('month', dateChk_d, 0, 'e', daytype = indMod, kw_cal = kw_cal)
	} else {
		benchofMon <- intnx('month', dateChk_d, 0, 'e', daytype = calcInd, kw_cal = kw_cal)
	}
	#[ASSUMPTION]
	#[1] Last day of month is always indicated by <calcInd>
	lastCDofMon <- intnx('month', dateChk_d, 0, 'e', daytype = 'C', kw_cal = kw_cal)
	#[ASSUMPTION]
	#[1] We would redirect the MTD KPI data to RAM for calculation
	#[2] There is no literal <key> for any object in RAM, hence we should differ the objects by names
	cfg_unique_file <- c('C_LIB_PATH','C_KPI_FILE_NAME','C_KPI_FILE_TYPE')
	cfg_unique_key <- c(cfg_unique_file, 'DF_NAME')

	#Abort under certain conditions
	if (dateChk_d != benchofMon) {
		stop(glue::glue(
			'[{LfuncName}][inDate][{dateChk_d}] should be the last <{calcInd}> of a month,'
			,' i.e. [{benchofMon}]'
		))
	}

	#021. Instantiate the IO operator for data migration
	#[ASSUMPTION]
	#[1] We use separate IO tool for all internal process where necessary, to avoid unexpected result
	dataIO <- do.call(DataIO$new, kw_DataIO)
	dataIO_int <- do.call(DataIO$new, kw_DataIO)

	#099. Debug mode
	if (fDebug){
		message('[',LfuncName,']','Debug mode...')
		message('[',LfuncName,']','Parameters are listed as below:')
		#Quote: https://stackoverflow.com/questions/11885207/get-all-parameters-as-list
		args_in <- as.list(environment())
		args_names <- names(args_in)
		for (m in seq_along(args_in)) {
			message('[',LfuncName,']','Structure: [',args_names[[m]],']:')
			message('[',LfuncName,']','End of structure: [',args_names[[m]],']',str(args_in[[m]]))
		}
	}

	#100. Minimize the KPI config table for current process
	#101. Prepare function to join paths by recognizing the names in RAM
	safe_path <- function(fparent,fname) {
		psep <- '[\\\\/\\s]+'
		fname_int <- gsub(paste0('^', psep), '', fname)
		rstOut <- file.path(gsub(paste0(psep, '$'), '', fparent), fname_int)
		parent_empty <- nchar(fparent) == 0
		parent_empty[is.na(parent_empty)] <- T
		rstOut[parent_empty] <- fname_int[parent_empty]
		return(rstOut)
	}

	#110. Identify the full base
	cfg_kpi_pre <- inKPICfg %>%
		dplyr::filter(!!rlang::sym('D_BGN') <= dateChk_d) %>%
		dplyr::filter(!!rlang::sym('D_END') >= dateChk_d) %>%
		dplyr::filter(!!rlang::sym('F_KPI_INUSE') == 1) %>%
		dplyr::filter(!!rlang::sym('C_KPI_ID') %in% (mapper[mapper_chain] %>% stack() %>% dplyr::pull('values')))

	#130. Validate the KPIs involved in any chain
	#[ASSUMPTION]
	#[1] All KPIs along any chain must exist at the same time
	mapper_vld <- mapper %>%
		dplyr::filter(
			mapper %>%
				apply(c(1,2), function(x){x %in% cfg_kpi_pre[['C_KPI_ID']]}, simplify = T) %>%
				apply(1, all)
		)

	#150. Mutate the involved config table
	#[ASSUMPTION]
	#[1] We cannot upcase the paths, since <DBuse_GetTimeSeriesForKpi> is called to locate the file paths in their
	#     original character case, esp. for the sources residing in RAM
	cfg_kpi <- cfg_kpi_pre %>%
		dplyr::filter(!!rlang::sym('C_KPI_ID') %in% (mapper_vld[mapper_chain] %>% stack() %>% dplyr::pull('values'))) %>%
		dplyr::mutate(
			!!rlang::sym('C_KPI_FILE_NAME') := !!rlang::sym('C_KPI_FILE_NAME') %>% trimws()
			,!!rlang::sym('C_LIB_PATH') := !!rlang::sym('C_LIB_PATH') %>% tidyr::replace_na('') %>% trimws()
			,!!rlang::sym('C_KPI_FILE_TYPE') := !!rlang::sym('C_KPI_FILE_TYPE') %>% trimws()
			,!!rlang::sym('DF_NAME') := !!rlang::sym('DF_NAME') %>% tidyr::replace_na('dummy') %>% trimws()
			,!!rlang::sym('options') := !!rlang::sym('options') %>% tidyr::replace_na('list()')
		) %>%
		dplyr::mutate(
			!!rlang::sym('FilePath') := safe_path(!!rlang::sym('C_LIB_PATH'), !!rlang::sym('C_KPI_FILE_NAME'))
		)

	#160. Only validate the paths at top priority for all Full Month KPIs
	#[ASSUMPTION]
	#[1] These KPIs are only CREATED to the paths of their respective top priority, while not SEARCHED in this process
	cfg_kpi_fm_pre <- cfg_kpi %>%
		dplyr::filter(!!rlang::sym('C_KPI_ID') %in% mapper_vld[['mapper_fm']]) %>%
		{. %>% dplyr::inner_join(
			.[cfg_unique_row] %>%
				dplyr::arrange_at(cfg_unique_row) %>%
				dplyr::group_by_at('C_KPI_ID') %>%
				dplyr::slice_head(n = 1) %>%
				dplyr::ungroup()
			,by = cfg_unique_row
		)}()

	#170. Determine the unique paths for Full Month KPIs
	file_fm_unique <- cfg_kpi_fm_pre %>%
		dplyr::select(tidyselect::all_of(cfg_unique_file)) %>%
		dplyr::distinct() %>%
		dplyr::mutate(
			!!rlang::sym('df_i') := seq_along(!!rlang::sym(head(cfg_unique_file,1)))
		)

	#180. Determine the unique <keys> for Full Month KPIs
	key_fm_unique <- cfg_kpi_fm_pre %>%
		dplyr::select(tidyselect::all_of(cfg_unique_key)) %>%
		dplyr::distinct() %>%
		dplyr::group_by_at(cfg_unique_file) %>%
		dplyr::mutate(
			!!rlang::sym('key_i') := seq_along(!!rlang::sym(head(cfg_unique_key,1)))
		) %>%
		dplyr::ungroup()

	#190. Create config table for Full Month KPIs
	cfg_kpi_fm <- cfg_kpi_fm_pre %>%
		dplyr::inner_join(
			cfg_kpi_fm_pre %>%
				dplyr::select(tidyselect::all_of(cfg_unique_key)) %>%
				dplyr::distinct() %>%
				dplyr::arrange_at(cfg_unique_key) %>%
				dplyr::mutate(
					!!rlang::sym('out_unique') := seq_along(!!rlang::sym(head(cfg_unique_key,1)))
				)
			,by = cfg_unique_key
		) %>%
		dplyr::mutate(
			!!rlang::sym('kfts_org_path') := !!rlang::sym('C_LIB_PATH')
			,!!rlang::sym('kfts_org_file') := !!rlang::sym('C_KPI_FILE_NAME')
			,!!rlang::sym('kfts_org_type') := !!rlang::sym('C_KPI_FILE_TYPE')
			,!!rlang::sym('kfts_org_key') := !!rlang::sym('DF_NAME')
			,!!rlang::sym('kfts_org_opt') := !!rlang::sym('options')
			,!!rlang::sym('kfts_org_fullpath') := !!rlang::sym('FilePath')
		) %>%
		dplyr::inner_join(
			file_fm_unique
			,by = cfg_unique_file
		) %>%
		dplyr::inner_join(
			key_fm_unique
			,by = cfg_unique_key
		) %>%
		dplyr::mutate(
			!!rlang::sym('C_LIB_PATH') := ''
			,!!rlang::sym('C_KPI_FILE_NAME') := paste0(
				'kfts_'
				,!!rlang::sym('df_i')
				,'_'
				,!!rlang::sym('key_i')
				#[ASSUMPTION]
				#[1] Below string pattern must be able to translate as indicated in <fTrans>
				,'_',int_sfx
			)
			,!!rlang::sym('C_KPI_FILE_TYPE') := 'RAM'
			,!!rlang::sym('DF_NAME') := 'dummy'
			,!!rlang::sym('options') := 'list()'
		) %>%
		dplyr::mutate(
			!!rlang::sym('FilePath') := safe_path(!!rlang::sym('C_LIB_PATH'), !!rlang::sym('C_KPI_FILE_NAME'))
		)

	#500. Helper functions
	#520. Column filter during loading data
	h_keepVar <- function(.vars = c('C_KPI_ID',aggrVar,byVar,copyVar)){
		if (keep_all_col) {
			rlang::expr(tidyselect::everything())
		} else {
			substitute(tidyselect::matches(paste0('^(',paste0(.vars, collapse = '|'),')$'), ignore.case = T))
		}
	}

	#560. Function to only retrieve the empty table structure with 0 length on axis 0
	h_nullify <- function(df) {
		df %>% dplyr::slice_head(n = 0)
	}

	#570. Function to process a single output file name
	#[ASSUMPTION]
	#[1] This function is called by <mapply>, hence each of the input arguments represents 1 single element of a vector
	h_outkey <- function(v_type,v_key,v_rowid) {
		#009. Debug mode
		if (fDebug){
			if (v_type %in% hasKeys) {
				message(glue::glue('[{LfuncName}]Collect MTD KPI data frame for output key: <{v_key}>'))
			} else {
				message(glue::glue('[{LfuncName}]Collect MTD KPI data frame for dummy key'))
			}
		}

		#100. Subset the config table
		#110. Retrieve the mapper for current step
		mapper_load <- mapper %>%
			dplyr::inner_join(
				cfg_kpi_fm %>%
					dplyr::filter(!!rlang::sym('out_unique') == v_rowid) %>%
					dplyr::select_at('C_KPI_ID')
				,by = c('mapper_fm' = 'C_KPI_ID')
			)

		#150. Filter the KPI config table
		#[ASSUMPTION]
		#[1] We only need to load the MTD KPI data into RAM
		cfg_mtd <- cfg_kpi %>%
			dplyr::filter(!!rlang::sym('C_KPI_ID') %in% mapper_load[['mapper_mtd']])

		#170. Differ the mapping logic
		map_kpi_id <- mapper_load[['mapper_fm']] %>% as.list() %>% setNames(mapper_load[['mapper_mtd']])

		#179. Debug mode
		if (fDebug){
			message(glue::glue('[{LfuncName}]Directly map below MTD KPIs to Full Month ID:'))
			str(map_kpi_id)
		}

		#200. Define helper functions
		#210. Function to only retrieve the involved map-to KPIs right after loading the data
		h_to <- function(df) {
			df %>%
				dplyr::filter(!!rlang::sym('C_KPI_ID') %in% cfg_mtd[['C_KPI_ID']]) %>%
				dplyr::select(eval(h_keepVar()))
		}

		#300. Patch the behavior when loading data source
		kw_io <- kw_DataIO %>%
			modifyList(list(
				'argsPull' = dataIO$full %>% sapply(function(x){list('funcConv' = h_to)}, simplify = F, USE.NAMES = T)
			))

		#500. Prepare the common arguments for the data retrieval
		args_GTSFK <- list(
			'inKPICfg' = cfg_mtd
			,'dnDates' = dateChk_d
			,'ColRecDate' = 'D_RecDate'
			,'fImp.opt' = 'options'
			,'MergeProc' = 'SET'
			,'keyvar' = byVar
			,'SetAsBase' = 'k'
			,'fTrans' = fTrans
			,'fTrans.opt' = fTrans.opt
			,'outDTfmt' = outDTfmt
			,'.parallel' = .parallel
			,'omniR.ini' = omniR.ini
			,'cores' = cores
			,'fDebug' = fDebug
			,'miss_files' = 'G_miss_files'
			,'err_cols' = 'G_err_cols'
			,'values_fn' = function(...){sum(..., na.rm = T)}
			,'kw_DataIO' = kw_io
		)

		#700. Retrieve the data
		#[ASSUMPTION]
		#[1] We do not ignore the user warninggs at this step, since the data sources are designed to exist
		#[2] If none of the input data exists, below function raises exception, hence result can never be <None>
		#[3] We would verify the warnings later at abort the process, for the same reason as [1]
		rstPre <- do.call(DBuse_GetTimeSeriesForKpi, args_GTSFK)

		#790. Abort upon any warnings
		msgs <- character(0)
		vfyCol <- rstPre[['G_err_cols']]
		vfyMis <- rstPre[['G_miss_files']]
		if (!is.null(vfyCol)) {
			msgs %<>% c('unmatched column types')
			message(glue::glue('[{LfuncName}]Error column types:'))
			str(vfyCol)
		}
		if (!is.null(vfyMis)) {
			msgs %<>% c('missing source files')
			message(glue::glue('[{LfuncName}]Missing source data files:'))
			print(vfyMis[['C_KPI_FULL_PATH']])
		}
		if (length(msgs) > 0) {
			stop(glue::glue('[{LfuncName}]Process fails due to {paste(msgs, sep = " and ")}, please check above log!'))
		}

		#800. Mutate the result
		rstOut <- rstPre[['data']] %>%
			dplyr::select(-tidyselect::any_of('D_RecDate')) %>%
			dplyr::mutate(
				!!rlang::sym('C_KPI_ID') := apply_MapVal(
					!!rlang::sym('C_KPI_ID')
					,dict_map = map_kpi_id
					,preserve = F
					,fPartial = F
					,PRX = F
					,full.match = T
					,ignore.case = F
				)
			)
		if (tableVar %in% colnames(rstOut)) {
			rstOut %<>%
				dplyr::mutate(
					!!rlang::sym(tableVar) := asDates(dateChk_d)
				)
		}

		#999. Output
		return(rstOut)
	}

	#570. Function to process a single output file name
	h_outfile <- function(u_fpath,u_fname,u_ftype,u_opt) {
		#100. Register API
		dataIO$add(u_ftype)
		fmenv <- new.env()

		#200. Helper function to parse the file name
		parse_fname <- function(df, dates, outcol) {
			df %>%
				dplyr::inner_join(
					do.call(
						parseDatName
						,c(
							list(
								datPtn = df %>% dplyr::select('FilePath')
								,dates = dates
								,outDTfmt = outDTfmt
								,chkExist = F
								,dict_map = fTrans
							)
							,fTrans.opt
						)
					) %>%
						dplyr::select_at(c('FilePath','FilePath.Parsed')) %>%
						dplyr::rename(c('FilePath.Parsed') %>% setNames(outcol))
					,by = 'FilePath'
				)
		}

		#300. Load data as <chkDat> for all unique <key>s in current output file
		rstInt <- cfg_kpi_fm %>%
			dplyr::filter(!!rlang::sym('kfts_org_path') == u_fpath) %>%
			dplyr::filter(!!rlang::sym('kfts_org_file') == u_fname) %>%
			dplyr::mutate(
				!!rlang::sym('agg_df') := mapply(
					h_outkey
					,!!rlang::sym('C_KPI_FILE_TYPE')
					,!!rlang::sym('DF_NAME')
					,!!rlang::sym('out_unique')
					,SIMPLIFY = F
				)
			) %>%
			parse_fname(
				dates = dateChk_d
				,outcol = 'chkDat'
			) %>%
			parse_fname(
				dates = lastCDofMon
				,outcol = 'outDat'
			)

		#500. Determine the output file name
		#[ASSUMPTION]
		#[1] There is only one output file name at this step
		outfile <- do.call(
			parseDatName
			,c(
				list(
					datPtn = (
						rstInt %>%
							dplyr::distinct_at(c('kfts_org_path','kfts_org_file')) %>%
							dplyr::mutate(
								!!rlang::sym('FilePath') := safe_path(!!rlang::sym('kfts_org_path'), !!rlang::sym('kfts_org_file'))
							) %>%
							dplyr::select('FilePath')
					)
					,dates = lastCDofMon
					,outDTfmt = outDTfmt
					,chkExist = F
					,dict_map = fTrans
				)
				,fTrans.opt
			)
		) %>%
			dplyr::pull('FilePath.Parsed') %>%
			head(1)

		#509. Debug mode
		if (fDebug){
			message(glue::glue('[{LfuncName}]Dedicated Full Month file is: <{outfile}>'))
		}

		#600. Patch the behavior to write data
		if (u_ftype %in% hasKeys) {
			opt_ex <- rstInt[['kfts_org_opt']]
			if (is.character(opt_ex)) {
				opt_ex %<>% str2expression() %>% eval()
			}
			kw_patcher <- opt_ex
		} else {
			kw_patcher <- u_opt
			if (is.character(kw_patcher)) {
				kw_patcher %<>% str2expression() %>% eval()
			}

			#[ASSUMPTION]
			#[1] During the writing of SAS data file, we can only set encoding <GB2312> in Chinese locale
			if (u_ftype == 'SAS') {
				chk_enc <- kw_patcher[['encoding']]
				if (is.null(chk_enc)) chk_enc <- ''
				if (chk_enc %>% toupper() %>% startsWith('GB')) {
					kw_patcher %<>% modifyList(list('encoding' = 'GB2312'))
				}
			}
		}

		#700. Differ the process
		if (dateChk_d == lastCDofMon) {
			#009. Debug mode
			if (fDebug){
				message(glue::glue('[{LfuncName}]Directly convert MTD data to Full Month file'))
			}

			#900. Write the data
			rc <- do.call(
				dataIO[[u_ftype]]$push
				,c(
					list(
						indat = rstInt %>% dplyr::pull('agg_df') %>% setNames(rstInt[['kfts_org_key']])
						,outfile = outfile
					)
					,kw_patcher
				)
			)
		} else {
			#009. Debug mode
			if (fDebug){
				message(glue::glue('[{LfuncName}]Prepare MTD data as <chkDat>'))
			}

			#100. Create <chkDat>
			#110. Register API
			dataIO_int$add('RAM')

			#170. Helper function to loop the process
			h_pushRAM <- function(vv_key,vv_df,vv_out) {
				rc <- dataIO_int[['RAM']]$push(
					indat = rlang::list2(!!vv_key := vv_df)
					,outfile = vv_out
					,frame = fmenv
				)
			}

			#190. Write the data
			rc_chk <- mapply(
				h_pushRAM
				,rstInt[['DF_NAME']]
				,rstInt[['agg_df']]
				,rstInt[['chkDat']]
				,SIMPLIFY = F
			)

			#199. Assert the success
			if (fDebug){
				message(glue::glue('[{LfuncName}]Verify the success for creation of <chkDat>'))
				print(rstInt[['chkDat']])
			}
			if (!all(rc_chk == 0)) {
				stop(glue::glue('[{LfuncName}]Some of the <chkDat> data failed to be created!'))
			}

			#500. Call the standard process for calculation
			#509. Debug mode
			if (fDebug){
				message(glue::glue('[{LfuncName}]Create interim Full Month data in current frame'))
			}

			#510. Create mapper for current step
			mapper_DtoFM <- mapper %>%
				dplyr::filter(!!rlang::sym('mapper_fm') %in% rstInt[['C_KPI_ID']]) %>%
				dplyr::select(tidyselect::all_of(c('mapper_daily','mapper_fm'))) %>%
				dplyr::rename(c('mapper_fr' = 'mapper_daily', 'mapper_to' = 'mapper_fm'))

			#530. Patch the behavior when writing the data
			kw_io <- kw_DataIO %>%
				modifyList(list(
					'argsPush' = list('RAM' = list('frame' = fmenv))
				))

			#550. Prepare KPI config table
			cfg_out <- list(
				cfg_kpi %>%
					dplyr::filter(!!rlang::sym('C_KPI_ID') %in% mapper_DtoFM[['mapper_fr']]) %>%
					dplyr::mutate(
						!!rlang::sym('options') := !!rlang::sym('options') %>%
							lapply(function(x){
								if (is.character(x)) {
									x %>% str2expression() %>% eval()
								} else {
									x
								}
							})
					)
				,cfg_kpi_fm %>%
					dplyr::filter(!!rlang::sym('C_KPI_ID') %in% mapper_DtoFM[['mapper_to']]) %>%
					dplyr::mutate(
						!!rlang::sym('options') := !!rlang::sym('options') %>%
							lapply(function(x){list('frame' = fmenv)})
					)
			) %>%
				dplyr::bind_rows()

			#570. Prepare the modification upon the signature with Business requirement
			args_mtd_pre <- rlang::list2(
				'inDate' = lastCDofMon
				,'inKPICfg' = cfg_out
				,'mapper' = mapper_DtoFM
				,'aggrVar' = aggrVar
				,'byVar' = byVar
				,'copyVar' = copyVar
				,'tableVar' = tableVar
				,'fTrans' = fTrans
				,'outDTfmt' = outDTfmt
				,'kw_DataIO' = kw_io
			)
			args_mtd <- eSig$updParams(args_mtd_pre, args_in)

			#590. Call the process
			rc_int <- do.call(kfFunc_ts_mtd, args_mtd)

			#599. Assert the success
			if (fDebug){
				message(glue::glue('[{LfuncName}]Verify the success for creation of interim Full Month data'))
				print(rc_int)
			}
			if (!all(rc_int[['rc']] == 0)) {
				stop(glue::glue('[{LfuncName}]Some of the interim Full Month data failed to be created!'))
			}

			#900. Write the data via the dedicated API
			#909. Debug mode
			if (fDebug){
				message(glue::glue('[{LfuncName}]Write the data via the dedicated API'))
			}

			#990. Call the API
			#[ASSUMPTION]
			#[1] <outDat> is the NAME of a data frame in RAM of current session till this step
			#[2] The API may not be able to parse the name with specific enclosing environment
			#[3] Hence we have to retrieve the object it references BEFORE calling the API
			rc <- do.call(
				dataIO[[u_ftype]]$push
				,c(
					list(
						indat = rstInt %>%
							dplyr::pull('outDat') %>%
							lapply(function(x){fmenv[[x]]}) %>%
							setNames(rstInt[['kfts_org_key']])
						,outfile = outfile
					)
					,kw_patcher
				)
			)
		}

		#899. Remove the API to purge the RAM used
		dataIO$remove(u_ftype)

		#999. Output the result
		return(rlang::list2(!!outfile := rc))
	}

	#700. Execute the process
	#709. Verify the duplication of file type
	vfy_type <- cfg_kpi_fm[c('kfts_org_path','kfts_org_file','kfts_org_type')] %>%
		dplyr::distinct() %>%
		dplyr::mutate(
			!!rlang::sym('FilePath') := safe_path(!!rlang::sym('kfts_org_path'), !!rlang::sym('kfts_org_file'))
		) %>%
		dplyr::group_by_at('FilePath') %>%
		dplyr::summarise_at('kfts_org_type', ~dplyr::n()) %>%
		dplyr::ungroup() %>%
		dplyr::filter_at('kfts_org_type', ~. > 1)
	if (nrow(vfy_type) > 0) {
		msg_file <- vfy_type[['FilePath']] %>% paste0(collapse = ',')
		stop(glue::glue(
			'[{LfuncName}]Ambiguous <C_KPI_FILE_TYPE> for <{msg_file}>'
			,' Check <inKPICfg> for detailed <C_KPI_FILE_TYPE> of these file names.'
		))
	}

	#719. Verify the duplication of file API options
	vfy_opt <- cfg_kpi_fm %>%
		dplyr::filter(!!rlang::sym('kfts_org_type') %in% hasKeys) %>%
		dplyr::select(tidyselect::all_of(c('kfts_org_path','kfts_org_file','kfts_org_opt'))) %>%
		dplyr::distinct() %>%
		dplyr::mutate(
			!!rlang::sym('FilePath') := safe_path(!!rlang::sym('kfts_org_path'), !!rlang::sym('kfts_org_file'))
		) %>%
		dplyr::group_by_at('FilePath') %>%
		dplyr::summarise_at('kfts_org_opt', ~dplyr::n()) %>%
		dplyr::ungroup() %>%
		dplyr::filter_at('kfts_org_opt', ~. > 1)
	if (nrow(vfy_opt) > 0) {
		msg_file <- vfy_opt[['FilePath']] %>% paste0(collapse = ',')
		stop(glue::glue(
			'[{LfuncName}]Ambiguous <options> for <{msg_file}>'
			,' Check <inKPICfg> for detailed <options> of these file names.'
		))
	}

	#750. Execution
	rstOut <- cfg_kpi_fm[c('kfts_org_path','kfts_org_file','kfts_org_type','kfts_org_opt')] %>%
		dplyr::distinct() %>%
		dplyr::mutate(
			!!rlang::sym('rc_pre') := mapply(
				h_outfile
				,!!rlang::sym('kfts_org_path')
				,!!rlang::sym('kfts_org_file')
				,!!rlang::sym('kfts_org_type')
				,!!rlang::sym('kfts_org_opt')
				,SIMPLIFY = F
			)
		) %>%
		dplyr::mutate(
			!!rlang::sym('FilePath') := sapply(!!rlang::sym('rc_pre'), names, simplify = T)
			,!!rlang::sym('rc') := unlist(!!rlang::sym('rc_pre'))
		) %>%
		dplyr::rename(c('C_KPI_FILE_TYPE' = 'kfts_org_type')) %>%
		dplyr::select(tidyselect::all_of(c('FilePath','C_KPI_FILE_TYPE','rc')))

	#999. Validate the completion
	return(rstOut)
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
	G_d_rpt <- '20160429'
	bgn_kpi2 <- intnx('day', G_d_rpt, -1, daytype = 'w')
	G_d_out <- intnx('month', G_d_rpt, 0, 'e', daytype = 'c') %>% strftime('%Y%m%d')
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
		) %>%
		dplyr::mutate(
			!!rlang::sym('D_BGN') := asDates(
				ifelse(
					!!rlang::sym('C_KPI_SHORTNAME') %>% startsWith('kpi2')
					,bgn_kpi2
					,!!rlang::sym('D_BGN')
				)
				#[ASSUMPTION]
				#[1] <R == 4.1.1> <ifelse> removes the class of the vector, hence we need to provide correct origin for conversion
				,origin = lubridate::make_date(1970,1,1)
			)
		)

	#150. Mapper to indicate the aggregation
	#[ASSUMPTION]
	#[1] <D_BGN> of KPI <140111> is the same as <G_d_rpt>, hence its result only leverages daily KPI starting from <D_BGN>,
	#     regardless of whether the daily KPI data exists before that date
	map_dict <- matrix(
		data = c(
			'130100','130101','130109'
			,'140110','140111','140119'
		)
		,nrow = 2
		,ncol = 3
		,byrow = T
	)
	map_agg <- map_dict %>%
		as.data.frame() %>%
		setNames(c('mapper_daily','mapper_mtd','mapper_fm'))
	map_DtoFM <- map_agg[['mapper_fm']] %>% as.list() %>% setNames(map_agg[['mapper_daily']])

	#300. Call the factory to create Full Month ANR
	#310. Prepare arguments for MTD ANR
	args_ts_mtd <- rlang::list2(
		'inKPICfg' = cfg_kpi
		,'mapper' = map_agg %>% dplyr::rename(c('mapper_fr' = 'mapper_daily', 'mapper_to' = 'mapper_mtd'))
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

	#330. Prepare MTD ANR for all required workdays, literally from the beginning of <kpi2>
	#[ASSUMPTION]
	#[1] In such case that a KPI does not exist in all required days in a month, its initial MTD aggregation should exist
	#     for all subsequent daily aggregation processes, otherwise the result from <aggrByPeriod> is unexpected
	cln_init <- UserCalendar$new(bgn_kpi2, G_d_rpt)
	for (i in seq_len(cln_init$kWorkDay)) {
		d <- cln_init$d_AllWD[[i]]
		args_ts_init <- args_ts_mtd %>% modifyList(list('inDate' = d))
		time_bgn <- Sys.time()
		rst_init <- do.call(kfFunc_ts_mtd, args_ts_init)
		time_end <- Sys.time()
		print(time_end - time_bgn)
	}
	# Time difference of 3.974185 secs
	# Time difference of 3.546394 secs

	#350. Prepare arguments for Full Month ANR
	args_ts_fm <- args_ts_mtd %>%
		modifyList(list(
			'inDate' = G_d_rpt
			,'mapper' = map_agg
		))

	#350. Call the process
	time_bgn <- Sys.time()
	rst_fm <- do.call(kfFunc_ts_fullmonth, args_ts_fm)
	time_end <- Sys.time()
	print(time_end - time_bgn)
	# Time difference of 5.338406 secs

	#400. Verify the result
	#410. Retrieve the newly created data
	ptn_0 <- 'D:\\Temp\\agg{currdate}.RData'
	ptn_1 <- 'D:\\Temp\\fm_{currdate}.RData'
	file_kpi1 <- glue::glue(ptn_1, currdate = G_d_out)
	rst_kpi1 <- std_read_R(file_kpi1, 'kpi1') %>%
		dplyr::filter(!!rlang::sym('C_KPI_ID') == '130109')
	rst_kpi2 <- std_read_R(file_kpi1, 'kpi2') %>%
		dplyr::filter(!!rlang::sym('C_KPI_ID') == '140119')

	#420. Prepare unanimous arguments
	cln <- UserCalendar$new(
		intnx('month', G_d_rpt, 0, 'b', daytype = 'c')
		,intnx('month', G_d_rpt, 0, 'e', daytype = 'c')
	)
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
			,'dateEnd' = cln$d_AllCD %>% tail(1)
			,'byVar' = byvar_kpis
			,'outVar' = aggvar_kpis
		))
	man_kpi1 <- do.call(aggrByPeriod, args_agg_kpi1)[['data']] %>%
		dplyr::mutate(
			!!rlang::sym('C_KPI_ID') := apply_MapVal(!!rlang::sym('C_KPI_ID'), map_DtoFM)
			,!!rlang::sym('D_TABLE') := asDates(G_d_out)
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
			#[1] Since <D_BGN> is changed (see the data <cfg_agg>), we should only involve data file
			#     on two dates for identical calculation
			,'dateBgn' = bgn_kpi2
		))
	man_kpi2 <- do.call(aggrByPeriod, args_agg_kpi2)[['data']] %>%
		dplyr::mutate(
			!!rlang::sym('C_KPI_ID') := apply_MapVal(!!rlang::sym('C_KPI_ID'), map_DtoFM)
			,!!rlang::sym(aggvar_kpis) := !!rlang::sym(aggvar_kpis) * 3 / cln$kClnDay
		)

	#490. Assertion
	print(all.equal(rst_kpi1, man_kpi1, check.attributes = F, tolerance = 1e-4))
	# [1] TRUE
	print(all.equal(rst_kpi2, man_kpi2, check.attributes = F, tolerance = 1e-4))
	# [1] TRUE

	#600. Calculate MTD ANR for the next month, with its last workday the same as its last calendar day
	G_d_rpt2 <- intnx('month', G_d_rpt, 1, 'e', daytype = 'w') %>% strftime('%Y%m%d')
	G_d_out2 <- intnx('month', G_d_rpt2, 0, 'e', daytype = 'c') %>% strftime('%Y%m%d')
	args_ts_mtd2 <- args_ts_mtd %>%
		modifyList(list(
			'inDate' = G_d_rpt2
			#[ASSUMPTION]
			#[1] Check the log on whether the process leveraged the result on the previous workday
			,'fDebug' = T
		))

	#630. Prepare MTD ANR for the requested date
	time_bgn <- Sys.time()
	rst_mtd2 <- do.call(kfFunc_ts_mtd, args_ts_mtd2)
	time_end <- Sys.time()
	print(time_end - time_bgn)
	# Time difference of 5.334862 secs

	#650. Prepare arguments for Full Month ANR
	args_ts_fm2 <- args_ts_mtd2 %>%
		modifyList(list(
			'inDate' = G_d_rpt2
			,'mapper' = map_agg
		))

	#670. Call the process
	time_bgn <- Sys.time()
	rst_fm2 <- do.call(kfFunc_ts_fullmonth, args_ts_fm2)
	time_end <- Sys.time()
	print(time_end - time_bgn)

	#700. Verify the result for the next workday
	#710. Retrieve the newly created data
	file_kpi1_2 <- glue::glue(ptn_1, currdate = G_d_out2)
	rst_kpi1_2 <- std_read_R(file_kpi1_2, 'kpi1') %>%
		dplyr::filter(!!rlang::sym('C_KPI_ID') == '130109')
	rst_kpi2_2 <- std_read_R(file_kpi1_2, 'kpi2') %>%
		dplyr::filter(!!rlang::sym('C_KPI_ID') == '140119')

	#720. Prepare unanimous arguments
	cln2 <- UserCalendar$new( intnx('month', G_d_out2, 0, 'b', daytype = 'c'), G_d_out2 )

	#740. Calculate the ANR manually for <kpi1>
	args_agg_kpi1_2 <- args_agg_kpi1 %>%
		modifyList(list(
			'dateBgn' = cln2$d_AllCD[[1]]
			,'dateEnd' = G_d_out2
		))
	man_kpi1_2 <- do.call(aggrByPeriod, args_agg_kpi1_2)[['data']] %>%
		dplyr::mutate(
			!!rlang::sym('C_KPI_ID') := apply_MapVal(!!rlang::sym('C_KPI_ID'), map_DtoFM)
			,!!rlang::sym('D_TABLE') := asDates(G_d_rpt2)
		)

	#760. Calculate the ANR manually for <kpi2>
	args_agg_kpi2_2 <- args_agg_kpi1_2 %>%
		modifyList(list(
			'inDatPtn' = datptn_agg_kpi2
			,'fImp.opt' = agg_opt_kpi2
		))
	man_kpi2_2 <- do.call(aggrByPeriod, args_agg_kpi2_2)[['data']] %>%
		dplyr::mutate(
			!!rlang::sym('C_KPI_ID') := apply_MapVal(!!rlang::sym('C_KPI_ID'), map_DtoFM)
			,!!rlang::sym('D_TABLE') := asDates(G_d_rpt2)
		)

	#790. Assertion
	print(all.equal(rst_kpi1_2, man_kpi1_2, check.attributes = F, tolerance = 1e-4))
	# [1] TRUE
	print(all.equal(rst_kpi2_2, man_kpi2_2, check.attributes = F, tolerance = 1e-4))
	# [1] TRUE

	#900. Purge
	for (i in seq_len(cln_init$kWorkDay)) {
		d <- cln_init$d_AllWD[[i]]
		f <- glue::glue(ptn_0, currdate = d %>% strftime('%Y%m%d'))
		if (file.exists(f)) file.remove(f)
	}
	if (file.exists(glue::glue(ptn_0, currdate = G_d_rpt2))) file.remove(glue::glue(ptn_0, currdate = G_d_rpt2))
	if (file.exists(glue::glue(ptn_1, currdate = G_d_out))) file.remove(glue::glue(ptn_1, currdate = G_d_out))
	if (file.exists(glue::glue(ptn_1, currdate = G_d_out2))) file.remove(glue::glue(ptn_1, currdate = G_d_out2))
}
