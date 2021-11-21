
	
	/*LOG CHECK SETUP - DO NOT MODIFY                    */

	%let LogName=%QUOTE(C:\TEMP\TestMeCode_BAD.log);
	proc printto log="&LogName."  new; run;
	

	/* LOG CHECK SETUP END ==============================================*/
	
	title1 "No Issues With this Area";
	proc print data=sashelp.cars;
	where make ? 'Ac';
	run;

	/* ===  Various Errors        =========== */
		
	title1 "Dataset Doesn't Exist";
	proc print data=cars;
	where make ? 'Ac';
	run;
	
	data temp;
	format Empty 8.;
	k=.;
	X=K/0;
	A=71/0;
	run;
		
	data test;
	merge sashelp.cars sashelp.air;
	by make;
	run;

	data dumb;
	set sashelp.cars(drop=X);
	if make gt 0 then output;
	run;


	/*Log Check Final - DO NOT MODIFY*/
	%let RUNDATE=%SYSFUNC( DATETIME(), DATETIME18. );
	%put PASS HEADER DATE=&RUNDATE.;
	proc printto; run;

	%logcheck(&logname.)

	/*END PROGRAM*/
