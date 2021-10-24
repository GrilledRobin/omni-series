%macro Mdl_CategoryPct(
	inValType
	,inCategory
	,inDat		=
	,inDatCC	=	WORK.CC
	,inCC_Cat	=	Category
	,inCC_Freq	=	Count
	,outDAT		=	WORK.cPct
	,outPct		=	__cPct__
	,procLIB	=	WORK
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to calculate the Percentage of the given Category showing up in the Category-Frequency data.				|
|	|There are 2 ways to calculate the Category Probability (while the output will always be a dataset):								|
|	|[1] Provide the values as character strings.																						|
|	|[2] Provide the dataset that holds the Categories.																					|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Calculation Formula:																												|
|	|[CategoryPct] = [inCC_Freq] of [inCategory] in [inDatCC] / sum of [inCC_Freq] in [inDatCC]											|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inValType	:	The type of value that should be inserted into the Feature Category dataset.										|
|	|				[V] : The value is provided as character strings.																	|
|	|				[D] : The values reside in the provided dataset.																	|
|	|inCategory	:	The variable name that denotes the category that any Feature would fall into, either Good or Bad, or the			|
|	|				 Category value.																									|
|	|inDat		:	The input dataset.																									|
|	|				If [inValType]=[D], it should be provided.																			|
|	|				IMPORTANT: There should NOT be the same variables as in FC and CC tables, except that [inFeature] can be the same	|
|	|				            as [inFC_Feat] in [inDatFC], and that [inCategory] can be the same as [inCC_Cat] in [inDatCC].			|
|	|inDatCC	:	The Category Count dataset to be trained.																			|
|	|inCC_Cat	:	The variable name that denotes the Category that any Feature sentence is tagged, in [inDatCC].						|
|	|inCC_Freq	:	The variable name that denotes the frequency count of any Category that tags the paragraph, in [inDatCC]			|
|	|outDAT		:	The output dataset that contains the Probability of the given [inCategory].											|
|	|				All variables in [inDAT] will be reserved, with a new variable [outPct] created.									|
|	|outPct		:	The new variable in the output dataset that denotes the Percentage of the given [inCategory].						|
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

%if	%length(%qsysfunc(compress(&inDatCC.,%str( ))))		=	0	%then	%let	inDatCC		=	WORK.CC;
%if	%length(%qsysfunc(compress(&inCC_Cat.,%str( ))))	=	0	%then	%let	inCC_Cat	=	Category;
%if	%length(%qsysfunc(compress(&inCC_Freq.,%str( ))))	=	0	%then	%let	inCC_Freq	=	Count;

%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))		=	0	%then	%let	outDAT		=	WORK.cPct;
%if	%length(%qsysfunc(compress(&outPct.,%str( ))))		=	0	%then	%let	outPct		=	__cPct__;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))		=	0	%then	%let	procLIB		=	WORK;

%if	%sysfunc(nvalid(&outPct.))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.][outPct=&outPct.] is NOT a valid Variable Name!;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&inCategory.,%str( ))))	=	0	%then	%let	inCategory	=	&inCC_Cat.;
%let	inCategory	=	%qlowcase(%qsysfunc(strip(%qsysfunc(dequote(&inCategory.)))));

%if	&inValType.	=	D	%then %do;
	%*Verify whether the provided parameters are valid SAS variable names.;
	%if	%sysfunc(nvalid(&inCategory.))	=	0	%then %do;
		%put	%str(W)ARNING: [&L_mcrLABEL.][inCategory=&inCategory.] is NOT a valid Variable Name when [inValType=&inValType.]!;
		%ErrMcr
	%end;
%end;

%*013.	Define the local environment.;
%local
	OpNote
	TypCategory
	LnTotalCC
	Vi
;
%let	OpNote	=	%sysfunc(getoption(notes));

%*014.	Define the global environment.;
%global
	GnCPctVar
;
%let	GnCPctVar	=	0;

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in traditional SAS syntax colors.;
%macro dummy; %mend dummy;

%*070.	Retrieve necessary information from [inDAT].;
%if	&inValType.	=	D	%then %do;
	%*200.	Retrieve all the variables from [inDAT], except the required variables, for keeping them at the output step.;
	%getCOLbyStrPattern(
		inDAT		=	&inDAT.
		,inRegExp	=
		,exclRegExp	=	%nrbquote(\b(&inCategory.)\b)
		,chkVarTP	=	ALL
		,outCNT		=	GnCPctVar
		,outELpfx	=	GeCPctVar
	)
%end;

%*090.	Check the types of the Feature and Category variables in the output dataset.;
%let	TypCategory	=	%FS_VARTYPE( inDAT = &inDatCC. , inFLD = &inCC_Cat. );

