%macro list_sasautos(
	InclWORK	=	Y
	,outDAT		=	WORK._list_sasautosfull
	,procLIB	=	WORK
	,fDebug		=	0
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to load the available pre-defined macros in current session from below sources in order:					|
|	|[1] Macros that are actively compiled in the catalog: [WORK.SASMACR.SAS7BCAT]														|
|	|[2] Macros that are externally compiled in the catalog: [SASMACR.SAS7BCAT] as indicated by the system option: [SASMSTORE=]			|
|	|    [A] If [SASMSTORE=] option points to a [Concatenated Catalog], the physical file [SASMACR.SAS7BCAT] does not exist as it is	|
|	|         just a Logical Concatenation. Hence we need to find all physical files it concatenates with the user defined function:	|
|	|         [getAllCatNames]																											|
|	|    [B] Otherwise, [SASMSTORE=] option points to a [Physical Catalog], and we can extract the stored macros from it using the		|
|	|         [CATALOG Procedure]																										|
|	|    [C] The [TYPE] of macros stored in it MUST be [MACRO]																			|
|	|[3] Macro source codes that are not yet compiled in the session but stored in the physical paths as indicated by the system		|
|	|     option: [SASAUTOS=]																											|
|	|    [A] If [SASAUTOS=] option points to a [FileRef], we have to search inside all paths it links for available macro files			|
|	|        [a] If it links to a physical or concatenated [CATALOG], the [TYPE] of macros stored in it MUST be [SOURCE]				|
|	|        [b] If it links to a list of directories, we have to go through each one of them											|
|	|    [B] If [SASAUTOS=] option points to a [Physical Directory] on the harddisk, we have to search inside it for available macros	|
|	|         while leave all its sub-directories away.																					|
|	|[4] Macros that are initially compiled in the catalog: [SASHELP.SASMACR.SAS7BCAT], for the system will find the dedicated macro	|
|	|     within this one if it cannot be located via any of above approaches															|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|InclWORK	:	Whether the search includes the catalog [WORK.SASMACR.SAS7BCAT]														|
|	|				Default : [Y]																										|
|	|outDAT		:	The output dataset that stores the search result.																	|
|	|				IMPORTANT: The source code names that come from [SASAUTOS=] does not necessarily represent the available macros,	|
|	|				            for this program does not verify whether there is the macro definition program within the source code.	|
|	|				Default : [WORK._list_sasautosfull]																					|
|	|procLIB	:	The working library.																								|
|	|				Default : [WORK]																									|
|	|fDebug		:	The switch of Debug Mode. Valid values are [0] or [1].																|
|	|				Default: [0]																										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20181117		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20181124		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |[1] Add compatibility to [Concatenated Catalog] for the system options [SASMSTORE=] and [SASAUTOS=]							|
|	|      |[2] Re-write the logic to determine the search priority correctly															|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Please find the attachments for examples.																							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ErrMcr																															|
|	|	|getOBS4DATA																													|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\FileSystem"																						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|OSDirDlm																														|
|	|	|isDir																															|
|	|	|FS_getPathList4Lib																												|
|	|	|getMemberByStrPattern																											|
|	|	|getAllCatNames																													|
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
%if	%length(%qsysfunc(compress(&InclWORK.,%str( ))))	=	0	%then	%let	InclWORK	=	Y;
%let	InclWORK	=	%qupcase(%qsubstr( &InclWORK. , 1 , 1 ));
%if	&InclWORK.	^=	N	%then	%let	InclWORK	=	Y;

%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))	=	0	%then	%let	outDAT	=	WORK._list_sasautosfull;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))	=	0	%then	%let	procLIB	=	WORK;
%if	%length(%qsysfunc(compress(&fDebug.,%str( ))))	=	0	%then	%let	fDebug	=	0;
%if	&fDebug.^=	0	%then	%let	fDebug		=	1;

%*013.	Define the global environment.;

%*014.	Define the local environment.;
%local
	OptNotes	OptSource	OptSource2	OptMLogic	OptSymGen	OptMPrint	OptInOper
	Lib_mstore	Opt_autos	nLoc_autos	nSequence	nCatalog	nCataFil	nAutoDir	nAutoFil
	Mi			Mj			Ai			Si			Ci
;
%let	Lib_mstore	=;
%let	Opt_autos	=;
%let	nLoc_autos	=	0;
%let	nSequence	=	0;
%let	nCatalog	=	0;
%let	nCataFil	=	0;
%let	nAutoDir	=	0;
%let	nAutoFil	=	0;

