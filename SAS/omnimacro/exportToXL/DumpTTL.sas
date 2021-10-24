%macro DumpTTL(varhdr=,vardat=);
	%local	L_fmt_ws;

	%let	L_fmt_ws	=;

	/*010.	Screen the variable headers*/
	%let	varclean=	%sysfunc(trim(%sysfunc(left(%sysfunc(compbl(&varhdr))))));

	/*020.	Retrieve all Global variables that we need to export.*/
	data getXLtplVARDF;
		set sashelp.vmacro;
		if scope = 'GLOBAL';
		do i=1 to count(upcase("&varclean.")," ")+1;
			if index(name,scan(upcase("&varclean."),i)) = 1 then do;
				output;
			end;
		end;
		rename name = Gvar;
		drop i;
	run;

	/*If there is no Global Variable matched, we need to quit the program*/
	proc sql noprint;
		select trim( left( put( nobs, 20. ) ) ) into :chkmaccnt
		from sashelp.vtable
		where ( libname = upcase( "WORK" ) ) and ( memname = upcase( "getXLtplVARDF" ) );
	quit;

	%if	"&chkmaccnt." = ""	%then %do;
		%put;
		%put &saserror: The EXPORTTOEXCEL macro bombed due to "No Export Data";
		%put;
		%goto DTquit;
	%end;

	proc sort data=getXLtplVARDF;
		by Gvar;
	run;

	data dumpvalue;
		merge
			&vardat.(in=i)
			getXLtplVARDF(in=j)
		;
			by Gvar;
		if i;
		/*This variable is for positioning the "active cell" in the output workbook*/
		if i and j then do;
			CALL SYMPUT('sheet',trim(left(varToWS)));
		end;
	run;

	data _NULL_;
		set dumpvalue end=EOF;
		CALL SYMPUT('PUTWSNM'||(LEFT(PUT(_N_,5.))),trim(left(varToWS)));		/*The Worksheet Name*/
		CALL SYMPUT('PUTVAL'||(LEFT(PUT(_N_,5.))),trim(left(value)));
		CALL SYMPUT('PUTROWN'||(LEFT(PUT(_N_,5.))),trim(left(varrown)));
		CALL SYMPUT('PUTCOLN'||(LEFT(PUT(_N_,5.))),trim(left(varcoln)));
		CALL SYMPUT('PUTTYPE'||(LEFT(PUT(_N_,5.))),trim(left(varIsFld)));
		IF EOF THEN CALL SYMPUT('PUTVALTTL',LEFT(PUT(_N_,8.)));
	run;

	/*030.	Execute the input procedure*/
	%do DUMPi=1 %to &PUTVALTTL.;
		%if	"&&PUTTYPE&DUMPi.." = "1"	%then %do;
			%DumpFld(
				insheetnm	= &&PUTWSNM&DUMPi..
				,valin		= &&PUTVAL&DUMPi..
				,cell1row	= &&PUTROWN&DUMPi..
				,cell1col	= &&PUTCOLN&DUMPi..
			);
		%end;
		%else %do;
			%if	"&&PUTVAL&DUMPi.." = ""	%then %do;
				%*;
			%end;
			%else %do;
				%if	%index(&&PUTVAL&DUMPi..,%str(.)) > 0	%then %do;
					%let	L_lib	=	%scan(&&PUTVAL&DUMPi..,1,%str(.));
					%let	L_dsn	=	%scan(&&PUTVAL&DUMPi..,2,%str(.));
				%end;
				%else %do;
					%let	L_lib	=	WORK;
					%let	L_dsn	=	&&PUTVAL&DUMPi..;
				%end;
				%DumpDat(
					insheetnm	=	&&PUTWSNM&DUMPi..
					,libin		=	&L_lib.
					,dsin		=	&L_dsn.
					,cell1row	=	&&PUTROWN&DUMPi..
					,cell1col	=	&&PUTCOLN&DUMPi..
				);
			%end;
		%end;
		%* Formats the Excel spreadsheet if formatting is desired.;
		%let	L_fmt_ws	=	&&PUTWSNM&DUMPi..;
		%if	&wsformat ne none	%then %format_&wsformat;
	%end;

%DTquit:;
%mend;