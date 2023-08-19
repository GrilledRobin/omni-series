#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to calculate the extended Greatest Common Divisor (GCD), a.k.a. Highest Common Factor (HCF) of two       #
#   | integers using Euclidean Algorithm, together with integers <x> and <y> such that: ax + by = gcd(a,b)                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] https://www.geeksforgeeks.org/euclidean-algorithms-basic-and-extended/                                                         #
#   |[2] https://www.rookieslab.com/posts/extended-euclid-algorithm-to-find-gcd-bezouts-coefficients-python-cpp-code                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |x,y         :   The input integer vectors in the same length                                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[matrix]    :   n * (Element-wise GCD of the inputs, x, y)                                                                         #
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

gcdExtInteger <- function(x,y){
	#010. Local parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#050. Initialization
	s <- rlang::rep_along(x, 0); old_s <- rlang::rep_along(x, 1)
	t <- rlang::rep_along(x, 1); old_t <- rlang::rep_along(x, 0)
	r <- y; old_r <- x
	rstOut_r <- x
	rstOut_s <- old_s
	rstOut_t <- old_t

	#500. Apply the algorithm
	while (any(r != 0)) {
		r_nonzero <- r != 0
		quotient <- ifelse(r_nonzero, old_r %/% r, r)

		temp <- r
		r <- ifelse(r_nonzero, old_r - quotient * r, r)
		old_r <- temp

		temp <- s
		s <- ifelse(r_nonzero, old_s - quotient * s, s)
		old_s <- temp

		temp <- t
		t <- ifelse(r_nonzero, old_t - quotient * t, t)
		old_t <- temp

		rstOut_r[old_r != 0] <- old_r[old_r != 0]
		rstOut_s[old_r != 0] <- old_s[old_r != 0]
		rstOut_t[old_r != 0] <- old_t[old_r != 0]
	}

	#900. Output
	rstOut <- matrix(c(rstOut_r, rstOut_s, rstOut_t), ncol = 3)
	colnames(rstOut) <- c('gcd','x','y')
	rownames(rstOut) <- rownames(x)
	return(rstOut)
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
		x1 <- gcdExtInteger(aaa,bbb)
		t2 <- lubridate::now()
		print(t2 - t1)
		# 1.195s
		# 0.681s of omniPy.Stats.gcdExtInteger
		# message('r: ', r, '\n', 's: ', s, '\n', 't: ', t, '\n', 'old_r: ', old_r, '\n', 'old_s: ', old_s, '\n', 'old_t: ', old_t)

		head(aaa)
		head(bbb)
		head(x1)

		all.equal(x1[,'gcd'],aaa * x1[,'x'] + bbb * x1[,'y'])
		# TRUE
	}
}

#[Terminology]
if (FALSE){'
# Time Complexity: O(log N)
# Auxiliary Space: O(log N)
'}
