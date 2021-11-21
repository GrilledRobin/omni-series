%macro ecLog;
%*100.	Prepare the system.;
%*110.	Parameters.;
%*111.	Usually this part is passed from outsourced files.;
/*->Begin Block (Remove the following WHITE SPACE to un-comment the block)* /
%let	G_PATH_LOGCHK	=	C:\www\AutoReports\900tools\100SAS;
%let	LOG_NAME	=	X:\SAS_report\1298609\020201\notes_cn.log;
%let	RST_NAME	=	&G_PATH_LOGCHK.\a.txt;
%let	F_SENDEMAIL	=	0;
%let	G_email		=	your.email.address@company.com;
%let	G_ENC_LOG	=	euc-cn;
%let	G_JOB_NAME	=	SIP Platform;
/*<-End Block */

%*112.	Specify the log file name.;
%let	L_LOGNM	=	%qscan(%nrbquote(&LOG_NAME.),-1,%str(\/));

%*150.	Load all language files.;
%local
	L_DOScmd
	Fi
;
data _NULL_;
	cmd	=	"'dir /A-D /B """||"&G_PATH_LOGCHK."||'"''';
	call symput("L_DOScmd",cmd);
run;
filename	cLang	pipe	&L_DOScmd.;
data _NULL_;
	infile
		cLang
		truncover
		end=EOF
	;
	length
		langfile	$512.
		tmpEnc		$32.
	;
	input;
	langfile	=	strip(_infile_);
	retain
		prxM	%*PRX for Match;
		prxL	%*PRX for Language;
		prxE	%*PRX for Encoding;
		Fi
	;
	if	_N_	=	1	then do;
		%*The naming convetion is: "ecLang_<Lang-Short-Name>_<SAS-Encoding-Code>.sas",;
		%* where <Lang-Short-Name> should be unique and cannot contain underscores "_".;
		%*The macros stored in the language files have the naming convention as:;
		%* "ecLang_<Lang-Short-Name>".;
		prxM	=	prxparse('/^ecLang_.+\.sas$/i');
		prxL	=	prxparse('s/^([^_]+?_[^_]+?)_.+\.sas$/\1/i');
		prxE	=	prxparse('s/^[^_]+?_[^_]+?_(.+)\.sas$/\1/i');
		Fi		=	0;
	end;
	if	prxmatch(prxM, strip(langfile))	then do;
		Fi	+	1;
		call symputx(cats("LeLangFile",Fi),strip(langfile),"L");
		call symputx(cats("LeLangMac",Fi),prxchange(prxL,1,strip(langfile)),"L");
		call symputx(cats("LeLangName",Fi),scan(strip(prxchange(prxL,1,strip(langfile))),-1,"_"),"L");
		tmpEnc	=	prxchange(prxE,1,strip(langfile));
		if	upcase(tmpEnc)	=	"GB2312"	then do;
			call symputx(cats("LeLangEnc",Fi),"euc-cn","L");
		end;
		else do;
			call symputx(cats("LeLangEnc",Fi),tmpEnc,"L");
		end;
	end;
	if	EOF	then do;
		call symputx("LnLangFile",Fi,"L");
		call prxfree(prxM);
		call prxfree(prxL);
		call prxfree(prxE);
	end;
run;
%do	Fi	=	1	%to	&LnLangFile.;
	filename	tmplang	"&G_PATH_LOGCHK.\&&LeLangFile&Fi.."	encoding="&&LeLangEnc&Fi..";
	%include	tmplang;
	%&&LeLangMac&Fi..
%end;

