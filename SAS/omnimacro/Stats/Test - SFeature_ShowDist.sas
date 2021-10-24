%let	inflnm	=	D:\SAS\omnimacro\Stats\Test - SFeature_ShowDist.xlsx;

%*100.	Import sample data.;
PROC IMPORT
	OUT			=	Proc_univ(
						where=(
							compress(ID,"a","wk")	^=	""
						)
					)
	DATAFILE	=	"&inflnm."
	DBMS		=	EXCEL2007
	REPLACE
;
	SHEET		=	"sheet1$";
	GETNAMES	=	YES;
	MIXED		=	NO;
	SCANTEXT	=	YES;
	USEDATE		=	YES;
	SCANTIME	=	YES;
RUN;

%*200.	Basic Stats.;
ods select
	BasicMeasures
	ExtremeObs
;
proc univariate
	data=Proc_univ
;
	var	VAL;
run;
ods select
	default
;

%*210.	Histogram.;
ods graphics off;
title "Test Histogram";
proc univariate
	data=Proc_univ
	noprint
;
	histogram VAL;
	inset
		n	=	"Number of Obs"
		/position	=	nw
	;
run;
title;
ods graphics;

%*220.	Grouping and Kernel.;
title "Histogram with Kernel";
options nogstyle;
ods graphics on;
ods trace on;
ods select Quantiles Histogram;
proc univariate
	data=proc_univ
;
	var
		VAL
	;
	class
		TYPE
	;
	histogram
		VAL
		/KERNEL(color=red)
		cfill=ltgray
		name='myHist'	%*This seems useless in SAS9.3 X64;
	;
	inset
		n	=	"Number of Obs"
		median	=	"Median" (NegParen12.2)
		/position	=	ne
	;
	label
		TYPE	=	"Type of Color"
	;
run;
ods trace off;
options gstyle;
title;

%*230.	Normality Tests.;
title "Normality Test";
ods graphics on;
ods select
	Moments
	TestsForNormality
	ProbPlot
;
proc univariate
	data=proc_univ
	NormalTest
;
	var
		VAL
	;
	probplot
		VAL
		/normal (mu=est sigma=est)
		square
	;
	label
		VAL	=	"Values"
	;
	inset
		mean
		std
		/format=NegParen12.2
	;
run;
title;
