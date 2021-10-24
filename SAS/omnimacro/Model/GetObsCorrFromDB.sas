%macro GetObsCorrFromDB(
	inDAT		=
	,inDB		=
	,GrpBy		=
	,inKEY		=
	,inVAR		=
	,inMTHD		=
	,inScale	=	%nrbquote( ObsSim > 0 )
	,nFound		=
	,procLIB	=	WORK
	,outDAT		=
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to calculate the correlativity between each record in the sample data and									|
|	| all the records in the Database in terms of the provided methods.																	|
|	|Check "#REF-001" for known limits.																									|
|	|Check "#REF-010" for sample usage.																									|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDAT		:	Dataset name as the provided samples.																				|
|	|inDB		:	Dataset name as the comparison base.																				|
|	|GrpBy		:	The BY group to group the result. The input data should be sorted before calling this function.						|
|	|				The sort sequence, however, has no impact to the calculation.														|
|	|				i.e. if the [inDAT] is sorted by [b, a], while VARNUM(a)=1 and VARNUM(b)=2, the program can							|
|	|				 still set the [inDAT] by [a, b].																					|
|	|inKEY		:	The (clustered) keys of the source data.																			|
|	|				Currently variables in this list only affect the output data, while not affect the calculation.						|
|	|inVAR		:	The variable list to be involved in the calculation, default value is all _NUMERIC_ variables.						|
|	|inMTHD		:	The method for the similarity calculation, which is a preset macro led by "usgfObsSim_".							|
|	|				Eg. if the provided method is "CosSim", the corresponding macro "usgfObsSim_CosSim" is called.						|
|	|inScale	:	The certain scale to control the output, i.e. "ObsSim > 0.9" or " ObsDist < 1000"									|
|	|nFound		:	The max number of the observations that are found as of the certain scale of correlativity to						|
|	|				 each single observation in the sample data.																		|
|	|				"nFound = 0" means getting all observations in the [inDB].															|
|	|procLIB	:	The working library.																								|
|	|outDAT		:	The output data.																									|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20150128		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20150202		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |As it is less likely that the [inDB] is sorted due to the size, the procedure should be able to handle						|
|	|      | the unsorted one by creating a dummy SORTED view for [inDB].																|
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
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|This macro can retrieve a subset from the [inDB], which contains the observations with below features:								|
|	|(1)An additional field [K_ObsOriginal] representing the {N}th seed observation in the [inDAT]										|
|	|(2)An additional field [ObsSim] or [ObsDist] (the name is on behalf of [inMTHD]) representing the correlativity					|
|	| between the {N}th seed observation in the [inDAT] and the current observation in the [inDB]										|
|	|(3)There are at most [nFound] observations with their correlativity to each seed observation in the								|
|	| scale of [inScale] (e.g. "Sim > 90%" or "Dist < 1000") in terms of [inMTHD]														|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|To get the most accuracy, it is recommended to prune away the VARIABLES which cause the large variance across						|
|	| the variables listed in [inVAR], if it is intended to calculate the SIMILARITY between observations.								|
|	|For instance, there are 10 variables in [inVAR], among which one has an average value (over the observations)						|
|	| of 10000, while the other 9 have average values between -100 to 100. To use this procedure, please remove							|
|	| the certain one before calculating the SIMILARITY. However, if a DISTANCE is to be calculated, that variable						|
|	| can be involved.																													|
|	|This is because that during SIMILARITY calculation, there could possibly be a calculation of VARIANCE across						|
|	| the provided variables. If some of the variables hold values that are far different from others, they lead to						|
|	| large variance and thus reduce the sensivity of the perceptron.																	|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|	|ErrMcr																															|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\FileSystem"																						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below series of macros are from "&cdwmac.\Model"																					|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|prepGF_ChkParam																												|
|	|	|prepGF_SortInDB																												|
|	|	|prepGF_ReFmtInDAT																												|
|	|	|prepGF_HashInDAT																												|
|	|	|usgfObsCorr_&inMTHD.																											|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*010.	Check input buffers.;
%*011.	Identify current processing macro.;
%local
	L_mcrLABEL
	Lohno
;
%let	L_mcrLABEL	=	&sysMacroName.;
%let	Lohno		=	%str(E)RROR: [&L_mcrLABEL.]Process failed due to %str(e)rrors!;

%*012.	Handle the parameter buffer for current function.;
%if	%length(%qsysfunc(compress(&inMTHD.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No method is specified for the similarity calculation! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&inScale.,%str( ))))	=	0	%then	%let	inScale	=	1;

%if	%length(%qsysfunc(compress(&nFound.,%str( ))))	=	0	%then	%let	nFound	=	0;
%if	%length(%qsysfunc(compress(&nFound.),0,d))		^=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.][nFound=&nFound.] should be set as numeric! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;
%*Remove the leading zeros.;
%let	nFound	=	%eval( &nFound. + 0 );

