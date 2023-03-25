#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to split the provided paths into <drives> and <relative paths> respectively, resembling the function     #
#   |<os.path.splitdrive> in Python                                                                                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[SCENARIO]                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Obtain the drive from the provided path                                                                                        #
#   |[2] Unlike Python<=3.9, splitDrive('\\\\NET DRIVE\\base') and splitDrive('\\\\NET DRIVE\\base\\') returns the same result as the   #
#   |     file separators are automatically handled                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |path        :   <character> vector to be recognized as paths on the computer                                                       #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<list>      :   List of <character> vectors with names of <drive> and <relative path> as the split result                          #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20230325        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |magrittr, purrr                                                                                                                #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$FileSystem                                                                                                               #
#   |   |   |subPath                                                                                                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	magrittr, purrr
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

#We should use the pipe operands supported by below package
library(magrittr)

splitDrive <- function(
	path
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#012. Parameter buffer

	#015. Function local variables
	re_netsign <- '\\\\\\\\'
	hasdrive <- grepl('^\\w+:', path)
	netdrive <- grepl(paste0('^', re_netsign), path)

	#100. Helper functions
	#110. Function to extract roots from paths
	rootPath <- purrr::partial(subPath, FUN = head)

	#130. Function to extract relative paths from paths
	relativePath <- purrr::partial(subPath, FUN = tail)

	#400. Identify the drives
	drives <- rootPath(path, depth = 1L, .coerce = T)

	#430. Force output <NA> for those without valid drive name
	drives[!hasdrive] <- NA

	#450. Resemble the behavior in Python, by setting the second layer of net drive as the root
	drives[netdrive] <- rootPath(path[netdrive], depth = 2L, .coerce = T)

	#700. Identify the relative paths
	#710. Ensure the paths without valid conversion method to be output as-is
	relpath <- path

	#730. Set the relative path for those with drive names
	relpath[hasdrive] <- relativePath(path[hasdrive], depth = -1L, .coerce = F)

	#750. Resemble the behavior in Python, by setting the second layer of net drive as the root
	relpath[netdrive] <- relativePath(path[netdrive], depth = -2L, .coerce = F)

	#770. Resemble the behavior in Python, append a file separator to the left of the result
	relpath %<>% sapply(function(x){
		if (is.na(x)) return(NA)
		return(file.path('', x))
	})

	#800. Form the final result
	rstOut <- mapply(
		function(d,r){c('drive' = d, 'relative path' = r)}
		,drives
		,relpath
		,SIMPLIFY = F
	)
	names(rstOut) <- path

	#999. Output
	return(rstOut)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#100. Define paths
		locs <- c(
			'D:\\Software\\cron'
			,'\\\\NAS01\\This is\\not a\\valid path\\name'
			,NA
			,'.'
			,'E:'
			,'\\\\NAS01\\This is base path'
		)

		#200. Split the provided paths
		locs_split <- splitDrive(locs)

		#210. Obtain the drives from above result
		locs_drive <- locs_split %>% sapply('[[', 1)

		#290. Form the paths corresponding to the original ones, that can still be recognized by R
		locs_combine <- locs_split %>%
			sapply(function(x){
				x_clean <- x[!is.na(x)]
				if (length(x_clean) == 0) return(NA)
				rstOut <- do.call(file.path, as.list(x_clean))
				return(rstOut)
			})
	}
}
