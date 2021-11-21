%macro ecLang_CHS;
%global
	Lec_WN_SasUserReg_CHS
	Lec_WN_NoRegCust_CHS
	Lec_WN_SysSchExp_CHS
	Lec_WN_BasSchExp_CHS
	Lec_WN_BasSchExp1_CHS
	Lec_WN_BasSchExp2_CHS

	Lec_NT_VarUnini_CHS
	Lec_NT_PassHdrDt_CHS
	Lec_NT_Invalid_CHS
	Lec_NT_WDFormat_CHS
	Lec_NT_RepeatBy_CHS
	Lec_NT_MathOps_CHS
	Lec_NT_GenMissVal_CHS
	Lec_NT_DivideBy0_CHS
	Lec_NT_MergeStmt_CHS
	Lec_NT_ProcChar_CHS
	Lec_NT_ConvVal_CHS
	Lec_NT_DisableItv_CHS
	Lec_NT_ProcNoObs_CHS
	Lec_NT_ProcStop_CHS

	Lec_ER_ExpectPg1_CHS
	Lec_ER_PgVldFail_CHS
;
%let	Lec_WN_SasUserReg_CHS	=	%nrbquote( 无法将 SASUSER 注册表复制到 );
%let	Lec_WN_NoRegCust_CHS	=	%nrbquote( 您不会看到注册表定制情况 );
%let	Lec_WN_SysSchExp_CHS	=	%nrbquote( 您的系统预定在 );
%let	Lec_WN_BasSchExp_CHS	=	%nrbquote( 警告模式 );
%let	Lec_WN_BasSchExp1_CHS	=	%nrbquote( 很快就会 );
%let	Lec_WN_BasSchExp2_CHS	=	%nrbquote( 警告期 );

%let	Lec_NT_VarUnini_CHS		=	%nrbquote( 未初始化 );
%let	Lec_NT_PassHdrDt_CHS	=	%nrbquote( PASS HEADER DATE );
%let	Lec_NT_Invalid_CHS		=	%nrbquote( 无效 );
%let	Lec_NT_WDFormat_CHS		=	%nrbquote( W.D 格式对于 );
%let	Lec_NT_RepeatBy_CHS		=	%nrbquote( 带有重复的 BY 值 );
%let	Lec_NT_MathOps_CHS		=	%nrbquote( 无法执行算术运算 );
%let	Lec_NT_GenMissVal_CHS	=	%nrbquote( 已设为缺失值 );
%let	Lec_NT_DivideBy0_CHS	=	%nrbquote( 0 为除数 );
%let	Lec_NT_MergeStmt_CHS	=	%nrbquote( MERGE 语句 );
%let	Lec_NT_ProcChar_CHS		=	%nrbquote( 字符值已转换为 );
%let	Lec_NT_ConvVal_CHS		=	%nrbquote( 已转换为 );
%let	Lec_NT_DisableItv_CHS	=	%nrbquote( INTERACTIVITY DISABLED WITH );
%let	Lec_NT_ProcNoObs_CHS	=	%nrbquote( NO OBSERVATION );
%let	Lec_NT_ProcStop_CHS		=	%nrbquote( 系统停止处理 );

%let	Lec_ER_ExpectPg1_CHS	=	%nrbquote( 期望第 1 页，而得到的是第 -1 页 );
%let	Lec_ER_PgVldFail_CHS	=	%nrbquote( 时发生页面验证错误 );
%mend ecLang_CHS;