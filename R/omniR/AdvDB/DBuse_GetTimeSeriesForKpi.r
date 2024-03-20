#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to merge the KPI data to the given (descriptive) information data, in terms of different merging methods #
#   | in a periodical way, and combine the output as one single data frame                                                              #
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
#   |[5] 当[MergeProc=MERGE]时，合并后的数据需要有对应的AggrBy（可以为多个）字段，用于汇总输出                                          #
#   |[6] 程序不采用将KPI配置表统一操作的方法，转而使用循环来处理每个日期的数据，以防止单数据容量过大造成[*join]和[pivot]效率急剧下降    #
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
#   |                |                |           | [IMPORTANT] Required when <MergeProc==MERGE>                                        #
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
#   |InfDatCfg   :   The list that stores the full configuration of the Information Table. It MUST contain below elements:              #
#   |                [$InfDat         ] : Character string as the name of Information Table, or its [prefix] if [$SingleInf=F]          #
#   |                                     [NULL    ] <Default> No Information Table is required                                         #
#   |                [$.paths         ] : Character vector of the candidate paths to search for the [$InfDat]; the position of the      #
#   |                                      character strings represents the priority for searching, i.e. if the same data file exists   #
#   |                                      in several candidate paths, the first one will be used for import                            #
#   |                                     [NULL    ] <Default> No Information Table is required                                         #
#   |                [$DatType        ] : Character string as the type of Information Table for this function to import                 #
#   |                                     [RAM     ] <Default> Directly use it as an existing object in current R session               #
#   |                                     [R       ]           Try to import as R-Data                                                  #
#   |                                     [SAS     ]           Try to import via [haven::read_sas]                                      #
#   |                [$DF_NAME        ] : For some cases, such as [$DatType=R] there should be such an additional field indicating the  #
#   |                                      name of data.frame stored in the data file (i.e. container) for loading                      #
#   |                                     [NULL    ] <Default> No need if [$DatType] indicates the data is an object instead of a       #
#   |                                                           container with many objects                                             #
#   |                [$.trans         ] : Named list/vector to translate strings within the configuration to resolve the actual data    #
#   |                                      file name for process                                                                        #
#   |                                     [<preset>] <Default> Same as the universal parameter [fTrans]                                 #
#   |                                     [<list>  ]           A named list/vector for date value translation                           #
#   |                [$.trans.opt     ] : Additional options for value translation on [$.trans], see document for                       #
#   |                                      [AdvOp$apply_MapVal]                                                                         #
#   |                                     [<preset>] <Default> Same as the universal parameter [fTrans.opt]                             #
#   |                                     [<list>  ]           Use alternative options as provided by a list, see documents of          #
#   |                                                           [apply_MapVal]                                                          #
#   |                [$.imp.opt       ] : List of options during the data file import for different engines; each element of it is a    #
#   |                                      separate list, too. See the definition for the similar parameter [fImp.opt]                  #
#   |                                     [$SAS    ] <Default> Options for [haven::read_sas]                                            #
#   |                                     [<list>  ]           A named list for different engines, such as [R=list()] and [HDFS=list()] #
#   |                [$.func          ] : Function as pre-process before merging to KPI data; its first argument MUST take a            #
#   |                                      data.frame-like object                                                                       #
#   |                                     [NULL    ] <Default> No pre-process is applied to the Information Table                       #
#   |                                     [<func>  ]           An object of function to call                                            #
#   |                [$.func.opt      ] : Additional arguments to [$.func], provided as a named [list]                                  #
#   |                                     [NULL    ] <Default> No additional argument is required for [$.func]                          #
#   |                                     [<list>  ]           A named list acting as additional arguments to [$.func]                  #
#   |SingleInf   :   Whether it is only requested to use one Information Table to merge to all KPI data                                 #
#   |                [FALSE           ]  <Default> Information Table is also a time series input with snapshots on all provided dates   #
#   |                [TRUE            ]            There is only one Information Table to merge to all KPI data                         #
#   |dnDates     :   Vector/list of dates as character strings in the format [YYYYMMDD] (or: [%Y%m%d]) for time series process          #
#   |                [NULL            ]  <Default> Abort the program as there is no request for data extraction                         #
#   |                [<vec/list>      ]            Process the data files for the dates as indicated                                    #
#   |ColRecDate  :   Name of the column as [Date of Record] in the output data that indicates on which date the data record is obtained #
#   |                [D_RecDate       ]  <Default> Please take care of the character cases of this column name when using it            #
#   |                [<chr. string>   ]            Only a single character string is accepted; the first is taken if a vector is        #
#   |                                               provided with a warning message                                                     #
#   |MergeProc   :   In which type to merge the data                                                                                    #
#   |                [SET             ]  <Default> Conduct the [DBuse_SetKPItoInf] process for all provided dates                       #
#   |                [MERGE           ]            Conduct the [DBuse_MrgKPItoInf] process for all provided dates                       #
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
#   |                Default: [(See the function definition)]                                                                           #
#   |                [IMPORTANT] Below local variables are created to denote respective date values during the loop of data retrieval,  #
#   |                             hence please put them on the right side (i.e. values side) of this parameter to conduct translation.  #
#   |                [L_d_curr        ]            Denote each of the input [dnDates] within the loop, in the format [%Y%m%d]           #
#   |                [L_m_curr        ]            Denote each of the input [dnDates] within the loop, in the format [%Y%m]             #
#   |fTrans.opt  :   Additional options for value translation on [fTrans], see document for [AdvOp$apply_MapVal]                        #
#   |                [<See Func Def.> ]  <Default> The default options in [apply_MapVal]                                                #
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
#   |omniR.ini   :   Initialization configuration script to load all user defined function in [omniR] when [.parallel=T]                #
#   |                [D:/R/autoexec.r ]  <Default> Parallel mode requires standalone environment hence we need to load [omniR] inside   #
#   |                                               each batch of [%dopar%] to enable the dependent functions separately                #
#   |                [NULL            ]            No need when [.parallel=F]                                                           #
#   |cores       :   Number of system cores to read the data files in parallel                                                          #
#   |                Default: [4]                                                                                                       #
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
#   |                [data            ] [data.frame] that stores the result in terms of [MergeProc]:                                    #
#   |                                   [SET  ] Stores the result with columns including those in the same names as in [InfDat] if it is#
#   |                                            provided with their values determined by [KeepInfCol], as well as all available columns#
#   |                                            in all KPI data files                                                                  #
#   |                                   [MERGE] Stores the result with columns including [available KPIs] and the pivoting [ID]s        #
#   |                                            determined as:                                                                         #
#   |                                           [1] If [InfDat] is not provided, we only use [AggrBy] as [ID] during pivoting           #
#   |                                           [2] If [InfDat] is provided:                                                            #
#   |                                               [1] If [AggrBy] has the same values as [keyvar], we add to [AggrBy] by all other    #
#   |                                                    columns than [keyvar] in [InfDat] as [ID]                                      #
#   |                                               [2] Otherwise we follow the rule when [InfDat] is not provided                      #
#   |                [ <miss.files>   ] [NULL] if all data files are successfully loaded, or [data.frame] that contains the paths to the#
#   |                                    data files that are required but missing                                                       #
#   |                [ <err.cols>     ] [NULL] if all KPI data are successfully loaded, or [data.frame] that contains the column names  #
#   |                                    as well as the data files in which they are located, which cannot be concatenated due to       #
#   |                                    different [dtypes]                                                                             #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210131        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   | Log  |[1] Rewrite the verification part of data file existence, by introducing [AdvDB$parseDatName] as standardization            #
#   |      |[2] Introduce an argument [outDTfmt] aligning above change, to bridge the mapping from [fTrans] to the date series          #
#   |      |[3] Correct the part of frame lookup when assigning values to global variables for user request                             #
#   |      |[4] Change the output into a [list] to store all results, including debug facilities, to avoid pollution in global          #
#   |      |     environment                                                                                                            #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20220314        | Version | 2.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug that always raise error when there are multiple paths provided for [InfDatCfg] and [InfDat] does not exist  #
#   |      |     in any among them                                                                                                      #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230114        | Version | 2.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce a function [match.arg.x] to enable matching args after mutation, e.g. case-insensitive match                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230811        | Version | 2.30        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <rlang::exec> to simplify the function call with spliced arguments                                            #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240223        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |magrittr, rlang, dplyr, haven, doParallel, foreach, purrr, vctrs, glue                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |debug_comp_datcols                                                                                                         #
#   |   |   |match.arg.x                                                                                                                #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvDB                                                                                                                          #
#   |   |   |DataIO                                                                                                                     #
#   |   |   |parseDatName                                                                                                               #
#   |   |   |DBuse_SetKPItoInf                                                                                                          #
#   |   |   |DBuse_MrgKPItoInf                                                                                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	magrittr, rlang, dplyr, haven, doParallel, foreach, purrr, vctrs, glue
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

