%macro crCalendar(
	inYEAR		=
	,procLIB	=	WORK
	,outDAT		=	tmpCalendar
	,CountryCD	=	CN
	,ClndrAdj	=	%nrstr(D:\SAS\omnimacro\Dates\CalendarAdj.csv)
);
%*001.	Check parameters.;
%let	procLIB	=	%unquote(&procLIB.);
%Local
	OptNotes	OptSource	OptSource2	OptMLogic	OptSymGen	OptMPrint	OptInOper
	LpYearFst	LpYearLst
;

%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))		=	0	%then	%let	procLIB		=	WORK;
%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))		=	0	%then	%let	outDAT		=	tmpCalendar;
%if	%length(%qsysfunc(compress(&CountryCD.,%str( ))))	=	0	%then	%let	CountryCD	=	CN;
%if	%length(%qsysfunc(compress(&ClndrAdj.,%str( ))))	=	0	%then	%let	ClndrAdj	=	%nrstr(D:\SAS\omnimacro\Dates\CalendarAdj.csv);

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

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in traditional SAS syntax colors.;
%macro dummy; %mend dummy;

%*090.	Create temporary formats for date mapping.;
data &procLIB.._CalnFmt;
	length
		CountryCode				$4
		N_WEEKDAY	F_WORKDAY	3
		C_DESC					$16
	;
	CountryCode	=	'CN';
	N_WEEKDAY	=	1;	F_WORKDAY	=	0;	C_DESC	=	'星期天';	output;
	N_WEEKDAY	=	2;	F_WORKDAY	=	1;	C_DESC	=	'星期一';	output;
	N_WEEKDAY	=	3;	F_WORKDAY	=	1;	C_DESC	=	'星期二';	output;
	N_WEEKDAY	=	4;	F_WORKDAY	=	1;	C_DESC	=	'星期三';	output;
	N_WEEKDAY	=	5;	F_WORKDAY	=	1;	C_DESC	=	'星期四';	output;
	N_WEEKDAY	=	6;	F_WORKDAY	=	1;	C_DESC	=	'星期五';	output;
	N_WEEKDAY	=	7;	F_WORKDAY	=	0;	C_DESC	=	'星期六';	output;
run;

