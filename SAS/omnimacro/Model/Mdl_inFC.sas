%macro Mdl_inFC(
	inValType
	,inFeature
	,inCategory
	,inFreq
	,inDat			=
	,outDat			=	WORK.FC
	,outDat_Feat	=	Feature
	,outDat_Cat		=	Category
	,outDat_Freq	=	Count
	,procLIB		=	WORK
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to update the Feature Category dataset by the provided Feature as well as its Category.						|
|	|There are 2 ways to update the Feature Category dataset:																			|
|	|[1] Provide the values as character strings.																						|
|	|[2] Provide the dataset that holds the Features and their respective Categories, as well as their repective Frequency Counts.		|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inValType		:	The type of value that should be inserted into the Feature Category dataset.									|
|	|					[V] : The value is provided as character strings.																|
|	|					[D] : The values reside in the provided dataset.																|
|	|inFeature		:	The variable name that denotes the set of values of Feature, or the Feature values as character string.			|
|	|					If [inValType]=[D], it should be the same variable name as in [outDat], or the Feature Category dataset.		|
|	|inCategory		:	The variable name that denotes the category that any Feature would fall into, either Good or Bad, or the		|
|	|					 Category value.																								|
|	|					If [inValType]=[D], it should be the same variable name as in [outDat], or the Feature Category dataset.		|
|	|inFreq			:	The variable name that denotes the frequency count of any Feature that appears in any text message as certain	|
|	|					 category, or the value frequency count if [inValType]=[V].														|
|	|					If [inValType]=[D], it should be the same variable name as in [outDat], or the Feature Category dataset.		|
|	|inDat			:	The input dataset.																								|
|	|					If [inValType]=[D], it should be provided.																		|
|	|outDat			:	The output dataset.																								|
|	|outDat_Feat	:	The variable name that denotes the value of Feature in [outDat].												|
|	|outDat_Cat		:	The variable name that denotes the category that any Feature would fall into, in [outDat].						|
|	|outDat_Freq	:	The variable name that denotes the frequency count of any Feature that appears in any text message as certain	|
|	|					 category, in [outDat].																							|
|	|procLIB		:	The working library.																							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20170805		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170812		| Version | 2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Create a dataset for the mode where [inValType=V] to simulate the process of [inValType=D], to reduce the branches.			|
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
|	|All the Features and Categories will be translated into lower case.																|
|	|Special characters %nrstr(&) and %nrstr(%%) cannot be set as the values in either [inCategory] or [inFeature], for the compilation	|
|	| of HASH Object will try to resolve any parameters in [dataset:] option.															|
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
%if	%length(%qsysfunc(compress(&inValType.,%str( ))))	=	0	%then	%let	inValType	=	V;
%let	inValType	=	%qsubstr(%qupcase(&inValType.),1,1);
%if	&inValType.	^=	V	and	&inValType.	^=	D	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]Unknown data type [inValType=&inValType.]!;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&outDat.,%str( ))))		=	0	%then	%let	outDat		=	WORK.FC;
%if	%length(%qsysfunc(compress(&outDat_Feat.,%str( ))))	=	0	%then	%let	outDat_Feat	=	Feature;
%if	%length(%qsysfunc(compress(&outDat_Cat.,%str( ))))	=	0	%then	%let	outDat_Cat	=	Category;
%if	%length(%qsysfunc(compress(&outDat_Freq.,%str( ))))	=	0	%then	%let	outDat_Freq	=	Count;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))		=	0	%then	%let	procLIB		=	WORK;

%if	%length(%qsysfunc(compress(&inFeature.,%str( ))))	=	0	%then	%let	inFeature	=	&outDat_Feat.;
%if	%length(%qsysfunc(compress(&inCategory.,%str( ))))	=	0	%then	%let	inCategory	=	&outDat_Cat.;
%let	inFeature	=	%qlowcase(%qsysfunc(strip(%qsysfunc(dequote(&inFeature.)))));
%let	inCategory	=	%qlowcase(%qsysfunc(strip(%qsysfunc(dequote(&inCategory.)))));

%if	&inValType.	=	V	%then %do;
	%if	%length(%qsysfunc(compress(&inFreq.,%str( ))))	=	0	%then	%let	inFreq	=	1;
%end;
%else %do;
	%if	%length(%qsysfunc(compress(&inFreq.,%str( ))))	=	0	%then	%let	inFreq	=	&outDat_Freq.;

	%*Verify whether the provided parameters are valid SAS variable names.;
	%if	%sysfunc(nvalid(&inFeature.))	=	0	%then %do;
		%put	%str(W)ARNING: [&L_mcrLABEL.][inFeature=&inFeature.] is NOT a valid Variable Name when [inValType=&inValType.]!;
		%ErrMcr
	%end;
	%if	%sysfunc(nvalid(&inCategory.))	=	0	%then %do;
		%put	%str(W)ARNING: [&L_mcrLABEL.][inCategory=&inCategory.] is NOT a valid Variable Name when [inValType=&inValType.]!;
		%ErrMcr
	%end;
	%if	%sysfunc(nvalid(&inFreq.))	=	0	%then %do;
		%put	%str(W)ARNING: [&L_mcrLABEL.][inFreq=&inFreq.] is NOT a valid Variable Name when [inValType=&inValType.]!;
		%ErrMcr
	%end;
