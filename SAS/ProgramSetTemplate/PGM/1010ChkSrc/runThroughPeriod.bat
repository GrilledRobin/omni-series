@echo off
set PGM_TITLE=Program Set Template
@title %PGM_TITLE%
REM #######################################################################
set fKeepRpt=0
REM #######################################################################
REM Below for setting up system variables
@call "..\..\autoCALL.bat"
set CDW_TODAY=%RPT_CURR%
set CURR_STG=1010ChkSrc
set PGM_NAME=temp
set CFGFILE=CFG.txt

@title %PGM_TITLE% - %CURR_STG%

for /f "usebackq tokens=1,2" %%a in ("runThroughPeriod.txt") do (
	@call set RPT_CURR=%%a
	@call set RPT_PREV=%%b
	@call echo %%RPT_CURR%%
	@call "%BAT_PATH%\KernelRunPgm.bat"
)

@echo on