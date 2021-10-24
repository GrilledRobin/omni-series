%macro Mdl_TxtPct(
	inValType
	,inFeatSet
	,inDat		=
	,inDatFC	=	WORK.FC
	,inFC_Feat	=	Feature
	,inFC_Cat	=	Category
	,inFC_Freq	=	Count
	,outDAT		=	WORK.TxtPct
	,outPct		=	__TxtPct__
	,procLIB	=	WORK
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to calculate the Percentage of the given phrase of Features showing up in the Feature-Category-Frequency	|
|	| data.																																|
|	|There are 2 ways to calculate the Text Percentage (while the output will always be a dataset):										|
|	|[1] Provide the phrase of Features (e.g. "Bless you") as character strings.														|
|	|[2] Provide the dataset that holds the Features.																					|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Given below conditions:																											|
|	|  [Feature<N>]		=	<N>th unique Feature showing up in [inFeatSet]. The order of <N> is smallest to largest of total frequency	|
|	|  						counts that [Feature<N>] shows up in [inDatFC].																|
|	|  [Weight<N>]		=	Number of times that [Feature<N>] showing up in [inFeatSet]													|
|	|  [inFC_Freq<N>]	=	Number of times that [Feature<N>] showing up in [inDatFC]													|
|	|  [inFC_Freq]		=	Total sum of frequency counts in [inDatFC]																	|
|	|Calculation Formula:																												|
|	|				[inFC_Freq<1>] * [Weight<1>]		[inFC_Freq<2>] * [Weight<2>]			[inFC_Freq<3>] * [Weight<3>]			|
|	|[TxtPct]	=	----------------------------	+	----------------------------	+	-------------------------------------	...	|
|	|						[inFC_Freq]					[inFC_Freq] - [inFC_Freq<1>]		[inFC_Freq] - sum of [inFC_Freq<1,2>]		|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inValType	:	The type of value that should be inserted into the Feature Category dataset.										|
|	|				[V] : The value is provided as character strings.																	|
|	|				[D] : The values reside in the provided dataset.																	|
|	|inFeatSet	:	The variable name that denotes the set of values of Feature, or the Feature values as character string.				|
|	|				The common usage is to analyze the words in a sentence.																|
|	|inDat		:	The input dataset.																									|
|	|				If [inValType]=[D], it should be provided.																			|
|	|				IMPORTANT: There should NOT be the same variables as in FC and CC tables, except that [inFeatSet] can be the same	|
|	|				            as [inFC_Feat] in [inDatFC], and that [inCategory] can be the same as [inCC_Cat] in [inDatCC].			|
|	|inDatFC	:	The Feature-Category dataset to be trained.																			|
|	|inFC_Feat	:	The variable name that denotes the value of Feature in [inDatFC].													|
|	|inFC_Cat	:	The variable name that denotes the Category that any Feature would fall into, in [inDatFC].							|
|	|inFC_Freq	:	The variable name that denotes the frequency count of any Feature that appears in any text message as certain		|
|	|				 category, in [inDatFC].																							|
|	|outDAT		:	The output dataset that contains the Probability of the given [inFeatSet] under [inCategory].						|
|	|				All variables in [inDAT] will be reserved, with a new variable [outPct] created.									|
|	|outPct		:	The new variable in the output dataset that denotes the Percentage of the given [inFeatSet].						|
|	|procLIB	:	The working library.																								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20170819		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170820		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Make the Word Split process standalone for automation purpose.																|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170828		| Version |	3.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Switch back to the hashing of the entire table, instead of one observation at a time, as I found that the processing speed	|
|	|      | is incredibly slow when encountering relatively large dataset with only thousands of observations.							|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180311		| Version |	3.10		| Updater/Creator |	Lu Robin Bin												|
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
|	|	|chkDUPerr																														|
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
|	|	|Txt_WordSplit																													|
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

%if	%length(%qsysfunc(compress(&inDatFC.,%str( ))))		=	0	%then	%let	inDatFC		=	WORK.FC;
%if	%length(%qsysfunc(compress(&inFC_Feat.,%str( ))))	=	0	%then	%let	inFC_Feat	=	Feature;
%if	%length(%qsysfunc(compress(&inFC_Cat.,%str( ))))	=	0	%then	%let	inFC_Cat	=	&inCC_Cat.;
%if	%length(%qsysfunc(compress(&inFC_Freq.,%str( ))))	=	0	%then	%let	inFC_Freq	=	&inCC_Freq.;

%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))		=	0	%then	%let	outDAT		=	WORK.TxtPct;
%if	%length(%qsysfunc(compress(&outPct.,%str( ))))		=	0	%then	%let	outPct		=	__TxtPct__;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))		=	0	%then	%let	procLIB		=	WORK;

%if	%sysfunc(nvalid(&outPct.))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.][outPct=&outPct.] is NOT a valid Variable Name!;
	%ErrMcr
%end;

