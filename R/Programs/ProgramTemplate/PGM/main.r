#002. Take the command line arguments ahead of all other processes
#[ASSUMPTION]
#[1] All input values will be split by [space]; hence please ensure they are properly quoted where necessary
#[2] All input values are stored in one [character vector]
args_in <- commandArgs(T)
#This program takes 2 arguments in below order:
#[1] [dateEnd         ] [character       ] [yyyymmdd        ]
#[2] [dateBgn         ] [character       ] [yyyymmdd        ]
if (length(args_in) == 0) {
	stop('ERROR: ',Sys.time(),' No argument is detected! Program aborted!')
}

#010. Prepare logging
#Quote: https://community.rstudio.com/t/creating-log-files-in-r/71541/2
if (!('log4r' %in% installed.packages()[,'Package'])) install.packages('log4r')
#011. Define the layout of any logging message
#See definition of [log4r::default_log_layout]
log_layout_Python <- function (time_format = '%Y-%m-%d %H:%M:%S'){
	function(level, ...) {
		msg <- paste0(..., collapse = '')
		sprintf('%-4s: %s %s\n', level, log4r:::fmt_current_time(time_format), msg)
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

#039. Load the user defined encironment, which includs initialization of user defined package
source(file_autoexec)

#040. Enable the text writing to the log file
#Below function is from [omniR$FileSystem]
scr_name <- thisfile()
dir_curr <- dirname(scr_name)
log_name <- file.path(dir_curr, gsub('\\.\\w+$', '.log', basename(scr_name)))
if (file.exists(log_name)) file.remove(log_name)
p_logfile <- log4r::file_appender(log_name, append = T, layout = log_layout_Python())
my_logger <- log4r::logger(threshold = 'INFO', appenders = list(p_console, p_logfile))

#045. Define the messaging functions
logger.debug <- function(...){log4r::debug(my_logger, paste0(..., collapse = ''))}
logger.info <- function(...){
	msg <- paste0(..., collapse = '')
	msg <- gsub('^simpleMessage in\\s+[\\.[:alpha:]]\\w*\\(.*?\\):\\s+', '', msg)
	log4r::info(my_logger, msg)
}
logger.warn <- function(...){
	msg <- paste0(..., collapse = '')
	msg <- gsub('^simpleWarning in\\s+[\\.[:alpha:]]\\w*\\(.*?\\):\\s+', '', msg)
	log4r::warn(my_logger, msg)
}
logger.error <- function(...){log4r::error(my_logger, paste0(..., collapse = ''))}
logger.critical <- function(...){log4r::fatal(my_logger, paste0(..., collapse = ''))}

#050. Define local environment
#051. Period of dates for current script
#[IMPORTANT] Due to definition of [omniPy.Dates.UserCalendar], we have to set [dateBgn] ahead of [dateEnd]
f_has_dateBgn <- F
if (length(args_in) == 2) {
	if (length(args_in[[2]]) > 0) {
		f_has_dateBgn <- T
	}
}
if (f_has_dateBgn) {
	G_clndr$dateBgn <- args_in[[2]]
} else {
	#010. Declare the logic
	logger.info('<dateBgn> is not provided, use <Current Quarter Beginning> instead.')

	#100. Prepare to observe the date originated from the first input argument
	G_obsDates$values <- args_in[[1]]

	#500. Retrieve <Current Quarter Beginning> by adding 1 calendar day to the <Last Calendar Day of the Previous Quarter>
	G_clndr$dateBgn <- G_obsDates$prevQtrLCD + as.difftime(1, units = 'days')
}
G_clndr$dateEnd <- args_in[[1]]

#052. Directories for current process
dir_proc <- dirname(dir_curr)
dir_out <- file.path(dir_proc, 'Report')
dir_data <- file.path(dir_proc, 'Data')
dir_data_raw <- file.path(dir_data, 'RAWDATA')
dir_data_db <- file.path(dir_data, 'DB')

#055. Directories for local data mart
dir_DM <- file.path('D:', '01LocalDM', 'Data')
dir_DM_raw <- file.path(dir_DM, '01RAW')
dir_DM_sas <- file.path(dir_DM, '02SAS')
dir_DM_db <- file.path(dir_DM, 'DB')
dir_DM_src <- file.path(dir_DM, 'SRC')
dir_DM_T1 <- file.path(dir_DM, 'custlvl')
dir_DM_T2 <- file.path(dir_DM_db, '08Digital Banking')

#058. Prepare SAS parameters, in case one has to call SAS for interaction
#[ASSUMPTION]
#[1] We have to [shQuote] any valid system paths for calling [system] function
SAS_HOME <- 'C:/SASHome/SASFoundation/9.4'
#SAS_HOME <- 'C:/Program Files/SASHome/x86/SASFoundation/9.4'
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
	'dateBgn' = G_clndr$dateBgn %>% strftime('%Y-%m-%d')
	,'dateEnd' = G_clndr$dateEnd %>% strftime('%Y-%m-%d')
)
key_dirs <- c(
	'Process Home' = dir_curr
	# ,'SAS Home' = SAS_HOME
	,'SAS omnimacro' = SAS_omnimacro
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
logger.info(strrep('-', 80))
if (i_len == 0) {
	stop(logger.error('No available subordinate script is found! Program terminated!'))
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
	#001. Declare which script is called at this step
	logger.info(strrep('-', 40))
	logger.info('<',basename(pgm),'> Beginning...')

	#990. Call the dedicated program
	#Quote: https://www.r-bloggers.com/2012/10/error-handling-in-r/
	withCallingHandlers(
		source(pgm)
		,message = function(m){logger.info(m)}
		,warning = function(w){logger.warn(w)}
		,error = function(e){logger.error(e)}
		,abort = function(e){logger.critical(e)}
	)

	#999. Mark completion of current step
	logger.info('<',basename(pgm),'> Complete!')
}
logger.info(strrep('-', 80))
logger.info('Process Complete!')