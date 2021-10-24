%* Checks the parameters.                                                                ;


%macro STXR_checkParms;
	%* First we determine the values of certain SAS System options.                        ;
	%if %sysfunc( getoption( notes ) ) = NOTES         %then %let cnotes = 1;
	%if %sysfunc( getoption( source ) ) = SOURCE       %then %let csource = 1;
	%if %sysfunc( getoption( source2 ) ) = SOURCE2     %then %let csource2 = 1;
	%if %sysfunc( getoption( mlogic ) ) = MLOGIC       %then %let cmlogic = 1;
	%if %sysfunc( getoption( symbolgen ) ) = SYMBOLGEN %then %let csymbolg = 1;
	%if %sysfunc( getoption( mprint ) ) = MPRINT       %then %let cmprint = 1;

	%* Gets rid of the last backslash in each path, if any is included.                    ;
	%local	PRXID;
	%let	PRXID	=	%sysfunc(prxparse(s/[\\\/]+$//i));

	%let	savepath	=	%sysfunc(prxchange(&PRXID., -1, &savepath.));

	%if	%nrbquote(&tmplpath.)	EQ	%then %do;
		%put	&saserror.: [&L_mcrLABEL.]The path for template is not given!;
		%let	misspar	=	1;
		%goto	theend;
	%end;
	%else %do;
		%let	tmplpath	=	%sysfunc(prxchange(&PRXID., -1, &tmplpath.));
	%end;


	%if	%nrbquote(&savepath.)	EQ	%then %do;
		%let	savepath	=	c:\temp;
		%put;
		%put	&sasnote.: [&L_mcrLABEL.]The default value of the SAVEPATH parameter appears to have;
		%put	----- been overwritten by a null value during invocation of the EXPORTTOEXCEL;
		%put	----- macro. It has been reset to 'c:\temp' in order to allow macro execution.;
		%put;
	%end;

	%if	%nrbquote(&savename.)	EQ	%then %do;
		%let	savename	=	exportToExcel Output;
		%put;
		%put	&sasnote.: [&L_mcrLABEL.]The default value of the SAVENAME parameter appears to have;
		%put	----- been overwritten by a null value during invocation of the EXPORTTOEXCEL;
		%put	----- macro. It has been reset to 'exportToExcel Output' in order to allow;
		%put	----- macro execution.;
		%put;
	%end;

	%* We then turn all those options off, this to minimize the amount of junk that the    ;
	%* usage of this macro would otherwise insert between the lines of the log of the code ;
	%* in which it gets used.                                                              ;
	options nonotes nosource nosource2 nomlogic nosymbolgen nomprint;
	options noxwait xsync xmin;

	%* Here we declare the working temporary library to distinguish every call to sasToXLrpt;
	%if	%sysfunc(libref(exr_WORK))	%then %do;
		libname exr_WORK "&exroot.\exr_WORK";
	%end;

	proc datasets
		lib	=	exr_WORK
		nolist
		nowarn
		kill
	;
	run;
	quit;

	%* Now that the notes are turned off, we define a couple macro variables. Doing it     ;
	%* this way allows user variation -- e.g., the user can type in 'yes', 'TRUE', or '1'. ;
	%if %STXR_among( %upcase( %substr( &endclose., 1, 1 ) ), Y T 1 ) %then %let closeExcel	=	1;
	%if %STXR_among( %upcase( %substr( &printDATLBL., 1, 1 ) ), Y T 1 ) %then %let printHeaders	=	1;

	%* The parameters &TMPLPATH and &TMPLNAME should be used in conjunction with each      ;
	%* other. Check if this is the case. When necessary, reset both to a null value.       ;
	%if
		( ( %nrbquote(&tmplpath.) EQ ) and ( %nrbquote(&tmplname.) ne ) )
		or ( ( %nrbquote(&tmplpath.) ne ) and ( %nrbquote(&tmplname.) EQ ) )
		%then %do;
		%let	tmplpath	=;
		%let	tmplname	=;
		options notes;
		%put;
		%put	&sasnote.: [&L_mcrLABEL.]During invocation of the EXPORTTOEXCEL macro, either the parameter;
		%put	----- TMPLPATH was specified without TMPLNAME, or vice versa. The macro expects either;
		%put	----- both or none of them. They have been reset to a null value to allow macro execution.;
		%put;
		options nonotes;
	%end;

	%if ~( ( %nrbquote(&tmplpath.) EQ ) and ( %nrbquote(&tmplname.) EQ ) )
		and %sysfunc( fileexist( &tmplpath\&tmplname.&EnviroEXT. ) ) = 0
		%then %do;
		options notes;
		%put;
		%put	&sasnote.: [&L_mcrLABEL.]The template file "&tmplpath\&tmplname.&EnviroEXT." does not exist!;
		%put;
		%let	misspar		=	1;
		%let	tmplpath	=;
		%let	tmplname	=;
		options nonotes;
	%end;

    %theend:
	%*Free the memory;
	%syscall PRXFREE(PRXID);

%mend STXR_checkParms;