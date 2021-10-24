%macro DBcr_LoadDict(
	DictProc
	,preProc
	,cfg_KPIs	=	src.cfg_kpi
	,cfg_Vars	=	WORK.__ETLcfg_Vars__
	,cfg_Libs	=	WORK.__ETLcfg_Libs__
	,cfg_Stgs	=	WORK.__ETLcfg_Stgs__
	,cfg_Pgms	=	WORK.__ETLcfg_Pgms__
	,cfg_Dats	=	WORK.__ETLcfg_Dats__
	,procLIB	=	WORK
	,fDebug		=	0
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to load the Data Dictionary in a pre-defined format and establish the working environment.					|
|	|[1] Create necessary macro variables																								|
|	|[2] Establish links to all required libraries																						|
|	|[3] Interpret the workflows and dataflows in terms of the environment																|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|DictProc	:	The raw EXCEL file which stores the ETL workflow and dictionaries of all projects									|
|	|preProc	:	The statements to generate various variables in current environment													|
|	|				It must be provided as a full path of the SAS program, including the file extension, such as [C:\aa.sas].			|
|	|cfg_KPIs	:	The input dataset that stores the configuration of KPIs for data management											|
|	|				Default : [src.cfg_kpi]																								|
|	|cfg_Vars	:	The output dataset that stores the content of the original sheet [Overall] in the raw ETL file						|
|	|				Default : [WORK.__ETLcfg_Vars__]																					|
|	|cfg_Libs	:	The output dataset that stores the linkage information of all libraries in current session							|
|	|				Default : [WORK.__ETLcfg_Libs__]																					|
|	|cfg_Stgs	:	The output dataset that stores the stages of current project														|
|	|				Default : [WORK.__ETLcfg_Stgs__]																					|
|	|cfg_Pgms	:	The output dataset that stores the related program flows of current project											|
|	|				Default : [WORK.__ETLcfg_Pgms__]																					|
|	|cfg_Dats	:	The output dataset that stores the data flows of current project													|
|	|				Default : [WORK.__ETLcfg_Dats__]																					|
|	|procLIB	:	The working library.																								|
|	|				Default : [WORK]																									|
|	|fDebug		:	The switch of Debug Mode. Valid values are [0] or [1].																|
|	|				Default: [0]																										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20181111		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
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
|	|	|ErrMcr																															|
|	|	|list_sasautos																													|
|	|	|getMCRbySTR																													|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\FileSystem"																						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|OSDirDlm																														|
|	|	|getMemberByStrPattern																											|
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
%if	%length(%qsysfunc(compress(&DictProc.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.][DictProc] is not provided!;
	%ErrMcr
%end;
%let	DictProc	=	%qsysfunc(strip(&DictProc.));

%if	%length(%qsysfunc(compress(&preProc.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.][preProc] is not provided!;
	%ErrMcr
%end;
%let	preProc	=	%qsysfunc(strip(&preProc.));

%if	%length(%qsysfunc(compress(&cfg_KPIs.,%str( ))))	=	0	%then	%let	cfg_KPIs	=	src.cfg_kpi;
%let	cfg_KPIs	=	%qsysfunc(strip(&cfg_KPIs.));
%if	%length(%qsysfunc(compress(&cfg_Vars.,%str( ))))	=	0	%then	%let	cfg_Vars	=	WORK.__ETLcfg_Vars__;
%if	%length(%qsysfunc(compress(&cfg_Libs.,%str( ))))	=	0	%then	%let	cfg_Libs	=	WORK.__ETLcfg_Libs__;
%if	%length(%qsysfunc(compress(&cfg_Stgs.,%str( ))))	=	0	%then	%let	cfg_Stgs	=	WORK.__ETLcfg_Stgs__;
%if	%length(%qsysfunc(compress(&cfg_Pgms.,%str( ))))	=	0	%then	%let	cfg_Pgms	=	WORK.__ETLcfg_Pgms__;
%if	%length(%qsysfunc(compress(&cfg_Dats.,%str( ))))	=	0	%then	%let	cfg_Dats	=	WORK.__ETLcfg_Dats__;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))		=	0	%then	%let	procLIB		=	WORK;
%if	%length(%qsysfunc(compress(&fDebug.,%str( ))))		=	0	%then	%let	fDebug		=	0;
%if	&fDebug.^=	0	%then	%let	fDebug		=	1;

%*013.	Define the global environment.;

%*014.	Define the local environment.;
%local
	OptNotes	OptSource	OptSource2	OptMLogic	OptSymGen	OptMPrint	OptInOper
	Si			Mi			Mj
;

%*016.	Switch off the system options to reduce the LOG size.;
%if %sysfunc(getoption( notes ))		=	NOTES		%then	%let	OptNotes	=	1;	%else	%let	OptNotes	=	0;
%if %sysfunc(getoption( source ))		=	SOURCE		%then	%let	OptSource	=	1;	%else	%let	OptSource	=	0;
%if %sysfunc(getoption( source2 ))		=	SOURCE2		%then	%let	OptSource2	=	1;	%else	%let	OptSource2	=	0;
%if %sysfunc(getoption( mlogic ))		=	MLOGIC		%then	%let	OptMLogic	=	1;	%else	%let	OptMLogic	=	0;
%if %sysfunc(getoption( symbolgen ))	=	SYMBOLGEN	%then	%let	OptSymGen	=	1;	%else	%let	OptSymGen	=	0;
%if %sysfunc(getoption( mprint ))		=	MPRINT		%then	%let	OptMPrint	=	1;	%else	%let	OptMPrint	=	0;
%if %sysfunc(getoption( minoperator ))	=	MINOPERATOR	%then	%let	OptInOper	=	1;	%else	%let	OptInOper	=	0;
%*The default value of the system option [MINDELIMITER] is WHITE SPACE, given the option [MINOPERATOR] is on.;
%if	&fDebug.	=	0	%then %do;
options nonotes nosource nosource2 nomlogic nosymbolgen nomprint minoperator;
%end;

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in traditional SAS syntax colors.;
%macro dummy; %mend dummy;

%*049.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*All input values.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [DictProc=&DictProc.];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [preProc=&preProc.];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [cfg_KPIs=%qsysfunc(strip(&cfg_KPIs.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [cfg_Vars=%qsysfunc(strip(&cfg_Vars.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [cfg_Libs=%qsysfunc(strip(&cfg_Libs.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [cfg_Stgs=%qsysfunc(strip(&cfg_Stgs.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [cfg_Pgms=%qsysfunc(strip(&cfg_Pgms.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [cfg_Dats=%qsysfunc(strip(&cfg_Dats.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [procLIB=&procLIB.];
%end;

%*100.	Import the raw ETL file.;
proc import
	datafile	=	%sysfunc(quote( &DictProc. , %str(%') ))
	out			=	%unquote(&cfg_Vars.)
	dbms		=	EXCEL
	replace
;
	sheet		=	"Overall$";
	getnames	=	YES;
	scantext	=	YES;
run;
proc import
	datafile	=	%sysfunc(quote( &DictProc. , %str(%') ))
	out			=	%unquote(&cfg_Stgs.)
	dbms		=	EXCEL
	replace
;
	sheet		=	"Stages$";
	getnames	=	YES;
	scantext	=	YES;
run;
proc import
	datafile	=	%sysfunc(quote( &DictProc. , %str(%') ))
	out			=	&procLIB..__rawcfg_WorkFlow_pre__
	dbms		=	EXCEL
	replace
;
	sheet		=	"Workflow$";
	getnames	=	YES;
	scantext	=	YES;
run;
proc import
	datafile	=	%sysfunc(quote( &DictProc. , %str(%') ))
	out			=	&procLIB..__rawcfg_DataFlow_pre__
	dbms		=	EXCEL
	replace
;
	sheet		=	"DataFlow$";
	getnames	=	YES;
	scantext	=	YES;
run;

%*200.	Establish basic environment.;
%*210.	Resolve the macro variables in terms of the variable settings.;
data &procLIB..__rawcfg_var__;
	%*100.	Set the raw data.;
	set
		%unquote(&cfg_Vars.)(
			where=(
					upcase(Type)	=	"SAS VARIABLE"
				and	index( upcase(Reference) , ".SAS" )
			)
		)
	;

	%*200.	Resolve dedicated macro variables at first.;
	if	lowcase(Item)	=	"curstg"	then	Value	=	symget( "curstg" );
	if	lowcase(Item)	=	"cdwmac"	then	Value	=	symget( "cdwmac" );

	%*900.	Resolve the rest of all macro variables.;
	call symputx( Item , Value , "G" );
run;

%*220.	Create the necessary links to the libraries.;
data %unquote(&cfg_Libs.);
	%*100.	Set the raw data.;
	set
		%unquote(&cfg_Vars.)(
			where=(
					upcase(Type)	=	"LIBRARY"
				and	index( upcase(Reference) , ".SAS" )
			)
		)
	;

	%*200.	Resolve the path names of the libraries.;
	Item	=	lowcase(resolve( Item ));
	Value	=	resolve( Value );

	%*300.	Create the paths if they do not exist.;
	%*Please note that we have to preserve the character case during the directory creation.;
	%*Below function is from "&cdwmac.\FileSystem";
	_iorc_	=	mkdir( Value , "%OSDirDlm" );

	%*400.	Set the name of the path to lower case for later process.;
	Value	=	lowcase( Value );

	%*800.	Establish the link to the library.;
	_iorc_	=	libname( Item , Value , "base" );
run;

%*300.	Resolve the macro variables in other configuration tables.;
%*310.	Stages.;
data %unquote(&cfg_Stgs.);
	%*050.	Create standard variables.;
	length
		N_Seq_Stg	8
	;

	%*100.	Set the raw data.;
	set %unquote(&cfg_Stgs.);
	Stage_Name		=	lowcase(resolve( Stage_Name ));
	Stage_Location	=	lowcase(resolve( Stage_Location ));
	N_Seq_Stg		=	Stage_Sequence;
run;

%*320.	Program flow.;
data %unquote(&cfg_Pgms.);
	%*050.	Create standard variables.;
	length
		C_PGMNAME	$1024
		N_Seq_Pgm	8
	;

	%*100.	Set the raw data.;
	set
		&procLIB..__rawcfg_WorkFlow_pre__(
			where=(
				index( upcase(Program_Name) , ".SAS" )
			)
		)
	;
	Program_Name		=	lowcase(resolve( Program_Name ));
	Program_Location	=	lowcase(resolve( Program_Location ));
	C_PGMNAME			=	catx( "%OSDirDlm" , Program_Location , Program_Name );
	N_Seq_Pgm			=	Sequence_in_Stage;
run;

%*400.	Extend the autocall macro library.;
%*410.	Identify the sub-directories of [cdwmac].;
%getMemberByStrPattern(
	inDIR		=	&cdwmac.
	,inRegExp	=	%nrbquote(.*)
	,exclRegExp	=
	,chkType	=	2
	,FSubDir	=	0
	,mNest		=	0
	,outCNT		=	GnOmniMac
	,outELpfx	=	GeOmniMac
	,outElTpPfx	=	GtOmniMac
	,outElPPfx	=	GpOmniMac
	,outElNmPfx	=	GmOmniMac
)

%*410.	Identify the sub-directories of [macroot].;
%getMemberByStrPattern(
	inDIR		=	&macroot.
	,inRegExp	=	%nrbquote(.*)
	,exclRegExp	=
	,chkType	=	2
	,FSubDir	=	0
	,mNest		=	0
	,outCNT		=	GnMacRoot
	,outELpfx	=	GeMacRoot
	,outElTpPfx	=	GtMacRoot
	,outElPPfx	=	GpMacRoot
	,outElNmPfx	=	GmMacRoot
)

%*490.	Extend the library.;
options
	sasautos=(
		sasautos
	%do Mi=1 %to &GnOmniMac.;
		%sysfunc(quote( &&GeOmniMac&Mi.. , %str(%') ))
	%end;
	%do Mj=1 %to &GnMacRoot.;
		%sysfunc(quote( &&GeMacRoot&Mj.. , %str(%') ))
	%end;
	)
;

%*500.	Load all user defined Functions and Subroutines.;
%*510.	Generate the list for all predefined usable macros.;
%list_sasautos

%*520.	Retrieve all macro names beginning with "usFUN_" or "usSUB_";
%getMCRbySTR(
	FUZZY	=	0
	,inNAME	=
			usFUN_
			usSUB_
	,NMidx	=	1
	,outMEL	=	LeFUNSUB
	,outMT	=	LnFUNSUB
	,outLIB	=	&procLIB.
)

%*530.	Call each macro to run FCmp Procedure.;
%if	&LnFUNSUB.	=	0	%then %do;
	%goto	EndOfFunc;
%end;
options	cmplib=_NULL_;
proc FCmp
	outlib=WORK.mySubs.usr
;
	%do	FUNi=1	%to	&LnFUNSUB.;
		%&&LeFUNSUB&FUNi..
	%end;
run;
quit;
options	cmplib=WORK.mySubs;
%EndOfFunc:

%*540.	Retrieve all macro names beginning with "fmt_" or "cdwfmt_";
%*Below macro is from "&cdwmac.\AdvOp";
%getMCRbySTR(
	FUZZY	=	0
	,inNAME	=
			fmt_
			cdwfmt_
	,NMidx	=	1
	,outMEL	=	LMEL
	,outMT	=	LMTTL
	,outLIB	=	&procLIB.
)

%*550.	Call each macro in consequence.;
%if	&LMTTL.	=	0	%then %do;
	%goto	EndOfFmt;
%end;
proc format;
	%do	TRANSVALi=1	%to	&LMTTL.;
		%&&LMEL&TRANSVALi..
	%end;
run;
%EndOfFmt:

%*560.	Call an external program to define the further environment.;
%include	%sysfunc(quote( &preProc. , %str(%') ));

%*580.	Load Ad hoc patches.;
%*581.	Identify unique stages.;
data _NULL_;
	set %unquote(&cfg_Stgs.) end=EOF;
	call symputx( cats("GeStg",_N_) , Stage_Location , "G" );
	if	EOF	then	call symputx( "GnStg" , _N_ , "G" );
run;

%*585.	Call ad hoc patches in all stages.;
%do Si=1 %to &GnStg.;
	%include	%sysfunc(quote( %superq(GeStg&Si.)\AdhocPatch.sas , %str(%') ));
	%AdhocPatch
%end;

%*330.	Data flow.;
data &procLIB..__rawcfg_DataFlow_pre__;
	%*100.	Set the raw data.;
	set &procLIB..__rawcfg_DataFlow_pre__( where=( upcase( Data_Location ) ^= "[WORK]" ) );

	%*200.	Retrieve the data location of KPIs if any.;
	%*210.	Prepare to load the KPI configuration table.;
	if	0	then	set	%unquote(&cfg_KPIs.)(keep=C_KPI_ID C_KPI_DAT_PATH C_KPI_DAT_NAME);
	if	_N_	=	1	then do;
		dcl	hash	hCFG( dataset:%sysfunc(quote( &cfg_KPIs. , %str(%') )) );
		hCFG.DefineKey( "C_KPI_ID" );
		hCFG.DefineData( "C_KPI_DAT_PATH" , "C_KPI_DAT_NAME" );
		hCFG.DefineDone();
	end;
	call missing( C_KPI_DAT_PATH , C_KPI_DAT_NAME );

	%*219.	Skip the loading if current observation does not represent KPI data.;
	if	upcase( Data_Location )	^=	"{CFG_KPI}"	then	goto	EndOfKpiCfg;

	%*220.	Load the KPI configuration table.;
	_iorc_	=	hCFG.find(key:Data_Name);

	%*250.	Retrieve the data location.;
	Data_Name		=	C_KPI_DAT_NAME;
	Data_Location	=	C_KPI_DAT_PATH;

	%*299.	Mark the end of the special process for KPI.;
	EndOfKpiCfg:

	%*300.	Resolve macro variables for data names and locations.;
	%*310.	Resolve the macro variables.;
	Data_Name			=	lowcase(resolve( Data_Name ));
	Data_Location		=	lowcase(resolve( Data_Location ));
	Program_Name		=	lowcase(resolve( Program_Name ));
	Program_Location	=	lowcase(resolve( Program_Location ));

	%*320.	Prepare to load the library meta table.;
	if	0	then	set	%unquote(&cfg_Libs.)(keep=Item Value);
	if	_N_	=	1	then do;
		dcl	hash	hLIB( dataset:%sysfunc(quote( &cfg_Libs. , %str(%') )) );
		hLIB.DefineKey( "Item" );
		hLIB.DefineData( "Value" );
		hLIB.DefineDone();
	end;
	call missing( Value );

	%*324.	Skip the translation if current observation does not represent a library.;
	if	index( Data_Location , "[" )	=	0	then	goto	EndOfLibLoc;

	%*325.	Load the library meta table.;
	length	__tmpVar	$16;
	__tmpVar		=	substr( Data_Location , index( Data_Location , "[" ) + 1 , length( Data_Location ) - 2 );
	_iorc_			=	hLIB.find(key:__tmpVar);
	Data_Location	=	Value;

	%*329.	Mark the end of the special process for library.;
	EndOfLibLoc:

	%*900.	Purge.;
	drop	C_KPI_DAT_PATH	C_KPI_DAT_NAME	Item	Value	__tmpVar	C_KPI_ID;
run;

%*335.	Extract the absolute paths and standardize the output.;
data %unquote(&cfg_Dats.);
	%*050.	Create standard variables.;
	length
		C_FILENAME	C_PGMNAME	C_FNAME	$1024
		C_FlowType						$8
		N_Seq_Stg	N_Seq_Pgm			8
	;

	%*100.	Set the raw data.;
	set &procLIB..__rawcfg_DataFlow_pre__;

	%*200.	Prepare to identify the sequence of the programs in the ETL workflow.;
	%*210.	Stages.;
	if	0	then	set	%unquote(&cfg_Stgs.)(keep=Stage_Location N_Seq_Stg);
	if	_N_	=	1	then do;
		dcl	hash	hSTG( dataset:%sysfunc(quote( &cfg_Stgs. , %str(%') )) );
		hSTG.DefineKey( "Stage_Location" );
		hSTG.DefineData( "N_Seq_Stg" );
		hSTG.DefineDone();
	end;
	call missing( N_Seq_Stg );

	%*220.	Programs.;
	if	0	then	set	%unquote(&cfg_Pgms.)(keep=N_Seq_Pgm);
	if	_N_	=	1	then do;
		dcl	hash	hPGM( dataset:%sysfunc(quote( &cfg_Pgms. , %str(%') )) );
		hPGM.DefineKey( "Program_Location" , "Program_Name" );
		hPGM.DefineData( "N_Seq_Pgm" );
		hPGM.DefineDone();
	end;
	call missing( N_Seq_Pgm );

	%*300.	Assign the values.;
	_iorc_		=	hSTG.find(key:Program_Location);
	_iorc_		=	hPGM.find(key:Program_Location,key:Program_Name);
	C_PGMNAME	=	catx( "%OSDirDlm" , Program_Location , Program_Name );
	C_FlowType	=	strip(upcase( Flow_Type ));

	%*600.	Search for the files.;
	length
		Files		$32767
		cnt	tmpi	8
	;
	call missing(Files);
	if	Name_In_RegExp	=	"Y"	then do;
		%*Below function is from "&cdwmac.\FileSystem";
		call	getFILEbyStrPattern( Data_Location , cats( Data_Name , "\." , File_Extension , "$" ) , "" , 1 , "|" , "%OSDirDlm" , Files );
		cnt	=	count( Files , "|" ) + 1;
		do tmpi = 1 to cnt;
			C_FILENAME	=	scan( Files , tmpi , "|" );
			C_FNAME		=	scan( C_FILENAME , -1 , "%OSDirDlm" );
			output;
		end;
	end;
	else do;
		C_FILENAME	=	catx( "%OSDirDlm" , Data_Location , cats( Data_Name , "." , File_Extension ) );
		C_FNAME		=	scan( C_FILENAME , -1 , "%OSDirDlm" );
		output;
	end;

	%*900.	Purge.;
	drop
		Stage_Location Files cnt tmpi
	;
run;

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
%mend DBcr_LoadDict;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
%global
	RPT_CURR	RPT_PREV	G_cur_year	G_cur_mth	G_cur_day	G_prevyear	G_prevmth	LfKeepRpt	cdwmac	curstg	PjtDict	sp_Proc
;
%let	RPT_CURR	=	20181111;
%let	RPT_PREV	=	201810;
%let	LfKeepRpt	=	0;
%let	PjtDict		=	D:\SAS\ProgramSetTemplate\Document\Dictionary.xlsx;
%let	sp_Proc		=	D:\SAS\ProgramSetTemplate\Document\PreProc.sas;
%let	cdwmac		=	D:\SAS\omnimacro;
%let	curstg		=	1010ChkSrc;
%let	G_cur_year	=	%substr( &RPT_CURR. , 1 , 4 );
%let	G_cur_mth	=	%substr( &RPT_CURR. , 5 , 2 );
%let	G_cur_day	=	%substr( &RPT_CURR. , 7 , 2 );
%let	G_prevyear	=	%substr( &RPT_PREV. , 1 , 4 );
%let	G_prevmth	=	%substr( &RPT_PREV. , 5 , 2 );

%*010.	Prepare the tools.;
options
	sasautos=(
		sasautos
		%sysfunc(quote( &cdwmac.\AdvDB , %str(%') ))
		%sysfunc(quote( &cdwmac.\AdvOp , %str(%') ))
		%sysfunc(quote( &cdwmac.\FileSystem , %str(%') ))
	)
	mautosource
	xmin
;

%*050.	Load some functions for usage at initiation.;
%*Below macros are from "&cdwmac.\FileSystem";
options cmplib=_NULL_;
proc FCmp outlib=work.pre.FS;
	%usFUN_mkdir
run;
quit;
options cmplib=work.pre;

%*100.	Load the default dictionary.;
%DBcr_LoadDict( &PjtDict. , &sp_Proc. )

/*-Notes- -End-*/