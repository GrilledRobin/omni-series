%*001.	This section generates system log data.;
%*Below macro is from "&macroot.\010Proc";
%genLogByExecPgm

%*010.	Below section generates the system-level global variables;
%global
	L_srcflnm1
	L_srcflnm2
	L_stpflnm
;

%let	L_srcflnm1	=	src.CFG_KPI&L_curMon.;
%let	L_srcflnm2	=	DB.rptCFG_Req_OnlySet&L_curMon.;
%let	L_stpflnm	=	Anl.rptData_FrSetKPI&L_curMon.;

/***************************************************************************************************\
|	For those KPIs that do not require the merge to the Information Tables, we set them together.	|
\***************************************************************************************************/

%*020.	Below section is for main process;
%macro getRptSrcFrSetKPI;
%*010.	Define the local environment.;
%local
	LchkOutDAT
	LchkOutOBS
;
%let	LnKpiLvl	=	0;
%let	LchkOutDAT	=	0;
%let	LchkOutOBS	=	0;

%*100.	Skip this step if there is no available data for process.;
%*Below macro is from "&cdwmac.\AdvOp";
%if	%getOBS4DATA( inDAT = &L_srcflnm2. , gMode = F )	=	0	%then %do;
	%put	NOTE: There is no data for the set of KPI sources. Skip current step.;
	%goto	EndOfProc;
%end;

%*200.	Retrieve the inventory for the KPIs.;
%* (e.g. given there is enough descriptive information in KPI data for reporting);
proc sql;
	create table work2._rpt_kpi_cfg_wolvl as (
		select a.*
		from &L_srcflnm1. as a
		inner join &L_srcflnm2. as b
			on	a.C_KPI_ID	=	b.C_KPI_ID
	);
quit;

%*300.	Set the KPI tables without the information table.;
%*IMPORTANT: If the source data of a certain KPI does not exist, below macro DOES NOT create output.;
%*Below macro is from "&cdwmac.\AdvDB";
%DBuse_SetKPItoInf(
	inInfDat	=
	,KeyOfMrg	=	%nrbquote(
						nc_branch_cd
						c_branch_nm
						c_city_name
						nc_cifno
					)
	,SetAsBase	=
	,inKPICfg	=	work2._rpt_kpi_cfg_wolvl
	,outDAT		=	work2._rpt_kpi_wolvl
	,procLIB	=	WORK2
)
%EndOfSetKPI:

%*800.	If no KPI source data is found in the process, we skip this step.;
%if	%sysfunc(exist(work2._rpt_kpi_wolvl))	=	1	%then %do;
	%*100.	Increment the counter if any output data has been created.;
	%let	LchkOutDAT	=	%eval( &LchkOutDAT. + 1 );

	%*200.	Increment the counter if there are any observations.;
	%*We should assure there is at least 1 observation of all the output datasets to prevent the error;
	%* from being issued for the uninitialized HASH Object.;
	%let	LchkOutOBS	=	%eval( &LchkOutOBS. + %getOBS4DATA( inDAT = work2._rpt_kpi_wolvl , gMode = F ) );
%end;
%if	&LchkOutDAT.	=	0	%then %do;
	%put	NOTE: KPI source data is not found for the SET process. Skip current step.;
	%goto	EndOfProc;
%end;
%if	&LchkOutOBS.	=	0	%then %do;
	%put	NOTE: KPI source data contain no observation for the SET process. Skip current step.;
	%goto	EndOfProc;
%end;

%*900.	Standardize the data.;
data &L_stpflnm.(compress=yes);
	%*001.	Create D_TABLE;
	%*Below macro is from "&cdwmac.\AdvOp";
	%cr_d_table

	%*010.	Set all the KPI data.;
	set work2._rpt_kpi_wolvl;

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
%mend getRptSrcFrSetKPI;
%getRptSrcFrSetKPI