/*
 * Richard A. DeVenezia, 4/7/95
 *
 * Hunt out users who have a lock on a dataset and
 * stop their SAS processes from accessing the SAS server
 * Also, send them e-mail that they were stopped.
 *
 * mod
 *  5/22/95 rad Change all X commands to be filename PIPEs to
 *              ensure memory problems do not occur.
 *              (X forks with a full process copy, while filename PIPEs
 *              fork with a minimum process copy (see Observations 1st Q 1995.)
 *  5/17/99 rad add dfltsrvr and hostlist at top
 */

/*-----
 * group: Data management
 * purpose: Hunt down and stop users with a lock on the data set you must modify
 * notes: SAS/Share and UNIX.  Also contains %showuser and %stopuser.
 */


%* These must be filled in for your situation;
%let DFLTSRVR=HOST.SAS-SHARE-SERVICE-NAME;
%let HOSTLIST=HOST HOST2 HOST3 HOST4;        %* hosts from which users connect to Share server;

*******************************************************************************;
%macro showuser (USERID, SERVER=&DFLTSRVR);
  proc operate server=&SERVER;
    display user &USERID;
  run;
%mend;

*******************************************************************************;
%macro stopuser (USERID, UNIXID, DSN, SERVER=&DFLTSRVR);
  proc operate server=&SERVER;
    stop user &USERID;
  run;

  * now e-mail a message to the user who was stopped;
  *-----------------------------------------------------------;
  * find out if a list of mail addresses needs to be made;

  %local rc;
  %let rc=0;

  filename TEST pipe 'test -r /tmp/log-mail.address; echo $?';

  data _null_;
    infile TEST;
    input rc $;
    call symput ('rc', rc);
  run;

  filename TEST;

  %if &rc ^= 0 %then %do;
    %* do not have a mailing address file, need to create one;
    data _null_;
      * write a script, mail.who, to look at all the host cpus and users;
      * and create a user to mailing address cross-reference file,
      * mail.address;

      file '/tmp/log-mail.who';

      put 'echo getting addresses `date +%c` >> /tmp/log-getaddress.log';
      put "hosts=""&HOSTLIST""";
      put "for host in $hosts";
      put "do";
      put "  remsh $host cat /etc/passwd \";
      put "  | cut -d':' -f1 \";
      put "  | awk '{print $1"" ""$1""@xxxxxx""}' \";
      put "  | sed s/xxxxxx/$host/ \";
      put "  | grep -v '^\+' \";
      put "  | grep -v '^\#' \";
      put "  | grep -v uucp  \";
      put "  | grep -v lp    \";
      put "  | grep -v tftp  \";
      put " ";
      put "done";

      stop;
    run;

    %* run the script by using a filename pipe that is touched within
    %* a data null;

    filename GETADDR pipe
      'chmod +x /tmp/log-mail.who; /tmp/log-mail.who > /tmp/log-mail.address';

    data _null_;
      infile GETADDR;
      stop;
    run;

    filename GETADDR;
  %end;

  %* search the addresses for the user being stopped;

  %let UNIXID=%lowcase(&UNIXID);

  %* remove previous mail notification script;

  filename RMNOTIFY pipe
    'rm -f /tmp/log-notify';

  data _null_;
    infile RMNOTIFY;
    stop;
  run;

  filename RMNOTIFY;

  %* send a notification message to each unix acccount
  %* that apparently matches the user id returned by proc operate ;

  data _null_;

    infile "/tmp/log-mail.address" end=EOF;

    length unixid $40 mailaddr $100 ;

    do while ("&UNIXID" ^= unixid and not EOF);
      input unixid mailaddr;
    end;

    file '/tmp/log-stopmail.lst' mod;
    date=date();
    time=time();
    put date mmddyy8. +1 time time8. " stopuserid=&UNIXID " unixid= mailaddr=;
*   put _infile_;
*   put '---';

    file '/tmp/log-notify';

    if unixid = "&UNIXID" then do;
      put "echo ""You had &DSN open.";
      put "You were disconnected from SAS server '&SERVER'";
      put "so a data update could occur."" \";
      put "| mailx -s 'SAS server disconnect' " mailaddr;
      put ;
      put "echo ""&UNIXID stopped for &DSN at `date +" '%c' '`" \';
      put "| mailx -s '&UNIXID stopped for &DSN' root";
    end;

    stop;
  run;

  filename SENDMAIL pipe "chmod +x /tmp/log-notify; /tmp/log-notify";

  data _null_;
    infile SENDMAIL;
    stop;
  run;

  filename SENDMAIL;
%mend;

