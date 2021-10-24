%macro UnifyVarForDats(
	inDatLst	=
	,ModelDat	=
	,MixedType	=	N
	,outDAT		=	__UnifiedVars__
	,oTrTpNVar	=	GnTrTpVar
	,oTrTpVNam	=	GeTrTpVNam
	,oTrTpVTyp	=	GeTrTpVTyp
	,oTrTpDNam	=	GeTrTpDNam
	,procLIB	=	WORK
	,fDebug		=	0
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to unify the variables for the list of datasets, to eliminate the (w)arnings or (e)rrors during the SET or	|
|	| MERGE processes upon them.																										|
|	|Actions taken in this macro:																										|
|	|[1] Determine the sequence of variables in the Model Dataset, or in the very first one in the list if it is NOT specified.			|
|	|[2] Add all new variables found in the subsequent datasets to the variable list created above.										|
|	|[3] Set the variable type to Character if [MixedType=Y] while there are different types of the same variable in all datasets, or	|
|	|     abort the process by issuing a (w)arning message if the same situation is encountered when [MixedType=N].						|
|	|[4] Retrieve the maximum length of each identified variable for attribute unification.												|
|	|[5] Use the FORMAT of any variable when its LENGTH is identified as MAXIMUM.														|
|	|    If it is not defined at the certain dataset when its LENGTH is the maximum, we use the FORMAT when it first appears in the		|
|	|     variable list instead.																										|
|	|    If there are different TYPE of the same variable name among the datasets, we leave the FORMAT as BLANK to avoid unnecessary	|
|	|     misunderstanding of the data.																									|
|	|[6] Use the LABEL of any variables when they are firstly identified in any of the datasets.										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDatLst	:	The list of datasets to unify the attributes of variables.															|
|	|				The dataset names should be split by WHITE SPACES when provided.													|
|	|ModelDat	:	The Model Dataset to set the universal attributes of variables.														|
|	|				Default: [The first Dataset in the provided [inDatLst]]																|
|	|MixedType	:	Whether the unification accepts different types of any variable.													|
|	|				[Y] : Set the variable type to Character when there are different types of it in the datasets.						|
|	|				[N] : Abort the unification when there are different types of any variable(s) in the datasets.						|
|	|				Default: [N]																										|
|	|outDAT		:	The dataset holding the list of attributes of the unified variables.												|
|	|				Default: [work.__UnifiedVars__]																						|
|	|oTrTpNVar	:	Number of variables that should be translated from Numeric type to Character type.									|
|	|				Default: [GnTrTpVar]																								|
|	|oTrTpVNam	:	Prefix of macro variables that denote the series of SAS dataset variables to be translated from NUM to CHAR.		|
|	|				Default: [GeTrTpVNam]																								|
|	|oTrTpVTyp	:	Prefix of macro variables that denote the series of types of [GeTrTpVNam<N>].										|
|	|				Default: [GeTrTpVTyp]																								|
|	|oTrTpDNam	:	Prefix of macro variables that denote the series of dataset names containing [GeTrTpVNam<N>].						|
|	|				Default: [GeTrTpDNam]																								|
|	|procLIB	:	The working library.																								|
|	|fDebug		:	The switch of Debug Mode. Valid values are [0] or [1].																|
|	|				Default: [0]																										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20180318		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180422		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the SQL query from [dictionary.columns] with [OPEN] function in DATA step, to improve the efficiency.				|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20181103		| Version |	2.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |If the same variable in different datasets are defined in NUMERIC and CHARACTER respectively, we have to set the output		|
|	|      | variable type as CHARACTER. However, using CATS or STRIP will translate the value into unpredictable precision. Therefore	|
|	|      | we use another approach to keep the original value as precise as possible.													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Please find the attachments for examples.																							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|genvarlist																														|
|	|	|getOBS4DATA																													|
|	|	|ErrMcr																															|
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
%let	procLIB	=	%unquote(&procLIB.);

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
%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))		=	0	%then	%let	outDAT		=	__UnifiedVars__;
%if	%length(%qsysfunc(compress(&oTrTpNVar.,%str( ))))	=	0	%then	%let	oTrTpNVar	=	GnTrTpVar;
%if	%length(%qsysfunc(compress(&oTrTpVNam.,%str( ))))	=	0	%then	%let	oTrTpVNam	=	GeTrTpVNam;
%if	%length(%qsysfunc(compress(&oTrTpVTyp.,%str( ))))	=	0	%then	%let	oTrTpVTyp	=	GeTrTpVTyp;
%if	%length(%qsysfunc(compress(&oTrTpDNam.,%str( ))))	=	0	%then	%let	oTrTpDNam	=	GeTrTpDNam;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))		=	0	%then	%let	procLIB		=	WORK;
%if	%length(%qsysfunc(compress(&fDebug.,%str( ))))		=	0	%then	%let	fDebug		=	0;
%if	&fDebug.^=	0	%then	%let	fDebug		=	1;

