%macro Str_Factorization(
	inList		=
	,LBoundChar	=	%str(%()
	,RBoundChar	=	%str(%))
	,MultiChar	=	%str(*)
	,SplitChar	=	%str( )
	,kGP		=	0
	,nEP		=	0
	,mNest		=	0
	,outCNT		=	G_n_Grp
	,outEPfx	=	G_e_Grp
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to factorize the given character string, like "a * ( b c )", into "a * b a * c",							|
|	| in order to process the resolved character string in other processes, such as a simulation to PROC FREQ.							|
|	|Known Limitation:																													|
|	|(1) Currently we only consider the valid sub-strings, i.e. "a", "b" and "c" in "a * ( b c )", to be of below patterns:				|
|	|  - Begins with "[[:alpha:]_]"																										|
|	|  - Ends with "\w"																													|
|	|(2) Multiple characters for [MultiChar] and [SplitChar] are not tested,															|
|	|  presumably they can be used.																										|
|	|  (while [LBoundChar] and [RBoundChar] are tested, please see the sample[2] below)													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inList		:	The input character string, within which [LBoundChar] and [RBoundChar] must exist in PAIRS.							|
|	|LBoundChar	:	The Left-Bound Character for the group to be identified and further factorized.										|
|	|RBoundChar	:	The Right-Bound Character for the group to be identified and further factorized.									|
|	|MultiChar	:	The character existing as Multiplier, as the "*" in the polynomial "a * ( b + c )".									|
|	|SplitChar	:	The character existing as Splitter, as the "+" in the polynomial "a * ( b + c )".									|
|	|				IMPORTANT: Use Regular Expression for this parameter, for it is parsed in terms of RegExp!!!						|
|	|kGP		:	[K]th Group that is Passed down from upper nest level, which is zero at the first call.								|
|	|nEP		:	[N]th Element, of [K]th Group, that is Passed down from upper nest level, which is zero at the first call.			|
|	|mNest		:	[M]th Level of Nesting Call of the same macro, which is zero at the first call.										|
|	|outCNT		:	The number of factors that are defactorized from the string.														|
|	|outEPfx	:	The prefix of macro variables holding the factors that are defactorized from the string.							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20150919		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20150920		| Version |	1.01		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Add comments for process flow.																								|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20150920		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Use external macro definition file to bypass the DATA STEP,																	|
|	|      | hence enable this macro to be called at ANYWHERE in a project.																|
|	|      |However, we have no idea why [filrf] cannot be INCLUDED and thus we can only INCLUDE the physical file.						|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20150926		| Version |	2.01		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Quote the output result as the [MultiChar] could be comma and thus interfere with the corresponding processes.				|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20160611		| Version |	2.02		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the physical file name with the name as [filrf] in the INCLUDE statement.											|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20160730		| Version |	2.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Remove the determination of Directory Name Delimiters (\ or / or any others).												|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20170810		| Version |	2.20		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Minimize the use of [SUPERQ] to avoid the overflow of macro-quoting layers.													|
|	|      |Concept:																													|
|	|      |If some value is macro-quoted, its quoting status will be inherited to all the subsequent references unless it is modified	|
|	|      | by another macro function (adding additional characters before or after it will have no effect, e.g. [aa&bb.cc]).			|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180310		| Version |	2.30		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Please find the attachments for examples.																							|
|	|IMPORTANT: [LBoundChar] and [RBoundChar] must exist in PAIRS!!!																	|
|	|IMPORTANT: [LBoundChar] and [RBoundChar] must not be the SAME!!!																	|
|	|IMPORTANT: [MultiChar] and [SplitChar] cannot exist together, such as "a + * b"!!!													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from the same location as current macro.																			|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|Str_Factorization																												|
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
%if	%length(%qsysfunc(compress(&SplitChar.,%str( ))))	=	0	%then %do;
	%put	%str(N)OTE: [&L_mcrLABEL.]The character to split the groups is BLANK, it will be set as [\s+] with respect of RegExp.;
	%let	SplitChar	=	%str(\s+);
%end;
%if	%length(%qsysfunc(compress(&kGP.,%str( ))))		=	0	%then	%let	kGP		=	0;
%if	%length(%qsysfunc(compress(&nEP.,%str( ))))		=	0	%then	%let	nEP		=	0;
%if	%length(%qsysfunc(compress(&mNest.,%str( ))))	=	0	%then	%let	mNest	=	0;
%if	%length(%qsysfunc(compress(&outCNT.,%str( ))))	=	0	%then	%let	outCNT	=	G_n_Grp;
%if	%length(%qsysfunc(compress(&outEPfx.,%str( ))))	=	0	%then	%let	outEPfx	=	G_e_Grp;

%*013.	Define the global environment.;
%global
	&outCNT.
;
%let	&outCNT.	=	0;

%*014.	Define the local environment.;
%local
	lenLBC
	lenRBC
	BGchk
	GrpCnt
	BLbound
	BRbound
	StrChkL
	StrChkR
	FreqChr
	prxSep&mNest.
	FreqGrpCnt
	prxGrp&mNest.
	Gi
	Gj
	VarP
	NextL
	Oi
	intMAC
	tmpMAC
	tmpMACStr
	filrf
	rc
	fid
;
%*lenLBC : Length of the Left-Bound Character;
%*lenRBC : Length of the Right-Bound Character;
%let	lenLBC	=	%length(&LBoundChar.);
%let	lenRBC	=	%length(&RBoundChar.);
%let	FreqChr	=	&inList.;
%*BG : Bracket or Parenthesis Group.;
%let	BGchk	=	0;
%let	NextL	=	%eval(&mNest. + 1);

%*100.	Replace the most outside content, within matching parentheses, with the name "Grp[n]" to simplify the process.;
%*This concept comes from the Balanced Group of Regular Expression.;
%let	GrpCnt	=	0;
%do %while (%index(&FreqChr.,&LBoundChar.));
	%*100.	When we find there is [LBoundChar] we increment the [GrpCnt] by 1.;
	%let	GrpCnt	=	%eval(&GrpCnt. + 1);

	%*200.	Locate the very first [LBoundChar].;
	%let	BLbound	=	%index(&FreqChr.,&LBoundChar.);

	%*300.	We plan to move the pointer towards right by 1 character per each loop.;
	%let	BRbound	=	%eval(&BLbound. + &lenLBC. - 1);

	%*100.	Now that we have one [LBoundChar], we add the counter into the Stack.;
	%let	BGchk	=	1;

	%*500.	Until the count becomes 0, the matching [LBoundChar] and [RBoundChar] are determined.;
	%do %until (&BGchk. = 0);
		%*100.	We start the tracking from the first character on the right side of the [LBoundChar].;
		%let	BRbound	=	%eval(&BRbound. + 1);

		%*200.	We first get the string of the same length of the [LBoundChar] and see if it is same as [LBoundChar].;
		%let	StrChkL	=	%qsubstr(&FreqChr.,&BRbound.,&lenLBC.);

		%*300.	We then get the string of the same length of the [RBoundChar] and see if it is same as [RBoundChar].;
		%let	StrChkR	=	%qsubstr(&FreqChr.,&BRbound.,&lenRBC.);

		%*400.	When we find one [LBoundChar] we add the count by 1.;
		%if	&StrChkL. = &LBoundChar. %then %do;
			%let	BGchk	=	%eval(&BGchk. + 1);
			%*As this character string is the same as [LBoundChar], we move the pointer to its end.;
			%let	BRbound	=	%eval(&BRbound. + &lenLBC. - 1);
		%end;

		%*420.	When we find one [RBoundChar] we subtract the count by 1.;
		%*The [ELSE] here depends on the prerequisite that [LBoundChar]^=[RBoundChar].;
		%else	%if	&StrChkR. = &RBoundChar. %then %do;
			%let	BGchk	=	%eval(&BGchk. - 1);
			%*As this character string is the same as [RBoundChar], we move the pointer to its end.;
			%let	BRbound	=	%eval(&BRbound. + &lenRBC. - 1);
		%end;
	%end;

	%*600.	We capture the current stack of paired [LBoundChar] and [RBoundChar].;
	%local	Grp&GrpCnt.;
	%let	Grp&GrpCnt.	=	%qsubstr(&FreqChr.,&BLbound.,%eval(&BRbound. - &BLbound. + 1));

	%*700.	We replace above stack of characters with a pre-defined string for nesting call of this macro.;
	%let	FreqChr		=	%qsysfunc(tranwrd(&FreqChr.,&&Grp&GrpCnt..,_Fb_Grp&GrpCnt._Fe_));

	%*800.	We then remove the bound characters from above stack, to pass its exact value to the nesting call.;
	%let	Grp&GrpCnt.	=	%qsysfunc(strip(%qsubstr(&&Grp&GrpCnt..,%eval(&lenLBC. + 1),%eval(%length(&&Grp&GrpCnt..) - &lenLBC. - &lenRBC.))));
%end;

%*200.	Continue Grouping in terms of [MultiChar], which means we put all items that are connected with [MultiChar] as one group.;
%*After this step, each FreqGrp[n] will be either of below patterns:;
%*FreqGrp[1] : VAR;
%*FreqGrp[2] : VAR1 [MultiChar] VAR2 < [MultiChar] VAR3 < [MultiChar] ...>>;
%*210.	We validate the separator [\s+] when it directly connects two normal character strings.;
%let	prxSep&mNest.	=	%sysfunc(prxparse(s/^(.*?\w)\s*&SplitChar.\s*(?=[[:alpha:]_])//ismx));

%*220.	This determines the number of groups we split in current nesting level, but not the output number of groups we pass to upper level.;
%let	FreqGrpCnt	=	1;

%*230.	As long as we find the valid [SplitChar], we split the character string.;
%do %while (%sysfunc(prxmatch(&&prxSep&mNest..,&FreqChr.)));
	%*100.	Retrieve the first string that matches the above pattern.;
	%local	FreqGrp&FreqGrpCnt.;
	%let	FreqGrp&FreqGrpCnt.	=	%qsysfunc(prxposn(&&prxSep&mNest..,1,&FreqChr.));

	%*200.	Remove the above sub-string from the entire one.;
	%let	FreqChr	=	%qsysfunc(strip(%qsysfunc(prxchange(&&prxSep&mNest..,1,&FreqChr.))));

	%*300.	Add the counter by 1.;
	%let	FreqGrpCnt	=	%eval(&FreqGrpCnt. + 1);
%end;

%*240.	If there is any string left, we set it as the last group.;
%local	FreqGrp&FreqGrpCnt.;
%let	FreqGrp&FreqGrpCnt.	=	&FreqChr.;

%*300.	Nest the Groups to find all combinations.;
%*NeGrp[i] : Number of Elements in group [i].;
%*FreqGrpD[m]E[n] : Frequency Group Detail [#m], element [#n].;
%*NG : Nested Group.;
%*We find the pre-defined pattern in the grouped strings from above step.;
%let	prxGrp&mNest.	=	%sysfunc(prxparse(/^_Fb_(Grp\d+)_Fe_$/ismx));
%do Gi=1 %to &FreqGrpCnt.;
	%*100.	Take [MultiChar] as separator, we can find the number of elements in each group.;
	%local	NeGrp&Gi.;
	%let	NeGrp&Gi.	=	%eval(%sysfunc(count(&&FreqGrp&Gi..,&MultiChar.)) + 1);

	%*200.	Factorize all element in all groups by calling this macro in recursion.;
	%do Gj=1 %to &&NeGrp&Gi..;
		%*100.	Locate the [Gj]th element in current group.;
		%local	FreqGrpD&Gi.E&Gj.;
		%let	FreqGrpD&Gi.E&Gj.	=	%qsysfunc(strip(%qscan(&&FreqGrp&Gi..,&Gj.,&MultiChar.)));

		%*200.	If the pre-defined pattern is found, we call another same process to factorize it.;
		%if	%sysfunc(prxmatch(&&prxGrp&mNest..,&&FreqGrpD&Gi.E&Gj..))	%then %do;
			%*100.	Resolve the identifier, here we set as "Grp[n]", to get its value.;
			%let	VarP	=	%superq(%sysfunc(prxposn(&&prxGrp&mNest..,1,&&FreqGrpD&Gi.E&Gj..)));

			%*200.	Factorize the value by another nesting call.;
			%*We do not output meaningful variables determined by [outCNT] for any of the lower nesting levels.;
			%Str_Factorization(
				inList		=	&VarP.
				,LBoundChar	=	&LBoundChar.
				,RBoundChar	=	&RBoundChar.
				,MultiChar	=	&MultiChar.
				,SplitChar	=	&SplitChar.
				,kGP		=	&Gi.
				,nEP		=	&Gj.
				,mNest		=	&NextL.
				,outCNT		=	tmpN
				,outEPfx	=	tmpE
			)
		%end;
		%*220.	Otherwise we fake the lower nesting level by setting one element.;
		%else %do;
			%global
				NoutG&NextL._&Gi._&Gj.
				EoutG&NextL._&Gi._&Gj._1
			;
			%*100.	Should there be no nested group to evaluate, we set the count as 1.;
			%let	NoutG&NextL._&Gi._&Gj.		=	1;
			%let	EoutG&NextL._&Gi._&Gj._1	=	&&FreqGrpD&Gi.E&Gj..;
		%end;
	%end;
%end;

%*400.	Retrieve the combinations up to current level.;
%*NoutG : Number of Output Groups.;
%*EoutG : Elements of Output Groups.;

%*410.	Setup the temporary file in the WORK library, which will contain the created termporary macro denifition.;
%let	intMAC	=	myIntMac;
%let	rc		=	%sysfunc(filename(intMAC,%qsysfunc(pathname(work))));

%*420.	Assign the FileRef for writing the text messages.;
%let	filrf	=	myTmpMac;
%let	rc		=	%sysfunc(filename( filrf , tmpMAC.txt , , , &intMAC. ));

%*425.	Overwrite the file with a blank content, in case it exists, in order to create a blank file for operation.;
%let	fid			=	%sysfunc(fopen(&filrf.,O));
%let	rc			=	%sysfunc(fread(&fid.));
%let	tmpMACStr	=	%str( );
%let	rc			=	%sysfunc(fput(&fid.,&tmpMACStr.));
%let	rc			=	%sysfunc(fwrite(&fid.));
%let	rc			=	%sysfunc(fclose(&fid.));

%*430.	Open the file at APPEND mode so that each FWRITE function will write a new line.;
%let	fid			=	%sysfunc(fopen(&filrf.,A));

%*440.	Output the records to the file if the FileRef is successfully assigned.;
%*After all, it should have been successful as we create the file in the WORK directory.;
%if &fid. <= 0 %then %do;
	%put %sysfunc(sysmsg());
%end;

%*441.	Declare the position of the file pointer.;
%let	rc			=	%sysfunc(fread(&fid.));

%*442.	Write the MACRO name in the first line.;
%*In case of macro name conflict, we append the current [mNest] to the macro name.;
%let	tmpMACStr	=	%nrstr(%macro tmpMAC)&mNest.%str(;);
%*Write the text to File Data Buffer (FDB), same as below statements.;
%let	rc			=	%sysfunc(fput(&fid.,&tmpMACStr.));
%*Transmit the text from FDB to the file content, same as below statements.;
%let	rc			=	%sysfunc(fwrite(&fid.));

%*443.	This counter is for the output groups.;
%let	tmpMACStr	=	%nrstr(%global NoutG&mNest._&kGP._&nEP.; %let NoutG&mNest._&kGP._&nEP. = 0;);
%let	rc			=	%sysfunc(fput(&fid.,&tmpMACStr.));
%let	rc			=	%sysfunc(fwrite(&fid.));

%*444.	Write texts for all groups.;
%do Gi=1 %to &FreqGrpCnt.;

	%*100.	Write as many macro DO loops as [&&NeGrp&Gi..] into the file.;
	%*We need to loop over all the output items for each element in current group.;
	%do Gj=1 %to &&NeGrp&Gi..;
		%let	tmpMACStr	=	%nrstr(%do tmpLOOP)&Gj.%nrstr(=1 %to )&&NoutG&NextL._&Gi._&Gj..%str(;);
		%let	rc			=	%sysfunc(fput(&fid.,&tmpMACStr.));
		%let	rc			=	%sysfunc(fwrite(&fid.));
	%end;

	%*200.	Write the statement to increment the counter.;
	%let	tmpMACStr	=	%nrstr(%let NoutG&mNest._&kGP._&nEP. = %eval(&&NoutG&mNest._&kGP._&nEP.. + 1););
	%let	rc			=	%sysfunc(fput(&fid.,&tmpMACStr.));
	%let	rc			=	%sysfunc(fwrite(&fid.));

	%*300.	Write the statement, to connect all the found items by [MultiChar], and output for upper nesting levels.;
	%*310.	Firstly create the GLOBAL macro variable.;
	%let	tmpMACStr	=	%nrstr(%global EoutG&mNest._&kGP._&nEP._&&NoutG&mNest._&kGP._&nEP..;);
	%let	rc			=	%sysfunc(fput(&fid.,&tmpMACStr.));
	%let	rc			=	%sysfunc(fwrite(&fid.));

	%*320.	Write the first part of the value assignment.;
	%*Note: There are two unclosed left-parentheses;
	%let	tmpMACStr	=	%nrstr(
								%let EoutG&mNest._&kGP._&nEP._&&NoutG&mNest._&kGP._&nEP.. = %qsysfunc%(
									catx%(&MultiChar.
							);
	%let	rc			=	%sysfunc(fput(&fid.,&tmpMACStr.));
	%let	rc			=	%sysfunc(fwrite(&fid.));

	%*330.	Write the middle part of the value assignment by the loop.;
	%*We need to loop over all the output items for each element in current group.;
	%do Gj=1 %to &&NeGrp&Gi..;
		%let	tmpMACStr	=	%nrstr(,&&EoutG&NextL._)&Gi._&Gj.%nrstr(_&tmpLOOP)&Gj.%str(..);
		%let	rc			=	%sysfunc(fput(&fid.,&tmpMACStr.));
		%let	rc			=	%sysfunc(fwrite(&fid.));
	%end;

	%*340.	Write the last part of the value assignment.;
	%*Note: There are two unclosed right-parentheses, which are to enclose the above ones.;
	%let	tmpMACStr	=	%nrstr(
									%)
								%);
							);
	%let	rc			=	%sysfunc(fput(&fid.,&tmpMACStr.));
	%let	rc			=	%sysfunc(fwrite(&fid.));

	%*800.	Write as many END statements as the macro DO loops.;
	%*We need to loop over all the output items for each element in current group.;
	%do Gj=1 %to &&NeGrp&Gi..;
		%let	tmpMACStr	=	%nrstr(%end;);
		%let	rc			=	%sysfunc(fput(&fid.,&tmpMACStr.));
		%let	rc			=	%sysfunc(fwrite(&fid.));
	%end;

%*End of Loop for all groups.;
%end;

%*448.	Put a MEND statement for the macro.;
%let	tmpMACStr	=	%nrstr(%mend tmpMAC)&mNest.%str(;);
%let	rc			=	%sysfunc(fput(&fid.,&tmpMACStr.));
%let	rc			=	%sysfunc(fwrite(&fid.));

%*450.	Close the file.;
%let	rc	=	%sysfunc(fclose(&fid.));

%*490.	Call the temporary macro.;
%include &filrf.;
%tmpMAC&mNest.

%*800.	Purge.;
%let	rc	=	%sysfunc(filename(intMAC));
%let	rc	=	%sysfunc(filename(filrf));
%syscall	prxfree(prxSep&mNest.);
%syscall	prxfree(prxGrp&mNest.);

%*900.	Output.;
%*At the very top level among all calls, we output the final list.;
%let	&outCNT.	=	&&NoutG&mNest._&kGP._&nEP..;
%do Oi=1 %to &&&outCNT..;
	%global	&outEPfx.&Oi.;
	%let	&outEPfx.&Oi.	=	&&EoutG&mNest._&kGP._&nEP._&Oi..;
%end;

%EndOfProc:
%mend Str_Factorization;

/*-Notes- -Begin-* /
%*Taken below as a sample:;
%let inCHR	=	A B * < < C D * E > * F > * < G * < < H I > * J K > L > M * < N O >;
%*The groups passed down to [mNest=1] are as below:;
%*[2nd] Element of [2nd] Group: < C D * E > * F;
%*[3rd] Element of [2nd] Group: G * < < H I > * J K > L;
%*[1st] Element of [3rd] Group: N O;

%*Full Test Program[1]:;
%let inCHR	=	A B * < < C D * E > * F > * < G * < < H I > * J K > L > M * < N O >;
%*Or you can set the statement as below:;
%let inCHR	=
	A
	B * < < C D * E > * F > * < G * < < H I > * J K > L >
	M * < N O >
;
%Str_Factorization(
	inList		=	&inCHR.
	,LBoundChar	=	%str(<)
	,RBoundChar	=	%str(>)
	,MultiChar	=	%str(*)
	,SplitChar	=	%str( )
	,kGP		=	0
	,nEP		=	0
	,mNest		=	0
	,outCNT		=	GnGrp
	,outEPfx	=	GeGrp
)

%macro chk;
%do i=1 %to &GnGrp.;
	%put	GeGrp&i.	=	&&GeGrp&i..;
%end;
%mend chk;
%chk

%*Full Test Program[2]:;
%let inCHR	=
	A
	+ B * // // C + D * E --- * F --- * // G * // // H + I --- * J + K --- + L ---
	+ M * // N + O ---
;
%Str_Factorization(
	inList		=	%nrbquote(&inCHR.)
	,LBoundChar	=	%str(//)
	,RBoundChar	=	%str(---)
	,MultiChar	=	%str(*)
	,SplitChar	=	%str(\+)
	,kGP		=	0
	,nEP		=	0
	,mNest		=	0
	,outCNT		=	GnGrp
	,outEPfx	=	GeGrp
)

%macro chk;
%do i=1 %to &GnGrp.;
	%put	GeGrp&i.	=	&&GeGrp&i..;
%end;
%mend chk;
%chk

%*Output.;
GeGrp1    =   A
GeGrp2    =   B*C*F*G*H*J
GeGrp3    =   B*C*F*G*I*J
GeGrp4    =   B*C*F*G*K
GeGrp5    =   B*C*F*L
GeGrp6    =   B*D*E*F*G*H*J
GeGrp7    =   B*D*E*F*G*I*J
GeGrp8    =   B*D*E*F*G*K
GeGrp9    =   B*D*E*F*L
GeGrp10    =   M*N
GeGrp11    =   M*O

/*-Notes- -End-*/