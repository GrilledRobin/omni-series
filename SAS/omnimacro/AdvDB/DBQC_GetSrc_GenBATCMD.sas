%macro DBQC_GetSrc_GenBATCMD(
	inDat			=
	,CMDSrcToMedia	=
	,CMDMediaToDest	=
	,procLIB		=	WORK
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is one of the series of functions for Quality Control during the retrieval of the Source Files.							|
|	|(1) Generate the Windows Batch Command programs to retrieve the files from the source location via the temporary media, such as	|
|	|     a flash disk.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDat			:	The dataset that stores the required Source Files to be retrieved.												|
|	|CMDSrcToMedia	:	The output Windows Batch program to retrieve the Files from the source location to the temporary media.			|
|	|CMDMediaToDest	:	The output Windows Batch program to retrieve the Files from the temporary media to the destination.				|
|	|procLIB		:	The working library.																							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20160807		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20171024		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace COPY command with XCOPY to skip any files that already exist and have not been modified.							|
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
|	|Please find the attachments for examples.																							|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|The input data MUST contain below fields:																							|
|	|	C_SRC_NAME	$256.																												|
|	|	C_SRC_PATH	$512.																												|
|	|	C_MED_PATH	$512.																												|
|	|	C_DES_PATH	$512.																												|
|	|	C_SRC_TYPE	$64.																												|
|	|	F_SRC_MISS	8.																													|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Labels of the above fields:																										|
|	|	C_SRC_NAME	=	"File Name of the Source"																						|
|	|	C_SRC_PATH	=	"Location where to retrieve the Source File"																	|
|	|	C_MED_PATH	=	"Location on the temporary media where to transport the Source File"											|
|	|	C_DES_PATH	=	"Location on the destination where to store the Source File"													|
|	|	C_SRC_TYPE	=	"Type of the Source File"																						|
|	|	F_SRC_MISS	=	"Flag of whether the required Source File is missing at the destination"										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|getOBS4DATA																													|
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
%if	%length(%qsysfunc(compress(&inDat.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No Input data is specified! Skip the process.;
	%goto	EndOfProc;
%end;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))	=	0	%then	%let	procLIB		=	WORK;

%if	%upcase(%scan(%nrbquote(&CMDSrcToMedia.),-1,%str(.)))	^=	BAT	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.][CMDSrcToMedia] is not a valid Windows Batch Program (.BAT), this may cause unexpected result.;
%end;

%if	%upcase(%scan(%nrbquote(&CMDMediaToDest.),-1,%str(.)))	^=	BAT	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.][CMDMediaToDest] is not a valid Windows Batch Program (.BAT), this may cause unexpected result.;
%end;

%*013.	Define the local environment.;

%*018.	Define the global environment.;

%*100.	Split the input configuration.;
data
	&procLIB..__DBqc_GenBatCmd_all
	&procLIB..__DBqc_GenBatCmd_mis
;
	%*010.	Set the source.;
	set	%unquote(&inDat.);

	%*200.	Output all records.;
	output &procLIB..__DBqc_GenBatCmd_all;

	%*300.	Output the records that are marked as "missing" and need to be retrieved.;
	if	F_SRC_MISS	=	1	then do;
		output &procLIB..__DBqc_GenBatCmd_mis;
	end;
run;

%*190.	Quit the program if all of the required files exist.;
%if	%getOBS4DATA( inDAT = &procLIB..__DBqc_GenBatCmd_mis , gMode = F )	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]All the required source files exist. Skip the process.;
	%goto	EndOfProc;
%end;

