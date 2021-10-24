%macro getOBS4DATA(
	inDAT	=	_LAST_
	,outVAR	=
	,gMode	=	P
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro returns the number of observations in a data set,																		|
|	|or . if the data set does not exist or cannot be opened.																			|
|	|- It first opens the data set. An error message is returned																		|
|	| and processing stops if the dataset cannot be opened.																				|
|	|- It next checks the values of the data set attributes																				|
|	| ANOBS (does SAS know how many observations there are?) and																		|
|	| WHSTMT (is a where statement in effect?).																							|
|	|- If SAS knows the number of observations and there is no																			|
|	|  where clause, the value of the data set attribute NLOBS																			|
|	|  (number of logical observations) is returned.																					|
|	|- If SAS does not know the number of observations (perhaps																			|
|	|  this is a view or transport data set) or if a where clause																		|
|	|  is in effect, the macro iterates through the data set																			|
|	|  in order to count the number of observations.																					|
|	|The value returned is a whole number if the data set exists,																		|
|	| or a period (the default missing value) if the data set																			|
|	| cannot be opened.																													|
|	|This macro requires the data set information functions,																			|
|	|which are available in SAS version 6.09 and greater.																				|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDAT	:	The dataset to be verified																								|
|	|outVAR	:	The output macro variable name, which will contain the number of observations of the given dataset						|
|	|gMode	:	The mode to execute this macro, [F] represents Function Mode, while [P] represents Procedure Mode						|
|	|			[F] mode enables this macro to be executed anywhere in the program, with higher risk to slow down on large dataset		|
|	|			[P] mode restricts this macro to be executed parallel to [DATA] and [PROC] steps, with lower risk to slow down			|
|	|			 on large dataset																										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20010101		| Version |	1.00		| Updater/Creator |	Jack Hamilton, First Health									|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20130608		| Version |	1.01		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Modified a bit.																												|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170701		| Version |	1.02		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |CLOSE the data in macro facility for Function mode in the last option to retrieve the number of observations, rather than	|
|	|      |to close it at the end of the macro call.																					|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170718		| Version |	1.03		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |CLOSE the data at the end of the macro call.																				|
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
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*010.	Check parameters.;
%local
	L_mcrLABEL
	dsid
	anobs
	whstmt
	rc
	tmpVmcr
;
%let	L_mcrLABEL	=	&sysMacroName.;
%if	%length(%qsysfunc(compress(&inDAT.,%str( ))))	=	0	%then	%let	inDAT	=	_last_;
%let	inDAT	=	%qsysfunc(translate(&inDAT.,%str(%'),%str(%")));
%if	%length(%qsysfunc(compress(&outVAR.,%str( ))))	=	0	%then	%let	outVAR	=	tmpVmcr;
%*Valid value of &gMode. can only be: P, F or null;
%if	%qupcase(&gMode.)	^=	F	%then %do;
	%let	gMode	=	P;
%end;
%else %do;
	%let	gMode	=	F;
%end;
%let	&outVAR.	=	0;

%*100.	Retrieve observation.;
%let	DSID	=	%sysfunc(open(&inDAT.));
%if	&DSID.	=	0	%then %do;
	%put	%sysfunc(sysmsg());
	%goto	mexit;
%end;
%else %do;
	%let	anobs	=	%sysfunc(attrn(&DSID.,ANOBS));
	%let	whstmt	=	%sysfunc(attrn(&DSID.,WHSTMT));
%end;

%if	&anobs.	=	1	and	&whstmt.	=	0	%then %do;
	%let	&outVAR.	=	%sysfunc(attrn(&DSID.,NLOBS));
%end;
%else %do;
	%if	%sysfunc(getoption(msglevel))	=	I	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Observations in [&inDAT.] must be retrieved by iteration.;
	%end;
	%*100.	Below statements are for "function" usage,;
	%* for it can be used in anywhere including inside DATA step or PROC step.;
	%*However, it consumes much MORE time than the other solution.;
	%if	&gMode.	=	F	%then %do;
		%do	%while (%sysfunc(fetch(&DSID.)) = 0);
			%let	&outVAR.	=	%eval(&&&outVAR.. + 1);
		%end;
	%end;
	%else %do;
	%*200.	Below statements are for "procedure" usage,;
	%* for it cannot be used in DATA step or PROC step.;
	%*However, it consumes much LESS time than the other solution.;
		data _null_;
			dsid	=	open(%sysfunc(quote(&inDAT.,%str(%'))));
			do	while (fetch(dsid, 'noset') = 0);
				i + 1;
			end;
			call symputx("&outVAR.",i);
			rc	=	close(dsid);
			stop;
		run;
	%end;
%end;

%*Close the dataset.;
%let	rc	=	%sysfunc(close(&DSID.));

%*Below statement can only be used in "function" mode.;
%if	&gMode.	=	F	%then %do;
	&&&outVAR..
%end;

%MEXIT:
%mend getOBS4DATA;

/*
%*000.	Old method.;
data _NULL_;
	if	0	then	set	&inDAT.	nobs=tmpobs;
	call symput("&outVAR.",tmpobs);
	stop;
run;

For more information please find in below paper:
p095-26_getOBS4DATA.pdf
*/