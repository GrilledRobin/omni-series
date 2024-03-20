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
#   |infile      :   The name (as character string) of the file or data frame to read into RAM                                          #
#   |funcConv    :   Callable to mutate the loaded dataframe                                                                            #
#   |                 [<see def.>  ] <Default> Do not apply further process upon the data                                               #
#   |                 [callable    ]           Callable that takes only one positional argument with data.frame type                    #
#   |...         :   Various named parameters for the encapsulated function call if applicable                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[df]        :   The data frame to be read into RAM from the source                                                                 #
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
#   |   |omniR$Dates                                                                                                                    #
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

std_read_SAS <- function(
	infile
	,funcConv = function(x) x
	,...
){
	#010. Parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#013. Define the local environment.
	kw <- rlang::list2(...)
	f_nullify <- F

	#500. Overwrite the keyword arguments
	params_read_sas <- formals(haven::read_sas)

	#510. Obtain all defaults of keyword arguments of the function
	kw_raw <- params_read_sas[!names(params_read_sas) %in% c('data_file','col_select', '...')]

	#550. In case the raw API takes any variant keywords, we also identify them
	if ('...' %in% names(params_read_sas)) {
		kw_varkw <- kw[!names(kw) %in% c(names(kw_raw),'data_file','col_select','usecols')]
	} else {
		kw_varkw <- list()
	}

	#590. Create the final keyword arguments for calling the function
	kw_final <- c(
		kw[(names(kw) %in% names(kw_raw)) & !(names(kw) %in% c('data_file','col_select','usecols'))]
		,kw_varkw
	)

	#700. Determine the <usecols>
	#710. Split the kwargs
	usecols <- kw[['usecols']] %>% unlist() %>% {.[!is.na(.)]}
	col_select <- kw[['col_select']] %>% unlist() %>% {.[!is.na(.)]}
	has_usecols <- !is.null(usecols)
	has_col_select <- !is.null(col_select)
	cols_req <- NULL

	#719. Raise exception
	if (has_usecols & has_col_select) {
		stop(glue::glue('[{LfuncName}]Cannot specify <usecols> and <col_select> at the same time!'))
	}

	#730. Combine the requests
	if (has_usecols) cols_req <- usecols
	if (has_col_select) cols_req <- col_select

	#750. Handle requests by ignoring character case in column names
	if (!is.null(cols_req)) {
		#100. Modify the arguments by setting the input number of observations as 0
		kw_empty <- c(
			kw_final[!names(kw_final) %in% c('n_max')]
			,list('n_max' = 0)
		)

		#500. Load an empty data
		df_empty <- do.call(
			haven::read_sas
			,c(
				list(data_file = infile)
				,kw_empty
			)
		)
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
			kw_final <- kw_empty
			f_nullify <- T
		}
	}

	#750. Modify the <col_select> argument
	kw_col <- list('col_select' = cols_req)

	#800. Load the data
	if (f_nullify) {
		rstOut <- do.call(
			haven::read_sas
			,c(
				list(data_file = infile)
				,kw_empty
				,kw_col
			)
		) %>%
			dplyr::select(-tidyselect::all_of(names(.)))
	} else {
		rstOut <- do.call(
			haven::read_sas
			,c(
				list(data_file = infile)
				,kw_final
				,kw_col
			)
		)
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
}

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
		tt3 <- std_read_SAS(
			file.path(dir_omniPy, 'omniPy', 'AdvDB', 'test_loadsasdat.sas7bdat')
			,usecols = 'dt_test'
			,encoding = 'GB2312'
			#Below non-used argument is eliminated during the call
			,nonsense = 'abc'
		)
		lapply(tt3, class)

		#900. Load the SAS dataset by requesting a column (regardless of character case) that does not exist
		tt_empty <- std_read_SAS(
			file.path(dir_omniPy, 'omniPy', 'AdvDB', 'test_loadsasdat.sas7bdat')
			,usecols = 'aaa'
			,encoding = 'GB2312'
		)
		class(tt_empty)
		# [1] "tbl_df"     "tbl"        "data.frame"
		str(tt_empty)
		# tibble [200 x 0] (S3: tbl_df/tbl/data.frame)
		# Named list()

	}
}
