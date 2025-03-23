:: @echo off
:: [1] This script is to locate the VENV for setting up module <omniPy>
:: [2] This script is usually referenced in the caller program, such as:
::      ".\Packages\3.11\venv_install_offline.bat"
:: 010. Local environment
@set NAME_VENV=venv_omniPy
@set THIS_DIR=%~dp0
@set F_INST_PKG_OFFLINE=0

:: 100. Below for setting up system variables
setlocal enableDelayedExpansion
@for %%a in (D: C: E:) do (
	@call set cfgPy="%%a\Python\locPyEXEC.bat"
	@if exist !cfgPy! @goto :EndExist
)
:EndExist
endlocal & set cfgPy=%cfgPy%
@call %cfgPy%
:: @echo Python latest version found as: [%v_PyCore%]
:: @echo Executable found as: %EXEC_PGM%

setlocal enableDelayedExpansion
@for %%a in (D: C: E:) do (
	@call set DIR_PKG_OFFLINE=%%a\Python\Packages\%v_PyCore%\
	@if exist "!DIR_PKG_OFFLINE!" @goto :EndPkg
)
:EndPkg
endlocal & set DIR_PKG_OFFLINE=%DIR_PKG_OFFLINE%

:: 200. Locate VENV
:: [ASSUMPTION]
:: [1] We use below method in case this BAT file is called via another one
:: [2] <THIS_DIR> contains a trailing backslash [\]
:: [3] Usually only one VENV is needed to setup <omniPy> in one company,
::      so just change below name of VENV once when required
:: [4] Append a backslash <\> to ensure verification of a directory
@set DIR_VENV=%THIS_DIR%%NAME_VENV%
@set BAT_VENV="%DIR_VENV%\Scripts\activate.bat"

:: 250. Detect the existence of VENV
@if exist "%DIR_VENV%\" (
	@if exist %BAT_VENV% (
		@goto EndLocVenv
	) else (
		@echo Removing invalid VENV: "%DIR_VENV%\"
		@rmdir /s /q "%DIR_VENV%\"
	)
)

:: 400. Create the virtual environment
:: [ASSUMPTION]
:: [1] Quote: https://github.com/MNeMoNiCuZ/venv_create
@echo Creating virtual environment "%NAME_VENV%"
%EXEC_PGM% -m venv "%DIR_VENV%"

:: 600. Upgrade PIP
:: Quote: https://learn.microsoft.com/zh-cn/windows-server/administration/windows-commands/for
@for /f "delims=" %%A in ('dir "%DIR_PKG_OFFLINE%pip-*" /B/A-D') do (
	"%DIR_VENV%\Scripts\python.exe" -m pip install "%DIR_PKG_OFFLINE%%%~A"
)

:: 700. Install offline packages to the newly created virtual environment
:: [ASSUMPTION]
:: [1] Since Python may be installed with <Anaconda> or else, raw session
::      in command console may not be the proper environment to install
::      offline packages due to less privilege
:: [2] Hence we only warn users at this step
@if not defined F_INST_PKG_OFFLINE @set F_INST_PKG_OFFLINE=0
if "F_INST_PKG_OFFLINE"=="1" (
	@echo Packages are not verified at VENV creation! Please install
	@echo  packages separately as this program may have less privilege.
)

:: 999. Purge
:EndLocVenv
@echo Found VENV: "%DIR_VENV%"
@echo Call the BAT file with variable "BAT_VENV" to activate it
exit /b %ErrorLevel%
