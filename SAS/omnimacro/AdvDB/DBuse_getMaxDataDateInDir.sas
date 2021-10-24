%macro DBuse_getMaxDataDateInDir(
	inDir		=
	,inDatPfx	=
	,inDatExt	=	sas7bdat
	,inVar		=
	,DateBgn	=
	,DateEnd	=
	,outDate	=	G_d_MAX
	,oDDatName	=	G_DM_Name
	,oDDatPath	=	G_DM_Path
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to identify the latest data date (usually D_TABLE) from a series of datasets, with certain prefix and date	|
|	| suffix in [yyyymmdd] format, in a given directory or all its sub-directories, within a given period of time.						|
|	|It is useful when the user needs to report an Incremental summary in terms of the previously generated reports, for example the	|
|	| campaign targeted customers in each batch excluding those who were targeted in the last batch.									|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDir		:	The directory in which to search for the certain series of datasets.												|
|	|inDatPfx	:	The prefix of the datasets to be searched.																			|
|	|inDatExt	:	The file extension of the datasets to be searched, default as SAS7BDAT in the SAS 9.4 environment.					|
|	|inVar		:	The DATE variable among whose values we will identify the maximum one, in all the datasets to be searched.			|
|	|				If it is left blank, we will only find the largest SUFFIX of the datasets instead.									|
|	|DateBgn	:	The beginning of the period within which to search for the datasets.												|
|	|				It must be provided as a DATE VALUE rather than a formatted character string. e.g. 20994 (meaning [2017-06-24]).	|
|	|				It is INCLUDED during the date comparison ([outDate] >= [DateBgn]).													|
|	|DateEnd	:	The end of the period within which to search for the datasets.														|
|	|				It must be provided as a DATE VALUE rather than a formatted character string. e.g. 20994 (meaning [2017-06-24]).	|
|	|				It is EXCLUDED during the date comparison ([outDate] <  [DateEnd]).													|
|	|outDate	:	The output date value without formatting.																			|
|	|				It is set as a missing numeric value (.) if no valid date is found, rather than a null character string.			|
|	|oDDatName	:	The dataset in which the output date value is identified.															|
|	|oDDatPath	:	The dataset path in which the output date value is identified.														|
|	|				Since its value is assigned by CALL SYMPUTX routine in DATA step, we should reference its value by [SUPERQ] to		|
|	|				 avoid unexpected result.																							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20170624		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170724		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Use [SUPERQ] to mask all references to the directory names, for there could be %nrstr(&) and %nrstr(%%) in the names.		|
|	|      |Add a reference to a predefined macro [OSDirDlm] to generate the directory name delimiter for current OS.					|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170805		| Version |	1.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Remove the call of the function SORTC during the sorting of dataset names and replace it with the classic POPUP method.		|
|	|      |Reason: [C:\ABC\D20170804.sas7bdat] is recognized as SMALLER than [C:\D20170803.sas7bdat] when calling SORTC directly.		|
|	|      |Hence we should sort the names at first, then retrieve the full paths of the names at the second step.						|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170810		| Version |	1.30		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Minimize the use of [SUPERQ] to avoid the excession of macro-quoting layers.												|
|	|      |Concept:																													|
|	|      |If some value is macro-quoted, its quoting status will be inherited to all the subsequent references unless it is modified	|
|	|      | by another macro function (adding additional characters before or after it will have no effect, e.g. [aa&bb.cc]).			|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20171018		| Version |	1.40		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Remove the macro function UNQUOTE from parameter handling, to avoid unexpected result.										|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180304		| Version |	1.50		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Please find the attachments for examples.																							|
|	|The names of the series of datasets should follow the convention as: [&inDatPfx.<yyyymmdd>]										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ErrMcr																															|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\FileSystem"																						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|getMemberByStrPattern																											|
|	|	|OSDirDlm																														|
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

%if	%length(%qsysfunc(compress(&inDatExt.,%str( ))))	=	0	%then	%let	inDatExt	=	sas7bdat;
%if	%length(%qsysfunc(compress(&outDate.,%str( ))))		=	0	%then %do;
	%let	outDate	=	G_d_MAX;
	%global	&outDate.;
%end;
%if	%length(%qsysfunc(compress(&oDDatName.,%str( ))))	=	0	%then %do;
	%let	oDDatName	=	G_DM_Name;
	%global	&oDDatName.;
%end;
%if	%length(%qsysfunc(compress(&oDDatPath.,%str( ))))	=	0	%then %do;
	%let	oDDatPath	=	G_DM_Path;
	%global	&oDDatPath.;
%end;

%*013.	Define the local environment.;
%local
	Fi
	TnDat
	Ti
	Tj
	LNmLst
	rcLib
	TFull
	TPath
	TName
;
%let	TnDat	=	0;
%let	LNmLst	=;

%*018.	Define the global environment.;
%let	&outDate.	=	.;
%let	&oDDatName.	=;
%let	&oDDatPath.	=;

%*100.	Retrieve the names of all datasets with the provided prefix in the given directory and all its sub-directories.;
%*NOTE: Although we should identify the Suffix as <yyyymmdd>, we cannot tell whether [\d{8}] represents a date.;
%*      That is why we put the dates as character string during the comparison.;
%getMemberByStrPattern(
	inDIR		=	&inDir.
	,inRegExp	=	%nrbquote(^&inDatPfx.\d{8}\.&inDatExt.$)
	,exclRegExp	=
	,chkType	=	1
	,FSubDir	=	1
	,mNest		=	0
	,outCNT		=	LnDat
	,outELpfx	=	LeDat
	,outElTpPfx	=	LtDat
	,outElPPfx	=	LpDat
	,outElNmPfx	=	LmDat
)

%*190.	Quit the program if there is no dataset matching the provided rule.;
%if	&LnDat.	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No dataset matching the provided rule is found.;
	%goto	EndOfProc;
%end;

%*200.	We only need the files representing the dates within the given period of time.;
%do Fi=1 %to &LnDat.;
	%if		%qupcase(&&LmDat&Fi..)	>=	%qupcase(&inDatPfx.%sysfunc(putn(&DateBgn.,yymmddN8.)).&inDatExt.)
		and	%qupcase(&&LmDat&Fi..)	<	%qupcase(&inDatPfx.%sysfunc(putn(&DateEnd.,yymmddN8.)).&inDatExt.)
		%then %do;
		%*100.	Increment the counter.;
		%let	TnDat	=	%eval( &TnDat. + 1 );

		%*200.	Create new macro variable to hold the names matching the given rule.;
		%local
			TeDat&TnDat.
			TpDat&TnDat.
			TmDat&TnDat.
		;
		%let	TeDat&TnDat.	=	%qupcase(&&LeDat&Fi..);
		%let	TpDat&TnDat.	=	%qupcase(&&LpDat&Fi..);
		%let	TmDat&TnDat.	=	%qupcase(&&LmDat&Fi..);
	%end;
%end;

%*290.	Quit the program if there is no dataset matching the provided rule.;
%if	&TnDat.	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No dataset is found within the provided period [%sysfunc(putn(&DateBgn.,yymmddN8.))] to [%sysfunc(putn(&DateEnd.,yymmddN8.))].;
	%goto	EndOfProc;
%end;

%*300.	Sort the names in DESCENDING order to reduce the system effort.;
%*If the dataset is the most recently created, we can skip the older ones.;
%do Ti=1 %to &TnDat.;
	%do Tj=%eval( &Ti. + 1 ) %to &TnDat.;
		%*100.	Abort the process if we find any two datasets with the same name.;
		%if	&&TmDat&Ti..	=	&&TmDat&Tj..	%then %do;
			%put	%str(W)ARNING: [&L_mcrLABEL.]Two datasets with the same name are found!;
			%put	%str(W)ARNING: [&L_mcrLABEL.]One is [&&TeDat&Ti..];
			%put	%str(W)ARNING: [&L_mcrLABEL.]Another is [&&TeDat&Tj..];
			%put	%str(W)ARNING: [&L_mcrLABEL.]System cannot detect which one is correct to be sorted!;
			%ErrMcr
		%end;

		%*200.	Exchange the position of the two names if the latter is LARGER than the former one.;
		%if	&&TmDat&Ti..	<	&&TmDat&Tj..	%then %do;
			%*100.	Set the temporary variables.;
			%let	TFull		=	&&TeDat&Ti..;
			%let	TPath		=	&&TpDat&Ti..;
			%let	TName		=	&&TmDat&Ti..;

			%*200.	Assign the current [Ti]th element with the larger value.;
			%let	TeDat&Ti.	=	&&TeDat&Tj..;
			%let	TpDat&Ti.	=	&&TpDat&Tj..;
			%let	TmDat&Ti.	=	&&TmDat&Tj..;

			%*300.	Assign the current [Tj]th element with the smaller value.;
			%let	TeDat&Tj.	=	&TFull.;
			%let	TpDat&Tj.	=	&TPath.;
			%let	TmDat&Tj.	=	&TName.;
		%end;
	%end;
%end;

%*400.	Here we discard the file extension to identify the Dataset Name.;
%*Function QSCAN is not required, for there cannot be special characters in dataset names.;
%do Ti=1 %to &TnDat.;
	%local
		TDatName&Ti.
	;
	%let	TDatName&Ti.	=	%scan(&&TmDat&Ti..,1,.);
%end;

%*500.	We extract the suffix of the most recent dataset, given that the [inVar] is NOT provided and thus the data date is to be implicated.;
%if	%length(%qsysfunc(compress(&inVar.,%str( ))))	=	0	%then %do;
	%*100.	Issue a note in the log.;
	%put	%str(N)OTE: [&L_mcrLABEL.]Date variable is not indicated hence the date suffix of the dataset is to be verified.;

	%*200.	We directly extract the suffix of the first dataset as in the sorted list above and quit the program.;
	%let	&oDDatPath.	=	&TpDat1.;
	%let	&oDDatName.	=	&TDatName1.;
	%let	&outDate.	=	%sysfunc(inputn(%substr(&&&oDDatName..,%eval(%length(&&&oDDatName..) - 7)),yymmdd10.));

	%*900.	Quit the program.;
	%goto	EndOfProc;
%end;

%*700.	Search the [inVar] in each dataset and determine the maximum date value.;
%*710.	Establish libraries for all datasets as listed above.;
%do Ti=1 %to &TnDat.;
	%let	rcLib	=	%sysfunc(libname(__tM&Ti.,&&TpDat&Ti..,BASE,access=readonly));
%end;

%*750.	Use the HASH Object to load all datasets into RAM for value comparison.;
%*This approach is faster than to SET them via hard drive.;
data _NULL_;
	%*100.	Create fields for calculation.;
	format
		&inVar.	yymmddD10.
		maxPath	$512.
		maxDS	$64.
	%do Ti=1 %to &TnDat.;
		rc&Ti.	best12.
	%end;
		maxDT	yymmddD10.
	;
	call missing(&inVar.,maxPath,maxDS,maxDT,of rc:);

	%*200.	Establish the HASH Object to load the datasets.;
	%*We only hash the [inVar], and only in DESCENDING order.;
	%*Hence there is only ONE observation we will have to load from each dataset.;
%do Ti=1 %to &TnDat.;
	dcl	hash	hMD&Ti.(dataset:%sysfunc(quote(__tM&Ti..&&TDatName&Ti..,%str(%'))),ordered:"D",multidata:"N");
	hMD&Ti..DefineKey(%sysfunc(quote(&inVar.,%str(%'))));
	hMD&Ti..DefineData(%sysfunc(quote(&inVar.,%str(%'))));
	hMD&Ti..DefineDone();
	dcl	hiter	hiMD&Ti.(%sysfunc(quote(hMD&Ti.,%str(%'))));
%end;

	%*300.	Read the [inVar] in all the datasets and identify the maximum value.;
%do Ti=1 %to &TnDat.;
	%*310.	Retrieve the very maximum value of [inVar] from current dataset.;
	rc&Ti.	=	hiMD&Ti..first();
	if	rc&Ti.	^=	0	then do;
		%*100.	If it is the very first dataset, we will warn the user to verify its correctness.;
		if	&Ti.	=	1	then do;
			put	%sysfunc(quote(%str(W)ARNING: [&L_mcrLABEL.]The most recent dataset [&&TDatName&Ti..] has no observation or cannot be read properly!));
			put	%sysfunc(quote(%str(W)ARNING: [&L_mcrLABEL.]The dataset is located in [&&TpDat&Ti..]!,%str(%')));
		end;

		%*900.	Skip to the next dataset.;
		goto	EndComp&Ti.;
	end;

	%*320.	Skip to the next dataset if current date value is smaller than or equal to the retained maximum one.;
	if	maxDT	>=	&inVar.	then do;
		goto	EndComp&Ti.;
	end;

	%*350.	Assign the values to prepare the output.;
	maxPath	=	symget("TpDat&Ti.");
	maxDS	=	symget("TDatName&Ti.");
	maxDT	=	&inVar.;

	%*390.	Mark the end of current dataset.;
	EndComp&Ti.:
%end;

	%*500.	Output the results.;
	call symputx(%sysfunc(quote(&oDDatPath.,%str(%'))),maxPath,"F");
	call symputx(%sysfunc(quote(&oDDatName.,%str(%'))),maxDS,"F");
	call symputx(%sysfunc(quote(&outDate.,%str(%'))),maxDT,"F");

	%*900.	Stop the DATA step.;
	stop;
run;

%*900.	Purge.;
%*910.	De-assign the temporary libraries.;
%do Ti=1 %to &TnDat.;
	%let	rcLib	=	%sysfunc(libname(__tM&Ti.));
%end;

%EndOfProc:
%mend DBuse_getMaxDataDateInDir;

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
%let	fdr	=	E:\test;
%global
	GPrevDate
	GPDDatName
	GPDDatPath
;

%*100.	Create directory for testing.;
%sysexec	md "&fdr.\bak" & exit;
libname	rpt	"&fdr.";
libname	bak	"&fdr.\bak";

%*200.	Create datasets for testing.;
data rpt.rpt20170531;
	D_DATA	=	mdy(4,30,2017);	output;
	D_DATA	=	mdy(5,31,2017);	output;
run;
data rpt.rpt20170612;
	D_DATA	=	mdy(6,11,2017);	output;
	D_DATA	=	mdy(6,1,2017);	output;
run;
data bak.rpt20170619;
	D_DATA	=	mdy(6,13,2017);	output;
	D_DATA	=	mdy(6,19,2017);	output;
run;

%*500.	Testing.;
%*510.	Consider the period covers all previous datasets.;
%DBuse_getMaxDataDateInDir(
	inDir		=	%nrbquote(&fdr.)
	,inDatPfx	=	rpt
	,inDatExt	=	sas7bdat
	,inVar		=	D_DATA
	,DateBgn	=	%sysfunc(mdy(4,1,2017))
	,DateEnd	=	%sysfunc(mdy(6,24,2017))
	,outDate	=	GPrevDate
	,oDDatName	=	GPDDatName
	,oDDatPath	=	GPDDatPath
)
%put	[GPrevDate]=[&GPrevDate.];
%put	[GPDDatName]=[&GPDDatName.];
%put	[GPDDatPath]=[&GPDDatPath.];

%*520.	Consider the period does not cover the last dataset.;
%DBuse_getMaxDataDateInDir(
	inDir		=	%nrbquote(&fdr.)
	,inDatPfx	=	rpt
	,inDatExt	=	sas7bdat
	,inVar		=	D_DATA
	,DateBgn	=	%sysfunc(mdy(4,1,2017))
	,DateEnd	=	%sysfunc(mdy(6,18,2017))
	,outDate	=	GPrevDate
	,oDDatName	=	GPDDatName
	,oDDatPath	=	GPDDatPath
)
%put	[GPrevDate]=[&GPrevDate.];
%put	[GPDDatName]=[&GPDDatName.];
%put	[GPDDatPath]=[&GPDDatPath.];

%*530.	Do not provide the variable name for date comparison.;
%DBuse_getMaxDataDateInDir(
	inDir		=	%nrbquote(&fdr.)
	,inDatPfx	=	rpt
	,inDatExt	=	sas7bdat
	,inVar		=
	,DateBgn	=	%sysfunc(mdy(4,1,2017))
	,DateEnd	=	%sysfunc(mdy(6,18,2017))
	,outDate	=	GPrevDate
	,oDDatName	=	GPDDatName
	,oDDatPath	=	GPDDatPath
)
%put	[GPrevDate]=[&GPrevDate.];
%put	[GPDDatName]=[&GPDDatName.];
%put	[GPDDatPath]=[&GPDDatPath.];

%*540.	Consider the period does not cover the existing datasets.;
%DBuse_getMaxDataDateInDir(
	inDir		=	%nrbquote(&fdr.)
	,inDatPfx	=	rpt
	,inDatExt	=	sas7bdat
	,inVar		=
	,DateBgn	=	%sysfunc(mdy(7,1,2017))
	,DateEnd	=	%sysfunc(mdy(7,20,2017))
	,outDate	=	GPrevDate
	,oDDatName	=	GPDDatName
	,oDDatPath	=	GPDDatPath
)
%put	[GPrevDate]=[&GPrevDate.];
%put	[GPDDatName]=[&GPDDatName.];
%put	[GPDDatPath]=[&GPDDatPath.];

%*900.	Purge.;
libname	rpt	clear;
libname	bak	clear;

/*-Notes- -End-*/