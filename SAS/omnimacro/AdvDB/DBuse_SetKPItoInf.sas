%macro DBuse_SetKPItoInf(
	inInfDat	=
	,KeyOfMrg	=
	,SetAsBase	=	I
	,inKPICfg	=	src.CFG_KPI
	,outDAT		=
	,procLIB	=	WORK
	,fDebug		=	0
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to merge the KPI data to the given (descriptive) information data, in terms of								|
|	| different merging methods, and set all the datasets together for reporting purpose.												|
|	|IMPORTANT: If there is any variable in both [inInfDat] and the KPI dataset, the latter will be taken for granted and overwrite the	|
|	| final result. This is useful when the mapping result in the KPI dataset is at higher priority during the merge.					|
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
|	|outDAT		:	The output result.																									|
|	|procLIB	:	The working library.																								|
|	|fDebug		:	The switch of Debug Mode. Valid values are [0] or [1].																|
|	|				Default: [0]																										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20160507		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20160601		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Enable the function if there is no Information Table provided.																|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20160604		| Version |	2.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Fix the bug when the source data of KPI does not exist.																		|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20160626		| Version |	3.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Extract the part of the Information Loading of KPIs to a standardalone function, for it can be called in various functions.	|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20160913		| Version |	3.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |The program now retrieves all fields except [D_TABLE] from the KPI source data for all conditions.							|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170724		| Version |	3.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Use [SUPERQ] to mask all references to the directory names, for there could be %nrstr(&) and %nrstr(%%) in the names.		|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20171018		| Version |	3.40		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Remove the macro function UNQUOTE from parameter handling, to avoid unexpected result.										|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180204		| Version |	4.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |[1] Add verification of the TYPE and LENGTH of all variables in the datasets to be set together, to prevent unnecessary		|
|	|      | messages from being issued in the log.																						|
|	|      |[2] Introduce the macro [DropVarIfExists] to drop the unrequired variables where applicable.								|
|	|      |[3] Add DEBUG mode.																											|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180304		| Version |	4.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180325		| Version |	5.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Introduce the function [ForceMergeDats] to combine the required datasets in an independent way.								|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180422		| Version |	6.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |The program now eliminates the SQL query on [dictionary.columns] during the process.										|
|	|      |This is to improve the overall efficiency when there are many KPI datasets to retrieve.										|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180815		| Version |	7.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Fixed a bug of unnecessary extra KPI retrieval when [inInfDat] is not provided												|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20181204		| Version |	7.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Fixed a bug of missing observations from Information Table when none of the KPIs is applied to some of the keys in the		|
|	|      | Information Table. e.g. Some customers may have no stats in any of the KPIs while we still need the customer base to remain|
|	|      | complete in the reports.																									|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20210116		| Version |	7.20		| Updater/Creator |	Lu Robin Bin												|
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
|	|	|getCOLbyStrPattern																												|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\FileSystem"																						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|SAS_getTblLocation																												|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvDB"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|DBcore_LoadDatInfFrKpiCfg																										|
|	|	|ForceMergeDats																													|
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

%if	%length(%qsysfunc(compress(&inInfDat.,%str( ))))	^=	0	%then %do;
	%if	%length(%qsysfunc(compress(&KeyOfMrg.,%str( ))))	=	0	%then %do;
		%put	%str(W)ARNING: [&L_mcrLABEL.]Class variable list [KeyOfMrg=] is NOT provided!;
		%put	&Lohno.;
		%ErrMcr
	%end;
%end;

%if	%length(%qsysfunc(compress(&SetAsBase.,%str( ))))	=	0	%then	%let	SetAsBase	=	I;
%*Make sure we only retrieve the first character of the indicator.;
%let	SetAsBase	=	%upcase(%substr(&SetAsBase.,1,1));

%if	%length(%qsysfunc(compress(&inKPICfg.,%str( ))))	=	0	%then	%let	inKPICfg	=	src.CFG_KPI;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))		=	0	%then	%let	procLIB		=	WORK;
%if	%length(%qsysfunc(compress(&fDebug.,%str( ))))		=	0	%then	%let	fDebug		=	0;
%if	&fDebug.^=	0	%then	%let	fDebug		=	1;

%*013.	Define the local environment.;
%local
	OptNotes	OptSource	OptSource2	OptMLogic	OptSymGen	OptMPrint	OptInOper
	Ki			Mi			Di			Vi
	LInfDatLoc	LnDatAvail	LsDatAvail	LKpiSel		LInfModel
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
%let	LKpiSel		=;
%if	%length(%qsysfunc(compress(&inInfDat.,%str( ))))	=	0	%then %do;
	%let	LInfModel	=;
