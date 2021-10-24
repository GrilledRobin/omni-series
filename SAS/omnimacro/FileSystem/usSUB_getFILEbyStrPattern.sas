%macro usSUB_getFILEbyStrPattern;
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to search for specific files under given folder name by given matching rule with respect of					|
|	| Regular Expression.																												|
|	|The function is defined by PCmp Procedure, so its scope is limited by FCmp Procedure.												|
|	|IMPORTANT:																															|
|	|[1] It was previously designed as a FUNCTION instead of a SUBROUTINE, but once called during DATA step, the FUNCTION causes the	|
|	|  SAS session to freeze when the provided [inFDR] does not exist, even if it is forced to return a missing value in the definition.|
|	|  That is why we have to create a SUBROUTINE instead.																				|
|	|[2] It is tested that the SUBROUTINE cannot generate any result when called in [%SYSCALL] statement, which is quite weird.			|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inFDR		:	Folder name under which files should be searched.																	|
|	|inRegExp	:	Matching rule of character combination.																				|
|	|exclRegExp	:	Excluding rule of character combination.																			|
|	|chkType	:	0 - both files and directories, 1 - files, 2 - directories.															|
|	|Delims		:	The delimiter to connect the output results																			|
|	|OSDirDlm	:	The delimiter to connect the member name to its parent directory under current O/S									|
|	|Result		:	The result during the search with all items concatenated by the [Delims]											|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20181105		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Result:	[Character]																												|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|[<dir1>[Delims]<dir2>...]	:	The members found by the function, which are connected by the provided delimiters					|
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

%*100.	Function that identifies whether the provided date value is Workday in terms of the given Calendar data.;
subroutine
	getFILEbyStrPattern(
		inFDR		$
		,inRegExp	$
		,exclRegExp	$
		,chkType
		,Delims		$
		,OSDirDlm	$
		,Result		$
	)
;
	%*020.	Verify parameters.;
	outargs	Result;
	call missing(Result);
	if	missing(chkType)	then	goto	EndOfSub;

	%*050.	Declare internal fields.;
	attrib
		FdrRef	length=$8	FdrID	length=8	nFile	length=8	memI	length=8	fname	length=$512	fELisFdr	length=8
		tmpf	length=8
	;
	FdrRef	=	"MacRef";

	%*100.	Open the dedicated location.;
	if	fileexist( inFDR )	=	0	then	goto	EndOfSub;
	_iorc_	=	filename( FdrRef , inFDR );
	FdrID	=	dopen( FdrRef );
	if	FdrID	<=	0	then	goto	EndOfSub;

	%*200.	Roll over all members in the directory to determine the match of the criteria.;
	nFile	=	dnum( FdrID );
	do memI = 1 to nFile;
		%*100.	Verify whether current member is a File or a Directory.;
		fname		=	dread( FdrID , memI );
		tmpf		=	mopen( FdrID , fname );
		fELisFdr	=	if tmpf <= 0 then 1 else 0;
		_iorc_		=	fclose( tmpf );

		%*200.	Skip the current member if its type does not match the required criteria.;
		if	chkType	=	1	then do;
			if	fELisFdr	=	1	then do;
				goto	EndOfIter;
			end;
		end;
		else if	chkType	=	2	then do;
			if	fELisFdr	=	0	then do;
				goto	EndOfIter;
			end;
		end;

		%*300.	Skip the current member if it matches the [Exclusion criteria].;
		if	missing(exclRegExp)	=	0	then do;
			if	prxmatch( cats( "/" , exclRegExp , "/ismx" ) , fname )	then do;
				goto	EndOfIter;
			end;
		end;

		%*400.	Find the match of the criteria.;
		if	prxmatch( cats( "/" , ifc( missing(inRegExp) , ".*" , inRegExp ) , "/ismx" ) , fname )	then do;
			Result	=	catx(
							ifc( missing(Delims) , "|" , strip(Delims) )
							, Result
							, catx(
								strip(OSDirDlm)
								, dinfo( FdrID , doptname( FdrID , 1 ) )
								, fname
							)
						)
			;
		end;

		%*900.	Mark the end of current iteration.;
		EndOfIter:
	end;

	%*500.	Close the directory.;
	_iorc_	=	dclose( FdrID );
	_iorc_	=	filename( FdrRef );

%*700.	Finish the definition of the function.;
EndOfSub:
endsub;

%*900.	Purge memory usage.;

%EndOfProc:
%mend usSUB_getFILEbyStrPattern;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\FileSystem"
	)
	mautosource
;

%*090.	This step ensures there is no WARNING message issued when executing the FCmp Procedure.;
options
	cmplib=_NULL_
;

%*100.	Compile the function as defined in the macro.;
proc FCmp
	outlib=work.fso.FileSystem
;

	%usSUB_getFILEbyStrPattern

run;
quit;

%*300.	Tell the program where to find the compiled functions.;
options
	cmplib=work.fso
;

%*400.	Call the function to retrieve the files within the respective criteria.;
data aa;
	length
		c_dir	$512
		c_fil	$64
	;
	c_dir	=	"D:\SAS\omnimacro\FileSystem";
	c_fil	=	"usFUN_.+\.sas";
	output;
	c_dir	=	"D:\SAS\omnimacro\AdvOp";
	c_fil	=	"get.+\.sas";
	output;
run;
data bb;
	set aa;
	length	files	file_name	$32767;
	call	missing( files , file_name );
	call	getFILEbyStrPattern( c_dir , c_fil , "" , 1 , "|" , "%OSDirDlm" , files );
	cnt		=	count( files , "|" ) + 1;
	do i = 1 to cnt;
		file_name	=	scan( files , i , "|" );
		output;
	end;
	drop
		files cnt i
	;
run;

%*500.	Call the function to retrieve the files within the respective criteria in Macro Facility.;
%global	inDIR RXin RXex outTyp dlms osdlm outRst;
%let	inDIR	=	%str(D:\SAS\omnimacro\AdvDB);
%let	RXin	=	%str(toInf);
%let	RXex	=	mrg;
%let	outTyp	=	1;
%let	dlms	=	%str(|);
%let	osdlm	=	%OSDirDlm;
%let	outRst	=;
%syscall
	getFILEbyStrPattern(
		inDIR
		, RXin
		, RXex
		, outTyp
		, dlms
		, osdlm
		, outRst
	)
;
%put	outRst=[&outRst.];

/*-Notes- -End-*/