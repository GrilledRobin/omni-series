%global	G_sqlsvr;
%let	G_sqlsvr=127.0.0.1;
%global	G_DBNM;
%let	G_DBNM=ChinaCRM_Susbcr;
%global	G_entrust;
%let	G_entrust=1;
%global	G_sqlusr;
%let	G_sqlusr=;
%global	G_sqlpwd;
%let	G_sqlpwd=;
%global	G_sqlcmd;
%let	G_sqlcmd=C:\Program Files\Microsoft SQL Server\90\Tools\Binn;


/*
dm 'log' clear;
dm 'odsresults' clear;
*/

%global
	pfroot
	pfpgm
	pwroot
	pjtroot
	stgroot
	advroot
	exroot
	tplroot
	outroot
	macroot
	cdwmac
	sqlroot
	rootx
	rptDATA
;
%let	pfroot	=	D:\SAS\ProgramSetTemplate;	%*Root path for Platform which stores the common programs.;
%let	pwroot	=	D:\SAS;
%let	cdwmac	=	D:\SAS\omnimacro;
%let	rootx	=	\\10.25.238.41\sme;
%let	pjtroot	=	&pwroot.\ProgramSetTemplate;
%let	advroot	=	&cdwmac.\AdvOp;
%let	exroot	=	&cdwmac.\sasToXLrpt;
%let	tplroot	=	&pwroot.\900tools\002RPTtpl;
%let	vbsroot	=	&pwroot.\900tools\200VBS;
%let	outroot	=	&pjtroot.\Report;
%let	rptDATA	=	&pjtroot.\Data;
%let	stgroot	=	&pjtroot.\PGM;
%let	sqlroot	=	&stgroot.\sql;
%let	pfpgm	=	&pfroot.\PGM;
%let	macroot	=	&pfpgm.\macros;

libname	tmp		"&rptDATA.\tmp";
%*libname	work2	"D:\SAS\temp";
libname	work2		"&rptDATA.\WORK";
libname	exr_WORK	"&rptDATA.\exrWORK";

%*Universal system environment.;
options	NOQUOTELENMAX;
%macro opt;
%if	%sysevalf(&sysver.>9.1)	%then %do;
	options
		varlenchk=nowarn
	;
%end;
%mend opt;
%opt

%macro useodbc(entrust=,odbcusr=,odbcpwd=);
	%global	ouser;
	%let	ouser=;
	%if	&entrust.	NE	0	%then %do;
		%let	entrust	=	1;
	%end;
	%else %do;
	 	%let	entrust	=	0;
		%let	ouser	=	user=&odbcusr pwd=&odbcpwd.;
	%end;
%mend;
%useodbc(entrust=&G_entrust.,odbcusr=&G_sqlusr.,odbcpwd=&G_sqlpwd.);
%*libname	irmdata	odbc	dsn=Localhost &ouser.;

%macro rootlists(srcROOT=,desROOT=,ROOTLST=);
	%let	roots=;
	%if	%nrbquote(&ROOTLST.)	NE	%then %do;
		%let	ROOTLST=	%sysfunc(compbl(&ROOTLST.));
		%let	CCCC=1;
		%let	WWWW=%QSCAN(&ROOTLST.,&CCCC.,%STR( ));
		%let	VAR1=%STR(&WWWW.);
		%DO %WHILE(&WWWW. NE);
			%let CCCC=%EVAL(&CCCC.+1);
			%let WWWW=%QSCAN(&ROOTLST.,&CCCC.,%STR( ));
			%let VAR&CCCC.=%STR(&WWWW.);
		%END;
		%let	TOTAL=%EVAL(&CCCC.-1);

		%DO I=1 %TO &TOTAL.;
			%let	roots=&roots.%str(,%"&srcROOT.\&&VAR&I..%");
		%END;
		%*Below global variable is for the customized root name for later reference;
		%GLOBAL	&desROOT.;
		%let	&desROOT.=&roots.;
/*		%let	roots=%substr(&roots,1);
		%put	&roots;*/
	%end;
%mend;

%*Below commands generate the current date in a format of "yyyymmdd hh:mm:ss.mmm";
data	_NULL_;
	call symputx("rpt",put(today(),yymmddN8.),"G");
	call symputx("ddate",put(today(),yymmddD10.),"G");
	call symputx("dtime",translate(right(put(time(),time12.3)),'0',' '),"G");
run;

%GLOBAL	RPTdate;
%let	RPTdate	=	&rpt.;

%GLOBAL	G_DTable;
%let	G_DTable	=	%str(&ddate. &dtime.);
