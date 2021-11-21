%macro ecLang_ENG;
%global
	Lec_WN_SasUserReg_ENG
	Lec_WN_NoRegCust_ENG
	Lec_WN_SysSchExp_ENG
	Lec_WN_BasSchExp_ENG
	Lec_WN_BasSchExp1_ENG
	Lec_WN_BasSchExp2_ENG

	Lec_NT_VarUnini_ENG
	Lec_NT_PassHdrDt_ENG
	Lec_NT_Invalid_ENG
	Lec_NT_WDFormat_ENG
	Lec_NT_RepeatBy_ENG
	Lec_NT_MathOps_ENG
	Lec_NT_GenMissVal_ENG
	Lec_NT_DivideBy0_ENG
	Lec_NT_MergeStmt_ENG
	Lec_NT_ProcChar_ENG
	Lec_NT_ConvVal_ENG
	Lec_NT_DisableItv_ENG
	Lec_NT_ProcNoObs_ENG
	Lec_NT_ProcStop_ENG

	Lec_ER_ExpectPg1_ENG
	Lec_ER_PgVldFail_ENG
;
%let	Lec_WN_SasUserReg_ENG	=	%nrbquote(UNABLE TO COPY SASUSER REGISTRY TO WORK REGISTRY);
%let	Lec_WN_NoRegCust_ENG	=	%nrbquote(YOU WILL NOT SEE REGISTRY CUSTOMIZATIONS DURING THIS SESSION);
%let	Lec_WN_SysSchExp_ENG	=	%nrbquote(YOUR SYSTEM IS SCHEDULED TO EXPIRE ON);
%let	Lec_WN_BasSchExp_ENG	=	%nrbquote(IS ASSOCIATED WILL BE EXPIRING);
%let	Lec_WN_BasSchExp1_ENG	=	%nrbquote(IN WARNING MODE TO INDICATE);
%let	Lec_WN_BasSchExp2_ENG	=	%nrbquote(INFORMATION ON YOUR WARNING PERIOD);

%let	Lec_NT_VarUnini_ENG		=	%nrbquote(IS UNINITIALIZED);
%let	Lec_NT_PassHdrDt_ENG	=	%nrbquote(PASS HEADER DATE);
%let	Lec_NT_Invalid_ENG		=	%nrbquote(INVALID);
%let	Lec_NT_WDFormat_ENG		=	%nrbquote(W.D FORMAT);
%let	Lec_NT_RepeatBy_ENG		=	%nrbquote(REPEATS OF BY VALUES);
%let	Lec_NT_MathOps_ENG		=	%nrbquote(MATHEMATICAL OPERATIONS COULD NOT);
%let	Lec_NT_GenMissVal_ENG	=	%nrbquote(MISSING VALUES WERE);
%let	Lec_NT_DivideBy0_ENG	=	%nrbquote(DIVISION BY ZERO);
%let	Lec_NT_MergeStmt_ENG	=	%nrbquote(MERGE STATEMENT);
%let	Lec_NT_ProcChar_ENG		=	%nrbquote(CHARACTER VALUES HAVE);
%let	Lec_NT_ConvVal_ENG		=	%nrbquote(VALUES HAVE BEEN CONVERTED);
%let	Lec_NT_DisableItv_ENG	=	%nrbquote(INTERACTIVITY DISABLED WITH);
%let	Lec_NT_ProcNoObs_ENG	=	%nrbquote(NO OBSERVATION);
%let	Lec_NT_ProcStop_ENG		=	%nrbquote(STOPPED PROCESSING);

%let	Lec_ER_ExpectPg1_ENG	=	%nrbquote(EXPECTING PAGE 1, GOT PAGE -1 INSTEAD);
%let	Lec_ER_PgVldFail_ENG	=	%nrbquote(PAGE VALIDATION ERROR WHILE READING SASUSER.PROFILE.CATALOG);
%mend ecLang_ENG;