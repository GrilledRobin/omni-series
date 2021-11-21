%*001.	This section generates system log data.;
%*Below macro is from "&macroot.\010Proc";
%genLogByExecPgm

%*010.	Below section generates the system-level global variables;
%global
	L_srcflnm
	L_stpflnm
;

%let	L_srcflnm	=	&rptDATA.\RAWDATA\rpt_OthSrc.xlsx;
%let	L_stpflnm	=	src.rpt_OthSrc&L_curMon.;

/***************************************************************************************************\
|	Retrieve the source file list for current report if any											|
\***************************************************************************************************/

%*020.	Below section is for main process;
%macro ImpOthSrc;
%*010.	Parameters.;
%local	LvfyObs;
%let	LvfyObs	=	0;

%*020.	Issue error message once there is no such source data found.;
%if	%sysfunc(fileexist(&L_srcflnm.))	=	0	%then %do;
	%goto	EndOfProc;
%end;

%*100.	Import the source data.;
PROC IMPORT
	OUT			=	work2.rpt_OthSrc_pre(where=(missing(File_Name)=0))
	DATAFILE	=	"&L_srcflnm."
	DBMS		=	EXCEL2010
	REPLACE
;
	SHEET		=	"OthSrc$";
	GETNAMES	=	YES;
	MIXED		=	NO;
	SCANTEXT	=	YES;
	USEDATE		=	YES;
	SCANTIME	=	YES;
RUN;

%*500.	Verify the source.;
data work2.rpt_OthSrc_vfy;
	set
		work2.rpt_OthSrc_pre(
			where=(
					missing(File_Source)
				and	File_Type	=	"SASDAT"
			)
		)
	;
run;
%*Below macro is from "&cdwmac.\AdvOp";
%getOBS4DATA(
	inDAT	=	work2.rpt_OthSrc_vfy
	,outVAR	=	LvfyObs
	,gMode	=	P
)
%if &LvfyObs. ^= 0 %then %do;
	%put	WARNING: Some of the locations of the source datasets are not provided!;
	%put	WARNING: Please update below file for file type [SASDAT].;
	%put	WARNING: [&L_srcflnm.];
	%*Below macro is from "&cdwmac.\AdvOp";
	%ErrMcr
%end;

%*900.	Standardize the data.;
data &L_stpflnm.(compress=yes);
	%*Below macro is from "&cdwmac.\AdvOp";
	%cr_d_table

	set work2.rpt_OthSrc_pre;

	format
		C_FILE_TYPE	$16.
		C_FILE_NAME	$512.
		C_FILE_SRC	$512.
	;
	label
		C_FILE_TYPE	=	"File Type"
		C_FILE_NAME	=	"File Name"
		C_FILE_SRC	=	"Original Location of the File on the Server"
		
	;

	C_FILE_TYPE	=	strip(File_Type);
	C_FILE_NAME	=	strip(File_Name);
	C_FILE_SRC	=	strip(File_Source);

	keep
		D_TABLE
		C_FILE_TYPE
		C_FILE_NAME
		C_FILE_SRC
	;
run;

%EndOfProc:
%mend ImpOthSrc;
%ImpOthSrc