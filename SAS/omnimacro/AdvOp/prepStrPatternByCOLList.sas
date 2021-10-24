%macro prepStrPatternByCOLList(
	COLlst		=
	,chkArg		=	0
	,ArgLst		=	DESCENDING
	,nPTN		=	G_nPTN
	,ePTN		=	G_ePTN
	,OchkArg	=	G_AePTN
	,outPTN		=
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to generate a string pattern to facilitate the call of below macro:											|
|	| "getCOLbyStrPattern"																												|
|	|That is, if a naming list in SAS convention is provided, we should call this macro before calling									|
|	| "getCOLbyStrPattern"																												|
|	|Especially, this macro translates the SAS pattern (C_:) into RegExp pattern (C_\w*)												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|COLlst		:	The variable or field name (pattern) list to be dropped.															|
|	|				 Examples: 1. %nrbquote(C_: .+KPI.+), 2. %nrbquote(D_TABLE C_:).													|
|	|chkArg		:	The indicator of whether to check the grammar of the preceding argument. {0,1}										|
|	|ArgLst		:	The list of arguments to be identified and pruned.																	|
|	|nPTN		:	The global macro variable containing the number of items being split.												|
|	|ePTN		:	The prefix of a series of global macro variables, whose values are the names of the split items.					|
|	|				E.g. "ePTN1 -> a:", "ePTN2 -> c.+"																					|
|	|OchkArg	:	The output argument for each item if any.																			|
|	|outPTN		:	It is a combined RegExp with all [eVarPfx] separated by vertical bars (|).											|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20150109		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20150204		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Add the verification against the argument for the variables, such as "descending".											|
|	|      |For some instances, we should keep the preceding arguments to respective items in correspondence,							|
|	|      | hence we should keep the original sequence of RegExp for separate handling.												|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170810		| Version |	2.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Minimize the use of macro quoting functions to avoid the overflow of macro-quoting layers.									|
|	|      |Concept:																													|
|	|      |If some value is macro-quoted, its quoting status will be inherited to all the subsequent references unless it is modified	|
|	|      | by another macro function (adding additional characters before or after it will have no effect, e.g. [aa&bb.cc]).			|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180310		| Version |	2.20		| Updater/Creator |	Lu Robin Bin												|
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
|	|	|MarkArg4BYVAR																													|
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
%if	%length(%qsysfunc(compress(&COLlst.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No Variable or Field is specified.;
	%goto	EndOfProc;
%end;
%if	%length(%qsysfunc(compress(&outPTN.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No output macro variable is specified.;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	&chkArg.	^=	1	%then	%let	chkArg	=	0;
%if	%length(%qsysfunc(compress(&ArgLst.,%str( ))))	=	0	%then	%let	ArgLst	=	DESCENDING;
%if	%length(%qsysfunc(compress(&nPTN.,%str( ))))	=	0	%then	%let	nPTN	=	G_nPTN;
%if	%length(%qsysfunc(compress(&ePTN.,%str( ))))	=	0	%then	%let	ePTN	=	G_ePTN;
%if	%length(%qsysfunc(compress(&OchkArg.,%str( ))))	=	0	%then	%let	OchkArg	=	G_AePTN;
%let	&outPTN.	=;

%*013.	Define the local environment.;
%local
	ptnBGN
	ptnEND
	rxPURGE
	LePtn
	ELi
	ELptn
;
%let	ptnBGN	=	%str(^);
%let	ptnEND	=	$;
%let	rxPURGE	=	%sysfunc(prxparse(s/^\&ptnBGN.?(.*)\&ptnEND.?$/\1/i));
%let	LePtn	=;
%let	ELptn	=;
%MarkArg4BYVAR(
	inlst		=	&COLlst.
	,chkArg		=	&chkArg.
	,ArgLst		=	&ArgLst.
	,nVarTTL	=	&nPTN.
	,eVarPfx	=	LePtn
	,OchkArg	=	&OchkArg.
)

%*100.	Create pattern in terms of Regular Expression.;
%do	ELi=1	%to	&&&nPTN..;
	%*001.	Remove any possible leading (^) and trailing ($) for Regular Expression standardization.;
	%let	LePtn	=	%qsysfunc(prxchange(&rxPURGE.,-1,%nrbquote(&&LePtn&ELi..)));

	%*010.	Validate the given pattern.;
	%*Should the colon exists in the middle of the pattern, we regard it as invalid.;
	%if	%index(&LePtn.,%str(:))	^=	0	%then %do;
		%if	%index(&LePtn.,%str(:))	^=	%length(&LePtn.)	%then %do;
			%put	%str(E)RROR: [&L_mcrLABEL.]Colon is used out of proper order, pattern match failed!;
			%put	&Lohno.;
			%ErrMcr
		%end;
	%end;

	%*100.	Should there be input in the same pattern as "var:", it indicates that;
	%*       we should detect all variables with the leading characters.;
	%let	ELptn	=	&ptnBGN.%qsysfunc(tranwrd(&LePtn.,%str(:),%str(\w*)))&ptnEND.;

	%*200.	Prepare the pattern.;
	%*210.	Create each element.;
	%global	&ePTN.&ELi.;
	%let	&ePTN.&ELi.	=	&ELptn.;

	%*290.	Create a single combined pattern.;
	%let	&outPTN.	=	&&&outPTN..|(&ELptn.);
%end;
%EndGenPtn:
%let	&outPTN.	=	%qsubstr(&&&outPTN..,2);

%*900.	Purge memory usage.;
%*910.	Release PRX utilities.;
%ReleasePRX:
%syscall prxfree(rxPURGE);

%EndOfProc:
%mend prepStrPatternByCOLList;