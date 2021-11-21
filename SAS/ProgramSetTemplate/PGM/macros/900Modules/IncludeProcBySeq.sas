%macro IncludeProcBySeq(
	FdrProc		=
	,CodePfx	=
	,procLIB	=	WORK
);
%*000.	Introduction.;
%*Creation: Lu Robin Bin 20130428;
%*Version: 1.0;
%*This macro is intended to run specific programs from both "Common Procedures" (&curProc.) and "Current Step" (&curroot.).;
%*Work Flow:;
%*Step 1: Find programs in "Common Procedures" like "010_aaa.sas", "020_bbb.sas";
%*Step 2: Find programs in "Current Step" like "015_ccc.sas", "022_ddd.sas";
%*Step 3: Order the programs above like below:;
%* "&curProc.\010_aaa.sas", ;
%* "&curroot.\015_ccc.sas", ;
%* "&curProc.\020_bbb.sas", ;
%* "&curroot.\022_ddd.sas";
%*Step 4: run the above programs in the sorted sequence.;

%*001.	Glossary.;
%*FdrProc	:	Folder (list) of the Procedures with the "Pound (#)" sign as the separator.;
%*CodePfx	:	The prefix of SAS code. As the naming convention is as "\d{3}.*\.sas", this prefix should only contain the first digit.;
%*procLIB	:	The processing library.;

%*002.	Update log.;
%*Updater: Lu Robin Bin 20130523;
%*Version: 1.01;
%*Log: Check each given folder and make sure there is no duplicate involvement of any single programs.;

%*Updater: Lu Robin Bin 20131005;
%*Version: 2.01;
%*Log: Add loop to involve two or more procedure directories at the same time.;
%*Work Flow:;
%*Step 1: Find programs in "A" folder like "010_aaa.sas", "020_bbb.sas";
%*Step 2: Find programs in "B" folder like "015_ccc.sas", "022_ddd.sas";
%*Step 3: Order the programs above like below:;
%* "&B.\010_aaa.sas", ;
%* "&A.\015_ccc.sas", ;
%* "&B.\020_bbb.sas", ;
%* "&A.\022_ddd.sas";
%*Step 4: run the above programs in the sorted sequence.;

%*010.	Check parameters.;
%local
	Lchk
	Lcnt
	Lnpgm
;
%let	Lchk	=	0;
%let	Lcnt	=	0;
%let	Lnpgm	=	0;
%if	%nrbquote(&FdrProc.)	EQ	%then %do;
	%put	NOTE: No Folder is provided to search for callable programs!;
	%goto	EndOfMac;
%end;
%else %do;
	%let	Lchk	=	1;
	%let	Lcnt	=	%eval(%sysfunc(countc(%nrbquote(&FdrProc.),#)) + 1);
%end;

%*100.	Find necessary SAS programs.;
%do	FDRi=1	%to	&Lcnt.;
	%*010.	Initialize.;
	%global
		LeFdr&FDRi.
		LnFdr&FDRi._&CodePfx.
	;
	%let	LeFdr&FDRi.	=	%scan(%nrbquote(&FdrProc.),&FDRi.,#);
	%let	LnFdr&FDRi._&CodePfx.	=	0;

	%*100.	Search by string pattern.;
	%*Below macro is from "&cdwmac.\AdvOp";
	%getFILEbyStrPattern(
		inFDR		=	%nrbquote(&&LeFdr&FDRi..)
		,inRegExp	=	%nrbquote(^&CodePfx.\d{2}_.+\.sas\b)
		,exclRegExp	=	%nrbquote((bak)|(000_Pre_Def\.sas))
		,outCNT		=	LnFdr&FDRi._&CodePfx.
		,outELpfx	=	LeFdr&FDRi._&CodePfx._
	)

	%*900.	Prepare condition for verification.;
	%let	Lnpgm	=	%eval(&Lnpgm. + &&LnFdr&FDRi._&CodePfx..);
%end;

%*190.	Check availability.;
%if	%nrbquote(&Lnpgm.)	=	0	%then %do;
	%put	NOTE: No program is found for involvement.;
	%goto	EndOfMac;
%end;

%*200.	Re-order the found programs.;
%*210.	Retrieval of the found programs.;
data &procLIB.._tmp_SASpgm;
	length
		SASfdr	$512.
		SASpgm	$128.
	;
	%do	FDRi=1	%to	&Lcnt.;
		%if	%nrbquote(&&LnFdr&FDRi._&CodePfx..)	>	0	%then %do;
			%do	Pi=1	%to	&&LnFdr&FDRi._&CodePfx..;
				SASfdr	=	"&&LeFdr&FDRi..";
				SASpgm	=	"&&LeFdr&FDRi._&CodePfx._&Pi..";
				output;
			%end;
		%end;
	%end;
run;

%*220.	Sort;
proc sort
	data=&procLIB.._tmp_SASpgm
;
	by	SASpgm;
run;

%*228.	Check duplicated program names.;
%*Below macro is from "&cdwmac.\AdvOp";
%chkDUPerr(
	inDAT	=	&procLIB.._tmp_SASpgm
	,inKEY	=	SASpgm
	,dupDAT	=	tmp._err_pgm_code
)

%*280.	Generation for new sequence.;
data _NULL_;
	set &procLIB.._tmp_SASpgm end=EOF;
	by	SASpgm;
		call symputx(cats("LePGM&CodePfx._",_N_),cats(SASfdr,"\",SASpgm),"L");
	if	EOF	then do;
		call symputx("LnPGM&CodePfx.",_N_,"L");
	end;
run;

%*700.	Include the SAS programs found.;
%put	NOTE: Below programs are executed at this step by the listed order:;
%put	-------------------------------------------------------------------;
%do INCi=1 %to &&LnPGM&CodePfx..;
	%put	"&&LePGM&CodePfx._&INCi..";
%end;
%put	-------------------------------------------------------------------;
%do INCi=1 %to &&LnPGM&CodePfx..;
	%include	"&&LePGM&CodePfx._&INCi..";
%end;

%EndOfMac:
%mend IncludeProcBySeq;