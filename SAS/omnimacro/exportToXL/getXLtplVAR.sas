%macro getXLtplVAR(inxlwb=,inxlws=,toxlws=,maxrow=,maxcol=,varhdr=,outdatlib=work,outdatnm=);
/*010.	Check the conditions for variable screening*/
	%if		"&toxlws." = ""	%then %let	toxlws	=	&inxlws.;
	%let	varclean=	%sysfunc(trim(%sysfunc(left(%sysfunc(compbl(&varhdr))))));
	%let	CCCC=1;
	%let	WWWW=%QSCAN(&varclean,&CCCC,%STR( ));
	%let	HDR1=%STR(&WWWW);
	%DO %WHILE(&WWWW NE);
		%let	CCCC=%EVAL(&CCCC+1);
		%let	WWWW=%QSCAN(&varclean,&CCCC,%STR( ));
		%let	HDR&CCCC=%STR(&WWWW);
	%END;
	%let	HDRTTL=%EVAL(&CCCC-1);

/*020.	Import the template file*/
	PROC IMPORT
			OUT			= tmp_getXLtplVAR
			DATAFILE	= "&inxlwb."
			DBMS		= EXCEL
			REPLACE
		;
		SHEET		= "&inxlws.$"; 
		GETNAMES	= NO;
		MIXED		= YES;
		SCANTEXT	= YES;
		USEDATE		= NO;
		SCANTIME	= NO;
	RUN;

	DATA _NULL_;
		SET tmp_getXLtplVAR END=EOF;
		IF EOF THEN CALL SYMPUT('VALN',LEFT(PUT(_N_,8.)));
	RUN;

	PROC CONTENTS
		DATA=tmp_getXLtplVAR
		NOPRINT
		OUT=_TEMP_(KEEP=
			NAME
			VARNUM
		);
	RUN;
	DATA _TEMP_;
		SET _TEMP_;
		NAME=UPCASE(TRIM(LEFT(NAME)));
	RUN;

	DATA _NULL_;
		SET _TEMP_ END=EOF;
		IF EOF THEN CALL SYMPUT('TOTAL',LEFT(PUT(_N_,8.)));
	RUN;

	%let	resiROW	=	%eval(&maxrow.-&VALN.);
	%let	resiCOL	=	%eval(&maxcol.-&TOTAL.);

	%if	"&resiROW." > "0" or "&resiCOL." > "0"	%then %do;
		%if	"&resiROW." > "0"	%then %do;
			data getXLtplVAR;
				%do inCOLi=1 %to &maxcol.;
					format	F&inCOLi.	$128.;
				%end;
				%do inCOLi=1 %to &maxcol.;
					length	F&inCOLi.	$	128.;
				%end;
				do i=1 to &resiROW.;
					%do midCOLi=1 %to &maxcol.;
						F&midCOLi.="FAKE_ROW";
					%end;
					output;
				end;
				drop i;
			run;

			data getXLtplVAR;
				set
					getXLtplVAR
					tmp_getXLtplVAR
					%if	"&resiCOL." > "0"	%then %do;
						(
							rename=(
								%do inCOLj=%eval(&maxcol.-&resiCOL.) %to 1 %by -1;
									F&inCOLj.=F%eval(&inCOLj.+&resiCOL.)
								%end;
							)
						)
					%end;
				;
			run;
		%end;
		%else %do;
			data getXLtplVAR;
				%do inCOLi=1 %to &maxcol.;
					format	F&inCOLi.	$128.;
				%end;
				%do inCOLi=1 %to &maxcol.;
					length	F&inCOLi.	$	128.;
				%end;
				set tmp_getXLtplVAR
					%if	"&resiCOL." > "0"	%then %do;
						(
							rename=(
								%do inCOLj=%eval(&maxcol.-&resiCOL.) %to 1 %by -1;
									F&inCOLj.=F%eval(&inCOLj.+&resiCOL.)
								%end;
							)
						)
					%end;
				;
			run;
		%end;
	%end;
	%else %do;
		data getXLtplVAR;
			set tmp_getXLtplVAR;
		run;
	%end;

	PROC CONTENTS
		DATA=getXLtplVAR
		NOPRINT
		OUT=_TEMP_(KEEP=
			NAME
			VARNUM
		);
	RUN;
	DATA _TEMP_;
		SET _TEMP_;
		NAME=UPCASE(TRIM(LEFT(NAME)));
	RUN;

	DATA _NULL_;
		SET _TEMP_ END=EOF;
		CALL SYMPUT('VARNM'||(LEFT(PUT(_N_,5.))),UPCASE(NAME));
		IF EOF THEN CALL SYMPUT('TOTAL',LEFT(PUT(_N_,8.)));
	RUN;

/*030.	Generate table storing the position information of each variable in the EXCEL file*/
	data tmp_outdat;
		retain Gvar varrown varcoln;
		informat	Gvar	$128.;
		format		Gvar	$128.;
		length		Gvar	$	128.;
		set getXLtplVAR;
		%do j=1 %to &HDRTTL;
			%do i=1 %to &TOTAL;
				if &&VARNM&i=:"&&HDR&j.." then do;
					Gvar	= upcase(&&VARNM&i);
					varrown	= put(_N_,5.);
					varcoln	= put(&i,5.);
					output;
				end;
				drop &&VARNM&i;
			%end;
		%end;
	run;

	/*We find whether there is any observation in the above dataset*/
	data _NULL_;
		set sashelp.vtable;
		if	libname=upcase("WORK")
			and	memname=upcase("tmp_outdat")
			and	memtype="DATA"
			and	typemem="DATA"
			then do;
			/*"nlobs" is the "Number of Logical Observations"*/
			call symput ("L_obsCHK",trim(left(nlobs)));
		end;
	run;

	%if	"&L_obsCHK"	^=	"0"	%then %do;
		data tmp_outdat;
			retain varInWS varToWS varIsFld;
			set tmp_outdat;
			varInWS	=	"&inxlws.";
			varToWS	=	"&toxlws.";
			if index(Gvar,"VAR") > 0 or index(Gvar,"FLD") > 0 then do;
				varIsFld	= 1;
			end;
			else varIsFld	= 0;
		run;

		proc datasets library=&outdatlib.;
			append
				base=&outdatnm.
				data=tmp_outdat
			;
		run;

		proc sort data=&outdatlib..&outdatnm.;
			by	Gvar;
		run;
	%end;

%mend;

/*
This macro retrieves all appointed field-variables from a given MS EXCEL template.
Its purpose is to fill proper values into proper fields in an EXCEL report.

parameters:
inxlwb	:	name of EXCEL workbook
inxlws	:	name of EXCEL worksheet
toxlws	:	the mark of the dedicated worksheet (This is stored for necessary utilization)
maxrow	:	the number of used rows in the original worksheet
maxcol	:	the number of used columns in the original worksheet
varhdr	:	the initial letters of the variables in EXCEL
outdatlib	:	library of the dataset storing the position information of each variable
outdatnm	:	name of the dataset storing the position information of each variable
*/