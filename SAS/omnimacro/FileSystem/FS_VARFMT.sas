%macro FS_VARFMT(
	inDAT	=
	,inFLD	=
	,outVAR	=
	,gMode	=	F
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to return the format of the specified variable in the given dataset.										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDAT		:	Input dataset.																										|
|	|inFLD		:	The variable or field name to be verified.																			|
|	|outVAR		:	Macro variable name that holds the Format of the specified variable or field.										|
|	|gMode		:	Indicator of whether the macro is in Procedure Mode or Function Mode.												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20170812		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
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
|	|This macro can be called ANYWHERE as it does require DATA or PROC step to be skipped.												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
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
%if	%length(%qsysfunc(compress(&inFLD.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No Variable or Field is provided for verification!;
	%goto	MEXIT;
%end;
%if	%length(%qsysfunc(compress(&inDAT.,%str( ))))	=	0	%then %do;
	%let	inDAT	=	_last_;
%end;
%if	%length(%qsysfunc(compress(&outVAR.,%str( ))))	=	0	%then %do;
	%let	outVAR	=	G_n_VARFMT;
	%global	&outVAR.;
%end;
%if	%qupcase(&gMode.)	^=	P	%then %do;
	%let	gMode	=	F;
%end;
%else %do;
	%let	gMode	=	P;
%end;

%*013.	Define the local environment.;
%local
	DSID
	rc
;

%*100.	Retrieval.;
%let	DSID	=	%sysfunc(open(&inDAT.));
%if	&DSID.	=	0	%then %do;
	%put	%sysfunc(sysmsg());
	%let	&outVAR.	=	0;
	%goto	MEXIT;
%end;
%let	&outVAR.	=	%sysfunc(varfmt(&DSID.,%sysfunc(varnum(&DSID.,&inFLD.))));

%let	rc	=	%sysfunc(close(&DSID.));
%*Below statement can only be used in "function" mode.;
%if	&gMode.	=	F	%then %do;
	&&&outVAR..
%end;

%MEXIT:
%mend FS_VARFMT;