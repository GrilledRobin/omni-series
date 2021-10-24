%macro crIndvFdrForSPMS(
	inFLD	=
	,outFLD	=	link_folder
);
&outFLD.	=	cats("indv_",reverse(cats("1",(compress(&inFLD.," ","dk")*3+17683569),"9"))*8+180523359);
%*&outFLD.	=	cats("indv_",int(ranuni(&inFLD.*1)*1000000001)+17683569);
%mend crIndvFdrForSPMS;