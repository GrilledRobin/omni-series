%macro cdwflt_custseg_IND(inCUSTSEG=);
%*005.	Set parameters.;
%local	custseg_cond;

%let	custseg_cond	=	&inCUSTSEG.	not in ('026') ;

%*010.	Make statements.;
(&custseg_cond.)
%mend cdwflt_custseg_IND;