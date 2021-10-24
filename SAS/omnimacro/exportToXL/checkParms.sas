%* Checks the parameters.                                                                ;


%macro checkParms;


  %* First we determine the values of certain SAS System options.                        ;
  %if %sysfunc( getoption( notes ) ) = NOTES         %then %let cnotes = 1;
  %if %sysfunc( getoption( source ) ) = SOURCE       %then %let csource = 1;
  %if %sysfunc( getoption( source2 ) ) = SOURCE2     %then %let csource2 = 1;
  %if %sysfunc( getoption( mlogic ) ) = MLOGIC       %then %let cmlogic = 1;
  %if %sysfunc( getoption( symbolgen ) ) = SYMBOLGEN %then %let csymbolg = 1;
  %if %sysfunc( getoption( mprint ) ) = MPRINT       %then %let cmprint = 1;
/*
  %* We then do some basic parameter checking.                                           ;
  %if ( "&libin" = "" ) %then %do;
    %put &saserror: The LIBIN parameter is missing in a call to the EXPORTTOEXCEL macro!;
    %let misspar = 1;
    %end;

  %if ( "&dsin" = "" ) %then %do;
    %put &saserror: The DSIN parameter is missing in a call to the EXPORTTOEXCEL macro!;
    %let misspar = 1;
    %end;

  %* For the above errors, we exit first out of this macro, then out of EXPORTTOEXCEL    ;
  %* entirely. We assume that, if either &DSIN or &LIBIN are not given, the template     ;
  %* sheet is not to be exported, regardless of the value of &EXPORTTMPLIFEMPTY. That    ;
  %* is, if we do not even have the names of the library or data set, we should not go   ;
  %* any further.                                                                        ;
  %if &misspar %then %do;
    %put;
    %put &saserror: The EXPORTTOEXCEL macro bombed due to errors...;
    %put;
    %goto theend;
    %end;

  %* If the data set does not exist, we can either export the template (if there is one) ;
  %* or export nothing at all, depending on the value of &EXPORTTMPLIFEMPTY. This way    ;
  %* allows for user variation -- e.g., the user can type in 'no', 'false', or '0'.      ;  
  %if %sysfunc( exist( &libin..&dsin ) ) = 0 %then %do;
    %put &sasnote: The input SAS data set &libin..&dsin does not exist!  Nothing will be exported.;
    %if %upcase( %substr( &exporttmplifempty, 1, 1 ) ) = N or %upcase( %substr( &exporttmplifempty, 1, 1 ) ) = F
      or %substr( &exporttmplifempty, 1, 1 ) = 0 %then %let misspar = 1;
        %else %let missparexptmpl = 1;
    %goto theend;
    %end;

  %* If we are still there, we fill in the values of some of the optional parameters     ;
  %* that were either left blank, or were inadvertently reset to blank in the macro      ;
  %* call.                                                                               ;
  %if ( "&cell1row" = "" ) %then %do;
    %let cell1row = 1;
    %put;
    %put &sasnote: The default value of the CELL1ROW parameter appears to have been;
    %put ----- overwritten by a null value during invocation of the EXPORTTOEXCEL;
    %put ----- macro. It has been reset to '1' in order to allow macro execution.;
    %put;
    %end;

  %if ( "&cell1col" = "" ) %then %do;
    %let cell1col = 1;
    %put;
    %put &sasnote: The default value of the CELL1COL parameter appears to have been;
    %put ----- overwritten by a null value during invocation of the EXPORTTOEXCEL;
    %put ----- macro. It has been reset to '1' in order to allow macro execution.;
    %put;
    %end;
*/
  %* Gets rid of the last backslash in each path, if one is included.                    ;
  %if ( "%substr( &savepath, %length( &savepath ), 1 )" = "\" ) or
    ( "%substr( &savepath, %length( &savepath ), 1 )" = "/" ) %then
    %let savepath = %substr( &savepath, 1, %eval( %length( &savepath ) - 1 ) );
  %if ( "&tmplpath" != "" ) %then %do;
    %if ( ( "%substr( &tmplpath, %length( &tmplpath ), 1 )" = "\" ) or
    ( "%substr( &tmplpath, %length( &tmplpath ), 1 )" = "/" ) ) %then
    %let tmplpath = %substr( &tmplpath, 1, %eval( %length( &tmplpath ) - 1 ) );
    %end;

  %if ( "&savepath" = "" ) %then %do;
    %let savepath = c:\temp;
    %put;
    %put &sasnote: The default value of the SAVEPATH parameter appears to have been;
    %put ----- overwritten by a null value during invocation of the EXPORTTOEXCEL;
    %put ----- macro. It has been reset to 'c:\temp' in order to allow macro execution.;
    %put;
    %end;

  %if ( "&savename" = "" ) %then %do;
    %let savename = exportToExcel Output;
    %put;
    %put &sasnote: The default value of the SAVENAME parameter appears to have been;
    %put ----- overwritten by a null value during invocation of the EXPORTTOEXCEL;
    %put ----- macro. It has been reset to 'exportToExcel Output' in order to allow;
    %put ----- macro execution.;
    %put;
    %end;

  %* We then turn all those options off, this to minimize the amount of junk that the    ;
  %* usage of this macro would otherwise insert between the lines of the log of the code ;
  %* in which it gets used.                                                              ;
  options nonotes nosource nosource2 nomlogic nosymbolgen nomprint noxwait noxsync;

  %* Now that the notes are turned off, we define a couple macro variables. Doing it     ;
  %* this way allows user variation -- e.g., the user can type in 'yes', 'TRUE', or '1'. ;
  %if %among( %upcase( %substr( &endclose, 1, 1 ) ), Y T 1 ) %then %let closeExcel = 1;
/*
  %if %among( %upcase( %substr( &exportheaders, 1, 1 ) ), Y T 1 ) %then %let printHeaders = 1;
*/
/*
  %* We then continue the parameter checking -- here we first check if it is an empty    ;
  %* data set (no rows/columns), then correct inappropriate values of &NROWS or &NCOLS.  ;
  proc sql noprint;
    select trim( left( put( nobs, 20. ) ) ) into :nrows1
    from sashelp.vtable
    where ( libname = upcase( "&libin" ) ) and ( memname = upcase( "&dsin" ) );
  quit;

  proc sql noprint;
    select trim( left( put( nvar, 20. ) ) ) into :ncols1
    from sashelp.vtable
    where ( libname = upcase( "&libin" ) ) and ( memname = upcase( "&dsin" ) );
  quit;

  %if &ncols1 = 0 %then %do;
    option notes;
    %put &sasnote: The input SAS data set &libin..&dsin has no columns!  Nothing will be exported.;
    option nonotes;
    %if %upcase( %substr( &exporttmplifempty, 1, 1 ) ) = N or %upcase( %substr( &exporttmplifempty, 1, 1 ) ) = F
      or %substr( &exporttmplifempty, 1, 1 ) = 0 %then %let misspar = 1;
        %else %let missparexptmpl = 1;
    %goto theend;
    %end;

  %if &nrows1 = 0 %then %do;
    option notes;
    %put &sasnote: The input SAS data set &libin..&dsin has no observations!  Nothing will be exported.;
    option nonotes;
    %if %upcase( %substr( &exporttmplifempty, 1, 1 ) ) = N or %upcase( %substr( &exporttmplifempty, 1, 1 ) ) = F
      or %substr( &exporttmplifempty, 1, 1 ) = 0 %then %let misspar = 1;
        %else %let missparexptmpl = 1;
    %goto theend;
    %end;

  %if ( ( "&nrows" = "" ) or ( &nrows > &nrows1 ) ) %then %let nrows = &nrows1;
  %if ( ( "&ncols" = "" ) or ( &ncols > &ncols1 ) ) %then %let ncols = &ncols1;

  %* To make sure that a put-statement to one of our DDE-filenames remains on one single ;
  %* row of the spreadsheet, we calculate a LRECL for the filename that will (hopefully) ;
  %* be large enough to accommodate all the formatted values that we will want to push   ;
  %* through. In the old SAS 6.12 spirit, we assume that 200 bytes per variable will do  ;
  %* the trick. When exporting v8 data sets with extremely long character variables,     ;
  %* this may lead to trouble and should be coded a bit more robustly at some point.     ;
  %let lrecl = %eval( 200*&ncols );
*/
  %* The parameters &TMPLPATH and &TMPLNAME should be used in conjunction with each      ;
  %* other. Check if this is the case. When necessary, reset both to a null value.       ;
  %if ( ( "&tmplpath" = "" ) and ( "&tmplname" ne "" ) ) or ( ( "&tmplpath" ne "" ) 
    and ( "&tmplname" = "" ) ) %then %do;
    %let tmplpath = ;
    %let tmplname = ;
    option notes;
    %put;
    %put &sasnote: During invocation of the EXPORTTOEXCEL macro, either the parameter TMPLPATH;
    %put ----- was specified without TMPLNAME, or vice versa. The macro expects either;
    %put ----- both or none of them. They have been reset to a null value to allow macro execution.;
    %put;
    option nonotes;
    %end;

  %if ~( ( "&tmplpath" = "" ) and ( "&tmplname" = "" ) ) and 
    %sysfunc( fileexist( &tmplpath\&tmplname..xls ) ) = 0 %then %do;
    option notes;
    %put;
    %put &sasnote: The template file &tmplpath\&tmplname..xls does not exist!  A standard template will be used.;
    %put;
    %let tmplpath = ;
    %let tmplname = ;
    option nonotes;
    %end;

    %theend:

%mend checkParms;
