%*001.	This section generates system log data.;
%*Below macro is from "&macroot.\010Proc";
%genLogByExecPgm

%*010.	Below section generates the system-level global variables;
%global
	G_dn_DelBgn
	G_dn_DelEnd
	G_Del_Dir
	G_Del_Cmd
	G_m_DelBgn
	G_m_DelEnd
	G_Del_FName
;

%let	G_dn_DelBgn	=	&L_m_R3Mth_M1.01;
%let	G_dn_DelEnd	=	&L_m_R3Mth_M2.01;
%let	G_Del_Dir	=	D:\SAS\TestBck;
%let	G_Del_Cmd	=	&outroot.\FileDel.bat;
%let	G_m_DelBgn	=	%substr( &G_dn_DelBgn. 1 , 6 );
%let	G_m_DelEnd	=	%substr( &G_dn_DelEnd. 1 , 6 );
%let	G_Del_FName	=	CmdDel;

/***************************************************************************************************\
|	Keep all the files, that follow below naming convention, within the provided directory and all	|
|	 its sub-directories, while remove all others.													|
|	[1] Apart from the file extension, it contains <yyyymm<dd>>, e.g. [abc20170808.sas7bdat]		|
|	[2] The string as defined above represents either month <yyyymm> or Last Workday of the month	|
|	[3] Files that do not match above rules will NOT be removed										|
|---------------------------------------------------------------------------------------------------|
|	Exceptions for above process:																	|
|---------------------------------------------------------------------------------------------------|
|	|Consecutive 6 or 8 digits will be treated as date-like string and handled in [1] and [2]		|
|---------------------------------------------------------------------------------------------------|
|	Dependent Macros.																				|
|---------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\FileSystem"													|
|	|-----------------------------------------------------------------------------------------------|
|	|	|OSDirDlm																					|
|	|	|getMemberByStrPattern																		|
\***************************************************************************************************/

%*020.	Below section is for main process;
%macro FileRemoval;
%*010.	Define the local environment.;
%local
	Fi
	Mi
	LnDel
	RX6Dgt
	RX8Dgt
	nBuffer
	strbgn
	strlen
	LchkStr
	rcFnm
	idCMD
;
%let	LnDel	=	0;
%let	nBuffer	=	1;
%let	strbgn	=	0;
%let	strlen	=	0;

%*070.	Correct the directory name if necessary.;
%do %while ( %qsubstr( &G_Del_Dir. , %length(&G_Del_Dir.) , 1 ) = %OSDirDlm );
	%let	G_Del_Dir	=	%qsubstr( &G_Del_Dir. , 1 , %eval( %length( &G_Del_Dir. ) - 1 ) );
%end;

%*090.	Set the proper home directory as the destination to copy the files.;
%let	G_Bck_Home	=	&G_Del_Dir.%OSDirDlm%qsysfunc( translate( &G_Bck_DirFr. , _ , : ) );

%*100.	Retrieve all files, containing 6 or 8 consecutive digits in their names, within the source directory and all its sub-directories.;
%getMemberByStrPattern(
	inDIR		=	&G_Del_Dir.
	,inRegExp	=	%nrstr(%(?<!\d%)%(\d{6}|\d{8}%)%(?!\d%))
	,exclRegExp	=
	,chkType	=	1
	,FSubDir	=	1
	,mNest		=	0
	,outCNT		=	GnDel
	,outELpfx	=	GeDel
	,outElTpPfx	=	GeDelT
	,outElPPfx	=	GeDelP
	,outElNmPfx	=	GeDelN
)

%*190.	Quit the process if there is no file found.;
%if	&GnDel.	=	0	%then %do;
	%put	%str(N)OTE: There is no file in the firectory [&G_Del_Dir.] matching the deletion rule. Quit the process.;
	%goto	EndOfProc;
%end;

%*200.	Identify the files to be deleted.;
%*210.	Prepare the RegExp to identify the consecutive digits from the file names.;
%let	RX6Dgt	=	%sysfunc( prxparse( /^.*(?<!\d)(\d{6})(?!\d)[\w\s]*\.\w+$/ix ) );
%let	RX8Dgt	=	%sysfunc( prxparse( /^.*(?<!\d)(\d{8})(?!\d)[\w\s]*\.\w+$/ix ) );