%let	inFeatSet	=	%qlowcase(%qsysfunc(strip(%qsysfunc(dequote(&inFeatSet.)))));

%if	&inValType.	=	D	%then %do;
	%*Verify whether the provided parameters are valid SAS variable names.;
	%if	%sysfunc(nvalid(&inFeatSet.))	=	0	%then %do;
		%put	%str(W)ARNING: [&L_mcrLABEL.][inFeatSet=&inFeatSet.] is NOT a valid Variable Name when [inValType=&inValType.]!;
		%ErrMcr
	%end;
%end;

%*013.	Define the local environment.;
%local
	OpNote
	lenFeatSet
	TypFeature
	tmpWeight
	LnTotalFC
	Vi
;
%let	OpNote		=	%sysfunc(getoption(notes));
%let	lenFeatSet	=	0;
%let	tmpWeight	=	__Weight__;

%*014.	Define the global environment.;
%global
	GnTPctVar
;
%let	GnTPctVar	=	0;

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in traditional SAS syntax colors.;
%macro dummy; %mend dummy;

%*070.	Retrieve necessary information from [inDAT].;
%if	&inValType.	=	D	%then %do;
	%*100.	Retrieve the length of [inFeatSet] in the input dataset.;
	%let	lenFeatSet	=	%FS_VARLEN( inDAT = &inDat. , inFLD = &inFeatSet. );

	%*200.	Retrieve all the variables from [inDAT], except the required variables, for keeping them at the output step.;
	%getCOLbyStrPattern(
		inDAT		=	&inDAT.
		,inRegExp	=
		,exclRegExp	=	%nrbquote(\b(&inFeatSet.)\b)
		,chkVarTP	=	ALL
		,outCNT		=	GnTPctVar
		,outELpfx	=	GeTPctVar
	)
%end;

%*090.	Check the types of the Feature and Category variables in the output dataset.;
%let	TypFeature	=	%FS_VARTYPE( inDAT = &inDatFC. , inFLD = &inFC_Feat. );

%*100.	Prepare the input dataset.;
data &procLIB..__Mdl_TxtPct_pre;
	%*010.	Create the temporary variable to hold the sentence values.;
	length
		__wsplit__	$%sysfunc(max(&lenFeatSet.,%length(&inFeatSet.)))
	;

	%*100.	We take [inFC_Feat] for granted as intermediate variable.;
	%*We pseudo-set the output dataset to form the table structure.;
	if	0	then	set	%unquote(&inDatFC.);

	%*150.	Weight and Initial Probability.;
	length
		__Weight__
		8
	;

	%*151.	Weight of each Feature is 1.;
	__Weight__		=	1;

%if	&inValType.	=	V	%then %do;
	%*200.	Input the values.;
	__wsplit__	=	symget("inFeatSet");

	%*300.	Reset the macro variables for further process.;
	%*IMPORTANT: We can only call [SYMPUTX] rountine here, for the function [symget<n>] is run at execution phase;
	%*            instead of compilation phase, which means if we use [LET] statement, the values of these macro;
	%*            variables will be overwritten BEFORE above statements are executed.;
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
%end;

	%*900.	Purge.;
run;

%*190.	Quit the process if there is no observation to calculate the probability.;
%if	%getOBS4DATA( inDAT = &procLIB..__Mdl_TxtPct_pre , gMode = F )	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No observation is found in the input data [&inDat.]. Skip the process.;
	%goto	EndOfProc;
%end;

%*195.	Since we will aggregate the weights in the later steps, we should assure each [inFeatSet] only shows up once.;
%chkDUPerr(
	inDAT	=	&procLIB..__Mdl_TxtPct_pre
	,inKEY	=	&inFeatSet.
	,dupDAT	=	&procLIB..__Mdl_TxtPct_DUPchk
)

%*200.	Word split process.;
%Txt_WordSplit(
	inDAT	=	&procLIB..__Mdl_TxtPct_pre
	,inVAR	=	__wsplit__
	,outDAT	=	&procLIB..__Mdl_TxtPct_wsplit
	,outVAR	=	&inFC_Feat.
)

%*300.	Sum the total frequency counts by each [inFeature] in [inDatFC].;
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
		out=&procLIB..__Mdl_TxtPct_allFC
		sum=&inFC_Freq.
	;
run;

%*500.	Aggregate the data by unique [inFC_Feat].;
%*501.	Switch off the [NOTES] option to avoid large I/O in the LOG for HASH Object.;
options	nonotes;

%*510.	Sort the data.;
proc sort
	data=&procLIB..__Mdl_TxtPct_wsplit
;
	by
		&inFeatSet.
		&inFC_Feat.
	;
run;

