%macro ComplementOfWord(
	w
	,In		=
	,ByChar	=	%str( )
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to generate a sublist from the given [In] by removing all the distinct word [w].							|
|	|IMPORTANT! Misuse of such set of macros could lead to infinite loops.																|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|w		:	The word that is to be removed from the given list of words.															|
|	|In		:	The list of words, from which we should do the removal.																	|
|	|ByChar	:	The character list by which to split the [In] into separate [ItemRef].													|
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
%local
	_1stWord
	_tmpStr
	_Char
;
%let	_tmpStr	=;

%*100.	Create the sublist that do not contain the given word [w].;
%*110.	Skip the further process if the input string is NULL.;
%if	%length(%qsysfunc(compress(&In.,%str( ))))	=	0	%then %do;
	%goto	EndOfIn;
%end;

%*120.	Retrieve the first word within the list.;
%let	_1stWord	=	%TheFirstWordOf( List = &In. , ByChar = &ByChar. );

%*130.	Return it if it is NOT the same as the given word [w].;
%*If there are more than one character as [ByChar], we put the first one here, then;
%*We do not combine below expressions so that it is easy for readers to understand.;
%if	&_1stWord.	^=	&w.	%then %do;
	%let	_tmpStr	=	&_1stWord.%qsubstr(&ByChar.,1,1);
%end;

%*140.	Search through the rest of the list by retrieving the complement of the given word [w].;
%let	_tmpStr	=	&_tmpStr.%ComplementOfWord(
						&w.
						,In		=	%ExceptTheFirstWord_SubListOf( List = &In. , ByChar = &ByChar. )
						,ByChar	=	&ByChar.
					)
;

%*190.	Remove the trailing [ByChar].;
%if	%length(%qsysfunc(compress(&_tmpStr.,%str( ))))	=	0	%then	%goto	EndOfIn;
%let	_Char	=	%qsubstr(&_tmpStr.,%length(&_tmpStr.));
%do %while( %index(&ByChar.,&_Char.) and %length(&_tmpStr.) > 1 );
	%let	_tmpStr	=	%qsubstr(&_tmpStr.,1,%eval(%length(&_tmpStr.) - 1));
	%let	_Char	=	%qsubstr(&_tmpStr.,%length(&_tmpStr.));
%end;

%*199.	Mark the end of the string processing.;
%EndOfIn:

%*400.	Output as a sublist.;
&_tmpStr.

%EnfOfProc:
%mend ComplementOfWord;

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

%put	%ComplementOfWord(
			b
			,In		=	%str(a,b,d,b,c)
			,ByChar	=	%str(,)
		)
;
%put	%ComplementOfWord(
			b
			,In		=	%str(b,a,d,c,b)
			,ByChar	=	%str(,)
		)
;

/*-Notes- -End-*/