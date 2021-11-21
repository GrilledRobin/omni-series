%macro trans_value;
	%*Generate the list for all predefined usable macros.;
	%*Below macro is from "&cdwmac.\AdvOp";
	%list_sasautos

	%*Retrieve all macro names beginning with "fmt_" or "cdwfmt_";
	%*Below macro is from "&cdwmac.\AdvOp";
	%getMCRbySTR(
		FUZZY	=	0
		,inNAME	=
				fmt_
				cdwfmt_
		,NMidx	=	1
		,outMEL	=	LMEL
		,outMT	=	LMTTL
		,outLIB	=	WORK2
	)

	%*Call each macro in consequence.;
	%if	&LMTTL.	=	0	%then %do;
		%goto	EndOfFmt;
	%end;
	proc format;
		%do	TRANSVALi=1	%to	&LMTTL.;
			%&&LMEL&TRANSVALi..
		%end;
	run;
	%EndOfFmt:

%EndOfProc:
%mend trans_value;