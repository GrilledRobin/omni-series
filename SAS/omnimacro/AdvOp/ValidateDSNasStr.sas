%macro ValidateDSNasStr(
	inSTR	=
	,FUZZY	=	0
	,gMode	=	F
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to validate the Dataset Name provided as one character string.												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inSTR	:	Input string for DSN validation.																						|
|	|FUZZY	:	The flag indicating whether to match the whole string or part of it.													|
|	|			 This is useful when the dataset option is in effect while we still regard it as valid.									|
|	|gMode	:	Indicator of whether the macro is in Procedure Mode or Function Mode.													|
|	|			 Valid value should be F or P.																							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20140420		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
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

%if	%length(%qsysfunc(compress(&FUZZY.,%str( ))))	=	0	%then	%let	FUZZY	=	0;
%if	&FUZZY.	^=	0	%then	%let	FUZZY	=	1;

%if	&gMode.	^=	P	%then %do;
	%let	gMode	=	F;
%end;

%*013.	Define the local environment.;
%local
	ptnBGN
	ptnEND
	PRXDS
	Lvld
;
%if	&FUZZY.	=	0	%then %do;
	%let	ptnBGN		=;
	%let	ptnEND		=;
%end;
%else %do;
	%let	ptnBGN		=	%str(\s*);
	%let	ptnEND		=	%str(([\s\%(]+.*)?);
%end;
%*let	PRXDS	=
	%sysfunc(
		prxparse(/^&ptnBGN.(([[:alpha:]_]\w{0%str(,)7}?\.)?[[:alpha:]_]\w{0%str(,)31}?)&ptnEND.$/ismx)
	)
;
%let	PRXDS	=
	%sysfunc(
		prxparse(/
			^&ptnBGN.								(?# In Fuzzy mode there could be leading spaces)
			(										(?# Begin of the match in DS Name)
				([[:alpha:]_]\w{0%str(,)7}?\.)?		(?# Libname with dot if any)
				[[:alpha:]_]\w{0%str(,)31}?			(?# DS Name with the number of characters less than 32)
			)										(?# End of the match in DS Name)
			&ptnEND.								(?# Verify the trail)
			$										(?# End of the entire string)
			/ismx
		)
	)
;

%*100.	Validation.;
%let	Lvld	=	%eval(%sysfunc(prxmatch(&PRXDS.,&inSTR.)) > 0);

%*800.	Make statements.;
%if	&gMode.	^=	P	%then %do;
	&Lvld.
%end;
%else %do;
	%if	&Lvld.	=	0	%then %do;
		%put	%str(E)RROR: [&L_mcrLABEL.]The given string is an invalid DSN!;
		%put	&Lohno.;
		%ErrMcr
	%end;
	%else %do;
		%put	%str(N)OTE: [&L_mcrLABEL.]The given string has a valid DSN.;
	%end;
%end;

%*900.	Purge memory usage.;
%*910.	Release PRX utilities.;
%ReleasePRX:
%syscall prxfree(PRXDS);

%EndOfProc:
%mend ValidateDSNasStr;