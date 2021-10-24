%macro DBuse_MrgKPItoInf(
	inInfDat	=
	,KeyOfMrg	=
	,SetAsBase	=	I
	,inKPICfg	=	src.CFG_KPI
	,outAggrBy	=
	,outDAT		=
	,procLIB	=	WORK
	,fDebug		=	0
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to merge the KPI data to the given (descriptive) information data, in terms of transposition and			|
|	| different merging methods.																										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inInfDat	:	The dataset that stores the descriptive information at certain level (Acct level or Cust level).					|
|	|KeyOfMrg	:	The list of Key field names during the merge. This requires that the same Key fields exist in both data.			|
|	|SetAsBase	:	The merging method indicating which of above data is set as the base during the merge.								|
|	|				[I] : Use "Inf" data as the base to left join the "KPI" data.														|
|	|				[K] : Use "KPI" data as the base to left join the "Inf" data.														|
|	|				[B] : Use either data as the base to inner join the other, meaning "both".											|
|	|				[F] : Use either data as the base to full join the other, meaning "full".											|
|	|				 Above parameters are case insensitive, while the default one is set as [I].										|
|	|inKPICfg	:	The dataset that stores the full configuration of the KPI.															|
|	|outAggrBy	:	The list of field names that are to be used as the classes to aggregate the source data.							|
|	|				 IMPORTANT: This list will be combined with the [KeyOfMrg] during aggregation.										|
|	|outDAT		:	The output result.																									|
|	|procLIB	:	The working library.																								|
|	|fDebug		:	The switch of Debug Mode. Valid values are [0] or [1].																|
|	|				Default: [0]																										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20160320		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20160507		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |(1) Enable the compatibility of multiple variables in the [KeyOfMrg] parameter.												|
|	|      |(2) Fixed a bug when any "KPI" source data stores other KPIs that are not required in the output,							|
|	|      |     while they are still output.																							|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20160604		| Version |	2.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Fix the bug when the source data of KPI does not exist.																		|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20160606		| Version |	2.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Add the control for the aggregation, since many operations only need to retrieve the information table, while keep the		|
|	|      | number of observations.																									|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20160626		| Version |	3.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Extract the part of the Information Loading of KPIs to a standardalone function, for it can be called in various functions.	|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20160815		| Version |	3.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |(1) Fix the LABEL in the output data when the original KPI has no label.													|
|	|      |(2) Fix a bug when the elements in [outAggrBy] do not exist in the KPI data.												|
|	|      |(3) Enhance the performance during the join of the information table to the KPI data.										|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170724		| Version |	3.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Use [SUPERQ] to mask all references to the directory names, for there could be %nrstr(&) and %nrstr(%%) in the names.		|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170815		| Version |	3.30		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Change the LABEL statement since the value in [DBcore_LoadDatInfFrKpiCfg] is changed.										|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20171018		| Version |	3.40		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Remove the macro function UNQUOTE from parameter handling, to avoid unexpected result.										|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180113		| Version |	4.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Retain the largest LENGTH of each respective variable as listed in the [KeyOfMrg] and [outAggrBy] to prevent warnings from	|
|	|      | showing when any variables among them have different lengths in the datasets to be merged.									|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180204		| Version |	5.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |[1] Add verification of the TYPE and LENGTH of all variables in the datasets to be set together, to prevent unnecessary		|
|	|      | messages from being issued in the log.																						|
|	|      |[2] Add DEBUG mode.																											|
|	|___________________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180304		| Version |	5.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180325		| Version |	6.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Introduce the function [ForceMergeDats] to combine the required datasets in an independent way.								|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180327		| Version |	7.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Introduce the function [DBuse_SetKPItoInf] to eliminate the duplication on logic setting.									|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180422		| Version |	8.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |The program now eliminates the SQL query on [dictionary.columns] during the process.										|
|	|      |This is to improve the overall efficiency when there are many KPI datasets to retrieve.										|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20210116		| Version |	8.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Now support the multiple paths to a single library in the configuration table												|
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
|	|	|genvarlist																														|
|	|	|getOBS4DATA																													|
|	|	|ErrMcr																															|
|	|	|DropVarIfExists																												|
|	|	|KeepVarIfExists																												|
|	|	|getCOLbyStrPattern																												|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvDB"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|DBcore_LoadDatInfFrKpiCfg																										|
|	|	|ForceMergeDats																													|
|	|	|DBuse_SetKPItoInf																												|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\FileSystem"																						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|FS_VarExists																													|
|	|	|SAS_getTblLocation																												|
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
%let	procLIB	=	%unquote(&procLIB.);

%if	%length(%qsysfunc(compress(&inInfDat.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]Information Table [inInfDat=&inInfDat.] is NOT provided!;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&KeyOfMrg.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]Class variable list [KeyOfMrg=] is NOT provided!;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&SetAsBase.,%str( ))))	=	0	%then	%let	SetAsBase	=	I;
%*Make sure we only retrieve the first character of the indicator.;
%let	SetAsBase	=	%upcase(%substr(&SetAsBase.,1,1));

