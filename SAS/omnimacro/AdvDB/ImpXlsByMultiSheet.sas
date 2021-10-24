%macro ImpXlsByMultiSheet(
	inXLS		=
	,hdrSHEET	=
	,MergeProc	=	SET
	,byVAR		=
	,outDAT		=
	,procLIB	=	WORK
	,fDebug		=	0
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to import the EXCEL file within which there are multiple sheets of data.									|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inXLS		:	Input file name.																									|
|	|hdrSHEET	:	The sheet name (with "$" sign) in which there is Header/Title line, it should be blank if							|
|	|				 all sheets have Title lines.																						|
|	|MergeProc	:	The process to merge the datasets.																					|
|	|				[SET]   : Conduct the SET statement.																				|
|	|				[MERGE] : Conduct the MERGE statement.																				|
|	|				Default: [SET]																										|
|	|byVAR		:	The list of variables by which to merge the datasets.																|
|	|				The variable names should be split by WHITE SPACES when provided.													|
|	|				To purely SET the datasets, which means when [MergeProc=SET], this parameter can be left blank.						|
|	|outDAT		:	Output dataset.																										|
|	|procLIB	:	The working folder.																									|
|	|fDebug		:	The switch of Debug Mode. Valid values are [0] or [1].																|
|	|				Default: [0]																										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20130913		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20131022		| Version |	1.01		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Fix a bug when the functions of "min" and "max" are called while there is only one argument provided.						|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20131104		| Version |	1.02		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Add the verification of EXCEL file existence.																				|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20131121		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Add the compatibility to import the data as below format:																	|
|	|      |(1)Only one sheet has header, other sheets have no header.																	|
|	|      |(2)Data of all sheets have the same characteristics, i.e. number of fields, field sequence, etc..							|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20140412		| Version |	2.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Slightly enhance the program efficiency.																					|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20140912		| Version |	3.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Change the mechanism of the retrieval of EXCEL worksheet names.																|
|	|      |This is to prevent the weird "range" names to be recognized as Worksheet by SAS engine.										|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170811		| Version |	3.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Use macro function SUPERQ to prevent the sheet names from being resolved at the IMPORT Procedure.							|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170908		| Version |	3.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Fix a bug of SUPERQ when using the IMPORT Procedure with the [SHEET=] option.												|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180310		| Version |	3.30		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180331		| Version |	4.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |[1] Introduce the function [ForceMergeDats] to combine the required datasets in an independent way.							|
|	|      |[2] Add a parameter	[MergeProc] to allow user to [MERGE] the sheets instead of [SET] them directly.							|
|	|      |[3] Add debug mode.																											|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180422		| Version |	5.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the SQL query from [dictionary.columns] with [OPEN] function in DATA step, to improve the efficiency.				|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180503		| Version |	5.01		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |It is found that we only have to eliminate the leading spaces [regex: \s] in the sheet names, instead of all \W characters,	|
|	|      | during the call of this function.																							|
|	|      |However, we need to add another pair of quotation marks during importing these sheets.										|
|	|      |Test results:																												|
|	|      |[1] Double quotation marks cannot exist anywhere in the Sheet Name for SAS import, although they are accepted in EXCEL.		|
|	|      |[2] Single quotation marks cannot exist at the beginning and ending of the Sheet Name. This is because the EXCEL do not		|
|	|      |     accept them to embrace other characters in Sheet Name.																	|
|	|      |[3] Spaces cannot exist at the beginning of the Sheet Name for SAS import, although they are accepted in EXCEL.				|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|All sheets of the source file should have Title line (No longer necessary since v2.00).											|
|	|The same column in all the sheets should be of the same type, i.e. Numeric or Character.											|
|	|It is recommended that the contents of all sheets are in same shape, otherwise the result is unpredictable.						|
|	|The "hdrSHEET" SHOULD contain the sign of "$".																						|
|	|The "hdrSHEET" SHOULD BE BLANK if all sheets have Title lines.																		|
|	|Restrictions on Sheet Names:																										|
|	|(1) Sheet Name cannot start with \W (Perl Regular Expression) whose ASCII is less than 128 (0~127).								|
|	|(2) Sheet Name cannot contain Single or Double Quotation Marks.																	|
|	|    This comes from the libname engine restriction during import.																	|
|	|(3) All references to Sheet Names in this macro should use %nrbquote() function to concede special characters.						|
|	|    This impacts both the performance and the program sanitation^_^.																|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ErrMcr																															|
|	|	|getOBS4DATA																													|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvDB"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ForceMergeDats																													|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\FileSystem"																						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|VBS_getXLinf																													|
|	|	|FS_ATTRN																														|
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
%let	procLIB		=	%unquote(&procLIB.);

%if	%length(%qsysfunc(compress(&inXLS.,%str( ))))		=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No file is specified to import.;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%sysfunc(fileexist(&inXLS.))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]Specified file [&inXLS.] does not exist.;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&hdrSHEET.,%str( ))))	^=	0	%then %do;
	%if	%qsubstr(&hdrSHEET.,%length(&hdrSHEET.),1)		^=	$	%then %do;
		%put	%str(N)OTE: [&L_mcrLABEL.]Header name does not contain the trailing character [$].;
		%let	hdrSHEET	=	&hdrSHEET.$;
	%end;
