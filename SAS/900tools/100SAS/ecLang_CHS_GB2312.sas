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
%let	Lec_WN_SasUserReg_CHS	=	%nrbquote( �޷��� SASUSER ע����Ƶ� );
%let	Lec_WN_NoRegCust_CHS	=	%nrbquote( �����ῴ��ע�������� );
%let	Lec_WN_SysSchExp_CHS	=	%nrbquote( ����ϵͳԤ���� );
%let	Lec_WN_BasSchExp_CHS	=	%nrbquote( ����ģʽ );
%let	Lec_WN_BasSchExp1_CHS	=	%nrbquote( �ܿ�ͻ� );
%let	Lec_WN_BasSchExp2_CHS	=	%nrbquote( ������ );

%let	Lec_NT_VarUnini_CHS		=	%nrbquote( δ��ʼ�� );
%let	Lec_NT_PassHdrDt_CHS	=	%nrbquote( PASS HEADER DATE );
%let	Lec_NT_Invalid_CHS		=	%nrbquote( ��Ч );
%let	Lec_NT_WDFormat_CHS		=	%nrbquote( W.D ��ʽ���� );
%let	Lec_NT_RepeatBy_CHS		=	%nrbquote( �����ظ��� BY ֵ );
%let	Lec_NT_MathOps_CHS		=	%nrbquote( �޷�ִ���������� );
%let	Lec_NT_GenMissVal_CHS	=	%nrbquote( ����Ϊȱʧֵ );
%let	Lec_NT_DivideBy0_CHS	=	%nrbquote( 0 Ϊ���� );
%let	Lec_NT_MergeStmt_CHS	=	%nrbquote( MERGE ��� );
%let	Lec_NT_ProcChar_CHS		=	%nrbquote( �ַ�ֵ��ת��Ϊ );
%let	Lec_NT_ConvVal_CHS		=	%nrbquote( ��ת��Ϊ );
%let	Lec_NT_DisableItv_CHS	=	%nrbquote( INTERACTIVITY DISABLED WITH );
%let	Lec_NT_ProcNoObs_CHS	=	%nrbquote( NO OBSERVATION );
%let	Lec_NT_ProcStop_CHS		=	%nrbquote( ϵͳֹͣ���� );

%let	Lec_ER_ExpectPg1_CHS	=	%nrbquote( ������ 1 ҳ�����õ����ǵ� -1 ҳ );
%let	Lec_ER_PgVldFail_CHS	=	%nrbquote( ʱ����ҳ����֤���� );
%mend ecLang_CHS;