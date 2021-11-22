@echo off
set PGM_TITLE=Process Flow Example with no Argument
@title %PGM_TITLE%
REM #######################################################################
::100. Below for setting up system variables
::set EXEC_PGM="C:\Program Files\R\R-3.6.1\bin\Rscript.exe"
set EXEC_PGM="C:\Program Files\R\R-4.0.2\bin\Rscript.exe"
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