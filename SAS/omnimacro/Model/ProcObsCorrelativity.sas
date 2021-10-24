%macro ProcObsCorrelativity(
	inDAT		=
	,GrpBy		=
	,inKEY		=
	,inVAR		=
	,inMTHD		=
	,procLIB	=	WORK
	,outDAT		=
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to calculate the similarity between each two records in the same data,										|
|	| in terms of the provided methods.																									|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDAT		:	Dataset name in which variables or columns should be searched.														|
|	|GrpBy		:	The BY group to group the result. The input data should be sorted before calling this procedure.					|
|	|inKEY		:	The key list to be identified in the source data.																	|
|	|				Currently variables in this list only affect the output data, while not affect the calculation.						|
|	|inVAR		:	The variable list to be involved in the calculation, default value is all _NUMERIC_ variables.						|
|	|inMTHD		:	The method for the similarity calculation, which is a preset macro led by "uspObsCorr_".							|
|	|				Eg. if the provided method is "CosSim", the corresponding macro "uspRecSim_CosSim" is called.						|
|	|procLIB	:	The working library.																								|
|	|outDAT		:	The output data in the same format as that from the DISTANCE procedure in SAS.										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20150108		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20150123		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Expand the usage from Similarity-only to all correlativities, including DISTANCE.											|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20150205		| Version | 3.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Add verification on [GrpBy] when any argument exists, such as "descending col.+".											|
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
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ErrMcr																															|
|	|	|getOBS4DATA																													|
|	|	|prepStrPatternByCOLList																										|
|	|	|getCOLbyStrPattern																												|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\FileSystem"																						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below series of macros are from "&cdwmac.\Model"																					|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|uspObsCorr_&inMTHD.																											|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*010.	Check parameters.;
%*011.	Identify current processing macro.;
%local
	L_mcrLABEL
	Lohno
;
%let	L_mcrLABEL	=	&sysMacroName.;
%let	Lohno		=	%str(E)RROR: [&L_mcrLABEL.]Process failed due to %str(e)rrors!;

%*012.	Handle the parameter buffer.;
%if	%length(%qsysfunc(compress(&inDAT.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No dataset is provided! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&GrpBy.,%str( ))))	^=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]The procedure will be executed in terms of the BY group.;
%end;

