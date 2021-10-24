%macro DBuse_crKPIbyFnOnKPIID(
	inDat		=
	,inCLASS	=
	,inKPIlist	=
	,inFormula	=	%nrstr(.)
	,outKPIID	=
	,outDAT		=
	,procLIB	=	WORK
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to create a new KPI with regards of a function or formula that is applied to some							|
|	| KPIs in the inventory.																											|
|	|IMPORTANT: Since the formula is not controlled, there may be invalid values generated due to missing values						|
|	| in the input data. Hence there may be special notes or even warnings during the calculation. We close the							|
|	| log for such cases, unless the invalid values reach the limit of the threshold.													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDat		:	The dataset that stores the required KPIs as well as the Classes to summarize the result.							|
|	|inCLASS	:	The list of field names that are treated as Classes to summarize the result.										|
|	|inKPIlist	:	The list of KPI IDs that are involved in the formula of calculation.												|
|	|inFormula	:	The mathematical formula to calculate the value of the new KPI to be created.										|
|	|outKPIID	:	The ID to be tagged to the newly created KPI.																		|
|	|outDAT		:	The output result.																									|
|	|procLIB	:	The working library.																								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20160605		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20160820		| Version |	1.01		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |(1) Fix the LABEL in the output data when the original KPI has no label.													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20160821		| Version |	1.02		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |(1) No longer initialize the numeric variables during the implementation of Formula, to cater to some specific methods,		|
|	|      |     such as MIN and MAX.																									|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20171108		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Create the interim variables for all input KPIs during the calculation, regardless of the existence of the datasets storing	|
|	|      | them, in case the provided formula refers to a non-existing KPI and thus the process issues a warning message.				|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180304		| Version |	2.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
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
|	|	|InitNumVar																														|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\FileSystem"																						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|FS_VarExists																													|
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
%if	%length(%qsysfunc(compress(&inFormula.,%str( ))))	=	0	%then	%let	inFormula	=	%nrstr(.);
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))		=	0	%then	%let	procLIB		=	WORK;

