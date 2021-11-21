%macro BulkCopySRC;
%*000.	Introduction.;
%*Creation: Lu Robin Bin 20140220;
%*Version: 1.00;
%*This macro is intended to Copy all the system required source data to the new location.;

%*001.	Glossary.;

%*002.	Update log.;
%*Updater: Lu Robin Bin 20140220;
%*Version: 1.00;
%*Log: Setup.;

%*010.	Set parameters.;
%let	dt	=	20131231;

%global G_cur_year;
%let G_cur_year = %substr(&dt.,1,4);
%global G_cur_mth;
%let G_cur_mth = %substr(&dt.,5,2);
%global G_cur_day;
%let G_cur_day = %substr(&dt.,7,2);

%let	L_curMon	=	&G_cur_year.&G_cur_mth.;

%local
	Ldest
	rSlash
;
%let	Ldest	=	C:;
%*Regular Expression to retrieve the path name WITHOUT the Drive Name or UNC IP Address.;
%let	rSlash	=	%sysfunc(prxparse(s/^\\+//i));

options
	sasautos=(
		sasautos
		"X:\SAS_report\omnimacro\AdvOp"
		"X:\SAS_report\omnimacro\FileSystem"
		"X:\SAS_report\omnimacro\CDW_Filter"
		"X:\SAS_report\omnimacro\CDW_FldMap"
	)
	mautosource
/*	errorabend*/
	xmin
;

%*020.	Libnames.;
%let	rootx	=	\\10.25.238.41\sme;
libname	CASAbase	"&rootx.\SME_DATA\Source\ebbs\custbase";
libname	d_a_rev		"&rootx.\SAS_report\1298609\Monthly_010_Revenue\Data\A_REV";
libname	d_RLS		"&rootx.\SME_DATA\Source\RLS\daily";
libname	m_MUREX		"&rootx.\SME_DATA\Source\SD\Monthly";
libname	smecomp		"&rootx.\SME_DATA\SRC_COMP";
libname	sr_FIN		"&rootx.\SME_DATA\Rev_SRC\Finance";
libname	sr_RLS		"&rootx.\SME_DATA\Rev_SRC\Rls";
libname	yLTP		"&rootx.\SME_DATA\Source\LTP";
libname yrate 		"&rootx.\Indv_Data\SHARE_CDW\UTS";
libname	ysrc		"&rootx.\SME_DATA\SRC";

%*030.	Create list.;
%genVarByDate(
	clnDSN		=	ysrc
	,clnPFX		=	calendar
	,inDATE		=	&G_cur_year.&G_cur_mth.&G_cur_day.
	,procLIB	=	WORK
);

%genvarlist(
	nstart	=	1
	,inlst	=	%nrbquote(
					CASAbase.custbase&L_dn_LastWorkDayOfMth.
					d_a_rev.a_rev_sme_acct_comp&L_curMon.
					d_RLS.CRB310B&L_dn_LastWorkDayOfMth.
					m_MUREX.structuredeposit&L_curMon.
					smecomp.a_acct_sme&L_curMon.
					smecomp.A_cust_sme&L_curMon.
					sr_FIN.fin_fxrate&L_curMon.
					sr_RLS.CRB310B&L_curMon.
					yLTP.LTP&L_curMon.
					yLTP.LTP&L_m_lastMthOfPrevQtr.
					yrate.uts_fxrate_tob
					ysrc.brw&L_curMon.
					ysrc.RM&L_curMon.
					ysrc.Sme_avg_casa&L_curMon.
					ysrc.Sme_avg_pcd&L_curMon.
					ysrc.Sme_avg_td&L_curMon.
					ysrc.smebaserm&L_curMon.
				)
	,nvarnm	=	GeDAT
	,nvarttl=	GnDAT
);

%*100.	Extract the file names from the source data of each program.;
%do	DATi=1	%to	&GnDAT.;
	%*100.	Retrieve the Libname of current data.;
	%let	Llibnm	=	%scan(&&GeDAT&DATi..,1,%str(.));

	%*200.	Retrieve the physical path of the libname.;
	%FS_getPathList4Lib(
		inDSN		=	&Llibnm.
		,outCNT		=	GnP&Llibnm.
		,outELpfx	=	GeP&Llibnm.
	);

	%*300.	Retrieve the parameter for the copy of current data.;
	%do	PATHi=1	%to	&&GnP&Llibnm..;
		%let	fullpath	=	%sysfunc(compress(&&GeP&Llibnm.&PATHi..,%str(%'%")))\%scan(&&GeDAT&DATi..,2,%str(.)).sas7bdat;
		%*FCopy&DATi. : File for Copy;
		%*FDest&DATi. : Destination Location;
		%*FDFdr&DATi. : Destination Folder Name;
		%let	FCopy&DATi.	=;
		%let	FDest&DATi.	=;
		%let	FDFdr&DATi.	=;
		%if	%sysfunc(fileexist(&fullpath.))	%then %do;
			%*Find the first appearance and quit the loop.;
			%*rs : Slash or Back-slash Removed;
			%let	rs	=	%sysfunc(prxchange(&rSlash.,-1,%superq(fullpath)));
			%let	FDest&DATi.	=	&Ldest.%qsubstr(&rs.,%index(&rs.,\));
			%let	FDFdr&DATi.	=	%sysfunc(compress(&&GeP&Llibnm.&PATHi..,%str(%'%")));
			%let	FCopy&DATi.	=	&fullpath.;
			%goto	ExitLoopFdr;
		%end;
	%end;
	%ExitLoopFdr:
%end;

%*900.	Copy the files into the destination location.;
%do	DATi=1	%to	&GnDAT.;
	%if	%nrbquote(&&FCopy&DATi..)	NE	%then %do;
		%*100.	Create destination folder.;
		%put	md "&&FDFdr&DATi..";
		%*sysexec	(md "&&FDFdr&DATi.." & exit);

		%*200.	Copy files.;
		%put	copy /V /Y "&&FCopy&DATi.." "&&FDest&DATi..";
		%*sysexec	(copy /V /Y "&&FCopy&DATi.." "&&FDest&DATi.." & exit);
	%end;
%end;

%mend BulkCopySRC;
%BulkCopySRC;