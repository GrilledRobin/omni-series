%macro DBcr_GetRelatedDataFlow(
	FileList
	,inETLFlow	=	WORK.__ETLcfg_Dats__
	,outETLFlow	=	WORK.__ETL_RelatedDataFlow__
	,inValType	=	V
	,C_FILENAME	=	C_FILENAME
	,C_PGMNAME	=	C_PGMNAME
	,C_FlowType	=	C_FlowType
	,FlowByVar	=	C_PGMNAME
	,KeyOfFlow	=	C_PGMNAME C_FlowType C_FILENAME
	,procLIB	=	WORK
	,ListDlm	=	%str(|)
	,Direction	=	SUBSEQUENT
	,fDebug		=	0
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to retrieve the least necessary subset of the provided Data Flow for the provided files on below occasions:	|
|	|[1] All processes that finally generate the provided files.																		|
|	|[2] All processes that are affected by the provided files as input.																|
|	|[3] All processes that are combined by occassions of [1] and [2].																	|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|FileList	:	The list of files to lookup in the ETL meta table.																	|
|	|inETLFlow	:	The input ETL meta table which stores the data flow of all projects.												|
|	|				Default : [WORK.__ETLcfg_Dats__]																					|
|	|outETLFlow	:	The subset of the ETL meta table which stores the least necessary data flow to generate the listed files.			|
|	|				Default : [WORK.__ETL_RelatedDataFlow__]																			|
|	|inValType	:	The type of [FileList] that should be searched in the ETL meta table.												|
|	|				[V] : The value is provided as character strings.																	|
|	|				[D] : The values reside in the provided dataset.																	|
|	|				Default : [V]																										|
|	|C_FILENAME	:	The variable in the ETL meta table that denotes to the full path of the files, including the file extension.		|
|	|				Only one valid SAS dataset variable name is accepted.																|
|	|				Default : [C_FILENAME]																								|
|	|C_PGMNAME	:	The variable in the ETL meta table that denotes to the full path of the programs, including the file extension.		|
|	|				Only one valid SAS dataset variable name is accepted.																|
|	|				Default : [C_PGMNAME]																								|
|	|C_FlowType	:	The variable in the ETL meta table that denotes to the flow type of current data file, [INPUT] or [OUTPUT].			|
|	|				Only one valid SAS dataset variable name is accepted.																|
|	|				Default : [C_FlowType]																								|
|	|FlowByVar	:	The variable list in the ETL meta table that determines the sequence to execute the programs in the work flow.		|
|	|				If many variable names are provided, please use WHITE SPACES to split them.											|
|	|				Default : [C_PGMNAME]																								|
|	|KeyOfFlow	:	The variables in the ETL meta table that determine the unique records.												|
|	|				If many variable names are provided, please use WHITE SPACES to split them.											|
|	|				Default : [C_PGMNAME C_FlowType C_FILENAME]																			|
|	|procLIB	:	The working library.																								|
|	|				Default : [WORK]																									|
|	|ListDlm	:	The delimiter character that splits the [FileList] into various members.											|
|	|				Only one single character is accepted.																				|
|	|				Default : [|]																										|
|	|Direction	:	The direction to search for the related steps in the entire ETL process.											|
|	|				Valid values for forward search are: [FORWARD|SUBSEQUENT|NEXT]														|
|	|				Valid values for backward search are: [BACKWARD|PRIOR|PREVIOUS]														|
|	|				Valid values for full search are: [BOTH|FULL]																		|
|	|				Default : [SUBSEQUENT]																								|
|	|fDebug		:	The switch of Debug Mode. Valid values are [0] or [1].																|
|	|				Default: [0]																										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20181110		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
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
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvDB"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|DBcr_GetPriorDataFlow																											|
|	|	|DBcr_GetSubseqDataFlow																											|
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
%if	%length(%qsysfunc(compress(&FileList.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.][FileList] is not provided!;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&inETLFlow.,%str( ))))	=	0	%then	%let	inETLFlow	=	WORK.__ETLcfg_Dats__;
%if	%length(%qsysfunc(compress(&outETLFlow.,%str( ))))	=	0	%then	%let	outETLFlow	=	WORK.__ETL_RelatedDataFlow__;

