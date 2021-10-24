/*
 * Richard A. DeVenezia
 * Multi Level Hash Macros
 * May 31, 2004
 * Copyright 2004
 *
 * At present
 * Each class level corresponds to a single variable, no composites
 * The leaf or final data level may have multiple variables
 */

/*-----
 * group: Data processing
 * purpose: Macros for implementing and utilizing multi level hashes in DATA Step.
 * notes: Additional <A HREF='../samples/#hash7'>sample code</a>.
 */

%*---------------------------------------------------------------------;
%macro MLH_Start (top, keys=, data=, debug=no);

  /*
   * top - Base identifier used for creating DATA Step variable names
   * keys - A colon (:) separated list of variables that define a class hierarchy
   *        (corresponds to Tabulate CLASS statement)
   * data - A space separated list of variables that define a data leaf
   *        (corresponds to Tabulate VAR statement)
   */

  %global _mlh_&top._keys;
  %global _mlh_&top._data;

  %let _mlh_&top._keys  = &keys;
  %let _mlh_&top._data  = &data;

  %local i n;

  %let i = 1;
  %do %while (%scan(&data,&i,%str( )) ne );
    %global _mlh_&top._data_&i;
    %let _mlh_&top._data_&i = %scan(&data,&i,%str( ));
    %let i = %eval (&i+1);
  %end;

  %let n = %eval (&i-1);

  %global _mlh_&top._data_N;
  %let _mlh_&top._data_N = &n;

  %let i = 1;
  %do %while (%scan(&keys,&i,:) ne );

    %global _mlh_&top._key_&i;
    %global _mlh_&top._wrk_&i;

    %let _mlh_&top._key_&i = %scan(&keys,&i,:);
    %let _mlh_&top._wrk_&i = &top._anon_&i;

    declare hash &&_mlh_&top._wrk_&i;

    %let i = %eval (&i+1);
  %end;

  %let n = %eval (&i-1);

  %global _mlh_&top._key_N;
  %let _mlh_&top._key_N = &n;

  declare hash &top._node;

  declare hash &top();
  &top..defineKey  ("&&_mlh_&top._key_1");
  &top..defineData ("&&_mlh_&top._key_1");
  &top..defineData ("&&_mlh_&top._wrk_1"); %* generic hash worker;
  &top..defineDone ();

  declare hash &top._tracker();
  &top._tracker.defineKey  ("node_addr");
  &top._tracker.defineData ("&top._node");
  &top._tracker.defineDone ();

%if &debug=yes %then %do;
a = addr(&top);
put a= hex8. "&top defined (key: &&_mlh_&top._key_1, data:&&mlh_&top._wrk_1)" /;
%end;

%mend;

%*---------------------------------------------------------------------;
%macro MLH_Finish (top);

  %symdel _mlh_&top._keys;
  %symdel _mlh_&top._data;

  %local i;
  %do i = 1 %to &&_mlh_&top._key_N;
    %symdel _mlh_&top._key_&i;
    %symdel _mlh_&top._wrk_&i;
  %end;

  %symdel _mlh_&top._key_N;

  %local i;
  %do i = 1 %to &&_mlh_&top._data_N;
    %symdel _mlh_&top._data_&i;
  %end;

  %symdel _mlh_&top._data_N;

  %local hi;

  %let hi = &top._hif;

  declare hiter &hi ("&top._tracker");
  do rc = &hi..first() by 0 while (rc = 0);
    &top._node.delete();
    rc = &hi..next();
  end;
  put;
  &top..delete();

%mend;

%*---------------------------------------------------------------------;
%macro MLH_Set (top, debug=no);

  %local i node work keyn key keyvar wrk wrkvar wrknext wrknextvar data datan;

  %let node = &top._node;
  %let keyn = &&_mlh_&top._key_N;
  %let key  = &&_mlh_&top._key_1;
  %let wrk  = &&_mlh_&top._wrk_1;
  %let datan= &&_mlh_&top._data_N;

  &node = &top;

  %do i = 1 %to %eval(&keyn-1);

    rc = &node..find();

%if &debug=yes %then %do;
a = addr(&node);
put a= hex8. rc= @30 &key=;
%end;

%let keyvar = _mlh_&top._key_%eval(&i+1);
%let key = &&&keyvar;

%let wrkvar = _mlh_&top._wrk_&i;
%let wrk = &&&wrkvar;

%let wrknextvar = _mlh_&top._wrk_%eval(&i+1);
%let wrknext = &&&wrknextvar;

    if rc ne 0 then do;
      &wrk = _new_ hash();
      &wrk..defineKey  ("&key");
      &wrk..defineData ("&key");
      &wrk..defineData ("&wrknext");
      &wrk..defineDone();

%if &debug=yes %then %do;
a = addr(&wrk);
put a= hex8. "defined (key: &key, data:_&top._work_)";
%end;

      &node..replace();

      &node = &wrk;

      node_addr = addr (&node);
      &top._tracker.add ();
    end;
    else
      &node = &wrk;

  %end;

  %let wrk = &wrknext;

  &wrk._key + 1;

  rc = &node..find();
  if rc ne 0 then do;
    &wrk = _new_ hash ();
    &wrk..defineKey ("&wrk._key");
    %do i = 1 %to &datan;
      %let data = _mlh_&top._data_&i;
      %let data = &&&data;
      &wrk..defineData ("&data");
    %end;
    &wrk..defineDone ();
    &node..replace();
    &node = &wrk;

    node_addr = addr (&node);
    &top._tracker.add ();
  end;
  else
    &node = &wrk;

  &node..replace();

