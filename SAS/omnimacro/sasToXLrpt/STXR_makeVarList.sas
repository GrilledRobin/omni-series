%* For a PUT statement within %STXR_DumpDAT, this macro makes a blank-separated list of     ;
%* variables separated by &TABs (repeated as many times as dictated by &MERGEACROSS),    ;
%* called &VARLIST.                                                                      ;


%macro STXR_makeVarList;

%local ii jj;

%*-> 20170113 Modified by Lu Robin Bin.;
%*This is to eliminate the period sign (.) to be put via DDE when there is missing value;
%* in the numeric variable.;
array
	arrBLANK{&ncols.}
	$1024.
	_temporary_
;
%do ii=1 %to &ncols.;
	if	vtype(%scan( &vars., &ii. ))	=	"N"	then do;
		arrBLANK{&ii.}	=	ifc(missing(%scan( &vars., &ii. )),"",strip(%scan( &vars., &ii. )));
	end;
	else do;
		arrBLANK{&ii.}	=	ifc(missing(%scan( &vars., &ii. )),"",%scan( &vars., &ii. ));
	end;
%end;

put
%do ii=1 %to &ncols.;
	%if &ii. ne &ncols. %then %do;
		arrBLANK{&ii.} + ( -1 )
%*		%do jj=1 %to &mergeacross;
			&tab.
%*		%end;
	%end;
	%else %do;
		arrBLANK{&ii.} + ( -1 )
	%end;
%end;
;
%*<- 20170113 Modified by Lu Robin Bin.;

%mend STXR_makeVarList;

