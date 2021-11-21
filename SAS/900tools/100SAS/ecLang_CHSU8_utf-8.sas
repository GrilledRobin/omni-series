%macro ecLang_CHSU8;
%global
	Lec_WN_SasUserReg_CHSU8
	Lec_WN_NoRegCust_CHSU8
	Lec_WN_SysSchExp_CHSU8
	Lec_WN_BasSchExp_CHSU8
	Lec_WN_BasSchExp1_CHSU8
	Lec_WN_BasSchExp2_CHSU8

	Lec_NT_VarUnini_CHSU8
	Lec_NT_PassHdrDt_CHSU8
	Lec_NT_Invalid_CHSU8
	Lec_NT_WDFormat_CHSU8
	Lec_NT_RepeatBy_CHSU8
	Lec_NT_MathOps_CHSU8
	Lec_NT_GenMissVal_CHSU8
	Lec_NT_DivideBy0_CHSU8
	Lec_NT_MergeStmt_CHSU8
	Lec_NT_ProcChar_CHSU8
	Lec_NT_ConvVal_CHSU8
	Lec_NT_DisableItv_CHSU8
	Lec_NT_ProcNoObs_CHSU8
	Lec_NT_ProcStop_CHSU8

	Lec_ER_ExpectPg1_CHSU8
	Lec_ER_PgVldFail_CHSU8
;
%let	Lec_WN_SasUserReg_CHSU8	=	%nrbquote( 无法将 SASUSER 注册表复制到 );
%let	Lec_WN_NoRegCust_CHSU8	=	%nrbquote( 您不会看到注册表定制情况 );
%let	Lec_WN_SysSchExp_CHSU8	=	%nrbquote( 您的系统预定在 );
%let	Lec_WN_BasSchExp_CHSU8	=	%nrbquote( 警告模式 );
%let	Lec_WN_BasSchExp1_CHSU8	=	%nrbquote( 很快就会 );
%let	Lec_WN_BasSchExp2_CHSU8	=	%nrbquote( 警告期 );

%let	Lec_NT_VarUnini_CHSU8	=	%nrbquote( 未初始化 );
%let	Lec_NT_PassHdrDt_CHSU8	=	%nrbquote( PASS HEADER DATE );
%let	Lec_NT_Invalid_CHSU8	=	%nrbquote( 无效 );
%let	Lec_NT_WDFormat_CHSU8	=	%nrbquote( W.D 格式对于 );
%let	Lec_NT_RepeatBy_CHSU8	=	%nrbquote( 带有重复的 BY 值 );
%let	Lec_NT_MathOps_CHSU8	=	%nrbquote( 无法执行算术运算 );
%let	Lec_NT_GenMissVal_CHSU8	=	%nrbquote( 已设为缺失值 );
%let	Lec_NT_DivideBy0_CHSU8	=	%nrbquote( 0 为除数 );
%let	Lec_NT_MergeStmt_CHSU8	=	%nrbquote( MERGE 语句 );
%let	Lec_NT_ProcChar_CHSU8	=	%nrbquote( 字符值已转换为 );
%let	Lec_NT_ConvVal_CHSU8	=	%nrbquote( 已转换为 );
%let	Lec_NT_DisableItv_CHSU8	=	%nrbquote( INTERACTIVITY DISABLED WITH );
%let	Lec_NT_ProcNoObs_CHSU8	=	%nrbquote( NO OBSERVATION );
%let	Lec_NT_ProcStop_CHSU8	=	%nrbquote( 系统停止处理 );

%let	Lec_ER_ExpectPg1_CHSU8	=	%nrbquote( 期望第 1 页，而得到的是第 -1 页 );
%let	Lec_ER_PgVldFail_CHSU8	=	%nrbquote( 时发生页面验证错误 );
%mend ecLang_CHSU8;