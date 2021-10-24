%macro Mdl_FeatureProb(
	inValType
	,inFeature
	,inCategory
	,inDat		=
	,inDatFC	=	WORK.FC
	,inFC_Feat	=	Feature
	,inFC_Cat	=	Category
	,inFC_Freq	=	Count
	,inDatCC	=	WORK.CC
	,inCC_Cat	=	Category
	,inCC_Freq	=	Count
	,outDAT		=	WORK.fProb
	,outProb	=	__fProb__
	,procLIB	=	WORK
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to calculate the probability of the given Feature showing up in the Feature-Category-Frequency data in		|
|	| terms of the given Category showing up in the Category-Frequency data.															|
|	|There are 2 ways to calculate the Feature Probability (while the output will always be a dataset):									|
|	|[1] Provide the values as character strings.																						|
|	|[2] Provide the dataset that holds the Features and their respective Categories.													|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Calculation Formula:																												|
|	|					[inFC_Freq] of ( [inFeature] and [inCategory] ) in [inDatFC]		[inCC_Freq] of [inCategory] in [inDatCC]	|
|	|[FeatureProb]	=	------------------------------------------------------------	*	----------------------------------------	|
|	|							[inFC_Freq] of [inCategory] in [inDatFC]					[inFC_Freq] of [inCategory] in [inDatFC]	|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inValType	:	The type of value that should be inserted into the Feature Category dataset.										|
|	|				[V] : The value is provided as character strings.																	|
|	|				[D] : The values reside in the provided dataset.																	|
|	|inFeature	:	The variable name that denotes the set of values of Feature, or the Feature values as character string.				|
|	|inCategory	:	The variable name that denotes the category that any Feature would fall into, either Good or Bad, or the			|
|	|				 Category value.																									|
|	|inDat		:	The input dataset.																									|
|	|				If [inValType]=[D], it should be provided.																			|
|	|				IMPORTANT: There should NOT be the same variables as in FC and CC tables, except that [inFeature] can be the same	|
|	|				            as [inFC_Feat] in [inDatFC], and that [inCategory] can be the same as [inCC_Cat] in [inDatCC].			|
|	|inDatFC	:	The Feature-Category dataset to be trained.																			|
|	|inFC_Feat	:	The variable name that denotes the value of Feature in [inDatFC].													|
|	|inFC_Cat	:	The variable name that denotes the Category that any Feature would fall into, in [inDatFC].							|
|	|inFC_Freq	:	The variable name that denotes the frequency count of any Feature that appears in any text message as certain		|
|	|				 category, in [inDatFC].																							|
|	|inDatCC	:	The Category Count dataset to be trained.																			|
|	|inCC_Cat	:	The variable name that denotes the Category that any Feature sentence is tagged, in [inDatCC].						|
|	|inCC_Freq	:	The variable name that denotes the frequency count of any Category that tags the paragraph, in [inDatCC]			|
|	|outDAT		:	The output dataset that contains the Probability of the given [inFeature] under [inCategory].						|
|	|				All variables in [inDAT] will be reserved, with a new variable [outProb] created.									|
|	|outProb	:	The new variable in the output dataset that denotes the Probability of the given [inFeature] under [inCategory].	|
|	|procLIB	:	The working library.																								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20170813		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
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

%if	%length(%qsysfunc(compress(&inDatCC.,%str( ))))		=	0	%then	%let	inDatCC		=	WORK.CC;
%if	%length(%qsysfunc(compress(&inCC_Cat.,%str( ))))	=	0	%then	%let	inCC_Cat	=	Category;
%if	%length(%qsysfunc(compress(&inCC_Freq.,%str( ))))	=	0	%then	%let	inCC_Freq	=	Count;

%if	%length(%qsysfunc(compress(&inDatFC.,%str( ))))		=	0	%then	%let	inDatFC		=	WORK.FC;
%if	%length(%qsysfunc(compress(&inFC_Feat.,%str( ))))	=	0	%then	%let	inFC_Feat	=	Feature;
%if	%length(%qsysfunc(compress(&inFC_Cat.,%str( ))))	=	0	%then	%let	inFC_Cat	=	&inCC_Cat.;
%if	%length(%qsysfunc(compress(&inFC_Freq.,%str( ))))	=	0	%then	%let	inFC_Freq	=	&inCC_Freq.;

%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))		=	0	%then	%let	outDAT		=	WORK.fProb;
%if	%length(%qsysfunc(compress(&outProb.,%str( ))))		=	0	%then	%let	outProb		=	__fProb__;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))		=	0	%then	%let	procLIB		=	WORK;

%if	%sysfunc(nvalid(&outProb.))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.][outProb=&outProb.] is NOT a valid Variable Name!;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&inCategory.,%str( ))))	=	0	%then	%let	inCategory	=	&inCC_Cat.;
%let	inFeature	=	%qlowcase(%qsysfunc(strip(%qsysfunc(dequote(&inFeature.)))));
%let	inCategory	=	%qlowcase(%qsysfunc(strip(%qsysfunc(dequote(&inCategory.)))));

