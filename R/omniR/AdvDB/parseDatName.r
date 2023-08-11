#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to parse the input string by the provided mapping dictionary, esp. for the provided [dates], to generate #
#   | the full paths of the files as indicated in the input string                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Generate a list of file full paths in terms of the provided naming convention and date series, also check their existence if   #
#   |     requested                                                                                                                     #
#   |[2] Translate the string patterns in all cells of a provided data frame by the provided [dict_map], resembling the similar         #
#   |     function as [omniR$AdvOp$apply_MapVal]                                                                                        #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |datPtn     :   The naming pattern of the data files, either located on the harddisk or in RAM of current session                   #
#   |               [NULL            ] <Default> Program raises error as there is no input                                              #
#   |               [ <str vec>      ]           Vector of strings that represent the naming convention of a series of data files       #
#   |               [ <table>        ]           Table which contains character column(s) as naming conventions                         #
#   |parseCol   :   The column(s) to be parsed if [datPtn] is provided a [data.frame]                                                   #
#   |               [NULL            ] <Default> Parse all columns for [datPtn] where applicable                                        #
#   |dates      :   Date series that is used to substitute the corresponding naming patterns in [datPtn] to generate valid data paths   #
#   |               [ <date>         ]           Any value that can be parsed by the default arguments of [omniR$Dates$asDates]         #
#   |outDTfmt   :   Format of dates as string to be used for substitution. Its [names] should exist in the [values] of [dict_map]       #
#   |               [ <vec/list>     ] <Default> See the function definition as the default argument of usage                           #
#   |inRAM      :   Whether the [datPtn] that corresponds to the full paths of data files indicates they are in RAM of current session  #
#   |               [FALSE           ] <Default> Indicates that the data files are stored on harddisk                                   #
#   |               [TRUE            ]           Indicates that the data files are stored in RAM of current session                     #
#   |               [ <vec/list>     ]           Vector/list of <logical> in the same convention as above                               #
#   |               [ <table>        ]           Table that contains corresponding columns marking whether [datPtn] is in RAM           #
#   |chkExist   :   Whether to check the data file existence after the parse of the full paths of the them                              #
#   |               [TRUE            ] <Default> Try to locate the parsed data paths                                                    #
#   |               [FALSE           ]           Do not check the existence of the parsed data paths                                    #
#   |               [ <str>          ]           Try to locate the parsed data paths by appending the requested naming suffix, see      #
#   |                                             the output naming convention as in [Return values]                                    #
#   |dict_map   :   Same argument as in [omniR$AdvOp$apply_MapVal]                                                                      #
#   |               [NULL            ] <Default> Indicates that [datPtn] does not require translation by pattern                        #
#   |...        :   Various named parameters for [omniR$AdvOp$apply_MapVal] during import; see its official document                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values.                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |df         :   [data.frame] with below set of columns:                                                                             #
#   |               [1] When [datPtn] is a string or vector/list of strings, add two columns with the translated paths as:              #
#   |                   ['datPtn'] and ['datPtn.Parsed']                                                                                #
#   |               [2] When [datPtn] is a [table], add column(s) with the translated paths as:                                         #
#   |                   [names(datPtn)] and [ paste0(names(datPtn), '.Parsed') ]                                                        #
#   |               [3] When [dates] is provided, add one column created by [omniR$Date$asDates] as:                                    #
#   |                   ['dates'] <dtype: date>                                                                                         #
#   |               [4] When [datPtn] is a string or vector/list of strings, add one column with the indicator as:                      #
#   |                   ['datPtn.inRAM']                                                                                                #
#   |               [5] When [datPtn] is a [table], add column(s) with the indicator(s) as:                                             #
#   |                   [ paste0(names(datPtn), '.inRAM') ]                                                                             #
#   |               [6] When [datPtn] is a string or vector/list of strings and [chkExist!=False], add one column as:                   #
#   |                   ['datPtn.' + ( 'chkExist' if chkExist or <str> )]                                                               #
#   |               [7] When [datPtn] is a [table] and [chkExist!=False], add column(s) as:                                             #
#   |                   [ c + '.' + ( 'chkExist' if chkExist or <str> ) for c in datPtn.names ]                                         #
#   |               [8] When [datPtn] is a [table] there is a column [dates] in it, rename it as:                                       #
#   |                   ['dates.original']  (to differ from ['dates'] that is created in this function)                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210614        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20210829        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Remove the argument [dfclass] and introduce a separate function [omniR$AdvOp$isDF] to validate the inputs               #
#   |      |[2] Introduce the new function [omniR$AdvOp$get_values] to standardize the value retrieval of variables                     #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230811        | Version | 2.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <rlang::exec> to simplify the function call with spliced arguments in the examples                            #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |magrittr, dplyr, rlang                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvOp                                                                                                                    #
#   |   |   |apply_MapVal                                                                                                               #
#   |   |   |gen_locals                                                                                                                 #
#   |   |   |isDF                                                                                                                       #
#   |   |   |get_values                                                                                                                 #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$Dates                                                                                                                    #
#   |   |   |asDates                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	magrittr, dplyr, rlang
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

