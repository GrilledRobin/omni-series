@echo off
set PGM_TITLE=Process Flow Example with no Argument
@title %PGM_TITLE%
REM #######################################################################
::100. Below for setting up system variables
::Quote: https://www.cnblogs.com/harlanc/p/5656535.html
set HK_RCore="HKEY_LOCAL_MACHINE\SOFTWARE\R-core\R64"
set v_RCore="InstallPath"
for /f "tokens=1,2 delims=:" %%a in (
	'reg query %HK_RCore% /v %v_RCore%'
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
set str_left=%v_left:    =\%
for /f "tokens=*" %%i in ("%str_left%.$") do set drive_RCore=%%~ni
set path_RCore=%drive_RCore%:%v_right%
set EXEC_PGM="%path_RCore%\bin\Rscript.exe"
::[ASSUMPTION]
::[1] We use below method in case this BAT file is called via another one
::[2] Below result contains a trailing backslash [\]
set PROC_HOME=%~dp0
set PROC_DIR=%PROC_HOME%PGM
set PROC_PGM="%PROC_DIR%\main.r"
::set PROC_LOG="%PROC_DIR%\main.log"

::400. Run program
::Quote: https://stackoverflow.com/questions/14167178
::%EXEC_PGM% %PROC_PGM% >%PROC_LOG% 2>&1
%EXEC_PGM% %PROC_PGM%

@echo on