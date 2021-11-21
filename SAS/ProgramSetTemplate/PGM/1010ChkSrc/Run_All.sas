options
	nomprint
	nomlogic
	nosymbolgen
	sortsize	=	2000M
	sumsize		=	2000M
;

%*100.	Find necessary SAS programs.;
%*Below macro is from "&cdwmac.\AdvOp";
%getFILEbyStrPattern(
	inFDR		=	%nrbquote(&curroot.)
	,inRegExp	=	%nrbquote(^run\d{3}.*\.sas\b)
	,exclRegExp	=	%nrbquote(bak)
	,outCNT		=	LnRunAll
	,outELpfx	=	LeRunAll
)

%*200.	Run the found programs in numeric order.;
%macro runAllProg;
	%put	LnRunAll=&LnRunAll.;
	%if	&LnRunAll.>0	%then %do;
		%do RUNi=1 %to &LnRunAll.;
			%include	"&curroot.\&&LeRunAll&RUNi..";
		%end;
	%end;
%mend runAllProg;
%runAllProg

%*Below macro is from "&cdwmac.\AdvOp";
%KillLib(
	inLIB	=	work2
)