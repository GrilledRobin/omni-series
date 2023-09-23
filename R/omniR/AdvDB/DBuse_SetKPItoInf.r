#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to merge the KPI data to the given (descriptive) information data, in terms of different merging methods #
#   | and set all the datasets together for reporting purpose.                                                                          #
#   |IMPORTANT: If there is any variable in both [InfDat] and the KPI dataset, the latter will be taken for granted and overwrite the   #
#   |            final result. This is useful when the mapping result in the KPI dataset is at higher priority during the merge.        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Description of the data storage:                                                                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] 每天的KPI存储在一个单独的数据文件中；没有数据或数据值为0的行可以不存储以减少空间使用                                           #
#   |[2] 每天的多个KPI可以存储于同一个文件中以减少数据文件数量                                                                          #
#   |[3] KPI数据文件命名方式：[<任意字符>yyyymmdd<任意文件名后缀>]；一般后缀不影响读取，关键看参数要求使用哪种方法读取文件              #
#   |[4] InfDat数据需要有对应的keyvar（可以为多个）字段，且这些字段的组合必须唯一；用于表格的连接                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inKPICfg   :   The dataset that stores the full configuration of the KPI. It MUST contain below fields:                            #
#   |               [C_KPI_ID        ] : The ID of the KPI to be retrieved from the various data files.                                 #
#   |               [N_LIB_PATH_SEQ  ] : The sequence of paths to search for the KPI data file in the same library alias                #
#   |               [C_KPI_FILE_TYPE ] : The types of data files that indicates the method for this function to import data             #
#   |                                    [RAM     ] Try to load the data frame from RAM in current R session                            #
#   |                                    [R       ] Try to import as R-Data                                                             #
#   |                                    [SAS     ] Try to import via [haven::read_sas]                                                 #
#   |               [DF_NAME         ] : For some cases, such as [C_KPI_FILE_TYPE=R] there should be such an additional field           #
#   |                                     indicating the name of data.frame stored in the data file (i.e. container) for loading        #
#   |                                    Default: [NA] i.e. no need for such field when [C_KPI_FILE_TYPE=SAS]                           #
#   |               [C_KPI_FILE_NAME ] : The names of data files for identification of file existence in all available paths            #
#   |               [C_LIB_PATH      ] : The absolute paths to store the KPI data (excl. file name). Program will conduct translation   #
#   |               [--> IMPORTANT  <--] Program will translate several columns in below way as per requested by [fTrans], see local    #
#   |                                     variable [trans_var].                                                                         #
#   |                                    [1] [fTrans] is NOT provided: assume that the value in this field is a valid file path         #
#   |                                    [2] [fTrans] is provided a named list or vector: Translate the special strings in accordance   #
#   |                                          as data file names. in such case, names of the provided parameter are treated as strings #
#   |                                          to be replaced; while the values of the provided parameter are treated as variables in   #
#   |                                          the parent environment and are [get]ed for translation, e.g.:                            #
#   |                                        [1] ['&c_date.' = 'G_d_curr'  ] Current reporting/data date in SAS syntax [&c_date.] to be #
#   |                                              translated by the value of R variable [G_d_curr] in the parent frame                 #
#   |InfDat     :   The dataset that stores the descriptive information at certain level (Acct level or Cust level).                    #
#   |               Default: [NULL]                                                                                                     #
#   |keyvar     :   The vector of Key field names during the merge. This requires that the same Key fields exist in both data.          #
#   |               [IMPORTANT] All attributes of [keyvar] are retained from [InfDat] if provided.                                      #
#   |               Default: [NULL]                                                                                                     #
#   |SetAsBase  :   The merging method indicating which of above data is set as the base during the merge.                              #
#   |               [I] Use "Inf" data as the base to left join the "KPI" data.                                                         #
#   |               [K] Use "KPI" data as the base to left join the "Inf" data.                                                         #
#   |               [B] Use either data as the base to inner join the other, meaning "both".                                            #
#   |               [F] Use either data as the base to full join the other, meaning "full".                                             #
#   |                Above parameters are case insensitive, while the default one is set as [I].                                        #
#   |KeepInfCol :   Whether to keep the columns from [InfDat] if they also exist in KPI data frames                                     #
#   |               [FALSE           ]  <Default> Use those in KPI data frames as output                                                #
#   |               [TRUE            ]            Keep those retained from [InfDat] as output                                           #
#   |fTrans     :   Named list/vector to translate strings within the configuration to resolve the actual data file name for process    #
#   |               Default: [NULL]                                                                                                     #
#   |fTrans.opt :   Additional options for value translation on [fTrans], see document for [omniR$AdvOp$apply_MapVal]                   #
#   |               [NULL            ]  <Default> Use default options in [apply_MapVal]                                                 #
#   |               [<list>          ]            Use alternative options as provided by a list, see documents of [apply_MapVal]        #
#   |fImp.opt   :   List of options during the data file import for different engines; each element of it is a separate list, too       #
#   |               Valid names of the option lists are set in the field [inKPICfg$C_KPI_FILE_TYPE]                                     #
#   |               [$SAS            ]  <Default> Options for [haven::read_sas]                                                         #
#   |                                             [$encoding = 'GB2312' ]  <Default> Read SAS data in this encoding                     #
#   |               [<name>=<list>   ]            Other named lists for different engines, such as [R=list()] and [HDFS=list()]         #
#   |.parallel  :   Whether to load the data files in [Parallel]; it is useful for lots of large files, but many be slow for small ones #
#   |               [TRUE            ]  <Default> Use multiple CPU cores to load the data files in parallel                             #
#   |               [FALSE           ]            Load the data files sequentially                                                      #
#   |omniR.ini  :   Initialization configuration script to load all user defined function in [omniR] when [.parallel=T]                 #
#   |               [D:/R/autoexec.r ]  <Default> Parallel mode requires standalone environment hence we need to load [omniR] inside    #
#   |                                              each batch of [%dopar%] to enable the dependent functions separately                 #
#   |               [NULL            ]            No need when [.parallel=F]                                                            #
#   |cores      :   Number of system cores to read the data files in parallel                                                           #
#   |               Default: [4]                                                                                                        #
#   |fDebug     :   The switch of Debug Mode. Valid values are [F] or [T].                                                              #
#   |               Default: [F]                                                                                                        #
#   |miss.skip  :   Whether to skip loading the files which are requested but missing in all provided paths                             #
#   |               [TRUE            ]  <Default> Skip missing files, but issue a message to inform the user                            #
#   |               [FALSE           ]            Abort the process if any of the requested files do not exist                          #
#   |miss.files :   Name of the global variable to store the debug data frame with missing file paths and names                         #
#   |               [G_miss_files    ]  <Default> If any data files are missing, please check this global variable to see the details   #
#   |               [chr string      ]            User defined name of global variable that stores the debug information                #
#   |err.cols   :   Name of the global variable to store the debug data frame with error column information                             #
#   |               [G_err_cols      ]  <Default> If any columns are invalidated, please check this global variable to see the details  #
#   |               [chr string      ]            User defined name of global variable that stores the debug information                #
#   |outDTfmt   :   Format of dates as string to be used for assigning values to the variables indicated in [fTrans]                    #
#   |               [ <vec/list>     ] <Default> See the function definition as the default argument of usage                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<list>     :   The named list that contains below names as results:                                                                #
#   |               [data            ] [data.frame] that contains the combined result                                                   #
#   |               [ <miss.files>   ] [NULL] if all data files are successfully loaded, or [data.frame] that contains the paths to the #
#   |                                   data files that are required but missing                                                        #
#   |               [ <err.cols>     ] [NULL] if all KPI data are successfully loaded, or [data.frame] that contains the column names   #
#   |                                   as well as the data files in which they are located, which cannot be concatenated due to        #
#   |                                   different [dtypes]                                                                              #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210123        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210503        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Standardize the functions to read the source data files. Check the series of functions as [AdvDB$std_read_*]            #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210619        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Rewrite the verification part of data file existence, by introducing [omniR$AdvDB$parseDatName] as standardization      #
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
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |See the [Full Test Program] section                                                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |magrittr, rlang, dplyr, tidyselect, haven, doParallel, foreach                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvDB                                                                                                                    #
#   |   |   |std_read_R                                                                                                                 #
#   |   |   |std_read_RAM                                                                                                               #
#   |   |   |std_read_SAS                                                                                                               #
#   |   |   |parseDatName                                                                                                               #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvOp                                                                                                                    #
#   |   |   |rmObjAttr                                                                                                                  #
#   |   |   |debug_comp_datcols                                                                                                         #
#   |   |   |match.arg.x                                                                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	magrittr, rlang, dplyr, tidyselect, haven, doParallel, foreach
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

