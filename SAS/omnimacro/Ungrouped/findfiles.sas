/* FindFiles for Windows
 * Richard A. DeVenezia, Oct 2002
 * http://www.devenezia.com
 */

/*-----
 * group: Data in
 * purpose: Obtain information about files: type, size, time modified, altname and owner.
 * notes: <U>Windows</U> only.<BR>This macro will do wildcard and recursive searching.<BR>Updated 11/03/02 to provide owner.
 */

options nosource nonotes;
filename FFAPI catalog 'WORK.FINDFILE.WINAPI.SOURCE';

data _null_;
  file FFAPI;
  input;
  put _infile_;
  cards4;
********************************************************************************
* FindFile.api
********************************************************************************
* Richard A. DeVenezia 4/20/98
********************************************************************************
* Define SAS Module function interfaces to functions in Windows kernel
* used to obtain filenames that match a search string containing wildcards * and ?
*
* You can only wildcard the last part of the path,
* I.e. C:\A\B\*.SAS is allowed, C:\*\B\*.SAS is not.
*
* The FindFirstFile interface is defined handle paths upto 260 characters,
* The FindFirstFile DLL by default accepts a string up to MAX_PATH (which is 260)
* characters.  Any length string will be accepted by FindFirstFileW if prepended
* with \\?\
*
* FindFirstFile and FindNextFile return file information into a buffer that must
* be large enough to contain a LPWIN32_FIND_DATA structure, which is currently
* 320 bytes long
*
* The filename part of the structure, under Windows NT, is MAX_PATH (260) bytes
* Note: Using Explorer NT I could only create a filename with a total path length
*       of 254 characters
*       I.e. root level directory whose name is 245 characters long could only
*            contain a file with a name 5 or less characters long.
*            C:\<245 char dirname>\<5 char filename>, total length 254.
*            Maybe assume implicit dot at end of names, takes it up to 256.
*
*  Why MAX_PATH is 260 I do not know.
********************************************************************************
;

********************************************************************************
* Auxilliary Information
********************************************************************************
* from Winnt.h - File Attributes
*#define FILE_ATTRIBUTE_READONLY         0x00000001
*#define FILE_ATTRIBUTE_HIDDEN           0x00000002
*#define FILE_ATTRIBUTE_SYSTEM           0x00000004
*#define FILE_ATTRIBUTE_DIRECTORY        0x00000010
*#define FILE_ATTRIBUTE_ARCHIVE          0x00000020
*#define FILE_ATTRIBUTE_NORMAL           0x00000080
*#define FILE_ATTRIBUTE_TEMPORARY        0x00000100
*#define FILE_ATTRIBUTE_COMPRESSED       0x00000800
********************************************************************************
;

*------------------------------------------------------------------------------;
ROUTINE FindFirstFileA
        minarg=11
        maxarg=11
        stackpop=called
        module=Kernel32
        returns=long;

  arg  1 char input           format=$cstr260.; * LPCTSTR  lpFileName,               // address of name of file to search for ;
                                                * LPWIN32_FIND_DATA  lpFindFileData  // address of returned information ;
  arg  2 num  output fdstart  format=pib4.;     *   DWORD dwFileAttributes ;
  arg  3 num  output          format=pib8.;     *   FILETIME ftCreationTime ;
  arg  4 num  output          format=pib8.;     *   FILETIME ftLastAccessTime ;
  arg  5 num  output          format=pib8.;     *   FILETIME ftLastWriteTime ;
  arg  6 num  output          format=pib4.;     *   DWORD    nFileSizeHigh ;
  arg  7 num  output          format=pib4.;     *   DWORD    nFileSizeLow ;
  arg  8 num  output          format=pib4.;     *   DWORD    dwReserved0 ;
  arg  9 num  output          format=pib4.;     *   DWORD    dwReserved1 ;
  arg 10 char output          format=$CHAR260.; *   TCHAR    cFileName[ MAX_PATH ] ;
  arg 11 char output          format=$CSTR14.;  *   TCHAR    cfilename_altFileName[ 14 ] ;

