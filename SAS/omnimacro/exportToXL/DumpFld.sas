%macro DumpFld(
	insheetnm	=
	,valin		=
	,cell1row	= 1
	,cell1col	= 1
	,mergeacross	= 1
	,mergedown	= 1
);
	%* We then do some basic parameter checking.;
	%if	( "&cell1row" = "" )	%then %do;
		%let cell1row = 1;
		%put;
		%put &sasnote: The default value of the CELL1ROW parameter appears to have been;
		%put ----- overwritten by a null value during invocation of the EXPORTTOEXCEL;
		%put ----- macro. It has been reset to '1' in order to allow macro execution.;
		%put;
	%end;

	%if	( "&cell1col" = "" )	%then %do;
		%let cell1col = 1;
		%put;
		%put &sasnote: The default value of the CELL1COL parameter appears to have been;
		%put ----- overwritten by a null value during invocation of the EXPORTTOEXCEL;
		%put ----- macro. It has been reset to '1' in order to allow macro execution.;
		%put;
	%end;

	%if	( "&mergeacross" = "" )	%then %do;
		%let mergeacross = 1;
		%put;
		%put &sasnote: The default value of the MERGEACROSS parameter appears to have been;
		%put ----- overwritten by a null value during invocation of the EXPORTTOEXCEL;
		%put ----- macro. It has been reset to '1' in order to allow macro execution.;
		%put;
	%end;

	%if	( "&mergedown" = "" )	%then %do;
		%let mergedown = 1;
		%put;
		%put &sasnote: The default value of the MERGEDOWN parameter appears to have been;
		%put ----- overwritten by a null value during invocation of the EXPORTTOEXCEL;
		%put ----- macro. It has been reset to '1' in order to allow macro execution.;
		%put;
	%end;

	%* All necessary variables should be defined for possible formatting;
	%let	ulrowlab	=	&cell1row;
	%let	ulcollab	=	&cell1col;
	%let	lrrowlab	=	%eval( &cell1row + &mergedown - 1 );
	%let	lrcollab	=	%eval( &cell1col + &mergeacross - 1 );
	%* Calculate the range of cells to which the real data will be written. The upper left ;
	%* cell is obviously defined by (&CELL1ROW,&CELL1COL).                               ;
	%let	ulrowdat	=	&cell1row;
	%let	ulcoldat	=	&cell1col;
	%let	lrrowdat	=	%eval( &cell1row + &mergedown - 1 );
	%let	lrcoldat	=	%eval( &cell1col + &mergeacross - 1 );

	%* While we at at it, we also define the DDE link to the section of the spreadsheet;
	%* where the actual data will be written.;
	filename
		xlsheet
		dde "excel|&savepath\[&savename..xls]&insheetnm!&r&cell1row&c&cell1col"
		notab
		lrecl = 200
	;

	%* After all that preparation, we finally pour in the data!;
	data _null_;
		file xlsheet notab;
		put "&valin.";
	run;

%DFcheckend:;
%mend;