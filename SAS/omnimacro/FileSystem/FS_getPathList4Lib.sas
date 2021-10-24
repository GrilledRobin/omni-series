%macro FS_getPathList4Lib(
	inDSN		=	WORK
	,outCNT		=	G_LstNO
	,outELpfx	=	G_LstEL
	,fDequote	=	0
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to search for all paths which are involved in the given Libname.											|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDSN		:	Folder name under which files should be searched.																	|
|	|outCNT		:	Number of paths found in the folder.																				|
|	|outELpfx	:	Prefix of macro variables, which will contain the found path names.													|
|	|fDequote	:	Indicator of whether to dequote the output result, [0] or [1].														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20130703		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20140412		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Slightly enhance the program efficiency.																					|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20160508		| Version |	1.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Add the option to output the result in Quoted Mode or Dequoted Mode.														|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170701		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Use [SUPERQ] to mask all references to the directory names, for there could be %nrstr(&) and %nrstr(%%) in the names.		|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170810		| Version |	2.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Minimize the use of [SUPERQ] to avoid the excession of macro-quoting layers.												|
|	|      |Concept:																													|
|	|      |If some value is macro-quoted, its quoting status will be inherited to all the subsequent references unless it is modified	|
|	|      | by another macro function (adding additional characters before or after it will have no effect, e.g. [aa&bb.cc]).			|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180304		| Version |	2.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20181117		| Version |	3.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Introduce the function [COUNTW] and the macro function [%QSCAN] to facilitate the extraction of the path names linked to	|
|	|      | the library.																												|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
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

%*012.	Handle the parameter buffer.;
%if	%length(%qsysfunc(compress(&inDSN.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No Libname is given for search of paths! Program searches for [WORK] instead;
	%let	inDSN	=	WORK;
%end;
%if	%length(%qsysfunc(compress(&outCNT.,%str( ))))		=	0	%then	%let	outCNT		=	G_LstNO;
%if	%length(%qsysfunc(compress(&outELpfx.,%str( ))))	=	0	%then	%let	outELpfx	=	G_LstEL;
%if	&fDequote.	^=	0	%then %do;
	%let	fDequote	=	1;
%end;

%*013.	Define the local environment.;
%local
	LchkLIBext
	LPathList
	nMembers
	Mi
;
%let	LchkLIBext		=;
%let	LPathList		=;

%global	&outCNT.;
%let	&outCNT.	=	0;

%*050.	Check Libname existence.;
%let	LchkLIBext	=	%qsysfunc(pathname(&inDSN.));
%if	%length(%qsysfunc(compress(&LchkLIBext.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Given libname [&inDSN.] is invalid! Program ends with no output.;
	%goto	EndOfProc;
%end;

%*100.	Retrieve the path list.;
%*If there are more than one directories assigned to the same library, they will be quoted and shown in parentheses,;
%* otherwise, the name will NOT be placed between parentheses.;
%if	%index(&LchkLIBext.,%str(%())	=	1	and	%index(&LchkLIBext.,%str(%)))	=	%length(&LchkLIBext.)	%then %do;
	%*100.	Remove the surrounding parentheses;
	%let	LPathList	=	%qsubstr( &LchkLIBext. , 2 , %eval( %length(&LchkLIBext.) - 2 ) );

	%*200.	Count the members that linked to this library.;
	%let	nMembers	=	%sysfunc(countw( &LPathList. , %str( ) , qs ));

	%*300.	Extract each member.;
	%do Mi = 1 %to &nMembers.;
		%let	&outCNT.	=	%eval( &&&outCNT.. + 1 );
		%global	&outELpfx.&&&outCNT..;
		%let	&outELpfx.&&&outCNT..	=	%qsysfunc(dequote( %qscan( &LPathList. , &Mi. , %str( ) , qs ) ));
	%end;
%end;
%else %do;
	%let	&outCNT.	=	%eval( &&&outCNT.. + 1 );
	%global	&outELpfx.&&&outCNT..;
	%let	&outELpfx.&&&outCNT..	=	%qsysfunc(strip( &LchkLIBext. ));
%end;

%*200.	Add single quotation marks as requested.;
%if	&fDequote.	=	0	%then %do;
	%do Mi = 1 %to &&&outCNT..;
		%let	&outELpfx.&Mi.	=	%sysfunc(quote( &&&outELpfx.&Mi.. , %str(%') ));
	%end;
%end;

%EndOfProc:
%mend FS_getPathList4Lib;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvOp"
		"D:\SAS\omnimacro\FileSystem"
	)
	mautosource
;

%*100.	Create libraries.;
%let	HomePath	=	D:\SAS\omnimacro\AdvOp;
libname	test	"&HomePath.\test";

%getMemberByStrPattern(
	inDIR		=	%nrbquote(&HomePath.)
	,inRegExp	=
	,exclRegExp	=
	,chkType	=	2
	,FSubDir	=	1
	,mNest		=	0
	,outCNT		=	GnDir
	,outELpfx	=	GeDir
	,outElTpPfx	=	GtDir
)
libname	test2	"&GeDir2.";
libname	full	(
	"&HomePath."
	test
	test2
);

%*200.	Find all paths for the library [full].;
%FS_getPathList4Lib(
	inDSN		=	full
	,outCNT		=	GnPath
	,outELpfx	=	GePath
	,fDequote	=	1
)
%macro a;
%do i=1 %to &GnPath.;
	%put	GePath&i.=[&&GePath&i..];
%end;
%mend a;
%a

%*300.	Find all paths for the library [test2].;
%FS_getPathList4Lib(
	inDSN		=	test2
	,outCNT		=	GnPath
	,outELpfx	=	GePath
	,fDequote	=	1
)
%macro a;
%do i=1 %to &GnPath.;
	%put	GePath&i.=[&&GePath&i..];
%end;
%mend a;
%a

/*-Notes- -End-*/