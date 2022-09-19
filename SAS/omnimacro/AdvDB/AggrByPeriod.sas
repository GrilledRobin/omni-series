%macro AggrByPeriod(
	inClndrPfx	=
	,inDatPfx	=
	,AggrVar	=
	,dnDateBgn	=
	,dnDateEnd	=
	,ChkDatPfx	=
	,ChkDatVar	=
	,dnChkBgn	=
	,ByVar		=
	,CopyVar	=
	,genPHbyWD	=	1
	,FuncAggr	=	CMEAN
	,outVar		=
	,outDAT		=
	,procLIB	=	WORK
	,fDebug		=	0
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to calculate the summary stats for each respective group of [ByVar] by the provided aggregation function	|
|	| [FuncAggr] in terms of the serial data on Workdays or Calendar Days.																|
|	|___________________________________________________________________________________________________________________________________|
|	|It is used to minimize the computer resource consumption when the process is conducted on a daily basis, for it can leverage the	|
|	|calculated result of the previous workday to calculate the value of current day, prior to the aggregation of all datasets in the	|
|	|given period of time.																												|
|	|___________________________________________________________________________________________________________________________________|
|	|Usage could be:																													|
|	| - Calculate the Date-to-Date average value of the KPI, such as ANR																|
|	| - Identify the maximum or minimum value of the KPI over the period																|
|	|___________________________________________________________________________________________________________________________________|
|	|IMPORTANT: If there is any Descriptive Information in the series of input datasets, the Last Existing one will be kept in the		|
|	|            output dataset. E.g. if a customer only exists from 1st to 15th in a month, his or her status on 15th will be kept in	|
|	|            the output data.																										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|[Required] Overall Control:																										|
|	|___________________________________________________________________________________________________________________________________|
|	|inClndrPfx	:	The prefix of the series of datasets that store the yearly calendars.												|
|	|				The naming convention is: [inClndrPfx<yyyy>].																		|
|	|___________________________________________________________________________________________________________________________________|
|	|[Required] Input dataset information: (Daily snapshot of database)																	|
|	|___________________________________________________________________________________________________________________________________|
|	|inDatPfx	:	The prefix of the series of datasets that store the KPI for calculation (such as Daily Account Balances).			|
|	|				The naming convention is: [inDatPfx<yyyymmdd>].																		|
|	|AggrVar	:	The variable in [inDatPfx<yyyymmdd>] that represents the value to be applied by function [FuncAggr].				|
|	|dnDateBgn	:	The beginning date of the period.																					|
|	|				The naming convention [dn] indicates that it is a date but shown as a numeric string [yyyymmdd].					|
|	|dnDateEnd	:	The ending date of the period.																						|
|	|				The naming convention [dn] indicates that it is a date but shown as a numeric string [yyyymmdd].					|
|	|___________________________________________________________________________________________________________________________________|
|	|[Optional] Dataset to be leveraged for advanced aggregation: (Previously calculated result)										|
|	|___________________________________________________________________________________________________________________________________|
|	|ChkDatPfx	:	The prefix of the series of datasets that store the previously aggregated KPI for minimization of system effort.	|
|	|				The naming convention is: [ChkDatPfx<yyyymmdd>].																	|
|	|				It is useful when the ANR on Previous Workday exists while we will leverage it to calculate the ANR till today.		|
|	|ChkDatVar	:	The variable in [ChkDatPfx<yyyymmdd>] that represents the aggregatred value to leverage for new calculation.		|
|	|dnChkBgn	:	The beginning date of the period that the summary value in [ChkDatPfx<yyyymmdd>] covers.							|
|	|				The naming convention [dn] indicates that it is a date but shown as a numeric string [yyyymmdd].					|
|	|				If it is NOT provided, it will be set the same as [dnDateBgn].														|
|	|dnChkEnd	:	(Internal) The ending date of the period that the summary value in [ChkDatPfx<yyyymmdd>] covers. 					|
|	|				The naming convention [dn] indicates that it is a date but shown as a numeric string [yyyymmdd].					|
|	|				It is NOT provided by user and yet implied inside the program by different approaches.								|
|	|___________________________________________________________________________________________________________________________________|
|	|[Required] Grouping and Aggregation methods:																						|
|	|___________________________________________________________________________________________________________________________________|
|	|ByVar		:	The list of variable names that are to be used as the group to aggregate the KPI.									|
|	|				All variables should exist in both [inDatPfx<yyyymmdd>] and [ChkDatPfx<yyyymmdd>].									|
|	|CopyVar	:	(Optional) The list of variable names that are to be copied during the aggregation.									|
|	|				All variables should exist in both [inDatPfx<yyyymmdd>] and [ChkDatPfx<yyyymmdd>].									|
|	|				In a time series of datasets, only those variables in the Last Existing observation can be copied to the output.	|
|	|genPHbyWD	:	The flag of whether to Generate the multiplier to WorkDays to resemble the data of Public Holidays.					|
|	|				[1]	:	Resemble the data on Public Holidays by replicating their respective Previous Workdays.						|
|	|				[0]	:	Force to use the data on Public Holidays. All the data on Calendar Days should EXIST.						|
|	|				Default: [1]																										|
|	|FuncAggr	:	The aggregation function to be applied to the KPI. Supported functions are listed as below:							|
|	|				[WSUM]	:	Calculate the SUM of the KPI value for all workdays in the given period, regardless of the holidays.	|
|	|				[CSUM]	:	Calculate the SUM of the KPI value for all Calendar days in the given period.							|
|	|							The values of holidays are replaced by their respective Previous Workdays if implied by [genPHbyWD].	|
|	|				[WMEAN]	:	Calculate the MEAN of the KPI value for all workdays in the given period.								|
|	|				[CMEAN]	:	Calculate the MEAN of the KPI value for all Calendar days in the given period.							|
|	|				[WMAX]	:	Retrieve the MAXIMUM value of the KPI among all workdays in the given period.							|
|	|				[CMAX]	:	Retrieve the MAXIMUM value of the KPI among all Calendar days in the given period.						|
|	|				[WMIN]	:	Retrieve the MINIMUM value of the KPI among all workdays in the given period.							|
|	|				[CMIN]	:	Retrieve the MINIMUM value of the KPI among all Calendar days in the given period.						|
|	|				 Above parameters are case insensitive, while the default one is set as [CMEAN].									|
|	|___________________________________________________________________________________________________________________________________|
|	|[Required] Common Operations:																										|
|	|___________________________________________________________________________________________________________________________________|
|	|outVar		:	The variable that holds the value of the summary result in the output result.										|
|	|outDAT		:	The output result.																									|
|	|procLIB	:	The working library.																								|
|	|				Default: [WORK]																										|
|	|fDebug		:	The switch of Debug Mode. Valid values are [0] or [1].																|
|	|				Default: [0]																										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20170925		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20171014		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Correct the initial parameters [nCalcDays] and [nInterval] for when the beginning of Actual Calculation Period is NOT		|
|	|      | Workday, while it is also indicated that the calculation should be based on Calendar Days instead of Workdays.				|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180304		| Version |	1.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180401		| Version |	1.30		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |[1] Add declaration when the parameter [inClndrPfx] is NOT provided.														|
|	|      |[2] Introduce the system option [MINOPERATOR] during the verification of the acceptable functions.							|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20220814		| Version |	1.40		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|   | Log  |[1] Fixed a bug when [chkBgn] > [chkEnd] so that the program no longer tries to conduct calculation for Checking Period in	|
|   |      |     such case																												|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20220917		| Version |	1.50		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|   | Log  |[1] Fixed a bug of duplication when data as of holidays are to be created from their respective previous workdays			|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Please find the attachments for examples.																							|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|The input Calendar data MUST contain below fields:																					|
|	|	D_DATE		(numeric, date format)																								|
|	|	F_WORKDAY	(numeric, flag, 1 - Workday , 0 - Holiday)																			|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|The input series of datasets [inDatPfx<yyyymmdd>] MUST contain below fields:														|
|	|	[AggrVar]	(numeric)																											|
|	|	[ByVar]		(Various, can be more than one)																						|
|	|	[CopyVar]	(Various, can be more than one)																						|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ErrMcr																															|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvDB"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|AggrByPeriod (Recursion)																										|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\Dates"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|PrevWorkDateOf																													|
|	|	|getMthWithinPeriod																												|
|	|	|isWorkDay																														|
|	|	|usFUN_isWDorPredate																											|
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
%let	procLIB		=	%unquote(&procLIB.);

%if	%length(%qsysfunc(compress(&inClndrPfx.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No Calendar data [inClndrPfx=] is specified! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%index( &inClndrPfx. , . )	=	0	%then %do;
	%let	inClndrPfx	=	work.&inClndrPfx.;
%end;

%if	%length(%qsysfunc(compress(&ByVar.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]By group [ByVar] is not provided!;
	%put	&Lohno.;
	%ErrMcr
%end;

%let	FuncAggr	=	%upcase(&FuncAggr.);
%if	%length(%qsysfunc(compress(&FuncAggr.,%str( ))))	=	0	%then	%let	FuncAggr	=	CMEAN;

%if	%length(%qsysfunc(compress(&dnChkBgn.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.][dnChkBgn] is not provided. It will be set the same as [dnDateBgn=&dnDateBgn.].;
	%let	dnChkBgn	=	&dnDateBgn.;
%end;

%if	%length(%qsysfunc(compress(&genPHbyWD.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.][genPHbyWD] is not provided. Program resembles the data on Public Holidays by their respective Previous Workdays.;
	%let	genPHbyWD	=	1;
%end;
%if	&genPHbyWD.	^=	1	%then %do;
	%let	genPHbyWD	=	0;
%end;

%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No output data is specified! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))	=	0	%then	%let	procLIB		=	WORK;
%if	%length(%qsysfunc(compress(&fDebug.,%str( ))))	=	0	%then	%let	fDebug		=	0;
%if	&fDebug.^=	0	%then	%let	fDebug		=	1;

%*013.	Define the local environment.;
%local
	OptNotes	OptSource	OptSource2	OptMLogic	OptSymGen	OptMPrint	OptInOper
	dnChkEnd	d_CalcBgn	d_CalcEnd	d_ChkBgn	d_ChkEnd	PeriodOut	PeriodChk	PeriodDif
	pdCalcBgn	pdCalcEnd	pdChkBgn	pdChkEnd
	VldFuncLst	fCalcOnWD	LFuncAggr
	fLeadCalc	fUsePrev
	dnActBgn	d_ActBgn	f_ActIsWD
	nCalcDays	nInterval
	multiplier_CP
	Yi	Di	Dj
;
%let	VldFuncLst	=	%str( WSUM WMEAN WMIN WMAX CSUM CMEAN CMIN CMAX );
%let	d_CalcBgn	=	%sysfunc(inputn( &dnDateBgn. , yymmdd10. ));
%let	d_CalcEnd	=	%sysfunc(inputn( &dnDateEnd. , yymmdd10. ));
%let	d_ChkBgn	=	%sysfunc(inputn( &dnChkBgn. , yymmdd10. ));
%let	PeriodChk	=	0;
%let	fLeadCalc	=	0;
%let	fUsePrev	=	0;
%let	nCalcDays	=	0;
%let	nInterval	=	1;

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

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in traditional SAS syntax colors.;
%macro dummy; %mend dummy;

%*020.	Bomb the SAS session if the parameter [FuncAggr] is NOT acceptable.;
%if	%eval(&FuncAggr. in (&VldFuncLst.))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]The provided function [FuncAggr=&FuncAggr.] is not supported!;
	%put	%str(W)ARNING: [&L_mcrLABEL.]The valid functions should be among: [%sysfunc(compbl(&VldFuncLst.))]!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*030.	Define the local actions in terms of the valid function name.;
%let	fCalcOnWD	=	%sysfunc(ifn( %index( &FuncAggr. , W ) = 1 , 1 , 0 ));
%if	%substr( &FuncAggr. , 2 )	=	MEAN	%then %do;
	%let	LFuncAggr	=	SUM;
%end;
%else %do;
	%let	LFuncAggr	=	%substr( &FuncAggr. , 2 );
%end;

%*049.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*All input values.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [inClndrPfx=&inClndrPfx.].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [inDatPfx=&inDatPfx.].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [AggrVar=&AggrVar.].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [dnDateBgn=&dnDateBgn.].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [dnDateEnd=&dnDateEnd.].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [ChkDatPfx=&ChkDatPfx.].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [ChkDatVar=&ChkDatVar.].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [dnChkBgn=&dnChkBgn.].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [ByVar=%sysfunc(compbl(&ByVar.))].;
	%if	%length(%qsysfunc(compress( &CopyVar. , %str( ))))	=	0	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [CopyVar=&CopyVar.].;
	%end;
	%else %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [CopyVar=%sysfunc(compbl(&CopyVar.))].;
	%end;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [genPHbyWD=&genPHbyWD.].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [FuncAggr=&FuncAggr.].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [outVar=&outVar.].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [outDAT=%qsysfunc(compbl(&outDAT.))].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [procLIB=&procLIB.].;
%end;

%*050.	Combine the calendar data of the whole period starting from the previous year of [d_ChkBgn] to [d_CalcEnd].;
%*051.	Combine the data.;
data &procLIB..ABP_Clndr;
	set
	%do Yi=%eval( %substr( &dnChkBgn. , 1 , 4 ) - 1 ) %to %substr( &dnDateEnd. , 1 , 4 );
		%if	%sysfunc(exist( &inClndrPfx.&Yi. ))	%then %do;
			&inClndrPfx.&Yi.
		%end;
	%end;
	;
run;

%*055.	Ensure there is no duplicated date.;
proc sort
	data=&procLIB..ABP_Clndr
	nodupkey
;
	by	D_DATE;
run;

%*050.	Determine [d_ChkEnd] by the implication of [genPHbyWD].;
%if	&genPHbyWD.	=	1	%then %do;
	%let	d_ChkEnd	=	%PrevWorkDateOf( inDATE = &d_CalcEnd. , inCalendar = &procLIB..ABP_Clndr );
%end;
%else %do;
	%let	d_ChkEnd	=	%eval( &d_CalcEnd. - 1 );
%end;
%let	dnChkEnd	=	%sysfunc(putn( &d_ChkEnd. , yymmddN8. ));

%*059.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%put	%str(I)NFO: [&L_mcrLABEL.][genPHbyWD=&genPHbyWD.] End of Checking Period: [dnChkEnd=&dnChkEnd.].;
%end;

%*060.	Create various macro variables for the [Calculation Period] and [Checking Period].;
%*061.	Coverage of Calculation Period.;
%getMthWithinPeriod(
	clnLIB		=	%scan( &inClndrPfx. , 1 , . )
	,clnPFX		=	%scan( &inClndrPfx. , -1 , . )
	,DateBgn	=	&dnDateBgn.
	,DateEnd	=	&dnDateEnd.
	,outPfx		=	ABPCa
	,procLIB	=	&procLIB.
)

%*062.	Coverage of Checking Period.;
%getMthWithinPeriod(
	clnLIB		=	%scan( &inClndrPfx. , 1 , . )
	,clnPFX		=	%scan( &inClndrPfx. , -1 , . )
	,DateBgn	=	&dnChkBgn.
	,DateEnd	=	&dnChkEnd.
	,outPfx		=	ABPCh
	,procLIB	=	&procLIB.
)

%*070.	Retrieve the Previous Days by the implication of [fCalcOnWD].;
%*We also determine the [PeriodOut] and [PeriodChk] here.;
%if	&fCalcOnWD.	=	1	%then %do;
	%let	PeriodOut	=	&ABPCakWkDay.;
	%if	&dnChkBgn.	<=	&dnChkEnd.	%then %do;
		%let	PeriodChk	=	&ABPChkWkDay.;
	%end;
	%let	pdCalcBgn	=	%PrevWorkDateOf( inDATE = &d_CalcBgn. , inCalendar = &procLIB..ABP_Clndr );
	%let	pdCalcEnd	=	%PrevWorkDateOf( inDATE = &d_CalcEnd. , inCalendar = &procLIB..ABP_Clndr );
	%let	pdChkBgn	=	%PrevWorkDateOf( inDATE = &d_ChkBgn. , inCalendar = &procLIB..ABP_Clndr );
	%let	pdChkEnd	=	%PrevWorkDateOf( inDATE = &d_ChkEnd. , inCalendar = &procLIB..ABP_Clndr );
%end;
%else %do;
	%let	PeriodOut	=	&ABPCakClnDay.;
	%if	&dnChkBgn.	<=	&dnChkEnd.	%then %do;
		%let	PeriodChk	=	&ABPChkClnDay.;
	%end;
	%let	pdCalcBgn	=	%eval( &d_CalcBgn. - 1 );
	%let	pdCalcEnd	=	%eval( &d_CalcEnd. - 1 );
	%let	pdChkBgn	=	%eval( &d_ChkBgn. - 1 );
	%let	pdChkEnd	=	%eval( &d_ChkEnd. - 1 );
%end;

%*075.	Define the multiplier for Checking Period.;
%if	%substr( &FuncAggr. , 2 )	=	MEAN	%then %do;
	%let	multiplier_CP	=	&periodChk.;
%end;
%else %do;
	%let	multiplier_CP	=	1;
%end;

%*080.	Calculate the difference of # date coverages by the implication of [fCalcOnWD].;
%let	PeriodDif	=	%eval( &PeriodOut. - &PeriodChk. );

%*099.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%put	%str(I)NFO: [&L_mcrLABEL.][fCalcOnWD=&fCalcOnWD.].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Calculation Period: [dnDateBgn=&dnDateBgn.][dnDateEnd=&dnDateEnd.].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Checking Period: [dnChkBgn=&dnChkBgn.][dnChkEnd=&dnChkEnd.].;
	%put	%str(I)NFO: [&L_mcrLABEL.][PeriodOut=&PeriodOut.][PeriodChk=&PeriodChk.].;
	%put	%str(I)NFO: [&L_mcrLABEL.][pdCalcBgn=&pdCalcBgn.][pdCalcEnd=&pdCalcEnd.].;
	%put	%str(I)NFO: [&L_mcrLABEL.][pdChkBgn=&pdChkBgn.][pdChkEnd=&pdChkEnd.].;
	%put	%str(I)NFO: [&L_mcrLABEL.][PeriodDif=&PeriodDif.].;
%end;

%*100.	Calculate the summary for the leading period from [dnChkBgn] to [dnDateBgn], if applicable.;
%*110.	Consider there is no use of [ChkDatPfx<yyyymmdd>] if [dnChkBgn] >= [dnDateBgn], as its date coverage is no more than available.;
%if	&dnChkBgn.	>=	&dnDateBgn.	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Procedure will not leverage data [ChkDatPfx<yyyymmdd>] since [dnChkBgn=&dnChkBgn.] >= [dnDateBgn=&dnDateBgn.].;
	%goto	EndOfLeadCalc;
%end;

%*120.	Skip the calculation of Leading Period if the date coverage of [Calculation Period] and [Checking Period] are not the same.;
%if	&dnChkBgn.	<	&dnDateBgn.	%then %do;
	%if	&PeriodDif.	^=	0	%then %do;
		%put	%str(N)OTE: [&L_mcrLABEL.]Procedure will not leverage data [ChkDatPfx<yyyymmdd>] since its date coverage is not identical to current one.;
		%goto	EndOfLeadCalc;
	%end;
%end;

%*130.	Skip the calculation of Leading Period for the functions other than [SUM] and [MEAN].;
%if	%index(#SUM#MEAN#,#&LFuncAggr.#)	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Procedure will not leverage data [ChkDatPfx<yyyymmdd>] for function [FuncAggr=&FuncAggr.].;
	%goto	EndOfLeadCalc;
%end;

%*140.	Skip the calculation of Leading Period if [ChkDatPfx] is not provided.;
%if	%length(%qsysfunc(compress(&ChkDatPfx.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.][ChkDatPfx] is not provided. Skip the calculation of Leading Period.;
	%goto	EndOfLeadCalc;
%end;

%*150.	Skip the calculation of Leading Period if [ChkDatPfx<yyyymmdd>] does not exist.;
%if	%sysfunc(exist( &ChkDatPfx.&dnChkEnd. ))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]The data [ChkDatPfx<yyyymmdd>=&ChkDatPfx.&dnChkEnd.] does not exist. Skip the calculation of Leading Period.;
	%goto	EndOfLeadCalc;
%end;

%*160.	Call the same macro to calculate the summary in Leading Period.;
%*[1] There is no such [ChkDatPfx<yyyymmdd>] to leverage for the Leading Period.;
%*[2] The end date of the Leading Period is determined by [fCalcOnWD].;
%*[3] We will only apply [SUM] for the calculation in Leading Period, for later subtraction.;
%AggrByPeriod(
	inClndrPfx	=	&inClndrPfx.
	,inDatPfx	=	&inDatPfx.
	,AggrVar	=	&AggrVar.
	,dnDateBgn	=	&dnChkBgn.
	,dnDateEnd	=	%sysfunc(putn( &pdCalcBgn. , yymmddN8. ))
	,ChkDatPfx	=
	,ChkDatVar	=
	,dnChkBgn	=
	,ByVar		=	&ByVar.
	,CopyVar	=	&CopyVar.
	,genPHbyWD	=	&genPHbyWD.
	,FuncAggr	=	%substr( &FuncAggr. , 1 , 1 )SUM
	,outVar		=	_CalcLead_
	,outDAT		=	&procLIB..ABP_LeadPeriod
	,procLIB	=	&procLIB.
)

%*169.	Mark the success of the calculation.;
%let	fLeadCalc	=	1;

%*195.	Mark the end of calculation in Leading Period.;
%EndOfLeadCalc:

%*200.	Determine whether to leverage [ChkDatPfx<yyyymmdd>] as overall control.;
%*210.	Skip the determination if [ChkDatPfx] is not provided.;
%if	%length(%qsysfunc(compress(&ChkDatPfx.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.][ChkDatPfx] is not provided. Skip to leverage the data in the previous cycle of calculation.;
	%goto	EndOfUsePrev;
%end;

%*220.	Skip the determination if [ChkDatPfx<yyyymmdd>] does not exist.;
%if	%sysfunc(exist( &ChkDatPfx.&dnChkEnd. ))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]The data [ChkDatPfx<yyyymmdd>=&ChkDatPfx.&dnChkEnd.] does not exist. Skip to leverage the data in the previous cycle of calculation.;
	%goto	EndOfUsePrev;
%end;

%*230.	Skip the determination if [dnChkBgn] > [dnChkEnd], which indicates a non-existing period to be involved.;
%if	&dnChkBgn.	>	&dnChkEnd.	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Procedure will not conduct calculation in Checking Period since [dnChkBgn=&dnChkBgn.] > [dnChkEnd=&dnChkEnd.].;
	%goto	EndOfUsePrev;
%end;

%*250.	Mark to use [ChkDatPfx<yyyymmdd>] when either of below conditions are met:;
%*[1] [dnDateBgn] = [dnChkBgn], which usually represents a continuous calculation at fixed beginning, such as MTD ANR.;
%*[2] [fLeadCalc] = 1, which implies that the Leading Period has already been involved hence the entire Previous Calculation Result MUST also be involved.;
%if		&dnDateBgn.	=	&dnChkBgn.
	or	&fLeadCalc.	=	1
	%then %do;
	%let	fUsePrev	=	1;
%end;

%*295.	Mark the end of the determination.;
%EndOfUsePrev:

%*300.	Determine the datasets to be used for calculation in current period.;
%*310.	Determine the beginning of retrieval.;
%if	&fUsePrev.	=	1	%then %do;
	%*100.	We set the actual beginning date as the next Calendar Day of the date [d_ChkEnd] if the previous calculation result is to be leveraged.;
	%let	d_ActBgn	=	%eval( &d_ChkEnd. + 1 );
%end;
%else %do;
	%*200.	We set the actual beginning date as of the date [d_CalcBgn] if there is no previous result to leverage.;
	%let	d_ActBgn	=	&d_CalcBgn.;
%end;

%*330.	Format it into <yyyymmdd>.;
%let	dnActBgn	=	%sysfunc(putn( &d_ActBgn. , yymmddN8. ));

%*349.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%put	%str(I)NFO: [&L_mcrLABEL.]Actual Calculation Period: [dnActBgn=&dnActBgn.][dnDateEnd=&dnDateEnd.].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Condition for Actual Calculation Period: [genPHbyWD=&genPHbyWD.][fCalcOnWD=&fCalcOnWD.][[dnActBgn] is Workday? [%isWorkDay( inDATE = &d_ActBgn. , inCalendar = &procLIB..ABP_Clndr )]].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Initial parameters for Actual Calculation Period: [nInterval=&nInterval.][nCalcDays=&nCalcDays.].;
%end;

%*350.	Go through the period from [d_ActBgn] to [d_CalcEnd] and determine the suffix of the datasets to be set together for aggregation.;
%*351.	Retrieve all the date information within the period.;
%*IMPORTANT: The beginning of this period is always a Workday due to above operation.;
%getMthWithinPeriod(
	clnLIB		=	%scan( &inClndrPfx. , 1 , . )
	,clnPFX		=	%scan( &inClndrPfx. , -1 , . )
	,DateBgn	=	&dnActBgn.
	,DateEnd	=	&dnDateEnd.
	,outPfx		=	ABPAct
	,procLIB	=	&procLIB.
)

%*355.	Create necessary macro variables for calculation in the actually required period.;
%if	&fCalcOnWD.	=	1	%then %do;
	%let	nCalcDays	=	&ABPActkWkDay.;
	%do	Di=1	%to	&nCalcDays.;
		%let	CalcDate&Di.	=	&&ABPActdn_AllWD&Di..;
	%end;
%end;
%else	%if	&genPHbyWD.	=	1	%then %do;
	%*100.	Create a dataset to handle unique values, since macro facility is less effective or reader-friendly for such calculation.;
	data &procLIB..__calcdates_pre;
		format	d_avail	d_calc	yymmddD10.;
		do	i=1	to	&ABPActkClnDay.;
			d_avail	=	symgetn(cats("ABPActd_AllCD",i));
			%*Shift it to its previous workday if it is not, since the request indicates to resemble its data by is previous workday where necessary.;
			d_calc	=	isWDorPredate("&procLIB..ABP_Clndr","D_DATE","F_WORKDAY",d_avail);
			output;
		end;
	run;

	%*500.	Calculate the number of occurences of all unique dates, on which to retrieve source data.;
	proc freq
		data=&procLIB..__calcdates_pre
		noprint
	;
		tables
			d_calc
			/out=&procLIB..__calcdates
		;
	run;

	%*900.	Create lists of macro variables for later steps.;
	data _NULL_;
		set &procLIB..__calcdates end=EOF;
		call symputx(cats("CalcDate",_N_),put(d_calc,yymmddN8.),"F");
		call symputx(cats("CalcMult",_N_),strip(COUNT),"F");
		if	EOF	then do;
			call symputx("nCalcDays",_N_,"F");
		end;
	run;
%end;
%else %do;
	%let	nCalcDays	=	&ABPActkClnDay.;
	%do	Di=1	%to	&nCalcDays.;
		%let	CalcDate&Di.	=	&&ABPActdn_AllCD&Di..;
	%end;
%end;

%*357.	Reset the multiplier for data on each date for special cases.;
%if	(&genPHbyWD. = 0)	or	(&fCalcOnWD. = 1)	or	(&LFuncAggr. ^= SUM)	%then %do;
	%do	Di=1	%to	&nCalcDays.;
		%let	CalcMult&Di.	=	1;
	%end;
%end;

%*400.	Print the necessary information for testing.;
%if	&fDebug.	=	1	%then %do;
	%*100.	Print the Leading Period.;
	%if	&fLeadCalc.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.][fLeadCalc=1] Dataset to use: [&procLIB..ABP_LeadPeriod].;
	%end;

	%*200.	Print the Checking Dataset.;
	%if	&fUsePrev.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.][fUsePrev=1] Dataset to use: [&ChkDatPfx.&dnChkEnd.], multiplier: [&multiplier_CP.].;
	%end;

	%*300.	Print the datasets in the actual calculation period.;
	%do Dj=1 %to &nCalcDays.;
		%put	%str(I)NFO: [&L_mcrLABEL.][CalcData&Dj.=&inDatPfx.&&CalcDate&Dj..][CalcMult&Dj.=&&CalcMult&Dj..];
	%end;
%end;

%*500.	Conduct aggregation for each [ByVar] in each dataset within the calculation period.;
%*If there are more than 1 record for [ByVar] on any single date, the result will be erroneous for MIN or MAX functions across the entire period.;
%do Dj=1 %to &nCalcDays.;
	%*100.	Sort the data properly.;
	proc sort
		data=&inDatPfx.&&CalcDate&Dj..( keep= &ByVar. &CopyVar. &AggrVar. )
		out=&procLIB..ABP_CalcPre&Dj.
	;
		by	&ByVar.;
	run;

	%*200.	Aggregation.;
	data &procLIB..ABP_Calc&Dj.;
		%*100.	Set the source.;
		set	&procLIB..ABP_CalcPre&Dj.;
		by	&ByVar.;

		%*200.	Create temporary variable to sum up the values.;
		length	_CalcVar_	8;
		retain	_CalcVar_;

		%*300.	Initialize the variable at the beginning of each [ByVar].;
		if	first.%scan( &ByVar. , -1 )	then do;
			_CalcVar_	=	0;
		end;

		%*400.	Sum the dedicated variable.;
		_CalcVar_	+	&AggrVar.;

		%*500.	Output for each [ByVar] and only reserve the [CopyVar] of the last observation within the [ByVar] group.;
		if	last.%scan( &ByVar. , -1 )	then do;
			output;
		end;
	run;
%end;

%*600.	Set all the required data.;
data &procLIB..ABP_setall;
	%*100.	Set the source.;
	set
	%if	&fLeadCalc.	=	1	%then %do;
		&procLIB..ABP_LeadPeriod( in=i keep= &ByVar. &CopyVar. _CalcLead_ )
	%end;
	%if	&fUsePrev.	=	1	%then %do;
		&ChkDatPfx.&dnChkEnd.( in=j keep= &ByVar. &CopyVar. &ChkDatVar. rename=( &ChkDatVar. = _CalcChk_ ) )
	%end;
	%do Dj=1 %to &nCalcDays.;
		&procLIB..ABP_Calc&Dj.( in=k&Dj. keep= &ByVar. &CopyVar. _CalcVar_ )
	%end;
	;

	%*200.	Create temporary variables.;
	length
		__N_ORDER	8
		__Tmp_Val	8
	;

	%*300.	Assign the temporary values for later aggregation.;
%if	&fLeadCalc.	=	1	%then %do;
	if	i	then do;
		__N_ORDER	=	-1;
		__Tmp_Val	=	sum( 0 , -_CalcLead_ );
	end;
%end;
%if	&fUsePrev.	=	1	%then %do;
	if	j	then do;
		__N_ORDER	=	0;
		__Tmp_Val	=	_CalcChk_ * &multiplier_CP.;
	end;
%end;
%do Dj=1 %to &nCalcDays.;
	if	k&Dj.	then do;
		__N_ORDER	=	&Dj.;
		__Tmp_Val	=	_CalcVar_ * &&CalcMult&Dj..;
	end;
%end;

	%*900.	Purge.;
run;

%*699.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*100.	Whether the Leading Period is involved.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Whether the Leading Period is involved: [fLeadCalc=&fLeadCalc.].;

	%*200.	Whether the Checking Period is involved.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Whether the Checking Period is involved: [fUsePrev=&fUsePrev.].;

	%*300.	What is the actual function applied to the value in Checking Period.;
	%if	&fUsePrev.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Function to apply on Checking Period: [__Tmp_Val = _CalcChk_ * &multiplier_CP.];
	%end;
%end;

%*700.	Aggregate by the provided function.;
%*710.	Sort the data properly.;
proc sort
	data=&procLIB..ABP_setall
;
	by
		&ByVar.
		__N_ORDER
	;
run;

%*750.	Aggregation.;
data %unquote(&outDAT.);
	%*100.	Set the source.;
	set	&procLIB..ABP_setall;
	by
		&ByVar.
		__N_ORDER
	;

	%*200.	Create the output variable.;
	length	&outVar.	8;
	retain	&outVar.;

	%*300.	Initialize the value for each [ByVar].;
	if	first.%scan( &ByVar. , -1 )	then do;
		call missing(&outVar.);
	end;

	%*400.	Apply the formula.;
	&outVar.	=	&LFuncAggr.( &outVar. , __Tmp_Val );

	%*500.	Output for each [ByVar] and only reserve the [CopyVar] of the last observation within the [ByVar] group.;
	if	last.%scan( &ByVar. , -1 )	then do;
		%*100.	Correct the output value for the function [MEAN].;
		%if	%substr( &FuncAggr. , 2 )	=	MEAN	%then %do;
			&outVar.	=	&outVar.	/	&PeriodOut.;
		%end;

		%*900.	Output.;
		output;
	end;

	%*900.	Purge.;
	drop
%if	&fLeadCalc.	=	1	%then %do;
		_CalcLead_
%end;
%if	&fUsePrev.	=	1	%then %do;
		_CalcChk_
%end;
		_CalcVar_
		__N_ORDER
		__Tmp_Val
	;
run;

%*799.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*100.	Final formula.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Final formula for calculation: [&outVar. = &LFuncAggr.( &outVar. , __Tmp_Val )].;

	%*200.	Whether to divide the result.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Whether to divide the result for [FuncAggr=&FuncAggr.] function: %sysfunc(ifc( %substr( &FuncAggr. , 2 ) = MEAN , %nrbquote([YES], divisor: [PeriodOut=&PeriodOut.]) , [NO] )).;
%end;

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
%mend AggrByPeriod;

/* - Concept - * Begin * /
%*--  Below For Period Description  ------------------------------------------------------------------------------------------;
[1] The entire period of dates to be involved in this calculation process can be split into below sections:

  [dnChkBgn]           [dnDateBgn]                                                     [dnChkEnd]                   [dnDateEnd]
 /                      /                                                                 \                                \
|--Leading Period [L]--|                                                                   \                                \
|------------------------------------------Checking Period [C]------------------------------|                                \
                       |----------------------------------New Calculation Period [N]------------------------------------------|
                                                       ( Figure 1 )

[2] Given the dataset [C] exists and Len([C]) = Len([N]), the Actual Calculation Period [A] is set as below:

|------------------------------------------Checking Period [C]------------------------------|
                       |----------------------------------New Calculation Period [N]------------------------------------------|
                                                                                            |--Actual Calculation Period [A]--|
                                                                                           /                                 /
                                                                                        [dnActBgn]                   [dnActEnd]
                                                       ( Figure 2 )

[3] Given the dataset [C] does not exist or Len([C]) ^= Len([N]), the Actual Calculation Period [A] is set the same as [N].

[4] The final involvement of sections is as below: (by setting datasets of all sections)
Output = [FuncAggr]( [L] (if any, needs to be subtracted) + [C] (if any) + [A] )

%*--  Below For Terminology  -------------------------------------------------------------------------------------------------;
[L]   : It may not exist, depending on the value of [dnChkBgn], but has to be subtracted from [C] for SUM or MEAN functions.
[C]   : In a continuous process, such as ANR calculation, the result on each date is stored, and we will check them each time
         we conduct a new round of calculation.
[N]   : Current period within which we intend to conduct calculation.
[A]   : The actual involvement of basic daily KPI data.
Len() : The # of dates that a specific period covers, depending on whether [FuncAggr] indicates to use Calendar Day or Workday.

%*--  When to SKIP calculation of Leading Period [L]  ------------------------------------------------------------------------;
If any of below conditions is tiggered, we will NOT take the Leading Period into account.
[1] : [dnChkBgn] >= [dnDateBgn]. Obviously the date span of Leading Period is 0. (See [Figure 1] above)
[2] : [dnChkBgn] <  [dnDateBgn] while Len([C]) ^= Len([N]). e.g. if dataset [ANR20170831] was calculated out of 6 calendar
       days from [Bal20170826] to [Bal20170831], while we only need to calculate [ANR20170901] out of the series of datasets
       [Bal20170828-Bal20170901], then we will not leverage [ANR20170831] to calculate [ANR20170901].
[3] : [FuncAggr] does NOT represent [SUM] or [MEAN]. e.g. if the [MAX] value lies in the Leading Period, it cannot be involved
       in any period later than the end of the Leading Period.
[4] : [ChkDatPfx] is NOT provided.
[5] : [ChkDatPfx<dnChkEnd>] DOES NOT exist.

%*--  When to SKIP the involvement of Checking Period [C]  -------------------------------------------------------------------;
If any of below conditions is tiggered, we will NOT take the Checking Period into account.
[1] : [ChkDatPfx] is NOT provided.
[2] : [ChkDatPfx<dnChkEnd>] DOES NOT exist.

%*--  Calculation Process  ---------------------------------------------------------------------------------------------------;
[1] : If [L] should be involved, call the same macro to calculate the aggregation summary for [L], for later subtraction.
      The intermediate result in such case is marked as [L1].
      If [FuncAggr] represents [MEAN], [L1] should be calculated by [SUM] instead for subtraction purpose.
[2] : Aggregate all datasets to be used in [A] by the specified [ByVar] respectively, to avoid any possible erroneous result.
[3] : Set all required datasets together: (1) [L1] if any, (2) [C] if any, (3) the series of datasets generated in step [2].
[4] : Apply multiplier to above sections: (1) is multiplied by -1 since it is to be subtracted, (2) is multiplied by 1 or
       Len([C]) depending on whether the function [FuncAggr] represents [MEAN], (3) is always multiplied by 1.
[5] : Sum up the values in all above observations if [FuncAggr] represents [MEAN] or [SUM], while resolve the [MIN] or [MAX]
       values if otherwise, and at last, divide the summed value by Len([N]) if [FuncAggr] represents [MEAN].

/* - Concept - * End */

/*- Index of Examples - -Begin-* /

%*100.	Data Preparation.;
%*110.	Create Calendar dataset.;
%*120.	Retrieve all date information for the period of 20160229 to 20160603.;
%*130.	Create the test KPI tables.;
%*150.	Retrieve all date information for the period of 20160901 to 20161201.;
%*170.	Create the test KPI tables.;

%*200.	Using the same Beginning of a series of periods.;
%*210.	Mean of all Calendar Days from 20160501 to 20160516.;
%*220.	Mean of all Calendar Days from 20160501 to 20160517.;
%*230.	Mean of all Working Days from 20160501 to 20160516.;
%*240.	Mean of all Working Days from 20160501 to 20160517.;
%*250.	Max of all Calendar Days from 20160501 to 20160516.;
%*260.	Max of all Calendar Days from 20160501 to 20160517.;
%*270.	Max of all Working Days from 20160501 to 20160516.;
%*280.	Max of all Working Days from 20160501 to 20160517.;

%*300.	Rolling 10 days.;
%*310.	Mean of all Calendar Days from 20160401 to 20160410.;
%*311.	Mean of all Calendar Days from 20160402 to 20160411.;
%*312.	Mean of all Calendar Days from 20160403 to 20160412.;

%*400.	Rolling 5 Working Days.;
%*410.	Mean of all Working Days from 20160401 to 20160408.;
%*411.	Mean of all Working Days from 20160401 to 20160409.;
%*412.	Mean of all Working Days from 20160405 to 20160411.;

%*500.	Using the same Beginning of a series of periods.;
%*510.	Mean of all Calendar Days from 20160901 to 20160910.;
%*520.	Mean of all Calendar Days from 20160901 to 20160911.;
%*530.	Mean of all Working Days from 20160901 to 20160911.;
%*540.	Mean of all Working Days from 20160901 to 20160912.;
%*550.	Max of all Calendar Days from 20161001 to 20161010.;
%*560.	Max of all Calendar Days from 20161001 to 20161011.;
%*570.	Min of all Working Days from 20161001 to 20161010.;
%*580.	Min of all Working Days from 20161001 to 20161011.;

%*600.	Rolling 5 Calendar Days.;
%*610.	Mean of all Calendar Days from 20161007 to 20161011.;
%*611.	Mean of all Calendar Days from 20161008 to 20161012.;
%*612.	Mean of all Calendar Days from 20161009 to 20161013.;

%*700.	Rolling 5 Working Days.;
%*710.	Mean of all Working Days from 20160930 to 20161011.;
%*711.	Mean of all Working Days from 20161007 to 20161012.;
%*712.	Mean of all Working Days from 20161008 to 20161013.;
/*- Index of Examples - -End-*/

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvDB"
		"D:\SAS\omnimacro\AdvOp"
		"D:\SAS\omnimacro\Dates"
		"D:\SAS\omnimacro\FileSystem"
	)
	mautosource
;
options
	cmplib=_NULL_
;
proc FCmp
	outlib=work.fso.dates
;

	%usFUN_isWorkDay
	%usFUN_prevWorkday
	%usFUN_isWDorPredate

run;
quit;
options
	cmplib=work.fso
;

%*100.	Data Preparation.;
%*110.	Create Calendar dataset.;
%crCalendar(
	inYEAR		=	2015
	,procLIB	=	WORK
	,outDAT		=	tmpCalendar2015
)
%crCalendar(
	inYEAR		=	2016
	,procLIB	=	WORK
	,outDAT		=	tmpCalendar2016
)

%*120.	Retrieve all date information for the period of 20160229 to 20160603.;
%getMthWithinPeriod(
	clnLIB		=	work
	,clnPFX		=	tmpCalendar
	,DateBgn	=	20160229
	,DateEnd	=	20160603
	,outPfx		=	GmwPrd
	,procLIB	=	WORK
)

%*130.	Create the test KPI tables.;
%macro genKpiDat;
%let	Lsplit	=	40;
%do Di=1 %to &Lsplit.;
	data kpi&&GmwPrddn_AllWD&Di..;
		format
			nc_cifno	$32.
			nc_acct_no	$64.
			C_KPI_ID	$16.
			A_KPI_VAL	best32.
		;
		nc_cifno	=	"001";
		nc_acct_no	=	"10250";
		C_KPI_ID	=	"130100";
		A_KPI_VAL	=	&Di.;
	run;
%end;
%do Di=%eval(&Lsplit. + 1) %to &GmwPrdkWkDay.;
	data kpi&&GmwPrddn_AllWD&Di..;
		format
			nc_cifno	$32.
			nc_acct_no	$64.
			C_KPI_ID	$16.
			A_KPI_VAL	best32.
		;
		nc_cifno	=	"001";
		nc_acct_no	=	"10250";
		C_KPI_ID	=	"130100";
		A_KPI_VAL	=	&GmwPrdkWkDay. - &Di.;
	run;
%end;
%mend genKpiDat;
%genKpiDat

%*150.	Retrieve all date information for the period of 20160901 to 20161201.;
%getMthWithinPeriod(
	clnLIB		=	work
	,clnPFX		=	tmpCalendar
	,DateBgn	=	20160901
	,DateEnd	=	20161201
	,outPfx		=	GCln
	,procLIB	=	WORK
)

%*170.	Create the test KPI tables.;
%macro genClnDat;
%let	Lsplit	=	45;
%do Di=1 %to &Lsplit.;
	data kpi&&GClndn_AllCD&Di..;
		format
			nc_cifno	$32.
			nc_acct_no	$64.
			C_KPI_ID	$16.
			A_KPI_VAL	best32.
		;
		nc_cifno	=	"001";
		nc_acct_no	=	"10250";
		C_KPI_ID	=	"130100";
		A_KPI_VAL	=	&Di.;
	run;
%end;
%do Di=%eval(&Lsplit. + 1) %to &GClnkClnDay.;
	data kpi&&GClndn_AllCD&Di..;
		format
			nc_cifno	$32.
			nc_acct_no	$64.
			C_KPI_ID	$16.
			A_KPI_VAL	best32.
		;
		nc_cifno	=	"001";
		nc_acct_no	=	"10250";
		C_KPI_ID	=	"130100";
		A_KPI_VAL	=	&GClnkClnDay. - &Di.;
	run;
%end;
%mend genClnDat;
%genClnDat

%*200.	Using the same Beginning of a series of periods.;
%*210.	Mean of all Calendar Days from 20160501 to 20160516.;
%let	DtBgn	=	20160501;
%let	DtEnd	=	20160516;
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	avgKpi
	,ChkDatVar	=	A_KPI_ANR
	,dnChkBgn	=	&DtBgn.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=	C_KPI_ID
	,genPHbyWD	=	1
	,FuncAggr	=	CMEAN
	,outVar		=	A_KPI_ANR
	,outDAT		=	avgKpi&DtEnd.
	,procLIB	=	WORK
)
%put	%sysevalf((24*2+23+22+21+20*3+19+18+17+16+15*3+14)/16);

%*220.	Mean of all Calendar Days from 20160501 to 20160517.;
%let	DtBgn	=	20160501;
%let	DtEnd	=	20160517;
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	avgKpi
	,ChkDatVar	=	A_KPI_ANR
	,dnChkBgn	=	&DtBgn.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=	C_KPI_ID
	,genPHbyWD	=	1
	,FuncAggr	=	CMEAN
	,outVar		=	A_KPI_ANR
	,outDAT		=	avgKpi&DtEnd.
	,procLIB	=	WORK
)
%put	%sysevalf((24*2+23+22+21+20*3+19+18+17+16+15*3+14+13)/17);

%*230.	Mean of all Working Days from 20160501 to 20160516.;
%let	DtBgn	=	20160501;
%let	DtEnd	=	20160516;
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	WDavgKpi
	,ChkDatVar	=	A_KPI_ANR
	,dnChkBgn	=	&DtBgn.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=	C_KPI_ID
	,genPHbyWD	=	1
	,FuncAggr	=	WMEAN
	,outVar		=	A_KPI_ANR
	,outDAT		=	WDavgKpi&DtEnd.
	,procLIB	=	WORK
)
%put	%sysevalf((23+22+21+20+19+18+17+16+15+14)/10);

%*240.	Mean of all Working Days from 20160501 to 20160517.;
%let	DtBgn	=	20160501;
%let	DtEnd	=	20160517;
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	WDavgKpi
	,ChkDatVar	=	A_KPI_ANR
	,dnChkBgn	=	&DtBgn.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=	C_KPI_ID
	,genPHbyWD	=	1
	,FuncAggr	=	WMEAN
	,outVar		=	A_KPI_ANR
	,outDAT		=	WDavgKpi&DtEnd.
	,procLIB	=	WORK
)
%put	%sysevalf((23+22+21+20+19+18+17+16+15+14+13)/11);

%*250.	Max of all Calendar Days from 20160501 to 20160516.;
%let	DtBgn	=	20160501;
%let	DtEnd	=	20160516;
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	CDmaxKpi
	,ChkDatVar	=	A_KPI_MAX
	,dnChkBgn	=	&DtBgn.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=	C_KPI_ID
	,genPHbyWD	=	1
	,FuncAggr	=	CMAX
	,outVar		=	A_KPI_MAX
	,outDAT		=	CDmaxKpi&DtEnd.
	,procLIB	=	WORK
)
%put	%sysfunc(max(24,23,22,21,20,19,18,17,16,15,14));

%*260.	Max of all Calendar Days from 20160501 to 20160517.;
%let	DtBgn	=	20160501;
%let	DtEnd	=	20160517;
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	CDmaxKpi
	,ChkDatVar	=	A_KPI_MAX
	,dnChkBgn	=	&DtBgn.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=	C_KPI_ID
	,genPHbyWD	=	1
	,FuncAggr	=	CMAX
	,outVar		=	A_KPI_MAX
	,outDAT		=	CDmaxKpi&DtEnd.
	,procLIB	=	WORK
)
%put	%sysfunc(max(24,23,22,21,20,19,18,17,16,15,14,13));

%*270.	Max of all Working Days from 20160501 to 20160516.;
%let	DtBgn	=	20160501;
%let	DtEnd	=	20160516;
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	WDmaxKpi
	,ChkDatVar	=	A_KPI_MAX
	,dnChkBgn	=	&DtBgn.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=	C_KPI_ID
	,genPHbyWD	=	1
	,FuncAggr	=	WMAX
	,outVar		=	A_KPI_MAX
	,outDAT		=	WDmaxKpi&DtEnd.
	,procLIB	=	WORK
)
%put	%sysfunc(max(23,22,21,20,19,18,17,16,15,14));

