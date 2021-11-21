@echo off
REM set CDW_TODAY=20090417
REM set CURR_STG=900
REM set CURR_PATH=C:\www\CDW2\02.SourceCode\CDW_QC\001Daily\%CURR_STG%
REM set AWK_PATH=C:\www\CDW2\02.SourceCode\CDW_QC\001Daily\003tools\001AWK
set PATH=%PATH%;C:\cygwin\bin
if exist %CURR_PATH%\errCHK%CDW_TODAY%.log (
	@del %CURR_PATH%\errCHK%CDW_TODAY%.log
)

REM if exist "%CURR_PATH%\errorlog.txt" (
REM 	@gawk -v INSTG=%CURR_STG% -f %AWK_PATH%\errCHKSQL.awk "%CURR_PATH%\errorlog.txt" >> "%CURR_PATH%\errCHK%CDW_TODAY%.log"
REM )
if exist "%CURR_PATH%\Run_All.log" (
	@gawk -f %AWK_PATH%\errCHKSAS.awk "%CURR_PATH%\Run_All.log" >> "%CURR_PATH%\errCHK%CDW_TODAY%.log"
)
setlocal EnableDelayedExpansion
if exist "!CURR_PATH!\errCHK!CDW_TODAY!.log" (
	for /f %%i in ('dir /A-D /B "!CURR_PATH!\errCHK!CDW_TODAY!.log"') do (
		set LOGSIZE=%%~zi
		if "!LOGSIZE!"=="0" (
			@echo Every thing goes fine!
			@del "!CURR_PATH!\errCHK!CDW_TODAY!.log"
		) else (
			@echo Error Found! Program will terminate!
			if not exist !CURR_PATH!\errlog (
				@mkdir !CURR_PATH!\errlog
			)
			@move /y "!CURR_PATH!\errCHK!CDW_TODAY!.log" "!CURR_PATH!\errlog"
			@more "!CURR_PATH!\errlog\errCHK!CDW_TODAY!.log"
			@pause & @exit
		)
	)
)
endlocal

@echo on