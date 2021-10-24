%macro stat_LorenzGini(
	inDAT		=
	,inVAR		=
	,outDAT		=
	,xLRNZ		=	r_xLorenz
	,yLRNZ		=	r_yLorenz
	,outGINI	=	G_Gini
	,procLIB	=	WORK
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to generate the variables of x-axis and y-axis of Lorenz Curve												|
|	| for the given variable as well as the final Gini Coefficient of it.																|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDAT		:	The input data.																										|
|	|inVAR		:	The field for which to create the Lorenz Curve.																		|
|	|outDAT		:	The output result which contains the 2 new variables of Lorenz Curve.												|
|	|outGINI	:	The output macro variable name containing the value of Gini Coefficient.											|
|	|procLIB	:	The working folder.																									|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20140609		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20140630		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Add escape function when the input data only have one record.																|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180311		| Version |	1.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180407		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |[1] Introduce the function [FS_ATTRC] to identify the library and the member name, rather than to process character string.	|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ErrMcr																															|
|	|	|ValidateDSNasStr																												|
|	|	|getOBS4DATA																													|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\FileSystem"																						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|FS_ATTRC																														|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*010.	Set parameters.;
%*011.	Identify current processing macro.;
%local
	L_mcrLABEL
	Lohno
;
%let	L_mcrLABEL	=	&sysMacroName.;
%let	Lohno		=	%str(E)RROR: [&L_mcrLABEL.]Process failed due to %str(e)rrors!;

%*012.	Handle the parameter buffer.;
%if	%length(%qsysfunc(compress(&inDAT.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]Source Data is not provided!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%sysfunc(exist(&inDAT.))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Specified file [&inDAT.] does not exist.;
	%goto	EndOfProc;
%end;

%if	%length(%qsysfunc(compress(&inVAR.,%str( ))))	=	0	%then	%let	inVAR	=	A_VAL;
%if	%length(%qsysfunc(compress(&xLRNZ.,%str( ))))	=	0	%then	%let	xLRNZ	=	r_xLorenz;
%if	%length(%qsysfunc(compress(&yLRNZ.,%str( ))))	=	0	%then	%let	yLRNZ	=	r_yLorenz;
%if	%length(%qsysfunc(compress(&outGINI.,%str( ))))	=	0	%then	%let	outGINI	=	G_Gini;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))	=	0	%then	%let	procLIB	=	WORK;

%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Output Data is omitted, hence the source data [&inDAT.] will be overwritten.;
	%*Retrieve the dataset name of the &inDAT. to prevent some issues when output.;
	%let	outDAT	=	%FS_ATTRC( inDAT = &inDAT. , inATTR = LIB ).%FS_ATTRC( inDAT = &inDAT. , inATTR = MEM );
%end;

%*013.	Define the local environment.;
%local
	LxLorenz
	LyLorenz
	LnOBSinput
;

%*020.	Further verify the parameters.;
%*021.	Verify the name of output data.;
%if	%ValidateDSNasStr(inSTR=&outDAT.,FUZZY=0)	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]System does not accept DS Options or other invalid characters as outDAT [&outDAT.]!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*091.	Check the number of observations of the input data.;
%let	LnOBSinput	=	0;
%getOBS4DATA(
	inDAT	=	&inDAT.
	,outVAR	=	LnOBSinput
)

%if	&LnOBSinput.	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No record is found in [&inDAT.]. No Lorenz analysis will be conducted.;
	%goto	EndOfProc;
%end;

%*100.	Create coordinate system for Lorenz Curve.;
%*110.	Retrieve the cumulative sum of all observations.;
proc sql
	noprint
;
	select
		put(count(1),32.)
		,put(sum(&inVAR.),best32.)
	into
		:LxLorenz
		,:LyLorenz
	from %unquote(&inDAT.)
	;
quit;
%let	LxLorenz	=	%sysfunc(strip(&LxLorenz.));
%let	LyLorenz	=	%sysfunc(strip(&LyLorenz.));

%*150.	Set the coordinates for Lorenz Curve.;
proc sort
	data=%unquote(&inDAT.)
	out=&procLIB..Gini_4Lorenz
;
	by &inVAR.;
run;
data %unquote(&outDAT.);
	%*200.	Set the source data.;
	set &procLIB..Gini_4Lorenz end=EOF;
	by &inVAR.;

	%*300.	Initialization.;
	retain
		gini_S_bgn
		gini_S_act
		tmp_cumsum
		0
	;
	format
		&xLRNZ.
		&yLRNZ.
		percent12.4
	;
	gini_arith	=	1;
	gini_S_ttl	=	0;

	%*301.	If only one record is found in the data, we set below values.;
	if	_N_	=	1	and	EOF	=	1	then do;
		%*100.	The Lorenz Curve only has one observation.;
		&xLRNZ.	=	1;
		&yLRNZ.	=	1;

		%*200.	Calculate the Gini Coefficient.;
		call symputx("&outGINI.", 0, "G");

		%*900.	Stop current data step.;
		stop;
	end;

	%*310.	This is for the calculation of each granular area among the observations.;
	if	_N_	=	1	or	EOF	=	1	then	gini_arith	=	0.5;

	%*400.	Create Lorenz Curve system.;
	%*410.	Cumulative value of observations.;
	tmp_cumsum	+	&inVAR.;

	%*420.	X-axis of Lorenz Curve represents the cumulative proportion of observations.;
	&xLRNZ.	=	_N_ / &LxLorenz.;

	%*430.	Y-axis of Lorenz Curve represents the cumulative proportion of value.;
	&yLRNZ.	=	tmp_cumsum / &LyLorenz.;

	%*440.	Prepare the necessity for the calculation of the area of Absolute Inequality.;
	if	_N_	=	1	then gini_S_bgn	=	&yLRNZ.;

	%*450.	Calculation of each granular area among the observations.;
	gini_S_act	+	( &yLRNZ. * gini_arith );

	%*800.	Finalize the calculation.;
	if	EOF	then do;
		%*100.	Calculate the area of Absolute Equality.;
		gini_S_ttl	=	0.5	*	( _N_ - 1 )	*	( gini_S_bgn + &yLRNZ. );

		%*200.	Calculate the Gini Coefficient.;
		call symputx("&outGINI.", ( gini_S_ttl - gini_S_act ) / gini_S_ttl, "G");
	end;
	drop
		tmp_cumsum
		gini_arith
		gini_S_bgn
		gini_S_act
		gini_S_ttl
	;
run;

%*900.	Purge the memory.;
%*910.	Release PRX utilities.;
%ReleasePRX:

%EndOfProc:
%mend stat_LorenzGini;