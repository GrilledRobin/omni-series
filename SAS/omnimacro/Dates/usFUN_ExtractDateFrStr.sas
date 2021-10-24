%macro usFUN_ExtractDateFrStr;
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to extract all date strings from the provided character string, with specific format as validation.			|
|	|The verification is conducted via Perl Regular Expression, see the user-stored function [isDate] for more information.				|
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
|	|oDlm	:	(Character) The delimiter that separates the date strings in the output result.											|
|	|			Default value: [|]																										|
|	|oDates	:	(Character) The output result of the dates extracted, which are separated by the provided [oDlm].						|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20171029		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Return Values:	[Character]																											|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|[(Character String)]	:	The dates extracted from the provided string, separated by the provided [oDlm].							|
|	|[(Blank)]				:	There is no valid date found in the provided string, or the [rxRule] is not accepted.					|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\Dates"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|usFUN_isDate																													|
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
	ExtractDateFrStr(
		inSTR	$
		,rxRule	$
		,fWord
		,oDlm	$
	)
	$32767
;
	%*010.	Handle the input parameters.;
	if	missing( inSTR )	then	return;

	%*020.	Declare internal fields.;
	attrib
		chkRule			length=$128		chkID			length=8
		chkBgn			length=8		chkStp			length=8		chkPos			length=8		chkLen			length=8
		chkStr			length=$16
		prxBgn			length=$8		prxEnd			length=$8
		tmpRule			length=$16		tmpWord			length=8		tmpDlm			length=$1024
		oDates			length=$32767
	;
	chkBgn	=	1;
	chkStp	=	length( inSTR );
	chkPos	=	0;
	chkLen	=	0;
	oDates	=	"";
	if	missing( rxRule )	then do;
		tmpRule	=	"YMD";
	end;
	else do;
		tmpRule	=	upcase( strip( rxRule ) );
	end;
	if	index("#YMD#MDY#DMY#",cats("#",tmpRule,"#"))	=	0	then do;
		return;
	end;

	if	missing( fWord )	then	tmpWord	=	0;		else	tmpWord	=	fWord;
	if	tmpWord	^=	0		then	tmpWord	=	1;

	if	missing( oDlm )		then	tmpDlm	=	"|";	else	tmpDlm	=	strip(oDlm);

	%*030.	Determine the beginning and end of the whole expression.;
	if	tmpWord	=	1	then do;
		prxBgn	=	"\b";
		prxEnd	=	"\b";
	end;
	else do;
		prxBgn	=	"(?<!\d)";
		prxEnd	=	"(?!\d)";
	end;

	%*100.	Prepare the PRX to check whether the string matches a general rule.;
	%*101.	Initialize the processing branches.;
	if	0	then do;
	end;

	%*110.	Patterns for YMD.;
	else if	tmpRule	=	"YMD"	then do;
		chkRule	=	cats( prxBgn , "(\d{4}\D\d{1,2}\D\d{1,2}|\d{8})" , prxEnd );
	end;

	%*120.	Patterns for MDY or DMY.;
	else if	tmpRule	in	( "MDY" , "DMY" )	then do;
		chkRule	=	cats( prxBgn , "(\d{1,2}\D\d{1,2}\D\d{4}|\d{8})" , prxEnd );
	end;

	%*180.	Parse the string checker.;
	chkID	=	prxparse(cats( "/",chkRule,"/ismx" ));

	%*199.	Quit the function if the input string does not match the general rule.;
	if	prxmatch( chkID , inSTR )	=	0	then do;
		goto	PurgeChkID;
	end;

	%*200.	Identify the first capture buffer from the entire string.;
	call prxnext( chkID , chkBgn , chkStp , inSTR , chkPos , chkLen );

	%*300.	Verify the pattern for each capture buffer.;
	do while ( chkPos > 0 );
		%*010.	Retrieve the capture buffer from the general rule.;
		chkStr	=	substr( inSTR , chkPos , chkLen );

		%*100.	Skip to the next string checker if current one is NOT a date.;
		if	isDate( chkStr , tmpRule )	=	0	then do;
			goto	NextStr;
		end;

		%*400.	Append the result to the output string.;
		oDates	=	catx( strip( tmpDlm ) , oDates , chkStr );

		%*990.	Identify the next capture buffer from the entire string.;
		NextStr:
		call prxnext( chkID , chkBgn , chkStp , inSTR , chkPos , chkLen );
	end;

	%*800.	Purge memory usage.;
	PurgeChkID:
	call prxfree( chkID );

	%*990.	Return the result.;
	return( oDates );

%*700.	Finish the definition of the function.;
endsub;

%*900.	Purge memory usage.;

%EndOfProc:
%mend usFUN_ExtractDateFrStr;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\Dates"
	)
	mautosource
;
%global	getDates;

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

run;
quit;

%*030.	Tell the program where to find the compiled functions.;
options
	cmplib=work.fso
;

%*100.	Verify a string with only one date string.;
%*110.	Verify the date in the format of [YMD].;
%let	getDates	=	%sysfunc(ExtractDateFrStr( 20160814 , ymd , 0 , $ ));
%put	&getDates.;

%*120.	Verify the date in the format of [MDY].;
%let	getDates	=	%sysfunc(ExtractDateFrStr( 10-28-2017 , MdY , 0 , | ));
%put	&getDates.;

%*130.	Verify the date in the format of [DMY].;
%let	getDates	=	%sysfunc(ExtractDateFrStr( 7.12.2015 , DMY , 0 , - ));
%put	&getDates.;

%*140.	Incorrect date string in the format of [YMD].;
%let	getDates	=	%sysfunc(ExtractDateFrStr( 2017/02/29 , YMD , 0 , ));
%put	&getDates.;

%*150.	Incorrect date string in the format of [MDY].;
%let	getDates	=	%sysfunc(ExtractDateFrStr( %str(13 17 2046) , MDY , 0 , . ));
%put	&getDates.;

%*160.	Incorrect date string in the format of [DMY].;
%let	getDates	=	%sysfunc(ExtractDateFrStr( %str(213 11 2046) , DMY , 0 , ));
%put	&getDates.;

%*161.	Contains date string in the format of [DMY].;
%let	getDates	=	%sysfunc(ExtractDateFrStr( %str(a28 2 1900c) , DMY , 0 , ));
%put	&getDates.;

%*170.	Incorrect date string in the format of [DMY] if the whole word is to be verified.;
%let	getDates	=	%sysfunc(ExtractDateFrStr( %str(a13 11 2046) , DMY , 1 , ));
%put	&getDates.;

%*200.	Extract from a string with many date-like strings.;
%*210.	Verify the date in the format of [YMD].;
%let	getDates	=	%sysfunc(ExtractDateFrStr( %str(a2000-2-30bcd20160814) , ymd , 0 , # ));
%put	&getDates.;

%*220.	Verify the date in the format of [MDY].;
%let	getDates	=	%sysfunc(ExtractDateFrStr( %str(z11221994vfg2/14/1984own02.29.1900) , MDY , 0 , %str( $ | ) ));
%put	&getDates.;

%*300.	Verify a string without date-like strings.;
%let	getDates	=	%sysfunc(ExtractDateFrStr( Hello world! , , 1 , ));
%put	&getDates.;

/*-Notes- -End-*/