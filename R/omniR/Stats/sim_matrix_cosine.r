#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to calculate the Cosine Similarity for each column in the matrix to all other columns                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |x,y        :   The input matrices for which the calculation is to be taken upon the columns                                        #
#   |adj        :   Whether to adjust the input matrix by deducting the means of the respective columns before calculation              #
#   |                Check the blog for reason: https://blog.csdn.net/ifnoelse/article/details/7766123                                  #
#   |dim        :   On which dimension is the calculation requested                                                                     #
#   |               [row] Calculate the distance between each row in [x] to that in [y]                                                 #
#   |               [col] Calculate the distance between each column in [x] to that in [y]                                              #
#   |               [Default] [col] (similarity is usually calculated for models that are based upon dimensions)                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[matrix]   :   The [K*M] matrix, where [K] is equal to the number of columns of [x], while [M] is the number of columns of [y]     #
#   |               Each [k,m] represents the similarity of [k]th column in [x] to [m]th column in [y]                                  #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20191110        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200508        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Extend the calculation to two different matrices with the same number of rows but different number of columns, indicating   #
#   |      | the similarity of each column in matrix [x] to all columns in matrix [y] respectively.                                     #
#   |      |The original function with only one argument [x] becomes a special case to current version, where [x] == [y].               #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200517        | Version | 2.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Introduce the [rep_row] and [colsums] methods from [Rfast] package to increase the speed significantly                      #
#   |      |There is NOT an efficient replacement of [crossprod] in [Rfast] hence the overall speed is only increased a bit.            #
#   |      |A bug of [Rfast::mat.mult] is detected when it is applied to x[M*K] and y[K*N]. The result shows:                           #
#   |      | [1] Output a matrix as o[K*N], rather than o[M*N], when M>N; which means the rest piece of input data is lost              #
#   |      | [2] Memory error and cause RScript to collapse, when M<N                                                                   #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200518        | Version | 3.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Introduce the [eigenMapMatMult] method from [MatrixMultiplication.cpp] C++ function to replace [crossprod] and [tcrossprod] #
#   |      | functions from R base; which dramatically increase the efficiency by almost 10 times!                                      #
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
#---------------------------------------------------------------------------------------------------------------------------------------#
#500.   Dependent Facilities.                                                                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Dependent packages                                                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |Rfast, Rcpp                                                                                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |eigenMapMatMult       (See function definition in [MatrixMultiplication.cpp])                                                  #
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

