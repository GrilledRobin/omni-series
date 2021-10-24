%macro Txt_WordSplit(
	inDat		=
	,inVAR		=
	,outDAT		=
	,outVAR		=
	,procLIB	=	WORK
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to split the words from the whole sentence in the given data.												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDat		:	The input dataset.																									|
|	|inVAR		:	The variable denoting the sentence of phrase to be split.															|
|	|outDAT		:	The output dataset that contains all the variables in the input dataset, with an additional variable that denotes	|
|	|				 the words split from the dedicated sentence (a single observation is output for each word).						|
|	|outVAR		:	The new variable in the output dataset that denotes the word as split.												|
|	|				If it already exists in the input data, its value will be overwritten, otherwise it will be created as Character	|
|	|				 variable with the length of 64.																					|
|	|procLIB	:	The working library.																								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20170820		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180311		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Please find the attachments for examples.																							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ErrMcr																															|
|	|	|getCOLbyStrPattern																												|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\FileSystem"																						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|FS_VarExists																													|
|	|	|FS_VARTYPE																														|
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
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))	=	0	%then	%let	procLIB		=	WORK;

%if	%sysfunc(nvalid(&inVAR.))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.][inVAR=&inVAR.] is NOT a valid Variable Name!;
	%ErrMcr
%end;

%if	%sysfunc(nvalid(&outVAR.))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.][outVAR=&outVAR.] is NOT a valid Variable Name!;
	%ErrMcr
%end;

%*013.	Define the local environment.;
%local
	TypInVar
	TypOutVar
	Vi
;
%let	TypInVar	=	%FS_VARTYPE( inDAT = &inDat. , inFLD = &inVAR. );
%if	&TypInVar.	^=	C	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.][inVAR=&inVAR.] is NOT a Character Variable! Word Split cannot be executed!;
	%ErrMcr
%end;
%if	%FS_VarExists( inDAT = &inDat. , inFLD = &outVAR. )	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.][outVAR=&outVAR.] is to be created.;
	%let	TypOutVar	=	C;
%end;
%else %do;
	%let	TypOutVar	=	%FS_VARTYPE( inDAT = &inDat. , inFLD = &outVAR. );
%end;

%*014.	Define the global environment.;
%global
	GnWSVar
;
%let	GnWSVar	=	0;

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in traditional SAS syntax colors.;
%macro dummy; %mend dummy;

%*070.	Retrieve necessary information from [inDAT].;
%*071.	Retrieve all the variables from [inDAT] for keeping them at the output step.;
%getCOLbyStrPattern(
	inDAT		=	&inDAT.
	,inRegExp	=
	,exclRegExp	=
	,chkVarTP	=	ALL
	,outCNT		=	GnWSVar
	,outELpfx	=	GeWSVar
)

%*100.	Word split process.;
data %unquote(&outDAT.);
	%*100.	Set the data.;
	set %unquote(&inDAT.) end=EOF;

	%*200.	Create the new variable if necessary.;
%if	%FS_VarExists( inDAT = &inDat. , inFLD = &outVAR. )	=	0	%then %do;
	length	&outVAR.	$64;
	call missing(&outVAR.);
%end;

	%*300.	Word Split.;
	%*310.	Prepare the Regular Expression.;
	%*arrTWS{1} : Start;
	%*arrTWS{2} : Stop;
	%*arrTWS{3} : Position;
	%*arrTWS{4} : Length;
	array
		arrTWS{4}
		8
		_temporary_
	;
	arrTWS{1}	=	1;
	arrTWS{2}	=	length(&inVAR.);
	arrTWS{3}	=	0;
	arrTWS{4}	=	0;
	retain	__prxID__;
	if	_N_	=	1	then do;
		__prxID__	=	%sysfunc(ifc(&TypOutVar.=C,prxparse('/\b\w+\b/ismx'),prxparse('/\b\d+(\.\d+)?\b/ismx')));
	end;

	%*320.	Output all matches to above pattern as Feature values.;
	call prxnext(__prxID__,arrTWS{1},arrTWS{2},&inVAR.,arrTWS{3},arrTWS{4});
	do while ( arrTWS{3} > 0 );
	%if	&TypOutVar.	=	C	%then %do;
		&outVAR.	=	substr(&inVAR.,arrTWS{3},arrTWS{4});
	%end;
	%else %do;
		&outVAR.	=	input(substr(&inVAR.,arrTWS{3},arrTWS{4}),best32.);
	%end;
		output;
		call prxnext(__prxID__,arrTWS{1},arrTWS{2},&inVAR.,arrTWS{3},arrTWS{4});
	end;

	%*800.	Free memory usage.;
	if	EOF	then do;
		call prxfree(__prxID__);
	end;

	%*900.	Purge.;
	keep
	%do Vi=1 %to &GnWSVar.;
		&&GeWSVar&Vi..
	%end;
		&outVAR.
	;
run;

%EndOfProc:
%mend Txt_WordSplit;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvOp"
		"D:\SAS\omnimacro\FileSystem"
		"D:\SAS\omnimacro\Model"
	)
	mautosource
;

%*100.	Test.;
data testTxtWS;
	length
		C_SENTENCE	$1024
		Category	$64
	;
	C_SENTENCE	=	"QUick car";
	Category	=	"bAD";
	output;

	C_SENTENCE	=	"nobody jumps";
	Category	=	"Good";
	output;
run;
%Txt_WordSplit(
	inDAT	=	testTxtWS
	,inVAR	=	C_SENTENCE
	,outDAT	=	testTxtWSout
	,outVAR	=	C_FEATURE
)

/*-Notes- -End-*/