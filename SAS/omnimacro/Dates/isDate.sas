%macro isDate(
	inSTR	=
	,rxRule	=	YMD
	,fDebug	=	0
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to verify whether the provided character string, with specific format, represents a date.					|
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
|	|inSTR	:	The character string to verify.																							|
|	|			It is stripped from within the function, hence make sure it is left-justed when input to avoid unexpected result.		|
|	|rxRule	:	The rule that determines which pattern to use during the verification.													|
|	|			Valid rules are (case insensitive):																						|
|	|			[YMD]	:	The string is implied to show up as [yyyy-mm-dd], with or without separaters.								|
|	|						If a separater exists, the function can accept [yyyy-m-d] format.											|
|	|			[MDY]	:	The string is implied to show up as [mm-dd-yyyy], with other rules similar as [YMD].						|
|	|			[DMY]	:	The string is implied to show up as [dd-mm-yyyy], with other rules similar as [YMD].						|
|	|			Default value: [YMD]																									|
|	|fDebug	:	The switch of Debug Mode. Valid values are [0] or [1].																	|
|	|			Default value: [0]																										|
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
%if	%length(%qsysfunc(compress(&fDebug.,%str( ))))	=	0	%then	%let	fDebug	=	0;
%if	&fDebug.^=	0	%then	%let	fDebug	=	1;

%*013.	Define the local environment.;
%local
	f_HasDlm
	prxBgn	prxEnd	prxDlm	prxLeadZero
	prx_cmp_d28th	prx_cmp_d30th	prx_cmp_d31st
	prx_month_all	prx_mth_exFeb	prx_mth_full
	prx_Norm_Year	prx_mod4_year	prx_m400_year
	prx_Final	prx_Rule1to3	prx_Rule4
	prxID	MatchRst
;
%let	MatchRst	=	0;

%*020.	Return NULL if the input string is NULL.;
%if	%length(%qsysfunc(compress(&inSTR.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No string is given for verification.;
	%goto	ReturnVal;
%end;

%*030.	Determine the beginning and end of the whole expression.;
%let	prxBgn	=	%bquote(^);
%let	prxEnd	=	%bquote($);

%*040.	Flag the logic when there is NO delimiter found in the string checker.;
%if	%length(%sysfunc(compress(&inSTR,0,dk)))	=	%length(&inSTR.)	%then %do;
	%let	f_HasDlm	=	0;
%end;
%else %do;
	%let	f_HasDlm	=	1;
%end;

%*049.	Debug.;
%if	&fDebug.	=	1	%then %do;
	%put	%str(I)NFO: [&L_mcrLABEL.]Delimiter Existence: [f_HasDlm=&f_HasDlm.];
%end;

%*050.	Setup the justification of whether to check the leading 0 for months or days.;
%if	&f_HasDlm.	=	1	%then %do;
	%let	prxDlm		=	%bquote(\D);
	%let	prxLeadZero	=	%bquote(?);
%end;
%else %do;
	%let	prxDlm		=;
	%let	prxLeadZero	=;
%end;

%*100.	Prepare the basic components of the expressions.;
%*110.	年份可统一写作如下形式.;
%let	prx_Norm_Year	=	%bquote( (?!0000)[0-9]{4} );

%*120.	能被4整除但不能被100整除的年份.;
%let	prx_mod4_year	=	%bquote( [0-9]{2}(?:0[48]|[2468][048]|[13579][26]) );

%*130.	能被400整除的年份, 能被400整除的数肯定能被100整除，因此后两位肯定是00.;
%let	prx_m400_year	=	%bquote( (?:0[48]|[2468][048]|[13579][26])00 );

%*140.	包括闰年在内的所有年份的所有月份.;
%let	prx_month_all	=	%bquote( (?:0&prxLeadZero.[1-9]|1[0-2]) );

%*150.	包括闰年在内的所有年份1、3、5、7、8、10、12月.;
%let	prx_mth_full	=	%bquote( (?:0&prxLeadZero.[13578]|1[02]) );

%*160.	除2月外的所有月份.;
%let	prx_mth_exFeb	=	%bquote( (?:0&prxLeadZero.[13-9]|1[0-2]) );

%*170.	1-28日.;
%let	prx_cmp_d28th	=	%bquote( (?:0&prxLeadZero.[1-9]|1[0-9]|2[0-8]) );

%*180.	29-30日.;
%let	prx_cmp_d30th	=	%bquote( (?:29|30) );

%*190.	31日.;
%let	prx_cmp_d31st	=	%bquote( 31 );

%*200.	Combine the rules 1 to 3, for they have the same pattern for YEAR.;
%*201.	Initialize the processing branches.;
%if	0	%then %do;
%end;

%*210.	Patterns for YMD.;
%else %if	&rxRule.	=	YMD	%then %do;
	%let	prx_Rule1to3	=	%bquote(
									(?:
										&prx_Norm_Year. &prxDlm. (?:
											&prx_month_all. &prxDlm. &prx_cmp_d28th.
											|&prx_mth_exFeb. &prxDlm. &prx_cmp_d30th.
											|&prx_mth_full. &prxDlm. &prx_cmp_d31st.
										)
									)
								)
	;
%end;

%*220.	Patterns for MDY.;
%else %if	&rxRule.	=	MDY	%then %do;
	%let	prx_Rule1to3	=	%bquote(
									(?:
										(?:
											&prx_month_all. &prxDlm. &prx_cmp_d28th.
											|&prx_mth_exFeb. &prxDlm. &prx_cmp_d30th.
											|&prx_mth_full. &prxDlm. &prx_cmp_d31st.
										) &prxDlm. &prx_Norm_Year.
									)
								)
	;
%end;

%*230.	Patterns for DMY.;
%else %if	&rxRule.	=	DMY	%then %do;
	%let	prx_Rule1to3	=	%bquote(
									(?:
										(?:
											&prx_cmp_d28th. &prxDlm. &prx_month_all.
											|&prx_cmp_d30th. &prxDlm. &prx_mth_exFeb.
											|&prx_cmp_d31st. &prxDlm. &prx_mth_full.
										) &prxDlm. &prx_Norm_Year.
									)
								)
	;
%end;

%*300.	Prepare Rule 4.;
%*301.	Initialize the processing branches.;
%if	0	%then %do;
%end;

%*310.	Patterns for YMD.;
%else %if	&rxRule.	=	YMD	%then %do;
	%let	prx_Rule4	=	%bquote(
								(?:
									(?:&prx_mod4_year.|&prx_m400_year.)
									&prxDlm. 0&prxLeadZero.2 &prxDlm. 29
								)
							)
	;
%end;

%*320.	Patterns for MDY.;
%else %if	&rxRule.	=	MDY	%then %do;
	%let	prx_Rule4	=	%bquote(
								(?:
									0&prxLeadZero.2 &prxDlm. 29
									&prxDlm. (?:&prx_mod4_year.|&prx_m400_year.)
								)
							)
	;
%end;

%*330.	Patterns for DMY.;
%else %if	&rxRule.	=	DMY	%then %do;
	%let	prx_Rule4	=	%bquote(
								(?:
									29 &prxDlm. 0&prxLeadZero.2
									&prxDlm. (?:&prx_mod4_year.|&prx_m400_year.)
								)
							)
	;
%end;

%*800.	Verification.;
%*801.	Prepare the final pattern.;
%let	prx_Final	=	%bquote( &prxBgn.(&prx_Rule1to3.|&prx_Rule4.)&prxEnd. );

%*809.	Debug.;
%if	&fDebug.	=	1	%then %do;
	%put	%str(I)NFO: [&L_mcrLABEL.]Full PRX: [prx_Final=%qsysfunc(compress(&prx_Final.))];
%end;

%*810.	Parse the Perl Regular Expression.;
%let	prxID	=	%sysfunc(prxparse(/&prx_Final./ismx));

%*850.	Match the input string.;
%if	%sysfunc(prxmatch( &prxID. , &inSTR. ))	>	0	%then %do;
	%let	MatchRst	=	1;
%end;

%*890.	Purge memory usage.;
%syscall	prxfree( prxID );

%*990.	Return the result.;
%ReturnVal:
&MatchRst.

%EndOfProc:
%mend isDate;

/* - Concept - * Begin * /
The original Perl Regular Expression is:
^(?:(?!0000)[0-9]{4}-(?:(?:0[1-9]|1[0-2])-(?:0[1-9]|1[0-9]|2[0-8])|(?:0[13-9]|1[0-2])-(?:29|30)|(?:0[13578]|1[02])-31)|(?:[0-9]{2}(?:0[48]|[2468][048]|[13579][26])|(?:0[48]|[2468][048]|[13579][26])00)-02-29)$

/* - Concept - * End */

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
%global	fIsDate;

%*100.	Verify a string with only one date string.;
%*110.	Verify the date in the format of [YMD].;
%let	fIsDate	=	%isDate( inSTR = 20160814 , rxRule = ymd );
%put	&fIsDate.;

%*120.	Verify the date in the format of [MDY].;
%let	fIsDate	=	%isDate( inSTR = 10-28-2017 , rxRule = MdY );
%put	&fIsDate.;

%*130.	Verify the date in the format of [DMY].;
%let	fIsDate	=	%isDate( inSTR = 7.12.2015 , rxRule = DMY );
%put	&fIsDate.;

%*140.	Incorrect date string in the format of [YMD].;
%let	fIsDate	=	%isDate( inSTR = 2017/02/29 , rxRule = YMD );
%put	&fIsDate.;

%*150.	Incorrect date string in the format of [MDY].;
%let	fIsDate	=	%isDate( inSTR = %str(13 17 2046) , rxRule = MDY );
%put	&fIsDate.;

%*160.	Incorrect date string in the format of [DMY].;
%let	fIsDate	=	%isDate( inSTR = %str(213 11 2046) , rxRule = DMY );
%put	&fIsDate.;

%*161.	Contains date string in the format of [DMY].;
%let	fIsDate	=	%isDate( inSTR = %str(a28 2 1900c) , rxRule = DMY );
%put	&fIsDate.;

%*300.	Verify a string without date-like strings.;
%let	fIsDate	=	%isDate( inSTR = Hello world! , fDebug = 1 );
%put	&fIsDate.;

/*-Notes- -End-*/