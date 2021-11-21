%macro InitVar_KPIData;
format
	nc_branch_cd	$8.
	c_branch_nm		$16.
	c_city_name		$16.
	nc_cifno		$32.
	C_KPI_ID		$16.
	A_KPI_VAL		best32.
;
length
	nc_branch_cd	$8.
	c_branch_nm		$16.
	c_city_name		$16.
	nc_cifno		$32.
	C_KPI_ID		$16.
;
nc_branch_cd	=	"";
c_branch_nm		=	"";
c_city_name		=	"";
nc_cifno		=	"";
C_KPI_ID		=	"";
A_KPI_VAL		=	.;
keep
	nc_branch_cd
	c_branch_nm
	c_city_name
	nc_cifno
	C_KPI_ID
	A_KPI_VAL
;
%mend InitVar_KPIData;