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
libname	cln	"D:\SAS\Calendar";
libname	rpt	"D:\R\omniR\SampleKPI\KPI\k ','";
libname	rpt2	"D:\R\omniR\SampleKPI\KPI\K 2";
libname	nfo	"D:\R\omniR\SampleKPI\KPI\K1";

%*050.	Setup a dummy macro [ErrMcr] to prevent the session to be bombed.;
%macro	ErrMcr;	%mend	ErrMcr;

%*100.	Data Preparation.;
%*101.	KPI Configuration Table.;
data nfo.CFG_KPI(compress=yes);
	format
		D_BGN			yymmddD10.
		D_END			yymmddD10.
		C_KPI_ID		$16.
		C_KPI_SHORTNAME	$32.
		C_KPI_BIZNAME	$128.
		C_KPI_DESC		$1024.
		C_PGM_PATH		$512.
		C_PGM_NAME		$128.
		F_KPI_INUSE		8.
		C_KPI_FORMAT	$32.
		C_KPI_DAT_LIB	$512.
		C_KPI_DAT_NAME	$32.
	;
	label
		D_BGN			=	"Begin Date"
		D_END			=	"End Date"
		C_KPI_ID		=	"KPI ID"
		C_KPI_SHORTNAME	=	"KPI Short Name"
		C_KPI_BIZNAME	=	"KPI Business Name"
		C_KPI_DESC		=	"KPI Description"
		C_PGM_PATH		=	"Path of the Program that creates current KPI"
		C_PGM_NAME		=	"Name of the Program that creates current KPI"
		F_KPI_INUSE		=	"Flag of whether current KPI is in use at present"
		C_KPI_FORMAT	=	"The SAS Format of the values of current KPI"
		C_KPI_DAT_LIB	=	"The library name of the Dataset storing current KPI"
		C_KPI_DAT_NAME	=	"The Name of the Dataset storing current KPI"
		
	;

	D_BGN			=	mdy(1,31,2014);
	D_END			=	mdy(12,31,2999);
	C_KPI_ID		=	"130100";
	C_KPI_SHORTNAME	=	"K_COUNTER";
	C_KPI_BIZNAME	=	"Counter of Days";
	C_KPI_DESC		=	strip(C_KPI_BIZNAME);
	C_PGM_PATH		=	"D:\SAS";
	C_PGM_NAME		=	"DBuse_GetTimeSeriesForKpi.sas";
	F_KPI_INUSE		=	1;
	C_KPI_FORMAT	=	"comma32.";
	C_KPI_DAT_LIB	=	"rpt";
	C_KPI_DAT_NAME	=	'kpi&c_date.';
	output;

	C_KPI_ID		=	"140110";
	C_KPI_SHORTNAME	=	"K_DUMMY";
	C_KPI_BIZNAME	=	"Counter of Dummy";
	C_KPI_DESC		=	strip(C_KPI_BIZNAME);
	C_PGM_PATH		=	"D:\SAS";
	C_PGM_NAME		=	"DBuse_GetTimeSeriesForKpi.sas";
	F_KPI_INUSE		=	1;
	C_KPI_FORMAT	=	"comma32.";
	C_KPI_DAT_LIB	=	"rpt2";
	C_KPI_DAT_NAME	=	'kpi2_&c_date.';
	output;
run;