%end;

%if	%length(%qsysfunc(compress(&MergeProc.,%str( ))))	=	0	%then	%let	MergeProc	=	SET;
%if	&MergeProc.	^=	SET	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]The process to merge the datasets is NOT [SET], it is presumed to be [MERGE].;
	%let	MergeProc	=	MERGE;
%end;

%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))		=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No output data is specified to import the file!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))		=	0	%then	%let	procLIB		=	WORK;
%if	%length(%qsysfunc(compress(&fDebug.,%str( ))))		=	0	%then	%let	fDebug		=	0;
%if	&fDebug.^=	0	%then	%let	fDebug		=	1;

%*013.	Define the local environment.;
%local
	OptNotes	OptSource	OptSource2	OptMLogic	OptSymGen	OptMPrint	OptInOper
	LhdrDAT		Lf_oneHdr
	LnTMPSH		Lnerrsheet	Lerrsheet	LkErrSH
	Si			SHi			Di			Vi
;
%let	LhdrDAT		=;
%let	LnTMPSH		=	0;
%let	Lnerrsheet	=	0;
%let	Lerrsheet	=;
%let	LkErrSH		=	0;

%*The justification of "hdrSHEET" is critical for import process.;
%if	%length(%qsysfunc(compress(&hdrSHEET.,%str( ))))	=	0	%then %do;
	%let	Lf_oneHdr	=	0;
%end;
%else %do;
	%let	Lf_oneHdr	=	1;
%end;

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

%*099.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*100.	All input values.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [inXLS=&inXLS.].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [hdrSHEET=&hdrSHEET.].;
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

%*100.	Retrieve all available sheets.;
%*110.	Load the basic information of the given workbook.;
%VBS_getXLinf(
	inWorkBook	=	&inXLS.
	,outDAT		=	&procLIB.._Import_xlinf
)

%*120.	Initialize the macro variables containing the sheet names.;
%getOBS4DATA(
	inDAT	=	&procLIB.._Import_xlinf
	,outVAR	=	LnTMPSH
	,gMode	=	P
)
%if	&LnTMPSH. = 0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Specified file [&inXLS.] has no sheet.;
	%goto	EndOfProc;
%end;
%do	SHi=1	%to	&LnTMPSH.;
	%local	LeTMPSH&SHi.;
%end;

