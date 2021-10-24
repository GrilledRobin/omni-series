%macro getSeqDatesInPeriod(
	dnDateBgn	=
	,dnDateEnd	=
	,tInterval	=	DAY
	,tAlignment	=	B
	,outCNT		=	GnDates
	,outELpfx	=	GeDates
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to retrieve a series of sequential dates within the provided period of time, in terms of the function		|
|	| [INTNX].																															|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|___________________________________________________________________________________________________________________________________|
|	|[Required] Options for date retrieval by the Calendar:																				|
|	|___________________________________________________________________________________________________________________________________|
|	|dnDateBgn	:	The beginning date of the period.																					|
|	|				The naming convention [dn] indicates that it is a date but shown as a numeric string [yyyymmdd].					|
|	|dnDateEnd	:	The ending date of the period.																						|
|	|				The naming convention [dn] indicates that it is a date but shown as a numeric string [yyyymmdd].					|
|	|tInterval	:	The time interval to identify the dates.																			|
|	|				Please look into the option <Interval> of function [INTNX] in the official document for more information.			|
|	|				Default: [DAY]																										|
|	|tAlignment	:	The position of SAS dates within the [tInterval].																	|
|	|				Please look into the option <Alignment> of function [INTNX] in the official document for more information.			|
|	|				Default: [B]																										|
|	|___________________________________________________________________________________________________________________________________|
|	|[Required] Common Operations:																										|
|	|___________________________________________________________________________________________________________________________________|
|	|outCNT		:	Number of dates found in the calendar(s).																			|
|	|outELpfx	:	Prefix of macro variables, which will contain the SAS date values (instead of formatted date strings).				|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20180402		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180405		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Use [DATA _NULL_;] step to replace the original macro functions [SYSFUNC], for many user-defined date intervals can only be	|
|	|      | called within DATA step instead of macro facility when executing functions as  [INTCK] or [INTNX] under SAS 9.4.			|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Please find the attachments for examples.																							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*010.	Set parameters.;
%*011.	Identify current processing macro.;
%local
	L_mcrLABEL
	Lohno
;
%let	L_mcrLABEL	=	&sysMacroName.;
%let	Lohno		=	%str(E)RROR: [&L_mcrLABEL.]Process failed due to %str(e)rrors!;

%*012.	Handle the parameter buffer.;

%*013.	Define the local environment.;
%local
	dDateBgn	dDateEnd
	tmpDate		Di
;
%let	dDateBgn	=	%sysfunc(inputn( &dnDateBgn. , yymmdd10. ));
%let	dDateEnd	=	%sysfunc(inputn( &dnDateEnd. , yymmdd10. ));

%*018.	Define the global environment.;
%global	&outCNT.;
%let	&outCNT.	=	0;

%*100.	Create the series of dates.;
data _NULL_;
	%*100.	Initialize the loop.;
	length
		Di
		tmpDate
		outCNT
		8
	;
	Di		=	0;
	tmpDate	=	intnx( "&tInterval." , &dDateBgn. , Di , "&tAlignment." );
	outCNT	=	0;

	%*200.	Loop the dates within the period.;
	do until( tmpDate > &dDateEnd. );
		%*100.	Continue to increment the value if it does not lie inside the period.;
		if	tmpDate	<	&dDateBgn.	or	tmpDate	>	&dDateEnd.	then do;
			goto	NextIter;
		end;

		%*200.	Increment the global counter of identified dates.;
		outCNT	+	1;

		%*300.	Create macro variable to store current date value.;
		call symputx(cats("&outELpfx.",outCNT),tmpDate,"G");

		%*800.	Increment the counter.;
		NextIter:
		Di		+	1;

		%*900.	Increment the data value by request.;
		tmpDate	=	intnx( "&tInterval." , &dDateBgn. , Di , "&tAlignment." );
	end;

	%*900.	Output the count of all dates as identified.;
	call symputx("&outCNT.",outCNT,"G");
run;
/*
%let	Di			=	0;
%let	tmpDate		=	%sysfunc(intnx( &tInterval. , &dDateBgn. , &Di. , &tAlignment. ));
%do %until( &tmpDate. > &dDateEnd. );
	%*100.	Continue to increment the value if it does not lie inside the period.;
	%if	&tmpDate.	<	&dDateBgn.	or	&tmpDate.	>	&dDateEnd.	%then %do;
		%goto	NextIter;
	%end;

	%*200.	Increment the global counter of identified dates.;
	%let	&outCNT.	=	%eval( &&&outCNT.. + 1 );

	%*300.	Create macro variable to store current date value.;
	%global	&outELpfx.&&&outCNT..;
	%let	&outELpfx.&&&outCNT..	=	&tmpDate.;

	%*800.	Increment the counter.;
	%NextIter:
	%let	Di	=	%eval( &Di. + 1 );

	%*900.	Increment the data value by request.;
	%let	tmpDate		=	%sysfunc(intnx( &tInterval. , &dDateBgn. , &Di. , &tAlignment. ));
%end;
*/
%*900.	Purge.;

%EndOfProc:
%mend getSeqDatesInPeriod;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvDB"
		"D:\SAS\omnimacro\AdvOp"
		"D:\SAS\omnimacro\Dates"
		"D:\SAS\omnimacro\FileSystem"
	)
	mautosource
;

%*100.	Data Preparation.;

%*110.	Create Calendar dataset.;
%crCalendar(
	inYEAR		=	2015
	,procLIB	=	WORK
	,outDAT		=	tmpCalendar2015
)
%crCalendar(
	inYEAR		=	2016
	,procLIB	=	WORK
	,outDAT		=	tmpCalendar2016
)

%*120.	Retrieve all date information for the period of 20160229 to 20160603.;
%getSeqDatesInPeriod(
	dnDateBgn	=	20160101
	,dnDateEnd	=	20160108
	,tInterval	=	DAY
	,tAlignment	=	B
	,outCNT		=	GnDates
	,outELpfx	=	GeDates
)
%macro a;
%do i=1 %to &GnDates.;
	%put	[GeDates&i.]=[&&GeDates&i..];
%end;
%mend a;
%a

/*-Notes- -End-*/