%*090.	Parameters;
%global
	GnFLDN
;
%local
	LnOBS
	LstGrp
	LVerBar
	LstKey
	LstVar
	LcntBY
	LcntGrp
	LGrpQC
	LGrpC
	BYi
	GRPi
	GRPj
	GRPk
	SUBi
	LfirstArg
	LcntKey
	LKeyQC
	LKeyC
	KEYi
	KEYj
	RECi
	LVarQC
	LVarC
	COLi
	COLj
	LcSortedByInDB
	LfSortedInDB
;

%*100.	Check and prepare parameters.;
%prepGF_ChkParam

%*200.	Check the SORT status of [inDB] and create proper SORTED view if necessary.;
%if	%length(%qsysfunc(compress(&GrpBy.,%str( ))))	^=	0	%then %do;
	%let	LfSortedInDB	=	0;
	%prepGF_SortInDB
%end;
%else %do;
	%let	LfSortedInDB	=	1;
%end;

%*300.	Reformat the [inDAT] as preparation.;
%prepGF_ReFmtInDAT

%*500.	Calculate the Correlativity.;
data &outDAT.;
	%*001.	Initialize the counters for [inDAT].;
	if	0	then	set	&procLIB.._gf_indat;
	array
		arrCNT{ &LnOBS. }
		_temporary_
		(
			%do	RECi=1	%to	&LnOBS.;
				0
			%end;
		)
	;

	%*100.	Hash the [inDAT] to avoid the MERGE process.;
	%prepGF_HashInDAT

	%*300.	Calculate the Correlativity.;
	do	_n_	=	1	by	1	until	( EOD );
		%*010.	If the result for every single observation in [inDAT] reaches [nFound], we quit the entire process.;
		%*This is to minimize the system processing time when [inDB] is extremely large.;
	%if	&nFound.	^=	0	%then %do;
			___goc_tcnt	=	0;
		%do	RECi=1	%to	&LnOBS.;
			___goc_tcnt	+	( arrCNT{ &RECi. } = &nFound. );
		%end;
		if	___goc_tcnt	=	&LnOBS.	then do;
			put	"%str(N)OTE: [&L_mcrLABEL.]The result is full hence the procedure is to stop.";
			stop;
		end;
	%end;

		%*100.	Set the [inDB].;
		set
		%if	&LfSortedInDB.	=	1	%then %do;
			&inDB.
		%end;
		%else %do;
			&procLIB.._gf_VInDB
		%end;
			end=EOD
		;
	%if	%length(%qsysfunc(compress(&GrpBy.,%str( ))))	^=	0	%then %do;
		%*Here we have to take the sequence of the variable list for granted.;
		by
		%do GRPk=1 %to &GnPGrpBy.;
			%do SUBi=1 %to &&GgfRX&GRPk.n.;
				%if	&SUBi.	=	1	%then %do;
					%let	LfirstArg	=	&&GAePGrpBy&GRPk..;
				%end;
				%else %do;
					%let	LfirstArg	=;
				%end;

				%if	&LfSortedInDB.	=	1	%then %do;
					&LfirstArg.
				%end;
					&&GgfRX&GRPk.e&SUBi.
			%end;
		%end;
		;
	%end;

		%*200.	Should current observation does not match any group as in [inDAT], we skip it.;
	%if	%length(%qsysfunc(compress(&GrpBy.,%str( ))))	^=	0	%then %do;
		rcGB	=	hGrpByVar.find();
		if	rcGB	^=	0	then do;
			goto	EndOfObs;
		end;
	%end;

		%*300.	Handle each observation in current group.;
		%*310.	Retrieve the hash in [inDAT] that stores the very earliest record for GrpBy.;
		rcHB	=	hiByVar.first();

		%*400.	Loop each record in current group.;
		do while ( rcHB = 0 );
			%*001.	Retrieve the specified observation from [inDAT].;
			%*In the Hashed [inDAT], we only kept the necessary fields to prevent large RAM consumption.;
			%*Hence we should set the data for the retrieval of the [inVAR].;
			RID	=	K_ObsOriginal;
			set &procLIB.._gf_indat point=RID;

			%*100.	Count current result.;
			%*110.	Count for each "K_ObsOriginal" in [inDAT].;
			%*%str(N)OTE: The reason why it is put at the beginning of the loop is that we should consider the time consumption.;
			arrCNT{ K_ObsOriginal }	+	1;

			%*150.	Ensure the number of outputs is ceiled at [nFound];
		%if	&nFound.	^=	0	%then %do;
			if	arrCNT{ K_ObsOriginal }	>	&nFound.	then do;
				%*The count needs to be reversed, as it has been augmented at the beginning of the loop.;
				arrCNT{ K_ObsOriginal }	+	(-1);

				%*The observation is to be abandoned.;
				goto	EndOfCorr;
			end;
		%end;

			%*200.	Calculate the similarity.;
			%usgfObsCorr_&inMTHD.

			%*500.	Verify the scale of the Correlativity.;
			if	not	( &inScale. )	then do;
				%*The count needs to be reversed, as it has been augmented at the beginning of the loop.;
				arrCNT{ K_ObsOriginal }	+	(-1);

				%*The observation is to be abandoned.;
				goto	EndOfCorr;
			end;

			%*700.	Output the calculation result.;
			output;

			%*800.	Mark the end of the calculation for current observation.;
			EndOfCorr:

			%*900.	Retrieve the next group.;
			rcHB	=	hiByVar.next();

		%*End of DO WHILE loop.;
		end;

		%*800.	Mark the end of current observation.;
	%if	%length(%qsysfunc(compress(&GrpBy.,%str( ))))	^=	0	%then %do;
		EndOfObs:
	%end;

	%*End of the SET statement.;
	end;

	%*800.	Stop the current step, for there is a SET statement option "POINT=" used.;
	stop;

	%*900.	Purge.;
	%*Here we keep all the identified numeric variables from the [inDB] to reserve the data format.;
	keep
			K_ObsOriginal
	%if	%length(%qsysfunc(compress(&GrpBy.,%str( ))))	^=	0	%then %do;
		%do	GRPj=1	%to	&GnGrpDB.;
			&&GeGrpDB&GRPj..
		%end;
	%end;
		%do	KEYj=1	%to	&GnKeyDB.;
			&&GeKeyDB&KEYj..
		%end;
		%do	COLj=1	%to	&GnFldDB.;
			&&GeFldDB&COLj..
		%end;
	;
