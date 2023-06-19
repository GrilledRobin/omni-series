#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to stack (i.e. unfold) the provided 1-D or 2-D iterable object into a dataframe by setting all input     #
#   | values into one column, to simplify the future process. Use <vecUnstack> to transform such structure back to its shape and type   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |IMPORTANT:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] All input values must be in the same class, otherwise the result is unexpected                                                 #
#   |[2] If the input is a data.frame, class of all columns must be the same as well                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] When any function is designed to unanimously handle <vector>, <data.frame> and scalar value (or list of such), use             #
#   |     this function to unify the input data and hence the internal process                                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |vec         :   Vector to stack, can be vector, data.frame with class of all columns being the same, list of single scalars of the #
#   |                 same class, or single scalar value                                                                                #
#   |                 No plan to support other types; please transform them before calling this function                                #
#   |idRow       :   Name of the column indicating the row (axis-0) position of the input values, in the output result                  #
#   |                 [.idRow.     ] <Default> This column is exported to the result                                                    #
#   |idCol       :   Name of the column indicating the column (axis-1) position of the input values, in the output result               #
#   |                 [.idCol.     ] <Default> This column is exported to the result                                                    #
#   |valName     :   Name of the column storing the stacked input values, in the output result                                          #
#   |                 [.val.       ] <Default> This column is exported to the result                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<DataFrame> :   data.frame with below columns:                                                                                     #
#   |                 [<idRow>     ]           Input position at axis-0                                                                 #
#   |                 [<idCol>     ]           Input position at axis-1                                                                 #
#   |                 [<valName>   ]           Input value at above position                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20230617        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
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
#   |   |magrittr, rlang, vctrs, glue, dplyr, tidyr, tidyselect                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvOp                                                                                                                    #
#   |   |   |isDF                                                                                                                       #
#   |   |   |isVEC                                                                                                                      #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	magrittr, rlang, vctrs, glue, dplyr, tidyr, tidyselect
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

library(magrittr)

vecStack <- function(
	vec
	,idRow = '.idRow.'
	,idCol = '.idCol.'
	,valName = '.val.'
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#015. Function local variables
	tmp_stack <- c(
		'row_seq' = idRow
		,'col_seq' = idCol
		,'X..i..' = valName
	)
	ren_stack <- names(tmp_stack)
	names(ren_stack) <- tmp_stack

	#500. Convert the input value into a dataframe
	if (isDF(vec)) {
		vec_proc <- vec
	} else if (isVEC(vec)) {
		vec_proc <- data.frame(vec, stringsAsFactors = F)
	} else if (vctrs::vec_is_list(vec)) {
		vec_proc <- data.frame(unlist(vec, recursive = F), stringsAsFactors = F)
	} else {
		stop(glue::glue('[{LfuncName}]Type of input [{typeof(vec)}] is not recognized!'))
	}

	#510. Obtain the type of the vector to stack
	if (ncol(vec_proc) == 0) {
		vec_type <- 'numeric'
	} else {
		vec_type <- typeof(vec_proc %>% dplyr::pull())
	}

	#700. Stack the translated data
	#710. Obtain the attribute of the data
	vec_shape <- dim(vec_proc)

	#750. Differentiate the process
	if (vec_shape[[length(vec_shape)]] == 1) {
		rstOut <- vec_proc
		colnames(rstOut) <- valName
		rstOut %<>%
			dplyr::mutate(
				!!rlang::sym(idRow) := dplyr::row_number()
				,!!rlang::sym(idCol) := 1
			)
	} else {
		#100. Identify the row ID and column ID for the output
		row_seq <- seq_len(nrow(vec_proc))
		col_seq <- seq_along(vec_proc) %>% rep(each = nrow(vec_proc))

		#700. Stack the primitive type of values
		#Quote: https://www.statology.org/stack-columns-in-r/
		#[ASSUMPTION]
		#[1] <stack> removes the attributes of the input, hence for various vectors, such as <lubridate::Period>,
		#     it cannot be applied directly
		#[2] Even if we extract the attributes of such objects and do corresponding <stack> as well, it consumes
		#     a lot of time <O*N> where <N> is the number of attributes
		#[3] Hence, we resemble the process by setting the element sequence to the same as that out of <stack>
		rstOut <- vec_proc %>%
			lapply(data.frame, stringsAsFactors = F) %>%
			dplyr::bind_rows()

		#800. Correct the empty data
		if (nrow(rstOut) == 0) {
			rstOut %<>%
				dplyr::mutate(
					!!rlang::sym(idRow) := numeric(0)
					,!!rlang::sym(idCol) := numeric(0)
					,!!rlang::sym(valName) := do.call(vec_type, list(0))
				)
		} else {
			rstOut %<>%
				cbind(row_seq) %>%
				cbind(col_seq) %>%
				dplyr::rename(dplyr::any_of(ren_stack))
		}
	}

	#790. Remove the row index of the result (make it cardinal starting from 1)
	rownames(rstOut) <- NULL

	#999. Purge
	return(rstOut)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#100. Prepare sample data
		#[ASSUMPTION]
		#[1] We need the class of all columns to be the same
		data_raw <- data.frame(
			int = c(1,3,5)
			,float = c(0.5, 1.7, 3.2)
			,float2 = c(2.2, 7.6, 4.8)
		)

		#200. Stack it with the default parameters
		data_trns <- vecStack(data_raw)
		View(data_raw)
		View(data_trns)

		#300. Stack a list
		list_trns <- vecStack(list(4.0,3.1,7.9))

		#800. Speed test
		data_large <- data_raw %>% dplyr::sample_n(1000000, replace = T)

		t1 <- lubridate::now()
		trns_large <- vecStack(data_large)
		t2 <- lubridate::now()
		print(t2 - t1)
		# 0.04s on average
		View(data_large)
		View(trns_large)

	}
}