%if	%length(%qsysfunc(compress(&inKPICfg.,%str( ))))	=	0	%then	%let	inKPICfg	=	src.CFG_KPI;
%if	%length(%qsysfunc(compress(&outAggrBy.,%str( ))))	=	0	%then	%let	outAggrBy	=	&KeyOfMrg.;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))		=	0	%then	%let	procLIB		=	WORK;
%if	%length(%qsysfunc(compress(&fDebug.,%str( ))))		=	0	%then	%let	fDebug		=	0;
%if	&fDebug.^=	0	%then	%let	fDebug		=	1;

%*013.	Define the local environment.;
%local
	OptNotes	OptSource	OptSource2	OptMLogic	OptSymGen	OptMPrint	OptInOper
	Di			Ki			Mi			Ai			Vi
	LInfDatLoc	LnDatAvail	LsDatAvail	LKpiSel		LInfModel	LAggrList
	prxREM		rc
	LjoinMthd	LmergeMthd	LchkOutDAT	LVarSel		LMrgSearch
;
%let	LInfDatLoc	=	'';
%let	LnDatAvail	=	0;
%if	&SetAsBase.	=	I	%then %do;
	%let	LmergeMthd	=	%nrstr(if _1;);
	%let	LjoinMthd	=	%str(LEFT);
%end;
%if	&SetAsBase.	=	K	%then %do;
	%let	LmergeMthd	=	%nrstr(if _2;);
	%let	LjoinMthd	=	%str(RIGHT);
%end;
%if	&SetAsBase.	=	B	%then %do;
	%let	LmergeMthd	=	%nrstr(if _1 and _2;);
	%let	LjoinMthd	=	%str(INNER);
%end;
%if	&SetAsBase.	=	F	%then %do;
	%let	LmergeMthd	=	%nrstr(if _1 or _2;);
	%let	LjoinMthd	=	%str(FULL);
%end;
%let	LInfModel	=	&procLIB..__mrgKPI_inf__;
%let	LAggrList	=;
%let	LchkOutDAT	=	0;
%let	LMrgSearch	=;

