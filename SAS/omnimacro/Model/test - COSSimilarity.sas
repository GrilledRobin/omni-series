libname	spmDB	"X:\SAS_report\1298609\Monthly_100_SPM\Data\Database";
libname	spmCALC	"X:\SAS_report\1298609\Monthly_100_SPM\Data\Calculation";
libname	spmARM	"X:\SAS_report\1298609\Monthly_100_SPM\Data\ARM";
libname	scDB		"X:\SAS_report\1462415\Quarterly_500_SIP_Platform\Data\Database";
libname	scSRC	"X:\SAS_report\1462415\Quarterly_500_SIP_Platform\Data\SRC";

%let	L_curMon	=	201406;

proc format;
	value $s_schtype
		"MMSB"	=	10
		"HGSB 1"	=	40
		"HGSB 2"	=	50
	;

	value $s_jobgrade
		low	-	"M15"	=	15
		other				=	17
	;
run;

%*100.	Retrieve performance data.;
%*110.	Retrieval.;
data src;
	set
		spmDB.Mid_sc_armrat&L_curMon.
	;
	length
		C_VAR	$32.
	;
	C_VAR	=	cats(
		"V"
		,C_SCOPE
		,C_PART
		,C_CAT
		,C_KPI
		,C_TYPE_DATA
		,C_CUTOFF_DATA
	);
run;

%*120.	Transpose so that all KPIs are in the same record.;
proc sort
	data=src
;
	by	C_PO_PW;
run;

proc transpose
	data=src
	out=transPre
;
	by	C_PO_PW;
	id	C_VAR;
	var	A_KPI_VAL;
run;

%*200.	Retrieve SIP results, including scorecard and incentive.;
%*210.	Retrieval.;
proc sql;
	create table rmWithSIP as (
		select
			a.*
			,sc.A_KPI_VAL as A_SC
			,po.A_KPI_VAL as A_PO
			,(missing(sc.C_PO_PW) = 0 or missing(po.C_PO_PW) = 0) as F_SIP
			,ps.C_PO_GRADE
			,ps.K_QTR_JOIN
			,ps.C_SC_SCH_TYPE
		from transPre as a
		left join scDB.Sc_armfnl&L_curMon. as sc
			on	a.C_PO_PW	=	sc.C_PO_PW
		left join scDB.po_armfnl&L_curMon. as po
			on	a.C_PO_PW	=	po.C_PO_PW
		left join scSRC.Inf_pw&L_curMon. as ps
			on	a.C_PO_PW	=	ps.C_PO_PW
	);
quit;

%*290.	Prepare the source for Cosine Similarity Analysis.;
data rm4CS;
	%*100.	Set the source.;
	set
		rmWithSIP(
			where=(
				F_SIP	=	1
			)
		)
	;

	%*200.	Initialize numeric values.;
	array
		arrNUM
		_numeric_
	;
	do over arrNUM;
		arrNUM	=	sum(0, arrNUM);
	end;

	%*300.	Create score for hidden neurons.;
	length
		V_JobGrade
		V_QtrJoin
		V_SchType
		8.
	;
	V_JobGrade	=	put(C_PO_GRADE,s_jobgrade.);
	V_QtrJoin		=	K_QTR_JOIN;
	V_SchType	=	put(C_SC_SCH_TYPE,s_schtype.);

	%*900.	Purge.;
	drop
		_NAME_
		F_SIP
		C_PO_GRADE
		K_QTR_JOIN
/*		C_SC_SCH_TYPE*/
	;
run;

%*291.	Retrieve the number of numeric elements for CS.;
%let	DSID	=	%sysfunc(open(rm4CS));
%let	nVar	=	%sysfunc(attrn(&DSID.,NVARS));
%let	rc	=	%sysfunc(close(&DSID.));
%*There is only one Character Field C_PO_PW as Key.;
%*The 2 output fields should also be excluded.;
%let	nNum	=	%eval(&nVar. - 3);

%*295.	Standardize the input fields.;
proc standard
	data=rm4CS
	mean=0
/*	std=1*/
	out=rm4CSstd
;
	var	_numeric_;
run;
proc sort
	data=rm4CSstd
;
	by	C_SC_SCH_TYPE;
run;

