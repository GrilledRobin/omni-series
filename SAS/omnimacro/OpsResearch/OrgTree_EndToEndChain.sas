%macro OrgTree_EndToEndChain(
	inDAT		=
	,VarUpper	=
	,VarLower	=
	,ChainTop	=	ChainTop
	,ChainBtm	=	ChainBtm
	,ChainLvl	=	ChainLvl
	,inLeafDat	=	TreeLeaf
	,inLeafVar	=	TreeLeaf
	,outDAT		=
	,procLIB	=	WORK
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to create the end-to-end branches from the Organizational Tree.												|
|	|Each branch as grouped by the [ChainTop] and [ChainBtm] denotes a full path from [ChainTop] to one of its farthest subordinates.	|
|	|In a one-to-many Organizational Tree, only the Leaf (without any subordinates attached to it) can define a unique branch to the	|
|	| top, hence this procedure traces the branches starting from the Leaves, instead of from the roots.								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDAT		:	Dataset storing the Organizational Tree linkages.																	|
|	|VarUpper	:	Variable that represents the upper node for the link. It must be of the same data definition as [VarLower].			|
|	|VarLower	:	Variable that represents the lower node for the link. It must be of the same data definition as [VarUpper].			|
|	|ChainTop	:	The top of the Chain.																								|
|	|ChainBtm	:	The bottom of the Chain.																							|
|	|ChainLvl	:	The Level of current linkage within a single chain as grouped by [ChainTop] and [ChainBtm].							|
|	|inLeafDat	:	The dataset that contains all Leaves for the [inDAT].																|
|	|				(This parameter is Optional)																						|
|	|inLeafVar	:	The variable name in the Leaf Dataset that denotes the values of Leaves in the [inDAT].								|
|	|				(This parameter is Optional)																						|
|	|				There SHOULD NOT be duplicates for this variable.																	|
|	|outDAT		:	The output result.																									|
|	|procLIB	:	The working library.																								|
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
|	| Date |	20180311		| Version |	2.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
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
|	|	|OrgTree_GetLeaves																												|
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
%if	%length(%qsysfunc(compress(&inLeafDat.,%str( ))))	=	0	%then	%let	inLeafDat	=	TreeLeaf;
%if	%length(%qsysfunc(compress(&inLeafVar.,%str( ))))	=	0	%then	%let	inLeafVar	=	TreeLeaf;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))		=	0	%then	%let	procLIB		=	WORK;

%*013.	Define the local environment.;
%local
	OptNotes	OptSource	OptSource2	OptMLogic	OptSymGen	OptMPrint	OptInOper
	TreeID		LeafID		TreeTyp		LeafTyp		TreeLen		LeafLen
	DSID		DSrc
	vNumUpper	vNumLower
	errMsg		errLeaf
	outTyp		outFmt		outLen
;
%let	errMsg	=	0;
%let	errLeaf	=	0;

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

%*100.	Ensure the existence of the Leaf Dataset.;
%*110.	Verify the eixstence.;
%if	%sysfunc(exist(&inLeafDat.))	=	0	%then %do;
	%*100.	Issue a message in the LOG.;
	%put	%str(N)OTE: [&L_mcrLABEL.]Tree Leaf dataset [inLeafDat=&inLeafDat.] does not exist.;

	%*200.	Set the switch on.;
	%let	errLeaf	=	1;

	%*900.	Go to the creation step.;
	%goto	CrLeaf;
%end;

%*120.	Verify whether the provided [inLeafVar] is of the same definition as [VarLower].;
%*121.	Open both datasets.;
%let	TreeID	=	%sysfunc(open(&inDAT.));
%let	LeafID	=	%sysfunc(open(&inLeafDat.));

%*122.	Retrieve the variable types and lengths.;
%let	TreeTyp	=	%sysfunc(vartype(&TreeID.,%sysfunc(varnum(&TreeID.,&VarLower.))));
%let	LeafTyp	=	%sysfunc(vartype(&LeafID.,%sysfunc(varnum(&LeafID.,&inLeafVar.))));
%let	TreeLen	=	%sysfunc(varlen(&TreeID.,%sysfunc(varnum(&TreeID.,&VarLower.))));
%let	LeafLen	=	%sysfunc(varlen(&LeafID.,%sysfunc(varnum(&LeafID.,&inLeafVar.))));

