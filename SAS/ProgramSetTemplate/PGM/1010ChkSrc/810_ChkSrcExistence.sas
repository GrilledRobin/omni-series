%*001.	This section generates system log data.;
%*Below macro is from "&macroot.\010Proc";
%genLogByExecPgm

%*010.	Below section generates the system-level global variables;
%global
	L_srcflnm1
	L_srcflnm2
	L_srcflnm3
	L_srcflnm4
	L_stpflnm
;

%let	L_srcflnm1	=	src.CFG_KPI&L_curMon.;
%let	L_srcflnm2	=	src.rpt_KPI&L_curMon.;
%let	L_srcflnm3	=	src.rpt_KPI_lvl&L_curMon.;
%let	L_srcflnm4	=	src.rpt_OthSrc&L_curMon.;
%let	L_stpflnm	=	src.Check_Src&L_curMon.;

/***************************************************************************************************\
|	1. Verify whether all the required source files exist for current process						|
|	2. Should there be any other dataset or files required to exist, you can surely add them.		|
\***************************************************************************************************/

%*020.	Below section is for main process;
%macro vfyRptSrc;
%*010.	Define the local environment.;
%local
	Li
;

%*200.	Find all source data via the KPI configuration table.;
proc sql;
	create table work2.__kpi_src_pre as (
		select distinct
			a.C_KPI_DAT_PATH
			,a.C_KPI_DAT_NAME
		from &L_srcflnm1. as a
		inner join &L_srcflnm2. as b
			on	a.C_KPI_ID	=	b.C_KPI_ID
	);
