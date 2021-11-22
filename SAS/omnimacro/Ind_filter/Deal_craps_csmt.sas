%macro deal_craps_csmt(
		din_craps=
		,f_acct=1
		,dout_acct=
		,f_master=1
		,f_relno=1
		,dout_master=
		,dout_relno=
		,f_fmt_branch=
		,dout_branch=

		
		
	);
	
	%Macro stp_set(din=,dout=,con_in=,con=);
	data &dout;
		set &din(&con_in.);
	&con.;
	run;
	%Mend;
	%include "\\10.24.147.59\macro4updt\fmt.sas";
	%include "\\10.24.147.59\macro4updt\fmt.sas";
	options sumsize=2000m sortsize=2000M;
	options mprint mlogic compress=yes;
	options
		sasautos=(
		"\\10.25.238.41\sme\SME_MIS\omnimacro",
		"\\10.25.238.41\sme\SME_MIS\omnimacro\Ind_filter"
		,"\\10.25.238.41\sme\SME_MIS\omnimacro\CDW_Filter"
		,"\\10.25.238.41\sme\SME_MIS\omnimacro\CDW_FldMap"
		,"\\10.25.238.41\sme\SME_MIS\omnimacro\Fmt_bt"

	)
		mautosource
		mcompilenote=all
		notes
		source
		source2
	;
%if &f_fmt_branch. %then %do;
	Data &dout_branch.;
		set &din_craps.(where=(COSTCENTREFLAG="Y" )
				keep=ACCOUNTNO SHORTNAME  nc_relno MASTERNO BRANCHCODE CUSTSEGMTCODE BranchName TAXCTGCODE SEGMENTCODE COSTCENTREFLAG PRODUCTCODE))

%end;
	
%if &f_acct. %then %do;
	DATA	&dout_acct.;
						set &din_craps.(
					where	=(
						CUSTSEGMTCODE in ("25","26","27","28","29","025","026","027","028","029") or
						SEGMENTCODE in ('60' '61' '65' '66' '57')
									)
						keep	=
									MASTERNO
									BRANCHCODE
									ARMCODE
									SEGMENTCODE
									ISICCODE
									CUSTSEGMTCODE
									CUSTTYPECODE
									StaffFlag
									nc_relno
									PRIMARYFLAG
									ACCOUNTNO
									CURRENCYCODE
									ACCLASSCODE
									PRODUCTCODE
									ACOPENDATE
									d_table
									MASTEROPENDATE
									TERM
									 LEDGERBALANCE
									 DEALAMOUNT
									 CRGCODE
									 ACCTCURRENTSTATUS

						);
				
	
					format d_acctopn yymmdd10. d_masteropn yymmdd10.;
					d_acctopn =input(ACOPENDATE,anydtdte10.);
				  d_masteropn =input(MASTEROPENDATE,anydtdte10.);

					if substr(ACCOUNTNO,1,2) ^='91' then 
					nc_acctno=substr(cats("000000000000000000",ACCOUNTNO),length(cats("000000000000000000",ACCOUNTNO))-17);
					else 	nc_acctno=ACCOUNTNO;

					nc_acctbrnch	=	BRANCHCODE	;
					c_armcode		=	ARMCODE			;
					c_segcode		=	SEGMENTCODE	;	
					c_custseg		=	CUSTSEGMTCODE;
					%cdwmap_CUSTSEG_EBBStoPSGL(
							inCUSTSEG	=CUSTSEGMTCODE
							,inPDTCODE	=PRODUCTCODE
							,inACCLSS	=ACCLASSCODE
							,outCUSTSEG	=gl_custseg
						);
					c_curnycode	=	CURRENCYCODE	;

					format a_gl_bal  best12.;
					if Term = ''  then a_gl_bal    = LEDGERBALANCE;
         			if Term ^= '' then a_gl_bal    = DEALAMOUNT;	
					%cdwmap_PDT_EBBStoPSGL(
							inBRCODE=BRANCHCODE
							,inACCLSS=ACCLASSCODE
							,inPDTCODE=PRODUCTCODE
							,inCUSTSEG=CUSTSEGMTCODE
							,inDEPTID=
							,inPEBAL=a_gl_bal 
							,inCRGCODE=
							,inSEGCODE=SEGMENTCODE
							,inTXNTYPE=
							,inTXNDIR=
							,outPDTCODE=gl_prodcode
						);
						nc_prodcode=PRODUCTCODE;
					f_staff=0;
					if  StaffFlag="Y" then f_staff=1;
					if ( ACCTCURRENTSTATUS in ('O' 'D' 'A' 'U') and PRIMARYFLAG="Y") then f_primary=1;
					else f_primary=0;
					if  ACCTCURRENTSTATUS in ('O' 'A' )  then f_active=1;
					else f_active=0;
					if  ACCTCURRENTSTATUS in ('D' 'U' )  then f_dom=1;
					else f_dom=0;
					f_rank=1;
					length f_sme 8. f_ind 8.;
					f_sme=0;
					f_ind=0;
					if    ( %cdwflt_CASA_SME(inPDTCODE=PRODUCTCODE) 
						or %cdwflt_DEAL_SME(inPDTCODE=PRODUCTCODE))
					and %cdwflt_CustTypeCode_SME(inCUSTTYPE=CUSTTYPECODE) 					
					and %cdwflt_custseg_SME(inCUSTSEG=CUSTSEGMTCODE)
					then f_sme=1;

					if      %cdwflt_segcode_IND(inSEGCODE=SEGMENTCODE)
					and %cdwflt_CustTypeCode_IND(inCUSTTYPE=CUSTTYPECODE) 					
					and %cdwflt_custseg_IND(inCUSTSEG=CUSTSEGMTCODE)
					then f_ind=1;
					if f_ind or f_sme ;
					
					Keep masterno nc_relno nc_acctno f_ind f_sme c_custseg c_segcode c_armcode gl_custseg nc_prodcode
							nc_acctno c_curnycode  nc_acctbrnch d_acctopn  d_masteropn d_table f_primary f_active f_dom f_staff f_rank a_gl_bal;
					run;
