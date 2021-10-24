%macro DBcore_LoadDatInfFrKpiCfg(
	inKPICfg		=	src.CFG_KPI
	,nKpiID			=	LnKpi
	,pfxKpiID		=	LeKpiID
	,pfxKpiName		=	LeKpiNM
	,pfxKpiLbl		=	LeKpiLBL
	,pfxKpiFmt		=	LeKpiFMT
	,nKpiDat		=	LnKpiDat
	,pfxKpiDatPath	=	LeKpiDatPath
	,pfxKpiDatName	=	LeKpiDatName
	,procLIB		=	WORK
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is the core function that many of the data processes will call during the DB usage.										|
|	| It is intended to load the basic information for all KPIs defined in the Configuration Table.										|
|	|(1) KPI Level Information:																											|
|	|[KPI ID]																															|
|	|[KPI Names in different environments]																								|
|	|[Numeric Format of the KPI value]																									|
|	|[Dataset location of the KPI]																										|
|	|[Dataset name of the KPI] (This may contain the macro variables so remember to setup the related environment)						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|(2) Dataset Level Information:																										|
|	|[Unique Dataset Location as well as Name] (The same Dataset Name, which contain different KPIs but are in different				|
|	|  locations should be treated as different sources.)																				|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inKPICfg		:	The dataset that stores the full configuration of the KPI.														|
|	|nKpiID			:	The number of unique [KPI ID].																					|
|	|pfxKpiID		:	The PREFIX of the series of macro variables that contain the [KPI ID].											|
|	|					e.g. If it is provided as [GeKPIID], then macro variables [GeKPIID1] to [GeKPIID{n}] are created.				|
|	|pfxKpiName		:	The PREFIX of the series of macro variables that contain the [KPI Name].										|
|	|pfxKpiLbl		:	The PREFIX of the series of macro variables that contain the [KPI Label].										|
|	|pfxKpiFmt		:	The PREFIX of the series of macro variables that contain the [KPI Format].										|
|	|nKpiDat		:	The number of unique datasets, as well as locations, that contain the dedicated KPIs.							|
|	|pfxKpiDatPath	:	The PREFIX of the series of macro variables that contain the path of the unique KPI dataset.					|
|	|pfxKpiDatName	:	The PREFIX of the series of macro variables that contain the name of the unique KPI dataset.					|
|	|procLIB		:	The working library.																							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20160626		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170724		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Add the call of function RESOLVE upon the pathname and dataset name variables, to ensure the names are properly recognized.	|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170815		| Version |	1.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Quote the LABEL during calling SYMPUTX routine and translate the single-quotation marks into double ones, in case there are	|
|	|      | special characters in the LABEL that should be masked.																		|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180204		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Remove the macro function UNQUOTE from parameter handling, to avoid unexpected result.										|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180304		| Version |	2.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180722		| Version |	2.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Leverage the additional option field of the function [QUOTE] to eliminate unexpected results.								|
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
%let	procLIB	=	%unquote(&procLIB.);
%if	%length(%qsysfunc(compress(&inKPICfg.,%str( ))))		=	0	%then	%let	inKPICfg		=	src.CFG_KPI;
%if	%length(%qsysfunc(compress(&nKpiID.,%str( ))))			=	0	%then	%let	nKpiID			=	LnKpi;
%if	%length(%qsysfunc(compress(&pfxKpiID.,%str( ))))		=	0	%then	%let	pfxKpiID		=	LeKpiID;
%if	%length(%qsysfunc(compress(&pfxKpiName.,%str( ))))		=	0	%then	%let	pfxKpiName		=	LeKpiNM;
%if	%length(%qsysfunc(compress(&pfxKpiLbl.,%str( ))))		=	0	%then	%let	pfxKpiLbl		=	LeKpiLBL;
%if	%length(%qsysfunc(compress(&pfxKpiFmt.,%str( ))))		=	0	%then	%let	pfxKpiFmt		=	LeKpiFMT;
%if	%length(%qsysfunc(compress(&nKpiDat.,%str( ))))			=	0	%then	%let	nKpiDat			=	LnKpiDat;
%if	%length(%qsysfunc(compress(&pfxKpiDatPath.,%str( ))))	=	0	%then	%let	pfxKpiDatPath	=	LeKpiDatPath;
%if	%length(%qsysfunc(compress(&pfxKpiDatName.,%str( ))))	=	0	%then	%let	pfxKpiDatName	=	LeKpiDatName;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))			=	0	%then	%let	procLIB			=	WORK;

