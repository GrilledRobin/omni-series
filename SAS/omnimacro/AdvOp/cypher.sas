%macro cypher(
	indat		=
	,outdat		=
	,orgCAT		=
	,newCAT		=
	,fldlst		=	_ALL_
	,procLIB	=	WORK
);
%*001.	Check the system options.;
%local	cMSTORED;
%let	cMSTORED	=	0;
%if	%sysfunc(getoption(MSTORED) ) = MSTORED	%then	%let	cMSTORED	=	1;
%if	"&cMSTORED."	=	"0"	%then %do;
	options	MSTORED;
%end;

%*005.	Check parameters.;
%if	"&fldlst."	=	""	%then	%let	fldlst	=	_ALL_;

%*010.	Retrieve the catalog for encryption and decryption.;
options sasmstore=&newCAT.;

%*100.	Retrieve the fields for the transcription.;
data &procLIB..forTranscription;
	set
		&indat.(
			firstobs=1
			obs=1
			keep=&fldlst.
		)
	;
run;

%*110.	Retrieve the field names for the transcription.;
PROC CONTENTS
	DATA=&procLIB..forTranscription
	NOPRINT
	OUT=&procLIB..forTranscription_col(
		KEEP=
			NAME
			VARNUM
			TYPE
		where=(
			TYPE	=	2
		)
	);
RUN;

proc sort data=&procLIB..forTranscription_col;
	by VARNUM;
run;
data _NULL_;
	set &procLIB..forTranscription_col end=EOF;
		by VARNUM;
	call symput("L_trnm"||cats(put(_N_,8.)),cats(NAME));
	if	EOF	then	call symput("L_trttl",cats(put(_N_,8.)));
run;

%*200.	Transcryption.;
data &outdat.(compress=yes);
	set &indat.;
	%do	TRi=1	%to	&L_trttl.;
		%text_enc(fld=&&L_trnm&TRi..);
	%end;
run;

%*990.	Restore the catalog for current processing environment.;
%if	"&cMSTORED."	=	"0"	%then %do;
	options	NOMSTORED;
%end;
%else %do;
	options sasmstore=&orgCAT.;
%end;
%mend cypher;

/*
This macro is for the encryption or decryption of the sensitive data.
By default, all character fields will be transcribed.

indat	:	The dataset whose character fields are to be transcribed.
outdat	:	The output dataset.
orgCAT	:	The original catalog library which was assigned before the invocation of this macro. (This can be empty if there was option "NOMSTORED")
newCAT	:	The catalog library storing the encryption and decryption macros.
fldlst	:	The list of the fields to be transcribed.
procLIB	:	The library assigned for current process.
*/