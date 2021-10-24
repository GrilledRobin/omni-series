%macro getMemberByStrPattern(
	inDIR		=
	,inRegExp	=	%nrbquote(.*)
	,exclRegExp	=
	,chkType	=	1
	,FSubDir	=	0
	,mNest		=	0
	,outCNT		=	G_LstNO
	,outELpfx	=	G_LstEL
	,outElTpPfx	=	G_LstTP
	,outElPPfx	=	G_LstPth
	,outElNmPfx	=	G_LstNm
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to search for specific files or sub-folders under given folder name by given matching rule with respect of	|
|	| Regular Expression.																												|
|	|The switch [FSubDir] is intended to define whether to search for ALL sub-directories by infinite recursion.						|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDIR		:	Directory name under which files or sub-directories should be searched.												|
|	|inRegExp	:	Matching rule of character combination.																				|
|	|exclRegExp	:	Excluding rule of character combination.																			|
|	|chkType	:	0 - both files and directories, 1 - files, 2 - directories.															|
|	|FSubDir	:	0 - find members in current directory, 1 - search in all sub-directories.											|
|	|mNest		:	[M]th Level of Nesting Call of the same macro, which is zero at the first call.										|
|	|outCNT		:	Number of members found in the folder.																				|
|	|outELpfx	:	Prefix of macro variables, which will contain the full names of the members (including path name).					|
|	|outElTpPfx	:	Prefix of macro variables, which will contain the types of the members. The values of these macro variables are:	|
|	|				 [F]: File																											|
|	|				 [D]: Directory																										|
|	|outElPPfx	:	Prefix of macro variables, which will contain the full paths of the members (excluding file name).					|
|	|outElNmPfx	:	Prefix of macro variables, which will contain the names of the members (excluding path name).						|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20161023		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20161217		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Fix a bug when LIBNAME function engages with XLSX file and automatically defines it as a valid library.						|
|	|      |Use [V9] to restrict the libname to be verified as a directory.																|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170616		| Version |	1.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |LIBNAME function in V9.4 has a change on the sequence of its parameters hence we have to re-arrange the options and replace	|
|	|      | the option [V9] with a general one [BASE].																					|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170624		| Version |	1.30		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Add extra output macro variables to store the paths and file names separately.												|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170701		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the LIBNAME function by a predefined macro [isDir] during the identification process.								|
|	|      |Add a reference to a predefined macro [OSDirDlm] to generate the directory name delimiter for current OS.					|
|	|      |Use [SUPERQ] to mask all references to the member names, for there could be %nrstr(&) and %nrstr(%%) in the names.			|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170810		| Version |	2.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Minimize the use of [SUPERQ] to avoid the excession of macro-quoting layers.												|
|	|      |Concept:																													|
|	|      |If some value is macro-quoted, its quoting status will be inherited to all the subsequent references unless it is modified	|
|	|      | by another macro function (adding additional characters before or after it will have no effect, e.g. [aa&bb.cc]).			|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180304		| Version |	2.20		| Updater/Creator |	Lu Robin Bin												|
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
|	|	|getMemberByStrPattern																											|
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
%if	%length(%qsysfunc(compress(&inDIR.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No Folder is given for search of files! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%length(%qsysfunc(compress(&inRegExp.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No pattern is specified for file search, program will find all files in given folder: [&inDIR.];
	%let	inRegExp	=	%nrbquote(.*);
%end;
%let	chkType	=	%qsubstr(&chkType.,1,1);
%if		&chkType.	^=	0
	and	&chkType.	^=	1
	and	&chkType.	^=	2
	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No type is specified. Program will search for files instead of directories.;
	%let	chkType		=	1;
%end;
%if	&FSubDir.	^=	1	%then	%let	FSubDir		=	0;
%if	%length(%qsysfunc(compress(&mNest.,%str( ))))		=	0	%then	%let	mNest		=	0;
%if	%length(%qsysfunc(compress(&outCNT.,%str( ))))		=	0	%then	%let	outCNT		=	G_LstNO;
%if	%length(%qsysfunc(compress(&outELpfx.,%str( ))))	=	0	%then	%let	outELpfx	=	G_LstEL;
%if	%length(%qsysfunc(compress(&outElTpPfx.,%str( ))))	=	0	%then	%let	outElTpPfx	=	G_LstTP;
%if	%length(%qsysfunc(compress(&outElPPfx.,%str( ))))	=	0	%then	%let	outElPPfx	=	G_LstPth;
%if	%length(%qsysfunc(compress(&outElNmPfx.,%str( ))))	=	0	%then	%let	outElNmPfx	=	G_LstNm;

%*013.	Define the local environment.;
%local
	fELisFdr
	fChkExcl
	LprxIN&mNest.
	LprxXL&mNest.
	chkFDRxt
	LFdrRef
	LFdrID
	LnMem
	LfName
	Fi
	Fj
	LFdrRC
	NextL
;
%let	fChkExcl	=	1;
%if	%length(%qsysfunc(compress(&exclRegExp.,%str( ))))	=	0	%then %do;
	%let	fChkExcl	=	0;
%end;
%let	LFdrRef	=	GmDir&mNest.;
%let	NextL	=	%eval(&mNest. + 1);

%global	&outCNT.;
%let	&outCNT.	=	0;

%*050.	Check folder existence.;
%let	chkFDRxt	=	1;
%let	chkFDRxt	=	%sysfunc(fileexist(&inDIR.));
%if	&chkFDRxt.	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Given folder [&inDIR.] does not exist!.;
	%goto	EndOfProc;
%end;

%*100.	Extract the information from the given folder.;
%*110.	Create file reference for the given folder.;
%let	LFdrRC	=	%sysfunc(filename(LFdrRef,&inDIR.));

%*120.	Open the file reference.;
%let	LFdrID	=	%sysfunc(dopen(&LFdrRef.));
%if	&LFdrID.	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]The given folder [&inDIR.] cannot be accessed!.;
	%goto	ReleaseFR;
%end;

%*130.	Retrieve the number of members in the given folder.;
%let	LnMem	=	%sysfunc(dnum(&LFdrID.));
%if	&LnMem.	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]There is no file or directory in the given folder [&inDIR.]!.;
	%goto	ReleaseFR;
%end;

%*200.	Retrieve the file names.;
%*210.	Prepare the Perl Regular Expression for pattern match.;
%let	LprxIN&mNest.	=	%sysfunc(prxparse(/&inRegExp./ismx));
%let	LprxXL&mNest.	=	%sysfunc(prxparse(/&exclRegExp./ismx));

%*220.	Match the pattern.;
%do	Fi=1	%to	&LnMem.;
	%*100.	Determine the file name.;
	%let	LfName	=	%qsysfunc(dread(&LFdrID.,&Fi.));

	%*200.	Differentiate the files and directories.;
	%let	fELisFdr	=	%isDir(&inDIR.%OSDirDlm&LfName.);

	%*300.	Nesting search if current member is a directory, given the switch [FSubDir] is on.;
	%if		&FSubDir.	=	1
		and	&fELisFdr.	=	1
		%then %do;
		%*100.	Search for the child-members in the directory as current member.;
		%*We call the same macro recursively at this step.;
		%getMemberByStrPattern(
			inDIR		=	&inDIR.%OSDirDlm&LfName.
			,inRegExp	=	&inRegExp.
			,exclRegExp	=	&exclRegExp.
			,chkType	=	&chkType.
			,FSubDir	=	&FSubDir.
			,mNest		=	&NextL.
			,outCNT		=	TnGMBSP&NextL.
			,outELpfx	=	TeGMBSP&NextL._
			,outElTpPfx	=	TtGMBSP&NextL._
			,outElPPfx	=	TpGMBSP&NextL._
			,outElNmPfx	=	TmGMBSP&NextL._
		)

		%*500.	Add up to the overall outputs.;
		%if	&&TnGMBSP&NextL..	^=	0	%then %do;
			%do Fj=1	%to	&&TnGMBSP&NextL..;
				%let	&outCNT.	=	%eval(&&&outCNT.. + 1);
				%global
					&outELpfx.&&&outCNT..
					&outElTpPfx.&&&outCNT..
					&outElPPfx.&&&outCNT..
					&outElNmPfx.&&&outCNT..
				;
				%let	&outELpfx.&&&outCNT..	=	&&TeGMBSP&NextL._&Fj..;
				%let	&outElTpPfx.&&&outCNT..	=	&&TtGMBSP&NextL._&Fj..;
				%let	&outElPPfx.&&&outCNT..	=	&&TpGMBSP&NextL._&Fj..;
				%let	&outElNmPfx.&&&outCNT..	=	&&TmGMBSP&NextL._&Fj..;
			%end;
		%end;
	%end;

	%*500.	Different approaches for current member.;
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

	%*600.	Verify the exclusion.;
	%if	&fChkExcl.	=	1	%then %do;
		%if	%sysfunc(prxmatch(&&LprxXL&mNest..,&LfName.))	%then %do;
			%goto	EndOfIteration;
		%end;
	%end;

	%*700.	Verify the match.;
	%if	%sysfunc(prxmatch(&&LprxIN&mNest..,&LfName.))	%then %do;
		%let	&outCNT.	=	%eval(&&&outCNT.. + 1);
		%global
			&outELpfx.&&&outCNT..
			&outElTpPfx.&&&outCNT..
			&outElPPfx.&&&outCNT..
			&outElNmPfx.&&&outCNT..
		;
		%let	&outELpfx.&&&outCNT..	=	&inDIR.%OSDirDlm&LfName.;
		%let	&outElTpPfx.&&&outCNT..	=	%sysfunc(ifc(&fELisFdr.=1,D,F));
		%let	&outElPPfx.&&&outCNT..	=	&inDIR.;
		%let	&outElNmPfx.&&&outCNT..	=	&LfName.;
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
%syscall prxfree(LprxIN&mNest.);
%syscall prxfree(LprxXL&mNest.);

%*920.	Close the file reference.;
%ReleaseFR:
%let	LFdrRC	=	%sysfunc(dclose(&LFdrID.));

%EndOfProc:
%mend getMemberByStrPattern;

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

%*100.	Find the directories or files containing the given name ".sas".;
%getMemberByStrPattern(
	inDIR		=	%nrbquote(D:\SAS\omnimacro\AdvOp)
	,inRegExp	=	%nrstr(\.sas\s*$)
	,exclRegExp	=
	,chkType	=	0
	,FSubDir	=	1
	,mNest		=	0
	,outCNT		=	GnDir
	,outELpfx	=	GeDir
	,outElTpPfx	=	GtDir
	,outElPPfx	=	GpDir
	,outElNmPfx	=	GmDir
)

%macro a;
%do i=1 %to &GnDir.;
	%put	[GeDir&i.=&&GeDir&i..][GtDir&i.=&&GtDir&i..];
%end;
%do i=1 %to &GnDir.;
	%put	[GpDir&i.=&&GpDir&i..][GmDir&i.=&&GmDir&i..];
%end;
%mend a;
%a

%*200.	Find all the sub-directories.;
%let	fdr	=	AdvOp;
%getMemberByStrPattern(
	inDIR		=	%nrbquote(D:\SAS\omnimacro\&fdr.)
	,inRegExp	=
	,exclRegExp	=
	,chkType	=	2
	,FSubDir	=	1
	,mNest		=	0
	,outCNT		=	GnDir
	,outELpfx	=	GeDir
	,outElTpPfx	=	GtDir
)

%macro a;
%do i=1 %to &GnDir.;
	%put	[GeDir&i.=&&GeDir&i..][GtDir&i.=&&GtDir&i..];
%end;
%mend a;
%a

%*300.	Find all the directories or files.;
%getMemberByStrPattern(
	inDIR		=	%nrbquote(D:\SAS\omnimacro\AdvOp)
	,inRegExp	=
	,exclRegExp	=
	,chkType	=	0
	,FSubDir	=	1
	,mNest		=	0
	,outCNT		=	GnDir
	,outELpfx	=	GeDir
	,outElTpPfx	=	GtDir
	,outElPPfx	=	GpDir
	,outElNmPfx	=	GmDir
)

%macro a;
%do i=1 %to &GnDir.;
	%put	[GeDir&i.=&&GeDir&i..][GtDir&i.=&&GtDir&i..];
%end;
%do i=1 %to &GnDir.;
	%put	[GpDir&i.=&&GpDir&i..][GmDir&i.=&&GmDir&i..];
%end;
%mend a;
%a

/*-Notes- -End-*/