%*180.	Initialization.;
%*Note: We should use "INFILE" to read the source file, rather than DOS pipe,;
%* for the source file could be of the CharSet or Code Page other than MS-DOS.;
%*181.	Create necessary formats.;
proc format;
	%*100.	Number the Issues and Apply Format to get Proper Sort in Email.;
	value ec_Typefm
		1	=	'Error'
		2	=	'Warning'
		3	=	'Spec. Notes'
		4	=	'Note'
		5	=	'Datetime'
	;

	%*200.	Short Names for the system messages.;
	value $ec_LangEXP(min=128)
		%*100.	Warnings to be excluded.;
		'Lec_WN_SasUserReg'	=	'Unable to copy SASUSER registry to WORK registry'
		'Lec_WN_NoRegCust'	=	'you will not see registry customizations during this session'
		'Lec_WN_SysSchExp'	=	'system is scheduled to expire'
		'Lec_WN_BasSchExp'	=	'The Base Product product is going to expire by license'
		'Lec_WN_BasSchExp1'	=	'(Continued) in warning mode to indicate the upcoming expiration'
		'Lec_WN_BasSchExp2'	=	'(Continued) more information on your warning period'

		%*200.	Notes to be captured.;
		'Lec_NT_VarUnini'	=	'Some variables are uninitialized'
		'Lec_NT_PassHdrDt'	=	'PASS HEADER, date'
		'Lec_NT_Invalid'	=	'Invalid values'
		'Lec_NT_WDFormat'	=	'W.D Format is used'
		'Lec_NT_RepeatBy'	=	'Repeats of By values'
		'Lec_NT_MathOps'	=	'Mathematical operations could not be used'
		'Lec_NT_GenMissVal'	=	'Missing values are generated'
		'Lec_NT_DivideBy0'	=	'Division by zero'
		'Lec_NT_MergeStmt'	=	'Merge statement is not properly used'
		'Lec_NT_ProcChar'	=	'Character values have been automatically processed'
		'Lec_NT_ConvVal'	=	'Character or numeric values have been converted'
		'Lec_NT_DisableItv'	=	'Interactivity is disabled'
		'Lec_NT_ProcNoObs'	=	'No observation is found during Data or Proc step'
		'Lec_NT_ProcStop'	=	'Processing is abnormally stopped'

		%*300.	Errors to be excluded.;
		'Lec_ER_ExpectPg1'	=	'SASUSER.CATALOG is not available, expecting page 1 to create'
		'Lec_ER_PgVldFail'	=	'Page validation error while reading SASUSER.PROFILE.CATALOG.'
	;
run;

%*185.	Prepare the access to the log file.;
filename	CHKLOG	"&LOG_NAME." encoding="&G_ENC_LOG.";
filename	CHKOUT	"&RST_NAME." encoding="&G_ENC_LOG.";

%*200.	Analyze the log file.;
%*210.	Read and flag the lines.;
data CheckTheLog;
	%*100.	Initialize the fields.;
	%*Below field does not have to be dropped as it acts as a temporary one in the INFILE statement.;
	length
		finput	$512.
	;
	attrib
		logname	length=$80				label='Log File Name'
		c_msg	length=$32				label='Message to be put in the analysis result'
		txt		length=$256				label='Original SAS Log message'
		linum	length=8	format=8.	label='Line # in~SAS LOG'
		type	length=8				label='Type'
	;

	%*200.	Input the log file.;
	infile
		CHKLOG
		filename	=	finput
		lrecl		=	200
		pad
		END			=	eof
	;
	length	getline	$256.;
	input;
	getline	=	strip(_infile_);

	%*300.	Format the information.;
	%*310.	Retrieve the correct log file name.;
	retain
		logname
	;
	if	_N_	=	1	then do;
		logname	=	"&L_LOGNM.";
		linum	=	0;
	end;

	%*320.	Initialization.;
	intext	=	upcase(getline);
	linum	+	1;
	CTR		=	1;

	%*330.	Segment the information.;
	%*331.	Warnings.;
	if index(intext, 'WARNING:')	=	1	then do;
		Type	=	2;
		c_msg	=	"[SASWARNING]:";
		txt		=	substr(intext, 10);
		output;
	end;

	%*332.	Pass Header information.;
	else if	0
	%do Fi=1 %to &LnLangFile.;
		or	index(intext,strip("&&&&Lec_NT_PassHdrDt_&&LeLangName&Fi..."))	=	1
	%end;
		then do;
		type	=	5;
		c_msg	=	"[SASSPEC]:";
		txt		=	scan(intext,1,"=");
		output;
	end;

	%*333.	Universal abnormal notes.;
	%*Update or remove from this list as makes sense to you - ALL CAPS!;
	else  if index(intext, 'NOTE:')	=	1	then do;
		if	0
		%do Fi=1 %to &LnLangFile.;
			or	index(intext,strip("&&&&Lec_NT_Invalid_&&LeLangName&Fi..."))	>	0
			or	index(intext,strip("&&&&Lec_NT_WDFormat_&&LeLangName&Fi..."))	>	0
			or	index(intext,strip("&&&&Lec_NT_VarUnini_&&LeLangName&Fi..."))	>	0
			or	index(intext,strip("&&&&Lec_NT_RepeatBy_&&LeLangName&Fi..."))	>	0
			or	index(intext,strip("&&&&Lec_NT_MathOps_&&LeLangName&Fi..."))	>	0
			or	index(intext,strip("&&&&Lec_NT_GenMissVal_&&LeLangName&Fi..."))	>	0
			or	index(intext,strip("&&&&Lec_NT_DivideBy0_&&LeLangName&Fi..."))	>	0
			or	index(intext,strip("&&&&Lec_NT_MergeStmt_&&LeLangName&Fi..."))	>	0
