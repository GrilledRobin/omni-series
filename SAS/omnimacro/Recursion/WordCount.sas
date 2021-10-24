%macro WordCount(
	inStr
	,CI			=	Y
	,ByChar		=	%str( )
	,mNest		=	0
	,outCNT		=	G_LstNO
	,outELpfx	=	G_LstEL
	,outKpfx	=	GkLstEL
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to count the number of each word that shows up in [inStr] and return a set of macro variables holding their	|
|	| respective counts.																												|
|	|IMPORTANT! Misuse of such set of macros could lead to infinite loops.																|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inStr		:	The list of words, from which we should count the distinct words.													|
|	|				 IMPORTANT: There cannot be any leading separators among the [ByChar] in this string!!!								|
|	|CI			:	Whether to ignore the case of words. [Y] - Case Insensitive, [N] - Case Sensitive.									|
|	|ByChar		:	The character list by which to split the [inStr].																	|
|	|mNest		:	[M]th Level of Nesting Call of the same macro, which is zero at the first call.										|
|	|outCNT		:	Number of unique words found in [inStr].																			|
|	|outELpfx	:	Prefix of macro variables, which will contain the unique words.														|
|	|outKpfx	:	Prefix of macro variables, which will contain the counts of the correspondent words.								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20180114		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180311		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
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
|	|	|ErrMcr																															|
|	|	|TheFirstWordOf																													|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
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
%if	%index( #Y#N# , #%qupcase(&CI.)# )	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.][CI=&CI.] is NOT accepted! Provide [Y] to imply Case Insensitive, or [N] for Case Sensitive!;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&ByChar.,%str( ))))		=	0	%then	%let	ByChar		=	%str( );
%if	%length(%qsysfunc(compress(&mNest.,%str( ))))		=	0	%then	%let	mNest		=	0;
%if	%length(%qsysfunc(compress(&outCNT.,%str( ))))		=	0	%then	%let	outCNT		=	G_LstNO;
%if	%length(%qsysfunc(compress(&outELpfx.,%str( ))))	=	0	%then	%let	outELpfx	=	G_LstEL;
%if	%length(%qsysfunc(compress(&outKpfx.,%str( ))))		=	0	%then	%let	outKpfx		=	GkLstEL;

%*013.	Define the local environment.;
%local
	NextL
	_Word
	_tmpStr
	Wi
	cnt
;
%let	NextL	=	%eval(&mNest. + 1);
%if	%qupcase(&CI.)	=	Y	%then %do;
	%let	inStr	=	%qlowcase(&inStr.);
%end;

%*018.	Define the global environment.;
%global	&outCNT.;
%let	&outCNT.	=	0;

%*090.	Skip the process if the input [inStr] is NULL.;
%let	inStr	=	%qsysfunc(compbl(&inStr.));
%if	%length(%qsysfunc(compress(&inStr.,%str( ))))	=	0	%then %do;
	%goto	EndOfProc;
%end;

%*100.	Retrieve the first word within the list.;
%let	&outCNT.	=	%eval(&&&outCNT.. + 1);
%global	&outELpfx.&&&outCNT..;
%let	&outELpfx.&&&outCNT..	=	%TheFirstWordOf( List = &inStr. , ByChar = &ByChar. );

%*200.	Count the occurences of this word in [inStr].;
%*We cannot use [COUNT] function, for it does not verify the bounds of words.;
%*We cannot use [Perl Regular Expression], for there could be unknown metacharacters to be escaped.;
%global	&outKpfx.&&&outCNT..;
%let	&outKpfx.&&&outCNT..	=	0;
%ForEach(
	_Word
	,In		=	&inStr.
	,Do		=	%nrstr(
					%let	&outKpfx.&&&outCNT..	=	%sysfunc(ifn(
															&_Word. = &&&&&outELpfx.&&&outCNT...
															,%eval( &&&&&outKpfx.&&&outCNT... + 1 )
															,&&&&&outKpfx.&&&outCNT...
														))
					;
				)
	,ByChar	=	&ByChar.
)

%*300.	Retrieve the sublist as the complement of this word.;
%let	_tmpStr	=	%ComplementOfWord( &&&&&outELpfx.&&&outCNT... , In = &inStr. , ByChar = &ByChar. );

%*390.	Skip the increment of the result if the complement of this word in [inStr] is NULL.;
%if	%length(&_tmpStr.)	=	0	%then %do;
	%goto	EnfOfProc;
%end;

%*400.	Count the rest words in the complement list.;
%*410.	Call the same macro to count the rest words.;
%WordCount(
	&_tmpStr.
	,CI			=	&CI.
	,ByChar		=	&ByChar.
	,mNest		=	&NextL.
	,outCNT		=	TnWord&NextL.
	,outELpfx	=	TeWord&NextL._
	,outKpfx	=	TkWord&NextL._
)

%*450.	Add the unique words to the list of findings.;
%do Wi = 1 %to &&TnWord&NextL..;
	%let	cnt	=	%eval( &&&outCNT.. + &Wi. );
	%global
		&outELpfx.&cnt.
		&outKpfx.&cnt.
	;
	%let	&outELpfx.&cnt.	=	&&TeWord&NextL._&Wi..;
	%let	&outKpfx.&cnt.	=	&&TkWord&NextL._&Wi..;
%end;

%*460.	Increment the number of unique words that are identified.;
%let	&outCNT.	=	%eval(&&&outCNT.. + &&TnWord&NextL..);

%EnfOfProc:
%mend WordCount;

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
%macro printTest;
%do Wi=1 %to &nWrds.;
	%put	[[eWrds&Wi.] = [&&eWrds&Wi.]][[kWrds&Wi.] = [&&kWrds&Wi.]];
%end;
%mend printTest;

%*100.	Normal sentence.;
%let	str	=	%nrstr(I am a pilot, you are a Pilot, too.);
%WordCount(
	&str.
	,CI			=	N
	,ByChar		=	%str( ,.)
	,mNest		=	0
	,outCNT		=	nWrds
	,outELpfx	=	eWrds
	,outKpfx	=	kWrds
)
%printTest

%*200.	Sentence with abnormal character case.;
%let	str	=	%nrstr(I am a pilot, you are A Pilot, too.);
%WordCount(
	&str.
	,CI			=	y
	,ByChar		=	%str( ,.)
	,mNest		=	0
	,outCNT		=	nWrds
	,outELpfx	=	eWrds
	,outKpfx	=	kWrds
)
%printTest

/*-Notes- -End-*/