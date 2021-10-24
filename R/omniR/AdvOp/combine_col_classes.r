#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to extract the [class] attributes from all [column]s in all the provided [data.frame]s and combine them  #
#   | into one [data.frame]                                                                                                             #
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
#   |[data.frame] :   The combined data frame that stores the classes of all columns of all input data frames                           #
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

combine_col_classes <- function(..., with.attr = NULL){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	if (length(with.attr)==0) with.attr <- NULL
	else if (!is.character(unlist(with.attr))) stop('[',LfuncName,']','[with.attr] should be provided as a character vector!')
	#Below statements are copied from [dplyr::bind_rows]
	dots <- rlang::list2(...)
	is_flattenable <- function(x) vctrs::vec_is_list(x) && !rlang::is_named(x)
	if (length(dots) == 1 && rlang::is_bare_list(dots[[1]])) {
		dots <- dots[[1]]
	}
	dots <- rlang::flatten_if(dots, is_flattenable)
	dots <- purrr::discard(dots, is.null)
	for (i in seq_along(dots)) {
		.x <- dots[[i]]
		if (!is.data.frame(.x) && !vctrs::vec_is(.x)) {
			rlang::abort(glue::glue("Argument {i} must be a data frame or a named atomic vector."))
		}
		if (is.null(names(.x))) {
			rlang::abort(glue::glue("Argument {i} must have names."))
		}
	}
	in_names <- names(dots)

	#500. Combine the [class]es of the input
	dat_out <- sapply(
		seq_along(dots)
		,function(i){
			d_class <- sapply(dots[[i]], class)
			df <- lapply(
				seq_along(d_class)
				,function(j){
					dcls <- data.frame(
						dat_name = in_names[[i]]
						,col_name = rep(names(d_class)[[j]], times = length(d_class[[j]]))
						,col_class = d_class[[j]]
						,stringsAsFactors = F
					)
					if (!is.null(with.attr)) {
						for (a in with.attr) {
							dcls <- dcls %>% dplyr::mutate( {{a}} := attr(dots[[i]], a) )
						}
					}
					return(dcls)
				}
			) %>%
				dplyr::bind_rows()
			return(df)
		}
		,simplify = F
	) %>%
		dplyr::bind_rows()

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
		cls_1 <- combine_col_classes( a1 = x1, a2 = x2 )

		#200. Provide the data frames as list
		cls_1 <- combine_col_classes( lst_x, with.attr = c('tblname', 'paths') )

	}
}
