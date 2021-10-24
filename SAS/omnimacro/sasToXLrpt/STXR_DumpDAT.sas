%macro STXR_DumpDAT(
	insheetnm	=
	,valin		=
	,cell1row	= 1
	,cell1col	= 1
);
	%*let	insheetnm	=	%unquote(&insheetnm.);
	%let	valin		=	%unquote(&valin.);
	%let	cell1row	=	%unquote(&cell1row.);
	%let	cell1col	=	%unquote(&cell1col.);

	%local
		DSID
		anobs
		whstmt
		rc
	;

	%*100.	Verify the data existence.;
	%if %sysfunc( exist( &valin. ) ) = 0	%then %do;
		option notes;
		%put &sasnote.: [&L_mcrLABEL.]The input SAS data set "&valin." does not exist!;
		option nonotes;
		%goto EndOfProc;
	%end;

	%*200.	Retrieve the number of rows and columns of the output data.;
	%let	nrows	=	0;
	%let	ncols	=	0;
	%let	DSID	=	%sysfunc(open(&valin., IS));
	%let	anobs	=	%sysfunc(attrn(&DSID.,ANOBS));
	%let	ncols	=	%sysfunc(attrn(&DSID.,NVARS));
	%let	whstmt	=	%sysfunc(attrn(&DSID.,WHSTMT));

	%if	&anobs.	=	1	and	&whstmt.	=	0	%then %do;
		%let	nrows	=	%sysfunc(attrn(&DSID.,NLOBS));
	%end;
	%else %do;
		data _null_;
			dsid	=	open("&valin.",'is');
			do	while (fetch(dsid, 'noset') = 0);
				i + 1;
			end;
			call symputx("nrows",i);
			rc	=	close(dsid);
			stop;
		run;
	%end;
	%let	rc	=	%sysfunc(close(&DSID.));

	%*300.	Check the numbers.;
	%if	&ncols.	=	0	%then %do;
		option notes;
		%put &sasnote.: [&L_mcrLABEL.]The input SAS data set "&valin." has no columns!;
		option nonotes;
		%goto EndOfProc;
	%end;

	%if	&nrows.	=	0	%then %do;
		option notes;
		%put &sasnote.: [&L_mcrLABEL.]The input SAS data set "&valin." has no observations!;
		option nonotes;
		%goto EndOfProc;
	%end;

	%*400.	Define the range to be exported.;
	%* Calculate the range of cells to which label data will be written. The upper left    ;
	%* cell is obviously defined by (&CELL1ROW,&CELL1COL). The lower right corner of the   ;
	%* range, which incidentally is on the same row in case of the labels, is defined as   ;
	%* follows.                                                                            ;
	%let ulrowlab = &cell1row.;
	%let ulcollab = &cell1col.;
	%let lrrowlab = &ulrowlab.;
	%let lrcollab = %eval( &cell1col. + &ncols. - 1 );

	%* Calculate the range of cells to which the real data will be written. The upper left ;
	%* cell is obviously defined by (&CELL1ROW+1,&CELL1COL).                               ;
	%let ulrowdat = %eval( &cell1row. + &printHeaders. );
	%let ulcoldat = &cell1col.;
	%let lrrowdat = %eval( &cell1row. + &nrows. + &printHeaders. - 1 );
	%let lrcoldat = %eval( &cell1col. + &ncols. - 1 );

	%* To make sure that a put-statement to one of our DDE-filenames remains on one single;
	%* row of the spreadsheet, we calculate a LRECL for the filename that will (hopefully);
	%* be large enough to accommodate all the formatted values that we will want to push;
	%* through. In the old SAS 6.12 spirit, we assume that 200 bytes per variable will do;
	%* the trick. When exporting v8 data sets with extremely long character variables,;
	%* this may lead to trouble and should be coded a bit more robustly at some point.;
	%let lrecl = %eval( 200 * &ncols. );

	%*500.	Collect information of the outpu data.;
	%* Now we gather information about the input data set variables and their formats.     ;
	proc contents
		data = &valin.
		out=exr_WORK.____meta
		noprint
	;
	run;

	%* If a variable does not have a label or format defined, use the variable name or 'F' ;
	%* for the numeric format.                                                             ;
	data exr_WORK.____meta;
		set exr_WORK.____meta;
		if label = ' ' then label = name;
		if format = ' ' then format = 'F';
	run;

	%* We then sort this information by the order of the variables.                        ;
	proc sort
		data = exr_WORK.____meta
	;
		by varnum;
	run;

	%* From ____META, we now put information about the variable names and their formats    ;
	%* into macro variables &TYPES, &FMTS, &FMTLS, &FMTDS, &LENGS and &VARS, which are     ;
	%* lists separated by blanks, to be used later. &VARS will have the variable names,    ;
	%* while the others will give useful info about the formats which we will be used to   ;
	%* make the Excel versions of them.                                                    ;
	proc sql noprint;
		select
			type
			,format
			,formatl
			,formatd
			,name
			,length
		into
			:types separated by ' '
			,:fmts separated by ' '
			,:fmtls separated by ' '
			,:fmtds separated by ' '
			,:vars separated by ' '
			,:lengs separated by ' '
		from exr_WORK.____meta;
	quit;

	%*600.	Export the Label if required.;
