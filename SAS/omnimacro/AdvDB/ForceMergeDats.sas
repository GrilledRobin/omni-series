%macro ForceMergeDats(
	inDatLst	=
	,ModelDat	=
	,MixedType	=	N
	,MergeProc	=	SET
	,byVAR		=
	,addProc	=
	,outDAT		=	__MergedData__
	,procLIB	=	WORK
	,fDebug		=	0
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to merge the list of datasets, regardless of the different attributes of the same variables in different	|
|	| datasets within the list.																											|
|	|Actions taken to unify the variables can be found in the description of the function [UnifyVarForDats].							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDatLst	:	The list of datasets to be merged.																					|
|	|				The dataset names should be split by WHITE SPACES when provided.													|
|	|ModelDat	:	The Model Dataset to set the universal attributes of variables.														|
|	|				Default: [The first Dataset in the provided [inDatLst]]																|
|	|MixedType	:	Whether the unification accepts different types of any variable.													|
|	|				[Y] : Set the variable type to Character when there are different types of it in the datasets.						|
|	|				[N] : Abort the unification when there are different types of any variable(s) in the datasets.						|
|	|				Default: [N]																										|
|	|MergeProc	:	The process to merge the datasets.																					|
|	|				[SET]   : Conduct the SET statement.																				|
|	|				[MERGE] : Conduct the MERGE statement.																				|
|	|				Default: [SET]																										|
|	|byVAR		:	The list of variables by which to merge the datasets.																|
|	|				The variable names should be split by WHITE SPACES when provided.													|
|	|				To purely SET the datasets, which means when [MergeProc=SET], this parameter can be left blank.						|
|	|addProc	:	The additional process to be executed before each combined observation is output.									|
|	|				Tips: You can setup statements based on [_&Di.] to process the records from different datasets.						|
|	|				      Example: [if _1 then d_table=today();]																		|
|	|outDAT		:	The dataset as the merge result.																					|
|	|				Default: [work.__MergedData__]																						|
|	|procLIB	:	The working library.																								|
|	|fDebug		:	The switch of Debug Mode. Valid values are [0] or [1].																|
|	|				Default: [0]																										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20180325		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180722		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Leverage the additional option field of the function [QUOTE] to eliminate unexpected results.								|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20181103		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |If the same variable in different datasets are defined in NUMERIC and CHARACTER respectively, we have to set the output		|
|	|      | variable type as CHARACTER. However, using CATS or STRIP will translate the value into unpredictable precision. Therefore	|
|	|      | we use another approach to keep the original value as precise as possible.													|
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
|	|	|genvarlist																														|
|	|	|getOBS4DATA																													|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvDB"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|UnifyVarForDats																												|
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
%let	MergeProc	=	%qupcase(&MergeProc.);
%let	procLIB		=	%unquote(&procLIB.);

%if	%length(%qsysfunc(compress(&inDatLst.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No list of datasets is provided!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%index(&inDatLst.,%str(=))	^=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]Dataset options are NOT accepted!;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&ModelDat.,%str( ))))	=	0	%then	%let	ModelDat	=	%scan(&inDatLst.,1);
%if	%index(&ModelDat.,%str(.))	=	0	%then %do;
	%let	ModelDat	=	WORK.&ModelDat.;
%end;
%if	%length(%qsysfunc(compress(&MixedType.,%str( ))))	=	0	%then	%let	MixedType	=	N;
%*Make sure we only retrieve the first character of the indicator.;
%let	MixedType	=	%upcase(%substr(&MixedType.,1,1));
%if	%length(%qsysfunc(compress(&MergeProc.,%str( ))))	=	0	%then	%let	MergeProc	=	SET;
%if	&MergeProc.	^=	SET	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]The process to merge the datasets is NOT [SET], it is presumed to be [MERGE].;
	%let	MergeProc	=	MERGE;
%end;
%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))		=	0	%then	%let	outDAT		=	__MergedData__;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))		=	0	%then	%let	procLIB		=	WORK;
%if	%length(%qsysfunc(compress(&fDebug.,%str( ))))		=	0	%then	%let	fDebug		=	0;
%if	&fDebug.^=	0	%then	%let	fDebug		=	1;

