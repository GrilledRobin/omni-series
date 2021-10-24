%macro usFUN_isWDorPredate;
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This function is intended to return the provided date value if it is Workday, or return its previous Workday if it is not,			|
|	| with respect of the provided Calendar data.																						|
|	|The function is defined by PCmp Procedure, so its scope is limited by FCmp Procedure.												|
|	|The function will call some other functions as indicated below, please ensure they are properly compiled.							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inCalendar	:	The dataset that contains the dates with respect of the Calendar.													|
|	|				It MUST be provided as a quoted string or a text variable that denotes the full dataset name.						|
|	|ClnDateVar	:	The variable name that represents the Date in the Calendar.															|
|	|				It MUST be provided as a quoted string or a text variable that denotes the variable name.							|
|	|ClnFWDVar	:	The variable name that represents the Flag of Workday in the Calendar.												|
|	|				It MUST be provided as a quoted string or a text variable that denotes the variable name.							|
|	|inDATE		:	The date for which to flag the workday.																				|
|	|				It MUST be provided as a (date) num4ber or a numeric variable that denotes the date value.							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20170603		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Please find the attachments for examples.																							|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|The input Calendar data MUST contain below fields:																					|
|	|	D_DATE		(numeric, date format)																								|
|	|	F_WORKDAY	(numeric, flag)																										|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Return Values:	[Numeric]																											|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|[(Number)]	:	The date value that denotes [inDATE] (if it is Workday) or its Previous Workday.									|
|	|[.]		:	The [inDATE] cannot be found in the [inCalendar].																	|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\Dates"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|usFUN_isWorkDay																												|
|	|	|usFUN_prevWorkday																												|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*010.	Check parameters.;
%*011.	Identify current processing macro.;
%local
	L_mcrLABEL
	Lohno
;
%let	L_mcrLABEL	=	&sysMacroName.;
%let	Lohno		=	%str(E)RROR: [&L_mcrLABEL.]Process failed due to %str(e)rrors!;

%*012.	Handle the parameter buffer.;

%*013.	Define the local environment.;

%*100.	Function that returns the provided date value if it is Workday, or return its next Workday if it is not.;
function
	isWDorPredate(
		inCalendar	$
		,ClnDateVar	$
		,ClnFWDVar	$
		,inDATE
	)
;

	%*100.	Verify whether the provided date is Workday, or defer to the next Workday.;
	if	isWorkDay(inCalendar,ClnDateVar,ClnFWDVar,inDATE)	then do;
		return(inDATE);
	end;
	else do;
		return(prevWorkday(inCalendar,ClnDateVar,ClnFWDVar,inDATE));
	end;

%*700.	Finish the definition of the function.;
endsub;

%*900.	Purge memory usage.;

%EndOfProc:
%mend usFUN_isWDorPredate;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvOp"
		"D:\SAS\omnimacro\Dates"
	)
	mautosource
;

%*090.	This step ensures there is no WARNING message issued when executing the FCmp Procedure.;
options
	cmplib=_NULL_
;

%*100.	Compile the function as defined in the macro.;
proc FCmp
	outlib=work.fso.dates
;

	%usFUN_isWorkDay
	%usFUN_prevWorkday
	%usFUN_isWDorPredate

run;
quit;

%*200.	Locate the Calendar data.;
libname	clndr	"D:\SAS\Calendar";

%*300.	Tell the program where to find the compiled functions.;
options
	cmplib=work.fso
;

%*400.	Call the function to retrieve the Workday Flag for each observation in the provided data.;
data aa;
	D_NTB	=	mdy(11,22,2015);	output;
	D_NTB	=	mdy(2,14,2015);		output;
	D_NTB	=	mdy(6,1,2015);		output;
run;
data bb;
	set aa;
	format	D_WD	yymmddD10.;
	D_WD	=	isWDorPredate("clndr.calendar2015","D_DATE","F_WORKDAY",D_NTB);
run;

/*-Notes- -End-*/