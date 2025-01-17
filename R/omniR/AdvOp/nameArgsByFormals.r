#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to try to assign proper names for the parameters provided BEFORE calling a function                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Coerce the arguments provided for the dynamic call to functions                                                                #
#   |[2] Positional arguments without default values can be ignored during the call, which leaves a placeholder of type <symbol>, but   #
#   |     we will raise this exception when required as non-silent                                                                      #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |func        :   Function from which to extract the formals for evaluation                                                          #
#   |                [<see def.>  ] <Default> Simple function for testing                                                               #
#   |                [function    ]           Function that has various formals                                                         #
#   |args_       :   <pairlist/list> for assigning names, preferably generated via <rlang::list2(...)>                                  #
#   |                [<see def.>  ] <Default> Empty pairlist for processing                                                             #
#   |coerce_     :   Whether to try to remove excessive arguments silently (This is the only naming convention accepted by Python and R)#
#   |                [TRUE        ] <Default> Remove excessive arguments                                                                #
#   |                [FALSE       ]           Raise exceptions under certain situations                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[list]      :   list of (preferably keyword) parameters for a correct syntax in the future function call. If <...> exists in the   #
#   |                 function formals, extra positional/keyword parameters are also included                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20240217        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20250105        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Rewrite the entire function to support all scenarios                                                                    #
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
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
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