%*013.	Define the local environment.;
%local
	OptNotes	OptSource	OptSource2	OptMLogic	OptSymGen	OptMPrint	OptInOper
	LDropStmt
	Di			Dj			Vi
;
%let	LDropStmt	=;

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
%genvarlist(
	nstart		=	1
	,inlst		=	&inDatLst.
	,nvarnm		=	LeFMDDat
	,nvarttl	=	LnFMDDat
)

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in traditional SAS syntax colors.;
%macro dummy; %mend dummy;

%*040.	Create temporary macro variables in terms of the dataset list.;
%do Di=1 %to &LnFMDDat.;
	%*100.	Initialize the Statement.;
	%local
		LAsgnStmt_&Di.
		LAsgnVar_&Di.
		LRenStmt_&Di.
		LRenVar_&Di.
	;
	%let	LAsgnStmt_&Di.	=;
	%let	LAsgnVar_&Di.	=;
	%let	LRenStmt_&Di.	=;
	%let	LRenVar_&Di.	=;
%end;

%*050.	Correct the dataset names when they are located in WORK library.;
%do Di=1 %to &LnFMDDat.;
	%if	%index(&&LeFMDDat&Di..,%str(.))	=	0	%then %do;
		%let	LeFMDDat&Di.	=	WORK.&&LeFMDDat&Di..;
	%end;
%end;

%*099.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*100.	All input values.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [inDatLst=%qsysfunc(compbl(&inDatLst.))].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [ModelDat=%qsysfunc(compbl(&ModelDat.))].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [MixedType=&MixedType.].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [MergeProc=&MergeProc.].;
	%if	%length(%qsysfunc(compress(&byVAR.,%str( ))))	=	0	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [byVAR=].;
	%end;
	%else %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [byVAR=%qsysfunc(compbl(&byVAR.))].;
	%end;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [outDAT=%qsysfunc(compbl(&outDAT.))].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [procLIB=&procLIB.].;
%end;

%*100.	Unify the attributes of all variables related to current process.;
%UnifyVarForDats(
	inDatLst	=	&inDatLst.
	,ModelDat	=	&ModelDat.
	,MixedType	=	&MixedType.
	,outDAT		=	&procLIB..__FMD_UnifiedVar__
	,oTrTpNVar	=	LnTrTpVar
	,oTrTpVNam	=	LeTrTpVNam
	,oTrTpVTyp	=	LeTrTpVTyp
	,oTrTpDNam	=	LeTrTpDNam
	,fDebug		=	&fDebug.
)
%*190.	Abort the process if no variable is identified from all the input datasets.;
%if	%getOBS4DATA( inDAT = &procLIB..__FMD_UnifiedVar__ , gMode = F )	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]There is no variable in any of the listed datasets!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*200.	Retrieve the attributes of the unified variables.;
%*210.	Sort the meta data by [VARNUM].;
proc sort
	data=&procLIB..__FMD_UnifiedVar__
;
	by	VARNUM;
run;

%*250.	Retrieve the attributes of the variables.;
data _NULL_;
	set &procLIB..__FMD_UnifiedVar__ end=EOF;
	by	VARNUM;
	call symputx(cats("LeFMDVarNam",_N_),name,"L");
	call symputx(cats("LeFMDVarTyp",_N_),oVarTyp,"L");
	call symputx(cats("LeFMDVarLen",_N_),oVarLen,"L");
	call symputx(cats("LeFMDVarFmt",_N_),oVarFmt,"L");
	call symputx(cats("LeFMDVarLbl",_N_),quote(strip(oVarLbl),"'"),"L");
	if	EOF	then do;
		call symputx("LnFMDVar",_N_,"L");
	end;
run;

%*300.	Sort the datasets if [byVAR] is specified.;
%*301.	Skip this step if it is NOT specified.;
%if	%length(%qsysfunc(compress(&byVAR.,%str( ))))	=	0	%then %do;
	%goto	EndOfSortDats;