%*100.	Prepare the input dataset.;
data &procLIB..__mdl_cPct_pre;
	%*100.	We use the variables in the database to format the input data.;
	%*We pseudo-set the output dataset to form the table structure.;
	if	0	then	set	%unquote(&inDatCC.);

%if	&inValType.	=	V	%then %do;
	%*200.	Input the values.;
	&inCC_Cat.	=	%sysfunc(ifc(&TypCategory.=C,symget("inCategory"),symgetn("inCategory")));

	%*300.	Reset the macro variables for further process.;
	%*IMPORTANT: We can only call [SYMPUTX] rountine here, for the function [symget<n>] is run at execution phase;
	%*            instead of compilation phase, which means if we use [LET] statement, the values of these macro;
	%*            variables will be overwritten BEFORE above statements are executed.;
	call symputx("inCategory","&inCC_Cat.","F");

	%*400.	Output and stop the DATA step.;
	output;
	stop;
%end;
%else %do;
	%*600.	If the update mode is [D], we re-format the variables in the input dataset where necessary.;
	%*610.	Set the input data.;
	set %unquote(&inDat.);

	%*620.	Re-format the required variables.;
	&inCategory.	=	%sysfunc(ifc(&TypCategory.=C,lowcase(strip(&inCategory.)),&inCategory.));
	&inCC_Cat.		=	%sysfunc(ifc(&TypCategory.=C,lowcase(strip(&inCategory.)),&inCategory.));
%end;

	%*900.	Purge.;
run;

%*190.	Quit the process if there is no observation to calculate the probability.;
%if	%getOBS4DATA( inDAT = &procLIB..__mdl_cPct_pre , gMode = F )	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No observation is found in the input data [&inDat.]. Skip the process.;
	%goto	EndOfProc;
%end;

%*200.	Sum the total frequency counts by each [inCategory] in [inDatCC].;
proc means
	data=%unquote(&inDatCC.)
	noprint
	nway
;
	class
		&inCC_Cat.
	;
	var
		&inCC_Freq.
	;
	output
		out=&procLIB..__mdl_cPct_all
		sum=&inCC_Freq.
	;
run;

%*700.	Retrieve the sum of all Frequency Counts in [inDatCC].;
proc sql noprint;
	select sum(&inCC_Freq.) into :LnTotalCC from %unquote(&inDatCC.);
quit;
%let	LnTotalCC	=	%sysfunc(sum(0,&LnTotalCC.));

%*800.	Calculate the Feature Probability.;
%*801.	Switch off the [NOTES] option to avoid large I/O in the LOG for HASH Object.;
options	nonotes;

%*810.	Processing.;
data %unquote(&outDAT.);
	%*100.	Set the data.;
	set &procLIB..__mdl_cPct_pre end=EOF;

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
		%*200.	Prepare to load the Category-Frequency database.;
		if	0	then	set	&procLIB..__mdl_cPct_all;
		dcl	hash	hCC(dataset:"&procLIB..__mdl_cPct_all",hashexp:16);
		hCC.DefineKey("&inCC_Cat.");
		hCC.DefineData("&inCC_Freq.");
		hCC.DefineDone();
	end;
	call missing(&inCC_Freq.);

	%*400.	Read the database to retrieve the frequency counts.;
	%*420.	Read the Category Frequency.;
	_iorc_		=	hCC.find(key:&inCategory.);
	arrTFreq{1}	=	sum(0,&inCC_Freq.);

	%*500.	Calculate the Feature Probability.;
	%*We cannot use the function [IFN] here, for it will be parsed anyway at execution stage.;
	if	&LnTotalCC.	=	0	then do;
		&outPct.	=	0;
	end;
	else do;
		&outPct.	=	arrTFreq{1} / &LnTotalCC.;
	end;

	%*900.	Purge.;
	keep
		&inCategory.
		%if &GnCPctVar. ^= 0 %then %do;
			%do Vi=1 %to &GnCPctVar.;
				&&GeCPctVar&Vi..
			%end;
		%end;
		&outPct.
	;
run;

%*819.	Restore the [NOTES] option.;
options	&OpNote.;

%EndOfProc:
%mend Mdl_CategoryPct;

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
%Mdl_CategoryPct(V,Good)

%*150.	Calculate the Feature Probability based on dataset.;
data testCPct;
	length
		Feature		$64
		Category	$64
		Weight		8
		InitProb	8
	;
	Feature	=	"QUick";	Category	=	"bAD";	Weight	=	1;	InitProb	=	0.5;	output;
	Feature	=	"The";		Category	=	"good";	Weight	=	2;	InitProb	=	0.5;	output;
run;
%Mdl_CategoryPct(D,Category,inDAT=testCPct)

/*-Notes- -End-*/