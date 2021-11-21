%*001.	This section generates system log data.;
%*Below macro is from "&macroot.\010Proc";
%genLogByExecPgm

%*010.	Below section generates the system-level global variables;
%global
	L_srcflnm
	L_stpflnm
;

%let	L_srcflnm	=	&rptDATA.\RAWDATA\TXN.xlsx;
%let	L_stpflnm	=	src.txn&L_curMon.;

/***************************************************************************************************\
|	Transaction Details																				|
\***************************************************************************************************/

%*020.	Below section is for main process;
%macro ImpTxn;
%*010.	Issue error message once there is no such source data found.;
%if	%sysfunc(fileexist(&L_srcflnm.))	=	0	%then %do;
	%put	WARNING: The transaction details file does not exist! Program terminated!;
	%put	ERROR: Missing file "&L_srcflnm."!;
	%*Below macro is from "&cdwmac.\AdvOp";
	%ErrMcr
%end;

%*100.	Import the source data.;
PROC IMPORT
	OUT			=	work2.txn_pre(where=(missing(TransactionID)=0))
	DATAFILE	=	"&L_srcflnm."
	DBMS		=	EXCEL
	REPLACE
;
	SHEET		=	"TXN$";
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

	set work2.txn_pre;

	format
		C_CUST_ID		$32.
		C_PROD_ID		$16.
		C_TXN_ID		$16.
		DT_TXN			datetime23.2
		C_TXN_TYPE		$8.
		N_TXN_UNIT		best12.
		A_TXN_PRICE		best12.
	;

	C_CUST_ID	=	strip(Customer);
	C_PROD_ID	=	strip(ProductID);
	C_TXN_ID	=	strip(TransactionID);
	DT_TXN		=	dhms(Transaction_Date,hour(Transaction_Time),minute(Transaction_Time),second(Transaction_Time));
	C_TXN_TYPE	=	strip(Transaction_Type);
	N_TXN_UNIT	=	Transaction_Unit;
	A_TXN_PRICE	=	Price;

	keep
		A_:
		C_:
		D_:
		DT_:
		N_:
	;
run;

%EndOfProc:
%mend ImpTxn;
%ImpTxn