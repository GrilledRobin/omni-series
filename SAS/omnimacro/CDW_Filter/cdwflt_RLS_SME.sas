%macro cdwflt_RLS_SME(inFundCode=);
%*005.	Set parameters.;
%local	fundcode_cond;

%*20110101;
%let	fundcode_cond	=	cats(&inFundCode.)	=	"20";

%*010.	Make statements.;
(&fundcode_cond.)
%mend cdwflt_RLS_SME;

/*
This macro is to set the RLS fund codes for SME.
*/