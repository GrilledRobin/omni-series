%macro cdwflt_RLS_Lnbase(lnstatcode=);
%*005.	Set parameters.;
%local	lnbase_cond;

%let	lnbase_cond	=	&lnstatcode. in ("60" "61" "65" "67" "69" "70" "80" "81");

%*010.	Make statements.;
(&lnbase_cond.)
%mend cdwflt_RLS_Lnbase;

/*
This macro is to set the RLS Loan status code for active and Maturied deals.
*/