%*016.	Switch off the system options to reduce the LOG size.;
%if %sysfunc(getoption( notes ))		=	NOTES		%then	%let	OptNotes	=	1;	%else	%let	OptNotes	=	0;
%if %sysfunc(getoption( source ))		=	SOURCE		%then	%let	OptSource	=	1;	%else	%let	OptSource	=	0;
%if %sysfunc(getoption( source2 ))		=	SOURCE2		%then	%let	OptSource2	=	1;	%else	%let	OptSource2	=	0;
%if %sysfunc(getoption( mlogic ))		=	MLOGIC		%then	%let	OptMLogic	=	1;	%else	%let	OptMLogic	=	0;
%if %sysfunc(getoption( symbolgen ))	=	SYMBOLGEN	%then	%let	OptSymGen	=	1;	%else	%let	OptSymGen	=	0;
%if %sysfunc(getoption( mprint ))		=	MPRINT		%then	%let	OptMPrint	=	1;	%else	%let	OptMPrint	=	0;
%if %sysfunc(getoption( minoperator ))	=	MINOPERATOR	%then	%let	OptInOper	=	1;	%else	%let	OptInOper	=	0;
%*The default value of the system option [MINDELIMITER] is WHITE SPACE, given the option [MINOPERATOR] is on.;
%if	&fDebug.	=	0	%then %do;
options nonotes nosource nosource2 nomlogic nosymbolgen nomprint minoperator;
%end;

%*019.	Trick the SAS Base Enhanced Editor into thinking the macro has ended.;
%*This action allows the readers to see the rest of the codes in traditional SAS syntax colors.;
%macro dummy; %mend dummy;

%*049.	Debugger.;
%if	&fDebug.	=	1	%then %do;
	%*All input values.;
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [InclWORK=&InclWORK.];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [outDAT=%qsysfunc(strip(&outDAT.))];
	%put	%str(I)NFO: [&L_mcrLABEL.]Input Values: [procLIB=&procLIB.];
%end;

%*100.	Search for the existance of [WORK.SASMACR.SAS7BCAT].;
%*101.	Skip this step if it is indicated NOT to search within this catalog.;
%if	&InclWORK.	=	N	%then %do;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Skip the search into the actively compiled macros in [WORK.SASMACR];
	%end;
	%goto	EndOfWork;
%end;

%*130.	Determine whether the catalog exists.;
%if	%sysfunc(cexist( WORK.SASMACR ))	=	0	%then %do;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Catalog [WORK.SASMACR] does not exist.;
	%end;
	%goto	EndOfWork;
%end;

%*150.	Store necessary information for the catalog.;
%let	nSequence	=	%eval( &nSequence. + 1 );
%let	nCatalog	=	%eval( &nCatalog. + 1 );
%local
	L_cat&nCatalog.
	N_cat&nCatalog.
	S_cat&nCatalog.
	T_cat&nCatalog.
;
%let	L_cat&nCatalog.	=	WORK;
%let	N_cat&nCatalog.	=	SASMACR;
%let	S_cat&nCatalog.	=	&nSequence.;
%let	T_cat&nCatalog.	=	MACRO;

%*199..	Mark the end of the search for the catalog: [WORK.SASMACR];
%EndOfWork:

%*200.	Search for the catalog as linked by the system option [SASMSTORE=].;
%*202.	Skip this step if it is indicated that current session does not require the stored macros.;
%if	%sysfunc(getoption(MSTORED))	=	NOMSTORED	%then %do;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Current system option [%sysfunc(getoption(MSTORED))] does not require stored macros.;
	%end;
	%goto	EndOfStore;
%end;

%*210.	Identify the library for stored macros.;
%let	Lib_mstore	=	%sysfunc(getoption(SASMSTORE));

%*219.	Debugger.;
%if	%length(%qsysfunc(compress(&Lib_mstore.,%str( ))))	=	0	%then %do;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Current system option [SASMSTORE=&Lib_mstore.] is not active.;
	%end;
	%goto	EndOfStore;
%end;

%*220.	Determine whether the libref, which contains the catalog, is assigned.;
%if	%sysfunc(libref( &Lib_mstore. ))	^=	0	%then %do;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Current library [&Lib_mstore.] linked to system option [SASMSTORE=] is not assigned.;
	%end;
	%goto	EndOfStore;
%end;

%*230.	Determine whether the catalog exists.;
%if	%sysfunc(cexist( &Lib_mstore..SASMACR ))	=	0	%then %do;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Current library [&Lib_mstore.] linked to system option [SASMSTORE=] does not contain available catalog for stored macros.;
	%end;
	%goto	EndOfStore;
%end;

