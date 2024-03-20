#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to calculate the high water mark (HWM) in a convolutional way, by interpolating the vortex and the       #
#   | historically accumulated HWM result if any, to save the system calculation effort                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Scenarios:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Customer campaigns sometimes entitle the customers with game points in the method of HWM, i.e. only entitle them with the      #
#   |     additional points on top of their historically gained ones. Meanwhile, there could be manual payment that differs the         #
#   |     should-be results to encourage the customers to participate in a more proactive way (often higher than the entitlement at a   #
#   |     certain payment cycle), but they need to invest more in the future to gain more points that can cover these extra ones        #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |mark        :   Water mark at each each certain period of observation. It will be used for calculation of cumulative maximum       #
#   |vortex      :   Vortex that affects each <mark> along the period. Non-NA values among it will directly replace <mark> if           #
#   |                 <benchmark> is NOT provided. When <benchmark> is provided, its values before the last non-NA one will overwrite   #
#   |                 the calculation result, including <vortex>, even if any among them is NA. See details in the example              #
#   |                [NULL            ] <Default> No vortex is in effect                                                                #
#   |                [num. vec.       ]           A numeric vector with the same length as <mark>                                       #
#   |benchmark   :   Benchmark representing the final water mark in the history, ignoring <vortex> as it is designed to consume its     #
#   |                 effect. Only the values TILL the last non-NA one will be honored. E.g. the first 3 values of the data in          #
#   |                 C(0,NA,1,NA) will be honored, i.e. including those NA values within the valid period; while these 3               #
#   |                 values are retained in the calculation result, regardless of <vortex>                                             #
#   |                [NULL            ] <Default> No benchmark is in effect                                                             #
#   |                [num. vec.       ]           A numeric vector with the same length as <mark>                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<vec>       :   The residue of water mark on top of historical HWM at each observation period                                      #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20240302        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |magrittr, tidyr, rlang, dplyr                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	magrittr, tidyr, rlang, dplyr
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

#We should use the pipe operands supported by below package
library(magrittr)

