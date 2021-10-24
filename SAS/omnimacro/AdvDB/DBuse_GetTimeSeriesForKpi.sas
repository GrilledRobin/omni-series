%macro DBuse_GetTimeSeriesForKpi(
	inInfDat	=
	,InfDatOpt	=
	,SingleInf	=	N
	,MergeProc	=	SET
	,KeyOfMrg	=
	,SetAsBase	=	I
	,inKPICfg	=	src.CFG_KPI
	,dnDateList	=
	,outDAT		=
	,VarRecDate	=	D_RecDate
	,procLIB	=	WORK
	,fDebug		=	0
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to merge the KPI data to the given (descriptive) information data within the specified period of time, in	|
|	| terms of the predefined database structure.																						|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|[Required] Overall Process:																										|
|	|___________________________________________________________________________________________________________________________________|
|	|inInfDat	:	The dataset that stores the descriptive information at certain level (Acct level or Cust level).					|
|	|				[1] It MUST be provided if we need to [MergeProc=MERGE] the KPI datasets to Information Tables.						|
|	|				[2] It can be left as blank if we only need to [MergeProc=SET] the KPI datasets.									|
|	|				[3] This dataset name CANNOT be provided with dataset options.														|
|	|InfDatOpt	:	The Dataset Options to be applied to [inInfDat] before merging to the KPI datasets.									|
|	|				Tips: You can setup statements based on [LInfDatNm] to reference the dataset name when invoking [MergeProc].		|
|	|				      Examples: [%nrstr( %DropVarIfExists( inDAT = &LInfDatNm. , inFLDlst = D_TABLE , gMode = DSOPT ) )]			|
|	|SingleInf	:	Whether the Information Table is a single snapshot for merging to all Time Series datasets.							|
|	|				[Y] : Only one single Information Table is used to merge to all Time Series datasets.								|
|	|				[N] : The parameter [inInfDat] represents the Dataset Prefix, the naming convention is: [inInfDat<yyyymmdd>].		|
|	|				Default: [N]																										|
|	|MergeProc	:	The process to merge the datasets.																					|
|	|				[SET]   : Conduct the [DBuse_SetKPItoInf] process.																	|
|	|				[MERGE] : Conduct the [DBuse_MrgKPItoInf] process.																	|
|	|				Default: [SET]																										|
|	|KeyOfMrg	:	The list of Key field names during the merge. This requires that the same Key fields exist in both data.			|
|	|SetAsBase	:	The merging method indicating which of above data is set as the base during the merge. (case insensitive)			|
|	|				[I] : Use "Inf" data as the base to left join the "KPI" data.														|
|	|				[K] : Use "KPI" data as the base to left join the "Inf" data.														|
|	|				[B] : Use either data as the base to inner join the other, meaning "both".											|
|	|				[F] : Use either data as the base to full join the other, meaning "full".											|
|	|				Default: [I]																										|
|	|inKPICfg	:	The dataset that stores the full configuration of the KPI.															|
|	|				Default: [src.CFG_KPI]																								|
|	|___________________________________________________________________________________________________________________________________|
|	|[Required] Options for dataset retrieval by the Calendar:																			|
|	|___________________________________________________________________________________________________________________________________|
|	|dnDateList	:	The list of dates for the process to identify and retrieve the datasets.											|
|	|				The naming convention [dn] indicates that it is a date but shown as a numeric string [yyyymmdd].					|
|	|				This is also the naming convention of the suffix of the series of KPI datasets.										|
|	|___________________________________________________________________________________________________________________________________|
|	|[Required] Common Operations:																										|
|	|___________________________________________________________________________________________________________________________________|
|	|outDAT		:	The output result.																									|
|	|VarRecDate	:	The new variable created in the output result indicating the date on which the record represents.					|
|	|				Default: [D_RecDate]																								|
|	|procLIB	:	The working library.																								|
|	|fDebug		:	The switch of Debug Mode. Valid values are [0] or [1].																|
|	|				Default: [0]																										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20180406		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20190702		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Added a local file counter [LfCounter] to quit the program if none of the required KPI datasets exists.						|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Please find the attachments for examples.																							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|genvarlist																														|
|	|	|getOBS4DATA																													|
|	|	|ErrMcr																															|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvDB"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ForceMergeDats																													|
|	|	|DBuse_SetKPItoInf																												|
|	|	|DBuse_MrgKPItoInf																												|
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
%let	MergeProc	=	%qupcase(&MergeProc.);
%let	procLIB		=	%unquote(&procLIB.);

%if	%length(%qsysfunc(compress(&inInfDat.,%str( ))))	^=	0	%then %do;
	%if	%index( &inInfDat. , %str(%)) )	^=	0	%then %do;
		%put	%str(W)ARNING: [&L_mcrLABEL.]No Dataset Option is accepted for [inInfDat=%qsysfunc(compbl(&inInfDat.))]!;
		%put	%str(W)ARNING: [&L_mcrLABEL.]Please specify the Dataset Option in parameter [InfDatOpt]!;
		%put	&Lohno.;
		%ErrMcr
	%end;
