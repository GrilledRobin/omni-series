%*001.	This section generates system log data.;
%*Below macro is from "&macroot.\010Proc";
%genLogByExecPgm

%*010.	Below section generates the system-level global variables;
%global
	L_srcflnm1
	L_srcflnm2
	L_stpflnm
	L_ExSheet
	L_odsflnm
;

%let	L_srcflnm1	=	[Various];
%let	L_srcflnm2	=	src.rpt_KPI&L_curMon.;
%let	L_ExSheet	=	MiniPack&L_curMon.;
%let	L_odsflnm	=	&outroot.\&L_ExSheet..xls;
%let	L_stpflnm	=	&outroot.\&L_ExSheet..xlsx;

/***************************************************************************************************\
|	Generate the plain report data in terms of Tabulation											|
|	All datasets in the library [Anl], that have the naming convention as [rptData_:], will be		|
|	 retrieved for the final report.																|
|	This report should still be processed in terms of the final template							|
|	 , either via DDE or VBA in EXCEL																|
\***************************************************************************************************/

%*020.	Below section is for main process;
%macro genRawRpt;
%*001.	Purge the original file for new generation.;
%if	&LfKeepRpt.	=	0	%then %do;
	%sysexec(del /Q "&L_stpflnm." & exit);
%end;

%*010.	Define the local environment.;
%local
	Di
;

%*100.	Retrieve all the available data for reporting process.;
%*Below macro is from "&cdwmac.\AdvOp";
%getTblListByStrPattern(
	inLIB		=	Anl
	,inRegExp	=	%nrbquote(^rptData_.+?&L_curMon.\b)
	,exclRegExp	=
	,extRegExp	=	data
	,outCNT		=	LnRptData
	,outELpfx	=	LeRptData
)

%*190.	Quit the reporting process if there is no available data.;
%if	&LnRptData.	=	0	%then %do;
	%put	WARNING: No source data is found! The report cannot be created!;
	%goto	EndOfProc;
%end;

%*200.	Set together the performance data and the report structure.;
data work2._rpt_for_out;
	%*010.	Set all the reporting data.;
	set
		%do Di=1 %to &LnRptData.;
			Anl.&&LeRptData&Di..
		%end;
	;

	%*020.	Hash in the parameter table.;
	if	0	then	set	&L_srcflnm2.;
	if	_N_	=	1	then do;
		dcl	hash	hKpiRptDef(dataset:"&L_srcflnm2.(where=(missing(C_KPI_ID)=0))");
		hKpiRptDef.DefineKey("C_KPI_ID");
		hKpiRptDef.DefineData("C_KPI_ID");
		hKpiRptDef.DefineDone();
	end;

	%*100.	Remove the records which are not involved in the reporting.;
	if	hKpiRptDef.check()	^=	0	then do;
		delete;
	end;

	%*200.	Scale the KPI values in terms of the respective units.;
	if	missing(A_KPI_UNIT)	=	1	then do;
		A_KPI_UNIT	=	1;
	end;
	A_KPI_VAL	=	A_KPI_VAL	/	A_KPI_UNIT;
run;

%*290.	Quit the reporting process if there is no observation in the source data.;
%*Below macro is from "&cdwmac.\AdvOp";
%if	%getOBS4DATA( inDAT = work2._rpt_for_out , gMode = F )	=	0	%then %do;
	%put	WARNING: No observation is found! The report cannot be created!;
	%goto	EndOfProc;
%end;

%*500.	Initialize the ODS system.;
ods listing close;
ods html body = "&L_odsflnm." style=minimal rs=none;

%*600.	Create the report.;
proc tabulate
	data=work2._rpt_for_out
	missing
	format=comma32.4
;
	class
		c_branch_nm
		C_KPI_CAT1
		C_KPI_CAT2
		C_KPI_CAT3
		C_KPI_CAT4
		C_KPI_NAME
		D_TABLE
	;
	var
		A_KPI_VAL
	;
	table
		c_branch_nm	=	""
			*	C_KPI_CAT4	=	""
			*	C_KPI_CAT3	=	""
			*	C_KPI_CAT2	=	""
			*	C_KPI_CAT1	=	""
			*	C_KPI_NAME	=	""
		,D_TABLE	=	""
			*	A_KPI_VAL	=	""
				*	(
						sum		=	""
					)
		/misstext="0"
	;
run;

%*800.	Close the ODS system.;
ods html close;
ods listing;

%*900.	Save the HTML file into EXCEL file.;
%*Below macro is from "&cdwmac.\FileSystem";
%VBS_SaveXlSheetAsOthFile(
	inXLFile	=	%nrbquote(&L_odsflnm.)
	,inSheet	=	%nrbquote(&L_ExSheet.)
	,outFile	=	%nrbquote(&L_stpflnm.)
	,outFileTp	=	51
)

%*990.	Remove the temporary file.;
%sysexec(del /Q "&L_odsflnm." & exit);

%EndOfProc:
%mend genRawRpt;
%genRawRpt