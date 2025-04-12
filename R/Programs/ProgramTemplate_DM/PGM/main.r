#002. Take the command line arguments ahead of all other processes
args_in <- commandArgs(T)

#010. Prepare logging
#Quote: https://community.rstudio.com/t/creating-log-files-in-r/71541/2
if (!('log4r' %in% installed.packages()[,'Package'])) install.packages('log4r')
#011. Define the layout of any logging message
#See definition of [log4r::default_log_layout]
log_layout_Python <- function (time_format = '%Y-%m-%d %H:%M:%S'){
	function(level, ...) {
		msg <- paste0(..., collapse = '')
		sprintf('%-4s: %s %s\n', level, log4r:::fmt_current_time(time_format), trimws(msg))
	}
}
logger.head <- function(){strftime(Sys.time(), '%Y-%m-%d %H:%M:%OS ')}

#013. Enable printing the log into command console
p_console <- log4r::console_appender(layout = log_layout_Python())

#030. Import the user defined package
#031. Define the candidates
drives_autoexec <- c('D:', 'C:')
paths_autoexec <- c('R', 'Robin', 'RobinLu', 'SAS')
name_autoexec <- 'autoexec.r'
name_omnimacro <- 'omnimacro'
#Quote: https://stackoverflow.com/questions/22099546/creating-combinations-of-two-vectors
comb_autoexec <- expand.grid(drives_autoexec, paths_autoexec, stringsAsFactors = F)
files_autoexec <- file.path(comb_autoexec[[1]], comb_autoexec[[2]], name_autoexec)
paths_omnimacro <- file.path(comb_autoexec[[1]], comb_autoexec[[2]], name_omnimacro)

#032. Only retrieve the first valid path from the list of candidate paths
if (!any(file.exists(files_autoexec))) {
	stop('ERROR: ',logger.head(),'[',name_autoexec,'] is not found! Program aborted!')
}
#[ASSUMPTION]
#[1] [head] returns [NULL] if the provided length is zero, without error message
file_autoexec <- head(files_autoexec[file.exists(files_autoexec)], 1)

#039. Load the user defined environment, which includes initialization of user defined package
source(file_autoexec)
library(magrittr)

#040. Enable the text writing to the log file
#Below function is from [FileSystem]
scr_name <- thisfile()
dir_curr <- dirname(scr_name)
log_name <- file.path(dir_curr, gsub('\\.\\w+$', '.log', basename(scr_name)))
if (file.exists(log_name)) file.remove(log_name)
p_logfile <- log4r::file_appender(log_name, append = T, layout = log_layout_Python())
my_logger <- log4r::logger(threshold = 'INFO', appenders = list(p_console, p_logfile))

#045. Define the messaging functions
logger.debug <- function(...){log4r::debug(my_logger, trimws(paste0(..., collapse = '')))}
logger.info <- function(...){
	msg <- paste0(..., collapse = '')
	msg <- gsub('^simpleMessage in\\s+[\\.[:alpha:]]\\w*\\(.*?\\):\\s+', '', msg)
	log4r::info(my_logger, trimws(msg))
}
logger.warning <- function(...){
	msg <- paste0(..., collapse = '')
	msg <- gsub('^simpleWarning in\\s+[\\.[:alpha:]]\\w*\\(.*?\\):\\s+', '', msg)
	log4r::warn(my_logger, trimws(msg))
}
logger.error <- function(...){log4r::error(my_logger, trimws(paste0(..., collapse = '')))}
logger.critical <- function(...){log4r::fatal(my_logger, trimws(paste0(..., collapse = '')))}

