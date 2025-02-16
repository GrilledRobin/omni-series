#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function acts as a [helper] one to standardize the reading of files or data frames with different processing arguments        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] We could pass various parameters into one single expression [...] that have no negative impact to current function call        #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |infile        :   The name (as character string) of the file or data frame to read into RAM                                        #
#   |key           :   The placeholder to standardize the argument list as other APIs, since the ancestor has no variable argument <...>#
#   |                   , we must set a separate argument with no effect to achieve this                                                #
#   |                   [<see def.>  ] <Default> Only a placeholder and takes no effect                                                 #
#   |funcConv      :   Callable to mutate the loaded dataframe                                                                          #
#   |                   [<see def.>  ] <Default> Do not apply further process upon the data                                             #
#   |                   [callable    ]           Callable that takes only one positional argument with data.frame type                  #
#   |usecols       :   <chr     > Character vector naming the columns to be kept during loading, actually it is done after loading the  #
#   |                   entire file                                                                                                     #
#   |                   [<see def.>  ] <Default> Keep all columns of <key>                                                              #
#   |                   [chr         ]           Character vector as column names to keep                                               #
#   |data_file     :   The same argument in the ancestor function, which is a placeholder in this one, superseded by <infile> so it no  #
#   |                   longer takes effect                                                                                             #
#   |                   [IMPORTANT] We always have to define such argument if it is also in the ancestor function, and if we need to    #
#   |                   supersede it by another argument. This is because we do not know the <kind> of it in the ancestor and that it   #
#   |                   may be POSITIONAL_ONLY and prepend all other arguments in the expanded signature, in which case it takes the    #
#   |                   highest priority during the parameter input. We can solve this problem by defining a shared argument in this    #
#   |                   function with lower priority (i.e. to the right side of its superseding argument) and just do not use it in the #
#   |                   function body; then inject the fabricated one to the parameters passed to the call of the ancestor.             #
#   |                   [<see def.>  ] <Default> Use the same input as indicated in <infile>                                            #
#   |col_select    :   The same argument in the ancestor function, which is a placeholder in this one, superseded by <usecols> so it no #
#   |                   longer takes effect (However, if <usecols> is not provided while <col_select> is provided, the latter is used)  #
#   |                   [<see def.>  ] <Default> Use the same input as <usecols>                                                        #
#   |...           :   Various named parameters for the encapsulated function call if applicable                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[df]          :   The data frame to be read into RAM from the source                                                               #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210503        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20231209        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce argument <funcConv> to enable mutation of the loaded data and thus save RAM consumption                       #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240213        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce argument <usecols> to act in the same way as <col_select> for standardization purpose                         #
#   |      |[2] <usecols> and <col_select> (see haven::read_sas()) cannot be specified at the same time, but take the same effect       #
#   |      |[3] The provided column list is matched to all columns in the source data in the first place, so that anyone that is NOT in #
#   |      |     the source can be ignored, rather than triggering exception                                                            #
#   |      |[4] If none of the requested columns exists in the source, an empty data frame is returned with 0 columns and rows          #
#   |      |[5] Superfluous arguments are now eliminated without triggering exception                                                   #
#   |      |[6] <time> columns are converted by <asTimes> for standardization purpose                                                   #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20250214        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <ExpandSignature> to expand the signature with those of the ancestor functions for easy program design        #
#   |      |[2] Since the function signature is now expanded, it may no longer ignore unkown parameters in terms of the ancestor        #
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
#   |   |haven, magrittr, rlang, glue, dplyr, tidyselect                                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |ExpandSignature                                                                                                            #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |Dates                                                                                                                          #
#   |   |   |asTimes                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	haven, magrittr, rlang, glue, dplyr, tidyselect
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

