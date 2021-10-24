/******************************************************************/
/*This macro creates a new data set which contains the same fields as the original one.    */
/*The new data set has its "datetime" fields as a "yyyy-mm-dd" string of each observation.*/
%macro CHGdt2STR(dsn1=,dat1=,dsn2=,dat2=);
	%if	"&dsn1"	^=	""	%then %let	dsn1=	&dsn1..;
	%if	"&dsn2"	^=	""	%then %let	dsn2=	&dsn2..;
	%let	TMPCHK=;
	PROC CONTENTS
		DATA=&dsn1.&dat1.
		NOPRINT
		OUT=_TEMP_(KEEP=
			NAME
			FORMAT
			LABEL
			VARNUM
		);
	RUN;

	DATA _tempshrnk_;
		SET _TEMP_;
		if FORMAT not in ("$","BEST","");
	RUN;

	PROC SQL noprint;
		SELECT NAME
		INTO :TMPCHK
		FROM _tempshrnk_;
	QUIT;
	%IF	"&TMPCHK"	=	""	%THEN %GOTO	EndWithNoChange;

	DATA _NULL_;
		SET _tempshrnk_ END=EOF;
		CALL SYMPUT('STRVAR'||(LEFT(PUT(_N_,5.))),UPCASE(trim(left(NAME))));
		CALL SYMPUT('STRLBL'||(LEFT(PUT(_N_,5.))),UPCASE(trim(left(LABEL))));
		IF EOF THEN CALL SYMPUT('STRTOTAL',LEFT(PUT(_N_,8.)));
	RUN;

	DATA &dat1._tmp(compress=yes);
		SET &dsn1.&dat1.;
		rename %renfld;
	RUN;

	DATA &dsn2.&dat2.(compress=yes);
		%addattri;
		SET &dat1._tmp;
		%up_date
		label %addlbl;
		DROP Prev_:;
	RUN;
	%GOTO	EndWithChange;

%EndWithNoChange:
	DATA &dsn2.&dat2.(compress=yes);
		SET &dsn1.&dat1.;
	RUN;
%EndWithChange:
%mend;

%macro renfld;
	%local	i;
	%DO i=1 %TO &STRTOTAL;
		&&STRVAR&i.=Prev_&&STRVAR&i..
	%END;
%mend;
%macro addattri;
	%local	i;
	%DO i=1 %TO &STRTOTAL;
		format &&STRVAR&i $10.;
		length &&STRVAR&i $ 10;
	%END;
%mend;
%macro up_date;
	%local	i;
	%DO i=1 %TO &STRTOTAL;
		&&STRVAR&i=put(Prev_&&STRVAR&i..,yymmddD10.);
		&&STRVAR&i=tranwrd(tranwrd(&&STRVAR&i,"S",""),".","");
	%END;
%mend;
%macro addlbl;
	%local	i;
	%DO i=1 %TO &STRTOTAL;
		&&STRVAR&i.=&&STRLBL&i..
	%END;
%mend;