nameArgsByFormals <- function(
	func = function(){}
	,args_ = pairlist()
	,coerce_ = T
) {
	#010. Parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#013. Define the local environment.
	names_args <- names(args_)
	if (is.null(names_args)) {
		names_args <- rlang::rep_along(args_, '')
	}

	#100. Helper functions
	#110. Function to identify the positional arguments without default values
	flagPositional <- function(fml) {
		Map(function(x){class(x) == 'name' && typeof(x) == 'symbol'}, fml) %>% unlist()
	}

	#200. Retrieve the formals of the function
	#[ASSUMPTION]
	#[1] <...> may exist anywhere in the formals
	#[2] Arguments after <...> must be provided in keyword format, while all others can be provided as positional arguments
	#[3] Evaluation of parameters passed into a call follows below priority
	#    [1] keyword parameters will be matched by argument names
	#    [2] Positional parameters will fill the rest positions in the formals list; even if any among them have default values, their
	#         positions will be filled in the sequence as defined in the formals
	#[4] Such assumption makes the provision of <list(2, b = 1)> the same effect as <list(b = 1, 2)> during the call to a function
	#     with only positional formals as <list(a, b)>
	#[5] As a convenience call, we will put all keyword parameters to the head of the returned parameter list, and let R determine the
	#     positions of the rest parameters in the sequence they are provided
	#[6] Positional arguments without default values can be ignored during the call, which leaves a placeholder of type <symbol>, but
	#     we will raise this exception
	#[See the Examples section for testing results]
	formals_raw <- formals(func)
	names_raw <- names(formals_raw)

	#300. Locate the dots in the formals
	has_dots <- '...' %in% names_raw
	loc_dots <- head(seq_along(formals_raw)[names_raw %in% c('...')],1)
	if (length(loc_dots) == 0) loc_dots <- 0

	#400. Identify all keyword parameters as top priority
	#[ASSUMPTION]
	#[1] Excessive keyword parameters will be recognized by <...> if it exists in the formals
	#[2] Excessive keyword parameters will be ignored if <...> does not exist in the formals
	if (has_dots) {
		kw_pre <- args_[names_args != '']
	} else {
		kw_pre <- args_[names_args %in% names_raw]

		#400. Raise exception if not silent
		if (!coerce_) {
			kw_err <- args_[!names_args %in% c(names(kw_pre), '')]
			len_kw_err <- length(kw_err)
			if (len_kw_err > 0) {
				plural <- ''
				if (len_kw_err > 1) {
					plural <- 's'
				}
				stop(glue::glue('[{LfuncName}]Wrong keyword argument{plural} <{toString(names(kw_err))}> provided for the function!'))
			}
		}
	}

	#500. Eliminate duplicated names from <kw>
	#[ASSUMPTION]
	#[1] R list allows items with duplicated names
	#[2] Function call does not allow duplicated <kw> in parameter list
	#[3] We thus have to eliminate the duplicated ones to avoid error identification of positional parameters
	#510. Identify the valid <kw> for the function call by recognizing the first appearance
	kw_dup_flag <- duplicated(names(kw_pre))
	kw_in <- kw_pre[!kw_dup_flag]
	names_kw_in <- names(kw_in)
	len_kw_in <- length(kw_in)

	#550. Locate the valid <kw> that fill the holes before <...>
	loc_kw_in <- seq_along(formals_raw)[names_raw %in% names_kw_in]
	loc_kw_in_before_dots <- loc_kw_in[loc_kw_in < loc_dots]
	kw_in_before_dots <- kw_in[names_kw_in %in% names_raw[loc_kw_in_before_dots]]
	len_kw_before_dots <- length(kw_in_before_dots)

	#590. Raise exception if not silent
	if (!coerce_) {
		#100. Raise if duplicated parameters are provided
		kw_dup <- unique(names(kw_pre[kw_dup_flag]))
		len_kw_dup <- length(kw_dup)
		if (len_kw_dup > 0) {
			plural <- ''
			if (len_kw_dup > 1) {
				plural <- 's'
			}
			stop(glue::glue('[{LfuncName}]Duplicated keyword argument{plural} <{toString(names(kw_dup))}> provided for the function!'))
		}

		#300. Raise if positional arguments (without default values) after <...> are not provided
		if (has_dots) {
			#100. Identify the keyword parameters passed for the arguments after <...>
			kw_in_after_dots <- kw_in[loc_kw_in > loc_dots]

			#300. Identify all arguments after <...>
			formals_after_dots <- formals_raw[seq_along(formals_raw) > loc_dots]

			#500. Identify those without default values and without input as well
			kw_miss <- formals_after_dots %>%
				{.[!names(.) %in% names(kw_in_after_dots)]} %>%
				{.[flagPositional(.)]}
			len_kw_miss <- length(kw_miss)

			#900. Raise if any
			if (len_kw_miss > 0) {
				plural <- ''
				if (len_kw_miss > 1) {
					plural <- 's'
				}
				stop(glue::glue('[{LfuncName}]Require keyword input for argument{plural}: <{toString(names(kw_miss))}>!'))
			}
		}
	}

	#700. Identify positional-or-keyword parameters
	#[ASSUMPTION]
	#[1] Their precise positions do not matter
	#[2] Only their sequence matters
	#[3] In such case, the names can only be those arguments before <...>
	#[4] Meanwhile, we need to eliminate those already provided in keyword format
	#710. Determine the parameters
	if (has_dots) {
		if (length(kw_in) > 0) {
			pos_in <- args_[!names_args %in% names_kw_in]
		} else {
			pos_in <- args_
		}
		max_k_args <- loc_dots - 1
		max_k_pos <- max_k_args - len_kw_before_dots
	} else {
		pos_in <- args_[names_args == '']
		max_k_args <- length(formals_raw)
		max_k_pos <- max_k_args - len_kw_in
	}
	len_pos_in <- length(pos_in)

	#719. Raise exception if not silent
	if (!coerce_) {
		#100. Exception when more parameters provided than arguments
		if (!has_dots) {
			pos_err <- len_pos_in - max_k_pos
			if (pos_err > 0) {
				plural <- ''
				if (pos_err > 1) {
					plural <- 's'
				}
				stop(glue::glue('[{LfuncName}]{pos_err} excessive positional argument{plural} provided!'))
			}
		}

		#200. Raise if the provided parameters are less than the arguments
		#[ASSUMPTION]
		#[1] Valid provision includes:
		#    [1] All <kw_in> parameters
		#    [2] All <pos_in> parameters
		#[2] There could be some arguments left for check, after <kw_in> and <pos_in> are used off
		#[3] We locate the last one among them that has no default value
		#[4] All arguments from the first one that is not provided to that last one, must be provided
		#[5] The rest arguments already have defaults so they can be optionally provided
		pos_holes <- formals_raw[seq_len(max_k_args)] %>%
			{.[!names(.) %in% names_kw_in]} %>%
			{.[-seq_len(len_pos_in)]}

		#220. Tag those without default values
		pos_miss_flag <- flagPositional(pos_holes)

		#250. Identify the number of formals that must be provided, i.e. until the last one-without-default-value
		k_miss_least <- tail(seq_along(pos_holes)[pos_miss_flag], 1)
		if (length(k_miss_least) == 0) k_miss_least <- 0

		#290. Raise with rational messages
		if (k_miss_least > 0) {
			k_miss_most <- length(pos_holes)
			plural <- ''
			if (k_miss_least > 1) {
				plural <- 's'
			}
			if (k_miss_most > k_miss_least) {
				txt_err_most <- glue::glue(' ~ {k_miss_most}')
				plural <- 's'
			} else {
				txt_err_most <- ''
			}
			stop(
				glue::glue('[{LfuncName}]Require to provide {k_miss_least}{txt_err_most} more parameter{plural} for the function!')
			)
		}
	}

	#730. Further split the positional parameters into two lists
	#[ASSUMPTION]
	#[1] First list will be matched with all arguments before <...>, to obtain their names
	#[2] Second list will be left alone for final combination, as they are deemed to fill <...>
	#210. Determine the parameters to be translated as keyword provision
	len_to_be_kw <- min(max_k_pos, len_pos_in)
	pos_to_be_kw <- pos_in[seq_len(len_to_be_kw)]

	#750. Determine the parameters to be deemed as input for <...>
	if (has_dots) {
		if (len_to_be_kw > 0) {
			pos_var <- pos_in[-seq_len(len_to_be_kw)]
		} else {
			pos_var <- pos_in
		}
	} else {
		pos_var <- list()
	}

	#770. Retrieve the available names for above candidate parameters
	#[ASSUMPTION]
	#[1] Candidate names are from the rest formals other than <kw_in>, and meanwhile from the formals before <...>
	#[2] If there are items in <pos_to_be_kw>, conclusions are as below:
	#    [1] There is at least 1 positional parameter awaiting for filling the empty positional arguments
	#    [2] In silent mode (coerce_ == T), there may be insufficient positional parameters passed, we leave the exception for R
	#         to raise
	#[3] Based on above conclusions, there must have been candidate names for tagging
	#[4] Slicing of the candidate names must be in below sequence, indicating correct processing logic
	if (len_to_be_kw > 0) {
		names_cand <- names_raw[seq_len(max_k_args)] %>%
			{.[!. %in% names_kw_in]} %>%
			{.[seq_len(len_to_be_kw)]}
		names(pos_to_be_kw) <- names_cand
	}

	#900. Combine the lists
	rstOut <- c(kw_in, pos_to_be_kw, pos_var)
	if (length(rstOut) == 0) rstOut <- list()
	return(rstOut)
}