*------------------------------------------------------------------------------;
ROUTINE FindNextFileA
        minarg=11
        maxarg=11
        stackpop=called
        module=Kernel32
        returns=long;

  arg  1 num  input  byvalue format=pib4.;      * HANDLE  hFindFile,                // handle of search ;
                                                * LPWIN32_FIND_DATA  lpFindFileData // address of structure for data on found file;
  arg  2 num  output fdstart format=pib4.;      *   DWORD dwFileAttributes ;
  arg  3 num  output         format=pib8.;      *   FILETIME ftCreationTime ;
  arg  4 num  output         format=pib8.;      *   FILETIME ftLastAccessTime ;
  arg  5 num  output         format=pib8.;      *   FILETIME ftLastWriteTime ;
  arg  6 num  output         format=pib4.;      *   DWORD    nFileSizeHigh ;
  arg  7 num  output         format=pib4.;      *   DWORD    nFileSizeLow ;
  arg  8 num  output         format=pib4.;      *   DWORD    dwReserved0 ;
  arg  9 num  output         format=pib4.;      *   DWORD    dwReserved1 ;
  arg 10 char output         format=$CHAR260.;  *   TCHAR    cFileName[ MAX_PATH ] ;
  arg 11 char output         format=$CSTR14.;   *   TCHAR    cfilename_altFileName[ 14 ] ;

*------------------------------------------------------------------------------;
ROUTINE FindClose
        minarg=1
        maxarg=1
        stackpop=called
        module=Kernel32
        returns=long;

  arg  1 num  input  byvalue format=pib4.;      * HANDLE  hFindFile  // file search handle ;

*------------------------------------------------------------------------------;
ROUTINE FileTimeToLocalFileTime
        minarg=2
        maxarg=2
        stackpop=called
        module=Kernel32
        returns=long;

  arg  1 num  input          format=pib8.;      * CONST FILETIME *  lpFileTime,  // pointer to UTC file time to convert ;
  arg  2 num  output         format=pib8.;      * LPFILETIME  lpLocalFileTime    // pointer to converted file time ;

*------------------------------------------------------------------------------;
ROUTINE FileTimeToSystemTime
        minarg=9
        maxarg=9
        stackpop=called
        module=Kernel32
        returns=long;

  arg  1 num  input          format=pib8.;      * CONST FILETIME *  lpFileTime,   // pointer to file time to convert ;
                                                * LPSYSTEMTIME  lpSystemTime      // pointer to structure to receive system time ;
  arg  2 num  output fdstart format=pib2.;      *   WORD wYear ;
  arg  3 num  output         format=pib2.;      *   WORD wMonth ;
  arg  4 num  output         format=pib2.;      *   WORD wDayOfWeek ;
  arg  5 num  output         format=pib2.;      *   WORD wDay ;
  arg  6 num  output         format=pib2.;      *   WORD wHour ;
  arg  7 num  output         format=pib2.;      *   WORD wMinute ;
  arg  8 num  output         format=pib2.;      *   WORD wSecond ;
  arg  9 num  output         format=pib2.;      *   WORD wMilliseconds ;

*------------------------------------------------------------------------------;
ROUTINE
  GetFileSecurityA
  MODULE=advapi32
  MINARG=5
  MAXARG=5
  STACKPOP=CALLED
  RETURNS=LONG
;
arg 1 NUM         BYVALUE FORMAT=IB4.;      * lpFileName;
arg 2 NUM         BYVALUE FORMAT=IB4.;      * RequestedInformation;
arg 3 NUM         BYVALUE FORMAT=IB4.;      * pSecurityDescriptor;
arg 4 NUM         BYVALUE FORMAT=IB4.;      * nLength;
arg 5 NUM                 FORMAT=IB4.;      * lpnLengthNeeded;

*------------------------------------------------------------------------------;
ROUTINE
  GetSecurityDescriptorOwner
  MODULE=advapi32
  MINARG=3
  MAXARG=3
  STACKPOP=CALLED
  RETURNS=LONG
;
arg 1 NUM BYVALUE FORMAT=IB4. ; * pSecurityDescriptor ;
arg 2 NUM         FORMAT=IB4. ; * pOwner;
arg 3 NUM         FORMAT=IB4. ; * lpbOwnerDefaulted;

*------------------------------------------------------------------------------;
ROUTINE
  LookupAccountSidA
  MODULE=advapi32
  MINARG=7
  MAXARG=7
  STACKPOP=CALLED
  RETURNS=LONG
;
arg 1 BYVALUE FORMAT=IB4. ; * lpSystemName;
arg 2 BYVALUE FORMAT=IB4. ; * Sid;
arg 3 BYVALUE FORMAT=IB4. ; * Name;
arg 4 BYADDR  FORMAT=IB4. ; * cbName;
arg 5 BYVALUE FORMAT=IB4. ; * ReferencedDomainName;
arg 6 BYADDR  FORMAT=IB4. ; * cbReferencedDomainName ;
arg 7 BYADDR  FORMAT=IB4. ; * peUse;
;;;;
run;

filename FFAPI;
options notes;

