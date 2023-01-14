#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to calculate the Correlation Coefficient Matrix for each column in the matrix to all other columns       #
#   |This function calculates much faster than the internal function [cor()]                                                            #
#   |Quote: https://blog.csdn.net/lph188/article/details/84501481                                                                       #
#   |Formula of [pearson correlation coefficient] is as below:                                                                          #
#   |COR(X,Y) = COV(X,Y) / ( STD(X) * STD(Y) )                                                                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |x,y        :   The input matrices for which the calculation is to be taken upon the columns                                        #
#   |dim        :   On which dimension is the calculation requested                                                                     #
#   |               [row] Calculate the distance between each row in [x] to that in [y]                                                 #
#   |               [col] Calculate the distance between each column in [x] to that in [y]                                              #
#   |               [Default] [col] (covariance is usually calculated for models that are based upon dimensions)                        #
#   |method     :   Use which method to calculate the covariance. See the official document of R for [cov()]                            #
#   |               [pearson]<Default> Currently this function only supports this method                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[matrix]   :   The [K*M] matrix, where [K] is equal to the number of columns of [x], while [M] is the number of columns of [y]     #
#   |               Each [k,m] represents the Correlation Coefficient of [k]th column in [x] to [m]th column in [y]                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20200522        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Introduce the [eigenMapMatMult] method from [MatrixMultiplication.cpp] C++ function to replace [crossprod] and [tcrossprod] #
#   |      | functions from R base; which dramatically increase the efficiency by almost 20 times!                                      #
#   |      |Quote: https://stackoverflow.com/questions/35923787/fast-large-matrix-multiplication-in-r                                   #
#   |      |Note:                                                                                                                       #
#   |      | [1] You have to install the package [Rcpp] to enable dynamic compilation of [CPP] code                                     #
#   |      | [2] You also have to [Rcpp::sourceCpp] the dependent [CPP] code to introduce the C++ functions to R                        #
#   |      | [3] Use [Rfast::transpose] to transpose the corresponding matrix before multiplication in order to get the same result as  #
#   |      |      [crossprod] or [tcrossprod] respectively                                                                              #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230114        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Introduce a function [match.arg.x] to enable matching args after mutation, e.g. case-insensitive match                  #
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
#   |   |Rfast, Rcpp                                                                                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$Stats                                                                                                                    #
#   |   |   |cov_matrix                                                                                                                 #
#   |   |   |eigenMapMatMult       (See function definition in [MatrixMultiplication.cpp])                                              #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvOp                                                                                                                    #
#   |   |   |match.arg.x                                                                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	Rfast, Rcpp
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

cor_matrix <- function(x,y=NULL,dim = c('col','row'),method = c('pearson')){
	#010. Local parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	if (is.null(y)) y <- x
	y_pseudo <- identical(x, y)
	dim <- match.arg.x(dim, arg.func = tolower)
	method <- match.arg.x(method, arg.func = tolower)

	#100. Transpose the matrices to facilitate a stable algorithm
	#It is preferred to handle transposition outside this function while always using [col] for calculation
	if (dim == 'row') {
		x <- Rfast::transpose(x)
		if (y_pseudo) {
			y <- x
		} else {
			y <- Rfast::transpose(y)
		}
	}
	if (nrow(x) != nrow(y)) stop('[',LfuncName,'][x] has different length of the other dimension to [y] when [dim==[',dim,']]!')

	#200. Clean the data
	#It is preferred to handle NAs outside this function
	#[Quote: https://stackoverflow.com/questions/8161836/how-do-i-replace-na-values-with-zeros-in-an-r-dataframe ]
	# x[is.na(x)] <- 0
	# y[is.na(y)] <- 0

	#500. Calculation
	#510. Calculate the standard deviation for x and y
	vars_x <- sqrt( matrix( Rfast::colVars( x , na.rm = T ) , nrow = ncol(x) ) )
	#Note that we transpose [vars_y] here
	if (y_pseudo) {
		vars_y <- Rfast::transpose(vars_x)
	} else {
		vars_y <- sqrt( matrix( Rfast::colVars( y , na.rm = T ) , ncol = ncol(y) ) )
	}

	#590. Calculate the covariance for columns in pairs
	return( cov_matrix( x , y , dim = 'col' ) / eigenMapMatMult( vars_x , vars_y ) )
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		tmcn::setchs(rev=F)
		omniR <- 'D:\\R\\omniR'
		#Below may take quite a time, almost 20s
		Rcpp::sourceCpp(normalizePath(file.path(omniR, 'Stats', 'MatrixMultiplication.cpp')))

		x <- Rfast::matrnorm(100000, 1000)
		y <- Rfast::matrnorm(100000, 1000)

		#[AMD FX-6300 6Core 3.5G]

		#Test speed against the official R function [cor()], 16 times faster!
		start_time <- Sys.time()
		cor_xy1 <- cor_matrix(x,y)
		end_time <- Sys.time()
		end_time - start_time
		#[RAM 3GB]
		#[CPU 100%] 10.59s

		start_time <- Sys.time()
		cor_xy2 <- cor(x,y)
		end_time <- Sys.time()
		end_time - start_time
		#No extra RAM required
		#[CPU 20%] 170s (2.82m)

		all.equal(cor_xy1,cor_xy2)

		#Test speed against the [Rfast] function [cora()], 7.5 times faster!
		start_time <- Sys.time()
		cor_x1 <- cor_matrix(x)
		end_time <- Sys.time()
		end_time - start_time
		#[RAM 3GB]
		#[CPU 100%] 9.91s

		start_time <- Sys.time()
		cor_x2 <- Rfast::cora(x)
		end_time <- Sys.time()
		end_time - start_time
		#[RAM 3GB]
		#[CPU 20%] 75s (1.28m)

		all.equal(cor_x1,cor_x2)

	}
}
