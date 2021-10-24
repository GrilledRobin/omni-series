/* hash-macros
 * Richard A. DeVenezia
 * Copyright 2004
 * Jan 17, 2004
 *
 * Macros to (hopefully) simplify coding hash array solutions
 *
 * mod
 * 03JUN04 - Improved example
 */

/*-----
 * group: Data processing
 * purpose: Macros for simplified use of arrays as hashes. Be forewarned, know thy technique, know thy data.
 * notes: Inspired by Paul Dorfman.
 */

/**html
  * <p>Sample: <a href="#problem">problem</a> &nbsp; <a href="#usage">usage</a>
  * <br>Recommended reading: <a href="http://search.sas.com/suppquery.html?qt=dorfman">The numerous and educating papers of Paul Dorfman</a>
  * </p>
  */

%macro hashSize (n=, data=, load = 0.5) ;

 /*
  * n - an apriori determined n
  * data - let n be number of rows in data
  * load - load factor
  *
  * determine size of array that will contain a hash of N items
  * at a given load factor.
  *
  * Sugi 26 Paper 128-26, Paul M. Dorfman
  * QUICK DISK TABLE LOOKUP
  * VIA HYBRID INDEXING INTO A
  * DIRECTLY ADDRESSED SAS . DATA SET
  */

   %if %length(&data) %then %do;
     %local dsid;
     %let dsid = %sysfunc(open(&data));
     %if &dsid %then %do;
       %let n = %sysfunc (attrn(&dsid, NOBS));
       %let dsid=%sysfunc(close(&dsid));
     %end;
     %else %do;
       %put ERROR: hash_size could not open &data.  Forcing an error;
     ;DATA_NOT_FOUND;
     %end;
   %end;

   %local ip up pr ;

   %let pr = %sysfunc (floor(&n/&load)) ;

   %do %until ( &ip > &up ) ;
      %let pr = %eval (&pr + 1) ;

      %let up = %sysfunc(ceil(%sysfunc(sqrt(&pr)))) ;

      %if %sysfunc(mod(&pr,2)) = 0 %then %goto failed ;

      %do ip = 3 %to &up %by 2;
         %if %sysfunc(mod(&pr,&ip)) = 0 %then %goto failed ;
      %end ;
      %failed:
   %end ;
   &pr
%mend ;

%macro declareHash (hash, size, policy=LP, allowDuplicates=NO);
  %let policy = %upcase(&policy);
  %let allowDuplicates = %upcase (&allowDuplicates);

  %if (&policy ne LP and &policy ne CL) %then %do;
    %put ERROR: Hash collision resolution policy must be LP (Linear Probe) or CL (Coalesced Linking);
    ;UNKNOWN_POLICY;
    %goto EndMacro;
  %end;

  %if &allowDuplicates ne YES %then
    %let allowDuplicates = NO;

  %global hash_size_&hash;
  %global hash_policy_&hash;
  %global hash_dups_&hash;
  %global hash_add_count_&hash;
  %global hash_lp_increment_&hash;

  %let hash_size_&hash   = &size;
  %let hash_policy_&hash = &policy;
  %let hash_dups_&hash   = &allowDuplicates;
  %let hash_add_count_&hash = 1;
  %let hash_lp_increment_&hash = 3;

  array &hash._keys  (0:&size) _temporary_;

  %if &policy eq CL %then %do;
    array &hash._chain (0:&size) _temporary_;
    retain &hash._chain_addr &size;
  %end;

  retain &hash._max_depth 0;

%EndMacro:
%mend;

%macro declareHashKey (hash, key);
  %global hash_key_&hash;
  %let hash_key_&hash = &key;

  length &hash._key_addr 8;
%mend;

%macro declareHashData (hash, var);
  %local size;
  %let size = &&hash_size_&hash;

  array &hash._&var (0:&size) _temporary_;
%mend;

%macro hashAddKey (hash, rc=);
  %* PDV variable named in rc will receive -1 if duplicate key
  %* found when allowDuplicates = NO;

  %hashAddKey_&&hash_policy_&hash (&hash, rc=&rc)
%mend;

%macro hashAddKey_CL (hash, rc=);
  %local size key count key_addr chain chain_addr keys;

  %let size  = &&hash_size_&hash;
  %let key   = &&hash_key_&hash;
  %let count = &&hash_add_count_&hash;

  %let hash_add_count&hash = %eval ( 1 + &count );

  %let key_addr   = &hash._key_addr;
  %let chain      = &hash._chain;
  %let chain_addr = &hash._chain_addr;
  %let keys       = &hash._keys;
  %let end_block  = &hash._addkey_end_block_&count;