library(magrittr)
#We should use [%dopar%] supported by below package
library(foreach)

DBuse_SetKPItoInf <- function(
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
	,.parallel = T
	,cores = 4
	,omniR.ini = 'D:\\R\\autoexec.r'
	,fDebug = F
	,miss.skip = T
	,miss.files = 'G_miss_files'
	,err.cols = 'G_err_cols'
	,outDTfmt = list(
		'L_d_curr' = '%Y%m%d'
		,'L_m_curr' = '%Y%m'
	)
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

	#050. Local environment
	#Below function supports to force variable names on its LHS, see [!!!] in [rlang]
	outDict = rlang::list2(
		'data' = NULL
		,!!miss.files := NULL
		,!!err.cols := NULL
	)
	calc_var <- c( 'C_KPI_ID', 'A_KPI_VAL', 'D_TABLE' )
	trans_var <- c('C_KPI_FILE_NAME', 'C_KPI_FULL_PATH')
	params_funcs <- c( 'DF_NAME' )
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
		args_in <- as.list(environment())
		args_names <- names(args_in)
		for (m in seq_along(args_in)) {
			message('[',LfuncName,']','Structure: [',args_names[[m]],']:')
			message('[',LfuncName,']','End of structure: [',args_names[[m]],']',str(args_in[[m]]))
		}
	}

	#100. Translate the configurations once required
	#110. Define the full path of data files
	KPICfg <- inKPICfg %>%
		dplyr::mutate(
			C_KPI_FULL_PATH = file.path(
				gsub('[\\\\/]+\\s*$', '', C_LIB_PATH)
				,C_KPI_FILE_NAME
			)
		)

	#150. Map any dynamic values in the data file paths
	#[ASSUMPTION]:
	#[1] [dates=NULL] The variables of date values for translation have been defined in the parent frames
	#[2] [inRAM=FALSE] All requested data files are on harddisk, rather than in RAM of current session
	#[3] The output data frame of below function has the same index as its input, given [dates=NULL]
	parse_kpicfg <- rlang::exec(
		parseDatName
		,datPtn = KPICfg[trans_var]
		,parseCol = NULL
		,dates = NULL
		,outDTfmt = outDTfmt
		,inRAM = F
		,chkExist = T
		,dict_map = fTrans
		,!!!fTrans.opt
	)

	#190. Assign values for the necessary columns
	KPICfg[trans_var] <- parse_kpicfg[paste0(trans_var, '.Parsed')]
	KPICfg['f_exist'] <- parse_kpicfg['C_KPI_FULL_PATH.chkExist']

	#500. Import the KPI data files
	#501. Debug mode
	if (fDebug){
		message('[',LfuncName,']','Check data file existence...')
	}

	#510. Search in all paths of the libraries for the data files and identify the first occurrences respectively for later import
	files_exist <- KPICfg %>%
		dplyr::filter(f_exist) %>%
		dplyr::select(
			C_KPI_ID, N_LIB_PATH_SEQ
			,C_KPI_FILE_TYPE
			,tidyselect::all_of(trans_var)
			,tidyselect::any_of(params_funcs)
		) %>%
		#If the same data file exist in different paths of the same library alias, we only retrieve the first occurrence of it
		dplyr::group_by( C_KPI_ID ) %>%
		dplyr::slice_min( N_LIB_PATH_SEQ ) %>%
		dplyr::ungroup()

	#519. Abort the process if there is no available data file found
	if (nrow(files_exist)==0) {
		#500. Output a global data frame storing the information of the missing files
		# assign(miss.files, KPICfg, pos = globalenv())
		outDict[[miss.files]] <- KPICfg

		#999. Abort the process if no missing file is accepted
		if (!miss.skip) {
			warning('[',LfuncName,']','User requests not to skip the missing files!')
			warning('[',LfuncName,']','Check the data frame [',miss.files,'] in the output result for missing files!')
		} else {
			message('[',LfuncName,']','No data file is available! NULL result is returned!')
			print( KPICfg %>% dplyr::select(C_KPI_ID, C_KPI_FULL_PATH) )
		}
		return(outDict)
	}

	#530. Identify the files that are requested but do not exist
	#Except those existing ones from the requested files, the rest will be those do not exist in any provided paths
	files_chk_miss <- KPICfg %>%
		dplyr::select(C_KPI_FILE_NAME) %>%
		unique() %>%
		dplyr::anti_join(
			files_exist %>% dplyr::select(C_KPI_FILE_NAME) %>% unique()
		) %>%
		suppressMessages()

	#535. Print the names of all missing files in the log and create a global data frame for debug
	if (nrow(files_chk_miss)!=0) {
		#100. Print messages
		message('[',LfuncName,']','Below files are requested but do not exist.')
		print(files_chk_miss)

		#500. Output a global data frame storing the information of the missing files
		logs_file_miss <- KPICfg %>% dplyr::inner_join(files_chk_miss) %>% suppressMessages()
		# assign(miss.files, logs_file_miss, pos = globalenv())
		outDict[[miss.files]] <- logs_file_miss

		#999. Abort the process if no missing file is accepted
		if (!miss.skip) {
			warning('[',LfuncName,']','User requests not to skip the missing files!')
			warning('[',LfuncName,']','Check the data frame [',miss.files,'] in the output result for missing files!')
			return(outDict)
		}
	}

	#550. Prepare the import statement given there could be multiple KPIs stored in the same data file
	#551. Search for all columns EXCEPT [C_KPI_ID] for grouping
	files_prep_names <- names(files_exist %>% dplyr::select(-C_KPI_ID))

	#555. Concatenate [C_KPI_ID] for each unique absolute file path
	files_prep <- files_exist %>%
		dplyr::group_by_at( files_prep_names ) %>%
		dplyr::summarize( kpis = paste0(C_KPI_ID, collapse = '|') ) %>%
		dplyr::ungroup() %>%
		suppressMessages()
	n_files <- nrow(files_prep)

	#570. Define the function to be called in parallel
	#[IMPORTANT] All functions (especially pipe operands), that are directly called from packages, should be activated INSIDE this
	#             one, either by [library] or [library::], since it is trying to distribute the tasks separately to different CPU
	#             cores and they will NOT know what to do from scratch.
	#[Quote: https://www.r-bloggers.com/2013/05/import-all-text-files-in-a-folder-with-parallel-execution/ ]
	func_parallel <- function(i){
		if (.parallel) {
			#001. Load necessary packages
			lst_pkg <- c( 'magrittr', 'rlang' , 'dplyr' , 'tidyselect', 'tidyr'
				, 'haven' , 'doParallel' , 'foreach'
			)

			suppressPackageStartupMessages(
				sapply(lst_pkg, function(x){library(x,character.only = TRUE)})
			)
			#Below function provides the support to recognition of MBCS characters in the source programs
			tmcn::setchs()

			#010. Load user defined functions
			source(omniR.ini)
		}

		#100. Set parameters
		imp_KPI <- files_prep[i,'kpis'] %>% unlist() %>% strsplit('|', fixed = T) %>% unlist()
		imp_type <- files_prep[i,'C_KPI_FILE_TYPE'] %>% unlist()
		imp_path <- files_prep[i,'C_KPI_FULL_PATH'] %>% unlist()
		if (imp_type %in% c('R')) imp_df <- files_prep[i,'DF_NAME'] %>% unlist()
		else imp_df <- NULL

		#199. Debug mode
		if (fDebug){
			message(
				'[',LfuncName,']'
				,'[imp_KPI=',paste0(imp_KPI, collapse = '|'),']'
				,'[imp_type=',imp_type,']'
				,'[imp_path=',imp_path,']'
				,'[imp_df=',imp_df,']'
			)
		}

		#300. Prepare the function to apply to the process list
		imp_func <- list(
			RAM = list(
				.func = std_read_RAM
				,.opt = list(imp_path)
			)
			,R = list(
				.func = std_read_R
				#[Quote: https://www.r-bloggers.com/2013/08/a-new-r-trick-for-me-at-least/ ]
				,.opt = c(list(imp_path), list(imp_df), fImp.opt$R)
			)
			,SAS = list(
				.func = std_read_SAS
				,.opt = c( list(imp_path), fImp.opt$SAS )
			)
		)

		#500. Call functions to import data from current path
		imp_data <- do.call( imp_func[[imp_type]]$.func, imp_func[[imp_type]]$.opt ) %>%
			#100. Upcase the field names for all imported data, to facilitate the later [bind_rows]
			#Ensure the field used at below steps are all referred to in upper case
			dplyr::rename_all(toupper) %>%
			#500. Only keep the KPIs that are defined in [inKPICfg] to reduce the RAM expense
			dplyr::filter_at( 'C_KPI_ID', ~. %in% imp_KPI )
			# dplyr::select_at( c(keyvar, calc_var) )

		#700. Assign additional attributes to the data frame for column class check
		attr(imp_data, 'DF_NAME') <- imp_df

		#999. Return the result
		return(imp_data)
	}

	#590. Create a list of imported data frames and bind all rows of them together as one data frame
	#[IMPOTANT] There could be fields/columns in the same name but not the same types in different data files,
	#            but we throw the errors at the step [dplyr::bind_rows] to ask user to correct the input data,
	#            instead of guessing the correct types here, for it takes quite a lot of unnecessary effort.
	if (.parallel) {
		#001. Debug mode
		if (fDebug){
			message('[',LfuncName,']','Import data files in Parallel mode...')
		}

		#100. Set the cores to be used
		doParallel::registerDoParallel(cores = cores)

		#900. Read the files and combine them by rows
		#We do not directly combine the data, for there may be columns with different classes.
		# files_import <- foreach::foreach( i = seq_len(n_files), .combine = dplyr::bind_rows ) %dopar% func_parallel(i)
		files_import <- foreach::foreach( i = seq_len(n_files) ) %dopar% func_parallel(i)
	} else {
		#001. Debug mode
		if (fDebug){
			message('[',LfuncName,']','Import data files in Sequential mode...')
		}

		#900. Read the files sequentially
		#We do not directly combine the data, for there may be columns with different classes.
		# files_import <- lapply( seq_len(n_files), func_parallel ) %>% dplyr::bind_rows()
		files_import <- lapply( seq_len(n_files), func_parallel )
	}

	#600. Combine the results
	#610. Check the list of imported data on the classes of columns
	names(files_import) <- files_prep$C_KPI_FULL_PATH
	chk_cls <- debug_comp_datcols( files_import, with.attr = c('DF_NAME') )

	#619. Abort the program if any inconsistency is found on columns of data frames
	if (nrow(chk_cls)) {
		#500. Output a global data frame storing the information of the column inconsistency
		assign(err.cols, chk_cls, pos = globalenv())
		outDict[[err.cols]] <- chk_cls

		#999. Abort the process
		warning('[',LfuncName,']','Some columns cannot be bound due to different classes!')
		warning('[',LfuncName,']','Check data frame [',err.cols,'] in the output result for these columns!')
		return(outDict)
	}

	#680. Combine the data
	files_combine <- dplyr::bind_rows(files_import)

	#700. Return the above result if [InfDat] is not provided for combination
	if (is.null(InfDat)) {
		outDict[['data']] <- files_combine
		return(outDict)
	}

	#800. Retrieve the information table as per request
	#801. Debug mode
	if (fDebug){
		message('[',LfuncName,']','Combine [InfDat] with the loaded KPI data...')
	}

	#Drop any fields from [InfDat] if they exist in both data
	tbl_out <- InfDat %>%
		#Ensure the field used at below steps are all referred to in upper case
		dplyr::rename_all(toupper) %>%
		comb_func[[SetAsBase]](
			#Remove all attributes but [names] of the key columns to be used, to eliminate the warnings from [dplyr]
			files_combine %>% dplyr::mutate_at( keyvar, rmObjAttr )
			,by = keyvar
			,suffix = c('._inf_', '._kpi_')
		) %>%
		dplyr::select( -tidyselect::ends_with( ifelse(KeepInfCol, '._kpi_', '._inf_') ) ) %>%
		dplyr::rename_at(
			dplyr::vars( tidyselect::ends_with( ifelse(KeepInfCol, '._inf_', '._kpi_') ) )
			,~ gsub( ifelse(KeepInfCol, '\\._inf_\\s*$', '\\._kpi_\\s*$'), '', ., perl = T )
		)

	#999. Return the table
	outDict[['data']] <- tbl_out
	return(outDict)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#001. Load necessary packages
		lst_pkg <- c( 'magrittr', 'rlang' , 'dplyr' , 'tidyselect' , 'haven'
			, 'doParallel' , 'foreach'
		)

		suppressPackageStartupMessages(
			sapply(lst_pkg, function(x){library(x,character.only = TRUE)})
		)
		tmcn::setchs(rev=F)

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

		#300. Read the KPI data
		KPI_rst <- DBuse_SetKPItoInf(
			KPICfg_all
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
		)

		View(KPI_rst[['data']])

		#500. Test part of the function
		#Below function is from: [omniR$AdvOp]
		gen_locals(
			LfuncName = 'DBuse_SetKPItoInf'
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
			,omniR.ini = 'D:\\R\\autoexec.r'
			,fDebug = F
			,miss.skip = T
			,miss.files = 'G_miss_files'
			,err.cols = 'G_err_cols'
		)
		if (T){
			message('Copy any part in the function definition to test it here:')
			message(.parallel)
		}

	}
}
