%macro cdwmap_SME_TradeAsset(
	inPRODCODE	=
	,outFLD		=
);
&outFLD. = 'NON-ASSET';

if	&inPRODCODE.	in	('440','441','442','449','450','500','501','509','555')
	then	&outFLD.	=	'IMPORT';
if	&inPRODCODE.	in	('460','470','471','481','550','551')
	then	&outFLD.	=	'EXPORT';
if	&inPRODCODE.	in	('490','494','495','483')
	then	&outFLD.	=	'DISC';
%mend cdwmap_SME_TradeAsset;

/*
This macro is for CDW to map the specific trade type.
*/