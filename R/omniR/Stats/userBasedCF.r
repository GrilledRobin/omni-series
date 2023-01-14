#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to make recommendation to each [row] in the provided data by item based similarity/distance for all      #
#   | respective columns, other than the [keyvar], upon others                                                                          #
#   |[Quote: http://www.salemmarafi.com/code/collaborative-filtering-r/ ]                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |Concept:                                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[100] 将除了[keyvar]之外的其他字段([Item])组成一个矩阵                                                                             #
#   |[200] 若未提供[相似度矩阵]，为上述矩阵中的[Item]两两计算[相似性]，默认为[余弦相似性]                                               #
#   |[310] 将[相似度矩阵]的对角线赋值，使其在整个矩阵中为最小，其作用为：在排名时，每个[Item]对自己的相似度排最后，从而排除在计算之外   #
#   |[320] 对[相似度矩阵]以“行”为单位排名，最大值排名为1（此时每个[Item]对自己的相似度被排为最低，所以不受影响）                        #
#   |[330] 对所有排名小于（也即高于）给定值的相似度标记为有效                                                                           #
#   |[340] 在上述有效标记的基础上，进一步筛选出相似度高于给定阈值的元素                                                                 #
#   |[390] 根据上述标记为“有效”的元素，得出用于计算的[相似度矩阵]                                                                       #
#   |[610] 对上述的新[相似度矩阵]按“行”加总，作为后续计算公式的“分母”                                                                   #
#   |[640] 用公式：[sumproduct(purchaseHistory, similarities)/sum(similarities)]对[User]的这个未做过[Activity]的[Item]计算分数          #
#   |[660] 将这些未做过[Activity]的[Item]s按上述的分数倒序排列，找出每个[User]排在前[topk_recom]的[Item]s，作为推荐结果输出             #
#   |[670] 标记出每个[User]排在前[topk_recom]的[Item]s                                                                                  #
#   |[680] 在上述有效标记的基础上，进一步筛选出分数高于给定阈值的元素                                                                   #
#   |[690] 根据上述标记为“有效”的元素，得出用于输出的[分数矩阵]                                                                         #
#   |[810] 按每个分数在[分数矩阵]中的绝对位置，标记出不为0的分数；方向为从上到下-从左到右（先行后列）；方便从中取出对应的分数           #
#   |[820] 按每个分数在[分数矩阵]中的“行”与“列”位置，标记出不为0的分数；方便在输入数据集中对位填充符合推荐条件的[Item]s                 #
#   |[890] 从输入数据集中取出符合推荐条件的[keyvar]，再补上推荐的[Item]s及它们的排名和分数；最后输出                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |dat        :   The input dataset for which the calculation is to be taken upon the columns                                         #
#   |                [IMPORTANT] All the variables, other than the [keyvar] should be [numeric], and [non-missing]                      #
#   |keyvar     :   The variable name(s) that denotes to the [User]                                                                     #
#   |method     :   The method to conduct the calculation, usually the similarity function or distance function                         #
#   |                Below methods are supported:                                                                                       #
#   |                [CosSim] Cosine Similarity between each respective columns and others                                              #
#   |matrix_sim :   The pre-calculated [N*N] matrix that denotes the similarities between all [Item]s                                   #
#   |                If it is not provided, the function will generate it out of the [dat] using the provided [method]                  #
#   |sim_gt     :   Only preserve the [Item]s whose similarities between each other are greater than this value                         #
#   |score_gt   :   Only preserve the scores in the output result which are greater than this value                                     #
#   |topk_sim   :   How many similar [Item]s to the [Item] tha the [User] has NOT acted upon                                            #
#   |topk_recom :   How many [Item]s to be recommended to each [User]                                                                   #
#   |op_activity:   The strategy of recommendation (or operation) upon the items on which the user has taken activity                   #
#   |                [all       ]<default>  Recommend all [item]s, regardless of those on which user has taken activity, e.g. purchased #
#   |                [inclusive ]           Only recommend the [item]s on which user has taken activity, e.g. purchased                 #
#   |                                        This is used to recommend the products among those the user has purchased.                 #
#   |                [exclusive ]           Only recommend the [item]s on which user has never taken activity, e.g. purchased           #
#   |                                        This is used to recommend the products among those the user never purchased.               #
#   |...        :   Any other parameters that are required by the method to be used. Please check the documents for those functions     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[df]       :   [data.frame] The dataset containing the recommendation for all users                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |[keyvar]   :   The variable(s) acting as [User] in the input data                                                              #
#   |   |ItemName   :   The name of the [Item] to be recommended to the [User] based on the request                                     #
#   |   |ItemRank   :   The rank of the [Item] for recommendation, the smaller the higher priority                                      #
#   |   |Score      :   The score of the [Item] for evaluation                                                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20191112        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200516        | Version | 1.10        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Add a parameter [op_activity] to differentiate the recommendation strategy on whether to recommend the items which the  #
#   |      | user has already taken [activity] upon, e.g. whether to recommend a product again if it has been purchased by the user.    #
#   |      |[2] Introduce the [rowRank] and [colRank] methods from [Rfast] package to increase the speed significantly                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20200518        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20230114        | Version | 2.10        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |dplyr, Rfast, Rcpp                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$Stats                                                                                                                    #
#   |   |   |sim_matrix_cosine                                                                                                          #
#   |   |-------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$AdvOp                                                                                                                    #
#   |   |   |match.arg.x                                                                                                                #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	dplyr, Rfast, Rcpp
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

