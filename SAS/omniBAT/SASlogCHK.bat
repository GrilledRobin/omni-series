::echo off
::@set CDW_TODAY=20090417
::@set CURR_STG=900
::@set LOG_NAME=Run_All_Qrpt.log
::@set CURR_PATH=C:\www\CDW2\02.SourceCode\CDW_QC\001Daily\%CURR_STG%
::@set LOGCHK_PATH=C:\www\CDW2\02.SourceCode\CDW_QC\001Daily\003tools\010SAS
::@set PATH=%PATH%;C:\Program Files (x86)\SASHome\x86\SASFoundation\9.3
@set errCHKSAScfg=%CURR_PATH%\errCHKSAScfg.txt
if exist "%CURR_PATH%\errCHK%CDW_TODAY%.log" (
	@del /Q "%CURR_PATH%\errCHK%CDW_TODAY%.log"
)
if exist "%errCHKSAScfg%" (
	@del /Q "%errCHKSAScfg%"
)

if exist "%CURR_PATH%\%LOG_NAME%" (
	@echo %%global G_PATH_LOGCHK;>> "%errCHKSAScfg%"
	@echo %%let G_PATH_LOGCHK = %LOGCHK_PATH%;>> "%errCHKSAScfg%"
	@echo %%global LOG_NAME;>> "%errCHKSAScfg%"
	@echo %%let LOG_NAME = %CURR_PATH%\%LOG_NAME%;>> "%errCHKSAScfg%"
	@echo %%global RST_NAME;>> "%errCHKSAScfg%"
	@echo %%let RST_NAME = %CURR_PATH%\errCHK%CDW_TODAY%.log;>> "%errCHKSAScfg%"
	@echo %%global F_SENDEMAIL;>> "%errCHKSAScfg%"
	@echo %%let F_SENDEMAIL = %F_SENDEMAIL%;>> "%errCHKSAScfg%"
	@echo %%global G_email;>> "%errCHKSAScfg%"
	@echo %%let G_email = %EMAIL_NAME%;>> "%errCHKSAScfg%"
	@echo %%global G_ENC_LOG;>> "%errCHKSAScfg%"
	@echo %%let G_ENC_LOG = %ENC_LOG%;>> "%errCHKSAScfg%"
	@echo %%global G_JOB_NAME;>> "%errCHKSAScfg%"
	@echo %%let G_JOB_NAME = %JOB_NAME%;>> "%errCHKSAScfg%"
	@echo %%include "%LOGCHK_PATH%\errCHKSAS.sas";>> "%errCHKSAScfg%"
	@sas "%errCHKSAScfg%" %INITCFG% -nologo -noautoexec
)
@setlocal EnableDelayedExpansion
if exist "!CURR_PATH!\errCHK!CDW_TODAY!.log" (
	for /f %%i in ('dir /A-D /B "!CURR_PATH!\errCHK!CDW_TODAY!.log"') do (
		set LOGSIZE=%%~zi
		if "!LOGSIZE!"=="0" (
			@echo Every thing goes fine!
			@del /Q "!CURR_PATH!\errCHK!CDW_TODAY!.log"
		) else (
			@echo Error Found! Program will terminate!
			if not exist "!CURR_PATH!\errlog" (
				@mkdir "!CURR_PATH!\errlog"
			)
			@move /y "!CURR_PATH!\errCHK!CDW_TODAY!.log" "!CURR_PATH!\errlog"
			@more "!CURR_PATH!\errlog\errCHK!CDW_TODAY!.log"
			@pause & exit
		)
	)
)
@endlocal

::echo on