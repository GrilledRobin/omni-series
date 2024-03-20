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
#   |                [<see def.>  ] <Default> Do not apply further process upon the data                                                #
#   |                [callable    ]           Callable that takes only one positional argument with data.frame type                     #
#   |frame       :   Environment in which to search for objects                                                                         #
#   |                [None        ] <Default> Search in all frames along the call stack                                                 #
#   |                [environment ]           Dedicated environment in which to search the objects                                      #
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
#   | Date |    20210829        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce the new function [omniR$AdvOp$get_values] to standardize the value retrieval of variables                     #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20231209        | Version | 2.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce argument <funcConv> to enable mutation of the loaded data and thus save RAM consumption                       #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20240213        | Version | 2.20        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |magrittr, rlang, dplyr, tidyselect, glue                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |get_values                                                                                                                 #
#   |   |   |ls_frame                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	magrittr, rlang, dplyr, tidyselect, glue
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

std_read_RAM <- function(
	infile
	,funcConv = function(x) x
	,frame = NULL
	,...
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#013. Define the local environment.
	kw <- rlang::list2(...)

	#100. Determine the <usecols>
	usecols <- kw[['usecols']] %>% unlist() %>% {.[!is.na(.)]}
	has_usecols <- !is.null(usecols)

	#500. Load the data
	if (!is.environment(frame)) {
		#100. Retrieve the keyword arguments
		params_raw <- formals(get_values)

		#300. Obtain all defaults of keyword arguments of the function
		#[ASSUMPTION]
		#[1] We do not retrieve the VAR_KEYWORD args of the function, as it is designed for other purpose
		kw_raw <- params_raw[!names(params_raw) %in% c('inplace','...')]

		#500. Create the final keyword arguments for calling the function
		kw_final <- kw[(names(kw) %in% names(kw_raw)) & !(names(kw) %in% c('inplace','usecols'))]

		#900. Retrieval
		rstOut <- do.call(
			get_values
			,c(
				list(
					infile
					,inplace = F
				)
				,kw_final
			)
		)
	} else {
		#100. Retrieve the keyword arguments
		params_raw <- formals(ls_frame)

		#300. Obtain all defaults of keyword arguments of the function
		kw_raw <- params_raw[!names(params_raw) %in% c('pattern','verbose','...')]

		#400. In case the raw API takes any variant keywords, we also identify them
		if ('...' %in% names(params_raw)) {
			kw_varkw <- kw[!names(kw) %in% c(names(kw_raw),'pattern','verbose','usecols')]
		} else {
			kw_varkw <- list()
		}

		#500. Create the final keyword arguments for calling the function
		kw_final <- c(
			kw[(names(kw) %in% names(kw_raw)) & !(names(kw) %in% c('pattern','verbose','usecols'))]
			,kw_varkw
		)

		#900. Retrieval
		#[ASSUMPTION]
		#[1] The input file name is a literal string and may contain dots (as R allows), we need to escape it during searching
		rstPre <- do.call(ls_frame, c(
			list(
				'frame' = frame
				,'pattern' = paste0('^',gsub('\\.','\\\\.',infile),'$')
				,'verbose' = T
			)
			,kw_final
		))

		#950. Raise exception if multiple objects are found
		if (length(rstPre) > 1) {
			stop(glue::glue(
				'[{LfuncName}]Multiple objects found for pattern [infile] as <{names(rstPre)}>! It is designed to load only one!'
			))
		} else if (length(rstPre) == 0) {
			rstOut <- NULL
		} else {
			rstOut <- rstPre[[1]]
		}

	}

	#800. Filter the columns
	if (has_usecols) {
		rstOut %<>% dplyr::select(tidyselect::any_of(usecols))
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

		#100. Prepare testing environment
		aaa <- data.frame(a = c(1,3,5), b = c(5,7,8))
		myenv <- new.env()
		myenv$aaa <- data.frame(b = c(9,7,5), d = c(7,5,3))

		#200. Load a data frame from current frame
		bbb <- std_read_RAM(
			'aaa'
			,funcConv = function(x){x %>% dplyr::select(-tidyselect::any_of('b'))}
		)
		print(bbb)
		#   a
		# 1 1
		# 2 3
		# 3 5
		rm('bbb')

		#300. Load a data frame from a specific environment
		ccc <- std_read_RAM(
			'aaa'
			,frame = myenv
		)
		print(ccc)
		#   b d
		# 1 9 7
		# 2 7 5
		# 3 5 3
		rm('ccc')
		rm('myenv')

	}
}
