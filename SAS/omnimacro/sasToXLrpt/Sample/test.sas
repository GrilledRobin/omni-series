%let	exroot	=	D:\SAS\omnimacro\sasToXLrpt;
%let	advroot	=	D:\SAS\omnimacro\AdvOp;
%let	fsroot	=	D:\SAS\omnimacro\FileSystem;
%let	tplroot	=	D:\SAS\omnimacro\sasToXLrpt\Sample;

options
	sasautos=(
		sasautos
		"&exroot."
		"&advroot."
		"&fsroot."
	)
	mautosource
	xmin
;

%*100.	Test the standard macros.;
/*
%FS_getPathList4Lib(
	inDSN		=	
	,outCNT		=	G_LstNO
	,outELpfx	=	G_LstEL
)

%FS_VarExists(
	inDAT	=
	,inFLD	=
	,outVAR	=
	,gMode	=
)
*/
%*200.	Test DDE.;
%global
	Gv_abc
	Gd_dde
	Gd_dds
	Gv_ade
;
%let	Gv_abc	=	Test_text;
%let	Gd_dde	=	a;
%let	Gd_dds	=	b;
%let	Gv_ade	=	125;
data a;
	a=12;
	b="30";
	output;
	a=16;
	b="100";
	output;
run;
data b;
	a="125";
	b="dfage";
	c=37;
run;


%sasToXLrpt(
	tmplpath	=	&tplroot.
	,tmplname	=	test
	,savepath	=	&tplroot.
	,savename	=	%bquote(test_out)
	,varheader	=	Gv_ Gd_
	,EnviroEXT	=	.xlsx
)
