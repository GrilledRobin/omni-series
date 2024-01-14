#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to calculate the summary stats for each respective group of [byVar] by the provided aggregation function #
#   | [funcAggr] in terms of a time-series data source based on indication of calculation for Calendar Days, Workdays or Tradedays      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |It is used to minimize the computer resource consumption when the process is conducted on a daily basis, for it can leverage the   #
#   | calculated result of the previous workday to calculate the value of current day, prior to the aggregation of all datasets in the  #
#   | given period of time.                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |IMPORTANT:                                                                                                                         #
#   |[1] If there is any Descriptive Information in the series of input datasets, the Last Existing one will be kept in the output      #
#   |     dataset. E.g. if a customer only exists from 1st to 15th in a month, his/her status on 15th will be kept in the output data.  #
#   |[2] If there are multiple rows for the same [byVar] in a single import data (i.e. the daily snapshot of database), their [aggrVar] #
#   |     will be aggregated by [sum] in the first place, before being merged to other data in the series. This is to avoid uncertainty.#
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Calculate the Date-to-Date average value of the KPI, such as ANR (i.e. Average Net Receivables)                                #
#   |[2] Identify the maximum or minimum value of the KPI over the period                                                               #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |110.   Input dataset information: (Daily snapshot of database)                                                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inDatPtn   :   Naming pattern of the series of datasets for calculation (such as Daily Account Balances)                           #
#   |               [IMPORTANT] If a data.frame is provided, it MUST match below naming convention:                                     #
#   |               |------------------------------------------------------------------------------------------------------------------ #
#   |               |Column Name     |Required?  |Description                                                                           #
#   |               |----------------+-----------+--------------------------------------------------------------------------------------#
#   |               |FileName        |Yes        | The naming pattern of data files to be located in the candidate paths                #
#   |               |FilePath        |Yes        | The naming pattern of the candidate paths to store the data (incl. file name)        #
#   |               |PathSeq         |Yes        | The sequence of candidate paths to search for the data file. Should the same data    #
#   |               |                |           |  exist in many among these paths, the one with the smaller [PathSeq] is retrieved    #
#   |               |[inDatType]     |Yes        | The types of data files that indicates the method for this function to import data   #
#   |               |                |           | [RAM     ] Try to load the data frame from RAM in current session                    #
#   |               |                |           | [R       ] Try to import as RData file                                               #
#   |               |                |           | [SAS     ] Try to import via [pyreadstat.read_sas7bdat]                              #
#   |               |[in_df]         |No         | For some cases, such as [inDatType=R] there should be such an additional field       #
#   |               |                |           |  indicating the name of data.frame stored in the data file (i.e. container)          #
#   |               |                |           | It is required if [inDatType] on any record is [R]                                   #
#   |               |----------------+-----------+--------------------------------------------------------------------------------------#
#   |               [--> IMPORTANT  <--] Program will translate several columns in below way as per requested by [fTrans], see local    #
#   |                                     variable [trans_var].                                                                         #
#   |                                    [1] [fTrans] is NOT provided: assume that the value in this field is a valid file path         #
#   |                                    [2] [fTrans] is provided a named list or vector: Translate the special strings in accordance   #
#   |                                          as data file names. in such case, names of the provided parameter are treated as strings #
#   |                                          to be replaced; while the values of the provided parameter are treated as variables in   #
#   |                                          the parent environment and are [get]ed for translation, e.g.:                            #
#   |                                        [1] ['&c_date.' = 'G_d_curr'  ] Current reporting/data date in SAS syntax [&c_date.] to be #
#   |                                              translated by the value of Python variable [G_d_curr] in the parent frame            #
#   |               |------------------------------------------------------------------------------------------------------------------ #
#   |inDatType  :   The type of data files that indicates the method for this function to import data                                   #
#   |               [SAS             ] <Default> Try to import as the SAS dataset                                                       #
#   |               [RAM             ]           Try to load the data frame from RAM in current environment                             #
#   |               [R               ]           Try to import as R-Data                                                                #
#   |               [<column name>   ]           Column name indicating the data file type if [inDatPtn] is provided a data.frame       #
#   |in_df      :   For some containers, such as [inDatType=R] we should provide the name of data.frame stored inside it for loading    #
#   |               [NULL            ] <Default> No need for default SAS data loading                                                   #
#   |               [<column name>   ]           Column name indicating the data key if [inDatPtn] is provided a pd.DataFrame           #
#   |fImp.opt   :   List of options during the data file import for different engines; each element of it is a separate list, too       #
#   |               Valid names of the option lists are set in the argument [inDatType]                                                 #
#   |               [$SAS            ] <Default> Options for [omniR$AdvDB$std_read_SAS]                                                 #
#   |                                            [$encoding = 'GB2312' ]  <Default> Read SAS data in this encoding                      #
#   |               [<name>=<list>   ]           Other named lists for different engines, such as [R=list()] and [HDFS=list()]          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |120.   Naming pattern translation/mapping                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |fTrans     :   Named list/vector to translate strings within the configuration to resolve the actual data file name for process    #
#   |               [NULL            ] <Default> For time series process, please ensure this argument is manually defined, otherwise    #
#   |                                             the result is highly unexpected                                                       #
#   |fTrans.opt :   Additional options for value translation on [fTrans], see document for [AdvOp$apply_MapVal]                         #
#   |               [NULL            ] <Default> Use default options in [apply_MapVal]                                                  #
#   |               [<list>          ]           Use alternative options as provided by a list, see documents of [apply_MapVal]         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |130.   Multi-processing support                                                                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |.parallel  :   Whether to load the data files in [Parallel]; it is useful for lots of large files, but may be slow for small ones  #
#   |               [TRUE            ] <Default> Use multiple CPU cores to load the data files in parallel                              #
#   |               [FALSE           ]           Load the data files sequentially                                                       #
#   |omniR.ini  :   Initialization configuration script to load all user defined function in [omniR] when [.parallel=T]                 #
#   |               [D:/R/autoexec.r ] <Default> Parallel mode requires standalone environment hence we need to load [omniR] inside     #
#   |                                             each batch of [%dopar%] to enable the dependent functions separately                  #
#   |               [NULL            ]           No need when [.parallel=F]                                                             #
#   |cores      :   Number of system cores to read the data files in parallel                                                           #
#   |               [4               ] <Default> No need when [.parallel=F]                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |150.   Calculation period control                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |dateBgn    :   Beginning of the calculation period. It will be converted to [Date] by [Dates$asDates] internally, hence please     #
#   |                follow the syntax of this function during input                                                                    #
#   |               [NULL            ] <Default> Function will raise error if it is NOT provided                                        #
#   |dateEnd    :   Ending of the calculation period. It will be converted to [Date] by [Dates$asDates] internally, hence please        #
#   |                follow the syntax of this function during input                                                                    #
#   |               [NULL            ] <Default> Function will raise error if it is NOT provided                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |160.   Retrieval of previously aggregated result for Checking Period                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |chkDatPtn  :   Naming pattern of the datasets that store the previously aggregated KPI for minimization of system effort, such as  #
#   |                MTD Daily Average Balance by Account                                                                               #
#   |               [IMPORTANT] This pattern will be translated by [fTrans], hence please ensure the correct convention                 #
#   |               [NULL            ] <Default> Function will not use existing results for performance improvement                     #
#   |chkDatType :   The type of data files for Checking Period that indicates the method for this function to import data               #
#   |               [SAS             ] <Default> Try to import as the SAS dataset                                                       #
#   |               [RAM             ]           Try to load the data frame from RAM in current environment                             #
#   |               [R               ]           Try to import as R-Data                                                                #
#   |chkDatVar  :   Variable name in the [data as of Checking Period], which is used for calculation in [Checking Period]               #
#   |               [NULL            ] <Default> Not in use if [Checking Period] is not involved, or raise error when required          #
#   |               [<str>           ]           Use this column to calculate [Leading Period] out of [Checking Period]                 #
#   |chkDat_df  :   For some containers, such as [inDatType=R] we should provide the name of data.frame stored inside it for loading    #
#   |               [NULL            ] <Default> No need for default SAS data loading                                                   #
#   |chkDat.opt :   List of options during the data file import for different engines; each element of it is a separate list, too       #
#   |               Valid names of the option lists are set in the field [inDatType]                                                    #
#   |               [$SAS            ] <Default> Options for [omniR$AdvDB$std_read_SAS]                                                 #
#   |                                            [$encoding = 'GB2312' ]  <Default> Read SAS data in this encoding                      #
#   |               [<name>=<list>   ]           Other named lists for different engines, such as [R=list()] and [HDFS=list()]          #
#   |chkBgn     :   Beginning of the Checking Period. It will be converted to [Date] by [Dates$asDates] internally, hence please        #
#   |                follow the syntax of this function during input                                                                    #
#   |               [NULL            ] <Default> Function will set it the same as [dateBgn]                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |170.   Column inclusion                                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |byVar      :   The list/vector of column names that are to be used as the group to aggregate the KPI                               #
#   |               [IMPORTANT] All these columns MUST exist in both [inDatPtn] and [chkDatPtn]                                         #
#   |               [NULL            ] <Default> Function will raise error if it is NOT provided                                        #
#   |copyVar    :   The list/vector of column names that are to be copied during the aggregation                                        #
#   |               [Note 1] All these columns MUST exist in both [inDatPtn] and [chkDatPtn]                                            #
#   |               [Note 2] Only those values in the Last Existing observation/record can be copied to the output                      #
#   |               [NULL            ] <Default> There is no additional column to be retained for the output                            #
#   |               [_all_           ]           Retain all related columns from all sources                                            #
#   |aggrVar    :   The single column name in [inDatPtn] that represents the value to be applied by function [funcAggr]                 #
#   |               [A_KPI_VAL       ] <Default> Function will aggregate this column                                                    #
#   |outVar     :   The single column name as the aggregated value in the output data                                                   #
#   |               [A_VAL_OUT       ] <Default> Function will output this column                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |180.   Indicators and methods for aggregation                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |genPHMul   :   Whether to generate the data on Public Holidays by resembling their respective Previous Workdays/Tradedays with     #
#   |                proper Multipliers, to minimize the system effort                                                                  #
#   |               [TRUE            ] <Default> Resemble the data on Public Holidays with their respective Previous Workdays/Tradedays #
#   |                                            in terms of the indicator [calcInd]                                                    #
#   |                                            [IMPORTANT] Function will ignore any existing data on Public Holidays                  #
#   |               [FALSE           ]           Function will NOT generate pseudo data for Public Holidays                             #
#   |                                            [IMPORTANT] Function will raise error if there is no existing data on Public Holidays  #
#   |calcInd    :   The indicator for the function to calculate based on Calendar Days, Workdays or Tradedays                           #
#   |               [C               ] <Default> Conduct calculation based on Calendar Days                                             #
#   |               [W               ]           Conduct calculation based on Workdays. Namingly, [genPHMul] will hence take no effect  #
#   |               [T               ]           Conduct calculation based on Tradedays. Namingly, [genPHMul] will hence take no effect #
#   |funcAggr   :   The function to aggregate the input time series data. It should be provided a [function]                            #
#   |               [mean            ] <Default> Calculate the average of [aggrVar] per [byVar] as a time series                        #
#   |               [<other aggr.>   ]           Other aggregation functions that are supported in current environment                  #
#   |                                            [IMPORTANT] One can define specific aggregation function and use it here               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |190.   Process control                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |fDebug     :   The switch of Debug Mode. Valid values are [F] or [T].                                                              #
#   |               [FALSE           ] <Default> Do not print debug messages during calculation                                         #
#   |               [TRUE            ]           Print debug messages during calculation                                                #
#   |miss.files :   Name of the global variable to store the debug data frame with missing file paths and names                         #
#   |               [G_miss_files    ] <Default> If any data files are missing, please check this global variable to see the details    #
#   |               [chr string      ]           User defined name of global variable that stores the debug information                 #
#   |err.cols   :   Name of the global variable to store the debug data frame with error column information                             #
#   |               [G_err_cols      ] <Default> If any columns are invalidated, please check this global variable to see the details   #
#   |               [chr string      ]           User defined name of global variable that stores the debug information                 #
#   |outDTfmt   :   Format of dates as string to be used for assigning values to the variables indicated in [fTrans]                    #
#   |               [ <vec/list>     ] <Default> See the function definition as the default argument of usage                           #
#   |...        :   Any other arguments that are required by [funcAggr]. Please check the documents for it before defining this one     #
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
#   | Date |    20210503        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210512        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Change the type of the argument [funcAggr] from [character string] into [function] for more generalization              #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210614        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Rewrite the verification part of data file existence, by introducing [omniR$AdvDB$parseDatName] as standardization      #
#   |      |[2] Introduce an argument [outDTfmt] aligning above change, to bridge the mapping from [fTrans] to the date series          #
#   |      |[3] Correct the part of frame lookup when assigning values to global variables for user request                             #
#   |      |[4] Change the output into a [list] to store all results, including debug facilities, to avoid pollution in global          #
#   |      |     environment                                                                                                            #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210828        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Now accept [inDatPtn] as a data.frame which contains patterns of data files in different candidate paths                #
#   |      |[2] If multiple [inDatPtn] are provided, each one must exist in at least one among the candidate paths                      #
#   |      |[3] Now execute in silent mode by default. If one needs to see the calculation progress, switch to [fDebug = TRUE]          #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20220815        | Version | 3.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug when [chkBgn] > [chkEnd] so that the program no longer tries to conduct calculation for Checking Period in  #
#   |      |     such case                                                                                                              #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20220917        | Version | 3.20        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Removed excessive calculation for Actual Calculation Period to simplify the logic                                       #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230111        | Version | 3.30        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug when [inDatCfg] is provided a pd.DataFrame while [in_df] is not specified                                   #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230114        | Version | 3.40        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce a function [match.arg.x] to enable matching args after mutation, e.g. case-insensitive match                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230811        | Version | 3.50        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <rlang::exec> to simplify the function call with spliced arguments                                            #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230815        | Version | 3.60        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <Recall> to make the recursion more intuitive                                                                 #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20231209        | Version | 3.70        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Enable defining <copyVar = '_all_'> to output all columns from all possible data sources                                #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240114        | Version | 3.80        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Aligned the searching logic for <chkEnd>, now facilitate the scenario: calculate rolling 10-day ANR only on workdays and#
#   |      |     need to leverage the result on the previous workday                                                                    #
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
#   |   |magrittr, rlang, dplyr, doParallel, foreach, tidyr, purrr                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$Dates                                                                                                                    #
#   |   |   |asDates                                                                                                                    #
#   |   |   |UserCalendar                                                                                                               #
#   |   |   |ObsDates                                                                                                                   #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvOp                                                                                                                    #
#   |   |   |apply_MapVal                                                                                                               #
#   |   |   |debug_comp_datcols                                                                                                         #
#   |   |   |isDF                                                                                                                       #
#   |   |   |match.arg.x                                                                                                                #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvDB                                                                                                                    #
#   |   |   |std_read_R                                                                                                                 #
#   |   |   |std_read_RAM                                                                                                               #
#   |   |   |std_read_SAS                                                                                                               #
#   |   |   |parseDatName                                                                                                               #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	magrittr, rlang, dplyr, doParallel, foreach, tidyr, purrr
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
#We should use [%dopar%] supported by below package
library(foreach)

