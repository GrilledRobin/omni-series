%* Sets up the template and gathers information about it.                                ;


%macro setTemplate;
/*
  %local shxists tshxists nsheets oldshnam;
  %let shxists = 0;
  %let tshxists = 0;
  %let nsheets = 0;
  %let oldshnam = ;
*/
  %* If &TMPLPATH and &TMPLNAME are given (and exist, as verified in %checkParms), we    ;
  %* open the document they specify. Otherwise, we ask for a new blank document of the   ;
  %* workbook type. We then make sure we have a maximized screen, to prevent errors      ;
  %* later.                                                                              ;
  %if ( ( "&tmplpath" ne "" ) and ( "&tmplname" ne "" ) ) %then %do;
    data _null_;
      length ddecmd $ 200;
      file sas2xl;
      put "[&error(&false)]";
      ddecmd = "[&open("||'"'||"&tmplpath"||'\'||"&tmplname"||'.xls")]';
      put ddecmd;
      put "[&appmaximize()]";
      put "[&windowmaximize]";
    run;
    %end;
  %else %do;
    data _null_;
      file sas2xl;
      put "[&error(&false)]";
      put "[&new(1)]";
      put "[&appmaximize()]";
      put "[&windowmaximize]";
    run;
    %end;

  %* We then need to define a DDE link pointing to the exact location where data should  ;
  %* inserted. To do so, we need to know the filename. The easiest way to find the       ;
  %* filename is to save the document at the location specified by &SAVEPATH with the    ;
  %* name &SAVENAME.                                                                     ;
  data _null_;
    length ddecmd $ 200;
    file sas2xl;
    put "[&error(&false)]";
    ddecmd = "[&saveas("||'"'||"&savepath"||'\'||"&savename"||'.xls")]';
    put ddecmd;
  run;

  %* In what follows, we may need an old-style macro-sheet to be available in the        ;
  %* current Excel workbook. We assume the workbook to contain no such sheets yet, so    ;
  %* ours will be named 'MacroN' (in the language of the Excel installation -- e.g.,     ;
  %* 'MakroN' in German) by default, where N is the smallest integer not already in use. ;
  %* We also want it to sit on top of all the other sheets in the workbook.  This is     ;
  %* important in what follows. Since we do not know what the name of this workbook is   ;
  %* ahead of time, we do some clever stuff to find it: We look at the names of all the  ;
  %* worksheets before and after the addition and note the name of the sheet that was    ;
  %* added.                                                                              ;
  data _sheet_names_before;
    length strlen 8 sh_name $ 31 str wb_name wb_path $ 300 topic $ 1000;
	retain str " "
	  strlen 0
	  wb_name "&savename"
	  wb_path "&savepath";
	infile xltopics pad dsd notab dlm='09'x;
	input topic $ @@;
	if _n_ = 1 then do;
	  str = "[&savename..xls]";
	  strlen = length( trim( str ) );
	  end;
	if topic =: "[&savename..xls]" then do;
	  %* If topic starts with [&savename..xls] ...                                       ;
	  sh_name = substr( topic, strlen + 1 );
	  output;
	  end;
	drop str strlen topic;
  run;

  %* Now add the macro sheet.                                                            ;
  data _null_;
    length ddecmd $ 200;
    file sas2xl;
    %* In case the current workbook has more than one sheet selected, the                ;
    %* &WORKBOOKINSERT command will insert multiple new sheets before those selected. We ;
    %* do not want that and therefore advance the selection by one, just as a means of   ;
    %* making sure that a single sheet is selected.                                      ;
    put "[&workbooknext()]";
    %* Create the blank Macro1-sheet in front of the currently selected sheet.           ;
    put "[&workbookinsert(3)]";
  run;

  %* Now look at the new set of worksheets.                                              ;
  data _sheet_names_after;
    length strlen 8 sh_name $ 31 str wb_name wb_path $ 300 topic $ 1000;
	retain str " "
	  strlen 0
	  wb_name "&savename"
	  wb_path "&savepath";
	infile xltopics pad dsd notab dlm='09'x;
	input topic $ @@;
	if _n_ = 1 then do;
	  str = "[&savename..xls]";
	  strlen = length( trim( str ) );
	  end;
	if topic =: "[&savename..xls]" then do;
	  %* If topic starts with [&savename..xls] ...                                       ;
	  sh_name = substr( topic, strlen + 1 );
	  output;
	  end;
	drop str strlen topic;
  run;

  %* We now take the name of the new sheet and drop it into &MACROSHEET.                 ;
  proc sql noprint;
    select sh_name into :macrosheet
      separated by ''
	from
	  _sheet_names_after
	where
	  sh_name not in ( select sh_name from _sheet_names_before );
  quit;

  %* Now move the macro sheet to the top of the workbook.                                ;
  data _null_;
    length ddecmd $ 200;
    file sas2xl;
    ddecmd = "[&workbookmove("||'"'||"&macrosheet"||'","'||"&savename"||'.xls",1)]';
    put ddecmd;
  run;

  %* Subsequently, we define a range in the first column of the macro sheet,             ;
  %* sufficiently large to dump loads of Excel macro code into, but not so large that    ;
  %* the filename statement will take forever to compile. Yes, this depends on the size  ;
  %* of the cell range to which it points.  We assume that &MAXMROW cells will do -- if  ;
  %* not, we can just increase the value of &MAXMROW in the %SETVARIABLES macro.         ;
  filename xlmacro dde "excel|&macrosheet!&r.1&c.1:&r&maxmrow&c.1" notab lrecl = 200;

