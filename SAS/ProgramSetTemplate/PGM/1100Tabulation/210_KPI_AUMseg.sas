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
%let	L_stpflnm	=	Anl.rptData_AUMSeg&L_curMon.;

/***************************************************************************************************\
|	Create the temporary KPIs to split the customer base in terms of the AUM ranges.				|
\***************************************************************************************************/

%*020.	Below section is for main process;
%macro getRptSrcAUMseg;
%*010.	Define the local environment.;
%local
	LchkOutDAT
	LchkOutOBS
;
%let	LchkOutDAT	=	0;
%let	LchkOutOBS	=	0;

%*100.	Retrieve the AUM source data from the KPI inventory.;
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
								C_KPI_ID	=	"200000"
							)
						)
					)
	,outDAT		=	work2._rpt_kpi_AUMpre
	,procLIB	=	WORK2
)

%*200.	Skip this step if there is no available data for process.;
%if	%sysfunc(exist(work2._rpt_kpi_AUMpre))	=	1	%then %do;
	%*100.	Increment the counter if any output data has been created.;
	%let	LchkOutDAT	=	%eval( &LchkOutDAT. + 1 );

	%*200.	Increment the counter if there are any observations.;
	%*We should assure there is at least 1 observation of all the output datasets to prevent the error;
	%* from being issued for the uninitialized HASH Object.;
	%*Below macro is from "&cdwmac.\AdvOp";
	%let	LchkOutOBS	=	%eval( &LchkOutOBS. + %getOBS4DATA( inDAT = work2._rpt_kpi_AUMpre , gMode = F ) );
%end;
%if	&LchkOutDAT.	=	0	%then %do;
	%put	NOTE: KPI source data is not found for the AUM Segmentation. Skip current step.;
	%goto	EndOfProc;
%end;
%if	&LchkOutOBS.	=	0	%then %do;
	%put	NOTE: KPI source data contain no observation for the AUM Segmentation. Skip current step.;
	%goto	EndOfProc;
%end;

%*300.	Ensure there is only one observation for each customer for the segmentation.;
proc means
	data=work2._rpt_kpi_AUMpre
	noprint
	missing
	nway
;
	class
		c_city_name
		c_branch_nm
		nc_branch_cd
		nc_cifno
		C_KPI_ID
	;
	var
		A_KPI_VAL
	;
	output
		out=work2._rpt_kpi_AUMseg(drop=_:)
		sum=A_KPI_VAL
	;
run;

%*900.	Standardize the data.;
data &L_stpflnm.(compress=yes);
	%*001.	Create D_TABLE;
	%*Below macro is from "&cdwmac.\AdvOp";
	%cr_d_table

	%*010.	Set all the KPI data.;
	set work2._rpt_kpi_AUMseg;

	%*020.	Hash in the parameter table.;
	if	0	then	set	&L_srcflnm2.;
	if	_N_	=	1	then do;
		dcl	hash	hKpiRptDef(dataset:"&L_srcflnm2.");
		hKpiRptDef.DefineKey("C_KPI_ID");
		hKpiRptDef.DefineData(all: "YES");
		hKpiRptDef.DefineDone();
	end;

	%*100.	Define the temporary KPI ID.;
	%*Below format is from "&macroot.\010Biz";
	C_KPI_ID	=	put(A_KPI_VAL,f_AUMseg_a.);

	%*200.	Set the KPI Value.;
	%*Since this KPI is to count the number of customers, we set the value as 1 for each customer.;
	A_KPI_VAL	=	1;

	%*800.	Retrieve the reporting categories for the KPIs.;
	_iorc_	=	hKpiRptDef.find();

	%*900.	Initialize the values of the KPI.;

	%*990.	Purge.;
%*	keep
		D_TABLE
	;
run;

%EndOfProc:
%mend getRptSrcAUMseg;
%getRptSrcAUMseg