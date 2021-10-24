%macro ProcMultiFreq(
	inDAT		=
	,byVAR		=
	,inTABLES	=
	,TableOpt	=
	,FoutCUM	=	0
	,FmtStmt	=
	,procLIB	=	WORK
	,outDAT		=
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to mimick the PROC FREQ by enabling the multi-tables to be output at one time								|
|	| through the basic TABLES statement.																								|
|	|IMPORTANT! The pattern as [a * (b c * d)] is NOT accepted by PROC FREQ in SAS versions 9.3 or earlier,								|
|	| while it can be resolved by this macro^_^.																						|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDAT		:	The input data.																										|
|	|byVAR		:	The group of variables, within which the frequency is to be summarized.												|
|	|				 [IMPORTANT]: If any variable in this list exist in [inTABLES], SAS will issue a WARNING message.					|
|	|inTABLES	:	The same statement as TABLES in PROC FREQ without the options.														|
|	|				 It is designed to mimic the same fashion so currently it can be expressed as "a * (b c)".							|
|	|TableOpt	:	The set of options that are available in the TABLE(S) statement in PROC FREQ.										|
|	|				 Usually we would use [MISSING] for basic usage.																	|
|	|				 [IMPORTANT]: DO NOT use [OUT=] options here, as we would make other use of it.										|
|	|				 [IMPORTANT]: DO NOT use some multi-way-sensitive options for mixed tabulation, such as [a a*b],					|
|	|				  see the official document.																						|
|	|FoutCUM	:	The flag of whether to include the cumulative counts and percentages in the frequency summary.						|
|	|				 It is of the same effect as the option [OUTCUM] in the TABLES statement.											|
|	|				 [IMPORTANT]: The classic [OUTCUM] only supports one-way table, but we can leverage it here.						|
|	|FmtStmt	:	The statments that are applied in the [FORMAT] statement.															|
|	|procLIB	:	The working library.																								|
|	|outDAT		:	The summary result.																									|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20150927		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20150927		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Only keep the necessary fields if there is no DATASET OPTION specified in the [inDAT].										|
|	|      |This is to reduce the computer resources given large dataset.																|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20150927		| Version |	1.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Add the verification of the Grouping Syntax, such as [var1 - var3] and [var4 -- var2].										|
|	|      |Should there be something like [var1 - var3 -- var4] (two consecutive Grouping expressions), the macro						|
|	|      | will generate unexpected result as it also do not match the SAS syntax.													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20150928		| Version |	1.21		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Free the system resources by call the routine PRXFREE for the variable [prxGS].												|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20151008		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Add the verification of the special Grouping Syntax as [a-numeric-b] and [a-character-b].									|
|	|      |Enable the syntax of Name List: _NUMERIC_, _CHARACTER_, _CHAR_ and _ALL_													|
|	|      |Fixed a bug when [a*b c] is in effect, the variable names and values are retained to the 2nd table.							|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20160102		| Version |	3.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |The previous array [arrFe] stores values as: ["1" "a"|"2" "b"|...], which is highly probable to exceed						|
|	|      | the maximum length (32767) that one single field can carry in SAS under certain circumstances.								|
|	|      |In this version, several new arrays are created to conduct the same process, but will avoid the excess.						|
|	|      |Given one frequency combination [a * b], there will now be 3 arrays to perform the counting:								|
|	|      | arr1{<Total OBS of the data>} (<v1 of a> <v2 of a> ...)																	|
|	|      | arr2{<Total OBS of the data>} (<v1 of b> <v2 of b> ...)																	|
|	|      | (The [v1] in each array is correspondent to a unique combination in the frequency table, and so forth.)					|
|	|      | arr3{<Total OBS of the data>} (<K of Combo 1> <K of Combo 2> ...)															|
|	|      | (This array holds the count of the frequency of each correspondent unique combination.)									|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20160102		| Version |	4.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Since the array usage will be limited by the RAM, we use HASH object to avoid overbrimming.									|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20160103		| Version |	5.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |We have to get back to the original PROC FREQ to ensure the overall speed is acceptable.									|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170325		| Version |	5.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Added the %superq function so that any special characters in the LABEL contents can be masked.								|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170723		| Version |	5.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Fixed a potential bug for the RETAIN statement, to prevent retention of variable values when there is no [byVAR].			|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180304		| Version |	5.30		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Please find the attachments for examples.																							|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|20150927 Supported Statements:																										|
|	|[BY]																																|
|	|[TABLES]																															|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|20160103 Supported Statements:																										|
|	|Since we take the original PROC FREQ as the mainframe, it theoretically supports all classic statements.							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ErrMcr																															|
|	|	|prepStrPatternByCOLList																										|
|	|	|getCOLbyStrPattern																												|
|	|	|ResolveHyphenFrDat																												|
|	|	|Str_Factorization																												|
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
%let	procLIB		=	%unquote(&procLIB.);
%let	inTABLES	=	%qupcase(&inTABLES.);			%*It should be quoted as there may be special characters.;

%if	%length(%qsysfunc(compress(&byVAR.,%str( ))))	^=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]The procedure will be executed in terms of the BY group.;
%end;

