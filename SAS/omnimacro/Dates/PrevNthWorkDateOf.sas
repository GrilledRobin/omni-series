%macro PrevNthWorkDateOf(
	inDATE		=
	,nWorkDays	=	1
	,inDateFmt	=
	,inCalendar	=
	,outVAR		=
	,outDateFmt	=
	,gMode		=	F
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to Retrieve (and/or return) the N[th] Previous Work Date of the given date by calling [PrevWorkDateOf]		|
|	| repeatedly, in terms of the provided Calendar dataset.																			|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDATE		:	The date for which to retrieve the Previous Work Date.																|
|	|nWorkDays	:	The number of Workdays to count back from the given date.															|
|	|inDateFmt	:	The inFormat of the provided date to be input as numeric value.														|
|	|				Leave it BLANK to indicate that it is already a numeric date value.													|
|	|inCalendar	:	The dataset that contains the dates with respect of the Calendar.													|
|	|outVAR		:	The output macro variable that holds the value of the Previous Work Date.											|
|	|outDateFmt	:	The Format of the output date value as a text character string, such as [yyyymmddD10.].								|
|	|				Leave it BLANK to indicate that it is a numeric date value.															|
|	|gMode		:	The mode to execute this macro, [F] represents Function Mode, while [P] represents Procedure Mode					|
|	|				[F] mode directly returns the value of the Previous Work Date														|
|	|				[P] mode only exports the macro variable that holds the value of the Previous Work Date								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20160827		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
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
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|The input Calendar data MUST contain below fields:																					|
|	|	D_DATE		(numeric, date format)																								|
|	|	F_WORKDAY	(numeric, flag)																										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ErrMcr																															|
|	|	|getOBS4DATA																													|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\Dates"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|PrevWorkDateOf																													|
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
%if	%length(%qsysfunc(compress(&inDATE.,%str( ))))		=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No date is given for searching! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%length(%qsysfunc(compress(&nWorkDays.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.][nWorkDays] is not provided, program will search the first previous workday.;
	%let	nWorkDays	=	1;
%end;
%if	%length(%qsysfunc(compress(&inDateFmt.,%str( ))))	^=	0	%then %do;
	%*Here we set the [inDATE] as a numeric Date value as standardization.;
	%let	inDATE	=	%sysfunc(inputn(&inDATE.,&inDateFmt.));
%end;
%if	%length(%qsysfunc(compress(&inCalendar.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No Calendar dataset is provided!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%sysfunc(exist(&inCalendar.))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]The provided Calendar dataset does not exist!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%length(%qsysfunc(compress(&outVAR.,%str( ))))	=	0	%then	%let	outVAR	=	tmpNVdate;
%*Valid value of [gMode] can only be: P, F or null;
%*We make F as the default value.;
%if	%qupcase(&gMode.)	^=	P	%then %do;
	%let	gMode	=	F;
%end;
%else %do;
	%let	gMode	=	P;
%end;
%let	&outVAR.	=	&inDATE.;

%*013.	Define the local environment.;
%local
	LPrevWD
	Di
;
%let	LPrevWD	=	0;

%*100.	Retrieve the N[th] previous workday by calling [PrevWorkDateOf] recursively.;
%*110.	Set the result as the same as the input, if the [nWorkDays] = 0.;
%if	&nWorkDays.	<=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.][nWorkDays=&nWorkDays.] is out of scope, program returns the same date as input.;
	%goto	EndOfLoop;
%end;

%do Di=1 %to &nWorkDays.;
	%*100.	Retrieve the previous workday of current date.;
	%let	LPrevWD	=	%PrevWorkDateOf( inDATE = &&&outVAR.. , inCalendar = &inCalendar. );

	%*200.	Assign the earliest workday as the output result.;
	%if	%length(%qsysfunc(compress(&LPrevWD.,%str( ))))	^=	0	%then %do;
		%let	&outVAR.	=	&LPrevWD.;
	%end;

	%*300.	Leave the loop if there is no further previous workday.;
	%if	%length(%qsysfunc(compress(&LPrevWD.,%str( ))))	=	0	%then %do;
		%goto	EndOfLoop;
	%end;
%end;
%EndOfLoop:

%*600.	Assign format for the output result.;
%if	%length(%qsysfunc(compress(&outDateFmt.,%str( ))))	^=	0	%then %do;
	%let	&outVAR.	=	%sysfunc(putn(&&&outVAR..,&outDateFmt.));
%end;
%EndOfFmtDate:

%*800.	Announcement.;
%if	&gMode.	=	F	%then %do;
	&&&outVAR..
%end;

%*900.	Purge memory usage.;

%EndOfProc:
%mend PrevNthWorkDateOf;

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

%*100.	Create Calendar dataset.;
%crCalendar(
	inYEAR		=	2016
	,procLIB	=	WORK
	,outDAT		=	tmpCalendar
)

%*200.	Return the macro variable with the format of [DATE9.].;
%global	vPrevWD;
%let	vPrevWD	=;
%PrevNthWorkDateOf(
	inDATE		=	20160814
	,nWorkDays	=	5
	,inDateFmt	=	%nrbquote(yymmdd10.)
	,inCalendar	=	tmpCalendar
	,outVAR		=	vPrevWD
	,outDateFmt	=	%nrbquote(date9.)
	,gMode		=	P
)
%put	[vPrevWD] = [&vPrevWD.];

%*300.	Return the macro variable with the format of [yymmddN8.].;
%global	vPrevWD2;
%let	vPrevWD2	=;
%PrevNthWorkDateOf(
	inDATE		=	20160814
	,nWorkDays	=	5
	,inDateFmt	=	%nrbquote(yymmdd10.)
	,inCalendar	=	tmpCalendar
	,outVAR		=	vPrevWD2
	,outDateFmt	=	%nrbquote(yymmddN8.)
	,gMode		=	P
)
%put	[vPrevWD2] = [&vPrevWD2.];

%*400.	Return the value with no format.;
%global	vPrevWD3;
%let	vPrevWD3	=
			%PrevNthWorkDateOf(
				inDATE		=	20160814
				,nWorkDays	=	5
				,inDateFmt	=	%nrbquote(yymmdd10.)
				,inCalendar	=	tmpCalendar
				,outVAR		=
				,outDateFmt	=
				,gMode		=	f
			)
;
%put	[vPrevWD3] = [&vPrevWD3.];

%*500.	Return the value with no format, while the input date also has no format.;
%put	%PrevNthWorkDateOf(
				inDATE		=	20680
				,nWorkDays	=	5
				,inDateFmt	=
				,inCalendar	=	tmpCalendar
				,outVAR		=
				,outDateFmt	=
				,gMode		=	f
			)
;

%*600.	Return the value with default settings.;
%put	%PrevNthWorkDateOf(inDATE=20680,inCalendar=tmpCalendar);

%*700.	Test if there is no previous work date.;
%put	%PrevNthWorkDateOf(inDATE=20160101,inDateFmt=%str(anydtdte10.),inCalendar=tmpCalendar);

/*-Notes- -End-*/