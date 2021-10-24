#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to calculate the Euclidean Distance between each [ROW/COLUMN] of the provided matrix [x] and those of    #
#   | the provided matrix [y]                                                                                                           #
#   |[Special case] When y=x, it calculates the distance between each other [ROW/COLUMN] inside [x]                                     #
#   |[Quote: https://blog.csdn.net/qq_33254870/article/details/82933317 ]                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Concept:                                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[510] 将两个矩阵按[行]做[点积]，当dim(x)=[N,K]且dim(y)=[M,K]时，x%*%t(y)的形状为[N,M]                                              #
#   |[520] 将两个矩阵各自按[行]做[平方和]                                                                                               #
#   |[530] [x]的行平方和扩展成[M]列的矩阵(每列相同)，同时将[y]的行平方和扩展成[N]行的矩阵(每行相同)                                     #
#   |[590] 按照公式：sqrt(sum of (x-y)**2) = x**2 + y**2 -2*x*y 计算各行距离的平方                                                      #
#   |[900] 开方得到距离                                                                                                                 #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |x,y        :   Matrices for calculation                                                                                            #
#   |dim        :   On which dimension is the calculation requested                                                                     #
#   |               [row] Calculate the distance between each row in [x] to that in [y]                                                 #
#   |               [col] Calculate the distance between each column in [x] to that in [y]                                              #
#   |               [Default] [row] (distance is usually calculated for models that are based upon observations instead of dimensions)  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |800.   Naming Convention.                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |tdot       :   Transposed Dot Product                                                                                              #
#   |ss         :   Sum of Squares                                                                                                      #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[matrix]   :   The [N*M] matrix, where [N] is equal to number of rows in [x], [M] is equal to number of rows in [y]                #
#   |               [i,j] means the distance of [i]th row in [x] to [j]th row in [y]                                                    #
#   |                      (That's also why the columns of [x] and [y] should match)                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20191203        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200508        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Correct the expression: [tcrossprod(rep(1, length(ss_y)), ss_x)] with: [tcrossprod(rep(1, length(ss_x)), ss_y)]             #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200523        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
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
#---------------------------------------------------------------------------------------------------------------------------------------#
#400.   User Manual.                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |See the [Full Test Program] section                                                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Due to the feature of matrix calculation, [x] and [y] MUST have the same number of [COLUMN]s when the calculation is requestd upon #
#   | [ROW]s, and vice versa.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent packages                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |Rfast, Rcpp                                                                                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |Directory: [omniR$Stats ]                                                                                                      #
#   |   |   |eigenMapMatMult       (See function definition in [MatrixMultiplication.cpp])                                              #
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

dist_matrix_euclid <- function(x,y = NULL,dim = c('row','col')){
	#100. Local parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	if (is.null(y)) y <- x
	y_pseudo <- identical(x, y)
	dim <- match.arg(dim, c('row','col'))

	#200. Transpose the matrices to facilitate a stable algorithm
	#It is preferred to handle transposition outside this function while always using [row] for calculation
	if (dim == 'col') {
		x <- Rfast::transpose(x)
		if (y_pseudo) {
			y <- x
		} else {
			y <- Rfast::transpose(y)
		}
	}
	if (ncol(x) != ncol(y)) stop('[',LfuncName,'][x] has different length of the other dimension to [y] when [dim==[',dim,']]!')

	#500. Calculation
	#Below essay elaborates the method in R
	#[Quote: https://www.douban.com/note/146075804/ ]

	#510. Calculate the dot product for each respective row in the matrix [x] to the rows in [y]
	tdot_xy <- eigenMapMatMult( x, Rfast::transpose(y) )

	#520. Retrieve the sum of squares of each row in [x] and [y] respectively, and broadcast them to [nrow(x),nrow(y)]
	ss_x <- Rfast::rep_col( Rfast::rowsums( x ^ 2 ) , nrow(y) )
	#Note that we transpose [ss_y] here
	if (y_pseudo) {
		ss_y <- Rfast::transpose(ss_x)
	} else {
		ss_y <- Rfast::rep_row( Rfast::rowsums( y ^ 2 ) , nrow(x) )
	}

	#550. Set the distance between any row to itself as 0
	dist_sq <- ss_x + ss_y - tdot_xy * 2
	if (y_pseudo) diag(dist_sq) <- 0

	#900. Return the distance
	#[Quote: sqrt(sum of (x-y)**2) = x**2 + y**2 -2*x*y ]
	return( sqrt( dist_sq ) )
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		tmcn::setchs(rev=F)
		omniR <- 'D:\\R\\omniR'
		#Below may take quite a time, almost 20s
		Rcpp::sourceCpp(normalizePath(file.path(omniR, 'Stats', 'MatrixMultiplication.cpp')))

		x <- Rfast::matrnorm(2000, 1000)
		y <- Rfast::matrnorm(3000, 1000)

		#[AMD FX-6300 6Core 3.5G]

		#Test speed against the official R function [dist()], 30 times faster!
		start_time <- Sys.time()
		dist_x1 <- dist_matrix_euclid(x)
		end_time <- Sys.time()
		end_time - start_time
		#[RAM undetected]
		#[CPU 100%] 0.99s

		start_time <- Sys.time()
		dist_x2 <- as.matrix(dist(x))
		end_time <- Sys.time()
		end_time - start_time
		#No extra RAM required
		#[CPU 20%] 31.12s

		all(round(dist_x1,4)==round(dist_x2,4))

		#Test speed against the [Rfast] function [dista()], 45 times faster!
		start_time <- Sys.time()
		dist_xy1 <- dist_matrix_euclid(x,y)
		end_time <- Sys.time()
		end_time - start_time
		#[RAM undetected]
		#[CPU 100%] 0.99s

		start_time <- Sys.time()
		dist_xy2 <- Rfast::dista(x,y)
		end_time <- Sys.time()
		end_time - start_time
		#[RAM 2GB]
		#[CPU 20%] 44.06s

		all(round(dist_xy1,4)==round(dist_xy2,4))
		all.equal(dist_xy1,dist_xy2)

	}
}
