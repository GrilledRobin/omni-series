%*001.	This section generates system log data.;
%*Below macro is from "&macroot.\010Proc";
%genLogByExecPgm

%*010.	Below section generates the system-level global variables;
%global
	L_srcflnm
	L_stpflnm
;

%let	L_srcflnm	=	&rptDATA.\RAWDATA\Shibor&G_cur_year..xlsx;
%let	L_stpflnm	=	src.SHIBOR&G_cur_year.;

/***************************************************************************************************\
|	Retrieve the YTD SHIBOR from the website: http://www.shibor.org/								|
\***************************************************************************************************/

%*020.	Below section is for main process;
%macro ImpShibor;
%*010.	Issue error message once there is no such source data found.;
%if	%sysfunc(fileexist(&L_srcflnm.))	=	0	%then %do;
	%put	WARNING: The crucial configuration table does not exist! Program terminated!;
	%put	ERROR: Missing file "&L_srcflnm."!;
	%*Below macro is from "&cdwmac.\AdvOp";
	%ErrMcr
%end;

%*100.	Import the source data.;
PROC IMPORT
	OUT			=	work2.shibor_pre(where=(missing(_COL0)=0))
	DATAFILE	=	"&L_srcflnm."
	DBMS		=	EXCEL2010
	REPLACE
;
	SHEET		=	"SHEET$";
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

	set work2.shibor_pre;

	format
		D_SHIBOR		yymmddD10.
		T_SHIBOR		time8.
		A_SHIBOR_O_N	comma12.4
		A_SHIBOR_1W		comma12.4
		A_SHIBOR_2W		comma12.4
		A_SHIBOR_1M		comma12.4
		A_SHIBOR_3M		comma12.4
		A_SHIBOR_6M		comma12.4
		A_SHIBOR_9M		comma12.4
		A_SHIBOR_1Y		comma12.4
	;

	D_SHIBOR		=	int(_COL0);
	T_SHIBOR		=	timepart(_COL0);
	A_SHIBOR_O_N	=	O_N;
	A_SHIBOR_1W		=	_W;
	A_SHIBOR_2W		=	_W0;
	A_SHIBOR_1M		=	_M;
	A_SHIBOR_3M		=	_M0;
	A_SHIBOR_6M		=	_M1;
	A_SHIBOR_9M		=	_M2;
	A_SHIBOR_1Y		=	_Y;

	keep
		A_:
		D_:
		T_:
	;
run;

%EndOfProc:
%mend ImpShibor;
%ImpShibor