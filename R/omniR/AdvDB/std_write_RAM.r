#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function acts as a [helper] one to standardize the writing of files or data frames with different processing arguments        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] We could pass various parameters into one single expression [kw] that have no negative impact to current function call         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |indat       :   1-item <list> with its value as the data frame or its literal name (as character string) to be exported, while the #
#   |                 key of it is discarded                                                                                            #
#   |                [IMPORTANT   ] This argument is for standardization purpose to construct a unified API                             #
#   |outfile     :   Name as character string indicating the converted object                                                           #
#   |funcConv    :   Function to mutate the input data frame before exporting it                                                        #
#   |                [<see def.>  ] <Default> Do not apply further process upon the data                                                #
#   |                [function    ]           Function that takes only one positional argument with data.frame type                     #
#   |frame       :   <frame> object in which to create the variables                                                                    #
#   |                [<see def.>  ] <Default> Create the variables in the caller frame                                                  #
#   |                [frame       ]           Dedicated <frame> in which to create the variables                                        #
#   |...         :   Various named parameters for the encapsulated function call if applicable                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<int>       :   Return code from the encapsulated function call                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20240215        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |rlang, glue                                                                                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvOp                                                                                                                    #
#   |   |   |get_values                                                                                                                 #
#   |   |   |gen_locals                                                                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	rlang, glue
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

#We should use the big-bang operand [!!!] supported by below package
library(rlang)

std_write_RAM <- function(
	indat
	,outfile
	,funcConv = function(x) x
	,frame = sys.frame()
	,...
){
	#010. Parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#012. Handle the parameter buffer.
	if (!all(typeof(indat) == 'list')) {
		stop(glue::glue('[{LfuncName}]<indat> must be a 1-item list, while <{toString(typeof(indat))}> is given!'))
	}
	if (length(indat) != 1) {
		stop(glue::glue('[{LfuncName}]<indat> must be a 1-item list, while <{toString(length(indat))}> are given!'))
	}

	#013. Define the local environment.
	kw <- rlang::list2(...)
	rc <- 0

	#500. Overwrite the keyword arguments
	params_raw <- formals(get_values)

	#510. Obtain all defaults of keyword arguments of the function
	#[ASSUMPTION]
	#[1] We do not retrieve the VAR_KEYWORD args of the function, as it is designed for other purpose
	kw_raw <- params_raw[!names(params_raw) %in% c('inplace','...')]

	#590. Create the final keyword arguments for calling the function
	kw_final <- kw[(names(kw) %in% names(kw_raw)) & !(names(kw) %in% c('inplace'))]

	#600. Identify the data frame to be exported
	val <- indat[[1]]
	if (isVEC(val)) if (is.character(val)) {
		val <- do.call(get_values, c(list(val, inplace = F), kw_final))
	}

	#700. Identify the frame to export the data
	#[ASSUMPTION]
	#[1] It cannot be detected how deep this function is called along the stack
	#[2] It can neither be detected which along the call stack should we export the data for other processes
	#[3] Usually we put the data at the farthest stack, probably <global> to ensure maximum compatibility
	if (!is.environment(frame)) {
		k_depth <- rlang::env_depth(sys.frame())
		frame <- parent.frame(k_depth)
	}

	#800. Write the data
	do.call(gen_locals, rlang::list2(!!rlang::sym(outfile) := funcConv(val), frame = frame))

	#999. Return the result
	return(rc)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#100. Prepare testing environment
		aaa <- data.frame(a = c(1,3,5), b = c(5,7,8))
		myenv <- new.env()

		#200. Create a data frame in current frame
		rc <- std_write_RAM(
			list('vfy' = aaa)
			,'bbb'
			,funcConv = function(x){x %>% dplyr::select(-tidyselect::any_of('b'))}
		)
		print(bbb)
		#   a
		# 1 1
		# 2 3
		# 3 5
		rm('bbb')

		#300. Create a data frame in a separate environment
		rc <- std_write_RAM(
			list('vfy' = aaa)
			,'bbb'
			,frame = myenv
		)
		print(myenv$bbb)
		#   a b
		# 1 1 5
		# 2 3 7
		# 3 5 8
		rm('myenv')

	}
}
