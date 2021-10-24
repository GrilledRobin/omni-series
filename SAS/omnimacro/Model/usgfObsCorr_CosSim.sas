%macro usgfObsCorr_CosSim;
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is a method that supports the Record Similarity calculation in "Get-Function".											|
|	|Cosine Similarity: The quotient of the Euclidean Dot Product of two vectors divided by												|
|	| the product of their respective Euclidean Norms.																					|
|	|For Cosine Similarity, please find information in the internet.																	|
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
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
\*-------------------------------------------------------------------------------------------------------------------------------------*/

%*010.	Check parameters.;

%*090.	Parameters;
%*091.	Current local variables.;

%*095.	Parameters that are passed into this macro.;
%*Variable:;
%*GnFLDN	:	Number of all the variables as elements in the calculation vector.;

%*100.	Calculate the Euclidean Norm for the seed as in [inDAT];
___ENSeed	=	sqrt(
					uss(0
						%do	COLi=1	%to	&GnFLDN.;
							,sum( 0 , &&GeFLDS&COLi.. )
						%end;
					)
				)
;

%*200.	Calculate the Euclidean Norm for the comparison observation as in [inDB];
___ENComp	=	sqrt(
					uss(0
						%do	COLi=1	%to	&GnFLDN.;
							,sum( 0 , &&GeFLDN&COLi.. )
						%end;
					)
				)
;

%*300.	Calculate the Euclidean Dot Product for both observations.;
	___SIM_DP	=	0;
%do	COLi=1	%to	&GnFLDN.;
	___SIM_DP	+	( sum( 0 , &&GeFLDS&COLi.. ) * sum( 0 , &&GeFLDN&COLi.. ) );
%end;

%*400.	Generate the Cosine Similarity.;
ObsSim	=	___SIM_DP / ( ___ENSeed * ___ENComp );

%*900.	Purge.;
keep ObsSim;
%mend usgfObsCorr_CosSim;