%macro TrackDiff(
	baseDAT		=
	,compDAT	=
	,DateStr	=
	,byVAR		=
	,inVAR		=	_ALL_
	,xcptVAR	=
	,flgChng	=	1
	,procLIB	=	WORK
	,outDAT		=
);
%local
	L_mcrLABEL
	CHRi
	BYi
	NUMi
;
%let	L_mcrLABEL	=	&sysMacroName.;
%*001.	Purge the WORK library.;
%KillLib(
	inLIB	=	&procLIB.
)

%*002.	Check D_DATA. (We only insert the data which do not exist in the original base.);
%local	LchkDDATA;
%let	LchkDDATA	=	0;
data _NULL_;
	set
		&baseDAT.(
			keep=D_DATA
		)
	;
	if	D_DATA	=	input("&DateStr.",anydtdte10.)	then do;
		call symput("LchkDDATA","1");
		stop;
	end;
run;
%if	%bquote(&LchkDDATA.)	^=	0	%then %do;
	%put	NOTE: [&L_mcrLABEL.]Data of current date (&DateStr.) already exist in the database, program skipped.;
	%goto	EndOfProc;
%end;

%*005.	Set all necessary fields to be compared.;
%if	%bquote(&flgChng.)	EQ	%then	%let	flgChng	=	1;
%if	%bquote(&procLIB.)	EQ	%then	%let	procLIB	=	WORK;
%if	%bquote(&outDAT.)	EQ	%then	%let	outDAT	=	&baseDAT.;

%local
	LtNUM
	LtCHR
;
%let	LtNUM	=	0;
%let	LtCHR	=	0;
data &procLIB..__comp_mod_base;
	set
		&baseDAT.(
			obs=1
			%if	%upcase(%bquote(&inVAR.))	^=	%str(_ALL_)	%then %do;
				keep=&inVAR.
			%end;
			%else %do;
				drop=
				%if	%bquote(&xcptVAR.)	NE	%then %do;
					&xcptVAR.
				%end;
				%if	%bquote(&flgChng.)	=	1	%then %do;
					fchg_:
				%end;
			%end;
		)
	;
run;

proc contents
	data=&procLIB..__comp_mod_base
	out=&procLIB..__comp_cntnt_base(
		where=(
				index(upcase("&byVAR."),cats(upcase(NAME)))	=	0
		%if	%bquote(&xcptVAR.)	NE	%then %do;
			and	index(upcase("&xcptVAR."),cats(upcase(NAME)))	=	0
		%end;
		)
		keep=
			NAME
			VARNUM
			TYPE
	)
	noprint
;
run;

proc sort
	data=&procLIB..__comp_cntnt_base
;
	by
		TYPE
		VARNUM
	;
run;

%*010.	Generate the total numbers of the Numeric fields as well as Character fields.;
data &procLIB..__comp_cntnt_4call;
	set
		&procLIB..__comp_cntnt_base
		end=EOF
	;
		by
			TYPE
			VARNUM
		;
	retain tmpNUM tmpCHR;
	if	TYPE	=	1	then do;
		tmpNUM	+	1;
	end;
	else do;
		tmpCHR	+	1;
	end;
	if	EOF	then do;
		call symput("LtNUM",cats(tmpNUM));
		call symput("LtCHR",cats(tmpCHR));
	end;
	if	sum(tmpNUM,tmpCHR)	>	0	then	output;
run;
%if	&LtNUM.	=	0	and	&LtCHR.	=	0	%then %do;
	%put	WARNING: [&L_mcrLABEL.]No compatible variable is found in the source data! Program will skip this step!;
	%goto	EndOfProc;
%end;

%*020.	Retrieve all available fields.;
proc sort
	data=&procLIB..__comp_cntnt_4call(
		where=(
			TYPE	=	1
		)
	)
	out=&procLIB..__comp_cntnt_4call_num
;
	by VARNUM;
run;
proc sort
	data=&procLIB..__comp_cntnt_4call(
		where=(
			TYPE	=	2
		)
	)
	out=&procLIB..__comp_cntnt_4call_chr
