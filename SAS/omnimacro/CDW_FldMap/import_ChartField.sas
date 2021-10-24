%let	rootx		=	\\10.25.238.41\sme;
%let	L_curdate	=	201212;
%let	path		=	&rootx.\SAS_report\omnimacro\CDW_FldMap;
%let	StpFlNm		=	&rootx.\Indv_Raw\Rev_raw\Finance\Mapping rule\PSGL Chartfield_201212.xls;
%let	GdatBU		=	srFIN.Chartfield_BU&L_curdate.;
%let	GdatOU		=	srFIN.Chartfield_OU&L_curdate.;

libname	srFIN	"&rootx.\SME_Data\Rev_SRC\Finance";
libname	code	"&rootx.\SME_MIS\omnimacro\CDW_FldMap";

%*001.	Import the BU mapping.;
PROC IMPORT
	OUT			=	mapBU(where=(missing(Business_Unit)=0))
	DATAFILE	=	"&StpFlNm."
	DBMS		=	EXCEL
	REPLACE
;
	RANGE		=	"Business Unit$A3:D65535";
	GETNAMES	=	YES;
	MIXED		=	YES;
	SCANTEXT	=	YES;
	USEDATE		=	YES;
	SCANTIME	=	YES;
RUN;

%*002.	Import the OU mapping.;
PROC IMPORT
	OUT			=	mapOU(where=(missing(Operating_Unit)=0))
	DATAFILE	=	"&StpFlNm."
	DBMS		=	EXCEL
	REPLACE
;
	RANGE		=	"Operat Unit$A2:H65535";
	GETNAMES	=	YES;
	MIXED		=	YES;
	SCANTEXT	=	YES;
	USEDATE		=	YES;
	SCANTIME	=	YES;
RUN;

%*100.	Clean the source data.;
%*110.	Generate BU mapping.;
proc format;
	value $cdwfmt_BUtoBR
		"077"="10000"
		"248"="80010"
		"249"="80010"
		"257"="80010"
		"258"="80010"
		"259"="80010"
		"600"="80010"
		"613"="13010"
		"614"="15010"
		"615"="16010"
		"616"="12000"
		"617"="17010"
		"618"="18010"
		"619"="20010"
		"620"="21010"
		"621"="22010"
		"622"="80010"
		"623"="80010"
		"624"="80010"
		"625"="80010"
		"626"="26010"
		"627"="28010"
		"628"="29010"
		"629"="30010"
		"661"="31010"
		"668"="32010"
		"669"="33010"
		"670"="34010"
		"671"="35010"
		"672"="36010"
		"673"="37010"
		"674"="38010"
		"675"="39010"
		"676"="50010"
		"677"="51010"
		other='99999'
	;
run;
data &GdatBU.(compress=yes);
	set mapBU;
	format
		cdwfmt_BUtoBR	$32.
		c_brcode		$5.
		tmpStr1		$4.
		tmpStr2		$4.
	;
	length
		cdwfmt_BUtoBR	$32.
		c_brcode		$5.
		tmpStr1		$4.
		tmpStr2		$4.
	;
	tmpStr1	=	substr(cats('000',Business_Unit),length(cats('000',Business_Unit))-2);
	tmpStr2	=	cats(input(cats(Business_Unit),8.));
	c_brcode	=	put(tmpStr1,cdwfmt_BUtoBR.);
	cdwfmt_BUtoBR	=	cats('"',tmpStr1,'"="',c_brcode,'"');
	output;
	if	length(tmpStr1)	^=	length(tmpStr2)	then do;
		cdwfmt_BUtoBR	=	cats('"',tmpStr2,'"="',c_brcode,'"');
		output;
	end;
	drop
		tmp:
	;
run;

