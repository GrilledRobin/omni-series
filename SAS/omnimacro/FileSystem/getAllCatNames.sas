%macro getAllCatNames(
	outDAT		=	WORK.__CatNames_Mem__
	,procLIB	=	WORK
	,fDebug		=	0
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to search for all members together with their physical locations from all Concatenated Catalogs, which are	|
|	| created by the statement [CATNAME].																								|
|	|FEATURES:																															|
|	|[1] This macro looks up in the LOG file for the necessary information, since SAS version 9.4 and before do not have system storage	|
|	|     for the concatenated catalog details, esp. the physical location of its members.												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|[Required] Overall Process:																										|
|	|___________________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	|[Required] Output:																													|
|	|___________________________________________________________________________________________________________________________________|
|	|outDAT		:	The output result storing the details of the members within the catalogs found in this function						|
|	|				Default: [WORK.__CatNames_Mem__]																					|
|	|___________________________________________________________________________________________________________________________________|
|	|[Required] Common Operations:																										|
|	|___________________________________________________________________________________________________________________________________|
|	|procLIB	:	The working library.																								|
|	|				Default: [WORK]																										|
|	|fDebug		:	The switch of Debug Mode. Valid values are [0] or [1].																|
|	|				Default: [0]																										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20181124		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Please find the attachments for examples.																							|
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
%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))	=	0	%then	%let	outDAT		=	WORK.__CatNames_Mem__;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))	=	0	%then	%let	procLIB		=	WORK;
%if	%length(%qsysfunc(compress(&fDebug.,%str( ))))	=	0	%then	%let	fDebug		=	0;
%if	&fDebug.^=	0	%then	%let	fDebug		=	1;

%*013.	Define the local environment.;
%local
	OptNotes	OptSource	OptSource2	OptMLogic	OptSymGen	OptMPrint	OptInOper
	tmplog		rc			filrf
;

%*016.	Switch off the system options to reduce the LOG size.;
%if %sysfunc(getoption( notes ))		=	NOTES		%then	%let	OptNotes	=	1;	%else	%let	OptNotes	=	0;
%if %sysfunc(getoption( source ))		=	SOURCE		%then	%let	OptSource	=	1;	%else	%let	OptSource	=	0;
%if %sysfunc(getoption( source2 ))		=	SOURCE2		%then	%let	OptSource2	=	1;	%else	%let	OptSource2	=	0;
%if %sysfunc(getoption( mlogic ))		=	MLOGIC		%then	%let	OptMLogic	=	1;	%else	%let	OptMLogic	=	0;
%if %sysfunc(getoption( symbolgen ))	=	SYMBOLGEN	%then	%let	OptSymGen	=	1;	%else	%let	OptSymGen	=	0;
%if %sysfunc(getoption( mprint ))		=	MPRINT		%then	%let	OptMPrint	=	1;	%else	%let	OptMPrint	=	0;
%if %sysfunc(getoption( minoperator ))	=	MINOPERATOR	%then	%let	OptInOper	=	1;	%else	%let	OptInOper	=	0;
%*The default value of the system option [MINDELIMITER] is WHITE SPACE, given the option [MINOPERATOR] is on.;
%if	&fDebug.	=	0	%then %do;
options nonotes nosource nosource2 nomlogic nosymbolgen nomprint minoperator;
%end;

%*018.	Define the global environment.;

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in traditional SAS syntax colors.;
%macro dummy; %mend dummy;

%*099.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*100.	All input values.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [outDAT=&outDAT.];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [procLIB=&procLIB.];
%end;

%*100.	Redirect the log for this specific operation.;
%*110.	Setup the temporary file in the WORK library to contain the temporary log file.;
%let	tmplog	=	myIntLog;
%let	rc		=	%sysfunc(filename(tmplog,%qsysfunc(pathname(work))));

%*120.	Assign the FileRef for writing the text messages.;
%let	filrf	=	myTmpLog;
%let	rc		=	%sysfunc(filename( filrf , tmplog.txt , , , &tmplog. ));

%*150.	Point the log to the temporary file.;
proc printto log=&filrf. new; quit;

%*200.	Print all the concatenated catalogs into the temporary log file.;
options	notes;
catname	_all_	list;

%*290.	Purge.;
proc printto log=log; quit;
%if	&fDebug.	=	0	%then %do;
options nonotes;
%end;