*--------------------;
  %if %length (&rc) %then
  &rc = 0;;

  &key_addr = mod ( &key, &size ) + 1;

  if &chain ( &key_addr ) ne . then do;

    %if &&hash_dups_&hash = YES %then %do;

      %* allowing dup keys, proceed to end of chain;
      do while ( &chain ( &key_addr ) ne 0 );
        &key_addr = &chain ( &key_addr );
      end;

    %end;
    %else %do;

      %* disallowing duplicate keys;
      %* thus quit code block if key found;

      do while ( 1 ) ;
        if ( &key = &keys ( &key_addr ) ) then do;
          %if %length (&rc) %then
          &rc = -1;;
          goto &end_block;
        end;

        %* stop searching if end of chain reached;
        if ( &chain ( &key_addr ) = 0 ) then
          leave;

        &key_addr = &chain ( &key_addr );
      end;

    %end;

    %* &key_addr is at the end of a chain
    %* (where &chain (&key_addr) is 0);

    %* locate open addr for new end of chain;
    do &chain_addr = &chain_addr by -1
       until ( &chain ( &chain_addr ) = . );
    end;

    %* point to new end of chain and update key addr ;
    &chain ( &key_addr ) = &chain_addr;
    &key_addr = &chain_addr;
  end;

  %* set end of chain marker and set hash validator;
  &chain ( &key_addr ) = 0;
  &keys ( &key_addr ) = &key;

&end_block: ;
*--------------------;
%mend;

%macro hashAddKey_LP (hash, rc=);
  %local size key count increment key_addr keys end_block depth max_depth bound_check;

  %let size      = &&hash_size_&hash;
  %let key       = &&hash_key_&hash;
  %let count     = &&hash_add_count_&hash;
  %let increment = &&hash_lp_increment_&hash;

  %let hash_add_count&hash = %eval ( 1 + &count );

  %let key_addr   = &hash._key_addr;
  %let keys       = &hash._keys;
  %let end_block  = &hash._addkey_end_block_&count;
  %let depth      = &hash._depth;
  %let max_depth  = &hash._max_depth;

  %if &increment = 0 %then %do;
    %put ERROR: Linear probe increment must be non-zero;
    ;CauseError;
    %goto EndMacro;
  %end;
  %else
  %if &increment > 0 %then
    %let bound_check = if ( &key_addr > &size ) then &key_addr + ( - &size );
  %else
    %let bound_check = if ( &key_addr <   0   ) then &key_addr + ( + &size );

*--------------------;
  %if %length (&rc) %then
  &rc = 0;;

  &key_addr = mod ( &key, &size ) + 1;

  if ( &keys ( &key_addr ) ne . ) then do;

    &depth = 0;

    do while (1);

  %if &&hash_dups_&hash = NO %then %do;

      if ( &key = &keys ( &key_addr ) ) then do;
        %if %length (&rc) %then
        &rc = -1;;
        goto &end_block;
      end;

  %end;

      if ( &keys ( &key_addr ) = . ) then
        leave;

      &key_addr + ( &increment );
      &bound_check;
      &depth + 1;
    end;

    if ( &depth > &max_depth ) then
      &max_depth = &depth;

  end;

  &keys ( &key_addr ) = &key;

&end_block: ;
*--------------------;

%EndMacro:
%mend;

%macro keyArray (hash);
  &hash._keys
%mend;

%macro chainArray (hash);
  &hash._chain
%mend;

%macro dataArray (hash, var);
  &hash._&var
%mend;

%macro hashGetKey (hash);
  %keyArray(&hash) ( &hash._key_addr )
%mend;

%macro hashGetData (hash, var);
  %dataArray(&hash,&var) ( &hash._key_addr )
%mend;

%macro hashSetData (hash, var);
  %dataArray(&hash,&var) ( &hash._key_addr ) = &var;
%mend;

%macro hashKey (hash);
  &&hash_key_&hash
%mend;

%macro hashKeyAddr (hash);
  &hash._key_addr
%mend;

%macro hashFetch (hash, rc=);
  %* PDV variable named in rc will receive -1 if key not found
  %* and will receive 0 if key found;

  %hashFetch_&&hash_policy_&hash (&hash, rc=&rc)
%mend;

%macro hashFetchNext (hash, rc=);
  %* PDV variable named in rc will receive -1 if key not found
  %* and will receive 0 if key found;

  %hashFetchNext_&&hash_policy_&hash (&hash, rc=&rc)
%mend;

%macro hashFetch_CL (hash, rc);
  %local size key key_addr chain keys;

  %let size  = &&hash_size_&hash;
  %let key   = &&hash_key_&hash;

  %let key_addr = &hash._key_addr;
  %let chain    = &hash._chain;
  %let keys     = &hash._keys;

