%macro getFILEbyStrPattern(
	inFDR		=
	,inRegExp	=
	,exclRegExp	=
	,chkType	=	1
	,outCNT		=	G_LstNO
	,outELpfx	=	G_LstEL
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to search for specific files under given folder name by given matching rule with respect of					|
|	| Regular Expression.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inFDR		:	Folder name under which files should be searched.																	|
|	|inRegExp	:	Matching rule of character combination.																				|
|	|exclRegExp	:	Excluding rule of character combination.																			|
|	|chkType	:	0 - both files and directories, 1 - files, 2 - directories.															|
|	|outCNT		:	Number of files found in the folder.																				|
|	|outELpfx	:	Prefix of macro variables, which will contain the found file names.													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20130426		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20130502		| Version |	1.01		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Added check point of folder existence.																						|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20130516		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Modify the matching rule to Case Insensitive on behalf of the convention.													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20130527		| Version |	1.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Minimize the RAM consumption.																								|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20130725		| Version |	1.21		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace "symput" with "symputx" to reduce coding effort.																	|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20131004		| Version |	1.22		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Fix the bug for reporting error on "Filename" statmement when the directory is improperly given.							|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20140412		| Version |	1.30		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Slightly enhance the program efficiency.																					|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20140812		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the execution of Data Step by Macro Facility to enable the flexibility to call the macro,							|
|	|      | add the verification of DIRECTORY or FILE.																					|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20140817		| Version |	2.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |It is found that the trick of "fileexist" cannot work under WinVista.														|
|	|      | Hence we use "libname" to trick the file verification until we find it inappropriate later.								|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20150908		| Version |	2.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Fix the grammar issue when implemented in LINUX environment (Slash or Backslash).											|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20161208		| Version |	2.30		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Fix a bug when LIBNAME function engages with XLSX file and automatically defines it as a valid library.						|
|	|      |Use [V9] to restrict the libname to be verified as a directory.																|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170616		| Version |	2.40		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |LIBNAME function in V9.4 has a change on the sequence of its parameters hence we have to re-arrange the options and replace	|
|	|      | the option [V9] with a general one [BASE].																					|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170701		| Version |	2.50		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the LIBNAME function by a predefined macro [isDir] during the identification process.								|
|	|      |Add a reference to a predefined macro [OSDirDlm] to generate the directory name delimiter for current OS.					|
|	|      |Use [SUPERQ] to mask all references to the member names, for there could be %nrstr(&) and %nrstr(%%) in the names.			|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170810		| Version |	2.60		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Minimize the use of [SUPERQ] to avoid the excession of macro-quoting layers.												|
|	|      |Concept:																													|
|	|      |If some value is macro-quoted, its quoting status will be inherited to all the subsequent references unless it is modified	|
|	|      | by another macro function (adding additional characters before or after it will have no effect, e.g. [aa&bb.cc]).			|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180304		| Version |	2.70		| Updater/Creator |	Lu Robin Bin												|
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
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\FileSystem"																						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|isDir																															|
|	|	|OSDirDlm																														|
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
%if	%length(%qsysfunc(compress(&inFDR.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No Folder is given for search of files! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%length(%qsysfunc(compress(&inRegExp.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No pattern is specified for file search, program will find all files in given folder: [&inFDR.];
	%let	inRegExp	=	%nrbquote(.*);
%end;
%if		&chkType.	^=	0
	and	&chkType.	^=	1
	and	&chkType.	^=	2
	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No type is specified. Program will search for files instead of directories.;
	%let	chkType		=	1;
%end;
%if	%length(%qsysfunc(compress(&outCNT.,%str( ))))		=	0	%then	%let	outCNT		=	G_LstNO;
%if	%length(%qsysfunc(compress(&outELpfx.,%str( ))))	=	0	%then	%let	outELpfx	=	G_LstEL;

%*013.	Define the local environment.;
%local
	fELisFdr
	fChkExcl
	LprxIN
	LprxXL
	chkFDRxt
	LFdrRef
	LFdrID
	LnFile
	LfName
	Fi
	LFdrRC
;
%let	fChkExcl	=	1;
%if	%length(%qsysfunc(compress(&exclRegExp.,%str( ))))	=	0	%then %do;
	%let	fChkExcl	=	0;
%end;
%let	LFdrRef	=	dirPtn;

%global	&outCNT.;
%let	&outCNT.	=	0;

%*050.	Check folder existence.;
%let	chkFDRxt	=	1;
%let	chkFDRxt	=	%sysfunc(fileexist(&inFDR.));
%if	&chkFDRxt.	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Given folder [&inFDR.] does not exist!.;
	%goto	EndOfProc;
%end;

%*100.	Extract the information from the given folder.;
%*110.	Create file reference for the given folder.;
%let	LFdrRC	=	%sysfunc(filename(LFdrRef,&inFDR.));

%*120.	Open the file reference.;
%let	LFdrID	=	%sysfunc(dopen(&LFdrRef.));
%if	&LFdrID.	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]The given folder [&inFDR.] cannot be accessed!.;
	%goto	ReleaseFR;
%end;

%*130.	Retrieve the number of files in the given folder.;
%let	LnFile	=	%sysfunc(dnum(&LFdrID.));
%if	&LnFile.	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]There is no file or directory in the given folder [&inFDR.]!.;
	%goto	ReleaseFR;
%end;

%*200.	Retrieve the file names.;
%*210.	Prepare the Perl Regular Expression for pattern match.;
%let	LprxIN	=	%sysfunc(prxparse(/&inRegExp./ismx));
%let	LprxXL	=	%sysfunc(prxparse(/&exclRegExp./ismx));

%*220.	Match the pattern.;
%do	Fi=1	%to	&LnFile.;
	%*100.	Determine the file name.;
	%let	LfName	=	%qsysfunc(dread(&LFdrID.,&Fi.));

	%*200.	Differentiate the files and directories.;
	%*210.	Flag the element on the attribute.;
	%let	fELisFdr	=	%isDir(&inFDR.%OSDirDlm&LfName.);

	%*220.	Different approaches.;
	%if	&chkType.	=	1	%then %do;
		%*Operation when it is desired to search for files.;
		%if	&fELisFdr.	=	1	%then %do;
			%goto	EndOfIteration;
		%end;
	%end;
	%else %if	&chkType.	=	2	%then %do;
		%*Operation when it is desired to search for directories.;
		%if	&fELisFdr.	=	0	%then %do;
			%goto	EndOfIteration;
		%end;
	%end;

	%*300.	Verify the exclusion.;
	%if	&fChkExcl.	=	1	%then %do;
		%if	%sysfunc(prxmatch(&LprxXL.,&LfName.))	%then %do;
			%goto	EndOfIteration;
		%end;
	%end;

	%*400.	Verify the match.;
	%if	%sysfunc(prxmatch(&LprxIN.,&LfName.))	%then %do;
		%let	&outCNT.	=	%eval(&&&outCNT.. + 1);
		%global	&outELpfx.&&&outCNT..;
		%let	&outELpfx.&&&outCNT..	=	&LfName.;
	%end;

	%*900.	End of current iteration.;
	%EndOfIteration:
%end;
%EndOfLoopFile:

%*300.	Purge the memory consumption.;

%*800.	Announcement.;
%if	&&&outCNT..	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No file or directory is found under given matching rule.;
%end;

%*900.	Purge memory usage.;
%*910.	Release PRX utilities.;
%ReleasePRX:
%syscall prxfree(LprxIN);
%syscall prxfree(LprxXL);

%*920.	Close the file reference.;
%ReleaseFR:
%let	LFdrRC	=	%sysfunc(dclose(&LFdrID.));

%EndOfProc:
%mend getFILEbyStrPattern;

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

%*100.	Get all SAS program files from the provided folder.;
%getFILEbyStrPattern(
	inFDR		=	%nrbquote(D:\SAS\omnimacro\AdvOp)
	,inRegExp	=	%nrstr(\.sas\s*$)
	,exclRegExp	=
	,chkType	=	1
	,outCNT		=	GnFile
	,outELpfx	=	GeFile
)
%macro a;
%do i=1 %to &GnFile.;
	%put	GeFile&i.=[&&GeFile&i..];
%end;
%mend a;
%a

%*200.	Get all subdirectories in the provided folder.;
%let	fdr	=	AdvOp;
%getFILEbyStrPattern(
	inFDR		=	%nrbquote(D:\SAS\omnimacro\&fdr.)
	,inRegExp	=
	,exclRegExp	=
	,chkType	=	2
	,outCNT		=	GnDir
	,outELpfx	=	GeDir
)
%macro a;
%do i=1 %to &GnDir.;
	%put	GeDir&i.=[&&GeDir&i..];
%end;
%mend a;
%a

/*-Notes- -End-*/