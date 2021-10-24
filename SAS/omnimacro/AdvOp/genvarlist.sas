%macro genvarlist(nstart=,inlst=,nvarnm=,nvarttl=);
	%local
		BBBB
		VVVV
	;

	%if	%bquote(&nvarnm.)	EQ	%then %let	nvarnm	=	NLST;
	%if	%bquote(&nvarttl.)	EQ	%then %let	nvarttl	=	LTOTAL;
	%if	%sysfunc(compress(&nstart.))=	%then %let	nstart	=	1;
	%GLOBAL	Gstart;
	%GLOBAL	&nvarnm.&nstart.;
	%GLOBAL	&nvarttl.;
	%let	Gstart	=	&nstart.;
	%let	lstclean=	%sysfunc(compbl(&inlst.));
	%let	BBBB=1;
	%let	VVVV=%QSCAN(%nrbquote(&lstclean.),&BBBB.,%STR( ));
	%let	&nvarnm.&nstart.=%qsubstr(&VVVV.,1);
	%*I do not know why I have to use %substr here! but this will prevent some field-creation problem during data step and proc sql.;
	%DO %WHILE(&VVVV. NE);
		%let	BBBB=%EVAL(&BBBB.+1);
		%let	VVVV=%QSCAN(%nrbquote(&lstclean.),&BBBB.,%STR( ));
		%if	&VVVV.	EQ	%then	%goto	endLoop;
		%GLOBAL	&nvarnm.%eval(&nstart.+&BBBB.-1);
		%let	&nvarnm.%eval(&nstart.+&BBBB.-1)=%qsubstr(&VVVV.,1);
	%END;
	%endLoop:
	%let	&nvarttl.=%EVAL(&nstart.+&BBBB.-2);
%mend;

/*
This macro generates a list of consecutive macro variables containing each element in the given character string;
if &nstart=1 and &inlst contains 8 elements;
	then the macro variables will be NLST1-8;
		the total element number is &LTOTAL=8;
*/