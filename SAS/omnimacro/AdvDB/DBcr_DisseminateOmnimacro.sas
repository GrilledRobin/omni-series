%macro DBcr_DisseminateOmnimacro(
	cdwmac		=
	,DataDic	=
	,SheetFunc	=	%str(Function$)
	,PkgFor		=
	,OutRoot	=
	,procLIB	=	WORK
	,fDebug		=	0
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to copy the required pack of macros for the destination project to the specified directory.					|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|cdwmac		:	The directory in which the [omnimacro] folder resides.																|
|	|DataDic	:	The data dictionary in EXCEL format for [cdwmac].																	|
|	|SheetFunc	:	The sheet to describe the functions in the data dictionary [DataDic].												|
|	|				Default: [Function$]																								|
|	|PkgFor		:	The project name for which to retrieve the necessary pack of macros.												|
|	|				There should ONLY be alphabets within the provided character string.												|
|	|OutRoot	:	The directory for the pack of macros to be copied to.																|
|	|procLIB	:	The processing library.																								|
|	|				Default: [WORK]																										|
|	|fDebug		:	The switch of Debug Mode. Valid values are [0] or [1].																|
|	|				Default: [0]																										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20180310		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Please find the attachments for examples.																							|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|The parameter [PkgFor] should be the SAME as [PjtName] in the header field [Launch for <PjtName>] in the sheet [Function] of the	|
|	| provided [DataDic].																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ErrMcr																															|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\FileSystem"																						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|FS_VarExists																													|
|	|	|OSDirDlm																														|
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
%let	procLIB	=	%unquote(&procLIB.);

%if	%length(%qsysfunc(compress(&cdwmac.,%str( ))))		=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]The parameter [cdwmac] is NOT provided!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%length(%qsysfunc(compress(&PkgFor.,%str( ))))		=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]The parameter [PkgFor] is NOT provided!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%qsysfunc(compress(&PkgFor.,%str(a),ak))	^=	&PkgFor.	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]The project name [PkgFor] SHOULD ONLY contain alphabets! [&PkgFor.] is NOT accepted!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%length(%qsysfunc(compress(&OutRoot.,%str( ))))		=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]The parameter [OutRoot] is NOT provided!;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&SheetFunc.,%str( ))))	=	0	%then	%let	SheetFunc	=	%str(Function$);
%if	%qsubstr(&SheetFunc.,%length(&SheetFunc.),1)		^=	$	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Sheet name does not contain the trailing character [$].;
	%let	SheetFunc	=	&SheetFunc.$;
%end;
%if	%length(%qsysfunc(compress(&DataDic.,%str( ))))		=	0	%then	%let	DataDic		=	%qsysfunc(catx( %OSDirDlm , &cdwmac. , %str(Instruction.xlsx) ));
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))		=	0	%then	%let	procLIB		=	WORK;
%if	%length(%qsysfunc(compress(&fDebug.,%str( ))))		=	0	%then	%let	fDebug		=	0;
%if	&fDebug.^=	0	%then	%let	fDebug		=	1;

%*013.	Define the local environment.;
%local
	PjtFld
	BatFile
;
%let	PjtFld	=	Launch_for_&PkgFor.;
%let	BatFile	=	%qsysfunc(catx( %OSDirDlm , %qsysfunc(pathname(WORK)) , %str(CopyMac.bat) ));

%*018.	Define the global environment.;

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in traditional SAS syntax colors.;
%macro dummy; %mend dummy;

%*020.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*All input values.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [cdwmac=&cdwmac.].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [DataDic=&DataDic.].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [SheetFunc=&SheetFunc.].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [PkgFor=&PkgFor.].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [OutRoot=&OutRoot.].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [procLIB=&procLIB.].;
%end;