*--------------------;
  %if %length (&rc) %then
  &rc = -1;;

  &key_addr = mod ( &key, &size ) + 1;

  if &chain ( &key_addr ) ne . then do;
    do while ( 1 ) ;
      if ( &key = &keys ( &key_addr ) ) then do;
        %if %length (&rc) %then
        &rc = 0;;
        leave;
      end;

      %* stop searching if end of chain reached;
      if ( &chain ( &key_addr ) = 0 ) then do;
        &key_addr = -1;
        leave;
      end;

      &key_addr = &chain ( &key_addr );
    end;
  end;
  else
    &key_addr = -1;

*--------------------;
%mend;

%macro hashFetchNext_CL (hash, rc);
  %if &&hash_dups_&hash = NO %then %do;
    %put ERROR: hashFetchNext can only be called for hashes declared with allowDuplicates=YES;
    %put ERROR: hash [&hash] was not declared thus.;
    ;CauseError;
    %goto EndMacro;
  %end;

  %local size key key_addr chain ;

  %let size  = &&hash_size_&hash;
  %let key   = &&hash_key_&hash;

  %let key_addr = &hash._key_addr;
  %let chain    = &hash._chain;

*--------------------;
  %if %length (&rc) %then
  &rc = -1;;

  if &key_addr > -1 then do;

    &key_addr = &chain ( &key_addr );

    if &chain ( &key_addr ) ne . then do;
      do while ( 1 ) ;
        if ( &key = &keys ( &key_addr ) ) then do;
          %if %length (&rc) %then
          &rc = 0;;
          leave;
        end;

        %* stop searching if end of chain reached;
        if ( &chain ( &key_addr ) = 0 ) then do;
          &key_addr = -1;
          leave;
        end;

        &key_addr = &chain ( &key_addr );
      end;
    end;
    else
      &key_addr = -1;

  end;

*--------------------;
%EndMacro:
%mend;

%macro hashFetch_LP (hash, rc);
  %local size key increment key_addr keys depth max_depth bound_check;

  %let size      = &&hash_size_&hash;
  %let key       = &&hash_key_&hash;
  %let increment = &&hash_lp_increment_&hash;

  %let key_addr  = &hash._key_addr;
  %let keys      = &hash._keys;
  %let depth     = &hash._depth;
  %let max_depth = &hash._max_depth;

  %if &increment > 0 %then
    %let bound_check = if ( &key_addr > &size ) then &key_addr + ( - &size );
  %else
    %let bound_check = if ( &key_addr <   0   ) then &key_addr + ( + &size );

*--------------------;
  %if %length (&rc) %then
  &rc = -1;;

  &key_addr = mod ( &key, &size ) + 1;

  if &keys ( &key_addr ) ne . then do;

    &depth = 0;

    do while ( 1 ) ;
      if ( &key = &keys ( &key_addr ) ) then do;
        %if %length (&rc) %then
        &rc = 0;;
        leave;
      end;

      %* stop searching if end of probe reached;
      if ( &keys ( &key_addr ) = . or &depth > &max_depth ) then do;
        &key_addr = -1;
        leave;
      end;

      &key_addr + ( &increment );
      &bound_check;
      &depth + 1;
    end;
  end;
  else
    &key_addr = -1;

*--------------------;
%mend;

%macro hashFetchNext_LP (hash, rc);
  %local size key increment key_addr keys depth max_depth bound_check;

  %let size      = &&hash_size_&hash;
  %let key       = &&hash_key_&hash;
  %let increment = &&hash_lp_increment_&hash;

  %let key_addr  = &hash._key_addr;
  %let keys      = &hash._keys;
  %let depth     = &hash._depth;
  %let max_depth = &hash._max_depth;

  %if &increment > 0 %then
    %let bound_check = if ( &key_addr > &size ) then &key_addr + ( - &size );
  %else
    %let bound_check = if ( &key_addr <   0   ) then &key_addr + ( + &size );

*--------------------;
  %if %length (&rc) %then
  &rc = -1;;

  if ( &key_addr > -1 ) then do;

    do while ( 1 ) ;
      &key_addr + ( &increment );
      &bound_check;
      &depth + 1;

      if ( &key = &keys ( &key_addr ) ) then do;
        %if %length (&rc) %then
        &rc = 0;;
        leave;
      end;

      %* stop searching if end of probe reached;
      if ( &keys ( &key_addr ) = . or &depth > &max_depth ) then do;
        &key_addr = -1;
        leave;
      end;
    end;

  end;

*--------------------;
%mend;


/**html
 * <p><a name="problem"></a>Sample code - A problem</p>
 */

