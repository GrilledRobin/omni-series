%* Closes the file and the DDE connection.                                               ;


%macro STXR_closeDDE;

	%if &misspar. = 1 %then %goto jump;

	%*100.	Save the file as a temporary one.;
	data _null_;
		length ddecmd $ 200;
		file sas2xl;
		put "[&error.(&false.)]";
		ddecmd = "[&saveas."||'("'||"&savepath."||'\'||"&savename.tmp&EnviroEXT."||'")]';
		put ddecmd;
		put "[&fileclose.(&false.)]";
		%if &closeExcel. = 1 %then %do;
			put "[&quit.()]";
		%end;
	run;

	%*200.	Remove the original desitination file and rename the temporary file.;
	options noxwait xsync;
	%local
		Ltmpfl
		Ltmpflupd
	;
	%let	Ltmpfl		=	&savename.&EnviroEXT.;
	%let	Ltmpflupd	=	&savename.tmp&EnviroEXT.;
	x "cd ""&savepath.""";
	x "del /Q ""&Ltmpfl.""";
	x "ren ""&Ltmpflupd."" ""&Ltmpfl.""";

	%*900.	Upon exiting the macro, we restore all the system options we turned off earlier.;
	%jump:

	%* Check if the macro actually executed some code (&MISSPAR=0) or if we got here       ;
	%* because of lacking parameter errors (&MISSPAR=1).                                   ;
	%if &misspar = 0 %then %do;

		options nonotes;

		%* Clean up remaining junk in the local SAS session.                                 ;
		proc datasets
			library=exr_WORK
			nolist
			nowarn
			kill
		;
		run;
		quit;

		filename	sas2xl		clear;
		filename	xltopics	clear;

	%end;

	%if &cnotes.   %then options notes;
	%if &csource.  %then options source;
	%if &csource2. %then options source2;
	%if &cmlogic.  %then options mlogic;
	%if &csymbolg. %then options symbolgen;
	%if &cmprint.  %then options mprint;

%mend STXR_closeDDE;