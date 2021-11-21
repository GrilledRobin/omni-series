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
%let	L_srcflnm2	=	DB.rptCFG_Req_TmpKPI&L_curMon.;
%let	L_stpflnm	=	Anl.rptData_BMargin&L_curMon.;

/***************************************************************************************************\
|	Create the temporary KPI to calculate the Blended Margin with below formula.					|
|	Blended Margin = Total Revenue / Total AUM														|
\***************************************************************************************************/

%*020.	Below section is for main process;
%macro getRptSrcBlendedMargin;
%*010.	Define the local environment.;
%local
	LchkOutDAT
	LchkOutOBS
;
%let	LchkOutDAT	=	0;
%let	LchkOutOBS	=	0;

%*100.	Retrieve the source data from the KPI inventory.;
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
	,inKPICfg	=	%nrbquote(
						&L_srcflnm1.(
							where=(
								C_KPI_ID	in	(
									"100000"
									"200000"
								)
							)
						)
					)
	,outDAT		=	work2._rpt_kpi_BMgnPre
	,procLIB	=	WORK2
)

%*200.	Skip this step if there is no available data for process.;
%if	%sysfunc(exist(work2._rpt_kpi_BMgnPre))	=	1	%then %do;
	%*100.	Increment the counter if any output data has been created.;
	%let	LchkOutDAT	=	%eval( &LchkOutDAT. + 1 );

	%*200.	Increment the counter if there are any observations.;
	%*We should assure there is at least 1 observation of all the output datasets to prevent the error;
	%* from being issued for the uninitialized HASH Object.;
	%*Below macro is from "&cdwmac.\AdvOp";
	%let	LchkOutOBS	=	%eval( &LchkOutOBS. + %getOBS4DATA( inDAT = work2._rpt_kpi_BMgnPre , gMode = F ) );
%end;
%if	&LchkOutDAT.	=	0	%then %do;
	%put	NOTE: KPI source data is not found for the calculation of Blended Margin. Skip current step.;
	%goto	EndOfProc;
%end;
%if	&LchkOutOBS.	=	0	%then %do;
	%put	NOTE: KPI source data contain no observation for the calculation of Blended Margin. Skip current step.;
	%goto	EndOfProc;
%end;

%*300.	Calculate in terms of the pre-defined formula, using the KPIs.;
%*IMPORTANT: All Classes in the Tabulation report should be presented here, except the [C_KPI_ID] and its superior;
%* dimensions, such as [C_KPI_CAT1], for they will be created in the next step.;
%*Below macro is from "&cdwmac.\AdvDB";
%DBuse_crKPIbyFnOnKPIID(
	inDat		=	work2._rpt_kpi_BMgnPre
	,inCLASS	=	%nrbquote(
						nc_branch_cd
						c_branch_nm
						c_city_name
					)
	,inKPIlist	=	%nrbquote(
						100000
						200000
					)
	,inFormula	=	%nrstr(
						100000 / 200000
					)
	,outKPIID	=	TMGN010
	,outDAT		=	work2._rpt_kpi_BMgn
	,procLIB	=	WORK
)

%*390.	Skip this step if there is no output data.;
%if	%sysfunc(exist(work2._rpt_kpi_BMgn))	=	0	%then %do;
	%put	NOTE: Creation of new KPI failed due to missing data. Skip current step.;
	%goto	EndOfProc;
%end;

%*900.	Standardize the data.;
data &L_stpflnm.(compress=yes);
	%*001.	Create D_TABLE;
	%*Below macro is from "&cdwmac.\AdvOp";
	%cr_d_table

	%*010.	Set all the KPI data.;
	set work2._rpt_kpi_BMgn;

	%*020.	Hash in the parameter table.;
	if	0	then	set	&L_srcflnm2.;
	if	_N_	=	1	then do;
		dcl	hash	hKpiRptDef(dataset:"&L_srcflnm2.");
		hKpiRptDef.DefineKey("C_KPI_ID");
		hKpiRptDef.DefineData(all: "YES");
		hKpiRptDef.DefineDone();
	end;

	%*800.	Retrieve the reporting categories for the KPIs.;
	_iorc_	=	hKpiRptDef.find();

	%*900.	Initialize the values of the KPI.;

	%*990.	Purge.;
%*	keep
		D_TABLE
	;
run;

%EndOfProc:
%mend getRptSrcBlendedMargin;
%getRptSrcBlendedMargin