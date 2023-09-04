@echo off
set PGM_TITLE=Process Flow Example with no Argument
@title %PGM_TITLE%
REM #######################################################################
::100. Below for setting up system variables
setlocal enableDelayedExpansion
@for %%a in (D: C: E:) do (
	@call set cfgPy="%%a\Python\locPyEXEC.bat"
	@if exist !cfgPy! @goto :EndExist
)
:EndExist
endlocal & set cfgPy=%cfgPy%
@call %cfgPy%
@echo Python latest version found as: [%v_PyCore%]
@echo Executable found as: %EXEC_PGM%
::[ASSUMPTION]
::[1] We use below method in case this BAT file is called via another one
::[2] Below result contains a trailing backslash [\]
set PROC_HOME=%~dp0
set PROC_DIR=%PROC_HOME%PGM
set PROC_PGM="%PROC_DIR%\main.py"

::400. Run program
::We presume that the executed software will handle the log file properly.
%EXEC_PGM% %PROC_PGM%

@echo on