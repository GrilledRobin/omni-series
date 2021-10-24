%macro OrgTree_AllChains(
	inDAT		=
	,VarUpper	=
	,VarLower	=
	,ChainTop	=	ChainTop
	,ChainBtm	=	ChainBtm
	,ChainLvl	=	ChainLvl
	,outDAT		=
	,procLIB	=	WORK
	,mNest		=	0
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to identify all the Chains, starting from any nodes to their correspondent ending leaves, from the			|
|	| Organizational Tree.																												|
|	|Each Chain as grouped by the [ChainTop] and [ChainBtm] denotes a full path from [ChainTop] to one of its ending leaves.			|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Concept:																															|
|	|[1]	Retrieve all the end-to-end branches in the entire tree [d1], via the macro [OrgTree_EndToEndChain].						|
|	|[2]	Remove the DIRECT linkages from the roots in the original dataset [d1] and create a new input dataset [d2].					|
|	|[3]	Repeat step [1] and [2] upon the new dataset [d2], via the macro [OrgTree_EndToEndChain], until all linkages in [d2] are	|
|	|		 direct linkages from the roots to the leaves.																				|
|	|[4]	Set together all datasets created in all step [1]s as the final result.														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDAT		:	Dataset storing the Organizational Tree linkages.																	|
|	|VarUpper	:	Variable that represents the upper node for the link. It must be of the same data definition as [VarLower].			|
|	|VarLower	:	Variable that represents the lower node for the link. It must be of the same data definition as [VarUpper].			|
|	|ChainTop	:	The top of the Chain.																								|
|	|ChainBtm	:	The bottom of the Chain.																							|
|	|ChainLvl	:	The Level of current linkage within a single chain as grouped by [ChainTop] and [ChainBtm].							|
|	|outDAT		:	The output result.																									|
|	|procLIB	:	The working library.																								|
|	|mNest		:	[M]th Level of Nesting Call of the same macro, which is zero at the first call.										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20170716		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
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
|	| Date |	20170829		| Version |	2.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the retrieval of attributes of [__TreeRoot] by the statement [if 0 then set ...], to save extra RAM effort.			|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180311		| Version |	2.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180401		| Version |	2.30		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Introduce the local macro variable [HasNextL] to determine whether there is further chain.									|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Each observation in the input dataset should represent ONLY ONE link from the upper node to its lower one.							|
|	|There are 5 variables in the output result:																						|
|	|[VarUpper]	:	Which is the same variable in the input dataset.																	|
|	|[VarLower]	:	Which is the same variable in the input dataset.																	|
|	|[ChainTop]	:	Defines the top of current Chain.																					|
|	|[ChainBtm]	:	Defines the bottom of current Chain.																				|
|	|[ChainLvl]	:	Stands for the position of current linkage (from [VarUpper] to [VarLower]) inside current Chain.					|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ErrMcr																															|
|	|	|getOBS4DATA																													|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\OrgResearch"																						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|OrgTree_GetRoots																												|
|	|	|OrgTree_EndToEndChain																											|
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
%if	%length(%qsysfunc(compress(&inDAT.,%str( ))))		=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No dataset is provided! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%length(%qsysfunc(compress(&ChainTop.,%str( ))))	=	0	%then	%let	ChainTop	=	ChainTop;
%if	%length(%qsysfunc(compress(&ChainBtm.,%str( ))))	=	0	%then	%let	ChainBtm	=	ChainBtm;
%if	%length(%qsysfunc(compress(&ChainLvl.,%str( ))))	=	0	%then	%let	ChainLvl	=	ChainLvl;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))		=	0	%then	%let	procLIB		=	WORK;

%*013.	Define the local environment.;
%local
	OptNotes	OptSource	OptSource2	OptMLogic	OptSymGen	OptMPrint	OptInOper
	NextL		HasNextL
;
%let	NextL		=	%eval( &mNest. + 1 );
%let	HasNextL	=	1;

%*016.	Switch off the system options to reduce the LOG size.;
%if %sysfunc(getoption( notes ))		=	NOTES		%then	%let	OptNotes	=	1;	%else	%let	OptNotes	=	0;
%if %sysfunc(getoption( source ))		=	SOURCE		%then	%let	OptSource	=	1;	%else	%let	OptSource	=	0;
%if %sysfunc(getoption( source2 ))		=	SOURCE2		%then	%let	OptSource2	=	1;	%else	%let	OptSource2	=	0;
%if %sysfunc(getoption( mlogic ))		=	MLOGIC		%then	%let	OptMLogic	=	1;	%else	%let	OptMLogic	=	0;
%if %sysfunc(getoption( symbolgen ))	=	SYMBOLGEN	%then	%let	OptSymGen	=	1;	%else	%let	OptSymGen	=	0;
%if %sysfunc(getoption( mprint ))		=	MPRINT		%then	%let	OptMPrint	=	1;	%else	%let	OptMPrint	=	0;
%if %sysfunc(getoption( minoperator ))	=	MINOPERATOR	%then	%let	OptInOper	=	1;	%else	%let	OptInOper	=	0;
%*The default value of the system option [MINDELIMITER] is WHITE SPACE, given the option [MINOPERATOR] is on.;
options nonotes nosource nosource2 nomlogic nosymbolgen nomprint minoperator;

%*018.	Define the global environment.;

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in traditional SAS syntax colors.;
%macro dummy; %mend dummy;

