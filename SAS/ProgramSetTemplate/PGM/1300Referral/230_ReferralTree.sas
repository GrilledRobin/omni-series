%*001.	This section generates system log data.;
%*Below macro is from "&macroot.\010Proc";
%genLogByExecPgm

%*010.	Below section generates the system-level global variables;
%global
	L_srcflnm
	L_stpflnm
;

%let	L_srcflnm	=	src.Referral;
%let	L_stpflnm	=	Anl.Ref_Tree;

/***************************************************************************************************\
|	Create a data that resemble the Referral Trees growing from all Roots.							|
|	Concept: a customer can only be referred to the company by ONE customer, while one customer can	|
|	 refer many.																					|
\***************************************************************************************************/

%*020.	Below section is for main process;
%macro GenRefTree;
%*010.	Define the local environment.;
%local
	LnLvl
	Vi
;
%let	LnLvl	=	0;

%*100.	Retrieve the end-to-end branchs from the entire Referral base.;
%OrgTree_EndToEndChain(
	inDAT		=	&L_srcflnm.
	,VarUpper	=	C_REFERRER
	,VarLower	=	C_CUSTOMER
	,ChainTop	=	C_ChainTop
	,ChainBtm	=	C_ChainBtm
	,ChainLvl	=	N_ChainLvl
	,inLeafDat	=	work2.Leaves
	,inLeafVar	=	TreeLeaf
	,outDAT		=	work2.ref_End2EndChain
	,procLIB	=	WORK2
)

%*200.	Retrieve the maximum depth of the entire tree.;
proc sql noprint;
	select
		max(N_ChainLvl)
		into	:LnLvl
	from work2.ref_End2EndChain
	;
quit;
%let	LnLvl	=	%eval(&LnLvl. + 0);

%*200.	Sort above data in proper order.;
%*We should list all subordinates to the right side of their respective superiors.;
proc sort
	data=work2.ref_End2EndChain
;
	by
		C_ChainTop
		C_ChainBtm
		N_ChainLvl
		C_REFERRER
		C_CUSTOMER
	;
run;

%*300.	Transpose the data.;
proc transpose
	data=work2.ref_End2EndChain
	out=work2.ref_tree
	prefix=Depth_
;
	by
		C_ChainTop
		C_ChainBtm
	;
	id
		N_ChainLvl
	;
	var
		C_CUSTOMER
	;
run;

%*500.	Standardization.;
data &L_stpflnm.(compress=yes);
	%*001.	Create D_TABLE.;
	%*Below macro is from "&cdwmac.\AdvOp";
	%cr_d_table

	%*050.	Re-arrange the variables.;
	retain
		C_ChainTop
		C_ChainBtm
	%do Vi=1 %to &LnLvl.;
		Depth_&Vi.
	%end;
	;

	%*100.	Set the data.;
	set
		work2.ref_tree(
			drop=_:
		)
	;
run;

%*800.	Draw an Organizational Tree.;
/* SAS/OR is Required * /
proc netdraw
	data=&L_srcflnm.
	graphics
;
	actnet /
		act		=	C_REFERRER
		succ	=	C_CUSTOMER
		id		=	(C_REFERRER)
		nodefid
		nolabel
		pcompress
		centerid
		tree
		xbetween	=	15
		ybetween	=	3
		arrowhead	=	0
		rectilinear
		carcs		=	black
		ctext		=	white
		htext		=	3
	;
run;
/* SAS/OR is Required */

%EndOfProc:
%mend GenRefTree;
%GenRefTree