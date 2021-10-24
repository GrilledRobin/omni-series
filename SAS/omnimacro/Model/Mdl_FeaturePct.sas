%macro Mdl_FeaturePct(
	inValType
	,inFeature
	,inDat		=
	,inDatFC	=	WORK.FC
	,inFC_Feat	=	Feature
	,inFC_Freq	=	Count
	,outDAT		=	WORK.fPct
	,outPct		=	__fPct__
	,procLIB	=	WORK
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to calculate the percentage of the given Feature showing up in the Feature-Category-Frequency data.			|
|	|There are 2 ways to calculate the Feature Percentage (while the output will always be a dataset):									|
|	|[1] Provide the values as character strings.																						|
|	|[2] Provide the dataset that holds the Features.																					|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Calculation Formula:																												|
|	|[FeaturePct] = [inFC_Freq] of [inFeature] in [inDatFC] / sum of [inFC_Freq] in [inDatFC]											|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inValType	:	The type of value that should be inserted into the Feature Category dataset.										|
|	|				[V] : The value is provided as character strings.																	|
|	|				[D] : The values reside in the provided dataset.																	|
|	|inFeature	:	The variable name that denotes the set of values of Feature, or the Feature values as character string.				|
|	|inDat		:	The input dataset.																									|
|	|				If [inValType]=[D], it should be provided.																			|
|	|				IMPORTANT: There should NOT be the same variables as in FC and CC tables, except that [inFeature] can be the same	|
|	|				            as [inFC_Feat] in [inDatFC], and that [inCategory] can be the same as [inCC_Cat] in [inDatCC].			|
|	|inDatFC	:	The Feature-Category dataset to be trained.																			|
|	|inFC_Feat	:	The variable name that denotes the value of Feature in [inDatFC].													|
|	|inFC_Freq	:	The variable name that denotes the frequency count of any Feature that appears in any text message as certain		|
|	|				 category, in [inDatFC].																							|
|	|outDAT		:	The output dataset that contains the Percentage of the given [inFeature].											|
|	|				All variables in [inDAT] will be reserved, with a new variable [outPct] created.									|
|	|outPct		:	The new variable in the output dataset that denotes the Percentage of the given [inFeature].						|
|	|procLIB	:	The working library.																								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20170819		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170828		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Switch back to the hashing of the entire table, instead of one observation at a time, as I found that the processing speed	|
|	|      | is incredibly slow when encountering relatively large dataset with only thousands of observations.							|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180311		| Version |	2.10		| Updater/Creator |	Lu Robin Bin												|
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
|	|	|ErrMcr																															|
|	|	|getCOLbyStrPattern																												|
|	|	|getOBS4DATA																													|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\FileSystem"																						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|FS_VARTYPE																														|
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

%if	%length(%qsysfunc(compress(&inValType.,%str( ))))	=	0	%then	%let	inValType	=	V;
%let	inValType	=	%qsubstr(%qupcase(&inValType.),1,1);
%if	&inValType.	^=	V	and	&inValType.	^=	D	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]Unknown data type [inValType=&inValType.]!;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&inFeature.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No data [inFeature=&inFeature.] is provided for Probability Calculation!;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&inDatFC.,%str( ))))		=	0	%then	%let	inDatFC		=	WORK.FC;
%if	%length(%qsysfunc(compress(&inFC_Feat.,%str( ))))	=	0	%then	%let	inFC_Feat	=	Feature;
%if	%length(%qsysfunc(compress(&inFC_Freq.,%str( ))))	=	0	%then	%let	inFC_Freq	=	&inCC_Freq.;

%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))		=	0	%then	%let	outDAT		=	WORK.fPct;
%if	%length(%qsysfunc(compress(&outPct.,%str( ))))		=	0	%then	%let	outPct		=	__fPct__;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))		=	0	%then	%let	procLIB		=	WORK;

%if	%sysfunc(nvalid(&outPct.))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.][outPct=&outPct.] is NOT a valid Variable Name!;
	%ErrMcr
%end;

%let	inFeature	=	%qlowcase(%qsysfunc(strip(%qsysfunc(dequote(&inFeature.)))));

