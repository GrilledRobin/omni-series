%macro DumpDat(
	insheetnm	=
	,libin		= work
	,dsin		=
	,cell1row	= 1
	,cell1col	= 1
	,nrows		=
	,ncols		=
	,sumvars	=
	,statvars	=
	,weightvar	=
	,mergeacross	= 1
	,mergedown	= 1
	,exportheaders	= no
	,exportvarfmts	= no
);
	%local insheetnm ncols1 nrows1;

	%* We then do some basic parameter checking.;
	%if ( "&libin" = "" ) %then %do;
		%put &saserror: The LIBIN parameter is missing in a call to the EXPORTTOEXCEL macro!;
		%let misspar = 1;
	%end;

	%if ( "&dsin" = "" ) %then %do;
		%put &saserror: The DSIN parameter is missing in a call to the EXPORTTOEXCEL macro!;
		%let misspar = 1;
	%end;

	%* For the above errors, we exit first out of this macro, then out of EXPORTTOEXCEL;
	%* entirely. We assume that, if either &DSIN or &LIBIN are not given, the template;
	%* sheet is not to be exported, regardless of the value of &EXPORTTMPLIFEMPTY. That;
	%* is, if we do not even have the names of the library or data set, we should not go;
	%* any further.;
	%if &misspar %then %do;
		%put;
		%put &saserror: The EXPORTTOEXCEL macro bombed due to errors...;
		%put;
		%goto DDcheckend;
	%end;

	%* If the data set does not exist, we can either export the template (if there is one);
	%* or export nothing at all, depending on the value of &EXPORTTMPLIFEMPTY. This way;
	%* allows for user variation -- e.g., the user can type in 'no', 'false', or '0'.;  
	%if %sysfunc( exist( &libin..&dsin ) ) = 0	%then %do;
		%put &sasnote: The input SAS data set &libin..&dsin does not exist!  Nothing will be exported.;
		%if	%among( %upcase( %substr( &exporttmplifempty, 1, 1 ) ), N F 0 )	%then %let misspar = 1;
/*
		%if	%upcase( %substr( &exporttmplifempty, 1, 1 ) ) = N
			or %upcase( %substr( &exporttmplifempty, 1, 1 ) ) = F
			or %substr( &exporttmplifempty, 1, 1 ) = 0
			%then %let misspar = 1;
*/
		%else %let missparexptmpl = 1;
		%goto DDcheckend;
	%end;

	%* If we are still there, we fill in the values of some of the optional parameters;
	%* that were either left blank, or were inadvertently reset to blank in the macro;
	%* call.;
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

	%* Now that the notes are turned off, we define a couple macro variables. Doing it;
	%* this way allows user variation -- e.g., the user can type in 'yes', 'TRUE', or '1'.;
	%if %among( %upcase( %substr( &exportheaders, 1, 1 ) ), Y T 1 ) %then %let printHeaders = 1;

	%* We then continue the parameter checking -- here we first check if it is an empty;
	%* data set (no rows/columns), then correct inappropriate values of &NROWS or &NCOLS.;
	proc sql noprint;
		select trim( left( put( nobs, 20. ) ) ) into :nrows1
		from sashelp.vtable
		where ( libname = upcase( "&libin" ) ) and ( memname = upcase( "&dsin" ) );
	quit;

	proc sql noprint;
		select trim( left( put( nvar, 20. ) ) ) into :ncols1
		from sashelp.vtable
		where ( libname = upcase( "&libin" ) ) and ( memname = upcase( "&dsin" ) );
	quit;

	%if &ncols1 = 0 %then %do;
		option notes;
		%put &sasnote: The input SAS data set &libin..&dsin has no columns!  Nothing will be exported.;
		option nonotes;
		%if	%among( %upcase( %substr( &exporttmplifempty, 1, 1 ) ), N F 0 )	%then %let misspar = 1;
/*
		%if	%upcase( %substr( &exporttmplifempty, 1, 1 ) ) = N
			or %upcase( %substr( &exporttmplifempty, 1, 1 ) ) = F
			or %substr( &exporttmplifempty, 1, 1 ) = 0
			%then %let misspar = 1;
*/
		%else %let missparexptmpl = 1;
		%goto DDcheckend;
	%end;

	%if &nrows1 = 0 %then %do;
		option notes;
		%put &sasnote: The input SAS data set &libin..&dsin has no observations!  Nothing will be exported.;
		option nonotes;
		%if	%among( %upcase( %substr( &exporttmplifempty, 1, 1 ) ), N F 0 )	%then %let misspar = 1;
/*
		%if	%upcase( %substr( &exporttmplifempty, 1, 1 ) ) = N
			or %upcase( %substr( &exporttmplifempty, 1, 1 ) ) = F
			or %substr( &exporttmplifempty, 1, 1 ) = 0
			%then %let misspar = 1;
*/
		%else %let missparexptmpl = 1;
		%goto DDcheckend;
	%end;

	%if ( ( "&nrows" = "" ) or ( &nrows > &nrows1 ) ) %then %let nrows = &nrows1;
	%if ( ( "&ncols" = "" ) or ( &ncols > &ncols1 ) ) %then %let ncols = &ncols1;

	%* To make sure that a put-statement to one of our DDE-filenames remains on one single;
	%* row of the spreadsheet, we calculate a LRECL for the filename that will (hopefully);
	%* be large enough to accommodate all the formatted values that we will want to push;
	%* through. In the old SAS 6.12 spirit, we assume that 200 bytes per variable will do;
	%* the trick. When exporting v8 data sets with extremely long character variables,;
	%* this may lead to trouble and should be coded a bit more robustly at some point.;
	%let lrecl = %eval( 200*&ncols );

%DDcheckend:;
	%if &misspar %then %goto DDquit;

	%inputData;

%DDquit:
%mend;