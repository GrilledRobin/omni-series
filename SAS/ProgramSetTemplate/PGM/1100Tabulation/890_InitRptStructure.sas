%*001.	This section generates system log data.;
%*Below macro is from "&macroot.\010Proc";
%genLogByExecPgm

%*010.	Below section generates the system-level global variables;
%global
	L_srcflnm1
	L_srcflnm2
	L_stpflnm
;

%let	L_srcflnm1	=	src.BrMapping&L_curDate.;
%let	L_srcflnm2	=	src.rpt_KPI&L_curMon.;
%let	L_stpflnm	=	Anl.rptData_BlankStruct&L_curMon.;

/***************************************************************************************************\
|	Initialize the structure of the tabulation for the report										|
|	For this Subbranch level report, we need to assure the final report of each Subbranch has all	|
|	 the required dimensions, even if there is no performance data of some KPIs in any of the		|
|	 Subbranches.																					|
|	For the required fields please check the step of tabulation.									|
\***************************************************************************************************/

%*020.	Below section is for main process;
%macro genRptStructure;
%*100.	We only reserve the necessary fields.;
%*110.	Branch mapping table.;
proc sort
	data=&L_srcflnm1.(
		keep=
			nc_branch_cd
			c_branch_nm
			c_city_name
	)
	out=work2._rpt_st_BrMapping
	nodupkey
;
	by
		nc_branch_cd
		c_branch_nm
		c_city_name
	;
run;

%*120.	KPI configuration for this report.;
data work2._rpt_st_rptKPI;
	set
		&L_srcflnm2.(
			keep=
				C_KPI_ID
				C_KPI_CAT1
				C_KPI_CAT2
				C_KPI_CAT3
				C_KPI_CAT4
				C_KPI_NAME
				D_TABLE
			where=(
				upcase(C_KPI_NAME)	^=	"(ADDITIONAL)"
			)
		)
	;
	format	A_KPI_VAL	best32.;
	A_KPI_VAL	=	0;
run;
proc sort
	data=work2._rpt_st_rptKPI
	nodupkey
;
	by	_ALL_;
run;

%*900.	Standardize the data.;
data &L_stpflnm.(compress=yes);
	%*100.	Prepare the data structure.;
	if	0	then do;
		set
			work2._rpt_st_BrMapping
			work2._rpt_st_rptKPI
		;
	end;

	%*200.	Hash in the datasets.;
	if	_N_	=	1	then do;
		dcl hash hLeft(dataset:"work2._rpt_st_BrMapping");
		hLeft.DefineKey(all:"yes");
		hLeft.DefineData(all:"yes");
		hLeft.DefineDone();
		dcl hiter hiLeft("hLeft");

		dcl hash hRight(dataset:"work2._rpt_st_rptKPI");
		hRight.DefineKey(all:"yes");
		hRight.DefineData(all:"yes");
		hRight.DefineDone();
		dcl hiter hiRight("hRight");
	end;

	%*300.	Initialize all the required fields.;
	call missing(of _all_);

	%*400.	Prepare the cartesian product of the datasets.;
	%*410.	Retrieve the first observation from the "Left" table.;
	rcLeft	=	hiLeft.first();

	%*420.	Iterate all observations in the "Left" table.;
	do	while ( rcLeft = 0 );
		%*100.	Retrieve the first observation from the "Right" table.;
		rcRight	=	hiRight.first();

		%*200.	Iterate all observations in the "Right" table.;
		do	while ( rcRight = 0 );
			%*100.	Output the combined observation, should both ones are found in the source.;
			output;

			%*900.	Fetch the next observation in the Hast Iteration Object of the "Right" table.;
			rcRight	=	hiRight.next();
		end;

		%*900.	Fetch the next observation in the Hast Iteration Object of the "Left" table.;
		rcLeft	=	hiLeft.next();
	end;

	%*900.	Purge.;
	drop
		rcLeft
		rcRight
	;
run;

%EndOfProc:
%mend genRptStructure;
%genRptStructure