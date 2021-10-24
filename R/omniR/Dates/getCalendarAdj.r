#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to locate the Calendar Adjustment file for Calendar related functions                                    #
#   |[IMPORTANT] If the dedicated file is in the same path as this function, its absolute path is directly returned, regardless of      #
#   |             whether the same file is in any of the candidate folders                                                              #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[ NULL  ]   :   This function does not take argument                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[ str   ]   :   Absolute path of the file on the harddisk                                                                          #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210830        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |   |omniR$FileSystem                                                                                                               #
#   |   |   |thisfile                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#

getCalendarAdj <- function(){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#012. Handle the parameter buffer.
	file_prior <- thisfile()

	#100. Prepare the candidates
	#[IMPORTANT] The sequence of below lists determines below logics:
	#[1] Search order for the dedicated file
	#[2] Program efficiency on system I/O
	fname <- 'CalendarAdj.csv'
	lst_drives <- c('D:', 'C:')
	lst_parent <- c('Python', 'Robin', 'RobinLu', 'SAS')
	lst_fpath <- c('omnimacro', 'omniPy')
	lst_fcurr <- c('Dates')

	#300. Directly return if the dedicated file is in the same folder as this function
	if (length(file_prior) > 0) {
		rst_prior <- file.path(dirname(file_prior), fname)
		if (file.exists(rst_prior)) return(rst_prior)
	}

	#500. Get the full combinations of the candidate paths
	lst_cand <- expand.grid(lst_drives, lst_parent, lst_fpath, lst_fcurr, stringsAsFactors = F)
	lst_cand[['name']] <- fname

	#700. Identify the first one among the candidates that is a physical file
	# fpath <- eval(rlang::expr(file.path(!!!lst_cand)))
	fpath <- do.call(file.path, lst_cand)
	fRst <- file.exists(fpath)
	if (!any(fRst)) {
		stop('[',LfuncName,']File is not found in any among the candidate paths! Please update function definition!')
	}

	#900. Translate the values
	return(head(fpath[fRst], 1))
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#010. Load user defined functions
		source('D:\\R\\autoexec.r')

		#100. Print the identified path to the calendar adjustment file
		print(getCalendarAdj())
	}
}