#050. Define local environment
#051. Period of dates for current script
#[ASSUMPTION]
#[1] All input values will be split by [space]; hence please ensure they are properly quoted where necessary
#[2] All input values are stored in one [character vector]
#[3] If any argument is provided, we should reset [G_clndr] and [G_obsDates] as their period coverage may have been extended
#[4] Symbols referenced below that are out of current scope are from <omniR>
#This program takes 2 arguments in below order:
#[1] [dateEnd         ] [character       ] [yyyymmdd        ]
#[2] [sendEmail       ] [character       ] [0, 1 or <empty> ]
if (length(args_in) > 0) {
	#300. Modify the default arguments to create calendars
	#[ASSUMPTION]
	#[1] Options for <getOption> are defined in <autoexec>
	argEnd <- args_in[[1]]
	args_cln_mod <- modifyList(
		getOption('args.Calendar')
		,list(
			clnBgn = intnx('day', argEnd, -30, daytype = 'C')
			,clnEnd = intnx('day', argEnd, 30, daytype = 'C')
		)
	)

	#500. Create a fresh new calendar
	G_clndr <- do.call(UserCalendar$new, args_cln_mod)

	#700. Create a fresh new date observer
	#[ASSUMPTION]
	#[1] It is often called on workdays
	#[2] Ensure the same behavior when arguments are provided for this script, and when they are not
	G_obsDates <- do.call(ObsDates$new, c(list(obsDate = intnx('day', argEnd, 1, daytype = 'W')), args_cln_mod))
}

#[ASSUMPTION]
#[1] As a business case, we often call the process on the previous workday of current run date
#[2] We align the system behavior when the Business Date is provided or not
#    [a] When NOT providing a date, the Business Date is the previous workday of the run date
#    [b] When a date is provided, it is presumed to be the Business Date to run the process
#[3] As the date is always referred to as a character string marking files or connections, we set it as a string representation
L_curdate <- intnx('day', G_obsDates$values, -1, daytype = 'W') %>% strftime('%Y%m%d')

#052. Directories for current process
dir_proc <- dirname(dir_curr)
dir_out <- file.path(dir_proc, 'Report')
dir_data <- file.path(dir_proc, 'Data')
dir_data_raw <- file.path(dir_data, 'RAWDATA')
dir_data_db <- file.path(dir_data, 'DB')
dir_data_src <- file.path(dir_data, 'SRC')
dir_ctrl <- file.path(dir_curr, 'Control')
if (!dir.exists(dir_ctrl)) dir.create(dir_ctrl, recursive = T)

#055. Directories for local data mart
dir_DM <- file.path('D:', '01LocalDM', 'Data')
dir_DM_raw <- file.path(dir_DM, '01RAW')
dir_DM_sas <- file.path(dir_DM, '02SAS')
dir_DM_db <- file.path(dir_DM, 'DB')
dir_DM_src <- file.path(dir_DM, 'SRC')
dir_DM_T1 <- file.path(dir_DM, 'custlvl')
dir_DM_T2 <- file.path(dir_DM_db, '08Digital Banking')

#059. Initialize the I/O class for standardization of data API
dataIO = DataIO$new()

#060. Determine whether to send email
f_sendmail <- FALSE
if (length(args_in) == 2) f_sendmail <- args_in[[2]] == '1'

#063. Search for necessary scripts anyway
scr_mail_ctrl <- list.files(
	dir_ctrl
	,'^\\d{3}_.*(mail).*\\.r$'
	,full.names = T
	,ignore.case = T
	,recursive = F
	,include.dirs = F
)
scr_mail_curr <- list.files(
	dir_curr
	,'^\\d{3}_.*(mail).*\\.r$'
	,full.names = T
	,ignore.case = T
	,recursive = F
	,include.dirs = F
)

#065. Move the script of sending mail in terms of the request
#[ASSUMPTION]
#[1] We allow multiple scripts to send emails
#[2] If there is any script of the same name in both <dir_ctrl> and <dir_curr>, we overwrite the destination file without warning
if (f_sendmail) {
	#100. Issue warning if there is no script to send email
	if ((length(scr_mail_ctrl) == 0) & (length(scr_mail_curr) == 0)) {
		#Quote: https://www.r-bloggers.com/2012/10/error-handling-in-r/
		withCallingHandlers(
			warning('No script found for emailing!')
			,warning = function(w){logger.warning(w)}
		)
	}

	#500. Move the scripts from <dir_ctrl> to <dir_curr>
	for (obj in scr_mail_ctrl) {
		rc <- file.copy(obj, dir_curr, overwrite = T, recursive = F, copy.mode = T, copy.date = T)
		rc <- file.remove(obj)
	}
} else {
	#500. Move the scripts from <dir_curr> to <dir_ctrl>
	for (obj in scr_mail_curr) {
		rc <- file.copy(obj, dir_ctrl, overwrite = T, recursive = F, copy.mode = T, copy.date = T)
		rc <- file.remove(obj)
	}
}