%end;
%***************************************************************************************************;
%if &f_relno. or &f_master. %then %do;
					Proc sort data=&dout_acct.;
					by   masterno descending f_active descending f_dom d_acctopn descending f_rank;
					run;
					
					%stp_set(
					din		=	&dout_acct.,
					dout	=	&dout_master.,
					con_in	=	keep=
								d_table f_ind f_sme f_rank f_dom nc_acctbrnch d_acctopn d_masteropn
								masterno nc_relno  c_segcode c_armcode c_custseg gl_custseg f_primary f_active
						,
					con		=
						by   masterno descending f_active descending f_dom d_acctopn descending f_rank;
    					if first.masterno;
					);
%end;
%***************************************************************************************************;
%if &f_relno.  %then %do;
					Proc sort data=&dout_acct.;
					by   nc_relno   descending f_active  descending f_dom descending f_primary d_masteropn descending f_rank ;
					run;

					%stp_set(
					din		=	&dout_acct.,
					dout	=	&dout_rel._temp,
					con_in	=	keep=
								d_table f_ind f_sme f_staff f_dom
								masterno nc_relno  c_armcode  d_masteropn f_primary f_active f_rank
						,
					con		=
							rename c_armcode=c_arm_bk;
							by   nc_relno   descending f_active  descending f_dom  descending f_primary d_masteropn descending f_rank ;
					if first.nc_relno;
					);


					proc sql;
							create table &dout_rel. as
								select a.*
								,b.c_armcode
								,b.c_segcode
								,b.c_custseg
								,b.nc_acctbrnch as nc_acctbrnch_anchor
								,b.f_active as f_active_master
								,1-sum(0,a.f_active,a.f_dom) as f_close 
							from &dout_rel._temp  as a
							left join &dout_master. as b
								on a.masterno=b.masterno;
					quit;
					
					data &dout_rel.;
						   set &dout_rel.;
								%cdwmap_Armbrnch(
								armbrnch=nc_arm_brnch_org
								,armcode=c_armcode
								,fmt=$ce_arm.
								);
								%cdwmap_channel(
								armbrnch=nc_arm_brnch_org
								,armcode=c_armcode
								,fixarmbrnch=nc_arm_brnch
								,Chl=c_channel
								,f_reallocate=f_reallocate
								);
					     if c_channel in ('SYSTEM' 'PVB' 'MD' 'MD-CASA' 'CallCentre' 'INBOUND' 'TeleSales' 'BCOT Lend') or c_armcode="999" then nc_arm_brnch = nc_acctbrnch_anchor;
							 drop f_rank nc_arm_brnch_org;
					         proc sort nodupkey;
							  by nc_relno;

run;					
					
%end;					
	
	
%mend;