#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to unstack (i.e. fold) the provided dataframe to the same type and shape of the model object, following  #
#   | the convention of <vecStack> as a reverse process                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] When any function is designed to unanimously handle <vector>, <data.frame> and scalar value (or list of such), use             #
#   |     <vecStack> to unify the input data and hence the internal process, and then this function to create output in the same type   #
#   |     and shape as the input                                                                                                        #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |df          :   data.frame to unstack                                                                                              #
#   |idRow       :   Name of the column indicating the row (axis-0) position of the values to export                                    #
#   |                 [<vecStack>  ] <Default> See documents of the captioned function                                                  #
#   |idCol       :   Name of the column indicating the column (axis-1) position of the values to export                                 #
#   |                 [<vecStack>  ] <Default> See documents of the captioned function                                                  #
#   |valName     :   Name of the column storing the values to unstack                                                                   #
#   |                 [<vecStack>  ] <Default> See documents of the captioned function                                                  #
#   |modelObj    :   Model object to determine the output type and shape                                                                #
#   |                 [NULL        ] <Default> Function fails if it is not provided                                                     #
#   |funcConv    :   Callable to process the unstacked dataframe, in case of dtype conversion during result process or other needs      #
#   |                 [<see def.>  ] <Default> Do not apply further process upon the unstacked data before transformation               #
#   |                 [callable    ]           Callable that takes only one positional argument                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<any>       :   Object in the same type and shape of the <modelObj>                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20230617        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230911        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Fixed a bug when input object is empty                                                                                  #
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
#   |   |magrittr, rlang, vctrs, glue, dplyr, tidyr, tidyselect                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvOp                                                                                                                    #
#   |   |   |vecStack                                                                                                                   #
#   |   |   |isDF                                                                                                                       #
#   |   |   |isVEC                                                                                                                      #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	magrittr, rlang, vctrs, glue, dplyr, tidyr, tidyselect
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

library(magrittr)