#[Full Test Program;]
if (FALSE){
	#Define helper function to print a list in a pretty format
	if (FALSE){
		library(magrittr)

		printList <- function(n = NULL,l = list(),indent = 0) {
			spaces <- strrep(' ', indent * 4)
			if (length(spaces) == 1) {
				curr_bgn <- spaces
				curr_end <- spaces
			} else {
				curr_bgn <- ''
				curr_end <- ''
			}
			if (is.character(n)) {
				if (all(nchar(n) > 0)) {
					curr_bgn %<>% paste0(glue::glue('{n} <- '))
				}
			}
			if (is.list(l)) {
				curr_bgn %<>% paste0('list(')
				curr_cnt <- ''
				curr_end %<>% paste0(')')
				l_names <- names(l)
				if (all(is.null(l_names))) {
					l_names <- rlang::rep_along(l, '')
				}
				l_indent <- indent + 1
			} else {
				curr_cnt <- l
			}
			if (is.list(l)) {
				print(paste0(curr_bgn, curr_cnt))
				mapply(
					function(n1,l1,i1) {
						spaces <- strrep(' ', i1 * 4)
						if (length(spaces) == 1) {
							curr_bgn <- spaces
							curr_end <- spaces
						} else {
							curr_bgn <- ''
							curr_end <- ''
						}
						if (is.character(n1)) {
							if (all(nchar(n1) > 0)) {
								curr_bgn %<>% paste0(glue::glue('{n1} <- '))
							}
						}
						if (is.list(l1)) {
							curr_bgn %<>% paste0('list(')
							curr_cnt <- ''
							curr_end %<>% paste0(')')
							l_names <- names(l1)
							if (all(is.null(l_names))) {
								l_names <- rlang::rep_along(l1, '')
							}
							l_indent <- i1 + 1
						} else {
							curr_cnt <- l1
						}
						if (is.list(l1)) {
							print(paste0(curr_bgn, curr_cnt))
							mapply(
								printList
								,l_names
								,l1
								,l_indent
							)
							print(curr_end)
						} else {
							print(paste0(curr_bgn, curr_cnt))
						}
					}
					,l_names
					,l
					,l_indent
				)
				print(curr_end)
			} else {
				print(paste0(curr_bgn, curr_cnt))
			}
		}

		printList(NULL, list(6,7,99, ff = 0, d = list(gg = 10)))
		# [1] "list("
		# [1] "    6"
		# [1] "    7"
		# [1] "    99"
		# [1] "    ff <- 0"
		# [1] "    d <- list("
		# [1] "        gg <- 10"
		# [1] "    )"
		# [1] ")"

		testfunc <- function(a,b,...,d = 5,gg = 20) {
			print(paste0('a : ', a))
			print(paste0('b : ', b))
			printList(NULL, rlang::list2(...))
			print(paste0('d : ', d))
			print(glue::glue('missing gg : {missing(gg)}'))
		}

		testfunc(6,7,99, ff = 0, d = 10)
		# [1] "a : 6"
		# [1] "b : 7"
		# [1] "list("
		# [1] "    99"
		# [1] "    ff <- 0"
		# [1] ")"
		# [1] "d : 10"
		# missing gg : TRUE

		testf1 <- function(a = 3,b,c,...){print(a);print(b);print(c);printList('dots',rlang::list2(...))}
		testf1(b = 1, g = 20, 2, 4, 5)
		# [1] 2
		# [1] 1
		# [1] 4
		# [1] "dots <- list("
		# [1] "    g <- 20"
		# [1] "    5"
		# [1] ")"
	}

	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		testf <- function(){}
		kw_test <- list('abcd','cdef','gh','inplace' = F,'encoding' = 'GB18030')

		#100. Basic tests
		#[ASSUMPTION]
		#[1] Since <...> is the first among the formals, we do not assign <mode> as name of any among the positional arguments
		kw_ren <- nameArgsByFormals(get_values, kw_test)
		# $inplace
		# [1] FALSE
		#
		# $encoding
		# [1] "GB18030"
		#
		# [[3]]
		# [1] "abcd"
		#
		# [[4]]
		# [1] "cdef"
		#
		# [[5]]
		# [1] "gh"

		#[ASSUMPTION]
		#[1] Positional arguments have names corresponding to the formals by positions
		#[2] <inplace> in the provision is eliminated
		kw_ren2 <- nameArgsByFormals(writeSASdat, kw_test)
		# $encoding
		# [1] "GB18030"
		#
		# $inDat
		# [1] "abcd"
		#
		# $outFile
		# [1] "cdef"
		#
		# $metaVar
		# [1] "gh"

		kw_toolong <- c(kw_test, list('fdea','fddfi','f33','rrfdfs','fdafsf','hrggfd','gdfd','vcxc'))
		kw_ren2_1 <- nameArgsByFormals(writeSASdat, kw_toolong)
		# $encoding
		# [1] "GB18030"
		#
		# $inDat
		# [1] "abcd"
		#
		# $outFile
		# [1] "cdef"
		#
		# $metaVar
		# [1] "gh"
		#
		# $dt_map
		# [1] "fdea"
		#
		# $nlsMap
		# [1] "fddfi"
		#
		# $sasReg
		# [1] "f33"
		#
		# $sasOpt
		# [1] "rrfdfs"
		#
		# $wd
		# [1] "fdafsf"

		#[ASSUMPTION]
		#[1] Excessive arguments are not coerced
		kw_ren3 <- nameArgsByFormals(writeSASdat, kw_test, coerce_ = F)
		# [nameArgsByFormals]Wrong keyword argument <inplace> provided for the function!

		#[ASSUMPTION]
		#[1] Excessive parameters are treated as part of <...>, including those excessive keyword ones
		kw_ren4 <- nameArgsByFormals(std_read_SAS, kw_test)
		# $inplace
		# [1] FALSE
		#
		# $encoding
		# [1] "GB18030"
		#
		# $infile
		# [1] "abcd"
		#
		# $funcConv
		# [1] "cdef"
		#
		# [[5]]
		# [1] "gh"

		nameArgsByFormals(testf, list(5), coerce_ = F)
		# [nameArgsByFormals]1 excessive positional argument provided!

		nameArgsByFormals(testf, list(ef = 5), coerce_ = F)
		# [nameArgsByFormals]Wrong keyword argument <ef> provided for the function!

		kw_ren6 <- nameArgsByFormals()
		# list()

		#300. Complex tests
		testf_nodots <- function(arg1,arg2 = 2,arg3,arg4 = 4,arg5,arg6 = 6,arg7 = 7){
			args_in <- as.list(environment())
			str(args_in)
		}
		testf_dots <- function(arg1,arg2 = 2,arg3,arg4 = 4,arg5,...,arg7 = 7,arg8){
			args_in <- as.list(environment())
			str(args_in)
			dots <- rlang::list2(...)
			print('dots:')
			str(dots)
		}

		#310. Where no <...> exists
		#311. Exception when extra keywords are provided
		prov01 <- list(arg1 = 1, 2, 3, arg8 = 8, arg9 = 9)
		nameArgsByFormals(testf_nodots, prov01, coerce_ = F)
		# [nameArgsByFormals]Wrong keyword arguments <arg8, arg9> provided for the function!

		#312. Exception when excessive positional parameters are provided
		#[1] Locations of keywords can be various, which is accepted by R
		prov02 <- list(arg1 = 1, 2, arg5 = 5, 3, 4, arg7 = 7, arg6 = 6, 8)
		nameArgsByFormals(testf_nodots, prov02, coerce_ = F)
		# [nameArgsByFormals]1 excessive positional argument provided!

		#313. Exception when less positional parameters are provided
		#[1] <arg5> should be provided as it has no default value
		#[2] Since there is no input for <arg4> yet, if we need <arg5> to be valid during function call, we should at least
		#     further provide <arg4> (either positional or keyword); that say, if we provide 4 parameters, <arg5> is still missing
		#[3] That is why the error message indicates we need to provide at least 2 more parameters to cover the
		#     last argument-without-default-value
		prov03 <- list(arg1 = 1, 2, 3)
		nameArgsByFormals(testf_nodots, prov03, coerce_ = F)
		# [nameArgsByFormals]Require to provide 2 ~ 4 more parameters for the function!

		#319. Specific provision
		#[1] <0,3,5> are provided to take place of <arg2> ~ <arg4>
		#[2] Hence <arg5> has no input
		#[3] Although R allows such input and set a placeholder <arg5> in the type of <symbol>, we still raise its exception
		prov04 <- list(arg1 = 1, 0, 3, 5)
		nameArgsByFormals(testf_nodots, prov04, coerce_ = F)
		# [nameArgsByFormals]Require to provide 1 ~ 3 more parameters for the function!

		#350. Where <...> exists
		#351. Exception when less positional parameters are provided
		#[1] <arg5> should be provided as it is before <...> and has no default value
		#[2] Same as above, <arg4> should also be provided as well to ensure the hole of <arg5> is filled
		prov11 <- list(arg1 = 1, 2, 3, arg8 = 8)
		nameArgsByFormals(testf_dots, prov11, coerce_ = F)
		# [nameArgsByFormals]Require to provide 2 more parameters for the function!

		#353. Exception when less keyword parameters are provided after <...>
		#[1] <arg8> is a positional argument after <...>, hence it should be provided in keyword format
		#[2] <arg7> has default value, hence it is OK not to provide it during the call
		#[3] Be cautious that <arg4, arg5> are still required to make a valid call, but since keyword check is done before positional
		#     parameter check, that exception is not raised
		prov12 <- list(arg1 = 1, 2, 3)
		nameArgsByFormals(testf_dots, prov12, coerce_ = F)
		# [nameArgsByFormals]Require keyword input for argument: <arg8>!

	}
}
