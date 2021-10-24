%* Closes the file and the DDE connection.                                               ;


%macro closeDDE;

  %if &misspar = 1 %then %goto jump;;

  %* Here we finalize the worksheet, delete our macro worksheet, save our Excel file,    ;
  %* and (if we have decided to do so) close Excel. By 'finalizing our worksheet', I     ;
  %* mean making it so that we see the upper left quadrant of the worksheet when we open ;
  %* it -- unless we have frozen panes and the sum or statistics of one or more          ;
  %* variables at the bottom, in which case the sum/statistics are shown in the  middle  ;
  %* of the screen. The code below accomplishes this, as explained below:                ;
  %*                                                                                     ;
  %* If we do not have frozen panes, all we need to do is select cell R1C1 before saving ;
  %* the file. If however we do have frozen panes (assumed to be partitioned at row      ;
  %* &CELL1ROW+&MERGEDOWN-1 and column &CELL1COL+&MERGEACROSS-1 -- if not there, this    ;
  %* will not work), we need to first select the cell at the top of the lower left       ;
  %* quadrant, then the cell at the left of the upper right quadrant, then the cell at   ;
  %* R1C1. But if we also have variable sums/statistics at the bottom of the worksheet,  ;
  %* we select the cell at the bottom of the sum/statistics section, then (as before)    ;
  %* the cell at the left of the upper right quadrant, then then cell at R1C1.           ;
  data _null_;
    length ddecmd $ 200;
    file sas2xl;
    put "[&error(&false)]";
    ddecmd = "[&workbookactivate("||'"'||"&sheet"||'"'||",&false)]";
    put ddecmd;
/*
 	ddecmd = "[&select("||'"'||"&r"||trim( left( %eval( &cell1row + &mergedown ) ) )||"&c.1"||'")]';
    %if %length( %scan( &sumvars, 1 ) ) > 0 or %length( %scan( &statvars, 1 ) ) > 0 %then
 	  ddecmd = "[&select("||'"'||"&r.&lrrowstat.&c.1"||'")]';;
	put ddecmd;
 	ddecmd = "[&select("||'"'||"&r.1&c"||trim( left( %eval( &cell1col + &mergeacross ) ) )||'")]';
    put ddecmd;
*/
 	ddecmd = "[&select("||'"'||"&r.1&c.1"||'")]';
    put ddecmd;
    ddecmd = "[&workbookdelete"||'("'||"&macrosheet"||'")]';
	put ddecmd;
    ddecmd = "[&saveas"||'("'||"&savepath"||'\'||"&savename"||'.xls")]';
    put ddecmd;
	put "[&fileclose(&false)]";
	%if &closeExcel = 1 %then put "[&quit()]";;
  run;

  %* Upon exiting the macro, we restore all the system options we turned off earlier.    ;
  %jump:

  %if &cnotes   %then options notes;
  %if &csource  %then options source;
  %if &csource2 %then options source2;
  %if &cmlogic  %then options mlogic;
  %if &csymbolg %then options symbolgen;
  %if &cmprint  %then options mprint;


  %* Check if the macro actually executed some code (&MISSPAR=0) or if we got here       ;
  %* because of lacking parameter errors (&MISSPAR=1).                                   ;
  %if &misspar = 0 %then %do;

    options nonotes;

    %* Clean up remaining junk in the local SAS session.                                 ;
    proc datasets nolist lib = work;
      delete %if &missparexptmpl %then ____meta; _sheet_names _sheet_names_before / memtype = data;
    quit;

    filename sas2xl clear;
    filename xlmacro clear;

    %if &cnotes %then options notes;

    %end;

%mend closeDDE;