%end;

%*013.	Define the local environment.;
%local
	OpNote
	nOutObs
	DSID
	TypFeature
	TypCategory
	rcds
	Vi
	nInObs
	nUpdObs
	nInsObs
	Ri
;
%let	OpNote	=	%sysfunc(getoption(notes));
%let	nOutObs	=	0;
%let	nInObs	=	0;
%let	nUpdObs	=	0;
%let	nInsObs	=	0;

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in traditional SAS syntax colors.;
%macro dummy; %mend dummy;

%*070.	Retrieve the number of observations of the output dataset.;
%*There will not be [EOF=1] when setting the data if there is no observation.;
%getOBS4DATA(
	inDAT	=	&outDat.
	,outVAR	=	nOutObs
	,gMode	=	P
)

%*080.	Retrieve all variable names in the dataset to be updated, for the last step to keey them during output.;
%getCOLbyStrPattern(
	inDAT		=	&outDat.
	,inRegExp	=
	,exclRegExp	=
	,chkVarTP	=	ALL
	,outCNT		=	GnOutVar
	,outELpfx	=	GeOutVar
)

%*090.	Check the types of the Feature and Category variables in the output dataset.;
%let	DSID		=	%sysfunc(open(&outDat.));
%let	TypFeature	=	%sysfunc(vartype(&DSID.,%sysfunc(varnum(&DSID.,&outDat_Feat.))));
%let	TypCategory	=	%sysfunc(vartype(&DSID.,%sysfunc(varnum(&DSID.,&outDat_Cat.))));
%let	rcds		=	%sysfunc(close(&DSID.));

%*100.	Prepare the input dataset.;
data &procLIB..__mdl_infc_pre;
%if	&inValType.	=	V	%then %do;
	%*100.	If the update mode is [V], we pseudo-set the output dataset to form the table structure.;
	if	0	then	set	%unquote(&outDat.);

	%*200.	Input the values.;
	&outDat_Feat.	=	%sysfunc(ifc(&TypFeature.=C,symget("inFeature"),symgetn("inFeature")));
	&outDat_Cat.	=	%sysfunc(ifc(&TypCategory.=C,symget("inCategory"),symgetn("inCategory")));
	&outDat_Freq.	=	symgetn("inFreq");

	%*300.	Reset the macro variables for further process.;
	%*IMPORTANT: We can only call [SYMPUTX] rountine here, for the function [symget<n>] is run at execution phase;
	%*            instead of compilation phase, which means if we use [LET] statement, the values of these macro;
	%*            variables will be overwritten BEFORE above statements are executed.;
	call symputx("inFeature","&outDat_Feat.","F");
	call symputx("inCategory","&outDat_Cat.","F");
	call symputx("inFreq","&outDat_Freq.","F");

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
%end;
run;

%*200.	Summarize the input dataset.;
proc means
	data=&procLIB..__mdl_infc_pre
	noprint
	nway
;
	class
		&inFeature.
		&inCategory.
	;
	var
		&inFreq.
	;
	output
		out=&procLIB..__mdl_infc_mns
		sum=&inFreq.
	;
run;

%*280.	Retrieve the number of observations of the values in the input dataset.;
%getOBS4DATA(
	inDAT	=	&procLIB..__mdl_infc_mns
	,outVAR	=	nInObs
	,gMode	=	P
)

%*290.	Quit the process if there is no observation in the input dataset.;
%if	&nInObs.	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No observation is found in the input data [&inDat.]. Skip the process.;
	%goto	EndOfProc;
%end;

%*300.	Prepare the datasets to update or insert into the base dataset.;
%*301.	Switch off the [NOTES] option to avoid large I/O in the LOG for HASH Object.;
options	nonotes;

%*310.	Split the data.;
data
	&procLIB..__mdl_infc_upd
	&procLIB..__mdl_infc_ins
;
	%*100.	Set the data.;
	set	&procLIB..__mdl_infc_mns;

	%*200.	Prepare the temporary variable that denotes the full dataset name.;

	%*300.	Prepare the Hash Object to load the base.;
	if	_N_	=	1	then do;
		dcl	hash	hBase(dataset:"&outDat.",hashexp:16);
		hBase.DefineKey("&outDat_Cat.","&outDat_Feat.");
		hBase.DefineData("&outDat_Freq.");
		hBase.DefineDone();
	end;

	%*500.	Split the dataset in terms of whether the Feature-Category combination is found in the base dataset.;
	if	hBase.check(key:&inCategory.,key:&inFeature.)	^=	0	then do;
		output	&procLIB..__mdl_infc_ins;
	end;
	else do;
		%*There is no use to verify whether there are duplicated combinations in the base dataset,;
		%* for there are more combinations than in the input dataset.;
		output	&procLIB..__mdl_infc_upd;
	end;
