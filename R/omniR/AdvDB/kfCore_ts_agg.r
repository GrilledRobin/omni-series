#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to standardize the generation of KPI datasets by minimize the calculation effort and consumption of      #
#   | system resources                                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[TERMINOLOGY]                                                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Naming: <K>PI <F>actory <CORE> function to provide <T>ime <S>eries algorithms in terms of <AGG>regation methods                #
#   |[2] KPIs listed in the mapper (on both sides) MUST have been registered in <inKPICfg>                                              #
#   |[3] <D_BGN> of the aggregated KPI must be equal to or later than that of its corresponding Daily Snapshot KPI                      #
#   |[4] Since <aggrByPeriod> does not verify <D_BGN>, please ensure NO DATA EXISTS for the registered Daily Snapshot KPIs before their #
#   |     respective <D_BGN>; otherwise those existing datasets will be inadvertently involved during aggregation                       #
#   |[5] This function is the low level interface of calculation over the period during time series aggregation                         #
#   |[6] One can realize various aggregation algorithms by providing customized <dateBgn>, <dateEnd> and <chkBgn>, with the common      #
#   |     modifiers as <genPHMul>, <calcInd> and <funcAggr>. See high level interfaces <kfFunc_ts_*> for demonstration                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[FUNCTION]                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Map the various aggregation of KPIs listed on the left side of <mapper> to those on the right side of it                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[SCENARIO]                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Calculate MTD ANR of product holding balances along the time series, by recognizing the data on each weekend as the same as    #
#   |     its previous workday, also leveraging the aggregation result on its previous workday                                          #
#   |[2] Calculate rolling period MAX of product holding balances along the time series, for the similar case as above                  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |110.   Input dataset information                                                                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inKPICfg    :   The dataset that stores the full configuration of the KPI. It MUST contain below fields:                           #
#   |                |------------------------------------------------------------------------------------------------------------------#
#   |                |Column Name     |Nullable?  |Description                                                                          #
#   |                |----------------+-----------+-------------------------------------------------------------------------------------#
#   |                |D_BGN           |No         | Beginning date of the KPI data file existence                                       #
#   |                |D_END           |No         | Ending date of the KPI data file existence                                          #
#   |                |C_KPI_ID        |No         | KPI ID used as part of keys for mapping and aggregation                             #
#   |                |F_KPI_INUSE     |No         | Column of type <int> indicating whether the KPI is in use for current database, as  #
#   |                |                |           |  filter condition in the process                                                    #
#   |                |C_KPI_FILE_TYPE |No         | File type to determine the API for data I/O process, see <DataIO>                   #
#   |                |N_LIB_PATH_SEQ  |No         | Priority to determine the candidate paths when loading and writing data files, the  #
#   |                |                |           |  lesser the higher. E.g. 1 represents the primary path, 2 indicates the backup      #
#   |                |                |           |  location of historical data files                                                  #
#   |                |C_LIB_PATH      |Yes        | Candidate path to store the KPI data file. Used together with <N_LIB_PATH_SEQ>      #
#   |                |                |           | It can be empty for data type <RAM>                                                 #
#   |                |C_KPI_FILE_NAME |No         | Data file name, should be the same for all candidate paths                          #
#   |                |DF_NAME         |Yes        | For some cases, such as [inDatType=HDFS] there should be such an additional field   #
#   |                |                |           |  indicating the name of data.frame stored in the data file (i.e. container)         #
#   |                |                |           | It is required if [C_KPI_FILE_TYPE] on any record is similar to [HDFS]              #
#   |                |options         |Yes        | Literal string representation of <list> representing the options used for the API   #
#   |                |                |           |  when loading and writing data files, see <DataIO>                                  #
#   |                |----------------+-----------+-------------------------------------------------------------------------------------#
#   |                [--> IMPORTANT  <--] Program will translate several columns in below way as per requested by [fTrans], see local   #
#   |                                      variable [trans_var].                                                                        #
#   |                                     [1] [fTrans] is NOT provided: assume that the value in this field is a valid file path        #
#   |                                     [2] [fTrans] is provided a named list or vector: Translate the special strings in accordance  #
#   |                                           as data file names. in such case, names of the provided parameter are treated as strings#
#   |                                           to be replaced; while the values of the provided parameter are treated as variables in  #
#   |                                           the parent environment and are [get]ed for translation, e.g.:                           #
#   |                                         [1] ['&c_date.' = 'G_d_curr'  ] Current reporting/data date in SAS syntax [&c_date.] to be#
#   |                                               translated by the value of Python variable [G_d_curr] in the parent frame           #
#   |                |------------------------------------------------------------------------------------------------------------------#
#   |mapper      :   Mapper from Daily KPI ID to aggregated KPI ID as a dataset. It MUST contain below fields:                          #
#   |                |------------------------------------------------------------------------------------------------------------------#
#   |                |Column Name     |Nullable?  |Description                                                                          #
#   |                |----------------+-----------+-------------------------------------------------------------------------------------#
#   |                |mapper_fr       |No         | ID of (usually) Daily Snapshot KPI, in the same type as <C_KPI_ID> in <inKPICfg>    #
#   |                |mapper_to       |No         | ID of aggregated KPI, in the same type as <C_KPI_ID> in <inKPICfg>                  #
#   |                |----------------+-----------+-------------------------------------------------------------------------------------#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |120.   Naming pattern translation/mapping                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |fTrans      :   Named list/vector to translate strings within the configuration to resolve the actual data file name for process   #
#   |                [NULL            ] <Default> For time series process, please ensure this argument is manually defined, otherwise   #
#   |                                              the result is highly unexpected                                                      #
#   |fTrans.opt  :   Additional options for value translation on [fTrans], see document for [AdvOp$apply_MapVal]                        #
#   |                [list()          ] <Default> Use default options in [apply_MapVal]                                                 #
#   |                [<list>          ]           Use alternative options as provided by a list, see documents of [apply_MapVal]        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |130.   Multi-processing support                                                                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |.parallel   :   Whether to load the data files in [Parallel]; it is useful for lots of large files, but may be slow for small ones #
#   |                [False           ]  <Default> Load the data files sequentially                                                     #
#   |                [True            ]            Use multiple CPU cores to load the data files in parallel. When using this option,   #
#   |                                               please ensure correct environment is passed to <kw_DataIO> for API searching, given #
#   |                                               that RAM is the requested location for search                                       #
#   |cores       :   Number of system cores to read the data files in parallel                                                          #
#   |                [4               ] <Default> No need when [.parallel=False]                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |150.   Calculation period control                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |dateBgn     :   Beginning of the calculation period. It will be converted to [Date] by [Dates$asDates] internally, hence please    #
#   |                 follow the syntax of this function during input                                                                   #
#   |                [NULL            ] <Default> Function will raise error if it is NOT provided                                       #
#   |dateEnd     :   Ending of the calculation period. It will be converted to [Date] by [Dates$asDates] internally, hence please       #
#   |                 follow the syntax of this function during input                                                                   #
#   |                [NULL            ] <Default> Function will raise error if it is NOT provided                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |160.   Retrieval of previously aggregated result for Checking Period                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |chkBgn      :   Beginning of the Checking Period. It will be converted to [Date] by [Dates$asDates] internally, hence please       #
#   |                 follow the syntax of this function during input                                                                   #
#   |                [NULL            ] <Default> Function will set it the same as [dateBgn]                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |170.   Column inclusion                                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |byVar       :   The list/vector of column names that are to be used as the group to aggregate the KPI                              #
#   |                [NULL            ] <Default> Function will raise error if it is NOT provided                                       #
#   |                [list[col. name] ]           <list> of column names                                                                #
#   |copyVar     :   The list/vector of column names that are to be copied during the aggregation                                       #
#   |                [Note 1] Only those values in the Last Existing observation/record can be copied to the output                     #
#   |                [NULL            ] <Default> There is no additional column to be retained for the output                           #
#   |                [_all_           ]           Retain all related columns from all sources                                           #
#   |                [list[col. name] ]           <list> of column names                                                                #
#   |aggrVar     :   The single column name in the KPI data file that represents the value to be applied by function [funcAggr]         #
#   |                [A_KPI_VAL       ] <Default> Function will aggregate this column                                                   #
#   |tableVar    :   The single column name in the KPI data file that represents the table creation date as Time Series Convention      #
#   |                [D_TABLE         ] <Default> Function will update this column with <dateEnd>                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |180.   Indicators and methods for aggregation                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |genPHMul    :   Whether to generate the data on Public Holidays by resembling their respective Previous Workdays/Tradedays with    #
#   |                 proper Multipliers, to minimize the system effort                                                                 #
#   |                [True            ] <Default> Resemble the data on Public Holidays with their respective Previous Workdays/Tradedays#
#   |                                             in terms of the indicator [calcInd]                                                   #
#   |                                             [IMPORTANT] Function will ignore any existing data on Public Holidays                 #
#   |                [False           ]           Function will NOT generate pseudo data for Public Holidays                            #
#   |                                             [IMPORTANT] Function will raise error if there is no existing data on Public Holidays #
#   |calcInd     :   The indicator for the function to calculate based on Calendar Days, Workdays or Tradedays                          #
#   |                [C               ] <Default> Conduct calculation based on Calendar Days                                            #
#   |                [W               ]           Conduct calculation based on Workdays. Namingly, [genPHMul] will hence take no effect #
#   |                [T               ]           Conduct calculation based on Tradedays. Namingly, [genPHMul] will hence take no effect#
#   |funcAggr    :   The function to aggregate the input time series data. It should be provided a [function]                           #
#   |                [IMPORTANT] All [NaN] values are excluded as they create meaningless results for all aggregation functions         #
#   |                [np.nanmean      ] <Default> Calculate the average of [aggrVar] per [byVar] as a time series, with NaN removed     #
#   |                [<other aggr.>   ]           Other aggregation functions that are supported in current environment                 #
#   |                                             [IMPORTANT] One can define specific aggregation function and use it here              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |190.   Process control                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |fDebug      :   The switch of Debug Mode. Valid values are [F] or [T].                                                             #
#   |                [False           ] <Default> Do not print debug messages during calculation                                        #
#   |                [True            ]           Print debug messages during calculation                                               #
#   |outDTfmt    :   Format of dates as string to be used for assigning values to the variables indicated in [fTrans]                   #
#   |                [ <list>         ] <Default> See the function definition as the default argument of usage                          #
#   |kw_d        :   Arguments for function [Dates$asDates] to convert the [indate] where necessary                                     #
#   |                [<see def.>      ] <Default> Use the default arguments for [asDates]                                               #
#   |kw_cal      :   Arguments for instantiating the class [Dates$UserCalendar] if [cal] is NOT provided                                #
#   |                [<see def.>      ] <Default> Use the default arguments for [UserCalendar]                                          #
#   |kw_DataIO   :   Arguments to instantiate <DataIO>                                                                                  #
#   |                [ empty-<list>   ] <Default> See the function definition as the default argument of usage                          #
#   |...         :   Any other arguments that are required by [funcAggr]. Please check the documents for it before defining this one    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[DataFrame] :   Data Frame indicating the process result with below columns:                                                       #
#   |                |------------------------------------------------------------------------------------------------------------------#
#   |                |Column Name     |Nullable?  |Description                                                                          #
#   |                |----------------+-----------+-------------------------------------------------------------------------------------#
#   |                |FilePath        |No         | Absolute path of the data files that are written by this process                    #
#   |                |                |           | When file type is <RAM>, it represents the object name in current session           #
#   |                |C_KPI_FILE_TYPE |No         | Same column retained from <inKPICfg>                                                #
#   |                |rc              |Yes        | Return code from the I/O, 0 indicates success, otherwise there are errors           #
#   |                |----------------+-----------+-------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20240310        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20250214        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed the bug when the config data has <options> and yet it cannot be parsed correctly                                  #
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
#   |   |   |UserCalendar                                                                                                               #
#   |   |   |ObsDates                                                                                                                   #
#   |   |   |intnx                                                                                                                      #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |apply_MapVal                                                                                                               #
#   |   |   |isDF                                                                                                                       #
#   |   |   |match.arg.x                                                                                                                #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvDB                                                                                                                          #
#   |   |   |DataIO                                                                                                                     #
#   |   |   |parseDatName                                                                                                               #
#   |   |   |DBuse_GetTimeSeriesForKpi                                                                                                  #
#   |   |   |aggrByPeriod                                                                                                               #
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

