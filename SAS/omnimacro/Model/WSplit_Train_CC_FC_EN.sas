%macro WSplit_Train_CC_FC_EN(
	inValType
	,inFeatSet
	,inCategory
	,inDat		=
	,outDatFC	=	WORK.FC
	,outFC_Feat	=	Feature
	,outFC_Cat	=	Category
	,outFC_Freq	=	Count
	,outDatCC	=	WORK.CC
	,outCC_Cat	=	Category
	,outCC_Freq	=	Count
	,procLIB	=	WORK
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to train the Feature-Category-Frequency datasets by the provided Feature values and Category values.		|
|	|There are 2 ways to train the datasets:																							|
|	|[1] Provide the values as character strings.																						|
|	|[2] Provide the dataset that holds the Features and their respective Categories..													|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|This macro only supports the Word Split for English.																				|
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
|	|				If [inValType]=[D], it should be the same variable name as in [outDat], or the Feature Category dataset.			|
|	|inDat		:	The input dataset.																									|
|	|				If [inValType]=[D], it should be provided.																			|
|	|outDatFC	:	The Feature-Category dataset to be trained.																			|
|	|outFC_Feat	:	The variable name that denotes the value of Feature in [outDatFC].													|
|	|outFC_Cat	:	The variable name that denotes the Category that any Feature would fall into, in [outDatFC].						|
|	|outFC_Freq	:	The variable name that denotes the frequency count of any Feature that appears in any text message as certain		|
|	|				 category, in [outDatFC].																							|
|	|outDatCC	:	The Category Count dataset to be trained.																			|
|	|outCC_Cat	:	The variable name that denotes the Category that any Feature sentence is tagged, in [outDatCC].						|
|	|outCC_Freq	:	The variable name that denotes the frequency count of any Category that tags the paragraph, in [outDatCC]			|
|	|procLIB	:	The working library.																								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20170812		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170820		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Make the Word Split process standalone for automation purpose.																|
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
|	|All the Features and Categories will be translated into lower case.																|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ErrMcr																															|
|	|	|getOBS4DATA																													|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\FileSystem"																						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|FS_VARLEN																														|
|	|	|FS_VARTYPE																														|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\Model"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|Txt_WordSplit																													|
|	|	|Mdl_inCC																														|
|	|	|Mdl_inFC																														|
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
	%put	%str(W)ARNING: [&L_mcrLABEL.]No data [inFeatSet=&inFeatSet.] is provided for training the model! Skip the process.;
	%goto	EndOfProc;
%end;

%if	%length(%qsysfunc(compress(&outDatCC.,%str( ))))	=	0	%then	%let	outDatCC	=	WORK.CC;
%if	%length(%qsysfunc(compress(&outCC_Cat.,%str( ))))	=	0	%then	%let	outCC_Cat	=	Category;
%if	%length(%qsysfunc(compress(&outCC_Freq.,%str( ))))	=	0	%then	%let	outCC_Freq	=	Count;

%if	%length(%qsysfunc(compress(&outDatFC.,%str( ))))	=	0	%then	%let	outDatFC	=	WORK.FC;
%if	%length(%qsysfunc(compress(&outFC_Feat.,%str( ))))	=	0	%then	%let	outFC_Feat	=	Feature;
%if	%length(%qsysfunc(compress(&outFC_Cat.,%str( ))))	=	0	%then	%let	outFC_Cat	=	&outCC_Cat.;
%if	%length(%qsysfunc(compress(&outFC_Freq.,%str( ))))	=	0	%then	%let	outFC_Freq	=	&outCC_Freq.;

%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))		=	0	%then	%let	procLIB		=	WORK;

%if	%length(%qsysfunc(compress(&inCategory.,%str( ))))	=	0	%then	%let	inCategory	=	&outCC_Cat.;
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
	lenFeatSet
	TypFeature
	TypCategory
;
%let	lenFeatSet	=	0;

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in traditional SAS syntax colors.;
%macro dummy; %mend dummy;

