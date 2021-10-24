%macro getTBLListBySTR(
	indsn		=
	,chkSTR		=
	,chkCONJ	=	and
	,NotSTR		=
	,notCONJ	=	and
	,LstNO		=	G_LstNO
	,LstELPrfx	=	G_LstEL
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro generates the dataset names as a list, with spaces between their names.													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|chkSTR		:	If given, then the dataset names like the conditions will be retrieved.												|
|	|NotSTR		:	If given, then the dataset names not like the conditions will be retrieved.											|
|	|LstNO		:	The number of found data names.																						|
|	|LstELPrfx	:	The prefix of the macro variables storing the found data names.														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20140331		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180310		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|getOBS4DATA																													|
|	|	|genvarlist																														|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%local
	chkCOND
	notCOND
	Ci
	Ni
	L_tmp_obsCHK
;
%if	%length(%qsysfunc(compress(&chkCONJ.,%str( ))))	=	0	%then	%let	chkCONJ	=	and;
%if	%length(%qsysfunc(compress(&notCONJ.,%str( ))))	=	0	%then	%let	notCONJ	=	and;

%global	&LstNO.;
%let	&LstNO.		=	0;

%let	chkCOND	=	;
%let	notCOND	=	;

%if	%length(%qsysfunc(compress(&chkSTR.,%str( ))))	^=	0	%then %do;
	%genvarlist(
		nstart=1
		,inlst=&chkSTR.
		,nvarnm=N_chkSTR
		,nvarttl=T_chkSTR
	)
	%do Ci=1 %to &T_chkSTR.;
		%let	chkCOND	=	&chkCOND. &chkCONJ. index(memname,upcase(%qsysfunc(quote(&&N_chkSTR&Ci..,%str(%'))))) > 0;
	%end;
	%let	chkCOND	=	%qsubstr(%superq(chkCOND),4);
%end;
%if	%length(%qsysfunc(compress(&NotSTR.,%str( ))))	^=	0	%then %do;
	%genvarlist(
		nstart=1
		,inlst=&NotSTR.
		,nvarnm=N_NotSTR
		,nvarttl=T_NotSTR
	)
	%do Ni=1 %to &T_NotSTR.;
		%let	notCOND	=	&notCOND. &notCONJ. index(memname,upcase(%qsysfunc(quote(&&N_NotSTR&Ni..,%str(%'))))) = 0;
	%end;
	%let	notCOND	=	%qsubstr(%superq(notCOND),5);
%end;

proc sql noprint;
	create table _TEMP_(where=(missing(memname)=0)) as (
		select memname
		from dictionary.members
		where compress(libname)	=	upcase(%sysfunc(quote(&indsn.,%str(%'))))
			and	memtype	=	"DATA"
		%if	%length(%qsysfunc(compress(&chkSTR.,%str( ))))	^=	0	%then %do;
			and	%unquote(&chkCOND.)
		%end;
		%if	%length(%qsysfunc(compress(&NotSTR.,%str( ))))	^=	0	%then %do;
			and	%unquote(&notCOND.)
		%end;
	);
quit;

%let	L_tmp_obsCHK	=	0;
%getOBS4DATA(
	inDAT	=	_TEMP_
	,outVAR	=	L_tmp_obsCHK
)

%*If there are observations found, we do further process;
%if	&L_tmp_obsCHK.	^=	0	%then %do;
	proc sort data=_TEMP_;
		by memname;
	run;
	DATA _NULL_;
		SET _TEMP_ END=EOF;
		CALL SYMPUTX(cats("&LstELPrfx.",_N_),UPCASE(memname),"G");
		IF EOF THEN CALL SYMPUTX("&LstNO.",_N_,"G");
	RUN;
%end;
%mend getTBLListBySTR;