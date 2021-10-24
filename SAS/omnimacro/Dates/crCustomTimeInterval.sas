%macro crCustomTimeInterval(
	inClndrPfx	=
	,preProc	=
	,outPfx		=	CN
	,procLIB	=	WORK
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to generate many datasets that store the Custom Time Intervals for functions as [INTCK] and [INTNX] to call.|
|	|IMPORTANT: It is found that the call like [%sysfunc(INTNX(Interval,DateBgn,Increment,Alignment))] upon the Custom Time Intervals	|
|	|            which are defined from the system option [IntervalDS=] would fail under SAS9.4 environment.							|
|	|           Hence it is strongly recommended to use these Customer Time Intervals within DATA step in any programs. Hope this		|
|	|            restriction can be fixed in new versions of SAS.																		|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inClndrPfx	:	The prefix of the series of datasets that store the yearly calendars.												|
|	|				The naming convention is: [inClndrPfx<yyyy>].																		|
|	|preProc	:	The statements to pre-control the input values. There MUST be ending semi-colon [;] to complete the statements.		|
|	|				This process is often used to filter the input dates, such as only to retrieve the Workdays.						|
|	|outPfx		:	The prefix of the datasets to be output, its length should be LESS THAN 16 characters.								|
|	|procLIB	:	The working library.																								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20180405		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Please find the attachments for examples.																							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|800.	Sample Results.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|For the Chinese Calendars, we can set below parameters, presuming that the calendar data is										|
|	| named as [ysrc.calendar<yyyy>]:																									|
|	|inClndrPfx	=	ysrc.calendar																										|
|	|preProc	=	%nrstr( )																											|
|	|outPfx		=	CN																													|
|	|procLIB	=	WORK																												|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|				Period				|			Name of Datasets			|				Description of Datasets				|
|	|	|___________________________________|_______________________________________|___________________________________________________|
|	|	| [outPfx] = [CN]					| [CNWorkDay]							| All Workdays										|
|	|	|									| [CNWorkWeek]							| All blocks of weeks that only describe the		|
|	|	|									|										|  Workdays, with [season] set unique for each		|
|	|	|									|										|  block.											|
|	|	|									| [CNTradeDay]							| All Trade Days (esp. for Stock Markets)			|
|	|	|									| [CNTradeWeek]							| All blocks of weeks that only describe the		|
|	|	|									|										|  Trade Days, with [season] set unique for each	|
|	|	|									|										|  block.											|
|	|	|___________________________________|_______________________________________|___________________________________________________|
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
%let	procLIB	=	%unquote(&procLIB.);

%if	%length(%qsysfunc(compress(&inClndrPfx.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No Calendar data [inClndrPfx=] is specified! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%index( &inClndrPfx. , . )	=	0	%then %do;
	%let	inClndrPfx	=	work.&inClndrPfx.;
%end;

%if	%length(%qsysfunc(compress(&outPfx.,%str( ))))	=	0	%then	%let	outPfx	=	CN;
%let	outPfx	=	%sysfunc(strip(&outPfx.));

%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))	=	0	%then	%let	procLIB	=	WORK;

%*013.	Define the local environment.;
%local
	OptNotes	OptSource	OptSource2	OptMLogic	OptSymGen	OptMPrint	OptInOper
	Yi
;

%*016.	Switch off the system options to reduce the LOG size.;
%if %sysfunc(getoption( notes ))		=	NOTES		%then	%let	OptNotes	=	1;	%else	%let	OptNotes	=	0;
%if %sysfunc(getoption( source ))		=	SOURCE		%then	%let	OptSource	=	1;	%else	%let	OptSource	=	0;
%if %sysfunc(getoption( source2 ))		=	SOURCE2		%then	%let	OptSource2	=	1;	%else	%let	OptSource2	=	0;
%if %sysfunc(getoption( mlogic ))		=	MLOGIC		%then	%let	OptMLogic	=	1;	%else	%let	OptMLogic	=	0;
%if %sysfunc(getoption( symbolgen ))	=	SYMBOLGEN	%then	%let	OptSymGen	=	1;	%else	%let	OptSymGen	=	0;
%if %sysfunc(getoption( mprint ))		=	MPRINT		%then	%let	OptMPrint	=	1;	%else	%let	OptMPrint	=	0;
%if %sysfunc(getoption( minoperator ))	=	MINOPERATOR	%then	%let	OptInOper	=	1;	%else	%let	OptInOper	=	0;
%*The default value of the system option [MINDELIMITER] is WHITE SPACE, given the option [MINOPERATOR] is on.;
options nonotes nosource nosource2 nomlogic nosymbolgen nomprint minoperator;

%*018.	Define the global environment.;

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in traditional SAS syntax colors.;
%macro dummy; %mend dummy;

%*100.	Set the Calendars of all years..;
data &procLIB..__CTI_Calendar__;
	%*100.	Set all Calendar Datasets.;
	set	%unquote(&inClndrPfx.):;

	%*300.	Apply the pre-control process if any.;
%if	%length(%qsysfunc(compress(&preProc.,%str( ))))	^=	0	%then %do;
	%unquote(&preProc.)
%end;

	%*400.	Create new fields.;
	length	N_YEAR	8;
	N_YEAR	=	year(D_DATE);
run;

%*200.	Generate the Workday datasets in terms of the calendar data.;
%*210.	Years, Quarters and Months.;
proc sort
	data=&procLIB..__CTI_Calendar__(
		where=(
			F_WORKDAY	=	1
		)
	)
	out=&procLIB..__CTI_Workday__
;
	by	N_YEAR	N_BLOCK	D_DATE;
run;
data
	&outPfx.WorkDay		&outPfx.WorkWeek
;
	%*010.	Set the combined calendar data.;
	set &procLIB..__CTI_Workday__ end=EOF;
	by	N_YEAR	N_BLOCK	D_DATE;

	%*050.	Create new fields.;
	length
		begin	end		season
		8
	;
	format
		begin	end
		yymmddD10.
	;
	retain
		Season_D	Begin_W
		0
	;
	keep
		begin	end		season
	;
	end		=	D_DATE;

	%*100.	Initialization.;
	%*110.	Initialize values for years.;
	if	first.N_YEAR	then do;
		Season_D	=	0;
	end;

	%*110.	Initialize values for weeks.;
	if	first.N_BLOCK	then do;
		Season_W	=	N_BLOCK;
		Begin_W		=	D_DATE;
	end;

	%*500.	Output.;
	%*510.	All days as separate seasons.;
	Season_D	+	1;
	season		=	Season_D;
	begin		=	D_DATE;
	output	&outPfx.WorkDay;

	%*520.	Weeks.;
	season	=	N_BLOCK;
	if	last.N_BLOCK	then do;
		begin	=	Begin_W;
		output	&outPfx.WorkWeek;
	end;
run;

%*300.	Generate the Trade Day datasets in terms of the calendar data.;
%*210.	Years, Quarters and Months.;
proc sort
	data=&procLIB..__CTI_Calendar__(
		where=(
			F_TradeDay	=	1
		)
	)
	out=&procLIB..__CTI_Tradeday__
;
	by	N_YEAR	N_TradeBlock	D_DATE;
run;
data
	&outPfx.TradeDay	&outPfx.TradeWeek
;
	%*010.	Set the combined calendar data.;
	set &procLIB..__CTI_Tradeday__ end=EOF;
	by	N_YEAR	N_TradeBlock	D_DATE;

	%*050.	Create new fields.;
	length
		begin	end		season
		8
	;
	format
		begin	end
		yymmddD10.
	;
	retain
		Season_D	Begin_W
		0
	;
	keep
		begin	end		season
	;
	end		=	D_DATE;

	%*100.	Initialization.;
	%*110.	Initialize values for years.;
	if	first.N_YEAR	then do;
		Season_D	=	0;
	end;

	%*110.	Initialize values for weeks.;
	if	first.N_TradeBlock	then do;
		Season_W	=	N_TradeBlock;
		Begin_W		=	D_DATE;
	end;

	%*500.	Output.;
	%*510.	All days as separate seasons.;
	Season_D	+	1;
	season		=	Season_D;
	begin		=	D_DATE;
	output	&outPfx.TradeDay;

	%*520.	Weeks.;
	season	=	N_TradeBlock;
	if	last.N_TradeBlock	then do;
		begin	=	Begin_W;
		output	&outPfx.TradeWeek;
	end;
run;

%EndOfProc:
%*Restore the system options.;
options
%if	&OptNotes.		=	1	%then %do;	NOTES		%end;	%else %do;	NONOTES			%end;
%if	&OptSource.		=	1	%then %do;	SOURCE		%end;	%else %do;	NOSOURCE		%end;
%if	&OptSource2.	=	1	%then %do;	SOURCE2		%end;	%else %do;	NOSOURCE2		%end;
%if	&OptMLogic.		=	1	%then %do;	MLOGIC		%end;	%else %do;	NOMLOGIC		%end;
%if	&OptSymGen.		=	1	%then %do;	SYMBOLGEN	%end;	%else %do;	NOSYMBOLGEN		%end;
%if	&OptMPrint.		=	1	%then %do;	MPRINT		%end;	%else %do;	NOMPRINT		%end;
%if	&OptInOper.		=	1	%then %do;	MINOPERATOR	%end;	%else %do;	NOMINOPERATOR	%end;
;
%mend crCustomTimeInterval;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\Dates"
	)
	mautosource
;
libname	cln	"D:\SAS\Calendar";

%crCustomTimeInterval(
	inClndrPfx	=	cln.calendar
	,preProc	=
	,outPfx		=	CN
	,procLIB	=	WORK
)

options
	IntervalDS=(
		CNWorkDay	=	CNWorkDay
		CNWorkWeek	=	CNWorkWeek

		CNTradeDay	=	CNTradeDay
		CNTradeWeek	=	CNTradeWeek
	)
;

data a;
	format	dt	new	yymmddD10.;

	dt	=	input("20120130",yymmdd10.);	new	=	intnx("CNWorkDay",dt,8,"b");	output;
	dt	=	input("20120906",yymmdd10.);	new	=	intnx("CNWorkWeek",dt,2,"m");	output;

	dt	=	input("20120130",yymmdd10.);	new	=	intnx("CNTradeDay3",dt,2,"b");	output;
	dt	=	input("20120906",yymmdd10.);	new	=	intnx("CNTradeWeek4",dt,2,"m");	output;
run;

/*-Notes- -End-*/