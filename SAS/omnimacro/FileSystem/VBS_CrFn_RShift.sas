%macro VBS_CrFn_RShift(
	VBSFile	=
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|VBSFile	:	The VBS file defining public functions.																				|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20140913		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*010.	Set parameters.;
%local
	L_mcrLABEL
;
%let	L_mcrLABEL	=	&sysMacroName.;

%*100.	Generate VB Script.;
data _NULL_;
	file "&VBSFile.";

	put	"Public Function RShift(ByVal lValue, ByVal iShiftBits)";
	put	"    RShift = lValue \ (2 ^ iShiftBits)";
	put	"End Function";
run;

%EndOfProc:
%mend VBS_CrFn_RShift;