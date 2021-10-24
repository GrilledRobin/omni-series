%macro Freq2Table(indsn=,indat=,inchk=,varlist=,inwcond=,outdsn=,outdat=);
	%local
		varclean
		CCCC
		WWWW
		TOTAL
		outparm
		ELList
		VALLst
		i
		wherecond
	;
	%if	"&indsn"	^=	""	%then %let	indsn=	&indsn..;
	%if	"&outdsn"	^=	""	%then %let	outdsn=	&outdsn..;
	%let	varclean=	%sysfunc(translate(%STR(&varlist),%STR( ),%STR(*)));
	%let	varclean=	%sysfunc(trim(%sysfunc(left(%sysfunc(compbl(&varclean))))));
	%let	CCCC=1;
	%let	WWWW=%QSCAN(&varclean,&CCCC,%STR( ));
	%local	VAR1;
	%let	VAR1=%STR(&WWWW);
	%DO %WHILE(&WWWW NE);
		%let	CCCC=%EVAL(&CCCC+1);
		%let	WWWW=%QSCAN(&varclean,&CCCC,%STR( ));
		%local	VAR&CCCC;
		%let	VAR&CCCC=%STR(&WWWW);
	%END;
	%let	TOTAL=%EVAL(&CCCC-1);
	%if	&G_ELNO	LE	&TOTAL	%then %let	G_ELNO	=	&TOTAL;
	%if	&TOTAL=1 %then %let	outparm=	outcum;
			%else %let	outparm=	outpct;
	%let	ELList=;
	%let	VALLst=;
	%DO I=1 %TO &TOTAL;
		/*Here the first "||" is a part of &ELList*/
		%let	ELList	=	&ELList%str(||&&VAR&I);
		%let	VALLst	=	&VALLst%str(||%'||%'||trim(left(&&VAR&I)));
	%END;
	%let	ELList=%substr(&ELList,3);
	%let	VALLst=%substr(&VALLst,9);
	%let	wherecond=;
	%if	&inwcond.	NE	%then %do;
		/*Note: here the value of &inwcond needs to be quoted by a couple of single-quote signs*/
		%let	wherecond	=	%str(where	&inwcond.);
	%end;
/*	%put _all_;*/
	proc freq data=&indsn.&indat.&inchk.;
		tables &varlist / out=tmp1freq_&indat. noprint &outparm list missing;
		&wherecond.;
	run;
/*Here the macro CHGdt2STR needs to be called, for we have to convert the Date/Time format to real string.*/
	%CHGdt2STR(dsn1=,dat1=tmp1freq_&indat.,dsn2=,dat2=tmpfreq_&indat.)

	data &outdsn.&outdat.(compress=yes);
		format	C_ELList	$128.;
		format	C_TBLNAME	$64.;
		format	C_VALLst	$128.;
		%DO I=1 %TO &TOTAL;
			format	C_VAREL&I	$64.;
			format	C_VARVAL&I	$128.;
		%END;
		length	C_ELList	$ 128;
		length	C_TBLNAME	$ 64;
		length	C_VALLst	$ 128;
		%DO I=1 %TO &TOTAL;
			length	C_VAREL&I	$ 64;
			length	C_VARVAL&I	$ 128;
		%END;
		set tmpfreq_&indat.;
		C_ELList	=	"&ELList";
		C_VALLst	=	&VALLst;
		C_TBLNAME	=	"&indat";
		%DO I=1 %TO &TOTAL;
			C_VAREL&I	=	"&&VAR&I";
			C_VARVAL&I	=	trim(left(&&VAR&I));
		%END;
		drop &varclean.;
	run;
%mend;
/*
%Freq2Table(indsn=datasrc,indat=A_cust_comp20090107,varlist=c_segcode*c_package,outdsn=datasrc,outdat=freqALVL2);
*/