kfCore_ts_agg <- function(
	inKPICfg = NULL
	,mapper = NULL
	,dateBgn = NULL
	,dateEnd = NULL
	,chkBgn = NULL
	,.parallel = F
	,omniR.ini = getOption('file.autoexec')
	,cores = 4
	,aggrVar = 'A_KPI_VAL'
	,byVar = NULL
	,copyVar = NULL
	,tableVar = 'D_TABLE'
	,genPHMul = TRUE
	,calcInd = c('C','W','T')
	,funcAggr = mean
	,fDebug = FALSE
	,fTrans = NULL
	,fTrans.opt = NULL
	,outDTfmt = list(
		'L_d_curr' = '%Y%m%d'
		,'L_m_curr' = '%Y%m'
	)
	,kw_d = formals(asDates)[!(names(formals(asDates)) %in% c('indate'))]
	,kw_cal = formals(UserCalendar$public_methods$initialize)[
		!(names(formals(UserCalendar$public_methods$initialize)) %in% c('dateBgn', 'dateEnd', 'clnBgn', 'clnEnd'))
	]
	,kw_DataIO = as.list(formals(DataIO$public_methods$initialize))
	,...
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
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
	calcInd <- match.arg.x(calcInd, arg.func = toupper)
	if (!is.logical(fDebug)) fDebug <- F

	#020. Local environment
	#[ASSUMPTION]
	#[1] 20240306 <R==4.1.1> It is tested that big-bang operator in <rlang> substitutes the expression and suppressed
	#     evaluation of the provided formals (extracted by the function <formals>)
	#[2] Hence we have to evaluate the list of arguments before splicing them during the call of <rlang::exec>
	#[3] As a classic practice, use <do.call> instead to ensure the first-level evaluation of arguments
	# kw_d %<>% sapply(eval, simplify = F, USE.NAMES = T)
	kw <- rlang::list2(...)
	if ('_ALL_' %in% copyVar) {
		keep_all_col <- T
	} else {
		keep_all_col <- F
	}
	hasKeys <- c('R')
	byInt <- c(byVar,'C_KPI_ID')
	cfg_unique_row <- c('C_KPI_ID','N_LIB_PATH_SEQ')
	dateBgn_d <- do.call(asDates, c(list(indate = dateBgn), kw_d))
	dateEnd_d <- do.call(asDates, c(list(indate = dateEnd), kw_d))
	inObs <- do.call(ObsDates$new, c(list(obsDate = dateEnd_d), kw_cal))
	if (length(chkBgn) == 0) {
		if (fDebug) {
			message(glue::glue('[{LfuncName}]<chkBgn> is not provided, set it the same as <dateBgn>'))
		}
		chkBgn_d <- dateBgn_d
	} else {
		chkBgn_d <- do.call(asDates, c(list(indate = chkBgn), kw_d))
	}
	vfy_ci <- fTrans.opt[['ignore.case']]
	if (!is.logical(vfy_ci)) vfy_ci <- T
	if (!vfy_ci) {
		message(glue::glue(
			'[{LfuncName}]<fTrans.opt> indicates NOT to ignore case'
			,', which is omitted as the function capitalizes pathnames during aggregation'
		))
	}
	int_sfx <- '&kfcoredate.'
	if (!int_sfx %in% names(fTrans)) {
		fTrans <- c(fTrans, rlang::list2(!!int_sfx := 'core_curr___'))
		if (!'core_curr___' %in% names(outDTfmt)) {
			outDTfmt <- c(outDTfmt, list('core_curr___' = '%Y%m%d'))
		}
	}

	#021. Instantiate the IO operator for data migration
	#[ASSUMPTION]
	#[1] We use separate IO tool for all internal process where necessary, to avoid unexpected result
	dataIO <- do.call(DataIO$new, kw_DataIO)
	dataIO_int <- do.call(DataIO$new, kw_DataIO)

	#050. Determine <chkEnd> by the implication of <genPHMul>
	if (genPHMul) {
		if (calcInd == 'C') {
			indMod <- 'W'
		} else {
			indMod <- calcInd
		}
		chkEnd <- inObs$shiftDays(kshift = -1, preserve = F, daytype = indMod) %>% strftime('%Y%m%d')
	} else {
		chkEnd <- intnx('day', dateEnd_d, -1, daytype = 'C', kw_cal = kw_cal) %>% strftime('%Y%m%d')
	}

	#080. Get the formals of the core function
	params_arg <- formals(aggrByPeriod)
	kw_agg_raw <- params_arg[!names(params_arg) %in% c('...')]

	#085. Since the function takes variant keywords, we also identify them
	if ('...' %in% names(params_arg)) {
		kw_varkw <- kw[!names(kw) %in% names(kw_agg_raw)]
	} else {
		kw_varkw <- list()
	}

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

	#100. Prepare mappers
	mapper_dict <- mapper[['mapper_to']] %>% as.list() %>% setNames(mapper[['mapper_fr']])

	#109. Debug mode
	if (fDebug){
		message(glue::glue('[{LfuncName}]Mapping from Daily KPI to periodical aggregation KPI:'))
		message(str(mapper_dict))
	}

	#300. Minimize the KPI config table for current process
	#310. Prepare function to join paths by recognizing the names in RAM
	safe_path <- function(fparent,fname) {
		psep <- '[\\\\/\\s]+'
		fname_int <- gsub(paste0('^', psep), '', fname)
		rstOut <- file.path(gsub(paste0(psep, '$'), '', fparent), fname_int)
		parent_empty <- nchar(fparent) == 0
		parent_empty[is.na(parent_empty)] <- T
		rstOut[parent_empty] <- fname_int[parent_empty]
		return(rstOut)
	}

	#390. Mutation
	cfg_kpi <- inKPICfg %>%
		dplyr::filter(!!rlang::sym('D_BGN') <= dateEnd_d) %>%
		dplyr::filter(!!rlang::sym('D_END') >= dateEnd_d) %>%
		dplyr::filter(!!rlang::sym('F_KPI_INUSE') == 1) %>%
		dplyr::filter(!!rlang::sym('C_KPI_ID') %in% c(mapper_dict %>% names(), mapper_dict %>% unlist())) %>%
		dplyr::mutate(
			!!rlang::sym('C_KPI_FILE_NAME') := !!rlang::sym('C_KPI_FILE_NAME') %>% trimws() %>% toupper()
			,!!rlang::sym('C_LIB_PATH') := !!rlang::sym('C_LIB_PATH') %>% tidyr::replace_na('') %>% trimws() %>% toupper()
			,!!rlang::sym('C_KPI_FILE_TYPE') := !!rlang::sym('C_KPI_FILE_TYPE') %>% trimws()
			,!!rlang::sym('DF_NAME') := !!rlang::sym('DF_NAME') %>% tidyr::replace_na('dummy') %>% trimws()
			,!!rlang::sym('options') := !!rlang::sym('options') %>% tidyr::replace_na('list()')
		) %>%
		dplyr::mutate(
			!!rlang::sym('FilePath') := safe_path(!!rlang::sym('C_LIB_PATH'), !!rlang::sym('C_KPI_FILE_NAME'))
		)

	#400. Map the input data files to the output ones, for later process upon files instead of KPIs
	#[ASSUMPTION]
	#[1] If there are multiple candidate paths for any output KPI, e.g. A and B, these paths should also apply to other KPIs
	#     that are stored in the same data file
	#[2] If such case happens, we would do as below:
	#    [1] When determining the output location, we only choose A since it is of higher priority
	#    [2] When loading <chkDat>, we search in both locations and choose the one residing in A since it is also at higher
	#         priority, given the same file name shows up in both paths
	cfg_rst <- cfg_kpi %>%
		dplyr::filter(!!rlang::sym('C_KPI_ID') %in% (mapper_dict %>% unlist())) %>%
		dplyr::arrange_at(cfg_unique_row) %>%
		dplyr::group_by_at('C_KPI_ID') %>%
		dplyr::slice_head(n = 1) %>%
		dplyr::ungroup()

	#500. Helper functions
	#520. Column filter during loading data
	h_keepVar <- function(.vars = c(aggrVar,byVar,copyVar)){
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
	h_outkey <- function(v_type,v_key,v_path) {
		#009. Debug mode
		if (fDebug){
			if (v_type %in% hasKeys) {
				message(glue::glue('[{LfuncName}]Create interim data frame for output key: <{v_key}>'))
			} else {
				message(glue::glue('[{LfuncName}]Create interim data frame for dummy key'))
			}
		}

		#010. Initialize current iteration
		chkdat_pre <- NULL

		#100. Subset the config table
		#110. Config table for searching of the previous periodical result
		#[ASSUMPTION]
		#[1] In APIs such as <RAM>, character case matters during object reference
		#[2] This function ensures the output of the data file names (object names for <RAM>) the same character case as
		#     defined in <inKPICfg>
		#[3] Hence we also have to search for the object for Checking Period in the same character case
		cfg_prd <- cfg_kpi %>%
			dplyr::filter(!!rlang::sym('C_KPI_ID') %in% (
				cfg_rst %>%
					dplyr::filter(!!rlang::sym('FilePath') == v_path) %>%
					dplyr::filter(!!rlang::sym('DF_NAME') == v_key) %>%
					dplyr::pull('C_KPI_ID')
			)) %>%
			dplyr::select(-tidyselect::any_of(c('C_LIB_PATH','C_KPI_FILE_NAME'))) %>%
			dplyr::left_join(
				inKPICfg %>% dplyr::select(tidyselect::all_of(c(cfg_unique_row,'C_LIB_PATH','C_KPI_FILE_NAME')))
				,by = cfg_unique_row
			) %>%
			dplyr::mutate_at(c('C_LIB_PATH','C_KPI_FILE_NAME'), tidyr::replace_na, replace = '')

		#130. Config table for searching of the daily KPI when necessary
		cfg_daily <- cfg_kpi %>%
			dplyr::filter(!!rlang::sym('C_KPI_ID') %in% (
				cfg_prd %>%
					dplyr::inner_join(
						mapper[c('mapper_to','mapper_fr')]
						,by = c('C_KPI_ID' = 'mapper_to')
					) %>%
					dplyr::pull('mapper_fr')
			))

		#300. Prepare <chkDat> for standardized aggregation
		#310. Verify whether ALL of the output KPIs are introduced to database ON the requested date
		#[ASSUMPTION]
		#[1] If no, <chkDat> is designed to be created by this function and may already exist, allowing us to load it directly
		#    However, this function does not verify the existence of the corresponding daily KPIs if <chkDat> DOES NOT EXIST,
		#     hence, one must make sure these daily KPIs exist on the correct dates, see <aggrByPeriod>
		#[2] If yes, there is no history of the creation of these KPIs, we will create empty <chkDat> from scratch
		bgn_today <- cfg_prd[['D_BGN']] %>% magrittr::equals(dateEnd_d) %>% all()

		#350. Prepare the common arguments for the data retrieval
		args_GTSFK_cmn <- list(
			'fImp.opt' = 'options'
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
			,'values_fn' = function(...){sum(..., na.rm = T)}
		)

		#370. Differ the process
		#[ASSUMPTION]
		#[1] Create empty <chkDat> only when <chkBgn> == <dateBgn>, such as MTD calculation
		if (bgn_today & (dateBgn_d == chkBgn_d)) {
			#009. Debug mode
			if (fDebug){
				msg_kpi <- cfg_daily[['C_KPI_ID']] %>% paste0(collapse = ',')
				message(glue::glue('[{LfuncName}]Create empty <chkDat> out of Daily KPIs as <D_BGN> equals <dateEnd>: <{dateEnd_d}>'))
				message(glue::glue('[{LfuncName}]List of Daily KPIs to be directly translated: <{msg_kpi}>'))
			}

			#300. Patch the behavior when loading data source
			#[ASSUMPTION]
			#[1] Force all APIs to only load the data structure
			#[2] Ensure no data is loaded from SAS API, rather than nullify it after loading
			io_patcher <- dataIO$full %>%
				sapply(function(x){list('funcConv' = h_nullify)}, simplify = F, USE.NAMES = T) %>%
				modifyList(list('SAS' = list('n_max' = 0)))
			kw_io <- kw_DataIO %>%
				modifyList(list('argsPull' = io_patcher))

			#500. Prepare arguments for the data structure retrieval
			args_GTSFK <- c(
				list(
					'inKPICfg' = cfg_daily
					,'dnDates' = dateEnd_d
					,'kw_DataIO' = kw_io
				)
				,args_GTSFK_cmn
			)

			#700. Retrieve all involved <Daily KPIs>
			chkdat_pre <- do.call(DBuse_GetTimeSeriesForKpi, args_GTSFK)[['data']]
		} else {
			#009. Debug mode
			if (fDebug){
				msg_kpi <- cfg_prd[['C_KPI_ID']] %>% paste0(collapse = ',')
				message(glue::glue('[{LfuncName}]Time series is designed to exist, search for the previous result as <chkDat>'))
				message(glue::glue('[{LfuncName}]List of historical KPIs to be retrieved: <{msg_kpi}>'))
			}

			#200. Helper functions
			#210. Function to only retrieve the involved map-to KPIs right after loading the data
			h_to <- function(df) {
				df %>%
					dplyr::filter(!!rlang::sym('C_KPI_ID') %in% cfg_prd[['C_KPI_ID']]) %>%
					dplyr::select(eval(h_keepVar()))
			}

			#300. Patch the behavior when loading data source
			kw_io <- kw_DataIO %>%
				modifyList(list(
					'argsPull' = dataIO$full %>% sapply(function(x){list('funcConv' = h_to)}, simplify = F, USE.NAMES = T)
				))

			#500. Prepare arguments for the data retrieval
			args_GTSFK <- c(
				list(
					'inKPICfg' = cfg_prd
					,'dnDates' = chkEnd
					,'kw_DataIO' = kw_io
				)
				,args_GTSFK_cmn
			)

			#700. Retrieve all involved <map-to KPIs>
			#[ASSUMPTION]
			#[1] Below function issues user warning when none of the requested KPIs exists
			#[2] However, we allow this to happen for this function
			tryCatch(
				chkdat_pre <- do.call(DBuse_GetTimeSeriesForKpi, args_GTSFK)[['data']]
				,warning = function(w){invisible(w)}
			)

			#800. Reverse the mapping of KPI ID
			if (!is.null(chkdat_pre)) {
				chkdat_pre %<>%
					dplyr::mutate(
						!!rlang::sym('C_KPI_ID') := apply_MapVal(
							!!rlang::sym('C_KPI_ID')
							,dict_map = (mapper_dict %>% names() %>% as.list() %>% setNames(mapper_dict))
							,preserve = F
							,fPartial = F
							,PRX = F
							,full.match = T
							,ignore.case = F
						)
					)
			}
		}

		#500. Determine the loop for aggregation
		#[ASSUMPTION]
		#[1] Candidate paths of all involved KPIs MUST BE all the same, indicating they are created in the same process
		#[2] All other cases are treated as different pathss and hence result in unnecessary extra system effort
		#[3] If different KPIs are stored in different <key>s in the container such as <HDFS>, we should also differ the process,
		#     for <aggrByPeriod> can only process one <key> at a time
		#[4] The loop is hence determined by unique <FileName> + <key>, taking into account all their candidate paths during searching
		#[5] To adapt to the function <aggrByPeriod>, <options> for loading the same file MUST be the same in the candidate paths
		loop_agg <- cfg_daily %>%
			dplyr::select(tidyselect::all_of(c('C_KPI_FILE_NAME','DF_NAME','options'))) %>%
			dplyr::distinct()

		#591. Raise exception if there are ambiguous parameters for the same file
		if (nrow(loop_agg) != nrow(cfg_daily[c('C_KPI_FILE_NAME','DF_NAME')] %>% dplyr::distinct())) {
			msg_file <- cfg_daily[['C_KPI_FILE_NAME']] %>% paste0(collapse = ',')
			stop(glue::glue(
				'[{LfuncName}]Ambiguous <options> for <{msg_file}>'
				,' Check <inKPICfg> for details of these file names.'
			))
		}

		#700. Aggregation for time series per input data file name
		#709. Debug mode
		if (fDebug){
			message(glue::glue('[{LfuncName}]Aggregate Daily KPIs for output key: <{v_key}>'))
		}

		#710. Helper function to handle each input
		h_agg <- function(vv_fname,vv_key,vv_opt) {
			#010. Initialize current iteration
			dateBgn_fnl <- dateBgn_d
			chkBgn_fnl <- chkBgn_d
			chkdat_vfy <- chkdat_pre
			chkenv <- new.env()

			#100. Subset the config table for current iteration
			cfg_input <- cfg_daily %>%
				dplyr::filter(!!rlang::sym('C_KPI_FILE_NAME') == vv_fname) %>%
				dplyr::filter(!!rlang::sym('DF_NAME') == vv_key) %>%
				#[ASSUMPTION]
				#[1] <rename> is unsafe if the renamed columns already exist
				dplyr::mutate(
					!!rlang::sym('FileName') := !!rlang::sym('C_KPI_FILE_NAME')
					,!!rlang::sym('PathSeq') := !!rlang::sym('N_LIB_PATH_SEQ')
				)

			#105. Verify <chkBgn>
			#[ASSUMPTION]
			#[1] For aggregation with aligned <dateBgn> and <chkBgn>, no verification is needed
			#[2] For rolling period aggregation, <D_BGN> > <chkBgn> means that Daily KPI data file should exist
			#    [1] If a pseudo <chkDat> is created, <aggrByPeriod> searches for <Leading Period> based on the difference between
			#         <dateBgn> and <chkBgn>
			if (dateBgn_d != chkBgn_d) {
				#100. Verify whether all KPIs in this container have different <D_BGN>
				vfy_d_bgn <- cfg_input[c('C_KPI_ID','D_BGN')] %>%
					dplyr::distinct() %>%
					dplyr::group_by_at('C_KPI_ID') %>%
					dplyr::summarise_at('D_BGN', ~dplyr::n()) %>%
					dplyr::ungroup() %>%
					dplyr::filter_at('D_BGN', ~. > 1)
				if (nrow(vfy_d_bgn) > 0) {
					msg_kpi <- vfy_d_bgn[['C_KPI_ID']] %>% paste0(collapse = ',')
					stop(glue::glue(
						'[{LfuncName}]Different <D_BGN> found for KPIs: <{msg_kpi}>'
						,' They should be the same for rolling period aggregation!'
					))
				}
				.d_bgn <- cfg_input %>% dplyr::pull('D_BGN') %>% head(1)

				#500. Differ the process
				if (.d_bgn >= dateBgn_d) {
					#[ASSUMPTION]
					#[1] In such case, the calculation only covers the period starting from <D_BGN> of the involved KPI
					#[2] Hence <chkBgn> also starts on the same date
					#[3] There should not be <Leading Period> as well
					dateBgn_fnl <- .d_bgn
					chkBgn_fnl <- .d_bgn
				} else if (.d_bgn > chkBgn_d) {
					#[ASSUMPTION]
					#[1] In such case, there is no clue whether <Checking Period> is equal to <Request Period>
					#[2] We conduct the process without <chkDat> to simplify the logic
					#[3] Hence we set <chkDat> as nothing for good
					#[4] Example
					#    [1] KPI starts on 20160330
					#    [2] The rolling 5-day ANR has been calculated from 20160328 to 20160401, which follows the logic at higher
					#         priority as <dateBgn> is set to <D_BGN>
					#    [3] Now we have to calculate rolling 5-day ANR from 20160401 to 20160405, i.e. the next workday of 20160401
					#    [4] Literally we would leverage [2] as <chkDat>, but by the logic of <aggrByPeriod>, <Checking Period> covers
					#         3 workdays while <Request Period> covers 2 workdays; hence <chkDat> is not used
					chkdat_vfy <- NULL
				}
			}

			#109. Debug mode
			if (fDebug){
				msg_kpi <- cfg_input[['C_KPI_ID']] %>% unique() %>% paste0(collapse = ',')
				message(glue::glue('[{LfuncName}]KPIs to load: <{msg_kpi}>'))
				message(glue::glue('[{LfuncName}]From daily source file: <{vv_fname}>'))
			}

			#300. Only check the involved KPI during aggregation, to save system effort
			#310. Register temporary API
			dataIO_int$add('RAM')

			#350. Differ the process
			if (isDF(chkdat_vfy)) {
				if (fDebug){
					message(glue::glue('[{LfuncName}]Create pseudo <chkDat> <chk_kpi_pd{chkEnd}> for current input'))
				}
				rc <- dataIO_int[['RAM']]$push(
					indat = list(
						'tmp' = (
							chkdat_vfy %>%
								dplyr::filter(!!rlang::sym('C_KPI_ID') %in% cfg_input[['C_KPI_ID']]) %>%
								dplyr::select(-tidyselect::any_of(c('D_RecDate')))
						)
					)
					,outfile = paste0('chk_kpi_pd',chkEnd)
					,frame = chkenv
				)
			} else {
				if (fDebug){
					message(glue::glue('[{LfuncName}]Remove the pseudo <chkDat> <chk_kpi_pd{chkEnd}> since it should not exist'))
				}
				rc <- dataIO_int[['RAM']]$push(
					indat = list(
						'tmp' = NULL
					)
					,outfile = paste0('chk_kpi_pd',chkEnd)
					,frame = chkenv
				)
			}

			#390. Remove the temporary API
			dataIO_int$remove('RAM')

			#700. Prepare arguments
			#701. Translate <options>
			if (is.character(vv_opt)) {
				.opt_this <- vv_opt %>% str2expression() %>% eval()
			} else {
				.opt_this <- vv_opt
			}

			#710. Set arguments
			args_agg <- list(
				'inDatPtn' = cfg_input
				,'inDatType' = 'C_KPI_FILE_TYPE'
				,'in_df' = 'DF_NAME'
				,'fImp.opt' = .opt_this
				,'fTrans' = fTrans
				,'fTrans.opt' = fTrans.opt
				,'.parallel' = .parallel
				,'omniR.ini' = omniR.ini
				,'cores' = cores
				,'dateBgn' = dateBgn_fnl
				,'dateEnd' = dateEnd_d
				,'chkDatPtn' = paste0('chk_kpi_pd',int_sfx)
				,'chkDatType' = 'RAM'
				,'chkDat.opt' = list(
					'RAM' = list(
						'frame' = chkenv
					)
				)
				,'chkDatVar' = aggrVar
				,'chkBgn' = chkBgn_fnl
				,'byVar' = byInt
				,'copyVar' = copyVar
				,'aggrVar' = aggrVar
				,'outVar' = aggrVar
				,'genPHMul' = genPHMul
				,'calcInd' = calcInd
				,'funcAggr' = funcAggr
				,'outDTfmt' = outDTfmt
				,'fDebug' = fDebug
				,'kw_DataIO' = kw_DataIO
			)

			#750. Determine the rest of keyword arguments
			kw_oth <- kw_agg_raw[!names(kw_agg_raw) %in% c(names(kw_varkw),names(args_agg))]

			#790. Finalize the arguments
			args_agg_fnl <- c(args_agg, kw_oth, kw_varkw)

			#800. Aggregation
			#[ASSUMPTION]
			#[1] We do not cover the errors by setting default value when <get> fails, since the data should exist if everything
			#     goes well
			rstOut <- do.call(aggrByPeriod, args_agg_fnl)[['data']]

			#999. Output
			return(rstOut)
		}

		#790. Aggregation for the same <key> in current output file
		rstOut <- mapply(
			h_agg
			,loop_agg[['C_KPI_FILE_NAME']]
			,loop_agg[['DF_NAME']]
			,loop_agg[['options']]
			,SIMPLIFY = F
		) %>%
			dplyr::bind_rows() %>%
			dplyr::mutate(
				!!rlang::sym('C_KPI_ID') := apply_MapVal(
					!!rlang::sym('C_KPI_ID')
					,dict_map = mapper_dict
					,preserve = F
					,fPartial = F
					,PRX = F
					,full.match = T
					,ignore.case = F
				)
			)

		#800. Update the indicator of the data refresh date
		if (tableVar %in% colnames(rstOut)) {
			rstOut %<>%
				dplyr::mutate(
					!!rlang::sym(tableVar) := asDates(dateEnd_d)
				)
		}

		#999. Output
		return(rstOut)
	}

	#570. Function to process a single output file name
	h_outfile <- function(u_fpath,u_ftype,u_opt) {
		#500. Conduct calculation for all unique <key>s in current output file
		rstOut <- cfg_rst %>%
			dplyr::filter(!!rlang::sym('FilePath') == u_fpath) %>%
			dplyr::mutate(
				!!rlang::sym('agg_df') := mapply(
					h_outkey
					,!!rlang::sym('C_KPI_FILE_TYPE')
					,!!rlang::sym('DF_NAME')
					,!!rlang::sym('FilePath')
					,SIMPLIFY = F
				)
			)

		#700. Prepare arguments to export the result
		#710. Register API
		dataIO$add(u_ftype)

		#740. Output file name
		#741. Locate the input filename pattern
		file_input <- inKPICfg %>%
			dplyr::mutate(
				!!rlang::sym('C_KPI_FILE_NAME') := !!rlang::sym('C_KPI_FILE_NAME') %>% trimws()
				,!!rlang::sym('C_LIB_PATH') := !!rlang::sym('C_LIB_PATH') %>% tidyr::replace_na('') %>% trimws()
			) %>%
			dplyr::mutate(
				!!rlang::sym('FilePath') := safe_path(!!rlang::sym('C_LIB_PATH'), !!rlang::sym('C_KPI_FILE_NAME'))
				,!!rlang::sym('inRAM') := !!rlang::sym('C_KPI_FILE_TYPE') =='RAM'
			) %>%
			dplyr::filter(toupper(!!rlang::sym('FilePath')) == u_fpath) %>%
			dplyr::select(tidyselect::all_of(c('FilePath','inRAM'))) %>%
			dplyr::slice_head(n = 1)

		#745. Parse the pattern with the data date
		outfile <- do.call(
			parseDatName
			,c(
				list(
					datPtn = file_input
					,dates = dateEnd_d
					,outDTfmt = outDTfmt
					,chkExist = F
					,dict_map = fTrans
				)
				,fTrans.opt
			)
		) %>%
			dplyr::pull('FilePath.Parsed') %>%
			head(1)

		#749. Debug mode
		if (fDebug){
			message(glue::glue('[{LfuncName}]Creating data file: <{outfile}>'))
		}

		#770. Patch the behavior to write data
		if (u_ftype %in% hasKeys) {
			opt_ex <- rstOut[['options']]
			if (is.character(opt_ex)) {
				#[ASSUMPTION]
				#[1] Till this step, <opt_ex> should only contain one element, but we ensure the completeness of logic
				if (length(opt_ex) == 1) {
					opt_ex %<>% str2expression() %>% eval()
				} else {
					opt_ex <- sapply(opt_ex, function(x){x %>% str2expression() %>% eval()}, USE.NAMES = F, simplify = F)
				}
			}
			kw_patcher <- opt_ex
		} else {
			kw_patcher <- u_opt
			if (is.character(kw_patcher)) {
				if (length(kw_patcher) == 1) {
					kw_patcher %<>% str2expression() %>% eval()
				} else {
					kw_patcher <- sapply(kw_patcher, function(x){x %>% str2expression() %>% eval()}, USE.NAMES = F, simplify = F)
				}
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

		#800. Push the data in accordance with the config table
		rc <- do.call(
			dataIO[[u_ftype]]$push
			,c(
				list(
					indat = rstOut %>% dplyr::pull('agg_df') %>% setNames(rstOut[['DF_NAME']])
					,outfile = outfile
				)
				,kw_patcher
			)
		)

		#899. Remove the API to purge the RAM used
		dataIO$remove(u_ftype)

		#999. Output the result
		return(rlang::list2('{outfile}' := rc))
	}

	#700. Execute the process
	#709. Verify the duplication of file type
	vfy_type <- cfg_rst[c('FilePath','C_KPI_FILE_TYPE')] %>%
		dplyr::distinct() %>%
		dplyr::group_by_at('FilePath') %>%
		dplyr::summarise_at('C_KPI_FILE_TYPE', ~dplyr::n()) %>%
		dplyr::ungroup() %>%
		dplyr::filter_at('C_KPI_FILE_TYPE', ~. > 1)
	if (nrow(vfy_type) > 0) {
		msg_file <- vfy_type[['FilePath']] %>% paste0(collapse = ',')
		stop(glue::glue(
			'[{LfuncName}]Ambiguous <C_KPI_FILE_TYPE> for <{msg_file}>'
			,' Check <inKPICfg> for detailed <C_KPI_FILE_TYPE> of these file names.'
		))
	}

	#719. Verify the duplication of file API options
	vfy_opt <- cfg_rst %>%
		dplyr::filter(!!rlang::sym('C_KPI_FILE_TYPE') %in% hasKeys) %>%
		dplyr::select(tidyselect::all_of(c('FilePath','options'))) %>%
		dplyr::distinct() %>%
		dplyr::group_by_at('FilePath') %>%
		dplyr::summarise_at('options', ~dplyr::n()) %>%
		dplyr::ungroup() %>%
		dplyr::filter_at('options', ~. > 1)
	if (nrow(vfy_opt) > 0) {
		msg_file <- vfy_opt[['FilePath']] %>% paste0(collapse = ',')
		stop(glue::glue(
			'[{LfuncName}]Ambiguous <options> for <{msg_file}>'
			,' Check <inKPICfg> for detailed <options> of these file names.'
		))
	}

	#750. Execution
	rstOut <- cfg_rst[c('FilePath','C_KPI_FILE_TYPE','options')] %>%
		dplyr::distinct() %>%
		dplyr::mutate(
			!!rlang::sym('rc_pre') := mapply(
				h_outfile
				,!!rlang::sym('FilePath')
				,!!rlang::sym('C_KPI_FILE_TYPE')
				,!!rlang::sym('options')
				,SIMPLIFY = F
			)
		) %>%
		dplyr::mutate(
			!!rlang::sym('FilePath') := sapply(!!rlang::sym('rc_pre'), names, simplify = T)
			,!!rlang::sym('rc') := unlist(!!rlang::sym('rc_pre'))
		) %>%
		dplyr::select(tidyselect::all_of(c('FilePath','C_KPI_FILE_TYPE','rc')))

	#999. Validate the completion
	return(rstOut)
}

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
	mtdBgn <- intnx('month', G_d_rpt, 0, 'b', daytype = 'c') %>% strftime('%Y%m%d')
	indate_mtd <- list(
		'dateBgn' = mtdBgn
		,'dateEnd' = G_d_rpt
		,'chkBgn' = mtdBgn
	)
	args_ts_mtd <- rlang::list2(
		'inKPICfg' = cfg_kpi
		,'mapper' = map_agg
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
		,!!!indate_mtd
	)

	#350. Call the process
	time_bgn <- Sys.time()
	rst <- do.call(kfCore_ts_agg, args_ts_mtd)
	time_end <- Sys.time()
	print(time_end - time_bgn)
	# Time difference of 3.970805 secs

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
		{.[(names(.) %in% formalArgs(aggrByPeriod)) | !(names(.) %in% formalArgs(kfCore_ts_agg))]} %>%
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
			'dateEnd' = G_d_next
			#[ASSUMPTION]
			#[1] Check the log on whether the process leveraged the result on the previous workday
			,'fDebug' = T
		))

	#650. Call the process
	time_bgn <- Sys.time()
	rst2 <- do.call(kfCore_ts_agg, args_ts_mtd2)
	time_end <- Sys.time()
	print(time_end - time_bgn)
	# Time difference of 3.786186 secs

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
