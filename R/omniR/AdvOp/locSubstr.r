#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to get the start and end of substrings matching [regexp] in the provided [txt], with or without          #
#   | overlapping                                                                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[QUOTE]                                                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] https://stackoverflow.com/questions/5616822/python-regex-find-all-overlapping-matches                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |regexp     :   Regular expression used to search for substrings                                                                    #
#   |txt        :   Character vector from which to extract the substrings                                                               #
#   |overlap    :   Whether to conduct the search in an overlapping mode, as it is always non-overlapping in the official package [re]  #
#   |               [FALSE      ] <Default> Conduct non-overlapping search, following the logic in the official package [re]            #
#   |               [TRUE       ]           Search for all possible matches one character next to another from left to right            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<list>     :   List of matrices, indicating [start, end] of each match of [regexp]                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20220212        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |stringi                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	stringi
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

locSubstr <- function(
	regexp
	,txt
	,overlap = FALSE
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	if (overlap) {
		#100. Prepare the Regular Expression when it is requested to search for all overlapping matches
		rx <- paste0('(?=(', regexp, '))')

		#500. Locate the matches by extracting the [groups] as well
		str_loc <- stringi::stri_locate_all_regex(txt, rx, capture_groups = T)

		#900. Return the list of matrices of positions in terms of the first groups of the matches
		return(
			sapply(
				str_loc
				,function(x){attr(x, which = 'capture_groups')[[1]]}
				,simplify = F
			)
		)
	} else {
		return(stringi::stri_locate_all_regex(txt, regexp))
	}
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#100. Prepare test string
		str_test <- c('fffafafadgfeagaaafadf', 'ggrgrgr')
		str_ptn <- 'afa'

		#200. Test in non-overlapping mode
		print(locSubstr(str_ptn, str_test))

		#200. Test in overlapping mode
		print(locSubstr(str_ptn, str_test, overlap = T))
	}
}