/** /

*
* From a SESUG 2003 coffee table discussion.
*
* Environment:
* Each transaction has an id (tid), a prior transaction id (pid) and an amount
* Each id is a unique 15 digit character string
* A transaction can be the prior transaction of only one transaction
* A path in the transaction data is the set of transactions x,y,z,... such that
* x.tid = y.pid and y.tid = z.pid and ...
* Some transactions are in paths of length 1
*
* Task:
* Find M path totals amongst N transactions
*
* Fake data construction:
* Set N to the number of transactions
* Create M (a random number of) paths in the transaction data
*;

options mprint notes;

%* number of transactions;

%let N = %sysevalf (0+1E6);

%* probability of transaction having a first backlink and
%* probability of transaction in a path having a backlink;

%let pt = 0.65;
%let pm = 0.65;

%* make fake data;

data transactions (keep=tid pid amount);

  array ids (&N,2) _temporary_;

  retain seed 1;

  * id is a 15 digit number;
  id = 1e14;

  do row = 1 to hbound (ids);

    * for simplicity, new id is always greater than previous id
    * if id was random a hash would be needed to ensure the id was not a repeat;

    id + 1e7*ranuni(seed) ;
    id + 1;

    ids ( row, 1 ) = id;

    * generate a random backlink trail;

    prow = row;
    p = &pt;

    do while ( ranuni(seed) < p );

      p = &pm;

      prow = int ( prow * ranuni(seed) );

      if prow = 0 then leave;

      if ids [ prow,1 ] > 0 then do;      * untagged;
        ids [ prow,1 ] = -ids [ prow,1 ]; * tag as being in a trail;
        ids [  row,2 ] = prow;            * store backlink;
      end;
      else
        leave;                            * tagged, scram;
    end;
  end;

  * output the simulated transactions;

  do row = 1 to hbound(ids);
    id = abs ( ids [ row, 1 ] );
    tid = put (id, z15.);

    prow = ids [ row, 2 ];
    if prow then do;
      id = abs ( ids [ prow, 1 ] );
      pid = put (id, z15.);
    end;
    else
      pid = '';

    amount = int (100*ranuni(seed)) - 30;  * -30 to 69;
    output;
  end;

run;


* disorder the transactions;

proc sort;
  by amount;
run;

/**/

/**html
 * <p><a name="usage"></a>Sample code - Solve the problem</p><p>Finding and summing ~650,000 paths amongst 1,000,000 transactions takes about 4 seconds on my system.</p>
 */

/** /

%global hash_size;

%let hash_size = %hashSize (load=0.75, data=transactions);

data trail_sums (keep=t_id ntids total_amount rename=(t_id=tid));

 %* two hashes will allow forward lookup given only backlinks;
 %* different hashing policies only for testing purposes;

  %declareHash (start, &hash_size, policy=CL)
  %declareHashKey  (start, tid)
  %declareHashData (start, amount)

  %declareHash (next, &hash_size, policy=LP)
  %declareHashKey  (next, pid)
  %declareHashData (next, tid)
  %declareHashData (next, amount)

  do until (endOfTransactions);
    set transactions
        ( keep=tid pid amount
          rename=(tid=t_id pid=p_id)
        )
        end=endOfTransactions;

    %* transform key variables from character to numeric;

    tid = input (t_id, 15.);
    pid = input (p_id, 15.);

    if p_id = '' then do;
      %hashAddKey (start, rc=rc)

      if (rc < 0) then do;
        put "ERROR: " tid= "is not unique";
        stop;
      end;

      %hashSetData (start, amount)
    end;
    else do;
      %* hash pid to allow forward lookup;

      %hashAddKey (next, rc=rc)

      if (rc < 0) then do;
        put "ERROR: " pid= "is not unique";
        stop;
      end;

      %hashSetData (next, tid)
      %hashSetData (next, amount)
    end;
  end;

%*-----;

  * summarize by trail;

  do key_addr = 1 to &hash_size;

    tid = %keyArray (start)(key_addr);

    * keyArray(tid)(key_addr) = . means no tid was ever hashed to key_addr;
    * but every tid was hashed, so . means there is
    * no tid that corresponds to key_addr and thus key_addr can be skipped;

    if tid eq . then continue;

    * sum amount while following the trail;

    total_amount = %dataArray (start,amount)(key_addr);
    ntids = 1;

    do until (tid=.);
      * check if tid is also pid;
      pid = tid;
      %hashFetch (next, rc=rc)
      if rc < 0 then leave;

      total_amount + %hashGetData (next, amount);
      ntids + 1;
      tid = %hashGetData (next, tid);
    end;

    output;

  end;

  stop;

  format tid pid z15.;
run;

options source;

proc sort data=trail_sums;
by descending ntids descending total_amount tid;
run;

ods html file="%sysfunc(pathname(WORK))/trail_sums.html" style=sasweb;
proc print label data=trail_sums (obs=100);
label
  tid='Most recent tid of trail'
  ntids='Number of transactions in trail'
;
run;
ods html close;

dm log 'top;find "ERROR:"' log;
/**/
