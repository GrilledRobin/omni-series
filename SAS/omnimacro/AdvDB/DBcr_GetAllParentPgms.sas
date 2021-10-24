%macro DBcr_GetAllParentPgms(
	inDAT		=
	,ETLDate	=
	,findDAT	=
	,outSEQ		=	__EXEC__SEQ__
	,procLIB	=	WORK
	,outAllProc	=
	,outExePgm	=
	,outExtDat	=
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to get the locations and names of all parent programs that generate the given dataset(s) in					|
|	| certain sequence.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDAT		:	The input ETL meta table which stores the data flow of all projects.												|
|	|ETLDate	:	The date which should be used to lookup the legible processes in the ETL meta table.								|
|	|findDAT	:	The dataset list to lookup in the ETL meta table.																	|
|	|outSEQ		:	The additional field that should be created for the output process list to determine the sequential call of			|
|	|			:	 different programs.																								|
|	|procLIB	:	The working library.																								|
|	|outAllProc	:	The dataset that stores the extraction of the entire call tree from the ETL meta table.								|
|	|outExePgm	:	The dataset that stores the program list which are to be called in the provided order (determined by [outSEQ]).		|
|	|outExtDat	:	The dataset that stores the names of the external sources to be prepared in order to call the program tree.			|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20160117		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
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
|	|Please find the attachments for examples.																							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|getOBS4DATA																													|
|	|	|genvarlist																														|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*010.	Set parameters.;
%*011.	Identify current processing macro.;
%local
	L_mcrLABEL
	Lohno
;
%let	L_mcrLABEL	=	&sysMacroName.;
%let	Lohno		=	%str(E)RROR: [&L_mcrLABEL.]Process failed due to errors!;

%*012.	Handle the parameter buffer.;
%let	procLIB	=	%unquote(&procLIB.);
%if	%length(%qsysfunc(compress(&outSEQ.,%str( ))))	=	0	%then	%let	outSEQ	=	__EXEC__SEQ__;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))	=	0	%then	%let	procLIB	=	WORK;

%*013.	Define the global environment.;

%*014.	Define the local environment.;
%local
	LnCNT
	Di
	LtmpSTR
	LnOBS
	LnEXT
	LnIN
;
%let	LnCNT	=	0;
%let	LnIN	=	0;

%*050.	Restructure the name list.;
%genvarlist(
	nstart		=	1
	,inlst		=	&findDAT.
	,nvarnm		=	GeLST
	,nvarttl	=	GnLST
)

