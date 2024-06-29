#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to query the value of [val_name] within the [key] of Windows Registry.                                   #
#   |It is useful to search for the installation path of any specific software on current Windows OS                                    #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |key         :   Full valid path for Windows Registry within which to query the value                                               #
#   |val_name    :   Name of the sub-key within current [key], for which to query the value                                             #
#   |                 [<missing>   ] <Default> Retrieve the [Default Value] of current [key], as indicated [(Default)] in Registry      #
#   |                 [<str>       ]           Provide a sub-key for query                                                              #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<str>       :   Character vector as query result                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20220213        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |300.   Dependent user-defined functions                                                                                            #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

winReg_QueryValue <- function(key, val_name){
	#001. Handle parameters
	#[Quote: https://stackoverflow.com/questions/15595478/how-to-get-the-name-of-the-calling-function-inside-the-called-routine ]
	LfuncName <- deparse(sys.call()[[1]])
	#If above statement cannot find the name correctly, this function must have been called via [do.call] or else,
	# hence we need to traverse one layer above current one and extract the first argument of that call.
	if (grepl('^function.+$',LfuncName[[1]],perl = T)) LfuncName <- gsub('^.+?\\((.+?),.+$','\\1',deparse(sys.call(-1)),perl = T)[[1]]

	#012. Parameter buffer
	if (missing(key)) return(NULL)
	if (length(key) == 0) return(character(0))
	if (missing(val_name)) val_name <- NA

	#200. Define helper functions
	#210. Function to process each element of the input vectors
	proc_query <- function(key, name){
		#100. Define the switch for the Windows Command [REG QUERY]
		if (length(name) == 0) name <- NA
		if (is.na(name)) {
			reg_switch <- '/ve'
			name <- '\\(.+?\\)'
		} else {
			reg_switch <- paste('/v', shQuote(name))
		}

		#200. Prepare the query command
		reg_cmd <- paste('REG', 'QUERY', shQuote(key), reg_switch)

		#300. Query the key from Windows Registry and return a list of characters
		reg_rst <- suppressWarnings(system(reg_cmd, intern = T))

		#399. Return NA if the query command fails
		reg_status <- attr(reg_rst, 'status')
		if (length(reg_status)) if (reg_status != 0) {return(NA)}

		#500. Define the regular expression to match the query result
		reg_exp <- paste0('^\\s*', name, '\\s{4}REG_\\w+\\s{4}(.+)\\s*$')

		#700. Clean the result from direct query
		reg_cln <- sapply(
			reg_rst
			,function(x){
				if (grepl(reg_exp, x, ignore.case = T, perl = T)) {
					return(gsub(reg_exp, '\\1', x, ignore.case = T, perl = T))
				}
			}
			,USE.NAMES = F
		)
		reg_cln <- unlist(Filter(Negate(is.null), reg_cln))

		#790. Set the default result as NA
		if (length(reg_cln) == 0) reg_cln <- NA

		#999. Return the cleaned result
		return(reg_cln)
	}

	#999. Apply the helper function to the input vectors
	return(unlist(mapply(proc_query, key, val_name, SIMPLIFY = T, USE.NAMES = F)))
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#100. Prepare strings
		reg_paths <- c(
			'HKEY_LOCAL_MACHINE\\SOFTWARE\\SAS Institute Inc.\\The SAS System\\9.4'
			,'HKEY_LOCAL_MACHINE\\SOFTWARE\\Python\\PythonCore\\3.7\\InstallPath'
			,'HKEY_LOCAL_MACHINE\\SOFTWARE\\R-core\\R64'
		)
		reg_names <- c(
			'DefaultRoot'
			,NA
			,'InstallPath'
		)

		#200. Test query
		reg_rst <- winReg_QueryValue(reg_paths, reg_names)

		#300. Retrieve the version of current Windows OS
		#Quote: https://mivilisnet.wordpress.com/2020/02/04/how-to-find-the-windows-version-using-registry/
		winver <- winReg_QueryValue('HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion', 'CurrentVersion')

		#400. Retrieve the <Language for non-Unicode Programs> of current Windows OS
		#[ASSUMPTION]
		#[1] In case there is a pre-defined key <Default> (rather than <(Default)>), we obtain its value
		#[2] Otherwise we obtain the <(Default)> value during OS installation
		#Quote: https://serverfault.com/questions/957167/windows-10-1809-region-language-registry-keys
		get_locale <- winReg_QueryValue('HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Nls\\Locale', 'Default')
		if (is.na(get_locale)) {
			get_locale <- winReg_QueryValue('HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Nls\\Locale')
		}
		message(get_locale)

		#500. Test calculation in [dplyr]
		library(magrittr)
		df_reg <- data.frame(x = reg_paths, y = reg_names, stringsAsFactors = F) %>%
			dplyr::mutate(p = winReg_QueryValue(x,y))
	}
}
