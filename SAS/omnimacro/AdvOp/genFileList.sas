%macro genFileList(
	inlst=
	,outEL=NLST
	,outTTL=LTOTAL
	,absDIR=1
);
	%local
		tmpLST
		tmplen
		LSTRi
		LDIRt
		chkLST
	;

	%if	%bquote(&outEL)		EQ		%then %let	outEL	=	NLST;
	%if	%bquote(&outTTL)	EQ		%then %let	outTTL	=	LTOTAL;
	%if	%bquote(&absDIR)	^=	0	%then %let	absDIR	=	1;
	%GLOBAL	&outTTL;

	%if	%bquote(&absDIR.)	EQ	%then %do;
		%let	absDIR	=	1;
	%end;
	%if	%bquote(&absDIR.)	=	1	%then %do;
		%let	tmpLST	=	&inlst.;
		%let	tmplen	=	%length(%superq(tmpLST));
		%do	%while	(&tmplen.	>	0);
			%let	LSTRi	=	0;
			%let	LDIRt	=	0;
			%let	chkLST	=	%substr(%superq(tmpLST),%length(%superq(tmpLST)));
			%do	%until	(%index(&chkLST.,%str(:))	=	2	or	&LSTRi.	=	&tmplen.);
				%let	chkLST	=	%substr(%superq(tmpLST),%eval(%length(%superq(tmpLST))-&LSTRi.));
				%let	LSTRi	=	%eval(&LSTRi.+1);
			%end;
			%if	%index(%superq(chkLST),%str(:))	=	2	%then %do;
				%let	LDIRt			=	%eval(&LDIRt.+1);
				%global	&outEL.&LDIRt.;
				%let	&outEL.&LDIRt.	=	&chkLST.;
			%end;

			%let	tmpLST	=	%sysfunc(tranwrd(%superq(tmpLST),%superq(chkLST),%str( )));
			%let	tmplen	=	%length(%superq(tmpLST));
		%end;
	%*end of %bquote(&absDIR.)	=	1;
	%end;
	%else %do;
		%let	tmpLST	=	%sysfunc(compbl(%superq(inlst)));
		%let	tmplen	=	%length(%superq(tmpLST));
		%let	LSTRi	=	1;
		%let	chkLST	=	%QSCAN(%superq(tmpLST),&LSTRi.,%STR( ));
		%global	&outEL.&LSTRi.;
		%let	&outEL.&LSTRi.	=	&chkLST.;
		%DO %WHILE	(%superq(chkLST) NE);
			%let	LSTRi	=	%EVAL(&LSTRi.+1);
			%let	chkLST	=	%QSCAN(%superq(tmpLST),&LSTRi.,%STR( ));
			%global	&outEL.&LSTRi.;
			%let	&outEL.&LSTRi.	=	&chkLST.;
		%END;
		%let	LDIRt	=	%EVAL(&LSTRi.-1);
	%end;
	%let	&outTTL.	=	&LDIRt.;
%mend genFileList;