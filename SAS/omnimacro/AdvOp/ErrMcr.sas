%macro ErrMcr;
	%local	cERRORABEND;
	%let	cERRORABEND	=	0;
	%if	%sysfunc(getoption(ERRORABEND) ) = ERRORABEND	%then	%let	cERRORABEND	=	1;
	%if	&cERRORABEND.	=	0	%then %do;
		options	ERRORABEND;
	%end;

	%put	%str(N)OTE: Below line is generated intentionally to bomb the current SAS program.;
	%abort	abend;
%*	data _NULL_;
%*		abort abend;
%*	run;
%mend ErrMcr;

/*
This "abend" option will cause the SAS instance to set the "_ERROR_" to 1 and terminate checking and executing subsequent statements.
*/