%macro SAS_CorrectEncoding(
	inDAT	=
	,outENC	=	"euc-cn"
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to modify the ENCODING attribute for given dataset to the desired one.										|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|inDAT	:	Input dataset.																											|
|	|outENC	:	The desired encoding.																									|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20131017		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20140412		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Add option "nowarn" to prevent warnings if the corrected encoding does not match the session encoding.						|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180304		| Version |	2.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Please try this macro to localize the dataset attribute once the "errors in trasncoding" are encountered.							|
|	|Note:	If an encoding value contains a hyphen (-), enclose the encoding value in quotation marks.									|
|	|Restriction:	CORRECTENCODING= can be used only when the SAS file uses the default base engine, which is V9 in SAS 9. 			|
|	|Ref.	http://support.sas.com/documentation/cdl/en/nlsref/61893/HTML/default/viewer.htm#a002626874.htm								|
|	|ENC.	http://support.sas.com/documentation/cdl/en/nlsref/61893/HTML/default/viewer.htm#a002607278.htm								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from "&cdwmac.\AdvOp"																								|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|ErrMcr																															|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*010.	Set parameters.;
%*Value of below variable should be the same as the name of current macro.;
%local	L_mcrLABEL;
%let	L_mcrLABEL	=	&sysMacroName.;

%if	%length(%qsysfunc(compress(&inDAT.,%str( ))))	=	0	%then %do;
	%put	%str(E)RROR: [&L_mcrLABEL.]No data is provided for conversion!;
	%ErrMcr
%end;

%*In China, the encoding is "euc-cn" by default.;
%if	%length(%qsysfunc(compress(&outENC.,%str( ))))	=	0	%then	%let	outENC	=	"euc-cn";

%if	%index(&inDAT.,%str(.))	=	0	%then	%let	inDAT	=	work.&inDAT.;

%*100.	Modify the ENCODING attribute.;
proc datasets
	library=%scan(&inDAT.,1,%str(.))
	nolist
	nowarn
;
   modify %scan(&inDAT.,2,%str(.)) / correctencoding=&outENC.;
quit;

%EndOfProc:
%mend SAS_CorrectEncoding;