%if &debug=yes %then %do;
a = addr(&node);
put a= hex8. rc= @30 &key= '-> ' &data= '*' / ;
%end;

%mend;

%*---------------------------------------------------------------------;
%macro MLH_Get (top, n);
  %local node wrkvar wrk;

  %let node = &top._node;

  &node = &top;

  %if %length(&n)=0 %then
    %let n = &&_mlh_&top._key_N;

  %do i = 1 %to %eval(&n);

    rc = &node..find();

%let wrkvar = _mlh_&top._wrk_&i;
%let wrk = &&&wrkvar;

    if rc eq 0 then do;
      &node = &wrk;

  %end;

  %do i = 1 %to %eval(&n);
    end;
  %end;

%mend;

%*---------------------------------------------------------------------;
%macro MLH_Dump (top, debug=no);

  %local i j ii n datan node hiter;

  %let n     = &&_mlh_&top._key_N;
  %let datan = &&_mlh_&top._data_N;

  %do i = 1 %to %eval(&n+1);
    %local hiter&i;
    %let hiter&i = &top._hi_&i._&sysindex;
    declare hiter &&hiter&i;
  %end;

  %let node = &top;

  %do i = 1 %to &n;

%if debug=yes %then %do;
a = addr (&node);
put a=hex8. ;
%end;

    %let hiter = &&hiter&i;
    &hiter = _new_ hiter ("&node");

    do rc&i = &hiter..first() by 0 while (rc&i = 0);

    put +&i &&_mlh_&top._key_&i=;

    %let node = &&_mlh_&top._wrk_&i;

  %end;

  %let hiter = &&hiter&i;
  &hiter = _new_ hiter ("&node");

  do rc&i = &hiter..first() by 0 while (rc&i = 0);
    put +&i
    %do j = 1 %to &datan;
      &&_mlh_&top._data_&j=
    %end;
    ;
    rc&i = &hiter..next();
  end;

  %do i = 1 %to &n;

      %let ii = %eval (&n-&i+1);
      %let hiter = &&hiter&ii;

      rc&ii = &hiter..next();
    end;

    &hiter..delete();

  %end;

%mend;

%*---------------------------------------------------------------------;
%macro MLH_Foreach (top, link=section, debug=no);

  %local i ii n node ;

  %let n = &&_mlh_&top._key_N;

  %do i = 1 %to %eval(&n+1);
    %local hiter&i;
    %let hiter&i = &top._hi_&i._&sysindex;
    declare hiter &&hiter&i;
  %end;

  %let node = &top;

  %do i = 1 %to &n;

%if debug=yes %then %do;
a = addr (&node);
put a=hex8. ;
%end;

    %let hiter = &&hiter&i;
    &hiter = _new_ hiter ("&node");

    do rc&i = &hiter..first() by 0 while (rc&i = 0);

    %let node = &&_mlh_&top._wrk_&i;

  %end;

  %let hiter = &&hiter&i;
  &hiter = _new_ hiter ("&node");

  do rc&i = &hiter..first() by 0 while (rc&i = 0);
    link &link;
    rc&i = &hiter..next();
  end;


  %do i = 1 %to &n;

      %let ii = %eval (&n-&i+1);
      %let hiter = &&hiter&ii;

      rc&ii = &hiter..next();
    end;

    &hiter..delete();

  %end;

%mend;

%*---------------------------------------------------------------------;

/**html
 * <p>Sample code - create and iterate a multi level hash</p>
 */

/* Ron Fehd style comment block */
/* remove space before ending slash to uncomment the block * /

dm 'clear log' log;

options mprint source nosymbolgen;

%let mlh = mlhx;

data _null_;

  retain level1-level5;

  %* prep PDV;
  if 0 then set sashelp.company;

  %MLH_Start ( &mlh
             , data=job1
             , keys=level1 : level2 : level3 : level4 : level5
             , debug=no)

  do until (endOfData);
    set sashelp.company end=endOfData;
    %MLH_Set (&mlh, debug=no )
  end;

  %MLH_Dump (&mlh)

  level1 = 'International Ai';
  level2 = 'NEW YORK';
  level3 = 'ADMIN';
  level4 = 'SHIPPING';

  %MLH_Get (&mlh, 4)

  put / (level1-level4) (=) / 20*'-';
  if rc = 0 then do;
    declare hiter hi ("&mlh._anon_4");
    do rc = hi.first() by 0 while (rc eq 0);
      put level5= job1=;
      rc = hi.next();
    end;
  end;
  hi.delete();
  put;

  %MLH_Foreach (&mlh, link=section1)

  %MLH_Finish (&mlh)

  stop;

section1:
  put (level:)(=) job1=;
return;
run;

/**/

/* Ron Fehd style comment block */
/* remove space before ending slash to uncomment the block * /

ods listing;

* check for yourself, mlh global macro variables have been cleaned out;
proc print data=sashelp.vmacro;
run;

/**/
