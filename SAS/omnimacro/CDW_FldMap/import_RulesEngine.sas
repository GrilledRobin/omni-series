%let	rootx		=	\\10.25.238.41\sme;
%let	L_curdate	=	201301;
%let	L_stpflnm	=	srFIN.RulesEngine&L_curdate.;
%let	path		=	&rootx.\SAS_report\omnimacro\CDW_FldMap;

libname	srFIN	"&rootx.\SME_Data\Rev_SRC\Finance";
libname	code	"&rootx.\SME_MIS\omnimacro\CDW_FldMap";

%*001.	Import the Rules Engine.;
%let	StpFlNm	=	&rootx.\Indv_Raw\Rev_raw\Finance\Mapping rule\Rules Engine Mapping details -04Jan13.xls;
%*let	StpFlNm	=	X:\Indv_Raw\Rev_raw\Finance\Mapping rule\Rules Engine Mapping details -08May12.xls;
PROC IMPORT
	OUT			=	RulesSource
	DATAFILE	=	"&StpFlNm."
	DBMS		=	EXCEL
	REPLACE
;
	SHEET		=	"rlexpdt$";
	GETNAMES	=	YES;
	MIXED		=	NO;
	SCANTEXT	=	YES;
	USEDATE		=	YES;
	SCANTIME	=	YES;
RUN;

%*002.	Import the Sequence logic.;
%let	StpFlNm	=	&path.\Rules Engine EXEC SEQ.xls;
PROC IMPORT
	OUT			=	SeqSource(where=(missing(Table_)=0))
	DATAFILE	=	"&StpFlNm."
	DBMS		=	EXCEL
	REPLACE
;
	RANGE		=	"RLPARAM$F2:S40";
	GETNAMES	=	YES;
	MIXED		=	NO;
	SCANTEXT	=	YES;
	USEDATE		=	YES;
	SCANTIME	=	YES;
RUN;

%*010.	Format the sequence data.;
data SeqFormat;
	set SeqSource;
	format
		N_RVS_SEQ	8.
		C_CAT		$16.
	;
	length
		N_RVS_SEQ	8
		C_CAT		$16.
	;
	N_RVS_SEQ	=	_N_;
	if	upcase(Biz_Unit)	=	"X"	then	C_CAT	=	"outBU";
	if	upcase(Product1)	=	"X"	then	C_CAT	=	"outPDTCODE";
	if	upcase(Oper_Unit)	=	"X"	then	C_CAT	=	"outOU";
	if	upcase(Account)		=	"X"	then	C_CAT	=	"outACCT";
	if	upcase(C_Class)		=	"X"	then	C_CAT	=	"outCUSTSEG";
	if	upcase(Dept_id)		=	"X"	then	C_CAT	=	"outDEPT";

	if	table_	in	("PSCUCLACBL","PSPRODACBL")	then	C_CAT	=	"outACCT";
run;

proc sort
	data=SeqFormat
	out=SeqInterim
;
	by
		C_CAT
		descending	N_RVS_SEQ
	;
run;

data SeqOut;
	set SeqInterim;
		by
			C_CAT
			descending	N_RVS_SEQ
		;
	format	N_CODE_SEQ	8.;
	retain	N_CODE_SEQ;
	if	first.C_CAT	then do;
		N_CODE_SEQ	=	0;
	end;
		N_CODE_SEQ	+	1;
run;

%*100.	Clean the source data.;
%*110.	Retrieve the number of conditions within each rule record.;
%global	GnCOND;
%let	GnCOND	=	0;
data condition;
	set
		RulesSource(
			keep=EXPRESSION
		)
	;
	format
		tmpEXP	$512.
		tmpLEN	8.
		tmpCNT	8.
	;
	length
		tmpEXP	$512.
		tmpLEN	8
		tmpCNT	8
	;
	tmpEXP	=	compress(tranwrd(EXPRESSION,"AND","@"));
	tmpLEN	=	length(tmpEXP);
	tmpCNT	=	1;
	do	tmpi	=	1	to	tmpLEN;
		if	substr(tmpEXP,tmpi,1)	=	'@'	then	tmpCNT	+	1;
	end;
run;
proc sql
	noprint
	errorstop
;
	select
		max(tmpCNT)
	into
		:GnCOND
	from condition;
quit;
%put	&GnCOND.;

%*120.	Prepare the interim data.;
proc sql;
	create table RulesInterimTmp as (
		select
			a.*
			,b.*
		from RulesSource as a
		left join SeqOut as b
			on	a.RULEGRPCODE	=	b.Table_
	);
quit;

