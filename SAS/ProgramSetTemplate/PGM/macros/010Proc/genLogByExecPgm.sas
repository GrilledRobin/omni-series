%macro genLogByExecPgm(
	outDAT		=	src.inf_ExeLog&L_curdate.
	,procLIB	=	WORK
);
%*000.	Introduction.;
%*Creation: Lu Robin Bin 20130704;
%*Version: 1.00;
%*This macro is intended to create log by every executing program.;

%*001.	Glossary.;
%*outDAT	:	The output pre-defined table containing the execution log.;
%*procLIB	:	The processing library.;

%*002.	Update log.;

%*003.	User Manual.;
%*Prerequisites (Primarily restricted by the macro "FS_WhereIsThisPgm"):;
%*(1) All programs which need to call this macro should be involved in '%include' statement when in batch mode.;
%*(2) All programs which need to call this macro should be SAVED to harddisk at first.;
%*(3) This macro should be called at the very FIRST LINE in the program.;

%*010.	Set parameters.;
%global
	execpath
	execfile
;
%let	execpath	=;
%let	execfile	=;

%if	%bquote(&outDAT.)	EQ	%then	%let	outDAT		=	src.inf_ExeLog&L_curdate.;
%if	%bquote(&procLIB.)	EQ	%then	%let	procLIB		=	WORK;

%*100.	Generate Log information.;
%*110.	Find currnt executing program.;
%*Below macro is from "&cdwmac.\FileSystem";
%FS_WhereIsThisPgm

%let	execfile	=	%qscan(&G_PathOfExecPgm.,-1,%str(\));
%let	execpath	=	%qsubstr(&G_PathOfExecPgm.,1,%eval(%length(&G_PathOfExecPgm.)-%length(&execfile.)));

%*500.	Create Description table.;
%*510.	Check existence of the pre-defined table.;
%if	not	%sysfunc(exist(&outDAT.))	%then %do;
	proc sql noprint;
		create table &outDAT.(
			D_TABLE			NUM			label='Date of Table'						format=yymmddD10.
			,D_DATA			NUM			label='Date of Data'						format=yymmddD10.
			,T_REC			NUM			label='Time of Record'						format=DATETIME.
			,C_STAGE		char(64)	label='Current Stage'
			,C_PGM_ROOT		char(512)	label='Program Root'
			,C_USERID		char(32)	label='Program User ID'
			,C_USERDOMAIN	char(128)	label='Program User Domain'
			,C_PGM_PATH		char(512)	label='Program Path'
			,C_PGM_FILE		char(128)	label='Program File'
		);
	quit;
%end;

%*520.	Create dummy table.;
data &procLIB.._tmptbl_log;
	set &outDAT.;
	drop
		D_TABLE
	;
run;

%*600.	Insert Journals to the pre-defined table.;
proc sql noprint;
	insert into &procLIB.._tmptbl_log
		set
			D_DATA			=	today()
			,T_REC			=	datetime()
			,C_STAGE		=	"&curstg."
			,C_PGM_ROOT		=	"&curroot."
			,C_USERID		=	"%sysget(USERNAME)"
			,C_USERDOMAIN	=	"%sysget(USERDOMAIN)"
			,C_PGM_PATH		=	"&execpath."
			,C_PGM_FILE		=	"&execfile."
	;
quit;

%*900.	Update the pre-defined table.;
data &outDAT.(compress=yes);
	%*Below macro is from "&cdwmac.\AdvOp";
	%cr_d_table

	set &procLIB.._tmptbl_log;
run;

%EndOfProc:
%mend genLogByExecPgm;