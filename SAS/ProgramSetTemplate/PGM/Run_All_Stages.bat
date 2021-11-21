@echo off
set PGM_TITLE=Program Set Template
@title %PGM_TITLE%
REM #######################################################################
set /p RPT_CURR=Please input current month(YYYYMMDD):
set /p RPT_PREV=Please input last month(YYYYMM):
set /p fKeepRpt=Whether keep the original reports?(0-Drop,1-Keep):
REM #######################################################################
::100. Below for setting up system variables
@call "..\autoCALL.bat"
set CDW_TODAY=%RPT_CURR%
set PGM_NAME=Run_All
set CFGFILE=CFG.txt
set LST_FOLDER=%PGM_PATH%\CFG_Folder.txt

::200. Create log file
@call "%BAT_PATH%\getNowTime.bat"
set BAT_LOG=%PGM_PATH%\9999BATLOG\BAT_LOG %LOGDATETIME%.txt

::300. Start the log
@echo %DATE% %TIME% %PGM_TITLE% Commencing...> "%BAT_LOG%"

::310. Sleep for scheduled task
::sas "%PGM_PATH%\sleep.sas"

::400. Run program by given folders
::SETLOCAL EnableDelayedExpansion
::(1) "CALL" routine gives us the solution for "Delayed Expansion" once
:: the "SETLOCAL" reaches the upper limit of variable resolution; meanwhile,
:: it enables the standalone programming for automation.
::(2) We must use the pattern "%%a%%" instead of "%a%" within "CALL" routine
:: to enable the "Delayed Expansion" if we abandon "SETLOCAL".
::(3) However, if the variable, which should be DELAYED, is called in an
:: external batch file; that batch file can (or should?) use the common way.
:: i.e. "%a%" to process. I should seek for further information about the
:: mechanism for this difference.

::"for /f" command will omit all records that have ";" as line beginning in
:: the specific file.
for /f "usebackq" %%a in ("%LST_FOLDER%") do (
	@call set CURR_STG=%%a
	@call title %PGM_TITLE% - %%CURR_STG%%
	@call echo %%DATE%% %%TIME%% Now Running %%CURR_STG%%
	@call echo %%DATE%% %%TIME%% Now Running %%CURR_STG%%>> "%BAT_LOG%"
	@call "%BAT_PATH%\KernelRunPgm.bat"
	@call echo %%DATE%% %%TIME%% %%CURR_STG%% Success!
	@call echo %%DATE%% %%TIME%% %%CURR_STG%% Success!>> "%BAT_LOG%"
)
::endlocal

::500. End the log
@echo %DATE% %TIME% %PGM_TITLE% Complete!>> "%BAT_LOG%"

@echo on