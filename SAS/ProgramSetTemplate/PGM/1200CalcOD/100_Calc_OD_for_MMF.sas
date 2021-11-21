%*001.	This section generates system log data.;
%*Below macro is from "&macroot.\010Proc";
%genLogByExecPgm

%*010.	Below section generates the system-level global variables;
%global
	L_srcflnm1
	L_srcflnm2
	L_srcflnm3
	L_stpflnm
	L_t_cutoff
	L_BankPrem
;

%let	L_srcflnm1	=	src.txn&L_curMon.;
%let	L_srcflnm2	=	clndr.Calendar&G_cur_year.;
%let	L_srcflnm3	=	src.SHIBOR&G_cur_year.;
%let	L_stpflnm	=	DB.OD_Premium&L_curMon.;

%*All transactions AFTER the cutoff will be valued at the next transaction window period.;
%let	L_t_cutoff	=	%str(15:00:00);
%*This Bank Premium will be added upon the SHIBOR, 80bps in Jun 2017.;
%let	L_BankPrem	=	0.8;

/***************************************************************************************************\
|	Calculate the premium for Overdraft of the bank on the Product of Money Market Fund, to cover	|
|	 the net customer redemption on T+0.															|
\***************************************************************************************************/

%*020.	Below section is for main process;
%macro CalcODforMMF;
%*010.	Define the local environment.;

%*050.	Prepare the formats for process.;
proc format;
	value $f_txnDir
		"SUB"	=	-1
		"RED"	=	1
		other	=	0
	;
run;

%*100.	Translate the Transaction Details to prepare the calculation.;
%*110.	Create necessary fields to determine the cutoff point of each transaction for each customer.;
data work2.OD4MMF_pre;
	%*100.	Set the transaction details.;
	set	&L_srcflnm1.(drop=D_TABLE);

	%*200.	Hash in the YTD Overnight SHIBOR as mapping.;
	if	0	then	set	&L_srcflnm3.(keep=D_SHIBOR A_SHIBOR_O_N);
	if	_N_	=	1	then do;
		dcl	hash	hSHIBOR(dataset:"&L_srcflnm3.(keep=D_SHIBOR A_SHIBOR_O_N)");
		hSHIBOR.DefineKey("D_SHIBOR");
		hSHIBOR.DefineData("A_SHIBOR_O_N");
		hSHIBOR.DefineDone();
	end;

	%*300.	Create new fields.;
	format
		D_TXN		yymmddD10.
		T_TXN		time8.
		D_OD_ACT	yymmddD10.
		D_OD_CALC	yymmddD10.
		A_SHIBOR_H	comma12.4
		D_SHIBOR_H	yymmddD10.
		K_SHIBOR_H	8.
		A_SHIBOR_W	comma12.4
		D_SHIBOR_W	yymmddD10.
		K_SHIBOR_W	8.
		A_TXN_DIR	8.
	;
	label
		D_OD_ACT	=	"The date on which the OD happens"
		D_OD_CALC	=	"The date on which to calculate the OD"
		A_SHIBOR_H	=	"The SHIBOR to calculate the OD (For Holidays)"
		D_SHIBOR_H	=	"The previous Workday to retrieve SHIBOR to calculate the OD for net redemption on Current Day (For Holidays)"
		K_SHIBOR_H	=	"The number of days to calculate the OD (For Holidays)"
		A_SHIBOR_W	=	"The SHIBOR to calculate the OD (For Workdays)"
		D_SHIBOR_W	=	"The Current Workday to retrieve SHIBOR to calculate the OD for net redemption on Current Day (For Workdays)"
		K_SHIBOR_W	=	"The number of days to calculate the OD (For Workdays)"
		A_TXN_DIR	=	"The direction of the transaction"
	;

	%*500.	Calculate the values for the created fields.;
	%*510.	The date and time on which the transaction happens.;
	D_TXN	=	datepart(DT_TXN);
	T_TXN	=	timepart(DT_TXN);

	%*520.	Determine the date one which the Overdraft happens.;
	%*Add one day upon [D_TXN] if the transaction is later than the cutoff.;
	D_OD_ACT	=	sum( D_TXN , ( T_TXN >= input( "&L_t_cutoff." , time8. ) ) );

	%*530.	Determine the date on which to calculate the Overdraft;
	%*Check whether above date is Workday or defer it to its next Workday.;
	%*e.g. If DT_TXN=[2017-05-19 20:00:00] (Friday), the Overdraft calculation date should be [2017-05-22].;
	%*Below function is from "&cdwmac.\Dates";
	D_OD_CALC	=	isWDorDefer("&L_srcflnm2.","D_DATE","F_TradeDay",D_OD_ACT);

	%*540.	Determine the SHIBOR to calculate Overdraft on holidays.;
	%*Below function is from "&cdwmac.\Dates";
	D_SHIBOR_H	=	prevWorkday("&L_srcflnm2.","D_DATE","F_TradeDay",D_OD_ACT);
	%*If the Overdraft Caclulation date is the same as the Overdraft Happening date, this part will be zero.;
	K_SHIBOR_H	=	D_OD_CALC	-	D_OD_ACT;
	call missing(A_SHIBOR_O_N);
	_iorc_		=	hSHIBOR.find(key:D_SHIBOR_H);
	if	_iorc_	=	0	then do;
		A_SHIBOR_H	=	A_SHIBOR_O_N;
	end;

	%*550.	Determine the SHIBOR to calculate Overdraft on workdays.;
	%*Since the calculation is on daily basis, this part should always take 1 day.;
	D_SHIBOR_W	=	D_OD_CALC;
	K_SHIBOR_W	=	1;
	call missing(A_SHIBOR_O_N);
	_iorc_		=	hSHIBOR.find(key:D_SHIBOR_W);
	if	_iorc_	=	0	then do;
		A_SHIBOR_W	=	A_SHIBOR_O_N;
	end;

	%*560.	Determine the direction of the transactions.;
	A_TXN_DIR	=	put( C_TXN_TYPE , f_txnDir. );

	%*900.	Purge.;
	drop
		D_SHIBOR
		A_SHIBOR_O_N
	;
