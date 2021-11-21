%*001.	This section generates system log data.;
%*Below macro is from "&macroot.\010Proc";
%genLogByExecPgm

%*010.	Below section generates the system-level global variables;
%global
	L_srcflnm
	L_stpflnm
;

%let	L_srcflnm	=	&rptDATA.\RAWDATA\CFG_KPI.xlsx;
%let	L_stpflnm	=	src.CFG_KPI&L_curMon.;

/***************************************************************************************************\
|	KPI Configuration Tables																		|
\***************************************************************************************************/

%*020.	Below section is for main process;
%macro ImpCFG4KPI;
%*010.	Issue error message once there is no such source data found.;
%if	%sysfunc(fileexist(&L_srcflnm.))	=	0	%then %do;
	%put	ERROR: The crucial configuration table does not exist! Program terminated!;
	%put	ERROR: Missing file "&L_srcflnm."!;
	%*Below macro is from "&cdwmac.\AdvOp";
	%ErrMcr
%end;

%*100.	Import the source data.;
PROC IMPORT
	OUT			=	work2.CFG_KPI_pre(where=(missing(KPI_ID)=0))
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

%*900.	Standardize the data.;
data &L_stpflnm.(compress=yes);
	%*Below macro is from "&cdwmac.\AdvOp";
	%cr_d_table

	set work2.CFG_KPI_pre;

	%*Below macro is from "&cdwmac.\AdvOp";
	%initNumVar

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
	C_KPI_DAT_PATH	=	strip(KPI_DAT_PATH);
	C_KPI_DAT_NAME	=	strip(KPI_DAT_NAME);

	%*100.	Tag the names of the source datasets that store the KPI with correct date.;
	%*If there is any exception, please define at this step.;
	C_KPI_DAT_PATH	=	upcase(C_KPI_DAT_PATH);
	C_KPI_DAT_NAME	=	upcase(cats(C_KPI_DAT_NAME,'&L_curDate.'));
/*
	%*e.g. If some data has the trail of [L_curMon], please conduct below action.;
	if	C_KPI_DAT_NAME	=	"[sth.]"	then do;
		C_KPI_DAT_NAME	=	cats(C_KPI_DAT_NAME,"&L_curMon.");
	end;
	else do;
		C_KPI_DAT_NAME	=	cats(C_KPI_DAT_NAME,"&L_curDate.");
	end;
*/

	keep
		D_TABLE
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

%EndOfProc:
%mend ImpCFG4KPI;
%ImpCFG4KPI