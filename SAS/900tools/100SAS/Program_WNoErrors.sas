
	/*LOG CHECK SETUP - DO NOT MODIFY                    */

	%let LogName=%QUOTE(C:\TEMP\TestMeCode_Good.log);
	proc printto log="&LogName."  new; run;

	/* LOG CHECK SETUP END ==============================================*/
	/* ==================================================================*/

	data temp;
	x='Test me';
	run;

	title1 "Correct";
	proc print data=temp;
	run;

	/* ==================================================================*/
	/* ==================================================================*/
	/* ==================================================================*/
	/*Log Check Final - DO NOT MODIFY*/
	%let RUNDATE=%SYSFUNC( DATETIME(), DATETIME18. );
	%put PASS HEADER DATE=&RUNDATE.;
	proc printto; run;

	%logcheck(&logname.)
	/*END PROGRAM*/
	/* ==================================================================*/
