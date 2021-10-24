%macro H_DBmin_ChangeInHistory(
	baseDAT		=
	,compDAT	=
	,CompDate	=
	,fPartial	=	0
	,byVAR		=	C_FLD
	,inVAR		=	C_VAL
	,procLIB	=	WORK
	,outDAT		=
);
%*000.	Introduction.;
%*Creation: Lu Robin Bin 20140322;
%*Version: 1.00;
%*This macro is intended to log all changes of the records in the data,;
%* so that all correct snapshot at any certain date spot can be easily extracted.;
%*Important: please assure all data for update should be verified before they are applied,;
%* otherwise the base data cannot be restored.;

%*001.	Glossary.;
%*baseDAT	:	The base data to be compared.;
%*compDAT	:	The data which is used to compare with the base data.;
%*				 It should only contain the data as of a certain Date instead of a period of dates.;
%*CompDate	:	The date on which the comparison is committed.;
%*				 It should be a number instead of a string, such as 19721, or "01Dec2013"d.;
%*fPartial	:	The flag for Partial Update, can only be 1 or 0.;
%*byVAR		:	The key by which the comparison is committed, it should be unique in the "&compDAT.".;
%*inVAR		:	The field which is to be compared.;
%*				 It should be only one field existing in both data.;
%*procLIB	:	The working folder.;
%*outDAT	:	The update4d result.;

%*002.	Update log.;
%*Updater: Lu Robin Bin 20140323;
%*Version: 2.00;
%*Log: Add new module to handle extreme cases, which update the historical data earlier than the first records.;

%*Updater: Lu Robin Bin 20140324;
%*Version: 3.00;
%*Log: Add new module to handle partial update.;
%*     Partial update only suppress the unaffected records to have their D_END modified automatically,;
%*      while any new records are still inserted.;
%*     Eg. there are 100 Keys in the Base Data, and yet you only want to update the information for 2 of them.;

%*Updater: Lu Robin Bin 20140412;
%*Version: 3.10;
%*Log: Slightly enhance the program efficiency.;

%*Updater: Lu Robin Bin 20140413;
%*Version: 3.20;
%*Log: Add validation to inVAR, fix a bug when inVAR has the length of its varname as 32.;

%*Updater: Lu Robin Bin 20140418;
%*Version: 4.00;
%*Log: Should there be any dataset option specified during the macro variable reference, there could be errors;
%*      reported when the marco is called. We eliminate the possibility to happen by validating the DS name.;

%*Updater: Lu Robin Bin 20140420;
%*Version: 4.10;
%*Log: Standardize the program to extract the valid DSN as well as the valid Variable Name.;

%*Updater: Lu Robin Bin 20140819;
%*Version: 5.00;
%*Log: Change the process method into SAS Hash Object to enhance the performance in terms of RAM utilization.;
%*      This process consumes extremely large RAM, hence is desperately supercalifragilisticexpialedocious on powerless OS!;

%*Updater: Lu Robin Bin 20150613;
%*Version: 6.00;
%*Log: Optimize the SAS Hash Object by clearing the hash instance after each group is processed and output.;

%*003.	User Manual.;

%*010.	Set parameters.;
%*011.	Identify current processing macro.;
%local
	L_mcrLABEL
	Lerror
;
%let	L_mcrLABEL	=	&sysMacroName.;
%let	Lerror		=	ERROR: [&L_mcrLABEL.]Process failed due to errors!;

%*012.	Handle the parameter buffer.;
%let	baseDAT		=	%unquote(&baseDAT.);
%let	compDAT		=	%unquote(&compDAT.);
%let	CompDate	=	%unquote(&CompDate.);
%let	fPartial	=	%unquote(&fPartial.);
%let	byVAR		=	%unquote(&byVAR.);
%let	inVAR		=	%unquote(&inVAR.);
%let	procLIB		=	%unquote(&procLIB.);
%let	outDAT		=	%unquote(&outDAT.);

%if	%nrbquote(&baseDAT.)	EQ	%then %do;
	%put	ERROR: [&L_mcrLABEL.]Base Data is not provided!;
	%put	&Lerror.;
	%*Below macro is from "&cdwmac.\AdvOp";
	%ErrMcr
%end;

%if	%nrbquote(&compDAT.)	EQ	%then %do;
	%put	NOTE: [&L_mcrLABEL.]No update data is provided, the Base Data will have no change.;
	%goto	EndOfProc;
%end;