run;

%*200.	Sort the data by each customer and transaction time.;
proc sort
	data=work2.OD4MMF_pre
	out=work2.OD4MMF_srt
;
	by
		C_PROD_ID
		C_CUST_ID
		D_OD_CALC
		DT_TXN
	;
run;

%*500.	Calculation.;
data &L_stpflnm.(compress=yes);
	%*001.	Create D_TABLE.;
	%*Below macro is from "&cdwmac.\AdvOp";
	%cr_d_table

	%*100.	Set the transaction details.;
	set	work2.OD4MMF_srt;
	by
		C_PROD_ID
		C_CUST_ID
		D_OD_CALC
		DT_TXN
	;

	%*200.	Create new fields.;
	format
		F_OD_CALC	8.
		N_OD_UNIT	best12.
		A_OD_AMT	best12.
	;
	label
		F_OD_CALC	=	"Flag of whether current transaction triggers Overdraft"
		N_OD_UNIT	=	"Number of units of the Overdraft"
		A_OD_AMT	=	"Amount of the Overdraft"
	;
	retain
		__OD_netRED
	;

	%*300.	Calculate the Overdraft.;
	%*310.	Reset the cumulative net redemption at the beginning of each trade date.;
	%*The trade date actually begins at the cutoff time of the previous Workday.;
	if	first.D_OD_CALC	then do;
		__OD_netRED	=	0;
	end;

	%*320.	Accumulate the net redemption in terms of the transaction direction.;
	__OD_netRED	+	N_TXN_UNIT	*	A_TXN_PRICE	*	A_TXN_DIR;

	%*330.	Trigger the Overdraft once the net redemption is positive.;
	F_OD_CALC	=	( __OD_netRED > 0 );

	%*340.	Assign the number of units for the Overdraft.;
	N_OD_UNIT	=	__OD_netRED	*	F_OD_CALC;

	%*350.	Calculate the amount for the Overdraft.;
	%*[AnnualizeDate] is from AUTOEXEC.SAS;
	A_OD_AMT	=	sum(0
						,N_OD_UNIT * sum( A_SHIBOR_H , &L_BankPrem. ) * K_SHIBOR_H / ( 100 * &AnnualizeDate.)
						,N_OD_UNIT * sum( A_SHIBOR_W , &L_BankPrem. ) * K_SHIBOR_W / ( 100 * &AnnualizeDate.)
					)
	;

	%*390.	Reset the net redemption to 0 AFTER the Overdraft is triggered.;
	if	F_OD_CALC	=	1	then do;
		__OD_netRED	=	0;
	end;

	%*900.	Purge.;
	drop
		_:
	;
run;

%EndOfProc:
%mend CalcODforMMF;
%CalcODforMMF