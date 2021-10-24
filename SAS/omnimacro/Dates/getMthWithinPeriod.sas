%macro getMthWithinPeriod(
	clnLIB		=	ysrc
	,clnPFX		=	calendar
	,DateBgn	=
	,DateEnd	=
	,outPfx		=	GmwPrd
	,procLIB	=	WORK
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to generate many series of macro variables that store the useful dates for a given period of dates.			|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|clnLIB		:	The library that stores the Calendar data.																			|
|	|clnPFX		:	The prefix of the Calendar data.																					|
|	|DateBgn	:	The beginning of the period to be handled, in the format of [yyyymmdd].												|
|	|DateEnd	:	The end of the period to be handled, in the format of [yyyymmdd].													|
|	|outPfx		:	The prefix of the series of macro variables to be output, its length should be LESS THAN 16 characters.				|
|	|procLIB	:	The working library.																								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20160515		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20160703		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Fixed a bug when calculating the [First Workdays], the condition should be true when [k_wkday] and [F_WORKDAY]				|
|	|      | are both 1 for the same observation of date.																				|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180310		| Version |	1.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180406		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Add the output of macro variables representing the days of all [Work Weeks] and [Trade Weeks] within the period.			|
|	|______|____________________________________________________________________________________________________________________________|
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
|	|For the period starting from 201501 till now, we can set below parameters, presuming that the calendar data is						|
|	| named as [ysrc.calendar<yyyy>]:																									|
|	|clnLIB		=	ysrc																												|
|	|clnPFX		=	calendar																											|
|	|DateBgn	=	20150101																											|
|	|DateEnd	=	20160703																											|
|	|outPfx		=	GmwPrd																												|
|	|procLIB	=	WORK																												|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|				Period				|		Name of Macro Variables			|			Value of Macro Variables				|
|	|	|___________________________________|_______________________________________|___________________________________________________|
|	|	| [outPfx] = [GmwPrd]				| [GmwPrdkYear]							| [2] (Number of years in the period)				|
|	|	| (201501 ~ 201607)					| [GmwPrdkMth]							| [19]												|
|	|	| (m = # of Months)					| [GmwPrdm<k>]							| [201501] ~ [201607]								|
|	|	| (w = # of Work Weeks)				|_______________________________________|___________________________________________________|
|	|	| (t = # of Trade Weeks)			| [GmwPrdkCdOfM<m>]						| [31]~[3] (# Clndr Days of months)					|
|	|	| (k = # of Days)					| [GmwPrddn_BgnOfM<m>]					| [20150101] ~ [20160701] (First days of months)	|
|	|	|									| [GmwPrdd_BgnOfM<m>]					| [20089] ~ [20636] (First days of months)			|
|	|	|									| [GmwPrddn_M<m>_CD<k>]					| [<k>th Clndr day of <m>th Month][yyyymmdd]		|
|	|	|									| [GmwPrdd_M<m>_CD<k>]					| [<k>th Clndr day of <m>th Month][######]			|
|	|	|									| [GmwPrddn_EndOfM<m>]					| [20150131] ~ [20160703] (Last Clndr Days of Mth.)	|
|	|	|									| [GmwPrdd_EndOfM<m>]					| [20119] ~ [20638] (Last Clndr Days of Mth.)		|
|	|	|									|_______________________________________|___________________________________________________|
|	|	|									| [GmwPrdkWdOfM<m>]						| [21]~[1] (# Workdays of months)					|
|	|	|									| [GmwPrddn_FstWdOfM<m>]				| [20150104]~[20160701] (First Workdays of months)	|
|	|	|									| [GmwPrdd_FstWdOfM<m>]					| [20092]~[20638] (First Workdays of months)		|
|	|	|									| [GmwPrddn_M<m>_WD<k>]					| [<k>th Workday of <m>th Month][yyyymmdd]			|
|	|	|									| [GmwPrdd_M<m>_WD<k>]					| [<k>th Workday of <m>th Month][######]			|
|	|	|									| [GmwPrddn_LstWdOfM<m>]				| [20150130]~[20160701] (Last Workdays of months)	|
|	|	|									| [GmwPrdd_LstWdOfM<m>]					| [20118]~[20636] (Last Workdays of months)			|
|	|	|									|_______________________________________|___________________________________________________|
|	|	|									| [GmwPrdkClnDay]						| [550] (# Clndr Days in the period)				|
|	|	|									| [GmwPrddn_AllCD<k>]					| [20150101] ~ [20160703] (All Clndr days)			|
|	|	|									| [GmwPrdd_AllCD<k>]					| [20089] ~ [20638] (All Clndr days)				|
|	|	|									|_______________________________________|___________________________________________________|
|	|	|									| [GmwPrdkWkDay]						| [373] (# Workdays in the period)					|
|	|	|									| [GmwPrddn_AllWD<k>]					| [20150104] ~ [20160701] (All Workdays)			|
|	|	|									| [GmwPrdd_AllWD<k>]					| [20092] ~ [20636] (All Workdays)					|
|	|	|									| [GmwPrddn_FstWD]						| [20150104] (First Workday in the period)			|
|	|	|									| [GmwPrdd_FstWD]						| [20092] (First Workday in the period)				|
|	|	|									| [GmwPrddn_LstWD]						| [20160701] (Last Workday in the period)			|
|	|	|									| [GmwPrdd_LstWD]						| [20636] (Last Workday in the period)				|
|	|	|___________________________________|_______________________________________|___________________________________________________|
|	|	| (New in Ver. 2.00)				| [GmwPrdkTdOfM<m>]						| [20]~[1] (# Trade Days of months)					|
|	|	|									| [GmwPrddn_FstTdOfM<m>]				| [20150105]~[20160701] (First Trade Days of months)|
|	|	|									| [GmwPrdd_FstTdOfM<m>]					| [20093]~[20638] (First Trade Days of months)		|
|	|	|									| [GmwPrddn_M<m>_TD<k>]					| [<k>th Trade Day of <m>th Month][yyyymmdd]		|
|	|	|									| [GmwPrdd_M<m>_TD<k>]					| [<k>th Trade Day of <m>th Month][######]			|
|	|	|									| [GmwPrddn_LstTdOfM<m>]				| [20150130]~[20160701] (Last Trade Days of months)	|
|	|	|									| [GmwPrdd_LstTdOfM<m>]					| [20118]~[20636] (Last Trade Days of months)		|
|	|	|									|_______________________________________|___________________________________________________|
|	|	|									| [GmwPrdkTrDay]						| [365] (# Trade Days in the period)				|
|	|	|									| [GmwPrddn_AllTD<k>]					| [20150105] ~ [20160701] (All Trade Days)			|
|	|	|									| [GmwPrdd_AllTD<k>]					| [20093] ~ [20636] (All Trade Days)				|
|	|	|									| [GmwPrddn_FstTD]						| [20150105] (First Trade Day in the period)		|
|	|	|									| [GmwPrdd_FstTD]						| [20093] (First Trade Day in the period)			|
|	|	|									| [GmwPrddn_LstTD]						| [20160701] (Last Trade Day in the period)			|
|	|	|									| [GmwPrdd_LstTD]						| [20636] (Last Trade Day in the period)			|
|	|	|									|_______________________________________|___________________________________________________|
|	|	|									| [GmwPrdkWorkWeek]						| [77] (# WorkWeeks in the period)					|
|	|	|									| [GmwPrdkWdOfWW<w>]					| [6]~[5] (# Days of WorkWeek<w>)					|
|	|	|									| [GmwPrddn_BgnOfWW<w>]					| [20150104] ~ [20160701] (First Days of WorkWeeks)	|
|	|	|									| [GmwPrdd_BgnOfWW<w>]					| [20092] ~ [20636] (First Days of WorkWeeks)		|
|	|	|									| [GmwPrddn_WW<w>_D<k>]					| [<k>th day of <w>th WorkWeek][yyyymmdd]			|
|	|	|									| [GmwPrdd_WW<w>_D<k>]					| [<k>th day of <w>th WorkWeek][######]				|
|	|	|									| [GmwPrddn_EndOfWW<w>]					| [20150109] ~ [20160701] (Last Days of WorkWeeks)	|
|	|	|									| [GmwPrdd_EndOfWW<w>]					| [20118] ~ [20636] (Last Days of WorkWeeks)		|
|	|	|									|_______________________________________|___________________________________________________|
|	|	|									| [GmwPrdkTradeWeek]					| [77] (# TradeWeeks in the period)					|
|	|	|									| [GmwPrdkTdOfTW<w>]					| [5]~[5] (# Days of TradeWeek<w>)					|
|	|	|									| [GmwPrddn_BgnOfTW<w>]					| [20150105] ~ [20160701] (First Days of TradeWeeks)|
|	|	|									| [GmwPrdd_BgnOfTW<w>]					| [20093] ~ [20636] (First Days of TradeWeeks)		|
|	|	|									| [GmwPrddn_TW<w>_D<k>]					| [<k>th day of <w>th TradeWeek][yyyymmdd]			|
|	|	|									| [GmwPrdd_TW<w>_D<k>]					| [<k>th day of <w>th TradeWeek][######]			|
|	|	|									| [GmwPrddn_EndOfTW<w>]					| [20150109] ~ [20160701] (Last Days of TradeWeeks)	|
|	|	|									| [GmwPrdd_EndOfTW<w>]					| [20118] ~ [20636] (Last Days of TradeWeeks)		|
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
%let	clnLIB	=	%unquote(&clnLIB.);
%let	clnPFX	=	%unquote(&clnPFX.);
%let	procLIB	=	%unquote(&procLIB.);

%if	%length(%qsysfunc(compress(&clnLIB.,%str( ))))	=	0	%then	%let	clnLIB	=	ysrc;
%if	%length(%qsysfunc(compress(&clnPFX.,%str( ))))	=	0	%then	%let	clnPFX	=	calendar;
%if	%length(%qsysfunc(compress(&outPfx.,%str( ))))	=	0	%then	%let	outPfx	=	GmwPrd;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))	=	0	%then	%let	procLIB	=	WORK;

%*013.	Define the local environment.;
%local
	OptNotes	OptSource	OptSource2	OptMLogic	OptSymGen	OptMPrint	OptInOper
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

%*100.	Generate the list of years and months for the given period of time.;
data _NULL_;
	%*100.	Initialization.;
	dBgn	=	input("&DateBgn.",yymmdd10.);
	dEnd	=	input("&DateEnd.",yymmdd10.);
	nYear	=	intck("year",dBgn,dEnd)+1;
	nMonth	=	intck("month",dBgn,dEnd)+1;

	%*200.	Count the numbers.;
	call symputx("LnYear",nYear,"L");
	call symputx("LnMth",nMonth,"L");
	call symputx("&outPfx.kYear",nYear,"G");
	call symputx("&outPfx.kMth",nMonth,"G");

	%*300.	Generate the list of years.;
	do	i=1	to	nYear;
		call symputx(cats("LeYear",i),year(intnx("year",dBgn,i-1,"b")),"L");
	end;

	%*400.	Generate the list of months.;
	do	i=1	to	nMonth;
		call symputx(cats("LeMth",i),month(intnx("month",dBgn,i-1,"b")),"L");
	end;
run;

%*200.	Retrieve the necessary calendar data.;
data &procLIB..__ClnByPeriod__;
	set
		%do Yi=1 %to &LnYear.;
			&clnLIB..&clnPFX.&&LeYear&Yi..(
				where=(
					"&DateBgn."	<=	C_DATE	<=	"&DateEnd."
				)
			)
		%end;
	;
	format
		C_YEAR	$8.
		C_MONTH	$8.
	;
	C_YEAR	=	strip(year(D_DATE));
	C_MONTH	=	put(D_DATE,yymmN6.);
run;

%*300.	Generate the variables in terms of the calendar data of all months as counted above.;
proc sort
	data=&procLIB..__ClnByPeriod__
;
	by
		C_YEAR
		C_MONTH
		C_DATE
	;
run;
data _NULL_;
	set &procLIB..__ClnByPeriod__ end=EOF;
	by
		C_YEAR
		C_MONTH
		C_DATE
	;
	retain
		k_year
		k_month
		k_wkday
		k_trday
		k_cday			%*Calendar day;
		k_allClnDay
		k_allWkDay
		k_allTrDay
		lastWorkDay
		lastTradeDay
		0
	;

	%*100.	All years.;
	if	first.C_YEAR	then do;
		k_year	+	1;
	end;

	%*200.	Begining of months.;
	if	first.C_MONTH	then do;
		%*010.	Initialization.;
		k_month	+	1;
		k_wkday	=	0;
		k_trday	=	0;
		k_cday	=	0;

		%*100.	Months in [yyyymm] format.;
		call symputx(cats("&outPfx.m",k_month),put(D_DATE,yymmN6.),"G");

		%*200.	Beginning dates of months.;
		%* in [yyyymmdd] format.;
		call symputx(cats("&outPfx.dn_BgnOfM",k_month),put(D_DATE,yymmddN8.),"G");

		%* with no format but a date value.;
		call symputx(cats("&outPfx.d_BgnOfM",k_month),D_DATE,"G");
	end;

	%*300.	Dates in each month.;
	%*310.	Count of days.;
	k_wkday		+	F_WORKDAY;
	k_allWkDay	+	F_WORKDAY;
	k_trday		+	F_TradeDay;
	k_allTrDay	+	F_TradeDay;
	k_cday		+	1;
	k_allClnDay	+	1;

	%*320.	Workdays.;
	%*321.	First workday of the month.;
	if	k_wkday	*	F_WORKDAY	=	1	then do;
		%* in [yyyymmdd] format.;
		call symputx(cats("&outPfx.dn_FstWdOfM",k_month),put(D_DATE,yymmddN8.),"G");

		%* with no format but a date value.;
		call symputx(cats("&outPfx.d_FstWdOfM",k_month),D_DATE,"G");
	end;

	%*322.	First workday of the entire period.;
	if	k_allWkDay	*	F_WORKDAY	=	1	then do;
		%* in [yyyymmdd] format.;
		call symputx("&outPfx.dn_FstWD",put(D_DATE,yymmddN8.),"G");

		%* with no format but a date value.;
		call symputx("&outPfx.d_FstWD",D_DATE,"G");
	end;

	%*323.	All workdays.;
	if	F_WORKDAY	=	1	then do;
		%*100.	Workday of current month in [yyyymmdd] format.;
		call symputx(cats("&outPfx.dn_M",k_month,"_WD",k_wkday),put(D_DATE,yymmddN8.),"G");

		%*120.	Workday of current month with no format but a date value.;
		call symputx(cats("&outPfx.d_M",k_month,"_WD",k_wkday),D_DATE,"G");

		%*200.	Workday of the entire period in [yyyymmdd] format.;
		call symputx(cats("&outPfx.dn_AllWD",k_allWkDay),put(D_DATE,yymmddN8.),"G");

		%*220.	Workday of the entire period with no format but a date value.;
		call symputx(cats("&outPfx.d_AllWD",k_allWkDay),D_DATE,"G");

		%*900.	Preparation for the retrieval of the Last Workday.;
		lastWorkDay	=	D_DATE;
	end;

	%*330.	Trade Days.;
	%*331.	First Trade Day of the month.;
	if	k_trday	*	F_TradeDay	=	1	then do;
		%* in [yyyymmdd] format.;
		call symputx(cats("&outPfx.dn_FstTdOfM",k_month),put(D_DATE,yymmddN8.),"G");

		%* with no format but a date value.;
		call symputx(cats("&outPfx.d_FstTdOfM",k_month),D_DATE,"G");
	end;

	%*332.	First Trade Day of the entire period.;
	if	k_allTrDay	*	F_TradeDay	=	1	then do;
		%* in [yyyymmdd] format.;
		call symputx("&outPfx.dn_FstTD",put(D_DATE,yymmddN8.),"G");

		%* with no format but a date value.;
		call symputx("&outPfx.d_FstTD",D_DATE,"G");
	end;

	%*333.	All Trade Days.;
	if	F_TradeDay	=	1	then do;
		%*100.	Trade Day of current month in [yyyymmdd] format.;
		call symputx(cats("&outPfx.dn_M",k_month,"_TD",k_trday),put(D_DATE,yymmddN8.),"G");

		%*120.	Trade Day of current month with no format but a date value.;
		call symputx(cats("&outPfx.d_M",k_month,"_TD",k_trday),D_DATE,"G");

		%*200.	Trade Day of the entire period in [yyyymmdd] format.;
		call symputx(cats("&outPfx.dn_AllTD",k_allTrDay),put(D_DATE,yymmddN8.),"G");

		%*220.	Trade Day of the entire period with no format but a date value.;
		call symputx(cats("&outPfx.d_AllTD",k_allTrDay),D_DATE,"G");

		%*900.	Preparation for the retrieval of the Last Trade Day.;
		lastTradeDay	=	D_DATE;
	end;

	%*380.	Calendar days.;
	%*383.	All calendar days of current month.;
		%* in [yyyymmdd] format.;
		call symputx(cats("&outPfx.dn_M",k_month,"_CD",k_cday),put(D_DATE,yymmddN8.),"G");

		%* with no format but a date value.;
		call symputx(cats("&outPfx.d_M",k_month,"_CD",k_cday),D_DATE,"G");

	%*384.	All calendar days of the entire period.;
		%* in [yyyymmdd] format.;
		call symputx(cats("&outPfx.dn_AllCD",k_allClnDay),put(D_DATE,yymmddN8.),"G");

		%* with no format but a date value.;
		call symputx(cats("&outPfx.d_AllCD",k_allClnDay),D_DATE,"G");

	%*400.	Ending of months.;
	if	last.C_MONTH	then do;
		%*100.	Ending dates of months;
		%* in [yyyymmdd] format.;
		call symputx(cats("&outPfx.dn_EndOfM",k_month),put(D_DATE,yymmddN8.),"G");

		%* with no format but a date value.;
		call symputx(cats("&outPfx.d_EndOfM",k_month),D_DATE,"G");

		%*200.	Last workdays of months.;
		%* in [yyyymmdd] format.;
		call symputx(cats("&outPfx.dn_LstWdOfM",k_month),put(lastWorkDay,yymmddN8.),"G");

		%* with no format but a date value.;
		call symputx(cats("&outPfx.d_LstWdOfM",k_month),lastWorkDay,"G");

		%*300.	Last Trade Days of months.;
		%* in [yyyymmdd] format.;
		call symputx(cats("&outPfx.dn_LstTdOfM",k_month),put(lastTradeDay,yymmddN8.),"G");

		%* with no format but a date value.;
		call symputx(cats("&outPfx.d_LstTdOfM",k_month),lastTradeDay,"G");

		%*600.	Count of all calendar days in current month.;
		call symputx(cats("&outPfx.kCdOfM",k_month),k_cday,"G");

		%*700.	Count of all workdays in current month.;
		call symputx(cats("&outPfx.kWdOfM",k_month),k_wkday,"G");

		%*800.	Count of all Trade Days in current month.;
		call symputx(cats("&outPfx.kTdOfM",k_month),k_trday,"G");
	end;

	%*800.	Overall stats.;
	if	EOF	then do;
		%*100.	Number of all calendar days.;
		call symputx("&outPfx.kClnDay",k_allClnDay,"G");

		%*200.	Number of all workdays.;
		call symputx("&outPfx.kWkDay",k_allWkDay,"G");

		%*300.	Last workdays of the entire period.;
		%* in [yyyymmdd] format.;
		call symputx("&outPfx.dn_LstWD",put(lastWorkDay,yymmddN8.),"G");

		%* with no format but a date value.;
		call symputx("&outPfx.d_LstWD",lastWorkDay,"G");

		%*400.	Number of all Trade Days.;
		call symputx("&outPfx.kTrDay",k_allTrDay,"G");

		%*300.	Last Trade Days of the entire period.;
		%* in [yyyymmdd] format.;
		call symputx("&outPfx.dn_LstTD",put(lastTradeDay,yymmddN8.),"G");

		%* with no format but a date value.;
		call symputx("&outPfx.d_LstTD",lastTradeDay,"G");
	end;
run;

%*400.	Generate the variables in terms of the calendar data for all Work Weeks.;
%*The reason we can use [C_YEAR] to sort the data is that the New Year Day naturally splits the WorkWeeks.;
proc sort
	data=&procLIB..__ClnByPeriod__(
		where=(
			F_WORKDAY	=	1
		)
	)
	out=&procLIB..__ClnByPeriod_WW__
;
	by
		C_YEAR
		N_BLOCK
		D_DATE
	;
run;
data _NULL_;
	set &procLIB..__ClnByPeriod_WW__ end=EOF;
	by
		C_YEAR
		N_BLOCK
		D_DATE
	;
	retain
		k_Week
		k_wkday
		0
	;

	%*100.	Begining of weeks.;
	if	first.N_BLOCK	then do;
		%*010.	Initialization.;
		k_Week	+	1;
		k_wkday	=	0;

		%*200.	Beginning dates of weeks.;
		%*210.	In [yyyymmdd] format.;
		call symputx(cats("&outPfx.dn_BgnOfWW",k_Week),put(D_DATE,yymmddN8.),"G");

		%*220.	With no format but a date value.;
		call symputx(cats("&outPfx.d_BgnOfWW",k_Week),D_DATE,"G");
	end;

	%*300.	Dates in each week.;
	%*310.	Count of days.;
	k_wkday	+	1;

	%*320.	Workdays.;
	%*321.	Day of current week in [yyyymmdd] format.;
	call symputx(cats("&outPfx.dn_WW",k_Week,"_D",k_wkday),put(D_DATE,yymmddN8.),"G");

	%*322.	Day of current week with no format but a date value.;
	call symputx(cats("&outPfx.d_WW",k_Week,"_D",k_wkday),D_DATE,"G");

	%*400.	Ending of weeks.;
	if	last.N_BLOCK	then do;
		%*100.	Ending dates of weeks;
		%*110.	In [yyyymmdd] format.;
		call symputx(cats("&outPfx.dn_EndOfWW",k_Week),put(D_DATE,yymmddN8.),"G");

		%*120.	With no format but a date value.;
		call symputx(cats("&outPfx.d_EndOfWW",k_Week),D_DATE,"G");

		%*700.	Count of all workdays in current week.;
		call symputx(cats("&outPfx.kWdOfWW",k_Week),k_wkday,"G");
	end;

	%*800.	Overall stats.;
	if	EOF	then do;
		%*100.	Number of all weeks.;
		call symputx("&outPfx.kWorkWeek",k_Week,"G");
	end;
run;

%*500.	Generate the variables in terms of the calendar data for all Trade Weeks.;
%*The reason we can use [C_YEAR] to sort the data is that the New Year Day naturally splits the Trade Weeks.;
proc sort
	data=&procLIB..__ClnByPeriod__(
		where=(
			F_TradeDay	=	1
		)
	)
	out=&procLIB..__ClnByPeriod_TW__
;
	by
		C_YEAR
		N_TradeBlock
		D_DATE
	;
run;
data _NULL_;
	set &procLIB..__ClnByPeriod_TW__ end=EOF;
	by
		C_YEAR
		N_TradeBlock
		D_DATE
	;
	retain
		k_Week
		k_wkday
		0
	;

	%*100.	Begining of weeks.;
	if	first.N_TradeBlock	then do;
		%*010.	Initialization.;
		k_Week	+	1;
		k_wkday	=	0;

		%*200.	Beginning dates of weeks.;
		%*210.	In [yyyymmdd] format.;
		call symputx(cats("&outPfx.dn_BgnOfTW",k_Week),put(D_DATE,yymmddN8.),"G");

		%*220.	With no format but a date value.;
		call symputx(cats("&outPfx.d_BgnOfTW",k_Week),D_DATE,"G");
	end;

	%*300.	Dates in each week.;
	%*310.	Count of days.;
	k_wkday	+	1;

	%*320.	Trade Days.;
	%*321.	Day of current week in [yyyymmdd] format.;
	call symputx(cats("&outPfx.dn_TW",k_Week,"_D",k_wkday),put(D_DATE,yymmddN8.),"G");

	%*322.	Day of current week with no format but a date value.;
	call symputx(cats("&outPfx.d_TW",k_Week,"_D",k_wkday),D_DATE,"G");

	%*400.	Ending of weeks.;
	if	last.N_TradeBlock	then do;
		%*100.	Ending dates of weeks;
		%*110.	In [yyyymmdd] format.;
		call symputx(cats("&outPfx.dn_EndOfTW",k_Week),put(D_DATE,yymmddN8.),"G");

		%*120.	With no format but a date value.;
		call symputx(cats("&outPfx.d_EndOfTW",k_Week),D_DATE,"G");

		%*700.	Count of all Trade Days in current week.;
		call symputx(cats("&outPfx.kTdOfTW",k_Week),k_wkday,"G");
	end;

	%*800.	Overall stats.;
	if	EOF	then do;
		%*100.	Number of all weeks.;
		call symputx("&outPfx.kTradeWeek",k_Week,"G");
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
%mend getMthWithinPeriod;

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

%getMthWithinPeriod(
	clnLIB		=	cln
	,clnPFX		=	calendar
	,DateBgn	=	20150101
	,DateEnd	=	20160515
	,outPfx		=	GmwPrd
	,procLIB	=	WORK
)

%macro putVal;
%put	&GmwPrddn_FstWD.;

%do i=1 %to &GmwPrdkMth.;
	%put	&&GmwPrdm&i..;
	%put	&&GmwPrddn_FstWdOfM&i..;
%end;

%do j=1 %to &GmwPrdkCdOfM7.;
	%put	&&GmwPrddn_M7_CD&j..;
%end;

%do k=1 %to &GmwPrdkWdOfM14.;
	%put	&&GmwPrddn_M14_WD&k..;
%end;

%put	[# of Trade Days]=[&GmwPrdkTrDay.];
%put	[# of WorkWeeks]=[&GmwPrdkWorkWeek.];
%put	[# of TradeWeeks]=[&GmwPrdkTradeWeek.];
%put	[# of days of the <1>st WorkWeek]=[&GmwPrdkWdOfWW1.];
%put	[# of days of the <1>st TradeWeek]=[&GmwPrdkTdOfTW1.];
%mend putVal;
%putVal

/*-Notes- -End-*/