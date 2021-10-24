%macro genVarByDate(
	clnDSN		=	m_smesrc
	,clnPFX		=	calendar
	,inDATE		=	&G_cur_year.&G_cur_mth.&G_cur_day.
	,procLIB	=	WORK
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to generate a series of global macro variables in terms of the provided Calendar dataset.					|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|clnDSN		:	The library name that stores the Calendar data																		|
|	|clnPFX		:	The prefix of the name of the Calendar dataset (except the [yyyy] part in the name).								|
|	|inDATE		:	The date to be treated as the benchmark in the format of [yyyymmdd].												|
|	|procLIB	:	The working library.																								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20150617		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |First finalized version.																									|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20160804		| Version |	1.11		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |(1) Create the macro variable [L_d_PrevLastWorkDay].																		|
|	|      |(2) Create the macro variables [L_d_PrevWorkDay] and [L_dn_PrevWorkDay] (Previous Work Date against current one).			|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20160914		| Version |	1.12		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |(1) Fix the bug that the macro variable [L_d_PrevLastWorkDay] has missing value.											|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|800.	Sample Results.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Given [inDATE] is provided as [20160703], below global macro variables are generated.												|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|				Period				|		Name of Macro Variables			|			Value of Macro Variables				|
|	|	|___________________________________|_______________________________________|___________________________________________________|
|	|	| Standalone Dates					| [L_d_PrevWorkDay]						| [20636]											|
|	|	| (Against 20160703)				| [L_dn_PrevWorkDay]					| [20160701]										|
|	|	|___________________________________|_______________________________________|___________________________________________________|
|	|	| Current Month						| [L_d_BgnOfMth]						| [20636]											|
|	|	| (201607)							| [L_d_EndOfMth]						| [20666]											|
|	|	|									| [L_ELcurClnDAY<k>]					| [20160701] ~ [20160731]							|
|	|	|									| [L_curClnDays]						| [31]												|
|	|	|									| [L_dn_LastClnDayOfMth]				| [20160731]										|
|	|	|									| [L_ELcurWORKDAY<k>]					| [20160701] ~ [20160729] (Workdays)				|
|	|	|									| [L_curWorkDays]						| [21]												|
|	|	|									| [L_d_LastWorkDayOfMth]				| [20664]											|
|	|	|									| [L_dn_LastWorkDayOfMth]				| [20160729]										|
|	|	|									| [L_nPastClnDayOfMth]					| [3]	(Calandar days passed)						|
|	|	|									| [L_dn_PastClnDayOfMth_D<k>]			| [20160701] ~ [20160703] (Clndr days)				|
|	|	|									| [L_d_PastClnDayOfMth_D<k>]			| [20636] ~ [20638] (Clndr days)					|
|	|	|									| [L_nPastWorkDayOfMth]					| [1]	(Workdays passed)							|
|	|	|									| [L_dn_PastWorkDayOfMth_D<k>]			| [20160701] ~ [20160701] (Workdays)				|
|	|	|									| [L_d_PastWorkDayOfMth_D<k>]			| [20636] ~ [20636] (Workdays)						|
|	|	|									| [L_f_firstMthOfYear]					| [0]												|
|	|	|									| [L_d_currMthEnd]						| [20666]											|
|	|	|									| [L_f_LastMthOfCurrYr]					| [0]												|
|	|	|___________________________________|_______________________________________|___________________________________________________|
|	|	| Previous Month					| [L_d_BgnOfPrevMth]					| [20606]											|
|	|	| (201606)							| [L_d_EndOfPrevMth]					| [20635]											|
|	|	|									| [L_m_PrevMth]							| [201606]											|
|	|	|									| [L_ELprevClnDAY<k>]					| [20160601] ~ [20160630]							|
|	|	|									| [L_prevClnDays]						| [30]												|
|	|	|									| [L_dn_LastClnDayOfPrevMth]			| [20160630]										|
|	|	|									| [L_ELprevWORKDAY<k>]					| [20160601] ~ [20160630] (Workdays)				|
|	|	|									| [L_prevWorkDays]						| [21]												|
|	|	|									| [L_prevLastWorkDay]					| [20160630]										|
|	|	|									| [L_d_PrevLastWorkDay]					| [20635]											|
|	|	|___________________________________|_______________________________________|___________________________________________________|
|	|	| Next Month						| [L_d_BgnOfNextMth]					| [20667]											|
|	|	| (201608)							| [L_d_EndOfNextMth]					| [20727]											|
|	|	|									| [L_m_NextMth]							| [201608]											|
|	|	|									| [L_ELnextClnDAY<k>]					| [20160801] ~ [20160831]							|
|	|	|									| [L_nextClnDays]						| [31]												|
|	|	|									| [L_ELnextWORKDAY<k>]					| [20160801] ~ [20160831] (Workdays)				|
|	|	|									| [L_nextWORKDays]						| [23]												|
|	|	|___________________________________|_______________________________________|___________________________________________________|
|	|	| Current Quarter					| [L_f_firstQtrOfYear]					| [0]												|
|	|	| (201607 ~ 201609)					| [L_f_lastQtrOfYear]					| [0]												|
|	|	|									| [L_d_BeginOfQtr]						| [20636]											|
|	|	|									| [L_d_EndOfQtr]						| [20727]											|
|	|	|									| [L_m_lastMthOfQtr]					| [201609]											|
|	|	|									| [L_f_lastMthOfQtr]					| [0]												|
|	|	|									| [L_nMthOfQtr]							| [1]	(Number of months passed)					|
|	|	|									| [L_m_M<k>]							| [201607] ~ [201607] (months passed)				|
|	|	|									| [L_dayOfM<k>]							| [31] ~ [31] (Clndr days of months passed)			|
|	|	|___________________________________|_______________________________________|___________________________________________________|
|	|	| Previous Quarter					| [L_m_lastMthOfPrevQtr]				| [201606]											|
|	|	| (201604 ~ 201606)					| [L_nMthOfPrevQtr]						| [3]												|
|	|	|									| [L_d_EndOfPrevQtr]					| [20635]											|
|	|	|									| [L_d_BeginOfPrevQtr]					| [20545]											|
|	|	|									| [L_m_PrevQtrM<k>]						| [201604] ~ [201606] (months)						|
|	|	|									| [L_dayOfPrevQtrM<k>]					| [30][31][30] (Clndr days of months)				|
|	|	|									| [L_m_EndMthOfPrevQtr]					| [201606]											|
|	|	|___________________________________|_______________________________________|___________________________________________________|
|	|	| Previous Year						| [L_nMthOfPrevYr]						| [12]												|
|	|	| (201501 ~ 201512)					| [L_nMthOfPrevYrH2]					| [6]												|
|	|	|									| [L_nMthOfPrevYrQ3]					| [3]												|
|	|	|									| [L_nMthOfPrevYrQ4]					| [3]												|
|	|	|									| [L_nQtrOfPrevYr]						| [4]												|
|	|	|									| [L_d_BeginOfPrevYrQ4]					| [20362]											|
|	|	|									| [L_d_BeginOfPrevYrH2]					| [20270]											|
|	|	|									| [L_d_EndOfPrevYrQ3]					| [20361]											|
|	|	|									| [L_d_EndOfPrevYr]						| [20453]											|
|	|	|									| [L_m_PrevYrSameMth]					| [201507]											|
|	|	|									| [L_m_PrevYrQ3M<k>]					| [201507] ~ [201509] (months)						|
|	|	|									| [L_dayOfPrevYrQ3M<k>]					| [31][31][30] (Clndr days of months)				|
|	|	|									| [L_m_PrevYrQ4M<k>]					| [201510] ~ [201512] (months)						|
|	|	|									| [L_dayOfPrevYrQ4M<k>]					| [31][30][31] (Clndr days of months)				|
|	|	|									| [L_m_prevYr_EndMthOfQ<k>]				| [201503][201506][201509][201512]					|
|	|	|									| [L_m_PrevYrM<k>]						| [201501] ~ [201512] (months)						|
|	|	|									| [L_dayOfPrevYrM<k>]					| [31] ~ [31] (Clndr days of months)				|
|	|	|									| [L_m_PrevYrH2M<k>]					| [201507] ~ [201512] (months)						|
|	|	|									| [L_dayOfPrevYrH2M<k>]					| [31] ~ [31] (Clndr days of months)				|
|	|	|___________________________________|_______________________________________|___________________________________________________|
|	|	| Current Year						| [L_nMthOfCurrYr]						| [7]												|
|	|	| (201601 ~ 201612)					| [L_nQtrOfCurrYr]						| [3]												|
|	|	|									| [L_d_BeginOfCurrYr]					| [20454]											|
|	|	|									| [L_nDayOfCurrYr]						| [185]												|
|	|	|									| [L_m_currYrM<k>]						| [201601] ~ [201607] (months passed)				|
|	|	|									| [L_dayOfcurrYrM<k>]					| [31] ~ [31] (Clndr days of months passed)			|
|	|	|									| [L_m_currYr_EndMthOfQ<k>]				| [201603][201606][201609]							|
|	|	|___________________________________|_______________________________________|___________________________________________________|
|	|	| Rolling <m> Months				| [L_m_R3Mth_M<k>]						| [201605] ~ [201607]								|
|	|	| (m = 3, 6, 12, 13)				| [L_m_R6Mth_M<k>]						| [201602] ~ [201607]								|
|	|	|									| [L_m_R12Mth_M<k>]						| [201508] ~ [201607]								|
|	|	|									| [L_m_R13Mth_M<k>]						| [201507] ~ [201607]								|
|	|	|___________________________________|_______________________________________|___________________________________________________|
|	|	| Rolling <q> Quarters				| [L_m_R4Qtr_EndM<k>]					| [201512] ~ [201609] (Quarter Ends)				|
|	|	| (q = 4, 5)						| [LnMthInR4Qtr]						| [10] (Counting from 201510 to 201607)				|
|	|	|									| [L_m_AllMthInR4Qtr_M<k>]				| [201510] ~ [201607]								|
|	|	|									| [L_m_R5Qtr_EndM<k>]					| [201509] ~ [201609] (Quarter Ends)				|
|	|	|									| [LnMthInR5Qtr]						| [13] (Counting from 201507 to 201607)				|
|	|	|									| [L_m_AllMthInR5Qtr_M<k>]				| [201507] ~ [201607]								|
|	|	|___________________________________|_______________________________________|___________________________________________________|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*001.	Generate date indicators.;
%let	clnDSN	=	%unquote(&clnDSN.);
%let	clnPFX	=	%unquote(&clnPFX.);
%let	procLIB	=	%unquote(&procLIB.);

%local
	L_y_curMth
	L_m_curMth
	L_y_pMth
	L_m_pMth
	L_y_nxtMth
	L_m_nxtMth
	L_y_pYr
;
data _NULL_;
	curDate		=	input("&inDATE.",anydtdte10.);
	currMthBgn	=	intnx("month",curDate,0,"b");
	prevMthBgn	=	intnx("month",curDate,-1,"b");
	nextMthBgn	=	intnx("month",curDate,1,"b");
	nextMthEnd	=	intnx("month",curDate,2,"e");
	call symputx("L_currdate",put(curDate,yymmN6.),"L");		%*<yyyymm>;
	call symputx("L_prevdate",put(prevMthBgn,yymmN6.),"L");		%*<yyyymm>;
	call symputx("L_nextdate",put(nextMthBgn,yymmN6.),"L");		%*<yyyymm>;
	call symputx("L_d_BgnOfMth",currMthBgn,"G");
	call symputx("L_d_EndOfMth",(nextMthBgn-1),"G");
	call symputx("L_d_BgnOfPrevMth",prevMthBgn,"G");
	call symputx("L_d_EndOfPrevMth",(currMthBgn-1),"G");
	call symputx("L_d_BgnOfNextMth",nextMthBgn,"G");
	call symputx("L_d_EndOfNextMth",nextMthEnd,"G");
	call symputx("L_m_PrevMth",put(prevMthBgn,yymmN6.),"G");	%*<yyyymm>;
	call symputx("L_m_NextMth",put(nextMthBgn,yymmN6.),"G");	%*<yyyymm>;
run;
%let	L_y_curMth	=	%substr(&L_currdate.,1,4);
%let	L_m_curMth	=	%substr(&L_currdate.,5);
%let	L_y_pMth	=	%substr(&L_prevdate.,1,4);
%let	L_m_pMth	=	%substr(&L_prevdate.,5);
%let	L_y_nxtMth	=	%substr(&L_nextdate.,1,4);
%let	L_m_nxtMth	=	%substr(&L_nextdate.,5);
%let	L_y_pYr		=	%eval(&L_y_curMth.-1);

%*010.	Below is for the retrieval of the useful dates of current month.;
%*011.	Below is for the retrieval of all calendar days within current month.;
proc sort
	data=&clnDSN..&clnPFX.&L_y_curMth.(
		keep=
			D_DATE
			C_DATE
		where=(
			substr(C_DATE,1,6)	=	"&L_currdate."
		)
	)
	out=&procLIB..curClnDay
;
	by C_DATE;
run;

data _NULL_;
	set &procLIB..curClnDay end=EOF;
	by C_DATE;
	call symputx(cats("L_ELcurClnDAY",_N_),C_DATE,"G");
	if	EOF	then do;
		call symputx("L_curClnDays",_N_,"G");
	end;
run;
%global	L_dn_LastClnDayOfMth;
%let	L_dn_LastClnDayOfMth	=	&&L_ELcurClnDAY&L_curClnDays..;

%*012.	Below is for the retrieval of all working days within current month.;
proc sort
	data=&clnDSN..&clnPFX.&L_y_curMth.(
		keep=
			D_DATE
			C_DATE
			F_WORKDAY
		where=(
				F_WORKDAY
			and	substr(C_DATE,1,6)	=	"&L_currdate."
		)
	)
	out=&procLIB..curClndr
;
	by C_DATE;
run;

data _NULL_;
	set &procLIB..curClndr end=EOF;
	by C_DATE;
	call symputx(cats("L_ELcurWORKDAY",_N_),C_DATE,"G");
	if	EOF	then do;
		call symputx("L_curWorkDays",_N_,"G");
		call symputx("L_d_LastWorkDayOfMth",input(C_DATE,yymmdd10.),"G");
	end;
run;
%global	L_dn_LastWorkDayOfMth;
%let	L_dn_LastWorkDayOfMth	=	&&L_ELcurWORKDAY&L_curWorkDays..;

%*013.	Below is for the retrieval of the past calendar dates of current month.;
data _NULL_;
	curDate		=	input("&inDATE.",anydtdte10.);
	prevMthEnd	=	intnx("month",curDate,0) - 1;
	call symputx("L_nPastClnDayOfMth",curDate - prevMthEnd,"G");
run;
data _NULL_;
	curDate		=	input("&inDATE.",anydtdte10.);
	prevMthEnd	=	intnx("month",curDate,0) - 1;
	%do Di=1 %to &L_nPastClnDayOfMth.;
		call symputx("L_dn_PastClnDayOfMth_D&Di.",put(prevMthEnd + &Di.,yymmddN8.),"G");
		call symputx("L_d_PastClnDayOfMth_D&Di.",prevMthEnd + &Di.,"G");
	%end;
run;

%*014.	Below is for the retrieval of the past work dates of current month.;
data _NULL_;
	set &procLIB..curClndr end=EOF;
	by C_DATE;
	retain tmpd;
	if	_N_	=	1	then do;
		tmpd	=	0;
	end;
	if	input(C_DATE,yymmdd10.)	<=	input("&inDATE.",anydtdte10.)	then do;
		tmpd	+	1;
		call symputx(cats("L_dn_PastWorkDayOfMth_D",tmpd),C_DATE,"G");
		call symputx(cats("L_d_PastWorkDayOfMth_D",tmpd),input(C_DATE,yymmdd10.),"G");
		call symputx("L_nPastWorkDayOfMth",tmpd,"G");
	end;
	else do;
		stop;
	end;
run;

%*020.	Below is for the retrieval of the useful dates of the previous month.;
%*021.	Below is for the retrieval of all calendar days within the previous month.;
proc sort
	data=&clnDSN..&clnPFX.&L_y_pMth.(
		keep=
			D_DATE
			C_DATE
		where=(
			substr(C_DATE,1,6)	=	"&L_prevdate."
		)
	)
	out=&procLIB..prevClnDay
;
	by C_DATE;
run;

data _NULL_;
	set &procLIB..prevClnDay end=EOF;
	by C_DATE;
	call symputx(cats("L_ELprevClnDAY",_N_),C_DATE,"G");
	if	EOF	then do;
		call symputx("L_prevClnDays",_N_,"G");
	end;
run;
%global	L_dn_LastClnDayOfPrevMth;
%let	L_dn_LastClnDayOfPrevMth	=	&&L_ELprevClnDAY&L_prevClnDays..;

%*022.	Below is for the retrieval of all working days of the previous month.;
proc sort
	data=&clnDSN..&clnPFX.&L_y_pMth.(
		keep=
			D_DATE
			C_DATE
			F_WORKDAY
		where=(
				F_WORKDAY
			and	substr(C_DATE,1,6)	=	"&L_prevdate."
		)
	)
	out=&procLIB..prevClndr
;
	by C_DATE;
run;

data _NULL_;
	set &procLIB..prevClndr end=EOF;
	by C_DATE;
	call symputx(cats("L_ELprevWORKDAY",_N_),C_DATE,"G");
	if	EOF	then do;
		call symputx("L_prevWorkDays",_N_,"G");
		call symputx("L_prevLastWorkDay",C_DATE,"G");
		call symputx("L_d_PrevLastWorkDay",D_DATE,"G");
	end;
run;

%*050.	Below is for the retrieval of all useful days within the next month.;
%if	%sysfunc(exist(&clnDSN..&clnPFX.&L_y_nxtMth.))	%then %do;
	proc sort
		data=&clnDSN..&clnPFX.&L_y_nxtMth.(
			keep=
				D_DATE
				C_DATE
				F_WORKDAY
			where=(
				substr(C_DATE,1,6)	=	"&L_nextdate."
			)
		)
		out=&procLIB..nextClnDay
	;
		by C_DATE;
	run;

	data _NULL_;
		set &procLIB..nextClnDay end=EOF;
		by C_DATE;
		retain tmp_N 0;
		call symputx(cats("L_ELnextClnDAY",_N_),C_DATE,"G");
		if	F_WORKDAY	then do;
			tmp_N	+	1;
			call symputx(cats("L_ELnextWORKDAY",tmp_N),C_DATE,"G");
		end;
		if	EOF	then do;
			call symputx("L_nextClnDays",_N_,"G");
			call symputx("L_nextWORKDays",tmp_N,"G");
		end;
	run;
	%global
		L_dn_LastClnDayOfNextMth
		L_dn_LastWorkDayOfNextMth
	;
	%let	L_dn_LastClnDayOfNextMth	=	&&L_ELnextClnDAY&L_nextClnDays..;
	%let	L_dn_LastWorkDayOfNextMth	=	&&L_ELnextWORKDAY&L_nextWORKDays..;
%end;

%*100.	Below is for the retrieval of the useful dates of current quarter.;
data _NULL_;
	curDate		=	input("&inDATE.",anydtdte10.);
	curYrBgn	=	intnx("year",curDate,0,"b");
	curMthBgn	=	intnx("month",curDate,0,"b");
	curMthEnd	=	intnx("month",curMthBgn,0,"e");
	curQtrBgn	=	intnx("qtr",curMthBgn,0,"b");
	nextQtrBgn	=	intnx("qtr",curMthBgn,1,"b");
	nextYrBgn	=	intnx("year",curDate,1,"b");
	%*Below for when the current quarter is the first quarter of current year.;
	call symputx("L_f_firstQtrOfYear",(intck("QTR",curYrBgn,curDate)=0),"G");
	%*Below for when the current quarter is the last quarter of current year.;
	call symputx("L_f_lastQtrOfYear",(intck("QTR",curDate,nextYrBgn)=1),"G");

	%*Below for when the current month is the first month of current year.;
	call symputx("L_f_firstMthOfYear",(intck("month",curYrBgn,curDate)=0),"G");

	call symputx("L_d_BeginOfQtr",curQtrBgn,"G");
	call symputx("L_d_EndOfQtr",(nextQtrBgn-1),"G");
	call symputx("L_d_currMthEnd",curMthEnd,"G");
	call symputx("L_m_lastMthOfPrevQtr",put(curQtrBgn-1,yymmN6.),"G");				%*<yyyymm>;
	%*Below for when the current month is the last month of current quarter.;
	call symputx("L_m_lastMthOfQtr",put(nextQtrBgn-1,yymmN6.),"G");					%*<yyyymm>;
	call symputx("L_f_lastMthOfQtr",(intck("month",curDate,nextQtrBgn)=1),"G");

	call symputx("L_nMthOfQtr",(intck("MONTH",curQtrBgn,curDate)+1),"G");
run;
data _NULL_;
	curDate		=	input("&inDATE.",anydtdte10.);
	curQtrBgn	=	intnx("qtr",curDate,0,"b");
	%do Mi=1 %to &L_nMthOfQtr.;
		curMthBgn	=	intnx("month",curQtrBgn,&Mi.-1,"b");
		nextMthBgn	=	intnx("month",curMthBgn,1,"b");
		call symputx("L_m_M&Mi.",put(curMthBgn,yymmN6.),"G");
		call symputx("L_dayOfM&Mi.",(nextMthBgn-curMthBgn),"G");
	%end;
run;

%*200.	Below is for the retrieval of the useful dates of the previous quarter.;
data _NULL_;
	curDate		=	input("&inDATE.",anydtdte10.);
	currQtrBgn	=	intnx("qtr",curDate,0,"b");
	prevQtrBgn	=	intnx("qtr",curDate,-1,"b");
	call symputx("L_nMthOfPrevQtr",intck("MONTH",prevQtrBgn,currQtrBgn),"G");
run;
data _NULL_;
	prevQtrEnd	=	&L_d_BeginOfQtr.-1;
	prevQtrBgn	=	intnx("qtr",prevQtrEnd,0,"b");

	call symputx("L_d_EndOfPrevQtr",prevQtrEnd,"G");
	call symputx("L_d_BeginOfPrevQtr",prevQtrBgn,"G");
	%do Mi=1 %to &L_nMthOfPrevQtr.;
		curMthBgn	=	intnx("month",prevQtrBgn,&Mi.-1,"b");
		nextMthBgn	=	intnx("month",curMthBgn,1,"b");
		call symputx("L_m_PrevQtrM&Mi.",put(curMthBgn,yymmN6.),"G");
		call symputx("L_dayOfPrevQtrM&Mi.",(nextMthBgn-curMthBgn),"G");
	%end;
run;
%global	L_m_EndMthOfPrevQtr;
%let	L_m_EndMthOfPrevQtr	=	&&L_m_PrevQtrM&L_nMthOfPrevQtr..;

%*300.	Below is for the retrieval of the useful dates of the previous year.;
data _NULL_;
	curDate		=	input("&inDATE.",anydtdte10.);
	currYrBgn	=	intnx("year",curDate,0,"b");
	prevYrBgn	=	intnx("year",curDate,-1,"b");
	prevYrH2Bgn	=	intnx("semiyear",prevYrBgn,1,"b");
	prevYrQ4Bgn	=	intnx("qtr",prevYrH2Bgn,1,"b");
	call symputx("L_nMthOfPrevYr",intck("MONTH",prevYrBgn,currYrBgn),"G");
	call symputx("L_nMthOfPrevYrH2",intck("MONTH",prevYrH2Bgn,currYrBgn),"G");
	call symputx("L_nMthOfPrevYrQ3",intck("MONTH",prevYrH2Bgn,prevYrQ4Bgn),"G");
	call symputx("L_nMthOfPrevYrQ4",intck("MONTH",prevYrQ4Bgn,currYrBgn),"G");
	call symputx("L_nQtrOfPrevYr",intck("QTR",prevYrBgn,currYrBgn),"G");
run;
data _NULL_;
	curDate		=	input("&inDATE.",anydtdte10.);
	thisYrBgn	=	intnx("year",curDate,0,"b");
	prevYrBgn	=	intnx("year",curDate,-1,"b");
	prevYrEnd	=	thisYrBgn	-	1;
	prevYrH2Bgn	=	intnx("semiyear",prevYrEnd,0,"b");
	prevYrQ4Bgn	=	intnx("qtr",prevYrEnd,0,"b");
	pYrSameMEnd	=	intnx("month",curDate,-12,"e");

	call symputx("L_d_BeginOfPrevYrQ4",prevYrQ4Bgn,"G");
	call symputx("L_d_BeginOfPrevYrH2",prevYrH2Bgn,"G");
	call symputx("L_d_EndOfPrevYrQ3",(prevYrQ4Bgn-1),"G");
	call symputx("L_d_EndOfPrevYr",prevYrEnd,"G");
	call symputx("L_m_PrevYrSameMth",put(pYrSameMend,yymmN6.),"G");
	%do Mi=1 %to &L_nMthOfPrevYrQ3.;
		curMthBgn	=	intnx("month",prevYrH2Bgn,&Mi.-1,"b");
		nextMthBgn	=	intnx("month",curMthBgn,1,"b");
		call symputx("L_m_PrevYrQ3M&Mi.",put(curMthBgn,yymmN6.),"G");
		call symputx("L_dayOfPrevYrQ3M&Mi.",(nextMthBgn-curMthBgn),"G");
	%end;
	%do Mi=1 %to &L_nMthOfPrevYrQ4.;
		curMthBgn	=	intnx("month",prevYrQ4Bgn,&Mi.-1,"b");
		nextMthBgn	=	intnx("month",curMthBgn,1,"b");
		call symputx("L_m_PrevYrQ4M&Mi.",put(curMthBgn,yymmN6.),"G");
		call symputx("L_dayOfPrevYrQ4M&Mi.",(nextMthBgn-curMthBgn),"G");
	%end;
	%do Qi=1 %to &L_nQtrOfPrevYr.;
		prevQtrEnd	=	intnx("qtr",prevYrBgn,&Qi.,"b")-1;
		call symputx("L_m_prevYr_EndMthOfQ&Qi.",put(prevQtrEnd,yymmN6.),"G");
	%end;
run;
data _NULL_;
	curDate		=	input("&L_y_pYr.0101",anydtdte10.);
	curYrBgn	=	intnx("year",curDate,0,"b");
	%do Mi=1 %to &L_nMthOfPrevYr.;
		curMthBgn	=	intnx("month",curYrBgn,&Mi.-1,"b");
		nextMthBgn	=	intnx("month",curMthBgn,1,"b");
		call symputx("L_m_PrevYrM&Mi.",put(curMthBgn,yymmN6.),"G");
		call symputx("L_dayOfPrevYrM&Mi.",(nextMthBgn-curMthBgn),"G");
	%end;
run;
data _NULL_;
	curDate		=	&L_d_BeginOfPrevYrH2.;
	%do Mi=1 %to &L_nMthOfPrevYrH2.;
		curMthBgn	=	intnx("month",curDate,&Mi.-1,"b");
		nextMthBgn	=	intnx("month",curMthBgn,1,"b");
		call symputx("L_m_PrevYrH2M&Mi.",put(curMthBgn,yymmN6.),"G");
		call symputx("L_dayOfPrevYrH2M&Mi.",(nextMthBgn-curMthBgn),"G");
	%end;
run;

%*400.	Below is for the retrieval of the useful dates of the current year.;
data _NULL_;
	curDate		=	input("&inDATE.",anydtdte10.);
	nexYrBgn	=	intnx("year",curDate,1,"b");

	call symputx("L_f_LastMthOfCurrYr",(intck("month",curDate,nexYrBgn)=1),"G");
	call symputx("L_nMthOfCurrYr",intck("MONTH",&L_d_EndOfPrevYr.,curDate),"G");
	call symputx("L_nQtrOfCurrYr",intck("QTR",&L_d_EndOfPrevYr.,curDate),"G");
run;
data _NULL_;
	curDate		=	input("&inDATE.",anydtdte10.);
	curYrBgn	=	intnx("year",curDate,0,"b");

%* NCui added on Jul. 3, 2013;
	call symputx("L_d_BeginOfCurrYr",curYrBgn,"G");
%* End - NCui added on Jul. 3, 2013;

	call symputx("L_nDayOfCurrYr",curDate - curYrBgn + 1,"G");

	%do Mi=1 %to &L_nMthOfCurrYr.;
		curMthBgn	=	intnx("month",curYrBgn,&Mi.-1,"b");
		nextMthBgn	=	intnx("month",curMthBgn,1,"b");
		call symputx("L_m_currYrM&Mi.",put(curMthBgn,yymmN6.),"G");
		call symputx("L_dayOfcurrYrM&Mi.",(nextMthBgn-curMthBgn),"G");
	%end;
run;
data _NULL_;
	curDate		=	input("&inDATE.",anydtdte10.);
	curYrBgn	=	intnx("year",curDate,0,"b");
	%do Qi=1 %to &L_nQtrOfCurrYr.;
		curQtrEnd	=	intnx("qtr",curYrBgn,&Qi.,"b")-1;
		call symputx("L_m_currYr_EndMthOfQ&Qi.",put(curQtrEnd,yymmN6.),"G");
	%end;
run;

%*600.	Below is for the retrieval of the useful dates of rolling N months including current month.;
%macro getMForRollMth(nRoll=);
data _NULL_;
	curDate	=	input("&inDATE.",anydtdte10.);
	%do Mi=1 %to &nRoll.;
		DestMth	=	intnx("month",curDate,&Mi.-&nRoll.,"end");
		call symputx("L_m_R&nRoll.Mth_M&Mi.",put(DestMth,yymmN6.),"G");
	%end;
run;
%mend getMForRollMth;

%*610.	Rolling 3 months.;
%getMForRollMth(nRoll=3)

%*620.	Rolling 6 months.;
%getMForRollMth(nRoll=6)

%*630.	Rolling 12 months.;
%getMForRollMth(nRoll=12)

%*631.	Rolling 13 months.;
%getMForRollMth(nRoll=13)

%*700.	Below is for the retrieval of the useful dates of rolling N quarters including current quarter.;
%macro getEndMForRollQtr(nRoll=);
data _NULL_;
	curDate	=	input("&inDATE.",anydtdte10.);
	%do Qi=1 %to &nRoll.;
		DestMth	=	intnx("qtr",curDate,&Qi.-&nRoll.,"end");
		call symputx("L_m_R&nRoll.Qtr_EndM&Qi.",put(DestMth,yymmN6.),"G");
	%end;
	prevQtrEnd	=	intnx("qtr",curDate,1 - &nRoll.,"b") - 1;
	call symputx("LnMthInR&nRoll.Qtr",intck("month",prevQtrEnd,curDate),"G");
	RollMth	=	intck("month",prevQtrEnd,curDate);
	do Mi=1 to RollMth;
		call symputx(cats("L_m_AllMthInR&nRoll.Qtr_M",Mi),put(intnx("month",prevQtrEnd,Mi),yymmN6.),"G");
	end;
run;
%mend getEndMForRollQtr;

%*710.	Rolling 5 quarters.;
%*This enables the Quarter-on-Same-Quarter-in-Previous-Year analysis.;
%getEndMForRollQtr(nRoll=5)

%*720.	Rolling 4 quarters.;
%getEndMForRollQtr(nRoll=4)

%*800.	Below is for the retrieval of the useful standalone dates.;
%*810.	Useful workdays.;
data &procLIB..getWorkDays;
	set
	%if	&L_f_firstMthOfYear.	=	1	%then %do;
		&clnDSN..&clnPFX.&L_y_pYr.
	%end;
		&clnDSN..&clnPFX.&L_y_curMth.
	;
	where
			F_WORKDAY	=	1
		and	D_DATE	<	input("&inDATE.",anydtdte10.)
	;
run;

proc sort
	data=&procLIB..getWorkDays
;
	by C_DATE;
run;

data _NULL_;
	set &procLIB..getWorkDays end=EOF;
	by C_DATE;
	if	EOF	then do;
		call symputx("L_d_PrevWorkDay",D_DATE,"G");
		call symputx("L_dn_PrevWorkDay",C_DATE,"G");
	end;
run;

%mend genVarByDate;