%*090.	Verify whether the provided data is actually generated in this ETL process.;
data &procLIB..__ETLtmp_indat__;
	set
		%unquote(&inDAT.)(
			where=(
					Flow_Type	=	"Output"
				and	Begin_Date	<=	%unquote(&ETLDate.)	<=	End_Date
				and	(0
					%do Di=1 %to &GnLST.;
						%let	LtmpSTR	=	%sysfunc(dequote(&&GeLST&Di..));
						or	upcase(Data_Name)	=	upcase(%sysfunc(quote(&LtmpSTR.))
					%end;
					)
			)
		)
	;
run;
%let	LnIN	=	%getOBS4DATA( inDAT = &procLIB..__ETLtmp_indat__, gMode = F );

%*100.	Retrieve the ETL table structure.;
data
	&procLIB..__ETLtmp_proc__
	&procLIB..__ETLtmp_extDat__
;
	if	0	then do;
		set	%unquote(&inDAT.);
		output;
	end;
	format	__K__BATCH__	8.;
	__K__BATCH__	=	0;
run;

%*200.	Retrieve all parents for the data to be searched.;
%do %while (&LnIN. ^= 0);
	%*010.	Prepare the counter.;
	%let	LnCNT	=	%eval(&LnCNT. + 1);

	%*100.	Retrieve all records regarding the same program, including the input data for it.;
	proc sql;
		%*100.	Retrieve all records from the original ETL table which are related to current output data.;
		create table &procLIB..__ETLtmp_pgm__ as (
			select
				a.*
				,&LnCNT. as __K__BATCH__ format=8.
			from %unquote(&inDAT.) as a
			inner join &procLIB..__ETLtmp_indat__ as b
				on		a.Module_Name		=	b.Module_Name
					and	a.Program_Name		=	b.Program_Name
			where a.Begin_Date	<=	%unquote(&ETLDate.)	<=	a.End_Date
		);

		%*200.	Search all the "input" data as in the above result, in the original ETL table, to see whether they are "output".;
		%*210.	Pick up all the "input" data which are NOT generated in current ETL process.;
		create table &procLIB..__ETLtmp_extadd__ as (
			select distinct
				a.*
			from &procLIB..__ETLtmp_pgm__ as a
			left join (
				select *
				from %unquote(&inDAT.)
				where	Begin_Date	<=	%unquote(&ETLDate.)	<=	End_Date
					and	Flow_Type	=	"Output"
			) as b
				on	a.Data_Name	=	b.Data_Name
			where a.Flow_Type	=	"Input"
				and	missing(b.Data_Name)	=	1
		);

		%*220.	Retrieve all parent records to current "input" data.;
		create table &procLIB..__ETLtmp_indat__ as (
			select a.*
			from %unquote(&inDAT.) as a
			inner join (
				select distinct
					Data_Name
				from &procLIB..__ETLtmp_pgm__
				where Flow_Type	=	"Input"
			) as b
				on	a.Data_Name	=	b.Data_Name
			where	a.Begin_Date	<=	%unquote(&ETLDate.)	<=	a.End_Date
				and	a.Flow_Type	=	"Output"
		);
	quit;

	%*200.	Verify the observations of above results.;
	%let	LnEXT	=	0;
	%let	LnIN	=	0;
	%let	LnEXT	=	%getOBS4DATA( inDAT = &procLIB..__ETLtmp_extadd__, gMode = F );
	%let	LnIN	=	%getOBS4DATA( inDAT = &procLIB..__ETLtmp_indat__, gMode = F );

	%*300.	Reserve the "input" data which are NOT generated from this ETL process for one of the results.;
	%if	&LnEXT.	^=	0	%then %do;
		data &procLIB..__ETLtmp_extDat__;
			set
				&procLIB..__ETLtmp_extDat__
				&procLIB..__ETLtmp_extadd__
			;
		run;
	%end;

	%*400.	Append the process list by the parents that are newly found in the ETL table.;
	%*We do not verify the [LnIN] here, for we have to retrieve the immediate parent anyway.;
	data &procLIB..__ETLtmp_proc__;
		set
			&procLIB..__ETLtmp_proc__
			&procLIB..__ETLtmp_pgm__
		;
	run;
%end;
%EndOfRecursion:

%*300.	Generate the list of programs to be executed in appropriate sequence.;
%*310.	Reserve the program name which is found in the largest iteration of the loop (identified by [__K__BATCH__]).;
%*Example:;
%*[program A] is found in [__K__BATCH__=2] and [__K__BATCH__=3], which may indicate that two separate datasets are;
%* generated via the different calls of [program A] in the second last process and the third last process respectively.;
%*That is why we only have to call [program A] once at the very third last process of the call tree to minimize the;
%* system effort.;
proc sort
	data=&procLIB..__ETLtmp_proc__(
		keep=
			Module_Name
			Program_Name
			__K__BATCH__
	)
	out=&procLIB..__ETLtmp_exe_pre__
;
	by
		Module_Name
		Program_Name
		__K__BATCH__
	;
run;
data &procLIB..__ETLtmp_exe_4out__;
	set &procLIB..__ETLtmp_exe_pre__;
	by
		Module_Name
		Program_Name
		__K__BATCH__
	;
	if	last.Program_Name;
run;

%*320.	We reset the order of the call tree to clarify the real execution sequence of these programs.;
%*In this step, we presume that the [Module_Name] and [Program_Name] have their own sequential numbers;
%* , such as MODULE01 and MODULE02, and PGM001 and PGM002 respectively.;
proc sort
	data=&procLIB..__ETLtmp_exe_4out__
;
	by
		descending __K__BATCH__
		Module_Name
		Program_Name
	;
run;
data %unquote(&outExePgm.);
	set &procLIB..__ETLtmp_exe_4out__;
	by
		descending __K__BATCH__
		Module_Name
		Program_Name
	;
	format	&outSEQ.	8.;
	retain	&outSEQ.;
	if	_N_	=	1	then do;
		&outSEQ.	=	0;
	end;
	if	first.__K__BATCH__	then do;
		&outSEQ.	+	1;
	end;
	drop
		__K__BATCH__
	;
run;

%*900.	Output the full lists.;
data %unquote(&outAllProc.);
	set &procLIB..__ETLtmp_proc__(drop=__K__BATCH__);
run;
data %unquote(&outExtDat.);
	set &procLIB..__ETLtmp_extDat__(drop=__K__BATCH__);
run;

%EndOfProc:
%mend DBcr_GetAllParentPgms;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvOp"
	)
	mautosource
;
%let	currDate	=	mdy(1,17,2016);

PROC IMPORT
	OUT			=	testRaw
	DATAFILE	=	"D:\SAS\omnimacro\AdvDB\TestETL.xlsx"
	DBMS		=	EXCEL2010
	REPLACE
;
	SHEET		=	"sheet1$";
	GETNAMES	=	YES;
	MIXED		=	NO;
	SCANTEXT	=	YES;
	USEDATE		=	YES;
	SCANTIME	=	YES;
RUN;

%DBcr_GetAllParentPgms(
	inDAT		=	testRaw
	,ETLDate	=	&currDate.
	,findDAT	=	db.rst
	,outSEQ		=	K_BATCH
	,procLIB	=	WORK
	,outAllProc	=	chkAllParents
	,outExePgm	=	chkExePgm
	,outExtDat	=	chkExtDat
)

%*Full Test Program[2]:;
%DBcr_GetAllParentPgms(
	inDAT		=	testRaw
	,ETLDate	=	&currDate.
	,findDAT	=	"db.rst" 'db.ChangeJobs'
	,outSEQ		=	K_BATCH
	,procLIB	=	WORK
	,outAllProc	=	chkAllParents
	,outExePgm	=	chkExePgm
	,outExtDat	=	chkExtDat
)

%*Output.;

/*-Notes- -End-*/