%*013.	Define the local environment.;
%local
	OptNotes	OptSource	OptSource2	OptMLogic	OptSymGen	OptMPrint	OptInOper
	errNvars	msgNvars
	Di			Vj			Vk			Vn
;
%let	errNvars	=	0;
%let	msgNvars	=	0;

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
%global	&oTrTpNVar.;
%let	&oTrTpNVar.	=	0;
%genvarlist(
	nstart		=	1
	,inlst		=	&inDatLst.
	,nvarnm		=	LeUVDat
	,nvarttl	=	LnUVDat
)

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in traditional SAS syntax colors.;
%macro dummy; %mend dummy;

%*050.	Correct the dataset names when they are located in WORK library.;
%do Di=1 %to &LnUVDat.;
	%if	%index(&&LeUVDat&Di..,%str(.))	=	0	%then %do;
		%let	LeUVDat&Di.	=	WORK.&&LeUVDat&Di..;
	%end;
%end;

%*099.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*100.	All input values.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [inDatLst=%qsysfunc(compbl(&inDatLst.))].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [ModelDat=%qsysfunc(compbl(&ModelDat.))].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [MixedType=&MixedType.].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [outDAT=%qsysfunc(compbl(&outDAT.))].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [procLIB=&procLIB.].;

	%*200.	List of datasets identified.;
	%put	%str(I)NFO: [&L_mcrLABEL.]# of datasets is: [LnUVDat=&LnUVDat.];
	%put	%str(I)NFO: [&L_mcrLABEL.]Datasets are identified as below:;
	%do Di=1 %to &LnUVDat.;
		%put	%str(I)NFO: [&L_mcrLABEL.][LeUVDat&Di.=&&LeUVDat&Di..];
	%end;
%end;

%*100.	Retrieve all variables related to current process.;
%*This step tends to be faster than PROC SQL query from [dictionary.columns] when there are many datasets to process.;
data &procLIB..__UV_all_Vars__;
	length
		nVarSeq	8
		libname	$8
		memname	$32
		name	$32
		type	$4
		length	8
		varnum	8
		label	$256
		format	$64
	;
	length
		dsid	tmpi	8
	;
