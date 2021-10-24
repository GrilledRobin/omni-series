%macro DBcr_LoadDlmFileByCfg(
	inDlmFile	=
	,inVarDef	=
	,inFileOpt	=
	,preProc	=
	,outDAT		=
	,procLIB	=	WORK
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to load the delimiter-sensitive file into SAS dataset in terms of the given variable mapping table.			|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDlmFile	:	The text file with specific delimiter separating the variables, to be loaded into SAS dataset.						|
|	|inVarDef	:	The META data that is used to translate the LABELS into standard SAS variable names.								|
|	|inFileOpt	:	The additional options that should be applied in the INFILE statement.												|
|	|				If it is left blank, the default INFILE statement only has two options: <FileRef> and <DSD>.						|
|	|preProc	:	The statements to pre-control the input values. There MUST be ending semi-colon [;] to complete the statements.		|
|	|				This process is often applied to the internal variable [_INFILE_].													|
|	|outDAT		:	The translated dataset.																								|
|	|procLIB	:	The working library.																								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20170815		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180304		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180404		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Add pre-control to the input file, especially when there are extra comma signs in CSV file, for user to manually adjust.	|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180722		| Version |	2.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Leverage the additional option field of the function [QUOTE] to eliminate unexpected results.								|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20210121		| Version |	3.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |[1] Remove the default option [DSD] for [infile] and leave it to the input from user										|
|	|      |[2] Program now conducts processes in terms of the provision of [VARNUM] in the mapping table [inVarDef]					|
|	|      |    [1] When [VARNUM] exists in [inVarDef], program uses it as the sequence of the fields to import data					|
|	|      |    [2] When [VARNUM] does not exist in [inVarDef], program follows below steps to import the data by fields:				|
|	|      |        [1] Regard the first line of the input data as the field labels, and mark their positions as [VARNUM]				|
|	|      |        [2] Match the labels with those in the [inVarDef] to prepare their respective attributes for import					|
|	|      |        [3] Import the data from the second line to the end of the input file in terms of above attributes					|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|1. Setup a META data, or [inVarDef] in below format (same as the output of CONTENTS procedure), where the VARNUM denotes the 		|
|	|    same position of the variables to be imported:																					|
|	|	|VARNUM		best12.		(Crucial to identify the correct variable in the input file)											|
|	|	|LABEL		$256.		(Should be the same as the header row in the raw source file)											|
|	|	|NAME		$32.		(Should be the SAS variable name to be defined)															|
|	|	|TYPE		best12.		(1 or 2)																								|
|	|	|LENGTH		best12.																												|
|	|	|FORMAT		$32.																												|
|	|	|FORMATL	best12.																												|
|	|	|FORMATD	best12.																												|
|	|	|INFORMAT	$32.		(Should be the same as observed in the raw source file)													|
|	|	|INFORML	best12.		(Should be the same as observed in the raw source file)													|
|	|	|INFORMD	best12.		(Should be the same as observed in the raw source file)													|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|3. Run this macro to import the file, in terms of the META data, to translate the variables as the predefined [NAME].				|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from [&cdwmac.\AdvOp]																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ErrMcr																															|
|	|	|getOBS4DATA																													|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from [&cdwmac.\AdvDB]																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|DBcr_TransVarByLabel																											|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from [&cdwmac.\FileSystem]																						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|FS_VarExists																													|
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
%if	%length(%qsysfunc(compress(&inDlmFile.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No input data [inDlmFile] is specified! Program stopped!;
	%goto	EndOfProc;
%end;
%if	%length(%qsysfunc(compress(&inVarDef.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No Definition data [inVarDef] is specified! Program stopped!;
	%goto	EndOfProc;
%end;
%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))		=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No output data [outDAT] is specified! Program stopped!;
	%goto	EndOfProc;
%end;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))		=	0	%then	%let	procLIB	=	WORK;

%*013.	Define the global environment.;

%*014.	Define the local environment.;
%local
	LmaxRecL
	LnImpVar
	LlabelOpt
	LfVARNUM
	LdfVarDef
	LinvldObs
	LkInvld
	Vi
	Vj
;
%let	LmaxRecL	=	0;
%let	LfVARNUM	=	%FS_VarExists( inDAT = &inVarDef. , inFLD = VARNUM );
%if	&LfVARNUM.	=	1	%then %do;
	%let	LdfVarDef	=	&inVarDef.;
%end;
%else %do;
	%let	LdfVarDef	=	&procLIB..__ImpDlm_VarDef;
%end;

%*100.	Load the field labels from the data file if there is no indicator as [VARNUM] in the mapping table.;
%*101.	Skip loading field labels if [VARNUM] exists in [inVarDef].;
%if	&LfVARNUM.	=	1	%then	%goto	EndOfLabels;

%*110.	Remove the possible options [*over], [FIRSTOBS] and [OBS] from the user provided set.;
%*We cannot simply replace these options in the string, as there could be no such options provided.;
%let	LlabelOpt	=	%qsysfunc(prxchange( %str( s/((first)?obs[[:space:]]*=[[:space:]]*)(\d+)//ismx ) , -1 , &inFileOpt. ));
%*We remove the [*over] options as they conflict with the operand [@@] during input.;
%let	LlabelOpt	=	%qsysfunc(prxchange( %str( s/[a-z]+over//ismx ) , -1 , &LlabelOpt. ));

%*130.	Read the first line of the input data file for identification.;
data &procLIB..__ImpDlm_labels;
	%*100.	Define the input file.;
	infile
		%*The reason why we cannot simply use ["&inDlmFile."], but use a special statement, is described below:;
		%*[1] Value of [inDlmFile] could be longer than 262 characters. This will lead SAS to issue a (W)ARMING message in the log, which we prefer to avoid.;
		%*[2] Since we have to add quotation marks to the value to fulfill [INFILE] statement, we need to apply a [QUOTE] function to the value of [inDlmFile].;
		%*[3] In macro facility, once we apply any function to a character string, its original "macro quoting" status will have been changed.;
		%*[4] To avoid any possible special characters, which are macro-quoted within [inDlmFile], to be resolved, we should use the additional option for [QUOTE] function.;
		%*[5] The purpose is to surround the value by SINGLE QUOTATION MARKS in macro facility process, while keep it from being macro-quoted.;
		%*[6] This is because during DATA process, no statement is allowed to be macro-quoted, otherwise SAS will issue an (E)RROR message.;
		%sysfunc(quote(&inDlmFile.,%str(%')))
		%unquote(&LlabelOpt.)
		FIRSTOBS	=	1
		OBS			=	1
	;

	%*150.	Create new fields.;
	length
		VARNUM	8
		LABEL	$32767
	;
	retain
		VARNUM	0
	;

	%*500.	Translate the values into field labels.;
	%*Read the entire line by user definition into one field, one by one.;
	input	LABEL	$	@@;

	%*600.	Define the sequence of the variables.;
	VARNUM	+	1;
run;

%*150.	Check it with the meta mapping table [inVarDef] as provided.;
proc sql;
	%*100.	Load the field attributes.;
	create table &LdfVarDef. as (
		select
			a.VARNUM
			,b.*
		from &procLIB..__ImpDlm_labels as a
		left join %unquote(&inVarDef.) as b
		on	a.LABEL	=	b.LABEL
	);

	%*900.	Search for those fields not-existing in [inVarDef].;
	create table &procLIB..__ImpDlm_VarMis as (
		select
			a.*
		from &procLIB..__ImpDlm_labels as a
		left join %unquote(&inVarDef.) as b
		on	a.LABEL	=	b.LABEL
		where missing(b.LABEL)	=	1
	)
	order by VARNUM
	;
quit;

%*170.	Abort the process if there is any label not found in [inVarDef].;
%*171.	Check whether there is any record in the validation dataset.;
%getOBS4DATA(
	inDAT	=	&procLIB..__ImpDlm_VarMis
	,outVAR	=	LinvldObs
	,gMode	=	P
)

%*172.	Skip the step of messaging if everything goes right.;
%if	&LinvldObs.	=	0	%then	%goto	EndOfVarMis;

%*174.	Prepare the messages to be printed into log.;
data _NULL_;
	set	&procLIB..__ImpDlm_VarMis end=EOF;
	call symputx(cats('LeInvld',_N_),cats('[VARNUM=',VARNUM,'][LABEL=',LABEL,']'),'F');
	if	EOF	then do;
		call symputx('LkInvld',_N_,'F');
	end;
run;

%*178.	Print the messages and abort the process.;
%put	%str(W)ARNING: [&L_mcrLABEL.]Some labels are in the source file but not in the mapping table!;
%put	%str(W)ARNING: [&L_mcrLABEL.]Source file: [&inDlmFile.];
%put	%str(W)ARNING: [&L_mcrLABEL.]Labels as positions:;
%do Vj=1 %to &LkInvld.;
	%put	%str(W)ARNING: [&L_mcrLABEL.]&&LeInvld&Vj..;
%end;
%put	%str(W)ARNING: [&L_mcrLABEL.]Please update mapping table: [&inVarDef.];
%ErrMcr

%*179.	Mark the end of messaging.;
%EndOfVarMis:

%*199.	Mark the end of this step.;
%EndOfLabels:

%*500.	Retrieve the maximum length of all variables to be loaded, to determine the input buffer size.;
proc sql noprint;
	select
		max(max(LENGTH,FORMATL,INFORML))
	into
		:LmaxRecL
	from %unquote(&LdfVarDef.)
	;
quit;
%let	LmaxRecL	=	%eval(&LmaxRecL.);

%*600.	Define the variables to be loaded.;
%*610.	Sort the meta data by VARNUM.;
proc sort
	data=%unquote(&LdfVarDef.)
	out=&procLIB..__ImpDlm_Meta
;
	by	VARNUM;
run;

%*650.	Create necessary macro variables.;
data _NULL_;
	%*001.	Set the data.;
	set &procLIB..__ImpDlm_Meta end=EOF;
	by VARNUM;

	%*100.	Call necessary macro variables.;
	call symputx(cats("LinName",_N_),cats("_COL",_N_),"L");
	call symputx(cats("LinLbl",_N_),quote(strip(LABEL),"'"),"L");
	if	EOF	then do;
		call symputx("LkVar",_N_,"L");
	end;
run;

%*800.	Read the file.;
data &procLIB..__ImpDlm_pre;
	%*100.	Prepare the input definition.;
	infile
		%sysfunc(quote(&inDlmFile.,%str(%')))
		%unquote(&inFileOpt.)
	;

	%*150.	Input the buffer and hold its value to the next input statement.;
	input @;

	%*300.	Apply the pre-control process if any.;
%if	%length(%qsysfunc(compress(&preProc.,%str( ))))	^=	0	%then %do;
	%unquote(&preProc.)
%end;

	%*500.	Create the series of temporary variables to hold the input buffer values.;
	array
		arrTvar{&LkVar.}
		$&LmaxRecL.
	%do Vi=1 %to &LkVar.;
		&&LinName&Vi..
	%end;
	;
	call missing(of arrTvar{*});

	%*600.	Read the buffer values as translated above.;
	input	arrTvar{*}	$;

	%*800.	Assign labels to these variables for the later translation.;
	%*This statement should be created separately, since there could be NO label for any of the fields.;
	%do Vi=1 %to &LkVar.;
		%if	&&LinLbl&Vi..	^=	''	%then %do;
			label	&&LinName&Vi..	=	&&LinLbl&Vi..;
		%end;
	%end;
run;

%*900.	Translation.;
%DBcr_TransVarByLabel(
	inDAT		=	&procLIB..__ImpDlm_pre
	,inVarDef	=	&inVarDef.
	,outDAT		=	&outDAT.
	,procLIB	=	&procLIB.
)

%EndOfProc:
%mend DBcr_LoadDlmFileByCfg;

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
%*Prevent the program from being bombed.;
%macro ErrMcr;
%mend ErrMcr;

%let	inflnm	=	D:\SAS\omnimacro\AdvDB\test_DBcr_ImpDlmFileByCfg.csv;

data def;
	format
		VARNUM		best12.
		LABEL		$256.
		NAME		$32.
		TYPE		best12.
		LENGTH		best12.
		FORMAT		$32.
		FORMATL		best12.
		FORMATD		best12.
		INFORMAT	$32.
		INFORML		best12.
		INFORMD		best12.
	;
	VARNUM		=	1;
	LABEL		=	"×Ö¶Î1";
	NAME		=	"var1";
	TYPE		=	2;
	LENGTH		=	8;
	FORMAT		=	"$";
	FORMATL		=	16;
	FORMATD		=	0;
	INFORMAT	=	"$";
	INFORML		=	8;
	INFORMD		=	0;
	output;

	VARNUM		=	2;
	LABEL		=	'×Ö¶Î2 %pa';
	NAME		=	"var2";
	TYPE		=	1;
	LENGTH		=	8;
	FORMAT		=	"COMMA";
	FORMATL		=	12;
	FORMATD		=	2;
	INFORMAT	=	"COMMA";
	INFORML		=	12;
	INFORMD		=	0;
	output;

	VARNUM		=	3;
	LABEL		=	"×Ö¶Î4";
	NAME		=	"var3";
	TYPE		=	2;
	LENGTH		=	16;
	FORMAT		=	"$";
	FORMATL		=	16;
	FORMATD		=	0;
	INFORMAT	=	"COMMA";
	INFORML		=	12;
	INFORMD		=	2;
	output;

	VARNUM		=	4;
	LABEL		=	"×Ö¶Î5";
	NAME		=	"var5";
	TYPE		=	1;
	LENGTH		=	8;
	FORMAT		=	"DATETIME";
	FORMATL		=	22;
	FORMATD		=	0;
	INFORMAT	=	"YMDDTTM";
	INFORML		=	21;
	INFORMD		=	1;
	output;

	VARNUM		=	5;
	LABEL		=	"column7";
	NAME		=	"var7";
	TYPE		=	1;
	LENGTH		=	8;
	FORMAT		=	"";
	FORMATL		=	8;
	FORMATD		=	0;
	INFORMAT	=	"";
	INFORML		=	10;
	INFORMD		=	0;
	output;

	VARNUM		=	6;
	LABEL		=	"¹«Ë¾";
	NAME		=	"company";
	TYPE		=	2;
	LENGTH		=	32;
	FORMAT		=	"$";
	FORMATL		=	32;
	FORMATD		=	0;
	INFORMAT	=	"$";
	INFORML		=	32;
	INFORMD		=	0;
	output;

	VARNUM		=	7;
	LABEL		=	"ÐÕÃû";
	NAME		=	"Name";
	TYPE		=	2;
	LENGTH		=	32;
	FORMAT		=	"$";
	FORMATL		=	32;
	FORMATD		=	0;
	INFORMAT	=	"$";
	INFORML		=	32;
	INFORMD		=	0;
	output;

	%*Please test the new method without regard to [VARNUM] if you wish.;
%*	drop	VARNUM;
run;

%DBcr_LoadDlmFileByCfg(
	inDlmFile	=	&inflnm.
	,inVarDef	=	def
	,inFileOpt	=	%nrstr(
						dlm			=	","
						dsd
						missover
						lrecl		=	1024
						firstobs	=	2
					)
	,preProc	=	%nrstr(
						retain tmpPRX_NULL 0;
						drop tmpPRX_NULL;
						if tmpPRX_NULL = 0 then tmpPRX_NULL = prxparse('s/(\s*NULL\s*)(?=,|$)//ix');
						if prxmatch(tmpPRX_NULL,_infile_) then _infile_ = prxchange(tmpPRX_NULL,-1,_infile_);
						retain tmpPRX_Company tmpPRX_Name 0;
						drop tmpPRX_Company tmpPRX_Name;
						if tmpPRX_Company = 0 then tmpPRX_Company = prxparse('s/([^,]+CO\.?\s*,\s*L(TD)?[^,]*?)(?=,|$)/"\1"/ismx');
						if prxmatch(tmpPRX_Company,_infile_) then _infile_ = prxchange(tmpPRX_Company,-1,_infile_);
						if tmpPRX_Name = 0 then tmpPRX_Name = prxparse('s/(Johnson\s*,\s*Charles\s*)(?=,|$)/"\1"/ismx');
						if prxmatch(tmpPRX_Name,_infile_) then _infile_ = prxchange(tmpPRX_Name,-1,_infile_);
					)
	,outDAT		=	new
	,procLIB	=	WORK
)

%*Output.;

/*-Notes- -End-*/