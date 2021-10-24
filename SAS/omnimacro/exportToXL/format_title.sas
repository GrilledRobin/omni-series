%* Formats the Excel spreadsheet if formatting is desired.                               ;
%*                                                                                       ;
%* FONT: MS Sans Serif, 8.5 pt, bold, centered                                           ;
%* HEADER: None specified                                                                ;
%* COLUMN WIDTH: None specified                                                          ;
%* ROW HEIGHT: None specified                                                            ;
%*                                                                                       ;
%* After formatting, we go to R1C2, then to R1C1 -- so that upon opening the document,   ;
%* we see the whole upper left of the table (if we do not first go to R1C2, we could get ;
%* the first column, then the nth one, then the n+1th one, etc.).                        ;


%macro format_title;

  data _null_;
    length ddecmd $200.;
    file sas2xl;
    put "[&error(&false)]";
    ddecmd = "[&workbookactivate("||'"'||"&sheet"||'"'||",&false)]";
    put ddecmd;
    ddecmd = "[&select("||'"'||"&r&ulrowlab&c&ulcollab:&r&lrrowstat&c&lrcolstat"||'")]';
    put ddecmd;
    ddecmd = "[&formatfont"||'("MS Sans Serif"'||",8.5,&true,&false,&false,&false,0,&false,&false)]";
	put ddecmd;
	put "[&alignment(3)]";
  run;

%mend format_title;
