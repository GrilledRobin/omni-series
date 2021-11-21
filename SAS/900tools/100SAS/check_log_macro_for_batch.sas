/*___________________________________________________________________________
   JOB:     Macro  - Log Check
   PURPOSE: Reads log for active job and reports issues
   AUTHOR:  BI NOTES BLOG (http://www.bi-note.com)
   DATE:    MARCH 2011
= NOTES ========================================================

This code is provided with no warranty or support. Use or change as meets your needs.
================================================================
Requirements:
 Your need to have emails set up in your system
 The code you are checking must include the LogCheck macro and pass the logname variable.
______________________________________________________________________________*/
options mprint symbolgen mlogic;	


%let email= your.email.address@company.com;  /*===================================================Put Your Email Here*/


%macro logcheck(logname);
%put &logname.;

	/*Number the Issues and Apply Format to get Proper Sort in Email */
        proc format;
            value Typefm 1 = 'Error'
                         2 = 'Warning'
                         3 = 'Spec. Notes'
                         4 = 'Note'
                         5 = 'Datetime';
        run;
 
     /*Import the LOG FILE                                          */
	 /*  This code could be updated to get all logs in a directory	 */
	 /*                                                            */
		filename CHKLOG "&logname.";

         data CheckTheLog;
          length filename $100.;
          attrib logname length=$50             label='Log File Name'
                 txt     length=$256            label='Original SAS Log message'
                 linum   length=8    format=8.  label='Line # in~SAS LOG'
                 type    length=8               label='Type'
        ;
 
          infile CHKLOG  filename=filename lrecl=200 pad END=eof;
 
          INPUT @1 getline $200.;
          logname =strip(tranwrd(scan(filename,-1,'/'),'.log',''));
          intext = SUBSTR(upcase(getline), 1, 199);
 
          linum + 1;
          CTR=1;
 
        if index(intext, 'ERROR:')>0 then do;
                Type = 1;
                txt = substr(intext, 8);
                output;
            end;

        else if index(intext, 'WARNING:')>0 then do;
            Type = 2;
            txt = substr(intext, 10);
            output;
        end;        

      else if index(substr(intext,1, 16),'PASS HEADER DATE')>0
                  then do;
                  type=5;
                  txt = scan(intext,1,"=");
                  output;
       end;

           else  if index(intext, 'NOTE:')>0 then do;
 				/*Update or remove from this list as makes sense to you - ALL CAPS!*/
                    IF INDEX(INTEXT, 'INVALID') > 0 OR
                        INDEX(INTEXT, 'W.D FORMAT') > 0 OR
                        INDEX(INTEXT, 'IS UNINITIALIZED') > 0 OR
                        INDEX(INTEXT, 'REPEATS OF BY VALUES') > 0 OR
                        INDEX(INTEXT, 'MATHEMATICAL OPERATIONS COULD NOT') > 0 OR
                        INDEX(INTEXT, 'MISSING VALUES WERE') > 0 OR
                        INDEX(INTEXT, 'DIVISION BY ZERO') > 0 OR
                        INDEX(INTEXT, 'MERGE STATEMENT') > 0 OR
                        INDEX(INTEXT, 'CHARACTER VALUES HAVE') > 0 OR
                        INDEX(INTEXT, 'VALUES HAVE BEEN CONVERTED') > 0 OR
                        INDEX(INTEXT, 'INTERACTIVITY DISABLED WITH') > 0 OR
                        INDEX(INTEXT, 'NO OBSERVATION') > 0
	             then do;
	                Type = 4;
	                txt = substr(intext, 7);
	                output;
	              end;
		    end;
/*===========================================*/
/*===========================================*/
/*Any notes you want to trap - use this area */
/*===========================================*/
	if index(intext, 'NOTE:')>0 
			and index(intext, "STOPPED PROCESSING")
			then do;
				TYPE=3;
 				txt = substr(intext, 50);
	            output;
			end;
  DROP  getline eof ;
  run;
 
 
/* In some cases - you have known issues that are not actual errors      */
/* Use this area to recode those errors as Notes or Delete the lines     */

        data logcheck;
        set CheckTheLog;
		/* TERADATA ISSUES THIS WARNING WHEN CLEARS TABLE	 */
		 if index(txt,'TABLE') gt 0
                and index(txt,'HAS NOT BEEN DROPPED') gt 0
                and type=2
                            then type=4;
        run;

	proc print data=logcheck;
	run;

/*Count the total messages for each type to have for the Email Subject Line*/
 proc sql noprint; 
	select put(count(type), 2.) into: ERROR from logcheck where type = 1; 	
	select put(count(type), 2.) into: WARN  from logcheck where type = 2; 	
	select put(count(type), 2.) into: NOTES from logcheck where type in (3,4); 	
	select count(type) into: JobRanNoIssues from logcheck where type ne 5; 	

quit;

/*Email the Report to User */

%if &JobRanNoIssues. le 1 %then %do;

   FILENAME OutBox EMAIL 
   		"&EMAIL."
		subject="Log Check &LogName.: ==No Issues==";
	data _null_;
	file outbox;
	put "No issues to report for &LOGNAME.";
	put "Errors: &ERROR. Warnings: &WARN Notes: &notes.";
	run;

%end;

%else %do;

   FILENAME OutBox EMAIL type='text/html'
   		to=("&EMAIL.")
		subject="Log Check &LogName. ERROR: &ERROR. WARN: &WARN NOTE: &notes."
/*Remove this line if you want to attach the log to the email*/
	/*		attach="&logname."*/
	;

	ods html body=outbox rs=none style=printer;

        title 'Log Check Results';
        title2 "Run date: &SYSDATE.";
        proc report data=logcheck  nowd split='~';
        format type typefm.;
        column logname type linum txt;
        define type / order=formatted 'Type' ;
        define  linum / display  ;
        define txt / display width=80 flow ;
            compute txt;
            if type.sum = 1 then do;
                call define(_COL_,'style','style=[background=INDIANRED]');
           end;
            else if type.sum = 2 then do;
                   call define(_COL_,'style','style=[background=#FFD700]');
                    end;
            else if type.sum in (3, 4) then do;
                   call define(_COL_,'style','style=[background=POWDERBLUE]');
                    end;
             else if type.sum = 5
                         then do;
            call define(_ROW_,'style','style=[background=#D3D3D3 font_style=italic]');
            end;
            endcomp;
        run;
 
	ods html close;

%end;

%mend;
 
 
/* END OF CODE*/
