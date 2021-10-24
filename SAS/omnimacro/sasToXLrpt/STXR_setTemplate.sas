%* Sets up the template and gathers information about it.                                ;


%macro STXR_setTemplate;
	%local
		Ltplfl
		Loutfl
	;

	%* If &TMPLPATH and &TMPLNAME are given (and exist, as verified in %checkParms), we    ;
	%* create the output file in terms of them. Otherwise, we cease the processing.        ;
	%if ( ( %nrbquote(&tmplpath.) ne ) and ( %nrbquote(&tmplname.) ne ) ) %then %do;
		%let	Ltplfl	=	&tmplpath.\&tmplname.&EnviroEXT.;
		%let	Loutfl	=	&savepath.\&savename.&EnviroEXT.;
		%if	%nrbquote(&Ltplfl.)	^=	%nrbquote(&Loutfl.)	%then %do;
			%sysexec(copy /Y "&Ltplfl." "&Loutfl." & exit);
		%end;
	%end;
	%else %do;
		%let	misspar		=	1;
		%goto	EndOfProc;
	%end;

	%* Retrieve all basic information in the given template.;
	%STXR_getXLinf(
		inWorkBook	=	%nrbquote(&Loutfl.)
		,outDAT		=	exr_WORK._tmp_xlinf
	)

%EndOfProc:
%mend STXR_setTemplate;
