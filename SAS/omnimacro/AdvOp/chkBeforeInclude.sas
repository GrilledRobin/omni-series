%macro chkBeforeInclude(
	inroot=
	,inflnm=
);
%* Gets rid of the last backslash in each path, if any is included.;
%local	PRXID;
%let	PRXID	=	%sysfunc(prxparse(s/[\\\/]+$//i));

%let	inroot	=	%sysfunc(prxchange(&PRXID., -1, &inroot.));

%*Free the memory;
%syscall PRXFREE(PRXID);

%if	%sysfunc(fileexist(&inroot.\&inflnm.))	%then %do;
	%include	%sysfunc(quote(&inroot.\&inflnm.,%str(%')));
%end;
%mend chkBeforeInclude;