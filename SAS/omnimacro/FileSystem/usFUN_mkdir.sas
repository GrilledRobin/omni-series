%macro usFUN_mkdir;
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to create a directory under current O/S, without having to leverage the O/S scripts, such as DOS.			|
|	|The function is defined by PCmp Procedure, so its scope is limited by FCmp Procedure.												|
|	|It is tested that PUT statements (to write messages in LOG) would cause "PROC UNKNOWN is running" when the function is called		|
|	| in Macro Facility. Hence we remove them.																							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDIR		:	The OS directory full path to be created.																			|
|	|OSDirDlm	:	The delimiter to connect the member name to its parent directory under current O/S									|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20181016		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Return Values:	[Numeric]																											|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|[0]	:	The directory is successfully created																					|
|	|[-1]	:	The directory cannot be created																							|
|	|[-10]	:	Indicates that the parameter [OSDirDlm] is not provided																	|
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

%*013.	Define the local environment.;

%*100.	Function that identifies whether the provided OS member is Directory.;
function
	mkdir(
		inDIR		$
		,OSDirDlm	$
	)
;
	%*020.	Verify parameters.;
	if	missing(OSDirDlm)	then	return(-10);

	%*050.	Declare internal fields.;
	attrib
		rc		length=8
		tmpDir	length=$32767
		parDir	length=$32767
		curDir	length=$32767
		newDir	length=$32767
	;
	tmpDir	=	inDIR;
	call missing( parDir , curDir , newDir );

	%*060.	Skip the process if all characters in the name are the same as [Naming Delimiter] under current O/S.;
	if	count( tmpDir , strip(OSDirDlm) )	=	length( tmpDir )	then do;
		goto	EndOfFunc;
	end;

	%*070.	Remove the clogging trailing [Naming Delimiters] if any.;
	do while( substr( tmpDir , length( tmpDir ) ) = strip(OSDirDlm) );
		tmpDir	=	substr( tmpDir , 1 , length( tmpDir ) - 1 );
	end;

	%*100.	Check directory existence.;
	if	fileexist(tmpDir)	=	1	then do;
		goto	EndOfFunc;
	end;

	%*150.	Skip the process if the name represents a root directory on current hard drive under current O/S.;
	if	index( tmpDir , strip(OSDirDlm) )	=	0	or	tmpDir	=	strip(OSDirDlm)	then do;
		goto	EndOfFunc;
	end;

	%*200.	Split the path name by the [parent directory] and [current directory].;
	curDir	=	scan( tmpDir , -1 , strip(OSDirDlm) );
	parDir	=	substr( tmpDir , 1 , length( tmpDir ) - length( curDir ) );
	if	count( tmpDir , strip(OSDirDlm) )	=	length( tmpDir )	then do;
		call missing(parDir);
	end;
	else do;
		do while( substr( parDir , length( parDir ) ) = strip(OSDirDlm) );
			parDir	=	substr( parDir , 1 , length( parDir ) - 1 );
		end;
	end;
	%*We append a single [Naming Delimiter] to the trail of [parent directory].;
	parDir	=	cats( parDir , strip(OSDirDlm) );

	%*300.	Create the [parent directory] if it does not exist.;
	%*Call the same function recursively to create it.;
	rc	=	mkdir( parDir , OSDirDlm );

	%*400.	Skip the process if the [parent directory] cannot be created.;
	if	fileexist(parDir)	=	0	then do;
		goto	EndOfFunc;
	end;

	%*800.	Create [current directory].;
	newDir	=	dcreate( curDir , parDir );

	%*900.	Finish the definition of the function.;
	EndOfFunc:
	if	missing(newDir)	=	0	then do;
		return(0);
	end;
	else do;
		return(-1);
	end;
endsub;

%*900.	Purge memory usage.;

%EndOfProc:
%mend usFUN_mkdir;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\FileSystem"
	)
	mautosource
;

%*090.	This step ensures there is no WARNING message issued when executing the FCmp Procedure.;
options
	cmplib=_NULL_
;

%*100.	Compile the function as defined in the macro.;
proc FCmp
	outlib=work.fso.FS
;

	%usFUN_mkdir

run;
quit;

%*200.	Tell the program where to find the compiled functions.;
options
	cmplib=work.fso
;

%*300.	Test in Dataset.;
data a;
	length	dir	$256.;
	dir	=	"D:\test";	output;
	dir	=	"D:\test2\aaa";	output;
	dir	=	"D:\";	output;
run;
data b;
	set a;
	f_suc	=	mkdir( dir , "%OSDirDlm" );
run;

%*400.	Test in Macro Facility.;
%put	%sysfunc(mkdir( D:\test2\bbb ,%OSDirDlm ));

/*-Notes- -End-*/