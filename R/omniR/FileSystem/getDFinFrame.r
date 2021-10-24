#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to search for the available data.frames within the required environment/frame                            #
#   |IMPORTANT: If two frames are at the same level, it is literally NOT available to access the internal elements from one another;    #
#   |            the same situation happens when user needs to access the internal elements within its subordinate environments.        #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |nframe     :   The identity of frame(s) within which to retrieve the available names of data.frames                                #
#   |                [NULL]<Default> Retrieve names of data.frames from all parent frames to the one of this function                   #
#   |                [(int)] Retrieve names of data.frame in the provided frame, which MUST be less than the one of this function       #
#   |                IMPORTANT: Negative integers indicate a backward search of frames, which will plus [-1] during function execution. #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[out_rst]  :   A list that stores the names of the available data.frames as found in each dedicated frame                          #
#   |                [names(out_rst)] 'Frame_<k>' represents the <k>th frame                                                            #
#   |                [(values)]       Vectors of names of the data.frames                                                               #
#   |                IMPORTANT: It is improper to return a table, otherwise the result is unpredictable in a recursive search.          #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20200304        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |base                                                                                                                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

getDFinFrame <- function(nframe=NULL,dfclass=NULL,fDebug=FALSE){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	if (is.null(dfclass)){
		dfclass <- c(
			'data.frame' , 'tbl_df' , 'tbl'
			, 'groupedData' , 'nfnGroupedData' , 'nfGroupedData' , 'nmGroupedData' , 'nffGroupedData'
			, 'table' , 'tbl_cube' , 'spec_tbl_df'
		)
	}
	if (is.null(nframe)) gframe <- rev(sys.parents())
	else {
		if (nframe < 0) gframe <- nframe - 1
		else gframe <- nframe
	}
	if (max(gframe) >= sys.nframe()) stop('[',LfuncName,']Invalid nframe:[',nframe,']!')
	out_rst <- list()

	#600. Loop searching
	for (i in gframe){
		#900. Extend the result
		my.env <- sys.frame(i)
		out_rst[[paste0('Frame_',i)]] <- Filter(
			function(m) any(sapply(dfclass, function(x){ is(get(m , envir = my.env) , x) } )) ,
			ls(envir = my.env)
		)
		rm(my.env)
	}

	#999. Return the list
	return(out_rst)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Prepare a data.frame for later search
		usrdf3 <- data.frame(
			a = 1,
			b = c(2,3)
		)

		#100. Identify data.frames in the global environment
		dfs_global <- getDFinFrame(0)
		View(dfs_global)

		#200. Get data.frames from within a function (i.e. a higher level frame)
		df_in_func <- function(){
			usrdf6 <- data.frame(
				a = 5,
				b = c(6,7,8)
			)
			print(sys.parents())
			print(getDFinFrame(sys.nframe()))
			invisible(NULL)
		}
		df_in_func()

		#300. Get all data.frames in current session from within a function
		df_in_all <- function(){
			usrdf7 <- data.frame(
				a = 5,
				b = c(6,7,8)
			)
			df_in_inner <- function(){
				usrdf8 <- data.frame(
					a = 9,
					b = c(6,3,1)
				)
				usrlst <- list()
				usrlst$usrdf9 <- data.frame(
					a = 9,
					b = c(6,3,1)
				)
				dplyr::glimpse( get( 'usrlst' , envir = sys.nframe() )$usrdf9 )
				print(getDFinFrame())
				invisible(NULL)
			}
			df_in_inner()
			invisible(NULL)
		}
		df_in_all()
	}
}
