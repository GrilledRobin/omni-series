%macro ifn ( logical , true , false , missing ) ;
%*----------------------------------------------------------------------
  replicates the release 9 ifn() function.
  if called in release 9, it uses ifn() function. otherwise, it
  resorts to numeric-char-numeric trick to mimic what ifn() does

  note 1:
    it is strongly recommended to put the arguments within a
    pair of parentheses, e.g. female = %ifn( (sex="F"), 1, 0)
  note 2:
    as with ifn() function, when there is no fourth parameter,
    specified, then it returns the false choicee when logical
    is evaluated to a missing value
  reference:
    Chung and Whitlock (2006) "%IFN - A Macro Function." Paper 042-31 
    in the Proceedings of the Thirty-First SAS Users Group International
    (SUGI31). San Francisco. 
  written: 
    by chang y. chung and ian whitlock on aug. 2005
  last modified: 
    by chang y. chung on mar. 2006 
      improved precision by utilizing rb8. (in)format instead of best12.
---------------------------------------------------------------------* ;

  %local list choice retvalue msg ;

%*-------------------------------------------------------------------* ;
%*-- first three parameters are required                           --* ;

  %let retvalue = . ;

  %if ( %superq ( logical ) = %str() ) %then
    %let msg = Logical-expression ;

  %if ( %superq ( true ) = %str() ) %then
  %do ;
    %if ( %superq ( msg ) ^= %str() ) %then
      %let msg = &msg, ;
    %let msg = &msg Value-returned-when-true ;
  %end ;

  %if ( %superq ( false ) = %str() ) %then
  %do ;
    %if ( %superq ( msg ) ^= %str() ) %then
      %let msg = &msg, ;
    %let msg = &msg Value-returned-when-false ;
  %end ;

  %if ( %superq ( msg ) ^= %str() ) %then %goto retrn ;

  %if ( %superq ( missing ) = %str() ) %then
    %let missing = &false ;

%*-------------------------------------------------------------------* ;
%*-- if release 9 or later and not forced to do the conversions,   --* ;
%*--   then just call the ifn() function                           --* ;
  %if %sysevalf( &sysver >= 9.0 ) %then
    %let retvalue =
      ifn ( ( &logical ) , ( &true ) , ( &false ) , ( &missing ) )
   ;

%*-------------------------------------------------------------------* ;
%*-- if release 8 or ealier, then use the numeric-char-numeric     --* ;
%*-- trick to mimic what ifn() does                                --* ;
  %else
  %do ;

    %let list = put ( ( &true    ) , rb8. )
             || put ( ( &false   ) , rb8. )
             || put ( ( &missing ) , rb8. ) ;
    %let choice = 1 + 8 * ( ( &logical ) = 0 )
                    + 8 * missing ( &logical ) ;
    %let retvalue = input ( substr ( &list , &choice , 8 ) , rb8. ) ;

  %end ;

%*-------------------------------------------------------------------* ;
%*-- if error, then return a missing, set _ERROR_ to 1             --* ;
%retrn:
  %if ( %superq ( msg ) ^= %str() ) %then
    %put ERROR: (ifn) Missing required parameter(s): &msg.. ;

  &retvalue

%mend ifn ;
