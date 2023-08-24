#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to calculate the Greatest Common Divisor (GCD), a.k.a. Highest Common Factor (HCF) of two integers,      #
#   | using Stein's Algorithm.                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |IMPORTANT                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<R 4.1.1> Integer is 32bit, hence all integers larger than <2^32 - 1> are coerced to NA during bitwise operation                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |This is only a demonstration of bitwise calculation, and is much slower than <omniR$Stats$gcd> using Euclidean Algorithm           #
#   |[1] https://www.geeksforgeeks.org/steins-algorithm-for-finding-gcd/                                                                #
#   |[2] https://reddit.com/r/3blue1brown/comments/yn6wfo/divide_a_whole_number_by_2_until_it_reaches_an/                               #
#   |[3] https://www.pythonfixing.com/2022/11/fixed-numpy-int-bit-length.html                                                           #
#   |[4] https://stackoverflow.com/questions/11175131/code-for-greatest-common-divisor-in-python                                        #
#   |[5] https://www.geeksforgeeks.org/time-complexity-of-euclidean-algorithm/                                                          #
#   |[6] https://www.baeldung.com/cs/euclid-time-complexity                                                                             #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |...         :   The input integer vectors in the same length, can be spliced using big-bang operator <!!lst>                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[int]       :   Element-wise GCD of the inputs                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20230819        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1                                                                                                                   #
#   |______|____________________________________________________________________________________________________________________________#
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |See the [Full Test Program] section                                                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent packages                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |rlang, bitops                                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	rlang, bitops
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

gcdBitwise <- function(...){
	#010. Local parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#100. Define internal function to handle two vectors only
	gcdext.internal <- function(a,b){
		#100. Initialization
		rstOut <- ifelse(a > b, b, a)

		#100. Finding 2^K, where K is the greatest power of 2 that divides both a and b
		ab <- bitops::bitOr(a,b)
		exp2 <- bitops::bitAnd(ab, bitops::bitFlip(ab - 1))

		#300. Dividing a by 2 until a becomes odd
		a_exp2 <- bitops::bitAnd(a, bitops::bitFlip(a - 1))
		a <- ifelse(a, as.integer(a / a_exp2), a)

		#500. From here on, 'a' is always odd
		while (any(b != 0)) {
			#100. If b is even, remove all factor of 2 in b
			b_exp2 <- bitops::bitAnd(b, bitops::bitFlip(b - 1))
			b <- ifelse(b, as.integer(b / b_exp2), b)

			#500. Now a and b are both odd. Swap if necessary
			comp <- a > b
			tmp_a <- ifelse(comp, b, a)
			tmp_b <- ifelse(comp, a, b)

			#900. Subtract a from b
			b <- ifelse(b, tmp_b - tmp_a, b)
			a <- tmp_a

			#990. Assign the result
			rstOut <- ifelse(a != 0, a, rstOut)
		}

		#900. Restore common factors of 2
		return(rstOut * exp2)
	}

	#999. Reduce the calculation in pairs
	Reduce(gcdext.internal, rlang::list2(...))
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#[AMD Ryzen 5 5600X 6Core 3.7G]

		#100. Create the testing data
		pool <- c(7,21,10,27,87,111,35)

		aaa <- sample(pool, 1000000, replace = T)
		bbb <- sample(pool, 1000000, replace = T)
		ccc <- sample(pool, 1000000, replace = T)

		t1 <- lubridate::now()
		g1 <- gcdBitwise(aaa,bbb)
		t2 <- lubridate::now()
		print(t2 - t1)
		# 0.883s
		# 0.159s of omniPy.Stats.gcdBitwise

		head(aaa)
		head(bbb)
		head(g1)

		x1 <- gcd(aaa,bbb)

		all.equal(x1, g1)
		# TRUE

		#500. Reduce calculation on multiple vectors
		t1 <- lubridate::now()
		g2 <- gcdBitwise(aaa,bbb,ccc)
		t2 <- lubridate::now()
		print(t2 - t1)
		# 1.728s
		# 0.327s of omniPy.Stats.gcdBitwise

		head(aaa)
		head(bbb)
		head(ccc)
		head(g2)
	}
}

#[Terminology]
if (FALSE){'
Time Complexity: O(N*N)
Auxiliary Space: O(1)

Quote: https://www.geeksforgeeks.org/highest-power-of-two-that-divides-a-given-number/?ref=ml_lbp
a <- 64
b <- 48
ab <- a | b

[1] Below gives the maximum power to 2 that divides ab (There is no efficient <bit_length> function in R 4.1.1):
4 == (ab ^ (ab - 1)).bit_length() - 1

[2] Below two algorithms give the number that divides ab:
16 == ab & ~(ab - 1)
16 == 1 << (ab & -ab).bit_length() - 1
'}
