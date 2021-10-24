%macro ProcPseudoSort(
	inDAT		=
	,ByVar		=
	,procLIB	=	WORK
	,outVIEW	=
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to create a dummy view for the given data that supports the BY statement									|
|	| during the DATA step.																												|
|	|The VIEW is supposed to be of the same usage as when the given data is sorted in terms of SORT procedure.							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDAT		:	Dataset name in which variables or columns should be searched.														|
|	|ByVar		:	The BY group to group the result. The input data should be sorted before calling this procedure.					|
|	|procLIB	:	The working library.																								|
|	|outVIEW	:	The output data in the same format as that from the DISTANCE procedure in SAS.										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20150204		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170810		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Minimize the use of macro quoting functions to avoid the overflow of macro-quoting layers.									|
|	|      |Concept:																													|
|	|      |If some value is macro-quoted, its quoting status will be inherited to all the subsequent references unless it is modified	|
|	|      | by another macro function (adding additional characters before or after it will have no effect, e.g. [aa&bb.cc]).			|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180310		| Version |	1.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Please find the attachments for examples.																							|
|	|If the SAS version is below 9.2, the composite key [ByVar] should be UNIQUE in [inDAT], for the tag "multidata:"					|
|	| is not supported.																													|
|	|Currently this procedure does not handle the sort sequence OTHER THAN "ascending", hopefully this can be							|
|	| enhanced in the future, i.e. supporting cases like "a descending b c".															|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ErrMcr																															|
|	|	|prepStrPatternByCOLList																										|
|	|	|getCOLbyStrPattern																												|
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
%if	%length(%qsysfunc(compress(&inDAT.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No dataset is provided! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))	=	0	%then	%let	procLIB	=	WORK;

%if	%length(%qsysfunc(compress(&outVIEW.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No output data is specified! Program is interrupted!;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	%qupcase(&outVIEW.)	=	%qupcase(&inDAT.)	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]The view cannot refer to the data of the same name!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*090.	Parameters;
%local
	LstGrp
	GRPi
	SUBi
	LArg
	LGrpQC
	LGrpC
;
%let	LstGrp	=;
%let	LGrpQC	=;
%let	LGrpC	=;

%*100.	Identify all variables in the BY group.;
%*110.	Prepare the RegExp to search for the variables provided.;
%prepStrPatternByCOLList(
	COLlst		=	&ByVar.
	,chkArg		=	1
	,ArgLst		=	DESCENDING
	,nPTN		=	GnPTN
	,ePTN		=	GePTN
	,OchkArg	=	GAePTN
	,outPTN		=	LstGrp
)

%*120.	Prepare the BY statement.;
%*Please refer to the attachment after the %MEND statement: #REF-001;
%*PPS	:	Proc Pseudo Sort;
%*RX	:	Regular Expression;
%do GRPi=1 %to &GnPTN.;
	%*100.	Retrieve all the matching variables for current sub-pattern.;
	%*Here we benefit from below macro in that all the variables retrieved are in VARNUM sequence.;
	%getCOLbyStrPattern(
		inDAT		=	&inDAT.
		,inRegExp	=	&&GePTN&GRPi..
		,exclRegExp	=
		,chkVarTP	=
		,outCNT		=	GPPSRX&GRPi.n
		,outELpfx	=	GPPSRX&GRPi.e
	)

	%*200.	Prepare the statement.;
	%*In current sub-group of variables, the argument is only effective for the FIRST one.;
	%do SUBi=1 %to &&GPPSRX&GRPi.n.;
		%if	&SUBi.	=	1	%then %do;
			%let	LArg	=	&&GAePTN&GRPi..;
		%end;
		%else %do;
			%let	LArg	=;
		%end;

		%*For below character strings, we discard the arguments [LArg].;
		%let	LGrpQC	=	&LGrpQC.,"&&GPPSRX&GRPi.e&SUBi.";
		%let	LGrpC	=	&LGrpC.,&&GPPSRX&GRPi.e&SUBi.;
	%end;
%end;
%let	LGrpQC	=	%qsubstr(%nrbquote(&LGrpQC.),2);
%let	LGrpC	=	%qsubstr(%nrbquote(&LGrpC.),2);

%*800.	Declaration.;
%if	&sysver.	<	9.2	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]SAS version [9.2] or later is required to support tag "multidata" in Hash Object.;
%end;

%*900.	Create Dummy View to pretend as if the [inDAT] were properly sorted.;
%*Below program refers to the topic "NESUG 2011 Large Data Sets - NESUG | Northeast SAS Users Group";
%*Website: http://www.nesug.org/Proceedings/nesug11/ld/ld01.pdf;
%*The tag "multidata" is only available in SAS 9.2 or later.;
%*The reason why the tag "ordered" is not parameterized is that it is intended to enhance the function by;
%* supporting cases like "a descending b c", where each single variable should be kept in an individual hash;
%* instance with specific ordering command.;
data %unquote(&outVIEW. / view= &outVIEW.);
	dcl hash H (
		ordered: 'A'
	%if	&sysver.	>=	9.2	%then %do;
		,multidata: 'Y'
	%end;
	) ;														%*declare ordered hash, allow for dup keys		;
	dcl hiter I ('H') ;										%*need hash iterator to scroll thru table		;
	H.definekey (%unquote(&LGrpQC.)) ;						%*store [GrpBy] in the key portion of hash		;
	H.definedata (%unquote(&LGrpQC.), 'RID') ;				%*store both [GrpBy] and RID in data portion	;
	H.definedone () ;										%*check if valid and instantiate				;
	if 0 then set %unquote(&inDAT.);						%*need empty read to compile [inVAR]			;
	do RID = 1 by 1 until (eof) ;							%*use RID to enumerate file records				;
		set
			%unquote(&inDAT.)(
				keep=
					%do GRPi=1 %to &GnPTN.;
						%do SUBi=1 %to &&GPPSRX&GRPi.n.;
							&&GPPSRX&GRPi.e&SUBi.
						%end;
					%end;
			)
			end = eof
		;													%*read record from [inDB], keep [GrpBy] only	;
		h.add() ;											%*add next [GrpBy] and RID to hash				;
	end ;													%*at this point hash H is loaded				;
	do _iorc_ = I.first() by 0								%*point iterator to lowest [GrpBy] in hash		;
		while (_iorc_ = 0) ;								%*loop while next() still gets entries			;
		set %unquote(&inDAT.) point = RID ;					%*use RID from hash to read disk record			;
		output ;											%*output record									;
		_iorc_ = I.next() ;									%*point iterator to next hash entry				;
	end ;													%*_iorc_ ne 0 means all entries listed			;
	stop ;													%*stop DATA step execution						;
run ;
%EndOfCrView:

%EndOfProc:
%mend ProcPseudoSort;

/*#REF-001 Begin* /
Test Case:
data testdesc;
	a2=1;a1=3;output;
	a2=1;a1=4;output;
	a2=2;a1=1;output;
run;
proc sort
	data=testdesc
	out=testsrt
;
	by
		descending a:
	;
run;
data test2;
	set testsrt;
	by
		a:
	;
run;

Conclusion:
(1)If colon(:) is used, SAS sorts the first variable in terms of VARNUM in DESCENDING order,
    while for the rest ones in ASCENDING order.
(2)If DESCENDING argument is used, during the SET statement in DATA step, the same variable
    cannot be "BY"ed as ASCENDING order.
(3)For any case with ARGUMENT involved, we should keep the statement sequence the same as
    provided to prevent unexpected results.

Example:
For the case ByVar="a: descending b:", where below variables are in the given data:
    VARNUM=1 B2
    VARNUM=2 A1
    VARNUM=3 B1
    we should prepare the SORT statement as below:
    "A1 DESCENDING B2 B1"
    just to create the same effect as when we use SORT procedure.
That is also why we cannot simply call below macro for sorting:
%getCOLbyStrPattern(
	inDAT		=	%nrbquote(&inDAT.)
	,inRegExp	=	%nrbquote(&LstGrp.)
	,exclRegExp	=
	,chkVarTP	=
	,outCNT		=	GnPPSByVar
	,outELpfx	=	GePPSByVar
)
/*#REF-001 End*/

/*#REF-002 Begin* /
It is found that the COMPOSITE sort into VIEW is inapplicable.
Below program shows the result.
(1)If we create a physical data, the program can successfully run.
(2)If we intend to create a VIEW, it fails in "Read Access Violation".
"test - view.sas"
/*#REF-002 End*/