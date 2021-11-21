%*001.	This section generates system log data.;
%*Below macro is from "&macroot.\010Proc";
%genLogByExecPgm

%*010.	Below section generates the system-level global variables;
%global
	L_srcflnm
	L_stpflnm
;

%let	L_srcflnm	=	src.Referral;
%let	L_stpflnm	=	DB.Ref_AllChains;

/***************************************************************************************************\
|	Retrieve all referral chains from the Referral data.											|
|	A Chain denotes to a linkage from ANY node in the referral tree to the very ending leaf.		|
|	Concept: a customer can only be referred to the company by ONE customer, while one customer can	|
|	 refer many.																					|
\***************************************************************************************************/

%*020.	Below section is for main process;
%macro GetRefChain;
%*010.	Define the local environment.;

%*100.	Call the predefined macro to retrieve all chains.;
%*Below macro is from "&cdwmac.\OpsResearch";
%OrgTree_AllChains(
	inDAT		=	&L_srcflnm.
	,VarUpper	=	C_REFERRER
	,VarLower	=	C_CUSTOMER
	,ChainTop	=	C_ChainTop
	,ChainBtm	=	C_ChainBtm
	,ChainLvl	=	N_ChainLvl
	,outDAT		=	work2.ref_allChain
	,procLIB	=	WORK2
	,mNest		=	0
)

%*500.	Standardization.;
data &L_stpflnm.(compress=yes);
	%*001.	Create D_TABLE.;
	%*Below macro is from "&cdwmac.\AdvOp";
	%cr_d_table

	%*100.	Set the data.;
	set	work2.ref_allChain;
run;

%EndOfProc:
%mend GetRefChain;
%GetRefChain