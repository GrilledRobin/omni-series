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
#   |indat         :   <list> with its <names> as the literal names (as character string) to be exported, while the <values> as the     #
#   |                   corresponding objects.                                                                                          #
#   |outfile       :   PathLike object indicating the full path of the exported data file                                               #
#   |funcConv      :   Function to mutate the input data frame before exporting it                                                      #
#   |                   [<see def.>  ] <Default> Do not apply further process upon the data                                             #
#   |                   [function    ]           Function that takes only one positional argument with data.frame type                  #
#   |list          :   The same argument in the ancestor function, which is a placeholder in this one, omitted and overwritten as       #
#   |                   <indat> is of different input type so it no longer takes effect                                                 #
#   |                   [IMPORTANT] We always have to define such argument if it is also in the ancestor function, and if we need to    #
#   |                   supersede it by another argument. This is because we do not know the <kind> of it in the ancestor and that it   #
#   |                   may be POSITIONAL_ONLY and prepend all other arguments in the expanded signature, in which case it takes the    #
#   |                   highest priority during the parameter input. We can solve this problem by defining a shared argument in this    #
#   |                   function with lower priority (i.e. to the right side of its superseding argument) and just do not use it in the #
#   |                   function body; then inject the fabricated one to the parameters passed to the call of the ancestor.             #
#   |                   [<see def.>  ] <Default> Use the same input as indicated in <indat>                                             #
#   |file          :   The same argument in the ancestor function, which is a placeholder in this one, superseded by <outfile> so it no #
#   |                   longer takes effect                                                                                             #
#   |                   [<see def.>  ] <Default> Use the same input as <outfile>                                                        #
#   |envir         :   The same argument in the ancestor function, which is a placeholder in this one, input with the local one so it no#
#   |                   longer takes effect                                                                                             #
#   |                   [<see def.>  ] <Default> Suppress the input for this argument                                                   #
#   |compression_level The same argument in the ancestor function, which is a placeholder in this one as it has no default value. We    #
#   |                   follow its internal behavior by setting a <missing_arg> if no provision at runtime                              #
#   |                   [<see def.>  ] <Default> Set a NULL default value to supersede its ancestor                                     #
#   |...           :   Various named parameters for the encapsulated function call if applicable                                        #
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
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20250214        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce <ExpandSignature> to expand the signature with those of the ancestor functions for easy program design        #
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
#   |   |AdvOp                                                                                                                          #
#   |   |   |ExpandSignature                                                                                                            #
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

std_write_R <- local({
deco <- ExpandSignature$new(save, instance = 'eSig')
myfunc <- deco$wrap(function(
	indat
	,outfile
	,funcConv = function(x) x
	,list = NULL
	,file = NULL
	,envir = NULL
	,compression_level = NULL
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
		stop(glue::glue('[{LfuncName}]<indat> must be a named list, while <{toString(typeof(indat))}> is given!'))
	}

	#020. Define the local environment.
	rc <- 0
	myenv <- new.env()
	dots <- rlang::list2(...)

	#100. Convert the data as per requested and save them to temporary frame for later output
	rstOut <- sapply(
		indat
		,function(x) funcConv(x)
		,simplify = F
		,USE.NAMES = T
	)

	#190. Create corresponding local variables in temporary frame
	do.call(gen_locals, c(rstOut, list(frame = myenv)))

	#500. Identify the shared arguments between this function and its ancestor functions
	args_share <- list(
		'list' = names(rstOut)
		,'file' = outfile
		,'envir' = myenv
	)
	if (missing(compression_level)) {
		args_share <- c(args_share, list('compression_level' = rlang::missing_arg()))
	} else {
		args_share <- c(args_share, list('compression_level' = compression_level))
	}
	eSig$vfyConflict(args_share)

	#700. Insert the patched values into the input parameters
	args_out <- eSig$updParams(args_share, dots)

	#800. Write the data with API
	do.call(eSig$src, args_out)

	#900. Clear the temporary environment
	rm(myenv)

	#999. Return the result
	return(rc)
})
return(myfunc)
})

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		library(magrittr)

		#100. Create data in RAM
		aaa <- data.frame(a = c(1,3,5), b = c(5,7,8))
		bbb <- data.frame(b = c(9,7,5), d = c(7,5,3))

		#200. Write the table to harddisk
		outf <- file.path(getwd(), 'vfyR.RData')
		rc <- std_write_R(
			list(
				'aaa' = aaa
				,'bbb' = bbb
			)
			,outf
			,funcConv = function(x){x %>% dplyr::select(-tidyselect::any_of('b'))}
		)

		#300. Verify the written data
		vfyaaa <- std_read_R(outf, 'aaa')
		#   a
		# 1 1
		# 2 3
		# 3 5

		vfybbb <- std_read_R(outf, 'bbb')
		#   d
		# 1 7
		# 2 5
		# 3 3

		#309. Check whether the input object is modified
		print(bbb)
		#   b d
		# 1 9 7
		# 2 7 5
		# 3 5 3

		#990. Purge
		if (file.exists(outf)) rc <- file.remove(outf)

	}
}
