%macro genJnlByExecPgm(
	inPFX		=
	,nJNL		=	1
	,JNLDesc	=
	,outDAT		=	src.inf_JNL&L_curdate.
	,outELpfx	=	G_eJNL
	,procLIB	=	WORK
);
%*000.	Introduction.;
%*Creation: Lu Robin Bin 20130704;
%*Version: 1.00;
%*This macro is intended to create Journal information by current executing program.;

%*001.	Glossary.;
%*inPFX		:	Prefix of the Journal ID.;
%*nJNL		:	The number of Journals to be created.;
%*JNLDesc	:	The description for the Journals.;
%*outDAT	:	The output pre-defined table containing the Journal description.;
%*outELpfx	:	The output Journal prefixes.;
%*procLIB	:	The processing library.;

%*002.	Update log.;

%*003.	User Manual.;
%*Prerequisites (Primarily restricted by the macro "FS_WhereIsThisPgm"):;
%*(1) All programs which need to call this macro should be involved in '%include' statement when in batch mode.;
%*(2) All programs which need to call this macro should be SAVED to harddisk at first.;
%*(3) This macro should be called at the very FIRST LINE in the program.;

%*010.	Set parameters.;
%local
	execpath
	execfile
	tmpStr
	len
	pos
	PRXID
;
%let	execpath	=;
%let	execfile	=;
%let	PRXID		=	%sysfunc(prxparse(/[^[:digit:]]/i));	%*This pattern matches[^0-9];

%if	%bquote(&inPFX.)	EQ	%then	%let	inPFX		=	SYS;
%if	%bquote(&nJNL.)		EQ	%then	%let	nJNL		=	1;
%if	%bquote(&outDAT.)	EQ	%then	%let	outDAT		=	src.inf_JNL&L_curdate.;
%if	%bquote(&outELpfx.)	EQ	%then	%let	outELpfx	=	G_eJNL;
%if	%bquote(&procLIB.)	EQ	%then	%let	procLIB		=	WORK;

%if	%sysfunc(prxmatch(&PRXID.,&nJNL.))	^=	0	%then %do;
	%put	ERROR: "nJNL=&nJNL." is character instead of numeric!;
	%*Below macro is from "&cdwmac.\AdvOp";
	%ErrMcr
%end;

%*100.	Generate Journal ID.;
%*110.	Find currnt executing program.;
%*Below macro is from "&cdwmac.\FileSystem";
%FS_WhereIsThisPgm

%*120.	Generate the Journal ID.;
%let	execfile	=	%qscan(&G_PathOfExecPgm.,-1,%str(\));
%let	execpath	=	%qsubstr(&G_PathOfExecPgm.,1,%eval(%length(&G_PathOfExecPgm.)-%length(&execfile.)));

%let	PRXID		=	%sysfunc(prxparse(/^[[:digit:]\W_]+/i));	%*This pattern matches^[0-9\W_]+;
%let	pos			=	0;
%let	len			=	0;
%syscall prxsubstr(PRXID,execfile,pos,len);
%let	tmpStr		=	%sysfunc(compress(%substr(&execfile.,&pos.,&len.),0,dk));

%do	JNLi=1	%to	&nJNL.;
	%global	&outELpfx.&JNLi.;
	%let	&outELpfx.&JNLi.	=	%upcase(&inPFX.&RPTdate.&tmpStr.&JNLi.);
%end;

%*500.	Create Description table.;
%*510.	Check existence of the pre-defined table.;
%if	not	%sysfunc(exist(&outDAT.))	%then %do;
	proc sql noprint;
		create table &outDAT.(
			D_TABLE			NUM			label='Date of Table'						format=yymmddD10.
			,D_DATA			NUM			label='Date of Data'						format=yymmddD10.
			,T_REC			NUM			label='Time of Record'						format=DATETIME.
			,C_JNL_ID		char(32)	label='Journal ID'
			,C_JNL_DESC		char(128)	label='Journal Description'
			,C_USERID		char(32)	label='Journal Maker User ID'
			,C_USERDOMAIN	char(128)	label='Journal Maker User Domain'
			,C_PGM_PATH		char(512)	label='Program Path for Journal Creation'
			,C_PGM_FILE		char(128)	label='Program File for Journal Creation'
		);
	quit;
%end;

%*520.	Create dummy table.;
data &procLIB.._tmptbl_jnl;
	set &outDAT.;
	drop
		D_TABLE
	;
run;

%*600.	Insert Journals to the dummy table.;
proc sql noprint;
	insert into &procLIB.._tmptbl_jnl
		%do	JNLi=1	%to	&nJNL.;
			set
				D_DATA			=	today()
				,T_REC			=	datetime()
				,C_JNL_ID		=	"&&&outELpfx.&JNLi.."
				,C_JNL_DESC		=	"&JNLDesc."
				,C_USERID		=	"%sysget(USERNAME)"
				,C_USERDOMAIN	=	"%sysget(USERDOMAIN)"
				,C_PGM_PATH		=	"&execpath."
				,C_PGM_FILE		=	"&execfile."
		%end;
	;
quit;

%*900.	Update the pre-defined table.;
data &outDAT.(compress=yes);
	%*Below macro is from "&cdwmac.\AdvOp";
	%cr_d_table

	set &procLIB.._tmptbl_jnl;
run;

%EndOfProc:
%*Free the memory;
%syscall PRXFREE(PRXID);
%mend genJnlByExecPgm;