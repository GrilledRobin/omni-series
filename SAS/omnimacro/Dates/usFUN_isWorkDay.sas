%macro usFUN_isWorkDay;
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to flag whether the given date in a Date variable is Workday with respect of the provided Calendar data.	|
|	|The function is defined by PCmp Procedure, so its scope is limited by FCmp Procedure.												|
|	|The major drawback of this function is that it has to load the entire Calendar data at each call on each observation of the input	|
|	| dataset, which slow down the overall process.																						|
|	|The reason tha leads to this is that the READ_ARRAY function and the HASH object both cannot accept dataset option WHERE as input.	|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inCalendar	:	The dataset that contains the dates with respect of the Calendar.													|
|	|				It MUST be provided as a quoted string or a text variable that denotes the full dataset name.						|
|	|ClnDateVar	:	The variable name that represents the Date in the Calendar.															|
|	|				It MUST be provided as a quoted string or a text variable that denotes the variable name.							|
|	|ClnFWDVar	:	The variable name that represents the Flag of Workday in the Calendar.												|
|	|				It MUST be provided as a quoted string or a text variable that denotes the variable name.							|
|	|				The variable as can be denoted MUST be numeric and set as one of below values:										|
|	|				[0]: Holiday																										|
|	|				[1]: Workday																										|
|	|inDATE		:	The date for which to flag the workday.																				|
|	|				It MUST be provided as a (date) number or a numeric variable that denotes the date value.							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20170603		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170609		| Version |	1.01		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Modified the RETURN statement to make it easier to read.																	|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170701		| Version |	1.01		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replaced the call of macro [getOBS4DATA] by the call of function [getOBS4DATA] as defined in FCmp Procedure.				|
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
|	|[1]	:	The [inDATE] is Workday.																								|
|	|[0]	:	The [inDATE] is NOT Workday.																							|
|	|[.]	:	The [inDATE] cannot be found in the [inCalendar].																		|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|usFUN_getOBS4DATA																												|
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

%*100.	Function that identifies whether the provided date value is Workday in terms of the given Calendar data.;
function
	isWorkDay(
		inCalendar	$
		,ClnDateVar	$
		,ClnFWDVar	$
		,inDATE
	)
;
	%*050.	Declare internal fields.;
	attrib
		tmpOBS	length=8
		i		length=8
	;
	i		=	1;

	%*110.	Find the number of observations of above Calendar data to be loaded.;
	tmpOBS	=	getOBS4DATA(strip(inCalendar));

	%*200.	Create dynamic array to read the Calendar data.;
	%*We only need two fields to be read into the array: [ClnDateVar] and [ClnFWDVar],;
	%* hence the second dimension of the array is set to 2.;
	array
		_clnARR{1,1}
		/nosymbols
	;
	call dynamic_array(_clnARR,tmpOBS,2);

	%*300.	Read the Calendar data into the array.;
	_iorc_	=	read_array(strip(inCalendar),_clnARR,strip(ClnDateVar),strip(ClnFWDVar));

	%*500.	Assign the value of Workday Flag to the output result in terms of Exhaust Algorithm.;
	%*Here we presume that the Workday Flag is stored as numeric.;
	do until (i = dim(_clnARR,1));
		if	_clnARR{i,1}	=	inDATE	then do;
			return(_clnARR{i,2});
		end;
		i	+	1;
	end;

%*700.	Finish the definition of the function.;
%*If no such date as provided is found in the Calendar data, we return a missing value.;
return(.);
endsub;

%*900.	Purge memory usage.;

%EndOfProc:
%mend usFUN_isWorkDay;

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
	%usFUN_getOBS4DATA

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
	D_NTB	=	mdy(11,22,2015);
	f_WD	=	isWorkDay("clndr.calendar2015","D_DATE","F_WORKDAY",D_NTB);
run;

%*500.	Call the function to retrieve the Workday Flag for the provided date in Macro Facility.;
%put	%sysfunc(isWorkDay(clndr.calendar2015,D_DATE,F_WORKDAY,20414));

/*-Notes- -End-*/