%*190.	Generate the interim data.;
%macro genRE;
data &L_stpflnm.(compress=yes);
	set RulesInterimTmp;
	format
		C_SAS_CODE	$512.
		tmp1		$512.
		tmp2		$512.
		tmp3		$512.
		tmp4		$512.
		tmp5		$512.
		tmpval		$1024.
	;
	length
		C_SAS_CODE	$512.
		tmp1		$512.
		tmp2		$512.
		tmp3		$512.
		tmp4		$512.
		tmp5		$512.
		tmpval		$1024.
	;
	C_SAS_CODE	=	"";
	tmp1		=	compress(EXPRESSION);
	tmp2		=	tranwrd(tmp1,"AND","@");
	tmp3		=	translate(tranwrd(tmp2,"IF",""),"","()");
	tmp4		=	tranwrd(tranwrd(tranwrd(tranwrd(tranwrd(tranwrd(tmp3,"!="," NOTIN "),">="," GE "),"<="," LE "),"<"," LT "),">"," GT "),"="," IN ");
	tmp5		=	tranwrd(tmp4,"or",",");
	array	scani(*)
		$512
	%do	i=1	%to	&GnCOND.;
		exp&i.
	%end;
	;
	array	fldi(*)
		$512
	%do	i=1	%to	&GnCOND.;
		fld&i.
	%end;
	;
	array	outi(*)
		$512
	%do	i=1	%to	&GnCOND.;
		out&i.
	%end;
	;
	array	condi(*)
		$8
	%do	i=1	%to	&GnCOND.;
		cond&i.
	%end;
	;
	array	vali(*)
		$512
	%do	i=1	%to	&GnCOND.;
		val&i.
	%end;
	;
	array	stri(*)
		$128
		tmpstr1-tmpstr4
	;
	do	tmpi=1	to	dim(scani);
		scani(tmpi)	=	scan(tmp5,tmpi,"@");
		fldi(tmpi)	=	scan(scani(tmpi),1," ");
		if	fldi(tmpi)	=	"ACBRANCH"			then outi(tmpi)	=	'&inBRCODE.';
		if	fldi(tmpi)	=	"ACCLASS"			then outi(tmpi)	=	'&inACCLSS.';
		if	fldi(tmpi)	=	"ACPRODUCTCODE"		then outi(tmpi)	=	'&inPDTCODE.';
		if	fldi(tmpi)	=	"CUSTSEGMTCODE"		then outi(tmpi)	=	'&inCUSTSEG.';
		if	fldi(tmpi)	=	"GLDEPTID"			then outi(tmpi)	=	'&inDEPTID.';
		if	fldi(tmpi)	=	"PRODUCTCODE"		then outi(tmpi)	=	'&inPDTCODE.';
		if	fldi(tmpi)	=	"PSPRODUCT"			then outi(tmpi)	=	'&inPDTCODE.';
		if	fldi(tmpi)	=	"CLOSINGBALANCE"	then outi(tmpi)	=	'&inPEBAL.';
		if	fldi(tmpi)	=	"CRGCODE"			then outi(tmpi)	=	'&inCRGCODE.';
		if	fldi(tmpi)	=	"PSTXNTYPE"			then outi(tmpi)	=	'&inTXNTYPE.';
		if	fldi(tmpi)	=	"SEGMENTCODE"		then outi(tmpi)	=	'&inSEGCODE.';
		if	fldi(tmpi)	=	"CREDITDEBIT"		then outi(tmpi)	=	'&inTXNDIR.';

		condi(tmpi)	=	scan(scani(tmpi),2," ");
		vali(tmpi)	=	'("'||trim(left(tranwrd(scan(scani(tmpi),3," "),',','","')))||'")';

		if	condi(tmpi)	=	"NOTIN"	then	condi(tmpi)	=	"NOT IN";
		if	vali(tmpi)	=	'(" ")'	then	vali(tmpi)	=	'';
		if	fldi(tmpi)	=	"CLOSINGBALANCE"	then	vali(tmpi)	=	compress(translate(vali(tmpi),'','"'));
		if	missing(outi(tmpi))	=	0	then do;
			tmpval	=	"";
			tmppointer	=	1;
			tmpj	=	1;
			do while (tmppointer<=length(vali(tmpi))	and	missing(vali(tmpi))	=	0);
				stri(tmpj)	=	substr(vali(tmpi),tmppointer);
				if	length(stri(tmpj))+tmppointer-1<length(vali(tmpi))	then do;
					do while (substr(stri(tmpj),length(stri(tmpj)))	^=	",");
						stri(tmpj)	=	substr(stri(tmpj),1,length(stri(tmpj))-1);
					end;
				end;
				tmppointer	+	length(stri(tmpj));
				tmpval	=	cats(tmpval,'0A'x,stri(tmpj));
				tmpj	+	1;
			end;
			vali(tmpi)	=	substr(tmpval,2);
			C_SAS_CODE	=	cats(C_SAS_CODE," AND (",outi(tmpi)," ",condi(tmpi)," ",vali(tmpi),")");
		end;
	end;
	C_SAS_CODE	=	"IF "||substr(C_SAS_CODE,5);
	drop
		tmp:
	%do	i=1	%to	&GnCOND.;
		exp&i.
		fld&i.
	%end;
	;
