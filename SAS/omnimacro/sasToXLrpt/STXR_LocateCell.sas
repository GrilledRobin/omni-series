%* Retrieve the precise location of each marker.                                ;


%macro STXR_LocateCell;
	%local
		varclean
		hdrcnt
		hdrelt
		HDRTTL
		Loutfl
		SHi
		VARi
		HDRi
		LptnHDR
		PTNi
		varcleanD
		hdrcntD
		hdreltD
		HDRTTLD
		LptnDAT
		PTNj
		LnPOS
	;

	%let	Loutfl	=	&savepath.\&savename.&EnviroEXT.;
	%let	LnPOS	=	4;

	%* Define element list of "&varhdr.";
	%let	varclean	=	%sysfunc(compbl(&varheader.));
	%let	hdrcnt		=	1;
	%let	hdrelt		=	%QSCAN(&varclean.,&hdrcnt.,%STR( ));
	%local	HDR1;
	%let	HDR1		=	%substr(&hdrelt.,1);
	%DO %WHILE(&hdrelt.	NE);
		%let	hdrcnt	=	%EVAL(&hdrcnt.+1);
		%let	hdrelt	=	%QSCAN(&varclean.,&hdrcnt.,%STR( ));
		%if	&hdrelt.	EQ	%then	%goto	endLoopHDR;
		%local	HDR&hdrcnt.;
		%let	HDR&hdrcnt.	=	%substr(&hdrelt.,1);
	%END;
	%endLoopHDR:
	%let	HDRTTL=%EVAL(&hdrcnt.-1);

	%* Prepare the pattern for match-finding of all locators.;
	%let	LptnHDR	=;
	%do	PTNi=1	%to	&HDRTTL.;
		%let	LptnHDR	=	&LptnHDR.|&&HDR&PTNi..;
	%end;
	%let	LptnHDR	=	%qsubstr(&LptnHDR.,2);

	%* Define element list of "&exChkStrDat.";
	%let	varcleanD	=	%sysfunc(compbl(&exChkStrDat.));
	%let	hdrcntD		=	1;
	%let	hdreltD		=	%QSCAN(&varcleanD.,&hdrcntD.,%STR( ));
	%local	HDRD1;
	%let	HDRD1		=	%substr(&hdreltD.,1);
	%DO %WHILE(&hdreltD. NE);
		%let	hdrcntD	=	%EVAL(&hdrcntD.+1);
		%let	hdreltD	=	%QSCAN(&varcleanD.,&hdrcntD.,%STR( ));
		%if	&hdreltD.	EQ	%then	%goto	endLoopDAT;
		%local	HDRD&hdrcntD.;
		%let	HDRD&hdrcntD.	=	%substr(&hdreltD.,1);
	%END;
	%endLoopDAT:
	%let	HDRDTTL=%EVAL(&hdrcntD.-1);

	%* Prepare the pattern for match-finding of all Data-indicating locators.;
	%let	LptnDAT	=;
	%do	PTNj=1	%to	&HDRDTTL.;
		%let	LptnDAT	=	&LptnDAT.|&&HDRD&PTNj..;
	%end;
	%let	LptnDAT	=	%qsubstr(&LptnDAT.,2);

	%* Import all the sheets for later identification of the locators.;
	DATA _NULL_;
		SET exr_WORK._tmp_xlinf END=EOF;
		length
			tmp_len		$16.
			tmp_var		$16.
		;
		%*Here we cannot use CATS, for the could be trailing blanks in the sheet names.;
		CALL SYMPUTX(cats("L_WSRNG",_N_),"&savepath.\[&savename.&EnviroEXT.]"||substr(sheet,1,LenShNm)||cats("!r1c1:r",rows,"c",columns),"L");
		%*Here we cannot use SYMPUTX, for it removes the trailing blanks from the value.;
		%*However, currently we still cannot setup valid DDE session to the sheet whose name has trailing blanks.;
		CALL SYMPUT(cats("L_WSNM",_N_),substr(sheet,1,LenShNm));
		CALL SYMPUTX(cats("L_WSLENNM",_N_),LenShNm,"L");
		CALL SYMPUTX(cats("L_WSNCOL",_N_),columns,"L");
		do tmpi=1 to columns;
			tmp_len	=	cats(repeat("0",&LnPOS.),tmpi);
			tmp_var	=	substr(tmp_len,length(tmp_len)-&LnPOS.+1);
			CALL SYMPUTX(cats("L_WSRNG",_N_,"VAR",tmpi),cats("var",tmp_var),"L");
		end;
		IF EOF THEN CALL SYMPUTX("nsheets",_N_);
	RUN;

	%do	SHi=1	%to	&nsheets.;
		%*100.	Import each sheet.;
		filename
			tmploc
			dde
			"excel|&&L_WSRNG&SHi.."
		;

		%*200.	Retrieve position information of the locators.;
		data exr_WORK.__DefTplLoc&SHi.;
			%*100.	Input all fields.;
			infile
				tmploc
				notab
				dsd
				dlm='09'x
				missover
				end=EOF
			;
			length
				%do	VARi=1	%to	&&L_WSNCOL&SHi..;
					&&L_WSRNG&SHi.VAR&VARi..	$1024.
				%end;
			;
			input
				%do	VARi=1	%to	&&L_WSNCOL&SHi..;
					&&L_WSRNG&SHi.VAR&VARi..
				%end;
			;

			%*100.	Create arrays.;
			%*110.	Array of all fields in the imported sheet.;
			array
				arrVAR
				%do	VARi=1	%to	&&L_WSNCOL&SHi..;
					&&L_WSRNG&SHi.VAR&VARi..
				%end;
			;

			%*200.	Create necessary fields.;
			%*Please note the sequence of below statments against the above ones.;
			format
				varToWS		$128.
				ToWSLenNM	8.
				Gvar		$64.
				VarTP		$8.
				varrown		8.
				varcoln		8.
			;
			length
				varToWS		$128.
				Gvar		$64.
				VarTP		$8.
			;

			%*300.	Prepare the match rules.;
			retain	rxHDR rxDAT;
			if	_N_	=	1	then do;
				rxHDR	=	prxparse("/^(&LptnHDR.).*$/i");
				rxDAT	=	prxparse("/^(&LptnDAT.).*$/i");
			end;

			%*400.	Find all marks which match the given patterns.;
			do tmpi=1 to dim(arrVAR);
				if	prxmatch(rxHDR,arrVAR{tmpi})	then do;
					varToWS		=	"%nrbquote(&&L_WSNM&SHi..)";
					ToWSLenNM	=	&&L_WSLENNM&SHi..;
					Gvar		=	trim(left(arrVAR{tmpi}));
					if	prxmatch(rxDAT,arrVAR{tmpi})	then do;
						VarTP	=	"DAT";
					end;
					else do;
						VarTP	=	"FLD";
					end;
					varrown		=	_N_;
					varcoln		=	tmpi;
					output;
				end;
			end;

			%*900.	Purge the memory;
			if	EOF	then do;
				call prxfree(rxHDR);
				call prxfree(rxDAT);
			end;
			keep
				varToWS
				ToWSLenNM
				Gvar
				VarTP
				varrown
				varcoln
			;
		run;
	%end;

	%* Clearings.;
	filename	tmploc	clear;

	%* Gather all findings.;
	data exr_WORK.xlvartbl;
		set
			%do	SHi=1	%to	&nsheets.;
				exr_WORK.__DefTplLoc&SHi.
			%end;
		;
	run;

%EndOfProc:
%mend STXR_LocateCell;