%if	&FoutCUM.	NE	0	%then	%let	FoutCUM		=	1;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))	=	0	%then	%let	procLIB		=	WORK;

%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No output data is specified! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*013.	Define the local environment.;
%local
	vfyOutDat
	LstGrp
	GRPk
	SUBi
	tmpTABLES
	prxNL
	LrxVarTp
	prxGS
	prxGSFst
	prxGSBuf
	ptnGSBufB
	ptnGSBufL
	prxVAR
	prxFIRST
	ptnBUFFER
	ptnBUFbgn
	ptnBUFlen
	LpVARchk
	ptnReplace
	VFYi
	Aheadptn
	Behindptn
	FREQi
	ASTi
	LNmaxVAR
	LNmaxLEN
	LNmaxLBL
	DSID
	rc
	L_varnum
;
%*Make the character string somewhat short, although it has no effect in the process.;
%let	tmpTABLES	=	%qsysfunc(compbl(&inTABLES.));
%*If there is no parenthesis in the [inDAT], there must be no DATASET OPTION assigned,;
%* hence we can add our own options to reduce necessary fields.;
%let	vfyOutDat	=	%index(&inDAT.,%str(%());
%let	LNmaxVAR	=	0;
%let	LNmaxLEN	=	0;
%let	LNmaxLBL	=	0;

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in traditional SAS syntax colors.;
%macro dummy; %mend dummy;

%*050.	Identify all variables in the BY group.;
%if	%length(%qsysfunc(compress(&byVAR.,%str( ))))	^=	0	%then %do;
	%*100.	Prepare the RegExp to search for the variables provided.;
	%prepStrPatternByCOLList(
		COLlst		=	%nrbquote(&byVAR.)
		,chkArg		=	1
		,ArgLst		=	DESCENDING
		,nPTN		=	GnPGrpBy
		,ePTN		=	GePGrpBy
		,OchkArg	=	GAePGrpBy
		,outPTN		=	LstGrp
	)

	%*200.	Retrieve the existing variables indicated by [GrpBy] and mark them by the provided arguments if any.;
	%*GnPGrpBy	:	Global macro variable with the value of Number of Patterns from [byVAR];
	%do GRPk=1 %to &GnPGrpBy.;
		%*100.	Retrieve all the matching variables for current sub-pattern.;
		%*Here we benefit from below macro in that all the variables retrieved are in VARNUM sequence.;
		%getCOLbyStrPattern(
			inDAT		=	&inDAT.
			,inRegExp	=	%nrbquote(&&GePGrpBy&GRPk..)
			,exclRegExp	=
			,chkVarTP	=
			,outCNT		=	GprocRX&GRPk.n
			,outELpfx	=	GprocRX&GRPk.e
		)
	%end;
%end;

%*060.	Translate the Name List if any.;
%*061.	Define the Name List pattern in SAS system.;
%let	prxNL		=	%sysfunc(prxparse(/\b(_NUMERIC_|_CHAR(ACTER)?_|_ALL_)\b/ismx));
%let	prxFIRST	=	1;
%let	ptnBUFbgn	=	0;
%let	ptnBUFlen	=	0;

%*062.	Replace all the patterns of Name List with actual variable names in the [inDAT], by enclosing the variable list with parentheses.;
%do %while (%sysfunc(prxmatch(&prxNL.,&tmpTABLES.)));
	%*100.	Return the start position and the length of the capture buffer, for later replacement.;
	%syscall	prxposn(prxNL,prxFIRST,ptnBUFbgn,ptnBUFlen);

	%*200.	Retrieve the capture buffer that matches the pattern.;
	%let	ptnBUFFER	=	%qsysfunc(prxposn(&prxNL.,1,&tmpTABLES.));

	%*300.	Prepare the RegExp to search for the above capture buffer.;
	%if	&ptnBUFFER.	=	_NUMERIC_	%then %do;
		%let	LrxVarTp	=	N;
	%end;
	%else %if
			&ptnBUFFER.	=	_CHARACTER_
		or	&ptnBUFFER.	=	_CHAR_
		%then %do;
		%let	LrxVarTp	=	C;
	%end;
	%else %do;
		%let	LrxVarTp	=	A;
	%end;

	%*400.	Retrieve all the fields by the given pattern.;
	%getCOLbyStrPattern(
		inDAT		=	&inDAT.
		,inRegExp	=	%nrbquote(.*)
		,exclRegExp	=
		,chkVarTP	=	&LrxVarTp.
		,outCNT		=	GnNL
		,outELpfx	=	GeNL
	)

	%*410.	Connect all the variables found in the [inDAT] with WHITE SPACE and enclose the list with parentheses, such as "(a2 a3 a4)".;
	%let	ptnReplace	=;
	%do VFYi=1 %to &GnNL.;
		%let	ptnReplace	=	&ptnReplace. &&GeNL&VFYi..;
	%end;
	%let	ptnReplace	=	%nrbquote((&ptnReplace.));

	%*500.	Determine the character string ahead of the capture buffer.;
	%if	&ptnBUFbgn.	=	1	%then %do;
		%let	Aheadptn	=;
	%end;
	%else %do;
		%let	Aheadptn	=	%qsubstr(&tmpTABLES.,1,%eval(&ptnBUFbgn. - 1));
	%end;

	%*600.	Determine the character string behind the capture buffer.;
	%if	%eval(&ptnBUFbgn. + &ptnBUFlen. - 1)	=	%length(&tmpTABLES.)	%then %do;
		%let	Behindptn	=;
	%end;
	%else %do;
		%let	Behindptn	=	%qsubstr(&tmpTABLES.,%eval(&ptnBUFbgn. + &ptnBUFlen.));
	%end;

	%*700.	Replace the current capture buffer with the enclosed list.;
	%*The different character strings have been macro-quoted before.;
	%let	tmpTABLES	=	&Aheadptn.&ptnReplace.&Behindptn.;
%end;
%EndOfNameList:

%*090.	Handle all the Grouping Syntax patterns.;
%*091.	Define the character string pattern that matches a valid Grouping Syntax.;
%*Below pattern searches for all the types of Grouping Syntax:;
%*[a-b];
%*[a--b];
%*[a-numeric-b];
%*[a-character-b];
%*[a-char-b];
%let	prxGS		=	%sysfunc(prxparse(/\b(\w+\s*-\s*((numeric|char(acter)?)?\s*-)?\s*\w+)\b/ismx));
%let	prxGSFst	=	1;
%let	ptnGSBufB	=	0;
%let	ptnGSBufL	=	0;

%*092.	Replace all the patterns of [-]or [--] with actual variable names in the [inDAT], by enclosing the variable list with parentheses.;
%do %while (%sysfunc(prxmatch(&prxGS.,&tmpTABLES.)));
	%*100.	Return the start position and the length of the capture buffer, for later replacement.;
	%syscall	prxposn(prxGS,prxGSFst,ptnGSBufB,ptnGSBufL);

	%*200.	Retrieve the capture buffer that matches the pattern.;
	%let	prxGSBuf	=	%qsysfunc(prxposn(&prxGS.,1,&tmpTABLES.));

	%*400.	Retrieve all the fields by the given pattern.;
	%ResolveHyphenFrDat(
		inSTR	=	%nrbquote(&prxGSBuf.)
		,inDAT	=	&inDAT.
		,nFOUND	=	GnGS
		,eFOUND	=	GeGS
	)

	%*410.	Connect all the variables found in the [inDAT] with WHITE SPACE and enclose the list with parentheses, such as "(a2 a3 a4)".;
	%let	ptnReplace	=;
	%do VFYi=1 %to &GnGS.;
		%let	ptnReplace	=	&ptnReplace. &&GeGS&VFYi..;
	%end;
	%let	ptnReplace	=	%nrbquote((&ptnReplace.));

	%*500.	Determine the character string ahead of the capture buffer.;
	%if	&ptnGSBufB.	=	1	%then %do;
		%let	Aheadptn	=;
	%end;
	%else %do;
		%let	Aheadptn	=	%qsubstr(&tmpTABLES.,1,%eval(&ptnGSBufB. - 1));
	%end;

	%*600.	Determine the character string behind the capture buffer.;
	%if	%eval(&ptnGSBufB. + &ptnGSBufL. - 1)	=	%length(&tmpTABLES.)	%then %do;
		%let	Behindptn	=;
	%end;
	%else %do;
		%let	Behindptn	=	%qsubstr(&tmpTABLES.,%eval(&ptnGSBufB. + &ptnGSBufL.));
	%end;

	%*700.	Replace the current capture buffer with the enclosed list.;
	%*The different character strings have been macro-quoted before.;
	%let	tmpTABLES	=	&Aheadptn.&ptnReplace.&Behindptn.;
%end;
%EndOfGS:

%*100.	Translate the [VAR:] if any.;
%*120.	Define the character string pattern that matches a valid [VAR:] in SAS system.;
%*The pattern must be at most 31 writable characters leading one colon with an alphabetic or underscore at the beginning and \W after it.;
%*Please verify the pattern in here: http://blogs.sas.com/content/sasdummy/2012/08/22/using-a-regular-expression-to-validate-a-sas-variable-name/;
%let	prxVAR		=	%sysfunc(prxparse(/\b(?=.{1,31}:)([[:alpha:]_]\w*:)(?<=\W)/ismx));
%let	prxFIRST	=	1;
%let	ptnBUFbgn	=	0;
%let	ptnBUFlen	=	0;

%*190.	Replace all the patterns of [VAR:] with actual variable names in the [inDAT], by enclosing the variable list with parentheses.;
%do %while (%sysfunc(prxmatch(&prxVAR.,&tmpTABLES.)));
	%*100.	Return the start position and the length of the capture buffer, for later replacement.;
	%syscall	prxposn(prxVAR,prxFIRST,ptnBUFbgn,ptnBUFlen);

	%*200.	Retrieve the capture buffer that matches the pattern.;
	%let	ptnBUFFER	=	%qsysfunc(prxposn(&prxVAR.,1,&tmpTABLES.));

	%*300.	Prepare the RegExp to search for the above capture buffer.;
	%prepStrPatternByCOLList(
		COLlst		=	%nrbquote(&ptnBUFFER.)
		,outPTN		=	LpVARchk
	)

	%*400.	Retrieve all the fields by the given pattern.;
	%getCOLbyStrPattern(
		inDAT		=	&inDAT.
		,inRegExp	=	%nrbquote(&LpVARchk.)
		,exclRegExp	=
		,chkVarTP	=
		,outCNT		=	GnColonVar
		,outELpfx	=	GeColonVar
	)

	%*410.	Connect all the variables found in the [inDAT] with WHITE SPACE and enclose the list with parentheses, such as "(a2 a3 a4)".;
	%let	ptnReplace	=;
	%do VFYi=1 %to &GnColonVar.;
		%let	ptnReplace	=	&ptnReplace. &&GeColonVar&VFYi..;
	%end;
	%let	ptnReplace	=	%nrbquote((&ptnReplace.));

	%*500.	Determine the character string ahead of the capture buffer.;
	%if	&ptnBUFbgn.	=	1	%then %do;
		%let	Aheadptn	=;
	%end;
	%else %do;
		%let	Aheadptn	=	%qsubstr(&tmpTABLES.,1,%eval(&ptnBUFbgn. - 1));
	%end;

	%*600.	Determine the character string behind the capture buffer.;
	%if	%eval(&ptnBUFbgn. + &ptnBUFlen. - 1)	=	%length(&tmpTABLES.)	%then %do;
		%let	Behindptn	=;
	%end;
	%else %do;
		%let	Behindptn	=	%qsubstr(&tmpTABLES.,%eval(&ptnBUFbgn. + &ptnBUFlen.));
	%end;

	%*700.	Replace the current capture buffer with the enclosed list.;
	%*The different character strings have been macro-quoted before.;
	%let	tmpTABLES	=	&Aheadptn.&ptnReplace.&Behindptn.;
%end;
%EndOfMatching:

%*195.	If there is still colon in the whole string, we abandon current process.;
%if	%index(&tmpTABLES.,:)	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]The TABLES provided has abonrmal pattern which cannot be resolved!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*200.	Factorize the above character string into a list that can be used separately for PROC FREQ.;
%Str_Factorization(
	inList		=	&tmpTABLES.
	,LBoundChar	=	%str(%()
	,RBoundChar	=	%str(%))
	,MultiChar	=	%str(*)
	,SplitChar	=	%str( )
	,kGP		=	0
	,nEP		=	0
	,mNest		=	0
	,outCNT		=	GnFREQ
	,outEPfx	=	GeFREQ
)