%do Di=1 %to &LnUVDat.;
	%if	%upcase(%sysfunc(quote(&&LeUVDat&Di..,%str(%'))))	=	%upcase(%sysfunc(quote(&ModelDat.,%str(%'))))	%then %do;
		nVarSeq	=	0;
	%end;
	%else %do;
		nVarSeq	=	&Di.;
	%end;
	dsid	=	open(%sysfunc(quote(&&LeUVDat&Di..,%str(%'))));
	libname	=	attrc(dsid,'LIB');
	memname	=	attrc(dsid,'MEM');
	do tmpi=1 to attrn(dsid,"NVARS");
		name	=	upcase(varname(dsid,tmpi));
		type	=	upcase(vartype(dsid,tmpi));
		length	=	varlen(dsid,tmpi);
		varnum	=	tmpi;
		label	=	varlabel(dsid,tmpi);
		format	=	varfmt(dsid,tmpi);
		output;
	end;
	_iorc_	=	close(dsid);
%end;
	drop
		dsid	tmpi
	;
run;

%*200.	Extract the multiple TYPE and LENGTH of variables.;
%*210.	Count the frequency of [type] for each [name] in the summary table.;
proc freq
	data=&procLIB..__UV_all_Vars__
	noprint
;
	tables
		name	*	type
		/out=&procLIB..__UV_VarTypes__
	;
run;

%*220.	Check whether there are more than one TYPE for any of the variable names.;
proc freq
	data=&procLIB..__UV_VarTypes__
	noprint
;
	tables
		name
		/out=&procLIB..__UV_DifTypes__( where=( COUNT > 1 ) )
	;
run;

%*230.	Count the frequency of [length] for each [name] in the summary table.;
proc freq
	data=&procLIB..__UV_all_Vars__
	noprint
;
	tables
		name	*	length
		/out=&procLIB..__UV_VarLengths__
	;
run;

%*240.	Check whether there are more than one LENGTH for any of the variable names.;
proc freq
	data=&procLIB..__UV_VarLengths__
	noprint
;
	tables
		name
		/out=&procLIB..__UV_DifLengths__( where=( COUNT > 1 ) )
	;
run;

%*300.	Set the proper attributes of each variable.;
%*Here we sort the data by dataset name-sequence [nVarSeq] in terms of each variable name [name], just to dedup the variables.;
proc sort
	data=&procLIB..__UV_all_Vars__
;
	by
		name
		nVarSeq
	;
run;
data
	&procLIB..__UV_Var_Unified__(keep=name oVar:)
	&procLIB..__UV_Var_MultiTypes__(drop=oVar:)
	&procLIB..__UV_Var_MultiLengths__(drop=oVar:)
;
	%*100.	Set the dataset.;
	set &procLIB..__UV_all_Vars__ end=EOF;
	by
		name
		nVarSeq
	;

	%*200.	Create temporary variables.;
	length
		oVarTyp	$4
		oVarSeq	oVarNum	oVarLen	8
		oVarFmt	$64
		oVarLbl	$256
		oVarDsn	$128
		tmpFmt	$64
		tmpFTyp	3
	;
	retain
		oVarTyp	oVarSeq	oVarNum	oVarLen	oVarFmt	oVarLbl	oVarDsn
		tmpFmt	tmpFTyp
	;

	%*400.	Output all variables with multiple TYPE.;
	%*401.	Prepare the HASH Objects to search for the variable names with multiple TYPE.;
	if	_N_	=	1	then do;
		dcl	hash	hTyp(dataset:"&procLIB..__UV_DifTypes__");
		hTyp.DefineKey("name");
		hTyp.DefineData("name");
		hTyp.DefineDone();
	end;

	%*410.	Output to the list of variables with multiple TYPE.;
	if	hTyp.check()	=	0	then do;
		output	&procLIB..__UV_Var_MultiTypes__;
	end;

	%*500.	Output all variables with multiple LENGTH.;
	%*501.	Prepare the HASH Objects to search for the variable names with multiple LENGTH.;
	if	_N_	=	1	then do;
		dcl	hash	hLen(dataset:"&procLIB..__UV_DifLengths__");
		hLen.DefineKey("name");
		hLen.DefineData("name");
		hLen.DefineDone();
	end;

	%*510.	Output to the list of variables with multiple LENGTH.;
	if	hLen.check()	=	0	then do;
		output	&procLIB..__UV_Var_MultiLengths__;
	end;

	%*800.	Identify the attributes of current variable.;
	%*810.	Initialize the attributes of the variable in the output dataset.;
	if	first.name	then do;
		oVarTyp	=	strip(type);
		oVarSeq	=	nVarSeq;
		oVarNum	=	varnum;
		oVarLen	=	length;
		oVarFmt	=	strip(format);
		oVarLbl	=	strip(label);
		oVarDsn	=	catx( "." , libname , memname );
		tmpFmt	=	strip(format);
		tmpFTyp	=	0;
	end;

	%*820.	Set the type of the variable with Character if there are multiple types found for it.;
	if	oVarTyp	^=	type	then do;
		oVarTyp	=	"C";
		tmpFTyp	=	1;
	end;

	%*830.	Maximize the length of the variable.;
	if	length	>	oVarLen	then do;
		oVarLen	=	length;
		oVarFmt	=	strip(format);
	end;

	%*890.	Only keep one observation for each variable name.;
	if	last.name	then do;
		%*100.	Use the FORMAT at the first appearance if it is not defined when the LENGTH of current variable reaches the maximum.;
		if	missing(oVarFmt)	then do;
			oVarFmt	=	tmpFmt;
		end;

		%*200.	Reset the FORMAT to NULL, while the LENGTH to minimum 32, if multiple TYPE is identified for the same variable name.;
		if	tmpFTyp	=	1	then do;
			call missing(oVarFmt);
			oVarLen	=	max( oVarLen , 32 );
		end;

		%*900.	Output.;
		output	&procLIB..__UV_Var_Unified__;
	end;

	%*900.	Purge.;
	drop
		tmp:
	;
run;

%*400.	Verify the TYPE of the variables.;
%*401.	Skip the verification on TYPE if there is no variable with more than one TYPE among all the related datasets.;
%if	%getOBS4DATA( inDAT = &procLIB..__UV_Var_MultiTypes__ , gMode = F )	=	0	%then %do;
	%goto	EndOfVarTyp;
%end;

%*410.	Prepare messages to the log and the correction instructions for output.;
data _NULL_;
	%*100.	Set the dataset.;
	set &procLIB..__UV_Var_MultiTypes__ end=EOF;

	%*200.	Create temporary variables.;
	length	tmpNvar	tmpNtyp	8;
	retain	tmpNvar	tmpNtyp	0;

	%*300.	Increment the number of variable names to be printed in the log as abnormal messages.;
	tmpNvar	+	1;

	%*400.	Identify current variable name and its affiliating dataset.;
	call symputx(cats("errVName",tmpNvar),name,"F");
	call symputx(cats("errDName",tmpNvar),catx( "." , libname , memname ),"F");
	call symputx(cats("errVType",tmpNvar),type,"F");

	%*500.	Identify the numeric variables that have to be translated to characters.;
	%*501.	Skip If current variable is character type.;
	if	type	=	"C"	then do;
		goto	EndOfChar;
	end;

	%*510.	Increment the number of variable names to be translated.;
	tmpNtyp	+	1;

	%*520.	Identify current variable name and its affiliating dataset.;
	call symputx(cats("&oTrTpVNam.",tmpNtyp),name,"G");
	call symputx(cats("&oTrTpDNam.",tmpNtyp),catx( "." , libname , memname ),"G");
	call symputx(cats("&oTrTpVTyp.",tmpNtyp),type,"G");

	%*590.	Mark the end of the character variable.;
	EndOfChar:

	%*900.	Identify the number of variables.;
	if	EOF	then do;
		call symputx("errNvars",tmpNvar,"F");
		call symputx("&oTrTpNVar.",tmpNtyp,"G");
	end;
run;

%*470.	Skip printing messages to the log if this function accepts the multiple TYPE for the variables.;
%if	&MixedType.	=	Y	%then %do;
	%goto	EndOfVarTyp;
%end;

%*480.	Issue messages in the log.;
%put	%str(W)ARNING: [&L_mcrLABEL.]Program found mismatching TYPE for variables as listed below:;
%do Vj=1 %to &errNvars.;
	%put	%str(W)ARNING: [&L_mcrLABEL.][errVName&Vj.=&&errVName&Vj..][errVType&Vj.=&&errVType&Vj..][errDName&Vj.=&&errDName&Vj..];
%end;
%put	&Lohno.;
%ErrMcr

%*490.	Mark the end of the verification on TYPE mismatching.;
%EndOfVarTyp:

%*499.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*100.	Print those variables with different TYPE.;
	%put	%str(I)NFO: [&L_mcrLABEL.]# of variables that have different TYPE is: [errNvars=&errNvars.];
	%do Vj=1 %to &errNvars.;
		%put	%str(I)NFO: [&L_mcrLABEL.][errVName&Vj.=&&errVName&Vj..][errVType&Vj.=&&errVType&Vj..][errDName&Vj.=&&errDName&Vj..];
	%end;

	%*200.	Print those variables to be translated from numeric type to character type.;
	%put	%str(I)NFO: [&L_mcrLABEL.]# of variables that should be translated to Character Type: [&oTrTpNVar.=&&&oTrTpNVar..];
	%do Vn=1 %to &&&oTrTpNVar..;
		%put	%str(I)NFO: [&L_mcrLABEL.][&oTrTpVNam.&Vn.=&&&oTrTpVNam.&Vn..][&oTrTpVTyp.&Vn.=&&&oTrTpVTyp.&Vn..][&oTrTpDNam.&Vn.=&&&oTrTpDNam.&Vn..];
	%end;
%end;

%*500.	Verify the LENGTH of the variables.;
%*501.	Skip the verification on LENGTH if this function is NOT executed in debug mode.;
%if	&fDebug.	=	0	%then %do;
	%goto	EndOfVarLen;
%end;

%*505.	Skip the verification on LENGTH if there is no variable with more than one LENGTH among all the related datasets.;
%if	%getOBS4DATA( inDAT = &procLIB..__UV_Var_MultiLengths__ , gMode = F )	=	0	%then %do;
	%goto	EndOfVarLen;
%end;

%*510.	Prepare messages to the log and the correction instructions for output.;
data _NULL_;
	%*100.	Set the dataset.;
	set &procLIB..__UV_Var_MultiLengths__ end=EOF;

	%*200.	Create temporary variables.;
	length	tmpNvar	8;
	retain	tmpNvar	0;

	%*300.	Increment the number of variable names to be printed in the log as abnormal messages.;
	tmpNvar	+	1;

	%*400.	Identify current variable name and its affiliating dataset.;
	call symputx(cats("msgVName",tmpNvar),name,"F");
	call symputx(cats("msgDName",tmpNvar),catx( "." , libname , memname ),"F");
	call symputx(cats("msgVLen",tmpNvar),length,"F");

	%*900.	Identify the number of variables.;
	if	EOF	then do;
		call symputx("msgNvars",tmpNvar,"F");
	end;
run;

%*590.	Mark the end of the verification on LENGTH mismatching.;
%EndOfVarLen:

%*599.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%put	%str(I)NFO: [&L_mcrLABEL.]There are [msgNvars=&msgNvars.] variables that have different LENGTH in the required datasets, while the maximum one for each is used to create the output dataset.;
	%do Vk=1 %to &msgNvars.;
		%put	%str(I)NFO: [&L_mcrLABEL.][msgVName&Vk.=&&msgVName&Vk..][msgVLen&Vk.=&&msgVLen&Vk..][msgDName&Vk.=&&msgDName&Vk..];
	%end;
%end;

%*600.	Prepare the dictionary as final output.;
%*610.	Sort the variable names by their dedicated sequence.;
proc sort
	data=&procLIB..__UV_Var_Unified__
;
	by
		oVarSeq
		oVarNum
	;
run;

%*650.	Output.;
data %unquote(&outDAT.);
	%*010.	Create new variables.;
	length	VARNUM	8;

	%*100.	Set the source data.;
	set	&procLIB..__UV_Var_Unified__;
	by
		oVarSeq
		oVarNum
	;

	%*300.	Assign values.;
	VARNUM	=	_N_;

	%*900.	Purge.;
	drop
		oVarSeq
		oVarNum
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
%mend UnifyVarForDats;

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
	var4	=	354198.5;
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
		var4	6
		var6	8
		var7	$4
	;
	format
		var1	8.
		var4	best12.
		var7	$4.
	;
	label
		var1	=	"Sequence"
		var2	=	"Nationality"
		var4	=	"Amount"
	;
	var2	=	"CN";
	var1	=	3;
	var4	=	200000;
	var6	=	89181;
	var7	=	"BJ";
run;

%*200.	Include the Model Dataset in the list.;
%UnifyVarForDats(
	inDatLst	=	%nrbquote(
						UnifyVar_Dat1
						UnifyVar_Dat2
						UnifyVar_ModelDat
					)
	,ModelDat	=	UnifyVar_ModelDat
	,MixedType	=	Y
	,outDAT		=	test1
	,fDebug		=	1
)
%macro getTrnsTp;
%do i=1 %to &GnTrTpVar.;
	%put	[GeTrTpVNam&i.=&&GeTrTpVNam&i..][GeTrTpVTyp&i.=&&GeTrTpVTyp&i..][GeTrTpDNam&i.=&&GeTrTpDNam&i..];
%end;
%mend getTrnsTp;
%getTrnsTp

%*300.	Exclude the Model Dataset in the list.;
%UnifyVarForDats(
	inDatLst	=	%nrbquote(
						UnifyVar_Dat1
						UnifyVar_Dat2
					)
	,ModelDat	=	UnifyVar_ModelDat
	,MixedType	=	Y
	,outDAT		=	test2
	,fDebug		=	1
)

%*400.	Reverse the order of [Dat1] and [Dat2].;
%UnifyVarForDats(
	inDatLst	=	%nrbquote(
						UnifyVar_Dat2
						UnifyVar_Dat1
						UnifyVar_ModelDat
					)
	,ModelDat	=	UnifyVar_ModelDat
	,MixedType	=	Y
	,outDAT		=	test3
	,fDebug		=	1
)

%*500.	Restrict the multiple TYPE of any variable.;
%UnifyVarForDats(
	inDatLst	=	%nrbquote(
						UnifyVar_Dat2
						UnifyVar_Dat1
						UnifyVar_ModelDat
					)
	,ModelDat	=	UnifyVar_ModelDat
	,MixedType	=	N
	,outDAT		=	test4
	,fDebug		=	1
)

/*-Notes- -End-*/