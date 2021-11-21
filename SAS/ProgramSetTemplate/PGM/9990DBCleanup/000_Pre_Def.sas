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
%*We will remove the necessary files from specific directory in the third month before current one.;
%*[DateBgn] should be included, while [DateEnd] should be excluded.;
%*Below macros are from "&cdwmac.\AdvOp";
%getMthWithinPeriod(
	clnLIB		=	clndr
	,clnPFX		=	calendar
	,DateBgn	=	&L_m_R3Mth_M1.01
	,DateEnd	=	&L_m_R3Mth_M2.01
	,outPfx		=	LpDel
	,procLIB	=	WORK2
)

%*600.	Pre-load the necessary procedures.;
%*Below macro is from "&curroot.";
%AdhocPatch