%if	%nrbquote(&CompDate.)	EQ	%then %do;
	%put	NOTE: [&L_mcrLABEL.]No Update date is provided, the last update date will be set as system date.;
	%let	CompDate	=	"&sysdate."d;
%end;

%if	%nrbquote(&fPartial.)	NE	1	%then %do;
	%put	NOTE: [&L_mcrLABEL.]Flag of Partial Update is not set as 1, system will set Full Update as default.;
	%let	fPartial	=	0;
%end;

%if	%nrbquote(&byVAR.)		EQ	%then	%let	byVAR	=	C_FLD;
%if	%nrbquote(&inVAR.)		EQ	%then	%let	inVAR	=	C_VAL;
%if	%nrbquote(&procLIB.)	EQ	%then	%let	procLIB	=	WORK;

%if	%nrbquote(&outDAT.)		EQ	%then %do;
	%put	NOTE: [&L_mcrLABEL.]Output Data is omitted, hence the Base Data "&baseDAT." will be overwritten.;
	%let	outDAT	=	&baseDAT.;
%end;

%*013.	Define the local environment.;
%local
	LcrBaseDAT
	LvLstQuoteComma
	LvLstComma
	LvLstKeyComma
	VJi
;
%let	LcrBaseDAT	=	0;

%*020.	Further verify the parameters.;
%*021.	Verify the existence of both data.;
%*Below macro is from "&cdwmac.\AdvOp";
%if	%ValidateDSNasStr(inSTR=%nrbquote(&baseDAT.),FUZZY=0)	=	0	%then %do;
	%put	ERROR: [&L_mcrLABEL.]System does not accept DS Options or other invalid characters as baseDAT "&baseDAT."!;
	%put	&Lerror.;
	%*Below macro is from "&cdwmac.\AdvOp";
	%ErrMcr
%end;
%if	%ValidateDSNasStr(inSTR=%nrbquote(&compDAT.),FUZZY=0)	=	0	%then %do;
	%put	ERROR: [&L_mcrLABEL.]System does not accept DS Options or other invalid characters as compDAT "&compDAT."!;
	%put	&Lerror.;
	%*Below macro is from "&cdwmac.\AdvOp";
	%ErrMcr
%end;
%if	%sysfunc(exist(&baseDAT.))	=	0	%then %do;
	%put	NOTE: [&L_mcrLABEL.]Specified file "&baseDAT." does not exist.;
%end;
%if	%sysfunc(exist(&compDAT.))	=	0	%then %do;
	%put	NOTE: [&L_mcrLABEL.]Specified file "&compDAT." does not exist, the Base Data will have no change.;
	%goto	EndOfProc;
%end;
%if	%sysfunc(exist(&baseDAT.))	=	0	and	%sysfunc(exist(&compDAT.))	=	1	%then %do;
	%put	NOTE: [&L_mcrLABEL.]"&baseDAT." will be created on behalf of "&compDAT.".;
	%let	LcrBaseDAT	=	1;
%end;

%*025.	Validate &inVAR..;
%*Below macro is from "&cdwmac.\AdvOp";
%if	%ValidateVarNameAsStr(inSTR=%nrbquote(&inVAR.))	=	0	%then %do;
	%put	ERROR: [&L_mcrLABEL.]inVAR "&inVAR." is not one valid SAS data field!;
	%put	&Lerror.;
	%*Below macro is from "&cdwmac.\AdvOp";
	%ErrMcr
%end;
%*Verify its existence in both data.;
%*Below macro is from "&cdwmac.\FileSystem";
%if	&LcrBaseDAT.	=	0	%then %do;
	%if	%FS_VarExists(inDAT=&baseDAT.,inFLD=&inVAR.)	=	0	%then %do;
		%put	ERROR: [&L_mcrLABEL.]inVAR "&inVAR." does not exist in baseDAT "&baseDAT."!;
		%put	&Lerror.;
		%*Below macro is from "&cdwmac.\AdvOp";
		%ErrMcr
	%end;
%end;
%if	%FS_VarExists(inDAT=&compDAT.,inFLD=&inVAR.)	=	0	%then %do;
	%put	ERROR: [&L_mcrLABEL.]inVAR "&inVAR." does not exist in compDAT "&compDAT."!;
	%put	&Lerror.;
	%*Below macro is from "&cdwmac.\AdvOp";
	%ErrMcr
%end;

