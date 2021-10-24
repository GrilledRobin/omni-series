%macro CollapseRptCategory(
	inDat		=
	,KeyVar		=
	,BlankVal	=	%str(99. Others)
	,LayerPfx	=	%str(C_RPT_SEG_L)
	,outDAT		=
	,procLIB	=	WORK
	,fDebug		=	0
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to collapse the sub-layers of the reporting categories for each one listed the [KeyVar], and unify them		|
|	| into the standard fields which indicate the layers of the categories respectively.												|
|	|See the attached file [test_CollapseRptCategory.xlsx] as example, wichin which [Before] indicates the manual maintenance file,		|
|	| [After] indicates the unified categorization for each one in the [KeyVar].														|
|	|The primary purpose is to adapt the probably dynamic report templates with various layers at different reporting period.			|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Rules: (The period sign [.] in the field label will be automatically translated into [#] during PROC IMPORT from EXCEL)			|
|	|	|-------------------------------------------------------------------------------------------------------------------------------|
|	|	|[Field Name]/[Extract the numbering from the category name] %str(s/^(\d+\#?|\d+(\#\d+)+)(\s+.*)$/\1/ix)						|
|	|	|[Field Name]/[Extract the rest part from the category name] %str(s/^(\d+\#?|\d+(\#\d+)+)(\s+.*)$/\3/ix)						|
|	|	|[Number of current category layer] (Remove the trailing [#] if any) countc([var],'#') + 1										|
|	|	|All fields, except the [KeyVar], that do not match this rule will be regarded as a separate category with single layer.		|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDat		:	The dataset that stores the original table to be unified for report tabulation										|
|	|KeyVar		:	The list of Key field names, for which to unify the reporting categories											|
|	|BlankVal	:	The default value if any of the sub-categories of any [KeyVar] is missing during the unification					|
|	|				Default: [99. Others]																								|
|	|LayerPfx	:	The prefix of the reporting layers identified in the process, as a series of variables to be output					|
|	|				There will be new variables created as [LayerPfx<1>] to [LayerPfx<N>] in the output dataset, where [LayerPfx<1>]	|
|	|				 stands as the root layer of current category.																		|
|	|				Default: [C_RPT_SEG_L]																								|
|	|outDAT		:	The output result.																									|
|	|procLIB	:	The working library.																								|
|	|fDebug		:	The switch of Debug Mode. Valid values are [0] or [1].																|
|	|				Default: [0]																										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20190302		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
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
|	|	|ErrMcr																															|
|	|	|getCOLbyStrPattern																												|
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

%if	%length(%qsysfunc(compress(&KeyVar.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]Class variable list [KeyVar=] is NOT provided!;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&BlankVal.,%str( ))))	=	0	%then	%let	BlankVal	=	%str(99. Others);
%if	%length(%qsysfunc(compress(&LayerPfx.,%str( ))))	=	0	%then	%let	LayerPfx	=	%str(C_RPT_SEG_L);
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))		=	0	%then	%let	procLIB		=	WORK;
%if	%length(%qsysfunc(compress(&fDebug.,%str( ))))		=	0	%then	%let	fDebug		=	0;
%if	&fDebug.^=	0	%then	%let	fDebug		=	1;

%*013.	Define the local environment.;
%local
	OptNotes	OptSource	OptSource2	OptMLogic	OptSymGen	OptMPrint	OptInOper
	PrxExclVar	L_kLayer	L_LayerLen
	Ei			Ti			Li			Lj
;
%let	PrxExclVar	=;
%let	L_kLayer	=	0;
%let	L_LayerLen	=	0;

%*016.	Switch off the system options to reduce the LOG size.;
%if %sysfunc(getoption( notes ))		=	NOTES		%then	%let	OptNotes	=	1;	%else	%let	OptNotes	=	0;
%if %sysfunc(getoption( source ))		=	SOURCE		%then	%let	OptSource	=	1;	%else	%let	OptSource	=	0;
%if %sysfunc(getoption( source2 ))		=	SOURCE2		%then	%let	OptSource2	=	1;	%else	%let	OptSource2	=	0;
%if %sysfunc(getoption( mlogic ))		=	MLOGIC		%then	%let	OptMLogic	=	1;	%else	%let	OptMLogic	=	0;
%if %sysfunc(getoption( symbolgen ))	=	SYMBOLGEN	%then	%let	OptSymGen	=	1;	%else	%let	OptSymGen	=	0;
%if %sysfunc(getoption( mprint ))		=	MPRINT		%then	%let	OptMPrint	=	1;	%else	%let	OptMPrint	=	0;
%if %sysfunc(getoption( minoperator ))	=	MINOPERATOR	%then	%let	OptInOper	=	1;	%else	%let	OptInOper	=	0;
%*The default value of the system option [MINDELIMITER] is WHITE SPACE, given the option [MINOPERATOR] is on.;
%if	&fDebug.	=	0	%then %do;
options nonotes nosource nosource2 nomlogic nosymbolgen nomprint minoperator;
%end;

%*018.	Define the global environment.;
%genvarlist(
	nstart		=	1
	,inlst		=	&KeyVar.
	,nvarnm		=	LeKey
	,nvarttl	=	LnKey
)
%do Ei=1 %to &LnKey.;
	%let	PrxExclVar	=	&PrxExclVar.|&&LeKey&Ei..;
%end;
%let	PrxExclVar	=	%qsubstr( &PrxExclVar. , 2 );

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in traditional SAS syntax colors.;
%macro dummy; %mend dummy;

%*099.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*100.	All input values.;
	%if	%length(%qsysfunc(compress(&inDat.,%str( ))))	=	0	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [inDat=];
	%end;
	%else %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [inDat=%qsysfunc(compbl(&inDat.))];
	%end;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [KeyVar=%qsysfunc(compbl(&KeyVar.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [BlankVal=&BlankVal.];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [LayerPfx=&LayerPfx.];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [outDAT=%qsysfunc(compbl(&outDAT.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [procLIB=&procLIB.];

	%*200.	Variables identified as the keys for which to identify the report categories.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Below variable(s) are considered as keys for which to identify the report categories:;
	%do Ei=1 %to &LnKey.;
		%put	%str(I)NFO: [&L_mcrLABEL.]Variable Name: [LeKey&Ei.=&&LeKey&Ei..];
	%end;
%end;

%*100.	Transpose the input dataset.;
%*110.	Identify all variables EXCEPT the ones listed in [KeyVar].;
%getCOLbyStrPattern(
	inDAT		=	&inDat.
	,inRegExp	=
	,exclRegExp	=	%nrbquote(^(&PrxExclVar.)$)
	,chkVarTP	=	ALL
	,outCNT		=	LnTRNS
	,outELpfx	=	LeTRNS
)

%*119.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%put	%str(I)NFO: [&L_mcrLABEL.]Below variables are to be transposed for category identification:;
	%do Ti=1 %to &LnTRNS.;
		%put	%str(I)NFO: [&L_mcrLABEL.]Variable Name: [LeTRNS&Ti.=&&LeTRNS&Ti..];
	%end;
%end;

%*150.	Transpose all the identified variables by [KeyVar], while storing their labels for further process.;
proc sort
	data=%unquote(&inDat.)
	out=&procLIB.._CRptC_indat
;
	by	&KeyVar.;
run;
proc transpose
	data=&procLIB.._CRptC_indat
	out=&procLIB.._CRptC_indat_trns
;
	by	&KeyVar.;
	var
	%do Ti=1 %to &LnTRNS.;
		&&LeTRNS&Ti..
	%end;
	;
run;

%*200.	Identify different layers of the categories.;
data &procLIB.._CRptC_seg_pre;
	%*010.	Set the data.;
	set	&procLIB.._CRptC_indat_trns;

	%*050.	Create new fields.;
	length
		__N_LAYER	8
		__LAYER_VAL	$32767
	;
	length
		PRX_Layer	PRX_Lname	PRX_trail	3
		tmp__s_org	tmp__s_id	tmp__s_nam	$32767
	;
	retain	PRX_Layer	PRX_Lname	PRX_trail	0;

	%*060.	Prepare the RegExp to identify the different layers.;
	%*061.	Validate the reporting category.;
	if	PRX_Layer	=	0	then	PRX_Layer	=	prxparse("s/^(\d+\#?|\d+(\#\d+)+)(\s+.*)$/\1/ix");
	if	PRX_Lname	=	0	then	PRX_Lname	=	prxparse("s/^(\d+\#?|\d+(\#\d+)+)(\s+.*)$/\3/ix");

	%*062.	Validate the trailing sign (#) of the layer identifier.;
	if	PRX_trail	=	0	then	PRX_trail	=	prxparse("s/^(.+?)\#+\s*$/\1/ix");

	%*100.	Split the characters into Layer Identifier and Layer Name.;
	%*110.	Extract the Layer Identifier.;
	if	prxmatch( PRX_Layer , _LABEL_ )	then do;
		tmp__s_org	=	prxchange( PRX_Layer , 1 , _LABEL_ );
	end;

	%*120.	Remove the trailing sign (#) if any.;
	if	prxmatch( PRX_trail , tmp__s_org )	then do;
		tmp__s_id	=	prxchange( PRX_trail , 1 , tmp__s_org );
	end;
	else do;
		tmp__s_id	=	tmp__s_org;
	end;

	%*150.	Extract the Layer Name.;
	if	prxmatch( PRX_Lname , _LABEL_ )	then do;
		tmp__s_nam	=	prxchange( PRX_Lname , 1 , _LABEL_ );
	end;

	%*200.	Store the Layer Number of current category.;
	__N_LAYER	=	countc( tmp__s_id , "#" ) + 1;

	%*300.	Form the category name in terms of the naming convention.;
	%*The function [CATS] cannot be used as there may be leading white spaces in the Layer Name.;
	__LAYER_VAL	=	strip(translate( tmp__s_org , "." , "#" ))||tmp__s_nam;

	%*990.	Purge.;
	drop
		PRX_:	tmp__:
	;
run;

%*300.	Identify the maximum layers within the entire report template.;
proc sql noprint;
	select	max(__N_LAYER)
	into	:L_kLayer
	from &procLIB.._CRptC_seg_pre
	;
quit;
%let	L_kLayer	=	%eval( %sysfunc(strip(&L_kLayer.)) + 1 );

%*309.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%put	%str(I)NFO: [&L_mcrLABEL.]Maximum layer among all reporting categories is: [L_kLayer=&L_kLayer.];
%end;

%*400.	Determine the unified length of the series of Layer variables to be output.;
%*The variable [COL1] was created by TRANSPOSE Procedure.;
proc sql noprint;
	select	max(max( length(__LAYER_VAL) , length(COL1) ))
	into	:L_LayerLen
	from &procLIB.._CRptC_seg_pre
	;
quit;
%*Set the number as the minimum <N>th power to 2 that is just larger than the retrieved one.;
%let	L_LayerLen	=	%eval( 2** %sysfunc(ceil( %sysfunc(log(&L_LayerLen.)) / %sysfunc(log(2)) )) );

%*309.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%put	%str(I)NFO: [&L_mcrLABEL.]Unified length of all layers for all reporting categories is: [L_LayerLen=&L_LayerLen.];
%end;

%*600.	Collapse the layers to each root category.;
data &procLIB.._CRptC_seg;
	%*010.	Only set the root categories.;
	set
		&procLIB.._CRptC_seg_pre(
			where=(
				__N_LAYER	=	1
			)
		)
	;

	%*050.	Create new fields.;
	length
	%do Li=1 %to &L_kLayer.;
		%sysfunc(strip(&LayerPfx.))&Li.	$&L_LayerLen.
	%end;
	;

	%*100.	Define the report category at Layer 1.;
	if	missing(__LAYER_VAL)	then do;
		%*This part is for all additional reporting categories that do not match the naming convention of the ones with sub-layers.;
		%sysfunc(strip(&LayerPfx.))1	=	_LABEL_;
		%sysfunc(strip(&LayerPfx.))2	=	COL1;
	end;
	else do;
		%sysfunc(strip(&LayerPfx.))1	=	__LAYER_VAL;
	end;

	%*199.	Skip to search for sub-layers if there is not any.;
	if	&L_kLayer.	<=	2	then	goto	EndSubL;

	%*200.	Prepare the HASH objects to load the data at different sub-layers.;
	%do Li=1 %to %eval( &L_kLayer. - 1);
		if	0	then	set	&procLIB.._CRptC_seg_pre( where=( __N_LAYER = &Li. ) rename=( COL1 = tmp__val&Li. ) );
		if	_N_	=	1	then do;
			dcl	hash	hLayer&Li.(dataset:"&procLIB.._CRptC_seg_pre( where=( __N_LAYER = &Li. ) rename=( COL1 = tmp__val&Li. ) )");
			hLayer&Li..DefineKey(
			%do Ei=1 %to &LnKey.;
				"&&LeKey&Ei..",
			%end;
				"__LAYER_VAL"
			);
			hLayer&Li..DefineData( "tmp__val&Li." );
			hLayer&Li..DefineDone();
		end;
		call missing( tmp__val&Li. );
	%end;

	%*500.	Retrieve all sub-layers in line for each root category.;
	%do Li=1 %to %eval( &L_kLayer. - 1);
		%let	Lj	=	%eval( &Li. + 1 );
		if	hLayer&Li..Check(
			%do Ei=1 %to &LnKey.;
				key:&&LeKey&Ei..,
			%end;
				key:%sysfunc(strip(&LayerPfx.))&Li.
			)	=	0
			then do;
			_iorc_	=	hLayer&Li..find(
						%do Ei=1 %to &LnKey.;
							key:&&LeKey&Ei..,
						%end;
							key:%sysfunc(strip(&LayerPfx.))&Li.
						)
			;
			%sysfunc(strip(&LayerPfx.))&Lj.	=	tmp__val&Li.;
		end;
	%end;

	%*890.	Mark the end of the process to identify the sub-layers.;
	EndSubL:

	%*990.	Purge.;
	drop
		_NAME_	_LABEL_	COL1
		__:
		tmp__:
	;
run;

%*800.	Output.;
data %unquote(&outDAT.);
	%*010.	Set the data.;
	set	&procLIB.._CRptC_seg;

	%*100.	If any of the sub-layers are BLANK, they should be categorized as [BlankVal].;
	array	arrLayer	%sysfunc(strip(&LayerPfx.)):;
	do over arrLayer;
		if	missing(arrLayer)	then	arrLayer	=	%sysfunc(quote( &BlankVal. , %str(%') ));
	end;
run;

%*900.	Purge.;

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
%mend CollapseRptCategory;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvDB"
		"D:\SAS\omnimacro\AdvOp"
		"D:\SAS\omnimacro\FileSystem"
	)
	mautosource
;
%let	L_srcflnm	=	D:\SAS\omnimacro\AdvDB\test_CollapseRptCategory.xlsx;
%let	L_stpflnm	=	RptCategory;

%*050.	Setup a dummy macro [ErrMcr] to prevent the session to be bombed.;
%macro	ErrMcr;	%mend	ErrMcr;

%*100.	Import the configuration table.;
PROC IMPORT
	OUT			=	RptCat_pre(where=(missing(Pdt_Code)=0))
	DATAFILE	=	%sysfunc(quote( &L_srcflnm. , %str(%') ))
	DBMS		=	EXCEL
	REPLACE
;
	SHEET		=	"Before$";
	GETNAMES	=	YES;
	MIXED		=	NO;
	SCANTEXT	=	YES;
	USEDATE		=	YES;
	SCANTIME	=	YES;
RUN;

%*200.	Unify the report categories.;
%CollapseRptCategory(
	inDat		=	RptCat_pre
	,KeyVar		=	Pdt_Code
	,BlankVal	=	%str(99. Others)
	,LayerPfx	=	%str(C_SEG_L)
	,outDAT		=	&L_stpflnm.
	,procLIB	=	WORK
	,fDebug		=	1
)

/*-Notes- -End-*/