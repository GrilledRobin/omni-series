%macro getTblListByStrPattern(
	inLIB		=
	,inRegExp	=
	,exclRegExp	=
	,extRegExp	=	data
	,outCNT		=	G_LstNO
	,outELpfx	=	G_LstEL
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to search for specific data or views under given library name by given matching rule with respect of		|
|	| Regular Expression.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inLIB		:	Library name under which files should be searched.																	|
|	|inRegExp	:	Matching rule of character combination.																				|
|	|exclRegExp	:	Excluding rule of character combination.																			|
|	|extRegExp	:	Rule of File Type, currently DATA or VIEW.																			|
|	|outCNT		:	Number of files found in the library.																				|
|	|outELpfx	:	Prefix of macro variables, which will contain the found file names.													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20130826		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20160531		| Version |	1.01		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Change the macro condition judgement to base language condition judgement.													|
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
|	|	|getOBS4DATA																													|
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
%if	%length(%qsysfunc(compress(&inLIB.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No Library is given for search of files! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%sysfunc(libref(&inLIB.))	^=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]Library [&inLIB.] is invalid! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%length(%qsysfunc(compress(&inRegExp.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No pattern is specified for file search, program will find all files in given library: [&inLIB.];
	%let	inRegExp	=	%nrbquote(.*);
%end;
%if	%length(%qsysfunc(compress(&extRegExp.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No pattern is specified for file type, program will find all SAS Datasets in given library: [&inLIB.];
	%let	extRegExp	=	%nrbquote(DATA);
%end;
%if	%length(%qsysfunc(compress(&outCNT.,%str( ))))		=	0	%then	%let	outCNT		=	G_LstNO;
%if	%length(%qsysfunc(compress(&outELpfx.,%str( ))))	=	0	%then	%let	outELpfx	=	G_LstEL;

%*013.	Define the local environment.;
%local
	fChkExcl
	LobsChk
;
%let	fChkExcl	=	1;
%if	%length(%qsysfunc(compress(&exclRegExp.,%str( ))))	=	0	%then %do;
	%let	fChkExcl	=	0;
%end;

%global	&outCNT.;
%let	&outCNT.	=	0;

%*100.	Retrieve all SAS files within the given library.;
proc sql noprint;
	create table _TEMP_(where=(missing(memname)=0)) as (
		select *
		from dictionary.tables
		where libname	=	upcase(%sysfunc(quote(&inLIB.,%str(%'))))
	);
quit;
%let	LobsChk	=	0;
%getOBS4DATA(
	inDAT	=	_TEMP_
	,outVAR	=	LobsChk
	,gMode	=	P
)
%if	&LobsChk.	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No SAS file is found in given library: [&inLIB.];
	%goto	EndOfProc;
%end;

%*300.	Search for files with respect of the given PRX.;
data _NULL_;
	%*001.	Parameters.;
	retain
		tmpCNT
		0
	;

	%*010.	Set the data.;
	set _TEMP_ end=EOF;

	%*020.	Prepare the matching rules.;
	retain
		prxIN
		prxEX
		prxTP
	;
	if	_N_	=	1	then do;
		prxIN	=	prxparse("/&inRegExp./ix");
		prxEX	=	prxparse("/&exclRegExp./ix");
		prxTP	=	prxparse("/&extRegExp./ix");
	end;

	%*100.	Match the given PRX.;
	if	prxmatch(prxTP, memtype)	then do;
		%*100.	Discard the file if it matches the rule of exclusion.;
		if	&fChkExcl.	=	1	then do;
			if	prxmatch(prxEX, memname)	then do;
				goto	EndOfRec;
			end;
		end;

		%*200.	Add the valid finding into the output list.;
		if	prxmatch(prxIN, memname)	then do;
			tmpCNT	+	1;
			call symputx(cats("&outELpfx.", tmpCNT), memname, "G");
		end;
	end;

	%*900.	Generate the number of findings.;
	EndOfRec:
	if	EOF	then do;
		call symputx("&outCNT.", tmpCNT, "G");

		call prxfree(prxIN);
		call prxfree(prxEX);
		call prxfree(prxTP);
	end;
run;

%*300.	Purge the memory consumption.;

%*800.	Announcement.;
%if	&&&outCNT..	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No file is found under given matching rule.;
%end;

%*900.	Purge memory usage.;
%*910.	Release PRX utilities.;
%ReleasePRX:

%*920.	Close the file reference.;
%ReleaseFR:

%EndOfProc:
%mend getTblListByStrPattern;