*******************************************************************************;
%macro huntstop (DSN, SERVER=&DFLTSRVR);

  %local LINESIZE NOTES MPRINT SOURCE CENTER LOG;

  data _null_;
    set SASHELP.VOPTION;
    if OPTNAME in ('LINESIZE' 'NOTES' 'MPRINT' 'SOURCE' 'CENTER') then
      call symput (OPTNAME, trim(SETTING));
  run;

  * Note: setting ls to less than 130 could result in improper parsing
  * of lock information output from lock statement and proc operate;

  options ls=130 nonotes nocenter ; *nomprint nosource;
  *options notes source mprint mlogic symbolgen;

  %let LIB=%upcase(%scan(&DSN,1,.));
  %let DS =%upcase(%scan(&DSN,2,.));

  *---------------------------------------------------------------------------;
  * stop any user that has a LOCK on the dataset (locked by LOCK statement);
  *---------------------------------------------------------------------------;
  * make a timestamp;

  data _null_;
    length t $6;
    t = compress (put (time(), time8.), ': ');
    if length(t) = 5 then t = '0' || t;

    call symput ('log', '/tmp/log-operate.log.'
                        || put (date(),yymmdd6.) || '_' || t);
  run;

  *---------------------------------------------------------------------------;
  * output lock list to log file;

  proc printto log="&log." new;
  run;

  LOCK &LIB..&DS LIST;

  proc printto log=log;
  run;

  *---------------------------------------------------------------------------;
  * parse log file for lock info, write stopuser macro invocation
  * to temporary file that is %included (call EXECUTE seemed to have
  * problems with scope);

  filename LOCK pipe "grep &LIB.\.&DS &log";
  filename STOPUSER '/tmp/log-stopuser.sas';

  data _null_;

    infile LOCK length=len;
      file STOPUSER;

    length line command $200 unixid $40;

    input line $varying. len;

    p = index (line, 'server connection');
    if p then do;
      * userid is the nnnnn part of SAS Share connection TINnnnnn.user;
      userid = scan (substr(line,p),3,' )');
      p = index (line, ' by');
      unixid = scan (substr(line,p),2);
      command = '%STOPUSER ('
              || trim(userid) || ','
              || trim(unixid) || ','
              || "&LIB..&DS,"
              || "server=&SERVER);";
      put command;
    end;
  run;

  %include STOPUSER;

  filename LOCK;
  filename STOPUSER;

  *---------------------------------------------------------------------------;
  * stop users that have locks on the dataset;
  * (locked by other than LOCK statement);
  *---------------------------------------------------------------------------;
  * make a timestamp;

  data _null_;
    length t $6;
    t = compress (put (time(), time8.), ': ');
    if length(t) = 5 then t = '0' || t;

    call symput ('log', '/tmp/log-operate.log.'
                        || put (date(),yymmdd6.) || '_' || t);
  run;

  *---------------------------------------------------------------------------;
  * output library list to log file (contains info about locked datasets);

  proc printto log="&log." new;
  run;

  proc operate server=&SERVER;
    display lib &LIB;
  run;

  proc printto log=log;
  run;

  *---------------------------------------------------------------------------;
  * parse log file for lock info;
  *---------------------------------------------------------------------------;
  * write an awk program to strip out the datasets portion of
  * proc operate display output;

  data _null_;
    file '/tmp/log-_lock_.awk';
    length beg_tag end_tag $200;
    beg_tag = """These data sets in library &LIB are active""";
    end_tag = """==========================""";
    put '{';
    put 'if (!ok && index($0,' beg_tag ')) ok=1;';
    put 'if (ok  && index($0,' end_tag ')) ok=0;';
    put 'if (ok) print $0';
    put '}';
  run;

  filename LOCK pipe "awk -f /tmp/log-_lock_.awk &log.";
  filename STOPUSER '/tmp/log-stopuser.sas';

  data _null_;

    infile LOCK missover;
      file STOPUSER;

    length member type status $8 userid unixid $50 openmode $8 libref $20;
    length command $200;

    input member type status userid openmode libref;

    retain doCheck 0;
    if member = '--------' then do;
      doCheck=1;
      return;
    end;
    if doCheck;
    if member = "&DS" and type = "DATA" then do;
      * stop user that has lock on dataset;
      * userid is formatted like TINnnnnn.user;
      * have to extract nnnnn part;
      unixid = scan (userid,2,'.');
      userid = scan (userid,1,'.');
      userid = substr (userid,4);
      command = '%STOPUSER ('
              || trim(userid) || ','
              || trim(unixid) || ','
              || "&LIB..&DS,"
              || "server=&SERVER);";
      put command;
    end;
  run;

  %include STOPUSER;

  filename LOCK;
  filename STOPUSER;

  filename CLEANUP pipe 'rm -f /tmp/log-_lock_.awk /tmp/log-stopuser.sas';
  filename CLEANUP pipe ' ';

  data _null_;
    infile CLEANUP;
    stop;
  run;

  filename CLEANUP;

  options LS=&LINESIZE &NOTES &MPRINT &SOURCE &CENTER;

%mend;