;
	by VARNUM;
run;

%if	%bquote(&LtNUM.)	^=	0	%then %do;
	%do	NUMi=1	%to	&LtNUM.;
		%local	LeNUM&NUMi.;
		%let	LeNUM&NUMi.	=;
	%end;
	data _NULL_;
		set &procLIB..__comp_cntnt_4call_num;
			by VARNUM;
		call symput(cats("LeNUM",_N_),cats(NAME));
	run;
%end;
%if	%bquote(&LtCHR.)	^=	0	%then %do;
	%do	CHRi=1	%to	&LtCHR.;
		%local	LeCHR&CHRi.;
		%let	LeCHR&CHRi.	=;
	%end;
	data _NULL_;
		set &procLIB..__comp_cntnt_4call_chr;
			by VARNUM;
		call symput(cats("LeCHR",_N_),cats(NAME));
	run;
%end;

%*090.	Prepare the "by variable" list.;
%genvarlist(
	nstart		=	1
	,inlst		=	&byVAR.
	,nvarnm		=	LeBY
	,nvarttl	=	LtBY
)

%*100.	Join the data.;
%*110.	Separate the data to retrieve the most updated records.;
data
	&procLIB..__comp_out_old
	&procLIB..__comp_base
;
	length
			%do	BYi=1	%to	&LtBY.;
				fchg_&&LeBY&BYi..
			%end;
		%if	%bquote(&LtNUM.)	^=	0	%then %do;
			%do	NUMi=1	%to	&LtNUM.;
				fchg_&&LeNUM&NUMi..
			%end;
		%end;
		%if	%bquote(&LtCHR.)	^=	0	%then %do;
			%do	CHRi=1	%to	&LtCHR.;
				fchg_&&LeCHR&CHRi..
			%end;
		%end;
		3
	;
		%do	BYi=1	%to	&LtBY.;
			fchg_&&LeBY&BYi..	=	0;
		%end;
	%if	%bquote(&LtNUM.)	^=	0	%then %do;
		%do	NUMi=1	%to	&LtNUM.;
			fchg_&&LeNUM&NUMi..	=	0;
		%end;
	%end;
	%if	%bquote(&LtCHR.)	^=	0	%then %do;
		%do	CHRi=1	%to	&LtCHR.;
			fchg_&&LeCHR&CHRi..	=	0;
		%end;
	%end;
	set &baseDAT.;
	if	D_END	=	"31dec9999"d	then do;
		output	&procLIB..__comp_base;
	end;
	else do;
		output	&procLIB..__comp_out_old;
	end;
run;

%*120.	Compare the data.;
proc sql;
	create table &procLIB..__comp_join as (
		select
			inbase.*
				%do	BYi=1	%to	&LtBY.;
					,incomp.&&LeBY&BYi.. as z_&&LeBY&BYi..
					,inbase.fchg_&&LeBY&BYi.. as oldfchg_&&LeBY&BYi..
				%end;
			%if	%bquote(&LtNUM.)	^=	0	%then %do;
				%do	NUMi=1	%to	&LtNUM.;
					,incomp.&&LeNUM&NUMi.. as z_&&LeNUM&NUMi..
					,inbase.fchg_&&LeNUM&NUMi.. as oldfchg_&&LeNUM&NUMi..
				%end;
			%end;
			%if	%bquote(&LtCHR.)	^=	0	%then %do;
				%do	CHRi=1	%to	&LtCHR.;
					,incomp.&&LeCHR&CHRi.. as z_&&LeCHR&CHRi..
					,inbase.fchg_&&LeCHR&CHRi.. as oldfchg_&&LeCHR&CHRi..
				%end;
			%end;
		from &procLIB..__comp_base as inbase
		full outer join &compDAT. as incomp
			on	1=1
			%do	BYi=1	%to	&LtBY.;
				and	inbase.&&LeBY&BYi..	=	incomp.&&LeBY&BYi..
			%end;
	);
quit;

%*200.	Separate the updated data.;
data
	&procLIB..__comp_out_NoChange(drop=z_:)
	&procLIB..__comp_Change
