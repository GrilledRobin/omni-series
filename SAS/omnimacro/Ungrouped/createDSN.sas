/* Richard A. DeVenezia
 * 12/16/00
 *
 * Programatically create an ODBC datasource to a Microsoft Access database
 * using Windows API function SQLConfigDataSource()
 */

/*-----
 * group: Data in
 * purpose: Programatically create an ODBC data source to a Microsoft Access database
 * notes: Will show up when you run ODBC Data Source Administrator control panel applet
 */

%macro createDSN ( mdb=, dsn=, tablesView= );

  %* mdb - path to .mdb file;
  %* dsn - ODBC data source name to create;
  %* tablesView - SAS view showing list of tables in data source;

  %local me;
  %let me = createDSN;

  %if (%superq(mdb) eq ) %then %do;
    %put ERROR: &me: mdb argument is missing.;
    %goto ByeBye;
  %end;

  %if (%superq(dsn) eq ) %then %do;
    %put ERROR: &me: dsn argument is missing.;
    %goto ByeBye;
  %end;

  %* check if moduleN interface exists ;

  %local hold_sascbtbl;
  %let hold_sascbtbl = %sysfunc (pathname (sascbtbl));

  %if (&hold_sascbtbl ne ) %then
    %put Warning: filename SASCBTBL should be reassigned to "&hold_sascbtbl";

  %local catalogEntry;
  %let catalogEntry = work.odbc.config.source;

  filename sascbtbl catalog "&catalogEntry";

  %if (not %sysfunc (cexist (&catalogEntry))) %then %do;
	  %*
	  %* Define moduleN interface to Windows API;
	  %*;

	  data _null_;
	    file sascbtbl ;
	    length routines $2000;
	    put "routine SQLConfigDataSource";
	    put "  minarg=4";
	    put "  maxarg=4";
	    put "  stackpop=called";
	    put "  module=ODBCCP32";
	    put "  returns=LONG";
	    put ";";
	    put ;
	    put "arg 1 num input byvalue format=pib4.;    * HWND hwndParent;";
	    put "arg 2 num input byvalue format=pib4.;    * UINT fRequest;";
	    put "arg 3 char input  format=$cstr200.;      * LPCSTR lpszDriver;";
	    put "arg 4 char input  format=$cstr200.;      * LPCSTR lpszAttributes;";
	    stop;
	  run;
  %end;

  %*
  %* Create the ODBC data source using Windows API;
  %*;

  %local success;
  %let success = 0;

  data _null_;
    driver = "Microsoft Access Driver (*.mdb)";
    attrs  =          "DSN=&dsn"
          || '00'x || "DBQ=&mdb"
          || '0000'x ;
    ;
    odbc_add_dsn = 1;
    rc = modulen ("SQLConfigDataSource", 0, odbc_add_dsn, driver, attrs);
    call symput ('success', put(rc,best12.));
  run;

  %if &success = 0 %then
    %put ERROR: &me: an error occurred with SQLConfigDataSource;
  %else %do;
    %if (%superq (tablesView) ne ) %then %do;

		  proc sql;
		      connect to ODBC (DSN=&dsn);
		      create view &tablesView as select * from connection to ODBC
		      ( ODBC::SQLTables (,,,"TABLE,VIEW") );
		      disconnect from ODBC;
		  quit;

    %end;

    %put NOTE: The tables in Access database &mdb can now be accessed through a LIBNAME:;
    %put %str(LIBNAME aLibname ODBC dsn=&dsn;);
/*  %put %str(LIBNAME aLibname ODBC complete="dsn=MS Access 97 Database;DriverId=25;DBQ=&mdb";); */
  %end;

  filename sascbtbl;

  %ByeBye:
%mend createDSN;

/*
%createDSN (mdb=c:\temp\test, dsn=test, tablesView=test_tables);
*/