%*250.	Store necessary information for the catalog.;
%let	nSequence	=	%eval( &nSequence. + 1 );
%let	nCatalog	=	%eval( &nCatalog. + 1 );
%local
	L_cat&nCatalog.
	N_cat&nCatalog.
	S_cat&nCatalog.
	T_cat&nCatalog.
;
%let	L_cat&nCatalog.	=	&Lib_mstore.;
%let	N_cat&nCatalog.	=	SASMACR;
%let	S_cat&nCatalog.	=	&nSequence.;
%let	T_cat&nCatalog.	=	MACRO;

%*299..	Mark the end of the search for the catalog: [&Lib_mstore..SASMACR];
%EndOfStore:

%*300.	Locate all available locations as indicated by the system option: [SASAUTOS=].;
%*302.	Skip this step if it is indicated that current session does not require the autocall macros.;
%if	%sysfunc(getoption(MAUTOSOURCE))	=	NOMAUTOSOURCE	%then %do;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Current system option [%sysfunc(getoption(MAUTOSOURCE))] does not require autocall macros.;
	%end;
	%goto	EndOfAuto;
%end;

%*310.	Identify the system option for autocall macros.;
%let	Opt_autos	=	%sysfunc(getoption(SASAUTOS));

%*319.	Debugger.;
%if	%length(%qsysfunc(compress(&Opt_autos.,%str( ))))	=	0	%then %do;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Current system option [SASAUTOS=&Opt_autos.] is not active.;
	%end;
	%goto	EndOfAuto;
%end;

%*330.	Identify the catalogs or directories that are linked to the system option.;
%*331.	Identify the members associated with the system option.;
%if	%index(&Opt_autos.,%str(%())	=	1	and	%index(&Opt_autos.,%str(%)))	=	%length(&Opt_autos.)	%then %do;
	%*100.	Remove the surrounding parentheses;
	%let	Opt_autos	=	%qsubstr( &Opt_autos. , 2 , %eval( %length(&Opt_autos.) - 2 ) );

	%*200.	Count the members that linked to this system option.;
	%let	nLoc_autos	=	%sysfunc(countw( &Opt_autos. , %str(, ) , qs ));

	%*300.	Extract each member.;
	%do Mi = 1 %to &nLoc_autos.;
		%local	Autos&Mi.;
		%let	Autos&Mi.	=	%qsysfunc(dequote( %qscan( &Opt_autos. , &Mi. , %str(, ) , qs ) ));
	%end;
%end;
%else %do;
	%let	nDir_autos	=	1;
	%local	Autos&nLoc_autos.;
	%let	Autos&nLoc_autos.	=	%qsysfunc(strip( %qsysfunc(dequote( &Opt_autos. )) ));
%end;