%if	%length(%qsysfunc(compress(&inValType.,%str( ))))	=	0	%then	%let	inValType	=	V;
%let	inValType	=	%qsubstr(%qupcase(&inValType.),1,1);
%if	&inValType.	^=	V	and	&inValType.	^=	D	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]Unknown data type [inValType=&inValType.]! Only [V] or [D] is valid!;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&C_FILENAME.,%str( ))))	=	0	%then	%let	C_FILENAME	=	C_FILENAME;
%if	%length(%qsysfunc(compress(&C_PGMNAME.,%str( ))))	=	0	%then	%let	C_PGMNAME	=	C_PGMNAME;
%if	%length(%qsysfunc(compress(&C_FlowType.,%str( ))))	=	0	%then	%let	C_FlowType	=	C_FlowType;
%if	%length(%qsysfunc(compress(&FlowByVar.,%str( ))))	=	0	%then	%let	FlowByVar	=	C_PGMNAME;
%if	%length(%qsysfunc(compress(&KeyOfFlow.,%str( ))))	=	0	%then	%let	KeyOfFlow	=	C_PGMNAME C_FlowType C_FILENAME;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))		=	0	%then	%let	procLIB		=	WORK;
%if	%length(%qsysfunc(compress(&ListDlm.,%str( ))))		=	0	%then	%let	ListDlm		=	%str(|);

