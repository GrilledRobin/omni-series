::http://wenwen.soso.com/z/q306454229.htm
::姜千睿
::一个计算(1+2)+(1+2+3+4)+(1+2+3+4+5+6)的利用延迟拓展的批处理

@echo off
for /l %%i in (1,1,3) do (
	set /a f=%%i*2
	call :1 %%f%%
)
echo %num%
pause
:1
for /l %%i in (1,1,%1) do (
	Set a=%%i
	call set /a num=%%num%%+%%a%%
)
exit /b