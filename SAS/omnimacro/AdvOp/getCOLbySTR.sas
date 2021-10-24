%macro getCOLbySTR(
	FUZZY	=	1
	,inDSN	=
	,inDAT	=
	,inSTR	=
	,chkOR	=	1
	,NMidx	=	>0
	,outEL	=	LCEL
	,outCT	=	LCTTL
	,outLIB	=	WORK
	,outDAT	=	_subcol_
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is for the search of variable names in terms of the given character string.												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|FUZZY	:	whether we need to find the column names in a fuzzy mode.																|
|	|inDSN	:	The libname where the target dataset is stored.																			|
|	|inDAT	:	The target dataset name.																								|
|	|inSTR	:	The name string(s) which are to be searched in the target dataset. (Can be multi, connected by BLANKs)					|
|	|chkOR	:	When multi strings are given, this is to decide whether they are in an "OR" relation or an "AND" relation.				|
|	|			"1" represents "OR", others will be regarded as "AND".																	|
|	|NMidx	:	the position the given name string in the search base, eg. if NMidx=2, we search in the macro names						|
|	|			 who contain the given string at exactly the 2nd position.																|
|	|outEL	:	The initial of the output macro variables which contain the found column names. (The output macro variables				|
|	|			 will be like this: AAA1, AAA2,...; and here outEL="AAA")																|
|	|outCT	:	The number of output macro variables as above.																			|
|	|outLIB	:	the output library.																										|
|	|outDAT	:	the output dataset who contains the found column names.																	|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20140331		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
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
|	|	|getOBS4DATA																													|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*001.	Mark and hide the log.;
%local
	L_mcrLABEL
	cnotes
	cmlogic
	csymbolg
	cmprint
	Lconj
	lenconj
	tmpSTR
	LSTRi
	LSTRt
	chkSTR
	Lcond
;
%let	L_mcrLABEL	=	&sysMacroName.;
%if %sysfunc( getoption( notes ) ) = NOTES         %then %let cnotes = 1;
%if %sysfunc( getoption( mlogic ) ) = MLOGIC       %then %let cmlogic = 1;
%if %sysfunc( getoption( symbolgen ) ) = SYMBOLGEN %then %let csymbolg = 1;
%if %sysfunc( getoption( mprint ) ) = MPRINT       %then %let cmprint = 1;

options
	nonotes
	nomlogic
	nosymbolgen
	nomprint
;

%*002.	Check parameters.;
%if	&FUZZY.	^=	1	%then %do;
	%let	FUZZY	=	0;
%end;
%if	%length(%qsysfunc(compress(&inDSN.,%str( ))))	=	0	%then %let	inDSN	=	WORK;
%if	%length(%qsysfunc(compress(&inSTR.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No string is to be searched! The search bombed due to errors.;
	%goto	EndOfProc;
%end;
%if	&chkOR.	^=	1	%then %do;
	%let	chkOR	=	0;
%end;

%if	&FUZZY.	=	1	%then %do;
	%let	NMidx	=	%str(>0);
%end;
%else %do;
	%if	(%length(%qsysfunc(compress(&NMidx.,%str( ))))	=	0	or	&NMidx.	=	%str(>0))	%then %do;
		%put	%str(N)OTE: Missing index number for precise mode, it will be reset to 1.;
		%let	NMidx	=	1;
	%end;
	%let	NMidx	=	%str(=&NMidx.);
%end;

%if	%length(%qsysfunc(compress(&outEL.,%str( ))))	=	0	%then	%let	outEL	=	LCEL;
%if	%length(%qsysfunc(compress(&outCT.,%str( ))))	=	0	%then	%let	outCT	=	LCTTL;

%if	%length(%qsysfunc(compress(&outLIB.,%str( ))))	=	0	%then	%let	outLIB	=	WORK;
%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))	=	0	%then	%let	outDAT	=	_subcol_;

%*010.	Process interim variables.;
%if	&chkOR.	=	1	%then %do;
	%let	Lconj	=	OR;
%end;
%else %do;
	%let	Lconj	=	AND;
%end;
%let	lenconj	=	%length(&Lconj.);

%*020.	Main process.;
%if not	%sysfunc(exist(&inDSN..&inDAT.))	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]Necessary dataset "&inDSN..&inDAT." does not exist! The search bombed due to errors.;
	%goto	EndOfProc;
%end;
%else %do;
	%global	&outCT.;
	%let	&outCT.	=	0;

	%*001.	Separate the given string by blanks;
	%local	sepSTR&LSTRi.;
	%let	tmpSTR	=	%sysfunc(compbl(%superq(inSTR)));
	%let	LSTRi	=	1;
	%let	chkSTR	=	%QSCAN(%superq(tmpSTR),&LSTRi.,%STR( ));
	%let	sepSTR&LSTRi.	=	&chkSTR.;
	%DO %WHILE	(%superq(chkSTR) NE);
		%let LSTRi	=	%EVAL(&LSTRi.+1);
		%let chkSTR	=	%QSCAN(%superq(tmpSTR),&LSTRi.,%STR( ));
		%let sepSTR&LSTRi.	=	&chkSTR.;
	%END;
	%let	LSTRt	=	%EVAL(&LSTRi.-1);

	%*010.	Combine the strings by the condition conjunction.;
	%let	Lcond	=;
	%do LSTRi=1	%to	&LSTRt.;
		%let	Lcond	=	&Lcond. &Lconj. index(upcase(NAME),upcase("&&sepSTR&LSTRi.."))	&NMidx.;
	%end;

	%*011.	Remove the first "&Lconj.".;
	%let	Lcond	=	%qsubstr(%superq(Lcond),%eval(&lenconj. + 1));

	%*020.	Retrieve contents of the target dataset.;
	PROC CONTENTS
		DATA=%unquote(&inDSN..&inDAT.)
		NOPRINT
		OUT=%unquote(&outLIB..&outDAT.)(
			KEEP=
				NAME
				VARNUM
		);
	RUN;

	%*030.	Find the columns in need.;
	data %unquote(&outLIB..&outDAT.);
		set
			%unquote(&outLIB..&outDAT.)(
				where=(%unquote(&Lcond.))
			)
		;
	run;

	%*100.	Generate result.;
	%getOBS4DATA(
		inDAT	=	&outLIB..&outDAT.
		,outVAR	=	&outCT.
	)

	%if	&&&outCT..	=	0	%then %do;
		%put	%str(W)ARNING: [&L_mcrLABEL.]No matching column name is found!;
		%goto	EndOfProc;
	%end;
	%else %do;
		proc sort data=%unquote(&outLIB..&outDAT.);
			by VARNUM;
		run;
		data _NULL_;
			set %unquote(&outLIB..&outDAT.) end=EOF;
				by VARNUM;
			call symputx(cats("&outEL.",_N_),NAME,"G");
		run;
	%end;
%end;
%EndOfProc:

%*999.	Restore the system options.;
%if	&cnotes. = 1	%then %do;
options	NOTES;
%end;
%if	&cmlogic. = 1	%then %do;
options	MLOGIC;
%end;
%if	&csymbolg. = 1	%then %do;
options	SYMBOLGEN;
%end;
%if	&cmprint. = 1	%then %do;
options	MPRINT;
%end;
%mend getCOLbySTR;