%if	&inValType.	=	D	%then %do;
	%*Verify whether the provided parameters are valid SAS variable names.;
	%if	%sysfunc(nvalid(&inFeature.))	=	0	%then %do;
		%put	%str(W)ARNING: [&L_mcrLABEL.][inFeature=&inFeature.] is NOT a valid Variable Name when [inValType=&inValType.]!;
		%ErrMcr
	%end;
	%if	%sysfunc(nvalid(&inCategory.))	=	0	%then %do;
		%put	%str(W)ARNING: [&L_mcrLABEL.][inCategory=&inCategory.] is NOT a valid Variable Name when [inValType=&inValType.]!;
		%ErrMcr
	%end;
%end;

%*013.	Define the local environment.;
%local
	OpNote
	TypFeature
	TypCategory
	Vi
;
%let	OpNote	=	%sysfunc(getoption(notes));

%*014.	Define the global environment.;
%global
	GnFeaPVar
;
%let	GnFeaPVar	=	0;

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in traditional SAS syntax colors.;
%macro dummy; %mend dummy;

%*070.	Retrieve necessary information from [inDAT].;
%if	&inValType.	=	D	%then %do;
	%*200.	Retrieve all the variables from [inDAT], except the 2 required variables, for keeping them at the output step.;
	%getCOLbyStrPattern(
		inDAT		=	&inDAT.
		,inRegExp	=
		,exclRegExp	=	%nrbquote(\b(&inFeature.|&inCategory.)\b)
		,chkVarTP	=	ALL
		,outCNT		=	GnFeaPVar
		,outELpfx	=	GeFeaPVar
	)
%end;

%*090.	Check the types of the Feature and Category variables in the output dataset.;
%let	TypFeature	=	%FS_VARTYPE( inDAT = &inDatFC. , inFLD = &inFC_Feat. );
%let	TypCategory	=	%FS_VARTYPE( inDAT = &inDatCC. , inFLD = &inCC_Cat. );

%*100.	Prepare the input dataset.;
data &procLIB..__mdl_fProb_pre;
	%*100.	We use the variables in the database to format the input data.;
	%*We pseudo-set the output dataset to form the table structure.;
	if	0	then	set	%unquote(&inDatCC.);
	if	0	then	set	%unquote(&inDatFC.);

%if	&inValType.	=	V	%then %do;
	%*200.	Input the values.;
	&inFC_Feat.	=	%sysfunc(ifc(&TypFeature.=C,symget("inFeature"),symgetn("inFeature")));
	&inCC_Cat.	=	%sysfunc(ifc(&TypCategory.=C,symget("inCategory"),symgetn("inCategory")));

	%*300.	Reset the macro variables for further process.;
	%*IMPORTANT: We can only call [SYMPUTX] rountine here, for the function [symget<n>] is run at execution phase;
	%*            instead of compilation phase, which means if we use [LET] statement, the values of these macro;
	%*            variables will be overwritten BEFORE above statements are executed.;
	call symputx("inFeature","&inFC_Feat.","F");
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
	&inFeature.		=	%sysfunc(ifc(&TypFeature.=C,lowcase(strip(&inFeature.)),&inFeature.));
	&inCategory.	=	%sysfunc(ifc(&TypCategory.=C,lowcase(strip(&inCategory.)),&inCategory.));
	&inFC_Feat.		=	%sysfunc(ifc(&TypFeature.=C,lowcase(strip(&inFeature.)),&inFeature.));
	&inCC_Cat.		=	%sysfunc(ifc(&TypCategory.=C,lowcase(strip(&inCategory.)),&inCategory.));
%end;

	%*900.	Purge.;
run;

%*190.	Quit the process if there is no observation to calculate the probability.;
%if	%getOBS4DATA( inDAT = &procLIB..__mdl_fProb_pre , gMode = F )	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No observation is found in the input data [&inDat.]. Skip the process.;
	%goto	EndOfProc;
%end;

%*600.	Calculate the Category Stats.;
%*610.	Identify the unique Categories in the input data.;
proc sort
	data=&procLIB..__mdl_fProb_pre(keep=&inCC_Cat.)
	out=&procLIB..__mdl_fProb_UniCat
	nodupkey
;
	by	&inCC_Cat.;
run;

%*620.	Retrieve the sum of Frequency Counts of the [inCC_Cat] in [inDatCC].;
proc sql;
	create table &procLIB..__mdl_fProb_CatCC as (
		select
			a.&inCC_Cat.
			,sum(c.&inCC_Freq.) as __FreqCC__
		from &procLIB..__mdl_fProb_UniCat as a
		left join %unquote(&inDatCC.) as c
			on	a.&inCC_Cat.	=	c.&inCC_Cat.
		group by
			a.&inCC_Cat.
	);