/*20090601 Added by Lu Bin : Begin*/
	%loadNames;
	%genWSaddSuffix(inSuffix=&rptWSSuffix.);
/*20090601 Added by Lu Bin : End*/

/*
  %* As the next step in preparing for the actual writing out of data, we need to        ;
  %* implement some worksheet logic. For starters, consider the case where no values are ;
  %* given for either &TMPLPATH or &TMPLNAME. In this case, the bit above will have      ;
  %* created a new workbook with one worksheet having the default name of 'Sheet1' (in   ;
  %* language of the Excel Installation -- e.g., 'Tabelle1' in German).  Therefore, if   ;
  %* the &SHEET parameter is left blank or has the value 'Sheet1', nothing needs to be   ;
  %* done -- just dump the data in Sheet1 and be done with it. If OTOH &SHEET has a      ;
  %* different value, we need to rename the default Sheet1 to reflect the desired name.  ;
  %* Note that sheet-names in Excel only look as if they are case sensitive. In fact     ;
  %* they are not, and we always need to compare uppercase sheet-names.                  ;
  %if ( ( "&tmplpath" = "" ) and ( "&tmplname" = "" ) ) %then %do;

    %* We now take the name of the new sheet and drop it into &SHEETNAME.                ;
    proc sql noprint;
      select sh_name into :sheetname
        separated by ''
	  from
	    _sheet_names_before;
    quit;

    %if ( %upcase( "&sheet" ) = "" ) %then %do;

		%let sheet = &sheetname; 

        %end;

    %else %do;

      %* Write (and run) an Excel macro in the Macro1-sheet that will rename the default ;
      %* worksheet 'Sheet1' to the desired name &SHEET.                                  ;
      data _null_;
        length ddecmd $ 200;
        file xlmacro;
        ddecmd = "=&workbookname("||'"'||"&sheetname"||'","'||"&sheet"||'")';
        put ddecmd;
        put "=&halt(&true)";
        put '!dde_flush';
        file sas2xl;
        runmacro = "[&run("||'"'||"&macrosheet!"||"&r.1&c.1"||'")]';
        put runmacro;
        put "[&error(&false)]";
      run;

      %* Clear the Macro1-sheet in case we need it for another bit of code.              ;
      data _null_;
        file sas2xl;
        wactivate = "[&workbookactivate("||'"'||"&macrosheet"||'",'||"&false)]";
        put wactivate;
        select1 = "[&select("||'"'||"&r.1&c.1:&r&maxmrow&c.2"||'")]';
        put select1;
        put "[&clear(1)]";
        select2 = "[&select("||'"'||"&r.1&c.1"||'")]';
        put select2;
      run;

      %end;

    %end;

  %* If we are here, then the template is named and exists.                              ;
  %else %do;

    %loadNames;

    %if ( "&tmplsheet" ne "" ) %then %do;

      %* Check if &TMPLSHEET (the particular worksheet in the template that we wish to   ;
      %* pour the data into) exists. So &TSHXISTS = 1 only if &TMPLSHEET is nonempty and ;
      %* exists in our workbook.                                                         ;
      data _null_;
        set _sheet_names;
        if ( upcase( sh_name ) = "%upcase( &tmplsheet )" ) then call symput( 'tshxists', '1' );
      run;

      %if &tshxists = 0 %then %do;
		option notes;
        %put &sasnote: The desired template worksheet does not exist!  Using a standard; 
        %put ------ worksheet instead.;
		option nonotes;
        %end;

      %end;

    %* If no &SHEET parameter was specified then we just need to add a new worksheet     ;
    %* (with the default name of SheetN, where N is the lowest available integer that is ;
    %* not in use yet), dump the data in it, and be done. Sounds simple? Some tricky     ;
    %* bits involved, though.                                                            ;
    %if ( %upcase( "&sheet" ) = "" ) %then %do;

	  %* Take the data set we made in %LOADNAMES and copy it onto a new one.             ;
	  data _sheet_names_before;
	  	set _sheet_names;
	  run;

	  %* Now we add another worksheet, which we will soon find the name of.              ;
      data _null_;
        length ddecmd $ 200;
        file sas2xl;
        %* Make sure only one sheet is selected.                                         ;
        put "[&workbooknext()]";
        %* Insert a new worksheet somewhere, exact name as yet unknown.                  ;
        put "[&workbookinsert(1)]";
        %* Now we need to pick up the exact sheetname that just got created. Rather than ;
        %* parse all names looking like 'Sheet...' from the data sheet _SHEET_NAMES, we  ;
        %* take the lazy approach and move the new sheet (which is at this point the     ;
        %* active one) to the back of the workbook. Leaving out the sheet-name in the    ;
        %* workbook.name Excel function will act on the active sheet. However, leaving   ;
        %* out the position parameter will cause an error. Luckily we know &NSHEETS, to  ;
        %* which we need to add 1 to account for our temporary Macro1-sheet.             ;
        ddecmd = "[&workbookmove(,"||'"'||"&savename"||'.xls",'||%eval(&nsheets+3)||')]';
        put ddecmd;
      run;

      %* Then, running %LOADNAMES once more, we get the exact name of our new worksheet  ;
      %* in the last obs of _SHEET_NAMES.                                                ;
      %loadNames;

	  %* We now take the name of the new sheet and drop it into &SHEET.                  ;
	  proc sql noprint;
		select sh_name into :sheet
		  separated by ''
		from
		  _sheet_names
		where
		  sh_name not in ( select sh_name from _sheet_names_before );
	  quit;

      %end;

    %* If a name was specified for &SHEET, then we must first of all check whether       ;
    %* &SHEET already exists. We can do this because we have the data set _SHEET_NAMES.  ;
    %* If &SHEET already exists, we simply dump the SAS data there, and done. This       ;
    %* assumes that users know what they are doing, at least to a certain degree, since  ;
    %* extant data on the &SHEET may be partially or completely over-written by the new  ;
    %* data from SAS. OTOH, if there is no &SHEET yet, we need to make it, using similar ;
    %* techniques as in the above.                                                       ;
    %else %do;

      %* Check if it exists.                                                             ;
      data _null_;
        set _sheet_names;
        if ( upcase( sh_name ) = "%upcase( &sheet )" ) then call symput( 'shxists', '1' );
      run;

      %if &shxists = 0 %then %do;

	    %* Take the data set we made in %LOADNAMES and copy it onto a new one.           ;
	    data _sheet_names_before;
	  	  set _sheet_names;
	    run;

        %* Insert a new sheet and move it to the back.                                   ;
        data _null_;
          length ddecmd $ 200;
          file sas2xl;
          put "[&workbooknext()]";
          put "[&workbookinsert(1)]";
          ddecmd = "[&workbookmove(,"||'"'||"&savename"||'.xls",'||%eval(&nsheets+3)||')]';
		    %* &NSHEETS+3, since we have the original sheets, plus the macro sheet,      ;
			%* plus the new sheet, plus something else (???).                            ;
          put ddecmd;
        run;

        %loadNames;

	    %* Read the name of it, store it in &OLDSHNAM.                                   ;
	    proc sql noprint;
		  select sh_name into :oldshnam
		    separated by ''
		  from
		    _sheet_names
		  where
		    sh_name not in ( select sh_name from _sheet_names_before );
	    quit;

        %* Write (and run) an Excel macro in the Macro1-sheet to rename the worksheet    ;
        %* &OLDSHNAM as &SHEET.                                                          ;
        data _null_;
          length ddecmd $ 200;
          file xlmacro;
          ddecmd = "=&workbookname("||'"'||"&oldshnam"||'","'||"&sheet"||'")';
          put ddecmd;
          put "=&halt(&true)";
          put '!dde_flush';
          file sas2xl;
          ddecmd = "[&run("||'"'||"&macrosheet!"||"&r.1&c.1"||'")]';
          put ddecmd;
          put "[&error(&false)]";
        run;

        %* Clear the Macro1-sheet in case we need it for another bit of code.            ;
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

      %end;

    %* As a last step, if a template worksheet name is given and exists, we delete the   ;
    %* worksheet just made above and then copy the template worksheet instead.  Maybe it ;
    %* seems inefficient to do all that work above just to delete the worksheet, but it  ;
    %* is an easy way to get the right value of &SHEET, especially when equal to SheetN. ;
    %if &tshxists = 1 %then %do;

      data _null_;
        length ddecmd $ 200;
        file xlmacro;
        ddecmd = "=&workbookcopy("||'"'||"&tmplsheet"||'","'||"&savename"||'.xls",'||%eval(&nsheets+3)||')';
        put ddecmd;
        put "=&error(&false)";
        ddecmd = "=&workbookdelete("||'"'||"&sheet"||'"'||")";
        put ddecmd;
          %* Deleting it after copying it allows us to have &SHEET = &TMPLSHEET -- and   ;
          %* thus have an easy way to move it to the back                                ;
        ddecmd = "=&workbookname("||'"'||"&tmplsheet (2)"||'","'||"&sheet"||'")';
        put ddecmd;
        %if ( ( ( %upcase( %substr( &deletetmplsheet, 1, 1 ) ) = Y ) or ( %upcase( %substr( &deletetmplsheet, 1, 1 ) ) = T ) or
		  ( %upcase( %substr( &deletetmplsheet, 1, 1 ) ) = 1 ) ) and ( %superq( sheet ) ne %superq( tmplsheet ) ) ) %then %do;
            put "=&error(&false)";
            ddecmd = "=&workbookdelete("||'"'||"&tmplsheet"||'"'||")";
            put ddecmd; 
            %end;
        put "=&halt(&true)";
        put '!dde_flush';
        file sas2xl;
        ddecmd = "[&run("||'"'||"&macrosheet!"||"&r.1&c.1"||'")]';
        put ddecmd;
      run;

      %* Clear the Macro1-sheet in case we need it for another bit of code.              ;
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

    %end;
*/
%mend setTemplate;
