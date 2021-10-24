%macro backupdat(indat=);
	%if	%sysfunc(exist(&indat.))	%then %do;
		data &indat._bak(compress=yes);
			set &indat.;
		run;
	%end;
%mend backupdat;