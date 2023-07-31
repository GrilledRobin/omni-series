@echo off
set PGM_TITLE=Process Flow Example
@title %PGM_TITLE%
REM #######################################################################
set PROC_END=%1
set PROC_BGN=%2
REM #######################################################################
::100. Below for setting up system variables
::Quote: https://www.cnblogs.com/harlanc/p/5656535.html
set v_PyCore=3.9
set HK_PyCore="HKLM\SOFTWARE\Python\PythonCore\%v_PyCore%\InstallPath"
for /f "tokens=1,2 delims=:" %%a in (
	'reg query %HK_PyCore% /ve'
) do (
	set v_left=%%a
	set v_right=%%b
)
::Quote: http://www.bathome.net/thread-13000-1-1.html
::[ASSUMPTION]
::[1] The query result is split by 4 consecutive spaces
::[2] In case the number of drives exceeds 26, we retrieve the last string
::     instead of the last character (although it is nearly impossible)
::[3] Change the string into a pseudo "path"
::[4] Retrieve the last partition of this "path" as the "last string"
::[5] We cannot use [pythonw.exe] to execute [subprocess] due to errors!
set str_left=%v_left:    =\%
for /f "tokens=*" %%i in ("%str_left%.$") do set drive_PyCore=%%~ni
set path_PyCore=%drive_PyCore%:%v_right%
set EXEC_PGM="%path_PyCore%\python.exe"
::[ASSUMPTION]
::[1] We use below method in case this BAT file is called via another one
::[2] Below result contains a trailing backslash [\]
set PROC_HOME=%~dp0
set PROC_DIR=%PROC_HOME%PGM
set PROC_PGM="%PROC_DIR%\main.py"

::400. Run program
::We presume that the executed software will handle the log file properly.
%EXEC_PGM% %PROC_PGM% %PROC_END% %PROC_BGN%

@echo on