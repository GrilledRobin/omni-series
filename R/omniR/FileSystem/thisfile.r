#---------------------------------------------------------------------------------------------------------------------------------------#
#100.   Introduction.                                                                                                                   #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |This function is intended to retrieve the full path of current executing script, resembling [__file__] in Python                   #
#   |Quote: https://stackoverflow.com/questions/47044068/get-the-path-of-current-script                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |IMPORTANT:                                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[1] The script calling this function should be saved before being executed                                                         #
#---------------------------------------------------------------------------------------------------------------------------------------#
#200.   Glossary.                                                                                                                       #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   |100.   Parameters.                                                                                                                 #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |<NA>       :   This function does not take arguments                                                                               #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |900.   Return Values by position.                                                                                                  #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |[<str>]    :   Full path of current executing script as character string                                                           #
#---------------------------------------------------------------------------------------------------------------------------------------#
#300.   Update log.                                                                                                                     #
#---------------------------------------------------------------------------------------------------------------------------------------#
#   | Date |    20210303        | Version | 1.00        | Updater/Creator | Lu Robin Bin                                                #
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
#   |   |rstudioapi                                                                                                                     #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#   |300.   Dependent functions                                                                                                         #
#   |-----------------------------------------------------------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------------------------------#

#001. Append the list of required packages to the global environment
#Below expression is used for easy copy-paste from raw text strings instead of quoted ones.
lst_pkg <- deparse(substitute(c(
	rstudioapi
)))
#Quote: https://www.regular-expressions.info/posixbrackets.html?wlr=1
lst_pkg <- paste0(lst_pkg, collapse = '')
lst_pkg <- gsub('[[:space:]]', '', lst_pkg, perl = T)
lst_pkg <- gsub('^c\\((.+)\\)', '\\1', lst_pkg, perl = T)
lst_pkg <- unlist(strsplit(lst_pkg, ',', perl = T))
options( omniR.req.pkg = base::union(getOption('omniR.req.pkg'), lst_pkg) )

thisfile <- function(){
	#Most solutions use [sys.frames()[1]] but my research locates the last of the valid frames with attribute [ofile]
	#This is because the script calling this function is always in the last frame along its call stack
	frame_txt <- Filter(Negate(is.null), sapply(sys.frames(), function(f){f$ofile}))
	cmdArgs <- commandArgs(trailingOnly = FALSE)
	if (length(grep("^-f$", cmdArgs)) > 0) {
		# R console option
		normalizePath(cmdArgs[grep("^-f", cmdArgs) + 1])[1]
	} else if (length(grep("^--file=", cmdArgs)) > 0) {
		# Rscript/R console option
		normalizePath(sub("^--file=", "", cmdArgs[grep("^--file=", cmdArgs)]))[1]
	} else if (length(frame_txt) > 0) {
		# 'source'd via any other script
		return(frame_txt[[length(frame_txt)]])
	} else if (Sys.getenv("RSTUDIO") == "1") {
		#[IMPORTANT] This should be at the lowest priority as most tests are running within RStudio interactive mode
		# RStudio
		rstudioapi::getSourceEditorContext()$path
	} else {
		stop("Cannot find file path")
	}
}

#[Full Test Program;]
if (FALSE){
	#Simple test
	if (TRUE){
		#100. Create a temporary script file
		L_stpflnm <- 'D:\\Temp\\testpath.r'

		#110. Remove the original file if exists
		if (file.exists(L_stpflnm)) file.remove(L_stpflnm)
		file.create(L_stpflnm, showWarnings = F)

		#130. Create a new file
		fileconn <- file(L_stpflnm, encoding = 'utf-8')

		#150. Write the lines
		val_lines <- c(
			'source("D:/R/autoexec.r")'
			,'message(thisfile())'
		)
		writeLines(val_lines, fileconn, sep = '\n')

		#160. Close the file
		close(fileconn)

		#180. Run the file and check the log
		source(L_stpflnm)

		#300. Find the path of this file in RStudio interactive mode
		message(thisfile())

		#500. Test the log created by RScript
		#501. Create a BAT file for execution
		L_Rscript <- 'C:\\Program Files\\R\\R-4.0.2\\bin\\Rscript.exe'
		L_batflnm <- 'D:\\Temp\\testpath.bat'
		L_logflnm <- 'D:\\Temp\\testpath.log'

		#510. Remove the original file if exists
		if (file.exists(L_batflnm)) file.remove(L_batflnm)
		file.create(L_batflnm, showWarnings = F)

		#530. Create a new file
		fileconn <- file(L_batflnm)

		#550. Write the lines
		val_lines <- c(
			'@echo off'
			,paste(shQuote(L_Rscript), shQuote(L_stpflnm), '>', shQuote(L_logflnm), '2>&1')
			,'@echo on'
		)
		writeLines(val_lines, fileconn, sep = '\n')

		#560. Close the file
		close(fileconn)

		#580. Execute the BAT file
		#Quote: https://stackoverflow.com/questions/32015333/executing-a-batch-file-in-an-r-script
		shell.exec(L_batflnm)

		#999. Remove the temporary files
		if (file.exists(L_stpflnm)) file.remove(L_stpflnm)
		if (file.exists(L_batflnm)) file.remove(L_batflnm)
		if (file.exists(L_logflnm)) file.remove(L_logflnm)

	}
}
