%macro KeepVarIfExists(
	inDAT		=
	,inFLDlst	=
	,gMode		=	DSSTMT
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to keep any specific variables should they exist in the given dataset.										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDAT		:	Input dataset.																										|
|	|inFLDlst	:	The variable or field name (pattern) list to be kept.																|
|	|				 Examples: 1. %nrbquote(C_: .+KPI.+), 2. %nrbquote(D_TABLE C_:).													|
|	|gMode		:	Indicator of whether the macro is in Dataset Statement Mode or Dataset Option Mode.									|
|	|				 Valid value should be DSSTMT or DSOPT.																				|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20151022		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180310		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
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
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|prepStrPatternByCOLList																										|
|	|	|getCOLbyStrPattern																												|
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
%if	%length(%qsysfunc(compress(&inFLDlst.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No Variable or Field is specified to keep.;
	%goto	EndOfProc;
%end;
%if	%length(%qsysfunc(compress(&inDAT.,%str( ))))	=	0	%then %do;
	%let	inDAT	=	_last_;
%end;
%if	%length(%qsysfunc(compress(&gMode.,%str( ))))	=	0	%then	%let	gMode	=	DSSTMT;
%if	%qupcase(&gMode.)	^=	DSSTMT	%then %do;
	%let	gMode	=	DSOPT;
%end;

%*013.	Define the local environment.;
%local
	TotalPtn
	KEEPi
	SgnEq
	SgnSC
;
%let	TotalPtn	=;
%if	%qupcase(&gMode.)	=	DSSTMT	%then %do;
	%let	SgnEq	=;
	%let	SgnSC	=	%str(;);
%end;
%else %do;
	%let	SgnEq	=	%str(=);
	%let	SgnSC	=;
%end;

%*100.	Create pattern in terms of Regular Expression.;
%prepStrPatternByCOLList(
	COLlst	=	&inFLDlst.
	,outPTN	=	TotalPtn
)

%*200.	Search for the variables.;
%getCOLbyStrPattern(
	inDAT		=	&inDAT.
	,inRegExp	=	&TotalPtn.
	,exclRegExp	=
	,outCNT		=	LnKeepVar
	,outELpfx	=	LeKeepVar
)

%*800.	Make statement.;
%if	&LnKeepVar.	^=	0	%then %do;
	keep&SgnEq.
		%do	KEEPi=1	%to	&LnKeepVar.;
			&&LeKeepVar&KEEPi..
		%end;
	&SgnSC.
%end;
%else %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Skip the step as no matched column is found.;
%end;

%*900.	Purge memory usage.;
%*910.	Release PRX utilities.;
%ReleasePRX:

%EndOfProc:
%mend KeepVarIfExists;