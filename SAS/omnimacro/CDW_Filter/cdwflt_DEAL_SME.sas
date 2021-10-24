%macro cdwflt_DEAL_SME(inPDTCODE=);
%*005.	Set parameters.;
%local	pdtcode_cond;

%*20110101;
%let	pdtcode_cond	=
		"501"	<=	cats(&inPDTCODE.)	<=	"518"
	or	"615"	<=	cats(&inPDTCODE.)	<=	"618"
	or	"705"	<=	cats(&inPDTCODE.)	<=	"722"
;
%*20110226;
%*let	pdtcode_cond	=
		"501"	<=	cats(&inPDTCODE.)	<=	"518"
	or	"615"	<=	cats(&inPDTCODE.)	<=	"618"
	or	"705"	<=	cats(&inPDTCODE.)	<=	"722"
	or	cats(&inPDTCODE.)	in	("643","701","702","812","813","814")
;

%*20130724;
%let	pdtcode_cond	=
		"501"	<=	cats(&inPDTCODE.)	<=	"518"
	or	"615"	<=	cats(&inPDTCODE.)	<=	"618"
	or	"705"	<=	cats(&inPDTCODE.)	<=	"722"
	or	cats(&inPDTCODE.)	in	("571")
;

%*010.	Make statements.;
(&pdtcode_cond.)
%mend cdwflt_DEAL_SME;

/*
This macro is to set the DEAL product codes for SME.
*/