%if	&inValType.	=	D	%then %do;
	%*Verify whether the provided parameters are valid SAS variable names.;
	%if	%sysfunc(nvalid(&inFeature.))	=	0	%then %do;
		%put	%str(W)ARNING: [&L_mcrLABEL.][inFeature=&inFeature.] is NOT a valid Variable Name when [inValType=&inValType.]!;
		%ErrMcr
	%end;
%end;

%*013.	Define the local environment.;
%local
	OpNote
	TypFeature
	LnTotalFC
	Vi
;
%let	OpNote	=	%sysfunc(getoption(notes));

%*014.	Define the global environment.;
%global
	GnFPctVar
;
%let	GnFPctVar	=	0;

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in traditional SAS syntax colors.;
%macro dummy; %mend dummy;

%*070.	Retrieve necessary information from [inDAT].;
%if	&inValType.	=	D	%then %do;
	%*200.	Retrieve all the variables from [inDAT], except the required variables, for keeping them at the output step.;
	%getCOLbyStrPattern(
		inDAT		=	&inDAT.
		,inRegExp	=
		,exclRegExp	=	%nrbquote(\b(&inFeature.)\b)
		,chkVarTP	=	ALL
		,outCNT		=	GnFPctVar
		,outELpfx	=	GeFPctVar
	)
%end;

%*090.	Check the types of the Feature and Category variables in the output dataset.;
%let	TypFeature	=	%FS_VARTYPE( inDAT = &inDatFC. , inFLD = &inFC_Feat. );

%*100.	Prepare the input dataset.;
data &procLIB..__mdl_fPct_pre;
	%*100.	We use the variables in the database to format the input data.;
	%*We pseudo-set the output dataset to form the table structure.;
	if	0	then	set	%unquote(&inDatFC.);

%if	&inValType.	=	V	%then %do;
	%*200.	Input the values.;
	&inFC_Feat.	=	%sysfunc(ifc(&TypFeature.=C,symget("inFeature"),symgetn("inFeature")));

	%*300.	Reset the macro variables for further process.;
	%*IMPORTANT: We can only call [SYMPUTX] rountine here, for the function [symget<n>] is run at execution phase;
	%*            instead of compilation phase, which means if we use [LET] statement, the values of these macro;
	%*            variables will be overwritten BEFORE above statements are executed.;
	call symputx("inFeature","&inFC_Feat.","F");

	%*400.	Output and stop the DATA step.;
	output;
	stop;
%end;
%else %do;
	%*600.	If the update mode is [D], we re-format the variables in the input dataset where necessary.;
	%*610.	Set the input data.;
	set %unquote(&inDat.);

	%*620.	Re-format the required variables.;
	&inFeature.		=	%sysfunc(ifc(&TypFeature.=C,lowcase(strip(&inFeature.)),&inFeature.));
	&inFC_Feat.		=	%sysfunc(ifc(&TypFeature.=C,lowcase(strip(&inFeature.)),&inFeature.));
%end;

	%*900.	Purge.;
run;

%*190.	Quit the process if there is no observation to calculate the probability.;
%if	%getOBS4DATA( inDAT = &procLIB..__mdl_fPct_pre , gMode = F )	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No observation is found in the input data [&inDat.]. Skip the process.;
	%goto	EndOfProc;
%end;

%*200.	Sum the total frequency counts by each [inFeature] in [inDatFC].;
proc means
	data=%unquote(&inDatFC.)
	noprint
	nway
;
	class
		&inFC_Feat.
	;
	var
		&inFC_Freq.
	;
	output
		out=&procLIB..__mdl_fPct_all
		sum=&inFC_Freq.
	;
run;

%*700.	Retrieve the sum of all Frequency Counts in [inDatFC].;
proc sql noprint;
	select sum(&inFC_Freq.) into :LnTotalFC from %unquote(&inDatFC.);
quit;
%let	LnTotalFC	=	%sysfunc(sum(0,&LnTotalFC.));

%*800.	Calculate the Feature Percentage.;
%*801.	Switch off the [NOTES] option to avoid large I/O in the LOG for HASH Object.;
options	nonotes;