%*300.	Identify all the variables within each FREQ group.;
%do FREQi=1 %to &GnFREQ.;
	%*100.	Split by Asterisks.;
	%local	Ln&FREQi.V;
	%let	Ln&FREQi.V	=	%eval(%sysfunc(count(&&GeFREQ&FREQi.,*)) + 1);
	%do ASTi=1 %to &&Ln&FREQi.V.;
		%local	Le&FREQi.V&ASTi.;
		%let	Le&FREQi.V&ASTi.	=	%scan(&&GeFREQ&FREQi..,&ASTi.,*);
	%end;

	%*210.	Retrieve the largest number of items among the frequency groups, to determine the number of output variables.;
	%let	LNmaxVAR	=	%sysfunc(max(&LNmaxVAR.,&&Ln&FREQi.V.));
%end;

%*400.	Generate the Frequency Tables.;
proc freq
	data=%unquote(&inDAT.)
%if	&vfyOutDat.	=	0	%then %do;
	%*We only keep the necessary fields for processing.;
	(
		keep=
		%if	%length(%qsysfunc(compress(&byVAR.,%str( ))))	^=	0	%then %do;
			%do GRPk=1 %to &GnPGrpBy.;
				%do SUBi=1 %to &&GprocRX&GRPk.n.;
					&&GprocRX&GRPk.e&SUBi..
				%end;
			%end;
		%end;
			%do FREQi=1 %to &GnFREQ.;
				%do ASTi=1 %to &&Ln&FREQi.V.;
					&&Le&FREQi.V&ASTi..
				%end;
			%end;
	)
