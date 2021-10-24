%macro STXR_setVariables;

  %local langs ii nullid;

  %let ready = 0;
  %let misspar = 0;
  %let missparexptmpl = 0;
    %* Equals 1 if there is an error (&MISSPAR = 1) but we export the template anyway.   ;
  %let cnotes = 0;
  %let csource = 0;
  %let csource2 = 0;
  %let cmlogic = 0;
  %let csymbolg = 0;
  %let cmprint = 0;
  %let tab = '09'x;
  %let ulrowlab = ;
  %let ulcollab = ;
  %let lrrowlab = ;
  %let lrcollab = ;
  %let ulrowdat = ;
  %let ulcoldat = ;
  %let lrrowdat = ;
  %let lrcoldat = ;
  %let lrecl = ;
  %let types = ;
  %let vars = ;
  %let i = 0;
  %let colind = ;
  %let closeExcel = 0;
  %let printHeaders = 0;
  %let maxmrow = 65523;
    %* The max row in the macro sheet -- currently set to the maximum allowed by Excel.  ;
    %* For older, slower versions of Excel, perhaps a smaller number would be better.    ;
    %* For Excel 2007, which is not contrained to any maximum number of rows, a much     ;
    %* larger number can be substituted here -- although if there are more than 65523    ;
    %* rows, the data set really belongs in a database table like Access rather than in  ;
    %* Excel!                                                                            ;
  %let sasnote = NOTE;
  %let saswarning = WARNING;
  %let saserror = ERROR;
    %* Translations of the SAS log keywords NOTE, WARNING and ERROR -- in English, to be ;
	%* translated to another language below if needed.                                   ;

  %*let exChkStrDat = %sysfunc(compbl(%str(
        "LVAR" "LFLD" "LV_" "L_V_" "L_VAR"
        "GVAR" "GFLD" "GV_" "G_V_" "G_VAR"
        "LA_" "LF_" "LN_" "LT_"
      )
    )
  );
  %*let exChkStrDatN = %eval(%sysfunc(count(&exChkStrDat.,%str( )))+1);
  %let exChkStrDat = %sysfunc(compbl(%str(LDAT_ LD_ GDAT_ GD_)));
  %let exChkStrDatN = %eval(%sysfunc(count(&exChkStrDat.,%str( )))+1);

  %let langs = da de en es fi fr it nl no pt ru sv;
    %* The available languages.                                                          ;
  %let ii = 1;
  %let nullid = ;

  %do %until( %scan( &langs., &ii. ) = &nullid. );

	%if %scan( &langs., &ii. ) = &lang. and %sysfunc( fileexist( &exroot.\STXR_lang_&lang..sas ) ) = 1 %then %do;
	  %* Double check to make sure the language file exists.                             ;
	  %STXR_lang_&lang.
	  %goto quit;
	  %end;
	%let ii = %eval( &ii. + 1 );

	%end;

    %put &saserror.: [&L_mcrLABEL.]The language code chosen for the Excel application, &lang., is not supported!;
    %let misspar = 1;

	%quit:

%mend STXR_setVariables;
