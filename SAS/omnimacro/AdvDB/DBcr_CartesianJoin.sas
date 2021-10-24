%macro DBcr_CartesianJoin(
	inDatLst	=
	,addProc	=
	,outDAT		=
	,procLIB	=	WORK
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to create the Cartesian Join of all the datasets provided.													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDatLst	:	The list of datasets to be joined together.																			|
|	|addProc	:	The additional process to be executed before each combined observation is output.									|
|	|outDAT		:	The output result.																									|
|	|procLIB	:	The processing library.																								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20170318		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180304		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|genvarlist																														|
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
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))	=	0	%then	%let	procLIB		=	WORK;

%*013.	Define the local environment.;
%local
	Di
;

%*018.	Define the global environment.;
%genvarlist(
	nstart		=	1
	,inlst		=	&inDatLst.
	,nvarnm		=	LeCJDat
	,nvarttl	=	LnCJDat
)

%*100.	Create the Cartesian Join.;
data &procLIB..__CJ_4dedup;
	%*100.	Initialize the output table structure in terms of the sequence of eahc dataset as provided in the list.;
	if	0	then do;
		set
		%do Di=1 %to &LnCJDat.;
			&&LeCJDat&Di..
		%end;
		;
	end;

	%*200.	Instantiate hash object for each dataset.;
	if	_N_	=	1	then do;
		%do Di=1 %to &LnCJDat.;
			dcl	hash	hCJ&Di.(dataset:"&&LeCJDat&Di..");
			hCJ&Di..DefineKey(all:"YES");
			hCJ&Di..DefineData(all:"YES");
			hCJ&Di..DefineDone();
			dcl	hiter	hiCJ&Di.("hCJ&Di.");
		%end;
	end;

	%*300.	Initialize the loop for all observations in all datasets.;
	%do Di=1 %to &LnCJDat.;
		%*100.	Retrieve the first observation from current dataset.;
		rcD&Di.	=	hiCJ&Di..first();

		%*200.	Iterate all observations in current dataset.;
		do while ( rcD&Di. = 0 );
	%end;

	%*500.	Conduct additional process before the combined observation is output.;
	%unquote(&addProc.)

	%*600.	Output any combined observations.;
	output;

	%*690.	Mark the end of the output.;
	EndOfOutput:

	%*700.	Close all the loops.;
	%*IMPORTANT: We have to close the loops in the reversed order.;
	%do Di=&LnCJDat. %to 1 %by -1;
		%*100.	Mark the end of current observation in current dataset.;
		EndOfhiCJ&Di.:

		%*200.	Fetch the next observation in current dataset.;
		rcD&Di.	=	hiCJ&Di..next();

		%*900.	Leave current dataset.;
		%*This is to close the WHILE loop.;
		end;
	%end;

	%*800.	Stop the execution.;
	stop;

	%*900.	Purge.;
	drop
	%do Di=1 %to &LnCJDat.;
		rcD&Di.
	%end;
	;
run;

%*800.	Dedup.;
proc sort
	data=&procLIB..__CJ_4dedup
	out=%unquote(&outDAT.)
	noduprecs
;
	by	_all_;
run;

%EndOfProc:
%mend DBcr_CartesianJoin;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvDB"
		"D:\SAS\omnimacro\AdvOp"
	)
	mautosource
;

%*100.	Prepare the testing tables to be joined together.;
data dat1;
	length	C_CAT1	$32.;
	C_CAT1	=	"1. CTB";	output;
run;
data dat2;
	length	C_CAT2	$32.;
	C_CAT2	=	"1. CASA";	output;
	C_CAT2	=	"2. FD";	output;
run;
data dat3;
	length	C_CAT3	$32.;
	C_CAT3	=	"1. GII";	output;
	C_CAT3	=	"2. FTP";	output;
	C_CAT3	=	"2. COL";	output;
run;

%*200.	Processing.;
%DBcr_CartesianJoin(
	inDatLst	=	%nrbquote(
						dat1
						dat2
						dat3
					)
	,addProc	=
	,outDAT		=	RevComp
	,procLIB	=	WORK
)

/*-Notes- -End-*/