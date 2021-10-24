%macro STXR_DumpFLD(
	insheetnm	=
	,valin		=
	,cell1row	= 1
	,cell1col	= 1
);
	%*let	insheetnm	=	%unquote(&insheetnm.);
	%*let	valin		=	%unquote(&valin.);
	%let	cell1row	=	%unquote(&cell1row.);
	%let	cell1col	=	%unquote(&cell1col.);

	%* While we at at it, we also define the DDE link to the section of the spreadsheet;
	%* where the actual data will be written.;
	filename
		xlsheet
		dde
		"excel|&savepath.\[&savename.&EnviroEXT.]&insheetnm.!&r.&cell1row.&c.&cell1col."
		notab
		lrecl = 200
	;

	%* After all that preparation, we finally pour in the data!;
	data _null_;
		file xlsheet notab;
		put "&valin.";
	run;

	%*Internal Cleansing of the "filename".;
	filename	xlsheet	clear;

%EndOfProc:
%mend STXR_DumpFLD;