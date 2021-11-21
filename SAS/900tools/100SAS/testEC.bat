@echo off
@set PATH=%PATH%;C:\Program Files\SAS\SAS 9.1;
@set INITCFG=-CONFIG "C:\Program Files (x86)\SASHome\x86\SASFoundation\9.3\nls\u8\sasv9.cfg"
@set INITCFG=-CONFIG "C:\Program Files\SAS\SAS 9.1\nls\en\sasv9.cfg"
::@set INITCFG=-CONFIG "C:\Program Files\SAS\SAS 9.1\nls\en\sasv9.cfg"
@sas "errCHKSAS.sas" %INITCFG% -nologo -noautoexec
@echo on