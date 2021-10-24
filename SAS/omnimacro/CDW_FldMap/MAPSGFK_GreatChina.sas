%macro MAPSGFK_GreatChina(
	outDAT		=	GreatChina
	,outANNO	=	GreatChina_data
	,outANNOLBL	=	GreatChina_label
	,procLIB	=	WORK
);
%*000.	Info.;
/*-------------------------------------------------------------------------------------------------------------------------------------*\
|100.	Introduction.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|This macro is intended to generate the map source of Great China for the annotation or reporting with Geographical procedures.		|
|	|The data sources are from MAPSGFK library as preset in SAS.																		|
|---------------------------------------------------------------------------------------------------------------------------------------|
|200.	Glossary.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|outDAT		:	The output result.																									|
|	|outANNO	:	The output attribute table for annotation.																			|
|	|procLIB	:	The working library.																								|
|---------------------------------------------------------------------------------------------------------------------------------------|
|300.	Update log.																														|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	| Date |	20170107		| Version |	1.00		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Version 1.																													|
|	|______|____________________________________________________________________________________________________________________________|
|	|___________________________________________________________________________________________________________________________________|
|	| Date |	20180401		| Version |	1.10		| Updater/Creator |	Lu Robin Bin												|
|	|______|____________________|_________|_____________|_________________|_____________________________________________________________|
|	| Log  |Replace the macro expression [&aaa. = ] with [%length(%qsysfunc(compress(&aaa.,%str( )))) = 0] to avoid unnecessary			|
|	|      | failures.																													|
|	|______|____________________________________________________________________________________________________________________________|
|---------------------------------------------------------------------------------------------------------------------------------------|
|400.	User Manual.																													|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Please find the attachments for examples.																							|
|---------------------------------------------------------------------------------------------------------------------------------------|
|500.	Dependent Macros.																												|
|---------------------------------------------------------------------------------------------------------------------------------------|
|	|Below macros are from SAS Annotation Facility																						|
|	|-----------------------------------------------------------------------------------------------------------------------------------|
|	|	|annomac																														|
|	|	|maplabel																														|
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
%if	%length(%qsysfunc(compress(&outDAT.,%str( ))))		=	0	%then	%let	outDAT		=	GreatChina;
%if	%length(%qsysfunc(compress(&outANNO.,%str( ))))		=	0	%then	%let	outANNO		=	GreatChina_data;
%if	%length(%qsysfunc(compress(&outANNOLBL.,%str( ))))	=	0	%then	%let	outANNOLBL	=	GreatChina_label;
%if	%length(%qsysfunc(compress(&procLIB.,%str( ))))		=	0	%then	%let	procLIB		=	WORK;

%*013.	Define the local environment.;

%*100.	Retrieve the source of Taiwan.;
%*110.	Set the province ID for Taiwan.;
data &procLIB..mapsgfk_tw;
	set mapsgfk.taiwan;
	id2	=	id1;
	id1	=	"CN-83";
run;

%*150.	Combine the map sources.;
data &procLIB..mapsgfk_combine;
	set
		mapsgfk.China
		&procLIB..mapsgfk_tw
	;
run;

%*190.	Project the latitude and longitude of Taiwan to adapt the geographical location of the original China.;
proc gproject
	data=&procLIB..mapsgfk_combine
	out=&outDAT.
	LATLON
	PARMIN=mapsgfk.projparm
	PARMENTRY=&procLIB..China
;
	id	id;
run;

%*200.	Prepare the annotation facility, such as the Province Names.;
%*210.	The attributes of Taiwan.;
data &procLIB..mapsgfk_tw_attr;
	set mapsgfk.taiwan_attr;
	id2			=	id1;
	id2name		=	id1name;
	id1			=	"CN-83";
	id1name		=	"Taiwan Sheng";
	id1nameU	=	put("Ã®ÕÂ °",$uesc200.);
	isoname		=	"China";
run;

%*250.	Combine the attributes to those of the original China.;
data
	&outANNO.(
		rename=(
			id1			=	id
			id1nameU	=	idname
		)
	)
;
	set
		mapsgfk.China_attr
		&procLIB..mapsgfk_tw_attr
	;
%*	keep
		id1
		id1nameU
	;
	drop
		id
		idname
	;
run;

%*260.	Iniatialize the annotation facility.;
%annomac

%*260.	Add the map lable.;
%maplabel(
	&outDAT.
	,&outANNO.
	,&procLIB..anno_label
	,idname
	,id
	,font=SimSun
	,color=black
	,size=1.5
	,hsys=3
)

%*270.	Transcode the label from the annotation to match that of the current session.;
data &outANNOLBL.;
	set &procLIB..anno_label;
	text	=	unicode(text);
run;

%EndOfProc:
%mend MAPSGFK_GreatChina;

/*-Notes- -Begin-* /
%*Full Test Program[1]:;
options
	sasautos=(
		sasautos
		"D:\SAS\omnimacro\CDW_FldMap"
	)
	mautosource
;

%*100.	Generate the map of Great China.;
%MAPSGFK_GreatChina(
	outDAT		=	GreatChina
	,outANNO	=	GreatChina_data
	,outANNOLBL	=	GreatChina_label
	,procLIB	=	WORK
)

%*200.	Only keep the level at Province.;
proc sort
	data=GreatChina
;
	by	ID1;
run;
proc gremove
	data=GreatChina
	out=tmpds
;
	by	ID1;
	id	id;
run;
data GreatChina2;
	set tmpds;
	id	=	ID1;
	drop
		ID1
	;
run;

%*300.	Draw the map of Great China.;
proc gmap
	map		=	GreatChina2
	data	=	GreatChina_data
;
	id	id;
	choro
		id
		/nolegend
		anno	=	GreatChina_label
	;
run;
quit;

/*-Notes- -End-*/