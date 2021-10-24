%macro BayesTxtSeg_DocProb(
	inValType
	,inFeatSet
	,inCategory
	,inDat		=
	,inDatFC	=	WORK.FC
	,inFC_Feat	=	Feature
	,inFC_Cat	=	Category
	,inFC_Freq	=	Count
	,inDatCC	=	WORK.CC
	,inCC_Cat	=	Category
	,inCC_Freq	=	Count
	,outDAT		=	WORK.DocProb
	,outProb	=	__DocProb__
	,procLIB	=	WORK
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to calculate the probability of the given phrase of Features (under given Category) to show up in terms of	|
|	| the entire training database (comprised of Feature-Category-Frequency table and Category-Frequency table).						|
|	|There are 2 ways to calculate the Document Probability (while the output will always be a dataset):								|
|	|[1] Provide the phrase of Features (e.g. "Bless you") and its corresponding Category (e.g. "Good") as character strings.			|
|	|[2] Provide the dataset that holds the Features and their respective Categories..													|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Calculation Formula:																												|
|	|[DocProb] in the entire Training Database =																						|
|	| [TxtProb] for the given phrase (comprised of many Features) under given [inCategory] *											|
|	| [CategoryPct] of [inCategory] showing up in Category-Frequency table / 															|
|	| [TxtPct] of [inFeatSet] in Feature-Category-Frequency table 																		|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Bayes Theorem: Pr( Category | Text ) = Pr( Text | Category ) * Pr( Category ) / Pr( Text )											|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Pr( Category | Text ) = [DocProb]																									|
|	|Pr( Text | Category ) = [TxtProb]																									|
|	|Pr( Category ) = [CategoryPct]																										|
|	|Pr( Text ) = [TxtPct]																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inValType	:	The type of value that should be inserted into the Feature Category dataset.										|
|	|				[V] : The value is provided as character strings.																	|
|	|				[D] : The values reside in the provided dataset.																	|
|	|inFeatSet	:	The variable name that denotes the set of values of Feature, or the Feature values as character string.				|
|	|				The common usage is to analyze the words in a sentence.																|
|	|inCategory	:	The variable name that denotes the category that any Feature would fall into, either Good or Bad, or the			|
|	|				 Category value.																									|
|	|inDat		:	The input dataset.																									|
|	|				If [inValType]=[D], it should be provided.																			|
|	|				IMPORTANT: There should NOT be the same variables as in FC and CC tables, except that [inFeatSet] can be the same	|
|	|				            as [inFC_Feat] in [inDatFC], and that [inCategory] can be the same as [inCC_Cat] in [inDatCC].			|
|	|inDatFC	:	The Feature-Category dataset to be trained.																			|
|	|inFC_Feat	:	The variable name that denotes the value of Feature in [inDatFC].													|
|	|inFC_Cat	:	The variable name that denotes the Category that any Feature would fall into, in [inDatFC].							|
|	|inFC_Freq	:	The variable name that denotes the frequency count of any Feature that appears in any text message as certain		|
|	|				 category, in [inDatFC].																							|
|	|inDatCC	:	The Category Count dataset to be trained.																			|
|	|inCC_Cat	:	The variable name that denotes the Category that any Feature sentence is tagged, in [inDatCC].						|
|	|inCC_Freq	:	The variable name that denotes the frequency count of any Category that tags the paragraph, in [inDatCC]			|
|	|outDAT		:	The output dataset that contains the Probability of the given [inFeatSet] under [inCategory].						|
|	|				All variables in [inDAT] will be reserved, with a new variable [outProb] created.									|
|	|outProb	:	The new variable in the output dataset that denotes the Probability of the given [inFeatSet] under [inCategory].	|
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
|	|	|FS_VARLEN																														|
|	|	|FS_VARTYPE																														|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\Model"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|Mdl_TxtProb																													|
|	|	|Mdl_CategoryPct																												|
|	|	|Mdl_TxtPct																														|
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

%if	%length(%qsysfunc(compress(&inFeatSet.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No data [inFeatSet=&inFeatSet.] is provided for Probability Calculation!;
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

%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))		=	0	%then	%let	outDAT		=	WORK.DocProb;
%if	%length(%qsysfunc(compress(&outProb.,%str( ))))		=	0	%then	%let	outProb		=	__DocProb__;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))		=	0	%then	%let	procLIB		=	WORK;

