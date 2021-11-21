%*Lec_NT_VarUnini;
data a;
	a=b;
run;

%*Lec_NT_PassHdrDt;

%*Lec_NT_Invalid;
data a;
	length	a	8.;
	a="a";
run;

%*Lec_NT_WDFormat;
data a;
	infile cards;
	input
		@1	actual	$char5.
		@1	fmt42	4.2
	;
	file log;
	put
		@1	actual=	$char5.
		@15	fmt42=	4.2
	;
cards;
7.499
14.49
768.1
1997
4858.
54632
;
run;

%*Lec_NT_MergeStmt;
%*Lec_NT_RepeatBy;
data a;
	a=1;b=1;output;
	a=1;b=3;output;
	a=2;b=2;output;
run;
data b;
	a=1;c=1;output;
	a=1;c=1;output;
run;
proc sort
	data=a
;
	by	a;
run;
proc sort
	data=b
;
	by	a;
run;
data c;
	merge a b;
	by	a;
run;

%*Lec_NT_MathOps;
%*Lec_NT_DivideBy0;
data a;
	a=1;
	b=0;
	c=a/b;
run;

%*Lec_NT_ProcChar;
%*Lec_NT_ConvVal;
%*Lec_NT_GenMissVal;
data a;
	a="a;";
	b=1;
	c=a*b;
run;


%*Lec_NT_ProcStop;
data tmp
	a=1;
run;