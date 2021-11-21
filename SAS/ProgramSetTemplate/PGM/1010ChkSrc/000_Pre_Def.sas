%*001.	This section generates system log data.;
%*Below macros are from "&macroot.\010Proc";
%genLogByExecPgm

%*010.	Generate useful date-related variables by given date.;
%*Below macros are from "&cdwmac.\AdvOp";
%genVarByDate(
	clnDSN		=	clndr
	,clnPFX		=	calendar
	,inDATE		=	&G_cur_year.&G_cur_mth.&G_cur_day.
	,procLIB	=	WORK2
)

%*500.	System level parameters.;
%*Below macros are from "&cdwmac.\AdvOp";
%getMthWithinPeriod(
	clnLIB		=	clndr
	,clnPFX		=	calendar
	,DateBgn	=	20150101
	,DateEnd	=	&G_cur_year.&G_cur_mth.&G_cur_day.
	,outPfx		=	L1501ToNow_
	,procLIB	=	WORK2
)
%getMthWithinPeriod(
	clnLIB		=	clndr
	,clnPFX		=	calendar
	,DateBgn	=	20160101
	,DateEnd	=	&G_cur_year.&G_cur_mth.&G_cur_day.
	,outPfx		=	L1601ToNow_
	,procLIB	=	WORK2
)

%*600.	Pre-load the necessary procedures.;
%*Below macro is from "&curroot.";
%AdhocPatch