%*090.	Prepare the "by variable" list.;
%*Below macro is from "&cdwmac.\AdvOp";
%genvarlist(
	nstart		=	1
	,inlst		=	&byVAR.
	,nvarnm		=	LeByVar
	,nvarttl	=	LnByVar
)
%let	LvLstQuoteComma	=;
%do VJi=1 %to &LnByVar.;
	%let	LvLstQuoteComma	=	&LvLstQuoteComma.,"&&LeByVar&VJi..";
%end;
%let	LvLstQuoteComma	=	%unquote(%substr(%nrbquote(&LvLstQuoteComma.),2));

%let	LvLstComma	=;
%do VJi=1 %to &LnByVar.;
	%let	LvLstComma	=	&LvLstComma.,&&LeByVar&VJi..;
%end;
%let	LvLstComma	=	%unquote(%substr(%nrbquote(&LvLstComma.),2));

%let	LvLstKeyComma	=;
%do VJi=1 %to &LnByVar.;
	%let	LvLstKeyComma	=	&LvLstKeyComma.,key: &&LeByVar&VJi..;
%end;
%let	LvLstKeyComma	=	%unquote(%substr(%nrbquote(&LvLstKeyComma.),2));

%*100.	Initialize the Base Data if necessary.;
%if	&LcrBaseDAT.	=	1	%then %do;
	data &outDAT.;
		format	D_TABLE	yymmddD10.;
		D_TABLE	=	&CompDate.;

		format
			D_BGN
			D_END
			yymmddD10.
		;

		set
			&compDAT.(
				rename=(
					D_TABLE	=	_D_TABLE
				)
			)
		;

		D_BGN	=	_D_TABLE;
		D_END	=	"31DEC9999"d;

		drop
			_:
		;
	run;
	%goto	EndOfProc;
%end;

%*200.	We have to sort the data in order to minimize the system RAM usage with respect of the HASH object.;
%*No matter whether the data is sorted, we create a dummy VIEW to pretend that it is sorted.;
%ProcPseudoSort(
	inDAT		=	&baseDAT.
	,ByVar		=
					%do VJi=1 %to &LnByVar.;
						&&LeByVar&VJi..
					%end;
	,procLIB	=	WORK
	,outVIEW	=	_T_View_Dat_Hist_
)

