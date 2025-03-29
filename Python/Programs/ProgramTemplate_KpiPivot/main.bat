@echo off
@set PGM_TITLE=Example of KPI Pivoting and Distribution
@title %PGM_TITLE%
REM #######################################################################
set /p PROC_END=Please input period ending(YYYYMMDD):
set /p SEND_EMAIL=[Optional]Whether to send email?(1-Send, 0-Not Send):
@set PROC_HOME=%~dp0
@set RUN_IN_VENV=1
REM #######################################################################
:: 100. Below for setting up system variables
:: 101. Determine the execution environment
@if "%RUN_IN_VENV%"=="1" (
	@goto RunInVenv
) else (
	@goto RunInCore
)

:: 110. Identify core environment
:RunInCore
setlocal enableDelayedExpansion
@for %%a in (D: C: E:) do (
	@call set cfgPy="%%a\Python\locPyEXEC.bat"
	@if exist !cfgPy! @goto :EndCore
)
:EndCore
endlocal & set cfgPy=%cfgPy%
@call %cfgPy%
@goto EndFindEnv

:: 150. Identify virtual environment
:RunInVenv
setlocal enableDelayedExpansion
@for %%a in (D: C: E:) do (
	@call set cfgPyVenv="%%a\Python\loc_omniPy_VENV.bat"
	@if exist !cfgPyVenv! @goto :EndVenv
)
:EndVenv
endlocal & set cfgPyVenv=%cfgPyVenv%
@call %cfgPyVenv%
@call "%BAT_VENV%"
@set EXEC_PGM="%DIR_VENV%\Scripts\python.exe"
@echo Running in virtual environment: [%NAME_VENV%]
@goto EndFindEnv

:EndFindEnv
@echo Python latest version found as: [%v_PyCore%]
@echo Executable found as: %EXEC_PGM%
:: [ASSUMPTION]
:: [1] We use below method in case this BAT file is called via another one
:: [2] <PROC_HOME> contains a trailing backslash [\]
@set PROC_DIR=%PROC_HOME%PGM
@set PROC_PGM="%PROC_DIR%\main.py"

:: 400. Run program
:: We presume that the executed software will handle the log file properly.
%EXEC_PGM% %PROC_PGM% %PROC_END% %SEND_EMAIL%

@echo on