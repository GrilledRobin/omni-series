%*001.	This section generates system log data.;
%*Below macro is from "&macroot.\010Proc";
%genLogByExecPgm

%*010.	Below section generates the system-level global variables;
%global
	G_dn_BckBgn
	G_dn_BckEnd
	G_Bck_DirFr
	G_Bck_DirTo
	G_Bck_Cmd
	G_d_BckBgn
	G_d_BckEnd
	G_Bck_Home
	G_Bck_FName
;

%let	G_dn_BckBgn	=	&L_m_R3Mth_M1.01;
%let	G_dn_BckEnd	=	&L_m_R3Mth_M2.01;
%let	G_Bck_DirFr	=	D:\SAS\temp;
%let	G_Bck_DirTo	=	D:\SAS\TestBck;
%let	G_Bck_Cmd	=	&outroot.\BackupCopy.bat;
%let	G_d_BckBgn	=	%sysfunc(inputn(&G_dn_BckBgn.yymmdd10.));
%let	G_d_BckEnd	=	%sysfunc(inputn(&G_dn_BckEnd.yymmdd10.));
%let	G_Bck_FName	=	CmdBck;

/***************************************************************************************************\
|	Identify all the files that were MODIFIED between the provided dates, and copy them to the		|
|	 dedicated directory.																			|
|---------------------------------------------------------------------------------------------------|
|	As precaution, this program only creates the .BAT file while does not conduct the copying		|
|	 immediately. Please open and edit the .BAT file before commencing the copying when necessary.	|
|---------------------------------------------------------------------------------------------------|
|	Dependent Macros.																				|
|---------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\FileSystem"													|
|	|-----------------------------------------------------------------------------------------------|
|	|	|OSDirDlm																					|
|	|	|FS_FINFO																					|
|	|	|getMemberByStrPattern																		|
\***************************************************************************************************/

%*020.	Below section is for main process;
%macro BackupCopy;
%*010.	Define the local environment.;
%local
	Fi
	LnFil
	LtMod
	rcFnm
	idCMD
;
%let	LnFil	=	0;

%*070.	Correct the input directory name if necessary.;
%do %while ( %qsubstr( &G_Bck_DirFr. , %length(&G_Bck_DirFr.) , 1 ) = %OSDirDlm );
	%let	G_Bck_DirFr	=	%qsubstr( &G_Bck_DirFr. , 1 , %eval( %length( &G_Bck_DirFr. ) - 1 ) );
%end;

%*080.	Correct the output directory name if necessary.;
%do %while ( %qsubstr( &G_Bck_DirTo. , %length(&G_Bck_DirTo.) , 1 ) = %OSDirDlm );
	%let	G_Bck_DirTo	=	%qsubstr( &G_Bck_DirTo. , 1 , %eval( %length( &G_Bck_DirTo. ) - 1 ) );
%end;

%*090.	Set the proper home directory as the destination to copy the files.;
%let	G_Bck_Home	=	&G_Bck_DirTo.%OSDirDlm%qsysfunc( translate( &G_Bck_DirFr. , _ , : ) );

%*100.	Retrieve all files within the source directory and all its sub-directories.;
%getMemberByStrPattern(
	inDIR		=	&G_Bck_DirFr.
	,inRegExp	=	%nrbquote(.*)
	,exclRegExp	=
	,chkType	=	1
	,FSubDir	=	1
	,mNest		=	0
	,outCNT		=	GnFil
	,outELpfx	=	GeFil
	,outElTpPfx	=	GeFilT
	,outElPPfx	=	GeFilP
	,outElNmPfx	=	GeFilN
)

%*190.	Quit the process if there is no file found.;
%if	&GnFil.	=	0	%then %do;
	%put	%str(N)OTE: There is no file in the firectory [&G_Bck_DirFr.]. Quit the process.;
	%goto	EndOfProc;
%end;

%*200.	Identify the files that match the filtration rules.;
%do Fi=1 %to &GnFil.;
	%*100.	Retrieve the last modified date of current file.;
	%let	LtMod	=	%FS_FINFO( inFLNM = &&GeFil&Fi.. , OptNum = 5 );

	%*200.	Skip the file if its last modified date is NOT between the provided ones.;
	%if		%sysfunc( datepart( &LtMod. ) )	<	&G_d_BckBgn.
		or	%sysfunc( datepart( &LtMod. ) )	>=	&G_d_BckEnd.
		%then %do;
		%goto	EndOfId;
	%end;

	%*300.	Increment the counter of the identified files.;
	%let	LnFil	=	%eval( &LnFil. + 1 );

	%*400.	Create local macro variables to hold the file names and paths.;
	%local
		LeFil&LnFil.
		LePath&LnFil.
	;
	%let	LeFil&LnFil.	=	&&GeFil&Fi..;
	%let	LePath&LnFil.	=	&G_Bck_Home.%qsubstr( &&GeFilP&Fi.. , %eval( %length( &G_Bck_DirFr. ) + 1 ) );

	%*900.	Mark the end of current iteration.;
	%EndOfId:
%end;

%*290.	Quit the process if there is no file matching the rules.;
%if	&LnFil.	=	0	%then %do;
	%put	%str(N)OTE: There is no file matching the backup rule. Quit the process.;
	%goto	EndOfProc;
%end;

%*500.	Prepare the .BAT program to copy the identified files to the destination directory and maintain the folder structure.;
%*510.	Create the program file and open it for edit.;
%sysexec	del /Q "&G_Bck_Cmd." & exit;
%let	rcFnm	=	%sysfunc( filename( G_Bck_FName , &G_Bck_Cmd. ) );
%let	idCMD	=	%sysfunc( fopen( &G_Bck_FName. , O ) );

%*550.	Write the Command programs into the file.;
%do Fi=1 %to &LnFil.;
	%*100.	Create the directory where necessary.;
	%let	rcFnm	=	%sysfunc( fput( &idCMD. , %nrbquote(mkdir "&&LePath&Fi..") ) );
	%let	rcFnm	=	%sysfunc( fwrite( &idCMD. ) );

	%*200.	XCOPY the file into the newly created directory.;
	%let	rcFnm	=	%sysfunc( fput( &idCMD. , %nrbquote(xcopy "&&LeFil&Fi.." "&&LePath&Fi.." /Y /C /D) ) );
	%let	rcFnm	=	%sysfunc( fwrite( &idCMD. ) );
%end;

%*590.	Close the .BAT program file and clear the filename.;
%let	rcFnm	=	%sysfunc( fclose( &idCMD. ) );
%let	rcFnm	=	%sysfunc( filename( G_Bck_FName ) );

%*900.	Execute the .BAT program;
%*sysexec	"&G_Bck_Cmd." & exit;

%EndOfProc:
%mend BackupCopy;
%BackupCopy