%macro findfiles (
    path=
  , filespec=*
  , out=
  , recurse=N
  , getOwner=N
  , sdBuffLen=100
  , nameBuffLen=100
  , domainBuffLen=100
  )
  / des='Find Files';

  %* FindFiles for Windows
  %* Richard A. DeVenezia, Oct 2002
  %* http://www.devenezia.com
  %* 11/03/02 RAD Add getOwner option
  %*
  %* This macro performs a Data step;

  %local this mprint;

  %let this = findfiles;
  %let mprint = %sysfunc (getOption(MPRINT));
  %let recurse = %upcase (&recurse);

  %if &mprint = MPRINT %then options nomprint; ;

  %if &recurse ne Y and &recurse ne N %then %do;
    %put ERROR: &this: recurse must be N or Y.;
    %goto EndMacro;
  %end;

  %if &getOwner ne Y and &getOwner ne N %then %do;
    %put ERROR: &this: getOwner must be N or Y.;
    %goto EndMacro;
  %end;

  %if %quote(&filespec) = %str () %then %do;
    %put ERROR: &this: File specification is missing.;
    %goto EndMacro;
  %end;

  %if %quote(&out) = %str () %then %do;
    %put ERROR: &this: Output dataset name is missing.;
    %goto EndMacro;
  %end;

  %if %quote(&path) = %str() %then %do;
    %local p;
    %let path = %sysfunc(reverse (&filespec));
    %let p = %sysfunc (indexc (&path, :, \));
    %if &p %then %do;
      %let filespec = %sysfunc(reverse(%substr(&path,1,%eval(&p-1))));
      %let path = %sysfunc(reverse(%substr(&path,%eval(&p))));
    %end;
    %else
      %let path = .\;
  %end;

  %local mycbpath cbpath;
  %let mycbpath = WORK.FINDFILE.WINAPI.SOURCE;
  %let cbpath = %sysfunc (pathname(SASCBTBL));

  %if %sysfunc (fileref(SASCBTBL)) <= 0 and %quote(&cbpath) ne %quote(&mycbpath) %then %do;
    %* The robust thing would be to concatenate my API definitions,
    %* or store the prior SASCBTBL fileref and replace it with mine
    %* and on completion of macro restore the original SASCBTBL;
    %put WARNING: &this: Fileref SASCBTBL changed to point to WORK.FINDFILE.WINAPI.SOURCE;
    %put WARNING: &this: SASCBTBL had pointed to %sysfunc (pathname(SASCBTBL));
  %end;
  filename SASCBTBL catalog 'WORK.FINDFILE.WINAPI.SOURCE';

  data &out ;

    %if &recurse = Y %then %do;
    array path_[0:50] $200 _temporary_;
    array handle_[0:50] 8 _temporary_;
    retain rIndex 0;
    %end;

    retain
      path
      filename_out
      %if &getOwner = Y %then
      owner
      ;
      filetype
      filename_alt
      filesize
      fmod
    ;

    length filespec path filename_out $260 filetype $9;
    length filename_alt $14;

    %if &getOwner = Y %then
    length owner $&nameBuffLen;
    ;

    retain
      handle p
      fattr created accessed modified sizeh sizel reserve0 reserve1 lmod
      filesize fmod finfo
      year month dow day h m s ms rc
    0 ;

    path = %sysfunc(quote(&PATH));
    filespec = trim(path) || %sysfunc(quote(&FILESPEC));

    %if &recurse = Y %then %do;
Find:
    nFolders + 1;
    %end;

    filename_out = repeat (' ', 259);
    filename_alt = repeat (' ', 13);

    handle = modulen ("FindFirstFileA", filespec,
                      fattr, created, accessed, modified, sizeH, sizeL,
                      reserve0, reserve1, filename_out, filename_alt);

    if handle ne -1 then do;

      do until (0 eq modulen ("FindNextFileA", handle,
                              fattr, created, accessed, modified, sizeH, sizeL,
                              reserve0, reserve1, filename_out, filename_alt)
               );

        p = index (filename_out, '00'x);
        if p then filename_out = substr(filename_out,1,p-1);

        if (band (fattr, 10x))
          then filetype='Directory';
          else filetype='File';

        if filename_alt = "" then
          filename_alt = filename_out;

        filesize = 0ffffffffx * sizeH + sizeL;

        rc = modulen ("FileTimeToLocalFileTime", modified, lmod);
        rc = modulen ("FileTimeToSystemTime",
                      lmod,year,month,dow,day,h,m,s,ms);
        fmod = dhms ( mdy (month,day,year), h,m,s ) + ms/1000;

        if filename_out not in ('.' '..') then do;
