%macro DBmin_ChangeInHistory(
	baseDAT		=
	,compDAT	=
	,CompDate	=
	,fPartial	=	0
	,byVAR		=	C_FLD
	,inVAR		=	C_VAL
	,procLIB	=	WORK
	,outDAT		=
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to log all changes of the records in the data,																|
|	| so that all correct snapshot at any certain date spot can be easily extracted.													|
|	|Important: please assure all data for update should be verified before they are applied,											|
|	| otherwise the base data cannot be restored.																						|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|baseDAT	:	The base data to be compared.																						|
|	|compDAT	:	The data which is used to compare with the base data.																|
|	|				 It should only contain the data as of a certain Date instead of a period of dates.									|
|	|CompDate	:	The date on which the comparison is committed.																		|
|	|				 It should be a number instead of a string, such as 19721, or "01Dec2013"d.											|
|	|fPartial	:	The flag for Partial Update, can only be 1 or 0.																	|
|	|byVAR		:	The key by which the comparison is committed, it should be unique in the "&compDAT.".								|
|	|inVAR		:	The field which is to be compared.																					|
|	|				 It should be only one field existing in both data.																	|
|	|procLIB	:	The working folder.																									|
|	|outDAT		:	The update4d result.																								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20140322		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20140323		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Add new module to handle extreme cases, which update the historical data earlier than the first records.					|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20140324		| Version |	3.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Add new module to handle partial update.																					|
|	|      |Partial update only suppress the unaffected records to have their D_END modified automatically,								|
|	|      | while any new records are still inserted.																					|
|	|      |Eg. there are 100 Keys in the Base Data, and yet you only want to update the information for 2 of them.						|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20140412		| Version |	3.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Slightly enhance the program efficiency.																					|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20140413		| Version |	3.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Add validation to inVAR, fix a bug when inVAR has the length of its varname as 32.											|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20140418		| Version |	4.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Should there be any dataset option specified during the macro variable reference, there could be errors						|
|	|      | reported when the marco is called. We eliminate the possibility to happen by validating the DS name.						|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20140420		| Version |	4.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Standardize the program to extract the valid DSN as well as the valid Variable Name.										|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180304		| Version |	4.20		| Updater/Creator |	Lu Robin Bin												|
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
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ErrMcr																															|
|	|	|ValidateDSNasStr																												|
|	|	|ValidateVarNameAsStr																											|
|	|	|genvarlist																														|
|	|	|DropVarIfExists																												|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\FileSystem"																						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|FS_VarExists																													|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*010.	Set parameters.;
%*011.	Identify current processing macro.;
%local
	L_mcrLABEL
	Lohno
;
%let	L_mcrLABEL	=	&sysMacroName.;
%let	Lohno		=	%str(E)RROR: [&L_mcrLABEL.]Process failed due to %str(e)rrors!;

%*012.	Handle the parameter buffer.;
%let	procLIB	=	%unquote(&procLIB.);
%if	%length(%qsysfunc(compress(&baseDAT.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]Base Data is not provided!;
	%put	&Lohno.;
	%ErrMcr
%end;

%if	%length(%qsysfunc(compress(&compDAT.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No update data is provided, the Base Data will have no change.;
	%goto	EndOfProc;
%end;

%if	%length(%qsysfunc(compress(&CompDate.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]No Update date is provided, the last update date will be set as system date.;
	%let	CompDate	=	"&sysdate."d;
%end;

%if	%nrbquote(&fPartial.)	NE	1	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Flag of Partial Update is not set as 1, system will set Full Update as default.;
	%let	fPartial	=	0;
%end;

%if	%length(%qsysfunc(compress(&byVAR.,%str( ))))	=	0	%then	%let	byVAR	=	C_FLD;
%if	%length(%qsysfunc(compress(&inVAR.,%str( ))))	=	0	%then	%let	inVAR	=	C_VAL;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))	=	0	%then	%let	procLIB	=	WORK;

%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Output Data is omitted, hence the Base Data [&baseDAT.] will be overwritten.;
	%let	outDAT	=	&baseDAT.;
%end;

%*013.	Define the local environment.;
%local
	LcrBaseDAT
	VJi
;
%let	LcrBaseDAT	=	0;

%*020.	Further verify the parameters.;
%*021.	Verify the existence of both data.;
%if	%ValidateDSNasStr(inSTR=&baseDAT.,FUZZY=0)	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]System does not accept DS Options or other invalid characters as baseDAT [&baseDAT.]!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%ValidateDSNasStr(inSTR=&compDAT.,FUZZY=0)	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]System does not accept DS Options or other invalid characters as compDAT [&compDAT.]!;
	%put	&Lohno.;
	%ErrMcr
%end;
%if	%sysfunc(exist(&baseDAT.))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Specified file [&baseDAT.] does not exist.;
%end;
%if	%sysfunc(exist(&compDAT.))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]Specified file [&compDAT.] does not exist, the Base Data will have no change.;
	%goto	EndOfProc;
%end;
%if	%sysfunc(exist(&baseDAT.))	=	0	and	%sysfunc(exist(&compDAT.))	=	1	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.][&baseDAT.] will be created on behalf of [&compDAT.].;
	%let	LcrBaseDAT	=	1;
%end;

%*025.	Validate &inVAR..;
%if	%ValidateVarNameAsStr(inSTR=%nrbquote(&inVAR.))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]inVAR [&inVAR.] is not one valid SAS data field!;
	%put	&Lohno.;
	%ErrMcr
%end;
%*Verify its existence in both data.;
%if	&LcrBaseDAT.	=	0	%then %do;
	%if	%FS_VarExists(inDAT=&baseDAT.,inFLD=&inVAR.)	=	0	%then %do;
		%put	%str(E)RROR: [&L_mcrLABEL.]inVAR [&inVAR.] does not exist in baseDAT [&baseDAT.]!;
		%put	&Lohno.;
		%ErrMcr
	%end;
%end;
%if	%FS_VarExists(inDAT=&compDAT.,inFLD=&inVAR.)	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]inVAR [&inVAR.] does not exist in compDAT [&compDAT.]!;
	%put	&Lohno.;
	%ErrMcr
