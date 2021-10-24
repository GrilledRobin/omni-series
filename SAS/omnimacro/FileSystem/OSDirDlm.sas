%macro OSDirDlm;
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to generate the directory name delimiter under different OS, such as WIN, z/OS or Unix.						|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20170701		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
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
	LosDlm
;

%*018.	Define the global environment.;

%*100.	Generate the directory name delimiter under different OS.;
%*110.	For Windows(R).;
%if	%upcase(&sysscp.)	=	WIN	%then %do;
	%let	LosDlm	=	\;
%end;

%*120.	For z/OS and OpenVMS.;
%else %if	%upcase(&sysscp.)	=	OS
	or	%upcase(&sysscpl.)	=	OPENVMS
	%then %do;
	%let	LosDlm	=	.;
%end;

%*130.	For UNIX.;
%else %if	%index(*AIX*HP-UX*LINUX*OSF1*SUNOS*,%upcase(*&sysscpl.*))	>	0
	%then %do;
	%let	LosDlm	=	/;
%end;

%*190.	Issue [e]rror message if none of above systems is identified.;
%else %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]Cannot identify the directory name delimiter under current OS!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*900.	Purge memory usage.;

%EndOfProc:
&LosDlm.
%mend OSDirDlm;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvOp"
		"D:\SAS\omnimacro\FileSystem"
	)
	mautosource
;

%*100.	Testing.;
%put	%OSDirDlm;

/*-Notes- -End-*/