%*300.	Resolve the temporary log.;
data &procLIB..__CatNames_in__;
	%*010.	Open the link to the file.;
	infile	&filrf.;

	%*050.	Create fields.;
	length
		CATLIB	$8
		CATNAME	$32
		KLEVEL	8
		LIBNAME	$8
		MEMNAME	$32
		LEVEL	8
		ENGINE	$8
		PATH	$1024
		PATHLEN	8
		N_C_REC	8
		N_L_REC	8
	;
	retain;
	retain	prxblnk	prxBgn	prxNlvl	prxlvl	prxmbr	prxEng	prxPath	prxBrk	0;
	if	_N_	=	1	then do;
		call missing( CATLIB , CATNAME );
	end;
	if	prxblnk	=	0	then	prxblnk	=	prxparse('/^\W*$/ismx');

	%*080.	Input the line.;
	input;
	if	prxmatch( prxblnk , _infile_ )	then do;
		call missing( CATLIB , CATNAME );
		goto	EndOfRec;
	end;

	%*100.	Setup the matching rules.;
	%*IMPORTANT: The number of [6] is the length of the string: [NOTE: ];
	%*101.	Locate the beginning of the catalog.;
	if	prxBgn	=	0	then	prxBgn	=	prxparse('s/^NOTE:.+?=\s*([[:alpha:]_]\w{0,7})\.([[:alpha:]_]\w{0,31})\s*$/\1.\2/ix');

	%*110.	Determine the number of levels.;
	if	prxNlvl	=	0	then	prxNlvl	=	prxparse('s/^\s{6}.+?=\s*(\d+)\s*$/\1/ix');

	%*120.	Determine current level.;
	if	prxlvl	=	0	then	prxlvl	=	prxparse('s/^\s{6}\s+-\D+(\d+)-\s*$/\1/ix');

	%*130.	Determine current member.;
	if	prxmbr	=	0	then	prxmbr	=	prxparse('s/^\s{6}.+?=\s*([[:alpha:]_]\w{0,7})\.([[:alpha:]_]\w{0,31})\s*$/\1.\2/ix');

	%*140.	Determine the engine of current member.;
	if	prxEng	=	0	then	prxEng	=	prxparse('s/^\s{6}.+?=\s*(.+?)\s*$/\1/ix');

	%*150.	Determine the path name of current member.;
	if	prxPath	=	0	then	prxPath	=	prxparse('s/^\s{6}.+?=\s*(.+)$/\1/ix');

	%*190.	Mark the break line of the note.;
	if	prxBrk	=	0	then	prxBrk	=	prxparse('/^\d+/ix');
	if	prxmatch( prxBrk , _infile_ )	then do;
		call missing( CATLIB , CATNAME );
		goto	EndOfRec;
	end;

	%*200.	Identify all the lines.;
	%*201.	Identify the beginning of the concatenated catalog.;
	if	prxmatch( prxBgn , _infile_ )	then do;
		CATLIB	=	scan( prxchange( prxBgn , 1 , _infile_ ) , 1 , '.' );
		CATNAME	=	scan( prxchange( prxBgn , 1 , _infile_ ) , -1 , '.' );
		N_C_REC	=	0;
		call missing( KLEVEL , LIBNAME , MEMNAME , LEVEL , ENGINE , PATH , PATHLEN , N_L_REC );
	end;

	%*205.	Mark the lines for current concatenated catalog and skip if current line has no relation to current concatenated catalog.;
	if	missing(CATLIB)	=	0	and	missing(CATNAME)	=	0	then do;
		N_C_REC	+	1;
	end;
	else do;
		goto	EndOfRec;
	end;

	%*210.	Identify the number of levels.;
	if	N_C_REC	=	2	and	prxmatch( prxNlvl , _infile_ )	then do;
		KLEVEL	=	input( strip( prxchange( prxNlvl , 1 , _infile_ ) ) , best12. );
	end;

	%*220.	Identify current level.;
	if	prxmatch( prxlvl , _infile_ )	then do;
		LEVEL	=	input( strip( prxchange( prxlvl , 1 , _infile_ ) ) , best12. );
		N_L_REC	=	0;
		call missing( LIBNAME , MEMNAME , ENGINE , PATH , PATHLEN );
	end;
	N_L_REC	+	1;

	%*230.	Identify current member.;
	if	N_L_REC	=	2	and	prxmatch( prxmbr , _infile_ )	then do;
		LIBNAME	=	scan( prxchange( prxmbr , 1 , _infile_ ) , 1 , '.' );
		MEMNAME	=	scan( prxchange( prxmbr , 1 , _infile_ ) , -1 , '.' );
	end;

	%*240.	Identify the engine of current member.;
	if	N_L_REC	=	3	and	prxmatch( prxEng , _infile_ )	then do;
		ENGINE	=	prxchange( prxEng , 1 , _infile_ );
	end;

	%*250.	Identify the path name of current member.;
	if	N_L_REC	=	4	and	prxmatch( prxPath , _infile_ )	then do;
		PATH	=	prxchange( prxPath , 1 , _infile_ );
		%*In case the path name is too long to make the log extend to the next lines, we will not trim the string, for the path name may contain white spaces.;
		PATHLEN	=	lengthc( prxchange( prxPath , 1 , _infile_ ) );
	end;

	%*255.	Extend the string of path name if there are extra lines.;
	if	N_L_REC	>	4	then do;
		%*We cannot use [CATS] for the same reason as above.;
		PATH	=	substr( PATH , 1 , PATHLEN )||substr( _infile_ , 7 );
		PATHLEN	=	sum( PATHLEN , lengthc( substr( _infile_ , 7 ) ) );
	end;

	%*890.	Mark the end of the logic implementation.;
	EndOfRec:
run;

%*800.	Output the search result.;
%*810.	Sort the data.;
proc sort
	data=&procLIB..__CatNames_in__
	out=&procLIB..__CatNames_srt__
;
	where	missing(CATLIB)	=	0	and	missing(CATNAME)	=	0	and	missing(LEVEL)	=	0;
	by	CATLIB	CATNAME	LEVEL	N_C_REC	N_L_REC;
run;

%*850.	Output.;
data %unquote(&outDAT.);
	%*100.	Set the source.;
	set	&procLIB..__CatNames_srt__;
	by	CATLIB	CATNAME	LEVEL	N_C_REC	N_L_REC;

	%*900.	Purge.;
	if	last.LEVEL;
	drop	N_C_REC	N_L_REC	prx:;
run;

%*900.	Purge.;
%let	rc		=	%sysfunc(filename( filrf ));

%EndOfProc:
%*Restore the system options.;
options
%if	&OptNotes.		=	1	%then %do;	NOTES		%end;	%else %do;	NONOTES			%end;
%if	&OptSource.		=	1	%then %do;	SOURCE		%end;	%else %do;	NOSOURCE		%end;
%if	&OptSource2.	=	1	%then %do;	SOURCE2		%end;	%else %do;	NOSOURCE2		%end;
%if	&OptMLogic.		=	1	%then %do;	MLOGIC		%end;	%else %do;	NOMLOGIC		%end;
%if	&OptSymGen.		=	1	%then %do;	SYMBOLGEN	%end;	%else %do;	NOSYMBOLGEN		%end;
%if	&OptMPrint.		=	1	%then %do;	MPRINT		%end;	%else %do;	NOMPRINT		%end;
%if	&OptInOper.		=	1	%then %do;	MINOPERATOR	%end;	%else %do;	NOMINOPERATOR	%end;
;
%mend getAllCatNames;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\FileSystem"
	)
	mautosource
;

%*100.	Prepare the concatenated catalog to test the retrival.;
%mkdir(E:\test\cat1)
%mkdir(E:\test\This is a super long folder name that is used to test the case for the retrieval of physical path names of the concatenated catalog)
libname templib 'E:\test\cat1';
libname permlib 'E:\test\This is a super long folder name that is used to test the case for the retrieval of physical path names of the concatenated catalog';
options mstored sasmstore=templib;

%macro HelloWorld1() / store source;
  data _null_;
    put "Hello, World! &sysmacroname";
  run;
%mend;

%macro HelloWorld2() / store source;
  data _null_;
    put "Hello, World! &sysmacroname";
  run;
%mend;

proc catalog cat=templib.sasmacr ;
   copy out=permlib.cat1;
      select helloworld1 /et=macro;
   run;
   copy out=permlib.cat2;
      select helloworld2 /et=macro;
   run;
quit;

options mstored sasmstore=permlib;
CATNAME permlib.sasmacr
  (permlib.cat1 (ACCESS=READONLY)
   permlib.cat2 (ACCESS=READONLY)
);

%*200.	Invocation.;
%getAllCatNames
%*Finish the above statement.;

/*-Notes- -End-*/