userBasedCF <- function(dat,keyvar
	,method = 'CosSim',matrix_sim = NULL
	,sim_gt = NULL,score_gt = NULL
	,topk_sim = 10,topk_recom = 5
	,op_activity = c('all','inclusive','exclusive')
	,...){
	#001. Check parameters
	op_activity <- match.arg.x(op_activity, arg.func = tolower)
	prm_list <- list(...)
	map_func <- list(
		#Below functions are from [omniR$Stats]
		CosSim = sim_matrix_cosine
	)
	if (is.null(method)) method = 'CosSim'
	if (is.null(topk_sim)) topk_sim = 10
	if (is.null(topk_recom)) topk_recom = 5

	#100. Turn the input data into a matrix for calculation
	m_dat <- as.matrix(dat[-which(names(dat) %in% keyvar)])

	#200. Calculate the similarity/distance for columns/[Item]s
	if (is.null(matrix_sim)) {
		m_item_sim <- m_dat %>% map_func[[method]](...)
	} else {
		m_item_sim <- matrix_sim
	}

	#300. Retrieve the [topk_sim] similar [Item]s to each [Item]
	#310. Ensure the self-similarity to be placed at last during the ranking
	#The second [diag] creates a diagonal matrix for later subtraction only upon the diagonal values
	m_item_sim_mod <- m_item_sim - diag( diag(m_item_sim) + max(m_item_sim) + 1 )

	#320. Rank the similarity matrix by row in descending order of similarity values
	#We will soon use [tcrossprod] for matrix multiplication,
	# hence here we calculate upon rows in preparation of later transposition
	#[According to official document, [tcrossprod(x,y)] is slightly faster than the form: [x %*% t(y)]]
	#[Quote: https://stackoverflow.com/questions/22227828/rank-per-row-over-multiple-columns-in-r ]
	# m_item_sim_rnk <- t(apply(-m_item_sim_mod, 1, rank, ties.method = 'first'))
	#Below method saves 2/3 time elapse than the above one!
	#[Quote: https://rdrr.io/cran/Rfast/man/colRanks.html ]
	m_item_sim_rnk <- Rfast::rowRanks(m_item_sim_mod, method = 'first', descending = T)

	#330. Flag those elements which rank lower than [topk_sim + 1], while set others as 0 for exclusion
	m_item_sim_flg <- (m_item_sim_rnk <= topk_sim)

	#340. Flag those elements whose values are greater than the requested [sim_gt]
	if (!is.null(sim_gt)) m_item_sim_flg <- m_item_sim_flg * ( m_item_sim > sim_gt )

	#390. Create the final [Item] similarity matrix by adding all requested filtrations
	#Direct multiplication is element-wise in comparison to [crossprod]
	m_item_sim_fnl <- m_item_sim * m_item_sim_flg

	#600. Calculate the [User] based score with below formula:
	#[score = sumproduct( purchaseHistory , similarity ) / sum( similarity )]
	#where:
	#[purchaseHistory]: times of purchase upon the most similar products to that one the [User] did not purchase
	#[similarity]: the similarity of the most similar products to that one the [User] did not purchase
	#610. Prepare the denominator, i.e. the [similarity] matrix mentioned in above formula
	#611. Inverse every element of the row-sum of adjusted similarity matrix
	#This step acts as: [1 / sum( similarity )]
	# m_item_sim_inv <- 1 / rowSums(m_item_sim_fnl)
	#Below method saves 2/3 time elapse than the above one!
	m_item_sim_inv <- 1 / Rfast::rowsums(m_item_sim_fnl)

	#612. Reset the infinite values as 0 for those [Item]s without similar [Item]s to them
	m_item_sim_inv[is.infinite(m_item_sim_inv)] <- 0

	#615. Make the denominator a matrix instead of a single dimensional vector
	#[Quote: https://stackoverflow.com/questions/19590541/r-duplicate-a-matrix-several-times-and-then-bind-by-rows-together ]
	# m_item_sim_inv <- tcrossprod( rep(1,nrow(m_dat)) , m_item_sim_inv )
	#Below method saves 1/2 time elapse than the above one!
	m_item_sim_inv <- Rfast::rep_row( m_item_sim_inv , nrow(m_dat) )

	#640. Translate the formula into matrix multiplication
	#The second slowest step!
	# m_user_score <- tcrossprod( m_dat , m_item_sim_fnl ) * m_item_sim_inv
	#[Quote: [MatrixMultiplication.cpp]]
	m_user_score <- eigenMapMatMult(m_dat,Rfast::transpose(m_item_sim_fnl)) * m_item_sim_inv

	#650. Apply the recommendation strategy
	if (op_activity == 'inclusive') {
		m_user_score <- m_user_score * ( m_dat != 0 )
	} else if (op_activity == 'exclusive') {
		m_user_score <- m_user_score * ( m_dat == 0 )
	}

	#660. Rank the scores of [Item]s per [User] in descending order
	#The slowest step!
	# m_user_score_rnk <- t(apply(-m_user_score, 1, rank, ties.method = 'min'))
	#Below method saves 5/6 time elapse than the above one!
	m_user_score_rnk <- Rfast::rowRanks(m_user_score, method = 'min', descending = T)

	#670. Flag those scores which rank lower than [topk_recom + 1], while set others as 0 for exclusion
	m_user_score_flg <- (m_user_score_rnk <= topk_recom)

	#680. Flag those scores whose values are greater than the requested [score_gt]
	if (!is.null(score_gt)) m_user_score_flg <- m_user_score_flg * ( m_user_score > score_gt )

	#690. Finalize the scores by adding all requested filtrations
	m_user_score_fnl <- m_user_score * m_user_score_flg

	#800. Extract the valid recommendation result by removing those with final scores equal to 0
	#810. Flag those elements to be extracted from the score matrix and ranking matrix
	# m_user_score_i <- which(m_user_score_fnl != 0 , arr.ind = F)

	#820. Flag those elements to be extracted from the input dataset
	#[Quote: https://stackoverflow.com/questions/3192791/find-indices-of-non-zero-elements-in-matrix ]
	m_user_score_iarr <- which(m_user_score_fnl != 0 , arr.ind = T)

	#890. Form a data frame out of the matrices by indexing, which is faster than data.frame operations
	df_user_score <- dat[m_user_score_iarr[,'row'],keyvar] %>%
		dplyr::mutate(ItemName = colnames(m_dat)[m_user_score_iarr[,'col']]) %>%
		dplyr::mutate(ItemRank = m_user_score_rnk[m_user_score_iarr]) %>%
		dplyr::mutate(Score = m_user_score_fnl[m_user_score_iarr])

	#999. Output
	return(df_user_score)
}