DBuse_GetTimeSeriesForKpi <- function(
	inKPICfg
	,InfDatCfg = list(
		InfDat = NULL
		,.paths = NULL
		,DatType = c('RAM','R','SAS')
		,DF_NAME = NULL
		,.trans = fTrans
		,.trans.opt = fTrans.opt
		,.imp.opt = list(
			SAS = list(
				encoding = 'GB2312'
			)
		)
		,.func = NULL
		,.func.opt = NULL
	)
	,SingleInf = F
	,dnDates = NULL
	,ColRecDate = 'D_RecDate'
	,MergeProc = c('SET','MERGE')
	,keyvar = NULL
	,SetAsBase = c('I','K','B','F')
	,KeepInfCol = F
	,fTrans = list(
		'&c_date.' = 'L_d_curr'
		,'&L_curdate.' = 'L_d_curr'
		,'&L_curMon.' = 'L_m_curr'
		,'&L_prevMon.' = 'L_m_curr'
	)
	,fTrans.opt = list(
		PRX = c(F,F,F,F)
		,fPartial = T
		,full.match = F
		,ignore.case = T
	)
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
	if (!is.logical(SingleInf)) SingleInf <- F
	if (length(dnDates)==0) stop('[',LfuncName,']','[dnDates] is not provided!')
	dnDates <- unname(unlist(dnDates))
	d_Dates <- asDates(dnDates)
	if (any(is.na(d_Dates))) {
		invdates <- dnDates[is.na(d_Dates)]
		stop('[',LfuncName,']','Some values among [dnDates] cannot be converted to dates! [',paste0(invdates, collapse = ']['),']')
	}
	if (length(ColRecDate)==0) ColRecDate <- 'D_RecDate'
	MergeProc <- match.arg.x(MergeProc, arg.func = toupper)
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
	if (length(AggrBy)==0) AggrBy <- keyvar
	AggrBy <- toupper(unname(unlist(AggrBy)))
	if (length(values_fn)==0) values_fn <- sum
	#Abort the process if there is no column to conduct the pivoting
	if (MergeProc=='MERGE') if (length(AggrBy)==0) stop('[',LfuncName,']','[AggrBy] is not provided for pivoting!')
	#We set the verification of below parameter to the last, for there could be reference to the rest of universal parameters
	if (length(InfDatCfg)==0) InfDatCfg <- list()
	if (!is.null(InfDatCfg$InfDat)) {
		err_keyvar <- F
		if (is.null(keyvar)) err_keyvar <- T
		else if (length(keyvar)==0) err_keyvar <- T
		if (err_keyvar) stop('[',LfuncName,']','[keyvar] is not provided for mapping to [InfDat]!')
		keyvar <- toupper(unname(unlist(keyvar)))
	}
	#Below statements are copied from [dplyr::bind_rows]
	dots <- rlang::list2(...)

	#021. Instantiate the IO operator for data migration
	dataIO <- do.call(DataIO$new, kw_DataIO)

	#050. Local environment
	#Below function supports to force variable names on its LHS, see [!!!] in [rlang]
	outDict = rlang::list2(
		'data' = NULL
		,!!dup.KPIs := NULL
		,!!miss.files := NULL
		,!!err.cols := NULL
	)
	f_ts_errors <- FALSE
	trans_var <- c('C_KPI_FULL_PATH', 'C_KPI_FILE_NAME', 'C_KPI_SHORTNAME')
	if ('C_KPI_BIZNAME' %in% names(inKPICfg)) trans_var <- c(trans_var, 'C_KPI_BIZNAME')
	GTSFK_getFunc <- list(
		SET = 'DBuse_SetKPItoInf'
		,MERGE = 'DBuse_MrgKPItoInf'
	)
	if (is.list(fImp.opt)) {
		opt_ram <- fImp.opt[['RAM']]
		if (!is.null(opt_ram)) {
			opt_ram <- list(exist.Opt = rep_len(list(opt_ram), nrow(inKPICfg)))
		}
	} else if (fImp.opt %in% colnames(inKPICfg)) {
		opt_ram <- list(exist.Opt = inKPICfg[[fImp.opt]])
	} else {
		stop(glue::glue(
			'[{LfuncName}]<fImp.opt> must be list or existing name in <inKPICfg>'
			,', given <{str(fImp.opt)}> as class <{toString(class(fImp.opt))}>'
		))
	}

	#060. Handle the configuration for Information Tables
	cfg_local <- InfDatCfg
	formal.args <- formals()
	dattype_choices <- eval(formal.args$InfDatCfg$DatType)
	DatType <- match.arg.x(cfg_local$DatType, dattype_choices, arg.func = toupper)
	imp_df <- cfg_local$DF_NAME
	if (is.null(cfg_local$.trans)) cfg_local$.trans <- fTrans
	if (is.null(cfg_local$.trans.opt)) cfg_local$.trans.opt <- fTrans.opt

	#061. Prepare function to join paths by recognizing the names in RAM
	safe_path <- function(fparent,fname) {
		psep <- '[\\\\/\\s]+'
		fname_int <- gsub(paste0('^', psep), '', fname)
		rstOut <- file.path(gsub(paste0(psep, '$'), '', fparent), fname_int)
		parent_empty <- nchar(fparent) == 0
		parent_empty[is.na(parent_empty)] <- T
		rstOut[parent_empty] <- fname_int[parent_empty]
		return(rstOut)
	}

	#065. Combine the file path
	if (length(cfg_local$.paths)>0) {
		InfDat_path <- safe_path(unlist(cfg_local$.paths), cfg_local$InfDat)
	} else {
		InfDat_path <- cfg_local$InfDat
	}

	#099. Debug mode
	if (fDebug){
		message('[',LfuncName,']','Debug mode...')
		message('[',LfuncName,']','Parameters are listed as below:')
		#[Quote: https://stackoverflow.com/questions/11885207/get-all-parameters-as-list ]
		# args_in <- allargs()
		args_in <- c(as.list(environment()), list(...))
		args_names <- names(args_in)
		for (m in seq_along(args_in)) {
			message('[',LfuncName,']','Structure: [',args_names[[m]],']:')
			message('[',LfuncName,']','End of structure: [',args_names[[m]],']',str(args_in[[m]]))
		}
	}

	#300. Define helper functions
	#310. Prepare to import the Information Table
	GTSFK_getInfDat <- function(i){
		#100. Set parameters
		InfDat <- InfDat_exist[i, 'datPtn.Parsed'] %>% unlist(recursive = F)

		#500. Prepare the function to apply to the process list
		dataIO$add(DatType)
		.opt_in <- list(
			'infile' = InfDat
			#For unification purpose, some APIs would omit below arguments
			,'key' = imp_df
		)
		.opt_this <- cfg_local[['.imp.opt']][[DatType]]
		if (is.null(.opt_this)) .opt_this <- list()
		.opt_in <- modifyList(.opt_in, .opt_this)

		#700. Call functions to import data from current path
		#710. Import the data
		imp_data <- do.call(dataIO[[DatType]]$pull, .opt_in)

		#750. Conduct pre-process as requested
		if (is.function(cfg_local$.func)){
			imp_data <- do.call(cfg_local$.func, append( list(imp_data), cfg_local$.func.opt )) %>%
				#900. Upcase the field names for all imported data, to facilitate the later [*join]
				#Ensure the field used at below steps are all referred to in upper case
				dplyr::rename_all(toupper)
		}

		#800. Assign additional attributes to the data frame for column class check at later steps
		attr(imp_data, 'DF_NAME') <- imp_df
		attr(imp_data, 'path.InfDat') <- InfDat

		#999. Return the result
		return(imp_data)
	}

	#350. Prepare to retrieve both the Information Table and KPI data files by period in parallel
	#[IMPORTANT] All functions (especially pipe operands), that are directly called from packages, should be activated INSIDE this
	#             one, either by [library] or [library::], since it is trying to distribute the tasks separately to different CPU
	#             cores and they will NOT know what to do from scratch.
	#[Quote: https://www.r-bloggers.com/2013/05/import-all-text-files-in-a-folder-with-parallel-execution/ ]
	GTSFK_parallel <- function(i){
		if (.parallel) {
			#001. Load necessary packages
			lst_pkg <- c( 'magrittr', 'rlang' , 'dplyr' , 'tidyselect', 'tidyr'
				#Below packages are further required by function [DBuse_SetKPItoInf]
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
		KPICfg <- kpiDat_exist %>% dplyr::filter(dates == d_Dates[[i]])

		#500. Retrieve the Information Table if requested
		if (!is.null(InfDatCfg$InfDat)) {
			if (SingleInf) {
				InfDat <- GTSFK_uni_Inf
			} else {
				InfDat <- GTSFK_getInfDat(i)
			}
		} else {
			InfDat <- NULL
		}

		#700. Conduct the merge process for current date
		#710. Prepare the primary parameter list for the function [DBuse_SetKPItoInf]
		#[1] [fTrans] and [fTrans.opt] are of no use as we have done the translation in the mapping table at earlier steps.
		curr_args <- list(
			KPICfg
			,InfDat = InfDat
			,keyvar = keyvar
			,SetAsBase = SetAsBase
			,KeepInfCol = KeepInfCol
			,fTrans = NULL
			,fTrans.opt = NULL
			,outDTfmt = outDTfmt
			,fImp.opt = fImp.opt
			,.parallel = .parallel
			,cores = cores
			,fDebug = fDebug
			,miss.skip = miss.skip
			,miss.files = miss.files
			,err.cols = err.cols
			,kw_DataIO = kw_DataIO
		)

		#730. Append those parameters for [DBuse_MrgKPItoInf] if any
		if (MergeProc %in% 'MERGE') {
			curr_args <- c(
				curr_args
				,list(
					dup.KPIs = dup.KPIs
					,AggrBy = AggrBy
					,values_fn = values_fn
				)
				,dots
			)
		}

		#739. Debug mode
		if (fDebug){
			message('[',LfuncName,']','Arguments for current iteration [i=',i,'][curr_args]...')
			message('[',LfuncName,']','Structure: [curr_args]:')
			message('[',LfuncName,']','End of structure: [curr_args]',str(curr_args))
		}
		# assign('testargs',curr_args,pos = globalenv())

		#790. Call the function as per request
		KPI_set <- do.call( GTSFK_getFunc[[MergeProc]], curr_args )

		#900. Assign additional attributes to the data frame for column class check at later steps
		KPI_set[['data']] %<>% dplyr::mutate( {{ ColRecDate }} := d_Dates[[i]] )
		attr(KPI_set[['data']], 'DF_NAME.InfDat') <- attr(InfDat, 'DF_NAME')
		attr(KPI_set[['data']], 'path.InfDat') <- attr(InfDat, 'path.InfDat')

		#999. Return the result
		return(KPI_set)
	}

	#400. Verify the existence of the Information Tables that are actually required
	if (!is.null(InfDatCfg$InfDat)) {
		#050. Determine the options to search for RAM objects if any
		if (DatType == 'RAM') {
			opt_inf_ram <- cfg_local$.imp.opt[['RAM']]
			if (!is.null(opt_inf_ram)) {
				opt_inf_ram <- list(exist.Opt = rep_len(list(opt_inf_ram), length(InfDat_path)))
			}
		} else {
			opt_inf_ram <- list()
		}

		#100. Parse the provided naming pattern
		if (SingleInf) dats_inf <- NULL
		else dats_inf <- d_Dates
		parse_infDat <- do.call(
			parseDatName
			,c(
				list(
					datPtn = InfDat_path
					,parseCol = NULL
					,dates = dats_inf
					,outDTfmt = outDTfmt
					,inRAM = (DatType == 'RAM')
					,chkExist = T
					,dict_map = cfg_local$.trans
				)
				,opt_inf_ram
				,cfg_local$.trans.opt
			)
		)

		#500. Verify the existence of the data files and only use the first one among the existing files
		#510. Find the first existing data file per group
		#Below statement is the same as [col_exist='datPtn.chkExist'], except that it demonstrates the usage of [.values]
		col_exist <- names(parse_infDat)[grepl('\\.chkExist$', names(parse_infDat), perl = T)]
		if (SingleInf) {
			InfDat_exist <- parse_infDat %>%
				dplyr::filter_at(col_exist, ~.) %>%
				#[slice_head()] works even if there is no observation that can be extracted
				dplyr::slice_head()

			#Find the missing data files
			InfDat_miss <- parse_infDat %>%
				dplyr::anti_join(
					InfDat_exist %>% dplyr::select_at('datPtn') %>% unique()
				) %>%
				suppressMessages()
		} else {
			InfDat_exist <- parse_infDat %>%
				dplyr::filter_at(col_exist, ~.) %>%
				dplyr::group_by_at('dates') %>%
				#[slice_head()] works even if there is no observation that can be extracted
				dplyr::slice_head() %>%
				dplyr::ungroup()

			#Find the missing data files
			InfDat_miss <- parse_infDat %>%
				dplyr::anti_join(
					InfDat_exist %>% dplyr::select_at('dates') %>% unique()
				) %>%
				suppressMessages()
		}

		#559. Abort if there is any one not found as Information Table is not skippable once requested
		if (nrow(InfDat_miss) > 0) {
			#001. Print messages
			message('[',LfuncName,']','Below files of Information Table are requested but do not exist in the parsed path(s).')
			message(InfDat_miss %>% dplyr::select_at(c('datPtn', 'datPtn.Parsed')))

			#500. Output a global data frame storing the information of the missing files
			outDict[[miss.files]] <- InfDat_miss

			#999. Abort the process
			warning('[',LfuncName,']','Non-existence of Information Table cannot be skipped!')
			warning('[',LfuncName,']','Check the data frame [',miss.files,'] in the output result for missing files!')
			return(outDict)
		}

		#900. Only read the source of Information Table once if requested, to minimize work load
		if (SingleInf) GTSFK_uni_Inf <- GTSFK_getInfDat(1)
	}

	#500. Verify the existence of the KPI data files that are actually required
	#501. Define the full path of data files
	KPICfg <- inKPICfg %>%
		dplyr::mutate(
			C_KPI_FULL_PATH = safe_path(C_LIB_PATH, C_KPI_FILE_NAME)
		)

	#510. Parse the provided naming pattern
	#[ASSUMPTION]:
	#[1] [inRAM=FALSE] All requested data files are on harddisk, rather than in RAM of current session
	#[2] Keep all columns for determination of uniqueness
	parse_kpiDat <- do.call(
		parseDatName
		,c(
			list(
				datPtn = KPICfg
				,parseCol = trans_var
				,dates = d_Dates
				,outDTfmt = outDTfmt
				,inRAM = (
					KPICfg %>%
						dplyr::mutate_at(trans_var, ~F) %>%
						dplyr::mutate(
							!!rlang::sym('C_KPI_FULL_PATH') := !!rlang::sym('C_KPI_FILE_TYPE') == 'RAM'
						) %>%
						dplyr::select(tidyselect::all_of(trans_var))
				)
				,chkExist = T
				,dict_map = fTrans
			)
			,opt_ram
			,fTrans.opt
		)
	)

	#520. Set the useful columns to their parsed values for further data retrieval
	parse_kpiDat[trans_var] <- parse_kpiDat[paste0(trans_var, '.Parsed')]

	#550. Verify the existence of the data files and only use the first one among the existing files for each KPI on each date
	#[ASSUMPTION]:
	#[1] Use [N_LIB_PATH_SEQ] to identify the first valid path in which the KPI data file on current date is located
	kpiDat_exist <- parse_kpiDat %>%
		dplyr::filter_at('C_KPI_FULL_PATH.chkExist', ~.) %>%
		dplyr::group_by_at(c('C_KPI_ID', 'dates')) %>%
		dplyr::slice_min(N_LIB_PATH_SEQ) %>%
		dplyr::ungroup()

	#559. Abort the process if there is no data file found anywhere
	if (nrow(kpiDat_exist) == 0) {
		#500. Output a global data frame storing the information of the missing files
		outDict[[miss.files]] <- parse_kpiDat

		#999. Abort the process
		warning('[',LfuncName,']','There is no KPI data file found in any of the parsed paths!')
		warning('[',LfuncName,']','Check the data frame [',miss.files,'] in the output result for missing files!')
		return(outDict)
	}

	#580. Find the missing data files
	kpiDat_miss <- parse_kpiDat %>%
		dplyr::anti_join(
			kpiDat_exist %>% dplyr::select_at(c('C_KPI_ID', 'dates')) %>% unique()
		) %>%
		suppressMessages()

	#589. Abort the process if it is requested not to skip the missing KPI data files
	if (nrow(kpiDat_miss) > 0) {
		#001. Print messages
		message('[',LfuncName,']','Below KPI data files are requested but do not exist in the parsed path(s).')
		message(kpiDat_miss %>% dplyr::select_at(c('C_KPI_ID', 'dates', 'C_KPI_FULL_PATH')))

		#500. Output a global data frame storing the information of the missing files
		outDict[[miss.files]] <- kpiDat_miss

		#999. Abort the process
		if (!miss.skip) {
			warning('[',LfuncName,']','User requests not to skip the missing files!')
			warning('[',LfuncName,']','Check the data frame [',miss.files,'] in the output result for missing files!')
			return(outDict)
		}
	}

	#700. Loop all provided date series to retrieve KPI data
	#701. Debug mode
	if (fDebug){
		message(glue::glue('[{LfuncName}]Import data files in {ifelse(.parallel, "Parallel", "Sequential")} mode...'))
	}

	#[IMPOTANT] There could be fields/columns in the same name but not the same types in different data files,
	#            but we throw the errors at the step [dplyr::bind_rows] to ask user to correct the input data,
	#            instead of guessing the correct types here, for it takes quite a lot of unnecessary effort.
	if (.parallel) {
		#100. Set the cores to be used
		doParallel::registerDoParallel(cores = cores)

		#900. Read the files and combine them by rows
		#We do not directly combine the data, for there may be columns with different classes.
		# GTSFK_import <- foreach::foreach( i = seq_along(dnDates), .combine = dplyr::bind_rows ) %dopar% func_parallel(i)
		GTSFK_import <- foreach::foreach( i = seq_along(dnDates) ) %dopar% GTSFK_parallel(i)

		#990. Ensure the process is closed
		#Quote: https://www.r-bloggers.com/2015/02/how-to-go-parallel-in-r-basics-tips/
		doParallel::stopImplicitCluster()
	} else {
		#900. Read the files sequentially
		#We do not directly combine the data, for there may be columns with different classes.
		# GTSFK_import <- lapply( seq_along(dnDates), func_parallel ) %>% dplyr::bind_rows()
		GTSFK_import <- lapply( seq_along(dnDates), GTSFK_parallel )
	}

	#750. Check the list of imported data on the classes of columns
	#[IMPORTANT] Attributes of columns in KPI data files have lost during the retrieval, hence if there is any column that
	#             has different classes among the KPI data files on different dates, it cannot be clarified here.
	names(GTSFK_import) <- d_Dates %>% strftime('%Y%m%d')
	GTSFK_chk_cls <- debug_comp_datcols(
		lapply(
			GTSFK_import
			,function(x){x[['data']]}
		)
		,with.attr = c('DF_NAME.InfDat', 'path.InfDat')
	)

	#759. Abort the program if any inconsistency is found on columns of data frames among the [requested dates]
	#We do not directly abort the program, for we need more error information for debug at once
	if (nrow(GTSFK_chk_cls) > 0) {
		outDict[[err.cols]] <- GTSFK_chk_cls
		warning('[',LfuncName,']','Some columns cannot be bound due to different classes between different dates!')
		warning('[',LfuncName,']','Check data frame [',err.cols,'] in the output result for these columns!')
		f_ts_errors <- T
	}

	#790. Abort the program for certain conditions
	#791. Abort if any duplications are found on [C_KPI_SHORTNAME]
	if (MergeProc == 'MERGE') {
		if (!all(sapply(GTSFK_import, function(x){is.null(x[['dup.KPIs']])}))) {
			#001. Print messages
			warning('[',LfuncName,']','Below [C_KPI_SHORTNAME] are applied to more than 1 columns!')
			qc_KPI_id <- lapply(GTSFK_import, function(x){x[['dup.KPIs']]}) %>%
				dplyr::bind_rows() %>%
				dplyr::distinct_all()
			message(qc_KPI_id)

			#500. Output a global data frame storing the information of the duplicated [C_KPI_SHORTNAME]
			outDict[[dup.KPIs]] <- qc_KPI_id

			#999. Abort the process
			warning('[',LfuncName,']','Check data frame [',dup.KPIs,'] in the output result for duplications!')
			f_ts_errors <- T
		}
	}

	#797. Abort if any columns cannot be concatenated among the KPI data on [each date]
	if (!all(sapply(GTSFK_import, function(x){is.null(x[['err.cols']])}))) {
		#001. Print messages
		#[ASSUMPTION]:
		#[1] [simplify=FALSE] This prevents the data frames from being combined to [matrix], as we will do it later
		#[2] [USE.NAMES=TRUE] <Default> This provides the [names] for each member generated from [sapply]
		#[3] [bind_rows] will assign the [names] of the members in the input list to the newly created column [.id]
		qc_err_cols <- sapply(GTSFK_import, function(x){x[['err.cols']]}, simplify = F) %>%
			dplyr::bind_rows(.id = 'name_error')
		message(qc_err_cols)

		#500. Output a global data frame storing the information of the column inconsistency
		outDict[[err.cols]] %<>% dplyr::bind_rows(qc_err_cols)

		#999. Abort the process
		warning('[',LfuncName,']','Some columns cannot be bound due to different classes between the sources on the same date(s)!')
		warning('[',LfuncName,']','Check data frame [',err.cols,'] in the output result for these columns!')
		f_ts_errors <- T
	}

	#799. Abort if the flag of errors is True
	if (f_ts_errors) return(outDict)

	#800. Combine the data
	GTSFK_combine <- dplyr::bind_rows(lapply(GTSFK_import, function(x){x[['data']]}))

	#850. Fill the [NA] values with the requested ones if there are still any during the concatenation of data frames
	if ( (MergeProc %in% 'MERGE') & ('values_fill' %in% names(dots)) ) {
		#100. Retrieve the KPI name list from the input configuration
		cols_kpi <- inKPICfg %>% dplyr::select(C_KPI_SHORTNAME) %>% unlist() %>% unique()

		#500. [ToDo] We presume there is only one column [A_KPI_VAL] to be pivoted
		val_fill <- dots$values_fill$A_KPI_VAL
		if (is.null(val_fill)) val_fill <- dots$values_fill

		#900. Fill the [NaN] values of the KPIs with the requested values
		GTSFK_combine %<>% dplyr::mutate_at( cols_kpi, ~ifelse( is.na(.) | is.null(.), val_fill, . ) )
	}

	#999. Return the table
	outDict[['data']] <- GTSFK_combine
	return(outDict)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')
		#Below system options are defined in [autoexec.r]

		#100. Set parameters
		G_d_bgn <- '20160301'
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

		#150. Prepare the date list
		#Below function is from [Dates]
		cln <- UserCalendar$new(
			G_d_bgn
			, G_d_curr
			, clnBgn = '20160101'
			, countrycode = getOption('CountryCode')
			, CalendarAdj = getOption('ClndrAdj')
		)
		cln$fmtDateOut <- '%Y%m%d'

		#300. Read the KPI data
		#310. Prepare the modification upon the default arguments with current business requirements
		args.GTSFK <- modifyList(
			getOption('args.def.GTSFK')
			,list(
				inKPICfg = KPICfg_all
				,InfDatCfg = list(
					InfDat = 'acctinfo'
					,.paths = NULL
					,DatType = 'RAM'
					,.imp.opt = list(
						'RAM' = list(
							'frame' = environment()
						)
					)
					#Below is a demo, please modify the function where necessary
					,.func = function(df, ...){
						dots <- list(...)
						str(dots)
						return(df)
					}
					#Below option is used for the function defined above; [...] in this case
					,.func.opt = list(
						a = 1
						,b = 2
					)
				)
				,SingleInf = T
				,dnDates = cln$d_AllWD
				,MergeProc = 'MERGE'
				,keyvar = c('nc_cifno','nc_acct_no')
				,SetAsBase = 'I'
				#It is tested on 20210131 that:
				#[1] Process in parallel would fail due to lack of resources
				#[2] Process in parallel for small number of small data files are MUCH SLOWER than sequential mode
				,.parallel = F
				,fDebug = F
			)
		)
		str(args.GTSFK)

		#350. Test the timing
		time_bgn <- Sys.time()
		KPI_ts <- do.call( DBuse_GetTimeSeriesForKpi, args.GTSFK )
		time_end <- Sys.time()
		print(time_end - time_bgn)

		View(KPI_ts[['data']])

		#500. Test part of the function
		#Below function is from: [AdvOp]
		gen_locals(
			LfuncName = 'DBuse_GetTimeSeriesForKpi'
			,inKPICfg = KPICfg_all
			,InfDatCfg = list(
				InfDat = 'acctinfo'
				,.paths = NULL
				,DatType = 'RAM'
				,DF_NAME = NULL
				,.trans = getOption('fmt.def.GTSFK')
				,.trans.opt = getOption('fmt.opt.def.GTSFK')
				,.imp.opt = list(
					SAS = list(
						encoding = 'GB2312'
					)
				)
				,.func = NULL
				,.func.opt = NULL
			)
			,SingleInf = T
			,dnDates = cln$d_AllWD
			,ColRecDate = 'D_RecDate'
			,MergeProc = c('SET','MERGE')
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
			,.parallel = F
			,cores = 4
			,omniR.ini = 'D:\\R\\autoexec.r'
			,fDebug = F
			,miss.skip = T
			,miss.files = 'G_miss_files'
			,err.cols = 'G_err_cols'
			,dup.KPIs = 'G_dup_kpiname'
			,AggrBy = 'nc_cifno'
			,values_fn = sum
			,values_fill = list(A_KPI_VAL = 0)
		)
		if (T){
			message('Copy any part in the function definition to test it here:')
			message(.parallel)
		}

		#600. Test if there is no [InfDat]
		args.GTSFK2 <- list(
			inKPICfg = KPICfg_all
			,dnDates = cln$d_AllWD
			,ColRecDate = 'D_RecDate'
			,MergeProc = 'MERGE'
			,keyvar = c('nc_cifno','nc_acct_no')
			,SetAsBase = 'k'
			,KeepInfCol = F
			,fTrans = getOption('fmt.def.GTSFK')
			,fTrans.opt = getOption('fmt.opt.def.GTSFK')
			,fImp.opt = list(
				SAS = list(
					encoding = 'GB2312'
				)
			)
			,.parallel = F
			,cores = 4
			,omniR.ini = 'D:\\R\\autoexec.r'
			,fDebug = F
			,miss.skip = T
			,miss.files = 'G_miss_files'
			,err.cols = 'G_err_cols'
			,dup.KPIs = 'G_dup_kpiname'
			,AggrBy = NULL
			,values_fn = sum
			,values_fill = list(A_KPI_VAL = 0)
		)
		time_bgn <- Sys.time()
		KPI_ts2 <- do.call( DBuse_GetTimeSeriesForKpi, args.GTSFK2 )
		time_end <- Sys.time()
		print(time_end - time_bgn)

		View(KPI_ts2[['data']])

	}
}
