%MACRO PIVOT(DSN=,OUT=,VB=,VARLIST=,XLTYPE=,XLNAME=,ORIENTATION=,STAT=,FORMAT=,LBL=,OUTSAVEAS=,CURPAGE=,NOSUBT=);
	%GLOBAL GLOBLBL VBFILE;
	%IF %UPCASE(&XLTYPE) EQ WORKBOOK %THEN %DO;
		%LET GLOBLBL=&LBL;
		%LET VBFILE=&VB;
		%LET VARLIST=%UPCASE(&VARLIST);
		%LOCAL CCCC WWWW;
		PROC CONTENTS
			DATA=&DSN
			NOPRINT
			OUT=_TEMP_(KEEP=
				NAME
				TYPE
				VARNUM
				LABEL
			);
		RUN;
		DATA _TEMP_;
			SET _TEMP_;
			NAME=UPCASE(TRIM(LEFT(NAME)));
			LABEL=UPCASE(TRIM(LEFT(LABEL)));
		RUN;
		%IF "&VARLIST" EQ "_ALL_" %THEN %DO;
			DATA _NULL_;
				SET _TEMP_ END=EOF;
				CALL SYMPUT('VAR'||(LEFT(PUT(_N_,5.))),UPCASE(NAME));
				IF EOF THEN CALL SYMPUT('TOTAL',LEFT(PUT(_N_,8.)));
			RUN;
		%END;
		%IF "&VARLIST" NE "_ALL_" %THEN %DO;
			%LET CCCC=1;
			%LET WWWW=%QSCAN(&VARLIST,&CCCC,%STR( ));
			%LET VAR1=%STR(&WWWW);
			%DO %WHILE(&WWWW NE);
				%LET CCCC=%EVAL(&CCCC+1);
				%LET WWWW=%QSCAN(&VARLIST,&CCCC,%STR( ));
				%LET VAR&CCCC=%STR(&WWWW);
			%END;
			%LET TOTAL=%EVAL(&CCCC-1);
		%END;
		DATA MV(KEEP=NAME);
			LENGTH NAME $ 32;
			%DO I=1 %TO &TOTAL;
				NAME="&&VAR&I"; OUTPUT;
			%END;
		RUN;
		PROC SORT DATA=MV NODUPKEY;BY NAME;RUN;
		PROC SORT DATA=_TEMP_;BY NAME;RUN;
		DATA _TEMP_;
			MERGE	MV(IN=INA)
				_TEMP_(IN=INB)
				;
			BY NAME;
			IF INA AND INB;
			IF LABEL="" OR LABEL=" " THEN LABEL=NAME;
			LABEL=TRANSLATE(LABEL,' ','"');
			LABEL=TRANSLATE(LABEL,' ',"'");
			LABEL=TRANSLATE(LABEL,' ',',');
			LABEL=TRANSLATE(LABEL,' ','|');
		RUN;
		DATA _NULL_;
			SET _TEMP_ END=EOF;
			CALL SYMPUT('VAR'||(LEFT(PUT(_N_,5.))),UPCASE(NAME));
			CALL SYMPUT('VARN'||(LEFT(PUT(_N_,5.))),_N_);
			CALL SYMPUT('LABL'||(LEFT(PUT(_N_,5.))),UPCASE(TRIM(LEFT(LABEL))));
			CALL SYMPUT('TYP'||LEFT(PUT(_N_,5.)),TYPE);
			IF EOF THEN CALL SYMPUT('TOTAL',LEFT(PUT(_N_,8.)));
		RUN;
		%GLOBAL MASTTOTAL;
		%LET MASTTOTAL=&TOTAL;
		%DO I=1 %TO &MASTTOTAL;
			%GLOBAL MASTVAR&I MASTVARN&I MASTLABL&I MASTTYP&I;
		%END;
		%DO I=1 %TO &MASTTOTAL;
			%LET MASTVAR&I=&&VAR&I;
			%LET MASTVARN&I=&&VARN&I;
			%LET MASTLABL&I=&&LABL&I;
			%LET MASTTYP&I=&&TYP&I;
		%END;
		DATA _NULL_;
			FILE "&OUT" NOPRINT DLM='|' LRECL=1000;
			IF _N_=1 THEN DO;
				DO IIII=1 TO NOBSLAB;
					SET _TEMP_ NOBS=NOBSLAB POINT=IIII;
					%IF &LBL EQ Y %THEN %DO;
						IF IIII=NOBSLAB THEN PUT LABEL;
							ELSE PUT LABEL @;
					%END;
					%ELSE %DO;
						IF IIII=NOBSLAB THEN PUT NAME;
							ELSE PUT NAME @;
					%END;
				END;
			END;
			SET &DSN;
			FORMAT _NUMERIC_ BEST12.;
			%DO VNUM=1 %TO &TOTAL;
				%IF &&TYP&VNUM=2 %THEN %DO;
					&&VAR&VNUM=TRANSLATE(&&VAR&VNUM,' ','"');
					&&VAR&VNUM=TRANSLATE(&&VAR&VNUM,' ',"'");
					&&VAR&VNUM=TRANSLATE(&&VAR&VNUM,' ',',');
					&&VAR&VNUM=TRANSLATE(&&VAR&VNUM,' ','|');
				%END;
			%END;
			%DO VNUM=1 %TO &TOTAL;
				PUT &&VAR&VNUM @;
			%END;
			PUT ;
		RUN;
		%LET XLWBNAME=%QSCAN(&OUT,-2,'\,:,.');
		DATA _NULL_;
			FILE "&VBFILE";
			%LET OUT1=%BQUOTE(")&OUT%BQUOTE(");
			PUT 'SET XL = CreateObject("Excel.Application")';
			PUT 'XL.Visible=False';
			PUT 'XL.Workbooks.OpenText _';
			PUT "	&OUT1 _";			/*Filename=&OUT1*/
			PUT '	,936 _';			/*Origin=936*/
