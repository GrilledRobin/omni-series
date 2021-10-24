%macro prepGF_SortInDB;
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is for the establishment of dummy SORTED view of [inDB] for all "Get-Function" as models								|
|	|"Get-Function" is a series of "Get" macro comparing an [inDAT] to an [inDB] for specific retrievals.								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20150203		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
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
|	|At present, any COMPOSITE sort cannot be applied to a VIEW. Hence we can only "sort" the [inDB] in ascending						|
|	| order as by default.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|getCOLbyStrPattern																												|
|	|	|MarkArg4BYVAR																													|
|	|	|ProcPseudoSort																													|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\FileSystem"																						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|FS_ATTRC																														|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*100.	Retrieve the existing variables indicated by [GrpBy] and mark them by the provided arguments if any.;
%*GnPGrpBy	:	Global macro variable with the value of Number of Patterns from [GrpBy];
%do GRPk=1 %to &GnPGrpBy.;
	%*100.	Retrieve all the matching variables for current sub-pattern.;
	%*Here we benefit from below macro in that all the variables retrieved are in VARNUM sequence.;
	%getCOLbyStrPattern(
		inDAT		=	&inDB.
		,inRegExp	=	&&GePGrpBy&GRPk..
		,exclRegExp	=
		,chkVarTP	=
		,outCNT		=	GgfRX&GRPk.n
		,outELpfx	=	GgfRX&GRPk.e
	)
%end;

%*400.	Retrieve the sort sequence in terms of the BY statement should the [inDB] is sorted.;
%let	LcSortedByInDB	=	%FS_ATTRC(inDAT=&inDB.,inATTR=SORTEDBY,outVAR=,gMode=F);
%*Any "DESCENDING" argument will be kept here.;

%*500.	If the [inDB] is properly sorted, we skip creating the dummy view.;
%if	%length(%qsysfunc(compress(&LcSortedByInDB.,%str( ))))	^=	0	%then %do;
	%*100.	Retrieve all the BY variables from [inDB].;
	%MarkArg4BYVAR(
		inlst		=	&LcSortedByInDB.
		,chkArg		=	1
		,ArgLst		=	DESCENDING
		,nVarTTL	=	GnByVarDB
		,eVarPfx	=	GeByVarDB
		,OchkArg	=	GAeByVarDB
	)

	%*200.	Verify if ALL the variables of [GrpBy] exist in above list.;
	%*This step represents that we compare the list to be sorted ([GrpBy]) with that already sorted ([LcSortedByInDB]);
	%*To complete this, we need to assure each variable, as well as its preceding argument, in the provided list;
	%* is the same as that already in the SORTED data.;
	%*E.g. In the given list there is one item [descending b], while the [inDB] has a sorted variable [b] (ascending);
	%* , then we should consider this as unmatching and should create a view to "sort" it by [descending b].;
	%*E.g. The given criteria is [descending b], while the [inDB] is sorted in [a descending b], then we consider;
	%* this as identical, for we are able to SET the data BY DESCENDING B only (see SAS Language Dictionary).;
	%let	LcntBY	=	0;
	%do GRPk=1 %to &GnPGrpBy.;
		%do SUBi=1 %to &&GgfRX&GRPk.n.;
			%if	&SUBi.	=	1	%then %do;
				%let	LfirstArg	=	&&GAePGrpBy&GRPk..;
			%end;
			%else %do;
				%let	LfirstArg	=;
			%end;
			%do	BYi=1	%to	&GnByVarDB.;
				%if		&&GeByVarDB&BYi..	=	&&GgfRX&GRPk.e&SUBi.
					and	&&GAeByVarDB&BYi..	=	&LfirstArg.
					%then %do;
					%let	LcntBY	=	%eval( &LcntBY. + 1 );
				%end;
			%end;
		%end;
	%end;
	%*if [LcntBY] equals to [GnGrpDB], then ALL the variables of [GrpBy] exist in [GnByVarDB].;
	%if	&LcntBY.	=	&GnGrpDB.	%then %do;
		%put	%str(N)OTE: [&L_mcrLABEL.]Database [&inDB.] is properly sorted, no dummy view is created.;
		%let	LfSortedInDB	=	1;
		%goto	EndOfCrView;
	%end;
%end;

%*900.	Create Dummy View to pretend as if the [inDB] were properly sorted.;
%*910.	Declaration.;
%put	%str(N)OTE: [&L_mcrLABEL.]Database [&inDB.] is not properly sorted, a dummy view is created for facilitation.;
%if	&sysver.	<	9.2	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]SAS version [9.2] or later is required to support tag "multidata" in Hash Object!;
	%put	%str(N)OTE: [&L_mcrLABEL.]Otherwise the composit key [GrpBy-inKEY] should be unique in [inDB]!;
%end;

%*950.	Prepare the view.;
%ProcPseudoSort(
	inDAT		=	&inDB.
	,ByVar		=	%do GRPk=1 %to &GnPGrpBy.;
						%do SUBi=1 %to &&GgfRX&GRPk.n.;
							&&GgfRX&GRPk.e&SUBi.
						%end;
					%end;
					%if	&sysver.	<	9.2	%then %do;
						%do	KEYj=1	%to	&GnKeyDB.;
							&&GeKeyDB&KEYj..
						%end;
					%end;
	,procLIB	=	&procLIB.
	,outVIEW	=	&procLIB.._gf_VInDB
)
%EndOfCrView:

%EndOfProc:
%mend prepGF_SortInDB;