%end;

%*350.	Sort the datasets.;
%do Di=1 %to &LnFMDDat.;
	proc sort
		data=%unquote(&&LeFMDDat&Di..)
		out=&procLIB..__FMD_Dat&Di.__
	;
		by	&byVAR.;
	run;
%end;

%*390.	Mark the end of current step.;
%EndOfSortDats:

%*400.	Prepare to re-assign the variables for those with different data types.;
%*401.	Skip this step if there is no variable to be renamed during unification.;
%if	&LnTrTpVar.	=	0	%then %do;
	%goto	EndOfRename;
%end;

%*420.	Prepare the [DROP] statement for the later purge.;
%let	LDropStmt	=	DROP;

%*450.	Define the series of macro variables denoting the [RENAME=] dataset options for all the listed datasets.;
%do Di=1 %to &LnFMDDat.;
	%*200.	Search for the variables to be renamed in current dataset.;
	%do Dj=1 %to &LnTrTpVar.;
		%*500.	Prepare the statements.;
		%if	%upcase(&&LeTrTpDNam&Dj..)	=	%upcase(&&LeFMDDat&Di..)	%then %do;
			%*100.	Translation.;
			%*[1] Multiply the original value by 10**6.;
			%*[2] Retrieve the last 6 digits, while SAS can only ensure the 3 are precise when the entire number is too big.;
			%*[3] Verify whether all these 6 digits are 0.;
			%*[4] Concatenate all 3 parts of the number: [Original Integer Part], [Dot Sign] and [Decimal Part].;
			%let	LAsgnVar_&Di.	=	&&LAsgnVar_&Di.. %nrstr( if missing%()__TrnsVar_&Di._&Dj.%nrstr(%)=0 then do; );
			%let	LAsgnVar_&Di.	=	&&LAsgnVar_&Di..	%nrstr( trnsNUM{1} = strip%( put%( )__TrnsVar_&Di._&Dj.%nrstr( * 10 ** 6 , f32. %) %); );
			%let	LAsgnVar_&Di.	=	&&LAsgnVar_&Di..	%nrstr( trnsNUM{2} = substr( trnsNUM{1} , length( trnsNUM{1} ) - 5 ); );
			%let	LAsgnVar_&Di.	=	&&LAsgnVar_&Di..	%nrstr( trnsNUM{3} = compress( trnsNUM{2} , "0" ); );
			%let	LAsgnVar_&Di.	=	&&LAsgnVar_&Di..	&&LeTrTpVNam&Dj.. = %nrstr( catx( "." , substr( trnsNUM{1} , 1 , length( trnsNUM{1} ) - 6 ) , ifc( missing(trnsNUM{3}) , "" , trnsNUM{2} ) ); );
			%let	LAsgnVar_&Di.	=	&&LAsgnVar_&Di.. %nrstr( end; );

			%let	LRenVar_&Di.	=	&&LRenVar_&Di.. %nrbquote( &&LeTrTpVNam&Dj.. = __TrnsVar_&Di._&Dj. );
			%let	LDropStmt		=	&LDropStmt. __TrnsVar_&Di._&Dj.;
		%end;
	%end;

	%*300.	Determine the statements to assign values.;
	%if	%length(%qsysfunc(compress(&&LAsgnVar_&Di..,%str( ))))	^=	0	%then %do;
		%let	LAsgnStmt_&Di.	=	if _&Di. then do%str(;) &&LAsgnVar_&Di.. end%str(;);
	%end;

	%*400.	Determine the final dataset option.;
	%if	%length(%qsysfunc(compress(&&LRenVar_&Di..,%str( ))))	^=	0	%then %do;
		%let	LRenStmt_&Di.	=	%nrstr( rename=%() &&LRenVar_&Di.. %nrstr(%) );
	%end;
%end;

%*460.	Close the [DROP] statement if necessary.;
%if	%length(%qsysfunc(compress(&LDropStmt.,%str( ))))	^=	0	%then %do;
	%let	LDropStmt	=	&LDropStmt.%str(;);
%end;

