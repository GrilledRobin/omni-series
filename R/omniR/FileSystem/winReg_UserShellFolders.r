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
	reg_cmd <- system(paste0('REG QUERY "',reg_key,'"'), intern = T)

	#190. Clean the result from direct query
	reg_cln <- sapply(
		reg_cmd
		,function(x){
			if(!nchar(x)==0 & x != reg_key){
				tmp <- unlist(strsplit(x,'\\s{4}', perl = T))
				tmp <- tmp[nchar(tmp)!=0]
				return(tmp)
			}
		}
		,USE.NAMES = F
	)
	#[Quote: https://stackoverflow.com/questions/33004238/r-removing-null-elements-from-a-list ]
	reg_cln <- Filter(Negate(is.null), reg_cln)

	#500. Create a list as output
	#When we retrieve the un-masked values, we need to use [shell] instead of [system]
	#[Quote: https://stackoverflow.com/questions/33646816/r-system-functions-always-returns-error-127 ]
	out_lst <- lapply(
		reg_cln
		,function(x){
			vec <- list(
				reg_tp = x[[2]]
				,value_mask = x[[3]]
				#Below step is quite slow, about 3 seconds!
				,value = shell(paste('echo',x[[3]]), intern = T)
			)
		}
	)
	names(out_lst) <- sapply(reg_cln,function(x){x[[1]]})

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