/*			or	index(intext,strip("&&&&Lec_NT_ProcChar_&&LeLangName&Fi..."))	>	0
			or	index(intext,strip("&&&&Lec_NT_ConvVal&&LeLangName&Fi..."))		>	0
*/			or	index(intext,strip("&&&&Lec_NT_DisableItv_&&LeLangName&Fi..."))	>	0
			or	index(intext,strip("&&&&Lec_NT_ProcNoObs_&&LeLangName&Fi..."))	>	0
		%end;
		then do;
			Type	=	4;
			c_msg	=	"[SASSPEC]:";
			txt		=	substr(intext, 7);
			output;
		end;
	end;

	%*334.	User defined messages to be spotted.;
	if index(intext, 'NOTE:')	=	1	then do;
		if	0
		%do Fi=1 %to &LnLangFile.;
			or	index(intext,strip("&&&&Lec_NT_ProcStop_&&LeLangName&Fi..."))	>	0
		%end;
			then do;
			TYPE	=	3;
			c_msg	=	"[SASSPEC]:";
			txt		=	substr(intext, 7);
			output;
		end;
	end;

	%*339.	Errors.;
	if index(intext, 'ERROR:')	=	1	then do;
		Type	=	1;
		c_msg	=	"[SASERROR]:";
		txt		=	substr(intext, 8);
		output;
	end;

	%*900.	Cleansing.;
	DROP
		getline
	;
run;

%*290.	Modify the flags as per user requirement.;
%* In some cases - you have known issues that are not actual errors;
%* Use this area to recode those errors as Notes or Delete the lines;
data logcheck;
	set CheckTheLog;
/*	%*100.	TERADATA ISSUES THIS WARNING WHEN CLEARS TABLE;
	if		index(txt,'TABLE') gt 0
		and	index(txt,'HAS NOT BEEN DROPPED') gt 0
		and	type=2
		then do;
		c_msg	=	"[SASSPEC]:";
		type	=	4;
	end;
*/
	%*200.	Warning messages regarding system expiration can be excluded.;
	if	type	=	2
		and	(0
			%do Fi=1 %to &LnLangFile.;
				or	index(intext,strip("&&&&Lec_WN_SasUserReg_&&LeLangName&Fi..."))	>	0
				or	index(intext,strip("&&&&Lec_WN_NoRegCust_&&LeLangName&Fi..."))	>	0
				or	index(intext,strip("&&&&Lec_WN_SysSchExp_&&LeLangName&Fi..."))	>	0
				or	index(intext,strip("&&&&Lec_WN_BasSchExp_&&LeLangName&Fi..."))	>	0
				or	index(intext,strip("&&&&Lec_WN_BasSchExp1_&&LeLangName&Fi..."))	>	0
				or	index(intext,strip("&&&&Lec_WN_BasSchExp2_&&LeLangName&Fi..."))	>	0
			%end;
		)
		then do;
		c_msg	=	"[SASSPEC]:";
		type	=	4;
		delete;
	end;

	%*300.	Error messages regarding user authentication can be excluded.;
	if	type	=	1
		and	(0
			%do Fi=1 %to &LnLangFile.;
				or	index(intext,strip("&&&&Lec_ER_ExpectPg1_&&LeLangName&Fi..."))	>	0
				or	index(intext,strip("&&&&Lec_ER_PgVldFail_&&LeLangName&Fi..."))	>	0
			%end;
		)
		then do;
		c_msg	=	"[SASSPEC]:";
		type	=	4;
		delete;
	end;

	%*900.	You can stop the process when encountering the FIRST error message,;
	%* as all the processes AFTERWARDS could have unexpected results.;
	output;
	if Type	=	1	then do;
		stop;
	end;
run;

%*700.	Export the summary.;
data _NULL_;
	file CHKOUT;
	set logcheck;
	put c_msg '#' linum txt;
run;