%end;
	noprint
;
	%*100.	Handle the BY group.;
%if	%length(%qsysfunc(compress(&byVAR.,%str( ))))	^=	0	%then %do;
	by
	%do GRPk=1 %to &GnPGrpBy.;
		%do SUBi=1 %to &&GprocRX&GRPk.n.;
			%if	&SUBi.	=	1	%then %do;
				%let	LfirstArg	=	&&GAePGrpBy&GRPk..;
			%end;
			%else %do;
				%let	LfirstArg	=;
			%end;

			&LfirstArg.	&&GprocRX&GRPk.e&SUBi.
		%end;
	%end;
	;
%end;

	%*200.	Handle the FORMAT statement if any.;
%if	%length(%qsysfunc(compress(&FmtStmt.,%str( ))))	^=	0	%then %do;
	format
		&FmtStmt.
	;
%end;

	%*900.	Loop to generate the frequency tables.;
%do FREQi=1 %to &GnFREQ.;
	tables
		&&GeFREQ&FREQi.
		/&TableOpt.
		out=&procLIB..__freq_tmp_&FREQi.__
	%if	%index(%qupcase(&TableOpt.),MISSING)	=	0	%then %do;
		(
			where=(1
			%do ASTi=1 %to &&Ln&FREQi.V.;
				and	missing(&&Le&FREQi.V&ASTi..)	=	0
			%end;
			)
		)
	%end;
	;