data nfo.CFG_LIB;
	format
		D_BGN			yymmddD10.
		D_END			yymmddD10.
		C_KPI_DAT_LIB	$512.
		N_LIB_PATH_SEQ	8.
		C_LIB_PATH		$512.
	;
	label
		D_BGN			=	"Begin Date"
		D_END			=	"End Date"
		C_KPI_DAT_LIB	=	"The library name of the Dataset storing current KPI"
		N_LIB_PATH_SEQ	=	"The sequence of paths by which to search for KPI datasets in the same library"
		C_LIB_PATH		=	"The absolute of the path to the named library"
		
	;

	D_BGN			=	mdy(1,31,2014);
	D_END			=	mdy(12,31,2999);
	C_KPI_DAT_LIB	=	"rpt";
	%*Quote: [ https://blog.csdn.net/q158805972/article/details/105926950 ];
	%*Set a path with special characters for testing.;
	N_LIB_PATH_SEQ	=	1;
	C_LIB_PATH		=	"D:\R\omniR\SampleKPI\KPI\k ','";
	output;
	N_LIB_PATH_SEQ	=	2;
	C_LIB_PATH		=	"D:\R\omniR\SampleKPI\KPIhist";
	output;

	C_KPI_DAT_LIB	=	"rpt2";
	N_LIB_PATH_SEQ	=	1;
	C_LIB_PATH		=	"D:\R\omniR\SampleKPI\KPI\K 2";
	output;
	N_LIB_PATH_SEQ	=	2;
	C_LIB_PATH		=	"D:\R\omniR\SampleKPI\KPIhist";
	output;
run;

%*105.	Information Tables.;
data nfo.custinfo;
	format
		nc_cifno	$30.
		c_custid	$64.
		c_gender	$1.
		c_rmcode	$4.
	;
	nc_cifno	=	"001";
	c_custid	=	"123456789";
	c_gender	=	"F";
	c_rmcode	=	'1230';
	output;
	nc_cifno	=	"0002";
	c_custid	=	"923456780";
	c_gender	=	"M";
	c_rmcode	=	'1230';
	output;
	nc_cifno	=	"0004";
	c_custid	=	"6784654";
	c_gender	=	"M";
	c_rmcode	=	'1240';
	output;
	nc_cifno	=	"005";
	c_custid	=	"953826268";
	c_gender	=	"F";
	c_rmcode	=	'1240';
	output;
run;
data nfo.acctinfo;
	format
		nc_cifno	$30.
		nc_acct_no	$64.
		d_maturity	yymmddD10.
		c_rmcode	$4.
	;
	nc_cifno	=	"001";
	nc_acct_no	=	"10250";
	d_maturity	=	mdy(4,1,2016);
	c_rmcode	=	'1230';
	output;
	nc_cifno	=	"003";
	nc_acct_no	=	"10370";
	d_maturity	=	mdy(11,22,2017);
	c_rmcode	=	'1240';
	output;
	nc_cifno	=	"0004";
	nc_acct_no	=	"10895";
	d_maturity	=	mdy(12,31,2016);
	c_rmcode	=	'1240';
	output;
	nc_cifno	=	"005";
	nc_acct_no	=	"12644";
	d_maturity	=	mdy(12,31,2015);
	c_rmcode	=	'1240';
	output;
run;

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
%getMthWithinPeriod(
	clnLIB		=	work
	,clnPFX		=	tmpCalendar
	,DateBgn	=	20160229
	,DateEnd	=	20160603
	,outPfx		=	GmwPrd
	,procLIB	=	WORK
)

%*130.	Create the test KPI tables.;
%macro genKpiDat;
%let	Lsplit	=	40;
%do Di=1 %to &Lsplit.;
	data rpt.kpi&&GmwPrddn_AllWD&Di..;
		format
			D_TABLE		yymmddD10.
			nc_cifno	$32.
			nc_acct_no	$64.
			c_rmcode	$4.
			C_KPI_ID	$16.
			A_KPI_VAL	best32.
		;
		D_TABLE		=	&&GmwPrdd_AllWD&Di..;
		nc_cifno	=	"001";
		nc_acct_no	=	"10250";
		c_rmcode	=	'1220';
		C_KPI_ID	=	"130100";
		A_KPI_VAL	=	&Di.;
	run;
	data rpt2.kpi2_&&GmwPrddn_AllWD&Di..;
		format
			D_TABLE		yymmddD10.
			nc_cifno	$32.
			nc_acct_no	$64.
			c_rmcode	$4.
			C_KPI_ID	$16.
			A_KPI_VAL	best32.
		;
		D_TABLE		=	&&GmwPrdd_AllWD&Di..;
		nc_cifno	=	"0004";
		nc_acct_no	=	"10895";
		c_rmcode	=	'1280';
		C_KPI_ID	=	"140110";
		A_KPI_VAL	=	&Di.**2;
	run;
%end;
%do Di=%eval(&Lsplit. + 1) %to &GmwPrdkWkDay.;
	data rpt.kpi&&GmwPrddn_AllWD&Di..;
		format
			D_TABLE		yymmddD10.
			nc_cifno	$32.
			nc_acct_no	$64.
			c_rmcode	$4.
			C_KPI_ID	$16.
			A_KPI_VAL	best32.
		;
		D_TABLE		=	&&GmwPrdd_AllWD&Di..;
		nc_cifno	=	"001";
		nc_acct_no	=	"10250";
		c_rmcode	=	'1220';
		C_KPI_ID	=	"130100";
		A_KPI_VAL	=	&GmwPrdkWkDay. - &Di.;
	run;
	data rpt2.kpi2_&&GmwPrddn_AllWD&Di..;
		format
			D_TABLE		yymmddD10.
			nc_cifno	$32.
			nc_acct_no	$64.
			c_rmcode	$4.
			C_KPI_ID	$16.
			A_KPI_VAL	best32.
		;
		D_TABLE		=	&&GmwPrdd_AllWD&Di..;
		nc_cifno	=	"0004";
		nc_acct_no	=	"10895";
		c_rmcode	=	'1280';
		C_KPI_ID	=	"140110";
		A_KPI_VAL	=	&Di.**2 - &Di.*3;
	run;
%end;
%mend genKpiDat;
%genKpiDat

%*150.	Retrieve all date information for the period of 20160901 to 20161201.;
%getMthWithinPeriod(
	clnLIB		=	work
	,clnPFX		=	tmpCalendar
	,DateBgn	=	20160901
	,DateEnd	=	20161201
	,outPfx		=	GCln
	,procLIB	=	WORK
)

%*170.	Create the test KPI tables.;
%macro genClnDat;
%let	Lsplit	=	45;
%do Di=1 %to &Lsplit.;
	data rpt.kpi&&GClndn_AllCD&Di..;
		format
			D_TABLE		yymmddD10.
			nc_cifno	$32.
			nc_acct_no	$64.
			c_rmcode	$4.
			C_KPI_ID	$16.
			A_KPI_VAL	best32.
		;
		D_TABLE		=	&&GClnd_AllCD&Di..;
		nc_cifno	=	"001";
		nc_acct_no	=	"10250";
		c_rmcode	=	'1270';
		C_KPI_ID	=	"130100";
		A_KPI_VAL	=	&Di.;
	run;
%end;
%do Di=%eval(&Lsplit. + 1) %to &GClnkClnDay.;
	data rpt.kpi&&GClndn_AllCD&Di..;
		format
			D_TABLE		yymmddD10.
			nc_cifno	$32.
			nc_acct_no	$64.
			c_rmcode	$4.
			C_KPI_ID	$16.
			A_KPI_VAL	best32.
		;
		D_TABLE		=	&&GClnd_AllCD&Di..;
		nc_cifno	=	"001";
		nc_acct_no	=	"10250";
		c_rmcode	=	'1270';
		C_KPI_ID	=	"130100";
		A_KPI_VAL	=	&GClnkClnDay. - &Di.;
	run;
%end;
%mend genClnDat;
%genClnDat