%*300.	Update the history.;
data &outDAT.;
	%*001.	Create table information.;
	retain
		D_TABLE
		D_BGN
		D_END
	%do VJi=1 %to &LnByVar.;
		&&LeByVar&VJi..
	%end;
		&inVAR.
	;
	if	0	then	set &baseDAT.;

	%*002.	parameters.;
	tmpDEND	=	"31DEC9999"d;

	%*100.	Prepare hash object of hashed groups of [byVAR].;
	if	_N_	=	1	then do;
		%*100.	Declare the hash object storing the Group-objects for each [byVAR].;
		%*Each element in the array "hGrpByVar" stores a group of records under the same [byVAR].;
		%* the array is instantiated using the usual "combined" method.;
		dcl	hash	hGrpByVar(hashexp:8, ordered: 'a');
		dcl	hiter	hiGrpByVar('hGrpByVar');
		hGrpByVar.DefineKey(&LvLstQuoteComma.);
		hGrpByVar.DefineData('hByVar', 'hiByVar');
		hGrpByVar.DefineDone();

		%*200.	Declare the hash object storing the records for each [byVAR].;
		%*Its future instances are intended to hold group of byVAR-related data from the input file.;
		%*It is declared, but not yet instantiated.;
		dcl	hash	hByVar();
		dcl	hiter	hiByVar;
	end;

	%*200.	Instantiate the hash objects of each group of [byVAR].;
	%*We only hash one single group at each PDV to prevent the large consumption of RAM.;
	do	until	( last.&&LeByVar&LnByVar.. );
		%*100.	Read each record from base data into the hash.;
		set &baseDAT.;

		%*200.	For each newly encountered byVAR, instantiate its corresponding hash table.;
		%*.FIND() method searches hGrpByVar table using the current ID as a key. If it does not find an hByVar hash object with this key,;
		%* it has not been instantiated yet. Hence, it is now instantiated and stored in hGrpByVar by means of the hGrpByVar.REPLACE();
		%* method. Otherwise, an existing hash instance is copied from hGrpByVar into its 'host variable' hByVar to be reused.;
		if	hGrpByVar.find()	ne	0	then do;
			hByVar	=	_new_	hash(ordered: 'a');
			hiByVar	=	_new_	hiter('hByVar');
			hByVar.DefineKey(&LvLstQuoteComma., 'D_BGN', 'D_END');
			hByVar.DefineData("&inVAR.");
			hByVar.DefineDone();
			hGrpByVar.replace();
		end ;

		%*300.	Store the records into current hByVar instance.;
		%*The values from the record are inserted via hByVar.REPLACE() method into the hash table whose instance hByVar currently holds.;
		hByVar.replace();
	end ;

	%*300.	Update the records in terms of the comparison.;
	%*At EOF, the iterator hiGrpByVar (belonging to hGrpByVar table) is used to loop through the base data one byVAR at a time.;
	%*rcCD: Return Code for Comparison data.;
	%*rcHB: Return Code for the Hash table of each Group in Base data.;
	%*rcGB: Return Code for the Group in Base data.;
	%*rcEX: Return Code for the Execution.;
	do	_n_	=	1	by	1	until	( EOD );
		%*001.	Set the comparison data.;
		set
			&compDAT.(
				rename=(
					D_TABLE	=	_D_TABLE
					&inVAR.	=	_inVAR_4compare
				)
			)
			end=EOD
		;

		%*100.	Comparison and update.;
		%*101.	Find the hash of group to locate which group of byVAR to insert or update.;
		rcGB	=	hGrpByVar.find();

		%*110.	If there is a new byVAR in the comparison data, we add the record into the base data.;
		if	rcGB	ne	0	then do;
			%*100.	Add new hash to store the new Group of records.;
			hByVar	=	_new_	hash(ordered: 'a');
			hiByVar	=	_new_	hiter('hByVar');
			hByVar.DefineKey(&LvLstQuoteComma., 'D_BGN', 'D_END');
			hByVar.DefineData("&inVAR.");
			hByVar.DefineDone();

			%*200.	Refresh the hash of Groups to assure the new group is added.;
			hGrpByVar.replace();

			%*300.	Insert the record to the new Group of byVAR.;
			D_BGN	=	_D_TABLE;
			D_END	=	tmpDEND;
			&inVAR.	=	_inVAR_4compare;
			rcHB	=	hByVar.add();
			%*hByVar.add(&LvLstKeyComma., key: _D_TABLE, key: tmpDEND, data: _inVAR_4compare);

			%*310.	Alert for failure.;
			if	rcHB	NE	0	then do;
				put	"ERROR: [&L_mcrLABEL.]System fails to insert new record!";
				put	"&Lerror.";
				abort abend;
			end;
		end ;
		%*120.	If the byVAR is found existing as a Group in the base data, we handle it in different approaches.;
		else do;
			%*010.	Retrieve the hash in the base data that stores the very earliest record for byVAR.;
			rcHB	=	hiByVar.first();

			%*100.	Loop each record in the Group of byVAR.;
			do	while ( rcHB = 0 );
				%*100.	If the current record has _D_TABLE earlier than D_BGN, we create a new record.;
				if	_D_TABLE	<	D_BGN	then do;
					%*100.	Set the values.;
					%*We retrieve the D_BGN from the original element.;
					D_END	=	D_BGN - 1;
					%*We set D_BGN of the new element by the new data.;
					%*Please assure the sequence of this statement and the above one.;
					D_BGN	=	_D_TABLE;
					&inVAR.	=	_inVAR_4compare;
					rcEX	=	hByVar.add();
					%*rcEX	=	hByVar.add(&LvLstKeyComma., key: _D_TABLE, key: D_BGN - 1, data: _inVAR_4compare);

					%*110.	Alert for failure.;
					if	rcEX	NE	0	then do;
						put	"ERROR: [&L_mcrLABEL.]System fails to insert new record!";
						put	"&Lerror.";
						abort abend;
					end;

					%*900.	Quit current Group as current record has been processed.;
					goto	EndhiByVar;
				end;

				%*200.	If the current record has _D_TABLE later than D_BGN but no later than D_END, we split the record.;
				%*Only when the values are different.;
				%*Original Base:;
				%*[KEY001] + [D_BGN=20120101] + [D_END=20130131] + [value=ABC];
				%*To be updated:;
				%*[KEY001] + [D_TABLE=20130101] + [value=ABD];
				%*Result:;
				%*[KEY001] + [D_BGN=20120101] + [D_END=20121231] + [value=ABC];
				%*[KEY001] + [D_BGN=20130101] + [D_END=20130101] + [value=ABD];
				%*[KEY001] + [D_BGN=20130102] + [D_END=20130131] + [value=ABC];
				%*Theory: each record only contains data for one date, hence we cannot conclude the change in other dates.;
				if	_D_TABLE	<=	D_END	then do;
					%*100.	We only process the record with different value against current element.;
					if	_inVAR_4compare	^=	&inVAR.	then do;
						%*001.	Parameters.;
						tmpDATE	=	D_END;
						tmpRST	=	&inVAR.;
						%*tmpEDC: Temporary End Date of Comparison record.;
						if	tmpDATE	=	tmpDEND	then do;
							tmpEDC	=	tmpDEND;
						end;
						else do;
							tmpEDC	=	_D_TABLE;
						end;

						%*100.	The original element has to be deleted due to the insertion of the new data.;
						%*The .remove() method cannot remove current element as it is locked in the iteration.;
						%*The .replace() method can only update the Data List of the given Key List;
						&inVAR.	=	"";
						rcEX	=	hByVar.replace();

						%*110.	Alert for failure.;
						if	rcEX	NE	0	then do;
							put	"ERROR: [&L_mcrLABEL.]System fails to update the record!";
							put	"&Lerror.";
							abort abend;
						end;

						%*200.	Create a record same as the first result of the sample above.;
						D_END	=	_D_TABLE - 1;
						&inVAR.	=	tmpRST;
						rcEX	=	hByVar.add();

						%*210.	Alert for failure.;
						if	rcEX	NE	0	then do;
							put	"ERROR: [&L_mcrLABEL.]System fails to insert new record!";
							put	"&Lerror.";
							abort abend;
						end;

						%*300.	If the tmpDATE of the original element is not tmpDEND, we create another record.;
						%*This case resembles the 3rd result of the sample above.;
						if	tmpDATE	^=	tmpDEND	then do;
							D_BGN	=	_D_TABLE + 1;
							D_END	=	tmpDATE;
							&inVAR.	=	tmpRST;
							if	D_BGN	<=	D_END	then do;
								rcEX	=	hByVar.add();

								%*200.	Alert for failure.;
								if	rcEX	NE	0	then do;
									put	"ERROR: [&L_mcrLABEL.]System fails to insert new record!";
									put	"&Lerror.";
									abort abend;
								end;
							end;
						end;

						%*NOTE: Above steps could create records resulting D_END < D_BGN, which will be discarded when output.;

						%*300.	Create another record depending on the D_END of the original element.;
						D_BGN	=	_D_TABLE;
						D_END	=	tmpEDC;
						&inVAR.	=	_inVAR_4compare;
						rcEX	=	hByVar.add();

						%*310.	Alert for failure.;
						if	rcEX	NE	0	then do;
							put	"ERROR: [&L_mcrLABEL.]System fails to insert new record!";
							put	"&Lerror.";
							abort abend;
						end;
					%*End of if	_inVAR_4compare	^=	&inVAR.	then do;
					end;

					%*900.	Quit current Group as current record has been processed.;
					goto	EndhiByVar;
				%*End of if	D_TABLE	<=	D_END	then do;
				end;

				%*900.	Retrieve the next element in current Group.;
				rcHB	=	hiByVar.next();
			%*End of do	while ( rcHB = 0 );
			end;

			EndhiByVar:
		%*Else End of if	rcGB	ne	0	then do;
		end;
	%*End of do	_n_	=	1	by	1	until	( EOD );
	end ;

	%*800.	Output the result.;
	%*810.	Locate the first Group.;
	rcGB	=	hiGrpByVar.first();

	%*820.	Loop over the Groups.;
	do	rcGB	=	0	by	0	while ( rcGB = 0 );
		%*100.	Locate the first record in current Group.;
		rcHB	=	hiByVar.first();

		%*200.	Loop over all records in current Group.;
		do	rcHB	=	0	by	0	while ( rcHB = 0 );
			%*100.	Output if current record is valid.;
			if	not	( D_END < D_BGN or missing(&inVAR.) )	then do;
				%*100.	Refresh the table date.;
				D_TABLE	=	&CompDate.;

				%*200.	Output.;
				output;
			end;

			%*900.	Retrieve the next record in current Group.;
			rcHB	=	hiByVar.next();
		end ;

		%*900.	Retrieve the next Group.;
		rcGB	=	hiGrpByVar.next();
	end;

	%*900.	Purge the clogging deadwoods.;
	%*910.	Keep the necessary fields.;
	keep
		D_TABLE
		D_BGN
		D_END
	%do VJi=1 %to &LnByVar.;
		&&LeByVar&VJi..
	%end;
		&inVAR.
	;
run;

%*900.	Purge the memory.;
%*910.	Release PRX utilities.;
%ReleasePRX:

%EndOfProc:
%mend H_DBmin_ChangeInHistory;