%*100.	Import the data dictionary.;
PROC IMPORT
	OUT			=	&procLIB..__DisOM_DataDic
	DATAFILE	=	%sysfunc(quote(&DataDic.,%str(%')))
	DBMS		=	EXCEL
	REPLACE
;
	SHEET		=	%sysfunc(quote(%superq(SheetFunc),%str(%')));
	GETNAMES	=	YES;
	MIXED		=	YES;
	SCANTEXT	=	YES;
	USEDATE		=	YES;
	SCANTIME	=	YES;
RUN;

%*200.	Determine the field to identify the pack of macros by the provided [PkgFor].;
%if	%FS_VarExists( inDAT = &procLIB..__DisOM_DataDic , inFLD = &PjtFld. )	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]There is no pack of macros for the specified project. Skip the program.;
	%goto	EndOfProc;
%end;

%*300.	Retrieve all required macros for current project [PkgFor] to prepare for copying.;
data &procLIB..__DisOM_MacFiles;
	%*010.	Set the source data.;
	set
		&procLIB..__DisOM_DataDic(
			where=(
					&PjtFld.	=	1
				and	Begin_Date	<=	today()	<=	End_Date
			)
		)
		end=EOF
	;

	%*050.	Create new fields.;
	length
		Location_Fr	$512
		Location_To	$512
		File_Fr		$1024
		Mac_Exist	3
		System_CMD	$2048
		Log_Message	$2048
	;

	%*100.	Translate the file location.;
	Location_Fr	=	tranwrd( Function_Location , "<HomePath>" , cats(%sysfunc(quote(&cdwmac.,%str(%')))) );
	Location_To	=	tranwrd( Function_Location , "<HomePath>" , cats(%sysfunc(quote(&OutRoot.,%str(%')))) );
	File_Fr		=	catx( %sysfunc(quote(%OSDirDlm,%str(%'))) , Location_Fr , File_Name );
	Mac_Exist	=	fileexist(strip(File_Fr));
	call missing( System_CMD , Log_Message );

	%*200.	Open the BAT file for programming.;
	file	%sysfunc(quote(&BatFile.,%str(%')));

	%*500.	Copy the files.;
	if	Mac_Exist	=	0	then do;
		Log_Message	=	cats( "W" , "ARNING: [&L_mcrLABEL.]File [" , File_Fr , "] does not exist!" );
		putlog	Log_Message;
	end;
	else do;
		System_CMD	=	catx( " " , "echo d|" , "xcopy" , quote(strip(File_Fr)) , quote(strip(Location_To)) , "/Y /C /D" );
		put	System_CMD;
	end;

	%*900.	Close the file once finishing the copying.;
	if	EOF	then do;
		put	"exit";
	end;
run;

%*399.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*All input values.;
	%put	%str(I)NFO: [&L_mcrLABEL.]BAT program is saved as: [&BatFile.].;
	%put	%str(I)NFO: [&L_mcrLABEL.]Opening the BAT file for edit...;
	%sysexec	notepad %qsysfunc(quote(&BatFile.)) & exit;
%end;

%*500.	Execute the BAT program to conduct the copy.;
%sysexec	%qsysfunc(quote(&BatFile.)) & exit;

%EndOfProc:
%mend DBcr_DisseminateOmnimacro;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvDB"
		"D:\SAS\omnimacro\AdvOp"
		"D:\SAS\omnimacro\FileSystem"
	)
	mautosource
;

%*050.	Prevent program from being bombed.;
%macro ErrMcr;
%mend ErrMcr;

%*100.	Copy the macros for UOBC.;
%let	cdwmac	=	D:\SAS\omnimacro;
%DBcr_DisseminateOmnimacro(
	cdwmac		=	&cdwmac.
	,DataDic	=	%qsysfunc(catx( %OSDirDlm , &cdwmac. , %str(Instruction.xlsx) ))
	,SheetFunc	=	%str(Function$)
	,PkgFor		=	UOBC
	,OutRoot	=	%str(D:\SAS\UOBC\omnimacro)
	,procLIB	=	WORK
	,fDebug		=	0
)

/*-Notes- -End-*/