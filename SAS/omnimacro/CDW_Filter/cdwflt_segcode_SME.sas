%macro cdwflt_segcode_SME(inSEGCODE=);
%*005.	Set parameters.;
%local	segcode_cond;

%*20110101;
%let	segcode_cond	=	&inSEGCODE.	in	("52","53","54","55","56","58","59");

%*010.	Make statements.;
(&segcode_cond.)
%mend cdwflt_segcode_SME;