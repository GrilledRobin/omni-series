%macro FS_ChangeHdrForTextFile(
	inTXTfile	=
	,inDataLine	=	2
	,inHDRfile	=
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to change the header line (usually the first line) of the given plain text file with another.				|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inTXTfile	:	Input plain text file.																								|
|	|inDataLine	:	The first data line of the given file, default is 2.																|
|	|inHDRfile	:	The plain text file which contains the new line(s) as the header replacement.										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20131114		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20140412		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Slightly enhance the program efficiency.																					|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180304		| Version |	1.20		| Updater/Creator |	Lu Robin Bin												|
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
|	|	|ErrMcr																															|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*010.	Set parameters.;
%*011.	Identify current processing macro.;
%local
	L_mcrLABEL
	Lohno
;
%let	L_mcrLABEL	=	&sysMacroName.;
%let	Lohno		=	%str(E)RROR: [&L_mcrLABEL.]Process failed due to %str(e)rrors!;

%*012.	Handle the parameter buffer.;
%if	%length(%qsysfunc(compress(&inTXTfile.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No file is specified to change header.;
	%goto	EndOfProc;
%end;
%if	%length(%qsysfunc(compress(&inDataLine.,%str( ))))	=	0	%then %do;
	%let	inDataLine		=	2;
%end;
%if	%length(%qsysfunc(compress(&inHDRfile.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No header file is provided. The original file remains unmodified.;
	%goto	EndOfProc;
%end;

%*013.	Define the local environment.;
%local
	lpath
	lfile
	lext
	ltmpf
;

%*014.	Remove quotation marks from the given file names.;
%let	inTXTfile	=	%qsysfunc(compress(&inTXTfile.,%str(%"%')));
%let	inHDRfile	=	%qsysfunc(compress(&inHDRfile.,%str(%"%')));

%*015.	File system check.;
%if	%sysfunc(fileexist(&inTXTfile.))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]Original file does not exist! [&inTXTfile.].;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%sysfunc(fileexist(&inHDRfile.))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]Header file does not exist! [&inHDRfile.].;
	%put	&Lohno.;
	%ErrMcr
%end;

%*100.	Retrieve the input file detailed information.;
%let	lfile	=	%qscan(&inTXTfile.,-1,%str(\));
%let	lext	=	%qscan(&lfile.,-1,%str(.));
%let	lpath	=	%qsubstr(&inTXTfile.,1,%eval(%length(&inTXTfile.)-%length(&lfile.)));
%let	ltmpf	=	&lpath._chg_.&lext.;

%*200.	Change file header.;
%sysexec	copy /Y %qsysfunc(quote(&inHDRfile.)) %qsysfunc(quote(&ltmpf.)) & exit;
data _NULL_;
	infile
		%sysfunc(quote(&inTXTfile.,%str(%')))
		FIRSTOBS	=	&inDataLine.
		lrecl		=	32767
	;
	input;
	file
		%sysfunc(quote(&ltmpf.,%str(%')))
		lrecl	=	32767
		MOD
	;
	put _infile_;
run;

%*300.	Replace the original file by the changed one.;
%sysexec	copy /Y %qsysfunc(quote(&ltmpf.)) %qsysfunc(quote(&inTXTfile.)) & exit;

%*900.	Remove the interim file.;
%sysexec	del /Q %qsysfunc(quote(&ltmpf.)) & exit;

%EndOfProc:
%mend FS_ChangeHdrForTextFile;