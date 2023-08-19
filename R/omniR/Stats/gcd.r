#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to calculate the Greatest Common Divisor (GCD), a.k.a. Highest Common Factor (HCF) of two integers,      #
#   | using Euclidean Algorithm.                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
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
#   |   |rlang                                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	rlang
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

gcd <- function(...){
	#010. Local parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#100. Define internal function to handle two vectors only
	gcd.internal <- function(x,y){
		#100. Initialization
		rstOut <- y

		#500. Apply the algorithm
		while (any(y != 0)) {
			temp <- y
			y <- ifelse(y, x %% y, y)
			x <- temp
			rstOut[y != 0] <- y[y != 0]
		}

		#900. Output
		return(rstOut)
	}

	#999. Reduce the calculation in pairs
	Reduce(gcd.internal, rlang::list2(...))
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
		x1 <- gcd(aaa,bbb)
		t2 <- lubridate::now()
		print(t2 - t1)
		# 0.279s
		# 0.0115s of Python numpy.gcd
		# 0.071s of Python math.gcd

		head(aaa)
		head(bbb)
		head(x1)

		#200. Define recursive version as comparison
		#Quote: https://stackoverflow.com/questions/21502181/finding-the-gcd-without-looping-r
		gcd_rec <- function(...) Reduce(function(x,y) ifelse(y, Recall(y, x %% y), x), list(...))
		# Time Complexity: O(Log min(a, b))
		# Auxiliary Space: O(Log min(a, b))

		t1 <- lubridate::now()
		x2 <- gcd_rec(aaa,bbb)
		t2 <- lubridate::now()
		print(t2 - t1)
		# 0.365s

		all.equal(x1,x2)
		# TRUE

		#Both are much faster than below method:
		#[1] mapply(numbers.GCD, ...) 5.44s

		#500. Reduce calculation on multiple vectors
		t1 <- lubridate::now()
		y1 <- gcd(aaa,bbb,ccc)
		t2 <- lubridate::now()
		print(t2 - t1)
		# 0.531s
		# 0.022s of Python numpy.gcd
		# 0.139s of Python math.gcd

		head(aaa)
		head(bbb)
		head(ccc)
		head(y1)

		t1 <- lubridate::now()
		y2 <- gcd_rec(aaa,bbb,ccc)
		t2 <- lubridate::now()
		print(t2 - t1)
		# 0.559s

		all.equal(y1,y2)
		# TRUE
	}
}

#[Terminology]
if (FALSE){'
# Time Complexity: O(log b)
# Auxiliary Space: O(log b)
'}
