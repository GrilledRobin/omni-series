%macro uspObsCorr_CosSim;
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is a method that supports the Record Similarity calculation.															|
|	|Cosine Similarity: The quotient of the Euclidean Dot Product of two vectors divided by												|
|	| the product of their respective Euclidean Norms.																					|
|	|For Cosine Similarity, please find information in the internet.																	|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20150108		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20150123		| Version |	2.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Remove the dependency of &LnOBS., embed the array of arrSIM to expand the compatibility.									|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|To maximize the accuracy of Cosine Similarity, please ensure the source data is standized with the MEAN of							|
|	| all fields as 0 and the VARIANCE of them as unchanged.																			|
|	|This is to move the center of the Euclidean space to the center of the pool of observations.										|
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
%*111.	Euclidean Norm (Magnitude) of the Seed vector.;
array
	arrSeedEN{1}
	_temporary_
;
%*112.	Euclidean Norm (Magnitude) of the Comparison Object vector.;
array
	arrCompEN{ &LnCORR. }
	_temporary_
;
%*113.	Euclidean Dot Product between the Seed vector and the Comparison Object vector.;
array
	arrEDP{ &LnCORR. }
	_temporary_
;
%*119.	Similarity.;
array
	arrSIM{ &LnCORR. }
	Sim1-Sim&LnCORR.
;

%*111.	Prepare the Euclidean Norm and Euclidean Dot Product for all vectors.;
arrSeedEN{1}	=	sqrt(
						uss(0
							%do	COLi=1	%to	&GnFLDN.;
								,arrSeed{ &COLi. }
							%end;
						)
					)
;
do tmpi=1 to __rec;
	arrCompEN{tmpi}	=	sqrt(
							uss(0
								%do	COLi=1	%to	&GnFLDN.;
									,arrComp{ tmpi , &COLi. }
								%end;
							)
						)
	;
	arrEDP{tmpi}	=	0;
%do	COLi=1	%to	&GnFLDN.;
	arrEDP{tmpi}	+	( arrSeed{ &COLi. } * arrComp{ tmpi , &COLi. } );
%end;
end;

%*150.	Cosine Similarity.;
do tmpi=1 to __rec;
	arrSIM{tmpi}	=	arrEDP{tmpi} / ( arrSeedEN{1} * arrCompEN{tmpi} );
end;

%*900.	Purge.;
keep
	%do	RECi=1	%to	&LnCORR.;
		Sim&RECi.
	%end;
;
%mend uspObsCorr_CosSim;