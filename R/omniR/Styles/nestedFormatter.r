#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is to send <message> to the console, displaying the simplified structure of a (usually nested) <list>, or a base     #
#   | vector as well according to its design                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |SCENARIOS:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Verify the structure of nested <list> when it is produced by a customized function, such as <AdvOp$strNestedParser>            #
#   |[2] The result is cleaner than that of <str()> and easy to locate the information in substructure at certain levels                #
#   |[3] Use <message()> to facilitate the log capture of the logging packages, while <print()> can hardly be captured in comparison    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |tgt         :   <list   > A list, probably nested, for printing in the console                                                     #
#   |name_       :   <chr    > Name of current node inside the provided <tgt>                                                           #
#   |                [NULL        ] <Default> Indicate that current node has no <names> attribute                                       #
#   |indent      :   <int    > Indent level of the top structure. In such recursive evaluation, each substructure will have a deeper    #
#   |                           indent level than this one                                                                              #
#   |                [int <0>     ] <Default> Set the indent of the root structure, i.e. <tgt>, as this level                           #
#   |                [<int>       ]           Starting from this level to print all the nested structures                               #
#   |kSpaces     :   <int    > Number of spaces forming a certain level of indent                                                       #
#   |                [int <2>     ] <Default> Set this number of spaces to indicate a new level of indent                               #
#   |                [<int>       ]           Set other number of spaces                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<NULL>      :   This function only send <message>s to the console, which can be captured by many logging packages                  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20260114        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |magrittr, rlang, glue                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |isVEC                                                                                                                      #
#   |   |   |isDF                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	magrittr, rlang, glue
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

#We should use the pipe operands supported by below package
library(magrittr)

nestedFormatter <- function(
	tgt
	,name_ = NULL
	,indent = 0
	,kSpaces = 2
){
	#001. Handle parameters
	recall <- sys.function()

	#050. Local parameters
	spaces <- strrep(' ', indent * kSpaces)
	#[ASSUMPTION]
	#[1] Many <data.frame>-like objects are literally <list>s, hence we need to differ them with the real <list>
	tgt_is_list <- is.list(tgt)
	if (tgt_is_list) if (isDF(tgt)) {
		tgt_is_list <- F
	}

	#100. Determine the start and end of the message
	if (length(spaces) == 1) {
		curr_bgn <- spaces
		curr_end <- spaces
	} else {
		curr_bgn <- ''
		curr_end <- ''
	}

	#200. Determine whether to display the <names> of current node
	if (is.character(name_)) {
		if (all(nchar(name_) > 0)) {
			curr_bgn %<>% paste0(glue::glue('$`{name_}` : '))
		}
	}

	#300. Determine the main content
	tgt_names <- names(tgt)
	if (tgt_is_list) {
		curr_bgn %<>% paste0('list(')
		curr_cnt <- ''
		curr_end %<>% paste0(')')
		if (all(is.null(tgt_names))) {
			tgt_names <- rlang::rep_along(tgt, '')
		}
		tgt_indent <- indent + 1
	} else {
		#100. Verify whether the vector has <names> attribute
		is_named <- !is.null(tgt_names)

		#300. Split the values into separate lines if they are too many
		if (length(tgt) > 2) {
			newline <- '\n'
			extra_spaces <- strrep(' ', (indent + 1) * kSpaces)
			closeline <- strrep(' ', indent * kSpaces)
		} else {
			newline <- ''
			extra_spaces <- ''
			closeline <- ''
		}

		#700. Export in different fashions
		#[ASSUMPTION]
		#[1] Enclose character vector with double quotes and leave <NA_character_> unquoted as difference
		#[2] Export other base vectors in their original representations
		#[3] Only print the classes of objects of any other types
		if (is.character(tgt)) {
			val <- shQuote(tgt)
			val[is.na(tgt)] <- NA_character_
			if (is_named) {
				val <- paste0(paste0('`', tgt_names, '` : '), val)
			}
			curr_cnt <- paste0(
				'chr. (', newline, extra_spaces
				, paste0(val, collapse = paste0(newline, extra_spaces, ','))
				, newline, closeline, ')'
			)
		} else if (isVEC(tgt)) {
			if (is_named) {
				val <- paste0(paste0('`', tgt_names, '` : '), tgt)
			} else {
				val <- tgt
			}
			curr_cnt <- paste0(
				head(typeof(tgt), 1), ' (', newline, extra_spaces
				, paste0(val, collapse = paste0(newline, extra_spaces, ','))
				, newline, closeline, ')'
			)
		} else {
			curr_cnt <- paste0('Object of class: (',paste0(class(tgt), collapse = ','),')')
		}
	}

	#500. Send the start and content to the console
	message(paste0(curr_bgn, curr_cnt))

	#700. Send extra levels in recursion if current target is a <list>
	if (tgt_is_list) {
		if (length(tgt) > 0){
			mapply(
				recall
				,tgt
				,tgt_names
				,tgt_indent
			)
		}
		message(curr_end)
	}
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#050. Define helper functions
		testfunc <- function(a,b,...,d = 5,gg = 20) {
			message(paste0('a : ', a))
			message(paste0('b : ', b))
			nestedFormatter(rlang::list2(...))
			message(paste0('d : ', d))
			message(glue::glue('missing gg : {missing(gg)}'))
		}

		#100. Print a normal nested list
		nestedFormatter(list(6,7,99, ff = 0, d = list(gg = 10)))
		# list(
		#   double (6)
		#   double (7)
		#   double (99)
		#   $`ff` : double (0)
		#   $`d` : list(
		#     $`gg` : double (10)
		#   )
		# )

		#200. Test inside a function call
		testfunc(6,7,99, ff = 0, d = 10)
		# a : 6
		# b : 7
		# list(
		#   double (99)
		#   $`ff` : double (0)
		# )
		# d : 10
		# missing gg : TRUE

		#300. Test to provide a <name_> at initial call
		testf1 <- function(a = 3,b,c,...){message(a);message(b);message(c);nestedFormatter(rlang::list2(...),'dots')}
		testf1(b = 1, g = 20, 2, 4, 5)
		# 2
		# 1
		# 4
		# $`dots` : list(
		#   $`g` : double (20)
		#   double (5)
		# )

		#400. Test a nested list with objects of different types
		nestedFormatter(list(
			1
			,'aa'
			,lubridate::today()
			,'this' = list(
				'bb' = data.frame(a = 1)
			)
			,vec_ = c('name1' = 1, 'name2' = 3)
		))
		# list(
		#   double (1)
		#   chr. ("aa")
		#   double (2026-01-22)
		#   $`this` : list(
		#     $`bb` : Object of class: (data.frame)
		#   )
		#   $`vec_` : double (`name1` : 1,`name2` : 3)
		# )

	}
}
