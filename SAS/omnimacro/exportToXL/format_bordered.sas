%* Formats the Excel spreadsheet if formatting is desired.                               ;
%*                                                                                       ;
%* FONT: MS Sans Serif, 8.5 pt                                                           ;
%* HEADER: Bold                                                                          ;
%* COLUMN WIDTH: Best fit                                                                ;
%* ROW HEIGHT: Not specified                                                             ;
%* BORDERED                                                                              ;
%*                                                                                       ;
%* After formatting, we go to R1C1 -- so that upon opening the document, we see the      ;
%* whole upper left of the table.                                                        ;


%macro format_bordered;

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
	put "[&border(2)]";
    ddecmd = "[&select("||'"'||"&r&ulrowlab&c&ulcollab:&r&lrrowlab&c&lrcollab"||'")]';
    put ddecmd;
    ddecmd = "[&formatfont"||'("MS Sans Serif"'||",8.5,&true,&false,&false,&false,0,&false,&false)]";
 	put ddecmd;
    ddecmd = "[&columnwidth(0,"||'"'||"&c&ulcollab:&c&lrcollab"||'"'||",&false,3)]";
    put ddecmd;
  run;

%mend format_bordered;
