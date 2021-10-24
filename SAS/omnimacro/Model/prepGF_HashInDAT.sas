%macro prepGF_HashInDAT;
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is to hash the re-formatted [inDAT] for all "Get-Function" as models to improve the system processing.					|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20150130		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180311		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*100.	Prepare hash object of hashed groups of GrpBy.;
if	_N_	=	1	then do;
	%*100.	Declare the hash object storing the Group-objects for each GrpBy.;
	%*Each element in the array "hGrpByVar" stores a group of records under the same GrpBy.;
	%* the array is instantiated using the usual "combined" method.;
%if	%length(%qsysfunc(compress(&GrpBy.,%str( ))))	^=	0	%then %do;
	dcl	hash	hGrpByVar(hashexp:10, ordered: 'a');
	dcl	hiter	hiGrpByVar('hGrpByVar');
	hGrpByVar.DefineKey(&LGrpQC.);
	hGrpByVar.DefineData('hByVar', 'hiByVar');
	hGrpByVar.DefineDone();
%end;

	%*200.	Declare the hash object storing the records for each GrpBy.;
	%*Its future instances are intended to hold group of GrpBy-related data from the input file,;
	%* is declared, but not yet instantiated.;
	dcl	hash	hByVar();
	dcl	hiter	hiByVar;
end;

%*200.	Instantiate the hash objects of all groups of GrpBy.;
%if	%length(%qsysfunc(compress(&GrpBy.,%str( ))))	^=	0	%then %do;
	do	_n_	=	1	by	1	until	( eof );
		%*100.	Read each record from base data into the hash.;
		set &procLIB.._gf_indat end = eof;

		%*200.	For each newly encountered GrpBy, instantiate its corresponding hash table.;
		%*.FIND() method searches hGrpByVar table using the current ID as a key. If it does not find an hByVar hash object with this key,;
		%* it has not been instantiated yet. Hence, it is now instantiated and stored in hGrpByVar by means of the hGrpByVar.REPLACE();
		%* method. Otherwise, an existing hash instance is copied from hGrpByVar into its 'host variable' hByVar to be reused.;
		if	hGrpByVar.find()	ne	0	then do;
			hByVar	=	_new_	hash();
			hiByVar	=	_new_	hiter('hByVar');
			hByVar.DefineKey(&LGrpQC.,&LKeyQC.);
			hByVar.DefineData("K_ObsOriginal");
			hByVar.DefineDone();
			hGrpByVar.replace();
		end ;

		%*300.	Store the records into current hByVar instance.;
		%*The values from the record are inserted via hByVar.REPLACE() method into the hash table whose instance hByVar currently holds.;
		hByVar.replace();
	end ;
%end;
%else %do;
	if	_N_	=	1	then do;
		hByVar	=	_new_	hash(dataset: "&procLIB.._gf_indat");
		hiByVar	=	_new_	hiter('hByVar');
		hByVar.DefineKey(&LKeyQC.);
		hByVar.DefineData("K_ObsOriginal");
		hByVar.DefineDone();
		call missing(&LKeyC.,K_ObsOriginal);
	end;
%end;

%EndOfProc:
%mend prepGF_HashInDAT;