@echo off
REM set /p CDW_MONTH=Please input the MONTH(YYYYMM):
REM set /p CDW_DATE=Please input the date(DD):
REM set /p FREQ=Daily or Monthly?(D/M):
REM set /p KEEPSRC=Keep source file?(Y/N):
REM set /p BAKMODE=Folder only or File only?(D/L) (For current folder):
REM set OUTPUT_DIR=D:\1_Backup_Data\CDW
REM set SRC_DIR=C:\CDW\CDW_D\CDW_D_Data
REM set TOOL_DIR=C:\Program Files\WinRAR
REM set CMDSET=-ep -m5 -s -ibck -y
set CDW_TODAY=%CDW_MONTH%%CDW_DATE%

if "%KEEPSRC%"=="" (
	set KEEPSRC=Y
)
if "%FREQ%"=="" (
	set FREQ=M
)
if "%BAKMODE%"=="" (
	set BAKMODE=L
)
if "%OUTPUT_DIR%"=="" (
	set OUTPUT_DIR=D:\1_Backup_Data\CDW
)
if "%SRC_DIR%"=="" (
	set SRC_DIR=C:\CDW\CDW_D\CDW_D_Data
)

if "%KEEPSRC%"=="Y" (
	set	rarCMMND=a
) else (
	set rarCMMND=m
)

if "%FREQ%"=="D" (
	set	rarNAME=%CDW_DATE%
) else (
	set rarNAME=??
)

set /a iCNT=0

SETLOCAL EnableDelayedExpansion
if "!BAKMODE!"=="D" (
	@echo [Message] : Processing files in sub-directories one layer down of current folder......
	goto DirBackup
) else (
	@echo [Message] : Processing files in current folder......
	goto FileBackup
)

:DirBackup
for /f "delims=|" %%a in ('dir /AD /B "!SRC_DIR!"') do (
	if "%%a" == "A_C_RPT" (
		REM
	) else (
		set /a iCNT+=1
		@echo !iCNT!. Backup %%a......
		set SRC_SUB=!SRC_DIR!\%%a
		set OUT_SUB=!OUTPUT_DIR!\%%a\!CDW_MONTH!
		for /f "tokens=1,2 delims=." %%i in ('dir /B "!SRC_SUB!\*!CDW_MONTH!!rarNAME!.*"') do (
			if not exist "!OUT_SUB!" (
				@echo [Warning] Destination directory "!OUT_SUB!" does not exist, creating...
				@mkdir "!OUT_SUB!"
			)
			if "%%i"=="arm_cmpnbr!CDW_TODAY!" (
				"!TOOL_DIR!\winrar.exe" a !CMDSET! "!OUT_SUB!\%%i.rar" "!SRC_SUB!\%%i.%%j"
			) else if "%%i"=="a_cmpnbr!CDW_TODAY!" (
				"!TOOL_DIR!\winrar.exe" a !CMDSET! "!OUT_SUB!\%%i.rar" "!SRC_SUB!\%%i.%%j"
			) else if "%%i"=="arm_brcmpn!CDW_TODAY!" (
				"!TOOL_DIR!\winrar.exe" a !CMDSET! "!OUT_SUB!\%%i.rar" "!SRC_SUB!\%%i.%%j"
			) else if "%%i"=="a_brcmpn!CDW_TODAY!" (
				"!TOOL_DIR!\winrar.exe" a !CMDSET! "!OUT_SUB!\%%i.rar" "!SRC_SUB!\%%i.%%j"
			) else if "%%i"=="period_cmpnarm!CDW_TODAY!" (
				"!TOOL_DIR!\winrar.exe" a !CMDSET! "!OUT_SUB!\%%i.rar" "!SRC_SUB!\%%i.%%j"
			) else if "%%i"=="period_cmpnbr!CDW_TODAY!" (
				"!TOOL_DIR!\winrar.exe" a !CMDSET! "!OUT_SUB!\%%i.rar" "!SRC_SUB!\%%i.%%j"
			) else (
				"!TOOL_DIR!\winrar.exe" !rarCMMND! !CMDSET! "!OUT_SUB!\%%i.rar" "!SRC_SUB!\%%i.%%j"
			)
		)
		@echo  == "%%a" Backup Complete == : !CRM_TODAY!
	)
)
goto EndOfCode

:FileBackup
set /a iCNT+=1
@echo !iCNT!. Backup Files in "!SRC_DIR!"......
set OUT_SUB=!OUTPUT_DIR!\!CDW_MONTH!
for /f "tokens=1,2 delims=." %%i in ('dir /A-D /B "!SRC_DIR!\*!CDW_MONTH!!rarNAME!.*"') do (
	if not exist "!OUT_SUB!" (
		@echo [Warning] Destination directory "!OUT_SUB!" does not exist, creating...
		@mkdir "!OUT_SUB!"
	)
	if "%%i"=="arm_cmpnbr!CDW_TODAY!" (
		"!TOOL_DIR!\winrar.exe" a !CMDSET! "!OUT_SUB!\%%i.rar" "!SRC_DIR!\%%i.%%j"
	) else if "%%i"=="a_cmpnbr!CDW_TODAY!" (
		"!TOOL_DIR!\winrar.exe" a !CMDSET! "!OUT_SUB!\%%i.rar" "!SRC_DIR!\%%i.%%j"
	) else if "%%i"=="arm_brcmpn!CDW_TODAY!" (
		"!TOOL_DIR!\winrar.exe" a !CMDSET! "!OUT_SUB!\%%i.rar" "!SRC_DIR!\%%i.%%j"
	) else if "%%i"=="a_brcmpn!CDW_TODAY!" (
		"!TOOL_DIR!\winrar.exe" a !CMDSET! "!OUT_SUB!\%%i.rar" "!SRC_DIR!\%%i.%%j"
	) else if "%%i"=="period_cmpnarm!CDW_TODAY!" (
		"!TOOL_DIR!\winrar.exe" a !CMDSET! "!OUT_SUB!\%%i.rar" "!SRC_DIR!\%%i.%%j"
	) else if "%%i"=="period_cmpnbr!CDW_TODAY!" (
		"!TOOL_DIR!\winrar.exe" a !CMDSET! "!OUT_SUB!\%%i.rar" "!SRC_DIR!\%%i.%%j"
	) else (
		"!TOOL_DIR!\winrar.exe" !rarCMMND! !CMDSET! "!OUT_SUB!\%%i.rar" "!SRC_DIR!\%%i.%%j"
	)
)
@echo  == "!SRC_DIR!" Backup Complete == : !CRM_TODAY!

:EndOfCode
endlocal

@echo on