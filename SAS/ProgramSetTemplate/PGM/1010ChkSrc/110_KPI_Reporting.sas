%*001.	This section generates system log data.;
%*Below macro is from "&macroot.\010Proc";
%genLogByExecPgm

%*010.	Below section generates the system-level global variables;
%global
	L_srcflnm
	L_stpflnm
;

%let	L_srcflnm	=	&rptDATA.\RAWDATA\rpt_KPI.xlsx;
%let	L_stpflnm	=	src.rpt_KPI&L_curMon.;

/***************************************************************************************************\
|	KPI Configuration Table for current report														|
\***************************************************************************************************/

%*020.	Below section is for main process;
%macro ImpRptKPI;
%*010.	Issue error message once there is no such source data found.;
%if	%sysfunc(fileexist(&L_srcflnm.))	=	0	%then %do;
	%put	ERROR: The crucial configuration table does not exist! Program terminated!;
	%put	ERROR: Missing file "&L_srcflnm."!;
	%*Below macro is from "&cdwmac.\AdvOp";
	%ErrMcr
%end;

%*100.	Import the source data.;
PROC IMPORT
	OUT			=	work2.rpt_KPI_pre(where=(missing(KPI_ID)=0))
	DATAFILE	=	"&L_srcflnm."
	DBMS		=	EXCEL2010
	REPLACE
;
	SHEET		=	"RptKPI$";
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

	set work2.rpt_KPI_pre;

	format
		C_KPI_ID	$16.
		C_KPI_LEVEL	$8.
		A_KPI_UNIT	best.
		C_KPI_NAME	$32.
		C_KPI_CAT1	$512.
		C_KPI_CAT2	$512.
		C_KPI_CAT3	$512.
		C_KPI_CAT4	$512.
	;
	label
		C_KPI_ID	=	"KPI ID"
		C_KPI_LEVEL	=	"KPI Level to Current Report"
		A_KPI_UNIT	=	"Unit of KPI Value"
		C_KPI_NAME	=	"KPI Name in Current Report"
		C_KPI_CAT1	=	"KPI Category Level 1"
		C_KPI_CAT2	=	"KPI Category Level 2"
		C_KPI_CAT3	=	"KPI Category Level 3"
		C_KPI_CAT4	=	"KPI Category Level 4"
		
	;

	C_KPI_ID	=	strip(KPI_ID);
	C_KPI_LEVEL	=	strip(KPI_LEVEL);
	A_KPI_UNIT	=	KPI_UNIT;
	C_KPI_NAME	=	strip(KPI_NAME);
	C_KPI_CAT1	=	strip(KPI_CAT1);
	C_KPI_CAT2	=	strip(KPI_CAT2);
	C_KPI_CAT3	=	strip(KPI_CAT3);
	C_KPI_CAT4	=	strip(KPI_CAT4);

	keep
		D_TABLE
		C_KPI_ID
		C_KPI_LEVEL
		A_KPI_UNIT
		C_KPI_NAME
		C_KPI_CAT1
		C_KPI_CAT2
		C_KPI_CAT3
		C_KPI_CAT4
	;
run;

%EndOfProc:
%mend ImpRptKPI;
%ImpRptKPI