%*070.	Retrieve necessary information from [inDAT].;
%if	&inValType.	=	D	%then %do;
	%*100.	Retrieve the length of [inFeatSet] in the input dataset.;
	%let	lenFeatSet	=	%FS_VARLEN( inDAT = &inDat. , inFLD = &inFeatSet. );
%end;

%*090.	Check the types of the Feature and Category variables in the output dataset.;
%let	TypFeature	=	%FS_VARTYPE( inDAT = &outDatFC. , inFLD = &outFC_Feat. );
%let	TypCategory	=	%FS_VARTYPE( inDAT = &outDatCC. , inFLD = &outCC_Cat. );

%*100.	Prepare the input dataset.;
data &procLIB..__mdl_wsplit_CC;
	%*010.	Create the temporary variable to hold the sentence values.;
	length
		__wsplit__	$%sysfunc(max(&lenFeatSet.,%length(&inFeatSet.)))
	;

	%*200.	We take [outCC_Cat] and [outCC_Freq] for granted as intermediate variables.;
	%*We pseudo-set the output dataset to form the table structure.;
	if	0	then	set	%unquote(&outDatCC.);
	if	0	then	set	%unquote(&outDatFC.);

	%*250.	Assign the frequency count of the Category as 1 for each Feature set.;
	&outCC_Freq.	=	1;
	&outFC_Freq.	=	1;

%if	&inValType.	=	V	%then %do;
	%*300.	Input the values.;
	__wsplit__	=	symget("inFeatSet");
	&outCC_Cat.	=	%sysfunc(ifc(&TypCategory.=C,symget("inCategory"),symgetn("inCategory")));

	%*400.	Output and stop the DATA step.;
	output;
	stop;
%end;
%else %do;
	%*600.	If the update mode is [D], we re-format the variables in the input dataset where necessary.;
	%*610.	Set the input data.;
	set %unquote(&inDat.);

	%*620.	Re-format the required variables.;
	__wsplit__	=	%sysfunc(ifc(&TypFeature.=C,lowcase(strip(&inFeatSet.)),&inFeatSet.));
	&outCC_Cat.	=	%sysfunc(ifc(&TypCategory.=C,lowcase(strip(&inCategory.)),&inCategory.));
%end;

	%*700.	Assign the Category in Feature-Category-Frequency table.;
	&outFC_Cat.	=	%sysfunc(ifc(&TypCategory.=C,strip(&outCC_Cat.),&outCC_Cat.));

	%*900.	Purge.;
	keep
		__wsplit__
		&outCC_Cat.
		&outCC_Freq.
		&outFC_Cat.
		&outFC_Freq.
	;
run;

%*190.	Quit the process if there is no observation to train the model.;
%if	%getOBS4DATA( inDAT = &procLIB..__mdl_wsplit_CC , gMode = F )	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No observation is found in the input data [&inDat.]. Skip the process.;
	%goto	EndOfProc;
%end;

%*200.	Word split process.;
%Txt_WordSplit(
	inDAT	=	&procLIB..__mdl_wsplit_CC
	,inVAR	=	__wsplit__
	,outDAT	=	&procLIB..__mdl_wsplit_FC
	,outVAR	=	&outFC_Feat.
)

%*500.	Model Training.;
%*510.	Train the Category Count dataset.;
%Mdl_inCC(
	D
	,&outCC_Cat.
	,&outCC_Freq.
	,inDat			=	&procLIB..__mdl_wsplit_CC
	,outDat			=	&outDatCC.
	,outDat_Cat		=	&outCC_Cat.
	,outDat_Freq	=	&outCC_Freq.
	,procLIB		=	&procLIB.
)

%*520.	Train the Feature-Category-Frequency dataset.;
%Mdl_inFC(
	D
	,&outFC_Feat.
	,&outFC_Cat.
	,&outFC_Freq.
	,inDat			=	&procLIB..__mdl_wsplit_FC
	,outDat			=	&outDatFC.
	,outDat_Feat	=	&outFC_Feat.
	,outDat_Cat		=	&outFC_Cat.
	,outDat_Freq	=	&outFC_Freq.
	,procLIB		=	&procLIB.
)

%EndOfProc:
%mend WSplit_Train_CC_FC_EN;

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

/*-Notes- -End-*/