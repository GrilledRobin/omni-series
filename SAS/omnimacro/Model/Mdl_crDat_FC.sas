%macro Mdl_crDat_FC(
	inFeature	=	Feature
	,inCategory	=	Category
	,outFreq	=	Count
	,outDat		=	WORK.FC
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to create the Feature Category dataset for the modeling.													|
|	|The output dataset stores the frequency count of any feature (any single word) at any category that appears in the text message.	|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Table Structure:																													|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|         Variable Name          | Type | Len |     Format     |         Default Name           |            Description            |
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	| inFeature                      |  C   |  64 |      $64.      | Feature                        |Feature Value 特征值               |
|	| inCategory                     |  C   |  64 |      $64.      | Category                       |Category Value 属性值              |
|	| outFreq                        |  N   |   8 |    comma32.    | Count                          |Frequency Count                    |
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inFeature	:	The variable name that denotes the value of Feature, or any meaningful WORD.										|
|	|inCategory	:	The variable name that denotes the category that any Feature would fall into, either Good or Bad.					|
|	|outFreq	:	The variable name that denotes the frequency count of any Feature that appears in any text message as certain		|
|	|				 category.																											|
|	|outDat		:	The output dataset.																									|
|	|				This macro only CREATE a blank dataset.																				|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20170805		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180311		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
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
%if	%length(%qsysfunc(compress(&inFeature.,%str( ))))	=	0	%then	%let	inFeature	=	Feature;
%if	%length(%qsysfunc(compress(&inCategory.,%str( ))))	=	0	%then	%let	inCategory	=	Category;
%if	%length(%qsysfunc(compress(&outFreq.,%str( ))))		=	0	%then	%let	outFreq		=	Count;
%if	%length(%qsysfunc(compress(&outDat.,%str( ))))		=	0	%then	%let	outDat		=	WORK.FC;

%*013.	Define the local environment.;

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in traditional SAS syntax colors.;
%macro dummy; %mend dummy;

%*100.	Verify whether the provided dataset already exists.;
%if	%sysfunc(exist(&outDat.))	%then %do;
	%*100.	Issue message in the LOG.;
	%put	%str(N)OTE: [&L_mcrLABEL.]FC Dataset already exists, program will delete it and create a new one.;

	%*200.	Delete the original one.;
	proc sql noprint;
		drop table %unquote(&outDat.);
	quit;
%end;

%*200.	Create a blank dataset.;
data %unquote(&outDat.);
	%*100.	Create table structure.;
	length
		&inFeature.		$64
		&inCategory.	$64
		&outFreq.		8
	;
	format
		&inFeature.		$64.
		&inCategory.	$64.
		&outFreq.		comma32.
	;

	%*200.	Initialize the variables.;
	call missing(of _all_);

	%*300.	Export no observation.;
	if	0;
run;

%EndOfProc:
%mend Mdl_crDat_FC;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\Model"
	)
	mautosource
;

%*100.	Testing.;
%*110.	With specific variable names.;
%Mdl_crDat_FC(
	inFeature	=	C_FEATURE
	,inCategory	=	C_CATEGORY
	,outFreq	=	C_FREQUENCY
	,outDat		=	WORK.FC
)

%*120.	With no given parameters.;
%*If we do not provide the parenthases, it will NOT execute.;
%Mdl_crDat_FC()

/*-Notes- -End-*/