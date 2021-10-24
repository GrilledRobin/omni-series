%macro rpt_InDateLstGetDescByKey(
	inDAT		=
	,descDAT	=
	,inKEY		=	C_KEY
	,inDATE		=	D_DATA
	,DescLst	=
	,descVAR	=	C_VAR
	,valVAR		=	C_VAL
	,inCOND		=
	,procLIB	=	WORK
	,outDAT		=
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to search in the Descriptive Information History for each													|
|	| required Descriptive Field within the given list of date.																			|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDAT		:	The dataset containing the KEY list for which to retrieve the Descriptive Information.								|
|	|descDAT	:	The dataset containing the Descriptive Information to lookup in.													|
|	|inKEY		:	The key field list to be searched for.																				|
|	|				 It should be the same key list as generating the Descriptive Information History.									|
|	|inDATE		:	The date field in the inDAT containing the Date attribute of each inKEY.											|
|	|DescLst	:	The Descriptive Field List to be searched in the Descriptive Information History.									|
|	|descVAR	:	The variable containing the name of the Descriptive Fields.															|
|	|				 It should be only one field existing in the Descriptive Information History.										|
|	|valVAR		:	The variable containing the values of the Descriptive Fields.														|
|	|				 It should be only one field existing in the Descriptive Information History.										|
|	|inCOND		:	The further conditions to filter the results.																		|
|	|				 This condition only affects the &inDAT., for &descDAT. only stands for reference.									|
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
|	|The output data has the same structure as the &descDAT. in terms of the given condition.											|
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
%if	%length(%qsysfunc(compress(&inDAT.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]Data of KEY list is not provided!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%sysfunc(exist(&inDAT.))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]Specified file [&inDAT.] does not exist.;
	%put	&Lohno.;
	%ErrMcr
%end;

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

%if	%length(%qsysfunc(compress(&inKEY.,%str( ))))	=	0	%then	%let	inKEY		=	C_KEY;
%*In case quotation signs are provided, we clean them up for system to add them back.;
%*This could prevent some unexpectable results.;
%let	DescLst	=	%sysfunc(compress(%nrbquote(&DescLst.),%str(%'%")));

%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))	=	0	%then	%let	procLIB		=	WORK;

%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]Output data is not specified!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*013.	Define the local environment.;
%local
	LkeyLst4SQL
	LkeyLst4SRT
	KEYi
	LfAllDesc
	DESCi
	PRXID
;
%*We only allow one SAS data variable by the verification below.;
%let	PRXID	=	%sysfunc(prxparse(/^[[:alpha:]_]\w{0%str(,)31}?$/i));
%let	LkeyLst4SQL	=;
%let	LkeyLst4SRT	=;

%*020.	Further verify the parameters.;
%*022.	Validate the Descriptive Fields to be searched for.;
%let	LfAllDesc	=	0;
%if	%length(%qsysfunc(compress(&DescLst.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No Descriptive Field is provided, system will search for all.;
	%let	LfAllDesc	=	1;
%end;

%*025.	Validate &descVAR..;
%if	%sysfunc(prxmatch(&PRXID.,&descVAR.))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]descVAR [&descVAR.] is not one valid SAS data field!;
	%put	&Lohno.;
	%ErrMcr
%end;
%*Verify its existence in the &descDAT.;
%if	%FS_VarExists(inDAT=&descDAT.,inFLD=&descVAR.)	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]descVAR [&descVAR.] does not exist in descDAT [&descDAT.]!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*026.	Validate &valVAR..;
%if	%sysfunc(prxmatch(&PRXID.,&valVAR.))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]valVAR [&valVAR.] is not one valid SAS data field!;
	%put	&Lohno.;
	%ErrMcr
%end;
%*Verify its existence in the &descDAT.;
%if	%FS_VarExists(inDAT=&descDAT.,inFLD=&valVAR.)	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]valVAR [&valVAR.] does not exist in descDAT [&descDAT.]!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*027.	Validate &inDATE..;
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
%*110.	Key list.;
%genvarlist(
	nstart	=	1
	,inlst	=	&inKEY.
	,nvarnm	=	LeKeyVar
	,nvarttl=	LnKeyVar
)
%do	KEYi=1	%to	&LnKeyVar.;
	%let	LkeyLst4SQL	=	&LkeyLst4SQL.,a.&&LeKeyVar&KEYi..;
	%let	LkeyLst4SRT	=	&LkeyLst4SRT.,&&LeKeyVar&KEYi..;
%end;
%let	LkeyLst4SQL	=	%qsubstr(%nrbquote(&LkeyLst4SQL.),2);
%let	LkeyLst4SRT	=	%qsubstr(%nrbquote(&LkeyLst4SRT.),2);

%*120.	Descriptive Field list.;
%if	&LfAllDesc.	=	0	%then %do;
	%genvarlist(
		nstart	=	1
		,inlst	=	&DescLst.
		,nvarnm	=	LeDescVar
		,nvarttl=	LnDescVar
	)
%end;

%*200.	Retrieve the list of records that matches the requirement.;
proc sql
	noprint
	threads
;
	create table %unquote(&outDAT.) as (
		select
			&LkeyLst4SQL.
			,a.&inDATE.
			,d.&descVAR.
			,d.&valVAR.
		from %unquote(&inDAT.)(
			%if	%length(%qsysfunc(compress(&inCOND.,%str( ))))	^=	0	%then %do;
				where=(&inCOND.)
			%end;
		) as a
		inner join %unquote(&descDAT.)(
			%if	&LfAllDesc.	=	0	%then %do;
				where=(
					&descVAR. in (
						%do	DESCi=1	%to	&LnDescVar.;
							"&&LeDescVar&DESCi.."
						%end;
					)
				)
			%end;
		) as d
			on	1
			%do	KEYi=1	%to	&LnKeyVar.;
				and	a.&&LeKeyVar&KEYi..	=	d.&&LeKeyVar&KEYi..
			%end;
				and	d.D_BGN	<=	a.&inDATE.	<=	d.D_END
	);
quit;

%*900.	Purge the memory.;
%*910.	Release the Regular Expression matching rules.;
%ReleasePRX:
%syscall prxfree(PRXID);

%EndOfProc:
%mend rpt_InDateLstGetDescByKey;