%*810.	Processing.;
data %unquote(&outDAT.);
	%*100.	Set the data.;
	set &procLIB..__mdl_fPct_pre end=EOF;

	%*200.	Create new variables.;
	%*210.	Create the variable that denotes the Percentage.;
	format	&outPct.	percent12.2;
	call missing(&outPct.);

	%*220.	Create temporary variables to store the frequency counts.;
	array
		arrTFreq{1}
		8
		_temporary_
	;
	call missing(arrTFreq{1});

	%*250.	Prepare the temporary variables that denote the full dataset names.;

	%*300.	Prepare the Hash Objects.;
	if	_N_	=	1	then do;
		%*100.	Prepare to load the Feature-Category-Frequency database.;
		if	0	then	set	&procLIB..__mdl_fPct_all;
		dcl	hash	hFC(dataset:"&procLIB..__mdl_fPct_all",hashexp:16);
		hFC.DefineKey("&inFC_Feat.");
		hFC.DefineData("&inFC_Freq.");
		hFC.DefineDone();
	end;
	call missing(&inFC_Freq.);

	%*400.	Read the database to retrieve the frequency counts.;
	%*410.	Read the Feature Frequency.;
	_iorc_		=	hFC.find(key:&inFeature.);
	arrTFreq{1}	=	sum(0,&inFC_Freq.);

	%*500.	Calculate the Feature Percentage.;
	%*We cannot use the function [IFN] here, for it will be parsed anyway at execution stage.;
	if	&LnTotalFC.	=	0	then do;
		&outPct.	=	0;
	end;
	else do;
		&outPct.	=	arrTFreq{1} / &LnTotalFC.;
	end;

	%*900.	Purge.;
	keep
		&inFeature.
		%if &GnFPctVar. ^= 0 %then %do;
			%do Vi=1 %to &GnFPctVar.;
				&&GeFPctVar&Vi..
			%end;
		%end;
		&outPct.
	;
run;

%*819.	Restore the [NOTES] option.;
options	&OpNote.;

%EndOfProc:
%mend Mdl_FeaturePct;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvOp"
		"D:\SAS\omnimacro\FileSystem"
		"D:\SAS\omnimacro\Model"
	)
	mautosource
;


%*100.	With default variable names.;
%*110.	Create the FC Table.;
%*If we do not provide the parenthases, it will NOT execute.;
%Mdl_crDat_FC()

%*120.	Create the CC Table.;
%*If we do not provide the parenthases, it will NOT execute.;
%Mdl_crDat_CC()

%*130.	Provide training values.;
%WSplit_Train_CC_FC_EN(V,"nobody owns the warter",Good)
%WSplit_Train_CC_FC_EN(V,%str(the quick rabbit jumps fences),good)
%WSplit_Train_CC_FC_EN(V,"buy car now",GOOD)
%WSplit_Train_CC_FC_EN(V,"make quick money at the online casino",baD)
%WSplit_Train_CC_FC_EN(V,"the quick brown fox jumps","good")

%*140.	Train by dataset.;
data upd;
	length
		C_SENTENCE	$1024
		Category	$64
	;
	C_SENTENCE	=	"I had a dismal prospect of my condition";
	Category	=	"Bad";
	output;

	C_SENTENCE	=	"Studies serve for delight, for ornament, and for ability";
	Category	=	"gooD";
	output;

	C_SENTENCE	=	"They lived in a pleasant house, with a garden, and they had discreet servants, and felt themselves superior to anyone in the neighborhood.";
	Category	=	"bad";
	output;
run;
%WSplit_Train_CC_FC_EN(D,C_SENTENCE,inDAT=upd)

%*150.	Calculate the Feature Probability based on values.;
%Mdl_FeaturePct(V,"quick")

%*150.	Calculate the Feature Probability based on dataset.;
data testfPct;
	length
		Feature		$64
		Category	$64
		Weight		8
		InitProb	8
	;
	Feature	=	"QUick";	Category	=	"bAD";	Weight	=	1;	InitProb	=	0.5;	output;
	Feature	=	"The";		Category	=	"good";	Weight	=	2;	InitProb	=	0.5;	output;
run;
%Mdl_FeaturePct(D,Feature,inDAT=testfPct)

/*-Notes- -End-*/