%*150.	Retrieve the sheet names.;
data &procLIB.._Import_xlinf_add;
	%*100.	Read the information of each sheet.;
	set &procLIB.._Import_xlinf end=EOF;

	%*150.	Create new fields.;
	retain
		prxBGN		prxCNT		prxNR		0
	;
	length
		ModelDat	DATNUM					8
		DATNAME								$64
		tmpRSN		tmpRsnBgn	tmpRsnCnt	$32
		tmpMsg								$1024
	;
	ModelDat	=	0;
	DATNUM		=	_N_;
	tmpRSN		=	"";
	tmpRsnBgn	=	"";
	tmpRsnCnt	=	"";

	%*160.	Create the names of the temporary datasets.;
	DATNAME	=	upcase(cats("&procLIB..__impXlsMulti",_N_));
	call symputx(cats("LeTMPDAT",_N_),DATNAME,"L");

	%*200.	Abort the process if any sheet name has special characters;
	%*(1) Begin with non [0-9a-zA-Z_] characters.;
	%*(2) Contain Quotation Marks.;
	%*(3) Contain signs of Ampersand or Percent.;
	if	_N_	=	1	then do;
		prxBGN	=	prxparse('/^\s/i');
		prxCNT	=	prxparse('/"+/i');
		prxNR	=	prxparse('/[%&]+/i');
	end;
	if	prxmatch(prxNR, sheet)	then do;
		tmpMsg	=	catx(" " , "%str(W)ARNING: [&L_mcrLABEL.]Some sheet name contains Ampersand or Percent sign, result is unpredictable, file" , %sysfunc(quote([&inXLS.]!,%str(%'))));
		put	tmpMsg;
	end;
	%*Extended ASCII can be recognized by libname statement.;
	if	rank(sheet)	<	128	then do;
		if	prxmatch(prxBGN, sheet)	then do;
			tmpRsnBgn	=	"starts with \s characters";
		end;
	end;
	if	prxmatch(prxCNT, sheet)	then do;
		tmpRsnCnt	=	"contains Double Quote Signs";
	end;
	tmpRSN	=	catx(" and ", tmpRsnBgn, tmpRsnCnt);
	if	compress(tmpRSN,,"wko")	^=	""	then do;
		tmpMsg	=	catx(" " , %sysfunc(quote(%str(E)RROR: [&L_mcrLABEL.]Some sheet name)) , tmpRSN , ', file' , %sysfunc(quote([&inXLS.]!,%str(%'))));
		put	tmpMsg;
		abort abend;
	end;

	%*300.	Retrieve the sheet names.;
	%*We cannot use CALL SYMPUTX to generate local variables in this macro,;
	%* for there could be trailing BLANKS in the sheet names that we need to import;
	%* and SYMPUTX removes them.;
	call symput(cats("LeTMPSH",_N_),substr(sheet,1,lenShNm));

	%*400.	Identify the model dataset to unify the variables.;
	%*For the same reason as above, we cannot use [CATS] function to concatenate the sheet name with the [$] sign.;
	if		&Lf_oneHdr.	=	1
		and	symget('hdrSHEET')	=	substr(sheet,1,lenShNm)||"$"
		then do;
		ModelDat	=	1;
		%*Below counter is to ensure that the model dataset name is at the top of the list of datasets during the variable unification.;
		DATNUM		=	0;
		call symputx("LhdrDAT",DATNAME,"L");
	end;

	%*900.	Purge the memory.;
	if	EOF	then do;
		call prxfree(prxBGN);
		call prxfree(prxCNT);
		call prxfree(prxNR);
	end;
	drop
		prx:
		tmp:
	;
run;

%*199.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*100.	All sheets.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Program creates datasets for respective sheets as below:;
	%do	SHi=1	%to	&LnTMPSH.;
		%put	%str(I)NFO: [&L_mcrLABEL.][Sheet&SHi.=%superq(LeTMPSH&SHi.)$][Data&SHi.=&&LeTMPDAT&SHi..];
	%end;

	%*200.	Header Sheet.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Since [Lf_oneHdr=&Lf_oneHdr.], the model dataset is set as [LhdrDAT=&LhdrDAT.];
%end;

%*200.	Import all sheets separately.;
%do	SHi=1	%to	&LnTMPSH.;
	%*100.	Import each sheet.;
	PROC IMPORT
		OUT			=	&&LeTMPDAT&SHi..
		DATAFILE	=	%sysfunc(quote(&inXLS.,%str(%')))
		DBMS		=	EXCEL
		REPLACE
	;
		%*We cannot call another [QUOTE] function to add the second layer of quotation, for this will add unnecessary quotation marks in the name, causing (e)rrors.;
		%*Instead, we only add two single quotation marks at each end of the character string, to escape the existing single quotation marks appended by [QUOTE] function.;
		SHEET		=	''%sysfunc(quote(%superq(LeTMPSH&SHi.)$,%str(%')))'';
		%if		&Lf_oneHdr.	=	1
			and	[%superq(LeTMPSH&SHi.)$]	^=	[&hdrSHEET.]
			%then %do;
			GETNAMES	=	NO;
		%end;
		%else %do;
			GETNAMES	=	YES;
		%end;
		MIXED		=	YES;
		SCANTEXT	=	YES;
		USEDATE		=	YES;
		SCANTIME	=	YES;
	RUN;
%end;

%*300.	Rename the variables in all other datasets than [LhdrDAT], given that [hdrSHEET] is specified.;
%*301.	Skip this step if [hdrSHEET] is NOT specified.;
%if	&Lf_oneHdr.	=	0	%then %do;
	%goto	EndOfRename;
%end;

%*310.	Retrieve all the variables in all the datasets that were imported at earlier steps.;
%*311.	Retrieve all variable names.;
data &procLIB..__IXBMS_Var__;
	set &procLIB.._Import_xlinf_add;
	length
		varnum	8
		name	$32
	;
	length
		dsid	tmpi	8
	;
	dsid	=	open(strip(DATNAME));
	do tmpi=1 to attrn(dsid,"NVARS");
		varnum	=	tmpi;
		name	=	varname(dsid,tmpi);
		output;
	end;
	_iorc_	=	close(dsid);
	drop
		dsid	tmpi
	;
run;

%*315.	Retrieve the number of variables of the model dataset.;
%let	LnStdV	=	%FS_ATTRN( inDAT = &LhdrDAT. , inATTR = NVARS );

%*319.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*100.	# of variables in the model dataset.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Number of variables in the model sheet is: [LnStdV=&LnStdV.].;
%end;

%*320.	Identify those sheets with MORE variables than [hdrSHEET].;
proc freq
	data=&procLIB..__IXBMS_Var__
	noprint
;
	tables
			DATNAME
		*	sheet
		*	lenShNm
		/out=&procLIB..__IXBMS_ErrSH__(
			where=(
				COUNT	>	&LnStdV.
			)
		)
	;
run;

%*330.	Skip bombing the process if there is no sheet found with MORE variables than [hdrSHEET].;
%if	%getOBS4DATA( inDAT = &procLIB..__IXBMS_ErrSH__ , gMode = F )	=	0	%then %do;
	%goto	EndOfErrSH;
%end;

%*340.	Bomb the process if there are sheets with MORE variables than [hdrSHEET].;
data _NULL_;
	set &procLIB..__IXBMS_ErrSH__ end=EOF;
	%*For the same reason as above, we cannot use [SYMPUTX] routine to load the sheet name.;
	call symput(cats("LerrSH",_N_),substr(sheet,1,lenShNm));
	if	EOF	then do;
		call symputx("LkErrSH",_N_,"L");
	end;
run;
%put	%str(W)ARNING: [&L_mcrLABEL.]Below sheets have more variables than the header sheet [&hdrSHEET.]!;
%do Si=1 %to &LkErrSH.;
	%put	%str(W)ARNING: [&L_mcrLABEL.][&&LerrSH&Si..];
%end;
%put	&Lohno.;
%ErrMcr

%*349.	Mark the end of bombing the process.;
%EndOfErrSH:

%*350.	Prepare the statements to rename the variables in the respective datasets.;
proc sort
	data=&procLIB..__IXBMS_Var__
;
	by
		varnum
		DATNUM
	;
run;
data &procLIB..__IXBMS_VarRen__;
	%*100.	Set the variable list.;
	set &procLIB..__IXBMS_Var__;
	by
		varnum
		DATNUM
	;

	%*200.	Assign the new names to the respective variables.;
	length	newVName	$64;
	retain	newVName;
	if	first.varnum	then do;
		newVName	=	strip(name);
	end;
run;

%*360.	Create the statements for renaming.;
proc sort
	data=&procLIB..__IXBMS_VarRen__(
		where=(
			DATNAME	^=	%sysfunc(quote(&LhdrDAT.,%str(%')))
		)
	)
	out=&procLIB..__IXBMS_Ren__
;
	by
		DATNAME
		varnum
	;
run;
data _NULL_;
	%*100.	Set the list.;
	set &procLIB..__IXBMS_Ren__ end=EOF;
	by
		DATNAME
		varnum
	;

	%*150.	Create temporary fields.;
	retain
		tmpNDat	tmpNVar	0
	;

	%*200.	Increment the counter of datasets within which the variables are to be renamed.;
	if	first.DATNAME	then do;
		tmpNDat	+	1;
		tmpNVar	=	0;
		call symputx(cats("LeRenDat",tmpNDat),scan(DATNAME,2,"."),"L");
	end;

	%*500.	Add the current variable to the list.;
	if	upcase(name)	^=	upcase(newVName)	then do;
		tmpNVar	+	1;
		call symputx(cats("LeRenFr",tmpNDat,"_",tmpNVar),name,"L");
		call symputx(cats("LeRenTo",tmpNDat,"_",tmpNVar),newVName,"L");
	end;

	%*800.	Identify the count of variables to be renamed in current dataset.;
	if	last.DATNAME	then do;
		call symputx(cats("LnRenVar",tmpNDat),tmpNVar,"L");
	end;

	%*900.	Identify the count of datasets.;
	if	EOF	then do;
		call symputx("LnRenDat",tmpNDat,"L");
	end;
run;

%*369.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*100.	Total number of datasets within which to rename the variables.;
	%put	%str(I)NFO: [&L_mcrLABEL.]# of datasets, within which to rename the variables, is: [LnRenDat=&LnRenDat.];

	%*200.	Variables to be renamed.;
	%do Di=1 %to &LnRenDat.;
		%put	%str(I)NFO: [&L_mcrLABEL.]Variables to be renamed in [LeRenDat&Di.=&&LeRenDat&Di..] are [LnRenVar&Di.=&&LnRenVar&Di..], listed as below if any:;
		%do Vi=1 %to &&LnRenVar&Di..;
			%put	%str(I)NFO: [&L_mcrLABEL.][LeRenFr&Di._&Vi.=&&LeRenFr&Di._&Vi..][LeRenTo&Di._&Vi.=&&LeRenTo&Di._&Vi..];
		%end;
	%end;
%end;

%*380.	Rename the variables.;
proc datasets library=&procLIB. nolist;
	%do Di=1 %to &LnRenDat.;
		modify &&LeRenDat&Di..;
		rename
		%do Vi=1 %to &&LnRenVar&Di..;
			&&LeRenFr&Di._&Vi..	=	&&LeRenTo&Di._&Vi..
		%end;
		;
	%end;
quit;

%*390.	Mark the end of current step.;
%EndOfRename:

%*900.	Combine all data as imported.;
%ForceMergeDats(
	inDatLst	=	%do	SHi=1	%to	&LnTMPSH.;
						&&LeTMPDAT&SHi..
					%end;
	,ModelDat	=	&LhdrDAT.
	,MixedType	=	Y
	,MergeProc	=	&MergeProc.
	,byVAR		=	&byVAR.
	,outDAT		=	&outDAT.
	,fDebug		=	&fDebug.
)

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
%mend ImpXlsByMultiSheet;

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

%*050.	Setup a dummy macro [ErrMcr] to prevent the session to be bombed.;
%macro	ErrMcr;	%mend	ErrMcr;

%*100.	Load an EXCEL file within which all sheets have header lines.;
%ImpXlsByMultiSheet(
	inXLS		=	%nrstr(D:\SAS\omnimacro\AdvDB\test_ImpXlsByMultiSheet.xlsx)
	,hdrSHEET	=
	,MergeProc	=	SET
	,byVAR		=
	,outDAT		=	test1
	,procLIB	=	WORK
	,fDebug		=	1
)

%*200.	Load an EXCEL file within which only one sheet have header line.;
%ImpXlsByMultiSheet(
	inXLS		=	%nrstr(D:\SAS\omnimacro\AdvDB\test_ImpXlsByMultiSheet_OneHdr.xlsx)
	,hdrSHEET	=	%nrstr(AcctInfo)
	,MergeProc	=	SET
	,byVAR		=
	,outDAT		=	test2
	,procLIB	=	WORK
	,fDebug		=	1
)

%*300.	Use [MERGE] instead of [SET].;
%ImpXlsByMultiSheet(
	inXLS		=	%nrstr(D:\SAS\omnimacro\AdvDB\test_ImpXlsByMultiSheet.xlsx)
	,hdrSHEET	=
	,MergeProc	=	MERGE
	,byVAR		=	%nrstr(CustNo ID)
	,outDAT		=	test3
	,procLIB	=	WORK
	,fDebug		=	1
)

%*400.	Load an EXCEL file with special characters in the Sheet Names.;
%ImpXlsByMultiSheet(
	inXLS		=	%nrstr(D:\SAS\omnimacro\AdvDB\test_ImpXlsByMultiSheet_SpChar.xlsx)
	,hdrSHEET	=
	,MergeProc	=	SET
	,byVAR		=
	,outDAT		=	test4
	,procLIB	=	WORK
	,fDebug		=	1
)

/*-Notes- -End-*/