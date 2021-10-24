%macro usFUN_DateDiff;
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This function is intended to count the number of Work/Trade Days from [inBgn] to [inEnd] with respect of the provided Calendar		|
|	| data.																																|
|	|The function is defined by PCmp Procedure, so its scope is limited by FCmp Procedure.												|
|	|The major drawback of this function is that it has to load the entire Calendar data at each call on each observation of the input	|
|	| dataset, which slow down the overall process.																						|
|	|The reason tha leads to this is that the READ_ARRAY function and the HASH object both cannot accept dataset option WHERE as input.	|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inBgn		:	The date as a start to count the days																				|
|	|				It MUST be provided as a (date) number or a numeric variable that denotes the date value.							|
|	|inEnd		:	The date as an end to count the days																				|
|	|				It MUST be provided as a (date) number or a numeric variable that denotes the date value.							|
|	|inCalendar	:	The dataset that contains the dates with respect of the Calendar.													|
|	|				It MUST be provided as a quoted string or a text variable that denotes the full dataset name.						|
|	|TypeShift	:	The type to shift the provided date																					|
|	|				It MUST be provided as a quoted string or a text variable that denotes the type of shift.							|
|	|				[W]: Work Day																										|
|	|				[T]: Trade Day																										|
|	|				Default: [W]																										|
|	|ClnDateVar	:	The variable name that represents the Date in the Calendar.															|
|	|				It MUST be provided as a quoted string or a text variable that denotes the variable name.							|
|	|				Default: [D_DATE]																									|
|	|ClnFWDVar	:	The variable name that represents the Flag of Workday in the Calendar.												|
|	|				It MUST be provided as a quoted string or a text variable that denotes the variable name.							|
|	|				The variable as can be denoted MUST be numeric and set as one of below values:										|
|	|				[0]: Non Workday																									|
|	|				[1]: Work Day																										|
|	|				Default: [F_WORKDAY]																								|
|	|ClnFTDVar	:	The variable name that represents the Flag of Trade Day in the Calendar.											|
|	|				It MUST be provided as a quoted string or a text variable that denotes the variable name.							|
|	|				The variable as can be denoted MUST be numeric and set as one of below values:										|
|	|				[0]: Non Trade Day																									|
|	|				[1]: Trade Day																										|
|	|				Default: [F_TradeDay]																								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20181125		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
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
|	|	F_TradeDay	(numeric, flag)																										|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Return Values:	[Numeric]																											|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|[(Number)]	:	The number of Work/Trade Days counting from [inBgn] to [inEnd] as indicated by [TypeShift]							|
|	|[.]		:	The counting fails.																									|
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

%*100.	Function that returns the number of Work/Trade Days counting from [inBgn] to [inEnd] as indicated by [TypeShift].;
function
	DateDiff(
		inBgn
		,inEnd
		,inCalendar	$
		,TypeShift	$
		,ClnDateVar	$
		,ClnFWDVar	$
		,ClnFTDVar	$
	)
;
	%*010.	Check parameters.;
	if	missing(inBgn)		then	return;
	if	missing(inEnd)		then	return;
	if	missing(inCalendar)	then	return;

	%*050.	Declare internal fields.;
	attrib
		tts		length=$1	tvcd	length=$32	tvwd	length=$32	tvtd	length=$32	tmin	length=8	tmax	length=8
		tmpOBS	length=8	tmpk	length=8	tmpf	length=8	i		length=8
	;
	tts		=	ifc( upcase(TypeShift) ^= "T" , "W" , "T" );
	tvcd	=	ifc( missing(ClnDateVar) , "D_DATE" , ClnDateVar );
	tvwd	=	ifc( missing(ClnFWDVar) , "F_WORKDAY" , ClnFWDVar );
	tvtd	=	ifc( missing(ClnFTDVar) , "F_TradeDay" , ClnFTDVar );
	tmin	=	min( inBgn , inEnd );
	tmax	=	max( inBgn , inEnd );
	tmpk	=	0;
	tmpf	=	ifn( inEnd >= inBgn , 1 , -1 );

	%*110.	Find the number of observations of above Calendar data to be loaded.;
	tmpOBS	=	getOBS4DATA(strip(inCalendar));

	%*200.	Create dynamic array to read the Calendar data.;
	%*We only need two fields to be read into the array: [ClnDateVar] and [ClnFWDVar/ClnFTDVar],;
	%* hence the second dimension of the array is set to 2.;
	array
		_clnARR{1,1}
		/nosymbols
	;
	call dynamic_array(_clnARR,tmpOBS,2);

	%*300.	Read the Calendar data into the array.;
	if	tts	=	"W"	then do;
		_iorc_	=	read_array(strip(inCalendar),_clnARR,strip(tvcd),strip(tvwd));
	end;
	else do;
		_iorc_	=	read_array(strip(inCalendar),_clnARR,strip(tvcd),strip(tvtd));
	end;

	%*500.	Count the days.;
	do i = 1 to dim(_clnARR,1);
		%*010.	Skip if current date is not a Trade/Work Day as requested.;
		if	_clnARR{i,2}	=	0	then do;
			goto	EndOfDate;
		end;

		%*100.	Increment the counter if current date is between both edges.;
		if	tmin	<	_clnARR{i,1}	<=	tmax	then do;
			tmpk	+	1;
		end;

		%*900.	Mark the end of current date value.;
		EndOfDate:
	end;

	%*600.	Return the value in terms of the direction.;
	return( tmpk * tmpf );

%*700.	Finish the definition of the function.;
endsub;

%*900.	Purge memory usage.;

%EndOfProc:
%mend usFUN_DateDiff;

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

	%usFUN_DateDiff
	%usFUN_getOBS4DATA

run;
quit;

%*200.	Locate the Calendar data.;
libname	clndr	"D:\SAS\Calendar";

%*300.	Tell the program where to find the compiled functions.;
options
	cmplib=work.fso
;

%*400.	Call the function to count the number of Trade/Work Days for each observation in the provided data.;
data aa;
	format	D_NTB	D_NOW	yymmddD10.;
	D_NTB	=	mdy(11,22,2015);	Type	=	"W";	D_NOW	=	mdy(11,26,2015);	output;
	D_NTB	=	mdy(2,14,2015);		Type	=	"T";	D_NOW	=	mdy(2,12,2015);		output;
	D_NTB	=	mdy(6,1,2015);		Type	=	"T";	D_NOW	=	mdy(6,1,2015);		output;
run;
data bb;
	set aa;
	length	K_Diff	8;
	K_Diff	=	DateDiff(D_NTB,D_NOW,"clndr.calendar2015",Type,"","","");
run;

%*500.	Call the function to count the number of Trade/Work Days in Macro Facility.;
%put	%sysfunc(DateDiff(20414,20410,clndr.calendar2015,W,,,));

/*-Notes- -End-*/