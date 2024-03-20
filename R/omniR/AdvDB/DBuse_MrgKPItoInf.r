#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to merge the KPI data to the given (descriptive) information data, in terms of different merging methods #
#   | and pivot all the requested KPIs into new columns to fit the data visualization.                                                  #
#   |IMPORTANT: If there is any variable in both [InfDat] and the KPI dataset, the latter will be taken for granted by default and can  #
#   |            be switched by [KeepInfCol]. This is useful when the mapping result in the KPI dataset is at higher priority during    #
#   |            the merge.                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Description of the data storage:                                                                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] 每天的KPI存储在一个单独的数据文件中；没有数据或数据值为0的行可以不存储以减少空间使用                                           #
#   |[2] 每天的多个KPI可以存储于同一个文件中以减少数据文件数量                                                                          #
#   |[3] KPI数据文件命名方式：[<任意字符>yyyymmdd<任意文件名后缀>]；一般后缀不影响读取，关键看参数要求使用哪种方法读取文件              #
#   |[4] InfDat数据需要有对应的keyvar（可以为多个）字段，且这些字段的组合必须唯一；用于表格的连接                                       #
#   |[5] 合并后的数据需要有对应的AggrBy（可以为多个）字段，用于汇总输出                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inKPICfg    :   The dataset that stores the full configuration of the KPI. It MUST contain below fields:                           #
#   |                |------------------------------------------------------------------------------------------------------------------#
#   |                |Column Name     |Nullable?  |Description                                                                          #
#   |                |----------------+-----------+-------------------------------------------------------------------------------------#
#   |                |C_KPI_ID        |No         | KPI ID used as part of keys for mapping and aggregation                             #
#   |                |C_KPI_SHORTNAME |No         | It will be translated into [colnames] in the output data frame                      #
#   |                |                |           | [IMPORTANT] Ensure its values are valid according to the syntax in R                #
#   |                |C_KPI_BIZNAME   |Yes        | If it is present, the program will translate its values to the attribute [label] on #
#   |                |                |           |  the columns of the output data frame                                               #
#   |                |C_KPI_FILE_TYPE |No         | File type to determine the API for data I/O process, see <DataIO>                   #
#   |                |N_LIB_PATH_SEQ  |No         | Priority to determine the candidate paths when loading and writing data files, the  #
#   |                |                |           |  lesser the higher. E.g. 1 represents the primary path, 2 indicates the backup      #
#   |                |                |           |  location of historical data files                                                  #
#   |                |C_LIB_PATH      |Yes        | Candidate path to store the KPI data file. Used together with <N_LIB_PATH_SEQ>      #
#   |                |                |           | It can be empty for data type <RAM>                                                 #
#   |                |C_KPI_FILE_NAME |No         | Data file name, should be the same for all candidate paths                          #
#   |                |DF_NAME         |Yes        | For some cases, such as [inDatType=R] there should be such an additional field      #
#   |                |                |           |  indicating the name of data.frame stored in the data file (i.e. container)         #
#   |                |                |           | It is required if [C_KPI_FILE_TYPE] on any record is similar to [R]                 #
#   |                |options         |Yes        | Literal string representation of <dict> representing the options used for the API   #
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
#   |                                               translated by the value of R variable [G_d_curr] in the parent frame                #
#   |InfDat      :   The dataset that stores the descriptive information at certain level (Acct level or Cust level).                   #
#   |                Default: [NULL]                                                                                                    #
#   |keyvar      :   The vector of Key field names during the merge. This requires that the same Key fields exist in both data.         #
#   |                [IMPORTANT] All attributes of [keyvar] are retained from [InfDat] if provided.                                     #
#   |                Default: [NULL]                                                                                                    #
#   |SetAsBase   :   The merging method indicating which of above data is set as the base during the merge.                             #
#   |                [I] Use "Inf" data as the base to left join the "KPI" data.                                                        #
#   |                [K] Use "KPI" data as the base to left join the "Inf" data.                                                        #
#   |                [B] Use either data as the base to inner join the other, meaning "both".                                           #
#   |                [F] Use either data as the base to full join the other, meaning "full".                                            #
#   |                 Above parameters are case insensitive, while the default one is set as [I].                                       #
#   |KeepInfCol  :   Whether to keep the columns from [InfDat] if they also exist in KPI data frames                                    #
#   |                [FALSE           ]  <Default> Use those in KPI data frames as output                                               #
#   |                [TRUE            ]            Keep those retained from [InfDat] as output                                          #
#   |fTrans      :   Named list/vector to translate strings within the configuration to resolve the actual data file name for process   #
#   |                Default: [NULL]                                                                                                    #
#   |fTrans.opt  :   Additional options for value translation on [fTrans], see document for [omniR$AdvOp$apply_MapVal]                  #
#   |                [NULL            ]  <Default> Use default options in [apply_MapVal]                                                #
#   |                [<list>          ]            Use alternative options as provided by a list, see documents of [apply_MapVal]       #
#   |fImp.opt    :   List of options during the data file import for different engines; each element of it is a separate list, too      #
#   |                Valid names of the option lists are set in the field [inKPICfg$C_KPI_FILE_TYPE]                                    #
#   |                [$SAS            ]  <Default> Options for [haven::read_sas]                                                        #
#   |                                              [$encoding = 'GB2312' ]  <Default> Read SAS data in this encoding                    #
#   |                [<name>=<list>   ]            Other named lists for different engines, such as [R=list()] and [HDFS=list()]        #
#   |                [<col. name>     ]            Column name in <inKPICfg> that stores the options as a literal string that can be    #
#   |                                               parsed as a <list>                                                                  #
#   |.parallel   :   Whether to load the data files in [Parallel]; it is useful for lots of large files, but many be slow for small ones#
#   |                [FALSE           ]  <Default> Load the data files sequentially                                                     #
#   |                [TRUE            ]            Use multiple CPU cores to load the data files in parallel. When using this option,   #
#   |                                               please ensure correct environment is passed to <kw_DataIO> for API searching, given #
#   |                                               that RAM is the requested location for search                                       #
#   |cores       :   Number of system cores to read the data files in parallel                                                          #
#   |                Default: [4]                                                                                                       #
#   |omniR.ini   :   Initialization configuration script to load all user defined function in [omniR] when [.parallel=T]                #
#   |                [D:/R/autoexec.r ]  <Default> Parallel mode requires standalone environment hence we need to load [omniR] inside   #
#   |                                               each batch of [%dopar%] to enable the dependent functions separately                #
#   |                [NULL            ]            No need when [.parallel=F]                                                           #
#   |fDebug      :   The switch of Debug Mode. Valid values are [F] or [T].                                                             #
#   |                Default: [F]                                                                                                       #
#   |miss.skip   :   Whether to skip loading the files which are requested but missing in all provided paths                            #
#   |                [TRUE            ]  <Default> Skip missing files, but issue a message to inform the user                           #
#   |                [FALSE           ]            Abort the process if any of the requested files do not exist                         #
#   |miss.files  :   Name of the global variable to store the debug data frame with missing file paths and names                        #
#   |                [G_miss_files    ]  <Default> If any data files are missing, please check this global variable to see the details  #
#   |                [chr string      ]            User defined name of global variable that stores the debug information               #
#   |err.cols    :   Name of the global variable to store the debug data frame with error column information                            #
#   |                [G_err_cols      ]  <Default> If any columns are invalidated, please check this global variable to see the details #
#   |                [chr string      ]            User defined name of global variable that stores the debug information               #
#   |outDTfmt    :   Format of dates as string to be used for assigning values to the variables indicated in [fTrans]                   #
#   |                [ <vec/list>     ] <Default> See the function definition as the default argument of usage                          #
#   |dup.KPIs    :   Name of the global variable to store the debug data frame with duplicated [C_KPI_SHORTNAME]                        #
#   |                [G_dup_kpiname   ]  <Default> If any duplication is found, please check this global variable to see the details    #
#   |                [chr string      ]            User defined name of global variable that stores the debug information               #
#   |AggrBy      :   The vector of field names that are to be used as the classes to aggregate the source data.                         #
#   |                [IMPORTANT] This list of columns are NOT affected by [keyvar] during aggregation.                                  #
#   |                Default: [<keyvar>]                                                                                                #
#   |values_fn   :   The save parameter as passed into function [tidyr:pivot_wider] to summarize the [A_KPI_VAL] in the output data     #
#   |                [sum             ]  <Default> Sum the values of input records of any KPI                                           #
#   |                [<function>      ]            Function to be applied, as an object instead of a character string                   #
#   |...         :   Any other parameters that are required by [tidyr:pivot_wider]. Please check the documents for it                   #
#   |                [IMPORTANT] Below options have already been applied; DO avoid to provide them again!                               #
#   |                [id_cols], [names_from], [values_from], [values_fn]                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<list>      :   The named list that contains below names as results:                                                               #
#   |                [data            ] [data.frame] that stores the result with columns including [available KPIs] and the pivoting    #
#   |                                    [ID]s determined as:                                                                           #
#   |                                   [1] If [InfDat] is not provided, we only use [AggrBy] as [ID] during pivoting                   #
#   |                                   [2] If [InfDat] is provided:                                                                    #
#   |                                       [1] If [AggrBy] has the same values as [keyvar], we add to [AggrBy] by all other columns    #
#   |                                            than [keyvar] in [InfDat] as [ID]                                                      #
#   |                                       [2] Otherwise we follow the rule when [InfDat] is not provided                              #
#   |                [ <miss.files>   ] [NULL] if all data files are successfully loaded, or [data.frame] that contains the paths to the#
#   |                                    data files that are required but missing                                                       #
#   |                [ <err.cols>     ] [NULL] if all KPI data are successfully loaded, or [data.frame] that contains the column names  #
#   |                                    as well as the data files in which they are located, which cannot be concatenated due to       #
#   |                                    different [dtypes]                                                                             #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210130        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210619        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Rewrite the verification part of data file existence, by introducing [AdvDB$parseDatName] as standardization            #
#   |      |[2] Introduce an argument [outDTfmt] aligning above change, to bridge the mapping from [fTrans] to the date series          #
#   |      |[3] Correct the part of frame lookup when assigning values to global variables for user request                             #
#   |      |[4] Change the output into a [list] to store all results, including debug facilities, to avoid pollution in global          #
#   |      |     environment                                                                                                            #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230114        | Version | 2.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce a function [match.arg.x] to enable matching args after mutation, e.g. case-insensitive match                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230811        | Version | 2.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <rlang::exec> to simplify the function call with spliced arguments                                            #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240222        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Replace the low level APIs of data retrieval with <DataIO> to unify the processes                                       #
#   |      |[2] Accept <fImp.opt> to be a column name in <inKPICfg>, to differ the args by source files                                 #
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
#   |   |magrittr, rlang, dplyr, tidyselect, tidyr                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |rmObjAttr                                                                                                                  #
#   |   |   |match.arg.x                                                                                                                #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvDB                                                                                                                          #
#   |   |   |parseDatName                                                                                                               #
#   |   |   |DBuse_SetKPItoInf                                                                                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	magrittr, rlang, dplyr, tidyselect, tidyr
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

