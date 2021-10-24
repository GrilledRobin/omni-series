%* Makes the Excel version of each format, using macro variables &FMTS, &FMTLS, etc.,    ;
%* that were made in %INPUTDATA, producing another macro variable, &XLFMTS, which is a   ;
%* list of Excel versions of these formats, separated by '!' since some of these formats ;
%* contain a space. For example, the SAS format '5.2' has the Excel equivalent '000.00'. ;
%* If the format in SAS is either not given or is not included here, the result is       ;
%* 'NONE'.                                                                               ;
%*                                                                                       ;
%* This is done completely with macro functions -- if it were done with a DATA _NULL_    ;
%* statement instead, we would have to use CALL SYMPUT with &FMTLS, &FMTS or &TYPES in   ;
%* quotes, which would cause a warning message if &FMTLS, &FMTS or &TYPES contains more  ;
%* than 262 characters.                                                                  ;


%macro makeExcelFormats( ind );

  %local result start;
  %let start = 0;

  %if &ind = 1 %then %let start = 1;

  %if ( %scan( &types, &ind, " " ) = 2 ) %then %let result = @;
	%else %if %among( %scan( &fmts, &ind, " " ), MMDDYY MMDDYYS ) %then %do;
	  %if %scan( &fmtls, &ind, " " ) = 10 %then %let result = mm/dd/yyyy;
	  	%else %if %among( %scan( &fmtls, &ind, " " ), 8 9 ) %then %let result = mm/dd/yy;
	  	%else %if %among( %scan( &fmtls, &ind, " " ), 6 7 ) %then %let result = mmddyy;
	  	%else %if %scan( &fmtls, &ind, " " ) = 5 %then %let result = mm/dd;
	  	%else %if %scan( &fmtls, &ind, " " ) = 4 %then %let result = mmdd;
	  	%else %if %scan( &lengs, &ind, " " ) = 10 %then %let result = mm/dd/yyyy;
	  	%else %if %among( %scan( &lengs, &ind, " " ), 8 9 ) %then %let result = mm/dd/yy;
	  	%else %if %among( %scan( &lengs, &ind, " " ), 6 7 ) %then %let result = mmddyy;
	  	%else %if %scan( &lengs, &ind, " " ) = 5 %then %let result = mm/dd;
	  	%else %if %scan( &lengs, &ind, " " ) = 4 %then %let result = mmdd;
	  	%else %do;
	      %put &saswarning: No format listed for variable %scan( &vars, &ind, " " ), so no format will be exported.;
		  %let result = NONE;
		  %end;
	  %end;
	%else %if ( %scan( &fmtls, &ind, " " ) = 0 ) and ( %scan( &fmtds, &ind, " " ) = 0 ) %then %do;
	  %put &saswarning: No format listed for variable %scan( &vars, &ind, " " ), so no format will be exported.;
      %let result = NONE;
	  %end;
	%else %if %scan( &fmts, &ind, " " ) = $ %then %let result = @;
	%else %if %scan( &fmts, &ind, " " ) = F %then %do;
      %if %scan( &fmtds, &ind, " " ) = 0 %then %let result = 0;
      %else %let result = 0.%sysfunc( repeat( 0, %scan( &fmtds, &ind, " " )-1 ) );
	  %end;
	%else %if %scan( &fmts, &ind, " " ) = Z %then %do;
	  %if %scan( &fmtds, &ind, " " ) = 0 %then 
	      %let result = %sysfunc( repeat( 0, %scan( &fmtls, &ind, " " )-1 ) );
		%else %if %scan( &fmtls, &ind, " " ) = %eval( %scan( &fmtds, &ind, " " ) +1 ) %then 
		  %let result = .%sysfunc( repeat( 0, %scan( &fmtds, &ind, " " )-1 ) );
		%else %let result = %sysfunc( repeat( 0, %scan( &fmtls, &ind, " " ) - 
		  %scan( &fmtds, &ind, " " )-2 ) ).%sysfunc( repeat( 0, %scan( &fmtds, &ind, " " )-1 ) );
	  %end;
	%else %if %scan( &fmts, &ind, " " ) = DOLLAR %then %do;
	  %if %scan( &fmtds, &ind, " " ) = 0 %then 
	      %let result = _($* #,##0_)%str(;)_($* (#,##0)%str(;)_($* -_)%str(;)_(@_);
		%else %let result =  _($* #,##0.%sysfunc( repeat( 0, %scan( &fmtds, &ind, " " )-1 ) 
		  )_)%str(;)_($* (#,##0.%sysfunc( repeat( 0, %scan( &fmtds, &ind, " " )-1 ) ))%str(;)_($* -??_)%str(;)_(@_);
		  %* Actually, above should have "-"?? rather than -?? to be strictly equal  to  ;
		  %* the 'Accounting' format, but that would make a DDE error. This gives us the ;
		  %* same result. See the user guide for details.                                ;
	  %end;
	%else %if %scan( &fmts, &ind, " " ) = COMMA %then %do;
	  %if %scan( &fmtds, &ind, " " ) = 0 %then %let result = #,##0;
		%else %let result = #,##0.%sysfunc( repeat( 0, scan( &fmtds, &ind, " " )-1 ) );
	  %end;
	%else %if %scan( &fmts, &ind, " " ) = PERCENT %then %do;
	  %if %scan( &fmtds, &ind, " " ) = 0 %then %let result = 0%;
	    %else %let result = 0.%sysfunc( repeat( 0, %scan( &fmtds, &ind, " " )-1 ) )%;
	  %end;
	%else %if %scan( &fmts, &ind, " " ) = YYMMDD %then %do;
	  %if %scan( &fmtls, &ind, " " ) = 10 %then %let result = yyyy-mm-dd;
		%else %if %among( %scan( &fmtls, &ind, " " ), 8 9 ) %then %let result = yy-mm-dd;
		%else %if %among( %scan( &fmtls, &ind, " " ), 6 7 ) %then %let result = yymmdd;
		%else %if %scan( &fmtls, &ind, " " ) = 5 %then %let result = yy-mm;
		%else %if %scan( &fmtls, &ind, " " ) = 4 %then %let result = yymm;
		%else %do;
	      %put &saswarning: No format listed for variable %scan( &vars, &ind, " " ), so no format will be exported.;
		  %let result = NONE;
		  %end;
	  %end;
	%else %if %scan( &fmts, &ind, " " ) = YYMMDDS %then %do;
      %if %scan( &fmtls, &ind, " " ) = 10 %then %let result = yyyy/mm/dd;
		%else %if %among( %scan( &fmtls, &ind, " " ), 8 9 ) %then %let result = yy/mm/dd;
		%else %if %among( %scan( &fmtls, &ind, " " ), 6 7 ) %then %let result = yymmdd;
		%else %if %scan( &fmtls, &ind, " " ) = 5 %then %let result = yy/mm;
		%else %if %scan( &fmtls, &ind, " " ) = 4 %then %let result = yymm;
		%else %do;
	   	  %put &saswarning: No format listed for variable %scan( &vars, &ind, " " ), so no format will be exported.;
		  %let result = NONE;
		  %end;
	  %end;
	%else %do;
	  %put &saswarning: No format listed for variable %scan( &vars, &ind, " " ), so no format will be exported.;
	  %let result = NONE;
      %end;

  %if &start = 1 %then %let xlfmts = %superq(result);
	%else %let xlfmts = &xlfmts!%superq(result);

%mend makeExcelFormats;