%end;
run;

%*500.	Retrieve the attributes of each single variable, for the output result to show the user-friendly fashion.;
%*IMPORTANT: The classic PROC FREQ only gets the frequency in terms of the FORMATTED values, rather than the original ones.;
%do FREQi=1 %to &GnFREQ.;
	%*100.	Open the data for the retrieval of variable attributes.;
	%let	DSID	=	%sysfunc(open(&procLIB..__freq_tmp_&FREQi.__));

	%*200.	Retrieval.;
	%do ASTi=1 %to &&Ln&FREQi.V.;
		%*100.	Retrieve the VARNUM of current variable.;
		%let	L_varnum	=	%sysfunc(varnum(&DSID.,&&Le&FREQi.V&ASTi..));

		%*200.	Retrieve its attributes.;
		%local
			Le&FREQi.V&ASTi.vnum
			Le&FREQi.V&ASTi.Type
			Le&FREQi.V&ASTi.fmt
			Le&FREQi.V&ASTi.lbl
			Le&FREQi.V&ASTi.len
			Le&FREQi.V&ASTi.fmtf
		;
		%*Since there could be COMMA in the variable format, we macro-quote the necessary results.;
		%let	Le&FREQi.V&ASTi.vnum	=	&L_varnum.;
		%let	Le&FREQi.V&ASTi.Type	=	%sysfunc(vartype(&DSID.,&L_varnum.));			%*Its value should not be quoted.;
		%let	Le&FREQi.V&ASTi.fmt		=	%qsysfunc(varfmt(&DSID.,&L_varnum.));
		%let	Le&FREQi.V&ASTi.lbl		=	%qsysfunc(varlabel(&DSID.,&L_varnum.));
		%let	Le&FREQi.V&ASTi.len		=	%sysfunc(varlen(&DSID.,&L_varnum.));			%*Its value should not be quoted.;
		%let	Le&FREQi.V&ASTi.fmtf	=	%sysfunc(ifn(&&Le&FREQi.V&ASTi.fmt.=,0,1));

		%*300.	Determine the maximum lengths of the output variables.;
		%*This is to save the program coding by setting length of all the output variables to the maximum one.;
		%let	LNmaxLEN	=	%sysfunc(max(&LNmaxLEN.,&&Le&FREQi.V&ASTi.len.));
		%let	LNmaxLBL	=	%sysfunc(max(&LNmaxLBL.,%length(&&Le&FREQi.V&ASTi.lbl.)));
	%end;

	%*900.	Close the data.;
	%CloseDat:
	%let	rc		=	%sysfunc(close(&DSID.));