%*100.	Create Calendar.;
%*110.	Load the CSV configuration file in predefined format as the adjustment on the calendar.;
data &procLIB.._CalnAdj;
	%*100.	Define the variables.;
	length
		CountryCode				$4
		D_DATE					8
		F_WORKDAY	N_WEEKDAY	8
		C_DESC					$16
	;
	format	D_DATE	yymmddD10.;

	%*200.	Link to the configuration file.;
	infile
		%sysfunc(quote( &ClndrAdj. , %str(%') ))
		dlm			=	","
		encoding	=	"utf-8"
		missover
		lrecl		=	1024
		firstobs	=	2
		end			=	EndFile
	;

	%*300.	Read the data.;
	input
		CountryCode	$
		D_DATE		yymmdd10.
		C_DESC		$
		F_WORKDAY
	;

	%*500.	Identify the period covered by the adjustment.;
	retain	minYear	maxYear	0;
	if	_N_	=	1	then do;
		minYear	=	year(D_DATE);
		maxYear	=	year(D_DATE);
	end;
	if	minYear	>	year(D_DATE)	then	minYear	=	year(D_DATE);
	if	maxYear	<	year(D_DATE)	then	maxYear	=	year(D_DATE);

	%*800.	Create the local parameter to hold the value of the entire period coverage.;
	if	EndFile	then do;
		call symputx( "LpYearFst" , minYear , "F" );
		call symputx( "LpYearLst" , maxYear , "F" );
	end;

	%*900.	Purge.;
	drop	minYear	maxYear;
run;

%*150.	Create the full calendar in terms of the period coverage.;
data &procLIB.._CalnPre;
	%*100.	Define the variables.;
	length
		CountryCode				$4
		D_DATE					8
		C_DATE					$8
		F_WORKDAY	N_WEEKDAY	8
		C_DESC					$16
		F_TradeDay				8
		tmp_i					8
	;
	format	D_DATE	yymmddD10.;

	%*200.	Prepare to load the configuration tables.;
	if	_N_	=	1	then do;
		%*100.	Load the Date Description.;
		dcl	hash	hDes(dataset:"&procLIB.._CalnFmt");
		hDes.DefineKey("CountryCode","N_WEEKDAY");
		hDes.DefineData("C_DESC","F_WORKDAY");
		hDes.DefineDone();

		%*200.	Load the Calendar Adjustment.;
		dcl	hash	hAdj(dataset:"&procLIB.._CalnAdj");
		hAdj.DefineKey("CountryCode","D_DATE");
		hAdj.DefineData("C_DESC","F_WORKDAY");
		hAdj.DefineDone();

		%*900.	Initialize the new fields.;
		call missing(C_DESC,F_WORKDAY);
	end;

	%*500.	Create the Calendar through the entire period.;
	%*We extend the required period by 30 days to both sides, to correct the related WorkDays and TradeDays respectively.;
	do tmp_i = %eval( %sysfunc(mdy(1,1,&LpYearFst.)) - 30 ) to %eval( %sysfunc(mdy(12,31,&LpYearLst.)) + 30 );
		CountryCode	=	%sysfunc(quote( &CountryCD. , %str(%') ));
		D_DATE		=	tmp_i;
		C_DATE		=	put(D_DATE,yymmddN8.);
		N_WEEKDAY	=	weekday(D_DATE);
		_iorc_		=	hDes.find();
		_iorc_		=	hAdj.find();

		%*Correct the WorkDays and TradeDays.;
		%*Below statement is remarked as it is less likely that the New Year Day is public holiday in all countries.;
%*		if	month(D_DATE)	=	1	and	day(D_DATE)	=	1	then	F_WORKDAY	=	0;
		F_TradeDay	=	( F_WORKDAY and ( N_WEEKDAY not in ( 1 , 7 ) ) );
		output;
	end;
run;

%*200.	Identify the necessary attributes of WorkDays.;
%*210.	Only retrieve the WorkDays.;
proc sort
	data=&procLIB.._CalnPre( keep= D_DATE F_WORKDAY where=( F_WORKDAY ) )
	out=&procLIB.._CalnWD( keep= D_DATE )
;
	by	descending	D_DATE;
run;

%*220.	Identify the [Next WorkDay of each date].;
data &procLIB.._CalnWD;
	%*100.	Overwrite the same data to save space.;
	set &procLIB.._CalnWD;
	by	descending	D_DATE;

	%*200.	Create new fields.;
	length	D_NextWorkday	8;
	format	D_NextWorkday	yymmddD10.;

	%*500.	Set the Next WorkDay to current one.;
	D_NextWorkday	=	lag(D_DATE);
run;

%*250.	Identify the [Previous WorkDay of each date].;
proc sort
	data=&procLIB.._CalnWD
;
	by	D_DATE;
run;
data &procLIB.._CalnWD;
	%*100.	Overwrite the same data to save space.;
	set &procLIB.._CalnWD;
	by	D_DATE;

	%*200.	Create new fields.;
	length	D_PrevWorkday	8;
	format	D_PrevWorkday	yymmddD10.;

	%*500.	Set the Previous WorkDay to current one.;
	D_PrevWorkday	=	lag(D_DATE);
run;

%*300.	Identify the necessary attributes of TradeDays.;
%*310.	Only retrieve the TradeDays.;
proc sort
	data=&procLIB.._CalnPre( keep= D_DATE F_TradeDay where=( F_TradeDay ) )
	out=&procLIB.._CalnTD( keep= D_DATE )
;
	by	descending	D_DATE;
run;

%*320.	Identify the [Next TradeDay of each date].;
data &procLIB.._CalnTD;
	%*100.	Overwrite the same data to save space.;
	set &procLIB.._CalnTD;
	by	descending	D_DATE;

	%*200.	Create new fields.;
	length	D_NextTradeDay	8;
	format	D_NextTradeDay	yymmddD10.;

	%*500.	Set the Next TradeDay to current one.;
	D_NextTradeDay	=	lag(D_DATE);
run;

%*350.	Identify the [Previous TradeDay of each date].;
proc sort
	data=&procLIB.._CalnTD
;
	by	D_DATE;
run;
data &procLIB.._CalnTD;
	%*100.	Overwrite the same data to save space.;
	set &procLIB.._CalnTD;
	by	D_DATE;

	%*200.	Create new fields.;
	length	D_PrevTradeDay	8;
	format	D_PrevTradeDay	yymmddD10.;

	%*500.	Set the Previous TradeDay to current one.;
	D_PrevTradeDay	=	lag(D_DATE);
run;

%*400.	Retrieve the related dates.;
%*410.	Retrieve the user defined period for the final calculation.;
proc sort
	data=&procLIB.._CalnPre
	out=&procLIB.._CalnUsr
;
	by	descending	D_DATE;
run;

%*420.	Identify the [Previous WorkDays] and [Previous TradeDays] of all Calendar Days.;
data &procLIB.._CalnUsr;
	%*100.	Set the user calendar.;
	set &procLIB.._CalnUsr;
	by	descending	D_DATE;

	%*200.	Create new fields.;
	format	D_PrevWorkday	D_PrevTradeDay	yymmddD10.;
	retain	D_PrevWorkday	D_PrevTradeDay;

	%*300.	Prepare to load the additional fields.;
	if	_N_	=	1	then do;
		%*100.	Load the related WorkDays.;
		dcl	hash	hWD(dataset:"&procLIB.._CalnWD");
		hWD.DefineKey("D_DATE");
		hWD.DefineData("D_PrevWorkday");
		hWD.DefineDone();

		%*200.	Load the related TradeDays.;
		dcl	hash	hTD(dataset:"&procLIB.._CalnTD");
		hTD.DefineKey("D_DATE");
		hTD.DefineData("D_PrevTradeDay");
		hTD.DefineDone();

		%*900.	Initialize the new fields.;
		call missing(D_PrevWorkday,D_PrevTradeDay);
	end;

	%*400.	Load the additional fields.;
	_iorc_	=	hWD.find();
	_iorc_	=	hTD.find();
run;

%*450.	Identify the [Next WorkDays] and [Next TradeDays] of all Calendar Days.;
proc sort
	data=&procLIB.._CalnUsr
;
	by	D_DATE;
run;
data &procLIB.._CalnUsr;
	%*100.	Set the user calendar.;
	set &procLIB.._CalnUsr;
	by	D_DATE;

	%*200.	Create new fields.;
	format	D_NextWorkday	D_NextTradeDay	yymmddD10.;
	retain	D_NextWorkday	D_NextTradeDay;

	%*300.	Prepare to load the additional fields.;
	if	_N_	=	1	then do;
		%*100.	Load the related WorkDays.;
		dcl	hash	hWD(dataset:"&procLIB.._CalnWD");
		hWD.DefineKey("D_DATE");
		hWD.DefineData("D_NextWorkday");
		hWD.DefineDone();

		%*200.	Load the related TradeDays.;
		dcl	hash	hTD(dataset:"&procLIB.._CalnTD");
		hTD.DefineKey("D_DATE");
		hTD.DefineData("D_NextTradeDay");
		hTD.DefineDone();

		%*900.	Initialize the new fields.;
		call missing(D_NextWorkday,D_NextTradeDay);
	end;

	%*400.	Load the additional fields.;
	_iorc_	=	hWD.find();
	_iorc_	=	hTD.find();
run;

%*500.	Create further fields and only export the user requested period.;
%*510.	Retrieve the user defined period for the final calculation.;
proc sort
	data=&procLIB.._CalnUsr(
		where=(
		%if	%length(%qsysfunc(compress(&inYEAR.,%str( ))))	=	0	%then %do;
			%sysfunc(mdy(1,1,&LpYearFst.))	<=	D_DATE	<=	%sysfunc(mdy(12,31,&LpYearLst.))
		%end;
		%else %do;
			year(D_DATE)	=	&inYEAR.
		%end;
		)
	)
	out=&procLIB.._CalnOut
;
	by	D_DATE;
run;

%*550.	Calculate [N_BLOCK] and [N_TradeBlock].;
data %unquote(&outDAT.);
	%*100.	Set the user calendar.;
	set	&procLIB.._CalnOut;
	by	D_DATE;

	%*200.	Create new fields.;
	length	N_BLOCK	N_WORKDAY	N_TradeBlock	N_TradeDay	8;
	retain	tmp_WDblk	tmp_TDblk	N_WORKDAY	N_TradeDay	0;
	N_BLOCK			=	0;
	N_TradeBlock	=	0;

	%*300.	Calculate the WorkDay Blocks.;
	%*310.	Reset the counters and flags where necessary.;
	if	F_WORKDAY	=	0	then	N_WORKDAY	=	0;

	%*320.	Increment the counter of workdays in a block.;
	N_WORKDAY	+	( F_WORKDAY = 1 );

	%*330.	Increment the counter of the workday blocks when encountering each first workday.;
	tmp_WDblk	+	( N_WORKDAY = 1 );
	if	F_WORKDAY	=	1	then do;
		N_BLOCK		=	tmp_WDblk;
	end;

	%*400.	Calculate the TradeDay Blocks.;
	%*410.	Reset the counters and flags where necessary.;
	if	F_TradeDay	=	0	then	N_TradeDay	=	0;

	%*420.	Increment the counter of workdays in a block.;
	N_TradeDay	+	( F_TradeDay = 1 );

	%*430.	Increment the counter of the Trade Day blocks when encountering each first Trade Day.;
	tmp_TDblk	+	( N_TradeDay = 1 );
	if	F_TradeDay	=	1	then do;
		N_TradeBlock	=	tmp_TDblk;
	end;

	%*900.	Purge.;
	drop tmp:;
run;

%EndCrCalendar:
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
%mend crCalendar;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\Dates"
	)
	mautosource
;
%let	L_curFdr	=	D:\SAS\Calendar;
%let	L_srcflnm	=	D:\SAS\omnimacro\Dates\CalendarAdj.csv;
libname	cln	%sysfunc(quote( &L_curFdr. , %str(%') ));

%*100.	Generate the calendar for all years in current adjustment period.;
%crCalendar(
	inYEAR		=
	,procLIB	=	WORK
	,outDAT		=	tmpCalendar
	,CountryCD	=	CN
	,ClndrAdj	=	&L_srcflnm.
)

%*500.	Generate the calendar for any year.;
%let	yr	=	2018;
%crCalendar(
	inYEAR		=	&yr.
	,procLIB	=	WORK
	,outDAT		=	%nrbquote(cln.Calendar&yr.(compress=yes))
	,CountryCD	=	CN
	,ClndrAdj	=	&L_srcflnm.
)

/*-Notes- -End-*/