%if	%length(%qsysfunc(compress(&inKEY.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No key is specified in the given data! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&inVAR.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No variable is specified for similarity calculation, all numeric fields are used.;
%end;

%if	%length(%qsysfunc(compress(&inMTHD.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No method is specified for the similarity calculation! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))	=	0	%then	%let	procLIB	=	WORK;

%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No output data is specified! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*090.	Parameters;
%local
	LnOBS
	LstGrp
	FrqGrp
	LstKey
	LstVar
	GRPk
	SUBi
	LfirstArg
	KEYi
	RECi
	COLi
	LnCORR
;
%let	LnOBS	=	0;
%let	LstGrp	=;
%let	FrqGrp	=;
%let	LstKey	=;
%let	LExcl	=;
%let	LstVar	=;

%*100.	Retrieve the number of observations.;
%getOBS4DATA(
	inDAT	=	&inDAT.
	,outVAR	=	LnOBS
)
%let	LnCORR	=	&LnOBS.;

%*120.	Identify all variables in the BY group.;
%if	%length(%qsysfunc(compress(&GrpBy.,%str( ))))	^=	0	%then %do;
	%*100.	Prepare the RegExp to search for the variables provided.;
	%prepStrPatternByCOLList(
		COLlst		=	&GrpBy.
		,chkArg		=	1
		,ArgLst		=	DESCENDING
		,nPTN		=	GnPGrpBy
		,ePTN		=	GePGrpBy
		,OchkArg	=	GAePGrpBy
		,outPTN		=	LstGrp
	)

	%*200.	Retrieve the existing variables indicated by [GrpBy] and mark them by the provided arguments if any.;
	%*GnPGrpBy	:	Global macro variable with the value of Number of Patterns from [GrpBy];
	%do GRPk=1 %to &GnPGrpBy.;
		%*100.	Retrieve all the matching variables for current sub-pattern.;
		%*Here we benefit from below macro in that all the variables retrieved are in VARNUM sequence.;
		%getCOLbyStrPattern(
			inDAT		=	&inDAT.
			,inRegExp	=	&&GePGrpBy&GRPk..
			,exclRegExp	=
			,chkVarTP	=
			,outCNT		=	GprocRX&GRPk.n
			,outELpfx	=	GprocRX&GRPk.e
		)
	%end;

	%*300.	Create an involvement list for FREQ procedure.;
	%do GRPk=1 %to &GnPGrpBy.;
		%do SUBi=1 %to &&GprocRX&GRPk.n.;
			%let	FrqGrp	=	&FrqGrp.*&&GprocRX&GRPk.e&SUBi..;
		%end;
	%end;
	%let	FrqGrp	=	%substr(&FrqGrp.,2);
%end;

%*130.	Retrieve all the fields in the key list.;
%*131.	Prepare the RegExp to search for the variables provided.;
%prepStrPatternByCOLList(
	COLlst	=	&inKEY.
	,outPTN	=	LstKey
)

%*135.	Retrieve all the fields by the given pattern.;
%getCOLbyStrPattern(
	inDAT		=	&inDAT.
	,inRegExp	=	&LstKey.
	,exclRegExp	=
	,chkVarTP	=
	,outCNT		=	GnKeyList
	,outELpfx	=	GeKeyList
)

%*150.	Identify all variables in the VAR list.;
%if	%length(%qsysfunc(compress(&inVAR.,%str( ))))	^=	0	%then %do;
	%*100.	Prepare the RegExp to search for the variables provided.;
	%prepStrPatternByCOLList(
		COLlst	=	&inVAR.
		,outPTN	=	LstVar
	)
%end;

%*190.	Retrieve all the numeric fields.;
%if	%length(%qsysfunc(compress(&GrpBy.,%str( ))))	^=	0	%then %do;
	%*If there is any field in the BY group, we reserve the leading vertical bar.;
	%let	LstGrp	=	|&LstGrp.;
%end;
%getCOLbyStrPattern(
	inDAT		=	&inDAT.
	,inRegExp	=	&LstVar.
	,exclRegExp	=	&LstKey.&LstGrp.
	,chkVarTP	=	n
	,outCNT		=	GnFLDN
	,outELpfx	=	GeFLDN
)

%*200.	Determine the number of fields in the output data in terms of the largest number of records among all BY groups.;
%if	%length(%qsysfunc(compress(&GrpBy.,%str( ))))	^=	0	%then %do;
	%*100.	Retrieve the frequency in terms of the BY group.;
	proc freq
		data=%unquote(&inDAT.)
		noprint
	;
		tables
			&FrqGrp.
			/list
			missing
			out=&procLIB.._RSfreq
		;
	run;

	%*200.	Retrieve the largest number in the frequency table.;
	proc sql
		nowarn
		noprint
	;
		select	max(COUNT)
		into	:LnCORR
		from &procLIB.._RSfreq
		;
	quit;
	%*210.	We assure there is no leading or trailing blank on the value.;
	%let	LnCORR	=	%sysfunc(strip(&LnCORR.));
%end;

%*500.	Calculate the Similarity of each record against all others.;
data %unquote(&outDAT.);
	%*010.	Set the data.;
	set %unquote(&inDAT.);
%if	%length(%qsysfunc(compress(&GrpBy.,%str( ))))	^=	0	%then %do;
	by
	%do GRPk=1 %to &GnPGrpBy.;
		%do SUBi=1 %to &&GprocRX&GRPk.n.;
			%if	&SUBi.	=	1	%then %do;
				%let	LfirstArg	=	&&GAePGrpBy&GRPk..;
			%end;
			%else %do;
				%let	LfirstArg	=;
			%end;

			&LfirstArg.	&&GprocRX&GRPk.e&SUBi.
		%end;
	%end;
	;
%end;

	%*020.	Determine the following process in terms of the BY group.;
	retain	__rec;
%if	%length(%qsysfunc(compress(&GrpBy.,%str( ))))	^=	0	%then %do;
	if	first.&&&&GprocRX&GnPGrpBy.e&&GprocRX&GnPGrpBy.n..	then do;
%end;
%else %do;
	if	_N_	=	1	then do;
%end;
		__rec	=	0;
	end;
		__rec	+	1;

	%*030.	Prepare the record retention.;
	%*arrSeed{}	:	Calculation vector defined in terms of current record.;
	%*arrComp{}	:	The retrospective calculation vectors counting from the first on in current BY group or in;
	%*				 current dataset. arrComp{1,N} represents the retained 1st vector in current BY group or in;
	%*				 current dataset.;
	array
		arrSeed{ &GnFLDN. }
		_temporary_
	;
	array
		arrComp{ &LnCORR., &GnFLDN. }
		_temporary_
	;
	%*This array is to handle the lags across the records;
	array
		arrLag{ &LnCORR., &GnFLDN. }
		_temporary_
	;

	%*We should assure all related fields are NOT missing.;
	%*031.	We set the vector of current record as the Seed and the {__rec}th comparison object.;
	%do	COLi=1	%to	&GnFLDN.;
		arrSeed{        &COLi. }	=	sum( 0, &&GeFLDN&COLi.. );
		arrComp{ __rec, &COLi. }	=	sum( 0, &&GeFLDN&COLi.. );
	%end;

	%*035.	We "retain" all the previous records to current one for comparison.;
	%do	RECi=1	%to	%eval( &LnCORR. - 1 );
		%do	COLi=1	%to	&GnFLDN.;
			arrLag{ &RECi., &COLi. }	=	sum( 0, lag&RECi.( &&GeFLDN&COLi.. ) );
		%end;
	%end;

	%*039.	We prepare the array for comparison.;
	if	__rec	>	1	then do;
		do tmpRec=1 to ( __rec - 1 );
			%do	COLi=1	%to	&GnFLDN.;
				arrComp{ tmpRec, &COLi. }	=	arrLag{ __rec - tmpRec , &COLi. };
			%end;
		end;
	end;

	%*100.	Calculate the similarity.;
	%uspObsCorr_&inMTHD.

	%*900.	Purge.;
	keep
		%if	%length(%qsysfunc(compress(&GrpBy.,%str( ))))	^=	0	%then %do;
			%do GRPk=1 %to &GnPGrpBy.;
				%do SUBi=1 %to &&GprocRX&GRPk.n.;
					&&GprocRX&GRPk.e&SUBi.
				%end;
			%end;
		%end;
		%do	KEYi=1	%to	&GnKeyList.;
			&&GeKeyList&KEYi..
		%end;
	;
run;

%EndOfProc:
%mend ProcObsCorrelativity;