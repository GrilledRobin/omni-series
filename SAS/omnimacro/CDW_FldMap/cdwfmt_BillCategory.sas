%macro cdwfmt_BillCategory;
	*******************************************************
	format for Bill Category mapping by Bill Type
	*******************************************************
	;
	value $cdwfmt_BILLCAT_a
		'ADW'	=	'BAD'
		'CBNC'	=	'CBN'
		'CBND'	=	'CBN'
		'CBNW'	=	'CBN'
		'LBDW'	=	'BAD'
		'LBDR'	=	'BAD'
		'CBWS'	=	'CBN'
		'OB'	=	'CBN'
	;
%*		other	=	'Excl. CBN';

	*******************************************************
	format for Bill Category mapping by EBBS Acct Class
	*******************************************************
	;
	value $cdwfmt_ACLS_BILLCAT_a
		'133555'	=	'BAD'
		'132701'	=	'CBN'
		'132702'	=	'CBN'
		'132704'	=	'CBW'
	;

	*******************************************************
	format for Bill Category mapping by PSGL Acct Class
	*******************************************************
	;
	value $cdwfmt_ACLS_BILLCAT_b
		'133555'	=	'BAD'
		'132701'	=	'CBN'
		'132702'	=	'CBN'
		'132704'	=	'CBW'
	;
%mend cdwfmt_BillCategory;