#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to validate the input as a data.frame or the likes by matching their [class]es to the predefined ones    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |...          :   Various arguments in either form as below, that indicates a list of objects to be validated                       #
#   |                 [1] Name parameters just as calling other functions with [...] as parameter                                       #
#   |                 [2] A list with named members, similar as above, but provided in a combined list                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[vector    ] :   Logical vector that indicates which ones among the provided objects are data.frame-like                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210829        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |rlang, vctrs                                                                                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	rlang, vctrs
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

isDF <- function(...){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	#Below statements are copied from [dplyr::bind_rows]
	dots <- rlang::list2(...)
	is_flattenable <- function(x) vctrs::vec_is_list(x) && !rlang::is_named(x)
	if (length(dots) == 1 && rlang::is_bare_list(dots[[1]])) {
		dots <- dots[[1]]
	}
	dots <- rlang::flatten_if(dots, is_flattenable)
	in_names <- names(dots)
	dfclass <- c(
		'data.frame' , 'tbl_df' , 'tbl'
		, 'groupedData' , 'nfnGroupedData' , 'nfGroupedData' , 'nmGroupedData' , 'nffGroupedData'
		, 'table' , 'tbl_cube' , 'spec_tbl_df'
	)

	#500. Validate the [class] of the input objects
	rstOut <- sapply(dots, function(x) any(class(x) %in% dfclass))

	#700. Assign the names to the result
	names(rstOut) <- in_names

	#999. Return the data frame
	return(rstOut)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		x1 <- data.frame(x = as.Date('20210101','%Y%m%d'))
		x2 <- data.frame(x = strptime('20210101 12:00:00','%Y%m%d %H:%M:%S'), y = 1)
		lst_x <- list(a1 = x1, x2)
		y1 <- 3
		y2 <- 'abc'

		#100. Provide the data frames as parameters
		cls_1 <- isDF( a1 = x1, a2 = x2, y1, a3 = y2 )

		#200. Provide the data frames as list
		cls_1 <- isDF( lst_x )

		#300. Test on a plain value
		cls_2 <- isDF('aa')

	}
}
