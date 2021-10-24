%macro droptbl(dsntp=,indsn=,indat=);
	%local
		i
	;

	%genvarlist(
		nstart=1
		,inlst=&indat.
	)
	%if	%bquote(&dsntp.)	EQ	%then %let	dsntp	=	SASDATA;
		%else %if	%index(%upcase(&dsntp.),SQL)	^=	0	%then %let	dsntp	=	SQLDATA;
		%else %if	%index(%upcase(&dsntp.),SAS)	^=	0	%then %let	dsntp	=	SASDATA;
	%if	%upcase(&dsntp.)	=	%str(SASDATA)	%then %do;
		%if	%bquote(&indsn.)	NE	%then %do;
			proc datasets library = &indsn.;
				delete
					%DO I=1 %TO &LTOTAL.;
						&&NLST&I..
					%END;
				;
			quit;
		%end;
	%end;
	%else %if	%upcase(&dsntp.)	=	%str(SQLDATA)	%then %do;
		%if	%bquote(&indsn.)	NE	%then %do;
			%let	indsn	=	&indsn..;
			%DO I=1 %TO &LTOTAL.;
				%let	tblxst=;
				proc sql noprint;
					select 1
					into :tblxst
					from &indsn.sysobjects
					where name=upcase("&&NLST&I..");
				quit;
				%if	%bquote(&tblxst.)	NE	%then %do;
					proc sql;
						drop table &indsn.&&NLST&I..;
					quit;
				%end;
			%END;
		%end;
	%end;
%mend;