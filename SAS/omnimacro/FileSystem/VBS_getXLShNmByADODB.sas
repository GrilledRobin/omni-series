%macro VBS_getXLShNmByADODB(
	inWorkBook	=
	,outDAT		=	_tmp_xlinf
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to load basic information of the EXCEL workbook via the facility of VB Script.								|
|	|This macro can load the information even if there is no MS Office installed.														|
|	|However, the MS Office Data Connectivity Component is required to be installed instead.											|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inWorkBook	:	Input file name.																									|
|	|outDAT		:	Output dataset.																										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20140918		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
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
|	|Current information for collection:																								|
|	|(01) Names of all sheets																											|
|	|(02) Length of each sheet name (this is useful when sheet name has trailing blanks)												|
|	|(03) Usged range of each sheet																										|
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
%if	%length(%qsysfunc(compress(&inWorkBook.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No file is specified for investigation.;
	%goto	EndOfProc;
%end;
%if	%sysfunc(fileexist(&inWorkBook.))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Specified file "&inWorkBook." does not exist.;
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
		sWorkbook
		$256
		sheet
		sheet_pre
		$256
		LenShNm
		8.
	;
	script		=	catx('\',pathname('work'),'xlinf.vbs');
	filev		=	script;
	sWorkbook	=	symget('inWorkBook');
	call symputx("delscript1",script,"L");

	%*100.	Create temporary VBScript file.;
	%* Cards are not supported by macro facility.;
	file
		dummy1
		filevar=filev
	;

	put	"option explicit";
	put	"Dim objConn";
	put	"Dim objCat";
	put	"Dim tbl";
	put	"Dim iRow";
	put	"Dim sFileType";
	put	"Dim sConnString";
	put	"Dim sTableName";
	put	"Dim cLength";
	put	"Dim iTestPos";
	put	"Dim iStartpos";
	put;
	put 'Const ' sWorkbook=$quote1022.;
	put	"sFileType = Mid( sWorkbook, InStrRev(sWorkbook, ""."") + 1, Len(sWorkbook) - InStrRev(sWorkbook, ""."") )";
	put	"'Object Linking and Embedding Database";
	put	"If UCase(sFileType) = ""XLS"" Then";
	put	"sConnString = ""Provider=Microsoft.Jet.OLEDB.4.0;"" _";
	put	"              & ""Data Source="" & sWorkbook & "";"" _";
	put	"              & ""Extended Properties=Excel 8.0;""";
	put	"ElseIf UCase(sFileType) = ""XLSX"" Then";
	put	"sConnString = ""Provider=Microsoft.ACE.OLEDB.12.0;"" _";
	put	"              & ""Data Source="" & sWorkbook & "";"" _";
	put	"              & ""Extended Properties=Excel 12.0;""";
	put	"Else";
	put	"'Should there be any other file types please setup proper engine here.";
	put	"End If";
	put;
	put	"Set objConn = CreateObject(""ADODB.Connection"")";
	put	"objConn.Open sConnString";
	put	"Set objCat = CreateObject(""ADOX.Catalog"")";
	put	"Set objCat.ActiveConnection = objConn";
	put;
	put	"iRow = 1";
	put	"For Each tbl In objCat.Tables";
	put	"    sTableName = tbl.Name";
	put	"    cLength = Len(sTableName)";
	put	"    iTestPos = 0";
	put	"    iStartpos = 1";
	put	"        'Worksheet name with embedded spaces are enclosed by single quotes";
	put	"    If Left(sTableName, 1) = ""'"" And Right(sTableName, 1) = ""'"" Then";
	put	"        iTestPos = 1";
	put	"        iStartpos = 2";
	put	"    End If";
	put	"        'Worksheet names always end in the ""$"" character";
	put	"    If Mid(sTableName, cLength - iTestPos, 1) = ""$"" Then";
	put	"        wscript.echo ""&L_BRK_SAS."" & Mid(sTableName, iStartpos, cLength - (iStartpos + iTestPos)) & ""&L_BRK_SAS.""";
	put	"        iRow = iRow + 1";
	put	"    End If";
	put	"Next";
	put	"objConn.Close";
	put	"Set objCat = Nothing";
	put	"Set objConn = Nothing";

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
			sheet_pre
		;
%*		putlog	_infile_;
		%*Overwrite the value transmitted from the pipe engine.;
		LenShNm	=	length( sheet_pre ) - 2 * length( "&L_BRK_SAS." );
		sheet	=	substr( sheet_pre, length("&L_BRK_SAS.") + 1, LenShNm );
		output;
	end;
	stop;

	keep
		sWorkbook
		sheet
		LenShNm
	;
run;

%EndOfProc:
%sysexec	del /Q %qsysfunc(quote(&delscript1.)) %qsysfunc(quote(&delscript2.)) & exit;
%mend VBS_getXLShNmByADODB;