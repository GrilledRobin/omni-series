/* Richard A. DeVenezia
 * www.devenezia.com
 * Feb 11, 2003
 *
 * Show the values of the data items of a DATA Step hash object in the log
 */

/*-----
 * group: Data processing
 * purpose: Show the contents of a hash in the log.
 */

%macro putHash (hash, vars);

  %*
  %* hash - variable that references a hash object
  %* vars - space separated list of variables linked to the data items of hash
  %*        separate with pound sign (#) to get varname=varvalue format
  %*;

  %* generate a random variable name;
  %local random hi rc;
  %let random = %substr(%sysfunc(ranuni(0),10.8),3);
  %let hi = hi_&random;
  %let rc = rc_&random;

  %* emit DATA Step code that iterates the hash and
  %* puts the data items values in the log;

  declare hiter &hi ("&hash");
  do &rc = &hi..first() by 0 while (&rc = 0);
    put %sysfunc(translate(&vars,=,#));
    &rc = &hi..next();
  end;
  &hi..delete();
  put;

  %put WARNING: Values of variables &vars will change;

%mend;


/**html
 * <p>Sample code</p>
 */

data _null_;
  * prep the PDV, this lazy way is not always recommended;
  if 0 then set sashelp.class(obs=0);

  declare hash H (dataset:'sashelp.class');
  H.defineKey ('Name');
  H.defineData('Name', 'Age', 'Weight', 'Sex');
  H.defineDone();

  %putHash (H,name#age#weight#sex#);
  %putHash (H,name age weight sex);

  stop;
run;

/**html
<pre style='background-color:#DFD'>
Name=John Age=12 Weight=99.5 Sex=M
Name=Alice Age=13 Weight=84 Sex=F
Name=Henry Age=14 Weight=102.5 Sex=M
...

John 12 99.5 M
Alice 13 84 F
Henry 14 102.5 M
...
</pre>
 */