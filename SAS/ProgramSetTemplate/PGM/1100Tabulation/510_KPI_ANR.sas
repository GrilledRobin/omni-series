%*001.	This section generates system log data.;
%*Below macro is from "&macroot.\010Proc";
%genLogByExecPgm

%*010.	Below section generates the system-level global variables;
%global
	L_basedate
	LkDateDiff
	L_srcflnm1
	L_srcflnm2
	L_srcflnm3
	L_stpflnm
;

%let	L_basedate	=	%sysfunc( max( &L_prevLastWorkDay. , &L_dn_PrevWorkDay. ) );
%let	LkDateDiff	=	%sysfunc( max( 0 , %eval( &L_d_PrevWorkDay. - &L_d_BgnOfMth. + 1 ) ) );
%let	L_srcflnm1	=	DB.ACCT_MTD_ANR&L_basedate.;
%let	L_srcflnm2	=	DB.ACCT_ENR&L_basedate.;
%let	L_srcflnm3	=	DB.ACCT_ENR&L_curdate.;
%let	L_stpflnm	=	DB.ACCT_MTD_ANR&L_curdate.;

/***************************************************************************************************\
|	Create the KPI of MTD ANR (Average Net Receivable, or average balance).							|
|	Check the attachment for the detailed concept.													|
\***************************************************************************************************/

%*020.	Below section is for main process;
%macro genMTDANR;
%*010.	Define the local environment.;

%*050.	Create format for the calculation.;
proc format;
	value $f_kpi_factor
		"TANR01"	=	&LkDateDiff.
		"TANR02"	=	%eval( &L_nPastClnDayOfMth. - &LkDateDiff. - 1 )
		"TANR03"	=	1
	;
run;

%*100.	Retrieve the source data.;
data work2.__kpi_genMTDANR_pre;
	%*100.	Set the source.;
	set
	%if &LkDateDiff. ^= 0 %then %do;
		&L_srcflnm1.(in=i1)
	%end;
		&L_srcflnm2.(in=i2)
		&L_srcflnm3.(in=i3)
	;

	%*200.	Create temporary KPI ID for the calculation.;
%if &LkDateDiff. ^= 0 %then %do;
	if	i1	then do;
		C_KPI_ID	=	"TANR01";
	end;
%end;
	if	i2	then do;
		C_KPI_ID	=	"TANR02";
	end;
	if	i3	then do;
		C_KPI_ID	=	"TANR03";
	end;

	%*300.	Set the temporary KPI value.;
	A_KPI_VAL	=	A_KPI_VAL	*	put(C_KPI_ID,f_kpi_factor.);

	%*500.	Output.;
	output;

	%*800.	Create dummy observation if there is no ANR on previous workday provided.;
	nc_acctno	=	"Dummy";
	C_KPI_ID	=	"TANR01";
	A_KPI_VAL	=	0;
	output;

	%*900.	Purge.;
	drop
		D_TABLE
	;
run;

%*300.	Calculate in terms of the pre-defined formula, using the KPIs.;
%*IMPORTANT: All Classes in the Tabulation report should be presented here, except the [C_KPI_ID] and its superior;
%* dimensions, such as [C_KPI_CAT1], for they will be created in the next step.;
%*Below macro is from "&cdwmac.\AdvDB";
%DBuse_crKPIbyFnOnKPIID(
	inDat		=	work2.__kpi_genMTDANR_pre
	,inCLASS	=	%nrbquote(
						nc_branch_cd
						c_branch_nm
						c_city_name
						nc_officer_cd
						nc_cifno
						nc_acctno
					)
	,inKPIlist	=	%nrbquote(
						TANR01
						TANR02
						TANR03
					)
	,inFormula	=	%nrstr(
						sum( 0 , TANR01 , TANR02 , TANR03 ) / &L_nPastClnDayOfMth.
					)
	,outKPIID	=	102410
	,outDAT		=	work2.__kpi_genMTDANR
	,procLIB	=	WORK2
)

%*390.	Skip this step if there is no output data.;
%if	%sysfunc(exist(work2.__kpi_genMTDANR))	=	0	%then %do;
	%put	NOTE: Creation of new KPI failed due to missing data. Skip current step.;
	%goto	EndOfProc;
%end;

%*900.	Standardize the data.;
data &L_stpflnm.(compress=yes);
	%*001.	Create D_TABLE;
	%*Below macro is from "&cdwmac.\AdvOp";
	%cr_d_table

	%*005.	Initialize the standard KPI structure.;
	%*Below macro is from "&macroot.\010Proc";
	%InitVar_KPIData

	%*010.	Set all the KPI data.;
	set work2.__kpi_genMTDANR;

	%*990.	Purge.;
%	keep
		D_TABLE
	;
run;

%EndOfProc:
%mend genMTDANR;
%genMTDANR

/* - Concept - * Begin * /
The formula is set as below, for the calculation of ANR:
A(n) = ( A(k) * k + B(k) * ( n - k - 1 ) + B(n) * 1 ) / n
where:
A(i)	:	MTD ANR from the beginning of the month till the date of {i}
B(i)	:	ENR or Balance of the date of {i}
n		:	The calendar days counting from the beginning of the month till current date
k		:	The number of workdays counting from the first Calendar date of the month till the PREVIOUS workday

Explanation:
The algorithm is only based on the data for the previous workday and current day, which reduces the effort.
A(k)	:	The MTD ANR at previous workdate
B(k)	:	The ENR at previous workdate
A(n)	:	The MTD ANR at current date
B(n)	:	The ENR at current date

Calculation steps:
(1) k = max( 0 ,PrevWorkDay - FirstCalendarDay + 1 )
(2) BaseDate = max( PrevWorkDay , PrevMthLastWorkDay )
(3) A(k) = A(BaseDate)
(4) B(k) = B(BaseDate)
(5) Since A(k) may not exist (when the first workdate is not the first calendar date in current month),
     we do not set the ANR data as of any workdates of the previous month:
    if k ^= 0 then set A(k)
(6) Prepare the formula f(n) for the aggregation:
    "A(k)" = k
    "B(k)" = n - k - 1
    "B(n)" = 1
(7) Use the formula f(n) to aggregate all the elements: A(k), B(k) and B(n)
    A1(k) = A(k) * f(n)
    B1(k) = B(k) * f(n)
    B1(n) = B(n) * f(n)
(8) Create the value of the new KPI A(n):
    A_KPI_VAL = sum( A1(k) , B1(k) , B1(n) ) / n
/* - Concept - * End */