%if	%sysfunc(nvalid(&outProb.))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.][outProb=&outProb.] is NOT a valid Variable Name!;
	%ErrMcr
%end;
%if	%qupcase(&outProb.)	=	__TXTPROB__	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]Using preset field name [outProb=&outProb.] will cause unpredictable result!;
%end;

%if	%length(%qsysfunc(compress(&inCategory.,%str( ))))	=	0	%then	%let	inCategory	=	&inCC_Cat.;
%let	inFeatSet	=	%qlowcase(%qsysfunc(strip(%qsysfunc(dequote(&inFeatSet.)))));
%let	inCategory	=	%qlowcase(%qsysfunc(strip(%qsysfunc(dequote(&inCategory.)))));

%if	&inValType.	=	D	%then %do;
	%*Verify whether the provided parameters are valid SAS variable names.;
	%if	%sysfunc(nvalid(&inFeatSet.))	=	0	%then %do;
		%put	%str(W)ARNING: [&L_mcrLABEL.][inFeatSet=&inFeatSet.] is NOT a valid Variable Name when [inValType=&inValType.]!;
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
	lenFeatSet
	TypFeature
	TypCategory
	LnTotalFC
	Vi
;
%let	OpNote		=	%sysfunc(getoption(notes));
%let	lenFeatSet	=	0;
%let	LnTotalFC	=	0;

%*014.	Define the global environment.;
%global
	GnDocPVar
;
%let	GnDocPVar	=	0;

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in traditional SAS syntax colors.;
%macro dummy; %mend dummy;

%*070.	Retrieve necessary information from [inDAT].;
%if	&inValType.	=	D	%then %do;
	%*100.	Retrieve the length of [inFeatSet] in the input dataset.;
	%let	lenFeatSet	=	%FS_VARLEN( inDAT = &inDat. , inFLD = &inFeatSet. );

	%*200.	Retrieve all the variables from [inDAT], except the 4 required variables, for keeping them at the output step.;
	%getCOLbyStrPattern(
		inDAT		=	&inDAT.
		,inRegExp	=
		,exclRegExp	=	%nrbquote(\b(&inFeatSet.|&inCategory.)\b)
		,chkVarTP	=	ALL
		,outCNT		=	GnDocPVar
		,outELpfx	=	GeDocPVar
	)
%end;

%*090.	Check the types of the Feature and Category variables in the output dataset.;
%let	TypFeature	=	%FS_VARTYPE( inDAT = &inDatFC. , inFLD = &inFC_Feat. );
%let	TypCategory	=	%FS_VARTYPE( inDAT = &inDatCC. , inFLD = &inCC_Cat. );

%*100.	Prepare the input dataset.;
data &procLIB..__BTS_DocProb_pre;
	%*010.	Create the temporary variable to hold the sentence values.;
	length
		__wsplit__	$%sysfunc(max(&lenFeatSet.,%length(&inFeatSet.)))
	;

	%*100.	We take [inCC_Cat] for granted as intermediate variable.;
	%*We pseudo-set the output dataset to form the table structure.;
	if	0	then	set	%unquote(&inDatCC.);

%if	&inValType.	=	V	%then %do;
	%*200.	Input the values.;
	__wsplit__	=	symget("inFeatSet");
	&inCC_Cat.	=	%sysfunc(ifc(&TypCategory.=C,symget("inCategory"),symgetn("inCategory")));

	%*300.	Reset the macro variables for further process.;
	%*IMPORTANT: We can only call [SYMPUTX] rountine here, for the function [symget<n>] is run at execution phase;
	%*            instead of compilation phase, which means if we use [LET] statement, the values of these macro;
	%*            variables will be overwritten BEFORE above statements are executed.;
	call symputx("inCategory","&inCC_Cat.","F");
	call symputx("inFeatSet","__wsplit__","F");

	%*400.	Output and stop the DATA step.;
	output;
	stop;
