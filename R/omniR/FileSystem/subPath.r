#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to obtain a part, from either left or right at any depth, of the path defined in the input vector        #
#   |Quote: https://stackoverflow.com/questions/17315431/parent-directory-in-r                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[SCENARIO]                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] Obtain the drive from the provided path                                                                                        #
#   |[2] Obtain the grand parent folder of the provided path                                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |path        :   <character> vector to be recognized as paths on the computer                                                       #
#   |depth       :   <integer> vector at length 1 to indicate the depth by which to obtain the sub-paths, float is coerced as integer   #
#   |.coerce     :   <logical> vector at length 1 to indicate whether to ignore <depth> which is beyond the actual depth of any <path>  #
#   |                 [TRUE        ] <Default> Force return the most available depth of paths, e.g. return the left-most sub-path when  #
#   |                                           <path> has the depth of 3 and <depth> is provided 5 as <FUN> indicates <tail>           #
#   |                 [FALSE       ]           Return <NA> given <depth> is beyond the actual depth of <path>                           #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<str>       :   The extracted sub-paths in the same length as <path>                                                               #
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
#   |   |magrittr, fs                                                                                                                   #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	magrittr, fs
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

#We should use the pipe operands supported by below package
library(magrittr)

subPath <- function(
	path
	,depth
	,.coerce = TRUE
	,FUN = head
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#012. Parameter buffer
	depth <- as.integer(depth)

	#015. Function local variables
	re_netsign <- '\\\\\\\\'

	#100. Helper functions
	#110. Function to extract parts from a single path
	h_trans <- function(x, v_depth = depth){
		#100. Skip if the value cannot be processed
		if (all(is.na(x))) return(NA)

		#500. Determine the depth to extract from the path
		#510. Obtain the full depth
		len_depth <- length(x)

		#530. Only convert once for the negative slicer as there is no reason for recursive slicing on paths
		if (v_depth < 0) v_depth <- len_depth + v_depth

		#550. Skip if it is not requested to coerce the output
		if (!.coerce) {
			if ((v_depth < 1) | (v_depth > len_depth)) return(NA)
		}

		#590. Restrict the output as within the actual depth of the path
		out_depth <- v_depth %>% max(1) %>% min(len_depth)

		#900. Form the output path by the identified depth
		return( do.call(file.path, as.list(FUN(x, out_depth))) )
	}

	#500. Extraction
	paths <- fs::path_split(path) %>%
		sapply(h_trans) %>%
		{gsub(paste0('^', .Platform$file.sep, '{2}'), re_netsign, ., perl = T)}

	#999. Output
	return(paths)
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

		#200. Retrieve the root path to the depth of -3
		locs_roots <- subPath(locs, -3, FUN = head)

		#210. Retrieve the root path to the depth of -3, while return <NA> for those with depth less than 3
		locs_roots2 <- subPath(locs, -3, FUN = head, .coerce = F)

		#300. Retrieve the relative path to the depth of -1
		locs_rel <- subPath(locs, -1, FUN = tail)

		#310. Retrieve the relative path to the depth of 3, while return <NA> for those with depth less than 3
		locs_rel2 <- subPath(locs, 3, FUN = tail, .coerce = F)
	}
}
