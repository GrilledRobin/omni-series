%*001.	This section generates system log data.;
%*Below macro is from "&macroot.\010Proc";
%genLogByExecPgm

%*010.	Below section generates the system-level global variables;
%global
	L_srcflnm
	L_stpflnm1
	L_stpflnm2
;

%let	L_srcflnm	=	src.Check_Src&L_curMon.;
%let	L_stpflnm1	=	&outroot.\Script\SrcToMedia.bat;
%let	L_stpflnm2	=	&outroot.\Script\MediaToDest.bat;

/***************************************************************************************************\
|	1. Create a BAT program to copy all the source files, which do not exist for current process,	|
|	    from the Server to the transporting media, such as a flash disk.							|
|	2. Create a BAT program to copy the required source files from the transporting media to the	|
|	    destination, in which the current process can read and operate.								|
\***************************************************************************************************/

%*020.	Below section is for main process;
%macro GenPgm4SrcRetrieval;
%*010.	Define the local environment.;

%*050.	Delete the original BAT programs.;
%sysexec(del /Q "&L_stpflnm1." "&L_stpflnm2." & exit);

%*100.	Quit the program if all of the required files exist.;
%*Below macro is from "&cdwmac.\AdvOp";
%if	%getOBS4DATA( inDAT = %nrbquote( &L_srcflnm.( where=( F_SRC_MISS ) ) ) , gMode = F )	=	0	%then %do;
	%put	NOTE: All the required source files exist. Skip current step.;
	%goto	EndOfProc;
%end;

%*200.	Create the Windows Batch programs for the manual retrieval of the source files.;
%*Below macro is from "&cdwmac.\AdvDB";
%DBQC_GetSrc_GenBATCMD(
	inDat			=	&L_srcflnm.
	,CMDSrcToMedia	=	%nrbquote(&L_stpflnm1.)
	,CMDMediaToDest	=	%nrbquote(&L_stpflnm2.)
	,procLIB		=	WORK2
)

%*800.	Issue the system messages and quit the program, if there are any datasets missing for the process.;
%put	WARNING: Some Data are required but missing!;
%put	WARNING: Please use below programs to retrieve them via external media devices:;
%put	WARNING: [&L_stpflnm1.];
%put	WARNING: [&L_stpflnm2.];
%*Below macro is from "&cdwmac.\AdvOp";
%ErrMcr

%EndOfProc:
%mend GenPgm4SrcRetrieval;
%GenPgm4SrcRetrieval