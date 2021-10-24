%macro cdwflt_TradeSeg_SME(inSegCode=);
%*005.	Set parameters.;
%local	segcode_cond;

%*20110101;
%let	segcode_cond	=	cats(&inSegCode.)	in	("7","8","9","07","08","09","10","49");

%*010.	Make statements.;
(&segcode_cond.)
%mend cdwflt_TradeSeg_SME;

/*
This macro is to set the segment codes in Trade sources for SME.
*/