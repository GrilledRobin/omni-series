%macro cdwflt_CASA_SME(inPDTCODE=);
%*005.	Set parameters.;
%local	pdtcode_cond;

%*20110101;
%let	pdtcode_cond	=
	"201"	<=	cats(&inPDTCODE.)	<=	"319"
;
%*20110226;
%*let	pdtcode_cond	=
		"105"	<=	cats(&inPDTCODE.)	<=	"117"
	or	"201"	<=	cats(&inPDTCODE.)	<=	"319"
	or	"351"	<=	cats(&inPDTCODE.)	<=	"366"
	or	cats(&inPDTCODE.)	in	("119","120","122","123","141","142","144","163")
;

%*010.	Make statements.;
(&pdtcode_cond.)
%mend cdwflt_CASA_SME;

/*
This macro is to set the CASA product codes for SME.
*/