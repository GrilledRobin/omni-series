%* Pours the data in.                                                                    ;

%macro inputData;

  %local ii jj kk ll sumrows statrows extrarows fmts fmtls fmtds fmtlist lengs 
    xlfmts letters sumnumlist statnumlist colnum wvarnum;

  %let letters = A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 
    AA AB AC AD AE AF AG AH AI AJ AK AL AM AN AO AP AQ AR AS AT AU AV AW AX AY AZ
    BA BB BC BD BE BF BG BH BI BJ BK BL BM BN BO BP BQ BR BS BT BU BV BW BX BY BZ
    CA CB CC CD CE CF CG CH CI CJ CK CL CM CN CO CP CQ CR CS CT CU CV CW CX CY CZ
    DA DB DC DD DE DF DG DH DI DJ DK DL DM DN DO DP DQ DR DS DT DU DV DW DX DY DZ
    EA EB EC ED EE EF EG EH EI EJ EK EL EM EN EO EP EQ ER ES ET EU EV EW EX EY EZ
    FA FB FC FD FE FF FG FH FI FJ FK FL FM FN FO FP FQ FR FS FT FU FV FW FX FY FZ
    GA GB GC GD GE GF GG GH GI GJ GK GL GM GN GO GP GQ GR GS GT GU GV GW GX GY GZ
    HA HB HC HD HE HF HG HH HI HJ HK HL HM HN HO HP HQ HR HS HT HU HV HW HX HY HZ
    IA IB IC ID IE IF IG IH II IJ IK IL IM IN IO IP IQ IR IS IT IU IV;
  %let sumrows = 0;
  %let statrows = 0;
  %let extrarows = 0;

  %* Compute rows to add to the cell range -- this will be important later.              ;
  %if %length( %scan( &sumvars, 1 ) ) > 0 %then %let sumrows = 1;
  %if %length( %scan( &statvars, 1 ) ) > 0 %then %do;
	%let statrows = 7;
	%* A weighted average adds one more line.                                            ;
  	%if %length( &weightvar ) > 0 %then %let statrows = 8;
	%end;
  %if &statrows > 0 or &sumrows > 0 %then %let extrarows = 2;

  %* Calculate the range of cells to which label data will be written. The upper left    ;
  %* cell is obviously defined by (&CELL1ROW,&CELL1COL). The lower right corner of the   ;
  %* range, which incidentally is on the same row in case of the labels, is defined as   ;
  %* follows.                                                                            ;
  %let ulrowlab = &cell1row;
  %let ulcollab = &cell1col;
  %let lrrowlab = %eval( &ulrowlab + &mergedown - 1 );
  %let lrcollab = %eval( &cell1col + &mergeacross*&ncols - 1 );

  %* Calculate the range of cells to which the real data will be written. The upper left ;
  %* cell is obviously defined by (&CELL1ROW+1,&CELL1COL).                               ;
  %let ulrowdat = %eval( &cell1row + &mergedown*&printHeaders );
  %let ulcoldat = &cell1col;
  %let lrrowdat = %eval( &cell1row + &mergedown*( &nrows + &printHeaders ) - 1 );
  %let lrcoldat = %eval( &cell1col + &mergeacross*&ncols - 1 );

  %* Calculate the range of cells to which the summary data will be written. The upper   ;
  %* left cell is obviously defined by (&CELL1ROW+&NROWS+1,&CELL1COL).                   ;
  %let ulrowstat = %eval( &cell1row + &mergedown*( &nrows + &printHeaders ) );
  %let ulcolstat = &cell1col;
  %let lrrowstat = %eval( &cell1row + &mergedown*( &nrows + &printHeaders + &sumrows + &statrows + &extrarows ) - 1 );
  %let lrcolstat = %eval( &cell1col + &mergeacross*&ncols - 1 );

  %* Now we gather information about the input data set variables and their formats.     ;
  proc contents data = &libin..&dsin out=____meta noprint;
  run;

  %* If a variable does not have a label or format defined, use the variable name or 'F' ;
  %* for the numeric format.                                                             ;
  data ____meta;
    set ____meta;
    if label = ' ' then label = name;
    if format = ' ' then format = 'F';
  run;

  %* We then sort this information by the order of the variables.                        ;
  proc sort data = ____meta;
    by varnum;
  run;

  %* From ____META, we now put information about the variable names and their formats    ;
  %* into macro variables &TYPES, &FMTS, &FMTLS, &FMTDS, &LENGS and &VARS, which are     ;
  %* lists separated by blanks, to be used later. &VARS will have the variable names,    ;
  %* while the others will give useful info about the formats which we will be used to   ;
  %* make the Excel versions of them.                                                    ;
  proc sql noprint;
    select type, format, formatl, formatd, name, length
    into :types separated by ' ', :fmts separated by ' ', :fmtls separated by ' ',
      :fmtds separated by ' ', :vars separated by ' ', :lengs separated by ' '
    from ____meta;
  quit;

  %* We now define two new macro variables, &SUMNUMLIST and &STATNUMLIST, which will     ;
  %* give us numbers corresponding to the columns of variables in &SUMVARS and           ;
  %* &STATVARS. In the %DO %WHILE statements below, after we match a data set variable   ;
  %* to one in the list (either &SUMVARS or &STATVARS), we set &JJ to the length of      ;
  %* &SUMVARS just so that &JJ will be high enough to get out of the %DO loop.  This way ;
  %* we avoid problems if a variable is listed two or more times in &SUMVARS or          ;
  %* &STATVARS. Note that the comparisons are all in upper case -- since SAS is case     ;
  %* insensitive, our comparisons should be as well.                                     ;
  %let sumnumlist =;
  %let statnumlist =;

  %do ii=1 %to &ncols;
    %let jj = 1;
    %do %while( %length( %scan( &sumvars, &jj ) ) > 0 );
      %if %upcase( %scan( &vars, &ii ) ) = %upcase( %scan( &sumvars, &jj ) ) %then %do;
        %let sumnumlist = &sumnumlist &ii;
        %let jj = %length( &sumvars );
        %end;
      %let jj = %eval( &jj + 1 );
      %end;
    %end;

  %do ii=1 %to &ncols;
    %let jj = 1;
    %do %while( %length( %scan( &statvars, &jj ) ) > 0 );
      %if %upcase( %scan( &vars, &ii ) ) = %upcase( %scan( &statvars, &jj ) ) %then %do;
        %let statnumlist = &statnumlist &ii;
        %let jj = %length( &statvars );
        %end;
      %let jj = %eval( &jj + 1 );
      %end;
    %end;

  %* If &EXPORTVARFMTS is indicated, we format the cells before pouring the data in.     ;
  %if %substr( %upcase( &exportvarfmts ), 1, 1 ) = Y or 
    %substr( %upcase( &exportvarfmts ), 1, 1 ) = T or 
    %substr( &exportvarfmts, 1, 1 ) = 1 %then %do;

    %* %MAKEEXCELFORMATS makes the Excel version of each format, using macro variables   ;
    %* &FMTS, &FMTLS, etc., that we made above, giving another macro variable, &XLFMTS,  ;
    %* which is a list of Excel versions of these formats, separated by '!' since some   ;
    %* of these formats contain a space. For example, the SAS format '5.2' has the Excel ;
    %* equivalent '000.00'. If the format in SAS is either not given or is not included  ;
    %* in %MAKEEXCELFORMATS, the result is 'NONE'.                                       ;
    %do ii=1 %to &ncols;

      %makeExcelFormats( &ii );

      %end;	

    %* Now we format the cells -- first, if &PRINTHEADERS is indicated, we format that   ;
    %* row of cells as text.  Then we format the rest of the cells, column by column,    ;
    %* using the entries of &XLFMTS. If &XLFMTS has no result for a given column (i.e.,  ;
    %* 'NONE'), the column is left unformatted, in which case Excel may or may not       ;
    %* decide to figure out the format on its own, depending on whether the cell is      ;
    %* already formatted. We then format the cells for the summary statistics labels.    ;
    data _null_;
      length ddecmd $ 200;
      file sas2xl;
      put "[&error(&false)]";
      ddecmd = "[&workbookactivate("||'"'||"&insheetnm."||'"'||",&false)]";
      put ddecmd;
      %if &printheaders %then %do;
        ddecmd = "[&select("||'"'||"&r&ulrowlab&c&ulcollab:&r&lrrowlab&c&lrcollab"||'")]';
        put ddecmd;
        ddecmd = "[&formatnumber("||'"@")]';
        put ddecmd;
        %end;
      %let colind = ;
      %do ii=1 %to &ncols;
        %let colind = %eval( &ulcollab + &ii - 1 );
        ddecmd = "[&select("||'"'||"&r&ulrowdat&c&colind:&r&lrrowdat&c&colind"||'")]';
        %if %length( %scan( &sumvars, 1 ) ) > 0 or %length( %scan( &statvars, 1 ) ) > 0 %then
          ddecmd = "[&select("||'"'||"&r&ulrowdat&c&colind:&r&lrrowstat&c&colind"||'")]';;
        put ddecmd;
        %if %qscan( &xlfmts, &ii, ! ) ne NONE %then %do;                     
          ddecmd = "[&formatnumber("||'"'||"%nrbquote(%scan( &xlfmts, &ii, ! ))"||'")]';
          put ddecmd;                                                     
          %end;  
        %end;
      %if %length( %scan( &sumvars, 1 ) ) > 0 or %length( %scan( &statvars, 1 ) ) > 0 %then %do;
        ddecmd = "[&select("||'"'||"&r&ulrowstat&c&ulcolstat:&r&lrrowstat&c&ulcolstat"||'")]';
        put ddecmd;
        ddecmd = "[&formatnumber("||'"@")]';
        put ddecmd;
        %end;
    run;

    %end;

  %* Depending on &PRINTHEADERS, we pour in the variable labels. We start by defining    ;
  %* the DDE link for the section of the spreadsheet where the labels will be written.   ;
  filename xllabels dde "excel|&savepath\[&savename..xls]&insheetnm.!&r&ulrowlab&c&ulcollab:&r&lrrowlab&c&lrcollab" 
    notab lrecl = &lrecl;

  %* While we at at it, we also define the DDE link to the section of the spreadsheet    ;
  %* where the actual data will be written.                                              ;
  filename xlsheet dde "excel|&savepath\[&savename..xls]&insheetnm.!&r&ulrowdat&c&ulcoldat:&r&lrrowdat&c&lrcoldat" 
    notab lrecl = &lrecl;

  %* We then define the DDE link to the section of the spreadsheet where the summary     ;
  %* data will be written.                                                               ;
  filename xlsumm dde "excel|&savepath\[&savename..xls]&insheetnm.!&r&ulrowstat&c&ulcolstat:&r&lrrowstat&c&lrcolstat" 
    notab lrecl = &lrecl;

  %if &printHeaders %then %do;

    %* For the first &NCOLS variables, we write the labels to the DDE-filename XLLABELS. ;
    %* Since X4ML was created before cells could be merged, DDE always pours data into   ;
    %* unmerged cells. This is OK -- we can merge them later. For now, we will skip the  ;
    %* appropriate number of cells (e.g., if we want to merge every two cells together,  ;
    %* we pour data into every second cell), repeating &TAB as many times as dictated by ;
    %* &MERGEACROSS.                                                                     ;
    data _null_;
      set ____meta end = last;
      file xllabels notab;
      if varnum <= &ncols then do;
        put label +(-1) @@;
        if not last then put %do jj=1 %to &mergeacross; &tab %end; @@;
        end;
    run;

    %end;

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
  %* number of rows after each row. Nore that this was not necessary for the labels,     ;
  %* since that was just one row.                                                        ;
  data _null_;
    set &libin..&dsin( obs = &nrows );
    file xlsheet notab dsd dlm= '';
    put %makeVarList;
    %if &mergedown > 1 %then %do jj=1 %to %eval( &mergedown - 1 );
      put;
      %end;
  run;

  %* If either &SUMVARS or &STATVARS is nonempty, we add the summary stats.              ;
  %if %length( %scan( &sumvars, 1 ) ) > 0 or %length( %scan( &statvars, 1 ) ) > 0 %then %do;

    %* For the weighted average, we need the number of the column corresponding to the   ;
    %* weight variable.                                                                  ;
    %let wvarnum = 0;

	%* We must make comparisons in the same case.                                        ;
    %let ii = 1;
    %do %while( %length( %scan( &vars, &ii ) ) > 0 );
      %if %upcase( %scan( &vars, &ii ) ) = %upcase( &weightvar ) %then %do;
        %let wvarnum = &ii;
        %end;
      %let ii = %eval( &ii + 1 );
      %end;

    %if &wvarnum = 0 and %length( &weightvar ) ne 0 %then %do;
      %put &saserror: No weight variable in data set -- weighted average is not possible and will not be listed.;
      %let weightvar = ;
      %end;

    %let wvarnum = %eval( &wvarnum + &cell1col - 1 );

    %* We now write the sum or statistical data -- which contains the mean, the weighted ;
    %* mean, the minimum, 25th percentile, median, 75th percentile, and max. Anyone      ;
    %* desiring different statistical data would edit this part of the code. The column  ;
    %* numbers are changed into letters (using &LETTERS above), and we are once again    ;
    %* skipping rows and columns via &MERGEACROSS and &MERGEDOWN as we did above. When   ;
    %* the elements of &SUMNUMLIST or &STATNUMLIST are exhausted, we skip out of that    ;
    %* loop and move on to the next row. Note that their labels (e.g., 'SUM:', 'MIN:',   ;
    %* etc.) are put into the first column, so these statistics are not available for    ;
    %* the variable in the first column -- if that variable is in &SUMVARS or &STATVARS, ;
    %* it will simply be ignored. We already pre-formatted this first column above as    ;
    %* text.                                                                             ;
    data _null_;
      set &libin..&dsin;
      file xlsumm notab;
      %do ll=1 %to &mergedown;
        put;
        put;
        %end;
      %if %length( %scan( &sumvars, 1 ) ) > 0 %then %do;
        %let jj = 1;
        put 'SUM:' 
        %do kk=1 %to &mergeacross; 
          &tab 
          %end;
        %do ii = 2 %to &ncols;
          %if &ii = %scan( &sumnumlist, &jj, " " ) %then %do;
            %let colnum = %eval( &cell1col + &mergeacross*( &ii - 1 ) );
            "=&sum(%scan( &letters, &colnum )&ulrowdat:%scan( &letters, &colnum )&lrrowdat)"
            %let jj = %eval( &jj + 1 );
            %if %length( %scan( &sumnumlist, &jj, " " ) ) = 0 %then %goto out1;
            %end;
          %do kk=1 %to &mergeacross; 
            &tab 
            %end;
          %end;
        %out1:;
        %if &mergedown > 1 %then %do ll=1 %to %eval( &mergedown - 1 );
          put;
          %end;   
        %end;
      %if %length( %scan( &statvars, 1 ) ) > 0 %then %do;
        %let jj = 1;
        put 'MEAN:' 
        %do kk=1 %to &mergeacross; 
          &tab 
          %end;               
        %do ii = 2 %to &ncols;
          %if &ii = %scan( &statnumlist, &jj, " " ) %then %do;
            %let colnum = %eval( &cell1col + &mergeacross*( &ii - 1 ) );
            "=&average(%scan( &letters, &colnum )&ulrowdat:%scan( &letters, &colnum )&lrrowdat)"
            %let jj = %eval( &jj + 1 );
            %if %length( %scan( &statnumlist, &jj, " " ) ) = 0 %then %goto out2;
            %end;
          %do kk=1 %to &mergeacross; 
            &tab 
            %end;
          %end;
        %out2:;
        %if &mergedown > 1 %then %do ll=1 %to %eval( &mergedown - 1 );
          put;
          %end;  
        %if %length( &weightvar ) = 0 %then %goto out10; 
        %let jj = 1;
        put 'W MEAN:' 
        %do kk=1 %to &mergeacross; 
          &tab 
          %end;             
        %do ii = 2 %to &ncols;
          %if &ii = %scan( &statnumlist, &jj, " " ) %then %do;
            %let colnum = %eval( &cell1col + &mergeacross*( &ii - 1 ) );
            "=&sumproduct(%scan( &letters, &wvarnum )&ulrowdat:%scan( &letters, &wvarnum )&lrrowdat," 
            "%scan( &letters, &colnum )&ulrowdat:%scan( &letters, &colnum )&lrrowdat)/"
            "&sum(%scan( &letters, &wvarnum )&ulrowdat:%scan( &letters, &wvarnum )&lrrowdat)"
            %let jj = %eval( &jj + 1 );
            %if %length( %scan( &statnumlist, &jj, " " ) ) = 0 %then %goto out3;
            %end;
          %do kk=1 %to &mergeacross; 
            &tab 
            %end;
          %end;
        %out3:;
        %if &mergedown > 1 %then %do ll=1 %to %eval( &mergedown - 1 );
          put;
          %end;
        %out10:;
        %do ll=1 %to &mergedown;
          put;
          %end;
        %let jj = 1;
        put 'MIN:' 
        %do kk=1 %to &mergeacross; 
          &tab 
          %end;                
        %do ii = 2 %to &ncols;
          %if &ii = %scan( &statnumlist, &jj, " " ) %then %do;
            %let colnum = %eval( &cell1col + &mergeacross*( &ii - 1 ) );
            "=&min(%scan( &letters, &colnum )&ulrowdat:%scan( &letters, &colnum )&lrrowdat)"
            %let jj = %eval( &jj + 1 );
            %if %length( %scan( &statnumlist, &jj, " " ) ) = 0 %then %goto out4;
            %end;
          %do kk=1 %to &mergeacross; 
            &tab 
            %end;
          %end;
        %out4:;
        %if &mergedown > 1 %then %do ll=1 %to %eval( &mergedown - 1 );
          put;
          %end;
        %let jj = 1;
        put '1st QUAD:' 
        %do kk=1 %to &mergeacross; 
          &tab 
          %end;               
        %do ii = 2 %to &ncols;
          %if &ii = %scan( &statnumlist, &jj, " " ) %then %do;
            %let colnum = %eval( &cell1col + &mergeacross*( &ii - 1 ) );
            "=&percentile(%scan( &letters, &colnum )&ulrowdat:%scan( &letters, &colnum )&lrrowdat,0.25)"
            %let jj = %eval( &jj + 1 );
            %if %length( %scan( &statnumlist, &jj, " " ) ) = 0 %then %goto out5;
            %end;
          %do kk=1 %to &mergeacross; 
            &tab 
            %end;
          %end;
        %out5:;
        %if &mergedown > 1 %then %do ll=1 %to %eval( &mergedown - 1 );
          put;
          %end;
        %let jj = 1;
        put 'MEDIAN:' 
        %do kk=1 %to &mergeacross; 
          &tab 
          %end;             
        %do ii = 2 %to &ncols;
          %if &ii = %scan( &statnumlist, &jj, " " ) %then %do;
            %let colnum = %eval( &cell1col + &mergeacross*( &ii - 1 ) );
            "=&median(%scan( &letters, &colnum )&ulrowdat:%scan( &letters, &colnum )&lrrowdat)"
            %let jj = %eval( &jj + 1 );
            %if %length( %scan( &statnumlist, &jj, " " ) ) = 0 %then %goto out6;
            %end;
          %do kk=1 %to &mergeacross; 
            &tab 
            %end;
          %end;
        %out6:;
        %if &mergedown > 1 %then %do ll=1 %to %eval( &mergedown - 1 );
          put;
          %end;
        %let jj = 1;
        put '3rd QUAD:' 
        %do kk=1 %to &mergeacross; 
          &tab 
          %end;               
        %do ii = 2 %to &ncols;
          %if &ii = %scan( &statnumlist, &jj, " " ) %then %do;
            %let colnum = %eval( &cell1col + &mergeacross*( &ii - 1 ) );
              "=&percentile(%scan( &letters, &colnum )&ulrowdat:%scan( &letters, &colnum )&lrrowdat,0.75)"
              %let jj = %eval( &jj + 1 );
              %if %length( %scan( &statnumlist, &jj, " " ) ) = 0 %then %goto out7;
              %end;
            %do kk=1 %to &mergeacross; 
              &tab 
              %end;
            %end;
          %out7:;
          %if &mergedown > 1 %then %do ll=1 %to %eval( &mergedown - 1 );
            put;
            %end;
          %let jj = 1;
          put 'MAX:' 
          %do kk=1 %to &mergeacross; 
            &tab 
            %end;                
          %do ii = 2 %to &ncols;
            %if &ii = %scan( &statnumlist, &jj, " " ) %then %do;
              %let colnum = %eval( &cell1col + &mergeacross*( &ii - 1 ) );
              "=&max(%scan( &letters, &colnum )&ulrowdat:%scan( &letters, &colnum )&lrrowdat)"
              %let jj = %eval( &jj + 1 );
              %if %length( %scan( &statnumlist, &jj, " " ) ) = 0 %then %goto out8;
              %end;
            %do kk=1 %to &mergeacross; 
              &tab 
              %end;
            %end;
          %out8:;
          %if &mergedown > 1 %then %do ll=1 %to %eval( &mergedown - 1 );
            put;
            %end;
          %end;
        %else %do kk=1 %to %eval( 8*&mergedown ); 
          put; 
          %end;
    run;

    %end;

  %* Now that we have spaced everything out properly, we merge them. As mentioned above, ; 
  %* since X4ML was developed before cells could be merged, there is no X4ML command for ;
  %* merging cells. We get around this by using the keyboard controls to 'manually' do   ;
  %* this. It is not pretty (just watch it go!), but it gets the job done. Since we are  ;
  %* using keyboard commands, we must be sure to have this application activated (i.e.,  ;
  %* Excel must be the active window on the desktop), which we do with the &APPACTIVATE  ;
  %* command. This is the only part of %EXPORTTOEXCEL that requires &APPACTIVATE -       ;
  %* therefore, unless you are merging cells, you can run %EXPORTTOEXCEL in the          ;
  %* background while working on something else.                                         ;
  %if &mergeacross > 1 or &mergedown > 1 %then %do;

    data _null_;
    length ddecmd $200.;
    file sas2xl;
    ddecmd = "[&workbookactivate("||'"'||"&insheetnm."||'"'||",&false)]";
    put ddecmd;
    %do ii=1 %to &ncols;
      %do jj=1 %to %eval( &nrows + &printHeaders + &extrarows + &sumrows + &statrows );
        ddecmd = "[&select("||'"'||
          "&r.%eval( &cell1row + &mergedown*( &jj - 1 ) )&c.%eval( &cell1col + &mergeacross*( &ii - 1 ) ):"||
          "&r.%eval( &cell1row + &mergedown*&jj - 1 )&c.%eval( &cell1col + &mergeacross*&ii - 1 )"||'")]';
        put ddecmd;
        ddecmd = "[&appactivate("||'"'||"Microsoft Excel - &savename..xls"||'")]';
        put ddecmd;
        ddecmd = "[&sendkeys("||'"'||"&sendkeycmd"||'")]';
        put ddecmd;
          %* Merges the cells once again                                                 ;
        %end;
      %end;
    run;
        
    %end;

%mend inputData;
