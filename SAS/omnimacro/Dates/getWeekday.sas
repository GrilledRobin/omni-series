%macro getWeekday(
	inyr	=
	,inmth	=
	,inday	=
	,outvar	=
);
	data _NULL_;
		call symputx("&outvar.",put(mdy(&inmth,&inday,&inyr),weekdate3.),"G");
	run;

	%*Alternatives.;
/*
	%global	&outvar.;
	%let	&outvar.	=	%sysfunc(putn(%sysfunc(mdy(&inmth,&inday,&inyr)),downame3.));
	%let	&outvar.	=	%sysfunc(putn(%sysfunc(mdy(&inmth,&inday,&inyr)),weekdate3.));
	%let	&outvar.	=	%sysfunc(putn(%sysfunc(mdy(&inmth,&inday,&inyr)),weekdatx3.));

	%*Likewise: monnameX. will print the English name of the month, such as Jan in terms of the given length [X].;
*/
%mend getWeekday;