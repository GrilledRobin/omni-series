%macro getMCRbySTR(
	FUZZY	=	1
	,inDIR	=
	,absDIR	=	1
	,inNAME	=
	,inCAT	=
	,inTYPE	=
	,NMidx	=	>0
	,outMEL	=	LMEL
	,outMT	=	LMTTL
	,outLIB	=	WORK
	,outDAT	=	_sublistsasauto_
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to retrieve the macro names in terms of the provided character string										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|FUZZY	:	where we need to find the macro names in a fuzzy mode.																	|
|	|inDIR	:	where we can find the macros (can be multi, using BLANK to separate each other, but ABSOLUTE DIR should be input).		|
|	|absDIR	:	the identification of the paths about whether they are ABSolute or not, only affect when "inDIR" is defined.			|
|	|inNAME	:	the name(s) or string in name(s) to be searched for, using BLANK to separate each other.								|
|	|inCAT	:	the catalog of the macro, usually blank or "sasmacr".																	|
|	|inTYPE	:	the type of the macro storage, usually "macro" or ".sas"																|
|	|NMidx	:	the position the given name string in the search base, eg. if NMidx=2, we search in the macro names						|
|	|			 who contain the given string at exactly the 2nd position.																|
|	|outMEL	:	the element initial of output variables, who contain the macro names. Default is LMEL, means Local Macro name ELement.	|
|	|outMT	:	the number of found elements. Default is LMTTL, means Local Macro name ToTaL number.									|
|	|outLIB	:	the output library.																										|
|	|outDAT	:	the output dataset who contains the found macro names.																	|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20160617		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
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
|	|	|list_sasautos																													|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*001.	Check parameters.;
%local
	L_mcrLABEL
	whrDIR
	cmpDIR
	lenDIR
	LDIRt
	tmpDIR
	tmplen
	LSTRi
	chkDIR
	i
	whrTYPE
	whrCAT
	whrNAME
	cmpNAME
	CCCC
	WWWW
	LNMt
;
%let	L_mcrLABEL	=	&sysMacroName.;
%*001.010.	Check availability of the macro list.;
%if	%sysfunc(exist(_list_sasautosfull))=0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Necessary dataset "_list_sasautosfull" does not exist!;
	%put	%str(N)OTE: [&L_mcrLABEL.]Macro "list_sasautos" will be executed instantly.;
	%list_sasautos
%end;

%*001.020.	Check whether to define the macro storage directory.;
%if	%length(%qsysfunc(compress(&absDIR.,%str( ))))	=	0	%then %do;
	%let	absDIR	=	1;
%end;
%let	whrDIR	=;
%if	%length(%qsysfunc(compress(&inDIR.,%str( ))))	^=	0	%then %do;
	%let	cmpDIR	=	&inDIR.;
	%let	lenDIR	=	%length(%superq(cmpDIR));
	%let	LDIRt	=	0;

	%if	&absDIR.	=	1	%then %do;
		%let	tmpDIR	=	&cmpDIR.;
		%let	tmplen	=	&lenDIR.;
		%do	%while	(&tmplen.	>	0);
			%let	LSTRi	=	0;
			%let	chkDIR	=	%qsubstr(%superq(tmpDIR),%length(%superq(tmpDIR)));
			%do	%until	(%index(&chkDIR.,%str(:))	=	2	or	&LSTRi.	=	&tmplen.);
				%let	chkDIR	=	%qsubstr(%superq(tmpDIR),%eval(%length(%superq(tmpDIR))-&LSTRi.));
				%let	LSTRi	=	%eval(&LSTRi.+1);
			%end;
			%if	%index(%superq(chkDIR),%str(:))	=	2	%then %do;
				%let	LDIRt			=	%eval(&LDIRt.+1);
				%local	sepDIR&LDIRt.;
				%let	sepDIR&LDIRt.	=	%qsysfunc(quote(&chkDIR.));
			%end;

			%let	tmpDIR	=	%qsysfunc(tranwrd(%superq(tmpDIR),%superq(chkDIR),%str( )));
			%let	tmplen	=	%length(%superq(tmpDIR));
		%end;
	%end;	%*end &absDIR.	=	1;
	%else %do;
		%let	tmpDIR	=	%qsysfunc(compbl(%superq(cmpDIR)));
		%let	tmplen	=	%length(%superq(tmpDIR));
		%let	LSTRi	=	1;
		%let	chkDIR	=	%QSCAN(%superq(tmpDIR),&LSTRi.,%STR( ));
		%local	sepDIR&LSTRi.;
		%let	sepDIR&LSTRi.	=	&chkDIR.;
		%DO %WHILE	(%superq(chkDIR) NE);
			%let	LSTRi	=	%EVAL(&LSTRi.+1);
			%let	chkDIR	=	%QSCAN(%superq(tmpDIR),&LSTRi.,%STR( ));
			%local	sepDIR&LSTRi.;
			%let 	sepDIR&LSTRi.	=	&chkDIR.;
		%END;
		%let	LDIRt	=	%EVAL(&LSTRi.-1);
	%end;

	%if	&LDIRt.	>	0	%then %do;
		%do	i=1	%to	&LDIRt.;
			%let	whrDIR	=	&whrDIR. or index(upcase(path),upcase(%sysfunc(quote(&&sepDIR&i..,%str(%'))))) > 0;
		%end;
		%*Remove the first "or".;
		%let	whrDIR	=	%qsubstr(%superq(whrDIR),4);
	%end;
%end;	%*end %bquote(&inDIR.)	^=	%str();;

%*001.030.	Check macro type.;
%let	whrTYPE	=;

%*001.040.	Check macro catalog.;
%let	whrCAT	=;

%*001.050.	Check macro name.;
%if	%length(%qsysfunc(compress(&inNAME.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No macro name or string in macro name is provided, the search bombed due to errors.;
	%goto	EndOfProc;
%end;
%if	&FUZZY.	=	1	%then %do;
	%let	NMidx	=	>0;
%end;
%else %do;
	%if	(%length(%qsysfunc(compress(&NMidx.,%str( ))))	=	0	or	&NMidx.	=	>0)	%then %do;
		%put	%str(N)OTE: [&L_mcrLABEL.]Missing index number for precise mode, it will be reset to 1.;
		%let	NMidx	=	1;
	%end;
	%let	NMidx	=	=&NMidx.;
%end;

%let	whrNAME	=;
%let	cmpNAME	=	%qsysfunc(compbl(&inNAME.));
%let	CCCC=1;
%let	WWWW=%QSCAN(&cmpNAME.,&CCCC.,%STR( ));
%local	LNM1;
%let	LNM1=%STR(&WWWW.);
%DO %WHILE(&WWWW. NE);
	%let	CCCC=%EVAL(&CCCC.+1);
	%let	WWWW=%QSCAN(&cmpNAME.,&CCCC.,%STR( ));
	%local	LNM&CCCC.;
	%let	LNM&CCCC.=%STR(&WWWW.);
%END;
%let	LNMt=%EVAL(&CCCC.-1);

%DO I=1 %TO &LNMt.;
	%let	whrNAME	=	&whrNAME. or index(upcase(member),upcase(%sysfunc(quote(&&LNM&I..,%str(%')))))	&NMidx.;
%END;
%*Remove the first "or".;
%let	whrNAME	=	%qsubstr(%superq(whrNAME),4);

%*001.100.	Check output variables.;
%if	%length(%qsysfunc(compress(&outMEL.,%str( ))))	=	0	%then	%let	outMEL	=	LMEL;
%if	%length(%qsysfunc(compress(&outMT.,%str( ))))	=	0	%then	%let	outMT	=	LMTTL;

%*001.110.	Check output dataset storing the found macro names.;
%if	%length(%qsysfunc(compress(&outLIB.,%str( ))))	=	0	%then	%let	outLIB	=	WORK;
%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))	=	0	%then	%let	outDAT	=	_sublistsasauto_;

%*010.	Generate the variables storing the macro names.;
%global	&outMT.;
%let	&outMT.	=	0;
data %unquote(&outLIB..&outDAT.);
	set
		_list_sasautosfull(
			where=(
					(%unquote(&whrNAME.))
			%if	%length(%qsysfunc(compress(&whrDIR.,%str( ))))	^=	0	%then %do;
				and	(%unquote(&whrDIR.))
			%end;
			%if	%length(%qsysfunc(compress(&whrTYPE.,%str( ))))	^=	0	%then %do;
				and	(type in (%unquote(&whrTYPE.)))
			%end;
			%if	%length(%qsysfunc(compress(&whrCAT.,%str( ))))	^=	0	%then %do;
				and	(catalog in (%unquote(&whrCAT.)))
			%end;
			)
		)
	;
run;

%getOBS4DATA(
	inDAT	=	&outLIB..&outDAT.
	,outVAR	=	&outMT.
)

%if	&&&outMT..	^=	0	%then %do;
	data _NULL_;
		set %unquote(&outLIB..&outDAT.) end=EOF;
		call symputx(cats("&outMEL.",_N_),tranwrd(member,".sas"," "),"G");
	run;
%end;
%else %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No matching macro name is found!;
%end;

%EndOfProc:
%mend getMCRbySTR;