#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This is to create MTD aggregation upon the captioned KPIs                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Different aggregation process should be handled by separate scripts, e.g. <sum> and <mean> should be conducted at different    #
#   |     steps; otherwise the configuration becomes too complicated                                                                    #
#   |[2] Since function <AdvDB$kfFunc_ts_mtd> is introduced, there is no need to consider the split of process in terms of the storage  #
#   |     file path, for this function handles such case internally                                                                     #
#   |[3] In most cases, one only has to specify the KPI mapping table and leaves the calculation to the standard function               #
#   |[4] Full Month calculation only validates when Last Workday of a month is NOT the Last Calendar Day of it; if they are the same,   #
#   |     a copy of the MTD data is created as Full Month data                                                                          #
#   |[5] For many Business requirements, the Time Series analysis needs the result representing all calendar days in a month. For       #
#   |     instance, MTD Average Balance is not accurate for Revenue calculation, while Full Month Average Balance is the solution       #
#   |[6] Full Month aggregation only leverages on two data: MTD aggregation result on the Last Workday of a month, and the Daily KPI    #
#   |     data on the same workday. So please ensure both exist for this step                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |CAVEAT                                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] When a Daily KPI starts on a workday whose previous calendar day is NOT workday, its MTD companion MUST start later than it    #
#   |    [1] <AdvDB$kfFunc_ts_mtd> can only fabricate the <chkDat> on its previous workday using the data on current date, with a gap of#
#   |         several holidays between them                                                                                             #
#   |    [2] <AdvDB$aggrByPeriod> will try to fabricate data on all these holidays using the Daily KPI on that <previous workday>, which#
#   |         certainly fails if the Daily KPI also starts on current date, i.e. there is no data for Daily KPI on <previous workday>   #
#   |    [3] If the MTD companion starts on the next several workdays to current date, e.g. 20250415 for 140111, the fabrication in     #
#   |         <AdvDB$kfFunc_ts_mtd> will only use Daily KPI on 20250415 and ignore that on 20250414. This is a hallucination of the     #
#   |         function and an error during data management                                                                              #
#   |    [4] Solutions for such caveat could be two                                                                                     #
#   |        [1] Make a Daily KPI and its MTD companion start on a workday whose previous calendar day is also a workday, just like     #
#   |             130100 and 130101 in the demo (this is irrational as Business decisions are not dependent upon data requirement)      #
#   |        [2] Let the MTD aggregation start on the first workday of the NEXT month to the <D_BGN> of the Daily KPI, like 140110 and  #
#   |             140111 in the demo (which is easy to justify as there is no need to use the data of a partial Business month)         #
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
#   |   |   |kfFunc_ts_mtd                                                                                                              #
#   |   |   |kfFunc_ts_fullmonth                                                                                                        #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |isDF                                                                                                                       #
#   |   |   |get_values                                                                                                                 #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |Dates                                                                                                                          #
#   |   |   |intnx                                                                                                                      #
#---------------------------------------------------------------------------------------------------------------------------------------#

message('Aggregate KPI using <mean> on MTD basis')
#010. Local environment
L_srcflnm1 <- file.path(dir_data_src, 'CFG_KPI.RData')
L_stpflnm1 <- file.path(dir_data_db, 'Logger', glue::glue('rc_MTD_mean{L_curdate}.RData'))
dataIO$add('R')

#040. Load the data in current session
if (!isDF(get_values('cfg_kpi', inplace = F, mode = 'list'))) {
	cfg_kpi <- dataIO[['R']]$pull(L_srcflnm1, 'cfg_kpi')
}

message('100. Define mapper of KPIs [Daily] -> [MTD]')
#[ASSUMPTION]
#[1] Values in one row indicate the mapping in this order: Daily KPI -> MTD KPI -> Full Month KPI
#[2] <columns> should be set as is, which is required by the factory
#[3] If any chain has no requirement for Full Month calculation, e.g. MTD Max, just leave an empty string <''> for <mapper_fm>
map_agg <- matrix(
	data = c(
		c('130100','130101','130109')
		,c('140110','140111','140119')
	)
	,ncol = 3
	,byrow = T
) %>%
	as.data.frame() %>%
	setNames(c('mapper_daily','mapper_mtd','mapper_fm'))

message('200. Create the output folders for the factory')
#[ASSUMPTION]
#[1] The factory does not create the output folders
#[2] The factory always create the data file into <C_LIB_PATH> at top priority
#210. Helper function to create folder
h_mkdir <- function(path) {
	sapply(
		path
		,function(p) {
			if (!dir.exists(p)) return(dir.create(p, recursive = T))
			return(FALSE)
		}
		,simplify = T
		,USE.NAMES = T
	)
}

