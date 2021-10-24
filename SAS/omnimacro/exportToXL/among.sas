
%macro among( var, list );
  %* Not called %IN because that will be used in a future SAS release.                   ;

  %local word i found;
  %let found = 0;
  %let i = 1;
  %let word = %scan( &list, 1 );
  %do %while( &word ne and not &found );
  	%if &var eq &word %then %let found = 1;
  	%let i = %eval( &i+1 );
  	%let word = %scan( &list, &i );
  	%end;
  &found

%mend among;

/*

Usage:

%macro blah( city );

  %if %among( &city, Dallas Seattle Boston ) %then %put 1;
	%else %put 0;

%mend blah;

%blah( Seattle );
%blah( Syracuse );

*/
