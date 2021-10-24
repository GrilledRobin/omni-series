%macro usFUN_isDate;
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to verify whether the provided character string, with specific format, represents a date.					|
|	|The function is defined by PCmp Procedure, so its scope is limited by FCmp Procedure.												|
|	|The verification is conducted via Perl Regular Expression.																			|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|All rules that represent a date:																									|
|	|[1] 包括闰年在内的所有年份的月份都包含1-28日																						|
|	|[2] 包括闰年在内的所有年份除2月外都包含29和30日																					|
|	|[3] 包括闰年在内的所有年份1、3、5、7、8、10、12月都包含31日																		|
|	|[4] 所有闰年的2月29日																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inSTR	:	(Character) The character string to verify.																				|
|	|			It is stripped from within the function, hence make sure it is left-justed when input to avoid unexpected result.		|
|	|rxRule	:	(Character) The rule that determines which pattern to use during the verification.										|
|	|			Valid rules are (case insensitive):																						|
|	|			[YMD]	:	The string is implied to show up as [yyyy-mm-dd], with or without separaters.								|
|	|						If a separater exists, the function can accept [yyyy-m-d] format.											|
|	|			[MDY]	:	The string is implied to show up as [mm-dd-yyyy], with other rules similar as [YMD].						|
|	|			[DMY]	:	The string is implied to show up as [dd-mm-yyyy], with other rules similar as [YMD].						|
|	|			Default value: [YMD]																									|
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
|	|Return Values:	[Numeric]																											|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|[1]	:	The character string is a Date.																							|
|	|[0]	:	The character string is not a Date.																						|
|	|[.]	:	The input value is MISSING or the format to be used is not accepted.													|
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

%*100.	Function that verifies whether the provided character string contains a date.;
function
	isDate(
		inSTR	$
		,rxRule	$
	)
;
	%*010.	Handle the input parameters.;
	if	missing( inSTR )	then	return;

	%*020.	Declare internal fields.;
	attrib
		tmpRule			length=$16
		f_HasDlm		length=8
		prxBgn			length=$8		prxEnd			length=$8		prxDlm			length=$2		prxLeadZero		length=$1
		prx_cmp_d28th	length=$128		prx_cmp_d30th	length=$128		prx_cmp_d31st	length=$128
		prx_month_all	length=$128		prx_mth_exFeb	length=$128		prx_mth_full	length=$128
		prx_Norm_Year	length=$128		prx_mod4_year	length=$128		prx_m400_year	length=$128
		prx_Final		length=$1024	prx_Rule1to3	length=$512		prx_Rule4		length=$512
		prxID			length=8		MatchRst		length=8
	;
	MatchRst	=	0;
	if	missing( rxRule )	then do;
		tmpRule	=	"YMD";
	end;
	else do;
		tmpRule	=	upcase(strip(rxRule));
	end;
	if	index("#YMD#MDY#DMY#",cats("#",tmpRule,"#"))	=	0	then do;
		return;
	end;

	%*030.	Determine the beginning and end of the whole expression.;
	prxBgn	=	"^";
	prxEnd	=	"$";

	%*040.	Flag the logic when there is NO delimiter found in the provided string.;
	if	length( compress( inSTR , "0" , "dk" ) )	=	length( strip( inSTR ) )	then do;
		f_HasDlm	=	0;
	end;
	else do;
		f_HasDlm	=	1;
	end;

	%*050.	Setup the justification of whether to check leading 0 for months or days.;
	if	f_HasDlm	=	1	then do;
		prxDlm		=	"\D";
		prxLeadZero	=	"?";
	end;
	else do;
		prxDlm		=	"";
		prxLeadZero	=	"";
	end;

	%*100.	Prepare the basic components of the expressions.;
	%*110.	年份可统一写作如下形式.;
	prx_Norm_Year	=	"(?!0000)[0-9]{4}";

	%*120.	能被4整除但不能被100整除的年份.;
	prx_mod4_year	=	"[0-9]{2}(?:0[48]|[2468][048]|[13579][26])";

	%*130.	能被400整除的年份, 能被400整除的数肯定能被100整除，因此后两位肯定是00.;
	prx_m400_year	=	"(?:0[48]|[2468][048]|[13579][26])00";

	%*140.	包括闰年在内的所有年份的所有月份.;
	prx_month_all	=	cats("(?:0",prxLeadZero,"[1-9]|1[0-2])");

	%*150.	包括闰年在内的所有年份1、3、5、7、8、10、12月.;
	prx_mth_full	=	cats("(?:0",prxLeadZero,"[13578]|1[02])");

	%*160.	除2月外的所有月份.;
	prx_mth_exFeb	=	cats("(?:0",prxLeadZero,"[13-9]|1[0-2])");

	%*170.	1-28日.;
	prx_cmp_d28th	=	cats("(?:0",prxLeadZero,"[1-9]|1[0-9]|2[0-8])");

	%*180.	29-30日.;
	prx_cmp_d30th	=	"(?:29|30)";

	%*190.	31日.;
	prx_cmp_d31st	=	"31";

	%*200.	Combine the rules 1 to 3, for they have the same pattern for YEAR.;
	%*201.	Initialize the processing branches.;
	if	0	then do;
	end;

	%*210.	Patterns for YMD.;
	else if	tmpRule	=	"YMD"	then do;
		prx_Rule1to3	=	cats(
								"(?:"
									,prx_Norm_Year,prxDlm,"(?:"
										,prx_month_all,prxDlm,prx_cmp_d28th
										,"|",prx_mth_exFeb,prxDlm,prx_cmp_d30th
										,"|",prx_mth_full,prxDlm,prx_cmp_d31st
									,")"
								,")"
							)
		;
	end;

	%*220.	Patterns for MDY.;
	else if	tmpRule	=	"MDY"	then do;
		prx_Rule1to3	=	cats(
								"(?:"
									,"(?:"
										,prx_month_all,prxDlm,prx_cmp_d28th
										,"|",prx_mth_exFeb,prxDlm,prx_cmp_d30th
										,"|",prx_mth_full,prxDlm,prx_cmp_d31st
									,")",prxDlm,prx_Norm_Year
								,")"
							)
		;
	end;

	%*230.	Patterns for DMY.;
	else if	tmpRule	=	"DMY"	then do;
		prx_Rule1to3	=	cats(
								"(?:"
									,"(?:"
										,prx_cmp_d28th,prxDlm,prx_month_all
										,"|",prx_cmp_d30th,prxDlm,prx_mth_exFeb
										,"|",prx_cmp_d31st,prxDlm,prx_mth_full
									,")",prxDlm,prx_Norm_Year
								,")"
							)
		;
	end;

	%*300.	Prepare Rule 4.;
	%*301.	Initialize the processing branches.;
	if	0	then do;
	end;

	%*310.	Patterns for YMD.;
	else if	tmpRule	=	"YMD"	then do;
		prx_Rule4	=	cats(
								"(?:"
									,"(?:",prx_mod4_year,"|",prx_m400_year,")"
									,prxDlm,"0",prxLeadZero,"2",prxDlm,"29"
								,")"
							)
		;
	end;

	%*320.	Patterns for MDY.;
	else if	tmpRule	=	"MDY"	then do;
		prx_Rule4	=	cats(
								"(?:"
									,"0",prxLeadZero,"2",prxDlm,"29"
									,prxDlm,"(?:",prx_mod4_year,"|",prx_m400_year,")"
								,")"
							)
		;
	end;

	%*330.	Patterns for DMY.;
	else if	tmpRule	=	"DMY"	then do;
		prx_Rule4	=	cats(
								"(?:"
									,"29",prxDlm,"0",prxLeadZero,"2"
									,prxDlm,"(?:",prx_mod4_year,"|",prx_m400_year,")"
								,")"
							)
		;
	end;

	%*800.	Verification.;
	%*801.	Prepare the final pattern.;
	prx_Final	=	cats( prxBgn , "(" , prx_Rule1to3 , "|" , prx_Rule4 , ")" , prxEnd );

	%*810.	Parse the Perl Regular Expression.;
	prxID		=	prxparse(cats( "/",prx_Final,"/ismx" ));

	%*850.	Match the input string.;
	if	prxmatch( prxID , strip( inSTR ) )	>	0	then do;
		MatchRst	=	1;
	end;

	%*890.	Purge memory usage.;
	call prxfree( prxID );

	%*990.	Return the result.;
	return( MatchRst );

