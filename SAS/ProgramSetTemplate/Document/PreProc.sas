%*010.	Generate useful date-related variables by given date.;
%*Below macros are from "&cdwmac.\AdvOp";
%genVarByDate(
	clnDSN		=	clndr
	,clnPFX		=	calendar
	,inDATE		=	&G_cur_year.&G_cur_mth.&G_cur_day.
	,procLIB	=	WORK
)

%*500.	System level parameters.;
%*Below macros are from "&cdwmac.\AdvOp";
%getMthWithinPeriod(
	clnLIB		=	clndr
	,clnPFX		=	calendar
	,DateBgn	=	20150101
	,DateEnd	=	&G_cur_year.&G_cur_mth.&G_cur_day.
	,outPfx		=	L1501ToNow_
	,procLIB	=	WORK
)
%getMthWithinPeriod(
	clnLIB		=	clndr
	,clnPFX		=	calendar
	,DateBgn	=	20160101
	,DateEnd	=	&G_cur_year.&G_cur_mth.&G_cur_day.
	,outPfx		=	L1601ToNow_
	,procLIB	=	WORK
)

%*We will remove the necessary files from specific directory in the third month before current one.;
%*[DateBgn] should be included, while [DateEnd] should be excluded.;
%*Below macros are from "&cdwmac.\AdvOp";
%getMthWithinPeriod(
	clnLIB		=	clndr
	,clnPFX		=	calendar
	,DateBgn	=	&L_m_R3Mth_M1.01
	,DateEnd	=	&L_m_R3Mth_M2.01
	,outPfx		=	LpDel
	,procLIB	=	WORK
)