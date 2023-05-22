#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to scale the provided numbers to their closest exponents in terms of certain base, where the numeric     #
#   | part no longer than 4 characters.                                                                                                 #
#   |IMPORTANT: [NULL/NA/Inf/-Inf] values will be eliminated from input, hence please clean up the input BEFORE calling this function,  #
#   |            otherwise the output length is possibly not the same as input.                                                         #
#   |Example:                                                                                                                           #
#   |[1]: f(2097152,1024) = 2.00M                                                                                                       #
#   |[2]: f(30120,1000) = 30.1K                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] 作图时坐标轴刻度需要统一数量级，如都以[万]作为单位标注刻度                                                                     #
#   |[2] 统计数据中多项指标数量级不同，需分别显示其最接近的数量级：某城市人口k万，GDP共m亿，道路n条；则三个数需分别按其最接近的数量级进 #
#   |    行显示                                                                                                                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |inNum      :   The vector/list of numerics to scale respectively                                                                   #
#   |ScaleBase  :   The base to which to scale the numbers with exponent                                                                #
#   |                [Default: 1000] Use 1000 to scale the numbers                                                                      #
#   |map_units  :   The mapping dictionary (as a named vector) to append to the scaled numbers as suffix                                #
#   |unify      :   Unify the entire list of numbers into the same scale                                                                #
#   |                [NULL]<Default> Do not unify the numbers while leave them to scale respectively                                    #
#   |                [(char)] Single character selected from the values in [map_units], to scale all the numbers in this unit           #
#   |                [(function name)] Function, such as [min/max/median], to scale the numbers into the same one as directed           #
#   |                IMPORTANT: A function is always applied to the ABSOLUTE values of the given numbers during scaling.                #
#   |scientific :   The same parameter for the function [format]. Please check R document for more information                          #
#   |...        :   Additional arguments to the function [unify], such as [na.rm = T]. Please check R document for more information     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[list]     :   A list with 2 elements as below:                                                                                    #
#   |[$values]  :   The vector/list of formatted numbers in the same length as the input vector/list                                    #
#   |                [characters of formatted numbers]                                                                                  #
#   |                IMPORTANT: Its length is less than the input if there is [NULL/NA/Inf/-Inf] value as provided.                     #
#   |[$parts]   :   A data.frame that stores all the attributes to format each number                                                   #
#   |                [$k_idx] Index of the number among the input list                                                                  #
#   |                [$k_exp] Integer part of the exponent                                                                              #
#   |                [$f_sgn] Sign of the input values, with '-' prefixing the output result if it is negative                          #
#   |                [$a_val] Actual (probably scaled) number used for formatting                                                       #
#   |                [$k_dgt] Number of significant digits to display, including decimals                                               #
#   |                [$k_dec] Decimal length of the scaled number                                                                       #
#   |                [$f_sci] Whether this number is applied with scientific formatting                                                 #
#   |                [$c_sfx] suffix to the scaled number                                                                               #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20200301        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200303        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Add the options to unify all the numbers in the same scale, while deciding whether to show them in scientific mode.         #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200304        | Version | 2.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Correct the display when the scale has different length than 1000, such as '万'                                         #
#   |      |[2] Set the default value for [scientific] as TRUE, compromising most of the requirements                                   #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230522        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Now return the result in the same length as the input, mapping <NA> and <NULL> values to empty strings                  #
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
#   |   |rlang, magrittr                                                                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	rlang, magrittr
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

#We should use the pipe operands supported by below package
library(magrittr)

