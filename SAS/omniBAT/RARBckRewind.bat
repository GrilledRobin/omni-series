@echo off
REM set /p CDW_MONTH=Please input the MONTH(YYYYMM):
REM set /p CDW_DATE=Please input the date(DD):
REM set /p REWIND=Daily or Monthly?(D/M):
REM set /p REWMODE=Folder only or File only?(D/L) (For current folder):
REM set OUTPUT_DIR=D:\1_Rewind_Data\CDW
REM set SRC_DIR=C:\CDW\CDW_D\CDW_D_Data
REM set TOOL_DIR=C:\Program Files\WinRAR
REM set CMDSET=-ibck -y
set CDW_TODAY=%CDW_MONTH%%CDW_DATE%

if "%KEEPSRC%"=="" (
	set KEEPSRC=Y
)
if "%REWIND%"=="" (
	set REWIND=D
)
if "%REWMODE%"=="" (
	set REWMODE=L
)
if "%OUTPUT_DIR%"=="" (
	set OUTPUT_DIR=D:\1_Rewind_Data\CDW
)
if "%SRC_DIR%"=="" (
	set SRC_DIR=C:\CDW\CDW_D\CDW_D_Data
)

set rarCMMND=e

if "%REWIND%"=="D" (
	set	rarNAME=%CDW_DATE%
) else (
	set rarNAME=??
)

set /a iCNT=0

SETLOCAL EnableDelayedExpansion
if "!REWMODE!"=="D" (
	@echo [Message] : Processing files in sub-directories one layer down of current folder......
	goto DirRewind
) else (
	@echo [Message] : Processing files in current folder......
	goto FileRewind
)

:DirRewind
for /f "delims=|" %%a in ('dir /AD /B "!SRC_DIR!"') do (
	if "%%a" == "A_C_RPT" (
		REM
	) else (
		set /a iCNT+=1
		@echo !iCNT!. Rewind %%a......
		set SRC_SUB=!SRC_DIR!\%%a\!CDW_MONTH!
		set OUT_SUB=!OUTPUT_DIR!\%%a
		for /f "tokens=1,2 delims=." %%i in ('dir /B "!SRC_SUB!\*!CDW_MONTH!!rarNAME!.rar"') do (
			if not exist "!OUT_SUB!" (
				@echo [Warning] Destination directory "!OUT_SUB!" does not exist, creating...
				@mkdir "!OUT_SUB!"
			)
			"!TOOL_DIR!\winrar.exe" e !CMDSET! "!SRC_SUB!\%%i.rar" *.* "!OUT_SUB!\"
		)
		@echo  == "%%a" Rewind Complete == : !CRM_TODAY!
	)
)
goto EndOfCode

:FileRewind
set /a iCNT+=1
@echo !iCNT!. Rewind Files in "!SRC_DIR!"......
set SRC_SUB=!SRC_DIR!\!CDW_MONTH!
set OUT_SUB=!OUTPUT_DIR!
for /f "tokens=1,2 delims=." %%i in ('dir /A-D /B "!SRC_SUB!\*!CDW_MONTH!!rarNAME!.rar"') do (
	if not exist "!OUT_SUB!" (
		@echo [Warning] Destination directory "!OUT_SUB!" does not exist, creating...
		@mkdir "!OUT_SUB!"
	)
	"!TOOL_DIR!\winrar.exe" e !CMDSET! "!SRC_SUB!\%%i.rar" *.* "!OUT_SUB!\"
)
@echo  == "!SRC_DIR!" Rewind Complete == : !CRM_TODAY!

:EndOfCode
endlocal

@echo on