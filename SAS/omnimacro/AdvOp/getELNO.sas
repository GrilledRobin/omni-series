%macro getELNO(indsn=,indat=,instr=,outvar=);
	%if	%bquote(&indsn)	NE	%then %let	indsn	=	&indsn..;
	%global	&outvar.;
	%let	&outvar=1;
	%if %sysfunc(exist(&indsn.&indat.))	%then %do;
		PROC CONTENTS
			DATA=&indsn.&indat.
			NOPRINT
			OUT=_TEMP_(
				KEEP=
					NAME
					FORMAT
					LABEL
					VARNUM
				where=(
					index(NAME,"&instr.")	>	0
				)
			);
		RUN;
		%getOBS4DATA(
			inDAT	=	_TEMP_
			,outVAR	=	&outvar.
		)
	%end;
%mend;