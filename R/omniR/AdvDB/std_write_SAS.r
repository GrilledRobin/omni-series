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
#   |                 key of it is not validated, since SAS dataset only contains one data frame per file.                              #
#   |                 [IMPORTANT   ] This argument is for standardization purpose to construct a unified API                            #
#   |outfile     :   PathLike object indicating the full path of the exported data file                                                 #
#   |funcConv    :   Function to mutate the input data frame before exporting it                                                        #
#   |                 [<see def.>  ] <Default> Do not apply further process upon the data                                               #
#   |                 [function    ]           Function that takes only one positional argument with data.frame type                    #
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
#   |   |omniR$AdvDB                                                                                                                    #
#   |   |   |writeSASdat                                                                                                                #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvOp                                                                                                                    #
#   |   |   |isVEC                                                                                                                      #
#   |   |   |get_values                                                                                                                 #
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

std_write_SAS <- function(
	indat
	,outfile
	,funcConv = function(x) x
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

	#500. Overwrite the keyword arguments
	params_write_sas <- formals(writeSASdat)

	#510. Obtain all defaults of keyword arguments of the function
	kw_raw <- params_write_sas[!names(params_write_sas) %in% c('inDat','outFile','...')]

	#550. In case the raw API takes any variant keywords, we also identify them
	if ('...' %in% names(params_write_sas)) {
		kw_varkw <- kw[!names(kw) %in% c(names(kw_raw),'inDat','outFile')]
	} else {
		kw_varkw <- list()
	}

	#590. Create the final keyword arguments for calling the function
	kw_final <- c(
		kw[(names(kw) %in% names(kw_raw)) & !(names(kw) %in% c('inDat','outFile'))]
		,kw_varkw
	)

	#700. Identify the data frame to be exported
	val <- indat[[1]]
	if (isVEC(val)) if (is.character(val)) {
		val <- get_values(val, inplace = F, mode = 'list')
	}

	#999. Return the result
	return(do.call(writeSASdat, c(list(funcConv(val), outFile = outfile), kw_final)))
}

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