%if &getOwner = Y %then %do;
          link GetOwner;
%end;
          OUTPUT;
        end;

        filename_out = repeat (' ', 259);
        filename_alt = repeat (' ', 13);
      end;
      handle = modulen ("FindClose", handle);
    end;

    %if &recurse = Y %then %do;

    rIndex + 1;
    path_[rIndex] = path;

    filespec = trim(path) || '*';

    filename_out = repeat (' ', 259);
    filename_alt = repeat (' ', 13);

    handle_[rIndex] = modulen ("FindFirstFileA", filespec,
                      fattr, created, accessed, modified, sizeH, sizeL,
                      reserve0, reserve1, filename_out, filename_alt);

    if handle_[rIndex] ne -1 then do;

      do until (0 eq modulen ("FindNextFileA", handle_[rIndex],
                              fattr, created, accessed, modified, sizeH, sizeL,
                              reserve0, reserve1, filename_out, filename_alt)
               );

        p = index (filename_out, '00'x);
        if p then filename_out = substr(filename_out,1,p-1);

        if filename_out not in ('.' '..') and (band (fattr, 10x)) then
        do;
          path = trim(path) || trim(filename_out) || "\";
          filespec =  trim(path) || %sysfunc(quote(&FILESPEC));

          goto Find;
rIndexR: ;
          path = path_[rIndex];
        end;

        filename_out = repeat (' ', 259);
        filename_alt = repeat (' ', 13);
      end;
      handle_[rIndex] = modulen ("FindClose", handle_[rIndex]);
    end;

    rIndex + (-1);
    if rIndex then goto rIndexR;

    if getOption ('NOTES') = 'NOTES' then
      put "NOTE: &this: " nFolders "folders were searched.";

    %end; %* recurse=Y;

    stop;

%if &getOwner = Y %then %do;
GetOwner:
    array sdBuff [&sdBuffLen] $1 _temporary_;

    * determine how bytes needed to hold security info;
    fullname = trim (path) || trim (filename_out) || "00"x;

    sdSize=0;
    rc = modulen ("GetFileSecurityA", addr(fullname), 01x, addr(sdBuff[1]), sdSize, sdSize);
    if sdSize = 0 then do;
      put "ERROR: &this: GetFileSecurity had an error.";
      stop;
    end;

    if &sdBuffLen < sdSize then do;
      put "ERROR: &this: SD buffer length is &sdBuffLen, need " sdSize;
      stop;
    end;

    rc = modulen ("GetFileSecurityA", addr(fullname), 01x, addr(sdBuff[1]), sdSize, sdSize);
    if rc = 0 then do;
      put "ERROR: &this: GetFileSecurity had an error.";
      stop;
    end;

    pOwner = 0;
    flag = 0;
    rc = modulen ("GetSecurityDescriptorOwner", addr(sdBuff[1]), pOwner, flag);

    if rc = 0 then do;
      put "ERROR: &this: GetSecurityDescriptorOwner had an error.";
      stop;
    end;

    length owner $&nameBuffLen;
    length domain $&domainBuffLen;

    system = "00"x;
    owner = "00"x;
    name_len = 0;
    domain = "00"x;
    domain_len = 0;
    use = 0;

    rc = modulen ( "LookupAccountSidA", addr(system), pOwner, addr(owner), name_len, addr(domain), domain_len, use);

    if &nameBuffLen < name_len then do;
      put "ERROR: &this: Owner name buffer length is &nameBuffLen, need " name_len;
      stop;
    end;

    if &domainBuffLen < domain_len then do;
      put "ERROR: &this: Name buffer length is &domainBuffLen, need " domain_len;
      stop;
    end;

    rc = modulen ( "LookupAccountSidA", addr(system), pOwner, addr(owner), name_len, addr(domain), domain_len, use);

    domain = compress (domain, '00'x);
    owner = compress (owner, '00'x);
  return;
%end; %* GetOwner;

    keep
      path
      filename_out
      %if &getOwner = Y %then
      owner
      ;
      filetype
      filename_alt
      filesize
      fmod
    ;
    format
      fmod datetime16.
      filesize comma15.
    ;
    informat
      fmod datetime16.
      filesize comma15.
    ;
    rename
      filename_out = name
      filetype = type
      filename_alt = altname
      filesize = size
      fmod = modified
    ;
  run;

  %EndMacro:

  %if &mprint = MPRINT %then options mprint; ;

%mend findfiles;

options source;

/*
%findfiles (out=rad, filespec=c:\winnt\*.ini, getOwner=Y);
%findfiles (out=rad, filespec=c:\php\*.ini);
*/