%*335.	Extend the lists of catalogs and directories respectively.;
%do Mi = 1 %to &nLoc_autos.;
	%*100.	Extend the list directly if it is a Directory.;
	%if	%isDir( &&Autos&Mi.. )	=	1	%then %do;
		%*100.	Increment the overall Sequence Number for macro name searching.;
		%let	nSequence	=	%eval( &nSequence. + 1 );

		%*300.	Add to the list of directories for macro name searching.;
		%let	nAutoDir	=	%eval( &nAutoDir. + 1 );
		%local
			P_dir&nAutoDir.
			S_dir&nAutoDir.
		;
		%let	P_dir&nAutoDir.	=	&&Autos&Mi..;
		%let	S_dir&nAutoDir.	=	&nSequence.;
	%end;

	%*500.	handle the members if it is a [FILENAME].;
	%else %if	%sysfunc(fileref( &&Autos&Mi.. ))	=	0	%then %do;
		%*010.	Retrieve the path name of the FileRef.;
		%FS_getPathList4Lib(
			inDSN		=	&&Autos&Mi..
			,outCNT		=	GnAUTOS
			,outELpfx	=	GeAUTOS
			,fDequote	=	1
		)

		%*100.	Add to the list of catalogs for macro name searching if the name is in the form of [..LibRef.Catalog].;
		%if	&GnAUTOS.	=	1	and	%index( &&GeAUTOS&GnAUTOS.. , %str(..) )	=	1	%then %do;
			%*100.	Determine whether the libref, which contains the catalog, is assigned.;
			%if	%sysfunc(libref( %scan( &&GeAUTOS&GnAUTOS.. , -2 , %str(.) ) ))	^=	0	%then %do;
				%if	&fDebug.	=	1	%then %do;
					%put	%str(I)NFO: [&L_mcrLABEL.]Library [%scan( &&GeAUTOS&GnAUTOS.. , -2 , %str(.) )] of FileRef [&&Autos&Mi..] for system option [SASAUTOS=] is not assigned.;
				%end;
				%goto	EndOfCIter;
			%end;

			%*200.	Determine whether the catalog exists.;
			%if	%sysfunc(cexist( %substr( &&GeAUTOS&GnAUTOS.. , 3 ) ))	=	0	%then %do;
				%if	&fDebug.	=	1	%then %do;
					%put	%str(I)NFO: [&L_mcrLABEL.]Catalog [GeAUTOS&GnAUTOS.=&&GeAUTOS&GnAUTOS..] of FileRef [&&Autos&Mi..] for system option [SASAUTOS=] does not exist.;
				%end;
				%goto	EndOfCIter;
			%end;

			%*500.	Store necessary information for the catalog.;
			%let	nSequence	=	%eval( &nSequence. + 1 );
			%let	nCatalog	=	%eval( &nCatalog. + 1 );
			%local
				L_cat&nCatalog.
				N_cat&nCatalog.
				S_cat&nCatalog.
				T_cat&nCatalog.
			;
			%let	L_cat&nCatalog.	=	%scan( &&GeAUTOS&GnAUTOS.. , -2 , %str(.) );
			%let	N_cat&nCatalog.	=	%scan( &&GeAUTOS&GnAUTOS.. , -1 , %str(.) );
			%let	S_cat&nCatalog.	=	&nSequence.;
			%let	T_cat&nCatalog.	=	SOURCE;

			%*990.	Mark the end of current member.;
			%EndOfCIter:
		%end;

		%*500.	Add to the list of directories for macro name searching.;
		%else %do;
			%do Mj = 1 %to &GnAUTOS.;
				%*010.	Skip if current member is not a directory.;
				%if	%isDir( &&GeAUTOS&Mj.. )	=	0	%then %do;
					%if	&fDebug.	=	1	%then %do;
						%put	%str(W)ARNING: [&L_mcrLABEL.]Member name [GeAUTOS&Mj.=&&GeAUTOS&Mj..] of FileRef [&&Autos&Mi..] is not recognized for system option [SASAUTOS=]!;
					%end;
					%goto	EndOfDIter;
				%end;

				%*100.	Increment the overall Sequence Number for macro name searching.;
				%let	nSequence	=	%eval( &nSequence. + 1 );

				%*300.	Add to the list of directories for macro name searching.;
				%let	nAutoDir	=	%eval( &nAutoDir. + 1 );
				%local
					P_dir&nAutoDir.
					S_dir&nAutoDir.
				;
				%let	P_dir&nAutoDir.	=	&&GeAUTOS&Mj..;
				%let	S_dir&nAutoDir.	=	&nSequence.;

				%*990.	Mark the end of current member.;
				%EndOfDIter:
			%end;
		%end;
	%end;

	%*800.	If it is provided as a LIBRARY, it cannot be recognized for autocall.;
	%else %if	%sysfunc(libref( &&Autos&Mi.. ))	=	0	%then %do;
		%if	&fDebug.	=	1	%then %do;
			%put	%str(I)NFO: [&L_mcrLABEL.]The LIBNAME [&&Autos&Mi..] does not have effect for system option [SASAUTOS=];
		%end;
	%end;

	%*900.	Abort the session if the member type is not recognized.;
	%else %do;
		%put	%str(W)ARNING: [&L_mcrLABEL.]Member name [&&Autos&Mi..] is not recognized for system option [SASAUTOS=]!;
		%put	&Lohno.;
		%ErrMcr
	%end;
%end;

%*399..	Mark the end of the search.;
%EndOfAuto:

%*400.	Search for the existance of [SASHELP.SASMACR.SAS7BCAT] as it is the last location for SAS to search when a macro cannot be located at above steps.;
%*420.	Determine whether the catalog exists.;
%if	%sysfunc(cexist( SASHELP.SASMACR ))	=	0	%then %do;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]Catalog [SASHELP.SASMACR] does not exist.;
	%end;
	%goto	EndOfSashelp;
%end;

%*450.	Store necessary information for the catalog.;
%let	nSequence	=	%eval( &nSequence. + 1 );
%let	nCatalog	=	%eval( &nCatalog. + 1 );
%local
	L_cat&nCatalog.
	N_cat&nCatalog.
	S_cat&nCatalog.
	T_cat&nCatalog.
;
%let	L_cat&nCatalog.	=	SASHELP;
%let	N_cat&nCatalog.	=	SASMACR;
%let	S_cat&nCatalog.	=	&nSequence.;
%let	T_cat&nCatalog.	=	MACRO;