%end;
%else %do;
	%let	LInfModel	=	&procLIB..__setKPI_inf__;
%end;
%let	LchkOutDAT	=	0;
%let	LMrgSearch	=;

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
%if	%length(%qsysfunc(compress(&KeyOfMrg.,%str( ))))	^=	0	%then %do;
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
%end;

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in traditional SAS syntax colors.;
%macro dummy; %mend dummy;

%*099.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*100.	All input values.;
	%if	%length(%qsysfunc(compress(&inInfDat.,%str( ))))	=	0	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [inInfDat=].;
	%end;
	%else %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [inInfDat=%qsysfunc(compbl(&inInfDat.))].;
	%end;
	%if	%length(%qsysfunc(compress(&KeyOfMrg.,%str( ))))	=	0	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [KeyOfMrg=].;
	%end;
	%else %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [KeyOfMrg=%qsysfunc(compbl(&KeyOfMrg.))].;
	%end;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [SetAsBase=&SetAsBase.].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [inKPICfg=%qsysfunc(compbl(&inKPICfg.))].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [outDAT=%qsysfunc(compbl(&outDAT.))].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [procLIB=&procLIB.].;

	%*200.	Method to join the tables.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Method to join the tables: [LjoinMthd=&LjoinMthd.].;
%end;

%*100.	Identify all the required KPIs in the configuration table.;
%*The series of macro variables regarding the KPI list are generated by below macro.;
%DBcore_LoadDatInfFrKpiCfg(
	inKPICfg		=	&inKPICfg.
	,nKpiID			=	SnKpi
	,pfxKpiID		=	SeKpiID
	,pfxKpiName		=	SeKpiNM
	,pfxKpiLbl		=	SeKpiLBL
	,pfxKpiFmt		=	SeKpiFMT
	,nKpiDat		=	SnKpiDat
	,pfxKpiDatPath	=	SeKpiDatPath
	,pfxKpiDatName	=	SeKpiDatName
	,procLIB		=	&procLIB.
)
%*NOTE: It can also be called in below manner.;
%*DBcore_LoadDatInfFrKpiCfg( inKPICfg = &inKPICfg. );

%*190.	Quit the process if there is no KPI defined in the inventory.;
%if	&SnKpi.	=	0	%then %do;
	%put	%str(I)NFO: [&L_mcrLABEL.]No KPI is defined for retrieval. Skip the process.;
	%goto	EndOfProc;
%end;

%*195.	Define the KPI list for the selection within each dataset.;
%do Ki=1 %to &SnKpi.;
	%let	LKpiSel	=	&LKpiSel. %qsysfunc(quote(&&SeKpiID&Ki..));
%end;

%*199.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*Attributes of KPIs.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Total # of KPI IDs: [SnKpi=&SnKpi.].;
	%do Ki=1 %to &SnKpi.;
		%put	%str(I)NFO: [&L_mcrLABEL.][SeKpiID&Ki.=&&SeKpiID&Ki..][SeKpiNM&Ki.=&&SeKpiNM&Ki..][SeKpiLBL&Ki.=&&SeKpiLBL&Ki..][SeKpiFMT&Ki.=&&SeKpiFMT&Ki..];
	%end;

	%*Attributes of KPI datasets.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Total # of KPI datasets: [SnKpiDat=&SnKpiDat.].;
	%do Di=1 %to &SnKpiDat.;
		%put	%str(I)NFO: [&L_mcrLABEL.][SeKpiDatPath&Di.=&&SeKpiDatPath&Di..][SeKpiDatName&Di.=&&SeKpiDatName&Di..];
	%end;
%end;

%*200.	Identify the datasets that store the required KPIs.;
%do Di=1 %to &SnKpiDat.;
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
	%let	rc	=	%sysfunc( libname( &&LeKpiDatLib&Di.. , &LprLeft.%superq(SeKpiDatPath&Di.)&LprRight. , BASE , access=readonly ) );

	%*300.	Verify whether current dataset exists.;
	%local	LeKpiDatExist&Di.;
	%let	LeKpiDatExist&Di.	=	%sysfunc(exist(&&LeKpiDatLib&Di...&&SeKpiDatName&Di..));
%end;

%*209.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%do Di=1 %to &SnKpiDat.;
		%put	%str(I)NFO: [&L_mcrLABEL.]Dataset Existence: [LeKpiDatExist&Di.=&&LeKpiDatExist&Di..], name: [SeKpiDatName&Di.=&&SeKpiDatName&Di..];
	%end;
%end;