%end;
%else %do;
	%*600.	If the update mode is [D], we re-format the variables in the input dataset where necessary.;
	%*610.	Set the input data.;
	set %unquote(&inDat.);

	%*620.	Re-format the required variables.;
	&inFeatSet.	=	%sysfunc(ifc(&TypFeature.=C,lowcase(strip(&inFeatSet.)),&inFeatSet.));
	__wsplit__	=	%sysfunc(ifc(&TypFeature.=C,lowcase(strip(&inFeatSet.)),&inFeatSet.));
	&inCC_Cat.	=	%sysfunc(ifc(&TypCategory.=C,lowcase(strip(&inCategory.)),&inCategory.));
%end;

	%*900.	Purge.;
run;

%*190.	Quit the process if there is no observation to calculate the probability.;
%if	%getOBS4DATA( inDAT = &procLIB..__BTS_DocProb_pre , gMode = F )	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No observation is found in the input data [&inDat.]. Skip the process.;
	%goto	EndOfProc;
%end;

%*500.	Calculate the Text Probability.;
%Mdl_TxtProb(
	D
	,&inFeatSet.
	,&inCC_Cat.
	,inDat		=	&procLIB..__BTS_DocProb_pre
	,inDatFC	=	&inDatFC.
	,inFC_Feat	=	&inFC_Feat.
	,inFC_Cat	=	&inFC_Cat.
	,inFC_Freq	=	&inFC_Freq.
	,inDatCC	=	&inDatCC.
	,inCC_Cat	=	&inCC_Cat.
	,inCC_Freq	=	&inCC_Freq.
	,outDAT		=	&procLIB..__BTS_DocProb_TxtProb
	,outProb	=	__TxtProb__
	,procLIB	=	&procLIB.
)

%*600.	Calculate the Category Percentage.;
%*610.	Identify the unique Categories in the input data.;
proc sort
	data=&procLIB..__BTS_DocProb_pre(keep=&inCC_Cat.)
	out=&procLIB..__BTS_DocProb_UniCat
	nodupkey
;
	by	&inCC_Cat.;
run;

%*650.	Retrieve the Percentage for each unique Category from [inDatCC].;
%Mdl_CategoryPct(
	D
	,&inCC_Cat.
	,inDat		=	&procLIB..__BTS_DocProb_UniCat
	,inDatCC	=	&inDatCC.
	,inCC_Cat	=	&inCC_Cat.
	,inCC_Freq	=	&inCC_Freq.
	,outDAT		=	&procLIB..__BTS_DocProb_CatPct
	,outPct		=	__cPct__
	,procLIB	=	&procLIB.
)

%*700.	Calculate the Text Percentage.;
%*610.	Identify the unique [inFeatSet] in the input data.;
proc sort
	data=&procLIB..__BTS_DocProb_pre(keep=&inFeatSet.)
	out=&procLIB..__BTS_DocProb_UniFeat
	nodupkey
;
	by	&inFeatSet.;
run;

%*650.	Retrieve the Percentage for each unique [inFeatSet] from [inDatFC].;
%Mdl_TxtPct(
	D
	,&inFeatSet.
	,inDat		=	&procLIB..__BTS_DocProb_UniFeat
	,inDatFC	=	&inDatFC.
	,inFC_Feat	=	&inFC_Feat.
	,inFC_Cat	=	&inFC_Cat.
	,inFC_Freq	=	&inFC_Freq.
	,outDAT		=	&procLIB..__BTS_DocProb_TxtPct
	,outPct		=	__TxtPct__
	,procLIB	=	&procLIB.
)

%*800.	Calculate the Document Probability.;
%*801.	Switch off the [NOTES] option to avoid large I/O in the LOG for HASH Object.;
options	nonotes;

