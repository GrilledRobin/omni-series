@echo off
::000. Initiation
@title DataTransfer

::001. Input Parameters
@set FromDir=D:\RobinLu
@set DestDir=F:\DataMigration

::010. Internal Parameters
@set yymmdd=%date:~6,4%%date:~3,2%%date:~0,2%
::echo yymmdd=%yymmdd%
@set yymmdd=20151101
::set /p yymmdd=Please input Sync Date(YYYYMMDD):
@title From [%FromDir%] to [%DestDir%]
::Please note that the dedicated directory, including its sub-directories, will be copied under [DestDir]

::100. XCOPY files in loop
cd /d "%FromDir%"
setlocal EnableDelayedExpansion
for /f "delims=" %%i in ('dir /s/a-d/b') do (
	@set file1=%%~fi
	@set file2=%%~pi
	@set var_1=%%~ti
	@set var_2=!var_1:~0,2!
	@set var_3=!var_1:~3,2!
	@set var_4=!var_1:~6,4!
	@set varDT=!var_4!!var_3!!var_2!
	if "!varDT!" geq "!yymmdd!" (
		@echo Copying [!file1!] to [!DestDir!!file2!]
		@xcopy "!file1!" "!DestDir!!file2!" /Y/C/D
	)
)

@pause

@echo on