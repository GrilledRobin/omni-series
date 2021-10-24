/*-----
 * group: Data in
 * purpose: Macro to convert dbase file to SAS dataset: Ver 3.0b.<br><b><i>Author Richard Hockey DPH Sep 1998,<br>rhockey@mater.org.au</i></b><br><br>See also <a href="index.php?m=sas2dbf">sas2dbf</a>
 */

%macro dbf2sas(in=,out=,del=N,keep=,drop=,where=, dfmt=,);
%put %str(   ) ;
%put %str(   ) Macro to convert dbase file to SAS dataset Ver 3.0b ;
%put %str(   ) Author Richard Hockey DPH Sep 1998 ;
%put %str(   ) Email: rhockey@mater.org.au;
%put %str(   ) ;
%if %quote(&in)= %then %do;
  %put %str(  ) Usage: ;
  %put %str(      ) %nrstr(%DBF2SAS(IN= ,OUT= ,DEL= ,KEEP= ,DROP= ,WHERE= , DFMT=);) ;
  %put %str(  ) Parameters are: ;
  %put %str(      ) IN dbase file name (eg something.dbf) without quotes.;
  %put %str(      ) OUT output SAS dataset. ;
  %put %str(      ) Optional parameters: ;
  %put %str(      ) DEL Keep deleted records Y/N (Default=N). ;
  %put %str(      ) either KEEP Variables to keep. ;
  %put %str(      ) or DROP Variables to drop. ;
  %put %str(      ) WHERE subsetting where clause. ;
  %put %str(      ) DFMT date format in dataset (Default=DDMMYY6.).
  %put %str(      ) (as a concession to those US users). ;
  %goto endmacro;
%end;
/* determine byte order */
data _null_;
     if put(input('1234'x,ib2.),hex4.)='1234' then endian='BIG   ';
else if put(input('1234'x,ib2.),hex4.)='3412' then endian='LITTLE';
else put "Can't determine byte order of this computer!!";
call symput('endian',endian);
run;
%if &endian= %then %goto endmacro;
data _temp ;
 infile "&in" recfm=n lrecl=256;
length fmt $ 10;
input vn pib1. year ib1. month ib1. day ib1.  nr $4. hs $2. lr $2. +20 @;
%if &endian=BIG %then %do;
  nr=reverse(nr);
  hs=reverse(hs);
  lr=reverse(lr);
%end;
nrec=input(nr,ib4.);
heads=input(hs,ib2.);
lenrec=input(lr,ib2.);
nfields=int(heads/32)-1;
call symput('_nr',left(put(nrec,12.)));
call symput('_hs',left(put(heads,12.)));
put;
put "Date of dbf file= " day z2. "/" month z2. "/" year;
put "Version= " vn;
put "Number of Fields= " nfields ;
put "Number of Records= " nrec;
put "Length of Header= " heads ;
put "Length of Records= " lenrec ;
put;
do i=1 to nfields;
 input name $11. type $1. +4 flen pib1. fdec ib1. +14 @;
 if first^=1 then do;
   file "control.sas";
   first=1;
   put "DATA &out;";
   put "  FORMAT " ;
 end;

name=substr(name,1,verify(name,'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_')-1);
 if length(name)>8 then do;
  file log;
  vcount+1;
  name1="VDB"||put(vcount,z2.);
  put "Variable " name " too long, changed to " name1;
  name=name1;
 end;
 if type in('C','L') then do;
  if flen > 200 or fdec > 0 then do;
    file log;
    put "Variable " name " Field length too long, truncated to 1st 200 characters" /;
;
    fmt="$200.";
    end;
  else
    fmt="$"||trim(left(put(flen,8.)))||".";
 end;
 else if type in('N','F')  then
  fmt=trim(left(put(flen,8.)))||"."||trim(left(put(fdec,8.)));
 else if type='D' then
%if &dfmt^= %then %do;
  fmt="&dfmt" ;
%end;
%else %do;
  fmt="DDMMYY6.";
%end;
 file "control.sas";
 if type^='M' then
   put name  fmt ;
 output;
end;
put ";";
stop;
run;
data _null_;
 set _temp end=eof;
length range $ 25 ;
file "control.sas" mod;
if _n_ =1 then do;
  put "INFILE '&in' recfm=n lrecl=256 ;";
  put "START= &_hs ;";
  put "INPUT +START @;" ;
  put "DO J=1 TO &_NR ;" ;
  put "INPUT  del $1. " ;
end;
if type='D' then
  range=" "||name||" YYMMDD"||trim(left(put(flen,8.)))||". " ;
 else if type in("C","L") then do;
   if  flen > 200 or fdec > 0 then do;
     if fdec=0 then
       range=name||" $200."||" +"||trim(left(put((flen-200),8.))) ;
     else
       range=name||" $200."||"
+"||trim(left(put(((flen+(fdec*256))-200),8.)));
   end;
   else
     range=name||" $"||trim(left(put(flen,8.)))||". ";
 end;
 else if type in('N','F') then
     range=name||"
"||trim(left(put(flen,8.)))||"."||trim(left(put(fdec,8.)));
 else if type='M' then
     range="+10" ;
put range ;
if eof then do;
  put "@ ;" ;
%if &del=N %then %do;
  put "IF DEL^='*'";
  %if %nrbquote(&where)^= %then
    put " AND (&where)";;
  put " THEN OUTPUT;";
  put "ELSE IF DEL='*' THEN DO;";
  put "  FILE LOG;";
  put "  PUT 'RECORD ' J ' DELETED';";
  put "END;";
%end;
%else %do;
%if nrbquote(&where)^= %then
  put "IF (&where) THEN";;
  put "OUTPUT;";
%end;
  put "END;";
  put "DROP ";
  %if &del=N %then %do;
    put " DEL";
  %end;
  put " START J;";
  put "STOP;";
%if %nrbquote(&drop)^= %then
  put "DROP &drop;" %str(;);
%else %if %nrbquote(&keep)^= %then
  put "KEEP &keep;";;
  put "RUN;";
end;
run;
%inc control;
%endmacro:
%mend dbf2sas;
