%macro DBcr_GetInputForDataFlow(
	inETLFlow
	,outETLFlow	=	WORK.__ETL_InputOfDataFlow__
	,C_FILENAME	=	C_FILENAME
	,C_FlowType	=	C_FlowType
	,KeyOfFlow	=	C_PGMNAME C_FlowType C_FILENAME
	,procLIB	=	WORK
	,fDebug		=	0
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to retrieve a subset of the provided Data Flow, which contains all its input files.							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inETLFlow	:	The input ETL meta table which stores the data flow of all projects.												|
|	|outETLFlow	:	The subset of the ETL meta table which stores the least necessary data flow to generate the listed files.			|
|	|				Default : [WORK.__ETL_InputOfDataFlow__]																			|
|	|C_FILENAME	:	The variable in the ETL meta table that denotes to the full path of the files, including the file extension.		|
|	|				Only one valid SAS dataset variable name is accepted.																|
|	|				Default : [C_FILENAME]																								|
|	|C_FlowType	:	The variable in the ETL meta table that denotes to the flow type of current data file, [INPUT] or [OUTPUT].			|
|	|				Only one valid SAS dataset variable name is accepted.																|
|	|				Default : [C_FlowType]																								|
|	|KeyOfFlow	:	The variables in the ETL meta table that determine the unique records.												|
|	|				If many variable names are provided, please use WHITE SPACES to split them.											|
|	|				Default : [C_PGMNAME C_FlowType C_FILENAME]																			|
|	|procLIB	:	The working library.																								|
|	|				Default : [WORK]																									|
|	|fDebug		:	The switch of Debug Mode. Valid values are [0] or [1].																|
|	|				Default: [0]																										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20181118		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
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
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ErrMcr																															|
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
%if	%length(%qsysfunc(compress(&inETLFlow.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.][inETLFlow] is not provided!;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&outETLFlow.,%str( ))))	=	0	%then	%let	outETLFlow	=	WORK.__ETL_InputOfDataFlow__;
%if	%length(%qsysfunc(compress(&C_FILENAME.,%str( ))))	=	0	%then	%let	C_FILENAME	=	C_FILENAME;
%if	%length(%qsysfunc(compress(&C_FlowType.,%str( ))))	=	0	%then	%let	C_FlowType	=	C_FlowType;
%if	%length(%qsysfunc(compress(&KeyOfFlow.,%str( ))))	=	0	%then	%let	KeyOfFlow	=	C_PGMNAME C_FlowType C_FILENAME;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))		=	0	%then	%let	procLIB		=	WORK;
%if	%length(%qsysfunc(compress(&fDebug.,%str( ))))		=	0	%then	%let	fDebug		=	0;
%if	&fDebug.^=	0	%then	%let	fDebug		=	1;

%*013.	Define the global environment.;

%*014.	Define the local environment.;
%local
	OptNotes	OptSource	OptSource2	OptMLogic	OptSymGen	OptMPrint	OptInOper
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

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in traditional SAS syntax colors.;
%macro dummy; %mend dummy;

%*049.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*All input values.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [inETLFlow=&inETLFlow.];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [outETLFlow=&outETLFlow.];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [C_FILENAME=&C_FILENAME.];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [C_FlowType=&C_FlowType.];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [KeyOfFlow=&KeyOfFlow.];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [procLIB=&procLIB.];
%end;

%*100.	Retrieve the first occurance of all files and pick them up if they are [INPUT].;
%*110.	Lower the case of the file names for further sorting.;
data &procLIB..__GIFDF_inETLflow;
	%*100.	Set the source.;
	set	%unquote(&inETLFlow.);

	%*200.	Create temporary fields.;
	length
		___fname	$512
	;
	___fname	=	lowcase(&C_FILENAME.);
run;

%*130.	Sort the meta table for further process.;
proc sort
	data=&procLIB..__GIFDF_inETLflow
;
	by	___fname	&KeyOfFlow.;
run;

%*150.	Identification.;
data &procLIB..__GIFDF_input_all;
	%*100.	Set the source.;
	set	&procLIB..__GIFDF_inETLflow;
	by	___fname	&KeyOfFlow.;

	%*500.	Only when the first occurance of the file is [INPUT], should it be captured as result.;
	if	first.___fname	and	upcase(&C_FlowType.)	=	"INPUT";

	%*900.	Purge.;
	drop
		___fname
	;
run;

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
%mend DBcr_GetInputForDataFlow;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvOp"
		"D:\SAS\omnimacro\AdvDB"
		"D:\SAS\omnimacro\FileSystem"
	)
	mautosource
;
%let	currDate	=	mdy(11,7,2018);

PROC IMPORT
	OUT			=	testRaw
	DATAFILE	=	"D:\SAS\omnimacro\AdvDB\TestETL.xlsx"
	DBMS		=	EXCEL
	REPLACE
;
	SHEET		=	"DataFlow$";
	GETNAMES	=	YES;
	MIXED		=	NO;
	SCANTEXT	=	YES;
	USEDATE		=	YES;
	SCANTIME	=	YES;
RUN;

data test;
	set testRaw;
	length	pgm_full	$512;
	pgm_full	=	catx( "%OSDirDlm" , Program_Location , Program_Name );
run;

%DBcr_GetInputForDataFlow(
	test
	,outETLFlow	=	WORK.__ETL_InputOfDataFlow__
	,C_FILENAME	=	Data_Name
	,C_FlowType	=	Flow_Type
	,KeyOfFlow	=	pgm_full Flow_Type Data_Name
	,procLIB	=	WORK
	,fDebug		=	1
)

%*Output.;

/*-Notes- -End-*/