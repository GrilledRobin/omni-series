%macro FS_WhereIsThisPgm;
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to search for the physical path of current EXECUTING program.												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20130704		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170810		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Use [SUPERQ] to mask all references to the directory names, for there could be %nrstr(&) and %nrstr(%%) in the names.		|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180304		| Version |	2.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Prerequisites:																														|
|	|(1) All programs which need to call this macro should be involved in '%include' statement when in batch mode.						|
|	|(2) All programs which need to call this macro should be SAVED to harddisk at first.												|
|	|(3) This macro should be called at the very FIRST LINE in the program.																|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*010.	Check parameters.;
%global	G_PathOfExecPgm;
%let	G_PathOfExecPgm	=;

%local	LchkSYSIN;
%let	LchkSYSIN	=;

%*100.	Retrieve the path.;
%*SYSIN: The system option is blank if the program is executing in interactive window mode, otherwise batch mode.;
%let	LchkSYSIN	=	%qsysfunc(getoption(SYSIN));
%if	%length(%qsysfunc(compress(&LchkSYSIN.,%str( ))))	=	0	%then %do;
	%let	G_PathOfExecPgm	=	%qsysfunc(sysget(SAS_EXECFILEPATH));
%end;
%else %do;
	proc sql
		outobs=1
		nowarn
		noprint
	;
		select	trim(left(xpath))
		into	:G_PathOfExecPgm
		from dictionary.extfiles
		where fileref eqt '#LN'
		order by fileref descending;
	quit;
%end;

%*Make sure the value of the variable does not contain trailing blanks.;
%let	G_PathOfExecPgm	=	%qsysfunc(strip(%superq(G_PathOfExecPgm)));

%EndOfProc:
%mend FS_WhereIsThisPgm;

/*
Original topic at SAS(R) forum:
From: data_null_

Call this macro as the first line in each INCLUDED file.  When you use the quoted filename syntax in your
%INC 'program.sas';  SAS creates a FILEREF using the #LNnnnnnn naming convention.
It SHOULD be the fileref with the largest value each time.
Then you can query dictionary.extfiles for the LAST one created.
The example creates a macro variable but I suppose you could SET SAS_EXECFILEPATH if you wanted to.
%macro whereAmI(arg); 
   %global includePath;
   %let includePath=;
   proc sql outobs=1 nowarn;
      select xpath into :includePath
         from dictionary.extfiles
         where fileref eqt '#LN'
         order by fileref descending;
      quit;
      run;
   %put INCLUDEPATH=&includepath;
   %mend whereAmI; 
An alternative that would be better would be to write a macro to "replace" %INC.  %XINC perhaps.
The macro would find the full path of the quoted file name and create a macro variable or SET an enviornment variable and then %INC the file.
The INCed could use the info as needed.

Another practice:

proc sql noprint;
	select
		substr(xpath,1,length(xpath)-length(scan(xpath,-1,"\")))
		,scan(xpath,-1,"\")
	into
		:prgpath
		,:prgname
	from dictionary.extfiles
	where	(		substr(fileref,1,3)='_LN'
				or	substr(fileref,1,3)='#LN'
				or	substr(fileref,1,3)='SYS'
			)
		and	index(upcase(xpath),'.SAS')>0
	;
quit;
*/