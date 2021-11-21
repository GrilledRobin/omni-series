#Below function is from [main.r]
logger.info('step 2')

L_sasflnm <- shQuote(file.path(dir_curr, 'testrun.sas'))
L_saslog <- shQuote(file.path(dir_curr, 'testrun.log'))

logger.info('Executing below SAS program...')
logger.info('<',L_sasflnm,'>')

#Convention to use [system()]
#[1] Always use [call] in command console to execute an external BAT script: cmd <- paste('call', shQuote('xxx.bat')) for returncode retrieval

#100. Prepare the command in the console
#20211026 It is tested that when we require correct returncode from an external BAT script, we have to [call] it, e.g.
# cmd <- paste('call', shQuote('D:\test.bat'))
L_cmd <- paste(SAS_EXE, L_sasflnm, '-LOG', L_saslog, SAS_CFG_INIT)
# logger.info('<',L_cmd,'>')

#500. Prepare the pipe to the command console
rc <- system(L_cmd, intern = T, minimized = T)

#709. Abort the process if SAS program encounters issues
if (!is.null(attr(rc, 'status'))) {
	logger.warn(paste('COMMAND CONSOLE WARNING:', attr(rc, 'errmsg')))
	#Below exception is captured by [withCallingHandlers]
	stop('SAS program executed with errors!')
}