%*123.	Verify the variable types.;
%if	&TreeTyp.	^=	&LeafTyp.	%then %do;
	%*100.	Issue a message in the LOG.;
	%put	%str(N)OTE: [&L_mcrLABEL.]Type of [VarLower=&VarLower.] in [inDAT=&inDAT.] does not match [inLeafVar=&inLeafVar.] in [inLeafDat=&inLeafDat.].;

	%*200.	Set the switch on.;
	%let	errLeaf	=	1;
%end;

%*124.	Verify the variable lengths.;
%if	&TreeLen.	^=	&LeafLen.	%then %do;
	%*100.	Issue a message in the LOG.;
	%put	%str(N)OTE: [&L_mcrLABEL.]Length of [VarLower=&VarLower.] in [inDAT=&inDAT.] does not match [inLeafVar=&inLeafVar.] in [inLeafDat=&inLeafDat.].;

	%*200.	Set the switch on.;
	%let	errLeaf	=	1;
%end;

%*129.	Close the datasets.;
%CloseDS:
%let	DSrc	=	%sysfunc(close(&TreeID.));
%let	DSrc	=	%sysfunc(close(&LeafID.));
%if	&errLeaf.	=	1	%then %do;
	%goto	CrLeaf;
%end;

%*130.	Verify whether there is any observation in the Leaf Dataset.;
%if	%getOBS4DATA( inDAT = &inLeafDat. , gMode = F )	=	0	%then %do;
	%*100.	Issue a message in the LOG.;
	%put	%str(N)OTE: [&L_mcrLABEL.]Tree Leaf dataset [inLeafDat=&inLeafDat.] has no observation.;

	%*200.	Set the switch on.;
	%let	errLeaf	=	1;

	%*900.	Go to the creation step.;
	%goto	CrLeaf;
%end;

%*180.	Create the Leaf Dataset.;
%CrLeaf:
%if	&errLeaf.	=	1	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Program will create the Tree Leaf dataset [inLeafDat=&inLeafDat.].;
	%OrgTree_GetLeaves(
		inDAT		=	&inDAT.
		,VarUpper	=	&VarUpper.
		,VarLower	=	&VarLower.
		,outVAR		=	&inLeafVar.
		,outDAT		=	&inLeafDat.
		,procLIB	=	&procLIB.
	)
%end;

%*190.	Mark the end of the creation of the Leaf dataset.;
%EndOfCrLeaf:

%*200.	Verify the definitions of [VarUpper] and [VarLower].;
%*210.	Open the input dataset.;
%let	DSID	=	%sysfunc(open(&inDAT.));

%*220.	Retrieve the variable numbers.;
%let	vNumUpper	=	%sysfunc(varnum(&DSID.,&VarUpper.));
%let	vNumLower	=	%sysfunc(varnum(&DSID.,&VarLower.));

%*230.	Define the attributes of the output variables [&ChainTop.] and [&ChainBtm.], which should be the same as [&VarUpper.].;
%let	outTyp	=	%sysfunc(ifc(%sysfunc(vartype(&DSID.,&vNumUpper.))=C,$,));
%let	outFmt	=	%sysfunc(varfmt(&DSID.,&vNumUpper.));
%let	outLen	=	%sysfunc(varlen(&DSID.,&vNumUpper.));

%*240.	Abort if the VARTYPE of them do not match.;
%if	%sysfunc(vartype(&DSID.,&vNumUpper.))	^=	%sysfunc(vartype(&DSID.,&vNumLower.))	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.][&VarUpper.] and [&VarLower.] are of different data types. Program is interrupted!;
	%let	errMsg	=	1;
%end;

%*250.	Abort if the VARLEN of them do not match.;
%if	%sysfunc(varlen(&DSID.,&vNumUpper.))	^=	%sysfunc(varlen(&DSID.,&vNumLower.))	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.][&VarUpper.] and [&VarLower.] are of different lengths. Program is interrupted!;
	%let	errMsg	=	1;
%end;

%*290.	Close the input dataset.;
%let	DSrc	=	%sysfunc(close(&DSID.));

%*295.	Abort if there are any mismatches.;
%if	&errMsg.	=	1	%then %do;
	%put	&Lohno.;
	%ErrMcr