%end;

%*090.	Prepare the "by variable" list.;
%genvarlist(
	nstart		=	1
	,inlst		=	&byVAR.
	,nvarnm		=	LeByVar
	,nvarttl	=	LnByVar
)

%*100.	Initialize the Base Data if necessary.;
%if	&LcrBaseDAT.	=	1	%then %do;
	data %unquote(&outDAT.);
		format	D_TABLE	yymmddD10.;
		D_TABLE	=	%unquote(&CompDate.);

		format
			D_BGN
			D_END
			yymmddD10.
		;

		set
			%unquote(&compDAT.)(
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

%*200.	Prepare the update in terms of the full join of both given data.;
%*VJ - Variables for Join;
proc sql threads;
	create table &procLIB..__ChgInHist_4just as (
		select
			b.*
			%do VJi=1 %to &LnByVar.;
				,c.&&LeByVar&VJi.. as _ByVar&VJi.
			%end;
			,c.D_TABLE as _D_TABLE
			,c.%unquote(&inVAR.) as _inVAR_4compare
			,(1
			%do VJi=1 %to &LnByVar.;
				* missing(b.&&LeByVar&VJi..)
			%end;
			) as _F_MISSING_BAS
			,(1
			%do VJi=1 %to &LnByVar.;
				* missing(c.&&LeByVar&VJi..)
			%end;
			) as _F_MISSING_UPD
		from %unquote(&baseDAT.) as b
		full outer join %unquote(&compDAT.) as c
			on	1
			%do VJi=1 %to &LnByVar.;
				and	b.&&LeByVar&VJi..	=	c.&&LeByVar&VJi..
			%end;
				and	c.D_TABLE	>=	b.D_BGN
				and	c.D_TABLE	<=	b.D_END
	);
quit;

%*300.	Log the change.;
%*Extreme Case 1:;
%* (if the given update data is of some previous date with different values);
%*Original Base:;
%*[KEY001] + [D_BGN=20120101] + [D_END=20130131] + [value=ABC];
%*[KEY001] + [D_BGN=20130201] + [D_END=99991231] + [value=BCD];
%*To be updated::;
%*[KEY001] + [D_TABLE=20130101] + [value=ABD];
%*Result:;
%*[KEY001] + [D_BGN=20120101] + [D_END=20121231] + [value=ABC];
%*[KEY001] + [D_BGN=20130101] + [D_END=99991231] + [value=ABD];
%*[KEY001] + [D_BGN=20130201] + [D_END=99991231] + [value=BCD];
%*Hence this will be fixed if there is a temporary field containing [D_END=20130131] for the original base.;
data &procLIB..__ChgInHist_4fix;
	%*002.	Set the data.;
	set &procLIB..__ChgInHist_4just;

	%*003.	Ensure all Key variables have correct values.;
	if	_F_MISSING_BAS	=	1	then do;
	%do VJi=1 %to &LnByVar.;
		&&LeByVar&VJi..	=	_ByVar&VJi.;
	%end;
		D_END	=	"31DEC9999"d;
	end;

	%*010.	Create temporary field to store the original value of D_END;
	_D_END	=	D_END;

	%*100.	We omit the justification of all the records which match in both data.;

	%*200.	Records that have different [&inVAR.] in both data.;
	if	%unquote(&inVAR.)	^=	_inVAR_4compare	then do;
		D_END	=	_D_TABLE - 1;
	end;

	%*250.	Handle partial update.;
	if	_F_MISSING_UPD	=	1	then do;
		%if	&fPartial.	=	1	%then %do;
			D_END	=	_D_END;
		%end;
		%else %do;
			D_END	=	min(_D_END,%unquote(&CompDate.) - 1);
		%end;
	end;

	%*300.	Output the original base.;
	%*Please note that this output includes the records with all above conitions.;
	if	_F_MISSING_BAS	=	0	then do;
		%*Extreme Case 2, if we find there is some erroneously updated data and we have done the reversal,;
		%* there could exist below records:;
		%*[KEY001] + [D_BGN=20120101] + [D_END=20121231] + [value=ABC];
		%*[KEY001] + [D_BGN=20130101] + [D_END=20121231] + [value=ABD];
		%*[KEY001] + [D_BGN=20130101] + [D_END=20130131] + [value=ABC];
		%*[KEY001] + [D_BGN=20130201] + [D_END=99991231] + [value=BCD];
		%*Hence the sencond record should not be exported to the base data.;
		%*Please also note that if the extreme case happens, the 1st and the 3rd records may seem tedious,;
		%* albeit they will not affect any data extraction from the base data.;
		if	D_BGN	<=	D_END	then do;
			output;
		end;
	end;

	%*400.	Generate new records containing the changed value.;
	%*This creates an extra record against the above output, should there be any change in value.;
	%*This step eliminates the possibility to restore the base data if wrong data is updated.;
	if	%unquote(&inVAR.)	^=	_inVAR_4compare	then do;
		%*If the records do not exist in the update data, they should not be output.;
		if	_F_MISSING_UPD	=	0	then do;
			D_BGN	=	_D_TABLE;
			D_END	=	_D_END;
			%unquote(&inVAR.)	=	_inVAR_4compare;
			%*There is no necessity to compare D_BGN and D_END as what we have done above,;
			%* for _D_END (=original D_END) is Greater Than Or Equal To _D_TABLE (=D_BGN).;
			%*Please find the join condition in section 200 for their relationship.;
			output;
		end;
	end;

	%*900.	Purge the clogging deadwoods.;
	%DropVarIfExists(
		inDAT		=	&procLIB..__ChgInHist_4just
		,inFLDlst	=	D_TABLE
	)
	drop
		_:
	;
run;

%*400.	Fix the data resulting from below extreme case.;
%*Extreme Case 3:;
%*Original Base:;
%*[KEY001] + [D_BGN=20130201] + [D_END=99991231] + [value=BCD];
%*To be updated::;
%*[KEY001] + [D_TABLE=20120101] + [value=ABC];
%*Result:;
%*[KEY001] + [D_BGN=20120101] + [D_END=99991231] + [value=ABC];
%*[KEY001] + [D_BGN=20130201] + [D_END=99991231] + [value=BCD];
%*We have to fix the D_END for the first record by another step,;
%* for its value should be retrieved from D_BGN in the second record.;
%*410.	Sort the data by D_BGN in a descending pattern.;
proc sort
	data=&procLIB..__ChgInHist_4fix
;
	by
	%do VJi=1 %to &LnByVar.;
		&&LeByVar&VJi..
	%end;
		descending D_BGN
	;
run;

%*420.	Make use of the function of "LAG<n>";
data %unquote(&outDAT.);
	%*001.	Create table update date.;
	format	D_TABLE	yymmddD10.;
	D_TABLE	=	%unquote(&CompDate.);

	%*002.	Set the data.;
	set &procLIB..__ChgInHist_4fix;
	by
	%do VJi=1 %to &LnByVar.;
		&&LeByVar&VJi..
	%end;
		descending D_BGN
	;

	%*010.	Create temporary field to store the lagged value of the prior records.;
	format	_D_BGN_LAG	yymmddD10.;
	_D_BGN_LAG	=	lag1(D_BGN);

	%*100.	Fix D_END by the lagged value of the records in later dates.;
	if	first.&&LeByVar&LnByVar..	=	0	then do;
		%*Extreme Case 4:;
		%*If some key lacks of record in a certain period of date.;
		%*[KEY001] + [D_BGN=20120101] + [D_END=20121231] + [value=ABC];
		%*[KEY001] + [D_BGN=20130201] + [D_END=99991231] + [value=BCD];
		%*We should not change [D_END=20121231] by compromising to the facts.;
		if	D_END	=	"31DEC9999"d	then do;
			D_END	=	_D_BGN_LAG - 1;
		end;
	end;

	%*900.	Purge the clogging deadwoods.;
	drop
		_:
	;
run;

%*900.	Purge the memory.;
%*910.	Release PRX utilities.;
%ReleasePRX:

%EndOfProc:
%mend DBmin_ChangeInHistory;