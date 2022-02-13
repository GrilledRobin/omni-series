%macro winReg_QueryValue(key, name);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to query the value of [name] within the [key] of Windows Registry.											|
|	|It is useful to search for the installation path of any specific software on current Windows OS									|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|[QUOTE]																															|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|[1] https://blogs.sas.com/content/sasdummy/2012/05/22/windows-reg-query-from-sas/													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|key		:	The key to query in Windows Registry																				|
|	|name		:	The name t query within the [key]. Program seaches for the default value if it is not provided						|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20220212		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*010.	Check parameters.;
%*011.	Identify current processing macro.;
%local
	L_mcrLABEL
	Lohno
;
%let	L_mcrLABEL	=	&sysMacroName.;
%let	Lohno		=	%str(E)RROR: [&L_mcrLABEL.]Process failed due to %str(e)rrors!;

%*012.	Handle the parameter buffer.;

%*013.	Define the local environment.;
%local
	rstOut	reg_switch	reg_stmt	regref	rc	prx_ver	fileID_reg	str_query
;
%let	rstOut	=;

%*100.	Prepare the statement to query the Windows Registry;
%if	%length(%qsysfunc(compress(%superq(name),%str( ))))	=	0	%then %do;
	%let	reg_switch	=	/ve;
	%let	name		=	\(.+?\);
%end;
%else %do;
	%let	reg_switch	=	/v %qsysfunc(quote(%superq(key), %str(%")));
%end;
%let	reg_stmt	=	reg query %qsysfunc(quote(%superq(name), %str(%"))) &reg_switch.;

%*200.	Define the Regular Expression to filter the query result;
%let	prx_ver	=	%sysfunc(prxparse(s/^\s*%superq(name)\s{4}REG_\w+\s{4}(.+)\s*$/\1/ismx));

%*300.	Define the pipe connection to the query of Windows Registry.;
%*[IMPORTANT] Below PIPE connection requires the X-CMD privileges;
%let	regref	=	myreg;
%let	rc		=	%sysfunc(filename(regref, &reg_stmt., PIPE, lrecl = 32767));

%*500.	Retrieve the requested entries of Windows Registry.;
%*[IMPORTANT] We have to set the record length as 32767 again, beside the settings of the PIPE connection;
%let	fileID_reg	=	%sysfunc(fopen(&regref., s, 32767, v));
%do %while(%sysfunc(fread(&fileID_reg.)) = 0);
	%*100.	Retrieve current line;
	%*[IMPORTANT] We have to set the read the record in the length of 32767 in explicity;
	%let	rc	=	%sysfunc(fget(&fileID_reg., str_query, 32767));

	%*500.	Output the result only when current line matches the regular expression;
	%if	%sysfunc(prxmatch(&prx_ver., %superq(str_query)))	%then %do;
		%let	rstOut	=	%qsysfunc(prxchange(&prx_ver., 1, %superq(str_query)));
	%end;
%end;

%*990.	Purge.;
%let	rc	=	%sysfunc(fclose(&fileID_reg.));
%let	rc	=	%sysfunc(filename(regref));
%syscall	prxfree(prx_ver);

%EndOfProc:
&rstOut.
%mend winReg_QueryValue;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\FileSystem"
	)
	mautosource
;

%*100.	Retrieve the version of current Windows OS;
%*Quote: https://mivilisnet.wordpress.com/2020/02/04/how-to-find-the-windows-version-using-registry/ ;
%let	winver	=	%winReg_QueryValue(HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion, CurrentVersion);
%put	[&winver.];

/*-Notes- -End-*/