%end;

%*Make sure we only retrieve the first character of the indicator.;
%if	%length(%qsysfunc(compress(&SingleInf.,%str( ))))	=	0	%then	%let	SingleInf	=	N;
%let	SingleInf	=	%upcase(%substr(&SingleInf.,1,1));
%if	&SingleInf.	^=	N	%then	%let	SingleInf	=	Y;

%if	%length(%qsysfunc(compress(&MergeProc.,%str( ))))	=	0	%then	%let	MergeProc	=	SET;
%if	&MergeProc.	^=	SET	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]The process to merge the datasets is NOT [SET], it is presumed to be [MERGE].;
	%let	MergeProc	=	MERGE;

	%if	%length(%qsysfunc(compress(&inInfDat.,%str( ))))	=	0	%then %do;
		%put	%str(W)ARNING: [&L_mcrLABEL.]Information Table [inInfDat=] is NOT provided!;
		%put	&Lohno.;
		%ErrMcr
	%end;
%end;

%if	%length(%qsysfunc(compress(&inInfDat.,%str( ))))	^=	0	%then %do;
	%if	%length(%qsysfunc(compress(&KeyOfMrg.,%str( ))))	=	0	%then %do;
		%put	%str(W)ARNING: [&L_mcrLABEL.]Class variable list [KeyOfMrg=] is NOT provided!;
		%put	&Lohno.;
		%ErrMcr
	%end;
%end;

%if	%length(%qsysfunc(compress(&SetAsBase.,%str( ))))	=	0	%then	%let	SetAsBase	=	I;
%*Make sure we only retrieve the first character of the indicator.;
%let	SetAsBase	=	%upcase(%substr(&SetAsBase.,1,1));

%if	%length(%qsysfunc(compress(&dnDateList.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No date [dnDateList=] is provided!;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&inKPICfg.,%str( ))))	=	0	%then	%let	inKPICfg	=	src.CFG_KPI;
%if	%length(%qsysfunc(compress(&VarRecDate.,%str( ))))	=	0	%then	%let	VarRecDate	=	D_RecDate;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))		=	0	%then	%let	procLIB		=	WORK;
%if	%length(%qsysfunc(compress(&fDebug.,%str( ))))		=	0	%then	%let	fDebug		=	0;
%if	&fDebug.^=	0	%then	%let	fDebug		=	1;

%*013.	Define the local environment.;
%local
	OptNotes	OptSource	OptSource2	OptMLogic	OptSymGen	OptMPrint	OptInOper
	LMergeMac	LinInfDat	LInfDatNm	LAllDats	LAddProc	LfCounter	LfExist
	Di
;
%if	&MergeProc.	=	SET	%then %do;
	%let	LMergeMac	=	DBuse_SetKPItoInf;
%end;
%else %do;
	%let	LMergeMac	=	DBuse_MrgKPItoInf;
%end;
%let	LinInfDat	=;
%let	LAllDats	=;
%let	LAddProc	=	format &VarRecDate. yymmddD10.%str(;);
%let	LfCounter	=	0;

