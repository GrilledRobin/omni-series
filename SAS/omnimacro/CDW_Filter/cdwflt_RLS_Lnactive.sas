%macro cdwflt_RLS_Lnactive(lnstatcode=);
%*005.	Set parameters.;
%local	lnstatus_cond;

%let	lnstatus_cond	=	&lnstatcode. in ("60" "61" "65" "67" "69" "70" );

%*010.	Make statements.;
(&lnstatus_cond.)
%mend cdwflt_RLS_Lnactive;

/*
This macro is to set the RLS fund codes for IND.
*/