scaleNum <- function(inNum,ScaleBase=1000,map_units=NULL,unify=NULL,scientific=T,...){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	if (is.null(map_units)){
		if (ScaleBase == 1000) map_units <- c(kilo = 'K', million = 'M', billion = 'B', trillion = 'T', quintillion = 'Q')
		if (ScaleBase == 1024) map_units <- c(kilo = 'K', mega = 'M', giga = 'G', tera = 'T', peta = 'P', exa = 'E', zetta = 'Z')
		if (ScaleBase == 10000) map_units <- c('10K' = '万', '100M' = '亿', '1T' = '万亿', '10Q' = '亿亿')
	}
	if (is.list(inNum)) fn_apply <- lapply else fn_apply <- sapply
	names_out <- names(inNum)
	f_full <- Map(is.null, inNum) %>% unlist()
	f_inf <- Map(function(x){if (is.null(x)) F else is.infinite(x)}, inNum) %>% unlist()
	calcNum <- mapply(
		function(num, .null, .inf){if (.null | .inf) NA else num}
		,inNum, f_full, f_inf
	) %>% unlist()
	names(calcNum) <- NULL
	out_rst <- list()

	#010. Set the maximum length of integer part for the output result
	#When the length of integer part of the number exceeds the Scale Base, it will have been scaled before displayed.
	max_int <- nchar(ScaleBase) - 1

	#050. Get the signs of the input values and obtain the absolute values of them for calculation
	out_sgn <- sign(calcNum)
	calcNum <- abs(calcNum)

	#100. Set the powers/exponents for the scaled result
	if (is.null(unify)) {
		num_log <- log(calcNum,base = ScaleBase)
		exp_int <- floor(num_log)
	} else {
		if (is.character(unify)) {
			exp_int <- which(map_units == unify)
		} else {
			func_unify <- match.fun(unify)
			num_uni <- forceAndCall(1, func_unify, calcNum, ...)
			#Call the same function to scale the selected number as idol
			exp_src <- scaleNum(num_uni, ScaleBase = ScaleBase, map_units = map_units, scientific = scientific, ...)
			exp_int <- unlist(exp_src$parts$k_exp)
		}
		if (length(exp_int) > 1) stop('[',LfuncName,']More than one power scale is found during unification!')
		exp_int <- rlang::rep_along(calcNum, exp_int)
	}

	#500. Prepare the parameters for function [base::format]
	#510. Set the unit as suffix for the scaled result
	if (is.character(unify)) {
		out_unit <- rlang::rep_along(calcNum, unify)
	} else {
		out_unit <- sapply(exp_int, function(m){tryCatch(map_units[[m]], error = function(x){''})})
	}

	#520. Set the length of decimals for the scaled result
	out_int_len <- nchar(floor(calcNum/ScaleBase^exp_int))
	exp_dec <- mapply(
		function(h.calc, h.unit, h.int, h.len){
			#Here we set the default number of decimals as [1] for most cases, to shorten the total formatted length.
			#[out_dgt] part is to determine the total number of significant digits
			# message(glue::glue('[h.calc={h.calc}][h.unit={h.unit}][h.int={h.int}][h.len={h.len}]'))
			if (is.na(h.calc) | is.na(h.unit)) {
				1
			} else if (nchar(h.unit) == 0) {
				if ((h.int < 0) | is.na(h.int) | is.na(h.len)) 1
				else max(0, min(2, max_int - h.len))
			} else {
				if (abs(floor(log(h.calc, base = ScaleBase))) > which(map_units == h.unit)) 1
				else if (is.na(h.len)) 1
				else max(0, min(2, max_int - h.len))
			}
		}
		,calcNum, out_unit, exp_int, out_int_len
	)

	#530. Prepare the actual numbers to format
	out_val <- mapply(
		function(h.calc, h.unit, h.int){
			if (is.na(h.int)) NA
			else if ((nchar(h.unit) == 0) & (h.int < 0)) h.calc
			else h.calc/ScaleBase^h.int
		}
		,calcNum, out_unit, exp_int
	)

	#540. Set the number of significant digits for the scaled result
	#Please check the R document of [base::format]
	out_dgt <- sapply(
		out_val,
		function(x){
			if (is.na(x)) return(NA)
			tmplog <- floor(log(x, 10))
			#Within Decimal Metric System, when the number falls in (0.01,1000), there is no need to apply scientific format to it.
			if ((log(x, base = ScaleBase) < 1) & (tmplog > -3)) max(1, max_int + min(0, tmplog))
			#In other conditions, we only need 2 significant digits in all except the [e+nnn] part, including decimals
			#[exp_dec] part is to determine the total number of decimals
			else 2
		}
	)

	#550. Determine whether to format the numbers in scientific mode respectively
	#Please check the R document of [base::format]
	out_sci <- sapply(
		out_val,
		function(x){
			if (is.na(x)) return(F)
			tmplog <- floor(log(x, 10))
			if ((log(x, base = ScaleBase) < 1) & (tmplog > -3)) F
			else scientific
		}
	)

	#800. Create the output result
	out_rst$values <- fn_apply(
		seq_along(calcNum),
		function(i){
			if (is.na(out_val[[i]])) return('')
			paste0(
				ifelse(out_sgn[[i]] < 0, '-', '')
				,format(
					out_val[[i]]
					,digits = out_dgt[[i]], nsmall = exp_dec[[i]], scientific = out_sci[[i]]
					,big.mark=',', drop0trailing = T
				)
				,ifelse(nchar(out_unit[[i]]) == 0, '' , ' '), out_unit[[i]]
			)
		}
	)
	names(out_rst$values) <- names_out
	#[Quote: https://stackoverflow.com/questions/9281323/zip-or-enumerate-in-r ]
	# out_rst$parts <- mapply( list , exp_int , out_val , out_dgt , exp_dec , out_sci , out_unit , SIMPLIFY = F )
	# names(out_rst$parts) <- names(inNum)
	# for (i in 1:length(calcNum)) names(out_rst$parts[[i]]) <- c('k_exp','a_val','k_dgt','k_dec','f_sci','c_sfx')
	out_rst$parts <- data.frame(
		k_idx = seq_along(calcNum)
		,k_exp = exp_int
		,f_sgn = out_sgn
		,a_val = out_val
		,k_dgt = out_dgt
		,k_dec = exp_dec
		,f_sci = out_sci
		,c_sfx = out_unit
		,stringsAsFactors = F
	)

	#999. Return the list
	return(out_rst)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		usrnumc <- c( 1.2 , 12345 , 2468712 )
		usrnuml <- list( a = 12345 , b1 = NULL , b = 2468712 , a1 = NA , c = 1.2 )
		usrnums <- c( 0.305 , 0.00048102 , 0.0000005846 )

		#100. Scale the numbers respectively
		fmtnumc <- scaleNum( usrnumc )
		fmtnuml <- scaleNum( usrnuml , ScaleBase = 1024 )
		fmtnumst <- scaleNum( usrnums , scientific = T )
		fmtnumsf <- scaleNum( usrnums , scientific = F )

		#200. Scale the numbers by specific unit
		#Below is bad practice
		fmtunitlKf <- scaleNum( usrnuml , unify = 'K' , ScaleBase = 1000 , scientific = F )
		#Below is good practice
		fmtunitlKt <- scaleNum( usrnuml , unify = 'K' , ScaleBase = 1000 )

		#Below is bad practice
		fmtunitsKf <- scaleNum( usrnums , unify = 'K' , ScaleBase = 1000 , scientific = F )
		#Below is good practice
		fmtunitsKt <- scaleNum( usrnums , unify = 'K' , ScaleBase = 1000 )

		#300. Scale the numbers into the same as one among them
		#Below is bad practice
		fmtfunclf <- scaleNum( usrnuml , unify = median , ScaleBase = 1000 , scientific = F , na.rm = T )
		#Below is good practice
		fmtfunclt <- scaleNum( usrnuml , unify = median , ScaleBase = 1000 , na.rm = T )

		#Below is bad practice
		fmtfuncsf <- scaleNum( usrnums , unify = max , ScaleBase = 1000 , scientific = F )
		#Below is good practice
		fmtfuncst <- scaleNum( usrnums , unify = min , ScaleBase = 1000 )

		#390. Check the outputs
		fmtfuncst$values
		View(fmtfuncst$parts)

		#400. 场景
		#410. 作图时坐标轴刻度需要统一数量级
		chartunit <- scaleNum( usrnuml , unify = 'K' , ScaleBase = 1000 )

		#420. 某城市人口k万，GDP共m亿，道路n条
		usrstats <- list( '人口' = 689185 , 'GDP' = 5986888715 , '道路' = 681 )
		fmtstats <- scaleNum( usrstats , ScaleBase = 10000 )

		#500. Test the invalid numbers
		usrerrc <- c(1.5,NA,-26737)
		fmterrc <- scaleNum( usrerrc , unify = max , na.rm = T )

		#590. Check the outputs
		fmterrc$values
		View(fmterrc$parts)

	}
}