%if &printHeaders. %then %do;
	%*610.	Create the DDE link for Label Export.;
	%* Depending on &PRINTHEADERS, we pour in the variable labels. We start by defining    ;
	%* the DDE link for the section of the spreadsheet where the labels will be written.   ;
	filename
		xllabels
		dde
		"excel|&savepath.\[&savename.&EnviroEXT.]&insheetnm.!&r.&ulrowlab.&c.&ulcollab.:&r.&lrrowlab.&c.&lrcollab."
		notab
		lrecl = &lrecl.
	;

	%*620.	Export the labels.;
	%* For the first &NCOLS variables, we write the labels to the DDE-filename XLLABELS. ;
	%* Since X4ML was created before cells could be merged, DDE always pours data into   ;
	%* unmerged cells. This is OK -- we can merge them later. For now, we will skip the  ;
	%* appropriate number of cells (e.g., if we want to merge every two cells together,  ;
	%* we pour data into every second cell), repeating &TAB as many times as dictated by ;
	%* &MERGEACROSS.                                                                     ;
	data _null_;
		set exr_WORK.____meta end = last;
		file xllabels notab;
		if varnum <= &ncols. then do;
			put label +(-1) @@;
			if not last then do;
				put
%*					%do jj=1 %to &mergeacross;
						&tab.
%*					%end;
					@@
				;
			end;
		end;
	run;
%end;

	%*700.	Export the data.;
	%*710.	Create the DDE link for Data Export.;
	filename
		xlsheet
		dde
		"excel|&savepath.\[&savename.&EnviroEXT.]&insheetnm.!&r.&ulrowdat.&c.&ulcoldat.:&r.&lrrowdat.&c.&lrcoldat."
		notab
		lrecl = &lrecl.
	;

	%*720.	Export the data.;
	%* As mentioned above, since X4ML was created before cells could be merged, DDE always ;
	%* pours data into unmerged cells. This is OK -- we can merge them later. For now,     ;
	%* when we pour the data in, we will skip the appropriate number of cells, repeating   ;
	%* &TAB as many times as dictated by &MERGEACROSS. Above we did this with the PUT      ;
	%* statement, but we could only do that because we were reading from one column into   ;
	%* one row.  Now that we have many columns (and many rows), we have to be more crafty. ;
	%* For the upcoming PUT statement for pouring the data in, we shall use a blank-       ;
	%* separated list of the variables separated by &TABs (repeated as many times as       ;
	%* dictated by &MERGEACROSS). %MAKEVARLIST makes such a list.                          ;

	%* After all that preparation, we finally pour in the data! %MAKEVARLIST takes care of ;
	%* merging cells across -- for merging cells down, we simply need to skip the right    ;
	%* number of rows after each row. Note that this was not necessary for the labels,     ;
	%* since that was just one row.                                                        ;
	data _null_;
		set &valin.;
		file xlsheet notab dsd dlm= '';
%*-> 20170113 Modified by Lu Robin Bin.;
		%STXR_makeVarList
%*<- 20170113 Modified by Lu Robin Bin.;
/*
		%if &mergedown > 1 %then %do jj=1 %to %eval( &mergedown - 1 );
			put;
		%end;
*/
	run;

	%*999.	Internal Cleansing of the "filename".;
%if &printHeaders. %then %do;
	filename	xllabels	clear;
%end;
	filename	xlsheet		clear;

%EndOfProc:
%mend STXR_DumpDAT;