%macro DBcr_GetSubseqDataFlow(
	FileList
	,inETLFlow	=	WORK.__ETLcfg_Dats__
	,outETLFlow	=	WORK.__ETL_SubseqDataFlow__
	,inValType	=	V
	,C_FILENAME	=	C_FILENAME
	,C_PGMNAME	=	C_PGMNAME
	,C_FlowType	=	C_FlowType
	,FlowByVar	=	C_PGMNAME
	,KeyOfFlow	=	C_PGMNAME C_FlowType C_FILENAME
	,procLIB	=	WORK
	,ListDlm	=	%str(|)
	,mNest		=	0
	,fDebug		=	0
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to retrieve a subset of the provided Data Flow, which can be executed independently from the first program	|
|	| which use the listed files/datasets as input to the end of the entire ETL process, with the call of the least necessary programs.	|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|FileList	:	The list of files to lookup in the ETL meta table.																	|
|	|inETLFlow	:	The input ETL meta table which stores the data flow of all projects.												|
|	|				Default : [WORK.__ETLcfg_Dats__]																					|
|	|outETLFlow	:	The subset of the ETL meta table which stores the least necessary data flow to generate the listed files.			|
|	|				Default : [WORK.__ETL_SubseqDataFlow__]																				|
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
|	|mNest		:	[M]th Level of Nesting Call of the same macro, which is zero at the first call.										|
|	|				Only non-negative integar is accepted.																				|
|	|				Default : [0]																										|
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
|	|	|getOBS4DATA																													|
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
%if	%length(%qsysfunc(compress(&outETLFlow.,%str( ))))	=	0	%then	%let	outETLFlow	=	WORK.__ETL_SubseqDataFlow__;

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
%if	%length(%qsysfunc(compress(&fDebug.,%str( ))))		=	0	%then	%let	fDebug		=	0;
%if	&fDebug.^=	0	%then	%let	fDebug		=	1;

%*013.	Define the global environment.;

%*014.	Define the local environment.;
%local
	OptNotes	OptSource	OptSource2	OptMLogic	OptSymGen	OptMPrint	OptInOper
	NextL		GnLST		Fi			tmpPgmFrst	f_noNext
;
%let	NextL		=	%eval( &mNest. + 1 );
%let	tmpPgmFrst	=;
%let	f_noNext	=	0;

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
	%put	%str(I)NFO: [&L_mcrLABEL.][Nest Layer:&mNest.]Input Values: [FileList=&FileList.];
	%put	%str(I)NFO: [&L_mcrLABEL.][Nest Layer:&mNest.]Input Values: [inETLFlow=&inETLFlow.];
	%put	%str(I)NFO: [&L_mcrLABEL.][Nest Layer:&mNest.]Input Values: [outETLFlow=&outETLFlow.];
	%put	%str(I)NFO: [&L_mcrLABEL.][Nest Layer:&mNest.]Input Values: [inValType=&inValType.];
	%put	%str(I)NFO: [&L_mcrLABEL.][Nest Layer:&mNest.]Input Values: [C_FILENAME=&C_FILENAME.];
	%put	%str(I)NFO: [&L_mcrLABEL.][Nest Layer:&mNest.]Input Values: [C_PGMNAME=&C_PGMNAME.];
	%put	%str(I)NFO: [&L_mcrLABEL.][Nest Layer:&mNest.]Input Values: [C_FlowType=&C_FlowType.];
	%put	%str(I)NFO: [&L_mcrLABEL.][Nest Layer:&mNest.]Input Values: [FlowByVar=&FlowByVar.];
	%put	%str(I)NFO: [&L_mcrLABEL.][Nest Layer:&mNest.]Input Values: [KeyOfFlow=&KeyOfFlow.];
	%put	%str(I)NFO: [&L_mcrLABEL.][Nest Layer:&mNest.]Input Values: [procLIB=&procLIB.];
	%put	%str(I)NFO: [&L_mcrLABEL.][Nest Layer:&mNest.]Input Values: [ListDlm=&ListDlm.];
%end;

%*050.	Restructure the name list.;
%let	GnLST	=	%eval( %sysfunc(countc( &FileList. , &ListDlm. )) + 1 );
%do Fi=1 %to &GnLST.;
	%local	GeLST&Fi.;
	%let	GeLST&Fi.	=	%qsysfunc(strip( %qscan( &FileList. , &Fi. , &ListDlm. ) ));
%end;

%*100.	Clean the input list.;
%*110.	Create a dataset for the list.;
data &procLIB..__GSDF_inlist&mNest.;
%if	&inValType.	=	D	%then %do;
	set
	%do Fi=1 %to &GnLST.;
		%unquote(&&GeLST&Fi..)
	%end;
	;
	&C_FILENAME.	=	lowcase(&C_FILENAME.);
%end;
%else %do;
	length	&C_FILENAME.	$512;
	%do Fi=1 %to &GnLST.;
		&C_FILENAME.	=	lowcase(%sysfunc(quote( %qsysfunc(dequote( &&GeLST&Fi.. )) , %str(%') )));
		output;
	%end;
%end;

	%*Only keep one variable to reduce the system effort.;
	keep	&C_FILENAME.;
run;

%*120.	Dedup.;
proc sort
	data=&procLIB..__GSDF_inlist&mNest.
	nodupkey
;
	by	&C_FILENAME.;
run;

%*170.	Sort the meta table for further process.;
proc sort
	data=%unquote(&inETLFlow.)
	out=&procLIB..__GSDF_inETLflow&mNest.
	nodupkey
;
	by	&KeyOfFlow.;
run;
data &procLIB..__GSDF_inETLflow&mNest.;
	set &procLIB..__GSDF_inETLflow&mNest.;
	&C_FILENAME.	=	lowcase(&C_FILENAME.);
	&C_PGMNAME.		=	lowcase(&C_PGMNAME.);
run;
proc sort
	data=&procLIB..__GSDF_inETLflow&mNest.
;
	by	&FlowByVar.;
run;

%*200.	Search for the first process steps in the ETL meta table which use current files as input.;
%*210.	Find all processes that input current files.;
proc sql;
	create table &procLIB..__GSDF_FileProc&mNest. as (
		select	a.*
		from &procLIB..__GSDF_inETLflow&mNest.( where=( upcase(&C_FlowType.) = "INPUT" ) ) as a
		inner join &procLIB..__GSDF_inlist&mNest. as b
			on	strip(a.&C_FILENAME.)	=	strip(b.&C_FILENAME.)
	);
quit;

%*219.	Quit the search if none of the files is used in current ETL process.;
%if	%getOBS4DATA( inDAT = &procLIB..__GSDF_FileProc&mNest. , gMode = F )	=	0	%then %do;
	%*199.	Debugger.;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.][Nest Layer:&mNest.]Quit the search as none of the files is used in current ETL process;
	%end;

	%*900.	Quit the program.;
	%goto	EndOfProc;
%end;

%*250.	Only accept the last programs.;
proc sort
	data=&procLIB..__GSDF_FileProc&mNest.
;
	by
		&C_FILENAME.
		&FlowByVar.
	;
run;
data &procLIB..__GSDF_FileProc&mNest.;
	set &procLIB..__GSDF_FileProc&mNest.;
	by
		&C_FILENAME.
		&FlowByVar.
	;
	if	first.&C_FILENAME.;
run;

%*290.	Issue message when some of the provided files are NOT used in current ETL process.;
proc sql;
	create table &procLIB..__GSDF_FileMiss&mNest. as (
		select	a.*
		from &procLIB..__GSDF_inlist&mNest. as a
		left join &procLIB..__GSDF_FileProc&mNest. as b
			on	strip(a.&C_FILENAME.)	=	strip(b.&C_FILENAME.)
		where missing(b.&C_FILENAME.)	=	1
	);
quit;
%if	%getOBS4DATA( inDAT = &procLIB..__GSDF_FileMiss&mNest. , gMode = F )	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.][Nest Layer:&mNest.]Some of the provided files are NOT used in current ETL process, see [&procLIB..__GSDF_FileMiss&mNest.];
%end;

%*300.	Identify all files in the same process steps.;
data &procLIB..__GSDF_ProcIn&mNest.;
	%*100.	Set the meta table.;
	set &procLIB..__GSDF_inETLflow&mNest. end=EOF;
	by	&FlowByVar.;

	%*200.	Prepare to load the program names.;
	if	_N_	=	1	then do;
		dcl	hash	hPGM(dataset:"&procLIB..__GSDF_FileProc&mNest.",multidata:"N");
		hPGM.DefineKey("&C_PGMNAME.");
		hPGM.DefineData("&C_PGMNAME.");
		hPGM.DefineDone();
	end;

	%*300.	Prepare to identify the very first program to cut the ETL meta table for the next round of recursion.;
	array	tmpPGM{1}	8	_temporary_;

	%*800.	Identify the required process elements.;
	if	hPGM.check()	=	0	then do;
		tmpPGM{1}	=	1;
		output;
	end;

	%*900.	Retrieve the very first program at current round of search.;
	if	tmpPGM{1}	=	1	and	lag(tmpPGM{1})	<	tmpPGM{1}	then do;
		call symputx( "tmpPgmFrst" , &C_PGMNAME. , "L" );
	end;
run;

%*309.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%put	%str(I)NFO: [&L_mcrLABEL.][Nest Layer:&mNest.]All steps AFTER this program in the ETL process are used as the base for the next round of recursive search if any [tmpPgmFrst=%superq(tmpPgmFrst)];
%end;

%*390.	Skip recursive search if none of current programs has output file.;
%if	%getOBS4DATA( inDAT = %nrbquote( &procLIB..__GSDF_ProcIn&mNest.( where=( upcase(&C_FlowType.) = "OUTPUT" ) ) ) , gMode = F )	=	0	%then %do;
	%*100.	Mark that there should be no further recursive search.;
	%let	f_noNext		=	1;

	%*199.	Debugger.;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.][Nest Layer:&mNest.]None of current programs has output file, see [&procLIB..__GSDF_ProcIn&mNest.];
	%end;

	%*900.	Skip recursive search.;
	%goto	SkipSearch;
%end;

%*400.	Prepare a subset of the ETL meta table with all processes AFTER the very first program identified at above steps.;
data &procLIB..__GSDF_ETLsub&mNest.;
	%*100.	Set the meta table.;
	set &procLIB..__GSDF_inETLflow&mNest.;
	by	&FlowByVar.;
	retain	f_keep	0;

	%*200.	Identify the process step.;
	if	&C_PGMNAME.	=	%sysfunc(quote( %superq(tmpPgmFrst) , %str(%') ))	then do;
		f_keep	=	1;
	end;

	%*300.	Remove all prior steps as well as current one.;
	if	f_keep	=	0	or	&C_PGMNAME.	=	%sysfunc(quote( %superq(tmpPgmFrst) , %str(%') ))	then	delete;

	%*900.	Purge.;
	drop	f_keep;
run;

%*490.	Skip recursive search if none of current programs has subsequent process.;
%if	%getOBS4DATA( inDAT = &procLIB..__GSDF_ETLsub&mNest. , gMode = F )	=	0	%then %do;
	%*100.	Mark that there should be no further recursive search.;
	%let	f_noNext		=	1;

	%*199.	Debugger.;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.][Nest Layer:&mNest.]None of current programs has subsequent process, see [&procLIB..__GSDF_ProcIn&mNest.];
	%end;

	%*900.	Skip recursive search.;
	%goto	SkipSearch;
%end;

%*500.	Verify whether the [OUTPUT] files at current steps are also [INPUT] files at the subsequent steps.;
%*510.	Search for the files.;
proc sql;
	create table &procLIB..__GSDF_hasRecur&mNest. as (
		select	a.*
		from &procLIB..__GSDF_ETLsub&mNest.( where=( upcase(&C_FlowType.) = "INPUT" ) ) as a
		inner join &procLIB..__GSDF_ProcIn&mNest.( where=( upcase(&C_FlowType.) = "OUTPUT" ) ) as b
			on	strip(a.&C_FILENAME.)	=	strip(b.&C_FILENAME.)
	);
quit;

%*590.	Skip recursive search if none of the output files of current programs are used as input files at the subsequent steps.;
%if	%getOBS4DATA( inDAT = &procLIB..__GSDF_hasRecur&mNest. , gMode = F )	=	0	%then %do;
	%*100.	Mark that there should be no further recursive search.;
	%let	f_noNext		=	1;

	%*199.	Debugger.;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.][Nest Layer:&mNest.]None of the output files of current programs are used as input files at the subsequent steps, see [&procLIB..__GSDF_ProcIn&mNest.];
	%end;

	%*900.	Skip recursive search.;
	%goto	SkipSearch;
%end;

%*800.	Search for the subsequent processes by calling the same function in recursion.;
%DBcr_GetSubseqDataFlow(
	%nrbquote( &procLIB..__GSDF_ProcIn&mNest.( where=( upcase(&C_FlowType.) = "OUTPUT" ) ) )
	,inETLFlow	=	&procLIB..__GSDF_ETLsub&mNest.
	,outETLFlow	=	&procLIB..__GSDF_ProcSubseq&mNest.
	,inValType	=	D
	,C_FILENAME	=	&C_FILENAME.
	,C_PGMNAME	=	&C_PGMNAME.
	,C_FlowType	=	&C_FlowType.
	,FlowByVar	=	&FlowByVar.
	,KeyOfFlow	=	&KeyOfFlow.
	,procLIB	=	&procLIB.
	,ListDlm	=	&ListDlm.
	,mNest		=	&NextL.
	,fDebug		=	&fDebug.
)

%*850.	We have to combine the current program that inputs the dedicated files with all its subsequent steps as the final chain.;
%SkipSearch:
data &procLIB..__GSDF_ProcFnl&mNest.;
	set
		&procLIB..__GSDF_ProcIn&mNest.
	%if	&f_noNext.	=	0	%then %do;
		&procLIB..__GSDF_ProcSubseq&mNest.
	%end;
	;
run;

%*859.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%if	&f_noNext.	=	0	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.][Nest Layer:&mNest.]The result comes from recursive search, combined by [&procLIB..__GSDF_ProcIn&mNest.] and [&procLIB..__GSDF_ProcPrior&mNest.];
	%end;
	%else %do;
		%put	%str(I)NFO: [&L_mcrLABEL.][Nest Layer:&mNest.]The result comes directly from [&procLIB..__GSDF_ProcIn&mNest.];
	%end;
%end;

%*890.	Dedup as the provided files may share the same subsequent processes.;
proc sort
	data=&procLIB..__GSDF_ProcFnl&mNest.
	out=%unquote(&outETLFlow.)
	nodupkey
;
	by	&KeyOfFlow.;
run;

%*899.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%put	%str(I)NFO: [&L_mcrLABEL.][Nest Layer:&mNest.]Search complete!;
%end;

%*900.	Remove the temporary datasets as the recursive search may take a lot of disk space.;
%if	&fDebug.	=	1	%then %do;
	%goto	EndOfProc;
%end;
proc datasets
	lib	=	&procLIB.
	nolist
;
	delete
		__GSDF_inlist&mNest.
		__GSDF_inETLflow&mNest.
		__GSDF_FileProc&mNest.
		__GSDF_ETLsub&mNest.
		__GSDF_hasRecur&mNest.
		__GSDF_ProcSubseq&mNest.
		__GSDF_ProcFnl&mNest.
	;
run;
quit;

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
%mend DBcr_GetSubseqDataFlow;

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

%DBcr_GetSubseqDataFlow(
	%nrstr( raw.para3 | src.raw_add_job )
	,inETLFlow	=	test
	,outETLFlow	=	WORK.__ETL_SubseqDataFlow__
	,inValType	=	V
	,C_FILENAME	=	Data_Name
	,C_PGMNAME	=	pgm_full
	,C_FlowType	=	Flow_Type
	,FlowByVar	=	pgm_full
	,KeyOfFlow	=	pgm_full Flow_Type Data_Name
	,procLIB	=	WORK
	,ListDlm	=	%str(|)
	,mNest		=	0
	,fDebug		=	1
)

%*Output.;

/*-Notes- -End-*/