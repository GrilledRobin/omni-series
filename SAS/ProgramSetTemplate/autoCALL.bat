@set PLATFORM_PATH=D:\SAS
@set HOME_PATH=D:\SAS
@set PJT_PATH=%HOME_PATH%\ProgramSetTemplate
@set PGM_PATH=%PJT_PATH%\PGM
@set BAT_PATH=%PLATFORM_PATH%\omniBAT
@set TOOL_PATH=%PLATFORM_PATH%\900tools
@set DATA_PATH=%PJT_PATH%
@set AWK_PATH=%TOOL_PATH%\001AWK
@set LOGCHK_PATH=%TOOL_PATH%\100SAS
@set VBS_PATH=%TOOL_PATH%\200VBS

::@set SAS_HOME=C:\Program Files (x86)\SASHome\x86\SASFoundation\9.3
::@set SAS_HOME=C:\Program Files\SAS\SAS 9.1
@set SAS_HOME=F:\SAS\SASFoundation\9.4
@set PATH=%PATH%;%SAS_HOME%

@REM #######################################################################
@REM Below for retrieving current system time in yyyy-mm-dd
@for /F "tokens=1,2,3 delims=/ " %%a in ('date /t') do set curDAY=%%c-%%a-%%b

@REM #######################################################################
:: Please ensure "nls\en" is not used!
@set INITCFG=-CONFIG "%SAS_HOME%\nls\zh\sasv9.cfg" -MEMSIZE 0
@REM #######################################################################

::Below is for LOG Verification Purpose
@set JOB_NAME=Program Set Template
@set F_SENDEMAIL=0
@set EMAIL_NAME=your.email.address@company.com
@set ENC_LOG=euc-cn
::@set ENC_LOG=utf-8