/*-----
 * group: Data in
 * purpose: Fetch stock quotes from Yahoo into a data set
 * notes: Past performance is not indicative of future profits :-)
 */

%macro quotes (symbol=, start=, end=, prompt=NO, out=);

    %* Richard A. DeVenezia, 4/9/00
    %* Quotes: A macro to retrieve historical daily stock quotes from Yahoo;
    %*
    %* symbol - ticker symbol
    %* start  - starting date mm/dd/yy, default: 30 days prior to end
    %* end    - ending   date mm/dd/yy, default: today
    %* prompt - if YES then raise a macro window, otherwise proceed
    %* out    - table name, default: same as symbol
    %*
    %* Yahoo url that delivers a CSV of daily stock quotes looks like
    %* http://table.finance.yahoo.com
    %*       /table.csv?s=<SYMBOL>
    %*                 &a=<FROM_MONTH>
    %*                 &b=<FROM_DAY>
    %*                 &c=<FROM_YEAR>
    %*                 &d=<TO_MONTH>
    %*                 &e=<TO_DAY>
    %*                 &f=<TO_YEAR>
    %*                 &g=d
    %*
    %* MONTH 0 is January
    %*
    %* 12/08/03 rad Thanks to Andrew Farrer for v.8 bugfix (%window)
    %*  4/20/07 rad Use IS8601DA to read date value
    %*  1/12/10 rad Thanks to Sunny in Atlanta for bug report {dash in symbol}
    %*              Add out= option, compress symbol for default
    %*;

    %local symbol start end;
    %local s _s _e a b c d e f g url;

    %if (%superq(symbol) eq ) %then 
        %let symbol=msft;

    %let symbol = %upcase (&symbol);

    %if (%superq(end) eq ) %then 
        %let end = %sysfunc(today(),mmddyy8);

    %if (%superq(start) eq ) %then %do;
        %let start = %sysfunc(inputn(&end,mmddyy8.));
        %let start = %eval (&start-30);
        %let start = %sysfunc(putn(&start,mmddyy8.));
    %end;

    %if (%upcase(&prompt) eq YES) %then %do;
        %window Quotes rows=12 columns=30
          #2@2 "Symbol: " symbol 8 c=blue a=rev_video
          #4@2 "Start:  " start  8 c=blue a=rev_video
          #6@2 "End:    " end    8 c=blue a=rev_video
        ;

        %display Quotes;
        %let symbol = %upcase (&symbol);
    %end;

    %if (%superq(out) eq ) %then
      %let out = %sysfunc(compress(&symbol,%str(-./)));

    %let _e = %sysfunc(inputn(&end  ,mmddyy10.));
    %let _s = %sysfunc(inputn(&start,mmddyy10.));

    %let s  = &symbol;
    %let a  = %sysfunc (month(&_s)); %let a=%eval(&a-1);
    %let b  = %sysfunc (day  (&_s));
    %let c  = %sysfunc (year (&_s));
    %let d  = %sysfunc (month(&_e)); %let d=%eval(&d-1);
    %let e  = %sysfunc (day  (&_e));
    %let f  = %sysfunc (year (&_e));
    %let g  = d;

    %let and = %str(&);
/*
    %let url = http://ichart.finance.yahoo.com:80/table.csv;
*/
    %let url = http://table.finance.yahoo.com:80/table.csv;
    %let url = &url.?s=&s;
    %let url = &url.&and.a=&a.&and.b=&b.&and.c=&c;
    %let url = &url.&and.d=&d.&and.e=&e.&and.f=&f;
    %let url = &url.&and.g=&g;

    %put &url;

    filename quotes URL "&url";

    data &out;
      infile quotes dlm=',';

      retain symbol "&symbol";

      if _n_ = 1 then input; * skip header row;

*     input Date date9.    Open High Low Close Volume;
      input Date is8601da. Open High Low Close Volume;

      format Date mmddyy10.;
      format Volume comma11.;
    run;

    %if &SYSERR ne 0 and &SYSERR ne 4 %then %do;
      %put NOTE: --------------------;
      %put NOTE: SYSERR=&SYSERR.;
      %put NOTE: Check that you have used a valid stock symbol [&symbol];
      %put NOTE: and a valid date range [&start] to [&end];
      %put NOTE: --------------------;
    %end;

    %let syslast = &out;

%bye:

%mend;

/**html
 * <p>Sample code</p>
 */

/*
%quotes (symbol=twx,  prompt=YES);
%quotes (symbol=msft, start=4/1/00, end=4/10/00);
%quotes (symbol=msft, start=10/10/03, end=11/11/03);

%macro hlc_plot (symbol=, start=, end=);
  %quotes (symbol=&symbol, start=&start, end=&end);
  %let myData = &syslast.;

  proc transpose data=&myData. out=&myData._hlc(rename=col1=Price);
    by symbol descending date ;
    var high low close;
  run;

  symbol1 i=HiLoC;
  goptions ftext='Arial';

  proc gplot data=&myData._hlc;
    title "&symbol";
    plot price * date;
  run;
  quit;
%mend;

%hlc_plot (symbol=HPT-PB, start=1/1/08);
%hlc_plot (symbol=TCB-PA, start=1/1/08);
%hlc_plot (symbol=MSFT, start=10/10/03, end=11/11/03);
*/
