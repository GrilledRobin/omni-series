:: @echo off
:: This is to obtain the executable path of the latest version of Python
:: 010. Local parameters
@set HK_PyReg=HKEY_LOCAL_MACHINE\SOFTWARE\Python\PythonCore\
@set v_PyCore=
@set EXEC_PGM=
:: https://stackoverflow.com/questions/68623895/write-a-macro-in-batch-script-that-load-in-memory-other-macro-from-another-libra
:: https://stackoverflow.com/questions/19798777/accessing-batch-functions-in-another-batch-file

:: 100. Obtain the length of the home path
:: https://stackoverflow.com/questions/5837418/how-do-you-get-the-string-length-in-a-batch-file
:: -------- Begin macro definitions ----------
set ^"LF=^
%= This creates a variable containing a single linefeed (0x0A) character =%
^"
:: Define %\n% to effectively issue a newline with line continuation
(set \n=^^^
%=EMPTY=%
)

:: @strLen  StrVar  [RtnVar]
::
::   Computes the length of string in variable StrVar
::   and stores the result in variable RtnVar.
::   If RtnVar is is not specified, then prints the length to stdout.
::
setlocal disableDelayedExpansion
set @strLen=for %%. in (1 2) do if %%.==2 (%\n%
  for /f "tokens=1,2 delims=, " %%1 in ("!argv!") do ( endlocal%\n%
    set "s=A!%%~1!"%\n%
    set "len=0"%\n%
    for %%P in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (%\n%
      if "!s:~%%P,1!" neq "" (%\n%
        set /a "len+=%%P"%\n%
        set "s=!s:~%%P!"%\n%
      )%\n%
    )%\n%
    for %%V in (!len!) do endlocal^&if "%%~2" neq "" (set "%%~2=%%V") else echo %%V%\n%
  )%\n%
) else setlocal enableDelayedExpansion^&setlocal^&set argv=,

:: -------- End macro definitions ----------

@set len_HK=
%@strLen% HK_PyReg len_HK
:: @echo len_HK=%len_HK%
:: [ASSUMPTION]
:: [1] We must [endlocal] to avoid nested [setlocal] going to the subsequent steps
:: https://stackoverflow.com/questions/48964444/how-to-assign-something-to-global-variable-from-within-for-loop-in-batch
endlocal & set len_HK=%len_HK%

:: 500. Identify the latest version of the software
:: https://ss64.com/nt/syntax-substring.html
:: https://ss64.com/nt/syntax-replace.html
:: https://ss64.com/nt/if.html
:: [ASSUMPTION]
:: [1] We must [setlocal] as below, for [IF] statements to validate local variables
:: [2] Path to query in [reg query] cannot be double-quoted if it has a trailing backslash [\]
:: [3] Replace dot [.] with space [ ], for dots are likely not able to be identified as delimiters
:: [4] ['call echo %%ver_spl%%'] can also be used in [FOR] loop during certain operations
:: [5] Double colons [::] as comments inside [FOR] loop will insult errors on some systems
setlocal enableDelayedExpansion
for /f "tokens=1 delims=:" %%a in (
	'reg query %HK_PyReg% /f . /k'
) do (
	@if "%%a" neq "End of search" (
		@call set tmp=%%a
		@call set ver_cand=%%tmp:~%len_HK%%%
		@call set ver_spl=%%ver_cand:.= %%
		@rem @call echo ver_spl=%%ver_spl%%
		@for /f "tokens=1,2 delims= " %%A in ("!ver_spl!") do (
			@if not defined major @call set /a major=%%A
			@if not defined minor @call set /a minor=%%B
			@if %%A gtr !major! (
				@call set /a major=%%A
				@call set /a minor=%%B
			) else (
				@if %%A equ !major! (
					@if %%B gtr !minor! (
						@call set /a minor=%%B
					)
				)
			)
		)
	)
)
:: @call set v_PyCore=%%major%%.%%minor%%
:: @echo v_PyCore[inside]=!v_PyCore!
endlocal & set v_PyCore=%major%.%minor%
:: @echo v_PyCore[outside]=%v_PyCore%

:: 900. Look up for the executable in Windows Registry for certain version of the software
:: https://www.cnblogs.com/harlanc/p/5656535.html
set HK_PyCore=%HK_PyReg%%v_PyCore%\InstallPath
for /f "tokens=1,2 delims=:" %%a in (
	'reg query "%HK_PyCore%" /ve'
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
set str_left=%v_left:    =\%
for /f "tokens=*" %%i in ("%str_left%.$") do set drive_PyCore=%%~ni
set path_PyCore=%drive_PyCore%:%v_right%
set EXEC_PGM="%path_PyCore%\python.exe"

:: 999. Purge
exit /b %ErrorLevel%

:: Usage of the script to be called in a separate BAT file
:: setlocal enableDelayedExpansion
:: @for %%a in (D: C: E:) do (
:: 	@call set cfgPy="%%a\Python\locPyEXEC.bat"
:: 	@if exist !cfgPy! @goto :EndExist
:: )
:: :EndExist
:: endlocal & set cfgPy=%cfgPy%
:: @call %cfgPy%
:: @echo Python latest version found as: [%v_PyCore%]
:: @echo Executable found as: %EXEC_PGM%
