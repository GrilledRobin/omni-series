%macro ExtractDSNfrStr(
	inSTR	=
	,nMATCH	=	1
	,gMode	=	F
	,outSTR	=	Lsubstr
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to extract the Dataset Name from the character string.														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inSTR	:	Input string for DSN validation.																						|
|	|nMATCH	:	Returns the n-th match from the given string.																			|
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
|	|Currently only when the DSN exists as the leading character can it be extracted.													|
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
%let	gMode		=	%qupcase(&gMode.);

%if	%length(%qsysfunc(compress(&nMATCH.,%str( ))))	=	0	%then	%let	nMATCH	=	1;
%*Remember to remove below statement once extracting the n-th match can be realized.;
%if	&nMATCH.	^=	1	%then	%let	nMATCH	=	1;

%if	&gMode.	^=	P	%then %do;
	%let	gMode	=	F;
%end;

%if	%length(%qsysfunc(compress(&outSTR.,%str( ))))	=	0	%then	%let	outSTR	=	Lsubstr;

%*013.	Define the local environment.;
%local
	ptnBGN
	ptnEND
	PRXDS
;
%let	ptnBGN		=	%str(\s*);
%*Only Spaces and Left Parenthesis are allowed to follow the DSN.;
%let	ptnEND		=	%str(([\s\%(]+.*)?);
%*let	PRXDS	=
	%sysfunc(
		prxparse(s/^&ptnBGN.(([[:alpha:]_]\w{0%str(,)7}?\.)?[[:alpha:]_]\w{0%str(,)31}?)&ptnEND./\1/ismx)
	)
;
%let	PRXDS	=
	%sysfunc(
		prxparse(s/
			^&ptnBGN.								(?# There could be leading spaces)
			(										(?# Begin of the match in DS Name)
				([[:alpha:]_]\w{0%str(,)7}?\.)?		(?# Libname with dot if any)
				[[:alpha:]_]\w{0%str(,)31}?			(?# DS Name with the number of characters less than 32)
			)										(?# End of the match in DS Name)
			&ptnEND.								(?# Verify the trail)
			$										(?# End of the entire string)
			/\1/ismx
		)
	)
;

%*100.	Retrieval.;
%let	&outSTR.	=	%sysfunc(prxchange(&PRXDS.,&nMATCH.,&inSTR.));

%*900.	Purge memory usage.;
%*910.	Release PRX utilities.;
%ReleasePRX:
%syscall prxfree(PRXDS);

%*990.	Make statements.;
%if	&gMode.	^=	P	%then %do;
	&&&outSTR..
%end;

%EndOfProc:
%mend ExtractDSNfrStr;