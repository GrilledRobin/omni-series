%macro ResolveHyphenFrDat(
	inSTR	=
	,inDAT	=
	,nFOUND	=	G_n_FLD
	,eFOUND	=	G_e_FLD
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to resolve the Hyphens in Grouping Syntax during syntax evaluation and find all the dedicated				|
|	| variables in the provided dataset in terms of the syntax																			|
|	|It is useful in the understanding of PROC FREQ, PROC TABULATE and aggregation functions such as SUM(of ...).						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Grouping Syntax #1: [Single Hyphen: -], example: var1 - var3																		|
|	| Rule(1) variables linked by the hyphen should exist in the dataset, in this case [var1] and [var3].								|
|	| Rule(2) the header of the variables should be the same, in this case [var], case-insensitive.										|
|	| Rule(3) the trailer of the variables should be digits, in this case [1] to [3].													|
|	| Rule(4) the series of variables should ALL exist in the dataset.																	|
|	| Rule(5) there can be CHARACTER or NUMERIC variables in the series, but in the aggretaion functions, CHARACTER is translated		|
|	|          into numeric, and set missing if failed.																					|
|	| Rule(6) the series can be set in a descending order, e.g. var3 - var1																|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Grouping Syntax #2: [Double Hyphens: --], example: var4 -- var3 (Given there are 3 variables [var4], [var2], [var3] in order)		|
|	| Rule(1) variables linked by the hyphens should exist in the dataset, in this case [var4] and [var3].								|
|	| Rule(2) the header of the variables should be the same, in this case [var], case-insensitive.										|
|	| Rule(3) the trailer of the variables should be digits, in this case [4] and [3].													|
|	| Rule(4) the beginner [var4] should physically exist to the left of [var3].														|
|	| Rule(5) Special Grouping Syntax as [var4-numeric-var3] and [var4-character-var3] have to respect the field type as well.			|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inSTR	:	The character string that contains ONE appearance of the Grouping Syntax.												|
|	|			 Examples: [1]var1 - var3, [2]var4 -- var3																				|
|	|inDAT	:	The dataset in which the variables should be found.																		|
|	|nFOUND	:	The macro variable name that should have the value of the number of fields that are found via Grouping Syntax.			|
|	|eFOUND	:	The header of the series of macro variables that should have the value of the names of the fields found in the data.	|
|	|In correspondence, attributes are also output as macro variables with the same header as provided,									|
|	| e.g. if there is one field [VAR5] to be output with the macro variable name [GeVAR1],												|
|	| there will be another macro variables generated at the same as below:																|
|	| [GeVAR1typ] which stores the type of this variable, C or N.																		|
|	| [GeVAR1fmt] which stores the format of this variable.																				|
|	| [GeVAR1len] which stores the length of this variable.																				|
|	| [GeVAR1lbl] which stores the label of this variable.																				|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20150927		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20151008		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Add the verification of the special Grouping Syntax as [a-numeric-b] and [a-character-b].									|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180310		| Version |	2.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|20150927 Currently this macro can only handle one string at a time. If the string is a combination,								|
|	| please call this macro separately.																								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ErrMcr																															|
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
%let	inSTR		=	%qupcase(%qsysfunc(compress(&inSTR.,%str( ))));

%if	%length(%qsysfunc(compress(&nFOUND.,%str( ))))	=	0	%then	%let	nFOUND		=	G_n_FLD;
%if	%length(%qsysfunc(compress(&eFOUND.,%str( ))))	=	0	%then	%let	eFOUND		=	G_e_FLD;
%global	&nFOUND.;
%let	&nFOUND.	=	0;
%if	%index(&inSTR.,-)	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]There is no Grouping Syntax in the provided character string, it will be output directly.;
	%let	&nFOUND.	=	1;
	%global	&eFOUND.&&&nFOUND..;
	%let	&eFOUND.&&&nFOUND..	=	&inSTR.;
	%goto	EndOfProc;
%end;

