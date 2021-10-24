%macro usFUN_OSMemType;
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to return a numeric figure for the provided OS member telling whether it is a File or Directory, or return	|
|	| a missing value if it cannot be identified.																						|
|	|The function is defined by PCmp Procedure, so its scope is limited by FCmp Procedure.												|
|	|It is tested that PUT statements (to write messages in LOG) would cause "PROC UNKNOWN is running" when the function is called		|
|	| in Macro Facility. Hence we remove them.																							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inMEM		:	The OS member name to be identified.																				|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20170702		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Return Values:	[Numeric]																											|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|[1]	:	The member is a File that physically EXIST on the harddrive.															|
|	|[2]	:	The member is a Directory that physically EXIST on the harddrive.														|
|	|[.]	:	The member cannot be identified, or does not EXIST on the harddrive.													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\FileSystem"																						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|usFUN_isFile																													|
|	|	|usFUN_isDir																													|
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

%*100.	Function that identifies whether the provided OS member is File.;
function
	OSMemType(
		inMEM	$
	)
;
	%*050.	Declare internal fields.;
	attrib
		PutMsg	length=$256
	;

	%*100.	Verify whether the provided member physically exist.;
	if	fileexist(strip(inMEM))	=	0	then do;
		PutMsg	=	cats("N","OTE: [&L_mcrLABEL.]The given member [",inMEM,"] does not exist.");
%*		put	PutMsg;
		return(.);
	end;

	%*200.	Verify the member type.;
	if	isFile(inMEM)	then do;
		return(1);
	end;
	else if	isDir(inMEM)	then do;
		return(2);
	end;

	%*900.	Finish the definition of the function.;
	return(.);
endsub;

%*900.	Purge memory usage.;

%EndOfProc:
%mend usFUN_OSMemType;

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

	%usFUN_OSMemType
	%usFUN_isFile
	%usFUN_isDir

run;
quit;

%*200.	Tell the program where to find the compiled functions.;
options
	cmplib=work.fso
;

%*300.	Test in Dataset.;
data a;
	length	dir	$256.;
	dir	=	"C:\Program Files";	output;
	dir	=	"C:\Program Files2";	output;
	dir	=	"C:\Program Files\Common Files\System\DirectDB.dll";	output;
run;
data b;
	set a;
	f_MemType	=	OSMemType(dir);
run;

%*400.	Test in Macro Facility.;
%put	%sysfunc(OSMemType(C:\Program Files));
%put	%sysfunc(OSMemType(C:\Program Files2));
%put	%sysfunc(OSMemType(C:\Program Files\Common Files\System\DirectDB.dll));

/*-Notes- -End-*/