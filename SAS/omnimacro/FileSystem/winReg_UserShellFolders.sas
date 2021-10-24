%macro winReg_UserShellFolders(
	outDAT
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to retrieve all values under the key [User Shell Folders] from the Windows(R) registry						|
|	|Quote: https://blog.csdn.net/yq_forever/article/details/89638012																	|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|outDAT		:	Output result which contains below fields:																			|
|	|				[ name       ]	The name of the entry (e.g. [Personal] ==> [My Documents])											|
|	|				[ reg_tp     ]	The type of the entry in Windows Registry															|
|	|				[ value_mask ]	The masked value (by DOS variable) of the entry in Windows Registry									|
|	|				[ value_act  ]	The value of the entry																				|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20210113		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro can only be called in open code, for it executes DATA Steps																|
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
%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))	=	0	%then %do;
	%put	%str(W)ARNING: [&L_mcrLABEL.]Output dataset name is not provided! It is set as [work.winUSF];
	%let	outDAT	=	work.winUSF;
%end;

%*013.	Define the local environment.;
%local
	reg_key
	dumcmd
	rc
;
%let	reg_key	=	HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders;
%let	dumcmd	=	sysecho;

%*100.	Define the pipe connection to the query of Windows Registry.;
filename myreg pipe %sysfunc(quote(REG QUERY %sysfunc(quote(&reg_key., %str(%"))), %str(%')));

%*500.	Retrieve the requested entries of Windows Registry.;
data reg_query;
	%*010.	Define the pipe command as input.;
	infile
		myreg
		%*There are 4 consecutive spaces set as delimiters between the fields in the pipe output.;
		dlmstr="    "
		%*We need to skip the missing fields in any line, otherwise the results are mis-located.;
		missover
	;

	%*050.	Create new fields.;
	length	k_entry	8	name	reg_tp	value_mask	$512;
	input	name	$	reg_tp	$	value_mask	$;

	%*300.	Remove the invalid results from the query.;
	if	missing(reg_tp)	=	1	and	missing(value_mask)	=	1	then	delete;

	%*500.	Assign counts to the entries.;
	retain	k_entry	0;
	k_entry	+	1;

	%*700.	Create macro variables for further resolution of the masked values.;
	call symputx(cats('REGe',k_entry),value_mask,'F');
	%*Below value assignment action will be taken many timnes until the pipe closes.;
	call symputx('REGk',k_entry,'F');

	%*990.	Purge.;
	keep	k_entry	name	reg_tp	value_mask;
run;

%*700.	Loop all masked values and use system console to resolve them respectively.;
%do Ri=1 %to &REGk.;
	%*100.	Create a pipe connection to the command console.;
	%let	rc	=	%sysfunc(filename(dumcmd, echo %superq(REGe&Ri.), pipe));

	%*500.	Retrieve the result evaluated by the Windows command console.;
	data _NULL_;
		infile	&dumcmd.;
		length	val	$512;
		input	val	$;
		call symputx(cats('REGv',&Ri.),val,'F');
	run;

	%*900.	Purge.;
	%let	rc	=	%sysfunc(filename(dumcmd));
%end;

%*900.	Combine the resolved values to the original query.;
data %unquote(&outDAT.);
	%*100.	Set the source data.;
	set	reg_query;

	%*500.	Add the resolved values.;
	length	value_act	$512;
	value_act	=	symget(cats('REGv',k_entry));
run;

%*990.	Purge.;
filename	myreg;

%EndOfProc:
%mend winReg_UserShellFolders;