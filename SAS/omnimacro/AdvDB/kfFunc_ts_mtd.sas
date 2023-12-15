%macro kfFunc_ts_mtd(
	inKPICfg	=	src.CFG_KPI
	,mapDtoMTD	=
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
|	|[1] Map the MTD aggregation of KPIs listed on the left side of <mapDtoMTD> to those on the right side of it						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|[SCENARIO]																															|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|[1] Calculate MTD ANR of product holding balances along the time series, by recognizing the data on each weekend as the same as	|
|	|     its previous workday																											|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|[HOW TO]																															|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|[1] Create the mapper in MS EXCEL: ="'"&A1&"'"&CHAR(9)&"="&CHAR(9)&"'"&B1&"'"&CHAR(9)&"%*"&C1&";"									|
|	|    [1] <A1> is filled with Daily KPI ID																							|
|	|    [2] <B1> is filled with MTD KPI ID																								|
|	|    [3] <C1> is filled with MTD KPI Description (Act as SAS remarks in macro facility)												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|[Required] Overall Process:																										|
|	|___________________________________________________________________________________________________________________________________|
|	|inKPICfg	:	The dataset that stores the full configuration of the KPI.															|
|	|				Default: [src.CFG_KPI]																								|
|	|mapDtoMTD	:	Mapper from Daily KPI ID to MTD KPI ID as a dataset with at least these fields: ['mapper_in','mapper_out']			|
|	|				['mapper_in' ] Daily KPI ID																							|
|	|				['mapper_out'] MTD KPI ID																							|
|	|___________________________________________________________________________________________________________________________________|
|	|[Required] Options for dataset retrieval by the Calendar:																			|
|	|___________________________________________________________________________________________________________________________________|
|	|inDate		:	The date in format <yyyymmdd> indicating the date to which MTD is calculated										|
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
|	| Date |	20231210		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20231213		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |[1] Distinguish the interim datasets to avoid unexpected results															|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20231215		| Version |	1.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |[1] Fix a bug by removing <%goto> statements within <%do> loops																|
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
|	|	|AggrByPeriod																													|
|	|	|DBuse_GetTimeSeriesForKpi																										|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\Dates"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|getMthWithinPeriod																												|
|	|	|PrevWorkDateOf																													|
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

%if	%length(%qsysfunc(compress(&mapDtoMTD.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.][mapDtoMTD] is not provided!;
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
	fnm_DtoMTD	rstIter		byInt		dtBgn		chknm		intpfx
	Oj			Ij
	d_ChkEnd	dnChkEnd	f_chkEnd
	prx_sfx		f_dtable
;
%let	fnm_DtoMTD	=	map_DtoMTD;
%*Quote: https://blogs.sas.com/content/sasdummy/2012/08/22/using-a-regular-expression-to-validate-a-sas-variable-name/ ;
%let	prx_sfx		=	%nrstr(s/&[a-z_]\w{0,31}\.?\s*$//ismx);
%let	byInt		=	%unquote(&byVar. C_KPI_ID);
%let	dtBgn		=	%sysfunc(putn(%sysfunc(intnx(month, %sysfunc(inputn(&inDate., yymmdd10.)), 0, b)), yymmddN8.));

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
	,DateEnd	=	&inDate.
	,outPfx		=	GkftsMTD
	,procLIB	=	&procLIB.
)

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in classical SAS syntax colors.;
%macro dummy; %mend dummy;

%*040.	Combine the calendar data of the whole period starting from the previous year of <dtBgn> to <inDate>.;
%*041.	Combine the data.;
data &procLIB.._kftsmtd_Clndr;
	set
	%do Yi=%eval( %substr( &dtBgn. , 1 , 4 ) - 1 ) %to %substr( &inDate. , 1 , 4 );
		%if	%sysfunc(exist( &inClndrPfx.&Yi. ))	%then %do;
			&inClndrPfx.&Yi.
		%end;
	%end;
	;
run;

%*045.	Ensure there is no duplicated date.;
proc sort
	data=&procLIB.._kftsmtd_Clndr
	nodupkey
;
	by	D_DATE;
run;

%*050.	Determine [d_ChkEnd] by the implication of [genPHbyWD].;
%if	&genPHbyWD.	=	1	%then %do;
	%let	d_ChkEnd	=	%PrevWorkDateOf( inDATE = %sysfunc(inputn(&inDate., yymmdd10.)) , inCalendar = &procLIB.._kftsmtd_Clndr );
%end;
%else %do;
	%let	d_ChkEnd	=	%eval( %sysfunc(inputn(&inDate., yymmdd10.)) - 1 );
%end;
%let	dnChkEnd	=	%sysfunc(putn( &d_ChkEnd. , yymmddN8. ));

%*099.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*100.	All input values.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [inKPICfg=%qsysfunc(compbl(&inKPICfg.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [mapDtoMTD=%qsysfunc(compbl(&mapDtoMTD.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [inDate=%qsysfunc(compbl(&inDate.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [inClndrPfx=%qsysfunc(compbl(&inClndrPfx.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [aggrVar=%qsysfunc(compbl(&aggrVar.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [byVar=%qsysfunc(compbl(&byVar.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [copyVar=%qsysfunc(compbl(&copyVar.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [genPHbyWD=%qsysfunc(compbl(&genPHbyWD.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [funcAggr=%qsysfunc(compbl(&funcAggr.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [procLIB=&procLIB.];

	%*500.	Local variables.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Local variables: [dnChkEnd=&dnChkEnd.];
%end;

%*100.	Prepare mapper.;
%*Quote: https://support.sas.com/resources/papers/proceedings/proceedings/forum2007/068-2007.pdf ;
%*110.	Define the formats.;
data &procLIB.._kftsmtd_trns_pre;
	%*100.	Create necessary fields for <FORMAT Procedure>;
	length
		FMTNAME	$32
		START	LABEL	$256
		TYPE	HLO	$16
	;

	%*200.	Set the input mapper;
	set	%unquote(&mapDtoMTD.) end=EOF;

	%*500.	Assign values;
	FMTNAME	=	%upcase(%sysfunc(quote($&fnm_DtoMTD., %str(%'))));
	TYPE	=	'C';
	START	=	strip(mapper_in);
	LABEL	=	strip(mapper_out);
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
	cntlin=&procLIB.._kftsmtd_trns_pre
	cntlout=&procLIB.._kftsmtd_trns_fmtout
;
	select	$&fnm_DtoMTD.;
run;

%*119.	Print the format.;
%*Quote: https://support.sas.com/documentation/cdl/en/proc/65145/HTML/default/viewer.htm#p1swd5d7lnugzgn1rv7pgzkjav4w.htm ;
%if	&fDebug.	=	1	%then %do;
	proc format fmtlib;
		select	$&fnm_DtoMTD.;
		title	"[%str(I)NFO] Verify format [$&fnm_DtoMTD.]";
	run;
%end;

%*150.	Reverse the mapping;
%*We need to map the KPI ID in the results back to their respective input ones during verification of Checking Data.;
data &procLIB.._kftsmtd_trns_fmtout_r;
	%*100.	Rename the input columns;
	set
		&procLIB.._kftsmtd_trns_fmtout(
			rename=(
				START	=	__START
				END		=	__END
				LABEL	=	__LABEL
			)
		)
	;

	%*200.	Create the fields that are accepted by FORMAT Procedure;
	length	START	END	LABEL	$256;

	%*500.	Assign new values;
	%*[ASSUMPTION];
	%*[1] Add suffix <_r> to the format name, indicating reversed mapping;
	%*[2] SAS internal format name is always upcased;
	%*[3] Ensure the final length of format name less than 16;
	FMTNAME	=	upcase(catx('_', FMTNAME, 'r'));
	if	HLO	=	'O'	then do;
		START	=	__START;
		END		=	__END;
		LABEL	=	__LABEL;
	end;
	else do;
		START	=	__LABEL;
		END		=	__LABEL;
		LABEL	=	__START;
	end;

	%*900.	Purge;
	drop	__:;
run;
proc format cntlin=&procLIB.._kftsmtd_trns_fmtout_r;
run;

%*159.	Print the format.;
%if	&fDebug.	=	1	%then %do;
	proc format fmtlib;
		select	$&fnm_DtoMTD._r;
		title	"[%str(I)NFO] Verify reversed format [$&fnm_DtoMTD._r]";
	run;
%end;

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
	create table &procLIB.._kftsmtd_cfg_all as (
		select
			i.D_BGN as bgn_in
			,i.C_KPI_ID as kpi_in
			,upcase(i.C_KPI_DAT_PATH) as lib_in
			,upcase(prxchange(%sysfunc(quote(%superq(prx_sfx), %str(%'))), -1, i.C_KPI_DAT_NAME)) as dat_in
			,o.D_BGN as bgn_out
			,o.C_KPI_ID as kpi_out
			,upcase(o.C_KPI_DAT_PATH) as lib_out
			,upcase(prxchange(%sysfunc(quote(%superq(prx_sfx), %str(%'))), -1, o.C_KPI_DAT_NAME)) as dat_out
		from &procLIB.._kftsmtd_trns_fmtout(
			where=(
					upcase(FMTNAME)	=	%upcase(%sysfunc(quote(&fnm_DtoMTD., %str(%'))))
				and	HLO	^=	'O'
			)
		) as a
		inner join %unquote(&inKPICfg.)(
			where=(
					D_BGN	<=	%sysfunc(inputn(&inDate., yymmdd10.))	<=	D_END
				and	F_KPI_INUSE	=	1
			)
		) as i
			on	i.C_KPI_ID	=	a.START
		inner join %unquote(&inKPICfg.)(
			where=(
					D_BGN	<=	%sysfunc(inputn(&inDate., yymmdd10.))	<=	D_END
				and	F_KPI_INUSE	=	1
			)
		) as o
			on	o.C_KPI_ID	=	a.LABEL
	);
quit;

%*318.	Quit if there is no KPI involved due to configuration.;
%if	%getOBS4DATA(inDAT = &procLIB.._kftsmtd_cfg_all, gMode = F)	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No KPI is involved, skip current process.;
	%goto	EndOfProc;
%end;

%*330.	Verify the begin date of both sides on the mapper.;
data &procLIB.._kftsmtd_vfy_bgn;
	set
		&procLIB.._kftsmtd_cfg_all(
			where=(
				bgn_in	^=	bgn_out
			)
		)
	;
	length	txt	$32767;
	txt	=	cats(
		'W','ARNING: <D_BGN>'
		,'[',put(bgn_in, yymmddN8.),'] of KPI [',kpi_in,'] differs <D_BGN>'
		,'[',put(bgn_out, yymmddN8.),'] of KPI [',kpi_out,']!'
	);
	put	txt;
run;
%if	%getOBS4DATA(inDAT = &procLIB.._kftsmtd_vfy_bgn, gMode = F)	^=	0	%then %do;
	%ErrMcr
%end;

%*389.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%put	%str(I)NFO: [&L_mcrLABEL.]Final KPI mapping is listed below:;
	data _NULL_;
		set &procLIB.._kftsmtd_cfg_all;
		length	txt	$32767;
		txt	=	cats('I','NFO: [',kpi_in,'] -> [',kpi_out,']');
		put	txt;
	run;
%end;

%*390.	Prepare the loops.;
proc sort
	data=&procLIB.._kftsmtd_cfg_all
	out=&procLIB.._kftsmtd_cfg_all_dedup
	nodupkey
;
	by
		lib_out
		dat_out
	;
run;
data _NULL_;
	set	&procLIB.._kftsmtd_cfg_all_dedup end=EOF;
	call symputx(cats('eAMTDLIBo', _N_), lib_out, 'F');
	call symputx(cats('eAMTDDATo', _N_), dat_out, 'F');
	if	EOF	then do;
		call symputx('kAMTDDATo', _N_, 'F');
	end;
run;

%*500.	Loop the calculation for the same output dataset per iteration.;
%do Oj=1 %to &kAMTDDATo.;
	%*010.	Local parameters.;
	%let	rstIter		=	&&eAMTDDATo&Oj..&inDate.;
	%let	f_chkEnd	=	0;
	%let	f_dtable	=	0;

	%*019.	Debugger.;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.][Oj=&Oj.]Create data <%superq(rstIter)> in path: <%superq(eAMTDLIBo&Oj.)>;
	%end;

	%*100.	Determine the loop for all input datasets.;
	%*Below macro-to-call only handles time series of one dataset name prefix per call;
	%*110.	Subset the config table for current output dataset.;
	data &procLIB.._kftsmtd_cfg_thisOj;
		set
			&procLIB.._kftsmtd_cfg_all(
				where=(
						lib_out	=	%sysfunc(quote(%superq(eAMTDLIBo&Oj.), %str(%')))
					and	dat_out	=	%sysfunc(quote(%superq(eAMTDDATo&Oj.), %str(%')))
				)
			)
		;
	run;

	%*190.	Prepare the loop.;
	proc sort
		data=&procLIB.._kftsmtd_cfg_thisOj
		out=&procLIB.._kftsmtd_cfg_thisOj_in
		nodupkey
	;
		by
			lib_in
			dat_in
		;
	run;
	data _NULL_;
		set	&procLIB.._kftsmtd_cfg_thisOj_in end=EOF;
		call symputx(cats('eAMTDLIBi', _N_), lib_in, 'F');
		call symputx(cats('eAMTDDATi', _N_), dat_in, 'F');
		if	EOF	then do;
			call symputx('kAMTDDATi', _N_, 'F');
		end;
	run;

	%*300.	Assign temporary library as output destination.;
	libname	kfmtd_o	%sysfunc(quote(%superq(eAMTDLIBo&Oj.), %str(%')));
	%let	intpfx	=	kfmtd_o.&&eAMTDDATo&Oj..;

	%*400.	Determine the KPIs to be involved in this patch.;
	%*[ASSUMPTION] All below conditions MUST BE fulfilled at the same time;
	%*[1] No need to verify its existence, as the data is required anyway.;
	%*[2] <inDate> is the same as <D_BGN> for both KPIs involved in the mapper at current iteration.;
	%*[3] The output dataset ONLY has the required KPIs under conditions [2], i.e. no other KPIs are involved.;
	%*[4] All involved <intpfx> MUST HAVE BEEN created by this (and only by this) function in the previous periods,;
	%*     if any among the KPIs has <D_BGN> earlier than <inDate>.;
	%*[5] If there are multiple KPIs launched on the same date that fulfill above conditions, we process them together.;
	%*[6] Given condition [4] is fulfilled, it is safe to replicate the <Daily KPI> to resemble <MTD KPI>.;
	data &procLIB.._kftsmtd_vfy_bgn_in;
		set
			&procLIB.._kftsmtd_cfg_thisOj(
				where=(
					bgn_in	^=	%sysfunc(inputn(&inDate., yymmdd10.))
				)
			)
		;
	run;

	%*400.	Create empty Checking Data as of <chkEnd> for standardized process at later steps.;
	%if	%getOBS4DATA(inDAT = &procLIB.._kftsmtd_vfy_bgn_in, gMode = F)	=	0	%then %do;
		%if	&fDebug.	=	1	%then %do;
			%put	%str(I)NFO: [&L_mcrLABEL.][Oj=&Oj.]Create empty MTD KPIs as Checking Data out of daily ones as their <D_BGN> is the same as <%qsysfunc(compbl(&inDate.))>.;
		%end;

		%*300.	Obtain the config for the KPI to be replicated.;
		proc sql;
			create table &procLIB.._kftsmtd_repl_cfg as (
				select a.*
				from &inKPICfg. as a
				inner join &procLIB.._kftsmtd_cfg_thisOj as b
					on	a.C_KPI_ID	=	b.kpi_in
			);
		quit;

		%*399.	Debugger.;
		%if	&fDebug.	=	1	%then %do;
			%put	%str(I)NFO: [&L_mcrLABEL.][Oj=&Oj.]Below is the list of Daily KPIs to be directly translated on <&inDate.>.;
			data _NULL_;
				set &procLIB.._kftsmtd_repl_cfg;
				length	txt	$32767;
				txt	=	cats('I','NFO: [',C_KPI_ID,']');
				put	txt;
			run;
		%end;

		%*500.	Retrieve all involved <Daily KPI>.;
		%*[ASSUMPTION];
		%*[1] We only export an empty dataset to resemble the data on Checking Period.;
		%*[2] The reason is that we need the combined structure of these datasets for the output.;
		%*[2] By doing this we would eliminate other logics to create the output.;
		%DBuse_GetTimeSeriesForKpi(
			inInfDat	=
			,InfDatOpt	=
			,SingleInf	=	Y
			,MergeProc	=	SET
			,KeyOfMrg	=	&byVar.
			,SetAsBase	=	K
			,inKPICfg	=	&procLIB.._kftsmtd_repl_cfg
			,dnDateList	=	&inDate.
			,outDAT		=	&procLIB.._kftsmtd_chkdat
			,VarRecDate	=	D_RecDate
			,procLIB	=	&procLIB.
			,fDebug		=	&fDebug.
		)
		data &procLIB.._kftsmtd_chkdat;
			set &procLIB.._kftsmtd_chkdat(obs=0);
			drop	D_RecDate;
		run;
		%let	f_chkEnd	=	1;
	%end;

	%*470.	Create interim dataset for calculation based on the result as of the previous date.;
	%else %do;
		%if	&fDebug.	=	1	%then %do;
			%put	%str(I)NFO: [&L_mcrLABEL.][Oj=&Oj.]Time Series is designed to exist, search for it as Checking Data.;
		%end;

		%*[ASSUMPTION];
		%*[1] Typical variable name that differs the KPI value for the same key is <C_KPI_ID>.;
		%*[2] In the MTD source data the above variable has been assigned with different values against those in the daily source data.;
		%*[3] We hence have to map the ID back to the same as in the daily source data to conduct the calculation,;
		%*     as we also have to group by KPI ID for the same key.;
		%*[4] Below mapper is dynamically created at earlier steps.;
		%*[5] We only create it once per iteration over the outer loop, to save system effort.;
		%*[6] If the data of the same prefix is to be involved, it MUST HAVE BEEN created by this function,;
		%*     hence it is safe not to filter the required KPIs from it.;
		%if	%sysfunc(exist(&intpfx.&dnChkEnd.))	%then %do;
			%let	f_chkEnd	=	1;
			data &procLIB.._kftsmtd_chkdat;
				set &intpfx.&dnChkEnd.;
				C_KPI_ID	=	put(C_KPI_ID, $&fnm_DtoMTD._r.);
			run;
		%end;
	%end;

	%*700.	Aggregation for time series per input dataset name.;
	%do Ij=1 %to &kAMTDDATi.;
		%*100.	Assign temporary library for this step.;
		libname	kfmtd_i	%sysfunc(quote(%superq(eAMTDLIBi&Ij.), %str(%')));

		%*300.	Only check the involved KPI during aggregation, to save system effort.;
		%let	chknm	=	&procLIB.._kftsmtd_chk_kpi_pd;
		%if	&f_chkEnd.	=	1	%then %do;
			proc sql;
				create table &chknm.&dnChkEnd. as (
					select a.*
					from &procLIB.._kftsmtd_chkdat as a
					inner join &procLIB.._kftsmtd_cfg_thisOj(
						where=(
								lib_in	=	%sysfunc(quote(%superq(eAMTDLIBi&Ij.), %str(%')))
							and	dat_in	=	%sysfunc(quote(%superq(eAMTDDATi&Ij.), %str(%')))
						)
					) as b
						on	a.C_KPI_ID	=	b.kpi_in
				);
			quit;
		%end;
		%else %do;
			%*100.	Ensure there is no data for the checking period at this iteration.;
			%if	%sysfunc(exist(&chknm.&dnChkEnd.))	%then %do;
				proc sql;
					drop table &chknm.&dnChkEnd.;
				quit;
			%end;
		%end;

		%*700.	Standardize the aggregation.;
		%AggrByPeriod(
			inClndrPfx	=	&inClndrPfx.
			,inDatPfx	=	kfmtd_i.&&eAMTDDATi&Ij..
			,AggrVar	=	&aggrVar.
			,dnDateBgn	=	&dtBgn.
			,dnDateEnd	=	&inDate.
			,ChkDatPfx	=	&chknm.
			,ChkDatVar	=	&aggrVar.
			,dnChkBgn	=	&dtBgn.
			,ByVar		=	&byInt.
			,CopyVar	=	&copyVar.
			,genPHbyWD	=	&genPHbyWD.
			,FuncAggr	=	&funcAggr.
			,outVar		=	_A_MTD_AGG
			,outDAT		=	&procLIB.._kftsmtd__agg&Ij.
			,procLIB	=	&procLIB.
			,fDebug		=	&fDebug.
		)

		%*800.	Search for the specific columns.;
		%getCOLbyStrPattern(
			inDAT		=	&procLIB.._kftsmtd__agg&Ij.
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
		libname	kfmtd_i	clear;
	%*End of inner loop;
	%end;

	%*800.	Standardize the output.;
	data &intpfx.&inDate.(compress=yes);
		%*010.	Set all results.;
		set
		%do Ij=1 %to &kAMTDDATi.;
			&procLIB.._kftsmtd__agg&Ij.
		%end;
		;

		%*100.	Reset D_TABLE if it exists.;
		%if	&f_dtable.	=	1	%then %do;
			D_TABLE	=	input("&inDate.", yymmdd10.);
		%end;

		%*500.	Map Daily KPIs to MTD ones.;
		C_KPI_ID	=	put(C_KPI_ID, $&fnm_DtoMTD..);
		&aggrVar.	=	_A_MTD_AGG;

		%*800.	Delete excessive data if there are additional KPIs.;
		%*Due to above function call, there is actually no excessive KPI, but we ensure it.;
		if	missing(C_KPI_ID)	then	delete;

		%*900.	Purge.;
		drop	_A_MTD_AGG;
	run;

	%*900.	Purge.;
	%*910.	De-assign the temporary library.;
	libname	kfmtd_o	clear;

	%*999.	Debugger.;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.][Oj=&Oj.]End iteration.;
	%end;
%*End of outer loop;
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
%mend kfFunc_ts_mtd;

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
	length	mapper_in	mapper_out	$64;
	mapper_in	=	'130100';	mapper_out	=	'230100';	output;
run;

%*200.	Create MTD KPI for 20160412.;
%kfFunc_ts_mtd(
	inKPICfg	=	CFG_KPI
	,mapDtoMTD	=	mapdat
	,inDate		=	20160412
	,inClndrPfx	=	work.tmpCalendar
	,aggrVar	=	A_KPI_VAL
	,byVar		=	nc_cifno
	,copyVar	=	_all_
	,genPHbyWD	=	1
	,funcAggr	=	CMEAN
	,procLIB	=	WORK
	,fDebug		=	0
)
%put	%sysevalf(31 / 12);

%*300.	Create MTD KPI for 20160413.;
%kfFunc_ts_mtd(
	inKPICfg	=	CFG_KPI
	,mapDtoMTD	=	mapdat
	,inDate		=	20160413
	,inClndrPfx	=	work.tmpCalendar
	,aggrVar	=	A_KPI_VAL
	,byVar		=	nc_cifno
	,copyVar	=	_all_
	,genPHbyWD	=	1
	,funcAggr	=	CMEAN
	,procLIB	=	WORK
	,fDebug		=	0
)
%put	%sysevalf((31 + 32) / 13);

/*-Notes- -End-*/