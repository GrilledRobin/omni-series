libname	tt	"C:\www\omnimacro\Model";

options
	sasautos=(
		sasautos
		"C:\www\omnimacro\AdvOp"
		"C:\www\omnimacro\FileSystem"
		"C:\www\omnimacro\Model"
	)
	mautosource
;

%macro ErrMcr;
%mend ErrMcr;

%*100.	Preparation.;

%*200.	Test macro.;
%*Below is for comparison.;
%ProcObsCorrelativity(
	inDAT	=	tt.rm4CSstd
/*	,GrpBy	=	C_SC_SCH_:*/
	,inKEY	=	%nrbquote(c_po.*)
	,inVAR	=
	,inMTHD	=	CosSim
	,outDAT	=	MatrixCosSim
)
%ProcObsCorrelativity(
	inDAT	=	tt.rm4CSstd
	,GrpBy	=	C_SC_SCH_:
	,inKEY	=	%nrbquote(c_po.*)
	,inVAR	=
	,inMTHD	=	CosSim
	,outDAT	=	GrpCosSim
)
%ProcObsCorrelativity(
	inDAT	=	tt.rm4CSstd
	,GrpBy	=	C_SC_SCH_:
	,inKEY	=	%nrbquote(c_po.*)
	,inVAR	=
	,inMTHD	=	EuclidDist
	,outDAT	=	GrpEuclidDist
)

%*201.	Single Record.;
data
	smpl
	db
;
	set tt.Rm4csstd;
	if	C_PO_PW	=	"1436092"	then do;
		output	smpl;
	end;
	else do;
		output	db;
	end;
run;
proc sort
	data=smpl
;
	by
		C_SC_SCH_TYPE
		C_PO_PW
	;
run;
proc sort
	data=db
;
	by
		C_SC_SCH_TYPE
		C_PO_PW
	;
run;
%GetObsCorrFromDB(
	inDAT		=	smpl
	,inDB		=	db
	,GrpBy		=
	,inKEY		=	C_PO_PW
	,inVAR		=
	,inMTHD		=	CosSim
	,inScale	=
	,nFound		=
	,procLIB	=	WORK
	,outDAT		=	aa
)

%*202.	With BY group.;
%GetObsCorrFromDB(
	inDAT		=	smpl
	,inDB		=	db
	,GrpBy		=	descending C_SC:
	,inKEY		=	C_PO_PW
	,inVAR		=
	,inMTHD		=	CosSim
	,inScale	=
	,nFound		=
	,procLIB	=	WORK
	,outDAT		=	bb
)

%*203.	With Scale.;
%GetObsCorrFromDB(
	inDAT		=	smpl
	,inDB		=	db
	,GrpBy		=
	,inKEY		=	C_PO_PW
	,inVAR		=
	,inMTHD		=	CosSim
	,inScale	=	%nrbquote( abs(ObsSim) < 0.1 )
	,nFound		=
	,procLIB	=	WORK
	,outDAT		=	bb2
)

%*204.	With Limit on findings.;
%GetObsCorrFromDB(
	inDAT		=	smpl
	,inDB		=	db
	,GrpBy		=
	,inKEY		=	C_PO_PW
	,inVAR		=
	,inMTHD		=	CosSim
	,inScale	=	%nrbquote( abs(ObsSim) < 0.1 )
	,nFound		=	7
	,procLIB	=	WORK
	,outDAT		=	bb3
)

%*210.	Two Records.;
data
	smpl2
	db2
;
	set tt.Rm4csstd;
	if	C_PO_PW	in	("1436092" "1447483")	then do;
		output	smpl2;
	end;
	else do;
		output	db2;
	end;
run;
proc sort
	data=smpl2
;
	by
		C_SC_SCH_TYPE
		C_PO_PW
	;
run;
proc sort
	data=db2
;
	by
		C_SC_SCH_TYPE
		C_PO_PW
	;
run;
%GetObsCorrFromDB(
	inDAT		=	smpl2
	,inDB		=	db2
	,GrpBy		=
	,inKEY		=	C_PO_PW
	,inVAR		=
	,inMTHD		=	CosSim
	,inScale	=
	,nFound		=
	,procLIB	=	WORK
	,outDAT		=	cc
)

%*212.	With BY group.;
%GetObsCorrFromDB(
	inDAT		=	smpl2
	,inDB		=	db2
	,GrpBy		=	C_SC:
	,inKEY		=	C_PO_PW
	,inVAR		=
	,inMTHD		=	CosSim
	,inScale	=
	,nFound		=
	,procLIB	=	WORK
	,outDAT		=	dd
)

%*213.	With Scale.;
%GetObsCorrFromDB(
	inDAT		=	smpl2
	,inDB		=	db2
	,GrpBy		=	C_SC:
	,inKEY		=	C_PO_PW
	,inVAR		=
	,inMTHD		=	CosSim
	,inScale	=	%nrbquote( abs(ObsSim) < 0.1 )
	,nFound		=
	,procLIB	=	WORK
	,outDAT		=	dd2
)

%*214.	With Limit on findings.;
%GetObsCorrFromDB(
	inDAT		=	smpl2
	,inDB		=	db2
	,GrpBy		=	C_SC:
	,inKEY		=	C_PO_PW
	,inVAR		=
	,inMTHD		=	CosSim
	,inScale	=	%nrbquote( abs(ObsSim) < 0.9 )
	,nFound		=	5
	,procLIB	=	WORK
	,outDAT		=	dd3
)

%*300.	Euclidean Distance.;
%GetObsCorrFromDB(
	inDAT		=	smpl2
	,inDB		=	db2
	,GrpBy		=	C_SC:
	,inKEY		=	C_PO_PW
	,inVAR		=
	,inMTHD		=	EuclidDist
	,inScale	=	%nrbquote( abs(ObsDist) < 1000000 )
	,nFound		=	5
	,procLIB	=	WORK
	,outDAT		=	dd4
)

%*400.	Unsorted DB.;
proc sort
	data=DB2
;
	by C_PO_PW;
run;
%GetObsCorrFromDB(
	inDAT		=	smpl2
	,inDB		=	db2
	,GrpBy		=	C_SC:
	,inKEY		=	C_PO_PW
	,inVAR		=
	,inMTHD		=	CosSim
	,inScale	=	%nrbquote( abs(ObsSim) < 0.9 )
	,nFound		=	5
	,procLIB	=	WORK
	,outDAT		=	dd3
)
