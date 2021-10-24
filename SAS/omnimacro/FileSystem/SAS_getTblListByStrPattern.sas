%macro SAS_getTblListByStrPattern(
	inLIB		=
	,inRegExp	=
	,exclRegExp	=
	,extRegExp	=	sas7bdat
	,outCNT		=	G_LstNO
	,outELpfx	=	G_LstEL
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to search for specific files under given library name by given matching rule with respect of				|
|	| Regular Expression.																												|
|	|This can be called ANYWHERE in the program, as the same as the 2 macros called here.												|
|	|There is a series of Global Macro Variables storing the absolute path of the files found in this process.							|
|	|PthTLstByStr&n.																													|
|	|IMPORTANT: The search is based on physical file name hence please take the file extension into account when setting up RX			|
|	|           This is only applicable for libraries using SAS Engine, despite of ODBC or other librefs.								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inLIB		:	Library name under which files should be searched.																	|
|	|inRegExp	:	Matching rule of character combination.																				|
|	|exclRegExp	:	Excluding rule of character combination.																			|
|	|extRegExp	:	Rule of File Extension.																								|
|	|outCNT		:	Number of files found in the library.																				|
|	|outELpfx	:	Prefix of macro variables, which will contain the found file names.													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20130817		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170701		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Add a reference to a predefined macro [OSDirDlm] to generate the directory name delimiter for current OS.					|
|	|      |Use [SUPERQ] to mask all references to the directory names, for there could be %nrstr(&) and %nrstr(%%) in the names.		|
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
|	| Date |	20180304		| Version |	1.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180401		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the call of macro [getFILEbyStrPattern] with a more general macro [getMemberByStrPattern].							|
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
|	|	|FS_getPathList4Lib																												|
|	|	|getMemberByStrPattern																											|
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
%if	%length(%qsysfunc(compress(&inLIB.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No Library is given for search of files! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%sysfunc(libref(&inLIB.))	^=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]Library [&inLIB.] is invalid! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%length(%qsysfunc(compress(&inRegExp.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No pattern is specified for file search, program will find all files in given library: [&inLIB.];
	%let	inRegExp	=	%nrbquote(.*);
%end;
%if	%length(%qsysfunc(compress(&extRegExp.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No pattern is specified for file extension, program will find all SAS Datasets in given library: [&inLIB.];
	%let	extRegExp	=	sas7bdat;
%end;
%if	%length(%qsysfunc(compress(&outCNT.,%str( ))))		=	0	%then	%let	outCNT		=	G_LstNO;
%if	%length(%qsysfunc(compress(&outELpfx.,%str( ))))	=	0	%then	%let	outELpfx	=	G_LstEL;

%*013.	Define the local environment.;
%local
	fChkExcl
	LfName
	prxIDV
	prxIDC
	Vi
	Vj
	Vf
	Pi
	tmpFName
;
%*prxIDV: for verification.;
%*prxIDC: for cut of file extension.;
%*Vi: for verification of file extension.;
%*Vj: for verification of the found result.;
%*Vf: Flag of that the same name has been found in previous iterations.;
%*Pi: for path.;
%let	fChkExcl	=	1;
%if	%length(%qsysfunc(compress(&exclRegExp.,%str( ))))	=	0	%then %do;
	%let	fChkExcl	=	0;
%end;
%let	prxIDV	=	%sysfunc(prxparse(/%nrbquote(^.*\.(&extRegExp.)$)/ismx));
%let	prxIDC	=	%sysfunc(prxparse(s/%nrbquote(^(.*)\.(&extRegExp.)$)/\1/ismx));

%global	&outCNT.;
%let	&outCNT.	=	0;

%*100.	Retrieve physical path of the given library.;
%FS_getPathList4Lib(
	inDSN		=	&inLIB.
	,outCNT		=	LnLibPath
	,outELpfx	=	LeLibPath
)
%if	&LnLibPath.	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No physical path is found for given library: [&inLIB.].;
	%goto	ReleasePRX;
%end;

%*200.	Search for files in the first physical path.;
%*210.	Find files of all extensions.;
%getMemberByStrPattern(
	inDIR		=	%qsysfunc(compress(&LeLibPath1.,%str(%'%")))
	,inRegExp	=	&inRegExp.
	,exclRegExp	=	&exclRegExp.
	,chkType	=	1
	,FSubDir	=	0
	,outCNT		=	LnLibPath1Dat
	,outElNmPfx	=	LeLibPath1Dat
)

%*250.	Limit the result within all required file extensions.;
%if	&LnLibPath1Dat.	^=	0	%then %do;
	%do	Vi=1	%to	&LnLibPath1Dat.;
		%let	LfName	=	&&LeLibPath1Dat&Vi..;
		%if	%sysfunc(prxmatch(&prxIDV.,&LfName.))	%then %do;
			%let	&outCNT.	=	%eval(&&&outCNT.. + 1);
			%global
				&outELpfx.&&&outCNT..
				PthTLstByStr&&&outCNT..
			;
			%let	&outELpfx.&&&outCNT..	=	%qsysfunc(prxchange(&prxIDC.,1,&LfName.));
			%let	PthTLstByStr&&&outCNT..	=	%qsysfunc(compress(&LeLibPath1.,%str(%'%")))%OSDirDlm&LfName.;
		%end;
	%end;
%end;

%*300.	Search for files in the rest physical paths if any.;
%*(1) This is to reduce the process effort, for most of the libraries only direct to one physical path.;
%*(2) This also suppresses the files of the same name to be listed in the output result, catering to ;
%*     the internal setting that only the one in the first physical path can be listed and processed ;
%*     if the library directs to two or more physical paths and meanwhile there are the same dataset ;
%*     names in these paths.;
%if	&LnLibPath.	^=	1	%then %do;
	%*100.	Loop the rest physical paths to search for files.;
	%do	Pi=2	%to	&LnLibPath.;
		%*100.	Search for files in current path.;
		%getMemberByStrPattern(
			inDIR		=	%qsysfunc(compress(&&LeLibPath&Pi..,%str(%'%")))
			,inRegExp	=	&inRegExp.
			,exclRegExp	=	&exclRegExp.
			,chkType	=	1
			,FSubDir	=	0
			,outCNT		=	LnLibPath&Pi.Dat
			,outElNmPfx	=	LeLibPath&Pi.Dat
		)

		%*200.	Limit the result within all required file extensions.;
		%if	&&LnLibPath&Pi.Dat.	^=	0	%then %do;
			%do	Vi=1	%to	&&LnLibPath&Pi.Dat.;
				%let	LfName	=	&&LeLibPath&Pi.Dat&Vi..;
				%if	%sysfunc(prxmatch(&prxIDV.,&LfName.))	%then %do;
					%*100.	Drop the result if there has been the same name located in previous iterations.;
					%let	tmpFName	=	%qsysfunc(prxchange(&prxIDC.,1,&LfName.));
					%let	Vf			=	0;
					%do	Vj=1	%to	&&&outCNT..;
						%if	%qupcase(&tmpFName.)	=	%qupcase(&&&outELpfx.&Vj..)	%then %do;
							%let	Vf	=	1;
						%end;
					%end;

					%*200.	Store the result if the name is found for the first time.;
					%if	&Vf.	=	0	%then %do;
						%let	&outCNT.	=	%eval(&&&outCNT.. + 1);
						%global
							&outELpfx.&&&outCNT..
							PthTLstByStr&&&outCNT..
						;
						%let	&outELpfx.&&&outCNT..	=	&tmpFName.;
						%let	PthTLstByStr&&&outCNT..	=	%qsysfunc(compress(&&LeLibPath&Pi..,%str(%'%")))%OSDirDlm&LfName.;
					%end;
				%end;
			%end;
		%end;
	%end;
	%EndOfLoopPath:
%end;

%*300.	Purge the memory consumption.;

%*800.	Announcement.;
%if	&&&outCNT..	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No file is found under given matching rule.;
%end;

%*900.	Purge memory usage.;
%*910.	Release PRX utilities.;
%ReleasePRX:
%syscall prxfree(prxIDV);
%syscall prxfree(prxIDC);

%*920.	Close the file reference.;
%ReleaseFR:

%EndOfProc:
%mend SAS_getTblListByStrPattern;

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

%*100.	Create libraries.;
%let	HomePath	=	D:\SAS\omnimacro\AdvOp;
libname	test	"&HomePath.\test";

%getMemberByStrPattern(
	inDIR		=	%nrbquote(&HomePath.)
	,inRegExp	=
	,exclRegExp	=
	,chkType	=	2
	,FSubDir	=	1
	,mNest		=	0
	,outCNT		=	GnDir
	,outELpfx	=	GeDir
	,outElTpPfx	=	GtDir
)
libname	test2	"&GeDir2.";
libname	full	(
	"&HomePath."
	test
	test2
);

%*200.	Create datasets.;
data full.a1;
	a	=	1;
run;
data test.a2;
	a	=	2;
run;
data test2.a3;
	a	=	3;
run;

%*300.	Find all datasets.;
%SAS_getTblListByStrPattern(
	inLIB		=	full
	,inRegExp	=
	,exclRegExp	=
	,extRegExp	=	sas7bdat
	,outCNT		=	GnDat
	,outELpfx	=	GeDat
)

%*400.	Set them together.;
%macro a;
%do i=1 %to &GnDat.;
	%put	PthTLstByStr&i.	=	[&&PthTLstByStr&i..];
%end;
data chk;
	set
	%do i=1 %to &GnDat.;
		full.&&GeDat&i..
	%end;
	;
run;
%mend a;
%a

%*500.	Drop the temporary tables.;
proc datasets
	lib	=	full
;
	delete	a:;
run;
quit;

/*-Notes- -End-*/