/* doc2sas
 * Richard A. DeVenezia
 * March 24, 2004
 *
 * Create a SAS table from a table in a document that Word can open
 */

/*-----
 * group: Data in
 * purpose: Create a SAS table from a table in a document.
 * notes: <U>Windows</U> only.
 */

/*
 * Write a vbs script that writes a stream that Proc IMPORT eventually reads
 */

%let doctableout = %sysfunc(pathname(WORK))\doctableout.vbs;

data _null_;
  file "&doctableout";
  input;
  L = length(_infile_);
  put _infile_ $varying. L;
cards4;
on error resume next

if WScript.Arguments.Count <> 2 then WScript.quit

file = WScript.Arguments(0)
tabno = WScript.Arguments(1)

set oWord = CreateObject ("Word.Application")
set oDocument = oWord.Documents.Open( file, vbFalse, vbTrue )
set oTable = oDocument.Tables ( tabno )

for i = 1 to oTable.Rows.Count
  line = ""
  delim = ""
  for j = 1 to oTable.Rows(i).Cells.Count
    celltext = oTable.Rows(i).Cells(j).Range.Text
    cleantext = ""
    for k = 1 to len (celltext)
      c = mid(celltext,k,1)
      if asc (c) >= 32 then cleantext = cleantext & c
    next
    line = line & delim & cleantext
    delim = vbTab
  next
  WScript.echo line
next

oWord.Quit()
;;;;
run;

/*
 * Invoke vbs script, copy its output to a file so that it can be IMPORTed
 * Note: Proc IMPORT requires a random accessible file, that is why the
 * stream is copied to a file)
 */

%macro doc2sas (
  file=
, table=1
, out=
);

  %local pipe pipestor;
  %let pipe = _%substr(%sysfunc(ranuni(0),9.7),4);
  %let pipestor = &pipe.2;

  %* Copy output of vbs to a file so that Proc IMPORT can read it;
  %* The file created by a temp fileref is automatically deleted when
  %* the fileref is cleared.;

  filename &pipe pipe %sysfunc(quote(cscript "&doctableout." //Nologo "&file." &table)) ;
  filename &pipestor temp ;

  data _null_;
    infile &pipe     lrecl=2000;
      file &pipestor lrecl=2000;
    input;
    put _infile_;
  run;

  proc IMPORT file=&pipestor DBMS=dlm out=&out replace ;
    delimiter = '09'x;
  run;

  filename &pipe;
  filename &pipestor;


%mend;

/**html
 * <P>Sample code</P>
 */

/*
 * Create a doc file with four tables
 */

%let docfile = %sysfunc(pathname(WORK))\tables.doc;

ods noresults;
ods listing close;
ods rtf file="&docfile";

data class;
  set sashelp.class;
run;

proc print data=class noobs ; run;
proc print data=class; run;

data class;
  set class;
  attrib dateOfBirth format=mmddyy10. label='Date of Birth';
  dateOfBirth = today() - age*365 - 365*ranuni(0);
run;

proc print data=class noobs ; run;
proc print data=class; run;

ods rtf close;
ods results;


options mprint;

/*
 * Read the 3rd table
 */

%doc2sas (
  file=&docfile
, table=3
, out=foo
)

dm 'vt foo' viewtable;
