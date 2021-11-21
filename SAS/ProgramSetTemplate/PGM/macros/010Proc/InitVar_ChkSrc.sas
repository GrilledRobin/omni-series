%macro InitVar_ChkSrc;
format
	C_SRC_NAME	$256.
	C_SRC_PATH	$512.
	C_MED_PATH	$512.
	C_DES_PATH	$512.
	C_SRC_TYPE	$64.
	F_SRC_MISS	8.
;
length
	C_SRC_NAME	$256.
	C_SRC_PATH	$512.
	C_MED_PATH	$512.
	C_DES_PATH	$512.
	C_SRC_TYPE	$64.
	F_SRC_MISS	8.
;
label
	C_SRC_NAME	=	"File Name of the Source"
	C_SRC_PATH	=	"Location where to retrieve the Source File"
	C_MED_PATH	=	"Location on the temporary media where to transport the Source File"
	C_DES_PATH	=	"Location on the destination where to store the Source File"
	C_SRC_TYPE	=	"Type of the Source File"
	F_SRC_MISS	=	"Flag of whether the required Source File is missing at the destination"
;
	C_SRC_NAME	=	"";
	C_SRC_PATH	=	"";
	C_MED_PATH	=	"";
	C_DES_PATH	=	"";
	C_SRC_TYPE	=	"";
	F_SRC_MISS	=	.;
keep
	C_SRC_NAME
	C_SRC_PATH
	C_MED_PATH
	C_DES_PATH
	C_SRC_TYPE
	F_SRC_MISS
;
%mend InitVar_ChkSrc;