%macro PermutationOf(
	List
	,SelectedPath	=
	,Execute		=	%nrstr(%put &SelectedPath;)
	,ByChar			=	%str( )
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to generate the full permutation of the listed items.														|
|	|IMPORTANT! Misuse of such set of macros could lead to infinite loops.																|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|List			:	The given list.																									|
|	|SelectedPath	:	The permutation result, please see the attachment for its usage.												|
|	|Execute		:	The process to execute for each item in the list.																|
|	|ByChar			:	The character list by which to scan the first member from the [list].											|
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
|	|Copyright is reserved for "PharmaSUG2011 ¨C Paper CC21", thanks to the authors.													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\Recursion"																							|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ForEach																														|
|	|	|ComplementOfWord																												|
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

%*100.	Permutation.;
%if	%length(%qsysfunc(compress(&List.,%str( ))))	=	0	%then %do;
	%unquote(&Execute.)
%end;
%Else %do;
	%ForEach(
		word
		,In		=	&List.
		,Do		=	%nrstr(
						%PermutationOf(
							%ComplementOfWord(
								&word.
								,In		=	&List.
								,ByChar	=	&ByChar.
							)
							,SelectedPath	=	&SelectedPath. &word.
							,Execute		=	&Execute.
							,ByChar			=	&ByChar.
						)
					)
		,ByChar	=	&ByChar.
	)
%end;

%EnfOfProc:
%mend PermutationOf;

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

%*100.	Do nothing:;
%PermutationOf(1 2 3 4,Execute=%nrstr())

%*200.	Do the default (output to Log file):;
%PermutationOf(1 2 3 4)

%*300.	Do the default plus count the number of permutation:;
%let c=0;
%PermutationOf(
	1 2 3 4
	,Execute=%nrstr(%let c=%eval(&c+1);%put &c: &SelectedPath;)
)

%*400.	Output the permutations to a SAS dataset for n=5:;
data Perm5;
	%PermutationOf(
		1 2 3 4 5
		,Execute=%nrstr(perm="&SelectedPath.";output;)
	)
run;

/*-Notes- -End-*/