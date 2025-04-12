#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This is to create Rolling-15-Day aggregation upon the captioned KPIs                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |ASSUMPTION                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Different aggregation process should be handled by separate scripts, e.g. <sum> and <mean> should be conducted at different    #
#   |     steps; otherwise the configuration becomes too complicated                                                                    #
#   |[2] Since function <AdvDB.kfFunc_ts_roll> is introduced, there is no need to consider the split of process in terms of the storage #
#   |     file path, for this function handles such case internally                                                                     #
#   |[3] In most cases, one only has to specify the KPI mapping table and leaves the calculation to the standard function               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |CAVEAT                                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Right after <D_BGN> of a Daily KPI, its Rolling companion only takes data as of EXISTING dates within <k-1> days.              #
#   |    [1] For instance, 140112 in the demo on the date 20250415 is the average of 140110 on the dates 20250414 and 20250415 instead  #
#   |         of 15 days, 140112 in the demo on the date 20250415 is the average of 140110 on the dates 20250414 and 20250415 instead of#
#   |         15 days, regardless of whether there are any existing data files on other dates                                           #
#   |    [2] This is logical but maybe less readable                                                                                    #
#   |    [3] For most of Business cases, suggest using such rolling aggregation when all data process is between <D_BGN> and <D_END> of #
#   |         any provided Daily KPIs, e.g. in this demo start using 140112 from 20250428 which covers all 15 days from 20250414        #
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
#   |   |   |kfFunc_ts_roll                                                                                                             #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |isDF                                                                                                                       #
#   |   |   |get_values                                                                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#

message('Aggregate KPI using <mean> for Rolling-15-Day period')
#010. Local environment
L_srcflnm1 <- file.path(dir_data_src, 'CFG_KPI.RData')
L_stpflnm1 <- file.path(dir_data_db, 'Logger', glue::glue('rc_R15_mean{L_curdate}.RData'))
k_roll_days <- 15
dataIO$add('R')

#040. Load the data in current session
if (!isDF(get_values('cfg_kpi', inplace = F, mode = 'list'))) {
	cfg_kpi <- dataIO[['R']]$pull(L_srcflnm1, 'cfg_kpi')
}

message('100. Define mapper of KPIs [Daily] -> [Rolling-15-Day]')
#[ASSUMPTION]
#[1] Values in one row indicate the mapping in this order: Daily KPI -> Rolling-15-Day KPI
#[2] <columns> should be set as is, which is required by the factory
map_agg <- matrix(
	data = c(
		c('130100','130102')
		,c('140110','140112')
	)
	,ncol = 2
	,byrow = T
) %>%
	as.data.frame() %>%
	setNames(c('mapper_fr','mapper_to'))

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
rc_MkDir_R15 <- h_md_from_cfg(cfg_kpi, map_agg[['mapper_to']])

message('300. Prepare the modification upon the default arguments with current Business requirements')
#[ASSUMPTION]
#[1] The factory only leverages daily KPI starting from <D_BGN>, regardless of whether the daily KPI data exists before that date
#[2] E.g. if <140110> starts on <20250303> with initial value as 6, its <R15 mean> on <20250303> will be 6, even if there
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
args_ts_roll <- rlang::list2(
	'inKPICfg' = cfg_kpi
	,'mapper' = map_agg
	,'inDate' = L_curdate
	,'kDays' = k_roll_days
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

message('400. Conduct rolling calculation')
rc_R15 <- do.call(kfFunc_ts_roll, args_ts_roll)

message('999. Save the result to harddrive')
if (!dir.exists(dirname(L_stpflnm1))) dir.create(dirname(L_stpflnm1), recursive = T)

if (file.exists(L_stpflnm1)) rc <- file.remove(L_stpflnm1)
rc <- dataIO[['R']]$push(
	list(
		'rc_MkDir_R15' = rc_MkDir_R15
		,'rc_R15' = rc_R15
	)
	,outfile = L_stpflnm1
)
