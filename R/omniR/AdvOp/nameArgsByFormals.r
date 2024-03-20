#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to try to assign proper names for the arguments provided BEFORE calling a function                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Coerce the arguments provided for the dynamic call to functions                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |.args       :   <pairlist> for assigning names, preferrably generated via <rlang::list2(...)>                                      #
#   |                [<see def.>  ] <Default> Empty pairlist for processing                                                             #
#   |func        :   Function from which to extract the formals for evaluation                                                          #
#   |                [<see def.>  ] <Default> Simple function for testing                                                               #
#   |                [function    ]           Function that has various formals                                                         #
#   |.coerce     :   Whether to try to remove excessive arguments if the <func> does not take dynamic dots <...> as formals             #
#   |                [TRUE        ] <Default> Remove excessive arguments                                                                #
#   |                [FALSE       ]           Validate the names and length of positional arguments by the formals                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[pairlist]  :   pairlist if the provision has valid number of elements, otherwise a simple list for compatibility purpose          #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20240217        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |magrittr, glue                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	magrittr, glue
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

#We should use the pipe operands supported by below package
library(magrittr)

nameArgsByFormals <- function(
	.args = pairlist()
	,func = function(){}
	,.coerce = T
) {
	#010. Parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#013. Define the local environment.
	kw <- .args

	#100. Retrieve the formals of the function
	formals_raw <- formals(func)

	#300. Validate the effective keyword arguments as provided
	#[ASSUMPTION]
	#[1] Positional arguments provided have no <names>, hence we should match them with the formals of the function
	#[2] Unlike Python, positional arguments during the call can be anywhere if accepted by the function
	#[3] Here we only take the convention as below
	#    [1] Except all keyword arguments during the call, the rest are provided by their positions corresponding to the
	#         rest formals of the function. We recognize these as <pos_cand>
	#    [2] We recognize the matching keyword arguments as <kw_eff>
	kw_eff <- Filter(
		function(x) {
			(x %in% names(kw)) & !(x %in% c('','...'))
		}
		,names(formals_raw)
	) %>%
		{kw[names(kw) %in% .]}

	#500. Remove the effective keywords from the formals for name matching at next step, a.k.a. candidates for positional args
	#[ASSUMPTION]
	#[1] There may be dynamic dots <...> in this list, we should match the positions until where it exists
	#[2] All the provided arguments BEFORE the position of <...> will have their names attached by this function
	#[3] The rest of these arguments will all be considered as provided for <...>, hence have no names but recognized as variant
	#     keyword arguments
	#[4] Such assumption makes the provision of <list(2, b = 1)> the same effect as <list(b = 1, 2)> during the call to a function
	#     with only positional formals as <list(a, b)>, which may not be the desired functionality but currently there is no better
	#     alternative
	#[5] From this step on, we only manipulate the <names>
	pos_cand_formals <- names(formals_raw[!names(formals_raw) %in% names(kw_eff)])
	hasDots <- '...' %in% pos_cand_formals
	posDots <- head(seq_along(pos_cand_formals)[pos_cand_formals %in% c('...')],1)

	#700. Match the names of the positional arguments
	#710. Identify the candidates from input arguments
	if ((length(kw) == 0) | (length(names(kw)) == 0)) {
		pos_cand <- kw
	} else {
		pos_cand <- kw[!names(kw) %in% names(kw_eff)]
	}
	pos_rest <- list()

	#750. Differ the calculation
	if (!hasDots) {
		#100. Remove the excessive arguments
		if (.coerce) {
			pos_eff <- pos_cand[names(pos_cand) %in% c('')]
		} else {
			#009. Verify whether there are named arguments
			vfy_names <- names(pos_cand)[!names(pos_cand) %in% c('')]
			if (length(vfy_names) > 0) {
				stop(glue::glue('[{LfuncName}]Wrong keyword arguments <{toString(vfy_names)}> provided for the function!'))
			}

			#900. Collect all candidates
			pos_eff <- pos_cand
		}

		#109. Verify whether the number of the rest arguments match that in the formals
		if (length(pos_eff) > length(pos_cand_formals)) {
			stop(glue::glue('[{LfuncName}]Too many positional arguments provided!'))
		}

		#900. Assign the names
		names(pos_eff) <- head(pos_cand_formals, length(pos_eff))
	} else {
		if (posDots == 1) {
			#100. We do not need to assign names to any of them
			pos_eff <- pos_cand
		} else {
			#100. Remove those provided with names, which we do not have to assign names
			if ((length(pos_cand) == 0) | (length(names(pos_cand)) == 0)) {
				pos_int <- pos_cand
			} else {
				pos_int <- pos_cand[names(pos_cand) %in% c('')]
			}

			#100. Only Identify the first K arguments to assign names
			pos_eff <- head(pos_int, posDots - 1)

			#500. Assign the names
			if (length(pos_eff) > 0) {
				names(pos_eff) <- head(pos_cand_formals, length(pos_eff))
			}

			#900. Identify the rest of positional arguments
			pos_rest <- tail(pos_cand, length(pos_cand) - length(pos_eff))
		}
	}

	#900. Combine the lists
	rstOut <- as.pairlist(c(pos_eff, kw_eff, pos_rest))
	if (length(rstOut) == 0) rstOut <- list()
	return(rstOut)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		testf <- function(){}
		kw_test <- list('abcd','cdef','gh','inplace' = F,'encoding' = 'GB18030')

		#[ASSUMPTION]
		#[1] Since <...> is the first among the formals, we do not assign <mode> as name of any among the positional arguments
		kw_ren <- nameArgsByFormals(kw_test, get_values)
		# [[1]]
		# [1] "abcd"
		#
		# [[2]]
		# [1] "cdef"
		#
		# [[3]]
		# [1] "gh"
		#
		# $encoding
		# [1] "GB18030"
		#
		# $inplace
		# [1] FALSE

		#[ASSUMPTION]
		#[1] Positional arguments have names corresponding to the formals by positions
		#[2] <inplace> in the provision is eliminated
		kw_ren2 <- nameArgsByFormals(kw_test, writeSASdat)
		# $inDat
		# [1] "abcd"
		#
		# $outFile
		# [1] "cdef"
		#
		# $metaVar
		# [1] "gh"
		#
		# $encoding
		# [1] "GB18030"

		kw_toolong <- c(kw_test, list('fdea','fddfi','f33','rrfdfs','fdafsf','hrggfd','gdfd','vcxc'))
		kw_ren2_1 <- nameArgsByFormals(kw_toolong, writeSASdat)
		# [nameArgsByFormals]Too many positional arguments provided!

		#[ASSUMPTION]
		#[1] Excessive arguments are not coerced
		kw_ren3 <- nameArgsByFormals(kw_test, writeSASdat, .coerce = F)
		# [nameArgsByFormals]Wrong keyword arguments <inplace> provided for the function!

		#[ASSUMPTION]
		#[1] Excessive arguments are treated as part of <...>
		kw_ren4 <- nameArgsByFormals(kw_test, std_read_SAS)
		# $infile
		# [1] "abcd"
		#
		# $funcConv
		# [1] "cdef"
		#
		# [[3]]
		# [1] "gh"
		#
		# $inplace
		# [1] FALSE
		#
		# $encoding
		# [1] "GB18030"

		kw_ren5 <- nameArgsByFormals(kw_test, testf)
		# [nameArgsByFormals]Too many positional arguments provided!

		kw_ren6 <- nameArgsByFormals()
		# list()

	}
}