library(magrittr)

parseDatName <- function(
	datPtn
	,parseCol = NULL
	,dates = NULL
	,outDTfmt = list(
		'L_d_curr' = '%Y%m%d'
		,'L_m_curr' = '%Y%m'
	)
	,inRAM = FALSE
	,chkExist = TRUE
	,dict_map = NULL
	,dfclass = c(
		'data.frame' , 'tbl_df' , 'tbl'
		, 'groupedData' , 'nfnGroupedData' , 'nfGroupedData' , 'nmGroupedData' , 'nffGroupedData'
		, 'table' , 'tbl_cube' , 'spec_tbl_df'
	)
	,...
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	parseCol <- unname(unlist(parseCol))
	if (!is.logical(chkExist) & !is.character(chkExist)) {
		stop('[',LfuncName,']','[chkExist] should either be [logical] or a single [character string]!')
	}
	if (length(chkExist) > 1) {
		warning('[',LfuncName,']','[chkExist] has its length more than 1, only the first one is used!')
		chkExist <- chkExist[[1]]
	}

	#013. Local environment
	if (!is.null(dates)) {
		#100. Abort if there are any blank names in [outDTfmt]
		outDTfmt_names <- names(outDTfmt)
		outDTfmt_names_vld <- outDTfmt_names[nchar(outDTfmt_names) > 0]
		if (length(outDTfmt_names) != length(outDTfmt_names_vld)) {
			stop('[',LfuncName,']','[outDTfmt]: Its all elements must contain names respectively!')
		}
	}

	#020. Transform [dates]
	if (!is.null(dates)) {
		dates <- data.frame('dates' = asDates(dates))
	}

	#030. Transform [datPtn]
	if (isDF(datPtn)) {
		df_ptn <- as.data.frame(datPtn)
	} else if (is.character(datPtn) | is.list(datPtn)) {
		datPtn <- unname(unlist(datPtn))
		df_ptn <- data.frame('datPtn' = datPtn)
	} else {
		stop('[',LfuncName,']','[datPtn] must be a vector/list of strings, or [table] of the previous!')
	}
	if ('dates' %in% names(df_ptn)) {
		names(df_ptn)[names(df_ptn) == 'dates'] <- 'dates.original'
	}

	#040. Transform [parseCol]
	if (isDF(datPtn) & is.character(parseCol)) {
		names_trans <- parseCol
	} else {
		names_trans <- names(df_ptn)
	}
	names_resolve <- paste0(names_trans, '.Parsed')

	#070. Transform [inRAM]
	if (isDF(inRAM)) {
		#Pass as we will directly assign columns based on this table
	} else if (is.logical(inRAM) | is.list(inRAM)) {
		inRAM <- unname(unlist(inRAM))
	} else {
		stop('[',LfuncName,']','[datPtn] must be a vector/list of [logical], or [table] of the previous!')
	}
	names_inRAM <- paste0(names_trans, '.inRAM')
	df_ptn[names_inRAM] <- inRAM

	#080. Translate [chkExist]
	if (is.logical(chkExist)) {
		if (chkExist) {
			col_exist <- paste0(names_trans, '.chkExist')
		} else {
			col_exist <- NULL
		}
	} else {
		#Till this step [chkExist] must have become a single character string.
		col_exist <- paste0(names_trans, '.', chkExist)
	}

	#100. Define helper functions to be applied to interim data frames
	#[Assumptions]:
	#[1] Helper functions are called within [dplyr::mutate], hence they only accept [vector] as arguments
	#[2] All arguments for the helper functions are vectors in length of the same [nrow] of input table

	#110. Translate naming patterns by the mapping dictionary
	rowTranslate <- function(col_dates, col_ptnDat){
		sapply(
			seq_along(col_ptnDat)
			,function(i){
				#100. Assign local variables for later step to get their respective values by batch
				if ('dates' %in% names(ptn_comb)) {
					#100. Create a [list] of [key:value] to be generated as local variables
					var_locals <- sapply(outDTfmt, function(x){strftime(col_dates[[i]], x)}, simplify = F)

					#900. Generate local variables
					gen_locals( var_locals )
				}

				#400. Translate the mapping dictionary at first by the values of above local variables
				get_Trans_val <- get_values(dict_map)

				#700. Translate the naming patterns by the new mapping dictionary
				rst <- apply_MapVal(col_ptnDat[[i]], dict_map = get_Trans_val, ... )

				#999. Return the result
				return(rst)
			}
		)
	}

	#150. Create column(s) that indicate the data file existence
	rowExistence <- function(col_inRAM, col_ptnDat){
		if (length(col_ptnDat)==0) return(logical(0))
		sapply(
			seq_along(col_ptnDat)
			,function(i){
				#Assumptions:
				#[1] If the Information Table is in RAM, its [mode] is [list]. See details in [exists] function
				if (col_inRAM[[i]]) rst <- exists(col_ptnDat[[i]], mode = 'list')
				else rst <- file.exists(col_ptnDat[[i]])

				#999. Return the result
				return(rst)
			}
		)
	}

	#400. Conduct translation of the naming pattern
	ptn_comb <- df_ptn
	if (!is.null(dict_map) & (nrow(df_ptn) != 0)) {
		#100. Create cartesian join of the naming patterns and dates
		if (isDF(dates)) if (nrow(dates)) {
			#Quote[#16]: https://stackoverflow.com/questions/35406535/cross-join-in-dplyr-in-r
			ptn_comb <- df_ptn %>% dplyr::full_join(dates, by = character())
		}

		#500. Translation by the helper function
		ptn_trans <- ptn_comb %>% dplyr::mutate_at(names_trans, ~ rowTranslate(!!rlang::sym('dates'), .))
		ptn_comb[names_resolve] <- ptn_trans[names_trans]
	} else {
		#100. Consider there is no need for translation
		ptn_comb[names_resolve] <- ptn_comb[names_trans]
	}

	#700. Check file existence if requested
	if (!is.null(col_exist)) {
		ptn_exist <- ptn_comb
		for (i in seq_along(names_trans)) {
			ptn_exist %<>% dplyr::mutate_at(names_resolve[[i]], ~ rowExistence(!!rlang::sym(names_inRAM[[i]]), .))
		}
		ptn_comb[col_exist] <- ptn_exist[names_resolve]
	}

	#999. Return the result
	return(ptn_comb)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Create envionment.
		#Below program provides the most initial environment and system options for best usage of [omniR]
		source('D:\\R\\autoexec.r')

		#We will use big-bang expression to simplify the function call later
		library(rlang)

		#100. Test if a data frame exists in current session
		aa <- data.frame('a' = c(1,2,3))
		exist_aa <- parseDatName(
			datPtn = 'aa'
			,inRAM = TRUE
		)
		View(exist_aa)

		#200. Test for multiple file patterns in multiple dates
		lst_args <- list(
			datPtn = c(
				"D:/R/omniR/SampleKPI/KPI/k ','/kpi&L_curdate..sas7bdat"
				,'D:/R/omniR/SampleKPI/KPI/K 2/kpi2_&L_curdate..sas7bdat'
			)
			,dates = c('20160329', '20160603', '20161019')
			,outDTfmt = getOption('fmt.parseDates')
			,inRAM = FALSE
			,dict_map = getOption('fmt.def.GTSFK')
		)
		lst_args <- c(lst_args, getOption('fmt.opt.def.GTSFK'))
		exist_bb <- do.call(parseDatName, lst_args)
		View(exist_bb)

		#300. Test multiple files
		test20160604 <- data.frame('a' = c(1,2,3))
		testmulti <- data.frame(
			'datIn' = "D:/R/omniR/SampleKPI/KPI/k ','/kpi&L_curdate..sas7bdat"
			,'datOut' = 'test&L_curdate.'
			,'fRAM_In' = F
			,'fRAM_Out' = T
			,stringsAsFactors = F
		)
		exist_cc <- rlang::exec(
			parseDatName
			,datPtn = testmulti %>% dplyr::select_at(c('datIn', 'datOut'))
			,dates = c('20160602', '20160603', '20160604')
			,outDTfmt = getOption('fmt.parseDates')
			,inRAM = testmulti %>% dplyr::select_at(c('fRAM_In', 'fRAM_Out'))
			,dict_map = getOption('fmt.def.GTSFK')
			,!!!getOption('fmt.opt.def.GTSFK')
		)
		if (F) {
			#Below statements are the same as the above one, but more tedious!
			lst_args2 <- list(
				datPtn = testmulti %>% dplyr::select_at(c('datIn', 'datOut'))
				,dates = c('20160602', '20160603', '20160604')
				,outDTfmt = getOption('fmt.parseDates')
				,inRAM = testmulti %>% dplyr::select_at(c('fRAM_In', 'fRAM_Out'))
				,dict_map = getOption('fmt.def.GTSFK')
			)
			lst_args2 <- c(lst_args2, getOption('fmt.opt.def.GTSFK'))
			exist_cc <- do.call(parseDatName, lst_args2)
		}
		View(exist_cc)

		#390. Test if the input has zero [nrow]
		testmulti2 <- testmulti %>% dplyr::filter(FALSE)
		exist_dd <- rlang::exec(
			parseDatName
			,datPtn = testmulti2 %>% dplyr::select_at(c('datIn', 'datOut'))
			,dates = c('20160602', '20160603', '20160604')
			,outDTfmt = getOption('fmt.parseDates')
			,inRAM = testmulti2 %>% dplyr::select_at(c('fRAM_In', 'fRAM_Out'))
			,dict_map = getOption('fmt.def.GTSFK')
			,!!!getOption('fmt.opt.def.GTSFK')
		)
		View(exist_dd)
	}
}
