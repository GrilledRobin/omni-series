%* English language X4ML commands.                                                       ;

%macro lang_en;

  %let c = c;
  %let r = r;
  %let alignment = alignment;
  %let appactivate = app.activate;
  %let appmaximize = app.maximize;
  %let average = average;
  %let border = border;
  %let clear = clear;
  %let columnwidth = column.width;
  %let copy = copy;
  %let editcolor = edit.color;
  %let error = error;
  %let false = false;
  %let fileclose = file.close;
  %let filter = filter;
  %let fontproperties = font.properties;
  %let formatfont = format.font;
  %let formatnumber = format.number;
  %let formulareplace = formula.replace;
  %let freezepanes = freeze.panes;
  %let getdocument = get.document;
  %let getworkbook = get.workbook;
  %let halt = halt;
  %let max = max;
  %let median = median;
  %let min = min;
  %let new = new;
  %let open = open;
  %let pastespecial = paste.special;
  %let patterns = patterns;
  %let percentile = percentile;
  %let quit = quit;
  %let rowheight = row.height;
  %let run = run;
  %let saveas = save.as;
  %let select = select;
  %let selection = selection;
  %let sendkeys = send.keys;
  %let sendkeycmd = %{o}{e}{a}%{m}{enter};
    %* Key command to merge two adjacent cells together, meaning                         ;
	%* "ALT+O -> E -> A -> ALT+M -> ENTER", which is equivalent to                       ;
    %* "Format -> Cells -> Alignment -> Merge Cells -> OK" in the English version.       ;
  %let setname = set.name;
  %let setvalue = set.value;
  %let sum = sum;
  %let sumproduct = sumproduct;
  %let true = true;
  %let windowmaximize = window.maximize;
  %let workbookactivate = workbook.activate;
  %let workbookcopy = workbook.copy;
  %let workbookdelete = workbook.delete;
  %let workbookinsert = workbook.insert;
  %let workbookmove = workbook.move;
  %let workbookname = workbook.name;
  %let workbooknext = workbook.next;

%mend lang_en;
