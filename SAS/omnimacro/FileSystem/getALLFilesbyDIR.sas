%macro getALLFilesbyDIR(
	inDIR		=
	,inNMKey	=
	,inEXT		=	_NONE_
	,procLIB	=	WORK
	,outTTL		=	G_FileALL
	,outEL		=	G_FLel
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is for the retrieval of every element within a specific folder.															|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDIR		:	The folder directory for process.																					|
|	|inNMKey	:	The Key characters of the file name to filter specific files.														|
|	|inEXT		:	The file extension to filter specific files.																		|
|	|procLIB	:	The default processing library.																						|
|	|outTTL		:	The total number of processed files.																				|
|	|outEL		:	The prefix of the output macro variables storing the name of the files.												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20140331		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180304		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
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
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|getOBS4DATA																													|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*001.	Check parameters.;
%local
	L_mcrLABEL
	L_fullname
	L_dot
	L_DIRcmd
;
%let	L_mcrLABEL	=	&sysMacroName.;
%if	%length(%qsysfunc(compress(&inEXT.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No folder is provided! Program skipped due to exceptions.;
	%goto	EndOfProc;
%end;
%if	&inEXT.	=	_NONE_	%then	%let	inEXT	=;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))	=	0	%then	%let	procLIB	=	WORK;
%if	%length(%qsysfunc(compress(&outTTL.,%str( ))))	=	0	%then	%let	outTTL	=	G_FileALL;
%if	%length(%qsysfunc(compress(&outEL.,%str( ))))	=	0	%then	%let	outEL	=	G_FLel;
%let	L_dot	=	.;
%if	%length(%qsysfunc(compress(&inEXT.,%str( ))))	=	0	%then	%let	L_dot	=;
%let	L_fullname	=	\%str(*)&inNMKey.%str(*)&L_dot.&inEXT.;

%*010.	Retrieve files.;
%*010.010.	Generate the command for DOS operation.;
data _NULL_;
	cmd	=	"'dir /B /A-D """||"&inDIR.&L_fullname."||'"''';
	call symput("L_DIRcmd",cmd);
run;

%*010.020.	Check the given log file.;
filename	dirPA	pipe	&L_DIRcmd.;

data &procLIB..__dir_for_procALL;
	infile
		dirPA
		truncover
	;
	input	line	$char256.;
	format	flnm	$512.;
	flnm	=	trim(left(line));
	keep flnm;
run;

%global	&outTTL.;
%let	&outTTL.	=	0;
%getOBS4DATA(
	inDAT	=	&procLIB..__dir_for_procALL
	,outVAR	=	&outTTL.
)

%if	&outTTL.	>	0	%then %do;
	data _NULL_;
		set &procLIB..__dir_for_procALL;
		call symputx(cats("&outEL.",_N_),flnm,"G");
	run;
%end;

%EndOfProc:
%mend getALLFilesbyDIR;