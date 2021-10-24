%macro cdwflt_CustTypeCode_SME(inCUSTTYPE=);
%*005.	Set parameters.;
%local	custtype_cond;

%*20110521;
%let	custtype_cond	=	&inCUSTTYPE.	not	in	("ICB");

%*010.	Make statements.;
(&custtype_cond.)
%mend cdwflt_CustTypeCode_SME;