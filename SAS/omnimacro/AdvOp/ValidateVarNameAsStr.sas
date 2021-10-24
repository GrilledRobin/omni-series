%macro ValidateVarNameAsStr(
	inSTR	=
	,gMode	=	F
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to validate the Dataset Variable Name provided as one character string.										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inSTR	:	Input string for DSN validation.																						|
|	|gMode	:	Indicator of whether the macro is in Procedure Mode or Function Mode.													|
|	|			 Valid value should be F or P.																							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20140420		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
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
%let	gMode		=	%qupcase(&gMode.);

%if	&gMode.	^=	P	%then %do;
	%let	gMode	=	F;
%end;

%*013.	Define the local environment.;
%local
	ptnBGN
	ptnEND
	PRXVAR
	Lvld
;

%let	ptnBGN	=	%str(\s*);
%let	ptnEND	=	%str(\s*);
%let	PRXVAR	=
	%sysfunc(
		prxparse(/
			^&ptnBGN.				(?# There could be leading spaces)
			(						(?# Begin of the match as Variable Name)
				[[:alpha:]_]		(?# Alphabetics and underscore are valid beginning of a Variable Name)
				\w{0%str(,)31}?		(?# The rest characters in the Variable Name)
			)						(?# End of the match as Variable Name)
			&ptnEND.				(?# Verify the trail)
			$						(?# End of the entire string)
			/ismx
		)
	)
;

%*There is an alternative pattern in here: http://blogs.sas.com/content/sasdummy/2012/08/22/using-a-regular-expression-to-validate-a-sas-variable-name/;

%*100.	Validation.;
%let	Lvld	=	%eval(%sysfunc(prxmatch(&PRXVAR.,&inSTR.)) > 0);

%*800.	Make statements.;
%if	&gMode.	^=	P	%then %do;
	&Lvld.
%end;
%else %do;
	%if	&Lvld.	=	0	%then %do;
		%put	%str(E)RROR: [&L_mcrLABEL.]The given string is an invalid Dataset Variable Name!;
		%put	&Lohno.;
		%ErrMcr
	%end;
	%else %do;
		%put	%str(N)OTE: [&L_mcrLABEL.]The given string is a valid Dataset Variable Name.;
	%end;
%end;

%*900.	Purge memory usage.;
%*910.	Release PRX utilities.;
%ReleasePRX:
%syscall prxfree(PRXVAR);

%EndOfProc:
%mend ValidateVarNameAsStr;