%*800.	Send Email if required.;
%if	&F_SENDEMAIL.	^=	0	%then %do;
	%*100.	Generate summaries.;
	%*Count the total messages for each type to have for the Email Subject Line;
	%let	L_ERROR	=	0;
	%let	L_WARN	=	0;
	%let	L_NOTES	=	0;
	%let	L_FAIL	=	0;
	proc sql noprint;
		select count(type) into :L_ERROR	from logcheck where type = 1;
		select count(type) into :L_WARN		from logcheck where type = 2;
		select count(type) into :L_NOTES	from logcheck where type in (3,4);
		select count(type) into :L_FAIL		from logcheck where type ne 5;
	quit;
	data _NULL_;
		call symputx("L_ERROR","&L_ERROR.","L");
		call symputx("L_WARN","&L_WARN.","L");
		call symputx("L_NOTES","&L_NOTES.","L");
		call symputx("L_FAIL","&L_FAIL.","L");
	run;

	%*200.	Create summary information.;
	data _mail_sum;
		length	cnt	$256.;
		cnt	=	"Log File:";
		output;
		cnt	=	"[&LOG_NAME.]";
		output;
		cnt	=	"";
		output;
		cnt	=	"[Errors: &L_ERROR.]";
		output;
		cnt	=	"[Warnings: &L_WARN.]";
		output;
		cnt	=	"[Notes: &L_NOTES.]";
		output;
		cnt	=	"";
		output;
		cnt	=	"--SAS System Generated Message--";
		output;
		cnt	=	"User: %sysget(USERNAME)";
		output;
		cnt	=	"Domain: %sysget(USERDOMAIN)";
		output;
	run;

	%*300.	Create detailed report if issues are found.;
	%if &L_FAIL.	^=	0	%then %do;
		%*100.	Open the ODS system.;
		%local	outf;
		%let	outf	=	%sysfunc(pathname(WORK))\LogChk.pdf;
		filename
			outf
			"&outf."
			encoding="&G_ENC_LOG."
		;
		ods listing close;
		ods
			pdf
			body="&outf."
			style=printer
		;

		%*200.	Print the log table.;
		title 'Log Check Results';
		title2 "Run date: &SYSDATE.";
		proc report data=logcheck  nowindows split='~';
			format type ec_Typefm.;
			column logname type linum txt;
			define type / order=formatted 'Type';
			define linum / display;
			define txt / display width=80 flow;
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
				else if type.sum = 5 then do;
					call define(_ROW_,'style','style=[background=#D3D3D3 font_style=italic]');
				end;
			endcomp;
		run;

		%*900.	Close the ODS system.;
		ods pdf close;
		ods listing;
	%end;

	%*400.	Prepare the OutBox.;
	FILENAME
		OutBox
		EMAIL
		to=("&G_email.")
	%if &L_FAIL.	=	0	%then %do;
		subject="SAS Log Check [&G_JOB_NAME.][&L_LOGNM.]: ==Job Successful!=="
	%end;
	%else %do;
		subject="SAS Log Check [&G_JOB_NAME.][&L_LOGNM.]: [ERROR: &L_ERROR.][WARN: &L_WARN.][NOTE: &L_NOTES.]"
		attach="&outf."
	%end;
	;

	%*500.	Send the email.;
	data _NULL_;
		file OutBox;
		set _mail_sum;
		put cnt;
	run;

	%*900.	Purge the system.;
	%if &L_FAIL.	^=	0	%then %do;
		%sysexec(del /Q "&outf." & exit);
	%end;

%*End of %if	&F_SENDEMAIL.	^=	0;
%end;

%mend ecLog;
%ecLog

/*->Begin Block -Comment- (Remove the following WHITE SPACE to un-comment the block)* /
SAS All Versions:
When using INFILE statement to read the text file which is stored in EUC-CN by SAS English
 version (nls/en/), there will be a fatal I/O error.
Solution:
(1) Circumvent using SAS English version to execute this procedure to check logs generated in
either EUC-CN or UTF-8.

SAS9.1.3
The programs stored in UTF-8 cannot be read properly with (nls/1d) and thus the entire Error Check
 procedure will be terminated.
Solution:
(1) Remove all "ecLang" files which are stored in UTF-8 when executing this procedure.
(2) Use "encoding=" option in FILENAME statement and then use '%include filename'.

SAS9.3
If English version is to be used imperatively, please ensure the log file to be verified
 is stored in encoding other than EUC-CN and UTF-8.
/*<-End Block -Comment- */