%macro usFUN_isFile;
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to identify whether the input OS member is File.															|
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
|	|[0]	:	The member is NOT a File, but physically EXIST on the harddrive.														|
|	|[.]	:	The member does not EXIST on the harddrive.																				|
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

%*100.	Function that identifies whether the provided OS member is File.;
function
	isFile(
		inMEM	$
	)
;
	%*050.	Declare internal fields.;
	attrib
		PutMsg	length=$256
		filref	length=$16
		filrc	length=8
		filID	length=8
		outFlag	length=8
	;
	filref	=	"__tmpMem";
	outFlag	=	0;

	%*100.	Verify whether the provided member physically exist.;
	if	fileexist(strip(inMEM))	=	0	then do;
		PutMsg	=	cats("N","OTE: [&L_mcrLABEL.]The given member [",inMEM,"] does not exist.");
%*		put	PutMsg;
		return(.);
	end;

	%*200.	Assign a file reference to the provided member.;
	filrc	=	filename(filref,strip(inMEM));

	%*300.	Try to open the member as file.;
	filID	=	fopen(filref);

	%*400.	Return TRUE if it is successfully opened as a file.;
	if	filID	>	0	then do;
		%*100.	Close the member as purge.;
		filrc	=	fclose(filID);

		%*900.	Generate the output result.;
		outFlag	=	1;
	end;

	%*800.	Deassign the filename.;
	filrc	=	filename(filref);

	%*900.	Finish the definition of the function.;
	return(outFlag);
endsub;

%*900.	Purge memory usage.;

%EndOfProc:
%mend usFUN_isFile;

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

	%usFUN_isFile

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
	f_file	=	isFile(dir);
run;

%*400.	Test in Macro Facility.;
%put	%sysfunc(isFile(C:\Program Files));
%put	%sysfunc(isFile(C:\Program Files2));
%put	%sysfunc(isFile(C:\Program Files\Common Files\System\DirectDB.dll));

/*-Notes- -End-*/