aggrByPeriod <- function(
	inDatPtn = NULL
	,inDatType = c('SAS','R','RAM')
	,in_df = NULL
	,fImp.opt = list(
		SAS = list(
			encoding = 'GB2312'
		)
	)
	,fTrans = NULL
	,fTrans.opt = NULL
	,.parallel = T
	,omniR.ini = getOption('file.autoexec')
	,cores = 4
	,dateBgn = NULL
	,dateEnd = NULL
	,chkDatPtn = NULL
	,chkDatType = c('SAS','R','RAM')
	,chkDat_df = NULL
	,chkDat.opt = list(
		SAS = list(
			encoding = 'GB2312'
		)
	)
	,chkDatVar = NULL
	,chkBgn = NULL
	,byVar = NULL
	,copyVar = NULL
	,aggrVar = 'A_KPI_VAL'
	,outVar = 'A_VAL_OUT'
	,genPHMul = TRUE
	,calcInd = c('C','W','T')
	,funcAggr = mean
	,miss.files = 'G_miss_files'
	,err.cols = 'G_err_cols'
	,outDTfmt = list(
		'L_d_curr' = '%Y%m%d'
		,'L_m_curr' = '%Y%m'
	)
	,fDebug = FALSE
	,...
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	if (isDF(inDatPtn)) {
		if (!(inDatType %in% colnames(inDatPtn))) {
			stop('[',LfuncName,']','[inDatType] must be an existing column in the data frame [inDatPtn]')
		}
		if ('R' %in% unique(inDatPtn[[inDatType]])) {
			if (!(in_df %in% colnames(inDatPtn))) {
				stop('[',LfuncName,']','[in_df] must be an existing column in the data frame [inDatPtn]')
			}
		}
		inDatCfg <- inDatPtn
	} else {
		if (length(inDatPtn)==0) stop('[',LfuncName,']','[inDatPtn] is not provided!')
		if ((!is.character(inDatPtn)) | (length(inDatPtn)!=1)) stop('[',LfuncName,']','[inDatPtn] must be a single character string!')
		inDatType <- match.arg.x(inDatType, arg.func = toupper)
		if (inDatType=='R') {
			if (length(in_df)==0) stop('[',LfuncName,']','[in_df] is not provided for [inDatType=',inDatType,']!')
		}
		#Since [in_df] may be NULL, we can only create a data.frame and assign it at another step
		inDatCfg <- data.frame(
			FilePath = inDatPtn
			,PathSeq = 1
			,FileName = basename(inDatPtn)
			,FileType = inDatType
			,stringsAsFactors = F
		) %>%
			dplyr::mutate(DF_NAME = in_df)
	}
	if (!is.logical(.parallel)) .parallel <- F
	if (.parallel) {
		if (is.null(cores)) cores <- 4
	}
	if (length(dateBgn)==0) stop('[',LfuncName,']','[dateBgn] is not provided!')
	if (length(dateEnd)==0) stop('[',LfuncName,']','[dateEnd] is not provided!')
	if (length(chkDatPtn)>0) {
		if ((!is.character(chkDatPtn)) | (length(chkDatPtn)>1)) {
			stop('[',LfuncName,']','[chkDatPtn] must be a single character string!')
		}
	}
	chkDatType <- match.arg.x(chkDatType, arg.func = toupper)
	if (length(chkBgn)==0) {
		message('[',LfuncName,']','[chkBgn] is not provided. It will be set the same as [dateBgn].')
		chkBgn <- dateBgn
	}
	if (chkDatType=='R') {
		if (length(chkDat_df)==0) stop('[',LfuncName,']','[chkDat_df] is not provided for [chkDatType=',chkDatType,']!')
	}
	if (length(byVar)==0) stop('[',LfuncName,']','[byVar] is not provided!')
	if (length(aggrVar)==0) {
		aggrVar <- 'A_KPI_VAL'
		message('[',LfuncName,']','[aggrVar] is not provided, use the default one [',aggrVar,'] instead.')
	}
	if (!is.logical(genPHMul)) {
		message(
			'[',LfuncName,']','[genPHMul] is not provided as logical value.'
			,' Program resembles the data on Public Holidays by their respective Previous Workdays.'
		)
		genPHMul <- T
	}
	calcInd <- match.arg.x(calcInd, arg.func = toupper)
	if (!is.function(funcAggr)) stop('[',LfuncName,']','[funcAggr] should be provided a function!')
	if (!is.logical(fDebug)) fDebug <- F
	if (length(outVar)==0) outVar <- 'A_VAL_OUT'
	if (length(miss.files)==0) miss.files <- 'G_miss_files'
	if (length(err.cols)==0) err.cols <- 'G_err_cols'

	#020. Local environment
	byVar <- unlist(byVar)
	copyVar <- unlist(copyVar)
	outVar <- unlist(outVar)
	miss.files <- unlist(miss.files)
	err.cols <- unlist(err.cols)
	if ('_ALL_' %in% toupper(copyVar)) {
		keep_all_col <- T
	} else {
		keep_all_col <- F
	}
	indat_col_parse <- 'FilePath'
	indat_col_file <- 'FileName'
	indat_col_dirseq <- 'PathSeq'
	indat_col_date <- 'dates'
	if (isDF(inDatPtn)) {
		indat_col_type <- inDatType
		if (length(in_df) > 0) indat_col_df <- in_df
		else indat_col_df <- '.nulcol.'
	} else {
		indat_col_type <- 'FileType'
		indat_col_df <- 'DF_NAME'
	}
	f_get_in_df <- indat_col_df %in% colnames(inDatCfg)
	#Below function supports to force variable names on its LHS, see [!!!] in [rlang]
	outDict = rlang::list2(
		'data' = NULL
		,!!miss.files := NULL
		,!!err.cols := NULL
	)
	ABP_errors <- F
	dateBgn <- asDates(dateBgn)
	dateEnd <- asDates(dateEnd)
	chkBgn <- asDates(chkBgn)
	if (identical(funcAggr,mean)) {
		LFuncAggr <- sum
	} else {
		LFuncAggr <- funcAggr
	}
	fLeadCalc <- F
	fUsePrev <- F
	calcDate <- NULL
	calcMult <- NULL

	#039. Debug mode
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

	#040. Create calendar for calculation of time series
	ABP_Clndr <- UserCalendar$new(
		dateBgn = dateBgn
		,dateEnd = dateEnd
		,clnBgn = chkBgn - as.difftime(30, units = 'days')
		,clnEnd = dateEnd + as.difftime(30, units = 'days')
	)
	ABP_ObsDates <- ObsDates$new(
		obsDate = dateEnd
		,clnBgn = chkBgn - as.difftime(30, units = 'days')
		,clnEnd = dateEnd + as.difftime(30, units = 'days')
	)

	#050. Determine [chkEnd] by the implication of [genPHMul]
	if (genPHMul) {
		if (calcInd == 'C') {
			indMod <- 'W'
		} else {
			indMod <- calcInd
		}
		chkEnd <- ABP_ObsDates$shiftDays(kshift = -1, preserve = F, daytype = indMod)
	} else {
		chkEnd <- dateEnd - as.difftime(1, units = 'days')
	}

	#070. Retrieve the Previous Days by the implication of [calcInd]
	if (calcInd=='C') {
		periodOut <- as.numeric(dateEnd - dateBgn + as.difftime(1, units = 'days'), units = 'days')
		periodChk <- as.numeric(chkEnd - chkBgn + as.difftime(1, units = 'days'), units = 'days')
		pdCalcBgn <- dateBgn - as.difftime(1, units = 'days')
		pdCalcEnd <- dateEnd - as.difftime(1, units = 'days')
		pdChkBgn <- chkBgn - as.difftime(1, units = 'days')
		pdChkEnd <- chkEnd - as.difftime(1, units = 'days')
	} else if (calcInd=='W') {
		periodOut <- ABP_Clndr$kWorkDay
		if (chkEnd>=chkBgn) {
			ABP_Clndr$dateBgn <- chkBgn
			ABP_Clndr$dateEnd <- chkEnd
			periodChk <- ABP_Clndr$kWorkDay
		} else {
			periodChk <- 0
		}
		ABP_ObsDates$values <- c(dateBgn, dateEnd, chkBgn, chkEnd)
		pdCalcBgn <- ABP_ObsDates$prevWorkDay[1]
		pdCalcEnd <- ABP_ObsDates$prevWorkDay[2]
		pdChkBgn <- ABP_ObsDates$prevWorkDay[3]
		pdChkEnd <- ABP_ObsDates$prevWorkDay[4]
	} else {
		periodOut <- ABP_Clndr$kTradeDay
		if (chkEnd>=chkBgn) {
			ABP_Clndr$dateBgn <- chkBgn
			ABP_Clndr$dateEnd <- chkEnd
			periodChk <- ABP_Clndr$kTradeDay
		} else {
			periodChk <- 0
		}
		ABP_ObsDates$values <- c(dateBgn, dateEnd, chkBgn, chkEnd)
		pdCalcBgn <- ABP_ObsDates$prevTradeDay[1]
		pdCalcEnd <- ABP_ObsDates$prevTradeDay[2]
		pdChkBgn <- ABP_ObsDates$prevTradeDay[3]
		pdChkEnd <- ABP_ObsDates$prevTradeDay[4]
	}

	#075. Define the multiplier for Checking Period
	if (identical(funcAggr,mean)) {
		multiplier_CP <- periodChk
	} else {
		multiplier_CP <- 1
	}

	#080. Calculate the difference of # date coverage by the implication of [calcInd]
	periodDif <- periodOut - periodChk

	#099. Debug mode
	if (fDebug){
		message('[',LfuncName,']','[chkEnd]=[',chkEnd,']')
		message('[',LfuncName,']','[periodOut]=[',periodOut,']')
		message('[',LfuncName,']','[periodChk]=[',periodChk,']')
		message('[',LfuncName,']','[periodDif]=[',periodDif,']')
		message('[',LfuncName,']','[pdCalcBgn]=[',pdCalcBgn,']')
		message('[',LfuncName,']','[pdCalcEnd]=[',pdCalcEnd,']')
		message('[',LfuncName,']','[pdChkBgn]=[',pdChkBgn,']')
		message('[',LfuncName,']','[pdChkEnd]=[',pdChkEnd,']')
	}

	#100. Calculate the summary for the leading period from [chkBgn] to [dateBgn], if applicable
	#110. Calculate the prerequisites for the data as of Checking Period
	if ((length(chkDatPtn)>0) & (length(chkBgn)>0)) {
		#100. Determine the name of the data as dependency in Checking Period
		parse_chkDat <- rlang::exec(
			parseDatName
			,datPtn = chkDatPtn
			,parseCol = NULL
			,dates = chkEnd
			,outDTfmt = outDTfmt
			,inRAM = (chkDatType=='RAM')
			,chkExist = T
			,dict_map = fTrans
			,!!!fTrans.opt
		)

		#500. Extract the values for later steps
		chkDat <- parse_chkDat[1, 'datPtn.Parsed']
		LchkExist <- parse_chkDat[1, 'datPtn.chkExist']
	}

	#150. Call the same function in recursion when necessary
	if (length(chkBgn)==0) {
		#001. Debug mode
		if (fDebug){
			message(
				'[',LfuncName,']','Procedure will not conduct calculation in Leading Period'
				,' since [chkBgn] is not provided'
			)
		}
	} else if (chkBgn>=dateBgn) {
		#001. Debug mode
		if (fDebug){
			message(
				'[',LfuncName,']','Procedure will not conduct calculation in Leading Period'
				,' since [chkBgn=',chkBgn,'] >= [dateBgn=',dateBgn,']'
			)
		}
	} else if (periodDif!=0) {
		#001. Debug mode
		if (fDebug){
			message(
				'[',LfuncName,']','Procedure will not conduct calculation in Leading Period'
				,' since its date period coverage is not identical to current one'
			)
		}
	} else if (!identical(LFuncAggr, sum)) {
		#001. Debug mode
		if (fDebug){
			message(
				'[',LfuncName,']','Procedure will not conduct calculation in Leading Period'
				,' for the functions other than [sum] and [mean]'
			)
		}
	} else if (length(chkDatPtn)==0) {
		#001. Debug mode
		if (fDebug){
			message(
				'[',LfuncName,']','[chkDatPtn] is not provided. Skip the calculation for Leading Period'
			)
		}
	} else if (!LchkExist) {
		#001. Debug mode
		if (fDebug){
			message(
				'[',LfuncName,']','The data [chkDat=',chkDat,'] does not exist.'
				,' Skip the calculation for Leading Period'
			)
		}
	} else {
		#001. Debug mode
		if (fDebug){
			message('[',LfuncName,']','Entering calculation for Leading Period...')
		}

		#100. Recall the function to calculate the summary in Leading Period
		#[1] There is no such [chkDatPtn] to leverage for the Leading Period
		#[2] The end date of the Leading Period is determined by [calcInd]
		#[3] We will only apply [SUM] for the calculation in Leading Period, for later subtraction
		ABP_LeadPeriod <- Recall(
			inDatPtn = inDatPtn
			,inDatType = inDatType
			,in_df = in_df
			,fTrans = fTrans
			,fTrans.opt = fTrans.opt
			,fImp.opt = fImp.opt
			,.parallel = .parallel
			,cores = cores
			,dateBgn = chkBgn
			,dateEnd = pdCalcBgn
			,chkDatPtn = NULL
			,chkDatType = chkDatType
			,chkDat_df = chkDat_df
			,chkDat.opt = chkDat.opt
			,chkDatVar = chkDatVar
			,chkBgn = NULL
			,byVar = byVar
			,copyVar = copyVar
			,aggrVar = aggrVar
			,genPHMul = genPHMul
			,calcInd = calcInd
			,funcAggr = LFuncAggr
			,omniR.ini = omniR.ini
			,outVar = '.CalcLead.'
			,miss.files = miss.files
			,err.cols = err.cols
			,fDebug = fDebug
		)

		#199. Debug mode
		if (fDebug){
			message('[',LfuncName,']','Exiting calculation for Leading Period...')
		}

		#900. Mark the availability of this process
		fLeadCalc <- T
	}

	#200. Determine whether to leverage [chkDat] as overall control
	if (length(chkDatPtn)==0) {
		#001. Debug mode
		if (fDebug){
			message(
				'[',LfuncName,']','[chkDatPtn] is not provided. Skip the calculation for Checking Period'
			)
		}
	} else if (!LchkExist) {
		#001. Debug mode
		if (fDebug){
			message(
				'[',LfuncName,']','The data [chkDat=',chkDat,'] does not exist.'
				,' Skip the calculation for Checking Period'
			)
		}
	} else if (chkBgn > chkEnd) {
		#001. Debug mode
		if (fDebug){
			message(
				'[',LfuncName,']','Procedure will not conduct calculation in Checking Period'
				,' since [chkBgn=',chkBgn,'] > [chkEnd=',chkEnd,']'
			)
		}
	} else if ((dateBgn==chkBgn) | fLeadCalc) {
		#001. Debug mode
		if (fDebug){
			message('[',LfuncName,']','Prepare the calculation for Checking Period...')
		}

		#[1] [dateBgn] = [chkBgn], which usually represents a continuous calculation at fixed beginning, such as MTD ANR
		#[2] [fLeadCalc] = 1, which implies that the Leading Period has already been involved hence the entire
		#     Previous Calculation Result MUST also be involved
		fUsePrev <- T
	}

	#300. Determine the datasets to be used for calculation in current period
	#310. Determine the beginning of retrieval
	if (fUsePrev) {
		#We set the actual beginning date as the next Calendar Day of the date [chkEnd] if the previous calculation
		# result is to be leveraged
		actBgn <- chkEnd + as.difftime(1, units = 'days')
	} else {
		#We set the actual beginning date as of the date [dateBgn] if there is no previous result to leverage
		actBgn <- dateBgn
	}

	#329. Debug mode
	if (fDebug){
		message('[',LfuncName,']','Actual Calculation Period: [actBgn=',actBgn,'][dateEnd=',dateEnd,']')
	}

	#350. Go through the period from [actBgn] to [dateEnd] and determine the resolution for [inDatPtn]
	#351. Retrieve all the date information within the period
	#[IMPORTANT] Using below sequence of statements is because the latest [ABP_Clndr$dateEnd] is sometimes earlier than [actBgn]
	ABP_Clndr$dateEnd <- dateEnd
	ABP_Clndr$dateBgn <- actBgn

	#355. Create necessary variables for calculation in the actually required period
	if (calcInd=='W') {
		#This situation has nothing to do with the parameter [genPHMul]
		calcDate <- ABP_Clndr$d_AllWD
	} else if (calcInd=='T') {
		#This situation has nothing to do with the parameter [genPHMul]
		calcDate <- ABP_Clndr$d_AllTD
	} else if (genPHMul) {
		ABP_ObsDates$values <- ABP_Clndr$d_AllCD
		#Assumptions:
		#[1] In such case, we never know whether to predate the beginning of the actual calculation period by Workdays or Tradedays
		#[2] # Workdays is more than # Tradedays in the same period, hence we only resemble the data on holidays with the data
		#     on Workdays
		#[3] When there is absolute requirement to resemble the data on holidays by that on Tradedays, try to modify the Calendar
		#     Adjustment data by setting all Workdays to the same as Tradedays BEFORE using this function
		availDate <- ABP_ObsDates$shiftDays(kshift = -1, preserve = T, daytype = 'W')
		calcDate <- sort(unique(availDate))
		calcMult <- sapply(calcDate, function(x){sum(availDate==x)})
		names(calcMult) <- calcDate %>% strftime('%Y%m%d')
	} else {
		calcDate <- ABP_Clndr$d_AllCD
	}

	#357. Reset the multiplier for data on each date for special cases
	if ((!genPHMul) | (calcInd!='C') | !identical(LFuncAggr,sum)) {
		calcMult <- sapply(calcDate, function(x){1})
		names(calcMult) <- calcDate %>% strftime('%Y%m%d')
	}

	#399. Print necessary information for debugging purpose
	if (fDebug){
		#100. Print the necessities for Leading Period
		if (fLeadCalc) {
			message('[',LfuncName,']','[Leading Period] Dataset to use: [ABP_LeadPeriod]')
		}

		#400. Print the necessities for Checking Period
		if (fUsePrev) {
			message('[',LfuncName,']','[Checking Period] Dataset to use: [',chkDat,']')
			message('[',LfuncName,']','[Checking Period] Data multiplier: [',multiplier_CP,']')
		}

		#700. Print the necessities for Actual Calculation Period
		message('[',LfuncName,']','[Actual Calculation Period] Dataset to use: [',inDatCfg,']')
		for (i in seq_along(calcDate)) {
			message(
				'[',LfuncName,'][Actual Calculation Period]'
				,' Date[',i,']: [',calcDate[[i]],']'
				,', Multiplier[',i,']: [',calcMult[[i]],']'
			)
		}
	}

	#400. Verify the existence of the data files that are actually required
	#410. Parse the naming pattern into the physical file path
	parse_calcDat <- rlang::exec(
		parseDatName
		,datPtn = inDatCfg
		,parseCol = indat_col_parse
		,dates = calcDate
		,outDTfmt = outDTfmt
		,inRAM = (inDatCfg[[indat_col_type]]=='RAM')
		,chkExist = T
		,dict_map = fTrans
		,!!!fTrans.opt
	)

	#420. Search in all candidate paths of the the libraries for the data files and identify the first occurrences respectively
	exist_calcDat <- parse_calcDat %>%
		dplyr::filter_at(paste0(indat_col_parse,'.chkExist'), ~.) %>%
		dplyr::arrange_at(c(indat_col_file, indat_col_date, indat_col_dirseq)) %>%
		dplyr::group_by_at(c(indat_col_file, indat_col_date)) %>%
		dplyr::slice_head(n = 1)

	n_files <- nrow(exist_calcDat)

	#429. Debug mode
	if (fDebug){
		message('[',LfuncName,']','There are [',n_files,'] data files to involve in the Actual Calculation Period')
		message('[',LfuncName,']','Actual Calculation Period Covers below dates:')
		print(calcDate)
		message('[',LfuncName,']','Their respective multipliers are as below:')
		print(calcMult)
	}

	#450. Identify the files that do not exist in any among the candidate paths
	nonexist_calcDat <- parse_calcDat %>%
		dplyr::anti_join(
			exist_calcDat %>% dplyr::select_at(c(indat_col_file, indat_col_date)) %>% dplyr::distinct()
			,by = c(indat_col_file, indat_col_date)
		)

	#490. Abort the program for certain conditions
	#491. Abort the process if any of the data files do not exist
	if (nrow(nonexist_calcDat) > 0) {
		#500. Output a global data frame storing the information of the missing data files
		outDict[[miss.files]] <- nonexist_calcDat

		#999. Abort the process
		warning('[',LfuncName,']','Some data files do not exist! Check the data frame [',miss_files,'] in the output result!')
		ABP_errors <- T
	}

	#495. Verify the exit condition from the calculation of the Leading Period
	if (fLeadCalc) {
		if (!is.null(ABP_LeadPeriod[[miss.files]])) {
			#500. Output a global data frame storing the information of the missing data files
			outDict[[miss.files]] <- dplyr::bind_rows(ABP_LeadPeriod[[miss.files]], outDict[[miss.files]])

			#999. Abort the process
			warning('[',LfuncName,']','Some data files do not exist! Check the data frame [',miss_files,'] in the output result!')
			ABP_errors <- T
		}
	}

	#499. Abort if the flag of errors is True
	if (ABP_errors) return(outDict)

	#500. Import the source data within the Actual Calculation Period
	#510. Define the function for reading one data file per batch
	ABP_parallel <- function(i){
		#001. Set environment for multiprocessing
		if (.parallel) {
			#001. Load necessary packages
			library(magrittr)
			#Below function provides the support to recognition of MBCS characters in the source programs
			tmcn::setchs()

			#010. Load user defined functions
			source(omniR.ini)
		}

		#100. Set parameters
		inDat <- parse_calcDat[i, paste0(indat_col_parse, '.Parsed')]
		if (f_get_in_df) {
			inDat_df <- parse_calcDat[i, indat_col_df]
		} else {
			inDat_df <- NULL
		}
		inDat_type <- parse_calcDat[i, indat_col_type]
		L_d_curr<- parse_calcDat[i, 'dates'] %>% strftime('%Y%m%d')

		#300. Prepare the function to apply to the process list
		imp_func <- list(
			RAM = list(
				.func = std_read_RAM
				,.opt = list(inDat)
			)
			,R = list(
				.func = std_read_R
				#[Quote: https://www.r-bloggers.com/2013/08/a-new-r-trick-for-me-at-least/ ]
				,.opt = c(list(inDat), list(inDat_df), fImp.opt$R)
			)
			,SAS = list(
				.func = std_read_SAS
				,.opt = c( list(inDat), fImp.opt$SAS )
			)
		)

		#400. Create a list of unique column names for selection from the input data
		if (keep_all_col) {
			select_func <- dplyr::select_all
		} else {
			#We do not have to [union] the column names as [dplyr::select_at] will always select a column once
			select_func <- purrr::partial(dplyr::select_at, .vars = c(byVar,copyVar,aggrVar))
		}

		#500. Call functions to import data from current path
		#We have the create a symbol for [rlang] syntax of bang-bang operator
		aggrSym <- rlang::sym(aggrVar)
		imp_data <- do.call( imp_func[[inDat_type]]$.func, imp_func[[inDat_type]]$.opt ) %>%
			#100. Only select necessary columns
			select_func() %>%
			#900. Create identifier of current data within the time series
			dplyr::mutate(
				.Period = 'A'
				,.date = L_d_curr
				,.N_ORDER = i
				,.Tmp_Val = !!aggrSym * calcMult[[L_d_curr]]
			)

		#700. Assign additional attributes to the data frame for column class check
		attr(imp_data, 'name') <- L_d_curr
		attr(imp_data, 'DF_NAME') <- inDat_df

		#999. Return the result
		return(imp_data)
	}

	#550. Create a list of imported data frames and bind all rows of them together as one data frame
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
		files_import <- foreach::foreach( i = seq_len(n_files) ) %dopar% ABP_parallel(i)
	} else {
		#001. Debug mode
		if (fDebug){
			message('[',LfuncName,']','Import data files in Sequential mode...')
		}

		#900. Read the files sequentially
		#We do not directly combine the data, for there may be columns with different classes.
		files_import <- lapply( seq_len(n_files), ABP_parallel )
	}

	#560. Check the list of imported data on the classes of columns
	names(files_import) <- seq_len(n_files)
	chk_cls <- debug_comp_datcols( files_import, with.attr = c('name', 'DF_NAME') )

	#569. Abort the program if any inconsistency is found on columns of data frames
	if (nrow(chk_cls)) {
		#500. Output a global data frame storing the information of the column inconsistency
		# assign(err.cols, chk_cls, pos = globalenv())
		outDict[[err.cols]] <- chk_cls

		#999. Abort the process
		warning('[',LfuncName,']','Some columns cannot be bound due to different classes!')
		warning('[',LfuncName,']','Check data frame [',err.cols,'] in global environment for these columns!')
		ABP_errors <- T
	}

	#590. Abort the program for certain conditions
	#591. Verify the exit condition from the calculation of the Leading Period
	if (fLeadCalc) {
		#100. Abort if any columns cannot be concatenated
		if (!is.null(ABP_LeadPeriod[[err.cols]])) {
			#500. Output a global data frame storing the information of the missing data files
			outDict[[err.cols]] <- dplyr::bind_rows(ABP_LeadPeriod[[err.cols]], outDict[[err.cols]])

			#999. Abort the process
			warning('[',LfuncName,']','Some columns cannot be bound due to different classes!')
			warning('[',LfuncName,']','Check data frame [',err.cols,'] in global environment for these columns!')
			ABP_errors <- T
		}
	}

	#599. Abort if the flag of errors is True
	if (ABP_errors) return(outDict)

	#600. Set all the required data
	#610. Data for the Leading Period
	#The values in this data should be subtracted from those in the Actual Calculation Period
	if (fLeadCalc) {
		#300. Create a list of unique column names for selection from the input data
		if (keep_all_col) {
			sel_LP <- dplyr::select_all
		} else {
			sel_LP <- purrr::partial(dplyr::select_at, .vars = c(byVar,copyVar,'.CalcLead.'))
		}

		#500. Only retrieve certain columns for Leading Period
		ABP_set_LP <- ABP_LeadPeriod[['data']] %>%
			sel_LP() %>%
			tidyr::replace_na(list('.CalcLead.' = 0)) %>%
			dplyr::mutate(
				.Period = 'L'
				,.date = 'Leading'
				,.N_ORDER = -1
				,.Tmp_Val = -.CalcLead.
			)
	} else {
		ABP_set_LP <- NULL
	}

	#630. Data for [chkDat], i.e. Checking Period
	if (fUsePrev) {
		#300. Prepare the function to apply to the process list
		imp_func <- list(
			RAM = list(
				.func = std_read_RAM
				,.opt = list(chkDat)
			)
			,R = list(
				.func = std_read_R
				#[Quote: https://www.r-bloggers.com/2013/08/a-new-r-trick-for-me-at-least/ ]
				,.opt = c(list(chkDat), list(chkDat_df), fImp.opt$R)
			)
			,SAS = list(
				.func = std_read_SAS
				,.opt = c( list(chkDat), fImp.opt$SAS )
			)
		)

		#500. Call functions to import data from current path
		#510. Create a list of unique column names for selection from the input data
		if (keep_all_col) {
			sel_CP <- dplyr::select_all
		} else {
			sel_CP <- purrr::partial(dplyr::select_at, .vars = c(byVar,copyVar,chkDatVar))
		}

		#590. Load the data and conduct the requested transformation
		#We have the create a symbol for [rlang] syntax of bang-bang operator
		chkDatSym <- rlang::sym(chkDatVar)
		ABP_set_CP <- do.call( imp_func[[chkDatType]]$.func, imp_func[[chkDatType]]$.opt ) %>%
			sel_CP() %>%
			dplyr::mutate(
				.Period = 'C'
				,.date = 'Checking'
				,.N_ORDER = 0
				,.Tmp_Val = !!chkDatSym * multiplier_CP
			)
	} else {
		ABP_set_CP <- NULL
	}

	#690. Combine the data
	ABP_setall <- dplyr::bind_rows(c(list(ABP_set_LP), list(ABP_set_CP), files_import))
	# assign('chkABP', ABP_setall, pos = globalenv())

	#700. Aggregate by the provided function
	#710. Create a list of unique column names for sorting in the input data
	sort_cols <- c(byVar,'.N_ORDER')

	#730. Create a group of unique column names for eliminating excessive ones
	grp_cols <- c(byVar, '.Period', '.date')

	#760. Identify the columns to <copy> to the result, i.e. retain their respective values at the last record
	if (keep_all_col) {
		copy_cols <- colnames(ABP_setall)[!colnames(ABP_setall) %in% c(sort_cols,grp_cols,'.Tmp_Val')]
	} else {
		copy_cols <- copyVar[!copyVar %in% c(sort_cols,grp_cols,'.Tmp_Val')]
	}

	#790. Aggregation
	outSym <- rlang::sym(outVar)
	outDat <- ABP_setall %>%
		#100. Sort the data by [byVar] plus [.N_ORDER]
		dplyr::arrange_at(sort_cols) %>%
		#400. Aggregate by [byVar] on each date in the first place
		dplyr::group_by_at(grp_cols) %>%
		#410. Only retrieve the last occurrence of [copyVar] for each group
		dplyr::mutate_at(copy_cols, dplyr::last) %>%
		#450. Calculate the sum of [aggrVar]
		#451. Add the mutated columns into the grouping ones
		#Quote: https://stackoverflow.com/questions/43594841/extra-statistics-with-summarize-at-in-dplyr
		dplyr::group_by_at(copy_cols, .add = T) %>%
		#459. Summarise the [aggrVar]
		dplyr::summarise_at('.Tmp_Val', sum) %>%
		#480. Remove the groups
		dplyr::ungroup() %>%
		#600. Re-group the data for final aggregation
		dplyr::group_by_at(byVar) %>%
		#700. Only retrieve the last occurrence of [copyVar] for each group
		dplyr::mutate_at(copy_cols, dplyr::last) %>%
		#800. Calculate the sum of [aggrVar]
		#810. Add the mutated columns into the grouping ones
		#Quote: https://stackoverflow.com/questions/43594841/extra-statistics-with-summarize-at-in-dplyr
		dplyr::group_by_at(copy_cols, .add = T) %>%
		#890. Summarise the [aggrVar]
		#We have to set argument [.groups] as [keep] to avoid warning message
		dplyr::summarise(!!outSym := LFuncAggr(.Tmp_Val, ...), .groups = 'keep') %>%
		dplyr::ungroup() %>%
		#910. Correct the output value for the function [MEAN]
		dplyr::mutate_at(outVar, ~ifelse(identical(funcAggr,mean), ./periodOut, .))

	#999. Return the table
	outDict[['data']] <- outDat
	return(outDict)
}

