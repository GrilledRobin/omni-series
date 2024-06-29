#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to retrieve the special folders called [User Shell Folders] on Windows OS                                #
#   |[Supported values] (when providing below values as [str])                                                                          #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |AllUsersDesktop, AllUsersStartMenu, AllUsersPrograms, AllUsersStartup, Desktop, Favorites, Fonts, MyDocuments, NetHood, PrintHood, #
#   | Recent, SendTo, StartMenu, Startup & Templates                                                                                    #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[REFERENCE]                                                                                                                        #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[Way to find them]: https://stackoverflow.com/questions/2063508/find-system-folder-locations-in-python                             #
#   |[Names to find   ]: https://ss64.com/vb/special.html                                                                               #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |...         :   Any positional/named arguments that represent [special folder names] for search in Windows COM                     #
#   |inplace     :   Whether to keep the output the same as the input values if any cannot be found as [special folder names]           #
#   |                 [TRUE        ] <Default> Keep the input values as output if they cannot be found                                  #
#   |                 [FALSE       ]           Output [NA] for those which cannot be found                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<Various>   :   This function output different values in below convention:                                                         #
#   |                [1] If [...] is not provided, return an empty list                                                                 #
#   |                [2] If [...] is provided with at least one element, return a [list], with:                                         #
#   |                    [names ] [str('.arg' + pos. num)] for [positional arguments] and [keys] for named arguments                    #
#   |                    [values] absolute paths to the [names], or [NA] if not available                                               #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20240617        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |RDCOMClient, rlang                                                                                                             #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	RDCOMClient, rlang
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

library(RDCOMClient)

winUserShellFolders <- function(
	...
	,inplace = TRUE
){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]
	dots <- rlang::list2(...)
	if (!is.logical(inplace)) inplace <- TRUE

	#100. Redirect the internal log to a temporary file and suppress it from <stdout>
	#110. Read the current state of internal logging
	rdcom_f_log <- writeErrors(T)

	#150. Redirect the log
	writeErrors(F)

	#200. Helper functions
	#210. Function as the item getter
	#[ASSUMPTION]
	#[1] [SpecialFolders] returns a blank string when provided an invalid string, but raises an error when provided an invalid number.
	#[2] How to suppress the messages from an accepted failure (seems no effect)
	#    https://stackoverflow.com/questions/52948819/rdcomclient-log-file
	get_COM <- function(v){
		objShell <- COMCreate('WScript.Shell')
		objShell$SpecialFolders(v)
	}

	#230. Function to catch the errors if any
	tryShell <- function(v){
		tryCatch(
			get_COM(v)
			,error = function(e){return('')}
		)
	}

	#270. Function to process each element among the input dots
	dotsHdl <- function(.vec){
		#300. Retrieve the absolute paths of the provided special names
		dict_found <- sapply(
			.vec
			,tryShell
			,simplify = T
			,USE.NAMES = T
		)

		#500. Unify the invalid results
		dict_found[nchar(dict_found) == 0] <- NA

		#700. Set the result in terms of [inplace]
		if (inplace) {
			mask_null <- is.na(dict_found)
			dict_found[mask_null] <- .vec[mask_null]
		}

		#999. Export
		return(dict_found)
	}

	#500. Conduct the query
	rstOut <- sapply(
		dots
		,dotsHdl
		,simplify = F
		,USE.NAMES = T
	)

	#900. Resume the internal logging
	writeErrors(rdcom_f_log)

	#999. Export
	return(rstOut)
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		library(magrittr)

		#100. Retrieve [My Documents] for current logged user
		MyDocs <- winUserShellFolders('MyDocuments')

		#300. Retrieve several special folders at the same time
		curr_folders <- winUserShellFolders('Desktop', 'StartMenu')

		#400. Provide an integer for retrieval
		startMenu <- winUserShellFolders(1)

		#500. Provide named arguments
		spfolders <- winUserShellFolders('Favorites', chkfonts = 'Fonts')

		#600. Test multiple vectors
		spfolders_multi <- winUserShellFolders(
			c('Programs','PrintHood')
			,chkScope = c('AllUsersPrograms','Programs')
			,withInvalidNames = c('Startup','Ringtones')
			,inplace = F
		)

		#800. Test when the folder names are stored in a table-like
		v_df <- data.frame(folders = c('MyDocuments' , 'Favorites'), stringsAsFactors = F)
		testdf1 <- v_df %>%
			dplyr::mutate(
				paths = winUserShellFolders(folders) %>% .subset2(1) %>% unname()
			)

		#900. Test invalid folders
		test_invld <- winUserShellFolders(100, 5)
		test_invld2 <- winUserShellFolders(100, chk = 5, inplace = F)

	}
}