;
	set &procLIB..__comp_join;
	format	D_DATA	yymmddD10.;
	length
			%do	BYi=1	%to	&LtBY.;
				fchg_&&LeBY&BYi..
			%end;
		%if	%bquote(&LtNUM.)	^=	0	%then %do;
			%do	NUMi=1	%to	&LtNUM.;
				fchg_&&LeNUM&NUMi..
			%end;
		%end;
		%if	%bquote(&LtCHR.)	^=	0	%then %do;
			%do	CHRi=1	%to	&LtCHR.;
				fchg_&&LeCHR&CHRi..
			%end;
		%end;
		3
	;
	tmp_cnt	=	0;
		%do	BYi=1	%to	&LtBY.;
			fchg_&&LeBY&BYi..	=	compare(z_&&LeBY&BYi..,&&LeBY&BYi..,"L");
		%end;
	%if	%bquote(&LtNUM.)	^=	0	%then %do;
		%do	NUMi=1	%to	&LtNUM.;
				fchg_&&LeNUM&NUMi..	=	0;
			if	&&LeNUM&NUMi..	^=	z_&&LeNUM&NUMi..	then do;
				tmp_cnt				+	1;
				fchg_&&LeNUM&NUMi..	=	1;
			end;
		%end;
	%end;
	%if	%bquote(&LtCHR.)	^=	0	%then %do;
		%do	CHRi=1	%to	&LtCHR.;
				fchg_&&LeCHR&CHRi..	=	0;
			if	compare(&&LeCHR&CHRi..,z_&&LeCHR&CHRi..,"L")	^=	0	then do;
				tmp_cnt				+	1;
				fchg_&&LeCHR&CHRi..	=	1;
			end;
		%end;
	%end;
	if	tmp_cnt	>	0	then do;
		D_DATA	=	input("&DateStr.",anydtdte10.);
		output	&procLIB..__comp_Change;
	end;
	else do;
			%do	BYi=1	%to	&LtBY.;
				fchg_&&LeBY&BYi..	=	oldfchg_&&LeBY&BYi..;
			%end;
		%if	%bquote(&LtNUM.)	^=	0	%then %do;
			%do	NUMi=1	%to	&LtNUM.;
				fchg_&&LeNUM&NUMi..	=	oldfchg_&&LeNUM&NUMi..;
			%end;
		%end;
		%if	%bquote(&LtCHR.)	^=	0	%then %do;
			%do	CHRi=1	%to	&LtCHR.;
				fchg_&&LeCHR&CHRi..	=	oldfchg_&&LeCHR&CHRi..;
			%end;
		%end;
		output	&procLIB..__comp_out_NoChange;
	end;
run;

%*300.	Retrieve the changed part.;
%*210.	For updated data for changed records.;
data &procLIB..__comp_out_Change_new;
	set
		&procLIB..__comp_Change(
			where=(1
			%do	BYi=1	%to	&LtBY.;
				and	missing(z_&&LeBY&BYi..)	=	0
			%end;
			)
		)
	;
	format
		D_START
		D_END
		yymmddD10.
	;
	D_START	=	input("&DateStr.",anydtdte10.);
	D_END	=	"31dec9999"d;
	%*If NTB then we mark the flags of all new records as 0, except the keys.;
	if	1
	%do	BYi=1	%to	&LtBY.;
		and	missing(&&LeBY&BYi..)	=	1
	%end;
		then do;
		%if	%bquote(&LtNUM.)	^=	0	%then %do;
			%do	NUMi=1	%to	&LtNUM.;
				fchg_&&LeNUM&NUMi..	=	0;
			%end;
		%end;
		%if	%bquote(&LtCHR.)	^=	0	%then %do;
			%do	CHRi=1	%to	&LtCHR.;
				fchg_&&LeCHR&CHRi..	=	0;
			%end;
		%end;
	end;
		%do	BYi=1	%to	&LtBY.;
			&&LeBY&BYi..	=	z_&&LeBY&BYi..;
		%end;
	%if	%bquote(&LtNUM.)	^=	0	%then %do;
		%do	NUMi=1	%to	&LtNUM.;
			&&LeNUM&NUMi..	=	z_&&LeNUM&NUMi..;
		%end;
	%end;
	%if	%bquote(&LtCHR.)	^=	0	%then %do;
		%do	CHRi=1	%to	&LtCHR.;
			&&LeCHR&CHRi..	=	z_&&LeCHR&CHRi..;
		%end;
	%end;
	drop
		z_:
	;