%*490.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*100.	All the dataset options to be added to the merge process.;
	%put	%str(I)NFO: [&L_mcrLABEL.][RENAME=] dataset options for all the listed datasets are printed below:;
	%do Di=1 %to &LnFMDDat.;
		%put	%str(I)NFO: [&L_mcrLABEL.][LRenStmt_&Di.=&&LRenStmt_&Di..];
	%end;

	%*300.	All the statements to assign values during the merge process.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Statements to assign values during the TYPE translation for all the listed datasets are printed below:;
	%do Di=1 %to &LnFMDDat.;
		%put	%str(I)NFO: [&L_mcrLABEL.][LAsgnStmt_&Di.=&&LAsgnStmt_&Di..];
	%end;

	%*500.	All the temporary variables to be dropped.;
	%put	%str(I)NFO: [&L_mcrLABEL.]All the temporary variables to be removed after the process are printed within below statement:;
	%put	%str(I)NFO: [&L_mcrLABEL.][LDropStmt=&LDropStmt.];
%end;

%*499.	Mark the end of current step.;
%EndOfRename:

%*699.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*100.	The contents within the LENGTH statement.;
	%put	%str(I)NFO: [&L_mcrLABEL.]The lengths of the variables in the output result are printed below:;
	%do Vi=1 %to &LnFMDVar.;
		%put	%str(I)NFO: [&L_mcrLABEL.][&&LeFMDVarNam&Vi.. %sysfunc(ifc( &&LeFMDVarTyp&Vi..=C , $ , ))&&LeFMDVarLen&Vi..];
	%end;

	%*200.	All the FORMAT statements.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Statements to assign formats to the variables are printed below:;
	%do Vi=1 %to &LnFMDVar.;
		%put	%str(I)NFO: [&L_mcrLABEL.][&&LeFMDVarNam&Vi..=&&LeFMDVarFmt&Vi..];
	%end;

	%*300.	All the LABEL statements.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Statements to assign labels to the variables are printed below:;
	%do Vi=1 %to &LnFMDVar.;
		%put	%str(I)NFO: [&L_mcrLABEL.][&&LeFMDVarNam&Vi..=&&LeFMDVarLbl&Vi..];
	%end;
%end;

%*700.	Conduct the merge process.;
data %unquote(&outDAT.);
	%*100.	Create the variables for output.;
	attrib
	%do Vi=1 %to &LnFMDVar.;
		&&LeFMDVarNam&Vi..
			length	=	%sysfunc(ifc( &&LeFMDVarTyp&Vi..=C , $ , ))&&LeFMDVarLen&Vi..
			label	=	&&LeFMDVarLbl&Vi..
		%if	%length(%qsysfunc(compress(&&LeFMDVarFmt&Vi..,%str( ))))	^=	0	%then %do;
			format	=	&&LeFMDVarFmt&Vi..
		%end;
	%end;
	;

%*For one-to-many merging, SAS system would automatically retain those variables only in the [one] dataset.;
%*Hence we cannot initialize these variables at the run time.;
	%do Vi=1 %to &LnFMDVar.;
%*		call missing(&&LeFMDVarNam&Vi..);
	%end;

	%*200.	Set all the source data.;
	%unquote(&MergeProc.)
		%do Di=1 %to &LnFMDDat.;
			%if	%length(%qsysfunc(compress(&byVAR.,%str( ))))	=	0	%then %do;
				%unquote(&&LeFMDDat&Di..)
			%end;
			%else %do;
				&procLIB..__FMD_Dat&Di.__
			%end;
				(
					in=_&Di.
					%unquote(&&LRenStmt_&Di..)
				)
		%end;
	;
%if	%length(%qsysfunc(compress(&byVAR.,%str( ))))	^=	0	%then %do;
	by	&byVAR.;
%end;

	%*300.	Assign values during the TYPE translation.;
%if	&LnTrTpVar.	^=	0	%then %do;
	array trnsNUM{3} $64 _TEMPORARY_;
