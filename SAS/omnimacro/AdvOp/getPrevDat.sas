%macro getPrevDat(
	indsn	=
	,indat	=
	,inday	=
	,inmth	=
	,inyear	=
	,outday	=G_prevday
	,outmth	=G_prevmth
	,outyear=G_prevyear
	,loopcnt=100
);
	%local
		L_cur_day
		L_cur_mth
		L_cur_year
		L_li
		L_fxi
		L_fxj
		L_fxk
		L_fxd
		L_fxm
		L_fxy
		L_strDate
	;

	data _NULL_;
		call symput("L_cur_day",trim(left(day(today()))));
		call symput("L_cur_mth",trim(left(month(today()))));
		call symput("L_cur_year",trim(left(year(today()))));
	run;
	%if	%bquote(&indsn.)	NE	%then %let	indsn	=	&indsn..;
	%if	%bquote(&inday.)	EQ	%then %let	inday	=	&L_cur_day.;
	%if	%bquote(&inmth.)	EQ	%then %let	inmth	=	&L_cur_mth.;
	%if	%bquote(&inyear.)	EQ	%then %let	inyear	=	&L_cur_year.;
	%if	%bquote(&loopcnt.)	EQ	%then %let	loopcnt	=	100;
	%DO %WHILE (%index(&inday.,0) = 1);
		%let	inday	=	%substr(&inday.,2);
	%END;
	%DO %WHILE (%index(&inmth.,0) = 1);
		%let	inmth	=	%substr(&inmth.,2);
	%END;
	/*Below statements are for defining the Local File eXist Date parameter*/
	%let	L_li	=	1;
	%let	L_fxi	=	%eval(&inday-1);
	%if	%bquote(&L_fxi.)	=	0	%then %do;
		%let	L_fxi	=	31;
		%if	%eval(&inmth.-1)	=	0	%then %do;
			%let	L_fxj	=	12;
			%let	L_fxk	=	%eval(&inyear.-1);
		%end;
		%else %do;
			%let	L_fxj	=	%eval(&inmth.-1);
			%let	L_fxk	=	&inyear.;
		%end;
	%end;
	%else %do;
		%let	L_fxj	=	&inmth.;
		%let	L_fxk	=	&inyear.;
	%end;
	%let	L_fxd	=	%substr(00&L_fxi,%length(00&L_fxi)-1);
	%let	L_fxm	=	%substr(00&L_fxj,%length(00&L_fxj)-1);
	%let	L_fxy	=	%substr(0000&L_fxk,%length(0000&L_fxk)-3);
	%let	L_strDate	=	&L_fxy.&L_fxm.&L_fxd.;
	%DO %WHILE (%sysfunc(exist(&indsn.&indat.&L_strDate))=0 and %eval(&loopcnt-&L_li)^=0);
		%if	%bquote(&L_fxi.)	^=	1	%then %do;
			%let	L_fxi	=	%eval(&L_fxi-1);
			%let	L_fxd	=	%substr(00&L_fxi,%length(00&L_fxi)-1);
		%end;
		%else %do;
			%let	L_fxi	=	31;
			%let	L_fxd	=	&L_fxi;
			%if	%bquote(&L_fxj.)	^=	1	%then %do;
				%let	L_fxj	=	%eval(&L_fxj-1);
			%end;
			%else %do;
				%let	L_fxj	=	12;
				%let	L_fxk	=	%eval(&L_fxk-1);
				%let	L_fxy	=	%substr(0000&L_fxk,%length(0000&L_fxk)-3);
			%end;
			%let	L_fxm	=	%substr(00&L_fxj,%length(00&L_fxj)-1);
		%end;
		%let	L_strDate	=	&L_fxy.&L_fxm.&L_fxd.;
		%let	L_li	=	%eval(&L_li+1);
	%END;
	%global	&outday.;
	%global	&outmth.;
	%global	&outyear.;
	%let	&outday.	=	&L_fxd.;
	%let	&outmth.	=	&L_fxm.;
	%let	&outyear.	=	&L_fxy.;
%mend;