#080. Locate binaries of other languages for interaction
#081. Prepare Python parameters, in case one has to call python.exe for interaction
#[ASSUMPTION]
#[1] We have to [shQuote] any valid system paths for calling [system] function
pyKey <- 'HKEY_LOCAL_MACHINE\\SOFTWARE\\Python\\PythonCore'
#The names of the direct sub-keys are the version numbers of all installed [Python] software
pyVers <- winReg_getInfByStrPattern(pyKey, inRegExp = '^.*$', chkType = 2)
if (length(pyVers) > 0) {
	pyVer <- Reduce(function(a,b){if (compareVersion(a[['name']],b[['name']]) >= 0) a else b}, pyVers)[['name']]
	PYTHON_HOME <- winReg_getInfByStrPattern(file.path(pyKey, pyVer, 'InstallPath', fsep = '\\'))[[1]][['value']]
} else {
	PYTHON_HOME <- ''
}
PYTHON_EXE <- shQuote(file.path(PYTHON_HOME, 'python.exe'))

#083. Prepare SAS parameters, in case one has to call SAS for interaction
sasKey <- 'HKEY_LOCAL_MACHINE\\SOFTWARE\\SAS Institute Inc.\\The SAS System'
#The names of the direct sub-keys are the version numbers of all installed [SAS] software
sasVers <- winReg_getInfByStrPattern(sasKey, inRegExp = '^\\d+(\\.\\d+)+$', chkType = 2)
if (length(sasVers) > 0) {
	sasVers_comp <- Filter(function(x){tryCatch({numeric_version(x[['name']]);T;}, error = function(e){F})}, sasVers)
	sasVer <- Reduce(function(a,b){if (compareVersion(a[['name']],b[['name']]) >= 0) a else b}, sasVers_comp)[['name']]
	SAS_HOME <- winReg_getInfByStrPattern(file.path(sasKey, sasVer, fsep = '\\'), 'DefaultRoot')[[1]][['value']]
} else {
	SAS_HOME <- ''
}
SAS_EXE <- shQuote(file.path(SAS_HOME, 'sas.exe'))
SAS_CFG_ZH <- shQuote(file.path(SAS_HOME, 'nls', 'zh', 'sasv9.cfg'))
SAS_CFG_INIT <- paste('-CONFIG', SAS_CFG_ZH, '-MEMSIZE', '0', '-NOLOGO', '-ICON')
SAS_omnimacro <- head(paths_omnimacro[dir.exists(paths_omnimacro)], 1)

#100. Find all subordinate scripts that are to be called within current session
pgms_curr <- list.files(
	dir_curr
	,'^\\d{3}_.+\\.r$'
	,full.names = T
	,ignore.case = T
	,recursive = F
	,include.dirs = F
)

i_len <- length(pgms_curr)

#700. Print configurations into the log for debug
#701. Prepare lists of parameters
key_args <- c(
	'rundate' = L_curdate
)
key_dirs <- c(
	'Process Home' = dir_curr
	# ,'SAS omnimacro' = SAS_omnimacro
)
key_tolog <- c(key_args, key_dirs)
mlen_prms <- max(nchar(names(key_tolog)))

#710. Print parameters
#[ASSUMPTION]
#[1] Triangles [<>] are not accepted in naming folders, hence they are safe to be used for enclosing the value of variables
logger.info(strrep('-', 80))
logger.info('Process Parameters:')
for (i in seq_along(key_tolog)) {
	logger.info('<',tmcn::strpad(names(key_tolog)[[i]], width = mlen_prms, side = 'right'),'>: <',key_tolog[[i]],'>')
}

