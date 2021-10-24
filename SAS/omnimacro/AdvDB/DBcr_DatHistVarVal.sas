%macro DBcr_DatHistVarVal(
	inDAT		=
	,inKEY		=
	,updDATE	=
	,fPartial	=	0
	,outHIST	=
	,procLIB	=	WORK
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to track the changes of all values in the given data or series of data.										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDAT		:	The dataset from which the variable attributes are to be tracked.													|
|	|inKEY		:	The key list of the dataset which should be unique.																	|
|	|updDATE	:	The date on which the comparison is committed.																		|
|	|				 It should be a number instead of a string, such as 19721, or "01Dec2013"d.											|
|	|fPartial	:	The flag for Partial Update, can only be 1 or 0.																	|
|	|outHIST	:	The output pre-defined table containing the change history of the record values.									|
|	|procLIB	:	The processing library.																								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20140411		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
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
|	| Date |	20140425		| Version |	2.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Add Partial Update process.																									|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20140730		| Version |	2.30		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Add verification of existence of Numeric or Character fields.																|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180304		| Version |	2.40		| Updater/Creator |	Lu Robin Bin												|
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
|	|	|genvarlist																														|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvDB"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|DBmin_ChangeInHistory																											|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*003.	User Manual.;

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
%if	%length(%qsysfunc(compress(&outHIST.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]History Data is not provided!;
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

%if	&fPartial.	NE	1	%then	%let	fPartial	=	0;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))	=	0	%then	%let	procLIB		=	WORK;

%*013.	Define the local environment.;
%local
	CHRi
	oHistNm
	LnNUM
	LnCHR
	Cj
	Nj
;
%let	LnNUM	=	0;
%let	LnCHR	=	0;

%*020.	Further verify the parameters.;
%*021.	Retrieve the dataset name of the [outHIST] to prevent some issues when processing step600.;
%let	oHistNm	=	%ExtractDSNfrStr(inSTR=&outHIST.);

%if	%length(%qsysfunc(compress(&oHistNm.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.][outHIST=&outHIST.] does not contain valid SAS DS Name!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*100.	Prepare the variable list of the KEY.;
%genvarlist(
	nstart	=	1
	,inlst	=	&inKEY.
	,nvarnm	=	LeKeyVar
	,nvarttl=	LnKeyVar
)

%*110.	Retrieve the names of all character fields as well as numeric ones.;
PROC CONTENTS
	DATA=%unquote(&inDAT.)
	NOPRINT
	OUT=&procLIB..__spl_cnt
;
RUN;
data _NULL_;
	set
		&procLIB..__spl_cnt(
			where=(
					TYPE	=	1
				and	NAME	not	in	(
					%do	CHRi=1	%to	&LnKeyVar.;
						"&&LeKeyVar&CHRi.."
					%end;
				)
			)
		)
		end=EOF
	;
	if	_N_	then do;
		call symputx(cats("LeNUM",_N_),NAME,"L");
	end;
	if	EOF	then do;
		call symputx("LnNUM",_N_,"L");
	end;
run;
data _NULL_;
	set
		&procLIB..__spl_cnt(
			where=(
					TYPE	=	2
				and	NAME	not	in	(
					%do	CHRi=1	%to	&LnKeyVar.;
						"&&LeKeyVar&CHRi.."
					%end;
				)
			)
		)
		end=EOF
	;
	if	_N_	then do;
		call symputx(cats("LeCHR",_N_),NAME,"L");
	end;
	if	EOF	then do;
		call symputx("LnCHR",_N_,"L");
	end;
run;

%if	&LnCHR.	=	0	and	&LnNUM.	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]The update data [&inDAT.] does not have field for comparison!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*300.	Transpose the Character data.;
%*The reason why we separately process the character and the numeric is that:;
%* when transposing the entire data, all numeric fields will be put to "Character" by their respective formats,;
%* and this will insult unexpectable troubles.;
%if	&LnCHR.	^=	0	%then %do;
	%*100.	Direct transposition.;
	proc sort
		data=%unquote(&inDAT.)(
			keep=
				%unquote(&inKEY.)
			%do	Cj=1	%to	&LnCHR.;
				&&LeCHR&Cj..
			%end;
		)
		out=&procLIB..__spl_chr
	;
		by	%unquote(&inKEY.);
	run;
	proc transpose
		data=&procLIB..__spl_chr
		out=&procLIB..__spl_chr_trns
	;
		by	%unquote(&inKEY.);
		var
			%do	Cj=1	%to	&LnCHR.;
				&&LeCHR&Cj..
			%end;
		;
	run;

	%*200.	Purge.;
	data &procLIB..__spl_chr_out;
		set &procLIB..__spl_chr_trns;
		format
			C_VAR	$32.
			C_VAL	$1024.
		;
		length
			C_VAR	$32.
			C_VAL	$1024.
		;
		C_VAR	=	strip(_NAME_);
		C_VAL	=	strip(COL1);
		%*Make sure the data contains the valid records.;
		if	compress(COL1,,"wko")	^=	""	then do;
			output;
		end;
		keep
			%unquote(&inKEY.)
			C_VAR
			C_VAL
		;
	run;
%end;

%*400.	Transpose the Numeric data.;
%if	&LnNUM.	^=	0	%then %do;
	%*100.	Direct transposition.;
	proc sort
		data=%unquote(&inDAT.)(
			keep=
				%unquote(&inKEY.)
			%do	Nj=1	%to	&LnNUM.;
				&&LeNUM&Nj..
			%end;
		)
		out=&procLIB..__spl_num
	;
		by	%unquote(&inKEY.);
	run;
	proc transpose
		data=&procLIB..__spl_num
		out=&procLIB..__spl_num_trns
	;
		by	%unquote(&inKEY.);
		var
			%do	Nj=1	%to	&LnNUM.;
				&&LeNUM&Nj..
			%end;
		;
	run;

	%*200.	Purge.;
	data &procLIB..__spl_num_out;
		set &procLIB..__spl_num_trns;
		format
			C_VAR	$32.
			C_VAL	$1024.
		;
		length
			C_VAR	$32.
			C_VAL	$1024.
		;
		C_VAR	=	strip(_NAME_);
		C_VAL	=	strip(COL1);
		%*Make sure the data contains the valid records.;
		if	missing(COL1)	=	0	then do;
			output;
		end;
		keep
			%unquote(&inKEY.)
			C_VAR
			C_VAL
		;
	run;
%end;

%*490.	Usage to retrieve the numeric descriptions within the given range.;
/*
proc sql;
	create table b as (
		select *
		from a
		where
			case
				when compress(b,".","dk") = b
					then input(strip(b),best12.)>&inVAL.
				else 0
			end
			and	a="cc"
	);
quit;
*/

%*500.	Combine the transposed data for history update.;
data
	&procLIB..__spl_4upd(
		index=(
			HistDesc=(
				%unquote(&inKEY.)
				C_VAR
				D_TABLE
			)
			/unique
			/nomiss
		)
	)
;
	format	D_TABLE	yymmddD10.;
	D_TABLE	=	%unquote(&updDATE.);

	set
		%if	&LnCHR.	^=	0	%then %do;
			&procLIB..__spl_chr_out
		%end;
		%if	&LnNUM.	^=	0	%then %do;
			&procLIB..__spl_num_out
		%end;
	;
run;

%*600.	Update the history.;
%DBmin_ChangeInHistory(
	baseDAT		=	&oHistNm.
	,compDAT	=	&procLIB..__spl_4upd
	,CompDate	=	&updDATE.
	,fPartial	=	&fPartial.
	,byVAR		=	&inKEY.	C_VAR
	,inVAR		=	C_VAL
	,procLIB	=	&procLIB.
	,outDAT		=	&outHIST.
)

%*900.	Purge the memory.;
%*910.	Release PRX utilities.;
%ReleasePRX:

%EndOfProc:
%mend DBcr_DatHistVarVal;