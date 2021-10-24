%macro getCOLbyStrPattern(
	inDAT		=
	,inRegExp	=
	,exclRegExp	=
	,chkVarTP	=	ALL
	,outCNT		=	G_LstNO
	,outELpfx	=	G_LstEL
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to search for specific variables or columns in given dataset												|
|	| by given matching rule with respect of Regular Expression.																		|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDAT		:	Dataset name in which variables or columns should be searched.														|
|	|inRegExp	:	Matching rule of character combination.																				|
|	|exclRegExp	:	Excluding rule of character combination.																			|
|	|chkVarTP	:	Filter on variable type, valid values are: C, N or others.															|
|	|outCNT		:	Number of files found in the folder.																				|
|	|outELpfx	:	Prefix of macro variables, which will contain the found file names.													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20140411		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20140412		| Version |	2.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Slightly enhance the program efficiency.																					|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20150105		| Version |	3.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Add the variable type filtration.																							|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180310		| Version |	3.10		| Updater/Creator |	Lu Robin Bin												|
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
	%put	%str(E)RROR: [&L_mcrLABEL.]No dataset is given for search of columns! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%length(%qsysfunc(compress(&inRegExp.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No pattern is specified for column search, program will find all columns in given dataset: [&inDAT.];
	%let	inRegExp	=	%nrbquote(.*);
%end;
%if		&chkVarTP.	^=	C
	and	&chkVarTP.	^=	N
	%then %do;
	%let	chkVarTP	=	ALL;
%end;
%if	%length(%qsysfunc(compress(&outCNT.,%str( ))))		=	0	%then	%let	outCNT		=	G_LstNO;
%if	%length(%qsysfunc(compress(&outELpfx.,%str( ))))	=	0	%then	%let	outELpfx	=	G_LstEL;

%*013.	Define the local environment.;
%local
	fChkExcl
	chkDATxt
	DSID
	rc
	nVAR
	VARi
	chkSRC
	chkVTP
	rxIN
	rxEX
;
%let	fChkExcl	=	1;
%let	rxIN		=;
%let	rxEX		=;
%if	%length(%qsysfunc(compress(&exclRegExp.,%str( ))))	=	0	%then %do;
	%let	fChkExcl	=	0;
%end;

%global	&outCNT.;
%let	&outCNT.	=	0;

%*050.	Check dataset existence.;
/*
%let	chkDATxt	=	1;
%let	chkDATxt	=	%sysfunc(exist(&inDAT.));
%if	%bquote(&chkDATxt.)	=	0	%then %do;
	%put	ERROR: [&L_mcrLABEL.]Named dataset "&inDAT." does not exist!.;
	%put	&Lohno.;
	%*Below macro is from "&cdwmac.\AdvOp";
	%ErrMcr
%end;
*/
%*100.	Retrieve dataset information.;
%let	DSID	=	%sysfunc(open(&inDAT.));
%let	nVAR	=	%sysfunc(attrn(&DSID., nvars));
%if	&nVAR.	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Given dataset: [&inDAT.] has no column.;
	%goto	CloseDS;
%end;

%*200.	Prepare Regular Expression.;
%let	rxIN	=	%sysfunc(prxparse(/%nrbquote(&inRegExp.)/ismx));
%if	&fChkExcl.	=	1	%then %do;
	%let	rxEX	=	%sysfunc(prxparse(/%nrbquote(&exclRegExp.)/ismx));
%end;

%*300.	Retrieve variables or columns by matching rules.;
%do	VARi=1	%to	&nVAR.;
	%*100.	Retrieve the original columns by sequence.;
	%let	chkSRC	=	%sysfunc(varname(&DSID.,&VARi.));
	%let	chkVTP	=	%sysfunc(vartype(&DSID.,&VARi.));

	%*200.	Should there be any pattern that matches the "exclusion" rules, we skip the step.;
	%if	&fChkExcl.	=	1	%then %do;
		%if	%sysfunc(prxmatch(&rxEX.,&chkSRC.))	%then %do;
			%goto	ExitCurrStepVar;
		%end;
	%end;

	%*300.	Verify the variable type.;
	%if	&chkVarTP.	^=	ALL	%then %do;
		%if	&chkVarTP.	^=	%qupcase(&chkVTP.)	%then %do;
			%goto	ExitCurrStepVar;
		%end;
	%end;

	%*400.	Verify the match results.;
	%if	%sysfunc(prxmatch(&rxIN.,&chkSRC.))	%then %do;
		%let	&outCNT.	=	%eval(&&&outCNT.. + 1);
		%global	&outELpfx.&&&outCNT..;
		%let	&outELpfx.&&&outCNT..	=	&chkSRC.;
	%end;

	%*900.	Quit current step of iteration.;
	%ExitCurrStepVar:
%end;
%QuitLoopVar:

%*800.	Announcement.;
%if	&&&outCNT..	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No column is found under given matching rule.;
%end;

%*900.	Purge the memory.;
%*910.	Release the Regular Expression matching rules.;
%ReleasePRX:
%syscall prxfree(rxIN);
%if	&fChkExcl.	=	1	%then %do;
	%syscall prxfree(rxEX);
%end;

%*980.	Close the dataset.;
%CloseDS:
%let	rc	=	%sysfunc(close(&DSID.));

%EndOfProc:
%mend getCOLbyStrPattern;