%macro uspObsCorr_EuclidDist;
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is a method that supports the Record Distance calculation.																|
|	|Euclidean Distance																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20150123		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
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

%*010.	Check parameters.;
%*011.	Identify current processing macro.;
%local
	L_mcrLABEL
	Lohno
;
%let	L_mcrLABEL	=	&sysMacroName.;
%let	Lohno		=	%str(E)RROR: [&L_mcrLABEL.]Process failed due to errors!;

%*090.	Parameters;
%*091.	Current local variables.;
%local
	COLi
	RECi
;

%*095.	Parameters that are passed into this macro.;
%*Variable:;
%*LnCORR	:	The maximum number of correlativity pairs to be generated.;
%*GnFLDN	:	Number of all the variables as elements in the calculation vector.;
%*__rec		:	The number of records starting from the first one in current BY group or in current dataset,;
%*				 as determined by the GrpBy in the caller macro.;
%*Array:;
%*arrSeed	:	The current vector as the seed for comparison.;
%*				arrSeed{N} : The {N}th element (SAS data variable) in the vector;
%*arrComp	:	The vector(s) as the object for comparison.;
%*				arrComp{M,N} : The {N}th element (SAS data variable) in the {M}th vector;

%*110.	Prepare the calculation.;
array
	arrEDist{ &LnCORR. }
	Dist1-Dist&LnCORR.
;

%*150.	Euclidean Distance.;
do tmpi=1 to __rec;
	arrEDist{tmpi}	=	sqrt(
							uss(0
								%do	COLi=1	%to	&GnFLDN.;
									,sum( 0 ,arrSeed{ &COLi. } , arrComp{ tmpi , &COLi. } * (-1) )
								%end;
							)
						)
	;
end;

%*900.	Purge.;
keep
	%do	RECi=1	%to	&LnCORR.;
		Dist&RECi.
	%end;
;
%mend uspObsCorr_EuclidDist;