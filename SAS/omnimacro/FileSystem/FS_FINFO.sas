%macro FS_FINFO(
	inFLNM	=
	,OptNum	=
	,outVAR	=
	,gMode	=	F
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to retrieve the system information for the given file.														|
|	|Unlike the original DATA STEP function [FINFO], this macro converts the [Last Modified Datetime] and [Create Datetime] into		|
|	| the DATETIME value in SAS environment.																							|
|	|Currently it supports below Operating System languages:																			|
|	| English																															|
|	| Chinese																															|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inFLNM	:	Input file name, including its full system path.																		|
|	|OptNum	:	Option number, by which to return the correspondent attribute of the file (WINDOWS environment).						|
|	|			[1] File Name (with full path)																							|
|	|			[2] RECFM																												|
|	|			[3] LRECL																												|
|	|			[4] File Size (Byte)																									|
|	|			[5] Last Modified Datetime																								|
|	|			[6] Create Datetime																										|
|	|outVAR	:	Output result containing the retrieved result.																			|
|	|gMode	:	Indicator of whether the macro is in Procedure Mode or Function Mode.													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20161105		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
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
|	|This macro can be called ANYWHERE.																									|
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
%if	%length(%qsysfunc(compress(&inFLNM.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No file is provided for information extraction!;
	%goto	EndOfProc;
%end;
%if	%length(%qsysfunc(compress(&OptNum.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]No Option Number is provided for information extraction!;
	%goto	EndOfProc;
%end;
%if	%length(%qsysfunc(compress(&outVAR.,%str( ))))	=	0	%then %do;
	%let	outVAR	=	G_FINFO;
	%global	&outVAR.;
%end;
%if	%qupcase(&gMode.)	^=	P	%then %do;
	%let	gMode	=	F;
%end;
%else %do;
	%let	gMode	=	P;
%end;

%*013.	Define the local environment.;
%local
	FileRefNm
	FileID
	FileRC
	FileNInf
	FileOptNm
	FileOptVal
	URL_Year
	URL_Mon
	URL_Day
	URL_Hour1
	URL_Hour2
	URL_Min
	URL_Sec
	LstrConv
	PRXID_str
	PRXID_Year
	PRXID_Mon
	PRXID_Day
	PRXID_Hour
	PRXID_Min
	PRXID_Sec
	Match_Year
	Match_Mon
	Match_Day
	Match_Hour
	Match_Min
	Match_Sec
	Value_Year
	Value_Mon
	Value_Day
	Value_Hour
	Value_Min
	Value_Sec
;
%let	FileRefNm	=	tmpflink;
%let	FileOptVal	=;
%let	URL_Year	=	%nrstr(%C4%EA);	%*The Chinese character of YEAR, same as below.;
%let	URL_Mon		=	%nrstr(%D4%C2);
%let	URL_Day		=	%nrstr(%C8%D5);
%let	URL_Hour1	=	%nrstr(%CA%B1);	%*Hour in GB2312;
%let	URL_Hour2	=	%nrstr(%95r);	%*Hour in BIG5;
%let	URL_Min		=	%nrstr(%B7%D6);
%let	URL_Sec		=	%nrstr(%C3%EB);

%*100.	Retrieve the file information.;
%let	FileRC		=	%sysfunc(filename(FileRefNm,&inFLNM.));
%let	FileID		=	%sysfunc(fopen(&FileRefNm.));
%let	FileNInf	=	%sysfunc(foptnum(&FileID.));

%*200.	Quit the process if the provided [OptNum] is not valid.;
%if	&OptNum.	>	&FileNInf.	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]The provided OptNum [&OptNum.] exceeds the available parameter!;
	%goto	CloseFile;
%end;

%*300.	Retrieve the file information.;
%let	FileOptNm	=	%sysfunc(foptname(&FileID.,&OptNum.));
%let	FileOptVal	=	%qsysfunc(finfo(&FileID.,&FileOptNm.));
%let	&outVAR.	=	&FileOptVal.;

%*390.	Purge.;
%CloseFile:
%let FileRC	=	%sysfunc(fclose(&FileID.));
%let FileRC	=	%sysfunc(filename(FileRefNm));

%*400.	Convert the datetime values to standard SAS values.;
%*401.	Check the condition to convert the datetime value.;
%if	%length(%qsysfunc(compress(&FileOptVal.,%str( ))))	=	0	%then %do;
	%goto	EndOfConv;
%end;
%if	&sysscp.	^=	WIN	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Datetime value conversion is not applicable under current OS.;
	%goto	EndOfConv;
%end;
%if		&OptNum.	^=	5
	and	&OptNum.	^=	6
	%then %do;
	%goto	EndOfConv;
%end;

%*410.	Conversion of the English datetime.;
%if		%index(&FileOptVal.,%qsysfunc(urldecode(&URL_Year.)))		=	0
	and	%index(&FileOptVal.,%qsysfunc(urldecode(&URL_Mon.)))		=	0
	and	%index(&FileOptVal.,%qsysfunc(urldecode(&URL_Day.)))		=	0
	and	%index(&FileOptVal.,%qsysfunc(urldecode(&URL_Hour1.)))		=	0
	and	%index(&FileOptVal.,%qsysfunc(urldecode(&URL_Hour2.)))		=	0
	and	%index(&FileOptVal.,%qsysfunc(urldecode(&URL_Min.)))		=	0
	and	%index(&FileOptVal.,%qsysfunc(urldecode(&URL_Sec.)))		=	0
	%then %do;
	%*100.	Use the informat [ANYDTDTMw.] to convert the standard datetime value.;
	%let	&outVAR.	=	%sysfunc(inputn(&FileOptVal.,ANYDTDTM24.));

	%*900.	Skip further try of conversion.;
	%goto	EndOfConv;
%end;

%*420.	Conversion of the Chinese datetime.;
%*PRX does not support the DBCS or MBCS data at SAS version 9.3 or earlier.;
%*Hence we enclose all consecutive digits by $ and @, while encodes all Chinese characters by URL standard, for future matching.;
%let	PRXID_str	=	%sysfunc(prxparse(s/(\d+)/\$$1@/ismx));
%let	LstrConv	=	%qsysfunc(urlencode(%qsysfunc(prxchange(&PRXID_str.,-1,&FileOptVal.))));

%*422.	Prepare all the PRX matching rules to identify the numbers at all positions.;
%let	PRXID_Year	=	%sysfunc(prxparse(/\$(\d+)@(?=&URL_Year.)/ismx));
%let	PRXID_Mon	=	%sysfunc(prxparse(/\$(\d+)@(?=&URL_Mon.)/ismx));
%let	PRXID_Day	=	%sysfunc(prxparse(/\$(\d+)@(?=&URL_Day.)/ismx));
%let	PRXID_Hour	=	%sysfunc(prxparse(/\$(\d+)@(?=(&URL_Hour1.|&URL_Hour2.))/ismx));
%let	PRXID_Min	=	%sysfunc(prxparse(/\$(\d+)@(?=&URL_Min.)/ismx));
%let	PRXID_Sec	=	%sysfunc(prxparse(/\$(\d+)@(?=&URL_Sec.)/ismx));

%*423.	Conduct the match of the PRX rule, before being able to extract the capture buffer.;
%let	Match_Year	=	%sysfunc(prxmatch(&PRXID_Year.,&LstrConv.));
%let	Match_Mon	=	%sysfunc(prxmatch(&PRXID_Mon.,&LstrConv.));
%let	Match_Day	=	%sysfunc(prxmatch(&PRXID_Day.,&LstrConv.));
%let	Match_Hour	=	%sysfunc(prxmatch(&PRXID_Hour.,&LstrConv.));
%let	Match_Min	=	%sysfunc(prxmatch(&PRXID_Min.,&LstrConv.));
%let	Match_Sec	=	%sysfunc(prxmatch(&PRXID_Sec.,&LstrConv.));

%*425.	Extract the digits as the correspondent values.;
%let	Value_Year	=	%sysfunc(prxposn(&PRXID_Year.,1,&LstrConv.));
%let	Value_Mon	=	%sysfunc(prxposn(&PRXID_Mon.,1,&LstrConv.));
%let	Value_Day	=	%sysfunc(prxposn(&PRXID_Day.,1,&LstrConv.));
%let	Value_Hour	=	%sysfunc(prxposn(&PRXID_Hour.,1,&LstrConv.));
%let	Value_Min	=	%sysfunc(prxposn(&PRXID_Min.,1,&LstrConv.));
%let	Value_Sec	=	%sysfunc(prxposn(&PRXID_Sec.,1,&LstrConv.));

%*428.	Set the output value.;
%let	&outVAR.	=	%sysfunc(dhms(%sysfunc(mdy(&Value_Mon.,&Value_Day.,&Value_Year.)),&Value_Hour.,&Value_Min.,&Value_Sec.));

%*429.	Purge the PRX IDs.;
%syscall prxfree(PRXID_str);
%syscall prxfree(PRXID_Year);
%syscall prxfree(PRXID_Mon);
%syscall prxfree(PRXID_Day);
%syscall prxfree(PRXID_Hour);
%syscall prxfree(PRXID_Min);
%syscall prxfree(PRXID_Sec);

%*490.	Mark the end of the datetime conversion.;
%EndOfConv:

%*990.	Below statement can only be used in "function" mode.;
%if	&gMode.	=	F	%then %do;
	&&&outVAR..
%end;

%EndOfProc:
%mend FS_FINFO;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\FileSystem"
	)
	mautosource
;

%let	Mdate	=	%FS_FINFO(inFLNM=%nrbquote(D:\SAS\omnimacro\FileSystem\FS_FINFO.sas),OptNum=5);
%let	Cdate	=	%FS_FINFO(inFLNM=%nrbquote(D:\SAS\omnimacro\FileSystem\FS_FINFO.sas),OptNum=6);

%*Output.;
%put	Create Date:[%sysfunc(putn(&Cdate.,datetime24.3))];
%put	Last Modified Date:[%sysfunc(putn(&Mdate.,datetime24.3))];

/*-Notes- -End-*/