/*437 may be the Encoding, so I guess this can be replaced by 936 (Chinese Simplified);*/
			PUT '	,1 _';				/*StartRow=1*/
			PUT '	,1 _';				/*DataType=1*/
			PUT '	,1 _';				/*TextQualifier=1*/
/*TextQualifier; xlTextQualifierDoubleQuote = 1, xlTextQualifierNone = -4142, xlTextQualifierSingleQuote = 2;*/
			PUT '	,False _';			/*ConsecutiveDelimiter=False*/
			PUT '	,False _';
			PUT '	,False _';			/*Semicolon=False*/
			PUT '	,False _';			/*Comma=False*/
			PUT '	,False _';			/*Space=False*/
			PUT '	,True _';			/*Other=True*/
			PUT '	,"|" _';			/*OtherChar="|"*/
			PUT '	,array( _ ';			/*FieldInfo=array()*/
			%DO I=1 %TO &TOTAL;
				%IF &I NE &TOTAL %THEN PUT "array(&i,&&typ&i), _";
					%ELSE PUT "array(&i,&&typ&i) _";
				;
			%END;
			PUT '	)';
%*			PUT '	,1';				/*TextVisualLayout=1*/
/*TextVisualLayout; xlTextVisualLTR = 1, xlTextVisualRTL = 2;*/
			%LET XLWBNAME1=%BQUOTE(")&XLWBNAME%BQUOTE(");
			PUT 'XL.Sheets(' "&XLWBNAME1" ').Select';
			PUT 'XL.Sheets(' "&XLWBNAME1" ').Name="RAWDATA"';
			PUT 'XL.Rows("1:1").Select';
			PUT 'XL.Selection.Font.Bold = True';
			PUT 'XL.Range("A2").Select';
			PUT 'XL.ActiveWindow.FreezePanes = True';
			PUT 'XL.Cells.Select';
			PUT 'XL.Selection.Columns.AutoFit';
	* For the above array statement, the first dimension is the variable number and the second dimension tells if its numeric 1, or character 2;
	%END;
	%IF %UPCASE(&XLTYPE) EQ WORKSHEET %THEN %DO;
		PUT 'XL.Sheets.Add.name = "'"&XLname"'"';
		PUT 'XL.ActiveSheet.PivotTableWizard SourceType=xlbase, XL.Sheets("'"RAWDATA"'").UsedRange, "'"&XLname!R1C1"'", "pvttbl"';
	%END;
	%IF %UPCASE(&XLTYPE) EQ FIELD %THEN %DO;
		%IF %UPCASE(&GLOBLBL) EQ Y %THEN %DO;
			%DO I=1 %TO &MASTTOTAL;
				%IF &XLNAME EQ &&MASTVAR&I %THEN %DO;
					%LET XLNAME=&&MASTLABL&I;
					%LET I=%EVAL(&MASTTOTAL+1);
				%END;
			%END;
		%END;
		%IF %UPCASE(&ORIENTATION) EQ DATA %THEN %DO;
			PUT 'XL.ActiveSheet.PivotTables("'"pvttbl"'").AddDataField _';
			PUT 'XL.ActiveSheet.PivotTables("'"pvttbl"'").PivotFields("'"&XLname"'"),"'"&Stat of &XLname"'",'
				%IF %UPCASE(&STAT) EQ SUM %THEN "-4157";
				%IF %UPCASE(&STAT) EQ COUNT %THEN "-4112";
				%IF %UPCASE(&STAT) EQ AVERAGE %THEN "-4106";
			;
		%END;
		%ELSE %DO;
			PUT "XL.ActiveSheet.PivotTables(""pvttbl"").PivotFields(""&XLname"").Orientation = "
			%IF %UPCASE(&ORIENTATION) EQ PAGE %THEN "3";
			%IF %UPCASE(&ORIENTATION) EQ ROW %THEN "1";
			%IF %UPCASE(&ORIENTATION) EQ COLUMN %THEN "2";
			;
		%END;
		%IF	&CURPAGE NE	%THEN %DO;
			PUT 'XL.ActiveSheet.PivotTables("pvttbl").PivotFields("'"&XLname"'").CurrentPage = "'"&CURPAGE."'"';
		%END;
		%IF &FORMAT^= %THEN
			%IF &STAT^= %THEN
				PUT "XL.ActiveSheet.PivotTables(""pvttbl"").PivotFields
				(""&stat of &XLname"").numberformat = " ""&format"";
			%ELSE
				PUT
				"XL.ActiveSheet.PivotTables(""pvttbl"").PivotFields(""&XLname"").numberformat = "
				""&format"";;
	%END;
	%IF %UPCASE(&XLTYPE) EQ RESIZE %THEN %DO;
		%IF	&NOSUBT NE	%THEN %DO;
			PUT	'XL.ActiveSheet.PivotTables("'"pvttbl"'").PivotFields("'"&NOSUBT"'").Subtotals = Array(False, False, False, False, False, False, False, False, False, False, False, False)';
		%END;
		PUT "XL.ActiveSheet.Columns.AutoFit";
	%END;
	%IF %UPCASE(&XLTYPE) EQ CREATE %THEN %DO;
		PUT 'XL.DisplayAlerts=0';
		PUT 'XL.ActiveWorkbook.SaveAs "'"&OUTSAVEAS"'",-4143';
/*Here the second parameter is FileFormat; xlExcel9795=43, while xlWorkbookNormal=-4143;*/
		PUT 'XL.ActiveWorkbook.Close';
		PUT 'XL.Quit';
		RUN;
		X "&VBFILE";
	%END;
%MEND PIVOT;