run;

%*220.	For original data for changed records.;
data &procLIB..__comp_out_Change_org;
	set
		&procLIB..__comp_Change(
			where=(1
			%do	BYi=1	%to	&LtBY.;
				and	missing(&&LeBY&BYi..)	=	0
			%end;
			)
		)
	;
	format
		D_START
		D_END
		yymmddD10.
	;
	D_END	=	input("&DateStr.",anydtdte10.)	-	1;
		%do	BYi=1	%to	&LtBY.;
			fchg_&&LeBY&BYi..	=	oldfchg_&&LeBY&BYi..;
		%end;
	%if	%bquote(&LtNUM.)	^=	0	%then %do;
		%do	NUMi=1	%to	&LtNUM.;
			fchg_&&LeNUM&NUMi..	=	oldfchg_&&LeNUM&NUMi..;
		%end;
	%end;
	%if	%bquote(&LtCHR.)	^=	0	%then %do;
		%do	CHRi=1	%to	&LtCHR.;
			fchg_&&LeCHR&CHRi..	=	oldfchg_&&LeCHR&CHRi..;
		%end;
	%end;
	drop
		z_:
	;
run;

%*900.	Set all 4 parts.;
data &outDAT.(compress=yes);
	format	D_TABLE	yymmddD10.;
	retain
			%do	BYi=1	%to	&LtBY.;
				&&LeBY&BYi..
			%end;
		%if	%bquote(&LtNUM.)	^=	0	%then %do;
			%do	NUMi=1	%to	&LtNUM.;
				&&LeNUM&NUMi..
			%end;
		%end;
		%if	%bquote(&LtCHR.)	^=	0	%then %do;
			%do	CHRi=1	%to	&LtCHR.;
				&&LeCHR&CHRi..
			%end;
		%end;
	;
	set
		&procLIB..__comp_out_old
		&procLIB..__comp_out_NoChange
		&procLIB..__comp_out_Change_org
		&procLIB..__comp_out_Change_new
	;
	D_TABLE	=	input("&DateStr.",anydtdte10.);
		%do	BYi=1	%to	&LtBY.;
			fchg_&&LeBY&BYi..	=	sum(0,fchg_&&LeBY&BYi..);
		%end;
	%if	%bquote(&LtNUM.)	^=	0	%then %do;
		%do	NUMi=1	%to	&LtNUM.;
			fchg_&&LeNUM&NUMi..	=	sum(0,fchg_&&LeNUM&NUMi..);
		%end;
	%end;
	%if	%bquote(&LtCHR.)	^=	0	%then %do;
		%do	CHRi=1	%to	&LtCHR.;
			fchg_&&LeCHR&CHRi..	=	sum(0,fchg_&&LeCHR&CHRi..);
		%end;
	%end;
	drop
		tmp_cnt
		oldfchg_:
	%if	%bquote(&flgChng.)	^=	1	%then %do;
		fchg_:
	%end;
	;
run;

%EndOfProc:
%mend TrackDiff;

/*
This macro is used to track the difference of each given field within any specific data series,
 generating each data line which is changed on any field against the base data.
baseDAT	:	The base data to be compared.
compDAT	:	The data which is used to compare with the base data.
DateStr	:	The date on which the comparison is committed.
byVAR	:	The key by which the comparison is committed.
inVAR	:	The fields which are to be compared.
xcptVAR	:	The exceptional fields which are prohibited to compare.
flgChng	:	Define whether to flag the changed field for each record (against the base data).
outDAT	:	The compared result.
*/