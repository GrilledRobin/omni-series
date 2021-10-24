%macro VBS_SaveRptRangeAsPic(
	inXLFile	=
	,inSheet	=
	,inRange	=
	,outXLFile	=
	,outSheet	=
	,FHighRes	=	1
	,VBSFile	=
	,DelVBSFile	=	Yes
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inXLFile	:	The input report file.																								|
|	|inSheet	:	The sheet which contains the specific report range.																	|
|	|inRange	:	The range to be saved as picture.																					|
|	|outXLFile	:	The ourput file.																									|
|	|outSheet	:	The output sheet.																									|
|	|FHighRes	:	Flag of whether the output image should be of High Resolution.														|
|	|VBSFile	:	The VBS file for internal use.																						|
|	|DelVBSFile	:	Whether the VBS file should be deleted.																				|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20140329		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
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
%local
	L_mcrLABEL
	LO_xwait
	LO_xsync
	inXLPath
	inXLName
	inXLExt
	tmpInXL
	outXLPath
	outXLName
	outXLExt
	tmpOutXL
	VBSVol
	VBSPath
	VBSName
	f_DelVBSFile
;
%let	L_mcrLABEL	=	&sysMacroName.;
%if	%sysfunc(getoption(xwait))	=	XWAIT	%then	%let	LO_xwait	=	1;
%if	%sysfunc(getoption(xsync))	=	XSYNC	%then	%let	LO_xsync	=	1;
options
	noxwait
	xsync
;

%if	%length(%qsysfunc(compress(&outXLFile.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No output file is defined, program will terminate immediately!;
	%goto	EndOfProc;
%end;
%if	%length(%qsysfunc(compress(&inXLFile.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No input file is defined, program will terminate immediately!;
	%goto	EndOfProc;
%end;
%if	%length(%qsysfunc(compress(&inSheet.,%str( ))))		=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No input sheet is defined, program will terminate immediately!;
	%goto	EndOfProc;
%end;
%if	%length(%qsysfunc(compress(&outSheet.,%str( ))))	=	0	%then %do;
	%let	outSheet	=	&inSheet.;
%end;
%if	%length(%qsysfunc(compress(&inRange.,%str( ))))		=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No input range is defined, program will terminate immediately!;
	%goto	EndOfProc;
%end;

%let	tmpInXL		=	%qscan(&inXLFile.,-1,%str(\));
%let	inXLExt		=	%qscan(&tmpInXL.,-1,.);
%let	inXLName	=	%qsubstr(&tmpInXL.,1,%length(&tmpInXL.)-%length(&inXLExt.)-1);
%let	inXLPath	=	%qsubstr(&inXLFile.,1,%length(&inXLFile.)-%length(&tmpInXL.));

%let	tmpOutXL	=	%qscan(&outXLFile.,-1,%str(\));
%let	outXLExt	=	%qscan(&tmpOutXL.,-1,.);
%let	outXLName	=	%qsubstr(&tmpOutXL.,1,%length(&tmpOutXL.)-%length(&outXLExt.)-1);
%let	outXLPath	=	%qsubstr(&outXLFile.,1,%length(&outXLFile.)-%length(&tmpOutXL.));
%if	%length(%qsysfunc(compress(&FHighRes.,%str( ))))	=	0	%then %do;
	%let	FHighRes	=	1;
%end;
%if	%bquote(&FHighRes.)	^=	1	%then %do;
	%let	FHighRes	=	0;
%end;
%if	%length(%qsysfunc(compress(&VBSFile.,%str( ))))		=	0	%then %do;
	%let	VBSFile	=	&inXLPath.SaveAsPic.vbs;
%end;
%let	VBSName	=	%qscan(&VBSFile.,-1,%str(\));
%let	VBSPath	=	%qsubstr(&VBSFile.,1,%length(&VBSFile.)-%length(&VBSName.));
%let	VBSVol	=	%qscan(&VBSFile.,1,%str(:));

%let	f_DelVBSFile	=	0;
%if		%index(%upcase(&DelVBSFile.),Y)	=	1
	or	%index(%upcase(&DelVBSFile.),T)	=	1
	or	%index(%upcase(&DelVBSFile.),1)	=	1
	%then %do;
	%let	f_DelVBSFile	=	1;
%end;

%*100.	Generate VB Script.;
data _NULL_;
	file "&VBSFile.";

	put	'''001.	System Initiation.';
	put	'Dim'"09"x'XLApp,XLBook,XLSheet,XLRng,XLChart';
	put	'Set'"09"x'XLApp'"09"x'='"09"x'CreateObject("Excel.Application")';
	put	'XLApp.Visible'"09"x'='"09"x'False';
	put	'XLApp.DisplayAlerts'"09"x'='"09"x'False';
	put;
	put	'InFdrName'"09"x'='"09"x'"'"&inXLPath."'"';
	put	'InFlName'"09"x'='"09"x'"'"&inXLName."'"';
	put	'InExt'"09"x"09"x'='"09"x'"'"&inXLExt."'"';
	put	'InShName'"09"x'='"09"x'"'"&inSheet."'"';
	put	'InShRng'"09"x"09"x'='"09"x'"'"&inRange."'"';
	put	'OutFdrName'"09"x'='"09"x'"'"&outXLPath."'"';
	put	'OutFlName'"09"x'='"09"x'"'"&outXLName."'"';
	put	'OutShName'"09"x'='"09"x'"'"&outSheet."'"';
	put	'OutExt'"09"x"09"x'='"09"x'"'"&outXLExt."'" ''bmp,jpg,gif,png';
	put	"FHighRes"'09'x'='"09"x"&FHighRes.";
	put;
	put	'''100.'"09"x'Source Retrieval.';
	put	'XLApp.Workbooks.Open InFdrName & InFlName & "." & InExt';
	put	'XLApp.ActiveWorkbook.Sheets(InShName).Activate';
	put	'Set'"09"x'XLRng'"09"x'='"09"x'XLApp.ActiveSheet.Range(InShRng)';
	put	'XLRng.CopyPicture 1,-4147';
	put;
	put	'''200.'"09"x'Create Output workbook.';
	put	'Set'"09"x'XLBook'"09"x'='"09"x'XLApp.Workbooks.Add';
	put	'Set'"09"x'XLSheet'"09"x'='"09"x'XLBook.Worksheets(1)';
	put	'Set'"09"x'XLDel2'"09"x'='"09"x'XLBook.Worksheets(2)';
	put	'Set'"09"x'XLDel3'"09"x'='"09"x'XLBook.Worksheets(3)';
	put	'Set'"09"x'XLChart'"09"x'='"09"x'XLSheet.ChartObjects.Add(0, 0, XLRng.Width, XLRng.Height)';
	put;
	put	'''300.'"09"x'Output.';
	put	'if	FHighRes = 1 then';
	put	"09"x'OutExt'"09"x'='"09"x'"xls"';
	put;
	put	"09"x'''Clogging sheets truncation.';
	put	"09"x'XLDel2.Delete';
	put	"09"x'XLDel3.Delete';
	put;
	put	"09"x'''Paste picture to the given sheet.';
	put	"09"x'XLSheet.Activate';
	put	"09"x'XLSheet.Name'"09"x'='"09"x'OutShName';
	put	"09"x'XLSheet.Paste';
	put;
	put	"09"x'''Save the Output workbook.';
	put	"09"x'XLBook.SaveAs	OutFdrName & OutFlName & "." & OutExt ,-4143';
	put	'else';
	put	"09"x'''Set Print Quality for Printer, this should be capped at 1200';
	put	"09"x'XLChart.Chart.PageSetup.PrintQuality'"09"x'='"09"x'1200';
	put;
	put	"09"x'''Paste picture to the given chart.';
	put	"09"x'XLChart.Chart.Paste';
	put;
	put	"09"x'''Save the Output file.';
	put	"09"x'XLChart.Chart.Export OutFdrName & OutFlName & "." & OutExt ,OutExt';
	put	'end if';
	put;
	put	'''800.	System Objects truncation.';
	put	'XLApp.WorkBooks.Close';
	put	'XLApp.Quit';
	put	'set XLChart'"09"x'='"09"x'nothing';
	put	'set XLRng'"09"x'='"09"x'nothing';
	put	'set XLSheet'"09"x'='"09"x'nothing';
	put	'set XLBook'"09"x'='"09"x'nothing';
	put	'set XLApp'"09"x'='"09"x'nothing';
run;

%*700.	Execute the script.;
x	"&VBSVol.:";
x	"cd &VBSPath.";
x	"cscript &VBSName. //B //nologo";

%*800.	Post process.;
%if	&f_DelVBSFile.	=	1	%then %do;
	x	"&VBSVol.:";
	x	"cd &VBSPath.";
	x	"del /Q ""&VBSName.""";
%end;

%*900.	Restore system parameters.;
%if	&LO_xwait.	=	1	%then %do;
	options	xwait;
%end;
%else %do;
	options	noxwait;
%end;
%if	&LO_xsync.	=	1	%then %do;
	options	xsync;
%end;
%else %do;
	options	noxsync;
%end;

%EndOfProc:
%mend VBS_SaveRptRangeAsPic;

/*
This macro is to interact with MS EXCEL to save the specific range of the given report to a picture in a separate EXCEL workbook.
*/