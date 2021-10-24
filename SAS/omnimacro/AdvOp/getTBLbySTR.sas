%macro getTBLbySTR(
	indsn=
	,chkSTR=
	,NotSTR=
	,fulldsn=G_ttldsn
	,fulltbl=G_ttltbl
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro generates the dataset names as a list, with spaces between their names.													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|chkSTR	:	If given, then the dataset names like the conditions will be retrieved.													|
|	|NotSTR	:	If given, then the dataset names not like the conditions will be retrieved.												|
|	|fulldsn	:	in a type of "aa.bb aa.cc".																							|
|	|fulltbl	:	in a type of "bb cc".																								|
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
		i
		j
		L_tmp_obsCHK
	;

	%global	&fulldsn.;
	%global	&fulltbl.;
	%let	&fulldsn.	=;
	%let	&fulltbl.	=;

	%if	%length(%qsysfunc(compress(&chkSTR.,%str( ))))	^=	0	%then %do;
		%genvarlist(
			nstart=1
			,inlst=&chkSTR.
			,nvarnm=N_chkSTR
			,nvarttl=T_chkSTR
		)
	%end;
	%if	%length(%qsysfunc(compress(&NotSTR.,%str( ))))	^=	0	%then %do;
		%genvarlist(
			nstart=1
			,inlst=&NotSTR.
			,nvarnm=N_NotSTR
			,nvarttl=T_NotSTR
		)
	%end;

	proc sql noprint;
		create table _TEMP_(where=(missing(memname)=0)) as (
			select *
			from dictionary.members
			where compress(libname)	=	upcase(%sysfunc(quote(&indsn.,%str(%'))))
				and	memtype	=	"DATA"
		%if	%length(%qsysfunc(compress(&chkSTR.,%str( ))))	^=	0	%then %do;
			%do i=1 %to &T_chkSTR.;
				and	index(memname,upcase(%sysfunc(quote(&&N_chkSTR&i..,%str(%'))))) > 0
			%end;
		%end;
		%if	%length(%qsysfunc(compress(&NotSTR.,%str( ))))	^=	0	%then %do;
			%do j=1 %to &T_NotSTR.;
				and	index(memname,upcase(%sysfunc(quote(&&N_NotSTR&j..,%str(%'))))) = 0
			%end;
		%end;
		);
	quit;

	%getOBS4DATA(
		inDAT	=	WORK._TEMP_
		,outVAR	=	L_tmp_obsCHK
	)

	/*If there are observations found, we do further process*/
	%if	&L_tmp_obsCHK.	^=	0	%then %do;
		proc sort data=_TEMP_;
			by memname;
		run;
		DATA _NULL_;
			SET _TEMP_ END=EOF;
			CALL SYMPUTX(CATS('TBLN',_N_),UPCASE(memname),"L");
			CALL SYMPUTX(CATS('LIBN',_N_),UPCASE(libname),"L");
			IF EOF THEN CALL SYMPUTX('TOTAL',_N_,"L");
		RUN;
		%do I=1 %TO &TOTAL.;
			%let	&fulldsn.	=	&&&fulldsn..%str( &&LIBN&I...&&TBLN&I..);
			%let	&fulltbl.	=	&&&fulltbl..%str( &&TBLN&I..);
		%end;
	%end;
%mend;