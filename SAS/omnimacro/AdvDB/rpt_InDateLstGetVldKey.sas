%macro rpt_InDateLstGetVldKey(
	inDAT		=
	,inDATE		=	D_DATA
	,descDAT	=
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
|	| existed &outKEY. within the given Date List.																						|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDAT		:	The dataset containing the Date list for which to retrieve the Key list.											|
|	|inDATE		:	The date field in the inDAT containing the Date List.																|
|	|descDAT	:	The dataset containing the Descriptive Information to lookup in.													|
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
|	| Date |	20140414		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
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
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ErrMcr																															|
|	|	|genvarlist																														|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\FileSystem"																						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|FS_VarExists																													|
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
	%put	%str(E)RROR: [&L_mcrLABEL.]Descriptive History [&descDAT.] does not exist.;
	%put	&Lohno.;
	%ErrMcr
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
	PRXID
;
%*We only allow one SAS data variable by the verification below.;
%let	PRXID	=	%sysfunc(prxparse(/^[[:alpha:]_]\w{0%str(,)31}?$/i));
%let	LkeyLst4SQL	=;

%*020.	Further verify the parameters.;
%*025.	Validate &inDATE..;
%if	%sysfunc(prxmatch(&PRXID.,&inDATE.))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]inDATE [&inDATE.] is not one valid SAS data field!;
	%put	&Lohno.;
	%ErrMcr
%end;
%*Verify its existence in the &inDAT.;
%if	%FS_VarExists(inDAT=&inDAT.,inFLD=&inDATE.)	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]inDATE [&inDATE.] does not exist in inDAT [&inDAT.]!;
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
	%let	LkeyLst4SQL	=	&LkeyLst4SQL.,d.&&LeKeyVar&KEYi..;
%end;
%let	LkeyLst4SQL	=	%qsubstr(%nrbquote(&LkeyLst4SQL.),2);

%*200.	Retrieve the list of records that matches the requirement.;
proc sql
	noprint
	threads
;
	create table %unquote(&outDAT.) as (
		select distinct
			&LkeyLst4SQL.
			,a.&inDATE.
		from %unquote(&inDAT.) as a
		inner join %unquote(&descDAT.)(
			%if	%length(%qsysfunc(compress(&inCOND.,%str( ))))	^=	0	%then %do;
				where=(&inCOND.)
			%end;
		) as d
			on	d.D_BGN	<=	a.&inDATE.	<=	d.D_END
	);
quit;

%*900.	Purge the memory.;
%*910.	Release the Regular Expression matching rules.;
%ReleasePRX:
%syscall prxfree(PRXID);

%EndOfProc:
%mend rpt_InDateLstGetVldKey;