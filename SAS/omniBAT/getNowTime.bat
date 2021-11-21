@for /F "tokens=1,2,3 delims=/ " %%a in ('date /t') do set LOGDAY=%%c-%%a-%%b
@for /F "tokens=1,2,3 delims=: " %%i in ('time /t') do set LOGTIME=%%i-%%j-%%k
@set LOGDATETIME=%LOGDAY% %LOGTIME%
:: @set output=%LOGDAY% %LOGTIME%.txt
:: @echo %LOGDATETIME%> "%output%"