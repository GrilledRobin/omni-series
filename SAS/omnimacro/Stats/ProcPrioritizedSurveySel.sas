%macro ProcPrioritizedSurveySel(
	inDAT		=
	,inCriteria	=
	,CriDlm		=	%str(#)
	,SampleSize	=
	,ProcOptOth	=	%str(noprint)
	,outStrata	=
	,StrataOpt	=
	,ControlVar	=
	,SizeVar	=
	,IDVar		=
	,outPriVar	=	_Priority_
	,outPri		=	1
	,outDAT		=
	,procLIB	=	WORK
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to conduct the selection of the survey in terms of the default procedure [SurveySelect],					|
|	| compromising a list of criteria with decreasing priorities during the sample selection.											|
|	|For detailed usage, please find the official SAS/STAT document for reference.														|
|	|Main purpose:																														|
|	|If we need to extract a survey list comprised of 50 customers from each branch, with a priority of selection of					|
|	| Qualified customers, and fulfill the sample size with random selection from the rest of customers if there are					|
|	| not as many as 50 Qualified customers in any certain branch, we can use this macro to conduct a sequential						|
|	| selection automatically.																											|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|20160702 Known limits:																												|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|[1] [SAMPLINGUNIT|CLUSTER] Statement cannot be used for this purpose, for it does not select samples within the sampling units.|
|	|	|-------------------------------------------------------------------------------------------------------------------------------|
|	|	|[2] Tested statements:																											|
|	|   | [STRATA]																														|
|	|   | [CONTROL] (together with the options: [METHOD=] and [SORT=])																	|
|	|   | [ID]																															|
|	|	|-------------------------------------------------------------------------------------------------------------------------------|
|	|	|[3] Tested options in the [PROC SURVEYSELECT] statement.																		|
|	|   | [SELECTALL]																													|
|	|   | [NOPRINT]																														|
|	|   | [DATA=]																														|
|	|   | [OUT=]																														|
| 	|	| [SAMPSIZE=]																													|
|	|   | [METHOD=]																														|
|	|   | [SORT=]																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDAT		:	The dataset from which to extract the survey list.																	|
|	|inCriteria	:	The list of criteria in decreasing priorities, with the predefined delimiter to separate each other.				|
|	|CriDlm		:	The delimiter that separates the list of criteria in terms of the decreasing priorities.							|
|	|SampleSize	:	The sample size to be extracted.																					|
|	|				IMPORTANT: This is NOT for any one of the criteria, but for the whole selection.									|
|	|				IMPORTANT: If it is provided as a dataset, make sure there is no dataset option in the input.						|
|	|ProcOptOth	:	The other options that are available in the [Proc SurveySelect] statement.											|
|	|				IMPORTANT: You CANNOT specify these options: DATA=, OUT=, SAMPSIZE=, for they have been used.						|
|	|outStrata	:	The requirement to select the samples by Strata (i.e. grouped selection).											|
|	|StrataOpt	:	The options in the STRATA statement.																				|
|	|ControlVar	:	The variables that are available in CONTROL statement.																|
|	|				IMPORTANT: Control sorting is available for systematic and sequential selection methods								|
|	|				 (METHOD=SYS, METHOD=PPS_SYS, METHOD=SEQ, and METHOD=PPS_SEQ).														|
|	|SizeVar	:	The variable that is available in SIZE statement.																	|
|	|IDVar		:	The variables that are available in ID statement.																	|
|	|				IMPORTANT: Variables will only be kept in the output data, almost the same as KEEP statement.						|
|	|outPriVar	:	The variable in the output data that contains the Priority of the selection criteria.								|
|	|outPri		:	The Priority of the samples selected into the output data, minimum is 1 (Top Priority).								|
|	|				IMPORTANT: Its value only affects the values of the variable [outPriVar].											|
|	|outDAT		:	The output result.																									|
|	|procLIB	:	The working library.																								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20160702		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Creation.																													|
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
|	|20160702 Currently [SampleSize] does NOT support the grammar of [SAMPSIZE=(values)].												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ErrMcr																															|
|	|	|getOBS4DATA																													|
|	|	|genvarlist																														|
|	|	|TheFirstWordOf																													|
|	|	|ExceptTheFirstWord_SubListOf																									|
|	|	|ValidateDSNasStr																												|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\FileSystem"																						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|FS_VarExists																													|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from the same location as current macro.																			|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ProcPrioritizedSurveySel																										|
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
%if	%length(%qsysfunc(compress(&inDAT.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No input dataset is provided!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%getOBS4DATA( inDAT = &inDAT. , gMode = F )		=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]Input data has no observation!;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&CriDlm.,%str( ))))		=	0	%then	%let	CriDlm		=	%str(#);
%if	%length(%qsysfunc(compress(&ProcOptOth.,%str( ))))	=	0	%then	%let	ProcOptOth	=	%str(noprint SelectAll);
%if	%length(%qsysfunc(compress(&outPriVar.,%str( ))))	=	0	%then	%let	outPriVar	=	_Priority_;
%if	%length(%qsysfunc(compress(&outPri.,%str( ))))		=	0	%then	%let	outPri		=	1;

%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))		=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No output dataset is specified!;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))		=	0	%then	%let	procLIB		=	WORK;

