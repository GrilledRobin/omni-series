%macro usFUN_RTrimByChar;
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to right-trim the character string by the specified character.												|
|	|The most common usage is to remove the trailing 0 in a serial number as [681581000000] and return [681581] as the result.			|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|The function is defined by PCmp Procedure, so its scope is limited by FCmp Procedure.												|
|	|It is tested that PUT statements (to write messages in LOG) would cause "PROC UNKNOWN is running" when the function is called		|
|	| in Macro Facility. Hence we remove them.																							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inSTR	:	Input variable name.																									|
|	|inCHAR	:	The character to be right-trimmed.																						|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20170826		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Return Values:	[Character]																											|
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

%*100.	Function that retrieves the number of observations for the given dataset.;
function
	RTrimByChar(
		inSTR	$
		,inCHAR	$
	)
	$32767
;
	%*050.	Declare internal fields.;
	attrib
		tmpPRX	length=8
		tmpVal	length=$32767
	;

	%*100.	Return a missing value if the [inCHAR] is provided more than the length of one character.;
	if	length(inCHAR)	^=	1	then do;
		return("");
	end;

	%*200.	Return a missing value if the [inSTR] is blank.;
	if	missing(inSTR)	=	1	then do;
		return("");
	end;

	%*300.	Define the pattern to remove the trailing characters as specified.;
	tmpPRX	=	prxparse(cats('s/^(.*?)',ifc(index('.\*+?()[]{}|^$#',strip(inCHAR)),'\',''),strip(inCHAR),'*\s*$/\1/ismx'));

	%*700.	Calculate the trimmed value.;
	tmpVal	=	strip(prxchange(tmpPRX,1,strip(inSTR)));

	%*800.	Free the memory usage.;
	call prxfree(tmpPRX);

	%*900.	Finish the definition of the function.;
	return(strip(tmpVal));
endsub;

%*900.	Purge memory usage.;

%EndOfProc:
%mend usFUN_RTrimByChar;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvOp"
	)
	mautosource
;

%*090.	This step ensures there is no WARNING message issued when executing the FCmp Procedure.;
options
	cmplib=_NULL_
;

%*100.	Compile the function as defined in the macro.;
proc FCmp
	outlib=work.fso.AdvOp
;

	%usFUN_RTrimByChar

run;
quit;

%*200.	Tell the program where to find the compiled functions.;
options
	cmplib=work.fso
;

%*300.	Create a dataset;
data aa;
	length	aa	$32.;
	aa	=	'000000587818000';	output;
	aa	=	'000500589716148';	output;
	aa	=	'56798681111';		output;
	aa	=	'';					output;
run;
data bb;
	set	aa;
	length	bb	$32.;
	bb	=	RTrimByChar(aa,"0");
run;

%*500.	Call the function to right-trim a value in Macro Facility.;
%put	%sysfunc(RTrimByChar(0006805660000,0));
%put	%sysfunc(RTrimByChar($$$$$$$15114$,$));

/*-Notes- -End-*/