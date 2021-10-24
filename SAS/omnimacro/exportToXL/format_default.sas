%* Formats the Excel spreadsheet if formatting is desired.                               ;
%*                                                                                       ;
%* FONT: MS Sans Serif, 8.5 pt                                                           ;
%* HEADER: Bold                                                                          ;
%* COLUMN WIDTH: Best fit                                                                ;
%* ROW HEIGHT: 12.00 (The default for Excel)                                             ;
%* FREEZE PANES                                                                          ;
%*                                                                                       ;
%* After formatting, we go to R1C2, then to R1C1 -- so that upon opening the document,   ;
%* we see the whole upper left of the table (if we do not first go to R1C2, we could get ;
%* the first column, then the nth one, then the n+1th one, etc.). This is needed because ;
%* of the frozen panes. Strictly speaking, we could leave the row height statement out,  ;
%* since it is equal to the default height for Excel -- but this makes it easy to modify ;
%* to accomodate a different row height.                                                 ;


%macro format_default;

  data _null_;
    length ddecmd $200.;
    file sas2xl;
    put "[&error(&false)]";
    ddecmd = "[&workbookactivate("||'"'||"&sheet"||'"'||",&false)]";
    put ddecmd;
    ddecmd = "[&select("||'"'||"&r&ulrowlab&c&ulcollab:&r&lrrowstat&c&lrcolstat"||'")]';
    put ddecmd;
    ddecmd = "[&formatfont"||'("MS Sans Serif"'||",8.5,&false,&false,&false,&false,0,&false,&false)]";
	put ddecmd;
    ddecmd = "[&select("||'"'||"&r&ulrowlab&c&ulcollab:&r&lrrowlab&c&lrcollab"||'")]';
    put ddecmd;
    ddecmd = "[&formatfont"||'("MS Sans Serif"'||",8.5,&true,&false,&false,&false,0,&false,&false)]";
 	put ddecmd;
    ddecmd = "[&columnwidth(0,"||'"'||"&c&ulcollab:&c&lrcollab"||'"'||",&false,3)]";
    put ddecmd;
    ddecmd = "[&rowheight(12.75,"||'"'||"&r&ulrowdat:&r&lrrowstat"||'"'||",&false)]";
    put ddecmd;
	  %* Must be in points corresponding to a whole number of pixels -- e.g., 12.00 or   ;
	  %* 12.75, but not 12.50.                                                           ;
    ddecmd = "[&freezepanes(&true,"||%eval(&cell1col+&mergeacross-1)||","||%eval(&cell1row+&mergedown-1)||")]";
	put ddecmd;
  run;

%mend format_default;