%*013.	Define the global environment.;
%if	%length(%qsysfunc(compress(&outStrata.,%str( ))))	^=	0	%then %do;
	%genvarlist(
		nstart	=	1
		,inlst	=	&outStrata.
		,nvarnm	=	LeStrata&outPri._
		,nvarttl=	LnStrata&outPri.
	)
%end;

%*014.	Define the local environment.;
%*[LQCStrata]	:	Quoted list of Strata with Comma as delimiter.;
%*[LvSampSize]	:	Variable name of the Sample Size, either _NSIZE_ or SampleSize.;
%*[LcSampSize]	:	Conditional option of [SampSize=] for [SurveySelect] procedure.;
%*[LrSampSize]	:	Conditional Sample Size for the Residual sampling (May be a number or a dataset).;
%local
	NextPri
	FreqStrata
	LQCStrata
	LCriSurvey
	LCriResi
	LnObsSurvey
	LnObsResi
	prxNUM
	F_sampNum
	F_sampDat
	LvSampSize
	LcSampSize
	LrSampSize
	LnSurveyRst
	Si
;
%let	NextPri		=	%eval(&outPri. + 1);
%let	FreqStrata	=;
%let	LQCStrata	=;
%if	%length(%qsysfunc(compress(&outStrata.,%str( ))))	^=	0	%then %do;
	%let	FreqStrata	=	%sysfunc(translate(%sysfunc(compbl(%nrbquote(&outStrata.))),%str(*),%str( )));
	%do Si=1 %to &&LnStrata&outPri..;
		%let	LQCStrata	=	&LQCStrata.%nrbquote(,"&&LeStrata&outPri._&Si..");
	%end;
	%let	LQCStrata	=	%qsubstr(&LQCStrata.,2);
%end;
%let	LCriSurvey	=;
%let	LCriResi	=;
%if	%length(%qsysfunc(compress(&outStrata.,%str( ))))	^=	0	%then %do;
	%let	LcSampSize	=	&procLIB.._PPSS_SampSize_&outPri._;
	%let	LrSampSize	=	&procLIB.._PPSS_Residual_k_&outPri._;
%end;
%let	LnSurveyRst	=	0;

%*050.	Prepare the selection criteria at top priority.;
%if	%length(%qsysfunc(compress(&inCriteria.,%str( ))))	^=	0	%then %do;
	%let	LCriSurvey	=	%TheFirstWordOf( List = &inCriteria. , ByChar = &CriDlm. );
	%let	LCriResi	=	%ExceptTheFirstWord_SubListOf( List = &inCriteria. , ByChar = &CriDlm. );
%end;

