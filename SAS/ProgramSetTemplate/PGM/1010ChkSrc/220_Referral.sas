%*001.	This section generates system log data.;
%*Below macro is from "&macroot.\010Proc";
%genLogByExecPgm

%*010.	Below section generates the system-level global variables;
%global
	L_srcflnm
	L_stpflnm
;

%let	L_srcflnm	=	&rptDATA.\RAWDATA\Referral.xlsx;
%let	L_stpflnm	=	src.Referral;

/***************************************************************************************************\
|	Referral Details																				|
\***************************************************************************************************/

%*020.	Below section is for main process;
%macro ImpReferral;
%*001.	Issue error message once there is no such source data found.;
%if	%sysfunc(fileexist(&L_srcflnm.))	=	0	%then %do;
	%*100.	Abort the process if both files do not exist.;
	%if	%sysfunc(exist(&L_stpflnm.))	=	0	%then %do;
		%put	%str(W)ARNING: The Referral details file does not exist! Program terminated!;
		%put	%str(W)ARNING: Missing file [&L_srcflnm.]!;
		%*Below macro is from "&cdwmac.\AdvOp";
		%ErrMcr
	%end;
	%else %do;
		%put	%str(N)OTE: [&L_srcflnm.] does not exist to update [&L_stpflnm.].;
		%goto	EndOfProc;
	%end;
%end;

%*010.	Define local environment.;
%local
	LinFModte
	LoutFModte
;
%let	LinFModte	=	.;
%let	LoutFModte	=	.;

%*020.	Skip the verification process if the output dataset does not exist.;
%if	%sysfunc(exist(&L_stpflnm.))	=	0	%then %do;
	%put	%str(N)OTE: Output file [&L_stpflnm.] does not exist and will be created.;
	%goto	EndOfFilChk;
%end;

%*030.	Retrieve the Last Modified Date of the input file.;
%*Below macro is from "&cdwmac.\AdvOp";
%let	LinFModte	=	%FS_FINFO( inFLNM = &L_srcflnm. , OptNum = 5 );

%*039.	Abort the process if we failed to retrieve the Last Modified Date.;
%if	&LinFModte.	=	.	%then %do;
	%put	%str(W)ARNING: Failed to retrieve the Last Modified Date of the input file!;
	%put	%str(W)ARNING: File name: [&L_srcflnm.]!;
	%*Below macro is from "&cdwmac.\AdvOp";
	%ErrMcr
%end;

%*040.	Retrieve the Last Modified Date of the output file.;
%let	LoutFModte	=	%FS_ATTRN( inDAT = &L_stpflnm. , inATTR = MODTE );

%*049.	Abort the process if we failed to retrieve the Last Modified Date.;
%if	&LoutFModte.	=	.	%then %do;
	%put	%str(W)ARNING: Failed to retrieve the Last Modified Date of the output file!;
	%put	%str(W)ARNING: File name: [&L_stpflnm.]!;
	%*Below macro is from "&cdwmac.\AdvOp";
	%ErrMcr
%end;

%*050.	Compare the Last Modified Date of both input and output files and quit if the latter is later than the former.;
%if	%sysevalf( &LoutFModte. > &LinFModte. )	%then %do;
	%put	%str(N)OTE: Output file [&L_stpflnm.] has been created before. Skip the process.;
	%goto	EndOfProc;
%end;

%*095.	Mark th end of verification.;
%EndOfFilChk:

%*100.	Import the source data.;
PROC IMPORT
	OUT			=	work2.ref_pre(where=(missing(Customer)=0))
	DATAFILE	=	"&L_srcflnm."
	DBMS		=	EXCEL
	REPLACE
;
	SHEET		=	"REF$";
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

	set work2.ref_pre;

	format
		C_REFERRER		$32.
		C_CUSTOMER		$32.
	;

	C_REFERRER	=	strip(Referrer);
	C_CUSTOMER	=	strip(Customer);

	keep
		C_:
		D_:
	;
run;

%EndOfProc:
%mend ImpReferral;
%ImpReferral