#720. Print existence of key directories
logger.info(strrep('-', 80))
logger.info('Existence of above key locations:')
for (i in seq_along(key_dirs)) {
	logger.info('<',tmcn::strpad(names(key_dirs)[[i]], width = mlen_prms, side = 'right'),'>: <',dir.exists(key_dirs[[i]]),'>')
}
if (!all(dir.exists(key_dirs))) {
	stop(logger.error('Some among the key locations DO NOT exist! Program terminated!'))
}

#770. Subordinate scripts
logger.info(strrep('-', 80))
logger.info('Subordinate scripts to be located at:')
logger.info(dir_curr)
if (i_len == 0) {
	stop(logger.error('No available subordinate script is found! Program terminated!'))
}

#780. Verify the process control file to minimize the system calculation effort
fname_ctrl <- paste0('proc_ctrl', L_curdate, '.txt')
proc_ctrl <- file.path(dir_curr, fname_ctrl)

#781. Remove any control files that were created on other dates
#Quote: https://stackoverflow.com/questions/31590730/list-files-in-r-that-do-not-match-a-pattern
cln_ctrls <- list.files(
	dir_curr
	,'^proc_ctrl\\d{8}\\.txt$'
	,full.names = T
	,ignore.case = T
	,recursive = F
	,include.dirs = F
) %>%
	grep(pattern = paste0(.Platform$file.sep, fname_ctrl, '$'), invert=TRUE, value=TRUE)

if (length(cln_ctrls) > 0) file.remove(cln_ctrls)

#785. Read the content of the process control file, which represents the previously executed scripts
pgm_executed <- character(0)
if (file.exists(proc_ctrl)) {
	pgm_executed <- readLines(proc_ctrl) %>%
		#500. Exclude those beginning with a semi-colon [;], resembling the syntax of [MS DOS]
		{Filter(function(x){!startsWith(x, ';')}, .)}
}

#787. Exclude the previously executed scripts from the full list for current session
if (length(pgm_executed) > 0) {
	#010. Remove duplicates from this list
	pgm_executed_dedup <- sort(unique(pgm_executed))

	#100. Prepare the log
	logger.info(strrep('-', 80))
	logger.info('Below scripts have been executed today, thus are excluded.')
	for (f in pgm_executed_dedup) {
		logger.info('<',f,'>')
	}

	#900. Exclusion
	pgms_curr <- pgms_curr[!(basename(pgms_curr) %in% pgm_executed_dedup)]
	i_len <- length(pgms_curr)
	if (i_len == 0) {
		logger.info('All scripts have been executed previously. Program completed.')
		q()
	}
}

logger.info('Subordinate scripts to be called in below order:')
i_nums <- nchar(as.character(i_len))
mlen_pgms <- max(nchar(basename(pgms_curr)))
for (i in seq_len(i_len)) {
	#100. Pad the sequence numbers by leading zeros, to make the log audience-friendly
	i_char <- tmcn::strpad(as.character(i), width = i_nums, side = 'left', pad = '0')

	#999. Print the message
	logger.info('<',i_char,'>: <',tmcn::strpad(basename(pgms_curr[[i]]), width = mlen_pgms, side = 'right'),'>')
}

#800. Call the subordinate scripts that are previously found
logger.info(strrep('-', 80))
logger.info('Calling subordinate scripts...')
for (pgm in pgms_curr) {
	#001. Get the file name of the script
	fname_scr <- basename(pgm)

	#100. Declare which script is called at this step
	logger.info(strrep('-', 40))
	logger.info('<',fname_scr,'> Beginning...')

	#500. Call the dedicated program
	#Quote: https://www.r-bloggers.com/2012/10/error-handling-in-r/
	withCallingHandlers(
		source(pgm, encoding = head(readr::guess_encoding(pgm), 1))
		,message = function(m){logger.info(m)}
		,print = function(m){logger.info(m)}
		,warning = function(w){logger.warning(w)}
		,error = function(e){logger.error(e)}
		,abort = function(e){logger.critical(e)}
	)

	#700. Write current script to the process control file for another call of the same process
	write(fname_scr, proc_ctrl, append = T)

	#999. Mark completion of current step
	logger.info('<',fname_scr,'> Complete!')
}
logger.info(strrep('-', 80))
logger.info('Process Complete!')