%*280.	Max of all Working Days from 20160501 to 20160517.;
%let	DtBgn	=	20160501;
%let	DtEnd	=	20160517;
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	WDmaxKpi
	,ChkDatVar	=	A_KPI_MAX
	,dnChkBgn	=	&DtBgn.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=	C_KPI_ID
	,genPHbyWD	=	1
	,FuncAggr	=	WMAX
	,outVar		=	A_KPI_MAX
	,outDAT		=	WDmaxKpi&DtEnd.
	,procLIB	=	WORK
)
%put	%sysfunc(max(23,22,21,20,19,18,17,16,15,14,13));

%*300.	Rolling 10 days.;
%*310.	Mean of all Calendar Days from 20160401 to 20160410.;
%let	DtBgn	=	20160401;
%let	DtEnd	=	20160410;
%let	pDate	=	%sysfunc(putn( %eval( %sysfunc(inputn( &DtBgn. , yymmdd10. )) - 1 ) , yymmddN8. ));
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	R10ANR
	,ChkDatVar	=	A_KPI_ANR
	,dnChkBgn	=	&pDate.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=	C_KPI_ID
	,genPHbyWD	=	1
	,FuncAggr	=	CMEAN
	,outVar		=	A_KPI_ANR
	,outDAT		=	R10ANR&DtEnd.
	,procLIB	=	WORK
)
%put	%sysevalf((25*4+26+27+28+29*3)/10);

