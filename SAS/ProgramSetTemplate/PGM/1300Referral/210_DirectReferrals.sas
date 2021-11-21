%*001.	This section generates system log data.;
%*Below macro is from "&macroot.\010Proc";
%genLogByExecPgm

%*010.	Below section generates the system-level global variables;
%global
	L_srcflnm
	L_stpflnm
;

%let	L_srcflnm	=	src.Referral;
%let	L_stpflnm	=	Anl.Ref_kDirRef;

/***************************************************************************************************\
|	Count the direct referrals for all referrers in the Referral Tree.								|
|	Concept: a customer can only be referred to the company by ONE customer, while one customer can	|
|	 refer many.																					|
\***************************************************************************************************/

%*020.	Below section is for main process;
%macro GetDirectRef;
%*010.	Define the local environment.;

%*100.	Call the predefined macro to count the direct referrals.;
%*Below macro is from "&cdwmac.\OpsResearch";
%OrgTree_KDirectSub(
	inDAT		=	&L_srcflnm.
	,VarUpper	=	C_REFERRER
	,VarLower	=	C_CUSTOMER
	,outVAR		=	K_DirRef
	,outDAT		=	work2.ref_kDirRef
	,procLIB	=	WORK2
)

%*500.	Standardization.;
data &L_stpflnm.(compress=yes);
	%*001.	Create D_TABLE.;
	%*Below macro is from "&cdwmac.\AdvOp";
	%cr_d_table

	%*100.	Set the data.;
	set	work2.ref_kDirRef;
run;

%EndOfProc:
%mend GetDirectRef;
%GetDirectRef