%*499..	Mark the end of the search for the catalog: [SASHELP.SASMACR];
%EndOfSashelp:

%*600.	Retrieve all [.SAS] files from the identified directories.;
%*601.	Skip if there is no directory to search the available [.SAS] files.;
%if	&nAutoDir.	=	0	%then %do;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]There is no directory within which to locate the [.SAS] files.;
	%end;
	%goto	EndOfDir;
%end;

%*605.	Announcement.;
%if	&fDebug.	=	1	%then %do;
	%put	%str(I)NFO: [&L_mcrLABEL.]Searching for [.SAS] files within below locations in order:;
	%do Mi = 1 %to &nAutoDir.;
		%put	%str(I)NFO: [&L_mcrLABEL.][Search Order=&&S_dir&Mi..][P_dir&Mi.]=[&&P_dir&Mi..];
	%end;
%end;

%*620.	Extend the list of [.SAS] files.;
%*Till SAS V9.4, the valid name of a macro should be preceded by an alphabet or underscore, and should have an alpha-numeric length of no longer than 32.;
%do Mi = 1 %to &nAutoDir.;
	%getMemberByStrPattern(
		inDIR		=	&&P_dir&Mi..
		,inRegExp	=	%nrstr(^[[:alpha:]_]\w{0,31}\.sas$)
		,exclRegExp	=
		,chkType	=	1
		,FSubDir	=	0
		,mNest		=	0
		,outCNT		=	GnFil
		,outELpfx	=	GeFil
		,outElTpPfx	=	GtFil
		,outElPPfx	=	GpFil
		,outElNmPfx	=	GmFil
	)
	%do Mj = 1 %to &GnFil.;
		%let	nAutoFil	=	%eval( &nAutoFil. + 1 );
		%local
			P_fil&nAutoFil.
			N_fil&nAutoFil.
			M_fil&nAutoFil.
			S_fil&nAutoFil.
		;
		%let	M_fil&nAutoFil.	=	&&GeFil&Mj..;
		%let	N_fil&nAutoFil.	=	&&GmFil&Mj..;
		%let	P_fil&nAutoFil.	=	&&GpFil&Mj..;
		%let	S_fil&nAutoFil.	=	&&S_dir&Mi..;
	%end;
%end;

%*629.	Skip the step if no file is found.;
%if	&nAutoFil.	=	0	%then %do;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]There is no [.SAS] file found for any directory linked to the system option [SASAUTOS=].;
	%end;
	%goto	EndOfDir;
%end;

