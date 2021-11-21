@set CURR_PATH=%PGM_PATH%\%CURR_STG%
@set OUTFILE=%CURR_PATH%\%CFGFILE%
if exist "%OUTFILE%" (
	@del /Q "%OUTFILE%"
)

@echo %%global G_cur_year;>> "%OUTFILE%"
@echo %%let G_cur_year = %%substr(%RPT_CURR%,1,4);>> "%OUTFILE%"
@echo %%global G_cur_mth;>> "%OUTFILE%"
@echo %%let G_cur_mth = %%substr(%RPT_CURR%,5,2);>> "%OUTFILE%"
@echo %%global G_cur_day;>> "%OUTFILE%"
@echo %%let G_cur_day = %%substr(%RPT_CURR%,7,2);>> "%OUTFILE%"
@echo %%global G_prevyear;>> "%OUTFILE%"
@echo %%let G_prevyear = %%substr(%RPT_PREV%,1,4);>> "%OUTFILE%"
@echo %%global G_prevmth;>> "%OUTFILE%"
@echo %%let G_prevmth = %%substr(%RPT_PREV%,5,2);>> "%OUTFILE%"
@echo %%global LfKeepRpt;>> "%OUTFILE%"
@echo %%let LfKeepRpt = %fKeepRpt%;>> "%OUTFILE%"

@echo %%put Current month is "&G_cur_year.-&G_cur_mth.".;>> "%OUTFILE%"
@echo %%put Last month is "&G_prevyear.-&G_prevmth.".;>> "%OUTFILE%"
REM #######################################################################
@CD /D "%CURR_PATH%"
sas "%CURR_PATH%\%PGM_NAME%.sas" %INITCFG% -nologo
REM #######################################################################
if exist "%CURR_PATH%\runSQLfile.bat" (
	@del /Q "%CURR_PATH%\runSQLfile.bat"
)

@echo Analyzing LOG......
@echo Check errors...
@set LOG_NAME=%PGM_NAME%.log
@call "%BAT_PATH%\SASlogCHK_auto.bat"