%macro DBuse_transDescVarAsCol(
	inDAT		=
	,attrDAT	=
	,byVAR		=	C_KEY
	,descVAR	=	C_VAR
	,valVAR		=	C_VAL
	,dateVAR	=	D_DATA
	,procLIB	=	WORK
	,outDAT		=
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to change the descriptive information of the given KEY into the (original)									|
|	| Column-style, for reporting or tabulating purpose, in terms of the given &dateVAR. which is										|
|	| unnecessarily single, i.e. we can retrieve descriptive fields on two dates at the same procedure.									|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDAT		:	The dataset to be transposed.																						|
|	|attrDAT	:	The dataset containing the attributes of all the Descriptive Fields to be converted.								|
|	|byVAR		:	The key by which the data is transposed.																			|
|	|descVAR	:	The variable containing the Descriptive Fields.																		|
|	|				 It should be only one field existing in the input data.															|
|	|valVAR		:	The variable containing the values of the Descriptive Fields.														|
|	|				 It should be only one field existing in the input data.															|
|	|dateVAR	:	The variable containing the date to retrieve the attribute of the Descriptive Fields.								|
|	|				 It should be only one field existing in the input data.															|
|	|procLIB	:	The processing library.																								|
|	|outDAT		:	The transposed result.																								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20140412		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180304		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Should any Descriptive Field be Character in the searched history, it will be transposed as Character.								|
|	|&dateVAR. should exist in the input dataset to determine the lookup date of each record.											|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ErrMcr																															|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\FileSystem"																						|
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
%if	%length(%qsysfunc(compress(&inDAT.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]Data-for-transposition is not provided!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%sysfunc(exist(&inDAT.))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]Specified file [&inDAT.] does not exist.;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&attrDAT.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]Attribute data is not provided!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%sysfunc(exist(&attrDAT.))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]Attribute data [&attrDAT.] does not exist.;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&byVAR.,%str( ))))	=	0	%then	%let	byVAR		=	C_KEY;
%if	%length(%qsysfunc(compress(&descVAR.,%str( ))))	=	0	%then	%let	descVAR		=	C_VAR;
%if	%length(%qsysfunc(compress(&valVAR.,%str( ))))	=	0	%then	%let	valVAR		=	C_VAL;
%if	%length(%qsysfunc(compress(&dateVAR.,%str( ))))	=	0	%then	%let	dateVAR		=	D_DATA;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))	=	0	%then	%let	procLIB		=	WORK;

%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]Output data is not specified!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*013.	Define the local environment.;
%local
	DESCi
	PRXID
;
%*We only allow one SAS data variable by the verification below.;
%let	PRXID	=	%sysfunc(prxparse(/^[[:alpha:]_]\w{0%str(,)31}?$/i));

%*020.	Further verify the parameters.;
%*025.	Validate &descVAR..;
%if	%sysfunc(prxmatch(&PRXID.,&descVAR.))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]descVAR [&descVAR.] is not one valid SAS data field!;
	%put	&Lohno.;
	%ErrMcr
%end;
%*Verify its existence in the &inDAT.;
%if	%FS_VarExists(inDAT=&inDAT.,inFLD=&descVAR.)	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]descVAR [&descVAR.] does not exist in inDAT [&inDAT.]!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*026.	Validate &valVAR..;
%if	%sysfunc(prxmatch(&PRXID.,&valVAR.))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]valVAR [&valVAR.] is not one valid SAS data field!;
	%put	&Lohno.;
	%ErrMcr
%end;
%*Verify its existence in the &inDAT.;
%if	%FS_VarExists(inDAT=&inDAT.,inFLD=&valVAR.)	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]valVAR [&valVAR.] does not exist in inDAT [&inDAT.]!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*027.	Validate &dateVAR..;
%if	%sysfunc(prxmatch(&PRXID.,&dateVAR.))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]dateVAR [&dateVAR.] is not one valid SAS data field!;
	%put	&Lohno.;
	%ErrMcr