%*550.	Aggregation.;
data &procLIB..__Mdl_TxtPct_in;
	%*100.	Set the data.;
	set &procLIB..__Mdl_TxtPct_wsplit;
	by
		&inFeatSet.
		&inFC_Feat.
	;

	%*200.	Create new variables.;
	%*210.	Create temporary variables to store the frequency counts.;
	format	__sumFreq__	8.;

	%*220.	Create temporary variables to hold the sum of Weights.;
	array
		arrWgt{1}
		8
		_temporary_
	;

	%*250.	Prepare the temporary variables that denote the full dataset names.;

	%*300.	Prepare the Hash Objects.;
	if	_N_	=	1	then do;
		%*100.	Prepare to load the Feature-Category-Frequency database.;
		if	0	then	set	&procLIB..__Mdl_TxtPct_allFC;
		dcl	hash	hFC(dataset:"&procLIB..__Mdl_TxtPct_allFC",hashexp:16);
		hFC.DefineKey("&inFC_Feat.");
		hFC.DefineData("&inFC_Freq.");
		hFC.DefineDone();
	end;
	call missing(&inFC_Freq.);

	%*400.	Read the database to retrieve the frequency counts.;
	%*410.	Read the Feature Frequency.;
	_iorc_		=	hFC.find(key:&inFC_Feat.);
	__sumFreq__	=	sum(0,&inFC_Freq.);

	%*700.	Initialize the sum of Weights.;
	if	first.&inFC_Feat.	then do;
		arrWgt{1}	=	0;
	end;

	%*800.	Increment the sum.;
	arrWgt{1}	+	__Weight__;

	%*900.	Output for each [inFC_Feat].;
	if	last.&inFC_Feat.	then do;
		__Weight__	=	arrWgt{1};
		output;
	end;
run;

%*590.	Restore the [NOTES] option.;
options	&OpNote.;

%*700.	Retrieve the sum of all Frequency Counts in [inDatFC].;
proc sql noprint;
	select sum(&inFC_Freq.) into :LnTotalFC from %unquote(&inDatFC.);
quit;
%let	LnTotalFC	=	%sysfunc(sum(0,&LnTotalFC.));

%*800.	Calculate the Feature Percentage.;
%*810.	Sort the data by [inFeatSet] for output.;
%*[inFC_Feat] with the smallest [__sumFreq__] is prior to others.;
proc sort
	data=&procLIB..__Mdl_TxtPct_in
;
	by
		&inFeatSet.
		__sumFreq__
		&inFC_Feat.
	;
run;

%*880.	Processing.;
data %unquote(&outDAT.);
	%*100.	Set the data.;
	set &procLIB..__Mdl_TxtPct_in end=EOF;
	by
		&inFeatSet.
		__sumFreq__
		&inFC_Feat.
	;

	%*200.	Create new variables.;
	%*210.	Create the variable that denotes the Percentage.;
	format	&outPct.	percent12.2;
	retain	&outPct.;
	if	first.&inFeatSet.	then do;
		&outPct.	=	0;
	end;

	%*220.	Create temporary variables to store the frequency counts.;
	%*arrTFreq{1} : The rest sum of Frequency Counts in [inDatFC];
	%*arrTFreq{2} : The sum of Frequency Counts of previous Features that were processed;
	array
		arrTFreq{2}
		8
		_temporary_
	;
	if	first.&inFeatSet.	then do;
		arrTFreq{1}	=	&LnTotalFC.;
		arrTFreq{2}	=	0;
	end;

	%*500.	Calculate the Feature Percentage.;
	arrTFreq{1}	=	sum( arrTFreq{1} , -arrTFreq{2} );
	%*We cannot use the function [IFN] here, for it will be parsed anyway at execution stage.;
	if	arrTFreq{1}	=	0	then do;
		%*100.	If there is no rest Feature in [inDatFC], all the Features in [inDatFC] must have been included in [inFeatSet].;
		&outPct.	=	1;
	end;
	else do;
		&outPct.	+	( __sumFreq__ * __Weight__ / arrTFreq{1} );
	end;

	%*600.	Accumulate the temporary variables.;
	%*We should accumulate below variable AFTER the Percentage is calculated.;
	arrTFreq{2}	=	sum( arrTFreq{2} , __sumFreq__ );

	%*800.	Output.;
	if	last.&inFeatSet.	then do;
		%*The maximum Percentage should be 100 Percent.;
		&outPct.	=	min( 1 , &outPct. );
		output;
	end;

	%*900.	Purge.;
	keep
		&inFeatSet.
		%if &GnTPctVar. ^= 0 %then %do;
			%do Vi=1 %to &GnTPctVar.;
				&&GeTPctVar&Vi..
			%end;
		%end;
		&outPct.
	;
run;

%EndOfProc:
%mend Mdl_TxtPct;

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
%Mdl_TxtPct(V,"quick car")

%*150.	Calculate the Document Probability based on dataset.;
data testTxtPct;
	length
		C_SENTENCE	$1024
		Category	$64
	;
	C_SENTENCE	=	"QUick car";
	Category	=	"bAD";
	output;

	C_SENTENCE	=	"nobody jumps";
	Category	=	"Good";
	output;
run;
%Mdl_TxtPct(D,C_SENTENCE,inDAT=testTxtPct)

/*-Notes- -End-*/