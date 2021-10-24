%macro cdwflt_segcode_IND(inSEGCODE=);
%*005.	Set parameters.;
%local	segcode_cond;

%*20110101;
%let	segcode_cond	=	&inSEGCODE.	in	('60' '61' '65' '66' '57');

%*010.	Make statements.;
(&segcode_cond.)
%mend cdwflt_segcode_IND;