std_read_SAS <- local({
deco <- ExpandSignature$new(read_sas, instance = 'eSig', srcEnv = NULL, srcPkg = 'haven')
myfunc <- deco$wrap(function(
	infile
	,funcConv = function(x) x
	,key = NULL
	,usecols = NULL
	,data_file = NULL
	,col_select = NULL
	,...
){
	#010. Parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#013. Define the local environment.
	dots <- rlang::list2(...)
	f_nullify <- F

	#100. Determine the <usecols>
	usecols %<>% unlist() %>% {.[!is.na(.)]}
	col_select %<>% unlist() %>% {.[!is.na(.)]}
	cols_req <- NULL
	if (!is.null(usecols)) {
		cols_req <- usecols
	} else if (!is.null(col_select)) {
		cols_req <- col_select
	}
	has_usecols <- !is.null(cols_req)

	#300. Identify the shared arguments between this function and its ancestor functions
	args_empty <- list(
		'data_file' = infile
		,'col_select' = NULL
	)
	eSig$vfyConflict(args_empty)

	#600. Handle requests by ignoring character case in column names
	if (has_usecols) {
		#100. Modify the arguments by setting the input number of observations as 0
		args_empty <- c(args_empty, list('n_max' = 0))
		args_int <- eSig$updParams(args_empty, dots)

		#500. Load an empty data
		df_empty <- do.call(eSig$src, args_int)
		f_nocol <- ncol(df_empty) == 0

		#900. Determine the columns to select
		cols_req <- Filter(function(x){toupper(x) %in% toupper(cols_req)}, names(df_empty))

		#990. Prepare the nullification of the result
		#[ASSUMPTION]
		#[1] Given any requested bunch of columns, if none of them exists in the input, we should export empty data, instead of
		#     exporting all columns
		#[2] In such case, we only import one column at first (since we cannot simply import no column by default), and then
		#     remove this column from the data, to minimize the system effort
		#[3] To ensure the same behavior as Python package <pyreadstat>, we also load no observation from the input
		if (length(cols_req) == 0) {
			if (!f_nocol) {
				cols_req <- names(df_empty)[[1]]
			}
			f_nullify <- T
		}
	}

	#650. Modify the <col_select> argument
	args_share <- c(
		args_empty[!names(args_empty) %in% c('col_select')]
		,list('col_select' = cols_req)
	)

	#700. Insert the patched values into the input parameters
	args_out <- eSig$updParams(args_share, dots)

	#800. Load the data
	rstOut <- do.call(eSig$src, args_out)
	if (f_nullify) {
		rstOut %<>% dplyr::select(-tidyselect::all_of(names(.)))
	}

	#850. Convert the <time> columns
	#[ASSUMPTION]
	#[1] Default class for such columns is <hms>, which is not appropriate for datetime related calculation
	#[2] We call the user defined function to convert the dtype to simplify further calculation
	#[3] <date> and <datetime> columns are well loaded, hence there is no need to handle them
	if (ncol(rstOut) > 0) {
		cls_rst <- lapply(rstOut, class)
		col_times <- Filter(function(x){any(x %in% c('hms','difftime'))}, cls_rst)
		if (length(col_times) > 0) {
			rstOut %<>% dplyr::mutate_at(names(col_times), asTimes)
		}
	}

	#999. Post process
	return(funcConv(rstOut))
})
return(myfunc)
})

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#100. Load the SAS dataset wich Chinese Characters and missing values
		dir_omniPy <- 'D:\\Python'
		tt <- std_read_SAS(file.path(dir_omniPy, 'omniPy', 'AdvDB', 'test_loadsasdat.sas7bdat'), encoding = 'GB2312')
		lapply(tt, class)

		#200. Load the empty SAS dataset
		tt2 <- std_read_SAS(file.path(dir_omniPy, 'omniPy', 'AdvDB', 'test_emptysasdat.sas7bdat'), encoding = 'GB2312')
		lapply(tt2, class)

		#300. Load the SAS dataset with specific columns, regardless of the character case; also with a superfluous argument
		#[ASSUMPTION]
		#[1] <20250214> Extra parameters are no longer ignored, given the signature is expanded by a function without <...>
		#[2] However, if the ancestor starts to take <...> in the future, the wrapped function ignores extra parameters automatically
		tt3 <- std_read_SAS(
			file.path(dir_omniPy, 'omniPy', 'AdvDB', 'test_loadsasdat.sas7bdat')
			,usecols = 'dt_test'
			,encoding = 'GB2312'
			#Below non-used argument is eliminated during the call
			,nonsense = 'abc'
		)
		# 参数没有用(nonsense = "abc")

		#900. Load the SAS dataset by requesting a column (regardless of character case) that does not exist
		tt_empty <- std_read_SAS(
			file.path(dir_omniPy, 'omniPy', 'AdvDB', 'test_loadsasdat.sas7bdat')
			,usecols = 'aaa'
			,encoding = 'GB2312'
		)
		class(tt_empty)
		# [1] "tbl_df"     "tbl"        "data.frame"
		str(tt_empty)
		# tibble [0 x 0] (S3: tbl_df/tbl/data.frame)
		# Named list()

	}
}
