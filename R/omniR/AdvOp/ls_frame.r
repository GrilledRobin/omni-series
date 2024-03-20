#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to list the object names or the list[name=object] if verbose, in the provided frame or all frames along  #
#   | the call stack, by matching a specific pattern to the names and the predicate upon the objects                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Search for certain pattern of functions within current session                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |frame       :   <frame> object in which to search for objects                                                                      #
#   |                [NULL        ] <Default> Search in all frames along the call stack                                                 #
#   |                [frame       ]           Dedicated <frame> in which to search the objects                                          #
#   |predicate   :   Function predicate to apply to the objects as found, only those with True predicates will be returned              #
#   |                [<see def.>  ] <Default> Do not apply predicate                                                                    #
#   |                [function    ]           Function with the first argument to be applied upon the object as found, and return bool  #
#   |pattern     :   Regex pattern to search within the object names, used for <str_detect> instead of <str_match>                      #
#   |                [<see def.>  ] <Default> Search for all names without filtration                                                   #
#   |                [str         ]           Valid Regex string representation                                                         #
#   |verbose     :   Whether to return verbose results                                                                                  #
#   |                [FALSE       ] <Default> Only return a list of names found by the conditions                                       #
#   |                [TRUE        ]           Return a dict[name:object]                                                                #
#   |...         :   Options for <stringr::regex> to compile a valid Regex parser                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<Various>   :   This function output different values in below convention:                                                         #
#   |                [1] If <verbose == FALSE>, return a [character vector] of names matching the conditions                            #
#   |                [2] If <verbose == TRUE>, return a [named list] of names pairing the objects, which match the conditions           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20240219        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |magrittr, stringr, stringi, rlang                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	magrittr, stringr, stringi, rlang
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

#We should use the pipe operands supported by below package
library(magrittr)

ls_frame <- function(
	frame = NULL
	,predicate = function(x){TRUE}
	,pattern = '.*'
	,verbose = FALSE
	,...
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	if (!is.function(predicate)) predicate <- function(x){TRUE}
	if (!is.logical(verbose)) verbose <- FALSE

	#050. Local parameters
	kw <- rlang::list2(...)

	#100. Setup Regex
	#110. Retrieve the keyword arguments
	params_r <- formalArgs(stringr::regex)
	params_i_coll <- formalArgs(stringi::stri_opts_collator)
	params_i_rx <- formalArgs(stringi::stri_opts_regex)
	params_i_br <- formalArgs(stringi::stri_opts_brkiter)

	#130. Obtain all defaults of keyword arguments of the function
	kw_raw <- c(
		params_r[!params_r %in% c('pattern')]
		,params_i_coll
		,params_i_rx
		,params_i_br
	) %>%
		{.[!. %in% c('...')]}

	#150. Create the final keyword arguments for calling the function
	kw_final <- kw[names(kw) %in% kw_raw]

	#190. Parse the pattern
	ptn <- do.call(stringr::regex, c(list(pattern = pattern), kw_final))

	#500. Define helper functions
	#[Quote: https://stackoverflow.com/questions/11885207/get-all-parameters-as-list ]
	h_globframe <- function(frame) {
		evalq(as.list(environment()), envir = frame) %>%
			{Filter(predicate, .)} %>%
			{.[stringr::str_detect(names(.), ptn)]}
	}

	#600. Directly export when a frame is specified
	if (is.environment(frame)) {
		rstOut <- h_globframe(frame)
		if (verbose) {
			return(rstOut)
		} else {
			return(names(rstOut))
		}
	}

	#700. Search starting from the parent frame and backwards
	ifr <- 1
	rstOut <- list()
	while (T) {
		#100. Retrieve the content of the parent frame to the previous one
		pframe <- parent.frame(ifr)

		#500. Glob the frame
		rstInt <- h_globframe(pframe)

		#700. Merge the results by taking the objects located in the child frames as higher priority
		rstOut <- c(
			rstOut
			,rstInt[!names(rstInt) %in% names(rstOut)]
		)

		#800. Stop the loop if current frame is the global environment
		#Quote: https://www.r-bloggers.com/2011/06/environments-in-r/
		if (environmentName(pframe) == 'R_GlobalEnv') break

		#900. Increment the counter of parent frames
		ifr <- ifr + 1
	}

	#999. Export
	if (verbose) {
		return(rstOut)
	} else {
		return(names(rstOut))
	}
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#100. Create objects
		aa1 <- 1
		aa2 <- function(){}
		aa3 <- list()
		ab1 <- 'aa'

		#300. Simple test
		ls_frame(pattern = '^aa')
		# [1] "aa1" "aa2" "aa3"

		ls_frame(pattern = '^aa', verbose = TRUE)
		# $aa1
		# [1] 1
		#
		# $aa2
		# function(){}
		#
		# $aa3
		# list()

		ls_frame(pattern = '^aa', predicate = is.list)
		# [1] "aa3"

		#400. Test the search within specific scopes
		testscope <- function(){
			frame <- environment()

			aa2 <- function(){'local'}
			aa3 <- list('1' = 3)

			#100. Include all global variables, with those local variables found prior to the globals if they share the same names
			print('All:')
			print(ls_frame(pattern = '^aa'))

			#300. Only include local variables defined in current frame
			print('Locals:')
			print(ls_frame(frame = frame, pattern = '^aa'))
		}
		testscope()
		# [1] "All:"
		# [1] "aa3" "aa2" "aa1"
		# [1] "Locals:"
		# [1] "aa3" "aa2"

		#500. Verify whether the members of <ls_frame> can be obtained
		ls_frame(pattern = 'h_globframe')
		# NULL

		ls_frame(pattern = 'h_globframe', verbose = T)
		# list()

	}
}
