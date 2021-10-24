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


%macro format_fullborder;

  data _null_;
    length ddecmd $200.;
    file sas2xl;
    put "[&error(&false)]";
    ddecmd = "[&workbookactivate("||'"'||"&sheet"||'"'||",&false)]";
    put ddecmd;
    ddecmd = "[&select("||'"'||"&r&ulrowlab&c&ulcollab:&r&lrrowdat&c&lrcoldat"||'")]';
    put ddecmd;
    ddecmd = "[&formatfont"||'("MS Sans Serif"'||",8.5,&false,&false,&false,&false,0,&false,&false)]";
	put ddecmd;
/*outline(for the entire SELECTION),leftborder,rightborder,topborder,bottomborder,gridbackground*/
	put "[&border(,1,1,1,1)]";
/*1:normal;2:bold;3:dashed;4:dotted;5:extra-bold;6:double;7:dense-dotted*/
/*8:bold-dashed;9:dash-dot;10:dot-dash;11:dot-dot-dash;12:bold-dot-dot-dash;13:italic-bold-dot-dash*/
/*Below are for Labels or Field Names*/
    ddecmd = "[&select("||'"'||"&r&ulrowlab&c&ulcollab:&r&lrrowlab&c&lrcollab"||'")]';
    put ddecmd;
	put "[&border(1)]";
    ddecmd = "[&formatfont"||'("MS Sans Serif"'||",8.5,&false,&false,&false,&false,0,&false,&false)]";
 	put ddecmd;
    ddecmd = "[&columnwidth(0,"||'"'||"&c&ulcollab:&c&lrcollab"||'"'||",&false,3)]";
    put ddecmd;
  run;

%mend format_fullborder;
