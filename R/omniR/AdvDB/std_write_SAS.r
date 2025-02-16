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
#   |indat         :   1-item <list> with its value as the data frame or its literal name (as character string) to be exported, while   #
#   |                   the key of it is not validated, since SAS dataset only contains one data frame per file.                        #
#   |                   [IMPORTANT   ] This argument is for standardization purpose to construct a unified API                          #
#   |outfile       :   PathLike object indicating the full path of the exported data file                                               #
#   |funcConv      :   Function to mutate the input data frame before exporting it                                                      #
#   |                   [<see def.>  ] <Default> Do not apply further process upon the data                                             #
#   |                   [function    ]           Function that takes only one positional argument with data.frame type                  #
#   |inDat         :   The same argument in the ancestor function, which is a placeholder in this one, omitted and overwritten as       #
#   |                   <indat> is of different input type so it no longer takes effect                                                 #
#   |                   [IMPORTANT] We always have to define such argument if it is also in the ancestor function, and if we need to    #
#   |                   supersede it by another argument. This is because we do not know the <kind> of it in the ancestor and that it   #
#   |                   may be POSITIONAL_ONLY and prepend all other arguments in the expanded signature, in which case it takes the    #
#   |                   highest priority during the parameter input. We can solve this problem by defining a shared argument in this    #
#   |                   function with lower priority (i.e. to the right side of its superseding argument) and just do not use it in the #
#   |                   function body; then inject the fabricated one to the parameters passed to the call of the ancestor.             #
#   |                   [<see def.>  ] <Default> Use the same input as indicated in <indat>                                             #
#   |outFile       :   The same argument in the ancestor function, which is a placeholder in this one, superseded by <outfile> so it no #
#   |                   longer takes effect                                                                                             #
#   |                   [<see def.>  ] <Default> Use the same input as <outfile>                                                        #
#   |...           :   Various named parameters for the encapsulated function call if applicable                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<int>         :   Return code from the encapsulated function call                                                                  #
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
#   |   |AdvDB                                                                                                                          #
#   |   |   |writeSASdat                                                                                                                #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |AdvOp                                                                                                                          #
#   |   |   |isVEC                                                                                                                      #
#   |   |   |get_values                                                                                                                 #
#   |   |   |ExpandSignature                                                                                                            #
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

#[ASSUMPTION]
#[1] When we need the immediate effect of the signature expansion, we need to instantiate <ExpandSignature> before the function
#     is defined
#[2] To make the instance holding various methods unique, we set both the instance and the function in the same <local> environment
#[3] Using <local()> will immediately evaluate all statements inside it, hence we have to prepare sufficient resources before
#     executing below script, e.g. ensure <ExpandSignature> is defined in current environment
std_write_SAS <- local({
#[ASSUMPTION]
#[1] By instantiation of below class, we resemble a <class decorator> in Python
deco <- ExpandSignature$new(writeSASdat, instance = 'eSig')
myfunc <- deco$wrap(function(
	indat
	,outfile
	,funcConv = function(x) x
	,inDat = NULL
	,outFile = NULL
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

	#020. Local environment.
	dots <- rlang::list2(...)

	#100. Identify the shared arguments between this function and its ancestor functions
	val_in <- indat[[1]]
	if (isVEC(val_in)) if (is.character(val_in)) {
		val_in <- get_values(val_in, inplace = F, mode = 'list')
	}
	val_out <- funcConv(val_in)
	args_share <- list(
		'inDat' = val_out
		,'outFile' = outfile
	)
	eSig$vfyConflict(args_share)

	#700. Insert the patched values into the input parameters
	args_out <- eSig$updParams(args_share, dots)

	#999. Return the result
	return(do.call(eSig$src, args_out))
})
return(myfunc)
})

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')
		if (nchar(Sys.getenv('TZ')) == 0) Sys.setenv(TZ = 'Asia/Shanghai')

		library(magrittr)

		#500. Convert the data to SAS dataset without meta config table
		#[ASSUMPTION]
		#[1] Dtypes that are not involved below CANNOT be exported, and will lead to exceptions
		testdf <- data.frame(
			var_str = c('abcde',NA)
			,var_raw = c(as.raw(40), charToRaw('A'))
			,var_int = c(5,7)
			,var_float = c(14.678,83.32)
			,var_date = c('2023-12-25','2023-12-32')
			,var_dt = c('2023-12-25 12:34:56.789012','2023-12-31 00:24:41.16812')
			,var_time = c('12:34:56.789012','789')
			,var_bool = c(T,F)
			,var_cat = as.factor(c('abc','def'))
			,var_complex = c(1 + 3i, 12.4 + 4.6i)
			,stringsAsFactors = F
		) %>%
			dplyr::mutate(
				var_int = as.integer(var_int)
				,var_date = asDates(var_date)
				,var_dt = asDatetimes(var_dt)
				,var_time = asTimes(var_time)
			)

		outf2 <- file.path(getwd(), 'vfysas2.sas7bdat')
		rc <- std_write_SAS(
			list('vfy' = testdf)
			,outf2
		)
		if (file.exists(outf2)) rc <- file.remove(outf2)

	}
}
