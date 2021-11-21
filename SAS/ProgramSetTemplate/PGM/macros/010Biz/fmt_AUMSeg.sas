%macro fmt_AUMSeg;
%*100.	AUM Category for the temporary reporting purpose.;
value f_AUMseg_a(min=16)
	6000000	-	high	=	"TAUM001"
	3000000	-<	6000000	=	"TAUM002"
	1000000	-<	3000000	=	"TAUM003"
	500000	-<	1000000	=	"TAUM004"
	200000	-<	500000	=	"TAUM005"
	10000	-<	200000	=	"TAUM006"
	0		<-<	10000	=	"TAUM007"
	low		-	0		=	"TAUM008"
;
%mend fmt_AUMSeg;