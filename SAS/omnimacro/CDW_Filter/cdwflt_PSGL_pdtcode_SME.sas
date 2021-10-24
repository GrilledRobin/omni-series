%macro cdwflt_PSGL_pdtcode_SME(inPDTCODE=);
%*005.	Set parameters.;
%local	pdtcode_cond;

%*20110514;
%*let	pdtcode_cond	=
		cats(&inPDTCODE.)	in	(
			"110","130","131"
			,"900"
		)
	or	"170"	<=	cats(&inPDTCODE.)	<=	"179"
	or	"200"	<=	cats(&inPDTCODE.)	<=	"770"
;

%*20110519;
%let	pdtcode_cond	=
		cats(&inPDTCODE.)	in	(
			"259"
			"349"
			"569"
		)
;

%*20120712;
%let	pdtcode_cond	=
		cats(&inPDTCODE.)	in	(
			"255"
			"259"
			"349"
			"569"
			"669"
		)
;

%*010.	Make statements.;
(&pdtcode_cond.)
%mend cdwflt_PSGL_pdtcode_SME;