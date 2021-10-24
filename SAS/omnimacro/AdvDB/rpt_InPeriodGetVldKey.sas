%macro rpt_InPeriodGetVldKey(
	descDAT		=
	,dateBGN	=	"&sysdate."d
	,dateEND	=	"&sysdate."d
	,inCOND		=
	,outKEY		=	C_KEY
	,procLIB	=	WORK
	,outDAT		=
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to search in the Descriptive Information History for the ever												|
|	| existed &outKEY. within the given period of date.																					|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|descDAT	:	The dataset containing the Descriptive Information to lookup in.													|
|	|dateBGN	:	The beginning of the period.																						|
|	|				 It should be a number instead of a string, such as 19721, or "01Dec2013"d.											|
|	|dateEND	:	The end of the period.																								|
|	|				 It should be a number instead of a string, such as 19721, or "01Dec2013"d.											|
|	|inCOND		:	The further conditions to filter the results.																		|
|	|				 It only applies to the Descriptive Information History.															|
|	|				 If any specific Descriptive Field will never be missing for all KEY variables,										|
|	|				  it will be very efficient to put it in the filtration condition in this procedure.								|
|	|outKEY		:	The key field list to be searched for.																				|
|	|				 It should be the same key list as generating the Descriptive Information History.									|
|	|procLIB	:	The processing library.																								|
|	|outDAT		:	The transposed result.																								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20140413		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180304		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|The output data contains below fields:																								|
|	|&outKEY.																															|
|	|D_BGN	:	The first date on or after &dateBGN. when the record is found.															|
|	|D_END	:	The last date on or before &dateEND. when the record is found.															|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ErrMcr																															|
|	|	|genvarlist																														|
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
%let	procLIB	=	%unquote(&procLIB.);
%if	%length(%qsysfunc(compress(&descDAT.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]Descriptive History is not provided!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%sysfunc(exist(&descDAT.))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]Descriptive History "&descDAT." does not exist.;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&dateBGN.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No Period Start is provided, it will be set as system date.;
	%let	dateBGN	=	"&sysdate."d;
%end;

%if	%length(%qsysfunc(compress(&dateEND.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No Period End is provided, it will be set as system date.;
	%let	dateEND	=	"&sysdate."d;
%end;

%if	%length(%qsysfunc(compress(&outKEY.,%str( ))))	=	0	%then	%let	outKEY		=	C_KEY;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))	=	0	%then	%let	procLIB		=	WORK;

%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]Output data is not specified!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*013.	Define the local environment.;
%local
	LkeyLst4SQL
	KEYi
;
%let	LkeyLst4SQL	=;

%*020.	Further verify the parameters.;
%*021.	Validate the given period of date.;
data _NULL_;
	call symputx("LfDateError",(&dateBGN. > &dateEND.),"L");
run;
%if	&LfDateError.	=	1	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]Period Start is later than Period End!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*100.	Prepare the SQL statement.;
%genvarlist(
	nstart	=	1
	,inlst	=	&outKEY.
	,nvarnm	=	LeKeyVar
	,nvarttl=	LnKeyVar
)
%do	KEYi=1	%to	&LnKeyVar.;
	%let	LkeyLst4SQL	=	&LkeyLst4SQL.,&&LeKeyVar&KEYi..;
%end;
%let	LkeyLst4SQL	=	%qsubstr(%nrbquote(&LkeyLst4SQL.),2);

%*200.	Retrieve the list of records that matches the requirement.;
proc sql
	noprint
	threads
;
	create table &procLIB..__keylst_4fix as (
		select
			&LkeyLst4SQL.
			,min(D_BGN) as D_BGN
			,max(D_END) as D_END
		from %unquote(&descDAT.)(
			%if	%length(%qsysfunc(compress(&inCOND.,%str( ))))	^=	0	%then %do;
				where=(&inCOND.)
			%end;
		)
		where	D_BGN	<=	&dateEND.
			and	D_END	>=	&dateBGN.
		group by
			&LkeyLst4SQL.
	);
quit;

%*800.	Fix the date by the given period.;
data %unquote(&outDAT.);
	set &procLIB..__keylst_4fix;
	format
		D_BGN
		D_END
		yymmddD10.
	;
	D_BGN	=	max(D_BGN,&dateBGN.);
	D_END	=	min(D_END,&dateEND.);
run;

%EndOfProc:
%mend rpt_InPeriodGetVldKey;