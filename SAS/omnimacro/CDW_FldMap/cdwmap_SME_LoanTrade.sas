%macro cdwmap_SME_LoanTrade(
	inPRODCODE	=
	,outFLD		=
	,outType		=
);
&outFLD. = 'Off-Bal';


if	&inPRODCODE.	in	(
		'440'
		'441'
		'442'
		'449'
		'450'
		'460'
		'470'
		'471'
		'481'
		'483'
		'490'
		'494'
		'495'
		'500'
		'501'
		'509'
		'555'
		'550'
		'551'
		'521'
		'569'

	)
	then do;
	%*****As Loan, DD***************;
	&outFLD.	=	'On-Bal';
	&outType.	=	"TradeLoan-OTH";

	if	&inPRODCODE.	in	(
		'440'
		'441'
		'442'
		'449'
		'450'
		'500'
		'501'
		'509'
		'555'

		)
		then do;
		%*****As Loan, DD***************;
		&outType.	=	"TradeLoan-Imp";
	end;

	if	&inPRODCODE.	in	(
		'460'
		'470'
		'471'
		'481'
		'550'
		'551'

		)
		then do;
		%*****As Loan, DD***************;
		&outType.	=	"TradeLoan-Exp";
	end;

	if	&inPRODCODE.	in	(
		'483'
		'490'
		'494'
		'495'

		)
		then do;
		%*****As Loan, DD***************;
		&outType.	=	"TradeLoan-Dis";
	end;
end;

%mend cdwmap_SME_LoanTrade;

/*
This macro is for CDW to map the specific trade type.
*/