%*100.	Verify the [SampleSize] definition.;
%*110.	Verify whether it is provided as a number.;
%let	prxNUM		=	%sysfunc(prxparse(/^\s*\d+\s*$/ismx));
%let	F_sampNum	=	0;
%if	%sysfunc(prxmatch(&prxNUM.,&SampleSize.))	%then %do;
	%let	F_sampNum	=	1;
%end;
%syscall	prxfree(prxNUM);

%*115.	Define the variable that specifies the sample size for the [SurveySelect] procedure.;
%if	&F_sampNum.	=	1	%then %do;
	%let	LvSampSize	=	_NSIZE_;
%end;

%*120.	Verify whether it is provided as a dataset.;
%let	F_sampDat	=	%ValidateDSNasStr(inSTR=&SampleSize.);

%*125.	Define the variable that specifies the sample size for the [SurveySelect] procedure.;
%if	&F_sampDat.	=	1	%then %do;
	%if	%FS_VarExists( inDAT = &SampleSize. , inFLD = _NSIZE_ )	%then %do;
		%let	LvSampSize	=	_NSIZE_;
	%end;
	%else %do;
		%let	LvSampSize	=	SampleSize;
	%end;
%end;

%*190.	Abort the process if neither of above conditions is set.;
%if	%eval( &F_sampNum. + &F_sampDat. )	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.][SampleSize] is not recognized!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*200.	Prepare a dataset of Sample Size.;
%*201.	Minimize the system resource usage.;
%if	&F_sampNum.	=	0	%then %do;
	%*100.	Create the dataset of Sample Size from the provided parameter.;
	data &LcSampSize.;
		set &SampleSize.;
	run;

	%*200.	Skip verifying the number of sample size.;
	%goto	EndOfCrSmplDat;
%end;

%*220.	Create a dataset in terms of the frequency of STRATA variables.;
%if	%length(%qsysfunc(compress(&outStrata.,%str( ))))	^=	0	%then %do;
	%*100.	Retrieve the frequency table from the entire [inDAT] by the STRATA variables.;
	proc freq
		data=%unquote(&inDAT.)
		noprint
	;
		tables
			&FreqStrata.
			/out=&procLIB.._PPSS_freqAll_&outPri._
		;
	run;

	%*200.	Use the number of [SampleSize] to extract the samples.;
	data &LcSampSize.;
		set &procLIB.._PPSS_freqAll_&outPri._;
		length	&LvSampSize.	8.;
		&LvSampSize.	=	&SampleSize.;
	run;
%end;

%*290.	Mark the end of the sort step.;
%EndOfCrSmplDat:

%*300.	Prepare the proper source data.;
%*310.	Split the input data into two in terms of the criteria at top priority.;
data
	&procLIB.._PPSS_indat_Survey_&outPri._
	&procLIB.._PPSS_indat_Residual_&outPri._
;
	%*100.	Set the input data.;
	set %unquote(&inDAT.);

	%*200.	Delete all observations that do not match the units in [SampleSize].;
	%*Should there be STRATA requirement, only those strata listed in [SampleSize] have to be sampled.;
%if	%length(%qsysfunc(compress(&outStrata.,%str( ))))	^=	0	%then %do;
	if	_N_	=	1	then do;
		dcl	hash	hSampSize(dataset:"&LcSampSize.");
		hSampSize.DefineKey(%unquote(&LQCStrata.));
		hSampSize.DefineData(%unquote(&LQCStrata.));
		hSampSize.DefineDone();
	end;

	if	hSampSize.check()	^=	0	then do;
		delete;
	end;
%end;

	%*800.	Output the valid data for [SurveySelect] procedure.;
	if	1
	%if	%length(%qsysfunc(compress(&LCriSurvey.,%str( ))))	^=	0	%then %do;
		and	( %unquote(&LCriSurvey.) )
	%end;
		then do;
		output	&procLIB.._PPSS_indat_Survey_&outPri._;
	end;
	else do;
		output	&procLIB.._PPSS_indat_Residual_&outPri._;
	end;