%*300.	Calculate the Cosine Similarity for some random record against all others.;
%*310.	Sort the input data by random and retrieve the first record as the seed.;
proc sql;
	create table csSortRnd as (
		select *
		from rm4CSstd
	)
	order by ranuni(round(time()))
	;
quit;
data csSample;
	set csSortRnd(obs=1);
run;

%*350.	Calculation.;
data csCalc;
	%*010.	Set the data.;
	set csSortRnd;

	%*020.	Create the necessary fields for calculation.;
	length
		A_CS_EDP		%*Euclidean Dot Products;
		A_CS_EN_Seed	%*Euclidean Norm (Magnitude);
		A_CS_EN_Comp	%*Euclidean Norm (Magnitude);
		A_CS			%*Cosine Similarity;
		8.
	;
	%*The Euclidean Norm for the seed never changes.;
	retain
		A_CS_EN_Seed
	;

	%*040.	Mark all numeric elements to be evaluated.;
	array
		arrCS{&nNum.}
		V:
	;

	%*050.	Create temporary fields that will be retained for Euclidean Dot Products.;
	array
		arrSeed{&nNum.}
		tmp1-tmp&nNum.
	;
	retain
		tmp1-tmp&nNum.
	;

	%*100.	Initialize the temporary fields.;
	if	_N_	=	1	then do;
		do	CSi=1	to	&nNum.;
			arrSeed{CSi}	=	arrCS{CSi};
		end;
		%*In SAS version 9.2 and later, there is one new function EUCLID creating the magnitude.;
		%*A_CS_EN_Seed	=	euclid(of v:);
		A_CS_EN_Seed	=	sqrt(uss(of V:));
	end;

	%*200.	Calculate the Euclidean Dot Product.;
	A_CS_EDP	=	0;
	do	CSi=1	to	&nNum.;
		A_CS_EDP	+	( arrCS{CSi} * arrSeed{CSi} );
	end;

	%*300.	Calculate the Euclidean Norm for the competitor.;
	%*In SAS version 9.2 and later, there is one new function EUCLID creating the magnitude.;
	%*A_CS_EN_Comp	=	euclid(of V:);
	A_CS_EN_Comp	=	sqrt(uss(of V:));

	%*400.	Calculate the Cosine Similarity.;
	A_CS	=	A_CS_EDP / ( A_CS_EN_Seed * A_CS_EN_Comp );

	%*900.	Purge.;
	drop
		tmp:
		CSi
	;
run;

%*400.	Find the most similar record.;
proc sql;
	create table csSimilar as (
		select *
		from csCalc
		where C_PO_PW not in (select distinct C_PO_PW from csSample)
		having A_CS = max(A_CS)
	);
quit;

%*500.	Verify the relationship.;
data csRst;
	set
		csSample
		csSimilar
	;
run;
proc sql;
	create table csOrigin as (
		select a.*
		from rm4CS as a
		inner join csRst as b
			on	a.C_PO_PW	=	b.C_PO_PW
	);
quit;

%*600.	Find the Euclidean Distance between records.;
%*610.	Calculate the distances.;
proc distance
	data=rm4CSstd
	out=csDist
	method=Euclid
	distonly
;
/*	by	C_SC_SCH_TYPE;*/
	var	interval(_numeric_);
run;

%*620.	Identify the records.;
data _TmpBase;
	set csSortRnd(keep=C_PO_PW);
	idrec	=	_N_;
run;
data _TmpDist;
	set csDist;
	idrec	=	_N_;
run;
proc sql;
	create table scDist4Cluster as (
		select
			a.C_PO_PW
			,b.*
		from _TmpBase as a
		inner join _TmpDist as b
			on	a.idrec	=	b.idrec
	);
quit;

options
	sasautos=(
		sasautos
		"C:\www\omnimacro\AdvOp"
		"C:\www\omnimacro\FileSystem"
		"C:\www\omnimacro\Model"
	)
	mautosource
;

%*700.	Cosine Similarity.;
%ProcObsCorrelativity(
	inDAT	=	rm4CSstd
/*	,GrpBy	=	C_SC_SCH_:*/
	,inKEY	=	%nrbquote(c_po.*)
	,inVAR	=
	,inMTHD	=	EuclidDist
	,outDAT	=	test
)
