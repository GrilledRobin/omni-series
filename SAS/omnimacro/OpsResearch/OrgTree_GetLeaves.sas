%macro OrgTree_GetLeaves(
	inDAT		=
	,VarUpper	=
	,VarLower	=
	,outVAR		=	TreeLeaf
	,outDAT		=
	,procLIB	=	WORK
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to retrieve all leaves in an Organizational Tree, which means there are no subordinates linked to them.		|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDAT		:	Dataset storing the Organizational Tree linkages.																	|
|	|VarUpper	:	Variable that represents the upper node for the link.																|
|	|VarLower	:	Variable that represents the lower node for the link.																|
|	|outVAR		:	The output variable that denotes to the leaves in the tree.															|
|	|outDAT		:	The output result.																									|
|	|procLIB	:	The working library.																								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20170716		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170828		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Switch back to the hashing of the entire table, instead of one observation at a time, as I found that the processing speed	|
|	|      | is incredibly slow when encountering relatively large dataset with only thousands of observations.							|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180311		| Version |	2.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Each observation in the input dataset should represent ONLY ONE link from the upper node to its lower one.							|
|	|There are only 1 variable in the output result:																					|
|	|[outVAR]	:	The leaves in the tree.																								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ErrMcr																															|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*010.	Check parameters.;
%*011.	Identify current processing macro.;
%local
	L_mcrLABEL
	Lohno
;
%let	L_mcrLABEL	=	&sysMacroName.;
%let	Lohno		=	%str(E)RROR: [&L_mcrLABEL.]Process failed due to %str(e)rrors!;

%*012.	Handle the parameter buffer.;
%if	%length(%qsysfunc(compress(&inDAT.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No dataset is provided! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%length(%qsysfunc(compress(&outVAR.,%str( ))))	=	0	%then	%let	outVAR		=	TreeLeaf;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))	=	0	%then	%let	procLIB		=	WORK;

%*013.	Define the local environment.;
%local
	OptNotes	OptSource	OptSource2	OptMLogic	OptSymGen	OptMPrint	OptInOper
	DSID		DSrc
	vNumUpper	vNumLower
	errMsg
	outTyp		outFmt		outLen
;
%let	errMsg	=	0;

%*016.	Switch off the system options to reduce the LOG size.;
%if %sysfunc(getoption( notes ))		=	NOTES		%then	%let	OptNotes	=	1;	%else	%let	OptNotes	=	0;
%if %sysfunc(getoption( source ))		=	SOURCE		%then	%let	OptSource	=	1;	%else	%let	OptSource	=	0;
%if %sysfunc(getoption( source2 ))		=	SOURCE2		%then	%let	OptSource2	=	1;	%else	%let	OptSource2	=	0;
%if %sysfunc(getoption( mlogic ))		=	MLOGIC		%then	%let	OptMLogic	=	1;	%else	%let	OptMLogic	=	0;
%if %sysfunc(getoption( symbolgen ))	=	SYMBOLGEN	%then	%let	OptSymGen	=	1;	%else	%let	OptSymGen	=	0;
%if %sysfunc(getoption( mprint ))		=	MPRINT		%then	%let	OptMPrint	=	1;	%else	%let	OptMPrint	=	0;
%if %sysfunc(getoption( minoperator ))	=	MINOPERATOR	%then	%let	OptInOper	=	1;	%else	%let	OptInOper	=	0;
%*The default value of the system option [MINDELIMITER] is WHITE SPACE, given the option [MINOPERATOR] is on.;
options nonotes nosource nosource2 nomlogic nosymbolgen nomprint minoperator;

%*018.	Define the global environment.;

%*100.	Verify the definitions of [VarUpper] and [VarLower].;
%*110.	Open the input dataset.;
%let	DSID	=	%sysfunc(open(&inDAT.));

%*120.	Retrieve the variable numbers.;
%let	vNumUpper	=	%sysfunc(varnum(&DSID.,&VarUpper.));
%let	vNumLower	=	%sysfunc(varnum(&DSID.,&VarLower.));

%*130.	Define the attributes of the output variables [&ChainTop.] and [&ChainBtm.], which should be the same as [&VarUpper.].;
%let	outTyp	=	%sysfunc(ifc(%sysfunc(vartype(&DSID.,&vNumUpper.))=C,$,));
%let	outFmt	=	%sysfunc(varfmt(&DSID.,&vNumUpper.));
%let	outLen	=	%sysfunc(varlen(&DSID.,&vNumUpper.));

%*140.	Abort if the VARTYPE of them do not match.;
%if	%sysfunc(vartype(&DSID.,&vNumUpper.))	^=	%sysfunc(vartype(&DSID.,&vNumLower.))	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.][&VarUpper.] and [&VarLower.] are of different data types. Program is interrupted!;
	%let	errMsg	=	1;
%end;

%*150.	Abort if the VARLEN of them do not match.;
%if	%sysfunc(varlen(&DSID.,&vNumUpper.))	^=	%sysfunc(varlen(&DSID.,&vNumLower.))	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.][&VarUpper.] and [&VarLower.] are of different lengths. Program is interrupted!;
	%let	errMsg	=	1;
%end;

%*190.	Close the input dataset.;
%let	DSrc	=	%sysfunc(close(&DSID.));

%*195.	Abort if there are any mismatches.;
%if	&errMsg.	=	1	%then %do;
	%put	&Lohno.;
	%ErrMcr
%end;

%*200.	Retrieve the unique [VarLower] in the input dataset.;
proc freq
	data=%unquote(&inDAT.)
	noprint
;
	tables
		&VarLower.
		/out=&procLIB.._ot_gl
	;
run;

%*100.	Calculation.;
data %unquote(&outDAT.);
	%*005.	Create new fields.;
	length
		&outVAR.	&outTyp.&outLen.
		&VarUpper.	&outTyp.&outLen.
	;
	format
		&outVAR.	&outFmt.
	;

	%*100.	Set the unique [VarLower].;
	set	&procLIB.._ot_gl;
	&outVAR.	=	&VarLower.;

	%*200.	Prepare the HASH object to identify whether current [VarLower] acts as [VarUpper] of other branches.;
	if	_N_	=	1	then do;
		dcl	hash	hDirSub(dataset:"&inDAT.",hashexp:16);
		hDirSub.DefineKey("&VarUpper.");
		hDirSub.DefineData("&VarUpper.");
		hDirSub.DefineDone();
	end;
	call missing(&VarUpper.);

	%*200.	Only output if current [VarLower] does not act as [VarUpper] of any other branches.;
	if	hDirSub.check(key:&outVAR.)	^=	0	then do;
		output;
	end;

	%*900.	Purge.;
	keep
		&outVAR.
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
%mend OrgTree_GetLeaves;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvOp"
		"D:\SAS\omnimacro\OpsResearch"
	)
	mautosource
;

%*100.	Create sample data.;
data test;
	length	u	l	$4.;
	u	=	"a1";	l	=	"b1";	output;
	u	=	"b1";	l	=	"c1";	output;
	u	=	"b1";	l	=	"c2";	output;

	u	=	"a1";	l	=	"b2";	output;

	u	=	"a1";	l	=	"b3";	output;
	u	=	"b3";	l	=	"c3";	output;
	u	=	"c3";	l	=	"d1";	output;
run;

%*200.	Calculation.;
%OrgTree_GetLeaves(
	inDAT		=	test
	,VarUpper	=	u
	,VarLower	=	l
	,outVAR		=	TreeLeaf
	,outDAT		=	leaves
	,procLIB	=	WORK
)

/*-Notes- -End-*/