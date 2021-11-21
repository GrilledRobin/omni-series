@echo off

@set ExtBefore=.wav
@set ExtAfter=.dts

@for /F "delims=;" %%i in ('dir *%ExtBefore% /B /A-D') do (
REM	@echo %%~ni + %%~xi
	@ren "%%~i" "%%~ni%ExtAfter%"
)

@echo on