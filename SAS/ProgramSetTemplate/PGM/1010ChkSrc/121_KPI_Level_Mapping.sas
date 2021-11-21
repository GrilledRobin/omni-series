%*001.	This section generates system log data.;
%*Below macro is from "&macroot.\010Proc";
%genLogByExecPgm

%*010.	Below section generates the system-level global variables;
%global
	L_srcflnm
	L_stpflnm
;

%let	L_srcflnm	=	&rptDATA.\RAWDATA\param_KPI_Lvl.xlsx;
%let	L_stpflnm	=	src.rpt_KPI_lvl&L_curMon.;

/***************************************************************************************************\
|	This table stores the names of the information tables for respective KPI levels.				|
\***************************************************************************************************/

%*020.	Below section is for main process;
%macro ImpKPILvlMap;
%*010.	Issue error message once there is no such source data found.;
%if	%sysfunc(fileexist(&L_srcflnm.))	=	0	%then %do;
	%put	ERROR: The crucial configuration table does not exist! Program terminated!;
	%put	ERROR: Missing file "&L_srcflnm."!;
	%*Below macro is from "&cdwmac.\AdvOp";
	%ErrMcr
%end;

%*100.	Import the source data.;
PROC IMPORT
	OUT			=	work2.rpt_KPI_lvl_pre(where=(missing(KPI_LEVEL)=0))
	DATAFILE	=	"&L_srcflnm."
	DBMS		=	EXCEL2010
	REPLACE
;
	SHEET		=	"KPILevel$";
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

	set work2.rpt_KPI_lvl_pre;

	format
		C_KPI_LEVEL	$8.
		C_INF_TABLE	$64.
		C_INF_KEY	$32.
		C_FILE_SRC	$512.
	;
	label
		C_KPI_LEVEL	=	"KPI Level to Current Report"
		C_INF_TABLE	=	"Information Table at Current KPI Level"
		C_INF_KEY	=	"Key Variable in the Information Table at Current KPI Level"
		C_FILE_SRC	=	"Original Location of the File on the Server"
		
	;

	C_KPI_LEVEL	=	strip(KPI_LEVEL);
	C_INF_TABLE	=	strip(Info_Table);
	C_INF_KEY	=	strip(Info_Key);
	C_FILE_SRC	=	strip(File_Source);

	keep
		D_TABLE
		C_KPI_LEVEL
		C_INF_TABLE
		C_INF_KEY
		C_FILE_SRC
	;
run;

%EndOfProc:
%mend ImpKPILvlMap;
%ImpKPILvlMap