%*013.	Define the local environment.;

%*018.	Define the global environment.;
%global
	&nKpiID.
	&nKpiDat.
;
%let	&nKpiID.	=	0;
%let	&nKpiDat.	=	0;

%*100.	Identify all the required KPIs in the configuration table.;
data &procLIB..__LoadKPIcfg__;
	set %unquote(&inKPICfg.) end=EOF;
	call symputx(cats("&pfxKpiID.",_N_),C_KPI_ID,"G");
	call symputx(cats("&pfxKpiName.",_N_),C_KPI_SHORTNAME,"G");
	call symputx(cats("&pfxKpiLbl.",_N_),quote(strip(C_KPI_BIZNAME),"'"),"G");
	call symputx(cats("&pfxKpiFmt.",_N_),C_KPI_FORMAT,"G");
	if	EOF	then do;
		call symputx("&nKpiID.",_N_,"G");
	end;
run;

%*190.	Quit the process if there is no KPI defined in the inventory.;
%if	&&&nKpiID..	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No KPI is defined for loading. Skip the process.;
	%goto	EndOfProc;
%end;

%*200.	Identify the datasets that store the required KPIs.;
proc sort
	data=&procLIB..__LoadKPIcfg__(
		keep=
			C_KPI_DAT_PATH
			C_KPI_DAT_NAME
	)
	out=&procLIB..__LoadKPIcfg_path__
	nodupkey
;
	by
		C_KPI_DAT_PATH
		C_KPI_DAT_NAME
	;
run;
data _NULL_;
	set &procLIB..__LoadKPIcfg_path__ end=EOF;
	%*Here we create the library for the data that stores each KPI.;
%*	rc=libname(cats("_k",_N_),C_KPI_DAT_PATH,,'access=readonly');
%*	call symputx(cats("LeKpiDatLib",_N_),cats("_k",_N_),"G");
	call symputx(cats("&pfxKpiDatPath.",_N_),resolve(C_KPI_DAT_PATH),"G");
	call symputx(cats("&pfxKpiDatName.",_N_),resolve(C_KPI_DAT_NAME),"G");
	if	EOF	then do;
		call symputx("&nKpiDat.",_N_,"G");
	end;
run;

%EndOfProc:
%mend DBcore_LoadDatInfFrKpiCfg;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
%let	L_srcflnm	=	D:\SAS\omnimacro\AdvDB\TestETL.xlsx;
%let	L_stpflnm	=	CFG_KPI;

%*100.	Import the configuration table.;
PROC IMPORT
	OUT			=	CFG_KPI_pre(where=(missing(KPI_ID)=0))
	DATAFILE	=	"&L_srcflnm."
	DBMS		=	EXCEL2010
	REPLACE
;
	SHEET		=	"KPIRepository$";
	GETNAMES	=	YES;
	MIXED		=	NO;
	SCANTEXT	=	YES;
	USEDATE		=	YES;
	SCANTIME	=	YES;
RUN;