highWaterMark <- function(
	mark
	,vortex = NULL
	,benchmark = NULL
) {
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#012. Handle the parameter buffer
	f_vortex <- !is.null(vortex)
	f_bench <- !is.null(benchmark)
	if (f_vortex) {
		if (length(vortex) != length(mark)) {
			stop('[',LfuncName,']','[mark] should have the same length as [vortex]!')
		}
	}
	if (f_bench) {
		if (length(benchmark) != length(mark)) {
			stop('[',LfuncName,']','[mark] should have the same length as [benchmark]!')
		}
	}

	#100. Prepare the high water mark (HWM)
	mark_high <- mark %>% tidyr::replace_na(0) %>% cummax()

	#300. Direct calculation without convolution if no other parameters are provided
	#310. Check if all values in <vortex> is NaN
	if (f_vortex) {
		p_vortex <- any(!is.na(vortex))
	} else {
		p_vortex <- F
	}

	#330. Check if all values in <benchmark> is NaN
	if (f_bench) {
		p_bench <- any(!is.na(benchmark))
	} else {
		p_bench <- F
	}

	#390. Simple version
	if (!p_vortex & !p_bench) {
		mark_hist <- mark_high - dplyr::lag(mark_high, n = 1, default = 0)
		mark_hist[mark_hist < 0] <- 0
		return(as.double(mark_hist))
	}

	#400. Prepare the vortex
	if (!f_vortex) {
		vortex <- rlang::rep_along(mark, NA) %>% as.double()
	}

	#500. Prepare the benchmark
	#[ASSUMPTION]
	#[1] <benchmark> should start from the first period with a consecutive trend along the same axis as <mark>
	#[2] It is presumed that the <index> of all inputs are sorted in the same and correct way
	#[2] Should the <benchmark> not fit above rule, we calculate starting from scratch with a warning
	if (!p_bench) {
		#100. Initialize the marks in history
		mark_hist <- rlang::rep_along(mark, 0) %>% as.double()

		#[ASSUMPTION]
		#[1] <p_vortex> is True till this step, i.e. at least one value is non-NULL
		#300. Retrieve all non-NULL values in the <vortex>
		vortex_vld <- seq_along(vortex)

		#500. Identify the first position
		vortex_first <- vortex_vld[!is.na(vortex)] %>% head(1)

		#900. Create the mask of valid index
		#[ASSUMPTION]
		#[1] We would commence the loop from the first non-NULL value of <vortex>
		#[2] This value is included in the loop
		idx_proc <- vortex_vld >= vortex_first
		benchmark <- as.double(mark_high - dplyr::lag(mark_high, n = 1, default = 0))
		benchmark[benchmark < 0] <- 0
	} else {
		#100. Retrieve all non-NULL values in the <benchmark>
		bench_vld <- seq_along(benchmark)

		#300. Identify the last position
		bench_last <- bench_vld[!is.na(benchmark)] %>% tail(1)

		#900. Create the mask of valid index
		#[ASSUMPTION]
		#[1] We would commence the loop right after the last non-NULL value of <benchmark>
		#[2] This value is excluded in the loop
		idx_proc <- bench_vld > bench_last
		mark_hist <- benchmark %>% as.double()
	}

	#700. Calculate the cumulative result
	#[ASSUMPTION]
	#[1] <cumsum> is affected by <vortex>, then by <benchmark>, every time along the period
	#[2] Such a situation forms a convolution
	#[3] That is why we have to repeat the calculation starting from the <benchmark> by every single <period>
	#[4] <benchmark> is at higher priority than <vortex>, as it should be, even if it has NaN values
	for (i in 1:sum(idx_proc)) {
		mark_hist <- mark_high %>%
			magrittr::subtract(
				mark_hist %>%
					tidyr::replace_na(0) %>%
					cumsum() %>%
					dplyr::lag(n = 1, default = 0)
			)
		mark_hist[mark_hist < 0] <- 0
		if (!is.null(vortex)) {
			mark_hist[!is.na(vortex)] <- vortex[!is.na(vortex)]
		}
		if (!is.null(benchmark)) {
			mark_hist[!idx_proc] <- benchmark[!idx_proc]
		}
	}

	#999. Output
	return(mark_hist)
}