%if	%length(%qsysfunc(compress(&inDat.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No Input data is specified! Skip the process.;
	%goto	EndOfProc;
%end;

%if	%length(%qsysfunc(compress(&inKPIlist.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No KPI is specified for calculation! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No output data is specified! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*013.	Define the local environment.;
%local
	LchkNOTES
	prxReplaceKpiID
	LpfxTranspose
	Ci
	Si
	LnMisClassVar
	LMisClassList
	LnMisKpiForFn
	LMisKpiForFnLst
	RepFldDSID
	RepFldVarNum
	LstOfRepFld
	Ri
	rc
;
%let	LchkNOTES		=	%sysfunc(getoption(notes));
%let	LpfxTranspose	=	_;
%let	LnMisClassVar	=	0;
%let	LMisClassList	=;
%let	LnMisKpiForFn	=	0;
%let	LMisKpiForFnLst	=;
%let	LstOfRepFld		=	C_KPI_ID A_KPI_VAL;

%*018.	Define the global environment.;
%if	%length(%qsysfunc(compress(&inCLASS.,%str( ))))	=	0	%then %do;
	%goto	EndOfClassLst;
%end;
%genvarlist(
	nstart		=	1
	,inlst		=	&inCLASS.
	,nvarnm		=	LeCrKpiClass
	,nvarttl	=	LnCrKpiClass
)
%EndOfClassLst:
%genvarlist(
	nstart		=	1
	,inlst		=	&inKPIlist.
	,nvarnm		=	LeCrKpiSrc
	,nvarttl	=	LnCrKpiSrc
)
%genvarlist(
	nstart		=	1
	,inlst		=	&LstOfRepFld.
	,nvarnm		=	LeRepFld
	,nvarttl	=	LnRepFld
)

%*100.	Only retrieve the necessary KPIs for the calculation.;
data &procLIB..__crKpiByFn_src__;
	set %unquote(&inDat.);
	if	C_KPI_ID	in	(
		%do Si=1 %to &LnCrKpiSrc.;
			"&&LeCrKpiSrc&Si.."
		%end;
		)
		then do;
		output;
	end;
run;

%*150.	Abort the process if any of the [inCLASS] does not exist in the source data.;
%*151.	Only conduct this check when there is [inCLASS] provided.;
%if	%length(%qsysfunc(compress(&inCLASS.,%str( ))))	=	0	%then %do;
	%goto	EndOfClassChk;
%end;

%*155.	Identify those fields that do not exist in the source data.;
%do Ci=1 %to &LnCrKpiClass.;
	%if	%FS_VarExists( inDAT = &procLIB..__crKpiByFn_src__ , inFLD = &&LeCrKpiClass&Ci.. )	=	0	%then %do;
		%*100.	Increment the counter of the missing fields.;
		%let	LnMisClassVar	=	%eval( &LnMisClassVar. + 1 );

		%*200.	Prepare the field list for the error message.;
		%let	LMisClassList	=	&LMisClassList.[&&LeCrKpiClass&Ci..];
	%end;
%end;

%*156.	Issue the error message if there is any field missing for the summarization.;
%if	&LnMisClassVar.	>	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]Some fields defined in [inCLASS] are required but missing! Program is interrupted!;
	%put	%str(E)RROR: [&L_mcrLABEL.]These fields should exist in the input data: &LMisClassList.;
	%put	&Lohno.;
	%ErrMcr
%end;

%*159.	Mark the end of current step.;
%EndOfClassChk:

%*170.	Abort the process if any of the [inKPIlist] does not exist in the source data.;
%*171.	Only conduct this check when there is [inKPIlist] provided.;
%if	%length(%qsysfunc(compress(&inKPIlist.,%str( ))))	=	0	%then %do;
	%goto	EndOfKpiChk;
%end;

%*172.	Extract the KPI list that exist in the source data.;
proc freq
	data=&procLIB..__crKpiByFn_src__
	noprint
;
	tables
		C_KPI_ID
		/list
		out=&procLIB..__crKpiByFn_KpiExist__
	;
run;

%*175.	Verify whether the KPI ID in [inKPIlist] has observation in above data.;
%do Si=1 %to &LnCrKpiSrc.;
	%if	%getOBS4DATA( inDAT = %nrbquote(&procLIB..__crKpiByFn_KpiExist__(where=(C_KPI_ID="&&LeCrKpiSrc&Si.."))) , gMode = F )	=	0	%then %do;
		%*100.	Increment the counter of the missing KPIs.;
		%let	LnMisKpiForFn	=	%eval( &LnMisKpiForFn. + 1 );

		%*200.	Prepare the field list for the error message.;
		%let	LMisKpiForFnLst	=	&LMisKpiForFnLst.[&&LeCrKpiSrc&Si..];
	%end;
%end;

%*176.	Issue the warning message if there is any KPI missing for the formula.;
%if	&LnMisKpiForFn.	>	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Some KPIs defined in [inKPIlist] are required but missing! Skip the process.;
	%put	%str(N)OTE: [&L_mcrLABEL.]These KPIs should exist in the input data: &LMisKpiForFnLst.;
	%goto	EndOfProc;
%end;

%*179.	Mark the end of current step.;
%EndOfKpiChk:

%*200.	Translate the formula.;
%*Since the formula is comprised of the KPI IDs, we need to translate each KPI ID into the temporary field name for calculation.;
%*Although we can use [TRANWRD] function, we should avoid some extreme cases that [TRANWRD] will replace the incorrect names.;
%*e.g. if the KPI list is: [FF100 EFF100];
%* while we should replace [FF100] with [_FF100] in above character string,;
%* the [TRANWRD] function leads to the result as: [_FF100 E_FF100].;
%* This will result in the error as the TRANSPOSE procedure only add the Prefix to all transposed variables.;
%do Si=1 %to &LnCrKpiSrc.;
	%*100.	Prepare the PRX pattern that can match the current KPI ID, and replace it with the temporary field name.;
	%let	prxReplaceKpiID	=	%sysfunc(prxparse(s/\b(&&LeCrKpiSrc&Si..)\b/&LpfxTranspose.\1/ismx));

	%*200.	Replace the KPI ID with the temporary field name in the [inFormula].;
	%let	inFormula		=	%qsysfunc(prxchange(&prxReplaceKpiID.,-1,&inFormula.));
%end;

%*290.	Free the memory.;
%syscall	prxfree(prxReplaceKpiID);

%*300.	Replicate the formats and lengths of the key variables in the source data.;
%*This is because that we have to re-create them in the output data.;
%*310.	Open the source data.;
%let	RepFldDSID	=	%sysfunc(open(&procLIB..__crKpiByFn_src__));

%*320.	Information for the replicated fields.;
%do Ri=1 %to &LnRepFld.;
	%*100.	Retrieve the VARNUM of current variable.;
	%let	RepFldVarNum	=	%sysfunc(varnum(&RepFldDSID.,&&LeRepFld&Ri..));

	%*200.	Retrieve its attributes.;
	%local
		LeRepFld&Ri.Type
		LeRepFld&Ri.fmt
		LeRepFld&Ri.lbl
		LeRepFld&Ri.len
		LeRepFld&Ri.fmtf
	;
	%*Since there could be COMMA in the variable format and label, we macro-quote the necessary results.;
	%let	LeRepFld&Ri.Type	=	%sysfunc(vartype(&RepFldDSID.,&RepFldVarNum.));		%*Its value should not be quoted.;
	%let	LeRepFld&Ri.fmt		=	%qsysfunc(varfmt(&RepFldDSID.,&RepFldVarNum.));
	%let	LeRepFld&Ri.lbl		=	%qsysfunc(varlabel(&RepFldDSID.,&RepFldVarNum.));
	%let	LeRepFld&Ri.len		=	%sysfunc(varlen(&RepFldDSID.,&RepFldVarNum.));		%*Its value should not be quoted.;
	%let	LeRepFld&Ri.fmtf	=	%sysfunc(ifn(&&LeRepFld&Ri.fmt.=,0,1));
%end;

%*390.	Close the source data.;
%CloseDat:
%let	rc	=	%sysfunc(close(&RepFldDSID.));

%*500.	Summarize the input data in terms of the [inCLASS].;
proc means
	data=&procLIB..__crKpiByFn_src__
	noprint
	missing
	nway
;
	class
%if	%length(%qsysfunc(compress(&inCLASS.,%str( ))))	^=	0	%then %do;
	%do Ci=1 %to &LnCrKpiClass.;
		&&LeCrKpiClass&Ci..
	%end;
%end;
		C_KPI_ID
	;
	var
		A_KPI_VAL
	;
	output
		out=&procLIB..__crKpiByFn_mns__
		sum=A_KPI_VAL
	;
run;

%*600.	Transposition.;
%*This step will add the prefix [_] to all involved KPI IDs to generate the temporary fields.;
%if	%length(%qsysfunc(compress(&inCLASS.,%str( ))))	^=	0	%then %do;
proc sort
	data=&procLIB..__crKpiByFn_mns__
;
	by
	%do Ci=1 %to &LnCrKpiClass.;
		&&LeCrKpiClass&Ci..
	%end;
	;
run;
%end;
proc transpose
	data=&procLIB..__crKpiByFn_mns__
	out=&procLIB..__crKpiByFn_trns__
	prefix=&LpfxTranspose.
;
%if	%length(%qsysfunc(compress(&inCLASS.,%str( ))))	^=	0	%then %do;
	by
	%do Ci=1 %to &LnCrKpiClass.;
		&&LeCrKpiClass&Ci..
	%end;
	;
%end;
	id	C_KPI_ID;
	var	A_KPI_VAL;
run;

%*700.	Calculation.;
%*710.	Close the system options to prevent too many notes on invalid values.;
options
	nonotes
;

%*750.	Output.;
data %unquote(&outDAT.);
	%*050.	Initialize the input KPI variables to facilitate the implementation of the formula.;
	%do Si=1 %to &LnCrKpiSrc.;
		length	&LpfxTranspose.%unquote(&&LeCrKpiSrc&Si..)	8;
		call missing(&LpfxTranspose.%unquote(&&LeCrKpiSrc&Si..));
	%end;

	%*100.	Set the data.;
	set &procLIB..__crKpiByFn_trns__;

	%*200.	Create the field storing the value of the new KPI.;
	%*210.	Lengths.;
	length
	%do Ri=1 %to &LnRepFld.;
		&&LeRepFld&Ri..
		%if	&&LeRepFld&Ri.Type.	=	N	%then %do;
			&&LeRepFld&Ri.len.
		%end;
		%else %do;
			$&&LeRepFld&Ri.len.
		%end;
	%end;
	;

	%*220.	Labels.;
	%*This statement should be created separately, since there could be NO label for any of the fields.;
	%do Ri=1 %to &LnRepFld.;
		%if	%length(&&LeRepFld&Ri.lbl.)	^=	0	%then %do;
			label	&&LeRepFld&Ri..	=	%sysfunc(quote(&&LeRepFld&Ri.lbl.,%str(%')));
		%end;
	%end;

	%*230.	Formats.;
	%*This statement should be created separately, since there could be NO format for any of the fields.;
	%do Ri=1 %to &LnRepFld.;
		%if	&&LeRepFld&Ri.fmtf.	=	1	%then %do;
			format	&&LeRepFld&Ri..	&&LeRepFld&Ri.fmt.;
		%end;
	%end;

	%*290.	Initialization.;
	%do Ri=1 %to &LnRepFld.;
		call missing(&&LeRepFld&Ri..);
	%end;

	%*300.	Initialize all numeric fields for the application of the formula.;
	%*InitNumVar;

	%*400.	Calculation in terms of the formula.;
	C_KPI_ID	=	%sysfunc(quote(&outKPIID.,%str(%')));
	A_KPI_VAL	=	%unquote(&inFormula.);

	%*900.	Purge.;
	keep
%if	%length(%qsysfunc(compress(&inCLASS.,%str( ))))	^=	0	%then %do;
	%do Ci=1 %to &LnCrKpiClass.;
		&&LeCrKpiClass&Ci..
	%end;
%end;
	%do Ri=1 %to &LnRepFld.;
		&&LeRepFld&Ri..
	%end;
	;
run;

%*900.	Purge.;

%*990.	Restore the system options.;
options
	&LchkNOTES.
;

%EndOfProc:
%mend DBuse_crKPIbyFnOnKPIID;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvOp"
		"D:\SAS\omnimacro\AdvDB"
		"D:\SAS\omnimacro\FileSystem"
	)
	mautosource
;

%*100.	Create the test KPI tables.;
data kpi;
	format
		c_city		$8.
		nc_branch	$8.
		nc_cifno	$32.
		nc_acct_no	$64.
		C_KPI_ID	$16.
		A_KPI_VAL	best32.
	;

	%*100.	City 1.;
	c_city		=	"SH";

	%*110.	SHM;
	nc_branch	=	"SHM";

	%*111.	CASA;
	nc_cifno	=	"0001";
	nc_acct_no	=	"0000101";
	C_KPI_ID	=	"220000";
	A_KPI_VAL	=	55000;
	output;

	nc_cifno	=	"0002";
	nc_acct_no	=	"0000102";
	C_KPI_ID	=	"220000";
	A_KPI_VAL	=	15000;
	output;

	%*TD;
	nc_cifno	=	"0002";
	nc_acct_no	=	"0001101";
	C_KPI_ID	=	"220102";
	A_KPI_VAL	=	600000;
	output;

	%*200.	City 2.;
	c_city		=	"BJ";

	%*110.	BJM;
	nc_branch	=	"BJM";

	%*111.	CASA;
	nc_cifno	=	"0003";
	nc_acct_no	=	"0000111";
	C_KPI_ID	=	"220000";
	A_KPI_VAL	=	370000;
	output;

	nc_cifno	=	"0012";
	nc_acct_no	=	"0000122";
	C_KPI_ID	=	"220000";
	A_KPI_VAL	=	3000;
	output;

	%*ASP;
	nc_cifno	=	"0003";
	nc_acct_no	=	"0021101";
	C_KPI_ID	=	"220302";
	A_KPI_VAL	=	500000;
	output;

	%*120.	DC;
	nc_branch	=	"DC";

	%*111.	CASA;
	nc_cifno	=	"0023";
	nc_acct_no	=	"0030111";
	C_KPI_ID	=	"220000";
	A_KPI_VAL	=	160000;
	output;

	%*TD;
	nc_cifno	=	"0103";
	nc_acct_no	=	"0041101";
	C_KPI_ID	=	"220102";
	A_KPI_VAL	=	100000;
	output;
run;

%DBuse_crKPIbyFnOnKPIID(
	inDat		=	kpi
	,inCLASS	=	%nrbquote(
						c_city
						nc_branch
					)
	,inKPIlist	=	%nrbquote(
						220000
						220102
						220302
					)
	,inFormula	=	%nrstr(
						220000 / sum(220000,220102,220302)
					)
	,outKPIID	=	510000
	,outDAT		=	CASApct
	,procLIB	=	WORK
)

%DBuse_crKPIbyFnOnKPIID(
	inDat		=	kpi
	,inCLASS	=
	,inKPIlist	=	%nrbquote(
						220000
						220102
						220302
					)
	,inFormula	=	%nrstr(
						220000 / sum(220000,220102,220302)
					)
	,outKPIID	=	510000
	,outDAT		=	CASApctAll
	,procLIB	=	WORK
)

%DBuse_crKPIbyFnOnKPIID(
	inDat		=	kpi
	,inCLASS	=	nc_cifno
	,inKPIlist	=	%nrbquote(
						220000
						220102
						220302
					)
	,inFormula	=	%nrstr(
						220000 / sum(220000,220102,220302)
					)
	,outKPIID	=	510000
	,outDAT		=	CASApctCifNo
	,procLIB	=	WORK
)

/*-Notes- -End-*/