%*820.	Use the mean of Weighted Feature Probability in each phrase of Features under [inCategory] as Document Probability.;
data %unquote(&outDAT.);
	%*100.	Set the data.;
	set &procLIB..__BTS_DocProb_TxtProb end=EOF;

	%*200.	Create new variables.;
	%*210.	Create the variable that denotes the Probability.;
	format	&outProb.	percent12.2;
	call missing(&outProb.);

	%*250.	Prepare the temporary variables that denote the full dataset names.;

	%*300.	Prepare the Hash Objects.;
	if	_N_	=	1	then do;
		%*100.	Prepare to load the Category Percentage.;
		if	0	then	set	&procLIB..__BTS_DocProb_CatPct;
		dcl	hash	hCP(dataset:"&procLIB..__BTS_DocProb_CatPct",hashexp:16);
		hCP.DefineKey("&inCC_Cat.");
		hCP.DefineData("__cPct__");
		hCP.DefineDone();

		%*200.	Prepare to load the Text Percentage.;
		if	0	then	set	&procLIB..__BTS_DocProb_TxtPct;
		dcl	hash	hTP(dataset:"&procLIB..__BTS_DocProb_TxtPct",hashexp:16);
		hTP.DefineKey("&inFeatSet.");
		hTP.DefineData("__TxtPct__");
		hTP.DefineDone();
	end;
	call missing(__cPct__);
	call missing(__TxtPct__);

	%*400.	Read the database to retrieve the percentages.;
	%*410.	Read the Category Percentage.;
	_iorc_		=	hCP.find(key:&inCC_Cat.);
	__cPct__	=	sum(0,__cPct__);

	%*420.	Read the Category Frequency.;
	_iorc_		=	hTP.find(key:&inFeatSet.);
	__TxtPct__	=	sum(0,__TxtPct__);

	%*500.	Calculate the Document Probability.;
	%*We cannot use the function [IFN] here, for it will be parsed anyway at execution stage.;
	if	__TxtPct__	=	0	then do;
		&outProb.	=	0;
	end;
	else do;
		&outProb.	=	__TxtProb__ * __cPct__ / __TxtPct__;
	end;

	%*900.	Purge.;
	keep
		&inFeatSet.
		&inCategory.
		%if &GnDocPVar. ^= 0 %then %do;
			%do Vi=1 %to &GnDocPVar.;
				&&GeDocPVar&Vi..
			%end;
		%end;
		&outProb.
	;
run;

%*819.	Restore the [NOTES] option.;
options	&OpNote.;

%EndOfProc:
%mend BayesTxtSeg_DocProb;

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

%*150.	Calculate the Document Probability based on values.;
%BayesTxtSeg_DocProb(V,"quick car",Good)
%BayesTxtSeg_DocProb(V,"quick car",bad)

%*150.	Calculate the Document Probability based on dataset.;
data testDocProb;
	length
		C_SENTENCE	$1024
		Category	$64
	;
	C_SENTENCE	=	"quick car";
	Category	=	"good";
	output;

	C_SENTENCE	=	"QUick car";
	Category	=	"bAD";
	output;

	C_SENTENCE	=	"nobody jumps";
	Category	=	"Good";
	output;
run;
%BayesTxtSeg_DocProb(D,C_SENTENCE,Category,inDAT=testDocProb)

/*-Notes- -End-*/

/*-Discussion- -Begin-* /
贝叶斯定理：Pr( Category | Text ) = Pr( Text | Category ) * Pr( Category ) / Pr( Text )
[01]定理中的总体是“所有的句子”而不是“所有独立的单词”（只有句子才能表达正向或负向情感），因此计算Pr( Category )的时候须使用CC表来判断“句子的总数”
[02]无法直接计算Pr( Category | Text )的原因：单词不能作为表达情感方向的条件，所以数据中不存在“当出现car的时候，有多少概率表达good的方向”；但是数据可以得出
    “car在所有正面情感句子中出现的概率”，也就是Pr( Text | Category )
[03]计算Pr( Text )时，由于必须拆分所有句子成为独立的单词，故使用的总体应当是FC表（在贝叶斯定理中，它与CC表是同一个总体，只是观察角度不同）
/*-Discussion- -End-*/