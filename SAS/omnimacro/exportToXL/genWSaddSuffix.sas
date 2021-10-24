%macro genWSaddSuffix(inSuffix=);

/*
This macro generates all destination sheets with a given suffix, orignating the name of
&TMPLSHEET. This is useful for multi-sheet reports.
*/

	DATA _NULL_;
		SET _sheet_names END=EOF;
		CALL SYMPUT('L_WSRN'||(LEFT(PUT(_N_,5.))),trim(left(n_rows_char)));		/*The last used row of each sheet*/
		CALL SYMPUT('L_WSCN'||(LEFT(PUT(_N_,5.))),trim(left(n_cols_char)));		/*The last used column of each sheet*/
		CALL SYMPUT('L_WSNM'||(LEFT(PUT(_N_,5.))),trim(left(sh_name)));
		IF EOF THEN CALL SYMPUT('L_WSTTL',LEFT(PUT(_N_,8.)));
	RUN;

	%* If a name was specified for &SHEET, then we must first of all check whether;
	%* &SHEET already exists. We can do this because we have the data set _SHEET_NAMES.;
	%* If &SHEET already exists, we simply dump the SAS data there, and done. This;
	%* assumes that users know what they are doing, at least to a certain degree, since;
	%* extant data on the &SHEET may be partially or completely over-written by the new;
	%* data from SAS. OTOH, if there is no &SHEET yet, we need to make it, using similar;
	%* techniques as in the above.;

	%DO LNWSi=1 %TO &L_WSTTL.;
		%let	L_TPLWS	=	&&L_WSNM&LNWSi..;
		%let	L_NEWWS	=	&&L_WSNM&LNWSi..&inSuffix.;

		%* Check if it exists.;
		data _null_;
			set _sheet_names;
			if ( upcase( sh_name ) = "%upcase( &L_NEWWS )" ) then call symput( 'shxists', '1' );
		run;

		%if &shxists = 0 %then %do;

			%* Take the data set we made in %LOADNAMES and copy it onto a new one.;
			data _sheet_names_before;
				set _sheet_names;
			run;

			%* Insert a new sheet and move it to the back.;
			data _null_;
				length ddecmd $ 200;
				file sas2xl;
				put "[&workbooknext()]";
				put "[&workbookinsert(1)]";
				ddecmd = "[&workbookmove(,"||'"'||"&savename"||'.xls")]';
				%*ddecmd = "[&workbookmove(,"||'"'||"&savename"||'.xls",'||%eval(&nsheets+3)||')]';
				%* &NSHEETS+3, since we have the original sheets, plus the macro sheet,;
				%* plus the new sheet, plus something else (???).;
				put ddecmd;
			run;

			%loadNames;

			%* Read the name of it, store it in &OLDSHNAM.;
			%let	oldshnam	=;
			proc sql noprint;
				select sh_name
				into :oldshnam
				separated by ''
				from
					_sheet_names
				where
					sh_name not in ( select sh_name from _sheet_names_before );
			quit;

			%* Write (and run) an Excel macro in the Macro1-sheet to rename the worksheet;
			%* &OLDSHNAM as &SHEET.;
			data _null_;
				length ddecmd $ 200;
				file xlmacro;
				ddecmd = "=&workbookname("||'"'||"&oldshnam"||'","'||"&L_NEWWS"||'")';
				put ddecmd;
				put "=&halt(&true)";
				put '!dde_flush';
				file sas2xl;
				ddecmd = "[&run("||'"'||"&macrosheet!"||"&r.1&c.1"||'")]';
				put ddecmd;
				put "[&error(&false)]";
			run;

			%* Clear the Macro1-sheet in case we need it for another bit of code.;
			data _null_;
				format ddecmd $200.;
				file sas2xl;
				ddecmd = "[&workbookactivate("||'"'||"&macrosheet"||'",'||"&false)]";
				put ddecmd;
				ddecmd = "[&select("||'"'||"&r.1&c.1:&r&maxmrow&c.2"||'")]';
				put ddecmd;
				put "[&clear(1)]";
				ddecmd = "[&select("||'"'||"&r.1&c.1"||'")]';
				put ddecmd;
			run;

		%end;

		%* As a last step, if a template worksheet name is given and exists, we delete the;
		%* worksheet just made above and then copy the template worksheet instead.  Maybe it;
		%* seems inefficient to do all that work above just to delete the worksheet, but it;
		%* is an easy way to get the right value of &SHEET, especially when equal to SheetN.;

		data _null_;
			length ddecmd $ 200;
			file xlmacro;
			ddecmd = "=&workbookcopy("||'"'||"&L_TPLWS"||'","'||"&savename"||'.xls")';
			%*ddecmd = "=&workbookcopy("||'"'||"&L_TPLWS"||'","'||"&savename"||'.xls",'||%eval(&nsheets+3)||')';
			put ddecmd;
			put "=&error(&false)";
			ddecmd = "=&workbookdelete("||'"'||"&L_NEWWS"||'"'||")";
			put ddecmd;
			%* Deleting it after copying it allows us to have &SHEET = &TMPLSHEET -- and;
			%* thus have an easy way to move it to the back;
			ddecmd = "=&workbookname("||'"'||"&L_TPLWS (2)"||'","'||"&L_NEWWS"||'")';
			put ddecmd;
			%if	( ( %among( %upcase( %substr( &deletetmplsheet, 1, 1 ) ), Y T 1 ) )
				and ( %superq( L_NEWWS ) ne %superq( L_TPLWS ) )
			) %then %do;
				put "=&error(&false)";
				ddecmd = "=&workbookdelete("||'"'||"&L_TPLWS"||'"'||")";
				put ddecmd; 
			%end;
			put "=&halt(&true)";
			put '!dde_flush';
			file sas2xl;
			ddecmd = "[&run("||'"'||"&macrosheet!"||"&r.1&c.1"||'")]';
			put ddecmd;
		run;

		%* Clear the Macro1-sheet in case we need it for another bit of code.;
		data _null_;
			format ddecmd $200.;
			file sas2xl;
			ddecmd = "[&workbookactivate("||'"'||"&macrosheet"||'",'||"&false)]";
			put ddecmd;
			ddecmd = "[&select("||'"'||"&r.1&c.1:&r&maxmrow&c.2"||'")]';
			put ddecmd;
			put "[&clear(1)]";
			ddecmd = "[&select("||'"'||"&r.1&c.1"||'")]';
			put ddecmd;
		run;

		/* Restore the sheet names, for covering the stuffs we did before and generating the correct names.*/
		%loadNames;

		%* Generate necessary table for the retrieval of the position of each variable in each template EXCEL sheet;
		%getXLtplVAR(
			inxlwb=&tmplpath.\&tmplname.
			,inxlws=&L_TPLWS.
			,toxlws=&L_NEWWS.
			,maxrow=&&L_WSRN&LNWSi..
			,maxcol=&&L_WSCN&LNWSi..
			,varhdr=&varheader.
			,outdatlib=work
			,outdatnm=xlvartbl
		);

		%let	shxists	=	0;

	%END;

%mend;