%if	%length(%qsysfunc(compress(&Direction.,%str( ))))	=	0	%then	%let	Direction	=	SUBSEQUENT;
%let	Direction	=	%qsysfunc(strip( %qupcase( &Direction. ) ));
%if	%index( #FORWARD#SUBSEQUENT#NEXT#BACKWARD#PRIOR#PREVIOUS#BOTH#FULL# , #&Direction.# )	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.][Direction=&Direction.] is not accepted! see the dictionary for the valid values!;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&fDebug.,%str( ))))		=	0	%then	%let	fDebug		=	0;
%if	&fDebug.^=	0	%then	%let	fDebug		=	1;

%*013.	Define the global environment.;

%*014.	Define the local environment.;
%local
	OptNotes	OptSource	OptSource2	OptMLogic	OptSymGen	OptMPrint	OptInOper
	f_Forward	f_Backward	f_BothDir	e_Forward	e_Backward
;
%if	%index( #FORWARD#SUBSEQUENT#NEXT# , #&Direction.# )	%then %do;
	%let	f_Forward	=	1;
%end;
%else %do;
	%let	f_Forward	=	0;
%end;
%if	%index( #BACKWARD#PRIOR#PREVIOUS# , #&Direction.# )	%then %do;
	%let	f_Backward	=	1;
%end;
%else %do;
	%let	f_Backward	=	0;
%end;
%if	%index( #BOTH#FULL# , #&Direction.# )	%then %do;
	%let	f_BothDir	=	1;
%end;
%else %do;
	%let	f_BothDir	=	0;
%end;

%let	e_Forward	=	0;
%let	e_Backward	=	0;

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
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [FileList=&FileList.];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [inETLFlow=&inETLFlow.];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [outETLFlow=&outETLFlow.];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [inValType=&inValType.];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [C_FILENAME=&C_FILENAME.];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [C_PGMNAME=&C_PGMNAME.];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [C_FlowType=&C_FlowType.];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [FlowByVar=&FlowByVar.];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [KeyOfFlow=&KeyOfFlow.];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [procLIB=&procLIB.];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [Direction=&Direction.];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [ListDlm=&ListDlm.];
%end;

%*090.	Delete the interim datasets at first.;
%if	%sysfunc(exist( &procLIB..__GRDF_Backward__ ))	%then %do;
	proc datasets lib=&procLIB. nolist; delete __GRDF_Backward__; run;quit;
%end;
%if	%sysfunc(exist( &procLIB..__GRDF_Forward__ ))	%then %do;
	proc datasets lib=&procLIB. nolist; delete __GRDF_Forward__; run;quit;
%end;

%*100.	Search for the prior processes if required.;
%if	&f_Backward.	=	1	or	&f_BothDir.	=	1	%then %do;
	%*100.	Searching.;
	%DBcr_GetPriorDataFlow(
		&FileList.
		,inETLFlow	=	&inETLFlow.
		,outETLFlow	=	&procLIB..__GRDF_Backward__
		,inValType	=	&inValType.
		,C_FILENAME	=	&C_FILENAME.
		,C_PGMNAME	=	&C_PGMNAME.
		,C_FlowType	=	&C_FlowType.
		,FlowByVar	=	&FlowByVar.
		,KeyOfFlow	=	&KeyOfFlow.
		,procLIB	=	&procLIB.
		,ListDlm	=	&ListDlm.
		,mNest		=	0
		,fDebug		=	&fDebug.
	)

	%*900.	Mark whether the search is complete.;
	%let	e_Backward	=	%sysfunc(exist( &procLIB..__GRDF_Backward__ ));
%end;

%*200.	Search for the subsequent processes if required.;
%if	&f_Forward.	=	1	or	&f_BothDir.	=	1	%then %do;
	%*100.	Searching.;
	%DBcr_GetSubseqDataFlow(
		&FileList.
		,inETLFlow	=	&inETLFlow.
		,outETLFlow	=	&procLIB..__GRDF_Forward__
		,inValType	=	&inValType.
		,C_FILENAME	=	&C_FILENAME.
		,C_PGMNAME	=	&C_PGMNAME.
		,C_FlowType	=	&C_FlowType.
		,FlowByVar	=	&FlowByVar.
		,KeyOfFlow	=	&KeyOfFlow.
		,procLIB	=	&procLIB.
		,ListDlm	=	&ListDlm.
		,mNest		=	0
		,fDebug		=	&fDebug.
	)

	%*900.	Mark whether the search is complete.;
	%let	e_Forward	=	%sysfunc(exist( &procLIB..__GRDF_Forward__ ));
%end;

%*300.	Quit the program if none of the provided files are related to the entire ETL process.;
%if	&e_Backward.	=	0	and	&e_Forward.	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]None of the provided files is related to the entire ETL process. [FileList=%qsysfunc(compbl(&FileList.))];
	%goto	EndOfProc;
%end;

%*500.	Combine both datasets and dedup.;
%*510.	Set the datasets.;
data &procLIB..__GRDF_FullSub__;
	set
	%if	&e_Backward.	=	1	%then %do;
		&procLIB..__GRDF_Backward__
	%end;
	%if	&e_Forward.	=	1	%then %do;
		&procLIB..__GRDF_Forward__
	%end;
	;
run;

%*590.	Dedup.;
proc sort
	data=&procLIB..__GRDF_FullSub__
	out=%unquote(&outETLFlow.)
	nodupkey
;
	by	&KeyOfFlow.;
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
%mend DBcr_GetRelatedDataFlow;

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

%DBcr_GetRelatedDataFlow(
	%nrstr( src.raw_add_job )
	,inETLFlow	=	test
	,outETLFlow	=	WORK.__ETL_RelatedDataFlow__
	,inValType	=	V
	,C_FILENAME	=	Data_Name
	,C_PGMNAME	=	pgm_full
	,C_FlowType	=	Flow_Type
	,FlowByVar	=	pgm_full
	,KeyOfFlow	=	pgm_full Flow_Type Data_Name
	,procLIB	=	WORK
	,ListDlm	=	%str(|)
	,Direction	=	Both
	,fDebug		=	1
)

%*Output.;

/*-Notes- -End-*/