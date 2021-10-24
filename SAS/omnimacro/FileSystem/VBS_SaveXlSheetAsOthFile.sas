%macro VBS_SaveXlSheetAsOthFile(
	inXLFile	=
	,inSheet	=
	,outFile	=
	,outFileTp	=
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to save the input EXCEL sheet as another file type, exp. CSV in most cases.									|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inXLFile	:	The input EXCEL file.																								|
|	|inSheet	:	The sheet which contains the specific report range.																	|
|	|outFile	:	The ourput file.																									|
|	|outFileTp	:	The ourput file type in the ID of VBS or VBA. Please find the ID list in the appendix below.						|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20160409		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170408		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Elinimate the activation of XLSheet if it is NOT provided.																	|
|	|      |This is useful if we do not know the sheet name for the provided file, while there is only one sheet.						|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180304		| Version |	1.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*010.	Set parameters.;
%*011.	Identify current processing macro.;
%local
	L_mcrLABEL
	Lohno
;
%let	L_mcrLABEL	=	&sysMacroName.;
%let	Lohno		=	%str(E)RROR: [&L_mcrLABEL.]Process failed due to %str(e)rrors!;

%*012.	Handle the parameter buffer.;
%if	%length(%qsysfunc(compress(&outFile.,%str( ))))		=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No output file is defined, program will terminate immediately!;
	%goto	EndOfProc;
%end;
%if	%length(%qsysfunc(compress(&outFileTp.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No file type is defined for output, program will terminate immediately!;
	%goto	EndOfProc;
%end;
%if	%length(%qsysfunc(compress(&inXLFile.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No input file is defined, program will terminate immediately!;
	%goto	EndOfProc;
%end;
%if	%sysfunc(fileexist(&inXLFile.))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Specified file [&inXLFile.] does not exist.;
	%goto	EndOfProc;
%end;
%if	%length(%qsysfunc(compress(&inSheet.,%str( ))))		=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No input sheet is defined, program presumes that the default sheet has been activated.;
%end;

%*100.	Generate VB Script.;
data _NULL_;
	%*010.	Initialization.;
	length
		script
		filev
		sWorkbook
		$1024
	;
	script		=	catx('\',pathname('work'),'XlSaveAs.vbs');
	filev		=	script;
	sWorkbook	=	symget('inXLFile');
	call symputx("delscript",script,"L");

	%*100.	Create temporary VBScript file.;
	%* Cards are not supported by macro facility.;
	file
		dummy
		filevar=filev
	;

	put	'''001.	System Initiation.';
	put	'Dim'"09"x'XLApp,XLBook,XLSheet,oFileName,oFileType';
	put	'Set'"09"x'XLApp'"09"x'='"09"x'CreateObject("Excel.Application")';
	put	'XLApp.Visible'"09"x'='"09"x'False';
	put	'XLApp.DisplayAlerts'"09"x'='"09"x'False';
	put;
	put	'XLBook'"09"x'='"09"x'"'"&inXLFile."'"';
%if	%length(%qsysfunc(strip(&inSheet.)))	^=	0	%then %do;
	put	'XLSheet'"09"x'='"09"x'"'"&inSheet."'"';
%end;
	put	'oFileName'"09"x'='"09"x'"'"&outFile."'"';
	put	'oFileType'"09"x'='"09"x'"'"&outFileTp."'"';
	put;
	put	'''100.'"09"x'Source Retrieval.';
	put	'XLApp.Workbooks.Open XLBook';
%if	%length(%qsysfunc(strip(&inSheet.)))	^=	0	%then %do;
	put	'XLApp.ActiveWorkbook.Sheets(XLSheet).Activate';
%end;
	put;
	put	'''200.'"09"x'''Save the Output file.';
	put	'XLApp.ActiveWorkbook.SaveAs'"09"x'oFileName , oFileType';
	put;
	put	'''800.	System Objects truncation.';
	put	'XLApp.WorkBooks.Close';
	put	'XLApp.Quit';
	put	'set oFileType'"09"x'='"09"x'nothing';
	put	'set oFileName'"09"x'='"09"x'nothing';
	put	'set XLSheet'"09"x'='"09"x'nothing';
	put	'set XLBook'"09"x'='"09"x'nothing';
	put	'set XLApp'"09"x'='"09"x'nothing';
run;

%*700.	Execute the script.;
%sysexec	cscript %qsysfunc(quote(&delscript.)) //B //nologo & exit;

%*900.	Purge.;

%EndOfProc:
%sysexec	del /Q %qsysfunc(quote(&delscript.)) & exit;
%mend VBS_SaveXlSheetAsOthFile;

/*--Appendix--*Begin* /
[Name in EXCEL]               [VBS/VBA ID] [File Type]
xlAddIn                                 18 Microsoft Office Excel 加载项 
xlAddIn8                                18 Excel 2007 加载项 
xlCSV                                    6 CSV 
xlCSVMac                                22 Macintosh CSV  
xlCSVMSDOS                              24 MSDOS CSV 
xlCSVWindows                            23 Windows CSV  
xlCurrentPlatformText                -4158 当前平台文本 
xlDBF2                                   7 DBF2 
xlDBF3                                   8 DBF3 
xlDBF4                                  11 DBF4 
xlDIF                                    9 DIF 
xlExcel12                               50 Excel 12 
xlExcel2                                16 Excel 2 
xlExcel2FarEast                         27 Excel2 FarEast 
xlExcel3                                29 Excel3 
xlExcel4                                33 Excel4 
xlExcel4Workbook                        35 Excel4 工作簿 
xlExcel5                                39 Excel5 
xlExcel7                                39 Excel7 
xlExcel8                                56 Excel8 
xlExcel9795                             43 Excel9795 
xlHtml                                  44 HTML 格式 
xlIntlAddIn                             26 国际加载项 
xlIntlMacro                             25 国际宏 
xlOpenXMLAddIn                          55 打开 XML 加载项 
xlOpenXMLTemplate                       54 打开 XML 模板 
xlOpenXMLTemplateMacroEnabled           53 打开启用的 XML 模板宏 
xlOpenXMLWorkbook                       51 打开 XML 工作簿 
xlOpenXMLWorkbookMacroEnabled           52 打开启用的 XML 工作簿宏 
xlSYLK                                   2 SYLK 
xlTemplate                              17 模板 
xlTemplate8                             17 模板 8 
xlTextMac                               19 Macintosh 文本 
xlTextMSDOS                             21 MSDOS 文本 
xlTextPrinter                           36 打印机文本 
xlTextWindows                           20 Windows 文本 
xlUnicodeText                           42 Unicode 文本 
xlWebArchive                            45 Web 档案 
xlWJ2WD1                                14 WJ2WD1 
xlWJ3                                   40 WJ3 
xlWJ3FJ3                                41 WJ3FJ3 
xlWK1                                    5 WK1 
xlWK1ALL                                31 WK1ALL 
xlWK1FMT                                30 WK1FMT 
xlWK3                                   15 WK3 
xlWK3FM3                                32 WK3FM3 
xlWK4                                   38 WK4 
xlWKS                                    4 工作表 
xlWorkbookDefault                       51 默认工作簿 
xlWorkbookNormal                     -4143 常规工作簿 
xlWorks2FarEast                         28 Works2 FarEast 
xlWQ1                                   34 WQ1 
xlXMLSpreadsheet                        46 XML 电子表格
/*--Appendix--*End*/