%macro cdwflt_PSGL_custseg_SME(inCUSTSEG=);
%*005.	Set parameters.;
%local	custseg_cond;

%*20110101;
%let	custseg_cond	=	&inCUSTSEG.	in	("23","24","25","26","27","28","29","023","024","025","026","027","028","029");

%*20110817;
%let	custseg_cond	=	&inCUSTSEG.	in	("19","23","24","25","26","27","28","29","019","023","024","025","026","027","028","029");

%*010.	Make statements.;
(&custseg_cond.)
%mend cdwflt_PSGL_custseg_SME;