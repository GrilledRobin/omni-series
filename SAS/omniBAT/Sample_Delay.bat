::http://wenwen.soso.com/z/q306454229.htm
::��ǧ�
::һ������(1+2)+(1+2+3+4)+(1+2+3+4+5+6)�������ӳ���չ��������

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