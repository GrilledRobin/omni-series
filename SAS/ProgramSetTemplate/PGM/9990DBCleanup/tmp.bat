@echo off
set PGM_TITLE=DB Cleanup Process
@title %PGM_TITLE%
REM #######################################################################
set RPT_CURR=20170531
set RPT_PREV=201704
set fKeepRpt=0
REM #######################################################################
REM Below for setting up system variables
@call "..\..\autoCALL.bat"
set CDW_TODAY=%RPT_CURR%
set CURR_STG=9990DBCleanup
set PGM_NAME=temp
set CFGFILE=CFG.txt

@title %PGM_TITLE% - %CURR_STG%
@call "%BAT_PATH%\KernelRunPgm.bat"

@echo on