%macro isDir(
	inMEM
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to identify whether the input OS member is Directory.														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inMEM		:	The OS member name to be identified.																				|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20170701		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170810		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Minimize the use of [SUPERQ] to avoid the excession of macro-quoting layers.												|
|	|      |Concept:																													|
|	|      |If some value is macro-quoted, its quoting status will be inherited to all the subsequent references unless it is modified	|
|	|      | by another macro function (adding additional characters before or after it will have no effect, e.g. [aa&bb.cc]).			|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180304		| Version |	1.20		| Updater/Creator |	Lu Robin Bin												|
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
%if	%length(%qsysfunc(compress(&inMEM.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No member is given for identification! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*013.	Define the local environment.;
%local
	outFlag
	filref
	filrc
	filID
;
%let	outFlag	=	0;
%let	filref	=	__tmpMem;

%*018.	Define the global environment.;

%*050.	Check member existence.;
%if	%sysfunc(fileexist(&inMEM.))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]The given member [&inMEM.] does not exist.;
	%let	outFlag	=;
	%goto	EndOfProc;
%end;

%*100.	Assign a file reference to the provided member.;
%let	filrc	=	%sysfunc(filename(filref,&inMEM.));

%*200.	Try to open the member as directory.;
%let	filID	=	%sysfunc(dopen(&filref.));

%*300.	Assign the output result if it is successfully opened as a directory.;
%if	%eval( &filID. > 0 )	%then %do;
	%*100.	Close the member as purge.;
	%let	filrc	=	%sysfunc(dclose(&filID.));

	%*900.	Generate the output result.;
	%let	outFlag	=	1;
%end;

%*900.	Purge memory usage.;
%let	filrc	=	%sysfunc(filename(filref));

%EndOfProc:
&outFlag.
%mend isDir;

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

%*100.	Testing.;
%put	%isDir(C:\Program Files);
%put	%isDir(C:\Program Files2);
%put	%isDir(C:\Program Files\Common Files\System\DirectDB.dll);

/*-Notes- -End-*/