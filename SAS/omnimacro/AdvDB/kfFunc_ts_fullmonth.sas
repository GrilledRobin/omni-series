%macro kfFunc_ts_fullmonth(
	inKPICfg	=	src.CFG_KPI
	,mapper		=
	,inDate		=	%sysfunc(putn(%sysfunc(today()), yymmddN8.))
	,inClndrPfx	=	src.calendar
	,aggrVar	=	A_KPI_VAL
	,byVar		=
	,copyVar	=	_all_
	,genPHbyWD	=	1
	,funcAggr	=	CMEAN
	,procLIB	=	WORK
	,fDebug		=	0
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to standardize the generation of KPI datasets by minimize the calculation effort and consumption of system 	|
|	| resources.																														|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|[TERMINOLOGY]																														|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|[1] Naming: <K>PI <F>actory <FUNC>tion for <T>ime <S>eries by <M>onth-<T>o-<D>ate algorithm										|
|	|[2] <inKPICfg> MUST have these fields: <D_BGN>,<C_KPI_ID>,<F_KPI_INUSE>,<C_KPI_DAT_PATH>,<C_KPI_DAT_NAME>, as well as the one 		|
|	|     indicated by the provided <aggrVar>																							|
|	|[3] For meta information of <inKPICfg> please check in the Example as below														|
|	|[4] KPIs listed in the mapper (on both sides) MUST have been registered in <inKPICfg>, with their <D_BGN> set as the same for each	|
|	|     pair, indicating that the MTD calculation commences on the same date as when Daily KPI takes effect							|
|	|[5] Since <AggrByPeriod> does not verify <D_BGN>, please ensure NO DATA EXISTS for the registered KPIs before their respective		|
|	|     <D_BGN>; otherwise those existing datasets will be inadvertently involved during aggregation									|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|[FUNCTION]																															|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|[1] Only conduct aggregation on the last workday of a month, to eliminate unnecessary effort										|
|	|[2] Leverage the corresponding MTD result as Checking Period (see <AggrByPeriod>) in terms of <mapper_daily -> mapper_mtd> in the	|
|	|     provided data <mapper>																										|
|	|[3] Chain the mapping <mapper_daily -> mapper_mtd -> mapper_fm> to introduce the Daily KPIs into the Actual Calculation Period		|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|[SCENARIO]																															|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|[1] Calculate Full Month ANR of product holding balances along the time series, by leveraging Daily Balance on the last workday and|
|	|     its corresponding MTD ANR on the same date																					|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|[Required] Overall Process:																										|
|	|___________________________________________________________________________________________________________________________________|
|	|inKPICfg	:	The dataset that stores the full configuration of the KPI.															|
|	|				Default: [src.CFG_KPI]																								|
|	|mapper		:	Mapper from Daily KPI ID to Full Month KPI ID as a dataset with at least these fields:								|
|	|				['mapper_daily' ] Daily KPI ID																						|
|	|				['mapper_mtd'] MTD KPI ID																							|
|	|				['mapper_fm'] Full Month KPI ID																						|
|	|___________________________________________________________________________________________________________________________________|
|	|[Required] Options for dataset retrieval by the Calendar:																			|
|	|___________________________________________________________________________________________________________________________________|
|	|inDate		:	The date in format <yyyymmdd> indicating the last workday of a month, otherwise the process is skipped				|
|	|				Default: [today]																									|
|	|inClndrPfx	:	The prefix of the series of datasets that store the yearly calendars.												|
|	|				The naming convention is: [inClndrPfx<yyyy>].																		|
|	|___________________________________________________________________________________________________________________________________|
|	|[Required] Input dataset information: (Daily snapshot of database)																	|
|	|___________________________________________________________________________________________________________________________________|
|	|aggrVar	:	The variable in <inKPICfg> that represents the value to be applied by function [funcAggr].							|
|	|___________________________________________________________________________________________________________________________________|
|	|[Required] Grouping and Aggregation methods:																						|
|	|___________________________________________________________________________________________________________________________________|
|	|byVar		:	See definition in <AggrByPeriod>																					|
|	|copyVar	:	See definition in <AggrByPeriod>																					|
|	|genPHbyWD	:	See definition in <AggrByPeriod>																					|
|	|funcAggr	:	See definition in <AggrByPeriod>																					|
|	|___________________________________________________________________________________________________________________________________|
|	|[Required] Common Operations:																										|
|	|___________________________________________________________________________________________________________________________________|
|	|procLIB	:	The working library.																								|
|	|fDebug		:	The switch of Debug Mode. Valid values are [0] or [1].																|
|	|				Default: [0]																										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20231216		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
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
|	|	|getOBS4DATA																													|
|	|	|ErrMcr																															|
|	|	|getCOLbyStrPattern																												|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvDB"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|kfFunc_ts_mtd																													|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\Dates"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|getMthWithinPeriod																												|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\FileSystem"																						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|FS_getPathList4Lib																												|
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
%let	procLIB		=	%unquote(&procLIB.);

%if	%length(%qsysfunc(compress(&mapper.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.][mapper] is not provided!;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&inClndrPfx.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No Calendar data [inClndrPfx=] is specified! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%index( &inClndrPfx. , . )	=	0	%then %do;
	%let	inClndrPfx	=	work.&inClndrPfx.;
%end;

%if	%length(%qsysfunc(compress(&byVar.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.][byVar] is not provided!;
	%put	&Lohno.;
	%ErrMcr
%end;

%let	funcAggr	=	%upcase(&funcAggr.);
%if	%length(%qsysfunc(compress(&funcAggr.,%str( ))))	=	0	%then	%let	funcAggr	=	CMEAN;

%if	%length(%qsysfunc(compress(&aggrVar.,%str( ))))		=	0	%then	%let	aggrVar		=	A_KPI_VAL;
%if	%length(%qsysfunc(compress(&copyVar.,%str( ))))		=	0	%then	%let	copyVar		=	_all_;
%if	%length(%qsysfunc(compress(&inDate.,%str( ))))		=	0	%then	%let	inDate		=	%sysfunc(putn(%sysfunc(today()), yymmddN8.));
%if	%length(%qsysfunc(compress(&inKPICfg.,%str( ))))	=	0	%then	%let	inKPICfg	=	src.CFG_KPI;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))		=	0	%then	%let	procLIB		=	WORK;
%if	%length(%qsysfunc(compress(&fDebug.,%str( ))))		=	0	%then	%let	fDebug		=	0;
%if	&fDebug.^=	0	%then	%let	fDebug		=	1;

%*013.	Define the local environment.;
%local
	OptNotes	OptSource	OptSource2	OptMLogic	OptSymGen	OptMPrint	OptInOper
	fnm_MtoFM	rstFM		mtd_fr		mtd_to		dtBgn		dtEnd
	Fj			Mj
	rx_sfx		f_dtable
;
%let	fnm_MtoFM	=	map_MtoFM;
%*Quote: https://blogs.sas.com/content/sasdummy/2012/08/22/using-a-regular-expression-to-validate-a-sas-variable-name/ ;
%let	rx_sfx		=	%nrstr(s/&[a-z_]\w{0,31}\.?\s*$//ismx);
%let	dtBgn		=	%sysfunc(putn(%sysfunc(intnx(month, %sysfunc(inputn(&inDate., yymmdd10.)), 0, b)), yymmddN8.));
%let	dtEnd		=	%sysfunc(putn(%sysfunc(intnx(month, %sysfunc(inputn(&inDate., yymmdd10.)), 0, e)), yymmddN8.));

%*016.	Switch off the system options to reduce the LOG size.;
%let	OptNotes	=	%sysfunc(getoption( notes ));
%let	OptSource	=	%sysfunc(getoption( source ));
%let	OptSource2	=	%sysfunc(getoption( source2 ));
%let	OptMLogic	=	%sysfunc(getoption( mlogic ));
%let	OptSymGen	=	%sysfunc(getoption( symbolgen ));
%let	OptMPrint	=	%sysfunc(getoption( mprint ));
%let	OptInOper	=	%sysfunc(getoption( minoperator ));
%*Quote: https://support.sas.com/documentation/cdl/en/mcrolref/61885/HTML/default/viewer.htm#a003092012.htm ;
%*The default value of the system option [MINDELIMITER] is WHITE SPACE, given the option [MINOPERATOR] is on.;
options nonotes nosource nosource2 nomlogic nosymbolgen nomprint minoperator;

%*018.	Define the global environment.;
%getMthWithinPeriod(
	clnLIB		=	%scan(&inClndrPfx., 1, .)
	,clnPFX		=	%scan(&inClndrPfx., -1, .)
	,DateBgn	=	&dtBgn.
	,DateEnd	=	&dtEnd.
	,outPfx		=	GkftsFM
	,procLIB	=	&procLIB.
)
%FS_getPathList4Lib(
	inDSN		=	&procLIB.
	,outCNT		=	GnProc
	,outELpfx	=	GeProc
	,fDequote	=	1
)

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in classical SAS syntax colors.;
%macro dummy; %mend dummy;

%*099.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*100.	All input values.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [inKPICfg=%qsysfunc(compbl(&inKPICfg.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [mapper=%qsysfunc(compbl(&mapper.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [inDate=%qsysfunc(compbl(&inDate.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [inClndrPfx=%qsysfunc(compbl(&inClndrPfx.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [aggrVar=%qsysfunc(compbl(&aggrVar.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [byVar=%qsysfunc(compbl(&byVar.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [copyVar=%qsysfunc(compbl(&copyVar.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [genPHbyWD=%qsysfunc(compbl(&genPHbyWD.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [funcAggr=%qsysfunc(compbl(&funcAggr.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [procLIB=&procLIB.];
%end;

%*Skip the process if the provided date is not the last workday of a month.;
%if	%sysfunc(strip(&inDate.))	^=	&GkftsFMdn_LstWD.	%then %do;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.][inDate=%qsysfunc(compbl(&inDate.))] is not the last workday of month [%substr(&dtEnd., 1, 6)].;
		%put	%str(I)NFO: [&L_mcrLABEL.]Skip the process.;
	%end;
	%goto	EndOfProc;
%end;

%*100.	Prepare mapper.;
%*Quote: https://support.sas.com/resources/papers/proceedings/proceedings/forum2007/068-2007.pdf ;
%*110.	Define the formats.;
data &procLIB.._kftsfm_trns_pre;
	%*100.	Create necessary fields for <FORMAT Procedure>;
	length
		FMTNAME	$32
		START	LABEL	$256
		TYPE	HLO	$16
	;

	%*200.	Set the input mapper;
	set	%unquote(&mapper.) end=EOF;

	%*500.	Assign values;
	FMTNAME	=	%upcase(%sysfunc(quote($&fnm_MtoFM., %str(%'))));
	TYPE	=	'C';
	START	=	strip(mapper_mtd);
	LABEL	=	strip(mapper_fm);
	output;

	%*900.	Create additional format to handle the excessive KPI ID within <inKPICfg>;
	if	EOF	then do;
		HLO		=	'O';
		LABEL	=	'';
		output;
	end;
run;
%*Quote: https://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a002473471.htm ;
proc format
	cntlin=&procLIB.._kftsfm_trns_pre
	cntlout=&procLIB.._kftsfm_trns_fmtout
;
	select	$&fnm_MtoFM.;
run;

%*119.	Print the format.;
%*Quote: https://support.sas.com/documentation/cdl/en/proc/65145/HTML/default/viewer.htm#p1swd5d7lnugzgn1rv7pgzkjav4w.htm ;
%if	&fDebug.	=	1	%then %do;
	proc format fmtlib;
		select	$&fnm_MtoFM.;
		title	"[%str(I)NFO] Verify format [$&fnm_MtoFM.]";
	run;
%end;

%*200.	Minimize the KPI Config table for current process.;
data &procLIB.._kftsfm_cfg_kpi;
	%*100.	Retrieve the KPI Config table.;
	set
		%unquote(&inKPICfg.)(
			where=(
					D_BGN	<=	%sysfunc(inputn(&inDate., yymmdd10.))	<=	D_END
				and	F_KPI_INUSE	=	1
			)
		)
	;

	%*200.	Prepare to hash in the KPI lists.;
	if	0	then	set	%unquote(&mapper.)(keep=mapper_daily mapper_mtd mapper_fm);
	if	_N_	=	1	then do;
		dcl	hash	hDaily(dataset:"&mapper.");
		hDaily.DefineKey("mapper_daily");
		hDaily.DefineData("mapper_daily");
		hDaily.DefineDone();

		dcl	hash	hMTD(dataset:"&mapper.");
		hMTD.DefineKey("mapper_mtd");
		hMTD.DefineData("mapper_mtd");
		hMTD.DefineDone();

		dcl	hash	hFM(dataset:"&mapper.");
		hFM.DefineKey("mapper_fm");
		hFM.DefineData("mapper_fm");
		hFM.DefineDone();
	end;
	call missing(mapper_daily,mapper_mtd,mapper_fm);

	%*500.	Only keep the KPIs involved in this process.;
	if		(hDaily.check(key: C_KPI_ID)	=	0)
		or	(hMTD.check(key: C_KPI_ID)	=	0)
		or	(hFM.check(key: C_KPI_ID)	=	0)
	then do;
		output;
	end;

	%*900.	Purge.;
	drop
		mapper_daily
		mapper_mtd
		mapper_fm
	;
run;

%*300.	Determine the source datasets, as well as possible iterations, in terms of the provided KPI list.;
%*[ASSUMPTION];
%*[1] Date indicator of all included dataset names MUST BE a non-nested reference of a macro variable.;
%*[2] Location of above datasets CANNOT include reference of macro variables, although it is not verified.;
%*[3] The loops are nested: outer one is per <output-dataset>, inner one is per <input-dataset>, meaning that;
%*     if multiple KPIs are to output to the same dataset, we collect all inputs for the same iteration,;
%*     within which we loop the inputs to conduct aggregation.;
%*[4] Based on [3], the restriction is: NO KPI is allowed to store in separate datasets on the same date,;
%*     while multiple KPIs are allowed to store in the same dataset.;
%*310.	Only select involved KPIs.;
proc sql;
	create table &procLIB.._kftsfm_cfg_all_org as (
		select
			d.D_BGN as bgn_daily
			,d.C_KPI_ID as kpi_daily
			,upcase(d.C_KPI_DAT_PATH) as lib_daily
			,upcase(prxchange(%sysfunc(quote(%superq(rx_sfx), %str(%'))), -1, d.C_KPI_DAT_NAME)) as dat_daily
			,m.D_BGN as bgn_mtd
			,m.C_KPI_ID as kpi_mtd
			,upcase(m.C_KPI_DAT_PATH) as lib_mtd
			,upcase(prxchange(%sysfunc(quote(%superq(rx_sfx), %str(%'))), -1, m.C_KPI_DAT_NAME)) as dat_mtd
			,f.D_BGN as bgn_fm
			,f.C_KPI_ID as kpi_fm
			,upcase(f.C_KPI_DAT_PATH) as lib_fm
			,upcase(prxchange(%sysfunc(quote(%superq(rx_sfx), %str(%'))), -1, f.C_KPI_DAT_NAME)) as dat_fm
		from %unquote(&mapper.) as a
		inner join &procLIB.._kftsfm_cfg_kpi as d
			on	d.C_KPI_ID	=	a.mapper_daily
		inner join &procLIB.._kftsfm_cfg_kpi as m
			on	m.C_KPI_ID	=	a.mapper_mtd
		inner join &procLIB.._kftsfm_cfg_kpi as f
			on	f.C_KPI_ID	=	a.mapper_fm
	);
quit;

%*318.	Quit if there is no KPI involved due to configuration.;
%if	%getOBS4DATA(inDAT = &procLIB.._kftsfm_cfg_all_org, gMode = F)	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No KPI is involved, skip current process.;
	%goto	EndOfProc;
%end;

%*330.	Verify the begin date of both sides on the mapper.;
data &procLIB.._kftsfm_vfy_bgn;
	set
		&procLIB.._kftsfm_cfg_all_org(
			where=(
				bgn_mtd	>	bgn_fm
			)
		)
	;
	length	txt	$32767;
	txt	=	cats(
		'W','ARNING: [',symget('L_mcrLABEL'),']<D_BGN>'
		,'[',put(bgn_mtd, yymmddN8.),'] of KPI [',kpi_mtd,'] is later than <D_BGN>'
		,'[',put(bgn_fm, yymmddN8.),'] of KPI [',kpi_fm,']!'
	);
	put	txt;
run;
%if	%getOBS4DATA(inDAT = &procLIB.._kftsfm_vfy_bgn, gMode = F)	^=	0	%then %do;
	%ErrMcr
%end;

%*350.	Prepare the redirection of the MTD data to separate locations.;
%*[ASSUMPTION];
%*[1] Dependent macro <kfFunc_ts_mtd> creates data (here the MTD KPIs) to their respective locations.;
%*[2] After redirection, all perudo-full-month results will also be redirected, hence we can avoid modifying the database.;
%*[3] We set the redirected location to the last path assigned to <procLIB>;
%*[4] We set the names of the redirected MTD data by their naming counters to avoid conflicts.;
%*351.	Identify unique datasets to be redirected.;
proc sort
	data=&procLIB.._kftsfm_cfg_all_org
	out=&procLIB.._kftsfm_vfy_mtd
	nodupkey
;
	by
		lib_mtd
		dat_mtd
	;
run;
data &procLIB.._kftsfm_vfy_mtd;
	set &procLIB.._kftsfm_vfy_mtd;
	length
		lib_mtd_r	$32767
		dat_mtd_r	$64
	;
	lib_mtd_r	=	symget("GeProc&GnProc.");
	%*The names will be suffixed by data date string led by a digit, hence we add separater to avoid naming conflicts.;
	dat_mtd_r	=	cats('_kftsfm_redir',_N_,'_');
run;

%*355.	Tag the redirected locations to the original mappings.;
proc sql;
	create table &procLIB.._kftsfm_cfg_all as (
		select
			a.*
			,b.lib_mtd_r
			,b.dat_mtd_r
		from &procLIB.._kftsfm_cfg_all_org as a
		inner join &procLIB.._kftsfm_vfy_mtd as b
			on		a.lib_mtd	=	b.lib_mtd
				and	a.dat_mtd	=	b.dat_mtd
	);
quit;

%*389.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%put	%str(I)NFO: [&L_mcrLABEL.]Final KPI mapping is listed below:;
	data _NULL_;
		set &procLIB.._kftsfm_cfg_all;
		length	txt	$32767;
		txt	=	cats('I','NFO: [',symget('L_mcrLABEL'),'][',kpi_daily,'] -> [',kpi_mtd,'] -> [',kpi_fm,']');
		put	txt;
	run;
%end;

%*500.	Loop the calculation for the same output dataset per iteration.;
%*510.	Prepare the Full Month loop.;
proc sort
	data=&procLIB.._kftsfm_cfg_all
	out=&procLIB.._kftsfm_cfg_fm
	nodupkey
;
	by
		lib_fm
		dat_fm
	;
run;
data _NULL_;
	set	&procLIB.._kftsfm_cfg_fm end=EOF;
	%*[1] <K/C>ount of <A>ggregation in <F>ull-<M>onth factory as <DAT>asets for output as <F>ull-month loop;
	%*[2] <E>lement of <A>ggregation in <F>ull-<M>onth factory as <LIB>rary for output within <F>ull-month loop;
	%*[3] <E>lement of <A>ggregation in <F>ull-<M>onth factory as <DAT>aset for output within <F>ull-month loop;
	%*[4] <E>lement of <A>ggregation in <F>ull-<M>onth factory as <KPI> ID for output within <F>ull-month loop;
	call symputx(cats('eAFMLIBf', _N_), lib_fm, 'F');
	call symputx(cats('eAFMDATf', _N_), dat_fm, 'F');
	call symputx(cats('eAFMKPIf', _N_), kpi_fm, 'F');
	if	EOF	then do;
		call symputx('kAFMDATf', _N_, 'F');
	end;
run;

%*550.	Loop the process.;
%if	&fDebug.	=	1	%then %do;
	%put	%str(I)NFO: [&L_mcrLABEL.]Total number of Full Month datasets/iterations: [kAFMDATf=&kAFMDATf.];
%end;
%do Fj=1 %to &kAFMDATf.;
	%*010.	Local parameters.;
	%let	rstFM		=	&&eAFMDATf&Fj..%substr(&inDate., 1, 6);
	%let	f_dtable	=	0;

	%*019.	Debugger.;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.][Fj=&Fj.]Create data <%superq(rstFM)> in path: <%superq(eAFMLIBf&Fj.)>;
	%end;

	%*100.	Determine the loop for all MTD datasets.;
	%*Redirect MTD data when necessary to resemble the Full Month data as of the previous workday;
	%*110.	Subset the config table for current output dataset.;
	data &procLIB.._kftsfm_cfg_thisFj;
		set
			&procLIB.._kftsfm_cfg_all(
				where=(
						lib_fm	=	%sysfunc(quote(%superq(eAFMLIBf&Fj.), %str(%')))
					and	dat_fm	=	%sysfunc(quote(%superq(eAFMDATf&Fj.), %str(%')))
				)
			)
		;
	run;

	%*190.	Prepare the loop.;
	proc sort
		data=&procLIB.._kftsfm_cfg_thisFj
		out=&procLIB.._kftsfm_cfg_thisFj_in
		nodupkey
	;
		by
			lib_mtd
			dat_mtd
		;
	run;
	data _NULL_;
		set	&procLIB.._kftsfm_cfg_thisFj_in end=EOF;
		%*[1] <K/C>ount of <A>ggregation in <F>ull-<M>onth factory as <DAT>asets for output as <M>td loop;
		%*[2] <E>lement of <A>ggregation in <F>ull-<M>onth factory as <LIB>rary for output within <M>td loop;
		%*[3] <E>lement of <A>ggregation in <F>ull-<M>onth factory as <DAT>aset for output within <M>td loop;
		%*[4] <E>lement of <A>ggregation in <F>ull-<M>onth factory as <LIB>rary for output within <M>td loop as <R>edirection;
		%*[5] <E>lement of <A>ggregation in <F>ull-<M>onth factory as <DAT>aset for output within <M>td loop as <R>edirection;
		call symputx(cats('eAFMLIBm', _N_), lib_mtd, 'F');
		call symputx(cats('eAFMDATm', _N_), dat_mtd, 'F');
		call symputx(cats('eAFMLIBmr', _N_), lib_mtd_r, 'F');
		call symputx(cats('eAFMDATmr', _N_), dat_mtd_r, 'F');
		if	EOF	then do;
			call symputx('kAFMDATm', _N_, 'F');
		end;
	run;

	%*300.	Redirect the MTD data as of the last workday of current month, regardless of whether it is also the last calendar day.;
	%*[ASSUMPTION];
	%*[1] If it is the last calendar day, we just copy the redirected data to where the Full Month KPI locates with proper mapper.;
	%*[2] Otherwise, we tweak the KPI Config to redirect the <mapper_daily -> mapper_mtd> mapping as well, and then;
	%*     call the MTD macro to generate the pseudo full month MTD data in the redirected path, then copy the latter to where the;
	%*     Full Month KPI locates.;
	%*[3] For such reason, the MTD data as of the last workday, i.e. <inDate>, MUST exist, otherwise we raise an error.;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.][Fj=&Fj.]Total number of MTD datasets/iterations: [kAFMDATm=&kAFMDATm.];
	%end;
	%do Mj=1 %to &kAFMDATm.;
		%*010.	Local parameters.;
		%let	mtd_fr	=	&&eAFMDATm&Mj..&inDate.;
		%let	mtd_to	=	&&eAFMDATmr&Mj..&inDate.;

		%*019.	Debugger.;
		%if	&fDebug.	=	1	%then %do;
			%put	%str(I)NFO: [&L_mcrLABEL.][Fj=&Fj.][Mj=&Mj.]Directly copy data <&mtd_fr.> From path: <%superq(eAFMLIBm&Mj.)>;
			%put	%str(I)NFO: [&L_mcrLABEL.][Fj=&Fj.][Mj=&Mj.]To data <&mtd_to.> in path: <%superq(eAFMLIBmr&Mj.)>;
		%end;

		%*200.	Assign temporary libraries.;
		%*[ASSUMPTION];
		%*[1] <kffm_mr> refers to <procLIB> just as designed.;
		libname	kffm_m	%sysfunc(quote(%superq(eAFMLIBm&Mj.), %str(%')));
		libname	kffm_mr	%sysfunc(quote(%superq(eAFMLIBmr&Mj.), %str(%')));

		%*300.	Verify the existence of the input data to write correct message in the log.;
		%if	%sysfunc(exist(kffm_m.&mtd_fr.))	=	0	%then %do;
			%put	%str(W)ARNING: [&L_mcrLABEL.][Fj=&Fj.][Mj=&Mj.]<&mtd_fr.> does not exist in path: <%superq(eAFMLIBm&Mj.)>!;
			%ErrMcr
		%end;

		%*500.	Only retrieve the necessary MTD KPIs at current iteration.;
		proc sql;
			create table kffm_mr.&mtd_to. as (
				select a.*
				from kffm_m.&mtd_fr.(
					%*[ASSUMPTION];
					%*[1] We have to output the same fields as requested.;
					keep=
						C_KPI_ID
						&aggrVar.
						&byVar.
						&copyVar.
				) as a
				inner join &procLIB.._kftsfm_cfg_thisFj(
					where=(
							lib_mtd	=	%sysfunc(quote(%superq(eAFMLIBm&Mj.), %str(%')))
						and	dat_mtd	=	%sysfunc(quote(%superq(eAFMDATm&Mj.), %str(%')))
					)
				) as b
					on	a.C_KPI_ID	=	b.kpi_mtd
			);
		quit;

		%*800.	Search for the specific columns.;
		%getCOLbyStrPattern(
			inDAT		=	kffm_mr.&mtd_to.
			,inRegExp	=	%nrstr(^D_TABLE\s*$)
			,exclRegExp	=
			,outCNT		=	kdtable
			,outELpfx	=	edtable
		)
		%if	&kdtable.	=	1	%then %do;
			%let	f_dtable	=	1;
		%end;

		%*900.	Purge.;
		%*910.	De-assign the temporary library.;
		libname	kffm_m	clear;
		libname	kffm_mr	clear;

		%*999.	Debugger.;
		%if	&fDebug.	=	1	%then %do;
			%put	%str(I)NFO: [&L_mcrLABEL.][Fj=&Fj.][Mj=&Mj.]End iteration.;
		%end;
	%*End of MTD redirection;
	%end;

	%*500.	Create pseudo Full Month KPIs within the redirections.;
	%if	%qsysfunc(compbl(&inDate.))	=	&dtEnd.	%then %do;
		%if	&fDebug.	=	1	%then %do;
			%put	%str(I)NFO: [&L_mcrLABEL.][Fj=&Fj.][inDate=%qsysfunc(compbl(&inDate.))] is the last calendar day of month [%substr(&dtEnd., 1, 6)].;
			%put	%str(I)NFO: [&L_mcrLABEL.][Fj=&Fj.]Directly map the MTD KPIs to Full Month ones.;
		%end;
	%end;
	%else %do;
		%*010.	Declare the process.;
		%if	&fDebug.	=	1	%then %do;
			%put	%str(I)NFO: [&L_mcrLABEL.][Fj=&Fj.]Create pseudo Full Month KPIs within the redirections.;
		%end;

		%*100.	Tweak the KPI Config table, also by redirecting the MTD KPIs to above locations respectively.;
		data &procLIB.._kftsfm_cfg_redir;
			%*100.	Retrieve the KPI Config table.;
			set	&procLIB.._kftsfm_cfg_kpi;

			%*200.	Prepare to hash in the MTD KPI list.;
			if	0	then	set	&procLIB.._kftsfm_cfg_thisFj(keep=kpi_mtd lib_mtd_r dat_mtd_r);
			if	_N_	=	1	then do;
				dcl	hash	hKPI(dataset:"&procLIB.._kftsfm_cfg_thisFj");
				hKPI.DefineKey("kpi_mtd");
				hKPI.DefineData("lib_mtd_r","dat_mtd_r");
				hKPI.DefineDone();
			end;
			call missing(lib_mtd_r,dat_mtd_r);

			%*500.	Redirection.;
			_iorc_	=	hKPI.find(key: C_KPI_ID);
			if	_iorc_	=	0	then do;
				C_KPI_DAT_PATH	=	lib_mtd_r;
				C_KPI_DAT_NAME	=	dat_mtd_r;
			end;

			%*900.	Purge.;
			drop
				kpi_mtd
				lib_mtd_r
				dat_mtd_r
			;
		run;

		%*400.	Subset the mapper for current iteration.;
		data &procLIB.._kftsfm_mapper_thisFj;
			set
				%unquote(&mapper.)(
					where=(
						mapper_fm	=	%sysfunc(quote(%superq(eAFMKPIf&Fj.), %str(%')))
					)
				)
			;
		run;

		%*700.	Create pseudo Full Month KPIs.;
		%*[ASSUMPTION] The reason why we do not just call this macro on the last calendar day for the default <inKPICfg>;
		%*[1] If we do so, we at least need to call it EVERY WORKDAY DAY and create a series of dataset suffixed <inDate>.;
		%*[2] For most Business cases, Full Month KPIs only represent the fact as of the last calendar day, which means only 1 dataset is necessary.;
		%*[3] We aim to save the calculation effort on both technical and business purposes.;
		%kfFunc_ts_mtd(
			inKPICfg	=	&procLIB.._kftsfm_cfg_redir
			,mapper		=	&procLIB.._kftsfm_mapper_thisFj
			,inDate		=	&dtEnd.
			,inClndrPfx	=	&inClndrPfx.
			,aggrVar	=	&aggrVar.
			,byVar		=	&byVar.
			,copyVar	=	&copyVar.
			,genPHbyWD	=	&genPHbyWD.
			,funcAggr	=	&funcAggr.
			,procLIB	=	&procLIB.
			,fDebug		=	&fDebug.
		)

		%*800.	We will NOT verify whether <D_TABLE> exists for all involved datasets at this step.;
		%*[ASSUMPTION];
		%*[1] We have verified its existence when we redirect the MTD datasets for the last workday.;
		%*[2] If it does not exist in any among the MTD datasets as of the last workday, it MUST also not exist in any corresponding Daily KPIs.;
	%*End of pseudo Full Month data creation;
	%end;

	%*700.	Assign temporary library as output destination.;
	libname	kffm_f	%sysfunc(quote(%superq(eAFMLIBf&Fj.), %str(%')));

	%*800.	Set together all the redirected pseudo Full Month KPI datasets.;
	%*[ASSUMPTION];
	%*[1] All redirected data reside in <procLIB> just as designed.;
	data kffm_f.&rstFM.(compress=yes);
		%*100.	Set all sources.;
		set
		%do Mj=1 %to &kAFMDATm.;
			&procLIB..&&eAFMDATmr&Mj..&dtEnd.
		%end;
		;

		%*100.	Reset D_TABLE if it exists.;
		%*[ASSUMPTION];
		%*[1] This field could have different values due to above cases.;
		%*[2] We unify the value since we only process the data on the last workday of a month.;
		%if	&f_dtable.	=	1	%then %do;
			D_TABLE	=	input(%sysfunc(quote(&inDate., %str(%'))), yymmdd10.);
		%end;

		%*500.	Map the KPI ID to the Full Month representation.;
		C_KPI_ID	=	put(C_KPI_ID, $&fnm_MtoFM..);

		%*800.	Delete excessive data if there are additional KPIs.;
		%*Due to above process, there is actually no excessive KPI, but we ensure it.;
		if	missing(C_KPI_ID)	then	delete;
	run;

	%*900.	Purge.;
	%*910.	De-assign the temporary library.;
	libname	kffm_f	clear;

	%*999.	Debugger.;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.][Fj=&Fj.]End iteration.;
	%end;
%*End of Full Month loop;
%end;

%*900.	Purge.;

%EndOfProc:
%*Restore the system options.;
options
	&OptNotes.
	&OptSource.
	&OptSource2.
	&OptMLogic.
	&OptSymGen.
	&OptMPrint.
	&OptInOper.
;
%mend kfFunc_ts_fullmonth;

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
%*Load dependencies for <AggrByPeriod>;
options
	cmplib=_NULL_
;
proc FCmp
	outlib=work.fso.dates
;

	%usFUN_getOBS4DATA
	%usFUN_isWorkDay
	%usFUN_prevWorkday
	%usFUN_isWDorPredate

run;
quit;
options
	cmplib=work.fso
;

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

	%*Daily KPI;
	D_BGN			=	input('20160412', yymmdd10.);
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
	output;

	%*MTD KPI;
	D_BGN			=	input('20160412', yymmdd10.);
	D_END			=	mdy(12,31,2999);
	C_KPI_ID		=	"230100";
	C_KPI_SHORTNAME	=	"AVG_COUNTER";
	C_KPI_BIZNAME	=	"Mean of Counter of Days";
	C_KPI_DESC		=	strip(C_KPI_BIZNAME);
	C_PGM_PATH		=	"D:\SAS";
	C_PGM_NAME		=	"DBuse_GetTimeSeriesForKpi.sas";
	F_KPI_INUSE		=	1;
	C_KPI_FORMAT	=	"comma32.";
	C_KPI_DAT_PATH	=	strip(pathname("work"));
	C_KPI_DAT_NAME	=	'kpi_anr&c_date.';
	output;

	%*Full Month KPI;
	D_BGN			=	input('20160412', yymmdd10.);
	D_END			=	mdy(12,31,2999);
	C_KPI_ID		=	"330100";
	C_KPI_SHORTNAME	=	"FM_AVG_COUNTER";
	C_KPI_BIZNAME	=	"Mean of Counter of Days in Full Month";
	C_KPI_DESC		=	strip(C_KPI_BIZNAME);
	C_PGM_PATH		=	"D:\SAS";
	C_PGM_NAME		=	"DBuse_GetTimeSeriesForKpi.sas";
	F_KPI_INUSE		=	1;
	C_KPI_FORMAT	=	"comma32.";
	C_KPI_DAT_PATH	=	strip(pathname("work"));
	C_KPI_DAT_NAME	=	'kpi_anr_fm&c_mon.';
	output;
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

%*180.	Create mapper.;
data mapdat;
	length	mapper_daily	mapper_mtd	mapper_fm	$64;
	mapper_daily	=	'130100';	mapper_mtd	=	'230100';	mapper_fm	=	'330100';	output;
run;

%*200.	Create MTD KPI for 20160429.;
%kfFunc_ts_mtd(
	inKPICfg	=	CFG_KPI
	,mapper		=	mapdat
	,inDate		=	20160429
	,inClndrPfx	=	work.tmpCalendar
	,aggrVar	=	A_KPI_VAL
	,byVar		=	nc_cifno
	,copyVar	=	_all_
	,genPHbyWD	=	1
	,funcAggr	=	CMEAN
	,procLIB	=	WORK
	,fDebug		=	0
)

%*300.	Create Full Month KPI for 20160429 as it is also the last calendar day of the month.;
%kfFunc_ts_fullmonth(
	inKPICfg	=	CFG_KPI
	,mapper		=	mapdat
	,inDate		=	20160429
	,inClndrPfx	=	work.tmpCalendar
	,aggrVar	=	A_KPI_VAL
	,byVar		=	nc_cifno
	,copyVar	=	_all_
	,genPHbyWD	=	1
	,funcAggr	=	CMEAN
	,procLIB	=	WORK
	,fDebug		=	1
)
%put	%sysevalf((31.0689655172413 * 29 + 24 * 1) / 30);

/*-Notes- -End-*/