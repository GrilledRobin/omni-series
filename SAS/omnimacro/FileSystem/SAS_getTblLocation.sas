%macro SAS_getTblLocation(
	inDAT		=
	,outLOC		=	G_LOC
	,gMode		=	F
	,fDequote	=	0
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to get the absolute path name of the provided SAS dataset or VIEW.											|
|	|This can be called ANYWHERE in the program.																						|
|	|IMPORTANT: The search is based on physical file name hence please take the file extension into account.							|
|	|           This is only applicable for libraries using SAS Engine, despite of ODBC or other librefs.								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDAT		:	The dataset or VIEW to be searched.																					|
|	|outLOC		:	The location of the input dataset or VIEW.																			|
|	|gMode		:	Indicator of whether the macro is in Procedure Mode or Function Mode, [P] or [F].									|
|	|fDequote	:	Indicator of whether to dequote the output result, [0] or [1].														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20160508		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170623		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Use the function [QUOTE] to quote the output path name, rather than the original macro quoting method, to avoid unnecessary	|
|	|      | effort during other processes.																								|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170701		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Use [SUPERQ] to mask all references to the directory names, for there could be %nrstr(&) and %nrstr(%%) in the names.		|
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
|	| Date |	20180204		| Version |	2.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |[1] Translate the double-quotation marks to single-quotation marks and thus prevent any possible characters to be resolved	|
|	|      | from the absolute path as extracted, such as those characters lead by an ampersand.										|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180304		| Version |	2.30		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180401		| Version |	3.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the call of macro [getFILEbyStrPattern] with a more general macro [getMemberByStrPattern].							|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180407		| Version |	4.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |[1] Introduce the function [FS_ATTRC] to identify the library and the member name, rather than to process character string.	|
|	|      |    This enables the user to provide the Dataset Name with Dataset Options.													|
|	|      |[2] Remove the parameter [inTblType], since we can use above function to retrieve it.										|
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
|	|	|FS_ATTRC																														|
|	|	|FS_getPathList4Lib																												|
|	|	|getMemberByStrPattern																											|
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
%if	%length(%qsysfunc(compress(&inDAT.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No dataset is given for search! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%length(%qsysfunc(compress(&outLOC.,%str( ))))	=	0	%then	%let	outLOC		=	G_LOC;
%if	%qupcase(&gMode.)	^=	P	%then %do;
	%let	gMode	=	F;
%end;
%else %do;
	%let	gMode	=	P;
%end;
%if	&fDequote.	^=	0	%then %do;
	%let	fDequote	=	1;
%end;

%*013.	Define the local environment.;
%local
	inLIB
	DatName
	DatType
	DatExt
	Pi
;
%*Pi: for path.;
%let	inLIB	=	%FS_ATTRC( inDAT = &inDAT. , inATTR = LIB );
%let	DatName	=	%FS_ATTRC( inDAT = &inDAT. , inATTR = MEM );
%let	DatType	=	%FS_ATTRC( inDAT = &inDAT. , inATTR = MTYPE );

%if	&DatType.	^=	DATA	%then %do;
	%let	DatExt	=	sas7bvew;
%end;
%else %do;
	%let	DatExt	=	sas7bdat;
%end;

%global	&outLOC.;
%let	&outLOC.	=;

%*100.	Retrieve physical path of the given library.;
%FS_getPathList4Lib(
	inDSN		=	&inLIB.
	,outCNT		=	LnLibPath
	,outELpfx	=	LeLibPath
	,fDequote	=	1
)
%if	&LnLibPath.	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No physical path is found for given library: [&inLIB.].;
	%goto	PurgeMem;
%end;

%*200.	Search for the file in the physical paths.;
%do	Pi=1	%to	&LnLibPath.;
	%*100.	Search for files in current path.;
	%getMemberByStrPattern(
		inDIR		=	&&LeLibPath&Pi..
		,inRegExp	=	%nrbquote(^&DatName.\.&DatExt.$)
		,exclRegExp	=
		,chkType	=	1
		,FSubDir	=	0
		,outCNT		=	LnLibPath&Pi.Dat
		,outElNmPfx	=	LeLibPath&Pi.Dat
	)

	%*200.	As long as we find the file in any path, we skip the rest ones.;
	%if	&&LnLibPath&Pi.Dat.	^=	0	%then %do;
		%if	&fDequote.	=	0	%then %do;
			%let	&outLOC.	=	%sysfunc(quote(&&LeLibPath&Pi..,%str(%')));
		%end;
		%else %do;
			%let	&outLOC.	=	&&LeLibPath&Pi..;
		%end;

		%goto	OutLoc;
	%end;
%end;
%EndOfLoopPath:

%*300.	Purge the memory consumption.;

%*800.	Announcement.;

%*900.	Purge memory usage.;
%PurgeMem:
%*910.	Release PRX utilities.;
%ReleasePRX:

%*920.	Close the file reference.;
%ReleaseFR:

%*990.	Output the result if this macro is executed as Function.;
%OutLoc:
%if	&gMode.	=	F	%then %do;
	&&&outLOC..
%end;

%EndOfProc:
%mend SAS_getTblLocation;

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

%*050.	Setup a dummy macro [ErrMcr] to prevent the session to be bombed.;
%macro	ErrMcr;	%mend	ErrMcr;

%*100.	Create libraries.;
%let	G_LOC		=;
%let	HomePath	=	D:\SAS\omnimacro\AdvOp;

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

%*200.	Create datasets.;
data test2.a3;
	a	=	3;
run;

%*300.	Locate the dataset.;
%SAS_getTblLocation(
	inDAT		=	test2.a3
	,outLOC		=	G_LOC
	,gMode		=	P
	,fDequote	=	1
)
%put	G_LOC=[&G_LOC.];

%*400.	Simply put the absolute path to the log.;
data b /view=b;
	set test2.a3;
run;
%put	%SAS_getTblLocation( inDAT = %nrbquote(b(where=(a=1))) );

%*500.	Drop the temporary tables.;
proc datasets
	lib	=	test2
;
	delete	a3;
run;
quit;

/*-Notes- -End-*/