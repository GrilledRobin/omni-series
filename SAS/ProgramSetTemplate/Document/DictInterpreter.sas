%global
	RPT_CURR	RPT_PREV	G_cur_year	G_cur_mth	G_cur_day	G_prevyear	G_prevmth	LfKeepRpt	cdwmac	curstg	PjtDict	sp_Proc
;
%let	RPT_CURR	=	20181111;
%let	RPT_PREV	=	201810;
%let	LfKeepRpt	=	0;
%let	PjtDict		=	D:\SAS\ProgramSetTemplate\Document\Dictionary.xlsx;
%let	sp_Proc		=	D:\SAS\ProgramSetTemplate\Document\PreProc.sas;
%let	cdwmac		=	D:\SAS\omnimacro;
%let	curstg		=	1010ChkSrc;
%let	G_cur_year	=	%substr( &RPT_CURR. , 1 , 4 );
%let	G_cur_mth	=	%substr( &RPT_CURR. , 5 , 2 );
%let	G_cur_day	=	%substr( &RPT_CURR. , 7 , 2 );
%let	G_prevyear	=	%substr( &RPT_PREV. , 1 , 4 );
%let	G_prevmth	=	%substr( &RPT_PREV. , 5 , 2 );

%*010.	Prepare the tools.;
options
	sasautos=(
		sasautos
		%sysfunc(quote( &cdwmac.\AdvDB , %str(%') ))
		%sysfunc(quote( &cdwmac.\AdvOp , %str(%') ))
		%sysfunc(quote( &cdwmac.\CDW_Filter , %str(%') ))
		%sysfunc(quote( &cdwmac.\CDW_FldMap , %str(%') ))
		%sysfunc(quote( &cdwmac.\Dates , %str(%') ))
		%sysfunc(quote( &cdwmac.\DDE , %str(%') ))
		%sysfunc(quote( &cdwmac.\FileSystem , %str(%') ))
		%sysfunc(quote( &cdwmac.\OpsResearch , %str(%') ))
		%sysfunc(quote( &cdwmac.\sasToXLrpt , %str(%') ))
	)
	mautosource
	xmin
;

%*050.	Load some functions for usage at initiation.;
%*Below macros are from "&cdwmac.\FileSystem";
options cmplib=_NULL_;
proc FCmp outlib=work.pre.FS;
	%usFUN_mkdir

run;
quit;
options cmplib=work.pre;

%*100.	Load the default dictionary.;
%DBcr_LoadDict( &PjtDict. , &sp_Proc. )