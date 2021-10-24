%macro MarkArg4BYVAR(
	inlst		=
	,chkArg		=	0
	,ArgLst		=	DESCENDING
	,nVarTTL	=	G_nByVar
	,eVarPfx	=	G_eByVar
	,OchkArg	=	G_AeByVar
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to precisely split the variable list [inlst] by removing the explicit										|
|	| argument (Probably "descending") and marking the direct-following variable.														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inlst		:	The list to be split, with the separator as WHITE SPACES (BLANKS).													|
|	|				E.g. "a descending b c", "a: descending b: c.+"																		|
|	|chkArg		:	The indicator of whether to check the grammar of the preceding argument. {0,1}										|
|	|ArgLst		:	The list of arguments to be identified and pruned.																	|
|	|nVarTTL	:	The global macro variable containing the number of items being split.												|
|	|eVarPfx	:	The prefix of a series of global macro variables, whose values are the names of the split items.					|
|	|				E.g. "G_eByVar1 -> a:", "G_eByVar2 -> c.+"																			|
|	|OchkArg	:	The output argument for each item if any.																			|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20150204		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170810		| Version |	1.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Minimize the use of macro quoting functions to avoid the overflow of macro-quoting layers.									|
|	|      |Concept:																													|
|	|      |If some value is macro-quoted, its quoting status will be inherited to all the subsequent references unless it is modified	|
|	|      | by another macro function (adding additional characters before or after it will have no effect, e.g. [aa&bb.cc]).			|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180310		| Version |	1.30		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|If the output list is used in BY statement, or imperatively removing "DESCENDING" argument,										|
|	| the [chkArg] must be set as 1.																									|
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

%if	&chkArg.	^=	1	%then	%let	chkArg	=	0;
%if	%length(%qsysfunc(compress(&ArgLst.,%str( ))))	=	0	%then	%let	ArgLst	=	DESCENDING;
%if	%length(%qsysfunc(compress(&nVarTTL.,%str( ))))	=	0	%then	%let	nVarTTL	=	G_nByVar;
%if	%length(%qsysfunc(compress(&eVarPfx.,%str( ))))	=	0	%then	%let	eVarPfx	=	G_eByVar;
%if	%length(%qsysfunc(compress(&OchkArg.,%str( ))))	=	0	%then	%let	OchkArg	=	G_AeByVar;

%*090.	Parameters;
%global
	&nVarTTL.
	&eVarPfx.1
	&OchkArg.1
;
%local
	lstclean
	cntALL
	itmALL
	cntchkArg

;
%let	&OchkArg.1	=;
%let	cntchkArg	=	0;

%*100.	Clean up the list by removing extra blanks.;
%let	lstclean	=	%qsysfunc(compbl(&inlst.));

%*200.	Find the first VALID item.;
%*210.	Find the first item.;
%let	cntALL		=	1;
%let	itmALL		=	%QSCAN(&lstclean.,&cntALL.,%STR( ));

%*220.	Verify it against the [chkArg] argument.;
%if	&chkArg.	=	1	%then %do;
	%if	%index(%qupcase(&ArgLst.),%qupcase(%qsubstr(&itmALL.,1)))	%then %do;
		%*100.	Set the number of argumented items.;
		%let	cntchkArg	=	1;

		%*200.	Set the argument for the first valid item.;
		%let	&OchkArg.1	=	%qupcase(%qsubstr(&itmALL.,1));

		%*200.	Retrieve the direct-following item as the first valid one.;
		%let	itmALL		=	%QSCAN(&lstclean.,%eval(&cntALL. + &cntchkArg.),%STR( ));
	%end;
%end;

%*290.	Generate the first valid item.;
%let	&eVarPfx.1	=	%qsubstr(&itmALL.,1);
%*I do not know why I have to use %substr here! but this will prevent some field-creation problem during data step and proc sql.;

%*300.	Retrieve the rest items.;
%DO %WHILE(&itmALL. NE);
	%*100.	Increment the counter.;
	%let	cntALL	=	%EVAL(&cntALL. + 1);

	%*200.	Retrieve the next item.;
	%let	itmALL	=	%QSCAN(&lstclean.,%eval(&cntALL. + &cntchkArg.),%STR( ));

	%*300.	Quit the loop if the current item is NULL.;
	%if	%length(%qsysfunc(compress(&itmALL.,%str( ))))	=	0	%then	%goto	endLoop;

	%*400.	Create flag for current item about whether it is "descending".;
	%global	&OchkArg.&cntALL.;
	%let	&OchkArg.&cntALL.	=;

	%*500.	Verify the current item against the [chkArg] argument.;
	%if	&chkArg.	=	1	%then %do;
		%if	%index(%qupcase(&ArgLst.),%qupcase(%qsubstr(&itmALL.,1)))	%then %do;
			%*100.	Set the number of "descending" items.;
			%let	cntchkArg			=	%eval(&cntchkArg. + 1);

			%*200.	Set the argument for the first valid item.;
			%let	&OchkArg.&cntALL.	=	%qupcase(%qsubstr(&itmALL.,1));

			%*300.	Retrieve the direct-following item as the first valid one.;
			%let	itmALL				=	%QSCAN(&lstclean.,%eval(&cntALL. + &cntchkArg.),%STR( ));
		%end;
	%end;

	%*600.	;
	%GLOBAL	&eVarPfx.&cntALL.;
	%let	&eVarPfx.&cntALL.	=	%qsubstr(&itmALL.,1);
%END;
%endLoop:
%let	&nVarTTL.	=	%EVAL(&cntALL. - 1);

%EndOfProc:
%mend MarkArg4BYVAR;