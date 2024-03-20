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
#   |key         :   The name of the data.frame stored in the RData to read into RAM                                                    #
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
#   | Log  |[1] Introduce argument <usecols> to filter columns before applying <funcConv> for standardization purpose                   #
#   |      |[2] The provided column list is matched to all columns in the source data in the first place, so that anyone that is NOT in #
#   |      |     the source can be ignored, rather than triggering exception                                                            #
#   |      |[4] If none of the requested columns exists in the source, an empty data frame is returned with 0 columns and <k> rows      #
#   |      |[5] Superfluous arguments are now eliminated without triggering exception                                                   #
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
#   |   |glue, magrittr, rlang, dplyr, tidyselect                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	glue, magrittr, rlang, dplyr, tidyselect
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

std_read_R <- function(
	infile
	,key
	,funcConv = function(x) x
	,...
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	if (missing(key)) stop(glue::glue('[{LfuncName}][key] is not provided!'))

	#013. Define the local environment.
	kw <- rlang::list2(...)
	myenv <- new.env()

	#100. Determine the <usecols>
	usecols <- kw[['usecols']] %>% unlist() %>% {.[!is.na(.)]}
	has_usecols <- !is.null(usecols)

	#500. Overwrite the keyword arguments
	params_load <- formals(load)

	#510. Obtain all defaults of keyword arguments of the function
	kw_raw <- params_load[!names(params_load) %in% c('file','envir', '...')]

	#550. In case the raw API takes any variant keywords, we also identify them
	if ('...' %in% names(params_load)) {
		kw_varkw <- kw[!names(kw) %in% c(names(kw_raw),'file','envir','usecols')]
	} else {
		kw_varkw <- list()
	}

	#590. Create the final keyword arguments for calling the function
	kw_final <- c(
		kw[(names(kw) %in% names(kw_raw)) & !(names(kw) %in% c('file','envir','usecols'))]
		,kw_varkw
	)

	#700. Load the data directly
	vec_files <- do.call(
		load
		,c(
			list(
				infile
				,envir = myenv
			)
			,kw_final
		)
	)

	#800. Filter the columns
	rstOut <- myenv[[key]]
	if (has_usecols) {
		rstOut %<>% dplyr::select(tidyselect::any_of(usecols))
	}

	#900. Clear the temporary environment
	rm(myenv)

	#999. Return the table
	return(rstOut)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#100. Create data frame
		testdf <- data.frame(
			v1 = c(0,1)
			,v2 = c('a','b')
			,stringsAsFactors = F
		)
		testloc <- getwd()
		testfile <- file.path(testloc, 'testloadR.RData')
		save('testdf', file = testfile)

		#200. Load the data, ignoring superfluous arguments
		vfydf1 <- std_read_R(testfile, 'testdf', nonsense = 'abc')
		lapply(vfydf1, class)

		#300. Load the data with specific columns, ignoring those not existing in the source
		vfydf2 <- std_read_R(testfile, 'testdf', usecols = c('v1','v3'))
		lapply(vfydf2, class)

		#900. Load the data by requesting a column that does not exist
		vfyempty <- std_read_R(testfile, 'testdf', usecols = c('v3'))
		class(vfyempty)
		# [1] "data.frame"
		str(vfyempty)
		# 'data.frame':	2 obs. of  0 variables

		#990. Purge
		if (file.exists(testfile)) file.remove(testfile)

	}
}