run;

%*320.	Sort the data if there is STRATA statement available.;
%if	%length(%qsysfunc(compress(&outStrata.,%str( ))))	^=	0	%then %do;
	proc sort
		data=&procLIB.._PPSS_indat_Survey_&outPri._
	;
		by	&outStrata.;
	run;
%end;

%*330.	Basic information of the dataset for current sampling.;
%*331.	# of observations.;
%let	LnObsSurvey	=	%getOBS4DATA( inDAT = &procLIB.._PPSS_indat_Survey_&outPri._ , gMode = F );

%*332.	Determine the sample size if there is no STRATA requirement.;
%if	%length(%qsysfunc(compress(&outStrata.,%str( ))))	=	0	%then %do;
	%let	LcSampSize	=	%sysfunc( min( &SampleSize. , &LnObsSurvey. ) );
%end;

%*335.	# of observations by STRATA variables.;
%*There is no need, for it is never used in the procedure.;

%*350.	Basic information of the residual dataset for further sampling.;
%*351.	# of observations.;
%let	LnObsResi	=	%getOBS4DATA( inDAT = &procLIB.._PPSS_indat_Residual_&outPri._ , gMode = F );

%*355.	# of observations by STRATA variables.;
%if	%length(%qsysfunc(compress(&outStrata.,%str( ))))	^=	0	%then %do;
	proc freq
		data=&procLIB.._PPSS_indat_Residual_&outPri._
		noprint
	;
		tables
			&FreqStrata.
			/out=&procLIB.._PPSS_freqResi_&outPri._
		;
	run;
%end;

%*399.	Go to the sampling in the residual dataset, if there is no observation found under current criteria.;
%if	&LnObsSurvey.	=	0	%then %do;
	%*100.	Create a blank dataset to enable further process.;
	data &procLIB.._PPSS_Survey_&outPri._;
		if	0	then do;
			set	&procLIB.._PPSS_indat_Survey_&outPri._;
			output;
		end;
	run;

	%*200.	Number of residual samples to be further extracted.;
	%if	%length(%qsysfunc(compress(&outStrata.,%str( ))))	^=	0	%then %do;
		data &LrSampSize.;
			set &LcSampSize.;
		run;
	%end;
	%else %do;
		%let	LrSampSize	=	&LcSampSize.;
	%end;

	%*900.	Redirect to the step of further sampling.;
	%goto	FurtherSampling;
%end;

%*400.	Sampling.;
proc SurveySelect
	data		=	&procLIB.._PPSS_indat_Survey_&outPri._
	out			=	&procLIB.._PPSS_Survey_&outPri._
	SampSize	=	&LcSampSize.
	&ProcOptOth.
;
	%*100.	Execute by strata if there is any STRATA requirement.;
	%if	%length(%qsysfunc(compress(&outStrata.,%str( ))))	^=	0	%then %do;
		STRATA
			&outStrata.
		%if	%length(%qsysfunc(compress(&StrataOpt.,%str( ))))	^=	0	%then %do;
			/&StrataOpt.
		%end;
		;
	%end;

	%*200.	Execute with control group if there is any CONTROL requirement.;
	%if	%length(%qsysfunc(compress(&ControlVar.,%str( ))))	^=	0	%then %do;
		CONTROL
			&ControlVar.
		;
	%end;

	%*300.	Execute in terms of Size variable if there is any SIZE requirement.;
	%if	%length(%qsysfunc(compress(&SizeVar.,%str( ))))	^=	0	%then %do;
		SIZE
			&SizeVar.
		;
	%end;

	%*400.	Output the ID variables if there is any ID requirement.;
	%if	%length(%qsysfunc(compress(&IDVar.,%str( ))))	^=	0	%then %do;
		ID
			&IDVar.
		;
	%end;
run;