%*311.	Mean of all Calendar Days from 20160402 to 20160411.;
%let	DtBgn	=	20160402;
%let	DtEnd	=	20160411;
%let	pDate	=	%sysfunc(putn( %eval( %sysfunc(inputn( &DtBgn. , yymmdd10. )) - 1 ) , yymmddN8. ));
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	R10ANR
	,ChkDatVar	=	A_KPI_ANR
	,dnChkBgn	=	&pDate.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=	C_KPI_ID
	,genPHbyWD	=	1
	,FuncAggr	=	CMEAN
	,outVar		=	A_KPI_ANR
	,outDAT		=	R10ANR&DtEnd.
	,procLIB	=	WORK
)
%put	%sysevalf((25*3+26+27+28+29*3+30)/10);

%*312.	Mean of all Calendar Days from 20160403 to 20160412.;
%let	DtBgn	=	20160403;
%let	DtEnd	=	20160412;
%let	pDate	=	%sysfunc(putn( %eval( %sysfunc(inputn( &DtBgn. , yymmdd10. )) - 1 ) , yymmddN8. ));
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	R10ANR
	,ChkDatVar	=	A_KPI_ANR
	,dnChkBgn	=	&pDate.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=	C_KPI_ID
	,genPHbyWD	=	1
	,FuncAggr	=	CMEAN
	,outVar		=	A_KPI_ANR
	,outDAT		=	R10ANR&DtEnd.
	,procLIB	=	WORK
)
%put	%sysevalf((25*2+26+27+28+29*3+30+31)/10);