%*650.	Create a temporary dataset to resemble the one created from the CATALOG Procedure.;
data &procLIB..__lsa_Autos_;
	length
		ORDER	8
		LEVEL	8
		MEMNAME	$32
		PATH	$1024
		NAME	$32
		TYPE	$8
		PATHFUL	$1024
	;
	%do Mi = 1 %to &nAutoFil.;
		ORDER	=	&&S_fil&Mi..;
		LEVEL	=	1;
		MEMNAME	=	"AUTOCALL";
		PATH	=	strip( %sysfunc(quote( &&P_fil&Mi.. , %str(%') )) );
		NAME	=	scan( %sysfunc(quote( &&N_fil&Mi.. , %str(%') )) , 1 , '.' );
		TYPE	=	".sas";
		PATHFUL	=	strip( %sysfunc(quote( &&M_fil&Mi.. , %str(%') )) );
		output;
	%end;
run;

%*699..	Mark the end of the search within the directories.;
%EndOfDir:

%*700.	Identify all physical catalog files.;
%*701.	Skip if there is no catalog to search the available macros.;
%if	&nCatalog.	=	0	%then %do;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]There is no CATALOG within which to locate the pre-defined macros.;
	%end;
	%goto	EndOfCat;
%end;

%*705.	Announcement.;
%if	&fDebug.	=	1	%then %do;
	%put	%str(I)NFO: [&L_mcrLABEL.]Searching for physical catalog files within below catalogs in order:;
	%do Ci = 1 %to &nCatalog.;
		%put	%str(I)NFO: [&L_mcrLABEL.][Search Order=&&S_cat&Ci..][Name=&&L_cat&Ci...&&N_cat&Ci..][Search Type=&&T_cat&Ci..];
	%end;
%end;

%*710.	List all Concatenated Catalogs for current session.;
%getAllCatNames(
	outDAT		=	&procLIB..__lsa_CatNames__
	,procLIB	=	&procLIB.
	,fDebug		=	&fDebug.
)

%*750.	Extend the list of catalog files.;
%do Ci = 1 %to &nCatalog.;
	%*100.	Locate the catalog name inside the full base of Concatenated Catalogs.;
	proc sort
		data=&procLIB..__lsa_CatNames__(
			where=(
				upcase( catx( '.' , CATLIB , CATNAME ) )	=	upcase(strip( %sysfunc(quote( &&L_cat&Ci...&&N_cat&Ci.. , %str(%') )) ))
			)
		)
		out=&procLIB..__lsa_temp__
	;
		by	CATLIB	CATNAME	LEVEL;
	run;

	%*300.	Append the physical members to the file list if current catalog is a concatenated one.;
	%if	%getOBS4DATA( inDAT = &procLIB..__lsa_temp__ , gMode = F )	^=	0	%then %do;
		%*001.	Announcement.;
		%if	&fDebug.	=	1	%then %do;
			%put	%str(I)NFO: [&L_mcrLABEL.]Catalog [&&L_cat&Ci...&&N_cat&Ci..] is a Concatenated Catalog.;
		%end;

		%*100.	Retrieve the items to be appended.;
		data _NULL_;
			set &procLIB..__lsa_temp__ end=EOF;
			by	CATLIB	CATNAME	LEVEL;
			call symput( cats( 'P_app' , _N_ ) , substr( PATH , 1 , PATHLEN ) );	%*We cannot use [CALL SYMPUTX] routine here.;
			call symputx( cats( 'L_app' , _N_ ) , LIBNAME , 'L' );
			call symputx( cats( 'N_app' , _N_ ) , MEMNAME , 'L' );
			call symputx( cats( 'U_app' , _N_ ) , LEVEL , 'L' );
			if	EOF	then	call symputx( 'K_app' , _N_ , 'L' );
		run;

		%*500.	Append to the list.;
		%do Ai=1 %to &K_app.;
			%*100.	Determine whether the libref, which contains the catalog, is assigned.;
			%if	%sysfunc(libref( %superq(L_app&Ai.) ))	^=	0	%then %do;
				%if	&fDebug.	=	1	%then %do;
					%put	%str(I)NFO: [&L_mcrLABEL.]Library of the catalog [%superq(L_app&Ai.).%superq(N_app&Ai.)] associated to the concatenated one [&&L_cat&Ci...&&N_cat&Ci..] is not assigned.;
				%end;
				%goto	EndOfAIter;
			%end;

			%*200.	Skip if the physical catalog does not exist.;
			%if	%sysfunc(cexist( %superq(L_app&Ai.).%superq(N_app&Ai.) ))	=	0	%then %do;
				%if	&fDebug.	=	1	%then %do;
					%put	%str(I)NFO: [&L_mcrLABEL.]Physical catalog [%superq(L_app&Ai.).%superq(N_app&Ai.)] associated to the concatenated one [&&L_cat&Ci...&&N_cat&Ci..] does not exist.;
				%end;
				%goto	EndOfAIter;
			%end;

			%*500.	Append.;
			%let	nCataFil	=	%eval( &nCataFil. + 1 );
			%local
				Ppcat&nCataFil.
				Lpcat&nCataFil.
				Npcat&nCataFil.
				Spcat&nCataFil.
				Upcat&nCataFil.
				Tpcat&nCataFil.
			;
			%let	Ppcat&nCataFil.	=	%superq(P_app&Ai.);	%*Reserve the trailing blanks if any;
			%let	Lpcat&nCataFil.	=	%superq(L_app&Ai.);
			%let	Npcat&nCataFil.	=	%superq(N_app&Ai.);
			%let	Spcat&nCataFil.	=	&&S_cat&Ci..;
			%let	Upcat&nCataFil.	=	&&U_app&Ai..;
			%let	Tpcat&nCataFil.	=	&&T_cat&Ci..;

			%*900.	Mark the end of the iteration of the appendix.;
			%EndOfAIter:
		%end;
	%*End Of [Concatenated Catalog];
	%end;

	%*400.	Directly add to the file list if current catalog is not a concatenated one.;
	%else %do;
		%*001.	Announcement.;
		%if	&fDebug.	=	1	%then %do;
			%put	%str(I)NFO: [&L_mcrLABEL.]Catalog [&&L_cat&Ci...&&N_cat&Ci..] is not a Concatenated Catalog.;
		%end;

		%*100.	Retrieve the paths that are associated to the library of current catalog.;
		%FS_getPathList4Lib(
			inDSN		=	&&L_cat&Ci..
			,outCNT		=	GnMSTORE
			,outELpfx	=	GeMSTORE
			,fDequote	=	1
		)

		%*500.	Search for the first directory that contains the catalog file.;
		%do Si=1 %to &GnMSTORE.;
			%if	%sysfunc(fileexist( &&GeMSTORE&Si..%OSDirDlm%nrbquote(&&N_cat&Ci..)%str(.SAS7BCAT) ))	=	1	%then %do;
				%let	nCataFil	=	%eval( &nCataFil. + 1 );
				%local
					Ppcat&nCataFil.
					Lpcat&nCataFil.
					Npcat&nCataFil.
					Spcat&nCataFil.
					Upcat&nCataFil.
					Tpcat&nCataFil.
				;
				%let	Ppcat&nCataFil.	=	&&GeMSTORE&Si..;
				%let	Lpcat&nCataFil.	=	&&L_cat&Ci..;
				%let	Npcat&nCataFil.	=	&&N_cat&Ci..;
				%let	Spcat&nCataFil.	=	&&S_cat&Ci..;
				%let	Upcat&nCataFil.	=	1;
				%let	Tpcat&nCataFil.	=	&&T_cat&Ci..;
				%goto	EndOfStoreIter;
			%end;
		%end;
		%EndOfStoreIter:
	%*End Of [Not a Concatenated Catalog];
	%end;
%*End of loop over [nCatalog];
%end;

%*799..	Mark the end of the search for catalog files.;
%EndOfCat:

%*800.	Retrieve the available macros from all catalog files found at above steps.;
%*801.	Skip the step if no catalog file is found.;
%if	&nCataFil.	=	0	%then %do;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(N)OTE: [&L_mcrLABEL.]There is no [.SAS7BCAT] file found.;
	%end;
	%goto	EndOfCatFiles;
%end;

%*809.	Announcement.;
%if	&fDebug.	=	1	%then %do;
	%put	%str(I)NFO: [&L_mcrLABEL.]All physical [.SAS7BCAT] files are listed as below:;
	%do Ci=1 %to &nCataFil.;
		%put	%str(I)NFO: [&L_mcrLABEL.][Search Order=&&Spcat&Ci..][Sub Order=&&Upcat&Ci..][Search Type=&&Tpcat&Ci..][&&Lpcat&Ci...&&Npcat&Ci..][&&Ppcat&Ci..%OSDirDlm%nrbquote(&&Npcat&Ci..)%str(.SAS7BCAT)];
	%end;
%end;

%*850.	Run CATALOG Procedure for each catalog.;
%do Ci=1 %to &nCataFil.;
	proc catalog c=&&Lpcat&Ci...&&Npcat&Ci..;
		contents
			out=&procLIB..__lsa_Cats&Ci._(
				keep= memname name type
				where=( type = %sysfunc(quote( &&Tpcat&Ci.. , %str(%') )) )
			)
		;
	quit;
%end;

%*899..	Mark the end of the search.;
%EndOfCatFiles:

%*900.	Set all results together.;
%*901.	Quit if nothing is found.;
%if	&nAutoFil.	=	0	and	&nCataFil.	=	0	%then %do;
	%if	&fDebug.	=	1	%then %do;
		%put	%str(I)NFO: [&L_mcrLABEL.]No available macro is found.;
	%end;
	%goto	EndOfProc;
%end;

%*910.	Set and rename.;
data &procLIB..__lsa_concat_;
	%*100.	Create the table structure.;
	length
		ORDER	8
		LEVEL	8
		MEMNAME	$32
		PATH	$1024
		NAME	$32
		TYPE	$8
		PATHFUL	$1024
		namelow	$32
	;
	label
		ORDER	=	"SEARCH ORDER OF THE SAME NAME WHEN BEING CALLED"
		LEVEL	=	"SEARCH SUB-ORDER OF THE SAME NAME WHEN BEING CALLED"
		MEMNAME	=	"SAS DATASET MEMBER (CATALOG) NAME"
		PATH	=	"PHYSICAL LOCATION OF THE SOURCE FILE"
		NAME	=	"CATALOG ENTRY NAME"
		TYPE	=	"CATALOG ENTRY TYPE"
		PATHFUL	=	"FULL PATH OF THE SOURCE FILE"
	;

	%*200.	Set the search results.;
	set
	%if	&nAutoFil.	^=	0	%then %do;
		&procLIB..__lsa_Autos_(in=a)
	%end;
	%do Ci=1 %to &nCataFil.;
		&procLIB..__lsa_Cats&Ci._(in=c&Ci.)
	%end;
	;

	%*300.	Determine the search order.;
	%do Ci=1 %to &nCataFil.;
		if	c&Ci.	then do;
			ORDER	=	&&Spcat&Ci..;
			LEVEL	=	&&Upcat&Ci..;
			PATH	=	strip( %sysfunc(quote( &&Ppcat&Ci.. , %str(%') )) );
			PATHFUL	=	strip( %sysfunc(quote( &&Ppcat&Ci..%OSDirDlm%nrbquote(&&Npcat&Ci..)%str(.SAS7BCAT) , %str(%') )) );
		end;
	%end;

	%*400.	Standardize the output.;
	TYPE	=	lowcase(TYPE);
	namelow	=	lowcase(NAME);

	%*800.	Rename;
	rename
		NAME	=	MEMBER
		MEMNAME	=	CATALOG
	;
run;

%*920.	Sort by macro name.;
proc sort
	data=&procLIB..__lsa_concat_
;
	by
		namelow
		ORDER
	;
run;

%*950.	Only keep the first occurance as it is the only one that can take effect.;
data %unquote(&outDAT.);
	set &procLIB..__lsa_concat_;
	by
		namelow
		ORDER
	;
	if	first.namelow;
	drop	namelow;
run;

%EndOfProc:
%*Restore the system options.;
options
%if	&OptNotes.		=	1	%then %do;	NOTES		%end;	%else %do;	NONOTES			%end;
%if	&OptSource.		=	1	%then %do;	SOURCE		%end;	%else %do;	NOSOURCE		%end;
%if	&OptSource2.	=	1	%then %do;	SOURCE2		%end;	%else %do;	NOSOURCE2		%end;
%if	&OptMLogic.		=	1	%then %do;	MLOGIC		%end;	%else %do;	NOMLOGIC		%end;
%if	&OptSymGen.		=	1	%then %do;	SYMBOLGEN	%end;	%else %do;	NOSYMBOLGEN		%end;
%if	&OptMPrint.		=	1	%then %do;	MPRINT		%end;	%else %do;	NOMPRINT		%end;
%if	&OptInOper.		=	1	%then %do;	MINOPERATOR	%end;	%else %do;	NOMINOPERATOR	%end;
;
%mend list_sasautos;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
%macro ErrMcr; %mend ErrMcr;

options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\AdvOp"
		"D:\SAS\omnimacro\FileSystem"
	)
	mautosource
;

%*020.	Assign a [FILENAME] associated with a [CATALOG].;
%mkdir(E:\test\cat1)
%mkdir(E:\test\This is a super long folder name that is used to test the case for the retrieval of physical path names of the concatenated catalog)
libname templib 'E:\test\cat1';
libname permlib 'E:\test\This is a super long folder name that is used to test the case for the retrieval of physical path names of the concatenated catalog';

filename	cat1	catalog	"templib.cat1.HelloWorld3.source";
data _NULL_;
	file	cat1;
	put	'%macro HelloWorld3;';
	put	'%put Hello, World! &sysmacroname;';
	put	'%mend HelloWorld3;';
run;
filename	cat1	clear;
filename	cat1	catalog	"templib.cat1";
options
	append=(
		sasautos=cat1
	)
;

%*050.	Define a macro in [WORK.SASMACR].;
%macro testWork;
%put	[This macro is from WORK.SASMACR];
%mend testWork;

%*060.	Define a macro in [templib.SASMACR].;
options mstored sasmstore=templib;
%macro HelloWorld1() / store source;
  data _null_;
    put "Hello, World! &sysmacroname";
  run;
%mend;

%macro HelloWorld2() / store source;
  data _null_;
    put "Hello, World! &sysmacroname";
  run;
%mend;

proc catalog cat=templib.sasmacr ;
   copy out=permlib.cat1;
      select helloworld1 /et=macro;
   run;
   copy out=permlib.cat2;
      select helloworld2 /et=macro;
   run;
quit;

options mstored sasmstore=permlib;
CATNAME permlib.sasmacr
  (permlib.cat1 (ACCESS=READONLY)
   permlib.cat2 (ACCESS=READONLY)
);

%*100.	Create the default output.;
%list_sasautos
%*We MUST add a complete statement like this if we would like to call the macro WITHOUT having to write the parentheses!;

%*900.	Purge.;
%*IMPORTANT: It is tested that we cannot simply delete the [.SAS7BCAT] file as long as current SAS session is active.;
%*IMPORTANT: Close current SAS session and remove the [.SAS7BCAT] file manually if required.;

/*-Notes- -End-*/

/*-Failures- -Begin-* /
%*100.	Below statements failed @ SAS V9.4;
%*There is a [.sas] file zipped in below ZIP package.;
filename	test	zip	"E:\test\testZip.zip";

options
	sasautos=(
		sasautos
		test
	)
	mautosource
;
%testZip
/*-Failures- -End-*/