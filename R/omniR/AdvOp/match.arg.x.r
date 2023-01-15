#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to extend the base R function [match.arg] by mutating the input argument with a customized function      #
#   | before matching it to the [choices]                                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Scenarios]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Use it for argument verification inside a function, when a mutation of the argument is required before [match.arg]             #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |arg          :   A Character vector (of length one unless several.ok is TRUE) or NULL, see [match.arg]                             #
#   |choices      :   A character vector of candidate values, see [match.arg]                                                           #
#   |arg.func     :   Function to be applied to [arg] as the first (and only) argument before matching it to [choices]                  #
#   |                 [f<x>==x        ]  <Default> Do not mutate [arg]                                                                  #
#   |choices.func :   Function to be applied to [choices] as the first (and only) argument before matching it for [arg]                 #
#   |                 [f<x>==x        ]  <Default> Do not mutate [choices]                                                              #
#   |...          :   Any other arguments that are required by [match.arg]                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<vec>        :   Same result as returned by [match.arg], see official document                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20230114        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |base                                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

match.arg.x <- function(
	arg
	,choices
	,arg.func = function(x){x}
	,choices.func = function(x){x}
	,...
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	if (!is.function(arg.func)) {
		stop('[',LfuncName,'][arg.func] must be a function!')
	}
	if (!is.function(choices.func)) {
		stop('[',LfuncName,'][choices.func] must be a function!')
	}

	#100. Determine the choices from the parent frame as a function when it is missing
	#[ASSUMPTION]
	#[1] This method is extracted from the official definition of [match.arg]
	#[2] We have to determine its value as [match.arg] is called later in nested mode, while [sys.parent()]
	#     only works for 1 level above current frame
	if (missing(choices)) {
		formal.args <- formals(sys.function(sysP <- sys.parent()))
		choices <- eval(formal.args[[as.character(substitute(arg))]], envir = sys.frame(sysP))
	}

	#200. Execute the customized function taking [arg] as the first argument
	arg_mutate <- arg.func(arg)

	#300. Execute the customized function taking [choices] as the first argument
	choices_mutate <- choices.func(choices)
	choices.no.change <- identical(choices, choices_mutate)

	#500. Match the mutated [arg] with the choices
	#[ASSUMPTION]
	#[1] Since there is a specific message guiding the program caller on available choices,
	#     we should catch it and replace it with the original [choices]
	#[2] The message pattern as replacement is extracted from the official function definition [match.arg]
	#510. Prepare function to handle [error]
	hdl_err <- function(...){
		msg <- paste0(..., collapse = '\n')
		vfy_msg <- paste(dQuote(choices_mutate), collapse = ', ')
		rep_msg <- paste(dQuote(choices), collapse = ', ')
		if (grepl(vfy_msg, msg, fixed = T)) {
			stop(gsub(vfy_msg, rep_msg, ..., fixed = T), domain = NA)
		} else {
			stop(...)
		}
	}

	#590. Try the process
	tryCatch(
		rstOut <- match.arg(arg_mutate, choices_mutate, ...)
		,error = hdl_err
	)

	#900. Differ the output
	if (choices.no.change) {
		return(rstOut)
	} else {
		#100. Find the indexes of the result in the mutated [choices]
		choices.pos <- match(rstOut, choices_mutate)

		#900. Return the values from indexing the original [choices]
		return(choices[choices.pos])
	}
}

#[Full Test Program;]
if (FALSE){
	#Below is the official definition of [match.arg] at [R==4.1.1]
	if (FALSE){
		match.arg.original <- function (arg, choices, several.ok = FALSE)
		{
			if (missing(choices)) {
				formal.args <- formals(sys.function(sysP <- sys.parent()))
				choices <- eval(formal.args[[as.character(substitute(arg))]], envir = sys.frame(sysP))
			}
			if (is.null(arg))
				return(choices[1L])
			else if (!is.character(arg))
				stop("'arg' must be NULL or a character vector")
			if (!several.ok) {
				if (identical(arg, choices))
					return(arg[1L])
				if (length(arg) > 1L)
					stop("'arg' must be of length 1")
			}
			else if (length(arg) == 0L)
				stop("'arg' must be of length >= 1")
			i <- pmatch(arg, choices, nomatch = 0L, duplicates.ok = TRUE)
			if (all(i == 0L))
				stop(gettextf("'arg' should be one of %s", paste(dQuote(choices), collapse = ", ")), domain = NA)
			i <- i[i > 0L]
			if (!several.ok && length(i) > 1)
				stop("there is more than one match in 'match.arg'")
			choices[i]
		}
	}

	#Simple test
	if (TRUE){
		#100. Prepare a function to mutate the strings into Proper Case
		#See official document for [toupper]
		toproper <- function(s, strict = FALSE) {
			cap <- function(s) paste(
				toupper(substring(s, 1, 1))
				,{s <- substring(s, 2); if(strict) tolower(s) else s}
				,sep = ""
				,collapse = " "
			)
			sapply(strsplit(s, split = " "), cap, USE.NAMES = !is.null(names(s)))
		}

		#200. Test the argument checker with Proper Case
		testfunc <- function(a = c('Ignore','The','Case'), ...){
			a <- match.arg.x(a, arg.func = purrr::partial(toproper, strict = TRUE), ...)
			message(a)
		}

		#210. Input in lower case
		testfunc('i')

		#220. Allow several matches
		testfunc(c('caSe','t'), several.ok = TRUE)

		#500. Test the argument checker ignoring cases of both [arg] and [choices]
		testfunc2 <- function(a = c('igNore','tHe','casE'), ...){
			a <- match.arg.x(a, arg.func = tolower, choices.func = tolower, ...)
			message(a)
		}

		#510. Input in mixed case
		testfunc2('iGnoRe')

		#520. Allow several matches
		testfunc2(c('caSe','thE'), several.ok = TRUE)

		#580. Test error message when more than one [arg] is provided while [several.ok = FALSE]
		testfunc2(c('case','the'))

		#590. Test error message when there is no valid match
		testfunc2('abc')
	}
}