%*500.	Identify the number of samples in the extraction.;
%*510.	If there is no STRATA requirement, we only retrieve the number of observations extracted above.;
%if	%length(%qsysfunc(compress(&outStrata.,%str( ))))	=	0	%then %do;
	%*100.	Number of samples extracted.;
	data &procLIB.._PPSS_Survey_k_&outPri._;
		length	COUNT	8.;
		COUNT	=	%getOBS4DATA( inDAT = &procLIB.._PPSS_Survey_&outPri._ , gMode = F );
		call symputx("LnSurveyRst",COUNT,"L");
	run;

	%*200.	Number of residual samples to be further extracted.;
	%let	LrSampSize	=	%eval( &SampleSize. - &LnSurveyRst. );
%end;

%*520.	Retrieve the frequency of the extraction result if there is STRATA requirement.;
%else %do;
	%*100.	Number of samples extracted.;
	proc freq
		data=&procLIB.._PPSS_Survey_&outPri._
		noprint
	;
		tables
			&FreqStrata.
			/out=&procLIB.._PPSS_Survey_k_&outPri._
		;
	run;

	%*200.	Number of residual samples to be further extracted.;
	proc sql;
		create table &LrSampSize. as (
			select
				min( a.COUNT , sum( 0 , b1.&LvSampSize. , -b2.COUNT ) ) as &LvSampSize.
			%do Si=1 %to &&LnStrata&outPri..;
				,a.&&LeStrata&outPri._&Si..
			%end;
			from &procLIB.._PPSS_freqResi_&outPri._ as a
			left join &LcSampSize. as b1
				on	1
				%do Si=1 %to &&LnStrata&outPri..;
					and	a.&&LeStrata&outPri._&Si..	=	b1.&&LeStrata&outPri._&Si..
				%end;
			left join &procLIB.._PPSS_Survey_k_&outPri._ as b2
				on	1
				%do Si=1 %to &&LnStrata&outPri..;
					and	a.&&LeStrata&outPri._&Si..	=	b2.&&LeStrata&outPri._&Si..
				%end;
			where	calculated &LvSampSize.	^=	0
		);
	quit;
%end;

%*600.	Conduct another round of sampling if the [SampleSize] is not fulfilled.;
%FurtherSampling:
%*601.	Drop the data if there is any existing one.;
%if	%sysfunc(exist(&procLIB.._PPSS_Residual_&outPri._))	%then %do;
	proc sql noprint;
		drop table &procLIB.._PPSS_Residual_&outPri._;
	quit;
%end;

%*610.	Skip current step if the condition of extraction cannot be fulfilled.;
%*611.	[LnObsResi] > 0 : There should be observations in the Residual part of the [inDAT].;
%if		&LnObsResi.	=	0	%then %do;
	%goto	CombineResult;
%end;

%*612.	[LrSampSize], as Residual Sample Size, should have observations or should not be zero.;
%if	%length(%qsysfunc(compress(&outStrata.,%str( ))))	=	0	%then %do;
	%if	&LrSampSize.	=	0	%then %do;
		%goto	CombineResult;
	%end;
%end;
%else %do;
	%if	%getOBS4DATA( inDAT = &LrSampSize. , gMode = F )	=	0	%then %do;
		%goto	CombineResult;
	%end;
%end;

%*650.	Call the same macro again as further sampling.;
%ProcPrioritizedSurveySel(
	inDAT		=	&procLIB.._PPSS_indat_Residual_&outPri._
	,inCriteria	=	&LCriResi.
	,CriDlm		=	&CriDlm.
	,SampleSize	=	&LrSampSize.
	,ProcOptOth	=	&ProcOptOth.
	,outStrata	=	&outStrata.
	,StrataOpt	=	&StrataOpt.
	,ControlVar	=	&ControlVar.
	,SizeVar	=	&SizeVar.
	,IDVar		=	&IDVar.
	,outPriVar	=	&outPriVar.
	,outPri		=	&NextPri.
	,outDAT		=	&procLIB.._PPSS_Residual_&outPri._
	,procLIB	=	&procLIB.
)

