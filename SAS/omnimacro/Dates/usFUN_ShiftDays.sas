%macro usFUN_ShiftDays;
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This function is intended to shift the provided date to its [n]th Previous/Next Trade/Work Days,									|
|	| with respect of the provided Calendar data.																						|
|	|The function is defined by PCmp Procedure, so its scope is limited by FCmp Procedure.												|
|	|The major drawback of this function is that it has to load the entire Calendar data at each call on each observation of the input	|
|	| dataset, which slow down the overall process.																						|
|	|The reason tha leads to this is that the READ_ARRAY function and the HASH object both cannot accept dataset option WHERE as input.	|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDATE		:	The date to be shifted																								|
|	|				It MUST be provided as a (date) number or a numeric variable that denotes the date value.							|
|	|inCalendar	:	The dataset that contains the dates with respect of the Calendar.													|
|	|				It MUST be provided as a quoted string or a text variable that denotes the full dataset name.						|
|	|TypeShift	:	The type to shift the provided date																					|
|	|				It MUST be provided as a quoted string or a text variable that denotes the type of shift.							|
|	|				[W]: Work Day																										|
|	|				[T]: Trade Day																										|
|	|				Default: [W]																										|
|	|kShift		:	The number of dates to shift																						|
|	|				It MUST be provided as an integar or a numeric variable that denotes the integar to shift the date.					|
|	|				If it is provided as [0], program searches for the latest Trade/Work Day previous or equal to the provided one,		|
|	|				 which could just be the same as it.																				|
|	|				Default: [0]																										|
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
|	| Date |	20181020		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
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
|	|[(Number)]	:	The date value that denotes the shifted date to [inDATE].															|
|	|[.]		:	The [inDATE] cannot be properly shifted.																			|
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

%*100.	Function that returns the date value that denotes the shifted date to [inDATE].;
function
	ShiftDays(
		inDATE
		,inCalendar	$
		,TypeShift	$
		,kShift
		,ClnDateVar	$
		,ClnFWDVar	$
		,ClnFTDVar	$
	)