%end;

%*300.	Trace back through the tree from the Leaf as the beginning to the root as the end.;
data %unquote(&outDAT.);
	%*005.	Create new fields.;
	length
		&ChainTop.	&outTyp.&outLen.
		&ChainBtm.	&outTyp.&outLen.
		&VarUpper.	&outTyp.&outLen.
		&VarLower.	&outTyp.&outLen.
		&ChainLvl.	8
		tmpCounter	8
		tmpTotal	8
		rcChain		8
		rcNode		8
	;
	format
		&ChainTop.
		&ChainBtm.
		&outFmt.
	;
	retain
		tmpTotal
	;

	%*010.	Set the Leaf data.;
	set	%unquote(&inLeafDat.);

	%*050.	Regard the current linkage as the bottom of current Chain.;
	&ChainBtm.	=	&inLeafVar.;
	&VarLower.	=	&inLeafVar.;
	tmpCounter	=	1;
	tmpTotal	=	0;	%*This variable stores the number of all linkages in a full branch, which is the number of Nodes minus 1.;
	rcChain		=	0;
	rcNode		=	0;

	%*100.	Setup the HASH object to store all the nodes in current Chain.;
	%*Since the [tmpCounter] is decremented at steps, we sort the HASH Object in descending order.;
	%*It is weird that the KEY cannot be stored correctly if [tmpCounter] is NOT included in the method of DefineData.;
	dcl	hash	hChain(ordered:"d");
	hChain.DefineKey("tmpCounter");
	hChain.DefineData("tmpCounter","&VarUpper.","&VarLower.");
	hChain.DefineDone();
	dcl	hiter	hiChain("hChain");

	%*200.	Prepare the HASH object to load the direct superior to current [VarLower].;
	%*There should be only one superior found.;
	if	_N_	=	1	then do;
		dcl	hash	hDirSup(dataset:"&inDAT.",hashexp:16);
		hDirSup.DefineKey("&VarLower.");
		hDirSup.DefineData("&VarUpper.");
		hDirSup.DefineDone();
	end;
	call missing(&VarUpper.);

	%*300.	Search for the upper node until the root is reached.;
	do while ( rcNode = 0 );
		%*200.	Skip to the output step if there is no superior found, or the root is reached.;
		rcNode	=	hDirSup.check(key:&VarLower.);
		if	rcNode	^=	0	then do;
			Leave;
		end;

		%*500.	Add current linkage to the Chain.;
		rcNode		=	hDirSup.find(key:&VarLower.);
		tmpCounter	+	(-1);
		tmpTotal	+	1;
		rcChain		=	hChain.add();

		%*700.	Reset the variables for the next round of search.;
		&VarLower.	=	&VarUpper.;
	end;

	%*400.	Retrieve the value of the root for the Chain.;
	%*410.	Retrieve the last linkage in the Chain, since the HASH Object is sorted in descending order.;
	%*All the values in the output dataset are replaced at this step.;
	rcChain		=	hiChain.last();

	%*450.	Set the value of the root.;
	&ChainTop.	=	&VarUpper.;

	%*500.	Traverse the entire branch as identified above and output each linkage.;
	do while ( rcChain = 0 );
		%*100.	Set the level of current linkage in current Chain.;
		&ChainLvl.	=	sum(tmpCounter,tmpTotal);

		%*500.	Output current linkage.;
		output;

		%*900.	Retrieve the previous linkage in the Chain.;
		rcChain		=	hiChain.prev();
	end;

	%*800.	Delete the HASH Object of current Chain.;
	hiChain.delete();
	hChain.delete();

	%*900.	Purge.;
	keep
		&ChainTop.
		&ChainBtm.
		&VarUpper.
		&VarLower.
		&ChainLvl.
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
%mend OrgTree_EndToEndChain;

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
%OrgTree_EndToEndChain(
	inDAT		=	test
	,VarUpper	=	u
	,VarLower	=	l
	,ChainTop	=	ChainTop
	,ChainBtm	=	ChainBtm
	,ChainLvl	=	ChainLvl
	,inLeafDat	=	Leaves
	,inLeafVar	=	TreeLeaf
	,outDAT		=	End2EndChain
	,procLIB	=	WORK
)

/*-Notes- -End-*/