%*400.	Rolling 5 Working Days.;
%*410.	Mean of all Working Days from 20160401 to 20160408.;
%let	DtEnd	=	20160408;
%let	DtBgn	=	%PrevNthWorkDateOf( inDATE = &DtEnd. , inDateFmt = %str(yymmdd10.) , nWorkDays = 4 , inCalendar = tmpCalendar2016 , outDateFmt = %str(yymmddN8.) );
%let	pDate	=	%PrevNthWorkDateOf( inDATE = &DtBgn. , inDateFmt = %str(yymmdd10.) , nWorkDays = 1 , inCalendar = tmpCalendar2016 , outDateFmt = %str(yymmddN8.) );
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	R5WMEAN
	,ChkDatVar	=	A_KPI_ANR
	,dnChkBgn	=	&pDate.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=	C_KPI_ID
	,genPHbyWD	=	1
	,FuncAggr	=	WMEAN
	,outVar		=	A_KPI_ANR
	,outDAT		=	R5WMEAN&DtEnd.
	,procLIB	=	WORK
)
%put	%sysevalf((25+26+27+28+29)/5);

%*411.	Mean of all Working Days from 20160401 to 20160409.;
%let	DtEnd	=	20160409;
%let	DtBgn	=	%PrevNthWorkDateOf( inDATE = &DtEnd. , inDateFmt = %str(yymmdd10.) , nWorkDays = 5 , inCalendar = tmpCalendar2016 , outDateFmt = %str(yymmddN8.) );
%let	pDate	=	%PrevNthWorkDateOf( inDATE = &DtBgn. , inDateFmt = %str(yymmdd10.) , nWorkDays = 1 , inCalendar = tmpCalendar2016 , outDateFmt = %str(yymmddN8.) );
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	R5WMEAN
	,ChkDatVar	=	A_KPI_ANR
	,dnChkBgn	=	&pDate.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=	C_KPI_ID
	,genPHbyWD	=	1
	,FuncAggr	=	WMEAN
	,outVar		=	A_KPI_ANR
	,outDAT		=	R5WMEAN&DtEnd.
	,procLIB	=	WORK
)
%put	%sysevalf((25+26+27+28+29)/5);