%end;
	%do Di=1 %to &LnFMDDat.;
		%unquote(&&LAsgnStmt_&Di..)
	%end;

	%*500.	Conduct additional process before the combined observation is output.;
	%unquote(&addProc.)

	%*900.	Purge.;
	%unquote(&LDropStmt.)
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
%mend ForceMergeDats;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvDB"
		"D:\SAS\omnimacro\AdvOp"
	)
	mautosource
;

%*050.	Setup a dummy macro [ErrMcr] to prevent the session to be bombed.;
%macro	ErrMcr;	%mend	ErrMcr;

%*100.	Create testing datasets.;
%*110.	Model dataset.;
data UnifyVar_ModelDat;
	length
		var1	3
		var3	8
		var4	8
		var6	$16
		var7	$4
	;
	format
		var1	3.
		var3	yymmddD10.
		var4	comma12.2
		var7	$6.
	;
	label
		var1	=	" "
		var3	=	"Data Date"
		var4	=	"Amount"
		var6	=	"Remarks"
		var7	=	"City"
	;
	var1	=	1;
	var3	=	today();
	var4	=	351884198.536712;
	var6	=	"Test";
	var7	=	"SH";
run;

%*120.	Data 1.;
data UnifyVar_Dat1;
	length
		var5	$6
		var3	8
		var2	$2
		var4	6
	;
	format
		var3	yymmddS10.
		var4	comma12.2
	;
	label
		var2	=	"Nationality"
		var3	=	"Table Date"
		var4	=	"Amount"
		var5	=	"Branch"
	;
	var3	=	mdy(3,18,2018);
	var2	=	"SG";
	var4	=	50000;
	var5	=	"SH";
run;

%*130.	Data 2.;
data UnifyVar_Dat2;
	length
		var2	$2
		var1	8
		var4	$6
		var6	8
		var7	$4
	;
	format
		var1	8.
		var7	$4.
	;
	label
		var1	=	"Sequence"
		var2	=	"Nationality"
		var4	=	"Amount"
	;
	var2	=	"CN";
	var1	=	3;
	var4	=	"200000";
	var6	=	89181;
	var7	=	"BJ";
run;

%*200.	Include the Model Dataset in the list.;
%ForceMergeDats(
	inDatLst	=	%nrbquote(
						UnifyVar_Dat1
						UnifyVar_Dat2
						UnifyVar_ModelDat
					)
	,ModelDat	=	UnifyVar_ModelDat
	,MixedType	=	Y
	,outDAT		=	mrgRst1
	,fDebug		=	1
)

%*300.	Exclude the Model Dataset in the list.;
%ForceMergeDats(
	inDatLst	=	%nrbquote(
						UnifyVar_Dat1
						UnifyVar_Dat2
					)
	,ModelDat	=	UnifyVar_ModelDat
	,MixedType	=	Y
	,outDAT		=	mrgRst2
	,fDebug		=	1
)

%*400.	Reverse the order of [Dat1] and [Dat2].;
%ForceMergeDats(
	inDatLst	=	%nrbquote(
						UnifyVar_Dat2
						UnifyVar_Dat1
						UnifyVar_ModelDat
					)
	,ModelDat	=	UnifyVar_ModelDat
	,MixedType	=	Y
	,outDAT		=	mrgRst3
	,fDebug		=	1
)

%*500.	Test the [MERGE] process.;
data a;
	a	=	1;
	b	=	2;
run;
data b;
	a	=	2;
	c	=	3;
run;

%ForceMergeDats(
	inDatLst	=	%nrbquote(
						a b
					)
	,ModelDat	=
	,MixedType	=	Y
	,MergeProc	=	merge
	,byVAR		=	a
	,outDAT		=	mrgRst4
	,fDebug		=	1
)

%*900.	Restrict the multiple TYPE of any variable.;
%ForceMergeDats(
	inDatLst	=	%nrbquote(
						UnifyVar_Dat2
						UnifyVar_Dat1
						UnifyVar_ModelDat
					)
	,ModelDat	=	UnifyVar_ModelDat
	,MixedType	=	N
	,outDAT		=	mrgRst9
	,fDebug		=	1
)

/*-Notes- -End-*/