%*120.	Generate OU mapping.;
data &GdatOU.(compress=yes);
	set mapOU;
	format
		c_brcode		$5.
		c_brcode_unify	$5.
		cdwfmt_OUtoBR	$32.
		cdwfmt_BRtoOU	$32.
		cdwfmt_OU_descr	$256.
		cdwfmt_BR_Unify	$32.
		tmpchk	8.
		tmpcode	8.
	;
	length
		c_brcode		$5.
		c_brcode_unify	$5.
		cdwfmt_OUtoBR	$32.
		cdwfmt_BRtoOU	$32.
		cdwfmt_OU_descr	$256.
		cdwfmt_BR_Unify	$32.
	;
	if	length(cats(Operating_Unit))	=	4	then do;
		tmpchk	=	int(mod(input(cats(Operating_Unit),8.),2));
		if	tmpchk	=	0	then do;
			tmpcode	=	input(cats(Operating_Unit),8.)-1;
		end;
		else do;
			tmpcode	=	input(cats(Operating_Unit),8.);
		end;
		c_brcode	=	cats(Operating_Unit,"0");
		if	cats(Operating_Unit)	in	('1001')	then do;
			tmpcode	=	1000;
			c_brcode	=	'10000';
		end;
		else if	cats(Operating_Unit)	in	('1002')	then do;
			tmpcode	=	1000;
			c_brcode	=	'10010';
		end;
		else if	cats(Operating_Unit)	in	('1201')	then do;
			tmpcode	=	1200;
			c_brcode	=	'12000';
		end;
		else if	cats(Operating_Unit)	in	('1202')	then do;
			tmpcode	=	1200;
			c_brcode	=	'12010';
		end;
		c_brcode_unify	=	cats(tmpcode,"0");
		cdwfmt_OUtoBR	=	cats('"',Operating_Unit,'"="',c_brcode_unify,'"');
		cdwfmt_BRtoOU	=	cats('"',c_brcode,'"="',Operating_Unit,'"');
		cdwfmt_OU_descr	=	cats('"',Operating_Unit,'"="',Description,'"');
		cdwfmt_BR_Unify	=	cats('"',c_brcode,'"="',c_brcode_unify,'"');
	end;
	drop
		tmp:
	;
run;

%*190.	Generate the interim data.;

%*200.	Retrieve the Code Mapping.;
%*210.	BU.;
%macro	outBU(
	inDAT	=
	,inCODE	=	&codeNM.
	,outFL	=	&path.\&codeNM..sas
);
proc sort
	data=&inDAT.
	out=outCODEpre
;
	by Business_Unit;
run;

data _NULL_;
	set
		outCODEpre
		end=EOF
	;
		by Business_Unit;
	file	"&outFL.";
	format	putstr	$64.;
	length	putstr	$64.;
	if	_N_	=	1	then do;
		put	'%macro '"&inCODE.;";
		put	'09'x"value $&inCODE.";
	end;

	putstr	=	cats('09'x,'09'x,&inCODE.);
	put	putstr;
	if	EOF	=	1	then do;
		putstr	=	cats('09'x,'09'x,"other='99999'");
		put	putstr;
		putstr	=	cats('09'x,';');
		put	putstr;
		put	'%mend '"&inCODE.;";
	end;
run;
%mend outBU;
%let	codeNM	=	cdwfmt_BUtoBR;
%outBU(
	inDAT	=	&GdatBU.
	,inCODE	=	&codeNM.
	,outFL	=	&path.\&codeNM..sas
);

%*220.	OU.;
%macro	outOU(
	inDAT	=
	,othCODE	=
	,inCODE	=	&codeNM.
	,outFL	=	&path.\&codeNM..sas
);
proc sort
	data=&inDAT.(
		where=(
			missing(&inCODE.)	=	0
		)
	)
	out=outCODEpre
;
	by Operating_Unit;
run;

data _NULL_;
	set
		outCODEpre
		end=EOF
	;
		by Operating_Unit;
	file	"&outFL.";
	format	putstr	$64.;
	length	putstr	$64.;
	if	_N_	=	1	then do;
		put	'%macro '"&inCODE.;";
		put	'09'x"value $&inCODE.";
	end;

	putstr	=	cats('09'x,'09'x,&inCODE.);
	put	putstr;
	if	EOF	=	1	then do;
		putstr	=	cats('09'x,'09'x,"other='","&othCODE.","'");
		put	putstr;
		putstr	=	cats('09'x,';');
		put	putstr;
		put	'%mend '"&inCODE.;";
	end;
run;
%mend outOU;
%let	codeNM	=	cdwfmt_OUtoBR;
%outOU(
	inDAT	=	&GdatOU.
	,othCODE	=	99999
	,inCODE	=	&codeNM.
	,outFL	=	&path.\&codeNM..sas
);
%let	codeNM	=	cdwfmt_BRtoOU;
%outOU(
	inDAT	=	&GdatOU.
	,othCODE	=	9999
	,inCODE	=	&codeNM.
	,outFL	=	&path.\&codeNM..sas
);
%let	codeNM	=	cdwfmt_OU_descr;
%outOU(
	inDAT	=	&GdatOU.
	,othCODE	=	Undefined
	,inCODE	=	&codeNM.
	,outFL	=	&path.\&codeNM..sas
);
%let	codeNM	=	cdwfmt_BR_Unify;
%outOU(
	inDAT	=	&GdatOU.
	,othCODE	=	99999
	,inCODE	=	&codeNM.
	,outFL	=	&path.\&codeNM..sas
);