;
	%*010.	Check parameters.;
	if	missing(inDATE)		then	return;
	if	missing(inCalendar)	then	return;

	%*050.	Declare internal fields.;
	attrib
		tts		length=$1	tks		length=8	tvcd	length=$32	tvwd	length=$32	tvtd	length=$32
		tmpOBS	length=8	tmpFMT	length=$256	tmpk	length=8	tvar	length=8
		i		length=8	j		length=8	k		length=8
	;
	tts		=	ifc( upcase(TypeShift) ^= "T" , "W" , "T" );
	tks		=	ifn( missing(kShift) , 0 , kShift );
	tvcd	=	ifc( missing(ClnDateVar) , "D_DATE" , ClnDateVar );
	tvwd	=	ifc( missing(ClnFWDVar) , "F_WORKDAY" , ClnFWDVar );
	tvtd	=	ifc( missing(ClnFTDVar) , "F_TradeDay" , ClnFTDVar );

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

	%*400.	Create the bucket to store the [n] closest dates to the provided one.;
	array
		_dayARR{1}
		/nosymbols
	;
	if	tks	^=	0	then do;
		call dynamic_array(_dayARR,abs(tks));
	end;

	%*500.	Retrieve the Trade/Work Days for shifting.;
	do i = 1 to dim(_clnARR,1);
		%*010.	Skip if current date is not a Trade/Work Day as requested.;
		if	_clnARR{i,2}	=	0	then do;
			goto	EndOfDate;
		end;

		%*100.	Handle the case when [tks=0];
		if	tks	=	0	then do;
			%*010.	Skip if current date is later than the provided one.;
			if	_clnARR{i,1}	>	inDATE	then do;
				goto	EndOfDate;
			end;

			%*100.	As long as the stored date value in the bucket is not the latest one, we replace it with the new one.;
			if	_dayARR{1}	<	_clnARR{i,1}	then do;
				_dayARR{1}	=	_clnARR{i,1};
			end;
		end;

		%*400.	Handle the case when [tks<0];
		else if	tks	<	0	then do;
			%*010.	Skip if current date is later than the provided one.;
			if	_clnARR{i,1}	>=	inDATE	then do;
				goto	EndOfDate;
			end;

			%*100.	As long as the first among the [n] days is missing, we continue to add date to the bucket and sort them in ascending order.;
			if	missing(_dayARR{1})	then do;
				_dayARR{1}	=	_clnARR{i,1};
				goto	EndOfLT0;
			end;

			%*200.	Skip if current date is earlier than the earliest one in the bucket.;
			if	_clnARR{i,1}	<=	_dayARR{1}	then do;
				goto	EndOfDate;
			end;

			%*300.	If the new date is later than the earliest one in the bucket, we popup the earliest one while append this one.;
			_dayARR{1}	=	_clnARR{i,1};

			%*900.	Sort the new list in ascending order.;
			EndOfLT0:
			do j = 1 to abs(tks);
				do k = j + 1 to abs(tks);
					if	_dayARR{j}	>	_dayARR{k}	then do;
						tvar		=	_dayARR{j};
						_dayARR{j}	=	_dayARR{k};
						_dayARR{k}	=	tvar;
					end;
				end;
			end;
		end;

		%*700.	Handle the case when [tks>0];
		else do;
			%*010.	Skip if current date is later than the provided one.;
			if	_clnARR{i,1}	<=	inDATE	then do;
				goto	EndOfDate;
			end;

			%*100.	As long as the last/earliest among the [n] days is missing, we continue to add date to the bucket and sort them in descending order.;
			if	missing(_dayARR{abs(tks)})	then do;
				_dayARR{abs(tks)}	=	_clnARR{i,1};
				goto	EndOfGT0;
			end;

			%*200.	Skip if current date is later than the latest one in the bucket.;
			if	_clnARR{i,1}	>=	_dayARR{1}	then do;
				goto	EndOfDate;
			end;

			%*200.	If the new date is earlier than the first/latest one in the bucket, we popup the latest one while append this one.;
			_dayARR{1}	=	_clnARR{i,1};

			%*900.	Sort the new list in descending order.;
			EndOfGT0:
			do j = 1 to abs(tks);
				do k = j + 1 to abs(tks);
					if	_dayARR{j}	<	_dayARR{k}	then do;
						tvar		=	_dayARR{j};
						_dayARR{j}	=	_dayARR{k};
						_dayARR{k}	=	tvar;
					end;
				end;
			end;
		end;

		%*900.	Mark the end of current date value.;
		EndOfDate:
	end;

	%*600.	Return the dedicated one as found.;
	%*610.	If there are not enough dates found in the calendar, we return a missing value.;
	if	missing(_dayARR{dim(_dayARR)})	or	missing(_dayARR{1})	then do;
		return;
	end;

	%*650.	Return the first date value in the bucket.;
	return(_dayARR{1});

%*700.	Finish the definition of the function.;
endsub;

%*900.	Purge memory usage.;

%EndOfProc:
%mend usFUN_ShiftDays;

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

	%usFUN_ShiftDays
	%usFUN_getOBS4DATA

run;
quit;

%*200.	Locate the Calendar data.;
libname	clndr	"D:\SAS\Calendar";

%*300.	Tell the program where to find the compiled functions.;
options
	cmplib=work.fso
;

%*400.	Call the function to retrieve the previous/next Trade/Work Days for each observation in the provided data.;
data aa;
	format	D_NTB	yymmddD10.;
	D_NTB	=	mdy(11,22,2015);	Type	=	"W";	Shift	=	3;	output;
	D_NTB	=	mdy(2,14,2015);		Type	=	"T";	Shift	=	-2;	output;
	D_NTB	=	mdy(6,1,2015);		Type	=	"T";	Shift	=	0;	output;
run;
data bb;
	set aa;
	format	D_WD	yymmddD10.;
	D_WD	=	ShiftDays(D_NTB,"clndr.calendar2015",Type,Shift,"","","");
run;

%*500.	Call the function to retrieve the previous Workday for the provided date in Macro Facility.;
%put	%sysfunc(putn( %sysfunc(ShiftDays(20414,clndr.calendar2015,W,-1,,,)) , yymmddN8. ));

/*-Notes- -End-*/