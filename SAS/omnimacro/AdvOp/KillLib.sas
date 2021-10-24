%macro KillLib(
	inLIB	=
);
proc datasets
	lib		=	&inLIB.
	nolist
	nowarn
	kill
;
run;
quit;
%mend KillLib;