%*412.	Mean of all Working Days from 20160405 to 20160411.;
%let	DtEnd	=	20160411;
%let	DtBgn	=	%PrevNthWorkDateOf( inDATE = &DtEnd. , inDateFmt = %str(yymmdd10.) , nWorkDays = 4 , inCalendar = tmpCalendar2016 , outDateFmt = %str(yymmddN8.) );
%let	pDate	=	%PrevNthWorkDateOf( inDATE = &DtBgn. , inDateFmt = %str(yymmdd10.) , nWorkDays = 1 , inCalendar = tmpCalendar2016 , outDateFmt = %str(yymmddN8.) );
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	R5WMEAN
	,ChkDatVar	=	A_KPI_ANR
	,dnChkBgn	=	&pDate.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=	C_KPI_ID
	,genPHbyWD	=	1
	,FuncAggr	=	WMEAN
	,outVar		=	A_KPI_ANR
	,outDAT		=	R5WMEAN&DtEnd.
	,procLIB	=	WORK
)
%put	%sysevalf((26+27+28+29+30)/5);

%*--------------------------------------------------Below For [genPHbyWD = 0]-------------------------------------------------;

%*500.	Using the same Beginning of a series of periods.;
%*510.	Mean of all Calendar Days from 20160901 to 20160910.;
%let	DtBgn	=	20160901;
%let	DtEnd	=	20160910;
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	CCMEAN
	,ChkDatVar	=	A_KPI_ANR
	,dnChkBgn	=	&DtBgn.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=
	,genPHbyWD	=	0
	,FuncAggr	=	CMEAN
	,outVar		=	A_KPI_ANR
	,outDAT		=	CCMEAN&DtEnd.
	,procLIB	=	WORK
)
%put	%sysevalf((1+2+3+4+5+6+7+8+9+10)/10);