library(magrittr)

DBuse_MrgKPItoInf <- function(
	inKPICfg
	,InfDat = NULL
	,keyvar = NULL
	,SetAsBase = c('I','K','B','F')
	,KeepInfCol = F
	,fTrans = NULL
	,fTrans.opt = NULL
	,fImp.opt = list(
		SAS = list(
			encoding = 'GB2312'
		)
	)
	,.parallel = F
	,cores = 4
	,omniR.ini = getOption('file.autoexec')
	,fDebug = F
	,miss.skip = T
	,miss.files = 'G_miss_files'
	,err.cols = 'G_err_cols'
	,outDTfmt = list(
		'L_d_curr' = '%Y%m%d'
		,'L_m_curr' = '%Y%m'
	)
	,dup.KPIs = 'G_dup_kpiname'
	,AggrBy = keyvar
	,values_fn = sum
	,kw_DataIO = list()
	,...
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	if (is.null(inKPICfg)) stop('[',LfuncName,']','[inKPICfg] is not provided!')
	if (!is.null(InfDat)) {
		err_keyvar <- F
		if (is.null(keyvar)) err_keyvar <- T
		else if (length(keyvar)==0) err_keyvar <- T
		if (err_keyvar) stop('[',LfuncName,']','[keyvar] is not provided for mapping to [InfDat]!')
		keyvar <- toupper(unname(unlist(keyvar)))
	}
	SetAsBase <- match.arg.x(SetAsBase, arg.func = toupper)
	if (!is.logical(KeepInfCol)) KeepInfCol <- F
	KeepInfCol <- KeepInfCol[[1]]
	if (!is.logical(.parallel)) .parallel <- F
	if (.parallel) {
		if (is.null(cores)) cores <- 4
	}
	if (!is.logical(fDebug)) fDebug <- F
	if (!is.logical(miss.skip)) miss.skip <- T
	if (length(miss.files)==0) miss.files <- 'G_miss_files'
	if (length(err.cols)==0) err.cols <- 'G_err_cols'
	if (length(dup.KPIs)==0) dup.KPIs <- 'G_dup_kpiname'
	if (length(AggrBy)==0) AggrBy <- keyvar
	AggrBy <- toupper(unname(unlist(AggrBy)))
	if (length(values_fn)==0) values_fn <- sum
	#Abort the process if there is no column to conduct the pivoting
	if (length(AggrBy)==0) stop('[',LfuncName,']','[AggrBy] is not provided for pivoting!')

	#050. Local environment
	#Below function supports to force variable names on its LHS, see [!!!] in [rlang]
	outDict = rlang::list2(
		'data' = NULL
		,!!dup.KPIs := NULL
		,!!miss.files := NULL
		,!!err.cols := NULL
	)
	trans_var <- c('C_KPI_FILE_NAME', 'C_KPI_FULL_PATH', 'C_KPI_SHORTNAME')
	if ('C_KPI_BIZNAME' %in% names(inKPICfg)) trans_var <- c(trans_var, 'C_KPI_BIZNAME')
	comb_func <- list(
		'I' = dplyr::left_join
		,'K' = dplyr::right_join
		,'B' = dplyr::inner_join
		,'F' = dplyr::full_join
	)

	#099. Debug mode
	if (fDebug){
		message('[',LfuncName,']','Debug mode...')
		message('[',LfuncName,']','Parameters are listed as below:')
		#Quote: https://stackoverflow.com/questions/11885207/get-all-parameters-as-list
		args_in <- append(as.list(environment()), list(...))
		args_names <- names(args_in)
		for (m in seq_along(args_in)) {
			message('[',LfuncName,']','Structure: [',args_names[[m]],']:')
			message('[',LfuncName,']','End of structure: [',args_names[[m]],']',str(args_in[[m]]))
		}
	}

	#100. Translate the configurations once required
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

	#110. Define the full path of data files
	KPICfg <- inKPICfg %>%
		dplyr::mutate(
			C_KPI_FULL_PATH = safe_path(C_LIB_PATH, C_KPI_FILE_NAME)
		)

	#150. Map any dynamic values in the data file paths
	#[ASSUMPTION]:
	#[1] [dates=NULL] The variables of date values for translation have been defined in the parent frames
	#[2] [inRAM=FALSE] All requested data files are on harddisk, rather than in RAM of current session
	#[3] [chkExist=False] We do not verify the data file existence here, and leave the verification to below steps
	#[4] The output data frame of below function has the same index as its input, given [dates=NULL]
	parse_kpicfg <- do.call(
		parseDatName
		,c(
			list(
				datPtn = KPICfg[trans_var]
				,parseCol = NULL
				,dates = NULL
				,outDTfmt = outDTfmt
				,inRAM = F
				,chkExist = F
				,dict_map = fTrans
			)
			,fTrans.opt
		)
	)

	#190. Assign values for the necessary columns
	KPICfg[trans_var] <- parse_kpicfg[paste0(trans_var, '.Parsed')]

	#200. Verify the duplication and abort the process if the same [C_KPI_SHORTNAME] is assigned to different [C_KPI_ID]
	#This is because we have to pivot the table by [C_KPI_SHORTNAME], hence it cannot be duplicated.
	#210. Extract the unique pairs of KPI ID and KPI Names for later pivoting and labeling where applicable
	KPI_names <- KPICfg %>%
		dplyr::select( tidyselect::any_of(c('C_KPI_ID', 'C_KPI_SHORTNAME', 'C_KPI_BIZNAME')) ) %>%
		unique()

	#220. Count the frequency of each [C_KPI_SHORTNAME]
	qc_KPI_name <- KPI_names %>%
		dplyr::group_by(C_KPI_SHORTNAME) %>%
		dplyr::summarize(cnt = dplyr::n()) %>%
		dplyr::ungroup() %>%
		dplyr::filter(cnt > 1) %>%
		dplyr::select(C_KPI_SHORTNAME) %>%
		suppressMessages()

	#250. Extract the [C_KPI_SHORTNAME] with more than 1 [C_KPI_ID] for issuing error messages
	qc_KPI_id <- KPICfg %>%
		dplyr::select( C_KPI_ID, C_KPI_SHORTNAME ) %>%
		dplyr::inner_join(qc_KPI_name) %>%
		suppressMessages()

	#290. Abort the process if any duplication is found
	if (nrow(qc_KPI_id) != 0) {
		#100. Print messages
		warning('[',LfuncName,']','Below [C_KPI_SHORTNAME] are applied to more than 1 columns!')
		print(qc_KPI_id)

		#500. Output a global data frame storing the information of the missing files
		# assign(dup.KPIs, qc_KPI_id, pos = globalenv())
		outDict[[dup.KPIs]] <- qc_KPI_id

		#999. Abort the process
		warning('[',LfuncName,']','Check the data frame [',dup.KPIs,'] in the output result for duplications!')
		return(outDict)
	}

	#300. Set together all the requested KPI data files WITHOUT [InfDat]
	#[1] We do not provide [InfDat] here, for we will simplify the process by merging the information table later.
	#[2] [keyvar], [SetAsBase] and [KeepInfCol] are also of no use due to above reason.
	#[3] [fTrans] and [fTrans.opt] are of no use as we have done the translation in the mapping table at earlier steps.
	KPI_set <- DBuse_SetKPItoInf(
		KPICfg
		,InfDat = NULL
		,keyvar = NULL
		,SetAsBase = SetAsBase
		,KeepInfCol = KeepInfCol
		,fTrans = NULL
		,fTrans.opt = NULL
		,fImp.opt = fImp.opt
		,.parallel = .parallel
		,cores = cores
		,omniR.ini = omniR.ini
		,fDebug = fDebug
		,miss.skip = miss.skip
		,miss.files = miss.files
		,err.cols = err.cols
		,kw_DataIO = kw_DataIO
	)

	#309. Return None if above function does not generate output
	if (is.null(KPI_set[['data']])) {
		outDict <- modifyList(outDict, KPI_set)
		return(outDict)
	}

	#500. Merge the KPI data to [InfDat] if it is provided
	if (!is.null(InfDat)) {
		#Debug mode
		if (fDebug){
			message('[',LfuncName,']','Combine [InfDat] with the loaded KPI data...')
		}

		#Determine whether to drop any fields from [InfDat] if they exist in both data
		df_with_inf <- InfDat %>%
			#Ensure the field used at below steps are all referred to in upper case
			dplyr::rename_all(toupper) %>%
			comb_func[[SetAsBase]](
				#Remove all attributes but [names] of the key columns to be used, to eliminate the warnings from [dplyr]
				KPI_set[['data']] %>% dplyr::mutate_at( keyvar, rmObjAttr )
				,by = keyvar
				,suffix = c('._inf_', '._kpi_')
			) %>%
			dplyr::select( -tidyselect::ends_with( ifelse(KeepInfCol, '._kpi_', '._inf_') ) ) %>%
			dplyr::rename_at(
				dplyr::vars( tidyselect::ends_with( ifelse(KeepInfCol, '._inf_', '._kpi_') ) )
				,~ gsub( ifelse(KeepInfCol, '\\._inf_\\s*$', '\\._kpi_\\s*$'), '', ., perl = T )
			) %>%
			#Retrieve the names to be used for pivoting
			dplyr::left_join(
				KPI_names %>%
					#Remove all attributes but [names] of the key columns to be used, to eliminate the warnings from [dplyr]
					dplyr::mutate_at( 'C_KPI_ID', rmObjAttr )
				,by = c('C_KPI_ID')
				,suffix = c('', '._nam_')
			) %>%
			dplyr::select( -tidyselect::ends_with('._nam_') )
	} else {
		#Debug mode
		if (fDebug){
			message('[',LfuncName,']','Process KPI data with no input of [InfDat]...')
		}

		df_with_inf <- KPI_set[['data']] %>%
			#Retrieve the names to be used for pivoting
			dplyr::left_join(
				KPI_names %>%
					#Remove all attributes but [names] of the key columns to be used, to eliminate the warnings from [dplyr]
					dplyr::mutate_at( 'C_KPI_ID', rmObjAttr )
				,by = c('C_KPI_ID')
				,suffix = c('', '._nam_')
			) %>%
			dplyr::select( -tidyselect::ends_with('._nam_') )
	}

	#700. Aggregate the data as per user request
	#710. Determine the columns to act as [ID] during pivoting
	if ( !is.null(InfDat) & identical( sort(unique(AggrBy)), sort(unique(keyvar)) ) ) {
		aggr_fnl <- unique(c(AggrBy, toupper(names(InfDat))))

		#Debug mode
		if (fDebug){
			message('[',LfuncName,']','Keep all columns that have the same names in [InfDat] as [ID] during pivoting...')
		}
	} else {
		aggr_fnl <- AggrBy

		#Debug mode
		if (fDebug){
			message('[',LfuncName,']','Keep [AggrBy] as [ID] during pivoting...')
		}
	}

	#719. Debug mode
	if (fDebug){
		message('[',LfuncName,']','Columns used as [ID] during pivoting are listed as below:')
		message('[',LfuncName,']','Structure: [aggr_fnl]:')
		message('[',LfuncName,']','End of structure: [aggr_fnl]',str(aggr_fnl))
	}

	#730. Conduct pivoting
	tbl_out <- df_with_inf %>%
		#There could be some [keyvar] without any record on any of the KPIs, we will retrieve them separately at below steps.
		dplyr::filter(!is.na(C_KPI_ID), !is.null(C_KPI_ID)) %>%
		tidyr::pivot_wider(
			id_cols = tidyselect::all_of(aggr_fnl)
			,names_from = C_KPI_SHORTNAME
			,values_from = A_KPI_VAL
			,values_fn = values_fn
			,...
		)

	#750. Retrieve those [aggr_fnl] without any KPI record but only existing in [InfDat]
	chk_miss_aggr <- df_with_inf %>% dplyr::filter(is.na(C_KPI_ID) | is.null(C_KPI_ID))
	if ( nrow(chk_miss_aggr) > 0 ) {
		#001. Debug mode
		if (fDebug){
			message('[',LfuncName,']','Correcting KPI columns for those in [InfDat] but without KPI records...')
		}

		#100. Retrieve unique combination of [aggr_fnl] from [df_with_inf]
		aggr_keys <- df_with_inf %>% dplyr::select( tidyselect::all_of(aggr_fnl) ) %>% unique()

		#900. Left join the pivot result to ensure all combinations have records
		tbl_out <- aggr_keys %>% dplyr::left_join(tbl_out, by = aggr_fnl)
	}

	#790. Add labels for the columns pivoted from KPI Names if requested
	if ('C_KPI_BIZNAME' %in% names(inKPICfg)) {
		#001. Debug mode
		if (fDebug){
			message('[',LfuncName,']','Assign [label] attributes to all [KPI] columns...')
		}

		#100. Prepare the mapping format for [names] <-> [attributes] of all KPIs
		map.labels <- KPI_names$C_KPI_BIZNAME %>% unlist()
		names(map.labels) <- KPI_names$C_KPI_SHORTNAME %>% unlist()

		#500. Retrieve the names of the output data
		tbl_names <- names(tbl_out)

		#900. Add labels respectively
		for (i in seq_along(tbl_names)) {
			#100. Match the current name in the mapping format
			this.label <- match(tbl_names[[i]], names(map.labels))
			this.label <- Filter(Negate(is.na), this.label)

			#900. Assign the attribute of [label]
			#[IMPORTANT] The statement <attr(tbl_out[[...]]> must use double brackets here,
			#            as <tbl_out> is a list instead of a vector!
			if (length(this.label)>0) attr(tbl_out[[i]], 'label') <- map.labels[this.label]
		}
	}

	#999. Return the table
	outDict %<>% modifyList(
		rlang::list2(
			'data' = tbl_out
			,!!miss.files := KPI_set[[miss.files]]
			,!!err.cols := KPI_set[[err.cols]]
		)
	)
	return(outDict)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#100. Set parameters
		G_d_curr <- '20160310'
		G_m_curr <- substr(G_d_curr,1,6)
		acctinfo <- haven::read_sas('D:\\R\\omniR\\SampleKPI\\KPI\\K1\\acctinfo.sas7bdat', encoding = 'GB2312')
		CFG_KPI <- haven::read_sas('D:\\R\\omniR\\SampleKPI\\KPI\\K1\\cfg_kpi.sas7bdat', encoding = 'GB2312')
		CFG_LIB <- haven::read_sas('D:\\R\\omniR\\SampleKPI\\KPI\\K1\\cfg_lib.sas7bdat', encoding = 'GB2312')
		KPICfg_all <- dplyr::left_join(
			dplyr::filter(CFG_KPI, D_BGN <= as.Date(G_d_curr,'%Y%m%d'), D_END >= as.Date(G_d_curr,'%Y%m%d'))
			,dplyr::filter(CFG_LIB, D_BGN <= as.Date(G_d_curr,'%Y%m%d'), D_END >= as.Date(G_d_curr,'%Y%m%d'))
			,by = 'C_KPI_DAT_LIB'
			,suffix = c('','.y')
		) %>%
			dplyr::select(-tidyselect::ends_with('.y')) %>%
			dplyr::mutate(
				C_KPI_FILE_TYPE = 'SAS'
				,C_KPI_FILE_NAME = paste0(C_KPI_DAT_NAME,'.sas7bdat')
				,DF_NAME = ''
			)

		#150. Prepare to translate the date strings in the file names
		#Similar to FORMAT Procedure in SAS, we map the special strings with what we need in current session
		#The function will attempt to resolve the values of below list as if they are R variables
		fmt_Trans <- list(
			'&c_date.' = 'G_d_curr'
			,'&L_curdate.' = 'G_d_curr'
			,'&L_curMon.' = 'G_m_curr'
			,'&L_prevMon.' = 'G_m_prev'
		)
		fmt_opt <- list(
			PRX = F
			,fPartial = T
			,full.match = F
			,ignore.case = T
		)

		#200. Modify the global API to load SAS data
		std_read_SAS <- function(
			infile
			,funcConv = function(df) {df %>% dplyr::select(-tidyselect::any_of(c('D_TABLE')))}
			,...
		) {
			dots <- rlang::list2(...)
			if (length(dots) > 0) {
				dots <- dots[!names(dots) %in% c('key')]
			}
			return(funcConv(do.call(haven::read_sas, c(list(data_file = infile), dots))))
		}

		#300. Read the KPI data
		args_in <- list(
			inKPICfg = KPICfg_all
			,InfDat = acctinfo
			,keyvar = c('nc_cifno','nc_acct_no')
			,SetAsBase = 'k'
			,KeepInfCol = F
			,fTrans = fmt_Trans
			,fTrans.opt = fmt_opt
			,fImp.opt = list(
				SAS = list(
					encoding = 'GB2312'
				)
			)
			,.parallel = T
			,cores = 4
			,omniR.ini = 'D:\\R\\autoexec.r'
			,fDebug = F
			,miss.skip = T
			,miss.files = 'G_miss_files'
			,err.cols = 'G_err_cols'
			,dup.KPIs = 'G_dup_kpiname'
			#Provide the same value for [AggrBy] as [keyvar], or just [AggrBy=keyvar] to keep all columns from [InfDat]
			,AggrBy = 'nc_cifno'
			,values_fn = sum
			#Below parameters represent [...] for [tidyr:pivot_wider]
			,values_fill = list(A_KPI_VAL = 0)
		)

		#350. Change the behavior to correct the calculation
		#[ASSUMPTION]
		#[1] For explanation on the environment assignment, see details in <DBuse_SetKPItoInf>
		apienv <- new.env()
		dataIO <- DataIO$new()
		if (length(dataIO$apidyn) > 0) {
			fn_export <- sapply(dataIO$apidyn, function(x){eval(str2expression(x))}, simplify = F, USE.NAMES = T)
			gen_locals(fn_export, frame = apienv)
		}
		KPI_rst <- do.call(
			DBuse_MrgKPItoInf
			,c(
				args_in
				,list(
					kw_DataIO = list(
						lsPullOpt = list(
							frame = apienv
						)
						,lsPushOpt = list(
							frame = apienv
						)
					)
				)
			)
		)

		View(KPI_rst[['data']])
		print(colnames(KPI_rst[['data']]))
		# [1] "NC_CIFNO"  "K_COUNTER" "K_DUMMY"
		print(sapply(KPI_rst[['data']], function(x){attr(x, 'label')}))
		# $NC_CIFNO
		# NULL
		#
		# $K_COUNTER
		#         K_COUNTER
		# "Counter of Days"
		#
		# $K_DUMMY
		#            K_DUMMY
		# "Counter of Dummy"

		#500. Test part of the function
		#Below function is from: [omniR$AdvOp]
		gen_locals(
			LfuncName = 'DBuse_MrgKPItoInf'
			,inKPICfg = KPICfg_all
			,InfDat = acctinfo
			,keyvar = c('nc_cifno','nc_acct_no')
			,SetAsBase = 'k'
			,KeepInfCol = F
			,fTrans = fmt_Trans
			,fTrans.opt = fmt_opt
			,fImp.opt = list(
				SAS = list(
					encoding = 'GB2312'
				)
			)
			,.parallel = T
			,cores = 4
			,fDebug = F
			,miss.skip = T
			,miss.files = 'G_miss_files'
			,err.cols = 'G_err_cols'
			,dup.KPIs = 'G_dup_kpiname'
			,AggrBy = 'nc_cifno'
			,values_fn = sum
			,values_fill = list(A_KPI_VAL = NA)
		)
		if (T){
			message('Copy any part in the function definition to test it here:')
			message(.parallel)
		}

		#600. Test if there is no [InfDat]
		args_tweak <- modifyList(
			args_in
			,list(
				InfDat = NULL
				,keyvar = 'nc_cifno'
				,AggrBy = NULL
			)
			,keep.null = T
		)
		KPI_rst2 <- do.call(
			DBuse_MrgKPItoInf
			,c(
				args_tweak
				,list(
					kw_DataIO = list(
						lsPullOpt = list(
							frame = apienv
						)
						,lsPushOpt = list(
							frame = apienv
						)
					)
				)
			)
		)

		View(KPI_rst2[['data']])

	}
}
