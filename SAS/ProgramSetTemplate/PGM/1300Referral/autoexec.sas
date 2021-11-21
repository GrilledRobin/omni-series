%*We need to do some universal settings before running this stage.;
%include	"..\..\universal.sas";

*libname	irmdata	odbc	dsn=Localhost &ouser;

%global	curstg;
%let	curstg	=	1300Referral;

%global	curroot;
%let	curroot	=	&stgroot.\&curstg.;

%*The config file for this stage, currently contains the input date, separated into yyyy, mm and dd;
%include	"&curroot.\CFG.txt";

%global
	L_curMon
	L_curdate
;
%let	L_curMon	=	&G_cur_year.&G_cur_mth.;			%*This is for date check on Monthly data.;
%let	L_curdate	=	&G_cur_year.&G_cur_mth.&G_cur_day.;	%*This is for date check on Daily data.;

%*Below macro is from "..\universal.sas";
%rootlists(
	srcROOT	=	&cdwmac.
	,desROOT	=	AdvMacTool
	,ROOTLST	=	AdvDB
					AdvOp
					Dates
					FileSystem
					CDW_Filter
					CDW_FldMap
					OpsResearch
)
%rootlists(
	srcROOT	=	&macroot.
	,desROOT	=	stgMacTool
	,ROOTLST	=	001Basic
					002Dependent
					010Biz
					010Proc
					900Modules
)

options
	sasautos=(
		sasautos
		"&exroot."
		&AdvMacTool.
		&stgMacTool.
		"&curroot."
	)
	mautosource
	errorabend
	xmin
;

%global	rawx;
%let	rawx	=	&rootx.\SME_Raw;

libname	clndr	"D:\SAS\Calendar";

libname	CUST	"&rptDATA.\CUST";
libname	hc		"&rptDATA.\HR";

libname	src		"&rptDATA.\SRC";
libname	DB		"&rptDATA.\Database";
libname	Anl		"&rptDATA.\Analysis";

%*Below variables are for some compilations in common;
%global	AnnualizeDate;
%let	AnnualizeDate	=	365;

%global	BTrate;
%let	BTrate	=	0.0565;

%global	G_BCY;
%let	G_BCY	=	CNY;

%*Below macros are called at stage initiation;
%*Below macro is from "&macroot.\001Basic";
%GenEnviro
%*Below macro is from "&macroot.\001Basic";
%trans_value