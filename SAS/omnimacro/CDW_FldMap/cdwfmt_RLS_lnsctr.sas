%macro cdwfmt_RLS_lnsctr;
	*******************************************************
	format for Product Type Mapping by Loan Product
	*******************************************************
	;
%*NOTE: Here the 2-digit product codes are from RLS SECTOR CODE;
	%*Below is when fund code equals "10";
	value $cdwfmt_LNsctr_10a(min=32)
		'10'				=	'Resi.CP'
		'11'				=	'Resi.CP Prime Based'
		'12'				=	'Resi.CP MTL Quota'
		'20'				=	'Resi.PUC'
		'21'				=	'Resi.PUC Prime Based'
		'22'				=	'Resi.PUC MTL Quota'
		'25'				=	'Comm.PUC'
		'30'				=	'Resi.EL Clean'
		'31'				=	'Resi.EL Clean Prime Based'
		'32'				=	'Resi.EL Clean MTL Quota'
		'40'				=	'Resi.EL Cash Out'
		'41'				=	'Resi.EL Cash Out Prime Based'
		'42'				=	'Resi.EL Cash Out MTL Quota'
		'45'				=	'Comm.EL Cash Out'
		'50'				=	'Resi.Car Park CP'
		'51'				=	'Resi.Car Park PUC'
		'55'				=	'Comm.CP'
		'70'				=	'Comm.EL Clean'
		'80'				=	'Emp.House Loan CP'
		'85'				=	'Emp.House Loan PUC'		
		'88'				=	'BIL'
		'89'				=	'LAP'
		'90'				=	'RLS CPML'
		'93'	-	'96'	=	'RLS TermLoan'
		other				=	'Others'
	;
	%*Below is when fund code equals "20";
	value $cdwfmt_LNsctr_20a(min=32)
		'10'				=	'BIL'
		'88'				=	'BIL'
		'89'				=	'LAP'
		'90'				=	'CNY CPML'
		'91'				=	'USD CPML'
		'92'				=	'HKD CPML'
		'93'	-	'96'	=	'TermLoan'
		other				=	'Others'
	;
	value $cdwfmt_LNsctr_20b(min=32)
		'10'				=	'BIL'
		'88'				=	'BIL'
		'89'				=	'LAP'
		'90'	-	'92'	=	'CPML'
		'93'	-	'96'	=	'TermLoan'
		other				=	'Others'
	;
	%*Below is when fund code equals "30";
	value $cdwfmt_LNsctr_30a(min=32)
		'10'				=	'CCPL'
		'11'				=	'Multi Tier'
		'12'				=	'POS Single Tier'
		'13'				=	'POS Multi Tier'
		other				=	'Others'
	;
	%*Below is when fund code equals "10";
		value $cdwfmt_LNsctr_psgl_MTG(min=32)
		'10'				=	'170'
		'11'				=	'170'
		'12'				=	'169'
		'20'				=	'170'
		'21'				=	'170'
		'22'				=	'169'
		'25'				=	'171'
		'30'				=	'170'
		'31'				=	'170'
		'32'				=	'169'
		'40'				=	'170'
		'41'				=	'170'
		'42'				=	'169'
		'45'				=	'171'
		'50'				=	'170'
		'51'				=	'170'
		'55'				=	'171'
		'70'				=	'171'
		'80'				=	'170'
		'85'				=	'170'		
		other				=	'Others'
	;
	
	
	
	
%mend cdwfmt_RLS_lnsctr;