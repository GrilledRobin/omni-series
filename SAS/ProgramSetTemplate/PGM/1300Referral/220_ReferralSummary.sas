%*001.	This section generates system log data.;
%*Below macro is from "&macroot.\010Proc";
%genLogByExecPgm

%*010.	Below section generates the system-level global variables;
%global
	L_srcflnm
	L_stpflnm
;

%let	L_srcflnm	=	DB.Ref_AllChains;
%let	L_stpflnm	=	Anl.Ref_Summary;

/***************************************************************************************************\
|	1. Retrieve the count of direct subordinates of any nodes in the tree.							|
|	2. Retrieve the count of all subordinates, either direct or indirect, of any nodes in the tree.	|
|	3. Retrieve the referral depths of any nodes in the tree.										|
|	   If A refers B, B refers C, while C does not refer any other, then the depth counting from A	|
|	    is 2.																						|
|	Concept: a customer can only be referred to the company by ONE customer, while one customer can	|
|	 refer many.																					|
\***************************************************************************************************/

%*020.	Below section is for main process;
%macro GetRefSummary;
%*010.	Define the local environment.;

%*100.	Sort the source data in proper order.;
%*When counting all subordinates for a node, we should:;
%*[1] Group the levels at first step;
%*[2] Count unique Referrers in each level, except when level=1;
%*[3] Count unique leaves in each level, where [C_CUSTOMER] = [C_ChainBtm];
%*[4] Sum up all retained numbers;
proc sort
	data=&L_srcflnm.(drop=D_TABLE)
	out=work2.ref_summary
;
	by
		C_ChainTop
		N_ChainLvl
		C_REFERRER
		C_CUSTOMER
	;
run;

%*500.	Standardization.;
data &L_stpflnm.(compress=yes);
	%*001.	Create D_TABLE.;
	%*Below macro is from "&cdwmac.\AdvOp";
	%cr_d_table

	%*100.	Set the data.;
	set	work2.ref_summary;
	by
		C_ChainTop
		N_ChainLvl
		C_REFERRER
		C_CUSTOMER
	;

	%*200.	Create new variables.;
	format
		K_DirRef
		K_AllRef
		K_RefDep
		tmp_Node
		tmp_Leaf
		comma32.
	;
	retain
		K_DirRef
		tmp_Node
		tmp_Leaf
	;

	%*300.	Initialize the counters for each referrer.;
	if	first.C_ChainTop	then do;
		K_DirRef	=	0;
		tmp_Node	=	0;
		tmp_Leaf	=	0;
	end;

	%*400.	Increment the counter of Direct Referrals when the "first node" of any branch is reached.;
	if	N_ChainLvl	=	1	then do;
		if	first.C_CUSTOMER	then do;
			K_DirRef	+	1;
		end;
	end;

	%*500.	Increment the counter of All Referrals;
	%*510.	Count the intermediate nodes.;
	if	N_ChainLvl	^=	1	then do;
		if	first.C_REFERRER	then do;
			tmp_Node	+	1;
		end;
	end;

	%*520.	Count the leaves.;
	if	C_ChainBtm	=	C_CUSTOMER	then do;
		tmp_Leaf	+	1;
	end;

	%*590.	Sum up all nodes and leaves.;
	if	last.C_ChainTop	then do;
		K_AllRef	=	sum(tmp_Node,tmp_Leaf);
	end;

	%*600.	Identify the maximum depth of current referrer.;
	if	last.C_ChainTop	then do;
		K_RefDep	=	N_ChainLvl;
	end;

	%*890.	Output the last record of each node.;
	if	last.C_ChainTop	then do;
		output;
	end;

	%*900.	Purge.;
	keep
		D_TABLE
		C_ChainTop
		K_DirRef
		K_AllRef
		K_RefDep
	;
run;

%EndOfProc:
%mend GetRefSummary;
%GetRefSummary