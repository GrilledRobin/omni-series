%*001.	This section generates system log data.;
%*Below macro is from "&macroot.\010Proc";
%genLogByExecPgm

%*010.	Below section generates the system-level global variables;
%global
	L_srcflnm1
	L_srcflnm2
	L_srcflnm3
	L_stpflnm
;

%let	L_srcflnm1	=	src.CFG_KPI&L_curMon.;
%let	L_srcflnm2	=	DB.rptCFG_Req_InfTable&L_curMon.;
%let	L_srcflnm3	=	src.rpt_KPI_lvl&L_curMon.;
%let	L_stpflnm	=	Anl.rptData_FrInfTable&L_curMon.;

/***************************************************************************************************\
|	Retrieve information tables at different levels													|
|	Retrieve KPI data in terms of the configuration tables											|
\***************************************************************************************************/

%*020.	Below section is for main process;
%macro getRptSrcFrInfTable;
%*010.	Define the local environment.;
%local
	Li
	LnKpiLvl
	LchkOutDAT
	LchkOutOBS
;
%let	LnKpiLvl	=	0;
%let	LchkOutDAT	=	0;
%let	LchkOutOBS	=	0;

%*100.	Skip this step if there is no available data for process.;
%*Below macro is from "&cdwmac.\AdvOp";
%if	%getOBS4DATA( inDAT = &L_srcflnm2. , gMode = F )	=	0	%then %do;
	%put	NOTE: There is no data for the retrieval from Information Tables. Skip current step.;
	%goto	EndOfProc;
%end;

%*200.	Find all types of source data, for the information mapping.;
%*210.	Retrieve unique KPI levels from the parameter table.;
%*211.	Existing KPI levels.;
proc freq
	data=&L_srcflnm2.
	noprint
;
	%*100.	Just in case there is anything missing, although there SHOULD NOT be.;
	where
		missing(C_KPI_LEVEL)	=	0
	;
	tables
		C_KPI_LEVEL
		/list
		out=work2._rpt_kpi_lvl
	;
run;

%*222.	Retrieval.;
proc sql;
	create table work2._rpt_kpi_WithInf as (
		select
			a.*
			,b.C_INF_TABLE
			,b.C_INF_KEY
		from work2._rpt_kpi_lvl as a
		left join &L_srcflnm3. as b
			on	a.C_KPI_LEVEL	=	b.C_KPI_LEVEL
	);
quit;
data _NULL_;
	set work2._rpt_kpi_WithInf end=EOF;
	call symputx(cats("LeKpiLvl",_N_),C_KPI_LEVEL,"L");
	call symputx(cats("LeLvlInf",_N_),C_INF_TABLE,"L");
	call symputx(cats("LeLvlKey",_N_),C_INF_KEY,"L");
	if	EOF	then do;
		call symputx("LnKpiLvl",_N_,"L");
	end;
run;

%*500.	Merge the KPI data to information tables at respective levels.;
%*510.	For those KPIs requiring information mapping.;
%do Li=1 %to &LnKpiLvl.;
	%*100.	Retrieve the KPI configuration table for current level.;
	proc sql;
		create table work2._rpt_kpi_cfg&Li. as (
			select a.*
			from &L_srcflnm1. as a
			inner join &L_srcflnm2.(
				where=(
					C_KPI_LEVEL	=	"&&LeKpiLvl&Li.."
				)
			) as b
				on	a.C_KPI_ID	=	b.C_KPI_ID
		);
	quit;

	%*200.	Set together the information table and the KPI data.;
	%*IMPORTANT: If the source data of a certain KPI does not exist, below macro DOES NOT create output.;
	%*Below macro is from "&cdwmac.\AdvDB";
	%DBuse_SetKPItoInf(
		inInfDat	=	%nrbquote(
							&&LeLvlInf&Li..(
								keep=
									&&LeLvlKey&Li..
									nc_branch_cd
									c_branch_nm
									c_city_name
							)
						)
		,KeyOfMrg	=	&&LeLvlKey&Li..
		,SetAsBase	=	B
		,inKPICfg	=	work2._rpt_kpi_cfg&Li.
		,outDAT		=	work2._rpt_kpi&Li.
		,procLIB	=	WORK2
	)
%end;
%EndOfMrgInf:

%*800.	If no KPI source data is found in the process, we skip this step.;
%do Li=1 %to &LnKpiLvl.;
	%if	%sysfunc(exist(work2._rpt_kpi&Li.))	=	1	%then %do;
		%*100.	Increment the counter if any output data has been created.;
		%let	LchkOutDAT	=	%eval( &LchkOutDAT. + 1 );

		%*200.	Increment the counter if there are any observations.;
		%*We should assure there is at least 1 observation of all the output datasets to prevent the error;
		%* from being issued for the uninitialized HASH Object.;
		%let	LchkOutOBS	=	%eval( &LchkOutOBS. + %getOBS4DATA( inDAT = work2._rpt_kpi&Li. , gMode = F ) );
	%end;
%end;
%if	&LchkOutDAT.	=	0	%then %do;
	%put	NOTE: KPI source data is not found for the retrieval from Information Tables. Skip current step.;
	%goto	EndOfProc;
%end;
%if	&LchkOutOBS.	=	0	%then %do;
	%put	NOTE: KPI source data contain no observation for the retrieval from Information Tables. Skip current step.;
	%goto	EndOfProc;
%end;

%*900.	Standardize the data.;
data &L_stpflnm.(compress=yes);
	%*001.	Create D_TABLE;
	%*Below macro is from "&cdwmac.\AdvOp";
	%cr_d_table

	%*010.	Set all the KPI data.;
	set
		%do Li=1 %to &LnKpiLvl.;
			%if	%sysfunc(exist(work2._rpt_kpi&Li.))	=	1	%then %do;
				work2._rpt_kpi&Li.
			%end;
		%end;
	;

	%*020.	Hash in the parameter table.;
	if	0	then	set	&L_srcflnm2.;
	if	_N_	=	1	then do;
		dcl	hash	hKpiRptDef(dataset:"&L_srcflnm2.");
		hKpiRptDef.DefineKey("C_KPI_ID");
		hKpiRptDef.DefineData(all: "YES");
		hKpiRptDef.DefineDone();
	end;

	%*100.	Retrieve the reporting categories for the KPIs.;
	_iorc_	=	hKpiRptDef.find();

	%*900.	Initialize the values of the KPI.;
	if	missing(A_KPI_VAL)	then	A_KPI_VAL	=	0;

	%*990.	Purge.;
%*	keep
		D_TABLE
	;
run;

%EndOfProc:
%mend getRptSrcFrInfTable;
%getRptSrcFrInfTable