%*520.	Mean of all Calendar Days from 20160901 to 20160911.;
%let	DtBgn	=	20160901;
%let	DtEnd	=	20160911;
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	CCMEAN
	,ChkDatVar	=	A_KPI_ANR
	,dnChkBgn	=	&DtBgn.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=
	,genPHbyWD	=	0
	,FuncAggr	=	CMEAN
	,outVar		=	A_KPI_ANR
	,outDAT		=	CCMEAN&DtEnd.
	,procLIB	=	WORK
)
%put	%sysevalf((1+2+3+4+5+6+7+8+9+10+11)/11);

%*530.	Mean of all Working Days from 20160901 to 20160911.;
%let	DtBgn	=	20160901;
%let	DtEnd	=	20160911;
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	CWMEAN
	,ChkDatVar	=	A_KPI_ANR
	,dnChkBgn	=	&DtBgn.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=
	,genPHbyWD	=	0
	,FuncAggr	=	WMEAN
	,outVar		=	A_KPI_ANR
	,outDAT		=	CWMEAN&DtEnd.
	,procLIB	=	WORK
)
%put	%sysevalf((1+2+5+6+7+8+9)/7);

%*540.	Mean of all Working Days from 20160901 to 20160912.;
%let	DtBgn	=	20160901;
%let	DtEnd	=	20160912;
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	CWMEAN
	,ChkDatVar	=	A_KPI_ANR
	,dnChkBgn	=	&DtBgn.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=
	,genPHbyWD	=	0
	,FuncAggr	=	WMEAN
	,outVar		=	A_KPI_ANR
	,outDAT		=	CWMEAN&DtEnd.
	,procLIB	=	WORK
)
%put	%sysevalf((1+2+5+6+7+8+9+12)/8);