%end;
%*Verify its existence in the &inDAT.;
%if	%FS_VarExists(inDAT=&inDAT.,inFLD=&dateVAR.)	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]dateVAR [&dateVAR.] does not exist in inDAT [&inDAT.]!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*100.	Determine the appropriate attributes to facilitate the transponsition.;
%*If there are 2 or more values of &dateVAR. in the given dataset:;
%*Given any attribute of the same Field at the different given &dateVAR. values are different:;
%*TYPE		:	We use the maximum one (character if any);
%*LENGTH	:	We use the maximum one;
%*VARNUM	:	We use the maximum one;
%*LABEL		:	We use the latest one;
%*FORMAT	:	We use the latest one, but compromise to the final TYPE;
%*FORMATL	:	We use the maximum one;
%*FORMATD	:	We use the maximum one;

%*110.	Retrieve the attribute checkpoint for each Descriptive Field.;
proc sql
	noprint
	threads
;
	create table &procLIB..DescTrns_4attr as (
		select distinct
			a.%unquote(&descVAR.)
			,a.%unquote(&dateVAR.)
			,d.C_ATTR
			,d.C_AVAL
		from %unquote(&inDAT.) as a
		left join %unquote(&attrDAT.) as d
			on	upcase(a.%unquote(&descVAR.))	=	upcase(d.%unquote(&descVAR.))
				and	a.%unquote(&dateVAR.)	>=	d.D_BGN
				and	a.%unquote(&dateVAR.)	<=	d.D_END
	)
	order by
		%unquote(&descVAR.)
		,%unquote(&dateVAR.)
	;
quit;

%*120.	Transpose the attribute information by the &dateVAR..;
proc transpose
	data=&procLIB..DescTrns_4attr
	out=&procLIB..DescTrns_4attr_trns
;
	by
		%unquote(&descVAR.)
		%unquote(&dateVAR.)
	;
	id
		C_ATTR
	;
	var
		C_AVAL
	;
run;

%*130.	Prepare to arrange the fields by VARNUM.;
%*We ensure each Descriptive Field has the same VARNUM value.;
%*It does not matter if different Descriptive Fields have the same VARNUM value,;
%* for we use the alphabetic order to determine their final sequence in such case.;

%*131.	Recover the VARNUM to numeric.;
data &procLIB..DescTrns_4varnum;
	set &procLIB..DescTrns_4attr_trns;
	format	n_VARNUM	best12.;
	n_VARNUM	=	input(strip(VARNUM),best12.);
run;

%*132.	Set all VARNUM for each Descriptive Field to the same by current definition.;
proc sort
	data=&procLIB..DescTrns_4varnum
;
	by
		%unquote(&descVAR.)
		descending	n_VARNUM
		%unquote(&dateVAR.)
	;
run;
data &procLIB..DescTrns_4out;
	set &procLIB..DescTrns_4varnum;
	by
		%unquote(&descVAR.)
		descending	n_VARNUM
		%unquote(&dateVAR.)
	;
	retain
		tmp_VARNUM
	;
	if	first.%unquote(&descVAR.)	then do;
		tmp_VARNUM	=	n_VARNUM;
	end;
		n_VARNUM	=	tmp_VARNUM;
	drop
		tmp_VARNUM
	;
run;

%*190.	Attribute determination.;
proc sort
	data=&procLIB..DescTrns_4out
;
	by
		n_VARNUM
		%unquote(&descVAR.)
		%unquote(&dateVAR.)
	;