%*290.	If no KPI source data is found in the process, we end the process.;
%do Di=1 %to &SnKpiDat.;
	%*100.	Increment the counter if any source data exists.;
	%let	LchkOutDAT	=	%eval( &LchkOutDAT. + &&LeKpiDatExist&Di.. );
%end;
%if	&LchkOutDAT.	=	0	%then %do;
	%put	%str(I)NFO: [&L_mcrLABEL.]KPI source data is not found for the retrieval from Information Tables. Skip the process.;
	%goto	EndOfProc;
%end;

%*300.	Skip the following steps if there is no Information Table provided.;
%if	%length(%qsysfunc(compress(&inInfDat.,%str( ))))	=	0	%then %do;
	%put	%str(I)NFO: [&L_mcrLABEL.]No Information Table is provided, only set together the KPI data.;
	%goto	EndOfInfTbl;
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
	dupout=&procLIB..__setKPI_inf_dup__
;
	by
	%do Mi=1 %to &LnKeyOfMrg.;
		&&LeKeyOfMrg&Mi..
	%end;
	;
run;

%*329.	Should there be any duplications in the information table, this process is abandoned.;
%if	%getOBS4DATA( inDAT = &procLIB..__setKPI_inf_dup__ , gMode = F )	>	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]Program found Duplicated KEY in [&inInfDat.], will terminate immediately! Duplications have been output to [&procLIB..__setKPI_inf_dup__].;
	%put	&Lohno.;
	%ErrMcr
%end;

%*390.	Mark the end of processing on the Information Table.;
%EndOfInfTbl:

%*400.	Retrieve all the required KPIs.;
%*IMPORTANT! We remove all the records that do not exist in the KPI data during the merge;
%* , and then set together all the filtered KPI data;
%* , and then merge it back to the information table.;
%* This can eliminate the duplication of data records, given that the Key field is unique in;
%*  the original Information Table.;
%do Di=1 %to &SnKpiDat.;
	%*010.	Skip current iteration if the KPI source data does not exist.;
	%if	&&LeKpiDatExist&Di..	=	0	%then %do;
		%goto	EndOfcurrKPI;
	%end;

	%*050.	Create macro variables to identify all the available datasets for further process.;
	%let	LnDatAvail	=	%eval( &LnDatAvail. + 1 );
	%local	LeDatAvail&LnDatAvail.;
	%let	LeDatAvail&LnDatAvail.	=	&procLIB..__setKPI_Kpi__&Di.;

	%*100.	Skip current iteration if [inInfDat] is not provided, which indicates that only the source datasets of the KPIs need to be set together.;
	%if	%length(%qsysfunc(compress(&inInfDat.,%str( ))))	=	0	%then %do;
		data &&LeDatAvail&LnDatAvail..;
			set
				&&LeKpiDatLib&Di...&&SeKpiDatName&Di..(
					where=(
						C_KPI_ID	in	( %unquote(&LKpiSel.) )
					)
				)
			;
		run;
		%goto	AddKpiToList;
	%end;

	%*200.	Determine which variables are to be removed from the information table before the final merge.;
	%*[1] All variables in [&&LeKpiDatLib&Di...&&SeKpiDatName&Di..] except the ones in [KeyOfMrg];
	%getCOLbyStrPattern(
		inDAT		=	&&LeKpiDatLib&Di...&&SeKpiDatName&Di..
		,inRegExp	=
		,exclRegExp	=	&LMrgSearch.
		,chkVarTP	=	ALL
		,outCNT		=	LnSK
		,outELpfx	=	LeSK
	)
	%let	LVarSel	=;
	%do Vi=1 %to &LnSK.;
		%let	LVarSel	=	&LVarSel. &&LeSK&Vi..;
	%end;

	%*209.	Debugger.;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Below variables are to be removed from [&procLIB..__setKPI_inf__] before merging to [&&LeKpiDatLib&Di...&&SeKpiDatName&Di..]:;
		%put	%str(I)NFO: [&L_mcrLABEL.][&LVarSel.];
	%end;

	%*300.	Prepare the information table for merge.;
	data &procLIB..__setKPI_inf4mrg__;
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

	%*600.	Join the KPI data to the Information Table.;
	%ForceMergeDats(
		inDatLst	=	%nrbquote(
							&procLIB..__setKPI_inf4mrg__
							&&LeKpiDatLib&Di...&&SeKpiDatName&Di..
						)
		,ModelDat	=	&procLIB..__setKPI_inf4mrg__
		,MixedType	=	N
		,MergeProc	=	MERGE
		,byVAR		=	&KeyOfMrg.
		,addProc	=	&LmergeMthd.
		,outDAT		=	%nrbquote(
							&&LeDatAvail&LnDatAvail..(
								where=(
									C_KPI_ID	in	( &LKpiSel. )
								)
							)
						)
		,fDebug		=	&fDebug.
	)

	%*690.	De-assign the temporary library.;
	%AddKpiToList:
	%let	rc	=	%sysfunc( libname( &&LeKpiDatLib&Di.. ) );

	%*800.	Add the dataset name to a temporary list for further process.;
	%let	LsDatAvail	=	&LsDatAvail. &&LeDatAvail&LnDatAvail..;

	%*900.	Mark the end of current iteration.;
	%EndOfcurrKPI:
%end;

%*499.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%put	%str(I)NFO: [&L_mcrLABEL.]Datasets that are to be set together are listed as below:;
	%do Dj=1 %to &LnDatAvail.;
		%put	%str(I)NFO: [&L_mcrLABEL.][LeDatAvail&Dj.=&&LeDatAvail&Dj..];
	%end;
%end;

%*800.	Generate the output result.;
%*810.	Set together all the KPI data.;
%ForceMergeDats(
	inDatLst	=	%nrbquote(&LsDatAvail.)
	,ModelDat	=	&LInfModel.
	,MixedType	=	N
	,MergeProc	=	SET
	,byVAR		=
	,addProc	=
%if	%length(%qsysfunc(compress(&inInfDat.,%str( ))))	=	0	%then %do;
	,outDAT		=	&outDAT.
%end;
%else %do;
	,outDAT		=	&procLIB..__setKPI_kpis__
%end;
	,fDebug		=	&fDebug.
)

%*819.	Skip the rest of process if [inInfDat] is NOT provided.;
%if	%length(%qsysfunc(compress(&inInfDat.,%str( ))))	=	0	%then %do;
	%goto	EndOfProc;
%end;

%*850.	Prepare the full base from the information table.;
data &procLIB..__setKPI_keys__;
	length	C_KPI_ID	$16;
	set &LInfModel.;
%do Ki=1 %to &SnKpi.;
	C_KPI_ID	=	%sysfunc(quote( &&SeKpiID&Ki.. , %str(%') ));	output;
%end;
run;

%*860.	Apply the type of merging as indicated.;
%ForceMergeDats(
	inDatLst	=	%nrbquote( &procLIB..__setKPI_keys__ &procLIB..__setKPI_kpis__ )
	,ModelDat	=	&LInfModel.
	,MixedType	=	N
	,MergeProc	=	MERGE
	,byVAR		=	&KeyOfMrg. C_KPI_ID
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
%mend DBuse_SetKPItoInf;

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
		nc_cifno	$30.
		nc_acct_no	$64.
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
		nc_cifno	$32.
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

%DBuse_SetKPItoInf(
	inInfDat	=	acctinfo
	,KeyOfMrg	=	nc_acct_no
	,SetAsBase	=	I
	,inKPICfg	=	CFG_KPI
	,outDAT		=	AcctFull
	,procLIB	=	WORK
	,fDebug		=	1
)

%DBuse_SetKPItoInf(
	inInfDat	=	custinfo
	,KeyOfMrg	=	nc_cifno
	,SetAsBase	=	f
	,inKPICfg	=	CFG_KPI
	,outDAT		=	CustFull
	,procLIB	=	WORK
	,fDebug		=	1
)

%DBuse_SetKPItoInf(
	inInfDat	=	acctinfo
	,KeyOfMrg	=	%nrbquote(nc_cifno nc_acct_no)
	,SetAsBase	=	k
	,inKPICfg	=	CFG_KPI
	,outDAT		=	AcctFull2
	,procLIB	=	WORK
	,fDebug		=	1
)

%DBuse_SetKPItoInf(
	inInfDat	=
	,KeyOfMrg	=	%nrbquote(nc_cifno nc_acct_no)
	,SetAsBase	=
	,inKPICfg	=	CFG_KPI
	,outDAT		=	AcctFull3
	,procLIB	=	WORK
	,fDebug		=	1
)

%DBuse_SetKPItoInf(
	inInfDat	=
	,KeyOfMrg	=	%nrbquote(nc_cifno nc_acct_no)
	,SetAsBase	=
	,inKPICfg	=	%nrbquote(
						CFG_KPI(
							where=(
								C_KPI_ID	=	"900000"
							)
						)
					)
	,outDAT		=	AcctFull4
	,procLIB	=	WORK
	,fDebug		=	1
)

proc sql noprint;
	drop table kpi2;
quit;

%DBuse_SetKPItoInf(
	inInfDat	=
	,KeyOfMrg	=	%nrbquote(nc_cifno nc_acct_no)
	,SetAsBase	=
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

/*-Notes- -End-*/