%*550.	Max of all Calendar Days from 20161001 to 20161010.;
%let	DtBgn	=	20161001;
%let	DtEnd	=	20161010;
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	CCMAX
	,ChkDatVar	=	A_KPI_MAX
	,dnChkBgn	=	&DtBgn.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=
	,genPHbyWD	=	0
	,FuncAggr	=	CMAX
	,outVar		=	A_KPI_MAX
	,outDAT		=	CCMAX&DtEnd.
	,procLIB	=	WORK
)
%put	%sysfunc(max(31,32,33,34,35,36,37,38,39,40));

%*560.	Max of all Calendar Days from 20161001 to 20161011.;
%let	DtBgn	=	20161001;
%let	DtEnd	=	20161011;
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	CCMAX
	,ChkDatVar	=	A_KPI_MAX
	,dnChkBgn	=	&DtBgn.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=
	,genPHbyWD	=	0
	,FuncAggr	=	CMAX
	,outVar		=	A_KPI_MAX
	,outDAT		=	CCMAX&DtEnd.
	,procLIB	=	WORK
)
%put	%sysfunc(max(31,32,33,34,35,36,37,38,39,40,41));

%*570.	Min of all Working Days from 20161001 to 20161010.;
%let	DtBgn	=	20161001;
%let	DtEnd	=	20161010;
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	CWMIN
	,ChkDatVar	=	A_KPI_MAX
	,dnChkBgn	=	&DtBgn.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=
	,genPHbyWD	=	0
	,FuncAggr	=	WMIN
	,outVar		=	A_KPI_MAX
	,outDAT		=	CWMIN&DtEnd.
	,procLIB	=	WORK
)
%put	%sysfunc(min(38,39,40));