vecUnstack <- function(
	df
	,idRow = formals(vecStack)[['idRow']]
	,idCol = formals(vecStack)[['idCol']]
	,valName = formals(vecStack)[['valName']]
	,modelObj = NULL
	,funcConv = function(x) x
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#012. Handle the parameter buffer
	if (!isDF(df)) {
		stop(glue::glue('[{LfuncName}][df] must be data.frame, got [{paste0(class(df), collapse = ",")}]!'))
	}
	#[ASSUMPTION]
	#[1] Sequence of row ID and column ID matters
	#[2] For unstacking purpose, we need to sort by column ID then by row ID, to ensure all values for the same columns
	#     are stored in the same block
	vfy_nans <- c(idCol,idRow)
	vfy_cols <- c(vfy_nans, valName)
	col_nonexist <- !(vfy_cols %in% colnames(df))
	if (any(col_nonexist)) {
		col_error <- vfy_cols[col_nonexist]
		stop(glue::glue('[{LfuncName}]Column names [{paste0(col_error, collapse = "][")}] cannot be found in [df]!'))
	}
	if (!is.null(modelObj)) {
		if (!(isDF(modelObj) | isVEC(modelObj) | vctrs::vec_is_list(modelObj))) {
			stop(glue::glue('[{LfuncName}]Type [{class(modelObj)}] of [modelObj] is not recognized!'))
		}
	}
	col_nans <- sapply(df[vfy_nans], anyNA)
	if (any(col_nans)) {
		nan_error <- vfy_nans[col_nans]
		stop(glue::glue('[{LfuncName}]Columns [{paste0(nan_error, collapse = "][")}] should not contain NA values!'))
	}

	#015. Function local variables

	#100. Obtain the attributes of the model object
	#130. Shape
	#[ASSUMPTION]
	#[1] We always <unstack> the input <df> by <idRow> and <idCol>
	#[2] Hence the shape of the unstacked data is always a 2-element vector
	if (isDF(modelObj)) {
		mdl_shape <- dim(modelObj)
	} else {
		mdl_shape <- c(length(modelObj), 1)
	}
	mdl_empty <- any(mdl_shape == 0)

	#150. Names if any
	mdl_names <- names(modelObj)

	#170. Index if any
	if (isDF(modelObj)) {
		mdl_index <- rownames(modelObj)
	} else {
		mdl_index <- NULL
	}

	#400. Unstack the data
	#410. Obtain the dimensions of the output result
	if (nrow(df) == 0) {
		#Empty data will be handled during output
		rst_shape <- mdl_shape

		if (!mdl_empty) {
			stop(glue::glue('[{LfuncName}]Shape of [modelObj] [({paste0(mdl_shape, collapse = ",")})] is not recognized!'))
		}
	} else {
		rst_shape <- c(dplyr::n_distinct(df[[idRow]]), dplyr::n_distinct(df[[idCol]]))
	}

	#419. Abort if the output shape is different from the model object
	if (any(rst_shape != mdl_shape)) {
		stop(glue::glue(
			'[{LfuncName}]Unstack result has shape [({paste0(mdl_shape, collapse = ",")})]'
			,' different as [modelObj] [({paste0(mdl_shape, collapse = ",")})]!'
		))
	}

	#430. Handle empty structures in certain classes
	if (mdl_empty) {
		return(modelObj %>% funcConv())
	}

	#450. Differentiate the process
	if (mdl_shape[[length(mdl_shape)]] == 1) {
		rstPre <- df %>%
			dplyr::select_at(vfy_cols) %>%
			dplyr::arrange_at(vfy_nans) %>%
			dplyr::select_at(valName) %>%
			funcConv()
	} else {
		#[ASSUMPTION]
		#[1] The column to unstack MUST BE first selected
		#[2] It is tested that the ID column may not necessarily be Factor, but it is presumed safer
		#[3] <unstack> removes the data class hence we set it back to all resulting columns
		rstPre <- df %>%
			dplyr::select_at(vfy_cols) %>%
			dplyr::arrange_at(vfy_nans) %>%
			dplyr::group_by_at(idCol) %>%
			dplyr::group_split() %>%
			lapply(function(x){
				int.name <- x %>% dplyr::pull(idCol) %>% unique() %>% as.character()
				rstOut <- x %>% dplyr::select_at(valName)
				colnames(rstOut) <- int.name
				return(rstOut)
			}) %>%
			dplyr::bind_cols() %>%
			funcConv()
	}

	#700. Apply attributes to the result
	if (isDF(modelObj)) {
		rstOut <- rstPre %>% as.data.frame()
		colnames(rstOut) <- mdl_names
		rownames(rstOut) <- mdl_index
	} else if (isVEC(modelObj) | is.null(modelObj)) {
		rstOut <- rstPre %>% dplyr::pull(valName)
		names(rstOut) <- mdl_names
	} else {
		rstOut <- rstPre %>%
			dplyr::pull(valName) %>%
			as.list()
		names(rstOut) <- mdl_names
	}

	#999. Purge
	return(rstOut)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#100. Prepare sample data
		#[ASSUMPTION]
		#[1] We need the class of all columns to be the same
		data_raw <- data.frame(
			int = c(1,3,5)
			,float = c(0.5, 1.7, 3.2)
			,float2 = c(2.2, 7.6, 4.8)
		)

		#200. Stack it with the default parameters
		data_trns <- vecStack(data_raw)

		#300. Stack a list
		list_raw <- list(4.0,aa = 3.1,7.9)
		list_trns <- vecStack(list_raw)

		#400. Unstack
		uns_data <- vecUnstack(data_trns, modelObj = data_raw)
		uns_list <- vecUnstack(list_trns, modelObj = list_raw)

		#800. Speed test
		data_large <- data_raw %>% dplyr::sample_n(1000000, replace = T)
		trns_large <- vecStack(data_large)

		t1 <- lubridate::now()
		uns_large <- vecUnstack(trns_large, modelObj = data_large)
		t2 <- lubridate::now()
		print(t2 - t1)
		# 0.50s on average
		View(uns_large)

	}
}
