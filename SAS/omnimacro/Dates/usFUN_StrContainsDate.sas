%macro usFUN_StrContainsDate;
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to verify whether the provided character string contains a date with specific format.						|
|	|The verification is conducted via Perl Regular Expression, see user-stored functions [isDate] and [ExtractDateFrStr] for more		|
|	| information.																														|
|	|The function is defined by PCmp Procedure, so its scope is limited by FCmp Procedure.												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inSTR	:	(Character) The character string to verify.																				|
|	|rxRule	:	(Character) The rule that determines which pattern to use during the verification.										|
|	|			Valid rules are (case insensitive):																						|
|	|			[YMD]	:	The string is implied to show up as [yyyy-mm-dd], with or without separaters.								|
|	|						If a separater exists, the function can accept [yyyy-m-d] format.											|
|	|			[MDY]	:	The string is implied to show up as [mm-dd-yyyy], with other rules similar as [YMD].						|
|	|			[DMY]	:	The string is implied to show up as [dd-mm-yyyy], with other rules similar as [YMD].						|
|	|			Default value: [YMD]																									|
|	|fWord	:	(Numeric) Flag of whether to match the entire word.																		|
|	|			[1]		:	Only when the entire string matches the rule, can the result be TRUE.										|
|	|			[0]		:	If the string contains the substring that matches the rule, the result is TRUE.								|
|	|			If it is provided OTHER THAN 0, the function sets its value as 1.														|
|	|			Default value: [0]																										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20171028		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20171029		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Split the process into 3 sub-processes to facilitate different requirements.												|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Return Values:	[Numeric]																											|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|[1]	:	The character string contains a valid Date.																				|
|	|[0]	:	The character string does not contain a valid Date.																		|
|	|[.]	:	The input value is MISSING, or the [rxRule] is NOT accepted.															|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\Dates"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|usFUN_ExtractDateFrStr																											|
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

%*100.	Function that verifies whether the provided character string contains a date.;
function
	StrContainsDate(
		inSTR	$
		,rxRule	$
		,fWord
	)
;
	%*010.	Handle the input parameters.;
	if	missing( inSTR )	then	return;

	%*020.	Declare internal fields.;
	attrib
		tmpRule			length=$16		tmpWord			length=8
	;
	if	missing( rxRule )	then do;
		tmpRule	=	"YMD";
	end;
	else do;
		tmpRule	=	upcase(strip(rxRule));
	end;
	if	index("#YMD#MDY#DMY#",cats("#",tmpRule,"#"))	=	0	then do;
		return;
	end;

	if	missing( fWord )	then	tmpWord	=	0;	else	tmpWord	=	fWord;
	if	tmpWord	^=	0		then	tmpWord	=	1;

	%*990.	Try to extract all dates from the provided string with all default settings and return positive if the length of the extraction is NOT zero.;
	return( 1 - missing( ExtractDateFrStr( inSTR , tmpRule , tmpWord , "^_^" ) ) );

%*700.	Finish the definition of the function.;
endsub;

%*900.	Purge memory usage.;

%EndOfProc:
%mend usFUN_StrContainsDate;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\Dates"
	)
	mautosource
;
%global	fContain;

%*010.	This step ensures there is no WARNING message issued when executing the FCmp Procedure.;
options
	cmplib=_NULL_
;

%*020.	Compile the function as defined in the macro.;
proc FCmp
	outlib=work.fso.dates
;

	%usFUN_isDate
	%usFUN_ExtractDateFrStr
	%usFUN_StrContainsDate

run;
quit;

%*030.	Tell the program where to find the compiled functions.;
options
	cmplib=work.fso
;

%*100.	Verify a string with only one date string.;
%*110.	Verify the date in the format of [YMD].;
%let	fContain	=	%sysfunc(StrContainsDate( 20160814 , ymd , 0 ));
%put	&fContain.;

%*120.	Verify the date in the format of [MDY].;
%let	fContain	=	%sysfunc(StrContainsDate( 10-28-2017 , MdY , 0 ));
%put	&fContain.;

%*130.	Verify the date in the format of [DMY].;
%let	fContain	=	%sysfunc(StrContainsDate( 7.12.2015 , DMY , 0 ));
%put	&fContain.;

%*140.	Incorrect date string in the format of [YMD].;
%let	fContain	=	%sysfunc(StrContainsDate( 2017/02/29 , YMD , 0 ));
%put	&fContain.;

%*150.	Incorrect date string in the format of [MDY].;
%let	fContain	=	%sysfunc(StrContainsDate( %str(13 17 2046) , MDY , 0 ));
%put	&fContain.;

%*160.	Incorrect date string in the format of [DMY].;
%let	fContain	=	%sysfunc(StrContainsDate( %str(213 11 2046) , DMY , 0 ));
%put	&fContain.;

%*161.	Contains date string in the format of [DMY].;
%let	fContain	=	%sysfunc(StrContainsDate( %str(a28 2 1900c) , DMY , 0 ));
%put	&fContain.;

%*170.	Incorrect date string in the format of [DMY] if the whole word is to be verified.;
%let	fContain	=	%sysfunc(StrContainsDate( %str(a13 11 2046) , DMY , 1 ));
%put	&fContain.;

%*200.	Verify a string with many date-like strings.;
%*210.	Verify the date in the format of [YMD].;
%let	fContain	=	%sysfunc(StrContainsDate( %str(a2000-2-30bcd20160814) , ymd , 0 ));
%put	&fContain.;

%*220.	Verify the date in the format of [MDY].;
%let	fContain	=	%sysfunc(StrContainsDate( z11221994vfg2/14/1984own02.29.1900 , MDY , 0 ));
%put	&fContain.;

%*300.	Verify a string without date-like strings.;
%let	fContain	=	%sysfunc(StrContainsDate( Hello world! , , 0 ));
%put	&fContain.;

/*-Notes- -End-*/