%*016.	Switch off the system options to reduce the LOG size.;
%if %sysfunc(getoption( notes ))		=	NOTES		%then	%let	OptNotes	=	1;	%else	%let	OptNotes	=	0;
%if %sysfunc(getoption( source ))		=	SOURCE		%then	%let	OptSource	=	1;	%else	%let	OptSource	=	0;
%if %sysfunc(getoption( source2 ))		=	SOURCE2		%then	%let	OptSource2	=	1;	%else	%let	OptSource2	=	0;
%if %sysfunc(getoption( mlogic ))		=	MLOGIC		%then	%let	OptMLogic	=	1;	%else	%let	OptMLogic	=	0;
%if %sysfunc(getoption( symbolgen ))	=	SYMBOLGEN	%then	%let	OptSymGen	=	1;	%else	%let	OptSymGen	=	0;
%if %sysfunc(getoption( mprint ))		=	MPRINT		%then	%let	OptMPrint	=	1;	%else	%let	OptMPrint	=	0;
%if %sysfunc(getoption( minoperator ))	=	MINOPERATOR	%then	%let	OptInOper	=	1;	%else	%let	OptInOper	=	0;
%*The default value of the system option [MINDELIMITER] is WHITE SPACE, given the option [MINOPERATOR] is on.;
options nonotes nosource nosource2 nomlogic nosymbolgen nomprint minoperator;

%*018.	Define the global environment.;
%genvarlist(
	nstart		=	1
	,inlst		=	&dnDateList.
	,nvarnm		=	LeTSDates
	,nvarttl	=	LnTSDates
)
%global
	GtmpDate	GtmpMon
;

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in traditional SAS syntax colors.;
%macro dummy; %mend dummy;

