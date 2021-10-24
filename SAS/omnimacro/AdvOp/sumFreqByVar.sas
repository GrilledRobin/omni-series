%macro sumFreqByVar(
	indsn=
	,indat=
	,tmpdat=
	,byvar=
	,freqvar=
	,outdat=
);
proc sort
	data=&indsn..&indat.
	out=&tmpdat.
	;
		by &byvar.;
run;

proc means
	data=&tmpdat.
	sum
	noprint
	;
		by &byvar.;
	var &freqvar.;
	output
		out=&outdat.(
			compress=yes
		)
		sum=
	;
run;
%mend sumFreqByVar;

/*This macro will help summarize the "freqvar" by the class of "byvar" and generate a table like below:
	c_rng_age		f_base		f_tgt		f_rsp
-------------------------------------------------------------
	<35				78433		1219		737
	35-40			29528		2552		1505
	41-45			17787		2319		1430
	>45				40958		2233		1344
-------------------------------------------------------------

*/