libname	src	"X:\SAS_report\1462415\Quarterly_500_SIP_Platform\Data\SRC";
libname	scACC	"X:\SAS_report\1462415\Quarterly_500_SIP_Platform\Data\ACC";
libname	scCUS	"X:\SAS_report\1462415\Quarterly_500_SIP_Platform\Data\CUS";
libname	scARM	"X:\SAS_report\1462415\Quarterly_500_SIP_Platform\Data\ARM";
libname	scDB	"X:\SAS_report\1462415\Quarterly_500_SIP_Platform\Data\Database";

%let	L_curMon	=	201312;

%macro getContent4Doc(
	inDAT	=
	,outFL	=
);
%let	outFL	=	%unquote(&outFL.);

proc contents
	data=&inDAT.
	out=cnt
	noprint
;
run;

proc sql;
	create table cntout as (
		select
			LIBNAME
			,MEMNAME
			,NAME
			,case TYPE
				when 1
					then "NUM"
				when 2
					then "CHAR"
				else ""
			end as TYPE
			,LENGTH
			,VARNUM
			,LABEL
			,FORMAT
			,FORMATL
			,FORMATD
		from cnt
	)
	order by VARNUM
	;
quit;

%sysexec (del /Q "&outFL." & exit);
proc export
	data=cntout
	OUTFILE= "&outFL."
	DBMS=EXCEL REPLACE;
	SHEET=Report; 
run;
%mend getContent4Doc;

%*100.	From parameter.xls;
%getContent4Doc(
	inDAT	=	src.Inf_config201312
	,outFL	=	%nrbquote(C:\www\AutoReports\Quarterly_500_SIP_Platform_new\Document\Examples\inf_config.xls)
);

%getContent4Doc(
	inDAT	=	src.param_SchemeSet&L_curMon.
	,outFL	=	%nrbquote(C:\www\AutoReports\Quarterly_500_SIP_Platform_new\Document\Examples\param_SchemeSet.xls)
);

%getContent4Doc(
	inDAT	=	src.param_PART&L_curMon.
	,outFL	=	%nrbquote(C:\www\AutoReports\Quarterly_500_SIP_Platform_new\Document\Examples\param_PART.xls)
);

%getContent4Doc(
	inDAT	=	src.param_KPI&L_curMon.
	,outFL	=	%nrbquote(C:\www\AutoReports\Quarterly_500_SIP_Platform_new\Document\Examples\param_KPI.xls)
);

%getContent4Doc(
	inDAT	=	src.dir_SC&L_curMon.
	,outFL	=	%nrbquote(C:\www\AutoReports\Quarterly_500_SIP_Platform_new\Document\Examples\dir_SC.xls)
);

%getContent4Doc(
	inDAT	=	src.inf_Involvement&L_curMon.
	,outFL	=	%nrbquote(C:\www\AutoReports\Quarterly_500_SIP_Platform_new\Document\Examples\inf_Involvement.xls)
);

%getContent4Doc(
	inDAT	=	src.inf_Method&L_curMon.
	,outFL	=	%nrbquote(C:\www\AutoReports\Quarterly_500_SIP_Platform_new\Document\Examples\inf_Method.xls)
);

%getContent4Doc(
	inDAT	=	src.inf_AggrMethod&L_curMon.
	,outFL	=	%nrbquote(C:\www\AutoReports\Quarterly_500_SIP_Platform_new\Document\Examples\inf_AggrMethod.xls)
);

%getContent4Doc(
	inDAT	=	src.inf_tag_logic&L_curMon.
	,outFL	=	%nrbquote(C:\www\AutoReports\Quarterly_500_SIP_Platform_new\Document\Examples\inf_tag_logic.xls)
);

%*200.	From SCScorePoints.xls;
%getContent4Doc(
	inDAT	=	src.fctr_ScoreFormats&L_curMon.
	,outFL	=	%nrbquote(C:\www\AutoReports\Quarterly_500_SIP_Platform_new\Document\Examples\fctr_ScoreFormats.xls)
);

%getContent4Doc(
	inDAT	=	src.fctr_SP&L_curMon.
	,outFL	=	%nrbquote(C:\www\AutoReports\Quarterly_500_SIP_Platform_new\Document\Examples\fctr_SP.xls)
);

%*300.	From SCFactors.xls;
%getContent4Doc(
	inDAT	=	src.fctr_GeneralFormats&L_curMon.
	,outFL	=	%nrbquote(C:\www\AutoReports\Quarterly_500_SIP_Platform_new\Document\Examples\fctr_GeneralFormats.xls)
);

%getContent4Doc(
	inDAT	=	src.fctr_PO_Ratio&L_curMon.
	,outFL	=	%nrbquote(C:\www\AutoReports\Quarterly_500_SIP_Platform_new\Document\Examples\fctr_PO_Ratio.xls)
);

%getContent4Doc(
	inDAT	=	src.fctr_Target&L_curMon.
	,outFL	=	%nrbquote(C:\www\AutoReports\Quarterly_500_SIP_Platform_new\Document\Examples\fctr_Target.xls)
);

%getContent4Doc(
	inDAT	=	src.fctr_NewJoiner&L_curMon.
	,outFL	=	%nrbquote(C:\www\AutoReports\Quarterly_500_SIP_Platform_new\Document\Examples\fctr_NewJoiner.xls)
);

%*400.	From FLIP_ManualJournal.xls;
%getContent4Doc(
	inDAT	=	src.inf_JNL_MAN&L_curMon.
	,outFL	=	%nrbquote(C:\www\AutoReports\Quarterly_500_SIP_Platform_new\Document\Examples\inf_JNL_MAN.xls)
);

%*500.	For database data.;
%*510.	Sample of Deal Level data.;
%getContent4Doc(
	inDAT	=	scACC.Acc_ftg_assetincr&L_curMon.
	,outFL	=	%nrbquote(C:\www\AutoReports\Quarterly_500_SIP_Platform_new\Document\Examples\Data_ACC.xls)
);

%*520.	Sample of Customer Level data.;
%getContent4Doc(
	inDAT	=	scCUS.Cus_ftg_newlmt&L_curMon.
	,outFL	=	%nrbquote(C:\www\AutoReports\Quarterly_500_SIP_Platform_new\Document\Examples\Data_CUS.xls)
);

%*530.	Sample of Sales Level data.;
%getContent4Doc(
	inDAT	=	scARM.Arm_ce_rework&L_curMon.
	,outFL	=	%nrbquote(C:\www\AutoReports\Quarterly_500_SIP_Platform_new\Document\Examples\Data_ARM.xls)
);

%*600.	Combined parameter table.;
%getContent4Doc(
	inDAT	=	scDB.param_Combine&L_curMon.
	,outFL	=	%nrbquote(C:\www\AutoReports\Quarterly_500_SIP_Platform_new\Document\Examples\param_Combine.xls)
);
