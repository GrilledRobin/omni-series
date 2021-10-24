%macro chkSTRinFLD(
	inSTR	=
	,inFLD	=
	,inARR	=	arrAMONG
	,tmpFLD	=	tmpi
	,outFLD	=
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is to count the times that the given string(s) show up in the current field.											|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inSTR	:	The string(s) for checking. Each element must be quoted by quotation marks.												|
|	|inFLD	:	The target field to search the given string(s).																			|
|	|inARR	:	The array name for the loop.																							|
|	|tmpFLD	:	The loop number field.																									|
|	|outFLD	:	The field containing the count result.																					|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20140330		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
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
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*010.	Check parameters.;
%local
	L_mcrLABEL
;
%let	L_mcrLABEL	=	&sysMacroName.;
%if	%length(%qsysfunc(compress(&outFLD.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No output field is defined, program will terminate immediately!;
	%goto	EndOfProc;
%end;
%else %do;
	&outFLD.	=	0;
%end;
%if	%length(%qsysfunc(compress(&inFLD.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No input field is defined, program will terminate immediately!;
	%goto	EndOfProc;
%end;
%if	%length(%qsysfunc(compress(&inSTR.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]There is no string to search, result is purged.;
	%goto	EndOfProc;
%end;
%if	%length(%qsysfunc(compress(&inARR.,%str( ))))	=	0	%then %do;
	%let	inARR	=	arrAMONG;
%end;
%if	%length(%qsysfunc(compress(&tmpFLD.,%str( ))))	=	0	%then %do;
	%let	tmpFLD	=	tmpi;
%end;

%*100.	Initiate.;
%local
	tmpChkStr
	tmpChkN
;
%let	tmpChkStr	=	%sysfunc(compbl(%sysfunc(translate(&inSTR.,%str( ),%str(,)))));
%let	tmpChkN		=	%eval(%sysfunc(count(&tmpChkStr.,%str( )))+1);

%*200.	Count;
array &inARR.{&tmpChkN.} $128.	_temporary_	(&tmpChkStr.);
do &tmpFLD.=1 to dim(&inARR.);
	if	index(upcase(&inFLD.),cats(&inARR.{&tmpFLD.}))	>	0	then do;
		&outFLD.	= &outFLD.	+	1;
	end;
end;

%EndOfProc:
%mend chkSTRinFLD;

/*
This macro is to count the times that the given string(s) show up in the current field.
*/