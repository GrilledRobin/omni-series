%macro executesql(homeroot=,insqlroot=,sqlcmdroot=,infn=,svrnm=,iftrust=,svrusr=,svrpwd=,dbnm=,outroot=,outfn=,erroot=,errfn=,errappend=);
	%local
		sqlusrpwd
		outname
		errname
		tmpvar1
	;
	%if	"&sqlcmdroot"	=	""	%then %let	sqlcmdroot	=	C:\Program Files\Microsoft SQL Server\90\Tools\Binn;
	%if	"&iftrust"	NE	"0"	%then %let	iftrust	=	1;
		%else %let	iftrust	=	0;
	%if	"&errappend"	^=	"0"	%then %let	errappend	=	1;
	%let	sqlusrpwd	=;
	%let	outname		=;
	%let	errname		=;
	%if	"&iftrust"	=	"0"	%then %do;
		%let	sqlusrpwd	=	%str(-U &svrusr. -P &svrpwd.);
	%end;
	%else %do;
		%let	sqlusrpwd	=	%str(-E);
	%end;

	%* Gets rid of the last backslash in each path, if one is included.;
	%if	("%substr(&homeroot,%length(&homeroot),1)"="\")
		or ("%substr(&homeroot,%length(&homeroot),1)"="/")
		%then %let homeroot	=	%substr(&homeroot,1,%eval(%length(&homeroot)-1));
	%let	homeroot	=	&homeroot.\;
	%if	("%substr(&insqlroot,%length(&insqlroot),1)"="\")
		or ("%substr(&insqlroot,%length(&insqlroot),1)"="/")
		%then %let insqlroot	=	%substr(&insqlroot,1,%eval(%length(&insqlroot)-1));
	%if ( "&outroot" ^= "" ) %then %do;
		%if	("%substr(&outroot,%length(&outroot),1)"="\")
			or ("%substr(&outroot,%length(&outroot),1)"="/")
			%then %let	outroot	=	%substr(&outroot,1,%eval(%length(&outroot)-1));
		%let	outroot	=	&outroot.\;
	%end;
	%if ( "&erroot" ^= "" ) %then %do;
		%if	("%substr(&erroot,%length(&erroot),1)"="\")
			or ("%substr(&erroot,%length(&erroot),1)"="/")
			%then %let	erroot	=	%substr(&erroot,1,%eval(%length(&erroot)-1));
		%let	erroot	=	&erroot.\;
	%end;
	%if	"&outfn"	NE	""	%then %do;
		%let	outname		=	%str( -o %"&outroot.&outfn.%");
	%end;
	%if	"&errfn"	NE	""	%then %do;
		%let	tmpvar1		=;
		%if	"&errappend"	=	"1"	%then %let	tmpvar1	=	%str(>);
		%let	errname		=	%str( -b -V 10 >&tmpvar1. %"&erroot.&errfn.%");
	%end;

	data _NULL_;
		file	"&homeroot.runSQLfile.bat";
		put	"@echo off";
		put	'set PATH=%PATH%;'"&sqlcmdroot";
		%if	"&errappend"	=	"0"	%then %do;
			put	'if exist "'"&erroot.&errfn."'" (';
			put	'	@del "'"&erroot.&errfn."'"';
			put	')';
		%end;
		put	"CD &insqlroot.";
		put	'sqlcmd -S'"&svrnm &sqlusrpwd"' -d '"&dbnm"' -i "'"&infn.""&outname.&errname.";
		put	"@echo on";
		put	'exit';
	run;
	X "&homeroot.runSQLfile.bat";
%mend;