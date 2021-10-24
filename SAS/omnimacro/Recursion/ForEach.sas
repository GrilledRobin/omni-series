%macro ForEach(
	ItemRef
	,In		=
	,Do		=	%nrstr(/* Nothing */)
	,ByChar	=	%str( )
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to iterate each word [ItemRef] in the given list and apply certain											|
|	| processes to them one-by-one.																										|
|	|IMPORTANT! Misuse of such set of macros could lead to infinite loops.																|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|ItemRef	:	The soft reference item to be called in each nesting layer.															|
|	|				 [IMPORTANT]: The input SHOULD NOT be "ItemRef" itself!																|
|	|In			:	The list of items to be iterated by applying certain same processes.												|
|	|Do			:	The certain process that is to be applied to each [ItemRef] in the give list.										|
|	|ByChar		:	The character list by which to split the [In] into separate [ItemRef].												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20160528		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170730		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Use [SUPERQ] to mask the input character string, for there could be %nrstr(&) and %nrstr(%%) in the words.					|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170810		| Version |	1.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Minimize the use of [SUPERQ] to avoid the excession of macro-quoting layers.												|
|	|      |Concept:																													|
|	|      |If some value is macro-quoted, its quoting status will be inherited to all the subsequent references unless it is modified	|
|	|      | by another macro function (adding additional characters before or after it will have no effect, e.g. [aa&bb.cc]).			|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180311		| Version |	1.30		| Updater/Creator |	Lu Robin Bin												|
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
|	|	|ExceptTheFirstWord_SubListOf																									|
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

%*100.	Iterate each [ItemRef] in the list by applying the process.;
%if	&In.	^=	%then %do;
	%*100.	Set the value of the [ItemRef] as the first word of the given list.;
	%let	&ItemRef.	=	%TheFirstWordOf(List=&In.,ByChar=&ByChar.);

	%*200.	Conduct the process to at current iteration.;
	%unquote(&Do.)

	%*900.	Call the same function to apply the same process to the rest of the [ItemRef].;
	%ForEach(
		&ItemRef.
		,In		=	%ExceptTheFirstWord_SubListOf(List=&In.,ByChar=&ByChar.)
		,Do		=	&Do.
		,ByChar	=	&ByChar.
	)
%end;

%EnfOfProc:
%mend ForEach;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvOp"
		"D:\SAS\omnimacro\Recursion"
	)
	mautosource
;

%ForEach(
	Word
	,In		=	%str(a,b,c)
	,Do		=	%nrstr(%put	ItemRef = &Word.;)
	,ByChar	=	%str(,)
)

/*-Notes- -End-*/