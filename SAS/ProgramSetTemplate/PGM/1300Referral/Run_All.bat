@echo off
set PGM_TITLE=Program Set Template
@title %PGM_TITLE%
REM #######################################################################
set /p RPT_CURR=Please input current month(YYYYMMDD):
set /p RPT_PREV=Please input last month(YYYYMM):
set /p fKeepRpt=Whether keep the original reports?(0-Drop,1-Keep):
REM #######################################################################
REM Below for setting up system variables
@call "..\..\autoCALL.bat"
set CDW_TODAY=%RPT_CURR%
set CURR_STG=1300Referral
set PGM_NAME=Run_All
set CFGFILE=CFG.txt

@title %PGM_TITLE% - %CURR_STG%
@call "%BAT_PATH%\KernelRunPgm.bat"

@echo on