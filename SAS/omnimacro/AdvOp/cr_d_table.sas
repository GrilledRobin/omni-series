%macro cr_d_table;
	format	D_TABLE	yymmddD10.;
	length	D_TABLE	8.;
	label	D_TABLE	=	"Date of Table";
	D_TABLE	=	mdy(&G_cur_mth.,&G_cur_day.,&G_cur_year.);
%mend;