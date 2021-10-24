%macro StrContainsDate(
	inSTR	=
	,rxRule	=	YMD
	,fWord	=	0
	,fDebug	=	0
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to verify whether the provided character string contains a date with specific format.						|
|	|The verification is conducted via Perl Regular Expression, see [%isDate] and [%ExtractDateFrStr] for more information.				|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inSTR	:	The character string to verify.																							|
|	|rxRule	:	The rule that determines which pattern to use during the verification.													|
|	|			Valid rules are (case insensitive):																						|
|	|			[YMD]	:	The string is implied to show up as [yyyy-mm-dd], with or without separaters.								|
|	|						If a separater exists, the function can accept [yyyy-m-d] format.											|
|	|			[MDY]	:	The string is implied to show up as [mm-dd-yyyy], with other rules similar as [YMD].						|
|	|			[DMY]	:	The string is implied to show up as [dd-mm-yyyy], with other rules similar as [YMD].						|
|	|			Default value: [YMD]																									|
|	|fWord	:	Flag of whether to match the entire word.																				|
|	|			[1]		:	Only when the entire string matches the rule, can the result be TRUE.										|
|	|			[0]		:	If the string contains the substring that matches the rule, the result is TRUE.								|
|	|			If it is provided OTHER THAN 0, the function sets its value as 1.														|
|	|			Default value: [0]																										|
|	|fDebug	:	The switch of Debug Mode. Valid values are [0] or [1].																	|
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
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180310		| Version |	2.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Please find the attachments for examples.																							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ErrMcr																															|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\Dates"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ExtractDateFrStr																												|
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
%if	%length(%qsysfunc(compress(&inSTR.,%str( ))))	^=	0	%then %do;
	%let	inSTR	=	%qsysfunc(strip(&inSTR.));
%end;
%let	rxRule	=	%upcase(&rxRule.);

%if	%length(%qsysfunc(compress(&rxRule.,%str( ))))	=	0	%then	%let	rxRule	=	YMD;
%if	%index( #YMD#MDY#DMY# , #&rxRule.# )	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]The provided rule [rxRule=&rxRule.] is NOT accepted!;
	%ErrMcr
%end;
%if	%length(%qsysfunc(compress(&fWord.,%str( ))))	=	0	%then	%let	fWord	=	0;
%if	&fWord.	^=	0	%then	%let	fWord	=	1;
%if	%length(%qsysfunc(compress(&fDebug.,%str( ))))	=	0	%then	%let	fDebug	=	0;
%if	&fDebug.^=	0	%then	%let	fDebug	=	1;

%*013.	Define the local environment.;

%*018.	Define the global environment.;

%*100.	Try to extract all dates from the provided string with all default settings.;
%ExtractDateFrStr( inSTR = &inSTR. , rxRule = &rxRule. , fWord = &fWord. , fDebug = &fDebug. )

%*990.	Return the result.;
%*Below GLOBAL macro variable is generated from above macro.;
%eval( &GnDates. > 0 )

%EndOfProc:
%mend StrContainsDate;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvOp"
		"D:\SAS\omnimacro\Dates"
	)
	mautosource
;
%global	fContain;

%*050.	Prepare macro to print the values to the LOG.;
%macro ExtVal;
%put	[fContain=&fContain.];
%if	&fContain.	=	0	%then %do;
	%goto	EndOfProc;
%end;

%put	[GnDates=&GnDates.];
%do i=1 %to &GnDates.;
	%put	[GeDates&i.=&&GeDates&i..][GbDates&i.=&&GbDates&i..][GlDates&i.=&&GlDates&i..];
%end;
%EndOfProc:
%mend ExtVal;

%*100.	Verify a string with only one date string.;
%*110.	Verify the date in the format of [YMD].;
%let	fContain	=	%StrContainsDate( inSTR = 20160814 , rxRule = ymd );
%ExtVal

%*120.	Verify the date in the format of [MDY].;
%let	fContain	=	%StrContainsDate( inSTR = 10-28-2017 , rxRule = MdY );
%ExtVal

%*130.	Verify the date in the format of [DMY].;
%let	fContain	=	%StrContainsDate( inSTR = 7.12.2015 , rxRule = DMY );
%ExtVal

%*140.	Incorrect date string in the format of [YMD].;
%let	fContain	=	%StrContainsDate( inSTR = 2017/02/29 , rxRule = YMD );
%ExtVal

%*150.	Incorrect date string in the format of [MDY].;
%let	fContain	=	%StrContainsDate( inSTR = %str(13 17 2046) , rxRule = MDY );
%ExtVal

%*160.	Incorrect date string in the format of [DMY].;
%let	fContain	=	%StrContainsDate( inSTR = %str(213 11 2046) , rxRule = DMY );
%ExtVal

%*161.	Contains date string in the format of [DMY].;
%let	fContain	=	%StrContainsDate( inSTR = %str(a28 2 1900c) , rxRule = DMY );
%ExtVal

%*170.	Incorrect date string in the format of [DMY] if the whole word is to be verified.;
%let	fContain	=	%StrContainsDate( inSTR = %str(a13 11 2046) , rxRule = DMY , fWord = 1 );
%ExtVal

%*200.	Verify a string with many date-like strings.;
%*210.	Verify the date in the format of [YMD].;
%let	fContain	=	%StrContainsDate( inSTR = a2000-2-30bcd20160814 , rxRule = ymd , fDebug = 1 );
%ExtVal

%*220.	Verify the date in the format of [MDY].;
%let	fContain	=	%StrContainsDate( inSTR = z11221994vfg2/14/1984own02.29.1900 , rxRule = MDY , fDebug = 1 );
%ExtVal

%*300.	Verify a string without date-like strings.;
%let	fContain	=	%StrContainsDate( inSTR = Hello world! , fDebug = 1 );
%ExtVal

/*-Notes- -End-*/