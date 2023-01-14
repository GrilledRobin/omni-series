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

	#100. Determine the choices from the parent frame as a function when it is missing
	#[ASSUMPTION]
	#[1] This method is extracted from the official definition of [match.arg]
	#[2] We have to determine its value as [match.arg] is called later in nested mode, while [sys.parent()]
	#     only works for 1 level above current frame
	if (missing(choices)) {
		formal.args <- formals(sys.function(sysP <- sys.parent()))
		choices <- eval(formal.args[[as.character(substitute(arg))]], envir = sys.frame(sysP))
	}

	#500. Execute the customized function taking [arg] as the first argument
	arg_mutate <- arg.func(arg)

	#900. Match the mutated [arg] with the choices
	return(match.arg(arg_mutate, choices, ...))
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
		#100. Prepare a function
		testfunc <- function(a = c('Ignore','The','Case'), ...){
			a <- match.arg.x(a, arg.func = toupper, ...)
			message(a)
		}

		#200. Input in lower case
		testfunc('i')

		#300. Allow several matches
		testfunc(c('case','t'), several.ok = TRUE)
	}
}