#[Concept]
if (FALSE){'
%*--  Below For Period Description  ------------------------------------------------------------------------------------------;
[1] The entire period of dates to be involved in this calculation process can be split into below sections:

  [chkBgn]             [dateBgn]                                                       [chkEnd]                       [dateEnd]
 /                      /                                                                 \                                \
|--Leading Period [L]--|                                                                   \                                \
|------------------------------------------Checking Period [C]------------------------------|                                \
                       |----------------------------------New Calculation Period [N]------------------------------------------|
                                                       ( Figure 1 )

[2] Given the dataset [C] exists and Len([C]) = Len([N]), the Actual Calculation Period [A] is set as below:

|------------------------------------------Checking Period [C]------------------------------|
                       |----------------------------------New Calculation Period [N]------------------------------------------|
                                                                                            |--Actual Calculation Period [A]--|
                                                                                           /                                 /
                                                                                        [actBgn]                       [actEnd]
                                                       ( Figure 2 )

[3] Given the dataset [C] does not exist or Len([C]) ^= Len([N]), the Actual Calculation Period [A] is set the same as [N].

[4] The final involvement of sections is as below: (by setting datasets of all sections)
Output = [funcAggr]( [L] (if any, needs to be subtracted) + [C] (if any) + [A] )

%*--  Below For Terminology  -------------------------------------------------------------------------------------------------;
[L]   : It may not exist, depending on the value of [chkBgn], but has to be subtracted from [C] for SUM or MEAN functions.
[C]   : In a continuous process, such as ANR calculation, the result on each date is stored, and we will check them each time
         we conduct a new round of calculation.
[N]   : Current period within which we intend to conduct calculation.
[A]   : The actual involvement of basic daily KPI data.
Len() : The # of dates that a specific period covers, depending on whether [calcInd] indicates to use Calendar Day or Workday.

%*--  When to SKIP calculation of Leading Period [L]  ------------------------------------------------------------------------;
If any of below conditions is tiggered, we will NOT take the Leading Period into account.
[1] : [chkBgn] >= [dateBgn]. Obviously the date span of Leading Period is 0. (See [Figure 1] above)
[2] : [chkBgn] <  [dateBgn] while Len([C]) ^= Len([N]). e.g. if dataset [ANR20170831] was calculated out of 6 calendar
       days from [Bal20170826] to [Bal20170831], while we only need to calculate [ANR20170901] out of the series of datasets
       [Bal20170828-Bal20170901], then we will not leverage [ANR20170831] to calculate [ANR20170901].
[3] : [funcAggr] does NOT represent [SUM] or [MEAN]. e.g. if the [MAX] value lies in the Leading Period, it cannot be involved
       in any period later than the end of the Leading Period.
[4] : [chkDatPtn] is NOT provided.
[5] : Resolved [chkDatPtn] DOES NOT exist as a data source.

%*--  When to SKIP the involvement of Checking Period [C]  -------------------------------------------------------------------;
If any of below conditions is tiggered, we will NOT take the Checking Period into account.
[1] : [chkDatPtn] is NOT provided.
[2] : Resolved [chkDatPtn] DOES NOT exist as a data source.
[3] : [chkBgn] > [chkEnd] which indicates a non-existing period to be involved.

%*--  Calculation Process  ---------------------------------------------------------------------------------------------------;
[1] : If [L] should be involved, call the same macro to calculate the aggregation summary for [L], for later subtraction.
      The intermediate result in such case is marked as [L1].
      If [funcAggr] represents [MEAN], [L1] should be calculated by [SUM] instead for subtraction purpose.
[2] : Aggregate all datasets to be used in [A] by the specified [byVar] respectively, to avoid any possible erroneous result.
[3] : Set all required datasets together: (1) [L1] if any, (2) [C] if any, (3) the series of datasets generated in step [2].
[4] : Apply multiplier to above sections: (1) is multiplied by -1 since it is to be subtracted, (2) is multiplied by 1 or
       Len([C]) depending on whether the function [funcAggr] represents [MEAN], (3) is always multiplied by 1.
[5] : Sum up the values in all above observations if [funcAggr] represents [MEAN] or [SUM], while resolve the [MIN] or [MAX]
       values if otherwise, and at last, divide the summed value by Len([N]) if [funcAggr] represents [MEAN].
'}

#[Index of Examples]
if (FALSE){'
%*100. Data Preparation.;
%*110. Create Calendar dataset.;
%*120. Retrieve all date information for the period of 20160229 to 20160603.;
%*130. Create the test KPI tables.;
%*150. Retrieve all date information for the period of 20160901 to 20161201.;
%*170. Create the test KPI tables.;

%*200. Using the same Beginning of a series of periods.;
%*210. Mean of all Calendar Days from 20160501 to 20160513;
%*220. Mean of all Calendar Days from 20160501 to 20160516;
%*230. Mean of all Working Days from 20160501 to 20160516.;
%*240. Mean of all Working Days from 20160501 to 20160517.;
%*250. Max of all Calendar Days from 20160501 to 20160513;
%*260. Max of all Calendar Days from 20160501 to 20160516;
%*270. Max of all Working Days from 20160501 to 20160516.;
%*280. Max of all Working Days from 20160501 to 20160517.;

%*300. Rolling 10 days, using the data on each last workday to resemble the data on holidays.;
%*310. Mean of all Calendar Days from 20160330 to 20160408;
%*311. Mean of all Calendar Days from 20160402 to 20160411.;
%*312. Mean of all Calendar Days from 20160403 to 20160412.;

%*400. Rolling 5 Working Days.;
%*410. Mean of all Working Days from 20160401 to 20160408.;
%*411. Mean of all Working Days from 20160401 to 20160409.;
%*412. Mean of all Working Days from 20160405 to 20160411.;

%*430. Rolling 5 Trade Days.;
%*431. Mean of all Trade Days from 20160926 to 20161008.;
%*432. Mean of all Trade Days from 20160926 to 20161009.;
%*433. Mean of all Trade Days from 20160927 to 20161010.;
%*434. Mean of all Trade Days from 20160928 to 20161011.;

%*500. Using the same Beginning of a series of periods.;
%*510. Mean of all Calendar Days from 20160901 to 20160910.;
%*520. Mean of all Calendar Days from 20160901 to 20160911.;
%*530. Mean of all Working Days from 20160901 to 20160911.;
%*540. Mean of all Working Days from 20160901 to 20160912.;
%*550. Max of all Calendar Days from 20161001 to 20161010.;
%*560. Max of all Calendar Days from 20161001 to 20161011.;
%*570. Min of all Working Days from 20161001 to 20161010.;
%*580. Min of all Working Days from 20161001 to 20161011.;

%*600. Rolling 5 Calendar Days.;
%*610. Mean of all Calendar Days from 20161007 to 20161011.;
%*611. Mean of all Calendar Days from 20161008 to 20161012.;
%*612. Mean of all Calendar Days from 20161009 to 20161013.;

%*700. Rolling 5 Working Days.;
%*710. Mean of all Working Days from 20160930 to 20161011.;
%*711. Mean of all Working Days from 20161007 to 20161012.;
%*712. Mean of all Working Days from 20161008 to 20161013.;
%*713. Mean of all Working Days from 20161010 to 20161014, with a data frame provided as [inDatPtn];
'}

#[Full Test Program;]
if (FALSE){
	#001. Load environment
	#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
	lst_pkg <- deparse(substitute(c(
		rlang, dplyr, doParallel, foreach, tidyr
	)))
	#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
	lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
	lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
	lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))

	suppressPackageStartupMessages(
		sapply(lst_pkg, function(x){library(x,character.only = TRUE)})
	)
	tmcn::setchs(rev=F)

	#010. Load user defined functions
	source('D:\\R\\autoexec.r')

	#100. Set the default arguments for all test cases
	opt.def.ABP <- list(
		inDatPtn = 'D:\\R\\omniR\\SampleKPI\\testAggr\\kpi&L_curdate..sas7bdat'
		,inDatType = 'SAS'
		,in_df = NULL
		,fImp.opt = list(
			SAS = list(
				# Try <GB18030> if below encoding fails
				encoding = 'GB2312'
			)
		)
		,fTrans = getOption('fmt.def.GTSFK')
		,fTrans.opt = getOption('fmt.opt.def.GTSFK')
		,.parallel = F
		,omniR.ini = getOption('file.autoexec')
		,cores = 4
		,chkDatType = 'RAM'
		,byVar = c('nc_cifno','nc_acct_no')
		,copyVar = '_all_'
		,aggrVar = 'A_KPI_VAL'
		,genPHMul = TRUE
		,calcInd = 'C'
		,funcAggr = mean
		,miss.files = 'G_miss_files'
		,err.cols = 'G_err_cols'
		,outDTfmt = getOption('fmt.parseDates')
		,na.rm = T
	)

	#200. Using the same Beginning of a series of periods
	#210. Mean of all Calendar Days from 20160501 to 20160513
	if (TRUE){
		DtBgn <- asDates('20160501')
		DtEnd <- asDates('20160513')
		args.ABP.CMEAN <- modifyList(
			opt.def.ABP
			,list(
				dateBgn = DtBgn
				,dateEnd = DtEnd
				,chkDatPtn = 'avgKpi&L_curdate.'
				,chkDatVar = 'A_KPI_ANR'
				,chkBgn = DtBgn
				,outVar = 'A_KPI_ANR'
				,fDebug = F
			)
		)
		outdat <- paste0('avgKpi', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.ABP.CMEAN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_ANR']] %>% unlist())
		message((24*2+23+22+21+20*3+19+18+17+16+15)/13)
	}

	#220. Mean of all Calendar Days from 20160501 to 20160516
	#[ASSUMPTION]
	#[1] Function searches for the aggregation on its previous workday, and set it as <chkDat>
	if (TRUE){
		DtEnd <- asDates('20160516')
		args.ABP.CMEAN <- modifyList(
			args.ABP.CMEAN
			,list(
				dateEnd = DtEnd
			)
		)
		outdat <- paste0('avgKpi', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.ABP.CMEAN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_ANR']] %>% unlist())
		message((24*2+23+22+21+20*3+19+18+17+16+15*3+14)/16)
	}

	#230. Mean of all Working Days from 20160501 to 20160516
	if (TRUE){
		DtBgn <- asDates('20160501')
		DtEnd <- asDates('20160516')
		args.ABP.WMEAN <- modifyList(
			opt.def.ABP
			,list(
				dateBgn = DtBgn
				,dateEnd = DtEnd
				,chkDatPtn = 'WDavgKpi&L_curdate.'
				,chkDatVar = 'A_KPI_ANR'
				,chkBgn = DtBgn
				,calcInd = 'W'
				,outVar = 'A_KPI_ANR'
				,fDebug = F
			)
		)
		outdat <- paste0('WDavgKpi', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.ABP.WMEAN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_ANR']] %>% unlist())
		message((23+22+21+20+19+18+17+16+15+14)/10)
	}

	#240. Mean of all Working Days from 20160501 to 20160517
	if (TRUE){
		DtEnd <- asDates('20160517')
		args.ABP.WMEAN <- modifyList(
			args.ABP.WMEAN
			,list(
				dateEnd = DtEnd
			)
		)
		outdat <- paste0('WDavgKpi', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.ABP.WMEAN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_ANR']] %>% unlist())
		message((23+22+21+20+19+18+17+16+15+14+13)/11)
	}

	#250. Max of all Calendar Days from 20160501 to 20160513
	if (TRUE){
		DtBgn <- asDates('20160501')
		DtEnd <- asDates('20160513')
		args.ABP.CMAX <- modifyList(
			opt.def.ABP
			,list(
				dateBgn = DtBgn
				,dateEnd = DtEnd
				,chkDatPtn = 'CDmaxKpi&L_curdate.'
				,chkDatVar = 'A_KPI_MAX'
				,chkBgn = DtBgn
				,funcAggr = max
				,outVar = 'A_KPI_MAX'
				,fDebug = F
			)
		)
		outdat <- paste0('CDmaxKpi', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.ABP.CMAX)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_MAX']] %>% unlist())
		message(max(24,23,22,21,20,19,18,17,16,15))
	}

	#260. Max of all Calendar Days from 20160501 to 20160516
	if (TRUE){
		DtEnd <- asDates('20160516')
		args.ABP.CMAX <- modifyList(
			args.ABP.CMAX
			,list(
				dateEnd = DtEnd
			)
		)
		outdat <- paste0('CDmaxKpi', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.ABP.CMAX)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_MAX']] %>% unlist())
		message(max(24,23,22,21,20,19,18,17,16,15,14))
	}

	#270. Max of all Working Days from 20160501 to 20160516
	if (TRUE){
		DtBgn <- asDates('20160501')
		DtEnd <- asDates('20160516')
		args.ABP.WMAX <- modifyList(
			opt.def.ABP
			,list(
				dateBgn = DtBgn
				,dateEnd = DtEnd
				,chkDatPtn = 'WDmaxKpi&L_curdate.'
				,chkDatVar = 'A_KPI_MAX'
				,chkBgn = DtBgn
				,calcInd = 'W'
				,funcAggr = max
				,outVar = 'A_KPI_MAX'
				,fDebug = F
			)
		)
		outdat <- paste0('WDmaxKpi', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.ABP.WMAX)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_MAX']] %>% unlist())
		message(max(23,22,21,20,19,18,17,16,15,14))
	}

	#280. Max of all Working Days from 20160501 to 20160517
	if (TRUE){
		DtEnd <- asDates('20160517')
		args.ABP.WMAX <- modifyList(
			args.ABP.WMAX
			,list(
				dateEnd = DtEnd
			)
		)
		outdat <- paste0('WDmaxKpi', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.ABP.WMAX)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_MAX']] %>% unlist())
		message(max(23,22,21,20,19,18,17,16,15,14,13))
	}

	#300. Rolling 10 days, using the data on each last workday to resemble the data on holidays
	#310. Mean of all Calendar Days from 20160330 to 20160408
	if (TRUE){
		DtBgn <- asDates('20160330')
		DtEnd <- asDates('20160408')
		pDate <- DtBgn - as.difftime(1, units = 'days')
		args.ABP.roll.CMEAN <- modifyList(
			opt.def.ABP
			,list(
				dateBgn = DtBgn
				,dateEnd = DtEnd
				,chkDatPtn = 'R10ANR&L_curdate.'
				,chkDatVar = 'A_KPI_ANR'
				,chkBgn = pDate
				,calcInd = 'C'
				,funcAggr = mean
				,outVar = 'A_KPI_ANR'
				,fDebug = F
			)
		)
		outdat <- paste0('R10ANR', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.ABP.roll.CMEAN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_ANR']] %>% unlist())
		message((23+24+25*4+26+27+28+29)/10)
	}

	#311. Mean of all Calendar Days from 20160402 to 20160411
	#[ASSUMPTION]
	#[1] Function searches for the aggregation on its previous workday, and set it as <chkDat>
	if (TRUE){
		DtBgn <- asDates('20160402')
		DtEnd <- asDates('20160411')
		pDate <- DtBgn - as.difftime(1, units = 'days')
		args.ABP.roll.CMEAN <- modifyList(
			args.ABP.roll.CMEAN
			,list(
				dateBgn = DtBgn
				,dateEnd = DtEnd
				,chkBgn = '20160330'
				,fDebug = F
			)
		)
		outdat <- paste0('R10ANR', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.ABP.roll.CMEAN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_ANR']] %>% unlist())
		message((25*3+26+27+28+29*3+30)/10)
	}

	#312. Mean of all Calendar Days from 20160403 to 20160412
	if (TRUE){
		DtBgn <- asDates('20160403')
		DtEnd <- asDates('20160412')
		pDate <- DtBgn - as.difftime(1, units = 'days')
		args.ABP.roll.CMEAN <- modifyList(
			args.ABP.roll.CMEAN
			,list(
				dateBgn = DtBgn
				,dateEnd = DtEnd
				,chkBgn = pDate
			)
		)
		outdat <- paste0('R10ANR', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.ABP.roll.CMEAN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_ANR']] %>% unlist())
		message((25*2+26+27+28+29*3+30+31)/10)
	}

	#400. Rolling 5 Working Days
	L_obsDates <- ObsDates$new(obsDate = '20160401', clnBgn = '20160301', clnEnd = '20160601')

	#410. Mean of all Working Days from 20160401 to 20160408
	if (TRUE){
		DtEnd <- asDates('20160408')
		L_obsDates$values <- DtEnd
		DtBgn <- L_obsDates$shiftDays(kshift = -4, preserve = F, daytype = 'W')
		pDate <- L_obsDates$shiftDays(kshift = -5, preserve = F, daytype = 'W')
		args.ABP.roll.WMEAN <- modifyList(
			opt.def.ABP
			,list(
				dateBgn = DtBgn
				,dateEnd = DtEnd
				,chkDatPtn = 'R5WMEAN&L_curdate.'
				,chkDatVar = 'A_KPI_ANR'
				,chkBgn = pDate
				,calcInd = 'W'
				,funcAggr = mean
				,outVar = 'A_KPI_ANR'
				,fDebug = F
			)
		)
		outdat <- paste0('R5WMEAN', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.ABP.roll.WMEAN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_ANR']] %>% unlist())
		message((25+26+27+28+29)/5)
	}

	#411. Mean of all Working Days from 20160401 to 20160409
	if (TRUE){
		DtEnd <- asDates('20160409')
		L_obsDates$values <- DtEnd
		DtBgn <- L_obsDates$shiftDays(kshift = -5, preserve = F, daytype = 'W')
		pDate <- L_obsDates$shiftDays(kshift = -6, preserve = F, daytype = 'W')
		args.ABP.roll.WMEAN <- modifyList(
			args.ABP.roll.WMEAN
			,list(
				dateBgn = DtBgn
				,dateEnd = DtEnd
				,chkBgn = pDate
			)
		)
		outdat <- paste0('R5WMEAN', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.ABP.roll.WMEAN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_ANR']] %>% unlist())
		message((25+26+27+28+29)/5)
	}

	#412. Mean of all Working Days from 20160405 to 20160411
	if (TRUE){
		DtEnd <- asDates('20160411')
		L_obsDates$values <- DtEnd
		DtBgn <- L_obsDates$shiftDays(kshift = -4, preserve = F, daytype = 'W')
		pDate <- L_obsDates$shiftDays(kshift = -5, preserve = F, daytype = 'W')
		args.ABP.roll.WMEAN <- modifyList(
			args.ABP.roll.WMEAN
			,list(
				dateBgn = DtBgn
				,dateEnd = DtEnd
				,chkBgn = pDate
			)
		)
		outdat <- paste0('R5WMEAN', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.ABP.roll.WMEAN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_ANR']] %>% unlist())
		message((26+27+28+29+30)/5)
	}

	#430. Rolling 5 Trade Days
	L_obsDates <- ObsDates$new(obsDate = '20160930', clnBgn = '20160901', clnEnd = '20161101')

	#431. Mean of all Trade Days from 20160926 to 20161008
	if (TRUE){
		DtEnd <- asDates('20161008')
		L_obsDates$values <- DtEnd
		L_kshift <- ifelse(L_obsDates$isTradeDay, 0, 1)
		DtBgn <- L_obsDates$shiftDays(kshift = -4 - L_kshift, preserve = F, daytype = 'T')
		pDate <- L_obsDates$shiftDays(kshift = -5 - L_kshift, preserve = F, daytype = 'T')
		args.ABP.roll.TMEAN <- modifyList(
			opt.def.ABP
			,list(
				dateBgn = DtBgn
				,dateEnd = DtEnd
				,chkDatPtn = 'R5TMEAN&L_curdate.'
				,chkDatVar = 'A_KPI_ANR'
				,chkBgn = pDate
				,calcInd = 'T'
				,funcAggr = mean
				,outVar = 'A_KPI_ANR'
				,fDebug = F
			)
		)
		outdat <- paste0('R5TMEAN', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.ABP.roll.TMEAN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_ANR']] %>% unlist())
		message((26+27+28+29+30)/5)
	}

	#432. Mean of all Trade Days from 20160926 to 20161009
	if (TRUE){
		DtEnd <- asDates('20161009')
		L_obsDates$values <- DtEnd
		L_kshift <- ifelse(L_obsDates$isTradeDay, 0, 1)
		DtBgn <- L_obsDates$shiftDays(kshift = -4 - L_kshift, preserve = F, daytype = 'T')
		pDate <- L_obsDates$shiftDays(kshift = -5 - L_kshift, preserve = F, daytype = 'T')
		args.ABP.roll.TMEAN <- modifyList(
			args.ABP.roll.TMEAN
			,list(
				dateBgn = DtBgn
				,dateEnd = DtEnd
				,chkBgn = pDate
			)
		)
		outdat <- paste0('R5TMEAN', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.ABP.roll.TMEAN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_ANR']] %>% unlist())
		message((26+27+28+29+30)/5)
	}

	#433. Mean of all Trade Days from 20160927 to 20161010
	if (TRUE){
		DtEnd <- asDates('20161010')
		L_obsDates$values <- DtEnd
		L_kshift <- ifelse(L_obsDates$isTradeDay, 0, 1)
		DtBgn <- L_obsDates$shiftDays(kshift = -4 - L_kshift, preserve = F, daytype = 'T')
		pDate <- L_obsDates$shiftDays(kshift = -5 - L_kshift, preserve = F, daytype = 'T')
		args.ABP.roll.TMEAN <- modifyList(
			args.ABP.roll.TMEAN
			,list(
				dateBgn = DtBgn
				,dateEnd = DtEnd
				,chkBgn = pDate
			)
		)
		outdat <- paste0('R5TMEAN', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.ABP.roll.TMEAN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_ANR']] %>% unlist())
		message((27+28+29+30+40)/5)
	}

	#434. Mean of all Trade Days from 20160928 to 20161011
	#This step is to test the utilization of the calculation result of the previous Trade Day
	if (TRUE){
		DtEnd <- asDates('20161011')
		L_obsDates$values <- DtEnd
		L_kshift <- ifelse(L_obsDates$isTradeDay, 0, 1)
		DtBgn <- L_obsDates$shiftDays(kshift = -4 - L_kshift, preserve = F, daytype = 'T')
		pDate <- L_obsDates$shiftDays(kshift = -5 - L_kshift, preserve = F, daytype = 'T')
		args.ABP.roll.TMEAN <- modifyList(
			args.ABP.roll.TMEAN
			,list(
				dateBgn = DtBgn
				,dateEnd = DtEnd
				,chkBgn = pDate
			)
		)
		outdat <- paste0('R5TMEAN', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.ABP.roll.TMEAN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_ANR']] %>% unlist())
		message((28+29+30+40+41)/5)
	}

	#500. Using the same Beginning of a series of periods
	#Below For [genPHMul = FALSE]
	args.ABP.noMul <- modifyList(opt.def.ABP, list(genPHMul = F))

	#510. Mean of all Calendar Days from 20160901 to 20160910
	if (TRUE){
		DtBgn <- asDates('20160901')
		DtEnd <- asDates('20160910')
		args.noMul.CMEAN <- modifyList(
			args.ABP.noMul
			,list(
				dateBgn = DtBgn
				,dateEnd = DtEnd
				,chkDatPtn = 'CCMEAN&L_curdate.'
				,chkDatVar = 'A_KPI_ANR'
				,chkBgn = DtBgn
				,outVar = 'A_KPI_ANR'
				,fDebug = F
			)
		)
		outdat <- paste0('CCMEAN', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.noMul.CMEAN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_ANR']] %>% unlist())
		message((1+2+3+4+5+6+7+8+9+10)/10)
	}

	#520. Mean of all Calendar Days from 20160901 to 20160911
	if (TRUE){
		DtEnd <- asDates('20160911')
		args.noMul.CMEAN <- modifyList(
			args.noMul.CMEAN
			,list(
				dateEnd = DtEnd
			)
		)
		outdat <- paste0('CCMEAN', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.noMul.CMEAN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_ANR']] %>% unlist())
		message((1+2+3+4+5+6+7+8+9+10+11)/11)
	}

	#530. Mean of all Working Days from 20160901 to 20160911
	if (TRUE){
		DtBgn <- asDates('20160901')
		DtEnd <- asDates('20160911')
		args.noMul.WMEAN <- modifyList(
			args.ABP.noMul
			,list(
				dateBgn = DtBgn
				,dateEnd = DtEnd
				,chkDatPtn = 'CWMEAN&L_curdate.'
				,chkDatVar = 'A_KPI_ANR'
				,chkBgn = DtBgn
				,calcInd = 'W'
				,outVar = 'A_KPI_ANR'
				,fDebug = F
			)
		)
		outdat <- paste0('CWMEAN', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.noMul.WMEAN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_ANR']] %>% unlist())
		message((1+2+5+6+7+8+9)/7)
	}

	#540. Mean of all Working Days from 20160901 to 20160912
	if (TRUE){
		DtEnd <- asDates('20160912')
		args.noMul.WMEAN <- modifyList(
			args.noMul.WMEAN
			,list(
				dateEnd = DtEnd
			)
		)
		outdat <- paste0('CWMEAN', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.noMul.WMEAN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_ANR']] %>% unlist())
		message((1+2+5+6+7+8+9+12)/8)
	}

	#550. Max of all Calendar Days from 20161001 to 20161010
	if (TRUE){
		DtBgn <- asDates('20161001')
		DtEnd <- asDates('20161010')
		args.noMul.CMAX <- modifyList(
			args.ABP.noMul
			,list(
				dateBgn = DtBgn
				,dateEnd = DtEnd
				,chkDatPtn = 'CCMAX&L_curdate.'
				,chkDatVar = 'A_KPI_MAX'
				,chkBgn = DtBgn
				,funcAggr = max
				,outVar = 'A_KPI_MAX'
				,fDebug = F
			)
		)
		outdat <- paste0('CCMAX', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.noMul.CMAX)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_MAX']] %>% unlist())
		message(max(31,32,33,34,35,36,37,38,39,40))
	}

	#560. Max of all Calendar Days from 20161001 to 20161011
	if (TRUE){
		DtEnd <- asDates('20161011')
		args.noMul.CMAX <- modifyList(
			args.noMul.CMAX
			,list(
				dateEnd = DtEnd
			)
		)
		outdat <- paste0('CCMAX', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.noMul.CMAX)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_MAX']] %>% unlist())
		message(max(31,32,33,34,35,36,37,38,39,40,41))
	}

	#570. Min of all Working Days from 20161001 to 20161010
	if (TRUE){
		DtBgn <- asDates('20161001')
		DtEnd <- asDates('20161010')
		args.noMul.WMIN <- modifyList(
			args.ABP.noMul
			,list(
				dateBgn = DtBgn
				,dateEnd = DtEnd
				,chkDatPtn = 'CWMIN&L_curdate.'
				,chkDatVar = 'A_KPI_MIN'
				,chkBgn = DtBgn
				,calcInd = 'W'
				,funcAggr = min
				,outVar = 'A_KPI_MIN'
				,fDebug = F
			)
		)
		outdat <- paste0('CWMIN', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.noMul.WMIN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_MIN']] %>% unlist())
		message(min(38,39,40))
	}

	#580. Min of all Working Days from 20161001 to 20161011
	if (TRUE){
		DtEnd <- asDates('20161011')
		args.noMul.WMIN <- modifyList(
			args.noMul.WMIN
			,list(
				dateEnd = DtEnd
			)
		)
		outdat <- paste0('CWMIN', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.noMul.WMIN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_MIN']] %>% unlist())
		message(min(38,39,40,41))
	}

	#600. Rolling 5 Calendar Days
	#610. Mean of all Calendar Days from 20161007 to 20161011
	if (TRUE){
		DtBgn <- asDates('20161007')
		DtEnd <- asDates('20161011')
		pDate <- DtBgn - as.difftime(1, units = 'days')
		args.noMul.roll.CMEAN <- modifyList(
			args.ABP.noMul
			,list(
				dateBgn = DtBgn
				,dateEnd = DtEnd
				,chkDatPtn = 'RC5CMEAN&L_curdate.'
				,chkDatVar = 'A_KPI_ANR'
				,chkBgn = pDate
				,outVar = 'A_KPI_ANR'
				,fDebug = F
			)
		)
		outdat <- paste0('RC5CMEAN', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.noMul.roll.CMEAN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_ANR']] %>% unlist())
		message((37+38+39+40+41)/5)
	}

	#611. Mean of all Calendar Days from 20161008 to 20161012
	if (TRUE){
		DtBgn <- asDates('20161008')
		DtEnd <- asDates('20161012')
		pDate <- DtBgn - as.difftime(1, units = 'days')
		args.noMul.roll.CMEAN <- modifyList(
			args.noMul.roll.CMEAN
			,list(
				dateBgn = DtBgn
				,dateEnd = DtEnd
				,chkBgn = pDate
			)
		)
		outdat <- paste0('RC5CMEAN', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.noMul.roll.CMEAN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_ANR']] %>% unlist())
		message((38+39+40+41+42)/5)
	}

	#612. Mean of all Calendar Days from 20161009 to 20161013
	if (TRUE){
		DtBgn <- asDates('20161009')
		DtEnd <- asDates('20161013')
		pDate <- DtBgn - as.difftime(1, units = 'days')
		args.noMul.roll.CMEAN <- modifyList(
			args.noMul.roll.CMEAN
			,list(
				dateBgn = DtBgn
				,dateEnd = DtEnd
				,chkBgn = pDate
			)
		)
		outdat <- paste0('RC5CMEAN', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.noMul.roll.CMEAN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_ANR']] %>% unlist())
		message((39+40+41+42+43)/5)
	}

	#700. Rolling 5 Working Days
	L_obsDates <- ObsDates$new(obsDate = '20160930', clnBgn = '20160901', clnEnd = '20161101')

	#710. Mean of all Working Days from 20160930 to 20161011
	if (TRUE){
		DtEnd <- asDates('20161011')
		L_obsDates$values <- DtEnd
		DtBgn <- L_obsDates$shiftDays(kshift = -4, preserve = F, daytype = 'W')
		pDate <- L_obsDates$shiftDays(kshift = -5, preserve = F, daytype = 'W')
		args.noMul.roll.WMEAN <- modifyList(
			args.ABP.noMul
			,list(
				dateBgn = DtBgn
				,dateEnd = DtEnd
				,chkDatPtn = 'RC5WMEAN&L_curdate.'
				,chkDatVar = 'A_KPI_ANR'
				,chkBgn = pDate
				,calcInd = 'W'
				,outVar = 'A_KPI_ANR'
				,fDebug = F
			)
		)
		outdat <- paste0('RC5WMEAN', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.noMul.roll.WMEAN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_ANR']] %>% unlist())
		message((30+38+39+40+41)/5)
	}

	#711. Mean of all Working Days from 20161007 to 20161012
	if (TRUE){
		DtEnd <- asDates('20161012')
		L_obsDates$values <- DtEnd
		DtBgn <- L_obsDates$shiftDays(kshift = -4, preserve = F, daytype = 'W')
		pDate <- L_obsDates$shiftDays(kshift = -5, preserve = F, daytype = 'W')
		args.noMul.roll.WMEAN <- modifyList(
			args.noMul.roll.WMEAN
			,list(
				dateBgn = DtBgn
				,dateEnd = DtEnd
				,chkBgn = pDate
			)
		)
		outdat <- paste0('RC5WMEAN', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.noMul.roll.WMEAN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_ANR']] %>% unlist())
		message((38+39+40+41+42)/5)
	}

	#712. Mean of all Working Days from 20161008 to 20161013
	if (TRUE){
		DtEnd <- asDates('20161013')
		L_obsDates$values <- DtEnd
		DtBgn <- L_obsDates$shiftDays(kshift = -4, preserve = F, daytype = 'W')
		pDate <- L_obsDates$shiftDays(kshift = -5, preserve = F, daytype = 'W')
		args.noMul.roll.WMEAN <- modifyList(
			args.noMul.roll.WMEAN
			,list(
				dateBgn = DtBgn
				,dateEnd = DtEnd
				,chkBgn = pDate
			)
		)
		outdat <- paste0('RC5WMEAN', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.noMul.roll.WMEAN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_ANR']] %>% unlist())
		message((39+40+41+42+43)/5)
	}

	#713. Mean of all Working Days from 20161010 to 20161014, with a data frame provided as [inDatPtn]
	if (TRUE){
		DtEnd <- asDates('20161014')
		L_obsDates$values <- DtEnd
		DtBgn <- L_obsDates$shiftDays(kshift = -4, preserve = F, daytype = 'W')
		pDate <- L_obsDates$shiftDays(kshift = -5, preserve = F, daytype = 'W')
		datCfg <- data.frame(
			FilePath = args.noMul.roll.WMEAN[['inDatPtn']]
			,PathSeq = 1
			,FileName = basename(args.noMul.roll.WMEAN[['inDatPtn']])
			,chkType = args.noMul.roll.WMEAN[['inDatType']]
			,stringsAsFactors = F
		) %>%
			dplyr::mutate(chkdf = NULL)
		args.noMul.roll.WMEAN <- modifyList(
			args.noMul.roll.WMEAN
			,list(
				dateBgn = DtBgn
				,dateEnd = DtEnd
				,chkBgn = pDate
				,inDatPtn = datCfg
				,inDatType = 'chkType'
				,in_df = 'chkdf'
			)
		)
		outdat <- paste0('RC5WMEAN', strftime(DtEnd,'%Y%m%d'))
		assign( outdat, do.call(aggrByPeriod, args.noMul.roll.WMEAN)[['data']] )
		print(get(outdat, mode = 'list')[['A_KPI_ANR']] %>% unlist())
		message((40+41+42+43+44)/5)
	}
}
