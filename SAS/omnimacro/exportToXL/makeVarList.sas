%* For a PUT statement within %INPUTDATA, this macro makes a blank-separated list of     ;
%* variables separated by &TABs (repeated as many times as dictated by &MERGEACROSS),    ;
%* called &VARLIST.                                                                      ;


%macro makeVarList;

  %local ii jj;

  %do ii=1 %to &ncols;
	%if &ii ne &ncols %then %do; %scan( &vars, &ii ) +(-1) %do jj=1 %to &mergeacross; &tab %end;   
	  %end;                                    
	%else %scan( &vars, &ii ) +(-1);
	%end;                                       

%mend makeVarList;  