%*014.	Remove the key fields to facilitate the TRANSPOSE procedure.;
%*If the key fields [C_KPI_ID] and [A_KPI_VAL] are in the list, we remove them and issue a warning message.;
%*This is because [C_KPI_ID] has to be transposed into variables based on its values, while [A_KPI_VAL] will be;
%* set as the transposed values.;
%let	prxREM		=	%sysfunc(prxparse(s/\b(C_KPI_ID|A_KPI_VAL)\b//ismx));
%if		%sysfunc(prxmatch(&prxREM.,%nrbquote(&KeyOfMrg.)))
	or	%sysfunc(prxmatch(&prxREM.,%nrbquote(&outAggrBy.)))
	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]Field [C_KPI_ID] and [A_KPI_VAL] are removed from the classes, for they are to be transposed.;
%end;
%let	KeyOfMrg	=	%qsysfunc(prxchange(&prxREM.,-1,%nrbquote(&KeyOfMrg.)));
%let	outAggrBy	=	%qsysfunc(prxchange(&prxREM.,-1,%nrbquote(&outAggrBy.)));
%syscall	prxfree(prxREM);

%*016.	Switch off the system options to reduce the LOG size.;
%if %sysfunc(getoption( notes ))		=	NOTES		%then	%let	OptNotes	=	1;	%else	%let	OptNotes	=	0;
%if %sysfunc(getoption( source ))		=	SOURCE		%then	%let	OptSource	=	1;	%else	%let	OptSource	=	0;
%if %sysfunc(getoption( source2 ))		=	SOURCE2		%then	%let	OptSource2	=	1;	%else	%let	OptSource2	=	0;
%if %sysfunc(getoption( mlogic ))		=	MLOGIC		%then	%let	OptMLogic	=	1;	%else	%let	OptMLogic	=	0;
%if %sysfunc(getoption( symbolgen ))	=	SYMBOLGEN	%then	%let	OptSymGen	=	1;	%else	%let	OptSymGen	=	0;
%if %sysfunc(getoption( mprint ))		=	MPRINT		%then	%let	OptMPrint	=	1;	%else	%let	OptMPrint	=	0;
%if %sysfunc(getoption( minoperator ))	=	MINOPERATOR	%then	%let	OptInOper	=	1;	%else	%let	OptInOper	=	0;
%*The default value of the system option [MINDELIMITER] is WHITE SPACE, given the option [MINOPERATOR] is on.;
options nonotes nosource nosource2 nomlogic nosymbolgen nomprint minoperator;

%*018.	Define the global environment.;
%genvarlist(
	nstart		=	1
	,inlst		=	&KeyOfMrg.
	,nvarnm		=	LeKeyOfMrg
	,nvarttl	=	LnKeyOfMrg
)
%do Mi=1 %to &LnKeyOfMrg.;
	%let	LMrgSearch	=	&LMrgSearch.|&&LeKeyOfMrg&Mi..;
%end;
%let	LMrgSearch	=	%qsubstr( &LMrgSearch. , 2 );
%genvarlist(
	nstart		=	1
	,inlst		=	&outAggrBy.
	,nvarnm		=	LeOutAggrBy
	,nvarttl	=	LnOutAggrBy
)

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in traditional SAS syntax colors.;
%macro dummy; %mend dummy;

%*090.	Combine the lists [KeyOfMrg] and [outAggrBy] for below steps, esp. the TRANSPOSE procedure.;
%*091.	Put both lists into a dataset.;
data &procLIB..__mrgKPI_KeyList__;
	%*100.	Set the length of the variable name as 32 on behalf of SAS system setup.;
	length	C_VAR_NAME	$32.;

	%*200.	Input the lists.;
%do Mi=1 %to &LnKeyOfMrg.;
	C_VAR_NAME	=	"&&LeKeyOfMrg&Mi..";
	output;
%end;
%do Ai=1 %to &LnOutAggrBy.;
	C_VAR_NAME	=	"&&LeOutAggrBy&Ai..";
	output;
%end;
run;

%*092.	Remove the duplicated variable names.;
proc sort
	data=&procLIB..__mrgKPI_KeyList__
	out=&procLIB..__mrgKPI_KeyDedup__
	nodupkey
;
	by	C_VAR_NAME;
run;

%*095.	Create the combined list.;
data _NULL_;
	set &procLIB..__mrgKPI_KeyDedup__ end=EOF;
	by	C_VAR_NAME;
	call symputx(cats("LeAggrBy",_N_),C_VAR_NAME,"L");
	if	EOF	then do;
		call symputx("LnAggrBy",_N_,"L");
	end;
run;
%do Ai=1 %to &LnAggrBy.;
	%let	LAggrList	=	&LAggrList. &&LeAggrBy&Ai..;
%end;

%*099.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*100.	All input values.;
	%if	%length(%qsysfunc(compress(&inInfDat.,%str( ))))	=	0	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [inInfDat=].;
	%end;
	%else %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [inInfDat=%qsysfunc(compbl(&inInfDat.))].;
	%end;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [KeyOfMrg=%qsysfunc(compbl(&KeyOfMrg.))].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [SetAsBase=&SetAsBase.].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [inKPICfg=%qsysfunc(compbl(&inKPICfg.))].;
	%if	%length(%qsysfunc(compress(&outAggrBy.,%str( ))))	=	0	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [outAggrBy=].;
	%end;
	%else %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [outAggrBy=%qsysfunc(compbl(&outAggrBy.))].;
	%end;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [outDAT=%qsysfunc(compbl(&outDAT.))].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [procLIB=&procLIB.].;

	%*200.	Method to join the tables.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Method to join the tables: [LjoinMthd=&LjoinMthd.].;

	%*300.	Variables to be grouped during the aggregation.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Variables to be grouped during the aggregation are listed as below:;
	%do Ai=1 %to &LnAggrBy.;
		%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [LeAggrBy&Ai.=&&LeAggrBy&Ai..].;
	%end;
%end;

%*100.	Identify all the required KPIs in the configuration table.;
%*The series of macro variables regarding the KPI list are generated by below macro.;
%DBcore_LoadDatInfFrKpiCfg(
	inKPICfg		=	&inKPICfg.
	,nKpiID			=	MnKpi
	,pfxKpiID		=	MeKpiID
	,pfxKpiName		=	MeKpiNM
	,pfxKpiLbl		=	MeKpiLBL
	,pfxKpiFmt		=	MeKpiFMT
	,nKpiDat		=	MnKpiDat
	,pfxKpiDatPath	=	MeKpiDatPath
	,pfxKpiDatName	=	MeKpiDatName
	,procLIB		=	&procLIB.
)
%*NOTE: It can also be called in below manner.;
%*DBcore_LoadDatInfFrKpiCfg( inKPICfg = &inKPICfg. );

%*190.	Quit the process if there is no KPI defined in the inventory.;
%if	&MnKpi.	=	0	%then %do;
	%put	%str(I)NFO: [&L_mcrLABEL.]No KPI is defined for retrieval. Skip the process.;
	%goto	EndOfProc;
%end;

%*195.	Define the KPI list for the selection within each dataset.;
%do Ki=1 %to &MnKpi.;
	%let	LKpiSel	=	&LKpiSel. %qsysfunc(quote(&&MeKpiID&Ki..));
%end;

%*199.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*Attributes of KPIs.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Total # of KPI IDs: [MnKpi=&MnKpi.].;
	%do Ki=1 %to &MnKpi.;
		%put	%str(I)NFO: [&L_mcrLABEL.][MeKpiID&Ki.=&&MeKpiID&Ki..][MeKpiNM&Ki.=&&MeKpiNM&Ki..][MeKpiLBL&Ki.=&&MeKpiLBL&Ki..][MeKpiFMT&Ki.=&&MeKpiFMT&Ki..];
	%end;

	%*Attributes of KPI datasets.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Total # of KPI datasets: [MnKpiDat=&MnKpiDat.].;
	%do Di=1 %to &MnKpiDat.;
		%put	%str(I)NFO: [&L_mcrLABEL.][MeKpiDatPath&Di.=&&MeKpiDatPath&Di..][MeKpiDatName&Di.=&&MeKpiDatName&Di..];
	%end;
%end;

%*200.	Identify the datasets that store the required KPIs.;
%do Di=1 %to &MnKpiDat.;
	%*100.	Create the Libnames for each unique dataset location.;
	%local
		LeKpiDatLib&Di.
		LprLeft
		LprRight
	;
	%let	LeKpiDatLib&Di.	=	_k&Di.;

	%*150.	Determine whether to enclose the location with Parentheses (pr), given the existence of single or double quotation marks.;
	%*If there is only one valid path for the library, we cannot enclose it with parentheses by the syntax.;
	%if	%index( %superq(SeKpiDatPath&Di.) , %str(%') ) ^= 0 or %index( %superq(SeKpiDatPath&Di.) , %str(%") ) ^= 0	%then %do;
		%let	LprLeft		=	%str(%();
		%let	LprRight	=	%str(%));
	%end;
	%else %do;
		%let	LprLeft		=;
		%let	LprRight	=;
	%end;

	%*200.	Assign the library.;
	%let	rc	=	%sysfunc( libname( &&LeKpiDatLib&Di.. , &LprLeft.%superq(MeKpiDatPath&Di.)&LprRight. , BASE , access=readonly ) );

	%*300.	Verify whether current dataset exists.;
	%local	LeKpiDatExist&Di.;
	%let	LeKpiDatExist&Di.	=	%sysfunc(exist(&&LeKpiDatLib&Di...&&MeKpiDatName&Di..));
%end;

%*209.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%do Di=1 %to &MnKpiDat.;
		%put	%str(I)NFO: [&L_mcrLABEL.]Dataset Existence: [LeKpiDatExist&Di.=&&LeKpiDatExist&Di..], name: [MeKpiDatName&Di.=&&MeKpiDatName&Di..];
	%end;
%end;

%*290.	If no KPI source data is found in the process, we end the process.;
%do Di=1 %to &MnKpiDat.;
	%*100.	Increment the counter if any source data exists.;
	%let	LchkOutDAT	=	%eval( &LchkOutDAT. + &&LeKpiDatExist&Di.. );
%end;
%if	&LchkOutDAT.	=	0	%then %do;
	%put	%str(I)NFO: [&L_mcrLABEL.]KPI source data is not found for the retrieval from Information Tables. Skip the process.;
	%goto	EndOfProc;
%end;

%*310.	Retrieve the location of the Information Table for logging purpose.;
%*319.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*Below value is enclosed by single quotation marks, hence please be cautious when referencing it.;
	%let	LInfDatLoc	=	%SAS_getTblLocation( inDAT = &inInfDat. );
	%put	%str(I)NFO: [&L_mcrLABEL.]Location of Information Dataset: [LInfDatLoc=&LInfDatLoc.];
%end;

%*320.	Sort the input information table.;
proc sort
	data=%unquote(&inInfDat.)
	out=&LInfModel.
	nodupkey
	dupout=&procLIB..__mrgKPI_inf_dup__
;
	by
	%do Mi=1 %to &LnKeyOfMrg.;
		&&LeKeyOfMrg&Mi..
	%end;
	;
run;

%*329.	Should there be any duplications in the information table, this process is abandoned.;
%if	%getOBS4DATA( inDAT = &procLIB..__mrgKPI_inf_dup__ , gMode = F )	>	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]Program found Duplicated KEY in [&inInfDat.], will terminate immediately! Duplications have been output to [&procLIB..__mrgKPI_inf_dup__].;
	%put	&Lohno.;
	%ErrMcr
%end;

%*400.	Retrieve all the required KPIs.;
%*410.	Only keep the minimum necessary set of variables from the [LInfModel] to combine the KPI datasets as required.;
data &procLIB..__mrgKPI_inf_min__;
	set
		&LInfModel.(
			%KeepVarIfExists(
				inDAT		=	&LInfModel.
				,inFLDlst	=	%nrbquote(&LAggrList.)
				,gMode		=	DSOPT
			)
		)
	;
run;

%*450.	Call the pre-defined process to set the required KPI datasets together with the information table as minimized above.;
%DBuse_SetKPItoInf(
	inInfDat	=	&procLIB..__mrgKPI_inf_min__
	,KeyOfMrg	=	&KeyOfMrg.
	,SetAsBase	=	&SetAsBase.
	,inKPICfg	=	&inKPICfg.
	,outDAT		=	&procLIB..__mrgKPI_KpiAll__
	,procLIB	=	&procLIB.
	,fDebug		=	&fDebug.
)

%*600.	Transpose the KPI data.;
%*610.	Ensure there is no duplication for the Key field.;
proc means
	data=&procLIB..__mrgKPI_KpiAll__
	noprint
	missing
	nway
;
	class
	%do Ai=1 %to &LnAggrBy.;
		&&LeAggrBy&Ai..
	%end;
		C_KPI_ID
	;
	var
		A_KPI_VAL
	;
	output
		out=&procLIB..__mrgKPI_KpiAll__mns__
		sum=A_KPI_VAL
	;
run;

%*520.	Sort the data for transposition.;
proc sort
	data=&procLIB..__mrgKPI_KpiAll__mns__
;
	by
	%do Ai=1 %to &LnAggrBy.;
		&&LeAggrBy&Ai..
	%end;
	;
run;

%*530.	Transposition.;
%*We need to combine the BY groups in this procedure, as there will be warning issued if there are any fields included;
%* in both lists.;
proc transpose
	data=&procLIB..__mrgKPI_KpiAll__mns__
	out=&procLIB..__mrgKPI_KpiAll__trns__
	prefix=_
;
	by
	%do Ai=1 %to &LnAggrBy.;
		&&LeAggrBy&Ai..
	%end;
	;
	id	C_KPI_ID;
	var	A_KPI_VAL;
run;

%*540.	Rename all the variables.;
data &procLIB..__mrgKPI_KpiAll4mrg__;
	%*100.	Set the data.;
	set &procLIB..__mrgKPI_KpiAll__trns__;

	%*200.	Create the field storing the value of the new KPI.;
	%*210.	Presume all fields that represent the KPIs are numeric and set their lengths as 8, the maximum.;
	length
	%do Ki=1 %to &MnKpi.;
		&&MeKpiNM&Ki..	8
	%end;
	;

	%*220.	Format.;
	%do Ki=1 %to &MnKpi.;
		%if	%length(%qsysfunc(compress(&&MeKpiFMT&Ki..,%str( ))))	=	0	%then %do;
			format	&&MeKpiNM&Ki..	&&MeKpiFMT&Ki..;
		%end;
	%end;

	%*230.	Labels.;
	%*This statement should be created separately, since there could be NO label for any of the fields.;
	%do Ki=1 %to &MnKpi.;
		%if	&&MeKpiLBL&Ki..	^=	''	%then %do;
			label	&&MeKpiNM&Ki..	=	&&MeKpiLBL&Ki..;
		%end;
	%end;

	%*300.	Assign the values.;
	%do Ki=1 %to &MnKpi.;
			call missing(&&MeKpiNM&Ki..);
		%if	%FS_VarExists( inDAT = &procLIB..__mrgKPI_KpiAll__trns__ , inFLD = _&&MeKpiID&Ki.. )	%then %do;
			&&MeKpiNM&Ki..	=	_&&MeKpiID&Ki..;
		%end;
	%end;

	%*900.	Purge.;
	keep
	%do Ai=1 %to &LnAggrBy.;
		&&LeAggrBy&Ai..
	%end;
	%do Ki=1 %to &MnKpi.;
		&&MeKpiNM&Ki..
	%end;
	;
run;

%*800.	Merge the KPIs to the information variables.;
%*810.	Determine which variables are to be removed from the information table before the final merge.;
%*[1] All variables in [&procLIB..__mrgKPI_KpiAll4mrg__] except the ones in [KeyOfMrg];
%getCOLbyStrPattern(
	inDAT		=	&procLIB..__mrgKPI_KpiAll4mrg__
	,inRegExp	=
	,exclRegExp	=	&LMrgSearch.
	,chkVarTP	=	ALL
	,outCNT		=	LnMK
	,outELpfx	=	LeMK
)
%let	LVarSel	=;
%do Vi=1 %to &LnMK.;
	%let	LVarSel	=	&LVarSel. &&LeMK&Vi..;
%end;

%*819.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%put	%str(I)NFO: [&L_mcrLABEL.]Below variables are to be removed from [&LInfModel.] before the final merge:;
	%put	%str(I)NFO: [&L_mcrLABEL.][&LVarSel.];
%end;

%*820.	Prepare the information table for final merge.;
data &procLIB..__mrgKPI_inf4mrg__;
	set
		&LInfModel.(in=i
		%if	%length(%qsysfunc(compress(&LVarSel.,%str( ))))	^=	0	%then %do;
			%DropVarIfExists(
				inDAT		=	&LInfModel.
				,inFLDlst	=	&LVarSel.
				,gMode		=	DSOPT
			)
		%end;
		)
	;
run;

%*850.	Combine the datasets.;
%ForceMergeDats(
	inDatLst	=	%nrbquote(
						&procLIB..__mrgKPI_inf4mrg__
						&procLIB..__mrgKPI_KpiAll4mrg__
					)
	,ModelDat	=	&procLIB..__mrgKPI_inf4mrg__
	,MixedType	=	N
	,MergeProc	=	MERGE
	,byVAR		=	&KeyOfMrg.
	,addProc	=	&LmergeMthd.
	,outDAT		=	&outDAT.
	,fDebug		=	&fDebug.
)

%*900.	Purge.;

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
%mend DBuse_MrgKPItoInf;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvDB"
		"D:\SAS\omnimacro\AdvOp"
		"D:\SAS\omnimacro\FileSystem"
	)
	mautosource
;
%let	L_srcflnm	=	D:\SAS\omnimacro\AdvDB\TestETL.xlsx;
%let	L_stpflnm	=	CFG_KPI;

%*050.	Setup a dummy macro [ErrMcr] to prevent the session to be bombed.;
%macro	ErrMcr;	%mend	ErrMcr;

%*100.	Import the configuration table.;
PROC IMPORT
	OUT			=	CFG_KPI_pre(where=(missing(KPI_ID)=0))
	DATAFILE	=	"&L_srcflnm."
	DBMS		=	EXCEL
	REPLACE
;
	SHEET		=	"KPIRepository$";
	GETNAMES	=	YES;
	MIXED		=	NO;
	SCANTEXT	=	YES;
	USEDATE		=	YES;
	SCANTIME	=	YES;
RUN;

data &L_stpflnm.(compress=yes);
	set CFG_KPI_pre;

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

	D_BGN			=	Begin_Date;
	D_END			=	End_Date;
	C_KPI_ID		=	strip(KPI_ID);
	C_KPI_SHORTNAME	=	strip(KPI_SHORTNAME);
	C_KPI_BIZNAME	=	strip(KPI_BIZNAME);
	C_KPI_DESC		=	strip(KPI_DESC);
	C_PGM_PATH		=	strip(PGM_PATH);
	C_PGM_NAME		=	strip(PGM_NAME);
	F_KPI_INUSE		=	KPI_INUSE;
	C_KPI_FORMAT	=	strip(KPI_FORMAT);
	C_KPI_DAT_PATH	=	strip(pathname("work"));
	C_KPI_DAT_NAME	=	strip(KPI_DAT_NAME);

	keep
		D_BGN
		D_END
		C_KPI_ID
		C_KPI_SHORTNAME
		C_KPI_BIZNAME
		C_KPI_DESC
		C_PGM_PATH
		C_PGM_NAME
		F_KPI_INUSE
		C_KPI_FORMAT
		C_KPI_DAT_PATH
		C_KPI_DAT_NAME
	;
run;

%*200.	Create the test KPI tables.;
data custinfo;
	format
		nc_cifno	$30.
		c_custid	$64.
	;
	nc_cifno	=	"0001";
	c_custid	=	"123456789";
	output;
	nc_cifno	=	"0002";
	c_custid	=	"923456780";
	output;
run;
data acctinfo;
	format
		nc_cifno	$30.
		nc_acct_no	$64.
		d_maturity	yymmddD10.
	;
	nc_cifno	=	"0001";
	nc_acct_no	=	"0000101";
	d_maturity	=	mdy(4,1,2016);
run;
data kpi;
	format
		nc_cifno	$60.
		nc_acct_no	$128.
		C_KPI_ID	$16.
		A_KPI_VAL	best32.
	;
	nc_cifno	=	"0001";

	%*CASA;
	nc_acct_no	=	"0000101";
	C_KPI_ID	=	"220000";
	A_KPI_VAL	=	55000;
	output;

	C_KPI_ID	=	"220001";
	A_KPI_VAL	=	55000;
	output;

	C_KPI_ID	=	"220101";
	A_KPI_VAL	=	55000;
	output;

	%*TD;
	nc_acct_no	=	"0001101";
	C_KPI_ID	=	"220000";
	A_KPI_VAL	=	600000;
	output;

	C_KPI_ID	=	"220102";
	A_KPI_VAL	=	600000;
	output;

	nc_acct_no	=	"0001103";
	C_KPI_ID	=	"220000";
	A_KPI_VAL	=	70000;
	output;

	C_KPI_ID	=	"220102";
	A_KPI_VAL	=	70000;
	output;
run;
data kpi2;
	format
		nc_cifno	$64.
		nc_acct_no	$64.
		C_KPI_ID	$32.
		A_KPI_VAL	best32.
	;
	nc_cifno	=	"0001";

	%*CASA;
	nc_acct_no	=	"0000101";
	C_KPI_ID	=	"100000";
	A_KPI_VAL	=	150;
	output;

	%*TD;
	nc_acct_no	=	"0001101";
	C_KPI_ID	=	"100000";
	A_KPI_VAL	=	3000;
	output;

	nc_acct_no	=	"0001103";
	C_KPI_ID	=	"100000";
	A_KPI_VAL	=	320;
	output;
run;

%DBuse_MrgKPItoInf(
	inInfDat	=	acctinfo
	,KeyOfMrg	=	nc_acct_no
	,SetAsBase	=	I
	,inKPICfg	=	CFG_KPI
	,outDAT		=	AcctFull
	,procLIB	=	WORK
	,fDebug		=	1
)

%DBuse_MrgKPItoInf(
	inInfDat	=	custinfo
	,KeyOfMrg	=	nc_cifno
	,SetAsBase	=	f
	,inKPICfg	=	CFG_KPI
	,outDAT		=	CustFull
	,procLIB	=	WORK
	,fDebug		=	1
)

%DBuse_MrgKPItoInf(
	inInfDat	=	acctinfo
	,KeyOfMrg	=	%nrbquote(nc_cifno nc_acct_no)
	,SetAsBase	=	k
	,inKPICfg	=	CFG_KPI
	,outDAT		=	AcctFull2
	,procLIB	=	WORK
	,fDebug		=	1
)

proc sql noprint;
	drop table kpi2;
quit;

%DBuse_MrgKPItoInf(
	inInfDat	=	acctinfo
	,KeyOfMrg	=	%nrbquote(nc_cifno nc_acct_no)
	,SetAsBase	=	k
	,inKPICfg	=	%nrbquote(
						CFG_KPI(
							where=(
								C_KPI_ID	=	"100000"
							)
						)
					)
	,outDAT		=	AcctFull5
	,procLIB	=	WORK
	,fDebug		=	1
)

%DBuse_MrgKPItoInf(
	inInfDat	=	custinfo
	,KeyOfMrg	=	nc_cifno
	,SetAsBase	=	f
	,inKPICfg	=	CFG_KPI
	,outAggrBy	=	c_custid
	,outDAT		=	CustFull2
	,procLIB	=	WORK
	,fDebug		=	1
)

/*-Notes- -End-*/