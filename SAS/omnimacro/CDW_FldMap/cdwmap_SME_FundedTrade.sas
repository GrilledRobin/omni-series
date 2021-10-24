%macro cdwmap_SME_FundedTrade(
	inPRODCODE	=
	,inACCLSS	=
	,outFLD		=
);
&outFLD. = 'Non-Funded';

%*IF	&inPRODCODE.	in	('300','440','441','442','449','450','460','470','471','481','490','495')
then	&outFLD.	=	'Funded';

%*20111223;
if	&inPRODCODE.	in	(
		'470'
		'471'
		'490'
		'500'
		'531'
		'533'
		'535'
		'550'
		'551'
		'555'
		'494'
		'495'
		'569'
		'440'
		'449'
		'483'
		'442'
		'481'
		'501'
		'509'
		'521'
		'569'
	)
	then do;
	&outFLD.	=	'Funded';
end;
if	&inPRODCODE.	in	(
		'490'
		'531'
		'533'
		'535'
	)
	then do;
	if	&inACCLSS.	in	("188102")	then do;
		&outFLD.	=	'Non-Funded';
	end;
end;
%mend cdwmap_SME_FundedTrade;

/*
This macro is for CDW to map the specific trade type.
*/