#130. Helper function to create folders
h_md_from_cfg <- function(cfg, select) {
	rstOut <- cfg %>%
		dplyr::filter(!!rlang::sym('C_KPI_ID') %in% select) %>%
		dplyr::group_by_at('C_LIB_NAME') %>%
		dplyr::slice_min('N_LIB_PATH_SEQ') %>%
		dplyr::ungroup() %>%
		#[ASSUMPTION]
		#[1] It is tested that the chain execution of a lambda call <{}()> without <rlang::quo()> can be done without a separate call
		#[2] See the difference against the demonstration in <110_create_Daily_KPI>
		{rlang::exec(
			parseDatName
			,datPtn = .
			,parseCol = 'FilePath'
			,dates = L_curdate
			,outDTfmt = getOption('fmt.parseDates')
			,inRAM = F
			,dict_map = getOption('fmt.def.GTSFK')
			,!!!getOption('fmt.opt.def.GTSFK')
		)} %>%
		dplyr::mutate(
			!!rlang::sym('dir_to_create_') := dirname(!!rlang::sym('FilePath.Parsed'))
		) %>%
		dplyr::select_at('dir_to_create_') %>%
		dplyr::distinct_all() %>%
		dplyr::mutate(
			!!rlang::sym('rc') := h_mkdir(!!rlang::sym('dir_to_create_'))
		)

	return(rstOut)
}

#150. Create the folders
rc_MkDir_MTD <- h_md_from_cfg(cfg_kpi, map_agg[['mapper_mtd']])
rc_MkDir_FM <- h_md_from_cfg(cfg_kpi, map_agg[['mapper_fm']])

message('300. Prepare the modification upon the default arguments with current Business requirements')
#[ASSUMPTION]
#[1] The factory only leverages daily KPI starting from <D_BGN>, regardless of whether the daily KPI data exists before that date
#[2] E.g. if <140110> starts on <20250303> with initial value as 6, its <MTD mean> on <20250303> will be 6/3 = 2, even if there
#     exists a data file on <20250301> and <20250302>
#[3] <.parallel> and <cores> are reserved for the scenario when ALL captioned Daily KPIs are stored in different files. Setting
#    <.parallel=TRUE> and provided sufficient <cores> under such scenario would raise the efficiency a lot
#[4] <byVar> is Business decision, usually contains Customer ID and Account ID. For details such as transaction KPIs, Transaction ID
#     can be involved; for lower details such as customer level flags, Account ID can be removed
#[5] <copyVar> ensures the table format consistent with Daily KPIs, while the respective values at the <last record> will be retained
#     to the output result for each <byVar> group
#[6] <genPHMul> and <calcInd> control the calculation on workday, tradeday or calendar day, see document for <AdvDB$aggrByPeriod>
#[7] <fTrans>, <fTrans_opt> and <outDTfmt> control the mapping for date placeholder translation, see <autoexec>. As a standard
#     process, they can be set as is with no necessary change
#[8] <fDebug> is useful when there is error or confusion on the calculation logic
args_ts_mtd <- rlang::list2(
	'inKPICfg' = cfg_kpi
	,'mapper' = map_agg %>% dplyr::rename(c('mapper_fr' = 'mapper_daily', 'mapper_to' = 'mapper_mtd'))
	,'inDate' = L_curdate
	,'.parallel' = F
	,'omniR.ini' = getOption('file.autoexec')
	,'cores' = 4
	,'aggrVar' = 'A_KPI_VAL'
	,'byVar' = c('NC_CUST','NC_ACCT')
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

message('400. Conduct MTD calculation')
rc_MTD <- do.call(kfFunc_ts_mtd, args_ts_mtd)

message('600. Determine whether to conduct Full Month calculation')
h_FM <- function() {
	#100. Skip if current date is not the last workday of a month
	monthEnd <- intnx('month', L_curdate, 0, 'e', daytype = 'w') %>% strftime('%Y%m%d')
	if (L_curdate != monthEnd) {
		message(glue::glue(
			'Current data date <{L_curdate}> is not the last workday <{monthEnd}> of this month. Skip full month aggregation.'
		))
		return(invisible(NULL))
	}

	#500. Prepare arguments for Full Month aggregation
	args_ts_fm <- args_ts_mtd %>%
		modifyList(list(
			'mapper' = map_agg %>%
				dplyr::mutate(
					!!rlang::sym('mapper_fm') := !!rlang::sym('mapper_fm') %>% tidyr::replace_na('')
				) %>%
				dplyr::filter(!!rlang::sym('mapper_fm') != '')
		))

	message('700. Conduct Full Month calculation')
	rc <- do.call(kfFunc_ts_fullmonth, args_ts_fm)

	return(rc)
}

rc_FM <- h_FM()

message('800. Collect the returncode')
rc_all <- list(
	'rc_MkDir_MTD' = rc_MkDir_MTD
	,'rc_MkDir_FM' = rc_MkDir_FM
	,'rc_MTD' = rc_MTD
) %>%
	modifyList(Filter(isDF, list('rc_FM' = rc_FM)))

message('999. Save the result to harddrive')
if (!dir.exists(dirname(L_stpflnm1))) dir.create(dirname(L_stpflnm1), recursive = T)

if (file.exists(L_stpflnm1)) rc <- file.remove(L_stpflnm1)
rc <- dataIO[['R']]$push(
	rc_all
	,outfile = L_stpflnm1
)