#[Full Test Program;]
if (FALSE){
	#Real case test
	if (TRUE){
		lst_pkg <- c( 'tmcn' , 'dplyr' , 'readr'
			, 'Rcpp'
		)

		suppressPackageStartupMessages(
			sapply(lst_pkg, function(x){library(x,character.only = TRUE)})
		)
		tmcn::setchs(rev=F)
		dir_omniR <- 'D:\\R\\omniR'
		omniR <- list.files( dir_omniR , '^.+\\.r$' , full.names = TRUE , ignore.case = TRUE , recursive = TRUE , include.dirs = TRUE ) %>%
			normalizePath()
		if (length(omniR)>0){
			o_enc <- sapply(omniR, function(x){guess_encoding(x)$encoding[1]})
			for (i in 1:length(omniR)){source(omniR[i],encoding = o_enc[i])}
		}
		#Below may take quite a time, almost 20s
		suppressMessages(Rcpp::sourceCpp(normalizePath(file.path(dir_omniR, 'Stats', 'MatrixMultiplication.cpp'))))

		# read user play data and song data from the internet
		# play_data <- 'https://static.turi.com/datasets/millionsong/10000.txt' %>%
		play_data <- normalizePath(file.path(dir_omniR,'SampleData','sim_10000.txt')) %>%
			readr::read_tsv(col_names = c('user', 'song_id', 'plays'))

		# song_data <- 'https://static.turi.com/datasets/millionsong/song_data.csv' %>%
		song_data <- normalizePath(file.path(dir_omniR,'SampleData','sim_song_data.csv')) %>%
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

		start_time <- Sys.time()
		recomm <- userBasedCF(top_1k_wide,'user',method = 'CosSim',topk_sim = 10,topk_recom = 5)
		end_time <- Sys.time()
		message(end_time - start_time)
		# pryr::object_size(get('top_1k_wide'),units = 'Mb')
		#For 70K rows with 1000 columns, 567MB RAM usage of [top_1k_wide]
		# RAM used: 7GB
		# Time elapse: 3m20s
		# Time elapse after applying [Rfast]: 2m40s
		# Time elapse after applying [eigenMapMatMult]: 18.3s

		#Below test has almost the same result as above
		#This proves that the split of input dataset has no effect on the overall efficiency
		#However, this provides a workaround to use distributed tasking to improve the process for large data
		if (FALSE) {
			keyvar <- 'user'
			dats <- split(top_1k_wide, sample(rep(1:20, nrow(top_1k_wide)%/%20+1))[1:nrow(top_1k_wide)])

			start_time <- Sys.time()
			m_sim <- top_1k_wide %>%
				dplyr::select_at(vars(-matches(paste0('^',paste0(keyvar,collapse = '|'),'$')))) %>%
				as.matrix() %>%
				sim_matrix_cosine()
			end_time <- Sys.time()
			message(end_time - start_time)

			rec <- list()
			start_time_t <- Sys.time()
			for (i in 1:length(dats)) {
				start_time <- Sys.time()
				rec[[i]] <- userBasedCF(
					dats[[i]],
					keyvar,
					matrix_sim = m_sim,
					method = 'CosSim',
					topk_sim = 10,
					topk_recom = 5
				)
				end_time <- Sys.time()
				message(end_time - start_time)
			}
			recomm2 <- bind_rows(rec)
			end_time_t <- Sys.time()
			message(end_time_t - start_time_t)
		}

		#Check the result
		test_usr <- 'c012ec364329bb08cbe3e62fe76db31f8c5d8ec3'

		#Check whether it is the same as what we did for a solius solution
		recomm_usr <- recomm %>% filter(user == test_usr)
		View(recomm_usr)

	}
}