run;

%EndOfProc:
%mend GetObsCorrFromDB;

/*#REF-001 Begin* /
Known Limits:
[01] Given below condition, the procedure may fail as the dummy view is improperly created.
(1)[inDB]=aa (Sort Explicitly : _NONE_)
(2)In [inDB], VARNUM(a1) = 2, VARNUM(a2) = 1
(3)[GrpBy]=a:
/*#REF-001 End*/

/*#REF-010 Begin* /
Sample Usage:
%GetObsCorrFromDB(
	inDAT		=	smpl
	,inDB		=	db
	,GrpBy		=	%nrbquote(C_SC: D.+)
	,inKEY		=	C_PO_PW
	,inVAR		=
	,inMTHD		=	CosSim
	,inScale	=	%nrbquote( abs(ObsSim) < 0.1 )
	,nFound		=	7
	,procLIB	=	WORK
	,outDAT		=	bb
)

%GetObsCorrFromDB(
	inDAT		=	smpl2
	,inDB		=	db2
	,GrpBy		=	C_SC:
	,inKEY		=	C_PO_PW
	,inVAR		=	A_\d+
	,inMTHD		=	EuclidDist
	,inScale	=	%nrbquote( abs(ObsDist) < 1000000 )
	,nFound		=	5
	,procLIB	=	WORK
	,outDAT		=	dd4
)
/*#REF-010 End*/