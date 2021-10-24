%macro usFUN_CellPhoneLoc;
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to retrieve the Cell Phone affiliation locaion from the provided website.									|
|	|Be cautious to use this function as it connects to a website every time once the program reads an observation, and this will		|
|	| probably consume a rather long time depending on the response frequency of the website.											|
|	|IMPORTANT: The provided website MUST BE able to accept the form as: [HTTP Address] + [Cell Phone Number], for searching.			|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|The function is defined by PCmp Procedure, so its scope is limited by FCmp Procedure.												|
|	|It is tested that PUT statements (to write messages in LOG) would cause "PROC UNKNOWN is running" when the function is called		|
|	| in Macro Facility. Hence we remove them.																							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inCPNumber	:	Input Cell Phone Number (or a character string that can be searched for, by appending to the HTTP address directly).|
|	|inWebsite	:	The HTTP address, to which we will append the Cell Phone Number for searching.										|
|	|URLOptions	:	The options to facilitate the URL method to assign HTTP link as FILENAME.											|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20170910		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
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
	CellPhoneLoc(
		inCPNumber	$
		,inWebsite	$
		,URLOptions	$
	)
	$32767
;
	%*050.	Declare internal fields.;
	attrib
		filref	length=$8
		tmpURL	length=$32767
		idURL	length=8
		rcURL	length=8
		tmpVal	length=$32767
	;

	%*100.	Return a missing value if the [inCPNumber] is blank.;
	if	missing(inCPNumber)	=	1	then do;
		return("");
	end;

	%*200.	Return a missing value if the [inWebsite] is blank.;
	if	missing(inWebsite)	=	1	then do;
		return("");
	end;

	%*300.	Correct the [inWebsite] if it does not contain the Forward Slash as the end.;
	if	substr(inWebsite,length(inWebsite))	^=	"/"	then do;
		tmpURL	=	catx('/',inWebsite,inCPNumber);
	end;
	else do;
		tmpURL	=	cats(inWebsite,inCPNumber);
	end;

	%*400.	Define the FILENAME to link to the website for searching.;
	filref	=	"myURL";
	rcURL	=	filename(
					filref
					,strip(tmpURL)
					,'URL'
					,strip(URLOptions)
				)
	;

	%*500.	Open the website link.;
	idURL	=	fopen(filref);

	%*600.	Read the return values from the website link.;
	rcURL	=	fread(idURL);

	%*700.	Assign the value to be returned from this function.;
	%*The length of the location is less likely to exceed 512 characters.;
	rcURL	=	fget(idURL,tmpVal,512);

	%*800.	Break the link and clear the FILENAME.;
	rcURL	=	fclose(idURL);
	rcURL	=	filename(filref);

	%*900.	Finish the definition of the function.;
	return(strip(tmpVal));
endsub;

%*900.	Purge memory usage.;

%EndOfProc:
%mend usFUN_CellPhoneLoc;

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

	%usFUN_CellPhoneLoc

run;
quit;

%*200.	Tell the program where to find the compiled functions.;
options
	cmplib=work.fso
;

%*300.	Create a dataset;
data aa;
	length	aa	$32.;
	aa	=	'1377435';	output;
	aa	=	'1527601';	output;
	aa	=	'1334883';	output;
	aa	=	'';			output;
run;
data bb;
	set	aa;
	length	bb	cc	$64.;
	bb	=	CellPhoneLoc(aa,"http://www.omsys.com.cn/Phone/getMobile/","encoding='utf-8'");
%*	cc	=	CellPhoneLoc(aa,"http://www.omsys.com.cn/Phone/getMobile/","proxy='http://proxy:8080/' user=&sysuserid. pass='********' encoding='utf-8'");
run;

%*500.	Call the function to left-trim a value in Macro Facility.;
%put	%sysfunc(CellPhoneLoc( 1527601 , %str(http://www.omsys.com.cn/Phone/getMobile/) , %str(encoding='utf-8') ) );

/*-Notes- -End-*/