quit;

%*630.	Retrieve the sum of Frequency Counts of the [inCC_Cat] in [inDatFC].;
proc sql;
	create table &procLIB..__mdl_fProb_CatFC as (
		select
			a.&inCC_Cat.
			,sum(f.&inCC_Freq.) as __FreqFC__
		from &procLIB..__mdl_fProb_UniCat as a
		left join %unquote(&inDatFC.) as f
			on	a.&inCC_Cat.	=	f.&inCC_Cat.
		group by
			a.&inCC_Cat.
	);
quit;

%*800.	Calculate the Feature Probability.;
%*801.	Switch off the [NOTES] option to avoid large I/O in the LOG for HASH Object.;
options	nonotes;

%*810.	Processing.;
data %unquote(&outDAT.);
	%*100.	Set the data.;
	set &procLIB..__mdl_fProb_pre end=EOF;

	%*200.	Create new variables.;
	%*210.	Create the variable that denotes the Probability.;
	format	&outProb.	percent12.2;
	call missing(&outProb.);

	%*220.	Create temporary variables to store the frequency counts.;
	array
		arrTFreq{3}
		8
		_temporary_
	;

	%*250.	Prepare the temporary variables that denote the full dataset names.;

	%*300.	Prepare the Hash Objects.;
	if	_N_	=	1	then do;
		%*100.	Prepare to load the Feature-Category-Frequency database.;
		if	0	then	set	%unquote(&inDatFC.);
		dcl	hash	hFC(dataset:"%unquote(&inDatFC.)",hashexp:16);
		hFC.DefineKey("&inFC_Cat.","&inFC_Feat.");
		hFC.DefineData("&inFC_Freq.");
		hFC.DefineDone();

		%*200.	Prepare to load the Category Frequency Counts in [inDatCC].;
		if	0	then	set	&procLIB..__mdl_fProb_CatCC;
		dcl	hash	hCC_CC(dataset:"&procLIB..__mdl_fProb_CatCC",hashexp:16);
		hCC_CC.DefineKey("&inCC_Cat.");
		hCC_CC.DefineData("__FreqCC__");
		hCC_CC.DefineDone();

		%*300.	Prepare to load the Category Frequency Counts in [inDatFC].;
		if	0	then	set	&procLIB..__mdl_fProb_CatFC;
		dcl	hash	hCC_FC(dataset:"&procLIB..__mdl_fProb_CatFC",hashexp:16);
		hCC_FC.DefineKey("&inCC_Cat.");
		hCC_FC.DefineData("__FreqFC__");
		hCC_FC.DefineDone();
	end;
	call missing(&inFC_Freq.);
	call missing(__FreqCC__);
	call missing(__FreqFC__);

	%*400.	Read the database to retrieve the frequency counts.;
	%*410.	Read the Feature Frequency.;
	_iorc_	=	hFC.find(key:&inCC_Cat.,key:&inFC_Feat.);
	arrTFreq{1}	=	sum(0,&inFC_Freq.);

	%*420.	Read the Category Frequency in [inDatCC].;
	_iorc_	=	hCC_CC.find(key:&inCC_Cat.);
	arrTFreq{2}	=	sum(0,__FreqCC__);

	%*430.	Read the Category Frequency in [inDatFC].;
	_iorc_	=	hCC_FC.find(key:&inCC_Cat.);
	arrTFreq{3}	=	sum(0,__FreqFC__);

	%*500.	Calculate the Feature Probability.;
	%*We cannot use the function [IFN] here, for it will be parsed anyway at execution stage.;
	if	arrTFreq{3}	=	0	then do;
		&outProb.	=	0;
	end;
	else do;
		&outProb.	=	( arrTFreq{1} * arrTFreq{2} ) / arrTFreq{3} ** 2;
	end;

	%*900.	Purge.;
	keep
		&inFeature.
		&inCategory.
		%if &GnFeaPVar. ^= 0 %then %do;
			%do Vi=1 %to &GnFeaPVar.;
				&&GeFeaPVar&Vi..
			%end;
		%end;
		&outProb.
	;
run;

%*819.	Restore the [NOTES] option.;
options	&OpNote.;

%EndOfProc:
%mend Mdl_FeatureProb;

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
%Mdl_FeatureProb(V,"quick",Good)

%*150.	Calculate the Feature Probability based on dataset.;
data testprob;
	length
		Feature		$64
		Category	$64
		Weight		8
		InitProb	8
	;
	Feature	=	"QUick";	Category	=	"bAD";	Weight	=	1;	InitProb	=	0.5;	output;
	Feature	=	"The";		Category	=	"good";	Weight	=	2;	InitProb	=	0.5;	output;
run;
%Mdl_FeatureProb(D,Feature,Category,inDAT=testprob)

/*-Notes- -End-*/