%*800.	Combine all extraction results.;
%CombineResult:
data %unquote(&outDAT.);
	set
		&procLIB.._PPSS_Survey_&outPri._(in=i)
	%if	%sysfunc(exist(&procLIB.._PPSS_Residual_&outPri._))	%then %do;
		&procLIB.._PPSS_Residual_&outPri._(in=j)
	%end;
	;
	if	i	then do;
		&outPriVar.	=	&outPri.;
	end;
run;

%EndOfProc:
%mend ProcPrioritizedSurveySel;

/*-Notes- -Begin-* /
%*Taken below as an example:;
%*There is a set of customers distributed in many branches of our bank.;
%*We need to extract 15 sample customers from each branch in terms of below priority:;
%*[1] AUM is over 500K.;
%*[2] The rest in customer base.;
%*If the samples extracted under criteria [1] for any branch are not up to 15,;
%* we continue sampling from the same branch using criteria [2].;
%*The sampling methodology ends for any single branch under one of below situations:;
%*[a] 15 samples are selected.;
%*[b] All customers are selected, given the number of customers in the branch is less than 15.;

%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvOp"
		"D:\SAS\omnimacro\FileSystem"
		"D:\SAS\omnimacro\Stats"
	)
	mautosource
;
%let	L_srcflnm	=	D:\SAS\omnimacro\Stats\Test_PrioritizedSurveySel.xlsx;

%*100.	Import the configuration table.;
PROC IMPORT
	OUT			=	SurveyBase(where=(missing(Branch)=0))
	DATAFILE	=	"&L_srcflnm."
	DBMS		=	EXCEL2010
	REPLACE
;
	SHEET		=	"Sample$";
	GETNAMES	=	YES;
	MIXED		=	NO;
	SCANTEXT	=	YES;
	USEDATE		=	YES;
	SCANTIME	=	YES;
RUN;

%*200.	Branch Level sampling.;
%*210.	Extraction of 15 samples from each Branch.;
%let	L_stpflnm	=	BR_15;
%ProcPrioritizedSurveySel(
	inDAT		=	SurveyBase
	,inCriteria	=	%nrstr(
							Segment	=	"Seg2"
						#	f_AUM_500k
					)
	,CriDlm		=	%str(#)
	,SampleSize	=	15
	,ProcOptOth	=	%str(noprint SelectAll)
	,outStrata	=	Branch
	,outDAT		=	&L_stpflnm.
)

%*220.	Extraction of 10 samples from each Branch without criteria.;
%let	L_stpflnm	=	BR_10_noCond;
%ProcPrioritizedSurveySel(
	inDAT		=	SurveyBase
	,inCriteria	=
	,CriDlm		=	%str(#)
	,SampleSize	=	10
	,ProcOptOth	=	%str(noprint SelectAll)
	,outStrata	=	Branch
	,outDAT		=	&L_stpflnm.
)

%*230.	Extraction of 15 samples from each Branch under single Criteria.;
%*%str(N)OTE: "Single" means there is one criterium, but should extend to all rest observations if it is not fulfilled.;
%let	L_stpflnm	=	BR_15_SingleCond;
%ProcPrioritizedSurveySel(
	inDAT		=	SurveyBase
	,inCriteria	=	%nrstr(
						f_AUM_500k
					)
	,CriDlm		=	%str(#)
	,SampleSize	=	15
	,ProcOptOth	=	%str(noprint SelectAll)
	,outStrata	=	Branch
	,outDAT		=	&L_stpflnm.
)

%*240.	Extraction of 15 samples from each Branch, as controlled by [f_AUM_500k].;
%let	L_stpflnm	=	BR_15_AUM_Control;
%ProcPrioritizedSurveySel(
	inDAT		=	SurveyBase
	,inCriteria	=	%nrstr(
						Segment	=	"Seg2"
					)
	,CriDlm		=	%str(#)
	,SampleSize	=	15
	,ProcOptOth	=	%nrstr(
						noprint
						SelectAll
						method=SYS
						sort=SERP
					)
	,outStrata	=	Branch
	,ControlVar	=	f_AUM_500k
	,outDAT		=	&L_stpflnm.
)

%*241.	Extraction of 15 samples from each Branch, as controlled by [f_AUM_500k].;
%*Another [METHOD] and [SORT] options.;
%let	L_stpflnm	=	BR_15_AUM_Control2;
%ProcPrioritizedSurveySel(
	inDAT		=	SurveyBase
	,inCriteria	=	%nrstr(
						Segment	=	"Seg2"
					)
	,CriDlm		=	%str(#)
	,SampleSize	=	15
	,ProcOptOth	=	%nrstr(
						noprint
						SelectAll
						method=SEQ
						sort=NEST
					)
	,outStrata	=	Branch
	,ControlVar	=	f_AUM_500k
	,outDAT		=	&L_stpflnm.
)

%*250.	Extraction of 20 samples from each Branch, and keep the [ID] of [Segment].;
%let	L_stpflnm	=	BR_20_ID_Segment;
%ProcPrioritizedSurveySel(
	inDAT		=	SurveyBase
	,inCriteria	=	%nrstr(
						f_AUM_500k
					)
	,CriDlm		=	%str(#)
	,SampleSize	=	20
	,ProcOptOth	=	%str(noprint SelectAll)
	,outStrata	=	Branch
	,IDVar		=	Segment
	,outDAT		=	&L_stpflnm.
)

%*300.	Overall sampling.;
%*When there is no STRATA requirement, we cannot use the option [SelectAll], since it causes all the observations to be sampled.;
%*310.	Extraction of 15 samples from the entire database.;
%let	L_stpflnm	=	DB_15;
%ProcPrioritizedSurveySel(
	inDAT		=	SurveyBase
	,inCriteria	=	%nrstr(
							Branch	=	"101"
						and	f_AUM_500k
						#	f_CASA_50k
					)
	,CriDlm		=	%str(#)
	,SampleSize	=	15
	,ProcOptOth	=	%str(noprint)
	,outStrata	=
	,outDAT		=	&L_stpflnm.
)

%*310.	Extraction of 15 samples from the entire database without criteria.;
%let	L_stpflnm	=	DB_15_noCond;
%ProcPrioritizedSurveySel(
	inDAT		=	SurveyBase
	,inCriteria	=
	,CriDlm		=	%str(#)
	,SampleSize	=	15
	,ProcOptOth	=	%str(noprint)
	,outStrata	=
	,outDAT		=	&L_stpflnm.
)

%*330.	Extraction of 20 samples from the entire database under single Criteria.;
%*%str(N)OTE: "Single" means there is one criterium, but should extend to all rest observations if it is not fulfilled.;
%let	L_stpflnm	=	DB_20_SingleCond;
%ProcPrioritizedSurveySel(
	inDAT		=	SurveyBase
	,inCriteria	=	%nrstr(
						f_CASA_50k
					)
	,CriDlm		=	%str(#)
	,SampleSize	=	20
	,ProcOptOth	=	%str(noprint)
	,outStrata	=
	,outDAT		=	&L_stpflnm.
)

%*340.	Extraction of 15 samples from the entire database, as controlled by [f_AUM_500k].;
%let	L_stpflnm	=	DB_15_AUM_Control;
%ProcPrioritizedSurveySel(
	inDAT		=	SurveyBase
	,inCriteria	=	%nrstr(
						Segment	=	"Seg2"
					)
	,CriDlm		=	%str(#)
	,SampleSize	=	15
	,ProcOptOth	=	%nrstr(
						noprint
						method=SYS
						sort=NEST
					)
	,outStrata	=
	,ControlVar	=	f_AUM_500k
	,outDAT		=	&L_stpflnm.
)

/*-Notes- -End-*/