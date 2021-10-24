/*-----
 * group: Data processing
 * purpose: For a given data set and by group specification, create a data set enumerating parent/child relationships of the by groups
 * notes: Useful for creating data for SAS/AF Organizational Chart class
 */

%macro hierarch (ds, vars);

  %* Copyright 1998-2000, Richard A. DeVenezia
  %*
  %* For a given dataset and list of hierarchal variables
  %* make a data view which can be used with AF legacy class
  %* Organizational Chart;
  %*
  %* Arguments:
  %* ds   - source data set name
  %* vars - class variables that define a hierarchy
  %*
  %* Warning:
  %* No error checking is performed to ensure the variables
  %* listed in 'vars' are actually columns in data set 'ds';
  %*
  %* 05/13/98 Initial coding ;
  %* 06/30/00 Comments by Benjamin Guralnik and RAD;

  %local ds vars i N h varlist;

  %* establish the value of macro variable 'varlist' as a
  %* comma delimited list of the hierarchy variables
  %* to be used later a SELECT DISTINCT clause;

  %let i = 1;
  %do %while (%scan(&vars,&i) ne);
    %if &i gt 1
      %then %let varlist = &varlist,%scan(&vars,&i);
      %else %let varlist = %scan(&vars,&i);
    %let i = %eval (&i+1);
  %end;

  %* N is the number of class variables in the hierarchy;

  %let N = %eval (&i-1);

  %* create a view to the source data that contains
  %* the class level values and the number of occurences;

  proc sql;
     create view h as
     select *, count(*) as N from
     (select distinct &varlist from &ds);
  quit;

  %* open the source dataset and get the format of each class variable;
  %* store the class variable format in the indexed macro variable 'vf';

  %let h = %sysfunc(open(&ds));
  %if &h %then %do;
    %do i = 1 %to &N;
      %local vf&i;
      %let vf&i=%sysfunc(varfmt(&h,%sysfunc(varnum(&h,%scan(&vars,&i)))));
    %end;
    %let h = %sysfunc(close(&h));
  %end;

  %* Traverse the view of class level values outputting parent/child relationships;

  data h2 / view = h2;
    set h;
    by &vars notsorted;  %* use notsorted just in case the SQL view 'h' is unsorted;

    length node_val $25;

    format _n_ n 4.; drop n;

	%* every 2% of levels update a display of progress;
    window status rows=6 columns=20
    #1 @4 _n_ ' of ' n;
    if 0 = mod (_n_ , 1+int(n/50)) then display status noinput;

    %* create the "documentElement" node in XML terms (BG);

    if _n_ = 1 then do;
      node_pop = .;
      node_id = 0;
      node_val = 'Drill Down';
      output;
    end;

	%* _Ni are temporary data set variables used to maintain the
	%* value of the parent node ids that must be traversed to reach the current leaf;

    retain _N1-_N&N;
      drop _N1-_N&N;

    %do i = 1 %to &N;
      if first.%scan(&vars,&i) then do;

	    %* a class level value has changed, update the parent node id;

        %if &i=1 %then
          node_pop = 0;
        %else
          node_pop = _N%eval(&i-1);
        ;

		%* the value to show in a node is the class level value;
		%* use the formatted value if the column is formatted;

        %if (&&vf&i=) %then
          node_val =     %scan(&vars,&i);
        %else
          node_val = put(%scan(&vars,&i),&&vf&i);
        ;

		%* Each row in the output data set represents a node,
		%* hence increment node_id, the value that uniquely identifies each node;

		node_id + 1;

		%* make sure the current level node id is updated for this first. condition;
        %* it will be retained for all its children;

        _N&i = node_id;
        output;
      end;
    %end;
  run;
%mend;

/**html
 * <p>Sample code</p>
 */

/* This was an e-mail I sent to Benjamin on how to get started using this
 * macro along with the Organization Chart class;

 * submit these statements;
 data snapshot;
   set sashelp.vcatalg;
   where libname = 'SASHELP'
     and memtype = 'CATALOG'
     and memname in ('FSP','CLASSES');
   ;
 run;

 %include 'hierarch.sas';
 %hierarch (snapshot, libname memname objname);

* now build a sample frame with these commands:
* BUILD WORK.TEST.HIERARCH.FRAME
* make a organizational chart object
* for dataset enter WORK.H2 (created by hierarch macro)

* click on Mapping list
* for parent_node use variable node_pop
* for current_node use variable node_id
* for node variable select TEXT
* for data set variable select NODE_VAL
* click on the Add button under Mapping List
* click OK

* click on Chart appearance
* uncheck Show all levels
* check Use +,- and dotted lines
* click OK

* click on Node appearance
* click on Select action
* check Hide/unhide children
* click OK
* click OK

* In Chart Style radio group, pick Directory
* In Node Spacing group, enter 4 for Vertical

* Now TESTAF to see the meta-data in an explorer like fashion

*/