%*100.	Retrieve the roots of current tree.;
%OrgTree_GetRoots(
	inDAT		=	&inDAT.
	,VarUpper	=	&VarUpper.
	,VarLower	=	&VarLower.
	,outVAR		=	__TreeRoot
	,outDAT		=	&procLIB.._ot_ac_root&mNest.
	,procLIB	=	&procLIB.
)

%*200.	Retrieve all full branches in current tree.;
%*We assure [&procLIB.._ot_ac_leaf] is NOT replaced, for the leaves are always the same for any sub-tree.;
%OrgTree_EndToEndChain(
	inDAT		=	&inDAT.
	,VarUpper	=	&VarUpper.
	,VarLower	=	&VarLower.
	,ChainTop	=	&ChainTop.
	,ChainBtm	=	&ChainBtm.
	,ChainLvl	=	&ChainLvl.
	,inLeafDat	=	&procLIB.._ot_ac_leaf
	,inLeafVar	=	__TreeLeaf
	,outDAT		=	&procLIB.._ot_ac_Chain&mNest.
	,procLIB	=	&procLIB.
)

%*300.	Determine whether to leave the recursive call by verifying whether there is only Level-1 in above Chain dataset.;
%if	%getOBS4DATA( inDAT = %nrbquote(&procLIB.._ot_ac_Chain&mNest.(where=(&ChainLvl.^=1))) , gMode = F )	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No further tree is identified.;
	%let	HasNextL	=	0;
	%goto	EndOfSearch;
%end;

%*400.	Remove the roots from current tree and create a new input dataset.;
data &procLIB.._ot_ac_rest&mNest.;
	%*100.	Set the input dataset.;
	set	%unquote(&inDAT.);

	%*200.	Prepare the HASH object to load the roots.;
	if	_N_	=	1	then do;
		if	0	then	set	&procLIB.._ot_ac_root&mNest.(keep=__TreeRoot);
		dcl	hash	hDirSup(dataset:"&procLIB.._ot_ac_root&mNest.",hashexp:16);
		hDirSup.DefineKey("__TreeRoot");
		hDirSup.DefineData("__TreeRoot");
		hDirSup.DefineDone();
	end;
	call missing(__TreeRoot);

	%*300.	Only output if current [VarUpper] does not act as [__TreeRoot].;
	if	hDirSup.check(key:&VarUpper.)	^=	0	then do;
		output;
	end;

	%*900.	Purge.;
	drop
		__TreeRoot
	;
run;

%*500.	Call the same macro to retrieve all Chains from the rest of the tree.;
%OrgTree_AllChains(
	inDAT		=	&procLIB.._ot_ac_rest&mNest.
	,VarUpper	=	&VarUpper.
	,VarLower	=	&VarLower.
	,ChainTop	=	&ChainTop.
	,ChainBtm	=	&ChainBtm.
	,ChainLvl	=	&ChainLvl.
	,outDAT		=	&procLIB.._ot_ac_rest_chain&mNest.
	,procLIB	=	&procLIB.
	,mNest		=	&NextL.
)

%*590.	Mark the end of the recursive call.;
%EndOfSearch:

%*700.	Set the very first Chain dataset together with further Chain datasets if any.;
data %unquote(&outDAT.);
	set
		&procLIB.._ot_ac_Chain&mNest.
	%if	&HasNextL.	=	1	%then %do;
		&procLIB.._ot_ac_rest_chain&mNest.
	%end;
	;
run;

%EndOfProc:
%*Restore the system options.;
options
%if	&OptNotes.		=	1	%then %do;	NOTES		%end;	%else %do;	NONOTES			%end;
%if	&OptSource.		=	1	%then %do;	SOURCE		%end;	%else %do;	NOSOURCE		%end;
%if	&OptSource2.	=	1	%then %do;	SOURCE2		%end;	%else %do;	NOSOURCE2		%end;
%if	&OptMLogic.		=	1	%then %do;	MLOGIC		%end;	%else %do;	NOMLOGIC		%end;
%if	&OptSymGen.		=	1	%then %do;	SYMBOLGEN	%end;	%else %do;	NOSYMBOLGEN		%end;
%if	&OptMPrint.		=	1	%then %do;	MPRINT		%end;	%else %do;	NOMPRINT		%end;
%if	&OptInOper.		=	1	%then %do;	MINOPERATOR	%end;	%else %do;	NOMINOPERATOR	%end;
;
%mend OrgTree_AllChains;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvOp"
		"D:\SAS\omnimacro\OpsResearch"
	)
	mautosource
;

%*100.	Create sample data.;
data test;
	u	=	"a1";	l	=	"b1";	output;
	u	=	"b1";	l	=	"c1";	output;
	u	=	"b1";	l	=	"c2";	output;

	u	=	"a1";	l	=	"b2";	output;

	u	=	"a1";	l	=	"b3";	output;
	u	=	"b3";	l	=	"c3";	output;
	u	=	"c3";	l	=	"d1";	output;
run;

%*200.	Calculation.;
%OrgTree_AllChains(
	inDAT		=	test
	,VarUpper	=	u
	,VarLower	=	l
	,ChainTop	=	ChainTop
	,ChainBtm	=	ChainBtm
	,ChainLvl	=	ChainLvl
	,outDAT		=	cnt
	,procLIB	=	WORK
	,mNest		=	0
)

/*-Notes- -End-*/