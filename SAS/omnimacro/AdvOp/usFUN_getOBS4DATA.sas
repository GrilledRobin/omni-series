%macro usFUN_getOBS4DATA;
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro returns the number of observations in a data set,																		|
|	|or . if the data set does not exist or cannot be opened.																			|
|	|- It first opens the data set. An error message is returned																		|
|	| and processing stops if the dataset cannot be opened.																				|
|	|- It next checks the values of the data set attributes																				|
|	| ANOBS (does SAS know how many observations there are?) and																		|
|	| WHSTMT (is a where statement in effect?).																							|
|	|- If SAS knows the number of observations and there is no																			|
|	|  where clause, the value of the data set attribute NLOBS																			|
|	|  (number of logical observations) is returned.																					|
|	|- If SAS does not know the number of observations (perhaps																			|
|	|  this is a view or transport data set) or if a where clause																		|
|	|  is in effect, the macro iterates through the data set																			|
|	|  in order to count the number of observations.																					|
|	|The value returned is a whole number if the data set exists,																		|
|	| or a period (the default missing value) if the data set																			|
|	| cannot be opened.																													|
|	|This macro requires the data set information functions,																			|
|	|which are available in SAS version 6.09 and greater.																				|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|The function is defined by PCmp Procedure, so its scope is limited by FCmp Procedure.												|
|	|It is tested that PUT statements (to write messages in LOG) would cause "PROC UNKNOWN is running" when the function is called		|
|	| in Macro Facility. Hence we remove them.																							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDAT	:	The dataset to be verified																								|
|	|			It MUST be provided as a quoted string or a text variable that denotes the full dataset name.							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20170701		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Return Values:	[Numeric]																											|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|[(Number)]	:	The number of observations of the provided dataset.																	|
|	|[.]		:	The dataset either does not exist or cannot be accessed.															|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
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

%*100.	Function that retrieves the number of observations for the given dataset.;
function
	getOBS4DATA(
		inDAT	$
	)
;
	%*050.	Declare internal fields.;
	attrib
		DSID	length=8
		ANOBS	length=8
		WHSTMT	length=8
		outVAR	length=8
		PutMsg	length=$256
	;
	PutMsg	=	"";
	%*If the dataset cannot be processed, return a missing value.;
	outVAR	=	.;

	%*100.	Skip the process if the input is blank.;
	if	missing(inDAT)	=	1	then do;
		PutMsg	=	"%str(N)OTE: [&L_mcrLABEL.]Dataset name is missing.";
%*		put		PutMsg;
		return;
	end;

	%*200.	Open the dataset.;
	DSID	=	open(strip(inDAT));

	%*290.	Issue a message and quit the function if it is NOT opened.;
	if	DSID	=	0	then do;
		PutMsg	=	"%str(N)OTE: [&L_mcrLABEL.]Dataset cannot be opened.";
%*		put		PutMsg;
		goto	CloseDS;
	end;

	%*300.	Retrieve the necessary attributes from the dataset.;
	%*310.	Verify whether the dataset has observation.;
	ANOBS	=	attrn(DSID,"ANOBS");

	%*320.	Verify whether the provided dataset name has WHERE option.;
	WHSTMT	=	attrn(DSID,"WHSTMT");

	%*400.	Retrieve the number of observations if there are observations and, meanwhile, there is NO WHERE option.;
	if	ANOBS	=	1	and	WHSTMT	=	0	then do;
		outVAR	=	attrn(DSID,"NLOBS");
	end;

	%*500.	We should retrieve the number of observations by iterating all observations one by one if the above condition is NOT satisified.;
	else do;
		%*100.	Issue a message for this situation.;
		if	getoption("MSGLEVEL")	=	"I"	then do;
			PutMsg	=	cats("%str(I)NFO: [&L_mcrLABEL.]Observations in [",inDAT,"] must be retrieved by iteration.");
%*			put	PutMsg;
		end;

		%*500.	Read each observation sequentially.;
		do	while (fetch(DSID, "NOSET") = 0);
			outVAR	+	1;
		end;
	end;

	%*800.	Close the dataset.;
	CloseDS:
	if	DSID	^=	0	then do;
		_iorc_	=	close(DSID);
	end;

	%*900.	Finish the definition of the function.;
	return(outVAR);
endsub;

%*900.	Purge memory usage.;

%EndOfProc:
%mend usFUN_getOBS4DATA;

/*-Info- -Begin-* /
%*000.	Old method.;
data _NULL_;
	if	0	then	set	&inDAT.	nobs=tmpobs;
	call symput("&outVAR.",tmpobs);
	stop;
run;

For more information please find in below paper:
p095-26_getOBS4DATA.pdf
/*-Info- -End-*/

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvOp"
	)
	mautosource
;

%*090.	This step ensures there is no WARNING message issued when executing the FCmp Procedure.;
options
	cmplib=_NULL_
;

%*100.	Compile the function as defined in the macro.;
proc FCmp
	outlib=work.fso.AdvOp
;

	%usFUN_getOBS4DATA

run;
quit;

%*200.	Tell the program where to find the compiled functions.;
options
	cmplib=work.fso
;

%*300.	Create a dataset;
data aa;
	aa	=	1;	output;
	aa	=	2;	output;
	aa	=	3;	output;
	aa	=	4;	output;
run;
data bb;
	cc	=	0;
	if	0;
run;

%*400.	Call the function to retrieve the number of observations of above dataset.;
data tt;
	length
		dsname
		dsname2
		dsname3
		$64.
	;
	dsname	=	" aa";
	dsname2	=	"";
	dsname3	=	"bb";

	%*100.	Directly provide the dataset name.;
	nobs1	=	getOBS4DATA("aa");

	%*200.	Denote the variable.;
	nobs2	=	getOBS4DATA(dsname);

	%*300.	Provide a WHERE option.;
	whrstmt	=	cats(dsname,"(where=(aa>2))");
	nobs3	=	getOBS4DATA(whrstmt);

	%*400.	Test if there is NO dataset provided.;
	nobs4	=	getOBS4DATA(dsname2);

	%*500.	Test if the provided dataset has no observation.;
	nobs5	=	getOBS4DATA(dsname3);
run;

%*500.	Call the function to retrieve the number of observations of above dataset in Macro Facility.;
%put	%sysfunc(getOBS4DATA(aa));
%put	%sysfunc(getOBS4DATA(bb));
%put	%sysfunc(
			getOBS4DATA(
				%nrbquote(
					aa(
						where=(
							aa>3
						)
					)
				)
			)
		)
;

%*600.	Suppose the dataset does not exist.;
%put	%sysfunc(getOBS4DATA(cc));

/*-Notes- -End-*/