#[Full Test Program;]
if (FALSE){
	#Real case test
	if (TRUE){
		#We should use the big-bang operand [!!!] supported by below package
		library(rlang)

		#100. Prepare testing data
		testdf <- data.frame(
			'cust' = c(rep_len('a', 7), rep_len('b', 5))
			,'prd' = c(seq_len(7), seq_len(5))
			,'marks' = c(0,100,500,300,0,0,1000,1500,2000,0,0,3000)
		)
		testvortex <- data.frame(
			'cust' = c('a','a','b','b')
			,'prd' = c(2,5,1,4)
			,'actual' = c(50,200,1800,100)
		)

		#200. Test the result
		testHWM <- testdf %>%
			dplyr::left_join(
				testvortex
				,by = c('cust','prd')
			) %>%
			dplyr::arrange_at(c('cust','prd')) %>%
			dplyr::group_by_at('cust') %>%
			dplyr::mutate(
				!!rlang::sym('sys') := highWaterMark(!!rlang::sym('marks'))
				,!!rlang::sym('paid') := highWaterMark(!!rlang::sym('marks'), !!rlang::sym('actual'))
			) %>%
			dplyr::ungroup()

		print(testHWM)
		# A tibble: 12 x 6
		#    cust    prd marks actual   sys  paid
		#    <chr> <dbl> <dbl>  <dbl> <dbl> <dbl>
		#  1 a         1     0     NA     0     0
		#  2 a         2   100     50   100    50
		#  3 a         3   500     NA   400   450
		#  4 a         4   300     NA     0     0
		#  5 a         5     0    200     0   200
		#  6 a         6     0     NA     0     0
		#  7 a         7  1000     NA   500   300
		#  8 b         1  1500   1800  1500  1800
		#  9 b         2  2000     NA   500   200
		# 10 b         3     0     NA     0     0
		# 11 b         4     0    100     0   100
		# 12 b         5  3000     NA  1000   900

		#300. Test without grouping
		#[ASSUMPTION]
		#[1] This function works well in both grouping and non-grouping environment
		paid2 <- highWaterMark(testHWM[['marks']],testHWM[['actual']])

		print(testHWM %>% dplyr::mutate(!!rlang::sym('paid') := paid2) %>% dplyr::select_at(c('marks','actual','paid')))
		# A tibble: 12 x 3
		#    marks actual  paid
		#    <dbl>  <dbl> <dbl>
		#  1     0     NA     0
		#  2   100     50    50
		#  3   500     NA   450
		#  4   300     NA     0
		#  5     0    200   200
		#  6     0     NA     0
		#  7  1000     NA   300
		#  8  1500   1800  1800
		#  9  2000     NA     0
		# 10     0     NA     0
		# 11     0    100   100
		# 12  3000     NA   100

		#400. Provide a <previously accumulated result>
		testbench <- data.frame(
			'cust' = c('a','a','b','b')
			,'prd' = c(1,3,1,2)
			,'prev' = c(50,100,1800,100)
		)

		testHWM2 <- testHWM %>%
			dplyr::select(-c('paid')) %>%
			dplyr::left_join(
				testbench
				,by = c('cust','prd')
			) %>%
			dplyr::arrange_at(c('cust','prd')) %>%
			dplyr::group_by_at('cust') %>%
			dplyr::mutate(
				!!rlang::sym('paid') := highWaterMark(!!rlang::sym('marks'), !!rlang::sym('actual'), benchmark = !!rlang::sym('prev'))
			) %>%
			dplyr::ungroup()

		print(testHWM2)
		# A tibble: 12 x 6
		#    cust    prd marks actual  prev  paid
		#    <chr> <dbl> <dbl>  <dbl> <dbl> <dbl>
		#  1 a         1     0     NA    50    50
		#  2 a         2   100     50    NA    NA
		#  3 a         3   500     NA   100   100
		#  4 a         4   300     NA    NA   350
		#  5 a         5     0    200    NA   200
		#  6 a         6     0     NA    NA     0
		#  7 a         7  1000     NA    NA   300
		#  8 b         1  1500   1800  1800  1800
		#  9 b         2  2000     NA   100   100
		# 10 b         3     0     NA    NA   100
		# 11 b         4     0    100    NA   100
		# 12 b         5  3000     NA    NA   900

		#700. Test speed
		smpl <- testHWM %>%
			dplyr::select(-c('paid')) %>%
			dplyr::slice_sample(n = 10000, replace = T) %>%
			dplyr::arrange_at(c('cust','prd'))

		t1 <- lubridate::now()
		smplHWM <- smpl %>%
			dplyr::group_by_at('cust') %>%
			dplyr::mutate(
				!!rlang::sym('paid') := highWaterMark(!!rlang::sym('marks'), !!rlang::sym('actual'))
			) %>%
			dplyr::ungroup()
		t2 <- lubridate::now()
		print(t2 - t1)
		# Time difference of 2.293429 secs
		# 60% of time saved against Python

		#700. Test speed when <benchmark> is provided
		smpl2 <- testHWM2 %>%
			dplyr::select(-c('paid')) %>%
			dplyr::slice_sample(n = 10000, replace = T) %>%
			dplyr::arrange_at(c('cust','prd'))

		t1 <- lubridate::now()
		smplHWM2 <- smpl2 %>%
			dplyr::group_by_at('cust') %>%
			dplyr::mutate(
				!!rlang::sym('paid') := highWaterMark(!!rlang::sym('marks'), !!rlang::sym('actual'), benchmark = !!rlang::sym('prev'))
			) %>%
			dplyr::ungroup()
		t2 <- lubridate::now()
		print(t2 - t1)
		# Time difference of 1.320616 secs
		# 60% of time saved against Python

	}
}
