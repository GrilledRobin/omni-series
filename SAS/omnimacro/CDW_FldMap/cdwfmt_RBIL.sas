%macro cdwfmt_RBIL;
	*******************************************************
	format for R-BIL Product Type mapping
	*******************************************************
	;
	value cdwfmt_RBILbyDDAmt
		600000	-<	800000	=	"R-BIL1"
		800000	-	high	=	"R-BIL2"
		other	=	"BIL"
	;

	*******************************************************
	format for R-BIL Product Category mapping
	*******************************************************
	;
	value $cdwfmt_RBILcat
		"R-BIL1"	=	"R-BIL"
		"R-BIL2"	=	"R-BIL"
	;
%mend cdwfmt_RBIL;