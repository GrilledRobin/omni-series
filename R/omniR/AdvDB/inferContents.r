#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to translate the attributes of all columns in the provided data frame into the syntax that can be        #
#   | used to convert the data across platforms, e.g. <data frame> -> <CSV> -> <SAS>                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inDat       :   Data frame to be inspected                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values.                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<DF>        :   Data frame describing the column-level meta information of the input data that contains below columns              #
#   |                |------------------------------------------------------------------------------------------------------------------#
#   |                |Column Name     |dtype      |Description                                                                          #
#   |                |----------------+-----------+-------------------------------------------------------------------------------------#
#   |                |VARNUM          |int        | Position of variables in the SAS dataset, as well as in the interim CSV file        #
#   |                |NAME            |str        | Column name in SAS syntax                                                           #
#   |                |FORMAT          |str        | Format name in SAS syntax                                                           #
#   |                |TYPE            |int        | Variable type, 1 for numeric, 2 for character                                       #
#   |                |LENGTH          |int        | Variable length of the actual storage in SAS dataset                                #
#   |                |FORMATL         |int        | Format length in SAS syntax, i.e. <w> in the definition <FORMATw.d>                 #
#   |                |                |           | [IMPORTANT] This value is only the display length in the converted data, the storage#
#   |                |                |           |              precision is always kept maximum during conversion                     #
#   |                |FORMATD         |int        | Format decimal in SAS syntax, i.e. <d> in the definition <FORMATw.d>                #
#   |                |                |           | [IMPORTANT] This value is only the display length in the converted data, the storage#
#   |                |                |           |              precision is always kept maximum during conversion                     #
#   |                |----------------+-----------+-------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20240212        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent Modules                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |haven, glue, magrittr, dplyr, tidyselect, tidyr, bitops                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvOp                                                                                                                    #
#   |   |   |getDtypes                                                                                                                  #
#   |   |   |apply_MapVal                                                                                                               #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	haven, glue, magrittr, dplyr, tidyselect, tidyr, bitops
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

library(magrittr)

inferContents <- function(
	inDat
){
	#010. Parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#013. Define the local environment.
	inDtype <- getDtypes(inDat)
	if (any(inDtype == 'unknown')) {
		err_type <- inDtype[inDtype == 'unknown']
		err_msg <- mapply(function(n,v){paste(n,v,sep = ' -> ')}, names(err_type), err_type) %>%
			paste0(collapse = ',')
		stop(glue::glue('[{LfuncName}]Types as [{err_msg}] cannot be intuitively converted!'))
	}
	map_fmt <- list(
		'character' = '$'
		,'complex' = '$'
		,'factor' = '$'
		,'logical' = '$'
		,'datetime' = 'DATETIME'
		,'Date' = 'YYMMDDD'
		,'time' = 'TIME'
		,'integer' = 'COMMA'
		,'raw' = 'COMMA'
		,'numeric' = 'COMMA'
	)
	map_len <- list(
		'DATETIME' = list(
			'length' = 23
			,'decimal' = 3
		)
		,'YYMMDDD' = list(
			'length' = 10
			,'decimal' = 0
		)
		,'TIME' = list(
			'length' = 12
			,'decimal' = 3
		)
		,'COMMA' = list(
			'length' = 32
			,'decimal' = 3
		)
	)

	#100. Identify column format
	col_name <- names(inDtype)
	col_format <- apply_MapVal(inDtype, map_fmt)

	#400. Infer column lengths
	#410. Data lengths
	#[ASSUMPTION]
	#[1] We set the length of numeric columns in SAS as 8 by default, with maximum compatibility
	#[2] Set the length of character columns as the minimum <k>th power raised from 2 that is larger than the maximum string length
	#     within the same column
	#Quote: https://www.listendata.com/2016/12/sas-length-of-numeric-variables.html
	dfsub_str <- inDat %>%
		dplyr::select(tidyselect::all_of(col_name[col_format == '$'])) %>%
		dplyr::mutate_all(as.character) %>%
		#Quote: https://tidyr.tidyverse.org/reference/replace_na.html
		dplyr::mutate_if(~any(is.na(.)), ~tidyr::replace_na(., '')) %>%
		dplyr::mutate_all(nchar, type = 'bytes') %>%
		sapply(max)
	dfsub_str[dfsub_str != 0] <- log2(dfsub_str[dfsub_str != 0])
	col_str_len <- data.frame(
		NAME = names(dfsub_str)
		,LENGTH = bitops::bitShiftL(1, ceiling(dfsub_str))
		,stringsAsFactors = F
	)

	#700. Create the data frame to store meta information
	rstOut <- dplyr::bind_cols(list(VARNUM = seq_along(col_name), NAME = col_name, FORMAT = col_format)) %>%
		dplyr::mutate(
			TYPE = as.integer(ifelse(FORMAT == '$', 2, 1))
		) %>%
		dplyr::left_join(
			col_str_len
			,by = 'NAME'
		) %>%
		dplyr::mutate_at('LENGTH', ~as.integer(tidyr::replace_na(., 8))) %>%
		dplyr::mutate(
			FORMATL = as.integer(ifelse(FORMAT %in% names(map_len), sapply(FORMAT, function(x){map_len[[x]][['length']]}), LENGTH))
			,FORMATD = as.integer(ifelse(
				FORMAT %in% names(map_len)
				,sapply(FORMAT, function(x){map_len[[x]][['decimal']]})
				,rlang::rep_along(FORMAT, 0)
			))
		) %>%
		dplyr::mutate(
			FORMATD = as.integer(ifelse(sapply(NAME, function(x){inDtype[[x]]} == 'integer'), rlang::rep_along(FORMAT, 0), FORMATD))
		)

	#999. Output
	return(rstOut)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')
		if (nchar(Sys.getenv('TZ')) == 0) Sys.setenv(TZ = 'Asia/Shanghai')

		library(magrittr)

		#100. Create data for test
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

		#300. Infer the meta information for data conversion
		infer_testdf <- inferContents(testdf)

	}
}
