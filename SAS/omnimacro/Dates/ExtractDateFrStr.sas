%macro ExtractDateFrStr(
	inSTR		=
	,rxRule		=	YMD
	,fWord		=	0
	,outCNT		=	GnDates
	,outELpfx	=	GeDates
	,outBgnPfx	=	GbDates
	,outLenPfx	=	GlDates
	,fDebug		=	0
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to extract all date strings from the provided character string, with specific format as validation.			|
|	|The verification is conducted via Perl Regular Expression, see [%isDate] for more information.										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inSTR		:	The character string to verify.																						|
|	|				It is stripped from within the function, hence make sure it is left-justed when input to avoid unexpected result.	|
|	|rxRule		:	The rule that determines which pattern to use during the verification.												|
|	|				Valid rules are (case insensitive):																					|
|	|				[YMD]	:	The string is implied to show up as [yyyy-mm-dd], with or without separaters.							|
|	|							If a separater exists, the function can accept [yyyy-m-d] format.										|
|	|				[MDY]	:	The string is implied to show up as [mm-dd-yyyy], with other rules similar as [YMD].					|
|	|				[DMY]	:	The string is implied to show up as [dd-mm-yyyy], with other rules similar as [YMD].					|
|	|				Default value: [YMD]																								|
|	|fWord		:	Flag of whether to match the entire word.																			|
|	|				[1]		:	Only when the entire string matches the rule, can the result be TRUE.									|
|	|				[0]		:	If the string contains the substring that matches the rule, the result is TRUE.							|
|	|				If it is provided OTHER THAN 0, the function sets its value as 1.													|
|	|				Default value: [0]																									|
|	|outCNT		:	Number of date strings found in the whole string.																	|
|	|outELpfx	:	Prefix of the series of macro variables, which will contain the date strings.										|
|	|outBgnPfx	:	Prefix of the series of macro variables, which will contain the beginning of current date string.					|
|	|outLenPfx	:	Prefix of the series of macro variables, which will contain the length of current date string.						|
|	|fDebug		:	The switch of Debug Mode. Valid values are [0] or [1].																|
|	|				Default value: [0]																									|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20171029		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180310		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
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
|	|	|isDate																															|
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

%if	%length(%qsysfunc(compress(&outCNT.,%str( ))))		=	0	%then	%let	outCNT		=	GnDates;
%if	%length(%qsysfunc(compress(&outELpfx.,%str( ))))	=	0	%then	%let	outELpfx	=	GeDates;
%if	%length(%qsysfunc(compress(&outBgnPfx.,%str( ))))	=	0	%then	%let	outBgnPfx	=	GbDates;
%if	%length(%qsysfunc(compress(&outLenPfx.,%str( ))))	=	0	%then	%let	outLenPfx	=	GlDates;
%if	%length(%qsysfunc(compress(&fWord.,%str( ))))		=	0	%then	%let	fWord		=	0;
%if	&fWord.	^=	0	%then	%let	fWord		=	1;
%if	%length(%qsysfunc(compress(&fDebug.,%str( ))))		=	0	%then	%let	fDebug		=	0;
%if	&fDebug.^=	0	%then	%let	fDebug		=	1;

%*013.	Define the local environment.;
%local
	chkRule	chkID	chkBgn	chkStp	chkPos	chkLen	chkStr
	prxBgn	prxEnd
;
%let	chkBgn		=	1;
%let	chkStp		=	%length(&inSTR.);
%let	chkPos		=	0;
%let	chkLen		=	0;

%*018.	Define the global environment.;
%global	&outCNT.;
%let	&outCNT.	=	0;

%*020.	Quit the process if the input string is NULL.;
%if	%length(%qsysfunc(compress(&inSTR.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No string is provided for extraction.;
	%goto	EndOfProc;
%end;

%*030.	Determine the beginning and end of the whole expression.;
%if	&fWord.	=	1	%then %do;
	%let	prxBgn	=	%bquote(\b);
	%let	prxEnd	=	%bquote(\b);
%end;
%else %do;
	%let	prxBgn	=	%bquote((?<!\d));
	%let	prxEnd	=	%bquote((?!\d));
%end;

%*039.	Debug.;
%if	&fDebug.	=	1	%then %do;
	%put	%str(I)NFO: [&L_mcrLABEL.]The boundaries of string checker are: [prxBgn=&prxBgn.][prxEnd=&prxEnd.];
%end;

%*100.	Prepare the PRX to check whether the string matches a general rule.;
%*101.	Initialize the processing branches.;
%if	0	%then %do;
%end;

%*110.	Patterns for YMD.;
%else %if	&rxRule.	=	YMD	%then %do;
	%let	chkRule	=	%bquote( &prxBgn.(\d{4}\D\d{1,2}\D\d{1,2}|\d{8})&prxEnd. );
%end;

%*120.	Patterns for MDY or DMY.;
%else %if	&rxRule.	=	MDY	or	&rxRule.	=	DMY	%then %do;
	%let	chkRule	=	%bquote( &prxBgn.(\d{1,2}\D\d{1,2}\D\d{4}|\d{8})&prxEnd. );
%end;

%*180.	Parse the string checker.;
%let	chkID	=	%sysfunc(prxparse( /&chkRule./ismx ));

%*199.	Quit the function if the input string does not match the general rule.;
%if	%sysfunc(prxmatch( &chkID. , &inSTR. ))	=	0	%then %do;
	%*001.	Debug.;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]There is no match for the Selection Rule: [chkRule=&chkRule.];
	%end;

	%*900.	Quit function.;
	%goto	PurgeChkID;
%end;

%*200.	Identify the first capture buffer from the entire string.;
%syscall	prxnext( chkID , chkBgn , chkStp , inSTR , chkPos , chkLen );

%*300.	Verify the pattern for each capture buffer.;
%do %while ( %eval( &chkPos. > 0 ) );
	%*010.	Retrieve the capture buffer from the general rule.;
	%let	chkStr	=	%substr( &inSTR. , &chkPos. , &chkLen. );

	%*100.	Skip to the next string checker if current one is NOT a date.;
	%if	%isDate( inSTR = &chkStr. , rxRule = &rxRule. , fDebug = &fDebug. )	=	0	%then %do;
		%*001.	Debug.;
		%if	&fDebug.	=	1	%then %do;
			%put	%str(I)NFO: [&L_mcrLABEL.]Current string [chkStr=&chkStr.] is NOT a valid date.;
		%end;

		%*900.	Skip.;
		%goto	NextStr;
	%end;

	%*199.	Debug.;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Current string [chkStr=&chkStr.] is recognized as a valid date.;
	%end;

	%*200.	Increment the number of date strings found for extraction.;
	%let	&outCNT.	=	%eval( &&&outCNT.. + 1 );

	%*300.	Output current string as it is validated as a date string.;
	%global
		&outELpfx.&&&outCNT..
		&outBgnPfx.&&&outCNT..
		&outLenPfx.&&&outCNT..
	;
	%let	&outELpfx.&&&outCNT..	=	&chkStr.;
	%let	&outBgnPfx.&&&outCNT..	=	&chkPos.;
	%let	&outLenPfx.&&&outCNT..	=	&chkLen.;

	%*990.	Identify the next capture buffer from the entire string.;
	%NextStr:
	%syscall	prxnext( chkID , chkBgn , chkStp , inSTR , chkPos , chkLen );
%end;

%*800.	Purge memory usage.;
%PurgeChkID:
%syscall	prxfree( chkID );

%EndOfProc:
%mend ExtractDateFrStr;

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

%*050.	Prepare macro to print the values to the LOG.;
%macro ExtVal;
%put	[GnDates=&GnDates.];
%if	&GnDates.	=	0	%then %do;
	%goto	EndOfProc;
%end;
%do i=1 %to &GnDates.;
	%put	[GeDates&i.=&&GeDates&i..][GbDates&i.=&&GbDates&i..][GlDates&i.=&&GlDates&i..];
%end;
%EndOfProc:
%mend ExtVal;

%*100.	Extract from a string with only one date string.;
%*110.	Verify the date in the format of [YMD].;
%ExtractDateFrStr(
	inSTR		=	20160814
	,rxRule		=	ymd
	,outCNT		=	GnOut
	,outELpfx	=	GeOut
	,outBgnPfx	=	GbOut
	,outLenPfx	=	GlOut
)
%put	[GnOut=&GnOut.][GeOut&GnOut.=&&GeOut&GnOut..][GbOut&GnOut.=&&GbOut&GnOut..][GlOut&GnOut.=&&GlOut&GnOut..];

%*120.	Verify the date in the format of [MDY].;
%ExtractDateFrStr( inSTR = 10-28-2017 , rxRule = MdY , outCNT = GnOut , outELpfx = GeOut , outBgnPfx = GbOut , outLenPfx = GlOut )
%put	[GnOut=&GnOut.][GeOut&GnOut.=&&GeOut&GnOut..][GbOut&GnOut.=&&GbOut&GnOut..][GlOut&GnOut.=&&GlOut&GnOut..];

%*130.	Verify the date in the format of [DMY].;
%ExtractDateFrStr( inSTR = 7.12.2015 , rxRule = DMY )
%ExtVal

%*140.	Incorrect date string in the format of [YMD].;
%ExtractDateFrStr( inSTR = 2017/02/29 , rxRule = YMD )
%ExtVal

%*150.	Incorrect date string in the format of [MDY].;
%ExtractDateFrStr( inSTR = %str(13 17 2046) , rxRule = MDY )
%ExtVal

%*160.	Incorrect date string in the format of [DMY].;
%ExtractDateFrStr( inSTR = %str(213 11 2046) , rxRule = DMY )
%ExtVal

%*161.	Contains date string in the format of [DMY].;
%ExtractDateFrStr( inSTR = %str(a28 2 1900c) , rxRule = DMY )
%ExtVal

%*170.	Incorrect date string in the format of [DMY] if the whole word is to be verified.;
%ExtractDateFrStr( inSTR = %str(a13 11 2046) , rxRule = DMY , fWord = 1 )
%ExtVal

%*200.	Extract from a string with many date-like strings.;
%*210.	Verify the date in the format of [YMD].;
%ExtractDateFrStr( inSTR = a2000-2-30bcd20160814 , rxRule = ymd , fDebug = 1 )
%ExtVal

%*220.	Verify the date in the format of [MDY].;
%ExtractDateFrStr( inSTR = z11221994vfg2/14/1984own02.29.1900 , rxRule = MDY , fDebug = 1 )
%ExtVal

%*300.	Verify a string without date-like strings.;
%ExtractDateFrStr( inSTR = Hello world! , fDebug = 1 )
%ExtVal

/*-Notes- -End-*/