%macro GenEnviro;
%*Below section generates the system-level global variables;

%*100.	Search for customized initialization program for each stage.;
%chkBeforeInclude(
	inroot=&curroot.
	,inflnm=000_Pre_Def.sas
)

%*200.	Load all user defined Functions and Subroutines.;
%*210.	Generate the list for all predefined usable macros.;
%*Below macro is from "&cdwmac.\AdvOp";
%list_sasautos

%*220.	Retrieve all macro names beginning with "usFUN_" or "usSUB_";
%*Below macro is from "&cdwmac.\AdvOp";
%getMCRbySTR(
	FUZZY	=	0
	,inNAME	=
			usFUN_
			usSUB_
	,NMidx	=	1
	,outMEL	=	LeFUNSUB
	,outMT	=	LnFUNSUB
	,outLIB	=	WORK2
)

%*230.	Call each macro to run FCmp Procedure.;
%if	&LnFUNSUB.	=	0	%then %do;
	%goto	EndOfFunc;
%end;
options	cmplib=_NULL_;
proc FCmp
	outlib=WORK.mySubs.usr
;
	%do	FUNi=1	%to	&LnFUNSUB.;
		%&&LeFUNSUB&FUNi..
	%end;
run;
quit;
options	cmplib=WORK.mySubs;
%EndOfFunc:

%mend GenEnviro;