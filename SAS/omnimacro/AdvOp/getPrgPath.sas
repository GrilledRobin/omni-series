%macro getPrgPath(
	inclFILE	=
	,outPATH	=
	,outFLNM	=
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to return the location of the program file that is being executed											|
|	|This macro is useful if we need to retrieve the physical location of current running program on the harddisk.						|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inclFILE	:	If the current program is included in current SAS session, please input its path here.								|
|	|outPATH	:	The output variable containing the full path of current program.													|
|	|outFLNM	:	The output variable containing the file name of current program.													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20120717		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180310		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*010.	Set parameters.;
%local	execpath;
%let	execpath	=;

%*100.	Generate path and file name.;
%if	%length(%qsysfunc(compress(&inclFILE.,%str( ))))	=	0	%then %do;
	%let	execpath	=	%sysfunc(getoption(sysin));
	%if	%length(&execpath)	=	0	%then	%let	execpath	=	%sysget(sas_execfilepath);
%end;
%else %do;
	%let	execpath	=	&inclFILE.;
%end;

%let	&outFLNM.	=	%qscan(&execpath.,-1,%str(\));
%let	&outPATH.	=	%qsubstr(&execpath.,1,%eval(%length(&execpath.)-%length(&&&outFLNM..)));
%mend getPrgPath;

/*
This macro is useful if we need to retrieve the physical location of current running program on the harddisk.
Problem not resolved:
1.	When using "%include" statement, the included program cannot be identified automatically.
*/

/*
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