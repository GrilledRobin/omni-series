#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to compare the columns of the input list of data frames, and output a checklist (data.frame) for those   #
#   | columns that have different classes among the input data frames while issuing a message in terms of the requested message level.  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |...          :   Various named parameters in either form as below, that indicates a list of data frames for extraction             #
#   |                 [1] Name parameters just as calling other functions with [...] as parameter                                       #
#   |                 [2] A list with named members, similar as above, but provided in a combined list                                  #
#   |with.attr    :   Whether to include the [attr]s from the input data frames into the output data frame                              #
#   |                 [NULL            ] <Default> No need to include the [attr]s of the input list of data frames                      #
#   |                 [chr list/vector ]           The indicated [attr]s to extract from the input data frames and set as new column in #
#   |                                               the output data frame                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[data.frame] :   The combined data frame that stores the columns in the same names but with different classes in the input list of #
#   |                  data frames as well as any requested attibutes (given they are provided in the input list)                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210126        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |dplyr, rlang, purrr, vctrs, glue, magrittr                                                                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvOp                                                                                                                    #
#   |   |   |combine_col_classes                                                                                                        #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	dplyr, rlang, purrr, vctrs, glue, magrittr
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

library(magrittr)

debug_comp_datcols <- function(..., with.attr = NULL){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	if (length(with.attr)==0) with.attr <- NULL
	else if (!is.character(unlist(with.attr))) stop('[',LfuncName,']','[with.attr] should be provided as a character vector!')

	#300. Retrieve the classes of the columns in all the data frames
	dat_classes <- combine_col_classes( ..., with.attr = with.attr )

	#500. Check the classes among the columns
	#510. Calculate the frequency at level: [ col_name * col_class ]
	sum_by_class <- dat_classes %>%
		dplyr::group_by(col_name, col_class) %>%
		dplyr::summarize( freq = dplyr::n_distinct(dat_name), .groups = 'keep' ) %>%
		dplyr::ungroup() %>%
		suppressMessages()

	#520. Calculate the frequency at level: [ col_name ]
	sum_by_dats <- dat_classes %>%
		dplyr::group_by(col_name) %>%
		dplyr::summarize( ndat = dplyr::n_distinct(dat_name), .groups = 'keep' ) %>%
		dplyr::ungroup() %>%
		suppressMessages()

	#550. Identify the columns with different classes among the data frames
	#When any combination of [ col_name * col_class ] is in different [dat_name] numbers to that of [ col_name ],
	# the column MUST have different classes within at least 2 data frames
	#This method is valid no matter how many classes are there for any single column in a single data frame.
	#如果一个字段有两个class，那么在其他表格里也必须是同样的两个class，否则以下方法仍能捕获它
	err_match_class <- sum_by_class %>%
		#These two tables have the same column: [ col_name ], hence any join method is acceptable
		dplyr::inner_join(sum_by_dats, by = c('col_name')) %>%
		dplyr::filter(freq != ndat)

	#700. Retrieve all necessary information for above columns as identified
	dat_out <- dat_classes %>%
		dplyr::inner_join(
			err_match_class %>% dplyr::select(col_name) %>% dplyr::distinct(col_name)
			, by = c('col_name')
		) %>%
		dplyr::arrange(col_name, col_class)

	#910. Print a warning message if there are any columns identified
	if (nrow(err_match_class)) {
		message('[',LfuncName,']','Columns are found with different classes in different data frames!')
		print(err_match_class)
	}

	#999. Return the data frame
	return(dat_out)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		library(magrittr)

		x1 <- data.frame(x = as.Date('20210101','%Y%m%d'))
		x2 <- data.frame(x = strptime('20210101 12:00:00','%Y%m%d %H:%M:%S'), y = 1)
		lst_x <- list(a1 = x1, a2 = x2)
		attr(lst_x$a1, 'tblname') <- c('tbl1')
		attr(lst_x[[2]], 'tblname') <- c('tbl_x')
		attr(lst_x[[1]], 'paths') <- c('aaa')
		attr(lst_x[[2]], 'paths') <- NULL

		#100. Provide the data frames as parameters
		cls_1 <- debug_comp_datcols( a1 = x1, a2 = x2 )

		#200. Provide the data frames as list
		cls_1 <- debug_comp_datcols( lst_x, with.attr = c('tblname', 'paths') )

	}
}
