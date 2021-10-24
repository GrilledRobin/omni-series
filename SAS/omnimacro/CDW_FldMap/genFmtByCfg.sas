%macro genFmtByCfg(
	inFmtLst			=
	,inFmtVal			=
	,ProcOption			=
	,C_FORMAT_TYPE		=	C_FORMAT_TYPE
	,C_FORMAT_NAME		=	C_FORMAT_NAME
	,C_FORMAT_VTYPE		=	C_FORMAT_VTYPE
	,C_FORMAT_OPTION	=	C_FORMAT_OPTION
	,N_VAL_GROUP_SEQ	=	N_VAL_GROUP_SEQ
	,C_VAL_LOWER		=	C_VAL_LOWER
	,FC_VAL_INC_LOWER	=	FC_VAL_INC_LOWER
	,C_VAL_UPPER		=	C_VAL_UPPER
	,FC_VAL_INC_UPPER	=	FC_VAL_INC_UPPER
	,C_OUTPUT_VAL		=	C_OUTPUT_VAL
	,C_OUTPUT_OPTION	=	C_OUTPUT_OPTION
	,procLIB			=	WORK
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to setup User Defined Formats in terms of a configuration table.											|
|	|Scenarios to use this macro are:																									|
|	|[1] The User Defined Formats can vary due to Business cases																		|
|	|[2] The Formatted Values comprise a subset of the entire User Defined Format while the report should display all possible values	|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inFmtLst			:	The dataset containing the list of User Defined Format Names and Format Options								|
|	|inFmtVal			:	The dataset containing the value groups of above User Defined Formats, as well as value group options		|
|	|ProcOption			:	The overall options for the PROC FORMAT statement.															|
|	|C_FORMAT_TYPE		:	SAS dataset variable name for Format Type																	|
|	|C_FORMAT_NAME		:	SAS dataset variable name for Format Name																	|
|	|C_FORMAT_VTYPE		:	SAS dataset variable name for Format Value Type, representing Numeric or Character input values				|
|	|C_FORMAT_OPTION	:	SAS dataset variable name for Format Options, see Base SAS Procedures Guide for more information			|
|	|N_VAL_GROUP_SEQ	:	SAS dataset variable name for Format Value Group Sequence, useful when using MULTILABLE option				|
|	|C_VAL_LOWER		:	SAS dataset variable name for Lower Bound in current value group for the Format								|
|	|FC_VAL_INC_LOWER	:	SAS dataset variable name for Whether to include the Lower Bound in current value group for the Format		|
|	|C_VAL_UPPER		:	SAS dataset variable name for Upper Bound in current value group for the Format								|
|	|FC_VAL_INC_UPPER	:	SAS dataset variable name for Whether to include the Upper Bound in current value group for the Format		|
|	|C_OUTPUT_VAL		:	SAS dataset variable name for Output Value of current value group for the Format, always Character			|
|	|C_OUTPUT_OPTION	:	SAS dataset variable name for Options for Formatted Value													|
|	|procLIB			:	The working library.																						|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20180127		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180310		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180608		| Version |	1.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Place a single White Space if the output value is indicated as Blank in the configuration table, to prevent the FORMAT		|
|	|      | Procedure from generating a quotation mark.																				|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180722		| Version |	1.30		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Leverage the additional option field of the function [QUOTE] to eliminate unexpected results.								|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|1. Setup a META data, or [inFmtLst] in below format, which contains all the User Defined Format Names:								|
|	|Note: The [C_FORMAT_TYPE], [C_FORMAT_NAME] and [C_FORMAT_VTYPE] jointly define a unique Format in SAS.								|
|	|	|C_FORMAT_TYPE		$16			(Type of Format: [INVALUE], [PICTURE] or [VALUE])												|
|	|	|C_FORMAT_NAME		$32			(Name of Format, WITHOUT the $ sign for character formats)										|
|	|	|C_FORMAT_VTYPE		$2			(Input Value Type of Format: [N] stands for Numeric Values as input, [C] for Characters)		|
|	|	|C_FORMAT_OPTION	$32767		(Options for current Format: see Base SAS Procedures Guide for more information)				|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|2. Setup a META data, or [inFmtVal] in below format, which contains all the value groups for formatting:							|
|	|Note: The [C_FORMAT_TYPE], [C_FORMAT_NAME] and [C_FORMAT_VTYPE] jointly define a unique Format in SAS.								|
|	|	|C_FORMAT_TYPE		$16			(Type of Format: [INVALUE], [PICTURE] or [VALUE])												|
|	|	|C_FORMAT_NAME		$32			(Name of Format, WITHOUT the $ sign for character formats)										|
|	|	|C_FORMAT_VTYPE		$2			(Input Value Type of Format: [N] stands for Numeric Values as input, [C] for Characters)		|
|	|	|N_VAL_GROUP_SEQ	3			(Sequence to create the value group. It is crucial once MULTILABLE is used)						|
|	|	|C_VAL_LOWER		$32767		(Lower bound of the current value group, WITHOUT quotation marks even for character values)		|
|	|	|FC_VAL_INC_LOWER	$1			(Whether to include the Lower Bound in current value group: [1]-Include, [0]-Exclude)			|
|	|	|C_VAL_UPPER		$32767		(Upper bound of the current value group, WITHOUT quotation marks even for character values)		|
|	|	|FC_VAL_INC_UPPER	$1			(Whether to include the Upper Bound in current value group: [1]-Include, [0]-Exclude)			|
|	|	|C_OUTPUT_VAL		$32767		(Formatted Value: it is always a Character String as defined in FORMAT Procedure)				|
|	|	|C_OUTPUT_OPTION	$32767		(Options for Formatted Value: see Base SAS Procedures Guide for more information)				|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|3. Run this macro in terms of the META data, to create the User Defined Formats.													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
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
%if	%length(%qsysfunc(compress(&inFmtLst.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No [Format List] is specified! [inFmtLst]=[&inFmtLst.]. Program skipped!;
	%goto	EndOfProc;
%end;
%if	%length(%qsysfunc(compress(&inFmtVal.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No [Format Value Groups] is specified! [inFmtVal]=[&inFmtVal.]. Program skipped!;
	%goto	EndOfProc;
%end;
%if	%length(%qsysfunc(compress(&C_FORMAT_TYPE.,%str( ))))		=	0	%then	%let	C_FORMAT_TYPE		=	C_FORMAT_TYPE;
%if	%length(%qsysfunc(compress(&C_FORMAT_NAME.,%str( ))))		=	0	%then	%let	C_FORMAT_NAME		=	C_FORMAT_NAME;
%if	%length(%qsysfunc(compress(&C_FORMAT_VTYPE.,%str( ))))		=	0	%then	%let	C_FORMAT_VTYPE		=	C_FORMAT_VTYPE;
%if	%length(%qsysfunc(compress(&C_FORMAT_OPTION.,%str( ))))		=	0	%then	%let	C_FORMAT_OPTION		=	C_FORMAT_OPTION;
%if	%length(%qsysfunc(compress(&N_VAL_GROUP_SEQ.,%str( ))))		=	0	%then	%let	N_VAL_GROUP_SEQ		=	N_VAL_GROUP_SEQ;
%if	%length(%qsysfunc(compress(&C_VAL_LOWER.,%str( ))))			=	0	%then	%let	C_VAL_LOWER			=	C_VAL_LOWER;
%if	%length(%qsysfunc(compress(&FC_VAL_INC_LOWER.,%str( ))))	=	0	%then	%let	FC_VAL_INC_LOWER	=	FC_VAL_INC_LOWER;
%if	%length(%qsysfunc(compress(&C_VAL_UPPER.,%str( ))))			=	0	%then	%let	C_VAL_UPPER			=	C_VAL_UPPER;
%if	%length(%qsysfunc(compress(&FC_VAL_INC_UPPER.,%str( ))))	=	0	%then	%let	FC_VAL_INC_UPPER	=	FC_VAL_INC_UPPER;
%if	%length(%qsysfunc(compress(&C_OUTPUT_VAL.,%str( ))))		=	0	%then	%let	C_OUTPUT_VAL		=	C_OUTPUT_VAL;
%if	%length(%qsysfunc(compress(&C_OUTPUT_OPTION.,%str( ))))		=	0	%then	%let	C_OUTPUT_OPTION		=	C_OUTPUT_OPTION;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))				=	0	%then	%let	procLIB				=	WORK;

%*013.	Define the global environment.;

%*014.	Define the local environment.;
%local
	rc
	intStmt
	filrf
	prxBrackets
	prxUnderscs
;
%let	prxBrackets	=	%nrstr((\[\s*[[:alpha:]]\w{0,31}(\(\)|\.\d*)\s*\]));
%let	prxUnderscs	=	%str((_SAME_|_%str(E)RROR_));

%*100.	Bomb the process if the Format Type is not valid.;
data &procLIB.._FBC_Ftype;
	set	%unquote(&inFmtLst.);
	if	upcase(&C_FORMAT_TYPE.)	not	in	("INVALUE" "PICTURE" "VALUE")	then	output;
run;
%if	%getOBS4DATA( inDAT = &procLIB.._FBC_Ftype , gMode = F )	^=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.][inFmtLst]=[&inFmtLst.] contains unrecognized Format Type in the variable [&C_FORMAT_TYPE.]!;
	%ErrMcr
%end;

%*200.	Bomb the process if any of the formats are NOT defined in [inFmtLst].;
proc sql noprint;
	create table &procLIB.._FBC_FVld as (
		select a.*
		from %unquote(&inFmtVal.) as a
		where not exists (
			select 1
			from %unquote(&inFmtLst.) as b
			where	a.&C_FORMAT_TYPE.	=	b.&C_FORMAT_TYPE.
				and	a.&C_FORMAT_NAME.	=	b.&C_FORMAT_NAME.
				and	a.&C_FORMAT_VTYPE.	=	b.&C_FORMAT_VTYPE.
		)
	);
quit;
%if	%getOBS4DATA( inDAT = &procLIB.._FBC_FVld , gMode = F )	^=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]There are formats NOT defined in [&inFmtLst.]! Find data [&procLIB.._FBC_FVld] for details.;
	%ErrMcr
%end;

%*400.	Sort the input dataset for process.;
proc sort
	data=%unquote(&inFmtVal.)
	out=&procLIB.._FBC_Val
;
	by
		&C_FORMAT_TYPE.
		&C_FORMAT_NAME.
		&C_FORMAT_VTYPE.
		&N_VAL_GROUP_SEQ.
	;
run;

%*500.	Prepare the statement for FORMAT Procedure.;
%*510.	Setup the temporary file in the WORK library, which will contain the termporary statements.;
%let	intStmt	=	myFmts;
%let	rc		=	%sysfunc(filename(intStmt,%qsysfunc(pathname(work))));

%*520.	Assign the FileRef for writing the text messages.;
%let	filrf	=	myTmpFmt;
%let	rc		=	%sysfunc(filename( filrf , fmtStmt.txt , , encoding="%sysfunc(getoption(encoding))" , &intStmt. ));

%*550.	Write the statements to the text file.;
data _NULL_;
	%*010.	Set the dataset of Format Values.;
	set	&procLIB.._FBC_Val end=EOF;
	by
		&C_FORMAT_TYPE.
		&C_FORMAT_NAME.
		&C_FORMAT_VTYPE.
		&N_VAL_GROUP_SEQ.
	;

	%*100.	Create variables.;
	length
		FilID		8
		FilRC		8
		rcHash		3
		tmp_Stmt	$32767
		C_FMT_PFX	$64
		F_HasLower	3
		F_HasUpper	3
		F_HasOpt	3
	;
	retain	FilID;
	C_FMT_PFX	=	ifc( upcase(&C_FORMAT_VTYPE.) = "C" , "$" , "" );
	F_HasLower	=	1 - missing(&C_VAL_LOWER.);
	F_HasUpper	=	1 - missing(&C_VAL_UPPER.);
	F_HasOpt	=	1 - missing(&C_OUTPUT_OPTION.);

	%*200.	Prepare the text file as output for the statements.;
	%*201.	Overwrite the file with a blank content, in case it exists, in order to create a blank file for operation.;
	if	_N_	=	1	then do;
		FilID	=	fopen("&filrf.","O");
		FilRC	=	fread(FilID);
		FilRC	=	fput(FilID," ");
		FilRC	=	fwrite(FilID);
		FilRC	=	fclose(FilID);
	end;

	%*210.	Open the file at APPEND mode so that each FWRITE function will write a new line.;
	if	_N_	=	1	then do;
		FilID	=	fopen("&filrf.","A");
	end;

	%*300.	Prepare the HASH object to load the Format Options.;
	if	0	then	set	%unquote(&inFmtLst.);
	if	_N_	=	1	then do;
		dcl	hash	hFmt(dataset:"%unquote(&inFmtLst.)");
		hFmt.DefineKey("&C_FORMAT_TYPE.","&C_FORMAT_NAME.","&C_FORMAT_VTYPE.");
		hFmt.DefineData("&C_FORMAT_OPTION.");
		hFmt.DefineDone();
	end;
	call missing(&C_FORMAT_OPTION.);

	%*400.	Initialize the statement at the beginning of each Format.;
	if	first.&C_FORMAT_VTYPE.	then do;
		%*100.	Prepare the primary statement.;
		tmp_Stmt	=	catx( " " , &C_FORMAT_TYPE. , cats( C_FMT_PFX , &C_FORMAT_NAME. ) );

		%*200.	Append the options if any.;
		rcHash		=	hFmt.find();
		if	missing(&C_FORMAT_OPTION.)	=	0	then do;
			tmp_Stmt	=	catx( " " , tmp_Stmt , "(" , &C_FORMAT_OPTION. , ")" );
		end;

		%*900.	Write the statement.;
		FilRC	=	fput(FilID,strip(tmp_Stmt));
		FilRC	=	fwrite(FilID);
	end;

	%*500.	Add current value group to the statement.;
	%*510.	Add definition if the [Lower Bound] exists.;
	if	F_HasLower	then do;
		FilRC	=	fput(
						FilID
						,catx( " "
							,ifc(
									&C_FORMAT_VTYPE. = "N"
								or	upcase(&C_VAL_LOWER.) in ("LOW" "HIGH" "OTHER")
								or	prxmatch( "/\(\s*REGEXP(E)?\s*\)/ismx" , &C_VAL_LOWER. )
								,&C_VAL_LOWER.
								,quote(strip(&C_VAL_LOWER.),"'")
							)
						)
					)
		;
	end;

	%*520.	Add connection if both [Lower Bound] and [Upper Bound] exist.;
	if	F_HasLower	and	F_HasUpper	then do;
		FilRC	=	fput(FilID,cats( ifc( &FC_VAL_INC_LOWER. = "0" , "<" , "" ) , "-" , ifc( &FC_VAL_INC_UPPER. = "0" , "<" , "" ) ));
	end;

	%*530.	Add definition if the [Upper Bound] exists.;
	if	F_HasUpper	then do;
		FilRC	=	fput(
						FilID
						,catx( " "
							,ifc(
									&C_FORMAT_VTYPE. = "N"
								or	upcase(&C_VAL_UPPER.) in ("LOW" "HIGH" "OTHER")
								or	prxmatch( "/\(\s*REGEXP(E)?\s*\)/ismx" , &C_VAL_UPPER. )
								,&C_VAL_UPPER.
								,quote(strip(&C_VAL_UPPER.),"'")
							)
						)
					)
		;
	end;

	%*540.	Add the output value for current value group.;
	%*IMPORTANT: Functions and Internal Formats in the definition of output value CANNOT be quoted!;
	%*IMPORTANT: Unmatched Brackets or underscores are NOT verified in below statement, which is a risk during compilation!;
	FilRC	=	fput(
					FilID
					,catx(" "
						,"="
						,ifc(
								( upcase(&C_FORMAT_TYPE.) in ("INVALUE") and &C_FORMAT_VTYPE. = "N" )
							or	prxmatch( "/^(&prxBrackets.|&prxUnderscs.)$/ismx" , strip(&C_OUTPUT_VAL.) )
							,ifc(missing(&C_OUTPUT_VAL.)," ",strip(&C_OUTPUT_VAL.))
							,quote(ifc(missing(&C_OUTPUT_VAL.)," ",strip(&C_OUTPUT_VAL.)),"'")
						)
					)
				)
	;

	%*580.	Add the options to current value group if any.;
	if	F_HasOpt	then do;
		FilRC	=	fput(FilID,catx( " " , "(" , &C_OUTPUT_OPTION. , ")" ));
	end;

	%*590.	Write the whole FDB to the file.;
	FilRC	=	fwrite(FilID);

	%*600.	Close current format.;
	if	last.&C_FORMAT_VTYPE.	then do;
		FilRC	=	fput(FilID,";");
		FilRC	=	fwrite(FilID);
	end;

	%*900.	Close the file after all statements have been written.;
	if	EOF	then do;
		FilRC	=	fclose(FilID);
	end;
run;

%*800.	Run the FORMAT Procedure to setup the User Defined Formats.;
proc format
%if	%length(%qsysfunc(compress(&ProcOption.,%str( ))))	^=	0	%then %do;
	%unquote(&ProcOption.)
%end;
;
%include &filrf.;
run;

%EndOfProc:
%mend genFmtByCfg;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvOp"
		"D:\SAS\omnimacro\CDW_FldMap"
	)
	mautosource
;
%*Prevent the program from being bombed.;
%macro ErrMcr;
%mend ErrMcr;

%let	UserFile	=	D:\SAS\omnimacro\CDW_FldMap\test_genFmtByCfg.xlsx;

PROC IMPORT
	OUT			=	FmtLstPre
	DATAFILE	=	"&UserFile."
	DBMS		=	EXCEL
	REPLACE
;
	SHEET		=	"Formats$";
	GETNAMES	=	YES;
	MIXED		=	NO;
	SCANTEXT	=	YES;
	USEDATE		=	YES;
	SCANTIME	=	YES;
RUN;
PROC IMPORT
	OUT			=	FmtValPre
	DATAFILE	=	"&UserFile."
	DBMS		=	EXCEL
	REPLACE
;
	SHEET		=	"FmtValues$";
	GETNAMES	=	YES;
	MIXED		=	NO;
	SCANTEXT	=	YES;
	USEDATE		=	YES;
	SCANTIME	=	YES;
RUN;
PROC IMPORT
	OUT			=	FmtData
	DATAFILE	=	"&UserFile."
	DBMS		=	EXCEL
	REPLACE
;
	SHEET		=	"Data$";
	GETNAMES	=	YES;
	MIXED		=	NO;
	SCANTEXT	=	YES;
	USEDATE		=	YES;
	SCANTIME	=	YES;
RUN;

data FmtLst;
	length
		C_FORMAT_TYPE		$16
		C_FORMAT_NAME		$32
		C_FORMAT_VTYPE		$2
		C_FORMAT_OPTION		$32767
	;
	set FmtLstPre;
	C_FORMAT_TYPE		=	strip(FmtType);
	C_FORMAT_NAME		=	strip(FmtName);
	C_FORMAT_VTYPE		=	strip(FmtVType);
	C_FORMAT_OPTION		=	strip(FmtOpt);
run;
data FmtVal;
	length
		C_FORMAT_TYPE		$16
		C_FORMAT_NAME		$32
		C_FORMAT_VTYPE		$2
		N_VAL_GROUP_SEQ		3
		C_VAL_LOWER			$32767
		FC_VAL_INC_LOWER	$1
		C_VAL_UPPER			$32767
		FC_VAL_INC_UPPER	$1
		C_OUTPUT_VAL		$32767
		C_OUTPUT_OPTION		$32767
	;
	set FmtValPre;
	C_FORMAT_TYPE		=	strip(FmtType);
	C_FORMAT_NAME		=	strip(FmtName);
	C_FORMAT_VTYPE		=	strip(FmtVType);
	N_VAL_GROUP_SEQ		=	ValSeq;
	C_VAL_LOWER			=	strip(ValLower);
	FC_VAL_INC_LOWER	=	strip(IncLower);
	C_VAL_UPPER			=	strip(ValUpper);
	FC_VAL_INC_UPPER	=	strip(IncUpper);
	C_OUTPUT_VAL		=	strip(ValOut);
	C_OUTPUT_OPTION		=	strip(OutOpt);
run;

%genFmtByCfg(
	inFmtLst	=	FmtLst
	,inFmtVal	=	FmtVal
	,procLIB	=	WORK
)

data DataFormatted;
	set	FmtData;
	length
		fmt_txt		$64
		fmt_Rev1	8
		fmt_Rev2	8
		fmt_RevYTD1	8
		fmt_RevYTD2	8
		fmt_RPQ		$64
		fmt_AUM		$64
		fmt_dttm	8
	;
	format
		fmt_dttm	datetime23.3
	;
	fmt_txt		=	strip(input(Txt,TxtToNbr.));
	fmt_Rev1	=	input(strip(put(Revenue,RMB10KND.)),comma32.);
	fmt_Rev2	=	input(strip(put(Revenue,RMB10K2D.)),comma32.2);
	fmt_RevYTD1	=	input(strip(put(YTDRevenue,RMB100MND.)),comma32.);
	fmt_RevYTD2	=	input(strip(put(YTDRevenue,RMB100M2D.)),comma32.2);
	fmt_RPQ		=	put(RPQ,$RPQ.);
	fmt_AUM		=	put(AUM,fAUM.);
	fmt_dttm	=	input(dttm,MDYDTTM.);
run;

%*Output.;

/*-Notes- -End-*/