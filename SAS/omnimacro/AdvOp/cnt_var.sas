%macro cnt_var(outvar=,outlbl=);
	retain	&outvar. 0;
	label	&outvar.	=	"&outlbl.";
	&outvar.+1;
	keep	&outvar.;
%mend;