%*013.	Define the local environment.;
%local
	kHyphen
	LchkSTR
	Lhyphen
	DSID
	nVARS
	VARi
	rc
	strB
	strE
	prxVAR
	strBc
	strBn
	strEc
	strEn
	loopBy
	bExist
	eExist
	nBgn
	nEnd
	bType
	eType
	VARj
	kZERO
	tmpSTR
;
%*The number of hyphens determines the route we would follow.;
%let	kHyphen	=	%sysfunc(countc(&inSTR.,-));
%*Different patterns of the Grouping Syntax should be processed differently.;
%if	%index(&inSTR.,-NUMERIC-)	%then %do;
	%let	LchkSTR	=	N;
%end;
%else %if
		%index(&inSTR.,-CHARACTER-)
	or	%index(&inSTR.,-CHAR-)
	%then %do;
	%let	LchkSTR	=	C;
%end;
%else %do;
	%let	LchkSTR	=	A;
%end;
%let	Lhyphen	=	-;
%let	prxVAR	=	%sysfunc(prxparse(/\b(\w+?)(\d+)\b/ismx));
%let	bExist	=	0;
%let	eExist	=	0;

%*100.	Retrieval of variable attributes.;
%*110.	Open the data.;
%let	DSID	=	%sysfunc(open(&inDAT.));
%let	nVARS	=	%sysfunc(attrn(&DSID.,nVARS));

%*120.	Retrieve all the variables.;
%do VARi=1 %to &nVARS.;
	%local
		LvNAM&VARi.
		LvTYP&VARi.
		LvFMT&VARi.
		LvLEN&VARi.
		LvLBL&VARi.
	;
	%*Since there could be special characters in the variable format, we macro-quote all the results.;
	%let	LvNAM&VARi.	=	%upcase(%qsysfunc(varname(&DSID.,&VARi.)));
	%let	LvTYP&VARi.	=	%qsysfunc(vartype(&DSID.,&VARi.));
	%let	LvFMT&VARi.	=	%qsysfunc(varfmt(&DSID.,&VARi.));
	%let	LvLEN&VARi.	=	%qsysfunc(varlen(&DSID.,&VARi.));
	%let	LvLBL&VARi.	=	%qsysfunc(varlabel(&DSID.,&VARi.));
%end;

%*190.	Close the data.;
%CloseDat:
%let	rc		=	%sysfunc(close(&DSID.));

%*200.	Evaluate the provided string.;
%*210.	Retrieve the features of the beginner and the ender.;
%let	strB	=	%scan(&inSTR.,1,&Lhyphen.);
%let	strE	=	%scan(&inSTR.,-1,&Lhyphen.);
%*Initialize the sequence to facilitate the PRXPOSN function.;
%let	rc		=	%sysfunc(prxmatch(&prxVAR.,&strB.));
%*Retrieve the Character part and Numeric part.;
%let	strBc	=	%sysfunc(prxposn(&prxVAR.,1,&strB.));
%let	strBn	=	%sysfunc(prxposn(&prxVAR.,2,&strB.));
%*Initialize the sequence to facilitate the PRXPOSN function.;
%let	rc		=	%sysfunc(prxmatch(&prxVAR.,&strE.));
%*Retrieve the Character part and Numeric part.;
%let	strEc	=	%sysfunc(prxposn(&prxVAR.,1,&strE.));
%let	strEn	=	%sysfunc(prxposn(&prxVAR.,2,&strE.));

%*219.	Free the system resources as we never use it later.;
%syscall	prxfree(prxVAR);

%*220.	Determine the loop direction.;
%*IMPORTANT: In the macro loop, "01" as the counter is treated as "1".;
%*           Hence we should add "0" back to it to get the correct DS variable name if any.;
%if	&strBn. > &strEn.	%then %do;
	%let	loopBy	=	-1;
%end;
%else %do;
	%let	loopBy	=	1;
%end;

