%macro prepGF_ReFmtInDAT;
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is to re-format the [inDAT] for all "Get-Function" as models															|
|	|The output data is "&procLIB.._gf_indat"																							|
|	|It has below features:																												|
|	|(1) Only keep necessary fields as required.																						|
|	|(2) Rename the [inKEY] fields to avoid conflicts during MERGE process.																|
|	|(3) "Rename" the [inVAR] fields by creating new temporary fields, to avoid conflicts during MERGE process.							|
|	|(4) Create a new field [K_ObsOriginal] to mark each observation in the [inDAT].													|
|	|(5) In addition, there a series of GLOBAL macro variables "GeFLDS&COLi." created to act as Field List of Seed.						|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20150130		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
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
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*100.	Reformat the [inDAT] as preparation.;
data &procLIB.._gf_indat;
	%*010.	Set the data.;
	set
		&inDAT.(
			keep=
			%if	%length(%qsysfunc(compress(&GrpBy.,%str( ))))	^=	0	%then %do;
				%do	GRPi=1	%to	&GnGrpDat.;
					&&GeGrpDat&GRPi..
				%end;
			%end;
				%do	KEYi=1	%to	&GnKeyDat.;
					&&GeKeyDat&KEYi..
				%end;
				%do	COLi=1	%to	&GnFLDN.;
					&&GeFLDN&COLi..
				%end;
		)
	;
%if	%length(%qsysfunc(compress(&GrpBy.,%str( ))))	^=	0	%then %do;
	by
	%do	GRPi=1	%to	&GnGrpDat.;
		&&GeGrpDat&GRPi..
	%end;
	;
%end;

	%*100.	Rename the fields.;
	rename
	%do	KEYi=1	%to	&GnKeyDat.;
		&&GeKeyDat&KEYi..	=	___tk_gf&KEYi.
	%end;
	;

	%*200.	Create necessary fields.;
	%*210.	Create observation identifier.;
	format	K_ObsOriginal	8.;
	label	K_ObsOriginal	=	"Number of OBS in the Sample Data";
	K_ObsOriginal	=	_N_;

	%*250.	Create termporary fields for later HASH process.;
	%*There is still some risk that the field name conflicts the ones in the [inDB].;
	format
	%do	COLi=1	%to	&GnFLDN.;
		___tn_gf&COLi.
	%end;
		best32.
	;
	%do	COLi=1	%to	&GnFLDN.;
		___tn_gf&COLi.	=	sum( 0 , &&GeFLDN&COLi.. );
		%global	GeFLDS&COLi.;
		%let	GeFLDS&COLi.	=	___tn_gf&COLi.;
	%end;

	%*900.	Purge.;
	drop
	%do	COLi=1	%to	&GnFLDN.;
		&&GeFLDN&COLi..
	%end;
	;
run;

%*NOTE: As below names are only effective here, they are not set in the function of "prepGF_ChkPrarm" for easy config.;

%*200.	Create a list of [inKEY] with Quotation Marks and Commas connecting each 2 variables.;
%do	KEYi=1	%to	&GnKeyDat.;
	%let	LKeyQC	=	&LKeyQC.%nrbquote(,"___tk_gf&KEYi.");
	%let	LKeyC	=	&LKeyC.%nrbquote(,___tk_gf&KEYi.);
%end;
%let	LKeyQC	=	%substr(&LKeyQC.,2);
%let	LKeyC	=	%substr(&LKeyC.,2);

%*300.	Create a list of [inVAR] with Quotation Marks and Commas connecting each 2 variables.;
%do	COLi=1	%to	&GnFLDN.;
	%let	LVarQC	=	&LVarQC.%nrbquote(,"___tn_gf&COLi.");
	%let	LVarC	=	&LVarC.%nrbquote(,___tn_gf&COLi.);
%end;
%let	LVarQC	=	%substr(&LVarQC.,2);
%let	LVarC	=	%substr(&LVarC.,2);

%EndOfProc:
%mend prepGF_ReFmtInDAT;