%* Here we extract a list of existing sheet names from the target workbook and store it  ;
%* in the data set _SHEET_NAMES. We also store the number of worksheets into &NSHEETS.   ;
%* Most of this code is derived from Koen Vyverman (2003): 'Excel Exposed: Using Dynamic ;
%* Data Exchange to Extract Metadata from MS Excel Workbooks'.                           ;

%macro loadNames;

  %local n_sheets;
    %* Stored the number of sheets in an intermediate data set of the sheets, including  ;
	%* charts and macro sheets, which we do not want to include. An updated number of    ;
	%* sheets, &NSHEETS, will not count these extra sheets.                              ;

  data _sheet_namesbefore;
    %* This will include the macro sheet itself, which will be removed later.            ;
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
	if sh_name = "&macrosheet" then delete;
	drop str strlen topic;
  run;

  %* Activate the macro sheet.                                                           ;
  data _null_;
	format ddecmd $200.;
    file sas2xl;
    ddecmd = "[&workbookactivate("||'"'||"&macrosheet"||'",'||"&false)]";
    put ddecmd;
  run;

  data _null_;
    %* Gets information about each sheet in the Excel file.                              ;
	set _sheet_namesbefore end=last;
	length ddecmd $ 200;
	file xlmacro;
	ddecmd="=&select(!$b$"||trim(left(put(_n_,8.)))||')';
	put ddecmd;
	ddecmd="=&setname("||'"rows",'||"&selection())";
	put ddecmd;
	ddecmd="=&select(!$c$"||trim(left(put(_n_,8.)))||')';
	put ddecmd;
	ddecmd="=&setname("||'"cols",'||"&selection())";
	put ddecmd;
	ddecmd="=&select(!$d$"||trim(left(put(_n_,8.)))||')';
	put ddecmd;
	ddecmd="=&setname("||'"type",'||"&selection())";
	put ddecmd;
	ddecmd="=&select(!$e$"||trim(left(put(_n_,8.)))||')';
	put ddecmd;
	ddecmd="=&setname("||'"pos",'||"&selection())";
	put ddecmd;
	ddecmd="=&select(!$f$"||trim(left(put(_n_,8.)))||')';
	put ddecmd;
	ddecmd="=&setname("||'"furow",'||"&selection())";
	put ddecmd;
	ddecmd="=&select(!$g$"||trim(left(put(_n_,8.)))||')';
	put ddecmd;
	ddecmd="=&setname("||'"fucol",'||"&selection())";
	put ddecmd;
	ddecmd="=&setvalue(rows,&getdocument(10,"||'"'||trim(left(sh_name))||'"))';
	put ddecmd;
	ddecmd="=&setvalue(cols,&getdocument(12,"||'"'||trim(left(sh_name))||'"))';
	put ddecmd;
	ddecmd="=&setvalue(type,&getdocument(3,"||'"'||trim(left(sh_name))||'"))';
	put ddecmd;
	ddecmd="=&setvalue(pos,&getdocument(87,"||'"'||trim(left(sh_name))||'"))';
	put ddecmd;
	ddecmd="=&setvalue(furow,&getdocument(9,"||'"'||trim(left(sh_name))||'"))';
	put ddecmd;
	ddecmd="=&setvalue(fucol,&getdocument(11,"||'"'||trim(left(sh_name))||'"))';
	put ddecmd;
	put "=&halt(&true)";
	put '!dde_flush';
	if last then do;
	  call symput('n_sheets',trim(left(put(_n_,2.))));
	  end;
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
    ddecmd = "[&select("||'"'||"&r.1&c.1:&r&maxmrow&c.1"||'")]';
    put ddecmd;
    put "[&clear(1)]";
    ddecmd = "[&select("||'"'||"&r.1&c.1"||'")]';
    put ddecmd;
  run;

  data _null_;
	set _sheet_namesbefore;
	file xlmacro;
	put sh_name;
  run;

  filename shparams dde "excel|&macrosheet!&r.1&c.1:&r.&n_sheets.&c.7" lrecl=200;

  data _sheet_names;
	length sh_name $ 31 n_rows_char n_cols_char fu_row_char fu_col_char $ 5
	  sh_type $ 1 sh_order_char $ 5;
	label sh_name = 'Sheet Name'
		  sh_type = 'Sheet Type';
	infile shparams notab dlm='09'x dsd missover;
	input sh_name n_rows_char n_cols_char sh_type sh_order_char
		fu_row_char fu_col_char;
	if sh_type = "1";
	  %* deletes all sheets (like charts and macro sheets) that are not worksheets.      ;
  run;

  %* Clear the Macro1-sheet in case we need it for another bit of code.              ;
  data _null_;
	format ddecmd $200.;
    file sas2xl;
    ddecmd = "[&workbookactivate("||'"'||"&macrosheet"||'",'||"&false)]";
    put ddecmd;
    ddecmd = "[&select("||'"'||"&r.1&c.1:&r&maxmrow&c.1"||'")]';
    put ddecmd;
    put "[&clear(1)]";
    ddecmd = "[&select("||'"'||"&r.1&c.1"||'")]';
    put ddecmd;
  run;

  data _null_;
	set _sheet_names end=last;
	if last then call symput( 'nsheets', trim( left( put( _n_, 2. ) ) ) );
  run;

%mend loadNames;