run;
data _NULL_;
	%*200.	Set the data.;
	set
		&procLIB..DescTrns_4out
		end=EOF
	;
	by
		n_VARNUM
		%unquote(&descVAR.)
		%unquote(&dateVAR.)
	;

	%*300.	Recover the attribute to the same as from "Proc Contents".;
	format
		n_TYPE
		n_LENGTH
		n_FORMATL
		n_FORMATD
		best12.
	;
	n_TYPE		=	input(strip(TYPE),best12.);
	n_LENGTH	=	input(strip(LENGTH),best12.);
	n_FORMATL	=	input(strip(FORMATL),best12.);
	n_FORMATD	=	input(strip(FORMATD),best12.);

	%*400.	Prepare the retention.;
	retain
		r_TYPE
		r_LENGTH
		r_LABEL
		r_FORMAT
		r_FORMATL
		r_FORMATD
		n_var
	;

	%*500.	Setup attribute.;
	%*510.	At the first record of each Descriptive Field.;
	if	first.%unquote(&descVAR.)	then do;
		%*This determines the sequence of the Descriptive Fields in the output data.;
		n_var	+	1;

		r_TYPE		=	n_TYPE;
		r_LENGTH	=	n_LENGTH;
		r_FORMATL	=	n_FORMATL;
		r_FORMATD	=	n_FORMATD;

		%*This is purely to align the type of the temporary fields with the original ones.;
		%*If we set r_LABEL as "" here, SAS will set its length as $1,;
		%* which will lead to unexpected result.;
		%* However, below statement can cause SAS to set its length as the same of LABEL.;
		r_LABEL		=	LABEL;
		r_FORMAT	=	FORMAT;
	end;

	%*520.	At each record of each Descriptive Field.;
	%*Follow the rules at the beginning of Step100.;
		r_TYPE		=	max(r_TYPE,n_TYPE);
		r_LENGTH	=	max(r_LENGTH,n_LENGTH);
	if	n_TYPE	=	2	then do;
		%*This stores the last existed text format.;
		r_FORMAT	=	FORMAT;
	end;
		r_FORMATL	=	max(r_FORMATL,n_FORMATL);
		r_FORMATD	=	max(r_FORMATD,n_FORMATD);

	%*530.	At the last record of each Descriptive Field.;
	if	last.%unquote(&descVAR.)	then do;
		%*100.	Follow the rules at the beginning of Step100.;
		r_LABEL		=	LABEL;
		if	r_TYPE	=	1	then do;
			%*It means this field for all &dateVAR. is numeric.;
			r_FORMAT	=	FORMAT;
		end;

		%*200.	Call the macro variables for the transposition initialization.;
		call symputx(cats("LdescVAR",n_var),%unquote(&descVAR.),"L");
		call symputx(cats("LdescTYPE",n_var),r_TYPE,"L");
		call symputx(cats("LdescFMT",n_var),cats(r_FORMAT,r_FORMATL,".",r_FORMATD),"L");
		if	r_TYPE	=	1	then do;
			call symputx(cats("LdescLEN",n_var),8,"L");
		end;
		else do;
			call symputx(cats("LdescLEN",n_var),cats(r_FORMAT,r_LENGTH),"L");
		end;
	end;

	%*600.	Retrieve the number of Descriptive Fields in the output data.;
	if	EOF	then do;
		call symputx("LnDescFLD",n_var,"L");
	end;
run;

%*200.	Transposition of the input data.;
proc sort
	data=%unquote(&inDAT.)
	out=&procLIB..Dat_4DescTrns
;
	by
		%unquote(&byVAR.)
		%unquote(&dateVAR.)
	;
run;
proc transpose
	data=&procLIB..Dat_4DescTrns
	out=&procLIB..Dat_DescTrns(
		drop=_NAME_
	)
;
	by
		%unquote(&byVAR.)
		%unquote(&dateVAR.)
	;
	id
		%unquote(&descVAR.)
	;
	var
		%unquote(&valVAR.)
	;
run;

%*300.	Generate the output data by fixing the field attributes.;
data %unquote(&outDAT.);
	%*200.	Set the data by renaming the original Descriptive Fields.;
	set
		&procLIB..Dat_DescTrns(
			rename=(
				%do	DESCi=1	%to	&LnDescFLD.;
					&&LdescVAR&DESCi..	=	_t_DescTrns_&DESCi.
				%end;
			)
		)
	;

	%*300.	Create the new Descriptive Fields by historical attributes.;
	format
		%do	DESCi=1	%to	&LnDescFLD.;
			&&LdescVAR&DESCi..	&&LdescFMT&DESCi..
		%end;
	;
	length
		%do	DESCi=1	%to	&LnDescFLD.;
			&&LdescVAR&DESCi..	&&LdescLEN&DESCi..
		%end;
	;

	%*400.	Translate all Descriptive Fields.;
	%do	DESCi=1	%to	&LnDescFLD.;
		%if	&&LdescTYPE&DESCi..	=	1	%then %do;
			&&LdescVAR&DESCi..	=	input(compress(_t_DescTrns_&DESCi.,".","dko"),best12.);
		%end;
		%else %do;
			&&LdescVAR&DESCi..	=	strip(_t_DescTrns_&DESCi.);
		%end;
	%end;

	%*900.	Purge the memory usage.;
	drop
		%do	DESCi=1	%to	&LnDescFLD.;
			_t_DescTrns_&DESCi.
		%end;
	;
run;

%*900.	Purge the memory.;
%*910.	Release the Regular Expression matching rules.;
%ReleasePRX:
%syscall prxfree(PRXID);

%EndOfProc:
%mend DBuse_transDescVarAsCol;