data &L_stpflnm.(compress=yes);
	set CFG_KPI_pre;

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
		C_KPI_DAT_PATH	$512.
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
		C_KPI_DAT_PATH	=	"The Absolute Path of the Dataset storing current KPI"
		C_KPI_DAT_NAME	=	"The Name of the Dataset storing current KPI"
		
	;

	D_BGN			=	Begin_Date;
	D_END			=	End_Date;
	C_KPI_ID		=	strip(KPI_ID);
	C_KPI_SHORTNAME	=	strip(KPI_SHORTNAME);
	C_KPI_BIZNAME	=	strip(KPI_BIZNAME);
	C_KPI_DESC		=	strip(KPI_DESC);
	C_PGM_PATH		=	strip(PGM_PATH);
	C_PGM_NAME		=	strip(PGM_NAME);
	F_KPI_INUSE		=	KPI_INUSE;
	C_KPI_FORMAT	=	strip(KPI_FORMAT);
	C_KPI_DAT_PATH	=	strip(pathname("work"));
	C_KPI_DAT_NAME	=	strip(KPI_DAT_NAME);

	keep
		D_BGN
		D_END
		C_KPI_ID
		C_KPI_SHORTNAME
		C_KPI_BIZNAME
		C_KPI_DESC
		C_PGM_PATH
		C_PGM_NAME
		F_KPI_INUSE
		C_KPI_FORMAT
		C_KPI_DAT_PATH
		C_KPI_DAT_NAME
	;
run;

%*200.	Create the test KPI tables.;
data custinfo;
	format
		nc_cifno	$30.
		c_custid	$64.
	;
	nc_cifno	=	"0001";
	c_custid	=	"123456789";
	output;
	nc_cifno	=	"0002";
	c_custid	=	"923456780";
	output;
run;
data acctinfo;
	format
		nc_cifno	$30.
		nc_acct_no	$64.
		d_maturity	yymmddD10.
	;
	nc_cifno	=	"0001";
	nc_acct_no	=	"0000101";
	d_maturity	=	mdy(4,1,2016);
run;
data kpi;
	format
		nc_cifno	$30.
		nc_acct_no	$64.
		C_KPI_ID	$16.
		A_KPI_VAL	best32.
	;
	nc_cifno	=	"0001";

	%*CASA;
	nc_acct_no	=	"0000101";
	C_KPI_ID	=	"220000";
	A_KPI_VAL	=	55000;
	output;

	C_KPI_ID	=	"220001";
	A_KPI_VAL	=	55000;
	output;

	C_KPI_ID	=	"220101";
	A_KPI_VAL	=	55000;
	output;

	%*TD;
	nc_acct_no	=	"0001101";
	C_KPI_ID	=	"220000";
	A_KPI_VAL	=	600000;
	output;

	C_KPI_ID	=	"220102";
	A_KPI_VAL	=	600000;
	output;

	nc_acct_no	=	"0001103";
	C_KPI_ID	=	"220000";
	A_KPI_VAL	=	70000;
	output;

	C_KPI_ID	=	"220102";
	A_KPI_VAL	=	70000;
	output;
run;
data kpi2;
	format
		nc_cifno	$30.
		nc_acct_no	$64.
		C_KPI_ID	$16.
		A_KPI_VAL	best32.
	;
	nc_cifno	=	"0001";

	%*CASA;
	nc_acct_no	=	"0000101";
	C_KPI_ID	=	"100000";
	A_KPI_VAL	=	150;
	output;

	%*TD;
	nc_acct_no	=	"0001101";
	C_KPI_ID	=	"100000";
	A_KPI_VAL	=	3000;
	output;

	nc_acct_no	=	"0001103";
	C_KPI_ID	=	"100000";
	A_KPI_VAL	=	320;
	output;
run;

%DBcore_LoadDatInfFrKpiCfg(
	inKPICfg		=	CFG_KPI
	,nKpiID			=	LnKpi
	,pfxKpiID		=	LeKpiID
	,pfxKpiName		=	LeKpiNM
	,pfxKpiLbl		=	LeKpiLBL
	,pfxKpiFmt		=	LeKpiFMT
	,nKpiDat		=	LnKpiDat
	,pfxKpiDatPath	=	LeKpiDatPath
	,pfxKpiDatName	=	LeKpiDatName
	,procLIB		=	WORK
)

%*Shortcut;
%DBcore_LoadDatInfFrKpiCfg( inKPICfg = CFG_KPI )

/*-Notes- -End-*/