%* Retrieve the input excel information, such as number of rows and number of columns.      ;
%* This is used in "STXR_setTemplate".;


%macro STXR_getXLinf(
	inWorkBook	=
	,outDAT		=	exr_WORK._tmp_xlinf
);
%*010.	Set parameters.;
%if	%length(%qsysfunc(compress(&inWorkBook.,%str( ))))	=	0	%then %do;
	option notes;
	%put &saserror.: [&L_mcrLABEL.]The EXCEL template is not provided!;
	option nonotes;
	%goto EndOfProc;
%end;
%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))	=	0	%then	%let	outDAT	=	exr_WORK._tmp_xlinf;

%if	%sysfunc(fileexist(&inWorkBook.))	=	0	%then %do;
	option notes;
	%put &saserror.: [&L_mcrLABEL.]The EXCEL template [&inWorkBook.] does not exist!;
	option nonotes;
	%goto EndOfProc;
%end;

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
	put	"Include ""&exroot.\STXR_PubFn.vbs""";
	put 'Const ' workbook=$quote1022.;
	put 'Const xlCellTypeLastCell = 11';
	put 'Set objExcel = CreateObject("Excel.Application")';
	put 'objExcel.Visible = False';
	put 'objExcel.DisplayAlerts = False';
	put 'Set objWorkbook = objExcel.Workbooks.Open(workbook)';
	put 'For Each objWorksheet in objWorkbook.Worksheets';
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
%sysexec	del /Q %qsysfunc(quote(&delscript1.,%str(%'))) %qsysfunc(quote(&delscript2.,%str(%'))) & exit;
%mend STXR_getXLinf;

/*Original Statements:
Please find the website for more reference:
http://compgroups.net/comp.soft-sys.sas/re-count-number-with-dde-excel-2-313492/313492

%let workbook = pathToWorkbook;

filename FT15F001 temp;
data rowsInExcel(keep=workbook sheet rows);
	%*100.	Create temporary VBScript file.;
	infile FT15F001 end=eof;
	length script filevar workbook $128 sheet $16;
	script  = catx('\',pathname('work'),'rownum.vbs');
	filevar = script;
	workbook = symget('WORKBOOK');


   file dummy1 filevar=filevar;
   put 'Const ' workbook=$quote130.;
   do while(not eof);
      input;
      put _infile_;
      end;
   eof = 0;
   filevar = catx('\',pathname('work'),'dummy.vbs');
   file dummy1 filevar=filevar;
   filevar = script;
   infile dummy2 filevar=filevar end=eof;

   do _n_ = 1 by 1 while(not eof);
      input;
      putlog _n_ z4. + 1 _infile_;
      end;

   filevar = catx(' ','cscript //nologo',quote(strip(script)));
   infile dummy3 pipe filevar=filevar end=eof truncover;
   do while(not eof);
      input rows sheet &$32.;
      putlog _infile_;
      output;
      end;
   stop;
parmcards4;
Const xlCellTypeLastCell = 11
Set objExcel = CreateObject("Excel.Application")
objExcel.Visible = False
objExcel.DisplayAlerts = False
Set objWorkbook = objExcel.Workbooks.Open(workbook)
For Each objWorksheet in objWorkbook.Worksheets
   objWorksheet.Activate
   Set objRange = objWorksheet.UsedRange
   objRange.SpecialCells(xlCellTypeLastCell).Activate
   wscript.echo objExcel.ActiveCell.Row & " " & objWorksheet.Name
   Next
objExcel.Quit
;;;;
   run;
proc print;
   run;


*/