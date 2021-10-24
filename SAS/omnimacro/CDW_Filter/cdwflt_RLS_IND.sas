%macro cdwflt_RLS_IND(inFundCode=);
%*005.	Set parameters.;
%local	fundcode_cond;

%*20110101;
%let	fundcode_cond	=	cats(&inFundCode.)	in	("10" "30");

%*010.	Make statements.;
(&fundcode_cond.)
%mend cdwflt_RLS_IND;

/*
This macro is to set the RLS fund codes for IND.
*/