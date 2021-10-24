%macro GetLastDat(
	inLIB	=
	,inPRFX	=
	,outVAR	=
	,tmpLIB	=	WORK
	,tmpDAT	=	_DATchk
	,COND	=
);
%if	%bquote(&tmpLIB.)	EQ	%then	%let	tmpLIB	=	work;
%if	%bquote(&tmpDAT.)	EQ	%then	%let	tmpDAT	=	_DATchk;
%if	%bquote(&COND.)		EQ	%then	%let	COND	=	%str(memname^="");

proc sql noprint;
	create table &tmpLIB..&tmpDAT.(where=(missing(memname)=0)) as (
		select memname
		from dictionary.members
		where compress(libname)	=	upcase("&inLIB.")
			and	memtype	=	"DATA"
			and	index(memname,upcase("&inPRFX."))	=	1
			and	(&COND.)
	)
	order by
		memname
	;
quit;

data _NULL_;
	set
		&tmpLIB..&tmpDAT.
		end=EOF
	;
		by memname;
	if	EOF	then call symputx("&outVAR.",memname,"G");
run;
%mend;

/*
inLIB	:	The LIBrary where to search the dataset
inPRFX	:	The PReFiX of the dataset to be searched
outVAR	:	The macro VARiable storing the dataset name
tmpLIB	:	The LIBrary where to process
tmpDAT	:	The DATaset name storing the partial vtable
*/