%*580.	Min of all Working Days from 20161001 to 20161011.;
%let	DtBgn	=	20161001;
%let	DtEnd	=	20161011;
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	CWMIN
	,ChkDatVar	=	A_KPI_MAX
	,dnChkBgn	=	&DtBgn.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=
	,genPHbyWD	=	0
	,FuncAggr	=	WMIN
	,outVar		=	A_KPI_MAX
	,outDAT		=	CWMIN&DtEnd.
	,procLIB	=	WORK
)
%put	%sysfunc(min(38,39,40,41));

%*600.	Rolling 5 Calendar Days.;
%*610.	Mean of all Calendar Days from 20161007 to 20161011.;
%let	DtBgn	=	20161007;
%let	DtEnd	=	20161011;
%let	pDate	=	%sysfunc(putn( %eval( %sysfunc(inputn( &DtBgn. , yymmdd10. )) - 1 ) , yymmddN8. ));
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	RC5CMEAN
	,ChkDatVar	=	A_KPI_ANR
	,dnChkBgn	=	&pDate.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=
	,genPHbyWD	=	0
	,FuncAggr	=	CMEAN
	,outVar		=	A_KPI_ANR
	,outDAT		=	RC5CMEAN&DtEnd.
	,procLIB	=	WORK
)
%put	%sysevalf((37+38+39+40+41)/5);

%*611.	Mean of all Calendar Days from 20161008 to 20161012.;
%let	DtBgn	=	20161008;
%let	DtEnd	=	20161012;
%let	pDate	=	%sysfunc(putn( %eval( %sysfunc(inputn( &DtBgn. , yymmdd10. )) - 1 ) , yymmddN8. ));
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	RC5CMEAN
	,ChkDatVar	=	A_KPI_ANR
	,dnChkBgn	=	&pDate.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=
	,genPHbyWD	=	0
	,FuncAggr	=	CMEAN
	,outVar		=	A_KPI_ANR
	,outDAT		=	RC5CMEAN&DtEnd.
	,procLIB	=	WORK
)
%put	%sysevalf((38+39+40+41+42)/5);

%*612.	Mean of all Calendar Days from 20161009 to 20161013.;
%let	DtBgn	=	20161009;
%let	DtEnd	=	20161013;
%let	pDate	=	%sysfunc(putn( %eval( %sysfunc(inputn( &DtBgn. , yymmdd10. )) - 1 ) , yymmddN8. ));
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	RC5CMEAN
	,ChkDatVar	=	A_KPI_ANR
	,dnChkBgn	=	&pDate.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=
	,genPHbyWD	=	0
	,FuncAggr	=	CMEAN
	,outVar		=	A_KPI_ANR
	,outDAT		=	RC5CMEAN&DtEnd.
	,procLIB	=	WORK
)
%put	%sysevalf((39+40+41+42+43)/5);

%*700.	Rolling 5 Working Days.;
%*710.	Mean of all Working Days from 20160930 to 20161011.;
%let	DtEnd	=	20161011;
%let	DtBgn	=	%PrevNthWorkDateOf( inDATE = &DtEnd. , inDateFmt = %str(yymmdd10.) , nWorkDays = 4 , inCalendar = tmpCalendar2016 , outDateFmt = %str(yymmddN8.) );
%let	pDate	=	%PrevNthWorkDateOf( inDATE = &DtBgn. , inDateFmt = %str(yymmdd10.) , nWorkDays = 1 , inCalendar = tmpCalendar2016 , outDateFmt = %str(yymmddN8.) );
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	RC5WMEAN
	,ChkDatVar	=	A_KPI_ANR
	,dnChkBgn	=	&pDate.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=
	,genPHbyWD	=	0
	,FuncAggr	=	WMEAN
	,outVar		=	A_KPI_ANR
	,outDAT		=	RC5WMEAN&DtEnd.
	,procLIB	=	WORK
)
%put	%sysevalf((30+38+39+40+41)/5);

%*711.	Mean of all Working Days from 20161007 to 20161012.;
%let	DtEnd	=	20161012;
%let	DtBgn	=	%PrevNthWorkDateOf( inDATE = &DtEnd. , inDateFmt = %str(yymmdd10.) , nWorkDays = 4 , inCalendar = tmpCalendar2016 , outDateFmt = %str(yymmddN8.) );
%let	pDate	=	%PrevNthWorkDateOf( inDATE = &DtBgn. , inDateFmt = %str(yymmdd10.) , nWorkDays = 1 , inCalendar = tmpCalendar2016 , outDateFmt = %str(yymmddN8.) );
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	RC5WMEAN
	,ChkDatVar	=	A_KPI_ANR
	,dnChkBgn	=	&pDate.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=
	,genPHbyWD	=	0
	,FuncAggr	=	WMEAN
	,outVar		=	A_KPI_ANR
	,outDAT		=	RC5WMEAN&DtEnd.
	,procLIB	=	WORK
)
%put	%sysevalf((38+39+40+41+42)/5);

%*712.	Mean of all Working Days from 20161008 to 20161013.;
%let	DtEnd	=	20161013;
%let	DtBgn	=	%PrevNthWorkDateOf( inDATE = &DtEnd. , inDateFmt = %str(yymmdd10.) , nWorkDays = 4 , inCalendar = tmpCalendar2016 , outDateFmt = %str(yymmddN8.) );
%let	pDate	=	%PrevNthWorkDateOf( inDATE = &DtBgn. , inDateFmt = %str(yymmdd10.) , nWorkDays = 1 , inCalendar = tmpCalendar2016 , outDateFmt = %str(yymmddN8.) );
%AggrByPeriod(
	inClndrPfx	=	work.tmpCalendar
	,inDatPfx	=	kpi
	,AggrVar	=	A_KPI_VAL
	,dnDateBgn	=	&DtBgn.
	,dnDateEnd	=	&DtEnd.
	,ChkDatPfx	=	RC5WMEAN
	,ChkDatVar	=	A_KPI_ANR
	,dnChkBgn	=	&pDate.
	,ByVar		=	%nrbquote(
						nc_cifno
						nc_acct_no
					)
	,CopyVar	=
	,genPHbyWD	=	0
	,FuncAggr	=	WMEAN
	,outVar		=	A_KPI_ANR
	,outDAT		=	RC5WMEAN&DtEnd.
	,procLIB	=	WORK
)
%put	%sysevalf((39+40+41+42+43)/5);

/*-Notes- -End-*/