%macro DBcr_DatHistVarAttr(
	inDAT		=
	,updDATE	=
	,outMETA	=
	,procLIB	=	WORK
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to track the changes of each variable or field in the given data or series of data.							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDAT		:	The dataset from which the variable attributes are to be tracked.													|
|	|updDATE	:	The date on which the comparison is committed.																		|
|	|				 It should be a number instead of a string, such as 19721, or "01Dec2013"d.											|
|	|outMETA	:	The output pre-defined table containing the change history of the variable attributes.								|
|	|procLIB	:	The processing library.																								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20140410		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20140412		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Slightly enhance the program efficiency.																					|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20140418		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Should there be any dataset option specified during the macro variable reference, there could be errors						|
|	|      | reported when the marco is called. We eliminate the possibility to happen by validating the DS name.						|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20140420		| Version |	2.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Standardize the program to extract the valid DSN.																			|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180304		| Version |	2.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ErrMcr																															|
|	|	|ExtractDSNfrStr																												|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvDB"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|DBmin_ChangeInHistory																											|
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
%if	%length(%qsysfunc(compress(&outMETA.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]Meta Data is not provided!;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&inDAT.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]Update Data is not provided!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%sysfunc(exist(&inDAT.))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Specified file [&inDAT.] does not exist, the Meta Data will have no change.;
	%goto	EndOfProc;
%end;

%if	%length(%qsysfunc(compress(&updDATE.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No Update date is provided, the last update date will be set as system date.;
	%let	updDATE	=	"&sysdate."d;
%end;

%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))	=	0	%then	%let	procLIB		=	WORK;

%*013.	Define the local environment.;
%local
	oMetaNm
;

%*020.	Further verify the parameters.;
%*021.	Retrieve the dataset name of the &outHIST. to prevent some issues when processing step600.;
%let	oMetaNm	=	%ExtractDSNfrStr(inSTR=&outMETA.);

%if	%length(%qsysfunc(compress(&oMetaNm.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.][outMETA=&outMETA.] does not contain valid SAS DS Name!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*100.	Retrieve the attributes of all variables in the given data.;
proc contents
	data=%unquote(&inDAT.)
	out=&procLIB..__attrupd_cnt(
		keep=
			NAME
			TYPE
			LENGTH
			VARNUM
			LABEL
			FORMAT
			FORMATL
			FORMATD
	)
	noprint
;
run;

%*200.	Fix some information for future retrieval.;
data &procLIB..__attrupd_fix;
	set &procLIB..__attrupd_cnt;

	%*For all variables.;
	if	FORMAT	=	""	then do;
		FORMATL	=	max(FORMATL,LENGTH);
	end;

	%*For distinguished variables.;
	if	TYPE	=	2	then do;
		if	FORMAT	=	""	then do;
			FORMAT	=	"$";
		end;
	end;
run;

%*300.	Transposition.;
%*310.	Transpose all variables.;
proc sort
	data=&procLIB..__attrupd_fix
;
	by	NAME;
run;
proc transpose
	data=&procLIB..__attrupd_fix
	out=&procLIB..__attrupd_trns(
		where=(
			_NAME_	^=	"NAME"
		)
	)
;
	by	NAME;
	var	_all_;
run;

%*320.	Remove leading and trailing blanks generated by above statements.;
data &procLIB..__attrupd_4std;
	set &procLIB..__attrupd_trns;
	array
		arrALL
		_all_
	;
	do over arrALL;
		arrALL	=	strip(arrALL);
	end;
run;

%*400.	Standardization.;
data &procLIB..__attrupd_4upd;
	format	D_TABLE	yymmddD10.;
	D_TABLE	=	%unquote(&updDATE.);

	set &procLIB..__attrupd_4std;
	format
		C_VAR	$32.
		C_ATTR	$16.
		C_AVAL	$256.
	;
	length
		C_VAR	$32.
		C_ATTR	$16.
		C_AVAL	$256.
	;
	C_VAR	=	NAME;
	C_ATTR	=	_NAME_;
	C_AVAL	=	COL1;
	keep
		D_TABLE
		C_VAR
		C_ATTR
		C_AVAL
	;
run;

%*600.	Update the pre-defined table.;
%DBmin_ChangeInHistory(
	baseDAT		=	&oMetaNm.
	,compDAT	=	&procLIB..__attrupd_4upd
	,CompDate	=	&updDATE.
	,fPartial	=	0
	,byVAR		=	C_VAR	C_ATTR
	,inVAR		=	C_AVAL
	,procLIB	=	&procLIB.
	,outDAT		=	&outMETA.
)

%*900.	Purge the memory.;
%*910.	Release PRX utilities.;
%ReleasePRX:

%EndOfProc:
%mend DBcr_DatHistVarAttr;