#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to retrieve all values under the key [User Shell Folders] from the Windows(R) registry                   #
#   |[Quote: https://blog.csdn.net/yq_forever/article/details/89638012 ]                                                                #
#   |Usage:                                                                                                                             #
#   |It is often used to retrieve the special folder [My Documents] on Windows OS, which is set as default working directory of RStudio #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |( none )   :   This function does not take any input parameter                                                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[out_lst]  :   A list that stores entries queried from Windows Registry; elements of each entry (as a list, too) is set as below   #
#   |                [$name       ]   The name of the entry (e.g. [Personal] ==> [My Documents])                                        #
#   |                [$reg_tp     ]   The type of the entry in Windows Registry                                                         #
#   |                [$value_mask ]   The masked value (by DOS variable) of the entry in Windows Registry                               #
#   |                [$value      ]   The value of the entry                                                                            #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210113        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |Version 1.                                                                                                                  #
#   |______|____________________________________________________________________________________________________________________________#
#   |___________________________________________________________________________________________________________________________________#
#   | Date |    20221016        | Version | 2.00        | Updater/Creator | Lu Robin Bin                                                #
#   |______|____________________|_________|_____________|_________________|_____________________________________________________________#
#   | Log  |[1] Replace [shell] with [Sys.getenv] to increase the query speed                                                           #
#   |      |[2] Introduce package [stringi] to replace the references of Windows Environment Variables with their respective values     #
#   |      |[3] Introduce a function [winReg_getInfByStrPattern] to query the Windows Registry                                          #
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
#   |   |magrittr, stringi                                                                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$FileSystem                                                                                                               #
#   |   |   |winReg_getInfByStrPattern                                                                                                  #
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	magrittr, stringi
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

library(magrittr)

winReg_UserShellFolders <- function(){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#100. Retrieve the requested entries of Windows Registry
	#110. Define the key for query
	reg_key <- 'HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders'

	#150. Query the key from Windows Registry and return a list
	reg_cln <- winReg_getInfByStrPattern(reg_key, inRegExp = '.*')

	#500. Create a list as output
	out_lst <- lapply(
		reg_cln
		,function(x){
			x_val <- x[['value']]
			# x_val <- reg_cln[[20]][['value']]
			#100. Parse the references of Windows Environment Variables
			#[ASSUMPTION]
			#[1] There is only one value to be processed at a time, hence [pos_ev] only needs one item
			pos_ev <- stringi::stri_locate_all_regex(x_val, '%[[:alpha:]].*?%')[[1]]
			val_ev <- stringi::stri_extract_all_regex(x_val, '%[[:alpha:]].*?%') %>%
				sapply(
					function(y){
						Sys.getenv(substr(y, 2, nchar(y) - 1))
					}
					,simplify = F
				)

			#500. Replace the references of Windows Environment Variables with their respective values
			val <- do.call(
				stringi::stri_sub_replace_all
				,list(
					x_val
					,pos_ev[,'start']
					,pos_ev[,'end']
					,replacement = val_ev
				)
			)

			#900. Construct result
			return(list(
				reg_tp = x[['type']]
				,value = val
			))
		}
	)
	names(out_lst) <- sapply(reg_cln, '[[', 'name')

	#999. Return the list
	return(out_lst)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		usrShellDir <- winReg_UserShellFolders()

		#Retrieve the location of [My Documents]
		usrShellDir$Personal$value

	}
}