%*230.	Verify the existence of the two provided variables.;
%do VARi=1 %to &nVARS.;
	%if	&strB.	=	&&LvNAM&VARi..	%then %do;
		%let	bExist	=	1;
		%let	nBgn	=	&VARi.;
		%let	bType	=	&&LvTYP&VARi..;
	%end;
	%if	&strE.	=	&&LvNAM&VARi..	%then %do;
		%let	eExist	=	1;
		%let	nEnd	=	&VARi.;
		%let	eType	=	&&LvTYP&VARi..;
	%end;
%end;
%if	&bExist.	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]The variable [&strB.] does not exist in the input data!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	&eExist.	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]The variable [&strE.] does not exist in the input data!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*240.	If there is leading zero in either variable, we should make sure their lengths are the same.;
%*Otherwise we cannot find the correct series as: a01 - a120;
%if		%index(&strBn.,0)	=	1
	or	%index(&strEn.,0)	=	1
	%then %do;
	%if	%length(&strBn.)	^=	%length(&strEn.)	%then %do;
		%put	%str(E)RROR: [&L_mcrLABEL.]The macro cannot resolve the series!;
		%put	&Lohno.;
		%ErrMcr
	%end;
%end;

%*290.	The header of the beginner should be the same as that of the ender.;
%if	&strBc.	^=	&strEc.	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]The variable names do not match!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*299.	Determine the process route.;
%goto	Hyphen&kHyphen.;
/*
%if	%sysfunc(countc(&inSTR.,-))	=	2	%then %do;
	%goto	Hyphen2;
%end;
%else %do;
	%goto	Hyphen1;
%end;
*/

%*300.	Resolve the syntax of Single Hyphen.;
%Hyphen1:
%put	%str(N)OTE: [&L_mcrLABEL.]Grouping Syntax is Single Hyphen, hence this macro do not verify the field existence.;
%do VARj=&strBn. %to &strEn. %by &loopBy.;
	%*100.	Supplement enough zeros to the left of the counter, should the DS variable is like: a001.;
	%if		%index(&strBn.,0)	=	1
		or	%index(&strEn.,0)	=	1
		%then %do;
		%let	kZERO	=	%sysfunc(repeat(0,%length(&strBn.)));
		%let	tmpSTR	=	%substr(&kZERO.&VARj.,%eval(%length(&kZERO.&VARj.) - %length(&strBn.) + 1));
	%end;
	%else %do;
		%let	tmpSTR	=	&VARj.;
	%end;

	%let	&nFOUND.	=	%eval(&&&nFOUND.. + 1);
	%global	&eFOUND.&&&nFOUND..;
	%let	&eFOUND.&&&nFOUND..	=	&strBc.&tmpSTR.;
%end;

%*399.	Quit current macro as it is finished.;
%goto	Purge;

%*400.	Resolve the syntax of Double Hyphen.;
%Hyphen2:
%*410.	If the Beginner is on the right side of the ender, we bomb the macro.;
%if	&nBgn.	>	&nEnd.	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]The variable [&strB.] is located at the right side to the variable [&strE.]!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*490.	Find the variables by the given conditions.;
%do VARj=&nBgn. %to &nEnd.;
	%*010.	Check the condition whether we need to distinguish the NUMERIC or CHARACTER field.;
	%if	&LchkSTR.	^=	A	%then %do;
		%if	&&LvTYP&VARj..	^=	&LchkSTR.	%then %do;
			%goto	EndOfIte;
		%end;
	%end;

	%*100.	Output the result.;
	%let	&nFOUND.	=	%eval(&&&nFOUND.. + 1);
	%global	&eFOUND.&&&nFOUND..;
	%let	&eFOUND.&&&nFOUND..	=	&&LvNAM&VARj..;

	%*900.	End of current iteration and scroll to the next one.;
	%EndOfIte:
%end;

%*499.	Quit current macro as it is finished.;
%goto	Purge;

%*900.	Purge.;
%Purge:

%EndOfProc:
%mend ResolveHyphenFrDat;