%end;

%*510.	We have to make sure the length of the LABEL is at least 1 in the output data.;
%if	&LNmaxLBL.	=	0	%then %do;
	%let	LNmaxLBL	=	1;
%end;

%*600.	Set all the frequency tables.;
data &procLIB..__freq_tmp_4out__;
	%*100.	Prepare the output data structure.;
	%*110.	Put all [byVAR] at the left-most part of the data, since they already exist in the input data.;
	%if	%length(%qsysfunc(compress(&byVAR.,%str( ))))	^=	0	%then %do;
		retain
			%do GRPk=1 %to &GnPGrpBy.;
				%do SUBi=1 %to &&GprocRX&GRPk.n.;
					&&GprocRX&GRPk.e&SUBi..
				%end;
			%end;
		;
	%end;

	%*120.	Here we put the variables as tabulated in the TABLES statement.;
	%*The sequence of below statements should remain on behalf of the readability of the output result.;
	length
		_FREQ_GROUP_	8.
	%do VARi=1 %to &LNmaxVAR.;
		_LABEL_VAR&VARi._	$&LNmaxLBL..
	%end;
	%do VARi=1 %to &LNmaxVAR.;
		_NAME_VAR&VARi._	$32.
	%end;
	%do VARi=1 %to &LNmaxVAR.;
		_VALUE_VAR&VARi._	$&LNmaxLEN..
	%end;
	%do FREQi=1 %to &GnFREQ.;
		_SORT_SEQ&FREQi._	8.
	%end;
	;
		call missing(_FREQ_GROUP_);
	%do VARi=1 %to &LNmaxVAR.;
		call missing(_LABEL_VAR&VARi._);
	%end;
	%do VARi=1 %to &LNmaxVAR.;
		call missing(_NAME_VAR&VARi._);
	%end;
	%do VARi=1 %to &LNmaxVAR.;
		call missing(_VALUE_VAR&VARi._);
	%end;
	if	_N_	=	1	then do;
	%do FREQi=1 %to &GnFREQ.;
		call missing(_SORT_SEQ&FREQi._);
	%end;
	end;

	%*200.	Set all the frequency tables.;
	set
	%do FREQi=1 %to &GnFREQ.;
		&procLIB..__freq_tmp_&FREQi.__(in=_FREQi_&FREQi.)
	%end;
	;

	%*300.	Combine all the variables for output.;
	%do FREQi=1 %to &GnFREQ.;
		if	_FREQi_&FREQi.	then do;
			_FREQ_GROUP_		=	&FREQi.;
			_SORT_SEQ&FREQi._	+	1;
			%do ASTi=1 %to &&Ln&FREQi.V.;
				_LABEL_VAR&ASTi._	=	%sysfunc(quote(%superq(Le&FREQi.V&ASTi.lbl),%str(%')));
				_NAME_VAR&ASTi._	=	upcase(%sysfunc(quote(%superq(Le&FREQi.V&ASTi.),%str(%'))));
				%if &&Le&FREQi.V&ASTi.fmtf. = 0 %then %do;
					_VALUE_VAR&ASTi._	=	strip(&&Le&FREQi.V&ASTi..);
				%end;
				%else %do;
					_VALUE_VAR&ASTi._	=	put(&&Le&FREQi.V&ASTi..,&&Le&FREQi.V&ASTi.fmt.);
				%end;
			%end;
		end;
	%end;

	%*900.	Purge.;
	drop
		%do FREQi=1 %to &GnFREQ.;
			%do ASTi=1 %to &&Ln&FREQi.V.;
				%*Should there be any field existing in the [byVAR] list, we do not drop it.;
				%*100.	Initialize the flag.;
				%let	LchkByVAR	=	1;

				%*200.	Lookup the current variable in the entire [byVAR] list.;
				%if	%length(%qsysfunc(compress(&byVAR.,%str( ))))	^=	0	%then %do;
					%do GRPk=1 %to &GnPGrpBy.;
						%do SUBi=1 %to &&GprocRX&GRPk.n.;
							%if	&&Le&FREQi.V&ASTi..	=	&&GprocRX&GRPk.e&SUBi.	%then %do;
								%let	LchkByVAR	=	0;
							%end;
						%end;
					%end;
				%end;

				%*900.	Only drop it once it exists in [byVAR] list.;
				%if	&LchkByVAR.	=	1	%then %do;
					&&Le&FREQi.V&ASTi..
				%end;
			%end;
		%end;
	;
run;

%*700.	Sort the frequency summary to make it similar to that of the classic PROC FREQ.;
proc sort
	data=&procLIB..__freq_tmp_4out__
;
	by
%if	%length(%qsysfunc(compress(&byVAR.,%str( ))))	^=	0	%then %do;
	%do GRPk=1 %to &GnPGrpBy.;
		%do SUBi=1 %to &&GprocRX&GRPk.n.;
			%if	&SUBi.	=	1	%then %do;
				%let	LfirstArg	=	&&GAePGrpBy&GRPk..;
			%end;
			%else %do;
				%let	LfirstArg	=;
			%end;

			&LfirstArg.	&&GprocRX&GRPk.e&SUBi.
		%end;
	%end;
%end;
		_FREQ_GROUP_
	%do VARi=1 %to &LNmaxVAR.;
		_NAME_VAR&VARi._
	%end;
	%do FREQi=1 %to &GnFREQ.;
		_SORT_SEQ&FREQi._
	%end;
	;
run;

%*800.	Output.;
data %unquote(&outDAT.);
	%*100.	Set the data.;
	set &procLIB..__freq_tmp_4out__;
	by
%if	%length(%qsysfunc(compress(&byVAR.,%str( ))))	^=	0	%then %do;
	%do GRPk=1 %to &GnPGrpBy.;
		%do SUBi=1 %to &&GprocRX&GRPk.n.;
			%if	&SUBi.	=	1	%then %do;
				%let	LfirstArg	=	&&GAePGrpBy&GRPk..;
			%end;
			%else %do;
				%let	LfirstArg	=;
			%end;

			&LfirstArg.	&&GprocRX&GRPk.e&SUBi.
		%end;
	%end;
%end;
		_FREQ_GROUP_
	%do VARi=1 %to &LNmaxVAR.;
		_NAME_VAR&VARi._
	%end;
	%do FREQi=1 %to &GnFREQ.;
		_SORT_SEQ&FREQi._
	%end;
	;

	%*200.	Create the CUM_FREQ and CUM_PCT as the same as in PROC FREQ, given the [FoutCUM] is 1.;
	%if	&FoutCUM.	=	1	%then %do;
		%*100.	Create the fields.;
		format
			CUM_FREQ	8.
			CUM_PCT		best12.
		;
		retain
			CUM_FREQ
			CUM_PCT
		;

		%*200.	Initialize the fields.;
		if	first._FREQ_GROUP_	then do;
			CUM_FREQ	=	0;
			CUM_PCT		=	0;
		end;

		%*300.	Cumulation.;
			CUM_FREQ	+	COUNT;
			CUM_PCT		+	PERCENT;
	%end;

	%*900.	Purge.;
	drop
	%do FREQi=1 %to &GnFREQ.;
		_SORT_SEQ&FREQi._
	%end;
	;
run;

%*900.	Purge.;
%syscall	prxfree(prxNL);
%syscall	prxfree(prxGS);
%syscall	prxfree(prxVAR);

%EndOfProc:
%mend ProcMultiFreq;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvOp"
		"D:\SAS\omnimacro\AdvDB"
	)
	mautosource
;

data a;
	input a1-a3 b2-b5;
cards;
3 5 7 9 4 8 2 1
4 9 5 3 7 8 4 5
3 5 7 0 4 8 7 1
4 4 5 3 7 9 4 5
;
run;

%ProcMultiFreq(
	inDAT		=	a
	,byVAR		=
	,inTABLES	=	%nrbquote(
						a: * b:
					)
	,TableOpt	=	MISSING
	,FoutCUM	=	0
	,FmtStmt	=
	,procLIB	=	WORK
	,outDAT		=	af
)

%*Full Test Program[2]:;
data b;
	input a1-a3 b2-b5;
cards;
3 5 7 9 4 8 2 1
4 9 5 3 . 8 4 5
3 5 7 0 4 8 7 1
4 4 5 3 7 9 . 5
;
run;

%ProcMultiFreq(
	inDAT		=	%nrbquote(b(where=(a1=3)))
	,byVAR		=
	,inTABLES	=	%nrbquote(
						a: * b:
					)
	,TableOpt	=	OUTPCT
	,FoutCUM	=	1
	,FmtStmt	=
	,procLIB	=	WORK
	,outDAT		=	bf
)

%*Full Test Program[3]:;
data b;
	input a1-a3 b2-b5;
cards;
3 5 7 9 4 8 2 1
4 9 5 3 . 8 4 5
3 5 7 0 4 8 7 1
4 4 5 3 7 9 . 5
;
run;

proc sort
	data=b
	out=b1
;
	by a1;
run;

%ProcMultiFreq(
	inDAT		=	b1
	,byVAR		=	a1
	,inTABLES	=	%nrbquote(
						a2-a3 * b:
					)
	,TableOpt	=
	,FoutCUM	=	1
	,FmtStmt	=
	,procLIB	=	WORK
	,outDAT		=	bf
)

%*Full Test Program[4]:;
data a;
	input a1-a3 b5 b2 b3 $1. b4;
cards;
3 5 7 9 4 8 2 1
4 9 5 3 7 8 4 5
3 5 7 0 4 8 7 1
4 4 5 3 7 9 4 5
;
run;

%ProcMultiFreq(
	inDAT		=	a
	,byVAR		=
	,inTABLES	=	%nrbquote(
						a3-a2 * b5 - numeric- b4
						_char_
					)
	,TableOpt	=	MISSING
	,FoutCUM	=	0
	,FmtStmt	=
	,procLIB	=	WORK
	,outDAT		=	af
)
proc freq
	data=a
;
	tables
		a3-a2 * b5 - numeric- b4
		_char_
		/list
		missing
	;
run;

%*Full Test Program[5]:;
%*This is to pressurize the RAM consumption.;
data masFreq;
	label
		a	=	"Value"
		b	=	"Primary"
		a1	=	"Secondary"
		b1	=	"Tertiary"
	;
	do _i = 1 to 50000000;
		a	=	ranuni(0);
		b	=	round(a * 4,1);

		a1	=	round(a * 5,1);
		b1	=	round(a * 6,1);
		output;
	end;
run;

%ProcMultiFreq(
	inDAT		=	masFreq
	,byVAR		=
	,inTABLES	=	%nrbquote(
						b:
						a1	*	b:
					)
	,TableOpt	=
	,FoutCUM	=	1
	,FmtStmt	=
	,procLIB	=	WORK
	,outDAT		=	masFreqRst
)
%*Total Time Consumption: 11.19;

proc freq
	data=masFreq
;
	tables
		b:
		a1	*	b:
		/list
		missing
	;
run;
%*Time Consumption: 10 Seconds;

%*Full Test Program[6]:;
%*This is to test the compatibility of [FORMAT] statement.;
data test;
	format
		d_data	8.
		a_val	best12.
	;
	i=0;
	j=0;
	d_data	=	mdy(1,1,2015);	a_val	=	ranuni(0);	output;
	do i=1 to 11;
		d_data	=	intnx("month",d_data,1,"b");
		do	j=1	to	(round(ranuni(i)*10,1));
			a_val	=	ranuni(j);
			output;
		end;
	end;
run;

proc format;
	value fmtI
		1	-	3	=	"01. A"
		4	-	9	=	"02. B"
		other		=	"99. O"
	;
run;

%ProcMultiFreq(
	inDAT		=	test
	,byVAR		=	d_data
	,inTABLES	=	%nrbquote(
						i	*	j
					)
	,TableOpt	=
	,FoutCUM	=	1
	,FmtStmt	=	%nrbquote(
						d_data	yymmddD10.
						i		fmtI.
					)
	,procLIB	=	WORK
	,outDAT		=	testFreq
)

proc freq
	data=test
	noprint
;
	by
		d_data
	;
	format
		d_data	yymmddD10.
		i		fmtI.
	;
	tables
		i * j
		/
		out=testfreqOrg
	;
run;

/*-Notes- -End-*/