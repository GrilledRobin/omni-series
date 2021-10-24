%macro cdwflt_custseg_SME(inCUSTSEG=);
%*005.	Set parameters.;
%local	custseg_cond;

%*20110101;
%let	custseg_cond	=	&inCUSTSEG.	in	("23","24","25","26","27","28","29","023","024","025","026","027","028","029");

%*20110321;
%*Since 23 is for PvB and 24 contains no customer, we abandon them at present.;
%let	custseg_cond	=	&inCUSTSEG.	in	("25","26","27","28","29","025","026","027","028","029");

%*20120419;
%*In accordance with Management Reporting Guideline.;
%*ME: 24,25,28;
%*SB: the rest ones;
%*let	custseg_cond	=	&inCUSTSEG.	in	("19","23","24","25","26","27","28","29","019","023","024","025","026","027","028","029");

%*010.	Make statements.;
(&custseg_cond.)
%mend cdwflt_custseg_SME;