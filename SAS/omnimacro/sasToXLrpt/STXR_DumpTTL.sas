%macro STXR_DumpTTL(varhdr=,vardat=);
	%local
		L_fmt_ws
		varclean
		hdrcnt
		hdrelt
		HDRTTL
		LptnHDR
		PTNi
		DSID
		anobs
		chkmaccnt
		rc
		DUMPi
	;

	%let	L_fmt_ws	=;

	%*010.	Screen the variable headers;
	%*011.	Define element list of "&varhdr.";
	%let	varclean	=	%sysfunc(compbl(&varhdr.));
	%let	hdrcnt		=	1;
	%let	hdrelt		=	%QSCAN(&varclean.,&hdrcnt.,%STR( ));
	%local	HDR1;
	%let	HDR1		=	%substr(&hdrelt.,1);
	%DO %WHILE(&hdrelt.	NE);
		%let	hdrcnt	=	%EVAL(&hdrcnt.+1);
		%let	hdrelt	=	%QSCAN(&varclean.,&hdrcnt.,%STR( ));
		%if	&hdrelt.	EQ	%then	%goto	endLoopHDR;
		%local	HDR&hdrcnt.;
		%let	HDR&hdrcnt.	=	%substr(&hdrelt.,1);
	%END;
	%endLoopHDR:
	%let	HDRTTL=%EVAL(&hdrcnt.-1);

	%*012.	Prepare the pattern for match-finding of all locators.;
	%let	LptnHDR	=;
	%do	PTNi=1	%to	&HDRTTL.;
		%let	LptnHDR	=	&LptnHDR.|&&HDR&PTNi..;
	%end;
	%let	LptnHDR	=	%qsubstr(&LptnHDR.,2);

	%*020.	Retrieve all Global variables that we need to export.;
	proc sql;
		create table exr_WORK.vmacros as (
			select *
			from dictionary.macros
			where scope = 'GLOBAL'
		);
	quit;

	data exr_WORK.getXLtplVARDF;
		set
			exr_WORK.vmacros
			end=EOF
		;

		%*100.	Prepare the match rules.;
		retain	rxHDR;
		if	_N_	=	1	then do;
			rxHDR	=	prxparse("/^(&LptnHDR.).*$/i");
		end;

		%*200.	Output the desired variable list.;
		if	prxmatch(rxHDR,name)	then do;
			output;
		end;

		%*900.	Purge the memory;
		rename name = Gvar;
		if	EOF	then do;
			call prxfree(rxHDR);
		end;
		drop rxHDR;
	run;

	%*If there is no Global Variable matched, we need to quit the program;
	%let	chkmaccnt	=	0;
	%let	DSID	=	%sysfunc(open(exr_WORK.getXLtplVARDF, IS));
	%let	anobs	=	%sysfunc(attrn(&DSID.,ANOBS));
	%if	&anobs.	=	1	%then %do;
		%let	chkmaccnt	=	%sysfunc(attrn(&DSID.,NLOBS));
	%end;
	%let	rc	=	%sysfunc(close(&DSID.));

	%if	&chkmaccnt.	=	0	%then %do;
		%put;
		%put	&saserror.: [&L_mcrLABEL.]The EXPORTTOEXCEL macro bombed due to "No Export Data".;
		%put;
		%goto	DTquit;
	%end;

	%*100.	Dump all values.;
	%*110.	Define all parameters.;
	proc sql;
		create table exr_WORK.dumpvalue as (
			select
				o.*
				,p.value
			from &vardat. as o
			left join exr_WORK.getXLtplVARDF as p
				on	upcase(o.Gvar)	=	upcase(p.Gvar)
		);
	quit;

	data _NULL_;
		set exr_WORK.dumpvalue end=EOF;
		%*Here we cannot use SYMPUTX, for it removes the trailing blanks from the value.;
		CALL SYMPUT(CATS('PUTWSNM',_N_),substr(varToWS,1,ToWSLenNM));
		CALL SYMPUTX(CATS('PUTVAL',_N_),value);
		CALL SYMPUTX(CATS('PUTROWN',_N_),varrown);
		CALL SYMPUTX(CATS('PUTCOLN',_N_),varcoln);
		CALL SYMPUTX(CATS('PUTTYPE',_N_),VarTP);
		IF EOF THEN CALL SYMPUTX('PUTVALTTL',_N_);
	run;

	%*130.	Execute the input procedure.;
	%do DUMPi=1 %to &PUTVALTTL.;
		%STXR_Dump&&PUTTYPE&DUMPi..(
			insheetnm	=	%nrbquote(&&PUTWSNM&DUMPi..)
			,valin		=	%nrbquote(&&PUTVAL&DUMPi..)
			,cell1row	=	%nrbquote(&&PUTROWN&DUMPi..)
			,cell1col	=	%nrbquote(&&PUTCOLN&DUMPi..)
		)
	%end;

%DTquit:
%mend STXR_DumpTTL;