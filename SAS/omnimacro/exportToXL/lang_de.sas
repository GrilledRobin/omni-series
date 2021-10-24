%* German language X4ML commands.                                                        ;

%macro lang_de;

  %let sasnote = HINWEIS;
  %let saswarning = WARNUNG;
  %let saserror = FEHLER;
    %* Translations of the SAS log keywords NOTE, WARNING and ERROR.                     ;

  %let c = s;
  %let r = z;
  %let alignment = ausrichtung;
  %let appactivate = anw.aktivieren;
  %let appmaximize = anw.vollbild;
  %let average = mittelwert;
  %let border = rahmenart;
  %let clear = inhalte.l�schen;
  %let columnwidth = spaltenbreite;
  %let copy = kopieren;
  %let editcolor = farbe.bearbeiten;
  %let error = fehler;
  %let false = falsch;
  %let fileclose = datei.schliessen;
  %let filter = filter;
  %let fontproperties = schriftart.eigenschaften;
  %let formatfont = format.schriftart;
  %let formatnumber = format.zahlenformat;
  %let formulareplace = formel.suchen.und.ersetzen;
  %let freezepanes = fenster.fixieren;
  %let getdocument = datei.zuordnen;
  %let getworkbook = arbeitsmappe.zuordnen;
  %let halt = stop;
  %let max = max;
  %let median = median;
  %let min = min;
  %let new = neu;
  %let open = �ffnen;
  %let pastespecial = inhalte.einfugen;
  %let patterns = muster;
  %let percentile = quantil;
  %let quit = beenden;
  %let rowheight = zeilenh�he;
  %let run = makro.ausf�hren;
  %let saveas = speichern.unter;
  %let select = ausw�hlen;
  %let selection = auswahl;
  %let sendkeys = tastenf.senden;
  %let sendkeycmd = %{t}{z}{a}%{z}{enter};
    %* Key command to merge two adjacent cells together, meaning                         ;
	%* "ALT+T -> Z -> A -> ALT+Z -> ENTER", which is equivalent to                       ;
    %* "Format -> Cells -> Alignment -> Merge Cells -> OK" in the English version.       ;
  %let setname = namen.zuweisen;
  %let setvalue = wert.festlegen;
  %let sum = summe;
  %let sumproduct = summenprodukt;
  %let true = wahr;
  %let windowmaximize = fenster.vollbild;
  %let workbookactivate = arbeitsmappe.aktivieren;
  %let workbookcopy = arbeitsmappe.kopieren;
  %let workbookdelete = arbeitsmappe.l�schen;
  %let workbookinsert = arbeitsmappe.einf�gen;
  %let workbookmove = arbeitsmappe.verschieben;
  %let workbookname = arbeitsmappe.namen;
  %let workbooknext = arbeitsmappe.n�chstes;

%mend lang_de;
