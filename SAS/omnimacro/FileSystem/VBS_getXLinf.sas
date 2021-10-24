%macro VBS_getXLinf(
	inWorkBook	=
	,outDAT		=	_tmp_xlinf
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to load basic information of the EXCEL workbook via the facility of VB Script.								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inWorkBook	:	Input file name.																									|
|	|outDAT		:	Output dataset.																										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20140912		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180304		| Version |	1.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180502		| Version |	1.30		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Add a step to unhide the sheets before activating them, to avoid the (e)rror messages being unable to retrieve the			|
|	|      | attributes of the respective sheets.																						|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Current information for collection:																								|
|	|(01) Names of all sheets																											|
|	|(02) Length of each sheet name (this is useful when sheet name has trailing blanks)												|
|	|(03) Usged range of each sheet																										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\FileSystem"																						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|VBS_CrFn_StrLen																												|
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
%if	%length(%qsysfunc(compress(&inWorkBook.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No file is specified for investigation.;
	%goto	EndOfProc;
%end;
%if	%sysfunc(fileexist(&inWorkBook.))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Specified file [&inWorkBook.] does not exist.;
	%goto	EndOfProc;
%end;

%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))	=	0	%then	%let	outDAT	=	_tmp_xlinf;

%*013.	Define the local environment.;
%local
	L_DLM_CHR
	L_BRK_SAS
;
%*We have to set a relatively unique delimiter for parameter reading.;
%*SAS can only recognize a single character as delimiter at one time.;
%*Hence if we set multiple characters as delimiters, SAS regards each one as a separate delimiter.;
%*Below character is "Tab", which cannot be MANUALLY input as sheet name, although it is still unsafe.;
%let	L_DLM_CHR	=	9;
data _NULL_;
	call symputx("L_DLM_SAS",cats("'",put(put(&L_DLM_CHR., PIB1.), $HEX2.),"'x"),"L");
run;

%*200.	Prepare the necessary VBScript environment.;
%*We have to define the public function "StrLen" for VBScript usage.;
%*Below statement reports error when the result contains "~1", for it is interpretated as %eval operand.;
%*let	LVBS_StrLen	=	%qsysfunc(catx(\,%qsysfunc(pathname(work)),%str(xlInfStrLen.vbs)));
data _NULL_;
	call symputx("LVBS_StrLen",catx('\',pathname('work'),'xlInfStrLen.vbs'),"L");
run;
%VBS_CrFn_StrLen(VBSFile = %nrbquote(&LVBS_StrLen.))

%*210.	Prepare the alternative for sheet name length retrieval.;
%*It is found that lots of difficulties exist for the retieval of the length of a string in VBScript;
%* for mixtures of SingleByte characters and MultiByte ones.;
%*Hence this function is abandoned while we have to find an alternative: quoting the sheet names with;
%* our predefined brackets and retrieve the length quoted within the brackets through SAS.;
%let	L_BRK_SAS	=	%str(`);

%*300.	Run the VB Script to retrieve information from the EXCEL workbook.;
data %unquote(&outDAT.);
	%*010.	Initialization.;
	length
		script
		filev
		workbook
		$256
		sheet
		sheet_pre
		$256
		LenShNm
		rows
		columns
		8
	;
	script		=	catx('\',pathname('work'),'xlinf.vbs');
	filev		=	script;
	workbook	=	symget('inWorkBook');
	call symputx("delscript1",script,"L");

	%*100.	Create temporary VBScript file.;
	%* Cards are not supported by macro facility.;
	file
		dummy1
		filevar=filev
	;
	put	"Sub Include(sInstFile)";
	put	"    Dim oFSO, f, s";
	put	"    Set oFSO = CreateObject(""Scripting.FileSystemObject"")";
	put	"    Set f = oFSO.OpenTextFile(sInstFile)";
	put	"    s = f.ReadAll";
	put	"    f.Close";
	put	"    ExecuteGlobal s";
	put	"End Sub";
	put;
	put	"Include ""%nrbquote(&LVBS_StrLen.)""";
	put 'Const ' workbook=$quote1022.;
	put 'Const xlCellTypeLastCell = 11';
	put 'Set objExcel = CreateObject("Excel.Application")';
	put 'objExcel.Visible = False';
	put 'objExcel.DisplayAlerts = False';
	put 'Set objWorkbook = objExcel.Workbooks.Open(workbook)';
	put 'For Each objWorksheet in objWorkbook.Worksheets';
	put '   objWorksheet.Visible = True';
	put '   objWorksheet.Activate';
	put '   Set objRange = objWorksheet.UsedRange';
	put '   objRange.SpecialCells(xlCellTypeLastCell).Activate';
	put '   wscript.echo objExcel.ActiveCell.Row _';
	put "     & CHR(&L_DLM_CHR.) & objExcel.ActiveCell.Column _";
	put "     & CHR(&L_DLM_CHR.) & ""&L_BRK_SAS."" & objWorksheet.Name & ""&L_BRK_SAS."" _";
	put "     & CHR(&L_DLM_CHR.) & StrLen(objWorksheet.Name)";
	put '   Next';
	put 'objExcel.Quit';
	put 'set objWorkbook = nothing';
	put 'set objExcel = nothing';

	%*200.	Redirect the option "filevar=" by creating a dummy file.;
	%* This is to ensure the above file is closed for later execution.;
	filev	=	catx('\',pathname('work'),'dummy.vbs');
	call symputx("delscript2",filev,"L");
	file
		dummy1
		filevar=filev
	;
/*
	%*300.	Create the log to verify the VB Script.;
	eof		=	0;
	filev	=	script;
	infile
		dummy2
		filevar=filev
		end=eof
	;

	do _n_ = 1 by 1 while(not eof);
		input;
		putlog _n_ z4. + 1 _infile_;
	end;
*/
	%*400.	Execute the VB Script to retrieve information from the workbook.;
	filev	=	catx(' ','cscript //nologo',quote(strip(script)));
	infile
		dummy3
		pipe
		delimiter=&L_DLM_SAS.
		filevar=filev
		end=eof
		truncover
	;
	do while(not eof);
		input
			rows
			columns
			sheet_pre
			LenShNm
		;
%*		putlog	_infile_;
		%*Overwrite the value transmitted from the pipe engine.;
		LenShNm	=	length( sheet_pre ) - 2 * length( "&L_BRK_SAS." );
		sheet	=	substr( sheet_pre, length("&L_BRK_SAS.") + 1, LenShNm );
		output;
	end;
	stop;

	keep
		workbook
		sheet
		LenShNm
		rows
		columns
	;
run;

%EndOfProc:
%sysexec	del /Q %qsysfunc(quote(&delscript1.)) %qsysfunc(quote(&delscript2.)) %qsysfunc(quote(&LVBS_StrLen.)) & exit;
%mend VBS_getXLinf;