%* Converts RGBHex that SAS understands to RGBDec for Microsoft Excel.                   ;
%* From Perry Watts (2004): 'Highlighting Inconsistent Record Entries in Excel: Possible ;
%* with SAS ODS, Optimized in Microsoft DDE'.							                 ;


%macro RGBDec( CXrrggbb );

  %local rr gg bb;
  %let rr = %substr( &CXrrggbb, 3, 2 );
  %let gg = %substr( &CXrrggbb, 5, 2 );
  %let bb = %substr( &CXrrggbb, 7 );
  %let DecCode = %sysfunc( compress( %sysfunc( putn( %sysfunc( inputn( &rr, hex2. ) ), z3. ) )
    %sysfunc( putn( %sysfunc( inputn( &gg, hex2. ) ), z3. ) )
    %sysfunc( putn( %sysfunc( inputn( &bb, hex2. ) ), z3. ) ) ) );
  %substr( &DecCode, 1, 3 ), %substr( &DecCode, 4, 3 ), %substr( &DecCode, 7, 3)

%mend RGBDec;