run;
%mend genRE;
%genRE;

%*200.	Retrieve the Product Code Mapping.;
%*210.	Make the data for outputing codes.;
%macro	outRules(
	inDAT	=	&L_stpflnm.
	,inCAT	=	outPDTCODE
	,inCODE	=	&codeNM.
	,outFL	=	&path.\&codeNM..sas
);
proc sort
	data=&inDAT.(
		where=(
			C_CAT	=	"&inCAT."
		)
	)
	out=outCODEpre
;
	by
		N_CODE_SEQ
		descending EXECSEQNO
		descending SEQNO
	;
run;

data _NULL_;
	set
		outCODEpre
		end=EOF
	;
		by
			N_CODE_SEQ
			descending EXECSEQNO
			descending SEQNO
		;
	file	"&outFL.";
	if	_N_	=	1	then do;
		put	'%macro '"&inCODE.(";
		put	'09'x'inBRCODE=';
		put	'09'x',inACCLSS=';
		put	'09'x',inPDTCODE=';
		put	'09'x',inCUSTSEG=';
		put	'09'x',inDEPTID=';
		put	'09'x',inPEBAL=';
		put	'09'x',inCRGCODE=';
		put	'09'x',inSEGCODE=';
		put	'09'x',inTXNTYPE=';
		put	'09'x',inTXNDIR=';
		put	'09'x",&inCAT.=";
		put	');';
	end;
	array	outi(*)
		$512
	%do	i=1	%to	&GnCOND.;
		out&i.
	%end;
	;
	array	condi(*)
		$8
	%do	i=1	%to	&GnCOND.;
		cond&i.
	%end;
	;
	array	vali(*)
		$512
	%do	i=1	%to	&GnCOND.;
		val&i.
	%end;
	;

	format
		putinit	$512.
		putsucc	$512.
		putend	$512.
		puttmp	$512.
	;
	length
		putinit	$512.
		putsucc	$512.
		putend	$512.
		puttmp	$512.
	;

	putinit	=	cats('IF (',outi(1),'09'x,condi(1),'09'x,vali(1),')');
	put	putinit;
	do	tmpi=2	to	dim(outi);
		if	missing(outi(tmpi))	=	0	then do;
			putsucc	=	cats('09'x,'AND (',outi(tmpi),'09'x,condi(tmpi),'09'x,vali(tmpi),')');
			put	putsucc;
		end;
	end;
	putend	=	cats('09'x,'THEN &',"&inCAT..=",'"',compress(CODE,"."),'";');
	put	putend;
	if	EOF	=	1	then do;
%*-> Starting from 20130101;
		if	C_CAT	=	"outCUSTSEG"	then do;
			puttmp	=	'IF &inCUSTSEG. IN ("021","022")';
			put	puttmp;
			puttmp	=	cats('09'x,'THEN &',"&inCAT..=""106"";");
			put	puttmp;

			puttmp	=	'IF &inSEGCODE. IN ("66")';
			put	puttmp;
			puttmp	=	cats('09'x,'THEN &',"&inCAT..=""106"";");
			put	puttmp;
		end;
%*<- Starting from 20130101;
		put	'%mend '"&inCODE.;";
	end;
run;
%mend outRules;
%let	codeNM	=	cdwmap_PDT_EBBStoPSGL;
%outRules(
	inDAT	=	&L_stpflnm.
	,inCAT	=	outPDTCODE
	,inCODE	=	&codeNM.
	,outFL	=	&path.\&codeNM..sas
);
%let	codeNM	=	cdwmap_CUSTSEG_EBBStoPSGL;
%outRules(
	inDAT	=	&L_stpflnm.
	,inCAT	=	outCUSTSEG
	,inCODE	=	&codeNM.
	,outFL	=	&path.\&codeNM..sas
);
%let	codeNM	=	cdwmap_ACCLSS_EBBStoPSGL;
%outRules(
	inDAT	=	&L_stpflnm.
	,inCAT	=	outACCT
	,inCODE	=	&codeNM.
	,outFL	=	&path.\&codeNM..sas
);