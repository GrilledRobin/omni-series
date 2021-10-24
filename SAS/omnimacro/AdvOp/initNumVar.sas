%macro initNumVar(
	arrNAME=
	,tmpFLD=
);
%let	arrNAME	=	%unquote(&arrNAME.);
%if	%length(%qsysfunc(compress(&arrNAME.,%str( ))))	=	0	%then	%let	arrNAME	=	arrTMP;
array &arrNAME. _NUMERIC_;
do over &arrNAME.;
%*	if	missing(&arrNAME.)	then	&arrNAME.	=	0;
	&arrNAME.	=	sum(0,&arrNAME.);
end;
%mend initNumVar;