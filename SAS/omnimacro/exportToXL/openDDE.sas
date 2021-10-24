%* Opens Excel and sets up a DDE dialogue with it.                                       ;
%* Idea from Chris Roper (2000): 'Intelligently Launching Microsoft Excel from SAS,      ;
%* using SCL functions ported to Base SAS'.											     ;


%macro openDDE;

  %* Establishes a DDE link to Excel.                                                    ;
  filename sas2xl dde 'excel|system';

  %* Establishes a DDE link to Excel topics, to be used later.                           ;
  filename xltopics dde 'excel|system!topics' lrecl=32000;

  data _null_;
	length fid rc start stop time 8.;
    fid = fopen( 'sas2xl', 's' );  
    if ( fid le 0 ) then do;
      rc = system( 'start excel' );    
		%* Starts Excel.                                                                 ;
      start = datetime();
      stop = start + 10;
      do while( fid le 0 );         
		%* If not yet opened.                                                            ;
        fid = fopen( 'sas2xl', 's' ); 
		  %* Opens an external file in sequential input mode.                            ;
        time = datetime();
        if ( time ge stop ) then fid = 1;
        end;
      end;
    rc = fclose( fid );              
	  %* Closes ddecmds, not Excel.                                                      ;
  run;

%mend openDDE;
