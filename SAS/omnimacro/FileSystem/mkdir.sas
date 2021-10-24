%macro mkdir(
	inDIR
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to create a directory under current O/S, without having to leverage the O/S scripts, such as DOS.			|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDIR		:	The OS directory full path to be created.																			|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20181015		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\FileSystem"																						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|OSDirDlm																														|
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
%if	%length(%qsysfunc(compress(&inDIR.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No member is given for identification! Program skipped.;
%end;

%*013.	Define the local environment.;
%local
	tmpDir
	parDir
	curDir
	newDir
;
%let	tmpDir	=	&inDIR.;
%let	parDir	=;
%let	curDir	=;
%let	newDir	=;

%*018.	Define the global environment.;

%*060.	Skip the process if all characters in the name are the same as [Naming Delimiter] under current O/S.;
%if	%sysfunc(count( &tmpDir. , %OSDirDlm ))	=	%length( &tmpDir. )	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]The directory name is invalid or a root path. Program skipped.;
	%goto	EndOfProc;
%end;

%*070.	Remove the clogging trailing [Naming Delimiters] if any.;
%do %while( %qsubstr( &tmpDir. , %length( &tmpDir. ) ) = %OSDirDlm );
	%let	tmpDir	=	%qsubstr( &tmpDir. , 1 , %length( &tmpDir. ) - 1 );
%end;

%*100.	Check directory existence.;
%if	%sysfunc(fileexist(&tmpDir.))	=	1	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]The given directory [&tmpDir.] exists.;
	%goto	EndOfProc;
%end;

%*150.	Skip the process if the name represents a root directory on current hard drive under current O/S.;
%if	%index( &tmpDir. , %OSDirDlm )	=	0	or	&tmpDir.	=	%OSDirDlm	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]The root path [&tmpDir.] does not exist! Failed to create it.;
	%goto	EndOfProc;
%end;

%*200.	Split the path name by the [parent directory] and [current directory].;
%let	curDir	=	%qscan( &tmpDir. , -1 , %OSDirDlm );
%let	parDir	=	%qsubstr( &tmpDir. , 1 , %eval( %length( &tmpDir. ) - %length( &curDir. ) ) );
%if	%sysfunc(count( &tmpDir. , %OSDirDlm ))	=	%length( &tmpDir. )	%then %do;
	%let	parDir	=;
%end;
%else %do;
	%do %while( %qsubstr( &parDir. , %length( &parDir. ) ) = %OSDirDlm );
		%let	parDir	=	%qsubstr( &parDir. , 1 , %length( &parDir. ) - 1 );
	%end;
%end;
%*We append a single [Naming Delimiter] to the trail of [parent directory].;
%let	parDir	=	&parDir.%OSDirDlm;

%*300.	Create the [parent directory] if it does not exist.;
%*Call the same function recursively to create it.;
%mkdir( &parDir. )

%*400.	Skip the process if the [parent directory] cannot be created.;
%if	%sysfunc(fileexist(&parDir.))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]Failed to create the directory [&tmpDir.];
	%goto	EndOfProc;
%end;

%*800.	Create [current directory].;
%let	newDir	=	%qsysfunc(dcreate( &curDir. , &parDir. ));

%EndOfProc:
%mend mkdir;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\FileSystem"
	)
	mautosource
;

%*100.	Testing.;
%mkdir(D:\test)
%mkdir(D:\test2\aaa)
%mkdir(D:\)

/*-Notes- -End-*/