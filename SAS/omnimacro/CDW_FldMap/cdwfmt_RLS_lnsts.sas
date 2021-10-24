%macro cdwfmt_RLS_lnsts;
	*******************************************************
	format for Loan Status mapping in RLS
	*******************************************************
	;
	value $cdwfmt_LnSts(min=32)
		"01"	=	"take on"
		"04"	=	"pending document/information"
		"06"	=	"pending repayment account"
		"09"	=	"cancelled - incomplete info"
		"10"	=	"application pending approval"
		"11"	=	"pending lending's approval"
		"12"	=	"approve in principal"
		"13"	=	"counter-offer"
		"20"	=	"declined-policy related"
		"21"	=	"withdrawn (deleted)"
		"22"	=	"decline"
		"23"	=	"declined-borrower risks"
		"24"	=	"declined - a/c experience"
		"26"	=	"declined - existing credit"
		"28"	=	"declined - security risks"
		"29"	=	"declined - sensitive"
		"30"	=	"approved"
		"39"	=	"loan drawndown today"
		"40"	=	"withdrawn after approval"
		"41"	=	"withdrawn before approval"
		"50"	=	"progress payment"
		"53"	=	"progress paymt - approved lsgr"
		"55"	=	"progress payment int suspended"
		"57"	=	"progressive payment - prov"
		"60"	=	"current"
		"61"	=	"expired overdue a/c (cvted ln)"
		"65"	=	"interest-in-suspense"
		"67"	=	"bad debt provision"
		"69"	=	"under redemption arrangement"
		"70"	=	"instalment commenced"
		"80"	=	"loan fully repaid"
		"81"	=	"early redemption"
		"82"	=	"disc under int in susp status"
		"83"	=	"disc with susp int written off"
		"84"	=	"discharge under bad debt status"
		"86"	=	"discharge with bad debt"
		"87"	=	"discharge under bank resell"
		"88"	=	"discharge by reselling"
		"89"	=	"discharged"
	;
/*
	value $cdwfmt_LnSts2 (min=15)                     
	   "30" 	=	"Approved"  
	   "60"-"80"=	"Active" 
	   "81" 	=	"EarlyRedemption"  
	   "82-89" 	=	"Discharge"
	   other	=	"---"                      
   ;
*/
%mend cdwfmt_RLS_lnsts;