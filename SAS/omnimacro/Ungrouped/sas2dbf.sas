/*-----
 * group: Data out
 * purpose: Macro to convert SAS dataset to dbase file. Ver 2.0B.<br><b><i>Author Richard Hockey DPH Sep 1998,<br>rhockey@mater.org.au</i></b><br><br>See also <a href="index.php?m=dbf2sas">dbf2sas</a>
 */

%macro sas2dbf(in=,out=,keep=,drop=,dec=0,where=);
%put %str(   ) ;
%put %str(   ) Macro to convert SAS dataset to dbase file Ver 2.0B ;
%put %str(   ) Author: Richard Hockey Sep 1998 ;
%put %str(   ) Email: rhockey@mater.org.au;
%put %str(   ) ;
%if &in= %then %do;
  %put %str(  ) Usage: ;
  %put %str(      ) %nrstr(%SAS2DBF(IN= ,OUT= ,KEEP= ,DROP= ,DEC= ,WHERE=);) ;
  %put %str(  ) Parameters are: ;
  %put %str(      ) IN SAS DATASET without quotes.;
  %put %str(      ) OUT output dbase file. ;
  %put %str(      ) Optional parameters: ;
  %put %str(      ) either KEEP Variables to keep. ;
  %put %str(      ) or DROP Variables to drop. ;
  %put %str(      ) DEC Number of decimal places for numeric variables.
;
  %put %str(      ) WHERE subsetting where clause. ;
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
proc contents data=&in
%if %nrbquote(&keep)^=  %then (keep=&keep) ;
%else %if %nrbquote(&drop)^=  %then (drop=&drop) ;
   out=_temp noprint;
proc sort; by varnum;
data _temp;
 set _temp end=eof;
if type=2 then vtype='C';
  else if index(format,'YY')>0 or index(format,'DATE')>0 then vtype='D';
  else vtype='N';
if vtype='D' then length=8;
if vtype='N' then length=12;
fdec=&dec;
if vtype='N' then do;
  if formatl^=0 then length=formatl;
  else if informl^=0 then length=informl;
%if &dec^=  %then %do;
  if formatd^=0 then fdec=formatd;
  else if informd^=0 then fdec=informd;
%end;
end;
flen=put(length,pib1.);
fd=put(fdec,ib1.);
if _n_=1 then do;
  fds=1;
  file "control.sas" ;
  put "DATA _NULL_;";
  put "  SET &in end=eof;";
%if %nrbquote(&where)^= %then
  put "WHERE &where ;";;
  put "FILE '&out' recfm=n lrecl=256 mod;";
  put "PUT ' ' ;  " ;
end;
length fmt $ 8;
if vtype='C' then fmt="$"||trim(left(put(length,8.)))||".";
else if vtype='N' then do;
  if fdec>0 then fmt=trim(left(put(length,8.)))||"."||put(fdec,1.);
  else fmt="12.4";
end;
else if vtype='D' then  fmt="$8.";
fds+length;
vcount+1;
if eof then do;
  vn=3;
  mdate=input(put(modate,datetime7.),date7.);
  day=day(mdate);
  month=month(mdate);
  year=year(mdate)-1900;
  %if &endian=BIG %then %do;
    nr=reverse(put(nobs,ib4.));
    hs=reverse(put((vcount+1)*32+1,ib2.));
    lr=reverse(put((fds),ib2.));
  %end;
  %else %do;
    nr=put(nobs,ib4.);
    hs=put((vcount+1)*32+1,ib2.);
    lr=put((fds),ib2.);
  %end;
  file "&out" recfm=n lrecl=256;
  put @1 vn ib1. year ib1. month ib1. day ib1. nr $4. hs $2. lr $2.  ;
  put '0000000000000000000000000000000000000000'x;
end;
run;
data _null_;
length name $ 11;
 set _temp end=eof;
file "control.sas" mod;
if vtype='D' then do;
  put 'length dvar $ 8.;';
  put '_year=year(' name ');';
  put '_month=month('name ');';
  put '_day=day(' name ');';
  put 'dvar=put(_year,z4.)||put(_month,z2.)||put(_day,z2.);';
  put 'put dvar ' fmt ';';
end;
else put 'put ' name fmt ';';
file "&out" recfm=n mod lrecl=256;
do i=1 to 11-length(name);
  name=trim(name)||'00'x;
end;
put name $11. vtype $1.  '00000000'x flen $1. fd $1.
    '0000000000000000000000000000'x ;
if eof then do;
  put '0d'x ;
  file "control.sas" mod;
  put "if eof then put '1a'x ;";
  put "run;";
end;
run;

%inc control;
%endmacro:
%mend sas2dbf;