sim_matrix_cosine <- function(x,y=NULL,adj=F,dim = c('col','row')){
	#010. Local parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	if (is.null(y)) y <- x
	y_pseudo <- identical(x, y)
	dim <- match.arg(dim, c('col','row'))

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

	#200. Make adjustment if required
	#[Quote: https://blog.csdn.net/ifnoelse/article/details/7766123 ]
	if (!is.null(adj)) {
		if (adj) {
			#100. Adjust [x]
			#Below column mean has one row and k columns
			# mean_x <- t(colMeans(x, na.rm = T))
			#For deduction of matrix, both matrices should have the same number of rows and columns
			#[Quote: https://r.789695.n4.nabble.com/repeat-matrix-rows-as-a-whole-td4588654.html ]
			# x <- x - mean_x[rep(1, nrow(x)),]
			mean_x <- colMeans(x, na.rm = T)
			x <- x - Rfast::rep_row( mean_x, nrow(x) )

			#500. Adjust [y]
			if (y_pseudo) {
				y <- x
			} else {
				# mean_y <- t(colMeans(y, na.rm = T))
				# y <- y - mean_y[rep(1,nrow(y)),]
				mean_y <- colMeans(y, na.rm = T)
				y <- y - Rfast::rep_row( mean_y, nrow(y) )
			}
		}
	}

	#200. Clean the data
	#It is preferred to handle NAs outside this function
	#[Quote: https://stackoverflow.com/questions/8161836/how-do-i-replace-na-values-with-zeros-in-an-r-dataframe ]
	# x[is.na(x)] <- 0
	# y[is.na(y)] <- 0

	#500. Calculation
	#Below essay is for column-by-column calculation of the similarity
	#[Quote: https://bgstieber.github.io/post/recommending-songs-using-cosine-similarity-in-r/ ]
	#Below essay extracts the methodology from [numpy] to calculate the matrix-wise similarity
	#[Quote: https://blog.csdn.net/u010412858/article/details/60467382 ]

	#510. Calculate the dot product for each respective column of the matrix to other columns
	#[Quote: t(x) %*% x]
	# if (y_pseudo) {
	# 	#This saves half of the time!
	# 	dot_xy <- crossprod(x)
	# } else {
	# 	dot_xy <- crossprod(x, y)
	# }
	#[Quote: [MatrixMultiplication.cpp]]
	dot_xy <- eigenMapMatMult( Rfast::transpose(x), y )

	#520. Retrieve the respective norms of all columns
	#Sum the squares of all rows within each column respectively, then obtain the respective square root
	# norm_x <- sqrt(apply(x, 2, crossprod))
	norm_x <- matrix( sqrt( Rfast::colsums( x ^ 2 ) ), ncol = 1 )
	if (y_pseudo) {
		norm_y <- norm_x
	} else {
		# norm_y <- sqrt(apply(y, 2, crossprod))
		norm_y <- matrix( sqrt( Rfast::colsums( y ^ 2 ) ), ncol = 1 )
	}

	#530. Calculate the cross products of the norms of all columns in pairs
	#[Quote: x %*% t(x)]
	# if (y_pseudo) {
	# 	#This saves half of the time!
	# 	crossprod_xy_norm <- tcrossprod(norm_x)
	# } else {
	# 	crossprod_xy_norm <- tcrossprod(norm_x, norm_y)
	# }
	crossprod_xy_norm <- eigenMapMatMult( norm_x, Rfast::transpose(norm_y) )

	#590. Calculate the cosine similarity for columns in pairs
	#When [x==y], the output matrix is symmetric while the diagonal is always 1, for every column is perfectly same to itself
	#[Quote: CosSim = ( X dot Y )/( ||X|| * ||Y|| ) ]
	return(dot_xy / crossprod_xy_norm)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		aa <- matrix(1:12,nrow = 3,ncol = 4)

		bb <- sim_matrix_cosine(aa,adj = T)

		aa_dot <- crossprod(aa)
		aa_norms <- sqrt(diag(aa_dot))
		aa_cross <- tcrossprod(aa_norms)
		sim <- aa_dot / aa_cross

	}

	#Real case test
	if (TRUE){
		lst_pkg <- c( 'tmcn' , 'dplyr' , 'tidyr' , 'readr'
		)

		suppressPackageStartupMessages(
			sapply(lst_pkg, function(x){library(x,character.only = TRUE)})
		)
		tmcn::setchs(rev=F)
		omniR <- 'D:\\R\\omniR'
		#We use [file.path] to create path names instead of using [paste], to set compatibility of different OS.
		#Below may take quite a time, almost 20s
		Rcpp::sourceCpp(normalizePath(file.path(omniR, 'Stats', 'MatrixMultiplication.cpp')))

		# read user play data and song data from the internet
		# play_data <- 'https://static.turi.com/datasets/millionsong/10000.txt' %>%
		play_data <- normalizePath(file.path(omniR,'SampleData','sim_10000.txt')) %>%
			readr::read_tsv(col_names = c('user', 'song_id', 'plays'))

		# song_data <- 'https://static.turi.com/datasets/millionsong/song_data.csv' %>%
		song_data <- normalizePath(file.path(omniR,'SampleData','sim_song_data.csv')) %>%
			readr::read_csv() %>%
			distinct(song_id, title, artist_name)
		# join user and song data together
		all_data <- play_data %>%
			group_by(user, song_id) %>%
			summarise(plays = sum(plays, na.rm = TRUE)) %>%
			inner_join(song_data)

		top_1k_songs <- all_data %>%
		    group_by(song_id, title, artist_name) %>%
		    summarise(sum_plays = sum(plays)) %>%
		    ungroup() %>%
		    top_n(1000, sum_plays) %>%
		    distinct(song_id)

		all_data_top_1k <- all_data %>%
			inner_join(top_1k_songs)

		top_1k_wide <- all_data_top_1k %>%
			ungroup() %>%
			distinct(user, song_id, plays) %>%
			tidyr::pivot_wider(names_from = song_id, values_from = plays, values_fill = list(plays = 0))

		ratings <- as.matrix(top_1k_wide[,-1])

		start_time <- Sys.time()
		ratings_sim <- sim_matrix_cosine(ratings)
		end_time <- Sys.time()
		end_time - start_time
		#For 70K rows with 1000 columns,
		# RAM used: 2.5GB
		# Time elapse: 58s
		# Time elapse after applying [eigenMapMatMult]: 5.7s

		#Check the result
		#[Item Based Collaborative Filtering] is accomplished now!
		# forgot_about_dre <- 'SOPJLFV12A6701C797'
		forgot_about_dre <- 'SOBOAFP12A8C131F36'

		#Retrieve the top 5 similar songs for each one of the songs
		#100. Ensure the self-similarity to be placed at last during the ranking
		item_sim_mod <- ratings_sim - diag( diag(ratings_sim) + max(ratings_sim) + 1 )

		#200. Rank the similarity matrix by row in descending order of similarity values
		item_sim_rnk <- Rfast::rowRanks(item_sim_mod, method = 'first', descending = T)

		#300. Flag those elements which rank lower than [topk_sim + 1], while set others as 0 for exclusion
		item_sim_flg <- (item_sim_rnk <= 5)

		#400. Create the final [Item] similarity matrix by adding all requested filtrations
		#Direct multiplication is element-wise in comparison to [crossprod]
		item_sim_fnl <- ratings_sim * item_sim_flg

		#500. Flag those elements to be extracted from the input dataset
		#[Quote: https://stackoverflow.com/questions/3192791/find-indices-of-non-zero-elements-in-matrix ]
		item_sim_iarr <- which(item_sim_fnl != 0 , arr.ind = T)

		#900. Create a data.frame to hold the top 5 similar songs to each song in the input data
		ratings_sim_top5 <- data.frame('song_id' = colnames(ratings)[item_sim_iarr[,'row']]) %>%
			dplyr::mutate(
				ItemName = colnames(ratings)[item_sim_iarr[,'col']]
				,ItemRank = item_sim_rnk[item_sim_iarr]
				,Similarity = item_sim_fnl[item_sim_iarr]
			)

		#Check whether it is the same as what we did for a solius solution
		ratings_sim_top5 %>% filter(song_id == forgot_about_dre)

	}
}
