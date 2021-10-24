%macro isWorkDay(
	inDATE		=
	,inDateFmt	=
	,inCalendar	=
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to flag whether the given date is Workday with respect to the provided Calendar data.						|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDATE		:	The date for which to flag the workday.																				|
|	|inDateFmt	:	The inFormat of the provided date to be input as numeric value.														|
|	|				Leave it BLANK to indicate that it is already a numeric date value.													|
|	|inCalendar	:	The dataset that contains the dates with respect of the Calendar.													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20160820		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
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

%*013.	Define the local environment.;
%local
	LfDate
	idCalendar
	varnum_F_WD
	LfWorkDay
	rc
;
%let	LfDate		=	0;
%let	LfWorkDay	=	0;

%*100.	Verify whether the given date is in the Calendar data.;
%let	LfDate	=
			%getOBS4DATA(
				inDAT	=	%nrbquote(
								&inCalendar.(
									where=(
										D_DATE		=	&inDATE.
									)
								)
							)
				,outVAR	=
				,gMode	=	F
			)
;

%*190.	Issue warning message and quit the program, should there be no result found.;
%if	&LfDate.	=	0	%then %do;
	%*100.	Issue the warning message.;
	%put	%str(W)ARNING: [&L_mcrLABEL.]The given data is NOT in the provided Calendar dataset!;

	%*200.	Skip the formatting process.;
	%goto	EndOfFmtDate;
%end;

%*200.	Open given Calendar dataset.;
%let	idCalendar	=
			%sysfunc(
				open(
					%nrbquote(
						&inCalendar.(
							where=(
								D_DATE		=	&inDATE.
							)
						)
					)
				)
			)
;

%*300.	Retrieve the variable number of [F_WORKDAY] in the open Calendar dataset.;
%let	varnum_F_WD	=	%sysfunc(varnum(&idCalendar.,F_WORKDAY));

%*400.	Retrieve the Workday flag from the calendar data.;
%let	rc			=	%sysfunc(fetch(&idCalendar.));
%let	LfWorkDay	=	%sysfunc(getvarn(&idCalendar.,&varnum_F_WD.));

%*500.	Close the Calendar dataset.;
%CloseDS:
%let	rc	=	%sysfunc(close(&idCalendar.));

%*600.	Assign format for the output result.;
%EndOfFmtDate:

%*800.	Announcement.;
&LfWorkDay.

%*900.	Purge memory usage.;

%EndOfProc:
%mend isWorkDay;

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

%*200.	Verify the date in the format of [yymmddN8.].;
%global	fIsWD;
%let	fIsWD	=
			%isWorkDay(
				inDATE		=	20160814
				,inDateFmt	=	%nrbquote(yymmdd10.)
				,inCalendar	=	tmpCalendar
			)
;
%put	&fIsWD.;

%*600.	Return the value with default settings.;
%put	%isWorkDay(inDATE=20680,inCalendar=tmpCalendar);

/*-Notes- -End-*/