%*250.	Identification;
%do Fi=1 %to &GnDel.;
	%*100.	When there are 8 consecutive digits in the file name, we keep the file if it represents the Last Workday of any month.;
	%if	%sysfunc( prxmatch( &RX8Dgt. , &&GeDelN&Fi.. ) )	%then %do;
		%*010.	Retrieve the consecutive digits as a character string.;
		%*IMPORTANT: We have to initialize all below 4 macro variables with a number, such as 0, in order to conduct below CALL routine.;
		%syscall	prxposn( RX8Dgt , nBuffer , strbgn , strlen );
		%let	LchkStr	=	%substr( &&GeDelN&Fi.. , &strbgn. , &strlen. );

		%*100.	Keep the file if it is NOT within the period.;
		%*IMPORTANT: We do not validate this string as a date, but compare the strings directly.;
		%if		&LchkStr.	<	&G_dn_DelBgn.
			or	&LchkStr.	>	&G_dn_DelEnd.
			%then %do;
			%goto	EndOfId;
		%end;

		%*500.	Verify the dates.;
		%do Mi=1 %to &LpDelkMth.;
			%if		&LchkStr.	=	&&LpDeldn_LstWdOfM&Mi..
				or	&LchkStr.	=	&&LpDeldn_EndOfM&Mi..
				%then %do;
				%goto	EndOfId;
			%end;
		%end;
	%end;

	%*200.	When there are 6 consecutive digits in the file name, we keep thefile if it represents any month.;
	%if	%sysfunc( prxmatch( &RX6Dgt. , &&GeDelN&Fi.. ) )	%then %do;
		%*010.	Retrieve the consecutive digits as a character string.;
		%*IMPORTANT: We have to initialize all below 4 macro variables with a number, such as 0, in order to conduct below CALL routine.;
		%syscall	prxposn( RX6Dgt , nBuffer , strbgn , strlen );
		%let	LchkStr	=	%substr( &&GeDelN&Fi.. , &strbgn. , &strlen. );

		%*100.	Keep the file if it is NOT within the period.;
		%*IMPORTANT: We do not validate this string as a date, but compare the strings directly.;
		%if		&LchkStr.	<	&G_m_DelBgn.
			or	&LchkStr.	>	&G_m_DelEnd.
			%then %do;
			%goto	EndOfId;
		%end;
	%end;

	%*300.	Increment the counter of the identified files.;
	%let	LnDel	=	%eval( &LnDel. + 1 );

	%*400.	Create local macro variables to hold the file names and paths.;
	%local
		LeDel&LnDel.
	;
	%let	LeDel&LnDel.	=	&&GeDel&Fi..;

	%*900.	Mark the end of current iteration.;
	%EndOfId:
%end;

%*290.	Quit the process if there is no file matching the rules.;
%if	&LnDel.	=	0	%then %do;
	%put	%str(N)OTE: There is no file matching the deletion rule. Quit the process.;
	%goto	EndOfProc;
%end;

%*500.	Prepare the .BAT program to delete the identified files.;
%*510.	Create the program file and open it for edit.;
%sysexec	del /Q "&G_Del_Cmd." & exit;
%let	rcFnm	=	%sysfunc( filename( G_Del_FName , &G_Del_Cmd. ) );
%let	idCMD	=	%sysfunc( fopen( &G_Del_FName. , O ) );

%*550.	Write the Command programs into the file.;
%do Fi=1 %to &LnDel.;
	%*500.	Delete the file.;
	%let	rcFnm	=	%sysfunc( fput( &idCMD. , %nrbquote(del /Q "&&LeDel&Fi..") ) );
	%let	rcFnm	=	%sysfunc( fwrite( &idCMD. ) );
%end;

%*590.	Close the .BAT program file and clear the filename.;
%let	rcFnm	=	%sysfunc( fclose( &idCMD. ) );
%let	rcFnm	=	%sysfunc( filename( G_Del_FName ) );

%*900.	Execute the .BAT program;
%*sysexec	"&G_Del_Cmd." & exit;

%EndOfProc:
%mend FileRemoval;
%FileRemoval