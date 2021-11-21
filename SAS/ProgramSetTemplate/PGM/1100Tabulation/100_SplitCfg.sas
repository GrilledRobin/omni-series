%*001.	This section generates system log data.;
%*Below macro is from "&macroot.\010Proc";
%genLogByExecPgm

%*010.	Below section generates the system-level global variables;
%global
	L_srcflnm1
	L_srcflnm2
	L_stpflnm1
	L_stpflnm2
	L_stpflnm3
;

%let	L_srcflnm1	=	src.CFG_KPI&L_curMon.;
%let	L_srcflnm2	=	src.rpt_KPI&L_curMon.;
%let	L_stpflnm1	=	DB.rptCFG_Req_InfTable&L_curMon.;
%let	L_stpflnm2	=	DB.rptCFG_Req_OnlySet&L_curMon.;
%let	L_stpflnm3	=	DB.rptCFG_Req_TmpKPI&L_curMon.;

/***************************************************************************************************\
|	Split the reporting configuration table into below types for different approaches:				|
|	1. KPIs that exist in the Data Mart																|
|	 (1) Level of KPI is defined in the parameter table, which requires the Information Table		|
|	 (2) Level of KPI is NOT defined in the parameter table, we only need to set them together		|
|	2. KPIs that DO NOT exist in the Data Mart, which we should create in current report process	|
|	 This part includes those ADDITIONAL KPIs, which are the interim media to create temporary KPIs	|
\***************************************************************************************************/

%*020.	Below section is for main process;
%macro splitCFG;
%*100.	Compromise to the SAS ver9.1 that the HASH object do not recognize the Dataset Options.;
data work2.__kpi_cfg__;
	set &L_srcflnm1.(keep=C_KPI_ID);
run;

%*900.	Split the data.;
data
	&L_stpflnm1.(compress=yes)
	&L_stpflnm2.(compress=yes)
	&L_stpflnm3.(compress=yes)
;
	%*001.	Create D_TABLE;
	%*Below macro is from "&cdwmac.\AdvOp";
	%cr_d_table

	%*010.	Prepare the data structure.;
	if	0	then do;
		set work2.__kpi_cfg__;
	end;

	%*100.	Set the configuration table for the report.;
	set &L_srcflnm2.;

	%*200.	Hash in the datasets.;
	if	_N_	=	1	then do;
		dcl hash hKPICfg(dataset:"work2.__kpi_cfg__");
		hKPICfg.DefineKey(all:"YES");
		hKPICfg.DefineData(all:"YES");
		hKPICfg.DefineDone();
	end;

	%*300.	Split the configuration table in terms of the KPI inventory.;
	if	hKPICfg.check()	=	0	then do;
		if	upcase(C_KPI_NAME)	^=	"(ADDITIONAL)"	then do;
			if	missing(C_KPI_LEVEL)	=	0	then do;
				%*100.	Generate the part that requires the Information Table.;
				output	&L_stpflnm1.;
			end;
			else do;
				%*200.	Generate the part that DO NOT require the Information Table.;
				output	&L_stpflnm2.;
			end;
		end;
		else do;
			%*300.	Identify the KPIs that are required to create the temporary KPIs.;
			output	&L_stpflnm3.;
		end;
	end;
	else do;
		%*400.	Identify the temporary KPIs.;
		output	&L_stpflnm3.;
	end;

	%*900.	Purge.;
run;

%EndOfProc:
%mend splitCFG;
%splitCFG