%*200.	Create the Windows Batch programs for the manual retrieval of the source files.;
data _NULL_;
	%*001.	Initialize the data structure.;
	if	0	then	set	&procLIB..__DBqc_GenBatCmd_all;

	%*010.	Create temporary fields.;
	length
		cnt		8.
		tmpType	$64.
		cmd		$1024.
	;

	%*100.	Prepare hash object of hashed groups of [C_SRC_TYPE], for the programming of each separate type of source files.;
	if	_N_	=	1	then do;
		%*100.	Declare the hash object for all the required source files.;
		dcl	hash	hSrcAll(dataset:"&procLIB..__DBqc_GenBatCmd_all",ordered: 'a',multidata: 'Y');
		dcl	hiter	hiSrcAll('hSrcAll');
		hSrcAll.DefineKey("C_SRC_TYPE");
		hSrcAll.DefineData(all: "YES");
		hSrcAll.DefineDone();

		%*200.	Declare the hash object for all the missing source files.;
		dcl	hash	hSrcMis(dataset:"&procLIB..__DBqc_GenBatCmd_mis",ordered: 'a',multidata: 'Y');
		dcl	hiter	hiSrcMis('hSrcMis');
		hSrcMis.DefineKey("C_SRC_TYPE");
		hSrcMis.DefineData(all: "YES");
		hSrcMis.DefineDone();
	end;

	%*300.	Prepare the program to copy the required source files from the server to the termporary media.;
	%*301.	Setup the file.;
	file "%unquote(&CMDSrcToMedia.)";

	%*310.	Create the file header.;
	put	"@echo off";

	%*320.	Generate the instructions.;
	put;
	put	"::100. Instructions";

	%*321.	List all the required source files.;
	put	"::--Process requires below source data";
	tmpType	=	"";
	rcSA	=	hiSrcAll.first();
	do while ( rcSA = 0 );
		%*100.	Declare the type of the required source files.;
		if	tmpType	^=	C_SRC_TYPE	then do;
			cnt	=	0;
			put	"::----" C_SRC_TYPE;
		end;

		%*200.	Increment the counter.;
		cnt	+	1;

		%*300.	List the files with their paths on the server.;
		cmd	=	cats("[",cnt,"][",C_SRC_PATH,"\",C_SRC_NAME,"]");
		put	"::" cmd;

		%*800.	Reset the temporary category of Source Type.;
		tmpType	=	C_SRC_TYPE;

		%*900.	Retrieve the next file name in the list.;
		rcSA	=	hiSrcAll.next();
	end;

	%*325.	List all the missing source files, which are to be copied from the server.;
	put;
	put	"::--Below source data need to be retrieved";
	tmpType	=	"";
	rcSM	=	hiSrcMis.first();
	do while ( rcSM = 0 );
		%*100.	Declare the type of the required source files.;
		if	tmpType	^=	C_SRC_TYPE	then do;
			cnt	=	0;
			put	"::----" C_SRC_TYPE;
		end;

		%*200.	Increment the counter.;
		cnt	+	1;

		%*300.	List the files with their paths on the server.;
		cmd	=	cats("[",cnt,"][",C_SRC_PATH,"\",C_SRC_NAME,"]");
		put	"::" cmd;

		%*800.	Reset the temporary category of Source Type.;
		tmpType	=	C_SRC_TYPE;

		%*900.	Retrieve the next file name in the list.;
		rcSM	=	hiSrcMis.next();
	end;

	%*330.	Create the prompt for the input of the destination.;
	put;
	put	"::200. Parameters";
	put	"@set /p DestLoc=Please input the location for the files to be copied:";

	%*340.	Generate the commands to copy the files.;
	put;
	put	"::300. Commands";
	tmpType	=	"";
	rcSM	=	hiSrcMis.first();
	do while ( rcSM = 0 );
		%*100.	Declare the type of the required source files.;
		if	tmpType	^=	C_SRC_TYPE	then do;
			put	"::" C_SRC_TYPE;
		end;

		%*200.	List the files with their paths on the server.;
		cmd	=	cats("@echo Copying [",C_SRC_NAME,"]");
		put	cmd;
		cmd	=	cats("@set cFileName=",C_SRC_PATH,"\",C_SRC_NAME);
		put	cmd;
		cmd	=	cats('@set cDestName=%DestLoc%\',C_MED_PATH);
		put	cmd;
		cmd	=	'@md "%cDestName%"';
		put	cmd;
		put	'if exist "%cFileName%" (';
		cmd	=	'@xcopy "%cFileName%" "%cDestName%" /D /Y';
		put	'09'x cmd;
		put	')';
		put;

		%*800.	Reset the temporary category of Source Type.;
		tmpType	=	C_SRC_TYPE;

		%*900.	Retrieve the next file name in the list.;
		rcSM	=	hiSrcMis.next();
	end;

	%*390.	Mark the end of the program.;
	put	"@echo on";

	%*400.	Prepare the program to copy the required source files from the temporary media to the destination.;
	%*401.	Setup the file.;
	file "%unquote(&CMDMediaToDest.)";

	%*410.	Create the file header.;
	put	"@echo off";

	%*420.	Generate the instructions.;
	put;
	put	"::100. Instructions";
	put	"::Please ensure below files exist in the transporting media.";

	%*430.	Create the prompt for the input of the destination.;
	put;
	put	"::200. Parameters";
	put	"@set /p DestLoc=Please input the location for the files to be copied:";

	%*440.	Generate the commands to copy the files.;
	put;
	put	"::300. Commands";
	tmpType	=	"";
	rcSM	=	hiSrcMis.first();
	do while ( rcSM = 0 );
		%*100.	Declare the type of the required source files.;
		if	tmpType	^=	C_SRC_TYPE	then do;
			put	"::" C_SRC_TYPE;
		end;

		%*200.	List the files with their paths on the server.;
		cmd	=	cats("@echo Copying [",C_SRC_NAME,"]");
		put	cmd;
		cmd	=	cats('@set cFileName=%DestLoc%\',C_MED_PATH,"\",C_SRC_NAME);
		put	cmd;
		cmd	=	cats('@set cDestName=',C_DES_PATH);
		put	cmd;
		cmd	=	'@md "%cDestName%"';
		put	cmd;
		put	'if exist "%cFileName%" (';
		cmd	=	'@xcopy "%cFileName%" "%cDestName%" /D /Y';
		put	'09'x cmd;
		put	')';
		put;

		%*800.	Reset the temporary category of Source Type.;
		tmpType	=	C_SRC_TYPE;

		%*900.	Retrieve the next file name in the list.;
		rcSM	=	hiSrcMis.next();
	end;

	%*490.	Mark the end of the program.;
	put	"@echo on";

	%*800.	Stop the DATA STEP.;
	stop;
run;

%EndOfProc:
%mend DBQC_GetSrc_GenBATCMD;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
%let	outFdr	=	D:\SAS\omnimacro\AdvDB;

options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvOp"
	)
	mautosource
;

libname	src	"&outFdr.";

%DBQC_GetSrc_GenBATCMD(
	inDat			=	src.test_DBQC_check_src
	,CMDSrcToMedia	=	%nrbquote(&outFdr.\SrcToMedia.bat)
	,CMDMediaToDest	=	%nrbquote(&outFdr.\MediaToDest.bat)
	,procLIB		=	WORK
)

/*-Notes- -End-*/