run;

%*319.	Restore the [NOTES] option.;
options	&OpNote.;

%*320.	Retrieve the number of observations of the values to be UPDATED.;
%getOBS4DATA(
	inDAT	=	&procLIB..__mdl_infc_upd
	,outVAR	=	nUpdObs
	,gMode	=	P
)

%*340.	Retrieve the number of observations of the values to be INSERTED.;
%getOBS4DATA(
	inDAT	=	&procLIB..__mdl_infc_ins
	,outVAR	=	nInsObs
	,gMode	=	P
)

%*500.	Update the value.;
%*501.	Switch off the [NOTES] option to avoid large I/O in the LOG for HASH Object.;
options	nonotes;

%*510.	Processing.;
data %unquote(&outDat.);
	%*100.	Set the dataset.;
	set
		%unquote(&outDat.)
		&procLIB..__mdl_infc_ins(in=ins)
	;

	%*200.	Output additional observations if there is new values in the INS dataset.;
	if	ins	=	1	then do;
		&outDat_Feat.	=	&inFeature.;
		&outDat_Cat.	=	&inCategory.;
		&outDat_Freq.	=	&inFreq.;
	end;

%if	&nUpdObs.	=	0	%then %do;
	%goto	EndOfUpd;
%end;
	%*300.	Prepare the Hash Object to load the UPD table.;
	if	_N_	=	1	then do;
		if	0	then	set	&procLIB..__mdl_infc_upd;
		dcl	hash	hUpd(dataset:"&procLIB..__mdl_infc_upd",hashexp:16);
		hUpd.DefineKey("&inCategory.","&inFeature.");
		hUpd.DefineData("&inCategory.","&inFeature.","&inFreq.");
		hUpd.DefineDone();
	end;
	if	ins	=	0	then do;
	%if	%FS_VarExists( inDAT = &outDat. , inFLD = &inFeature. )		=	0	%then %do;
		call missing(&inFeature.);
	%end;
	%if	%FS_VarExists( inDAT = &outDat. , inFLD = &inCategory. )	=	0	%then %do;
		call missing(&inCategory.);
	%end;
	%if	%FS_VarExists( inDAT = &outDat. , inFLD = &inFreq. )		=	0	%then %do;
		call missing(&inFreq.);
	%end;
	end;

	%*300.	Update the value if the same Feature in the same Category exists.;
	%*301.	Skip the Update process if there is no new value found.;
	if	hUpd.check(key:&outDat_Cat.,key:&outDat_Feat.)	^=	0	then do;
		goto	EndOfUpd;
	end;

	%*310.	Reserve the original frequency count.;
	length	tmpCount	8;
	tmpCount	=	&outDat_Freq.;

	%*320.	Load the value to be updated.;
	_iorc_			=	hUpd.find(key:&outDat_Cat.,key:&outDat_Feat.);
	&outDat_Freq.	=	sum(tmpCount,&inFreq.);

	%*390.	Mark the end of the Update process.;
	EndOfUpd:

%EndOfUpd:

	%*900.	Purge.;
	keep
	%do Vi=1 %to &GnOutVar.;
		&&GeOutVar&Vi..
	%end;
	;
run;

%*519.	Restore the [NOTES] option.;
options	&OpNote.;

%EndOfProc:
%mend Mdl_inFC;

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

%*120.	Insert initial values.;
%Mdl_inFC(V,"Laugh",Good,1)
%Mdl_inFC(V,Chuckle,good,1)
%Mdl_inFC(V,"giggle",GOOD,1)
%Mdl_inFC(V,"chortle",GOOD,1)
%Mdl_inFC(V,"grin","bad",1)
%Mdl_inFC(V,"smirk",bad,1)
%Mdl_inFC(V,"simper",bad,1)
%Mdl_inFC(V,"sneer",bad,1)

%*130.	Update new values.;
%Mdl_inFC(V,giGgle,good)
%Mdl_inFC(V,"simper","bad")
%Mdl_inFC(V,"grin","bad",3)

%*140.	Update by dataset.;
data upd;
	length
		Feature		$64
		Category	$64
		Count		8
	;
	Feature	=	"Laugh";	Category	=	"good";	Count	=	1;	output;
	Feature	=	"laugh";	Category	=	"gooD";	Count	=	1;	output;
	Feature	=	"sneer";	Category	=	"bad";	Count	=	1;	output;
	Feature	=	"beam";		Category	=	"good";	Count	=	1;	output;
run;
%Mdl_inFC(D,inDAT=upd)

%*200.	Update with special characters.;
%*There will be warnings reading that [KER is not resolved].;
%Mdl_inFC(V,'fa&ker',"bad")

/*-Notes- -End-*/