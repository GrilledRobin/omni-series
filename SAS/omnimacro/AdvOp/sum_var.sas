%macro sum_var(invar=,outvar=,outlbl=);
	retain	&outvar. 0;
	label	&outvar.	=	"&outlbl.";
	&outvar.+&invar.;
	keep	&outvar.;
%mend;