%macro ExceptTheFirstWord_SubListOf(
	List	=
	,ByChar	=	%str( )
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to retrieve the substring from the given list by pruning away the first word.								|
|	|IMPORTANT! Misuse of such set of macros could lead to infinite loops.																|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|List	:	The given list.																											|
|	|ByChar	:	The character list by which to scan the first member from the [list].													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20160528		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170729		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Use [SUPERQ] to mask the input character string, for there could be %nrstr(&) and %nrstr(%%) in the words.					|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170810		| Version |	1.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Minimize the use of [SUPERQ] to avoid the overflow of macro-quoting layers.													|
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
|	|Please find the attachments for examples.																							|
|	|Copyright is reserved for "PharmaSUG2011 ¨C Paper CC21", thanks to the authors.													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|TheFirstWordOf																													|
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
%if	%length(%qsysfunc(compress(&ByChar.,%str( ))))	=	0	%then	%let	ByChar	=	%str( );

%*013.	Define the local environment.;
%local
	L
	LtmpString
	LChar
;

%*100.	Should there be only one word in the list, we do nothing.;
%let	L	=	%length(%TheFirstWordOf(List=&List.,ByChar=&ByChar.));
%if	&L.	=	%length(&List.)	%then %do;
	%goto	EnfOfProc;
%end;

%*200.	Retrieve the rest of the list except the first word.;
%let	LtmpString	=	%qsubstr(&List.,%eval(1+&L.));

%*300.	Prune away the leading characters that match the [ByChar].;
%let	LChar	=	%qsubstr(&LtmpString.,1,1);
%do %while( %index(&ByChar.,&LChar.) and %length(&LtmpString.) > 1 );
	%let	LtmpString	=	%qsubstr(&LtmpString.,2);
	%let	LChar		=	%qsubstr(&LtmpString.,1,1);
%end;

%*310.	We set the final output as BLANK, should all the characters are declared in [ByChar].;
%if	%index(&ByChar.,&LtmpString.)	%then %do;
	%let	LtmpString	=;
%end;

%*400.	Output as a sublist.;
&LtmpString.

%EnfOfProc:
%mend ExceptTheFirstWord_SubListOf;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvOp"
	)
	mautosource
;

%let	b	=	%ExceptTheFirstWord_SubListOf(List=%nrstr(a&b&c),ByChar=%nrstr(&));
%put	b	=	[&b.];

/*-Notes- -End-*/