quit;
data work2.__kpicfg_src;
	%*010.	Create the standard fields.;
	%*Below macro is from "&macroot.\010Proc";
	%InitVar_ChkSrc

	%*100.	Set the configuration table.;
	set work2.__kpi_src_pre end=EOF;

	%*300.	Create temporary fields.;
	format
		DatExt	$16.
	;
	DatExt	=	".sas7bdat";
	C_KPI_DAT_PATH	=	resolve(C_KPI_DAT_PATH);
	C_KPI_DAT_NAME	=	resolve(C_KPI_DAT_NAME);

	%*400.	Identify all the required source data.;
	C_SRC_PATH	=	strip(C_KPI_DAT_PATH);
	C_SRC_NAME	=	cats(C_KPI_DAT_NAME,DatExt);
	%*We set the location of all KPI data as the same as in the server.;
	C_DES_PATH	=	strip(C_SRC_PATH);
	C_SRC_TYPE	=	"10.KPI data";
	F_SRC_MISS	=	1 - fileexist(catx("\",C_SRC_PATH,C_SRC_NAME));
run;

%*300.	Other SAS datasets that are to be retrieved as source.;
%*310.	Combine the KPI Level data and the ones in the Other Sources file list.;
data work2.__kpi_othsrc_sas;
	%*100.	Set the configuration table.;
	set
		&L_srcflnm3.(
			in=i
		)
		&L_srcflnm4.(
			in=j
			where=(
				C_FILE_TYPE	=	"SASDAT"
			)
		)
	;

	%*200.	Create temporary fields.;
	format
		C_SAS_DAT	$64.
		C_SAS_LIB	$16.
	;
	if	i	then do;
		C_SAS_DAT	=	upcase(strip(C_INF_TABLE));
	end;
	else do;
		C_SAS_DAT	=	upcase(strip(C_FILE_NAME));
	end;
	C_SAS_DAT	=	resolve(C_SAS_DAT);
	C_SAS_LIB	=	scan(C_SAS_DAT,1,".");
	C_FILE_SRC	=	resolve(C_FILE_SRC);

	%*900.	Purge.;
	keep
		C_SAS_DAT
		C_SAS_LIB
		C_FILE_SRC
	;
run;

%*320.	Retrieve the unique file names.;
proc sort
	data=work2.__kpi_othsrc_sas
	nodupkey
;
	by	C_SAS_DAT;
run;

%*330.	Identify the physical location of the SAS datasets to be stored.;
%*331.	Retrieve unique libnames.;
proc sort
	data=work2.__kpi_othsrc_sas(keep=C_SAS_LIB)
	out=work2.__kpi_othsrc_sas_chklib
	nodupkey
;
	by	C_SAS_LIB;
run;

%*332.	Create macro variables of the libnames.;
data _NULL_;
	set work2.__kpi_othsrc_sas_chklib end=EOF;
	call symputx(cats("LeOthSasLib",_N_),C_SAS_LIB,"L");
	if	EOF	then do;
		call symputx("LnOthSasLib",_N_,"L");
	end;
run;

%*335.	Identify the physical locations of the SAS libnames.;
%do Li=1 %to &LnOthSasLib.;
	%*100.	Retrieve all the paths assigned together to current library.;
	%*Below macro is from "&cdwmac.\FileSystem";
	%FS_getPathList4Lib(
		inDSN		=	&&LeOthSasLib&Li..
		,outCNT		=	LnTempLib
		,outELpfx	=	LeTempLib
		,fDequote	=	1
	)

	%*200.	We only reserve the last path, since these paths may exist in Time sequence.;
	%*e.g. \201501, \201502, ...;
	%local	LpLib_&&LeOthSasLib&Li..;
	%let	LpLib_&&LeOthSasLib&Li..	=	&&LeTempLib&LnTempLib..;
%end;
%EndOfOthSasLib:

%*350.	Check the file status.;
data work2.__kpicfg_src_OthSas;
	%*010.	Create the standard fields.;
	%*Below macro is from "&macroot.\010Proc";
	%InitVar_ChkSrc

	%*100.	Set the configuration table.;
	set work2.__kpi_othsrc_sas end=EOF;

	%*300.	Create temporary fields.;
	format
		DatExt	$16.
	;
	DatExt	=	".sas7bdat";

	%*400.	Identify all the required source data.;
	C_SRC_PATH	=	strip(C_FILE_SRC);
	C_SRC_NAME	=	cats(scan(C_SAS_DAT,-1,"."),DatExt);
	C_DES_PATH	=	strip(symget(cats("LpLib_",C_SAS_LIB)));
	C_SRC_TYPE	=	"20.Other SAS Datasets";
	F_SRC_MISS	=	1 - exist(C_SAS_DAT);
run;

%*400.	Other files that are to be retrieved as source.;
proc sort
	data=&L_srcflnm4.(
		where=(
			C_FILE_TYPE	^=	"SASDAT"
		)
	)
	out=work2.__kpi_othsrc_oth
	nodupkey
;
	by	C_FILE_NAME;
run;
data work2.__kpicfg_src_OthFil;
	%*010.	Create the standard fields.;
	%*Below macro is from "&macroot.\010Proc";
	%InitVar_ChkSrc

	%*100.	Set the configuration table.;
	set work2.__kpi_othsrc_oth end=EOF;

	%*300.	Create temporary fields.;
	C_FILE_NAME	=	resolve(C_FILE_NAME);
	C_FILE_SRC	=	resolve(C_FILE_SRC);

	%*400.	Identify all the required source data.;
	C_SRC_PATH	=	strip(C_FILE_SRC);
	C_SRC_NAME	=	scan(C_FILE_NAME,-1,"\");
	C_DES_PATH	=	substr(C_FILE_NAME,1,length(C_FILE_NAME) - index(reverse(strip(C_FILE_NAME)),"\"));
	C_SRC_TYPE	=	"30.Other Files";
	F_SRC_MISS	=	1 - fileexist(C_FILE_NAME);
run;

%*800.	Create the dataset that stores the necessary checking results, such as existence, file names, etc.;
data work2.__kpicfg_Retrieval;
	%*001.	Create D_TABLE.;
	%*Below macro is from "&cdwmac.\AdvOp";
	%cr_d_table

	%*100.	Set all the required datasets.;
	set
		work2.__kpicfg_src
		work2.__kpicfg_src_OthSas
		work2.__kpicfg_src_OthFil
	;

	%*300.	Create temporary fields.;
	format
		tmpPath	$512.
	;

	%*400.	Presume that the source path is the same as in the destination, if it is NOT provided.;
	if	missing(C_SRC_PATH)	=	1	then do;
		C_SRC_PATH	=	C_DES_PATH;
	end;

	%*500.	Generate the temporary paths in the transporting media, on behalf of the path on the source location.;
	%*Remove all leading back slashes.;
	tmpPath	=	C_SRC_PATH;
	do while (index(tmpPath,"\") = 1);
		tmpPath	=	substr(tmpPath,2);
	end;
	tmpPath	=	translate(tmpPath,"_",":");
	C_MED_PATH	=	strip(tmpPath);

	%*900.	Purge.;
	drop
		tmp:
	;
run;

%*900.	Dedup.;
proc sort
	data=work2.__kpicfg_Retrieval
	out=&L_stpflnm.(compress=yes)
	noduprecs
;
	by	C_SRC_TYPE;
run;

%EndOfProc:
%mend vfyRptSrc;
%vfyRptSrc