#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This is to create daily KPI in standard format                                                                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Different KPIs may be stored in one <RData> file with different names                                                          #
#   |[2] Key fields are <D_TABLE>, <C_KPI_ID>, <A_KPI_VAL>, as well as all other fields that are Business Keys and Categories           #
#   |[3] As a standard practice, use upper case for all field names, as other factory functions such as <AdvDB$aggrByPeriod> will do    #
#   |     the upcase anyway to ensure correct aggregation upon necessary fields                                                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20250412        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |magrittr, dplyr, rlang, glue                                                                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvDB                                                                                                                          #
#   |   |   |DataIO                                                                                                                     #
#   |   |   |parseDatName                                                                                                               #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |isDF                                                                                                                       #
#   |   |   |get_values                                                                                                                 #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |Dates                                                                                                                          #
#   |   |   |asDates                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#

message('Create daily KPI')
#010. Local environment
L_srcflnm1 <- file.path(dir_data_src, 'CFG_KPI.RData')
#[ASSUMPTION]
#[1] Below setting indicates these KPIs are stored in the same file on the same date
kpi_this <- c('130100','140110')
dataIO$add('R')

#040. Load the data in current session
if (!isDF(get_values('cfg_kpi', inplace = F, mode = 'list'))) {
	cfg_kpi <- dataIO[['R']]$pull(L_srcflnm1, 'cfg_kpi')
}

message('100. Define helper functions')
#[ASSUMPTION]
#[1] Below values are only for demonstration, real cases are more complex
d_date <- asDates(L_curdate)

#110. Function to create the 1st KPI, same as all the rest ones
h_f_130100 <- function(){
	rstOut <- dplyr::bind_rows(
		list(
			'NC_CUST' = '0001'
			,'NC_ACCT' = '001010'
			,'C_RM' = 'a'
			,'C_BRANCH' = 'SH'
			,'A_KPI_VAL' = day(d_date) * 1.7
		)
		,list(
			'NC_CUST' = '0002'
			,'NC_ACCT' = '002010'
			,'C_RM' = 'b'
			,'C_BRANCH' = 'BJ'
			,'A_KPI_VAL' = (month(d_date) * 2.0 + day(d_date)) * 1.5
		)
	) %>%
		dplyr::mutate(
			!!rlang::sym('D_TABLE') := d_date
			,!!rlang::sym('C_KPI_ID') := '130100'
		)

	return(rstOut)
}

#120. Function to create the 2nd KPI
h_f_140110 <- function(){
	rstOut <- dplyr::bind_rows(
		list(
			'NC_CUST' = '0001'
			,'NC_ACCT' = '001010'
			,'C_RM' = 'b'
			,'C_BRANCH' = 'BJ'
			,'A_KPI_VAL' = day(d_date) * 0.9
		)
		,list(
			'NC_CUST' = '0002'
			,'NC_ACCT' = '002010'
			,'C_RM' = 'b'
			,'C_BRANCH' = 'BJ'
			,'A_KPI_VAL' = (month(d_date) * 0.9 + day(d_date) * 0.1) * 1.6
		)
	) %>%
		dplyr::mutate(
			!!rlang::sym('D_TABLE') := d_date
			,!!rlang::sym('C_KPI_ID') := '140110'
		)

	return(rstOut)
}

message('500. Function to collectively create KPIs in one batch')
h_genKPI <- function(kpi_id) {
	return(getFunction(glue::glue('h_f_{kpi_id}'))())
}

message('700. Create KPI data')
#710. Locate the captioned KPIs
cfg_this <- cfg_kpi %>%
	dplyr::filter(!!rlang::sym('C_KPI_ID') %in% kpi_this) %>%
	dplyr::filter(!!rlang::sym('D_BGN') <= d_date) %>%
	dplyr::filter(!!rlang::sym('D_END') >= d_date) %>%
	dplyr::filter(!!rlang::sym('F_KPI_INUSE') == 1) %>%
	dplyr::group_by_at(c('C_KPI_ID','C_LIB_NAME')) %>%
	dplyr::slice_min('N_LIB_PATH_SEQ') %>%
	dplyr::ungroup()

#[ASSUMPTION]
#[1] Below is a tedious way to do the slicing for the minimum <N_LIB_PATH_SEQ>
#[2] It demonstrates the usage of lambda call <{}()> with lazy-evaluated symbol
if (F){
	cfg_this <- cfg_kpi %>%
		dplyr::filter(!!rlang::sym('C_KPI_ID') %in% kpi_this) %>%
		dplyr::filter(!!rlang::sym('D_BGN') <= d_date) %>%
		dplyr::filter(!!rlang::sym('D_END') >= d_date) %>%
		dplyr::filter(!!rlang::sym('F_KPI_INUSE') == 1) %>%
		{. %>% dplyr::inner_join(
			#[ASSUMPTION]
			#[1] It is tested that the usage of <. %>% dplyr::group_by_at()> fails
			#[2] In other cases, such as <AdvDB$kfFunc_ts_fullmonth>, the usage of <.[cols] %>% dplyr::group_by_at()> succeeds
			#[3] Hence it is presumed that the dot <.> must be applied by some function directly (e.g. slicing on columns) from within
			#     the body of the lambda call <{}()>, when it is referenced as a lazy-evaluated symbol
			dplyr::group_by_at(., c('C_KPI_ID','C_LIB_NAME')) %>%
				dplyr::summarise_at('N_LIB_PATH_SEQ', min) %>%
				dplyr::ungroup()
			,by = c('C_KPI_ID','C_LIB_NAME')
			,suffix = c('', '.y')
			,copy = T
		)}() %>%
		dplyr::filter(!!rlang::sym('N_LIB_PATH_SEQ') == !!rlang::sym('N_LIB_PATH_SEQ.y')) %>%
		dplyr::select(-dplyr::ends_with('.y'))
}

#719. Raise if the output files of these KPIs are NOT the same one
if (length(cfg_this[['FilePath']] %>% toupper() %>% unique()) > 1) {
	stop(glue::glue('Captioned KPIs: {toString(kpi_this)} are in different output files and cannot be created in one batch!'))
}

#750. Execution
rst_this <- cfg_this[['C_KPI_ID']] %>%
	sapply(
		h_genKPI
		,simplify = F
		,USE.NAMES = T
	) %>%
	rlang::set_names(cfg_this[['DF_NAME']])

#780. Determine the output file
#[ASSUMPTION]
#[1] Options for <getOption> are defined in <autoexec>
rst_file <- rlang::exec(
	parseDatName
	,datPtn = cfg_this[['FilePath']] %>% head(1)
	,dates = L_curdate
	,outDTfmt = getOption('fmt.parseDates')
	,inRAM = F
	,dict_map = getOption('fmt.def.GTSFK')
	,!!!getOption('fmt.opt.def.GTSFK')
) %>%
	dplyr::pull('datPtn.Parsed')

#790. Create the folder for the process
if (!dir.exists(dirname(rst_file))) dir.create(dirname(rst_file), recursive = T)

message('999. Save the result to harddrive')
if (file.exists(rst_file)) rc <- file.remove(rst_file)
rc <- dataIO[['R']]$push(
	rst_this
	,outfile = rst_file
)
