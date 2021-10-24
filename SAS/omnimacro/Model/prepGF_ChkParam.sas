%macro prepGF_ChkParam;
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is for the Parameter Check for all "Get-Function" as models																|
|	|"Get-Function" is a series of "Get" macro comparing an [inDAT] to an [inDB] for specific retrievals.								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20150130		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
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
|	|There should be some required values passed into this macro as below:																|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	LnOBS																															|
|	|	LstGrp																															|
|	|	LVerBar																															|
|	|	LstKey																															|
|	|	LstVar																															|
|	|	LcntGrp																															|
|	|	LGrpQC																															|
|	|	LGrpC																															|
|	|	GRPi																															|
|	|	GRPj																															|
|	|	LcntKey																															|
|	|	LKeyQC																															|
|	|	LKeyC																															|
|	|	KEYi																															|
|	|	KEYj																															|
|	|	RECi																															|
|	|	LVarQC																															|
|	|	LVarC																															|
|	|	COLi																															|
|	|	COLj																															|
|	|	LcSortedByInDB																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ErrMcr																															|
|	|	|getOBS4DATA																													|
|	|	|prepStrPatternByCOLList																										|
|	|	|getCOLbyStrPattern																												|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*local
	LnOBS
	LstGrp
	LVerBar
	LstKey
	LstVar
	LcntGrp
	LGrpQC
	LGrpC
	GRPi
	GRPj
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
;

%let	LnOBS	=	0;
%let	LstGrp	=;
%let	LstKey	=;
%let	LstVar	=;
%let	LGrpQC	=;
%let	LKeyQC	=;
%let	LVarQC	=;
%let	LGrpC	=;
%let	LKeyC	=;
%let	LVarC	=;
%let	LcSortedByInDB	=;
%let	LfSortedInDB	=	0;

%*091.	Should there be BY group, we insert a vertical bar between [LstKey] and [LstGrp] for numeric;
%*       variable search in terms of RegExp.;
%if	%length(%qsysfunc(compress(&GrpBy.,%str( ))))	^=	0	%then %do;
	%let	LVerBar	=	%str(|);
%end;
%else %do;
	%let	LVerBar	=;
%end;

%*012.	Handle the parameter buffer.;
%if	%length(%qsysfunc(compress(&inDAT.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No dataset is provided! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&inDB.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No database is provided! Program is interrupted!;
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

%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))	=	0	%then	%let	procLIB	=	WORK;

%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No output data is specified! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*100.	Retrieve the features of the [inDAT].;
%*110.	Retrieve the number of observations.;
%getOBS4DATA(
	inDAT	=	&inDAT.
	,outVAR	=	LnOBS
)

%*120.	Identify all variables in the BY group.;
%*Supposedly this can be provided with "descending" argument, such as "descending ab".;
%*At present, we should do two things as below:;
%*(1)If the [inDB] is actually sorted in the provided way, we SET the [inDB] directly in that way.;
%*(2)Otherwise, we create a dumm VIEW which pretends to "sort" [inDB] with NO argument, in this case;
%*    , "ab" instead of "descending ab" and SET the VIEW by "ab". This is because that the dummy VIEW;
%*    created from macro "ProcPseudoSort" cannot handle the "descending" argument, or a COMPOSITE key;
%*    like "a descending b".;
%*(3)The presumption for such case is that for analytical purpose, we can discard "descending" orders.;
%*(4)At "Parameter Check" stage, we hence discard all "descending" arguments.;
%if	%length(%qsysfunc(compress(&GrpBy.,%str( ))))	^=	0	%then %do;
	%*100.	Prepare the RegExp to search for the variables provided.;
	%prepStrPatternByCOLList(
		COLlst	=	&GrpBy.
		,chkArg		=	1
		,ArgLst		=	DESCENDING
		,nPTN		=	GnPGrpBy
		,ePTN		=	GePGrpBy
		,OchkArg	=	GAePGrpBy
		,outPTN	=	LstGrp
	)

	%*200.	Retrieve all the fields by the given pattern.;
	%getCOLbyStrPattern(
		inDAT		=	&inDAT.
		,inRegExp	=	&LstGrp.
		,exclRegExp	=
		,chkVarTP	=
		,outCNT		=	GnGrpDat
		,outELpfx	=	GeGrpDat
	)
%end;

%*130.	Retrieve all the fields in the key list.;
%*131.	Prepare the RegExp to search for the variables provided.;
%*Supposedly there should not be "descending" argument present in the list.;
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
	,outCNT		=	GnKeyDat
	,outELpfx	=	GeKeyDat
)

%*150.	Identify all variables in the VAR list.;
%if	%length(%qsysfunc(compress(&inVAR.,%str( ))))	^=	0	%then %do;
	%*100.	Prepare the RegExp to search for the variables provided.;
	%*Supposedly there should not be "descending" argument present in the list.;
	%prepStrPatternByCOLList(
		COLlst	=	&inVAR.
		,outPTN	=	LstVar
	)
%end;

