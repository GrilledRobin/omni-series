%let	home	=	X:\SAS_report\1298609\Quarterly_500_SIP_Platform_new\PGM;
%let	infdr	=	&home.\0010ARMCrDB;
%let	flin	=	101_get_CUS_cond.sas;
%let	flout	=	C:\www\AutoReports\Quarterly_500_SIP_Platform_new\Document\remarks.txt;

data _temp_;
	infile
		"&infdr.\&flin."
		end=EOF
	;
	file	"&flout.";
	input;

	%*010.	Parameter setup.;
	length
		line		$512.
	;
	line	=	_infile_;

	%*011.	Create the header for summary file.;
	if	_N_	=	1	then do;
		put	"[File Name:]";
		put	"&flin.";
	end;

	%*020.	Mark the macro beginning.;
	length
		nam_mcr	$32.
	;
	retain
		ptn_mBGN
		ptn_mEND
		switch_ptn_mEND
		nam_mcr
		mk_mBGN
		mk_mEND
	;
	if	_N_	=	1	then do;
		ptn_mBGN	=	prxparse('/%macro\s+[[:ALPHA:]]\w*?;.*$/i');
		%*Below field is to restrict the parse from being done over records, hence reduce the memory consumption.;
		switch_ptn_mEND	=	1;
		mk_mBGN	=	0;
		mk_mEND	=	0;
	end;
	if	prxmatch(ptn_mBGN,line)	=	1	then do;
		nam_mcr	=	prxchange('s/%macro\s+([[:ALPHA:]]\w*?);.*$/$1/i',-1,line);
		mk_mBGN	=	1;
	end;

	%*030.	Mark the macro end.;
	if	missing(nam_mcr)	=	0	then do;
		switch_ptn_mEND	=	(switch_ptn_mEND	=	1);
		if	switch_ptn_mEND	then do;
			ptn_mEND	=	prxparse(cats('/%mend\s+',nam_mcr,';.*$/i'));
			switch_ptn_mEND	=	not	(switch_ptn_mEND);
		end;
		if	prxmatch(ptn_mEND,line)	=	1	then do;
			mk_mEND	=	1;
		end;
	end;

	%*040.	Parse the retrieval of necessary contents.;
	retain
		switch_put_src
		switch_put_out
		switch_put_ann	%*Annotations;
		ptn_src
		sub_src
		ptn_out
		sub_out
		ptn_ann
		sub_ann
		tab_ann
	;
	length
		wrt	$512.
	;
	n_lvl	=	0;
	if	_N_	=	1	then do;
		switch_put_src	=	1;
		switch_put_out	=	1;
		switch_put_ann	=	1;
		ptn_src	=	prxparse('/%let\s+L_srcflnm\d*\s*=\s*(.+?);.*$/i');
		sub_src	=	prxparse('s/%let\s+L_srcflnm\d*\s*=\s*(.+?);.*$/$1/i');
		ptn_out	=	prxparse('/%let\s+L_stpflnm\d*\s*=\s*(.+?);.*$/i');
		sub_out	=	prxparse('s/%let\s+L_stpflnm\d*\s*=\s*(.+?);.*$/$1/i');
		ptn_ann	=	prxparse('/^\t*%\*\d{3}\.*\s+(.+?);/i');
		sub_ann	=	prxparse('s/^\t*%\*(\d{3}\.*)\s+(.+?);.*$/$1$2/i');
		tab_ann	=	prxparse('s/^(\t*)%\*\d{3}\.*\s+.+?;.*$/$1/i');
	end;

	%*100.	Source data and output data.;
	if	mk_mBGN	=	0	then do;
		if	prxmatch(ptn_src,line)	=	1	then do;
			switch_put_src	=	(switch_put_src	=	1);
			if	switch_put_src	then do;
				put;
				put	"[Source Data:]";
				switch_put_src	=	not	(switch_put_src);
			end;
			wrt	=	prxchange(sub_src,-1,line);
			put	wrt;
		end;
		if	prxmatch(ptn_out,line)	=	1	then do;
			switch_put_out	=	(switch_put_out	=	1);
			if	switch_put_out	then do;
				put;
				put	"[Output Data:]";
				switch_put_out	=	not	(switch_put_out);
			end;
			wrt	=	prxchange(sub_out,-1,line);
			put	wrt;
		end;
	end;

	%*200.	Retrieve annotations.;
	if	mk_mBGN	=	1	then do;
		if	mk_mEND	=	0	then do;
			if	prxmatch(ptn_ann,line)	=	1	then do;
				switch_put_ann	=	(switch_put_ann	=	1);
				if	switch_put_ann	then do;
					put;
					put	"[Annotation:]";
					switch_put_ann	=	not	(switch_put_ann);
				end;
				n_lvl	=	countc(prxchange(tab_ann,-1,line),'09'x);
				wrt	=	prxchange(sub_ann,-1,line);
				if	n_lvl	>	1	then do;
					wrt	=	repeat("-",(n_lvl - 1) * 4 - 1)||wrt;
				end;
				put	wrt;
			end;
		end;
	end;

	%*990.	Free memory.;
	if	EOF	then do;
		call prxfree(ptn_mBGN);
		call prxfree(ptn_mEND);
		call prxfree(ptn_src);
		call prxfree(sub_src);
		call prxfree(ptn_out);
		call prxfree(sub_out);
		call prxfree(ptn_ann);
		call prxfree(sub_ann);
		call prxfree(tab_ann);
	end;
run;