%*099.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*100.	All input values.;
	%if	%length(%qsysfunc(compress(&inInfDat.,%str( ))))	=	0	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [inInfDat=];
	%end;
	%else %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [inInfDat=%qsysfunc(compbl(&inInfDat.))];
	%end;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [SingleInf=&SingleInf.];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [MergeProc=&MergeProc.];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [KeyOfMrg=%qsysfunc(compbl(&KeyOfMrg.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [SetAsBase=&SetAsBase.];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [inKPICfg=%qsysfunc(compbl(&inKPICfg.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [dnDateList=%qsysfunc(compbl(&dnDateList.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [outDAT=%qsysfunc(compbl(&outDAT.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [procLIB=&procLIB.];
%end;

%*100.	Identify all the required KPIs in the configuration table.;
%*110.	Prepare the formats to translate the macro variables as defined during the ETL of Data Mart Maintenance.;
proc format;
	invalue $GTSFKDates(min=512)
		's/&(L_curDate|c_date)\.?(?=\W|$)/&GtmpDate./ismx' 		(regexpe)	=	_same_
		's/&(L_curMon|L_m_PrevMth)\.?(?=\W|$)/&GtmpMon./ismx'	(regexpe)	=	_same_
	;
run;

%*115.	Test the format.;
%if	&fDebug.	=	1	%then %do;
	data a;
		length	a	$64;
		a	=	'lib&L_curMon..a&c_date.a&l_curdate';	output;
		a	=	'&L_curMon_aa&L_curdate.';	output;
		a	=	'cc&L_curMon.';	output;
		a	=	'dd&L_m_PrevMth';	output;
	run;

	data b;
		set a;
		length	b c	$64;
		b	=	input(input(a,$GTSFKDates.),$GTSFKDates.);
		c	=	input(a,$GTSFKDates.);
	run;
%end;

%*150.	Retrieve the KPI configuration table.;
data &procLIB..__GTSFK_Cfg_Kpi__;
	set %unquote(&inKPICfg.);

	%*Since there are 2 rules applied in the [INVALUE] format, we need to input the values twice.;
	C_KPI_DAT_PATH	=	input(input(C_KPI_DAT_PATH,$GTSFKDates512.),$GTSFKDates512.);
	C_KPI_DAT_NAME	=	input(input(C_KPI_DAT_NAME,$GTSFKDates512.),$GTSFKDates512.);
run;

%*280.	Quit the program if there is no KPI found in the configuration table.;
%if	%getOBS4DATA( inDAT = &procLIB..__GTSFK_Cfg_Kpi__ , gMode = F )	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Program does not find the required KPI ID in [inKPICfg=%qsysfunc(compbl(&inKPICfg.))]. Skip processing.;
	%goto	EndOfProc;
%end;

%*400.	Loop all dates to merge the Information Table [inInfDat] to the KPI datasets.;
%do Di=1 %to &LnTSDates.;
	%*100.	Set proper parameters for the functions to be called.;
	%if	%length(%qsysfunc(compress(&inInfDat.,%str( ))))	^=	0	%then %do;
		%if	&SingleInf.	=	Y	%then %do;
			%let	LinInfDat	=	&inInfDat.;
		%end;
		%else %do;
			%let	LinInfDat	=	%qsysfunc(strip(&inInfDat.))&&LeTSDates&Di..;
		%end;
	%end;
	%let	LInfDatNm	=	&LinInfDat.;
	%let	GtmpDate	=	&&LeTSDates&Di..;
	%let	GtmpMon		=	%substr(&GtmpDate.,1,6);

	%*200.	Add the Dataset Options to [inInfDat] if any.;
	%if	%length(%qsysfunc(compress(&InfDatOpt.,%str( ))))	^=	0	%then %do;
		%let	LinInfDat	=	&LinInfDat.%str(%()&InfDatOpt.%str(%));
	%end;

	%*500.	Call the predefined process to merge the datasets.;
	%&LMergeMac.(
		inInfDat	=	&LinInfDat.
		,KeyOfMrg	=	&KeyOfMrg.
		,SetAsBase	=	&SetAsBase.
		,inKPICfg	=	&procLIB..__GTSFK_Cfg_Kpi__
		,outDAT		=	&procLIB..__GTSFK_Dat&Di.__
		,procLIB	=	&procLIB.
		,fDebug		=	&fDebug.
	)

	%*510.	Flag the above result if it exists.;
	%let	LfExist	=	%sysfunc(exist( &procLIB..__GTSFK_Dat&Di.__ ));

	%*550.	Increment the file counter by 1 if above process creates the result.;
	%let	LfCounter	=	%eval( &LfCounter. + &LfExist. );

	%*599.	Skip current iteration if there is no output of above process.;
	%if	&LfExist.	=	0	%then	%goto	EndOfIter;

	%*700.	Add the current dataset name to a list.;
	%let	LAllDats	=	&LAllDats. &procLIB..__GTSFK_Dat&Di.__;

	%*800.	Add the statement to create new field [&VarRecDate.] to the final output dataset.;
	%*The reference of [_&Di.] is taken from the hidden feature of [ForceMergeDats], please check its document for more information.;
	%let	LAddProc	=	&LAddProc. if _&Di. then &VarRecDate. = %sysfunc(inputn(&GtmpDate.,yymmdd10.))%str(;);

	%*990.	Mark the end of current iteration.;
	%EndOfIter:
%end;

%*499.	Skip the program if none of the required KPI datasets exists.;
%if	&LfCounter.	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Program does not find any of the required KPI datasets. Skip processing.;
	%goto	EndOfProc;
%end;

%*800.	Set all datasets together as output.;
%ForceMergeDats(
	inDatLst	=	%nrbquote(&LAllDats.)
	,ModelDat	=
	,MixedType	=	N
	,MergeProc	=	SET
	,byVAR		=
	,addProc	=	%nrbquote(&LAddProc.)
	,outDAT		=	&outDAT.
	,fDebug		=	&fDebug.
)

%*900.	Purge.;

%EndOfProc:
%*Restore the system options.;
options
%if	&OptNotes.		=	1	%then %do;	NOTES		%end;	%else %do;	NONOTES			%end;
%if	&OptSource.		=	1	%then %do;	SOURCE		%end;	%else %do;	NOSOURCE		%end;
%if	&OptSource2.	=	1	%then %do;	SOURCE2		%end;	%else %do;	NOSOURCE2		%end;
%if	&OptMLogic.		=	1	%then %do;	MLOGIC		%end;	%else %do;	NOMLOGIC		%end;
%if	&OptSymGen.		=	1	%then %do;	SYMBOLGEN	%end;	%else %do;	NOSYMBOLGEN		%end;
%if	&OptMPrint.		=	1	%then %do;	MPRINT		%end;	%else %do;	NOMPRINT		%end;
%if	&OptInOper.		=	1	%then %do;	MINOPERATOR	%end;	%else %do;	NOMINOPERATOR	%end;
;
%mend DBuse_GetTimeSeriesForKpi;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvDB"
		"D:\SAS\omnimacro\AdvOp"
		"D:\SAS\omnimacro\Dates"
		"D:\SAS\omnimacro\FileSystem"
	)
	mautosource
;
libname	cln	"D:\SAS\Calendar";

%*050.	Setup a dummy macro [ErrMcr] to prevent the session to be bombed.;
%macro	ErrMcr;	%mend	ErrMcr;

%*100.	Data Preparation.;
%*101.	KPI Configuration Table.;
data CFG_KPI;
	format
		D_BGN			yymmddD10.
		D_END			yymmddD10.
		C_KPI_ID		$16.
		C_KPI_SHORTNAME	$32.
		C_KPI_BIZNAME	$128.
		C_KPI_DESC		$1024.
		C_PGM_PATH		$512.
		C_PGM_NAME		$128.
		F_KPI_INUSE		8.
		C_KPI_FORMAT	$32.
		C_KPI_DAT_PATH	$512.
		C_KPI_DAT_NAME	$32.
	;
	label
		D_BGN			=	"Begin Date"
		D_END			=	"End Date"
		C_KPI_ID		=	"KPI ID"
		C_KPI_SHORTNAME	=	"KPI Short Name"
		C_KPI_BIZNAME	=	"KPI Business Name"
		C_KPI_DESC		=	"KPI Description"
		C_PGM_PATH		=	"Path of the Program that creates current KPI"
		C_PGM_NAME		=	"Name of the Program that creates current KPI"
		F_KPI_INUSE		=	"Flag of whether current KPI is in use at present"
		C_KPI_FORMAT	=	"The SAS Format of the values of current KPI"
		C_KPI_DAT_PATH	=	"The Absolute Path of the Dataset storing current KPI"
		C_KPI_DAT_NAME	=	"The Name of the Dataset storing current KPI"
		
	;

	D_BGN			=	today();
	D_END			=	mdy(12,31,2999);
	C_KPI_ID		=	"130100";
	C_KPI_SHORTNAME	=	"K_COUNTER";
	C_KPI_BIZNAME	=	"Counter of Days";
	C_KPI_DESC		=	strip(C_KPI_BIZNAME);
	C_PGM_PATH		=	"D:\SAS";
	C_PGM_NAME		=	"DBuse_GetTimeSeriesForKpi.sas";
	F_KPI_INUSE		=	1;
	C_KPI_FORMAT	=	"comma32.";
	C_KPI_DAT_PATH	=	strip(pathname("work"));
	C_KPI_DAT_NAME	=	'kpi&c_date.';
run;

%*105.	Information Tables.;
data custinfo;
	format
		nc_cifno	$30.
		c_custid	$64.
		c_gender	$1.
	;
	nc_cifno	=	"001";
	c_custid	=	"123456789";
	c_gender	=	"F";
	output;
	nc_cifno	=	"0002";
	c_custid	=	"923456780";
	c_gender	=	"M";
	output;
run;
data acctinfo;
	format
		nc_cifno	$30.
		nc_acct_no	$64.
		d_maturity	yymmddD10.
	;
	nc_cifno	=	"001";
	nc_acct_no	=	"10250";
	d_maturity	=	mdy(4,1,2016);
	output;
	nc_cifno	=	"003";
	nc_acct_no	=	"10370";
	d_maturity	=	mdy(11,22,2017);
	output;
run;

%*110.	Create Calendar dataset.;
%crCalendar(
	inYEAR		=	2015
	,procLIB	=	WORK
	,outDAT		=	tmpCalendar2015
)
%crCalendar(
	inYEAR		=	2016
	,procLIB	=	WORK
	,outDAT		=	tmpCalendar2016
)

%*120.	Retrieve all date information for the period of 20160229 to 20160603.;
%getMthWithinPeriod(
	clnLIB		=	work
	,clnPFX		=	tmpCalendar
	,DateBgn	=	20160229
	,DateEnd	=	20160603
	,outPfx		=	GmwPrd
	,procLIB	=	WORK
)

%*130.	Create the test KPI tables.;
%macro genKpiDat;
%let	Lsplit	=	40;
%do Di=1 %to &Lsplit.;
	data kpi&&GmwPrddn_AllWD&Di..;
		format
			D_TABLE		yymmddD10.
			nc_cifno	$32.
			nc_acct_no	$64.
			C_KPI_ID	$16.
			A_KPI_VAL	best32.
		;
		D_TABLE		=	&&GmwPrdd_AllWD&Di..;
		nc_cifno	=	"001";
		nc_acct_no	=	"10250";
		C_KPI_ID	=	"130100";
		A_KPI_VAL	=	&Di.;
	run;
%end;
%do Di=%eval(&Lsplit. + 1) %to &GmwPrdkWkDay.;
	data kpi&&GmwPrddn_AllWD&Di..;
		format
			D_TABLE		yymmddD10.
			nc_cifno	$32.
			nc_acct_no	$64.
			C_KPI_ID	$16.
			A_KPI_VAL	best32.
		;
		D_TABLE		=	&&GmwPrdd_AllWD&Di..;
		nc_cifno	=	"001";
		nc_acct_no	=	"10250";
		C_KPI_ID	=	"130100";
		A_KPI_VAL	=	&GmwPrdkWkDay. - &Di.;
	run;
%end;
%mend genKpiDat;
%genKpiDat

%*150.	Retrieve all date information for the period of 20160901 to 20161201.;
%getMthWithinPeriod(
	clnLIB		=	work
	,clnPFX		=	tmpCalendar
	,DateBgn	=	20160901
	,DateEnd	=	20161201
	,outPfx		=	GCln
	,procLIB	=	WORK
)

%*170.	Create the test KPI tables.;
%macro genClnDat;
%let	Lsplit	=	45;
%do Di=1 %to &Lsplit.;
	data kpi&&GClndn_AllCD&Di..;
		format
			D_TABLE		yymmddD10.
			nc_cifno	$32.
			nc_acct_no	$64.
			C_KPI_ID	$16.
			A_KPI_VAL	best32.
		;
		D_TABLE		=	&&GClnd_AllCD&Di..;
		nc_cifno	=	"001";
		nc_acct_no	=	"10250";
		C_KPI_ID	=	"130100";
		A_KPI_VAL	=	&Di.;
	run;
%end;
%do Di=%eval(&Lsplit. + 1) %to &GClnkClnDay.;
	data kpi&&GClndn_AllCD&Di..;
		format
			D_TABLE		yymmddD10.
			nc_cifno	$32.
			nc_acct_no	$64.
			C_KPI_ID	$16.
			A_KPI_VAL	best32.
		;
		D_TABLE		=	&&GClnd_AllCD&Di..;
		nc_cifno	=	"001";
		nc_acct_no	=	"10250";
		C_KPI_ID	=	"130100";
		A_KPI_VAL	=	&GClnkClnDay. - &Di.;
	run;
%end;
%mend genClnDat;
%genClnDat

%*200.	Set all KPI datasets together with the [custinfo] for all Workdays from 20160401 to 20160531.;
%macro test1;
	%*100.	Retrieve the date list.;
	%getMthWithinPeriod(
		clnLIB		=	cln
		,clnPFX		=	calendar
		,DateBgn	=	20160401
		,DateEnd	=	20160531
		,outPfx		=	T1
		,procLIB	=	WORK
	)

	%*200.	Conduct the process.;
	%DBuse_GetTimeSeriesForKpi(
		inInfDat	=	custinfo
		,InfDatOpt	=
		,SingleInf	=	Y
		,MergeProc	=	SET
		,KeyOfMrg	=	nc_cifno
		,SetAsBase	=	K
		,inKPICfg	=	CFG_KPI
		,dnDateList	=	%do i=1 %to &T1kWkDay.;
							&&T1dn_AllWD&i..
						%end;
		,outDAT		=	test1
		,VarRecDate	=	D_RecDate
		,procLIB	=	WORK
		,fDebug		=	0
	)
%mend test1;
%test1

%*300.	Merge all KPI datasets together with the [acctinfo] for the end of all Trade Weeks from 20161001 to 20161115.;
%macro test2;
	%*100.	Retrieve the date list.;
	%getMthWithinPeriod(
		clnLIB		=	cln
		,clnPFX		=	calendar
		,DateBgn	=	20161001
		,DateEnd	=	20161115
		,outPfx		=	T2
		,procLIB	=	WORK
	)

	%*200.	Conduct the process.;
	%DBuse_GetTimeSeriesForKpi(
		inInfDat	=	acctinfo
		,InfDatOpt	=	%nrstr(
							%DropVarIfExists(
								inDAT		=	&LInfDatNm.
								,inFLDlst	=	D_TABLE
								,gMode		=	DSOPT
							)
						)
		,SingleInf	=	Y
		,MergeProc	=	MERGE
		,KeyOfMrg	=	%str(nc_cifno nc_acct_no)
		,SetAsBase	=	K
		,inKPICfg	=	CFG_KPI
		,dnDateList	=	%do i=1 %to &T2kTradeWeek.;
							&&T2dn_EndOfTW&i..
						%end;
		,outDAT		=	test2
		,VarRecDate	=	D_CheckDate
		,procLIB	=	WORK
		,fDebug		=	1
	)
%mend test2;
%test2

/*-Notes- -End-*/