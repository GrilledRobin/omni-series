%macro cdwmap_Offshore(
	inPRODCODE	=
	,outFLD		=
);
%*001.	Glossary.;
%*inPRODCODE	:	Field of EBBS Product Code.;
%*outFLD		:	Output Field.;

%*999.	Make Statements.;
&outFLD. = 'On-shore';

%*Since 2008.;
%*IF		(&inACCTCLSS.	=	'221051'	AND	&inPRODCODE.	in	('282'))
	or	(&inACCTCLSS.	=	'231001'	AND	&inPRODCODE.	in	('281','282','283','285','287','319'))
	or	(&inACCTCLSS.	=	'233105'	AND	&inPRODCODE.	in	('512','513','515','516','517'))
	or	(&inACCTCLSS.	=	'233126'	AND	&inPRODCODE.	in	('617'))
	or	(&inACCTCLSS.	=	'233174'	AND	&inPRODCODE.	in	('618'))
	or	(&inACCTCLSS.	=	'287551'	AND	&inPRODCODE.	in	('281','282','283'))
then	&outFLD.	=	'Off-shore';

%*20120712;
if	&inPRODCODE.	in	(
		'104'	'106'	'108'	'110'	'112'	'114'	'116'	'120'	'153'	'154'
		'219'	'231'	'232'	'233'	'235'	'236'	'240'	'281'	'282'	'283'	'285'	'286'	'287'	'290'
		'311'	'312'	'313'	'314'	'319'	'359'
		'511'	'512'	'513'	'514'	'515'	'516'	'518'	'522'
		'617'	'618'	'630'
		'706'	'710'	'716'	'720'	'753'
	)	then do;
	&outFLD.	=	'Off-shore';
end;
%mend cdwmap_Offshore;

/*
This macro is for CDW to map the specific record with a new category.
*/