%*700.	Finish the definition of the function.;
endsub;

%*900.	Purge memory usage.;

%EndOfProc:
%mend usFUN_isDate;

/* - Concept - * Begin * /
The original Perl Regular Expression is:
^(?:(?!0000)[0-9]{4}-(?:(?:0[1-9]|1[0-2])-(?:0[1-9]|1[0-9]|2[0-8])|(?:0[13-9]|1[0-2])-(?:29|30)|(?:0[13578]|1[02])-31)|(?:[0-9]{2}(?:0[48]|[2468][048]|[13579][26])|(?:0[48]|[2468][048]|[13579][26])00)-02-29)$

/* - Concept - * End */

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\Dates"
	)
	mautosource
;
%global	fIsDate;

%*010.	This step ensures there is no WARNING message issued when executing the FCmp Procedure.;
options
	cmplib=_NULL_
;

%*020.	Compile the function as defined in the macro.;
proc FCmp
	outlib=work.fso.dates
;

	%usFUN_isDate

run;
quit;

%*030.	Tell the program where to find the compiled functions.;
options
	cmplib=work.fso
;

%*100.	Verify a string with only one date string.;
%*110.	Verify the date in the format of [YMD].;
%let	fIsDate	=	%sysfunc(isDate( 20160814 , ymd ));
%put	&fIsDate.;

%*120.	Verify the date in the format of [MDY].;
%let	fIsDate	=	%sysfunc(isDate( 10-28-2017 , MdY ));
%put	&fIsDate.;

%*130.	Verify the date in the format of [DMY].;
%let	fIsDate	=	%sysfunc(isDate( 7.12.2015 , DMY ));
%put	&fIsDate.;

%*140.	Incorrect date string in the format of [YMD].;
%let	fIsDate	=	%sysfunc(isDate( 2017/02/29 , YMD ));
%put	&fIsDate.;

%*150.	Incorrect date string in the format of [MDY].;
%let	fIsDate	=	%sysfunc(isDate( %str(13 17 2046) , MDY ));
%put	&fIsDate.;

%*160.	Incorrect date string in the format of [DMY].;
%let	fIsDate	=	%sysfunc(isDate( %str(213 11 2046) , DMY ));
%put	&fIsDate.;

%*161.	Contains date string in the format of [DMY].;
%let	fIsDate	=	%sysfunc(isDate( %str(a28 2 1900c) , DMY ));
%put	&fIsDate.;

%*170.	Incorrect date string in the format of [DMY] if the whole word is to be verified.;
%let	fIsDate	=	%sysfunc(isDate( %str(a13 11 2046) , DMY ));
%put	&fIsDate.;

%*300.	Verify a string without date-like strings.;
%let	fIsDate	=	%sysfunc(isDate( Hello world! , ));
%put	&fIsDate.;

/*-Notes- -End-*/