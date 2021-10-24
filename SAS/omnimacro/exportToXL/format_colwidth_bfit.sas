%* Formats the Excel spreadsheet if formatting is desired.                               ;
%*                                                                                       ;
%* FONT: Not specified                                                                   ;
%* HEADER: Not specified                                                                 ;
%* COLUMN WIDTH: Best fit                                                                ;
%* ROW HEIGHT: Not specified                                                             ;
%*                                                                                       ;
%* After formatting, we go to R1C1 -- so that upon opening the document, we see the      ;
%* whole upper left of the table.                                                        ;


%macro format_colwidth_bfit;

  data _null_;
    length ddecmd $200.;
    file sas2xl;
    put "[&error(&false)]";
    ddecmd = "[&workbookactivate("||'"'||"&sheet"||'"'||",&false)]";
    put ddecmd;
    ddecmd = "[&columnwidth(0,"||'"'||"&c&ulcollab:&c&lrcollab"||'"'||",&false,3)]";
    put ddecmd;
 	ddecmd = "[&select("||'"'||"&r.1&c.1"||'")]';
*    put ddecmd;
  run;

%mend format_colwidth_bfit;