%*190.	Retrieve all the numeric fields.;
%getCOLbyStrPattern(
	inDAT		=	&inDAT.
	,inRegExp	=	&LstVar.
	,exclRegExp	=	&LstKey.&LVerBar.&LstGrp.
	,chkVarTP	=	n
	,outCNT		=	GnFldDat
	,outELpfx	=	GeFldDat
)

%*200.	Retrieve the features of the [inDB].;
%*220.	Identify all variables in the BY group.;
%if	%length(%qsysfunc(compress(&GrpBy.,%str( ))))	^=	0	%then %do;
	%*200.	Retrieve all the fields by the given pattern.;
	%getCOLbyStrPattern(
		inDAT		=	&inDB.
		,inRegExp	=	&LstGrp.
		,exclRegExp	=
		,chkVarTP	=
		,outCNT		=	GnGrpDB
		,outELpfx	=	GeGrpDB
	)

	%*300.	Verify the variables in the BY group for both data.;
	%*Should there be any inconsistency between them, for instance, there are 3 variables as BY group in [inDAT];
	%* while there are only 2 variables found as BY group in [inDB] (in terms of the character string search),;
	%* we should abort the procedure.;
	%let	LcntGrp	=	0;
	%do	GRPi=1	%to	&GnGrpDat.;
		%do	GRPj=1	%to	&GnGrpDB.;
			%if	&&GeGrpDat&GRPi..	=	&&GeGrpDB&GRPj..	%then	%let	LcntGrp	=	%eval( &LcntGrp. + 1 );
		%end;
	%end;
	%if		&GnGrpDat.	^=	&GnGrpDB.
		or	&GnGrpDat.	^=	&LcntGrp.
		or	&GnGrpDB.	^=	&LcntGrp.
		%then %do;
		%put	%str(E)RROR: [&L_mcrLABEL.]Variables defined in BY group for both data are not identical!;
		%put	&Lohno.;
		%ErrMcr
	%end;

	%*400.	Create a list of [GrpBy] with Quotation Marks and Commas connecting each 2 variables.;
	%do	GRPj=1	%to	&GnGrpDB.;
		%let	LGrpQC	=	&LGrpQC.%nrbquote(,"&&GeGrpDB&GRPj..");
		%let	LGrpC	=	&LGrpC.%nrbquote(,&&GeGrpDB&GRPj..);
	%end;
	%let	LGrpQC	=	%substr(&LGrpQC.,2);
	%let	LGrpC	=	%substr(&LGrpC.,2);
%end;

%*230.	Retrieve all the fields in the key list.;
%*235.	Retrieve all the fields by the given pattern.;
%getCOLbyStrPattern(
	inDAT		=	&inDB.
	,inRegExp	=	&LstKey.
	,exclRegExp	=
	,chkVarTP	=
	,outCNT		=	GnKeyDB
	,outELpfx	=	GeKeyDB
)

%*238.	Verify the variables in the key list for both data.;
%*Should there be any inconsistency between them, for instance, there are 3 variables as keys in [inDAT];
%* while there are only 2 variables found as keys in [inDB] (in terms of the character string search),;
%* we should abort the procedure.;
%let	LcntKey	=	0;
%do	KEYi=1	%to	&GnKeyDat.;
	%do	KEYj=1	%to	&GnKeyDB.;
		%if	&&GeKeyDat&KEYi..	=	&&GeKeyDB&KEYj..	%then	%let	LcntKey	=	%eval( &LcntKey. + 1 );
	%end;
%end;
%if		&GnKeyDat.	^=	&GnKeyDB.
	or	&GnKeyDat.	^=	&LcntKey.
	or	&GnKeyDB.	^=	&LcntKey.
	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]Variables defined in key list for both data are not identical!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*290.	Retrieve all the numeric fields.;
%getCOLbyStrPattern(
	inDAT		=	&inDB.
	,inRegExp	=	&LstVar.
	,exclRegExp	=	&LstKey.&LVerBar.&LstGrp.
	,chkVarTP	=	n
	,outCNT		=	GnFldDB
	,outELpfx	=	GeFldDB
)

%*298.	Retrieve the common numeric variables in both data for correlativity calculation.;
%let	GnFLDN	=	0;
%do	COLi=1	%to	&GnFldDat.;
	%do	COLj=1	%to	&GnFldDB.;
		%if	&&GeFldDat&COLi..	=	&&GeFldDB&COLj..	%then %do;
			%let	GnFLDN	=	%eval( &GnFLDN. + 1 );
			%global	GeFLDN&GnFLDN.;
			%let	GeFLDN&GnFLDN.	=	&&GeFldDB&COLj..;
		%end;
	%end;
%end;
%if	&GnFLDN.	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]There is no common numeric field found for both data!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if		&GnFldDat.	^=	&GnFldDB.
	or	&GnFldDat.	^=	&GnFLDN.
	or	&GnFldDB.	^=	&GnFLDN.
	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Numeric variables for both data are not identical, program processes common ones.;
	%put	%str(N)OTE: [&L_mcrLABEL.][GnFldDat = &GnFldDat.][GnFldDB = &GnFldDB.][GnFLDN = &GnFLDN.];
%end;

%EndOfProc:
%mend prepGF_ChkParam;