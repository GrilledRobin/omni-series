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

::Quote: https://www.cnblogs.com/harlanc/p/5656535.html
@set ver_SAS=9.4
@set HK_SAS="HKLM\SOFTWARE\SAS Institute Inc.\The SAS System\%ver_SAS%"
@set val_SAS="DefaultRoot"
@for /f "tokens=1,2 delims=:" %%a in (
	'reg query %HK_SAS% /v %val_SAS%'
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
@set str_left=%v_left:    =\%
@for /f "tokens=*" %%i in ("%str_left%.$") do set drive_SAS=%%~ni
@set SAS_HOME=%drive_SAS%:%v_right%
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