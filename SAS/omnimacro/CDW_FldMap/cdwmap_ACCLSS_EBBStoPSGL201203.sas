%macro cdwmap_ACCLSS_EBBStoPSGL(
	inBRCODE=
	,inACCLSS=
	,inPDTCODE=
	,inCUSTSEG=
	,inDEPTID=
	,inPEBAL=
	,inCRGCODE=
	,inSEGCODE=
	,inTXNTYPE=
	,inTXNDIR=
	,outACCT=
);
IF (&inACCLSS.	IN	("652519"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("860009"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("820001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("890001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("840001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("850001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("830001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("810001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("772002"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("665062"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("665030"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("665016"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("665006"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("665009"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("665001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("661007"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("661002"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("659401"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("661019"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("658002"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("657601"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("657401"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("657219"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("656019"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("655801"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("655020"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("655019"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("655002"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("654519"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("654509"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("654506"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("654505"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("637001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("652554"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("652501"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("652151"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("651501"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("651101"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("637006"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("637005"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("637002"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("632104"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("637003"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("636003"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("636001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("651301"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("635051"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("635004"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("635003"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("635002"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("635001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("634004"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("652103"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("652502"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("634003"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("634002"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("654501"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("634001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("651701"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("652520"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("633003"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("633002"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("632105"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("615107"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("632102"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("654511"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("631505"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("631503"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("655001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("631019"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("631002"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("655006"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("631001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("615152"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("652553"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("615149"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("657001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("615125"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("615124"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("615118"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("615115"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("654502"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("657202"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("615109"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("615108"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("611701"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("615104"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("615102"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("659402"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("615101"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("613002"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("613001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("612559"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("657606"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("661004"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("656002"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("612556"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("612503"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("612502"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("612001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("665011"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("611713"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("662002"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("665045"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("611708"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("611704"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("611702"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("611449"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("611407"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("611405"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("772001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("662001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("611404"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("611401"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("860001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("611103"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("665049"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("669101"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("611102"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("870001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("611101"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("880001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("652519"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("860009"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("655002"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("665006"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("662001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("665009"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("657001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("665030"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("665045"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("665016"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("772001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("669101"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("810001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("830001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("860001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("850001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("890001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("870001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("840001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("820001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("655019"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("661019"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("661007"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("611102"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("611405"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("611407"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("655801"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("654501"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("656019"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("657401"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("657202"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("657606"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("659401"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("659402"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("657601"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("661002"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("880001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("665001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("772002"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("665062"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("665049"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("665011"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("662002"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("661004"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("615124"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("658002"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("657219"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("656002"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("655006"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("655001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("654519"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("654509"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("652520"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("652151"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("651301"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("633002"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("636001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("635004"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("635002"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("634002"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("632105"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("631503"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("615152"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("611701"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("615118"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("615107"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("613002"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("612503"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("611708"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("611449"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("611401"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("611702"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("612502"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("612001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("612556"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("613001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("612559"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("611713"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("615104"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("615102"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("615108"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("615115"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("611704"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("615101"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("615149"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("615125"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("631001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("631019"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("631002"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("631505"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("632104"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("632102"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("615109"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("634001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("633003"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("634003"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("635001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("635003"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("634004"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("635051"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("636003"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("637002"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("637005"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("637006"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("637001"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("651101"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("651501"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("652501"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("652103"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("652502"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("652553"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("652554"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("654502"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("654505"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("651701"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("637003"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("654506"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("611103"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("654511"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("611404"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("655020"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("611101"))
	THEN &outACCT.="";
IF (&inACCLSS.	IN	("231001"))
	THEN &outACCT.="133701";
IF (&inACCLSS.	IN	("231003"))
	AND (&inPEBAL.	LT	(0))
	THEN &outACCT.="133701";
IF (&inACCLSS.	IN	("932011"))
	THEN &outACCT.="232011";
IF (&inACCLSS.	IN	("232011"))
	THEN &outACCT.="232011";
IF (&inACCLSS.	IN	("932011"))
	AND (&inCUSTSEG.	IN	("026"))
	THEN &outACCT.="231001";
IF (&inACCLSS.	IN	("232011"))
	AND (&inCUSTSEG.	IN	("026"))
	THEN &outACCT.="231001";
IF (&inACCLSS.	IN	("231003"))
	AND (&inCUSTSEG.	IN	("110","111","112","113","115","116","121","122"))
	THEN &outACCT.="231013";
IF (&inACCLSS.	IN	("133701"))
	THEN &outACCT.="133701";
IF (&inACCLSS.	IN	("232012"))
	THEN &outACCT.="232012";
IF (&inACCLSS.	IN	("233161"))
	THEN &outACCT.="233161";
IF (&inACCLSS.	IN	("234231"))
	THEN &outACCT.="234231";
IF (&inACCLSS.	IN	("233174"))
	THEN &outACCT.="233174";
IF (&inACCLSS.	IN	("233201"))
	THEN &outACCT.="233201";
IF (&inACCLSS.	IN	("287501"))
	THEN &outACCT.="287501";
IF (&inACCLSS.	IN	("231001"))
	AND (&inPEBAL.	GE	(0))
	THEN &outACCT.="231001";
IF (&inACCLSS.	IN	("233105"))
	THEN &outACCT.="233105";
IF (&inACCLSS.	IN	("231003"))
	AND (&inPEBAL.	GE	(0))
	THEN &outACCT.="231001";
IF (&inACCLSS.	IN	("231003"))
	THEN &outACCT.="231001";
IF (&inACCLSS.	IN	("231001"))
	AND (&inCUSTSEG.	IN	("110","111","112","113","115","116","121","122"))
	AND (&inPEBAL.	GE	(0))
	THEN &outACCT.="231013";
IF (&inACCLSS.	IN	("233201"))
	AND (&inCUSTSEG.	IN	("110","111","112","113","115","116","121","122"))
	THEN &outACCT.="233251";
IF (&inACCLSS.	IN	("287501"))
	AND (&inCUSTSEG.	IN	("110","111","112","113","115","116","121","122"))
	THEN &outACCT.="232072";
IF (&inACCLSS.	IN	("233174"))
	AND (&inCUSTSEG.	IN	("110","111","112","113","115","116","121","122"))
	THEN &outACCT.="233125";
IF (&inACCLSS.	IN	("233161"))
	AND (&inCUSTSEG.	IN	("110","111","112","113","115","116","121","122"))
	THEN &outACCT.="233124";
IF (&inACCLSS.	IN	("234231"))
	AND (&inCUSTSEG.	IN	("110","111","112","113","115","116","121","122"))
	THEN &outACCT.="233126";
IF (&inACCLSS.	IN	("233105"))
	AND (&inCUSTSEG.	IN	("110","111","112","113","115","116","121","122"))
	THEN &outACCT.="233191";
IF (&inACCLSS.	IN	("232011"))
	AND (&inCUSTSEG.	IN	("110","111","112","113","115","116","121","122"))
	THEN &outACCT.="232067";
IF (&inACCLSS.	IN	("232012"))
	AND (&inCUSTSEG.	IN	("110","111","112","113","115","116","121","122"))
	THEN &outACCT.="232072";
IF (&inACCLSS.	IN	("289942"))
	THEN &outACCT.="289942";
IF (&inACCLSS.	IN	("288855"))
	THEN &outACCT.="288855";
IF (&inACCLSS.	IN	("288806"))
	THEN &outACCT.="288806";
IF (&inACCLSS.	IN	("867001"))
	THEN &outACCT.="867001";
IF (&inACCLSS.	IN	("177712"))
	THEN &outACCT.="177712";
IF (&inACCLSS.	IN	("288843"))
	THEN &outACCT.="288843";
IF (&inACCLSS.	IN	("289081"))
	THEN &outACCT.="289081";
IF (&inACCLSS.	IN	("504358"))
	THEN &outACCT.="504358";
IF (&inACCLSS.	IN	("876301"))
	THEN &outACCT.="876301";
IF (&inACCLSS.	IN	("267535"))
	THEN &outACCT.="267535";
IF (&inACCLSS.	IN	("860009"))
	THEN &outACCT.="860009";
IF (&inACCLSS.	IN	("289952"))
	THEN &outACCT.="289952";
IF (&inACCLSS.	IN	("289943"))
	THEN &outACCT.="289943";
IF (&inACCLSS.	IN	("288893"))
	THEN &outACCT.="288893";
IF (&inACCLSS.	IN	("289118"))
	THEN &outACCT.="289118";
IF (&inACCLSS.	IN	("289201"))
	THEN &outACCT.="289201";
IF (&inACCLSS.	IN	("289245"))
	THEN &outACCT.="289245";
IF (&inACCLSS.	IN	("288809"))
	THEN &outACCT.="288809";
IF (&inACCLSS.	IN	("289073"))
	THEN &outACCT.="289073";
IF (&inACCLSS.	IN	("876101"))
	THEN &outACCT.="876101";
IF (&inACCLSS.	IN	("333705"))
	THEN &outACCT.="333701";
IF (&inACCLSS.	IN	("504158"))
	THEN &outACCT.="504158";
IF (&inACCLSS.	IN	("288831"))
	THEN &outACCT.="288831";
IF (&inACCLSS.	IN	("122131"))
	THEN &outACCT.="122131";
IF (&inACCLSS.	IN	("289027"))
	THEN &outACCT.="289027";
IF (&inACCLSS.	IN	("289944"))
	THEN &outACCT.="289944";
IF (&inACCLSS.	IN	("289075"))
	THEN &outACCT.="289075";
IF (&inACCLSS.	IN	("866501"))
	THEN &outACCT.="866501";
IF (&inACCLSS.	IN	("299156"))
	THEN &outACCT.="299156";
IF (&inACCLSS.	IN	("547102"))
	THEN &outACCT.="547102";
IF (&inACCLSS.	IN	("289139"))
	THEN &outACCT.="289139";
IF (&inACCLSS.	IN	("332551"))
	THEN &outACCT.="332551";
IF (&inACCLSS.	IN	("323001"))
	THEN &outACCT.="323001";
IF (&inACCLSS.	IN	("504157"))
	THEN &outACCT.="504157";
IF (&inACCLSS.	IN	("111155"))
	THEN &outACCT.="111155";
IF (&inACCLSS.	IN	("876701"))
	THEN &outACCT.="876701";
IF (&inACCLSS.	IN	("289006"))
	THEN &outACCT.="289006";
IF (&inACCLSS.	IN	("267506"))
	THEN &outACCT.="267506";
IF (&inACCLSS.	IN	("299157"))
	THEN &outACCT.="299157";
IF (&inACCLSS.	IN	("555002"))
	THEN &outACCT.="555002";
IF (&inACCLSS.	IN	("288195"))
	THEN &outACCT.="288195";
IF (&inACCLSS.	IN	("288849"))
	THEN &outACCT.="288849";
IF (&inACCLSS.	IN	("289941"))
	THEN &outACCT.="289941";
IF (&inACCLSS.	IN	("288102"))
	THEN &outACCT.="288102";
IF (&inACCLSS.	IN	("433161"))
	THEN &outACCT.="433161";
IF (&inACCLSS.	IN	("289946"))
	THEN &outACCT.="289946";
IF (&inACCLSS.	IN	("133736"))
	THEN &outACCT.="133731";
IF (&inACCLSS.	IN	("515107"))
	THEN &outACCT.="515107";
IF (&inACCLSS.	IN	("504505"))
	THEN &outACCT.="504505";
IF (&inACCLSS.	IN	("515009"))
	THEN &outACCT.="515009";
IF (&inACCLSS.	IN	("289190"))
	THEN &outACCT.="289190";
IF (&inACCLSS.	IN	("547702"))
	THEN &outACCT.="547702";
IF (&inACCLSS.	IN	("652502"))
	THEN &outACCT.="652502";
IF (&inACCLSS.	IN	("122532"))
	THEN &outACCT.="122532";
IF (&inACCLSS.	IN	("289026"))
	THEN &outACCT.="289026";
IF (&inACCLSS.	IN	("288826"))
	THEN &outACCT.="288826";
IF (&inACCLSS.	IN	("289945"))
	THEN &outACCT.="289945";
IF (&inACCLSS.	IN	("170283"))
	THEN &outACCT.="170283";
IF (&inACCLSS.	IN	("111103"))
	THEN &outACCT.="111103";
IF (&inACCLSS.	IN	("231002"))
	AND (&inCUSTSEG.	IN	("110","111","112","113","115","116","121","122"))
	THEN &outACCT.="231014";
IF (&inACCLSS.	IN	("289204"))
	THEN &outACCT.="289204";
IF (&inACCLSS.	IN	("431002"))
	THEN &outACCT.="431001";
IF (&inACCLSS.	IN	("288808"))
	THEN &outACCT.="288808";
IF (&inACCLSS.	IN	("122132"))
	THEN &outACCT.="122132";
IF (&inACCLSS.	IN	("288811"))
	THEN &outACCT.="288811";
IF (&inACCLSS.	IN	("546057"))
	THEN &outACCT.="546057";
IF (&inACCLSS.	IN	("289082"))
	THEN &outACCT.="289082";
IF (&inACCLSS.	IN	("133562"))
	THEN &outACCT.="133557";
IF (&inACCLSS.	IN	("268109"))
	THEN &outACCT.="268109";
IF (&inACCLSS.	IN	("876501"))
	THEN &outACCT.="876501";
IF (&inACCLSS.	IN	("289158"))
	THEN &outACCT.="289158";
IF (&inACCLSS.	IN	("233126"))
	THEN &outACCT.="233126";
IF (&inACCLSS.	IN	("175101"))
	THEN &outACCT.="175101";
IF (&inACCLSS.	IN	("267526"))
	THEN &outACCT.="267526";
IF (&inACCLSS.	IN	("876553"))
	THEN &outACCT.="876553";
IF (&inACCLSS.	IN	("332701"))
	THEN &outACCT.="332701";
IF (&inACCLSS.	IN	("559022"))
	THEN &outACCT.="559022";
IF (&inACCLSS.	IN	("288274"))
	THEN &outACCT.="288274";
IF (&inACCLSS.	IN	("422002"))
	THEN &outACCT.="422002";
IF (&inACCLSS.	IN	("121003"))
	THEN &outACCT.="121003";
IF (&inACCLSS.	IN	("333301"))
	THEN &outACCT.="333301";
IF (&inACCLSS.	IN	("492502"))
	THEN &outACCT.="492502";
IF (&inACCLSS.	IN	("170212"))
	THEN &outACCT.="170212";
IF (&inACCLSS.	IN	("175502"))
	THEN &outACCT.="175502";
IF (&inACCLSS.	IN	("133717"))
	THEN &outACCT.="133717";
IF (&inACCLSS.	IN	("813614"))
	THEN &outACCT.="813614";
IF (&inACCLSS.	IN	("515016"))
	THEN &outACCT.="515016";
IF (&inACCLSS.	IN	("895001"))
	THEN &outACCT.="188001";
IF (&inACCLSS.	IN	("288807"))
	THEN &outACCT.="288807";
IF (&inACCLSS.	IN	("288900"))
	THEN &outACCT.="288821";
IF (&inACCLSS.	IN	("175507"))
	THEN &outACCT.="175502";
IF (&inACCLSS.	IN	("422061"))
	THEN &outACCT.="422061";
IF (&inACCLSS.	IN	("288154"))
	THEN &outACCT.="288154";
IF (&inACCLSS.	IN	("132706"))
	THEN &outACCT.="132703";
IF (&inACCLSS.	IN	("299101"))
	THEN &outACCT.="299101";
IF (&inACCLSS.	IN	("546060"))
	THEN &outACCT.="546060";
IF (&inACCLSS.	IN	("503017"))
	THEN &outACCT.="503017";
IF (&inACCLSS.	IN	("291701"))
	THEN &outACCT.="291701";
IF (&inACCLSS.	IN	("333999"))
	THEN &outACCT.="333999";
IF (&inACCLSS.	IN	("867063"))
	THEN &outACCT.="867062";
IF (&inACCLSS.	IN	("288255"))
	THEN &outACCT.="288255";
IF (&inACCLSS.	IN	("171550"))
	THEN &outACCT.="171550";
IF (&inACCLSS.	IN	("287666"))
	THEN &outACCT.="287666";
IF (&inACCLSS.	IN	("132704"))
	THEN &outACCT.="132701";
IF (&inACCLSS.	IN	("133561"))
	THEN &outACCT.="133551";
IF (&inACCLSS.	IN	("288859"))
	THEN &outACCT.="288859";
IF (&inACCLSS.	IN	("133312"))
	THEN &outACCT.="133305";
IF (&inACCLSS.	IN	("288201"))
	THEN &outACCT.="288201";
IF (&inACCLSS.	IN	("261501"))
	THEN &outACCT.="261501";
IF (&inACCLSS.	IN	("288905"))
	THEN &outACCT.="288810";
IF (&inACCLSS.	IN	("192701"))
	THEN &outACCT.="192701";
IF (&inACCLSS.	IN	("285003"))
	THEN &outACCT.="285003";
IF (&inACCLSS.	IN	("144115"))
	THEN &outACCT.="144115";
IF (&inACCLSS.	IN	("224051"))
	THEN &outACCT.="224051";
IF (&inACCLSS.	IN	("133505"))
	THEN &outACCT.="133505";
IF (&inACCLSS.	IN	("499102"))
	THEN &outACCT.="499102";
IF (&inACCLSS.	IN	("133504"))
	THEN &outACCT.="133504";
IF (&inACCLSS.	IN	("344112"))
	THEN &outACCT.="344112";
IF (&inACCLSS.	IN	("288820"))
	THEN &outACCT.="288820";
IF (&inACCLSS.	IN	("867006"))
	THEN &outACCT.="867006";
IF (&inACCLSS.	IN	("559014"))
	THEN &outACCT.="559014";
IF (&inACCLSS.	IN	("172501"))
	THEN &outACCT.="172501";
IF (&inACCLSS.	IN	("535001"))
	THEN &outACCT.="535001";
IF (&inACCLSS.	IN	("515005"))
	THEN &outACCT.="515005";
IF (&inACCLSS.	IN	("867064"))
	THEN &outACCT.="867062";
IF (&inACCLSS.	IN	("289130"))
	THEN &outACCT.="289130";
IF (&inACCLSS.	IN	("515001"))
	THEN &outACCT.="515001";
IF (&inACCLSS.	IN	("289028"))
	THEN &outACCT.="289028";
IF (&inACCLSS.	IN	("503003"))
	THEN &outACCT.="503003";
IF (&inACCLSS.	IN	("175521"))
	THEN &outACCT.="175521";
IF (&inACCLSS.	IN	("176501"))
	THEN &outACCT.="176501";
IF (&inACCLSS.	IN	("333555"))
	THEN &outACCT.="333555";
IF (&inACCLSS.	IN	("267008"))
	THEN &outACCT.="267003";
IF (&inACCLSS.	IN	("170803"))
	THEN &outACCT.="170803";
IF (&inACCLSS.	IN	("547901"))
	THEN &outACCT.="547901";
IF (&inACCLSS.	IN	("311701"))
	THEN &outACCT.="311701";
IF (&inACCLSS.	IN	("288880"))
	THEN &outACCT.="288880";
IF (&inACCLSS.	IN	("491503"))
	THEN &outACCT.="491503";
IF (&inACCLSS.	IN	("489099"))
	THEN &outACCT.="489099";
IF (&inACCLSS.	IN	("333731"))
	THEN &outACCT.="333731";
IF (&inACCLSS.	IN	("144501"))
	THEN &outACCT.="144501";
IF (&inACCLSS.	IN	("133557"))
	THEN &outACCT.="133557";
IF (&inACCLSS.	IN	("559021"))
	THEN &outACCT.="559021";
IF (&inACCLSS.	IN	("510004"))
	THEN &outACCT.="510004";
IF (&inACCLSS.	IN	("515002"))
	THEN &outACCT.="515002";
IF (&inACCLSS.	IN	("177352"))
	THEN &outACCT.="177352";
IF (&inACCLSS.	IN	("332501"))
	THEN &outACCT.="332501";
IF (&inACCLSS.	IN	("177505"))
	THEN &outACCT.="177505";
IF (&inACCLSS.	IN	("170201"))
	THEN &outACCT.="170201";
IF (&inACCLSS.	IN	("144112"))
	THEN &outACCT.="144112";
IF (&inACCLSS.	IN	("288101"))
	THEN &outACCT.="288101";
IF (&inACCLSS.	IN	("170404"))
	THEN &outACCT.="170404";
IF (&inACCLSS.	IN	("865001"))
	THEN &outACCT.="865001";
IF (&inACCLSS.	IN	("221051"))
	THEN &outACCT.="221051";
IF (&inACCLSS.	IN	("555007"))
	THEN &outACCT.="555007";
IF (&inACCLSS.	IN	("288906"))
	THEN &outACCT.="289051";
IF (&inACCLSS.	IN	("510057"))
	THEN &outACCT.="510057";
IF (&inACCLSS.	IN	("288810"))
	THEN &outACCT.="288810";
IF (&inACCLSS.	IN	("235001"))
	THEN &outACCT.="235001";
IF (&inACCLSS.	IN	("175504"))
	THEN &outACCT.="175504";
IF (&inACCLSS.	IN	("171551"))
	THEN &outACCT.="171550";
IF (&inACCLSS.	IN	("175508"))
	THEN &outACCT.="175501";
IF (&inACCLSS.	IN	("122001"))
	THEN &outACCT.="122001";
IF (&inACCLSS.	IN	("288132"))
	THEN &outACCT.="288132";
IF (&inACCLSS.	IN	("191701"))
	THEN &outACCT.="191701";
IF (&inACCLSS.	IN	("391506"))
	THEN &outACCT.="391506";
IF (&inACCLSS.	IN	("333733"))
	THEN &outACCT.="333732";
IF (&inACCLSS.	IN	("133880"))
	THEN &outACCT.="133880";
IF (&inACCLSS.	IN	("391501"))
	THEN &outACCT.="391501";
IF (&inACCLSS.	IN	("423011"))
	THEN &outACCT.="423011";
IF (&inACCLSS.	IN	("133351"))
	THEN &outACCT.="133351";
IF (&inACCLSS.	IN	("139503"))
	THEN &outACCT.="139503";
IF (&inACCLSS.	IN	("288829"))
	THEN &outACCT.="288829";
IF (&inACCLSS.	IN	("433105"))
	THEN &outACCT.="433105";
IF (&inACCLSS.	IN	("813603"))
	THEN &outACCT.="813603";
IF (&inACCLSS.	IN	("813608"))
	THEN &outACCT.="813608";
IF (&inACCLSS.	IN	("267511"))
	THEN &outACCT.="267511";
IF (&inACCLSS.	IN	("832112"))
	THEN &outACCT.="832112";
IF (&inACCLSS.	IN	("177557"))
	THEN &outACCT.="177557";
IF (&inACCLSS.	IN	("553011"))
	THEN &outACCT.="553011";
IF (&inACCLSS.	IN	("288904"))
	THEN &outACCT.="288810";
IF (&inACCLSS.	IN	("867062"))
	THEN &outACCT.="867062";
IF (&inACCLSS.	IN	("267006"))
	THEN &outACCT.="267006";
IF (&inACCLSS.	IN	("515073"))
	THEN &outACCT.="515073";
IF (&inACCLSS.	IN	("433201"))
	THEN &outACCT.="433201";
IF (&inACCLSS.	IN	("503005"))
	THEN &outACCT.="503005";
IF (&inACCLSS.	IN	("177301"))
	THEN &outACCT.="177301";
IF (&inACCLSS.	IN	("288879"))
	THEN &outACCT.="288879";
IF (&inACCLSS.	IN	("261555"))
	THEN &outACCT.="261555";
IF (&inACCLSS.	IN	("170235"))
	THEN &outACCT.="170203";
IF (&inACCLSS.	IN	("503002"))
	THEN &outACCT.="503002";
IF (&inACCLSS.	IN	("288179"))
	THEN &outACCT.="288157";
IF (&inACCLSS.	IN	("185501"))
	THEN &outACCT.="185501";
IF (&inACCLSS.	IN	("876102"))
	THEN &outACCT.="876102";
IF (&inACCLSS.	IN	("067511"))
	THEN &outACCT.="267511";
IF (&inACCLSS.	IN	("289087"))
	THEN &outACCT.="289087";
IF (&inACCLSS.	IN	("289152"))
	THEN &outACCT.="289152";
IF (&inACCLSS.	IN	("067526"))
	THEN &outACCT.="267526";
IF (&inACCLSS.	IN	("510001"))
	THEN &outACCT.="510001";
IF (&inACCLSS.	IN	("870001"))
	THEN &outACCT.="870001";
IF (&inACCLSS.	IN	("287508"))
	THEN &outACCT.="287501";
IF (&inACCLSS.	IN	("144101"))
	THEN &outACCT.="144101";
IF (&inACCLSS.	IN	("133732"))
	THEN &outACCT.="133732";
IF (&inACCLSS.	IN	("515055"))
	THEN &outACCT.="515055";
IF (&inACCLSS.	IN	("811103"))
	THEN &outACCT.="811103";
IF (&inACCLSS.	IN	("876505"))
	THEN &outACCT.="876505";
IF (&inACCLSS.	IN	("289086"))
	THEN &outACCT.="289086";
IF (&inACCLSS.	IN	("291755"))
	THEN &outACCT.="291755";
IF (&inACCLSS.	IN	("333501"))
	THEN &outACCT.="333501";
IF (&inACCLSS.	IN	("832111"))
	THEN &outACCT.="832111";
IF (&inACCLSS.	IN	("832501"))
	THEN &outACCT.="832501";
IF (&inACCLSS.	IN	("170229"))
	THEN &outACCT.="170204";
IF (&inACCLSS.	IN	("132702"))
	THEN &outACCT.="132702";
IF (&inACCLSS.	IN	("132703"))
	THEN &outACCT.="132703";
IF (&inACCLSS.	IN	("333505"))
	THEN &outACCT.="333505";
IF (&inACCLSS.	IN	("285556"))
	THEN &outACCT.="285556";
IF (&inACCLSS.	IN	("139505"))
	THEN &outACCT.="139505";
IF (&inACCLSS.	IN	("170204"))
	THEN &outACCT.="170204";
IF (&inACCLSS.	IN	("133559"))
	THEN &outACCT.="133559";
IF (&inACCLSS.	IN	("333701"))
	THEN &outACCT.="333701";
IF (&inACCLSS.	IN	("289054"))
	THEN &outACCT.="289054";
IF (&inACCLSS.	IN	("555001"))
	THEN &outACCT.="555001";
IF (&inACCLSS.	IN	("492501"))
	THEN &outACCT.="492501";
IF (&inACCLSS.	IN	("171552"))
	THEN &outACCT.="171502";
IF (&inACCLSS.	IN	("123001"))
	THEN &outACCT.="123001";
IF (&inACCLSS.	IN	("175506"))
	THEN &outACCT.="175501";
IF (&inACCLSS.	IN	("492505"))
	THEN &outACCT.="492505";
IF (&inACCLSS.	IN	("144503"))
	THEN &outACCT.="144503";
IF (&inACCLSS.	IN	("504312"))
	THEN &outACCT.="504312";
IF (&inACCLSS.	IN	("287667"))
	THEN &outACCT.="287667";
IF (&inACCLSS.	IN	("177717"))
	THEN &outACCT.="177717";
IF (&inACCLSS.	IN	("421001"))
	THEN &outACCT.="421001";
IF (&inACCLSS.	IN	("267003"))
	THEN &outACCT.="267003";
IF (&inACCLSS.	IN	("710401"))
	THEN &outACCT.="710401";
IF (&inACCLSS.	IN	("811107"))
	THEN &outACCT.="811107";
IF (&inACCLSS.	IN	("281501"))
	THEN &outACCT.="281501";
IF (&inACCLSS.	IN	("133355"))
	THEN &outACCT.="133355";
IF (&inACCLSS.	IN	("288899"))
	THEN &outACCT.="288899";
IF (&inACCLSS.	IN	("333768"))
	THEN &outACCT.="333732";
IF (&inACCLSS.	IN	("299172"))
	THEN &outACCT.="191810";
IF (&inACCLSS.	IN	("222061"))
	THEN &outACCT.="222061";
IF (&inACCLSS.	IN	("177736"))
	THEN &outACCT.="177732";
IF (&inACCLSS.	IN	("176551"))
	THEN &outACCT.="176551";
IF (&inACCLSS.	IN	("288813"))
	THEN &outACCT.="288813";
IF (&inACCLSS.	IN	("654502"))
	THEN &outACCT.="654502";
IF (&inACCLSS.	IN	("288878"))
	THEN &outACCT.="288878";
IF (&inACCLSS.	IN	("185502"))
	THEN &outACCT.="185502";
IF (&inACCLSS.	IN	("133303"))
	THEN &outACCT.="133301";
IF (&inACCLSS.	IN	("333305"))
	THEN &outACCT.="333305";
IF (&inACCLSS.	IN	("267004"))
	THEN &outACCT.="267004";
IF (&inACCLSS.	IN	("288841"))
	THEN &outACCT.="288841";
IF (&inACCLSS.	IN	("132701"))
	THEN &outACCT.="132701";
IF (&inACCLSS.	IN	("324505"))
	THEN &outACCT.="324502";
IF (&inACCLSS.	IN	("123051"))
	THEN &outACCT.="123051";
IF (&inACCLSS.	IN	("133356"))
	THEN &outACCT.="133355";
IF (&inACCLSS.	IN	("515076"))
	THEN &outACCT.="515076";
IF (&inACCLSS.	IN	("268501"))
	THEN &outACCT.="268501";
IF (&inACCLSS.	IN	("267501"))
	THEN &outACCT.="267501";
IF (&inACCLSS.	IN	("222001"))
	THEN &outACCT.="222001";
IF (&inACCLSS.	IN	("133767"))
	THEN &outACCT.="133767";
IF (&inACCLSS.	IN	("192806"))
	THEN &outACCT.="192806";
IF (&inACCLSS.	IN	("291756"))
	THEN &outACCT.="291756";
IF (&inACCLSS.	IN	("895025"))
	THEN &outACCT.="895025";
IF (&inACCLSS.	IN	("333309"))
	THEN &outACCT.="333309";
IF (&inACCLSS.	IN	("288895"))
	THEN &outACCT.="288895";
IF (&inACCLSS.	IN	("288126"))
	THEN &outACCT.="288126";
IF (&inACCLSS.	IN	("223011"))
	THEN &outACCT.="223011";
IF (&inACCLSS.	IN	("288897"))
	THEN &outACCT.="288897";
IF (&inACCLSS.	IN	("289173"))
	THEN &outACCT.="289173";
IF (&inACCLSS.	IN	("262501"))
	THEN &outACCT.="262501";
IF (&inACCLSS.	IN	("261505"))
	THEN &outACCT.="811102";
IF (&inACCLSS.	IN	("515066"))
	THEN &outACCT.="515066";
IF (&inACCLSS.	IN	("133733"))
	THEN &outACCT.="133733";
IF (&inACCLSS.	IN	("876702"))
	THEN &outACCT.="876702";
IF (&inACCLSS.	IN	("133890"))
	THEN &outACCT.="133890";
IF (&inACCLSS.	IN	("895088"))
	THEN &outACCT.="895088";
IF (&inACCLSS.	IN	("139501"))
	THEN &outACCT.="139501";
IF (&inACCLSS.	IN	("322001"))
	THEN &outACCT.="322001";
IF (&inACCLSS.	IN	("133551"))
	THEN &outACCT.="133551";
IF (&inACCLSS.	IN	("288902"))
	THEN &outACCT.="288821";
IF (&inACCLSS.	IN	("344502"))
	THEN &outACCT.="344502";
IF (&inACCLSS.	IN	("432011"))
	THEN &outACCT.="432011";
IF (&inACCLSS.	IN	("144102"))
	THEN &outACCT.="144102";
IF (&inACCLSS.	IN	("422001"))
	THEN &outACCT.="422001";
IF (&inACCLSS.	IN	("810001"))
	THEN &outACCT.="810001";
IF (&inACCLSS.	IN	("339073"))
	THEN &outACCT.="339073";
IF (&inACCLSS.	IN	("144502"))
	THEN &outACCT.="144502";
IF (&inACCLSS.	IN	("077701"))
	THEN &outACCT.="177701";
IF (&inACCLSS.	IN	("144504"))
	THEN &outACCT.="144504";
IF (&inACCLSS.	IN	("832121"))
	THEN &outACCT.="832121";
IF (&inACCLSS.	IN	("546001"))
	THEN &outACCT.="546001";
IF (&inACCLSS.	IN	("170206"))
	THEN &outACCT.="170206";
IF (&inACCLSS.	IN	("866502"))
	THEN &outACCT.="866502";
IF (&inACCLSS.	IN	("132501"))
	THEN &outACCT.="132501";
IF (&inACCLSS.	IN	("866564"))
	THEN &outACCT.="866562";
IF (&inACCLSS.	IN	("895087"))
	THEN &outACCT.="895087";
IF (&inACCLSS.	IN	("572009"))
	THEN &outACCT.="572009";
IF (&inACCLSS.	IN	("288870"))
	THEN &outACCT.="288870";
IF (&inACCLSS.	IN	("546056"))
	THEN &outACCT.="546056";
IF (&inACCLSS.	IN	("515072"))
	THEN &outACCT.="515072";
IF (&inACCLSS.	IN	("287601"))
	THEN &outACCT.="287601";
IF (&inACCLSS.	IN	("289114"))
	THEN &outACCT.="289114";
IF (&inACCLSS.	IN	("267523"))
	THEN &outACCT.="267523";
IF (&inACCLSS.	IN	("288842"))
	THEN &outACCT.="288842";
IF (&inACCLSS.	IN	("133305"))
	THEN &outACCT.="133305";
IF (&inACCLSS.	IN	("170807"))
	THEN &outACCT.="170803";
IF (&inACCLSS.	IN	("288903"))
	THEN &outACCT.="289140";
IF (&inACCLSS.	IN	("208903"))
	THEN &outACCT.="208903";
IF (&inACCLSS.	IN	("288881"))
	THEN &outACCT.="288881";
IF (&inACCLSS.	IN	("491502"))
	THEN &outACCT.="491502";
IF (&inACCLSS.	IN	("503050"))
	THEN &outACCT.="503050";
IF (&inACCLSS.	IN	("321002"))
	THEN &outACCT.="321002";
IF (&inACCLSS.	IN	("175509"))
	THEN &outACCT.="175509";
IF (&inACCLSS.	IN	("503061"))
	THEN &outACCT.="503061";
IF (&inACCLSS.	IN	("288202"))
	THEN &outACCT.="288201";
IF (&inACCLSS.	IN	("188011"))
	THEN &outACCT.="188001";
IF (&inACCLSS.	IN	("288157"))
	THEN &outACCT.="288157";
IF (&inACCLSS.	IN	("175121"))
	THEN &outACCT.="175121";
IF (&inACCLSS.	IN	("122005"))
	THEN &outACCT.="122005";
IF (&inACCLSS.	IN	("177552"))
	THEN &outACCT.="177552";
IF (&inACCLSS.	IN	("133511"))
	THEN &outACCT.="133504";
IF (&inACCLSS.	IN	("067501"))
	THEN &outACCT.="267501";
IF (&inACCLSS.	IN	("133510"))
	THEN &outACCT.="133503";
IF (&inACCLSS.	IN	("285001"))
	THEN &outACCT.="285001";
IF (&inACCLSS.	IN	("876502"))
	THEN &outACCT.="876502";
IF (&inACCLSS.	IN	("188001"))
	THEN &outACCT.="188001";
IF (&inACCLSS.	IN	("546053"))
	THEN &outACCT.="546053";
IF (&inACCLSS.	IN	("876106"))
	THEN &outACCT.="876106";
IF (&inACCLSS.	IN	("111101"))
	THEN &outACCT.="111101";
IF (&inACCLSS.	IN	("288901"))
	THEN &outACCT.="288821";
IF (&inACCLSS.	IN	("895063"))
	THEN &outACCT.="895063";
IF (&inACCLSS.	IN	("170225"))
	THEN &outACCT.="170225";
IF (&inACCLSS.	IN	("510005"))
	THEN &outACCT.="510005";
IF (&inACCLSS.	IN	("424051"))
	THEN &outACCT.="424051";
IF (&inACCLSS.	IN	("572003"))
	THEN &outACCT.="572003";
IF (&inACCLSS.	IN	("288907"))
	THEN &outACCT.="288810";
IF (&inACCLSS.	IN	("288871"))
	THEN &outACCT.="288871";
IF (&inACCLSS.	IN	("665006"))
	THEN &outACCT.="665006";
IF (&inACCLSS.	IN	("876153"))
	THEN &outACCT.="876153";
IF (&inACCLSS.	IN	("235003"))
	THEN &outACCT.="235003";
IF (&inACCLSS.	IN	("867002"))
	THEN &outACCT.="867002";
IF (&inACCLSS.	IN	("133876"))
	THEN &outACCT.="133876";
IF (&inACCLSS.	IN	("491564"))
	THEN &outACCT.="491564";
IF (&inACCLSS.	IN	("285554"))
	THEN &outACCT.="285554";
IF (&inACCLSS.	IN	("875001"))
	THEN &outACCT.="875001";
IF (&inACCLSS.	IN	("144113"))
	THEN &outACCT.="144113";
IF (&inACCLSS.	IN	("172505"))
	THEN &outACCT.="172501";
IF (&inACCLSS.	IN	("813607"))
	THEN &outACCT.="813607";
IF (&inACCLSS.	IN	("324501"))
	THEN &outACCT.="324501";
IF (&inACCLSS.	IN	("289036"))
	THEN &outACCT.="289036";
IF (&inACCLSS.	IN	("124501"))
	THEN &outACCT.="124501";
IF (&inACCLSS.	IN	("895023"))
	THEN &outACCT.="895023";
IF (&inACCLSS.	IN	("133731"))
	THEN &outACCT.="133731";
IF (&inACCLSS.	IN	("288178"))
	THEN &outACCT.="288178";
IF (&inACCLSS.	IN	("491506"))
	THEN &outACCT.="491506";
IF (&inACCLSS.	IN	("553003"))
	THEN &outACCT.="553003";
IF (&inACCLSS.	IN	("866565"))
	THEN &outACCT.="866562";
IF (&inACCLSS.	IN	("175125"))
	THEN &outACCT.="175121";
IF (&inACCLSS.	IN	("547701"))
	THEN &outACCT.="547701";
IF (&inACCLSS.	IN	("138506"))
	THEN &outACCT.="138506";
IF (&inACCLSS.	IN	("289099"))
	THEN &outACCT.="289099";
IF (&inACCLSS.	IN	("832113"))
	THEN &outACCT.="832113";
IF (&inACCLSS.	IN	("551003"))
	THEN &outACCT.="551003";
IF (&inACCLSS.	IN	("832102"))
	THEN &outACCT.="832102";
IF (&inACCLSS.	IN	("866562"))
	THEN &outACCT.="866562";
IF (&inACCLSS.	IN	("175153"))
	THEN &outACCT.="175153";
IF (&inACCLSS.	IN	("170211"))
	THEN &outACCT.="170211";
IF (&inACCLSS.	IN	("139509"))
	THEN &outACCT.="139509";
IF (&inACCLSS.	IN	("499101"))
	THEN &outACCT.="499101";
IF (&inACCLSS.	IN	("812702"))
	THEN &outACCT.="812702";
IF (&inACCLSS.	IN	("133555"))
	THEN &outACCT.="133555";
IF (&inACCLSS.	IN	("811106"))
	THEN &outACCT.="811106";
IF (&inACCLSS.	IN	("866507"))
	THEN &outACCT.="866507";
IF (&inACCLSS.	IN	("339072"))
	THEN &outACCT.="339072";
IF (&inACCLSS.	IN	("559013"))
	THEN &outACCT.="559013";
IF (&inACCLSS.	IN	("391505"))
	THEN &outACCT.="391505";
IF (&inACCLSS.	IN	("830001"))
	THEN &outACCT.="830001";
IF (&inACCLSS.	IN	("392501"))
	THEN &outACCT.="392501";
IF (&inACCLSS.	IN	("515020"))
	THEN &outACCT.="515001";
IF (&inACCLSS.	IN	("421501"))
	THEN &outACCT.="421501";
IF (&inACCLSS.	IN	("175511"))
	THEN &outACCT.="175511";
IF (&inACCLSS.	IN	("895081"))
	THEN &outACCT.="895081";
IF (&inACCLSS.	IN	("133304"))
	THEN &outACCT.="133302";
IF (&inACCLSS.	IN	("177503"))
	THEN &outACCT.="177503";
IF (&inACCLSS.	IN	("288171"))
	THEN &outACCT.="288171";
IF (&inACCLSS.	IN	("133309"))
	THEN &outACCT.="133309";
IF (&inACCLSS.	IN	("133313"))
	THEN &outACCT.="133306";
IF (&inACCLSS.	IN	("433174"))
	THEN &outACCT.="433174";
IF (&inACCLSS.	IN	("555003"))
	THEN &outACCT.="555003";
IF (&inACCLSS.	IN	("133705"))
	THEN &outACCT.="133705";
IF (&inACCLSS.	IN	("285557"))
	THEN &outACCT.="285557";
IF (&inACCLSS.	IN	("333557"))
	THEN &outACCT.="333557";
IF (&inACCLSS.	IN	("170224"))
	THEN &outACCT.="170224";
IF (&inACCLSS.	IN	("503049"))
	THEN &outACCT.="503049";
IF (&inACCLSS.	IN	("267538"))
	THEN &outACCT.="267538";
IF (&inACCLSS.	IN	("133554"))
	THEN &outACCT.="133554";
IF (&inACCLSS.	IN	("866561"))
	THEN &outACCT.="866561";
IF (&inACCLSS.	IN	("344212"))
	THEN &outACCT.="344212";
IF (&inACCLSS.	IN	("267002"))
	THEN &outACCT.="267002";
IF (&inACCLSS.	IN	("144114"))
	THEN &outACCT.="144114";
IF (&inACCLSS.	IN	("551011"))
	THEN &outACCT.="551011";
IF (&inACCLSS.	IN	("264802"))
	THEN &outACCT.="264802";
IF (&inACCLSS.	IN	("895089"))
	THEN &outACCT.="895089";
IF (&inACCLSS.	IN	("288833"))
	THEN &outACCT.="288833";
IF (&inACCLSS.	IN	("175501"))
	THEN &outACCT.="175501";
IF (&inACCLSS.	IN	("895064"))
	THEN &outACCT.="895064";
IF (&inACCLSS.	IN	("133501"))
	THEN &outACCT.="133501";
IF (&inACCLSS.	IN	("288858"))
	THEN &outACCT.="288858";
IF (&inACCLSS.	IN	("814601"))
	THEN &outACCT.="814601";
IF (&inACCLSS.	IN	("111105"))
	THEN &outACCT.="111105";
IF (&inACCLSS.	IN	("504340"))
	THEN &outACCT.="504340";
IF (&inACCLSS.	IN	("185557"))
	THEN &outACCT.="185557";
IF (&inACCLSS.	IN	("503019"))
	THEN &outACCT.="503019";
IF (&inACCLSS.	IN	("288123"))
	THEN &outACCT.="288123";
IF (&inACCLSS.	IN	("864501"))
	THEN &outACCT.="864501";
IF (&inACCLSS.	IN	("289180"))
	THEN &outACCT.="289180";
IF (&inACCLSS.	IN	("710101"))
	THEN &outACCT.="710101";
IF (&inACCLSS.	IN	("221001"))
	THEN &outACCT.="221001";
IF (&inACCLSS.	IN	("813612"))
	THEN &outACCT.="813612";
IF (&inACCLSS.	IN	("292804"))
	THEN &outACCT.="292804";
IF (&inACCLSS.	IN	("132705"))
	THEN &outACCT.="132702";
IF (&inACCLSS.	IN	("503018"))
	THEN &outACCT.="503018";
IF (&inACCLSS.	IN	("191859"))
	THEN &outACCT.="191859";
IF (&inACCLSS.	IN	("124503"))
	THEN &outACCT.="124503";
IF (&inACCLSS.	IN	("264801"))
	THEN &outACCT.="264801";
IF (&inACCLSS.	IN	("191858"))
	THEN &outACCT.="191858";
IF (&inACCLSS.	IN	("299102"))
	THEN &outACCT.="299102";
IF (&inACCLSS.	IN	("133560"))
	THEN &outACCT.="133560";
IF (&inACCLSS.	IN	("515017"))
	THEN &outACCT.="515017";
IF (&inACCLSS.	IN	("170308"))
	THEN &outACCT.="170308";
IF (&inACCLSS.	IN	("288830"))
	THEN &outACCT.="288830";
IF (&inACCLSS.	IN	("121006"))
	THEN &outACCT.="121003";
IF (&inACCLSS.	IN	("867061"))
	THEN &outACCT.="867061";
IF (&inACCLSS.	IN	("175122"))
	THEN &outACCT.="175122";
IF (&inACCLSS.	IN	("811101"))
	THEN &outACCT.="811101";
IF (&inACCLSS.	IN	("133503"))
	THEN &outACCT.="133503";
IF (&inACCLSS.	IN	("133302"))
	THEN &outACCT.="133302";
IF (&inACCLSS.	IN	("867065"))
	THEN &outACCT.="867062";
IF (&inACCLSS.	IN	("813605"))
	THEN &outACCT.="813605";
IF (&inACCLSS.	IN	("895090"))
	THEN &outACCT.="895087";
IF (&inACCLSS.	IN	("285501"))
	THEN &outACCT.="285501";
IF (&inACCLSS.	IN	("324502"))
	THEN &outACCT.="324502";
IF (&inACCLSS.	IN	("177733"))
	THEN &outACCT.="177733";
IF (&inACCLSS.	IN	("324504"))
	THEN &outACCT.="324502";
IF (&inACCLSS.	IN	("177305"))
	THEN &outACCT.="177305";
IF (&inACCLSS.	IN	("333717"))
	THEN &outACCT.="333717";
IF (&inACCLSS.	IN	("175523"))
	THEN &outACCT.="175521";
IF (&inACCLSS.	IN	("503001"))
	THEN &outACCT.="503001";
IF (&inACCLSS.	IN	("431001"))
	THEN &outACCT.="431001";
IF (&inACCLSS.	IN	("192802"))
	THEN &outACCT.="192802";
IF (&inACCLSS.	IN	("191802"))
	THEN &outACCT.="191802";
IF (&inACCLSS.	IN	("285005"))
	THEN &outACCT.="285005";
IF (&inACCLSS.	IN	("555058"))
	THEN &outACCT.="555058";
IF (&inACCLSS.	IN	("175126"))
	THEN &outACCT.="175122";
IF (&inACCLSS.	IN	("291703"))
	THEN &outACCT.="291703";
IF (&inACCLSS.	IN	("208301"))
	THEN &outACCT.="208301";
IF (&inACCLSS.	IN	("289142"))
	THEN &outACCT.="289142";
IF (&inACCLSS.	IN	("121004"))
	THEN &outACCT.="121003";
IF (&inACCLSS.	IN	("287669"))
	THEN &outACCT.="287669";
IF (&inACCLSS.	IN	("292702"))
	THEN &outACCT.="292702";
IF (&inACCLSS.	IN	("515065"))
	THEN &outACCT.="515065";
IF (&inACCLSS.	IN	("171504"))
	THEN &outACCT.="171504";
IF (&inACCLSS.	IN	("177551"))
	THEN &outACCT.="177551";
IF (&inACCLSS.	IN	("133506"))
	THEN &outACCT.="133506";
IF (&inACCLSS.	IN	("333767"))
	THEN &outACCT.="333767";
IF (&inACCLSS.	IN	("504301"))
	THEN &outACCT.="504301";
IF (&inACCLSS.	IN	("288908"))
	THEN &outACCT.="288810";
IF (&inACCLSS.	IN	("133895"))
	THEN &outACCT.="133895";
IF (&inACCLSS.	IN	("261502"))
	THEN &outACCT.="261502";
IF (&inACCLSS.	IN	("111701"))
	THEN &outACCT.="111701";
IF (&inACCLSS.	IN	("288845"))
	THEN &outACCT.="288845";
IF (&inACCLSS.	IN	("867005"))
	THEN &outACCT.="867005";
IF (&inACCLSS.	IN	("433107"))
	THEN &outACCT.="433105";
IF (&inACCLSS.	IN	("177731"))
	THEN &outACCT.="177731";
IF (&inACCLSS.	IN	("122002"))
	THEN &outACCT.="122002";
IF (&inACCLSS.	IN	("515003"))
	THEN &outACCT.="515003";
IF (&inACCLSS.	IN	("866563"))
	THEN &outACCT.="866562";
IF (&inACCLSS.	IN	("133502"))
	THEN &outACCT.="133502";
IF (&inACCLSS.	IN	("267009"))
	THEN &outACCT.="267002";
IF (&inACCLSS.	IN	("262511"))
	THEN &outACCT.="262501";
IF (&inACCLSS.	IN	("261511"))
	THEN &outACCT.="261501";
IF (&inACCLSS.	IN	("171502"))
	THEN &outACCT.="171502";
IF (&inACCLSS.	IN	("812701"))
	THEN &outACCT.="812701";
IF (&inACCLSS.	IN	("133701"))
	AND (&inPEBAL.	GT	(0))
	THEN &outACCT.="231001";
IF (&inACCLSS.	IN	("178049"))
	THEN &outACCT.="178049";
IF (&inACCLSS.	IN	("177701"))
	THEN &outACCT.="177701";
IF (&inACCLSS.	IN	("510003"))
	THEN &outACCT.="510003";
IF (&inACCLSS.	IN	("876302"))
	THEN &outACCT.="876302";
IF (&inACCLSS.	IN	("067523"))
	THEN &outACCT.="267523";
IF (&inACCLSS.	IN	("133301"))
	THEN &outACCT.="133301";
IF (&inACCLSS.	IN	("261556"))
	THEN &outACCT.="261555";
IF (&inACCLSS.	IN	("122006"))
	THEN &outACCT.="122006";
IF (&inACCLSS.	IN	("391550"))
	THEN &outACCT.="391550";
IF (&inACCLSS.	IN	("344501"))
	THEN &outACCT.="344501";
IF (&inACCLSS.	IN	("812101"))
	THEN &outACCT.="812101";
IF (&inACCLSS.	IN	("547905"))
	THEN &outACCT.="547905";
IF (&inACCLSS.	IN	("344101"))
	THEN &outACCT.="344101";
IF (&inACCLSS.	IN	("710901"))
	THEN &outACCT.="710901";
IF (&inACCLSS.	IN	("144104"))
	THEN &outACCT.="144104";
IF (&inACCLSS.	IN	("392505"))
	THEN &outACCT.="392505";
IF (&inACCLSS.	IN	("710601"))
	THEN &outACCT.="710601";
IF (&inACCLSS.	IN	("333503"))
	THEN &outACCT.="333503";
IF (&inACCLSS.	IN	("144103"))
	THEN &outACCT.="144103";
IF (&inACCLSS.	IN	("221503"))
	THEN &outACCT.="221503";
IF (&inACCLSS.	IN	("559026"))
	THEN &outACCT.="559026";
IF (&inACCLSS.	IN	("890001"))
	THEN &outACCT.="890001";
IF (&inACCLSS.	IN	("559025"))
	THEN &outACCT.="559025";
IF (&inACCLSS.	IN	("122003"))
	THEN &outACCT.="122002";
IF (&inACCLSS.	IN	("333732"))
	THEN &outACCT.="333732";
IF (&inACCLSS.	IN	("268502"))
	THEN &outACCT.="268502";
IF (&inACCLSS.	IN	("170203"))
	THEN &outACCT.="170203";
IF (&inACCLSS.	IN	("177732"))
	THEN &outACCT.="177732";
IF (&inACCLSS.	IN	("555019"))
	THEN &outACCT.="555019";
IF (&inACCLSS.	IN	("860001"))
	THEN &outACCT.="860001";
IF (&inACCLSS.	IN	("866506"))
	THEN &outACCT.="866506";
IF (&inACCLSS.	IN	("133896"))
	THEN &outACCT.="133896";
IF (&inACCLSS.	IN	("139504"))
	THEN &outACCT.="139504";
IF (&inACCLSS.	IN	("124502"))
	THEN &outACCT.="124502";
IF (&inACCLSS.	IN	("510002"))
	THEN &outACCT.="510002";
IF (&inACCLSS.	IN	("875501"))
	THEN &outACCT.="875501";
IF (&inACCLSS.	IN	("344102"))
	THEN &outACCT.="344102";
IF (&inACCLSS.	IN	("546059"))
	THEN &outACCT.="546059";
IF (&inACCLSS.	IN	("515018"))
	THEN &outACCT.="515018";
IF (&inACCLSS.	IN	("170363"))
	THEN &outACCT.="170363";
IF (&inACCLSS.	IN	("288896"))
	THEN &outACCT.="288896";
IF (&inACCLSS.	IN	("932011"))
	AND (&inCUSTSEG.	IN	("110","111","112","113","115","116","121","122"))
	THEN &outACCT.="232067";
IF (&inACCLSS.	IN	("931002"))
	THEN &outACCT.="231001";
IF (&inACCLSS.	IN	("515074"))
	THEN &outACCT.="515074";
IF (&inACCLSS.	IN	("547301"))
	THEN &outACCT.="547301";
IF (&inACCLSS.	IN	("289276"))
	THEN &outACCT.="289276";
IF (&inACCLSS.	IN	("515015"))
	THEN &outACCT.="515015";
IF (&inACCLSS.	IN	("516002"))
	THEN &outACCT.="515016";
IF (&inACCLSS.	IN	("288834"))
	THEN &outACCT.="288832";
IF (&inACCLSS.	IN	("289145"))
	THEN &outACCT.="289145";
IF (&inACCLSS.	IN	("516004"))
	THEN &outACCT.="515016";
IF (&inACCLSS.	IN	("289046"))
	THEN &outACCT.="289046";
IF (&inACCLSS.	IN	("504549"))
	THEN &outACCT.="504549";
IF (&inACCLSS.	IN	("555075"))
	THEN &outACCT.="555075";
IF (&inACCLSS.	IN	("287070"))
	THEN &outACCT.="287070";
IF (&inACCLSS.	IN	("289273"))
	THEN &outACCT.="289273";
IF (&inACCLSS.	IN	("291801"))
	THEN &outACCT.="291801";
IF (&inACCLSS.	IN	("576053"))
	THEN &outACCT.="576053";
IF (&inACCLSS.	IN	("504102"))
	THEN &outACCT.="504102";
IF (&inACCLSS.	IN	("516003"))
	THEN &outACCT.="515110";
IF (&inACCLSS.	IN	("515068"))
	THEN &outACCT.="515068";
IF (&inACCLSS.	IN	("231051"))
	THEN &outACCT.="231051";
IF (&inACCLSS.	IN	("504108"))
	THEN &outACCT.="504108";
IF (&inACCLSS.	IN	("665090"))
	THEN &outACCT.="665090";
IF (&inACCLSS.	IN	("504506"))
	THEN &outACCT.="504506";
IF (&inACCLSS.	IN	("547703"))
	THEN &outACCT.="547703";
IF (&inACCLSS.	IN	("547986"))
	THEN &outACCT.="547986";
IF (&inACCLSS.	IN	("122321"))
	THEN &outACCT.="122321";
IF (&inACCLSS.	IN	("288832"))
	THEN &outACCT.="288832";
IF (&inACCLSS.	IN	("931003"))
	AND (&inPDTCODE.	IN	("355"))
	THEN &outACCT.="231001";
IF (&inACCLSS.	IN	("292701"))
	THEN &outACCT.="292701";
IF (&inACCLSS.	IN	("289169"))
	THEN &outACCT.="289169";
IF (&inACCLSS.	IN	("516001"))
	THEN &outACCT.="515110";
IF (&inACCLSS.	IN	("287551"))
	THEN &outACCT.="287551";
IF (&inACCLSS.	IN	("652519"))
	THEN &outACCT.="652519";
IF (&inACCLSS.	IN	("288821"))
	THEN &outACCT.="288821";
IF (&inACCLSS.	IN	("503077"))
	THEN &outACCT.="503077";
IF (&inACCLSS.	IN	("288288"))
	THEN &outACCT.="288288";
IF (&inACCLSS.	IN	("287096"))
	THEN &outACCT.="287096";
IF (&inACCLSS.	IN	("289958"))
	THEN &outACCT.="289958";
IF (&inPDTCODE.	IN	("990"))
	THEN &outACCT.="289036";
IF (&inPDTCODE.	IN	("802"))
	THEN &outACCT.="299101";
IF (&inPDTCODE.	IN	("805"))
	THEN &outACCT.="299101";
IF (&inPDTCODE.	IN	("801"))
	THEN &outACCT.="299101";
IF (&inPDTCODE.	IN	("804"))
	THEN &outACCT.="299101";
IF (&inPDTCODE.	IN	("771"))
	THEN &outACCT.="299101";
IF (&inPDTCODE.	IN	("772"))
	THEN &outACCT.="299101";
IF (&inPDTCODE.	IN	("803"))
	THEN &outACCT.="299101";
IF (&inACCLSS.	IN	("133736"))
	AND (&inCRGCODE.	NOT IN	("13","14"))
	THEN &outACCT.="133731";
IF (&inACCLSS.	IN	("133736"))
	AND (&inCRGCODE.	IN	("13"))
	THEN &outACCT.="133740";
IF (&inACCLSS.	IN	("132501"))
	AND (&inCRGCODE.	IN	("14"))
	THEN &outACCT.="132565";
IF (&inACCLSS.	IN	("132704"))
	AND (&inCRGCODE.	IN	("14"))
	THEN &outACCT.="132703";
IF (&inACCLSS.	IN	("124502"))
	AND (&inCRGCODE.	IN	("14"))
	THEN &outACCT.="124505";
IF (&inACCLSS.	IN	("132701"))
	AND (&inCRGCODE.	IN	("14"))
	THEN &outACCT.="132703";
IF (&inACCLSS.	IN	("133501"))
	AND (&inCRGCODE.	IN	("14"))
	THEN &outACCT.="133554";
IF (&inACCLSS.	IN	("133312"))
	AND (&inCRGCODE.	IN	("14"))
	THEN &outACCT.="133355";
IF (&inACCLSS.	IN	("133305"))
	AND (&inCRGCODE.	IN	("14"))
	THEN &outACCT.="133355";
IF (&inACCLSS.	IN	("133303"))
	AND (&inCRGCODE.	IN	("14"))
	THEN &outACCT.="133351";
IF (&inACCLSS.	IN	("133301"))
	AND (&inCRGCODE.	IN	("14"))
	THEN &outACCT.="133351";
IF (&inACCLSS.	IN	("133510"))
	AND (&inCRGCODE.	IN	("14"))
	THEN &outACCT.="133551";
IF (&inACCLSS.	IN	("133503"))
	AND (&inCRGCODE.	IN	("14"))
	THEN &outACCT.="133551";
IF (&inACCLSS.	IN	("133732"))
	AND (&inCRGCODE.	IN	("14"))
	THEN &outACCT.="133733";
IF (&inACCLSS.	IN	("133701"))
	AND (&inCRGCODE.	IN	("14"))
	THEN &outACCT.="133705";
IF (&inACCLSS.	IN	("133557"))
	AND (&inCRGCODE.	IN	("14"))
	THEN &outACCT.="133559";
IF (&inACCLSS.	IN	("133562"))
	AND (&inCRGCODE.	IN	("14"))
	THEN &outACCT.="133559";
IF (&inACCLSS.	IN	("133731"))
	AND (&inCRGCODE.	IN	("14"))
	THEN &outACCT.="133740";
IF (&inACCLSS.	IN	("124502"))
	AND (&inCRGCODE.	IN	("13"))
	THEN &outACCT.="124505";
IF (&inACCLSS.	IN	("132704"))
	AND (&inCRGCODE.	IN	("13"))
	THEN &outACCT.="132703";
IF (&inACCLSS.	IN	("132701"))
	AND (&inCRGCODE.	IN	("13"))
	THEN &outACCT.="132703";
IF (&inACCLSS.	IN	("133305"))
	AND (&inCRGCODE.	IN	("13"))
	THEN &outACCT.="133355";
IF (&inACCLSS.	IN	("133501"))
	AND (&inCRGCODE.	IN	("13"))
	THEN &outACCT.="133554";
IF (&inACCLSS.	IN	("133312"))
	AND (&inCRGCODE.	IN	("13"))
	THEN &outACCT.="133355";
IF (&inACCLSS.	IN	("133303"))
	AND (&inCRGCODE.	IN	("13"))
	THEN &outACCT.="133351";
IF (&inACCLSS.	IN	("133301"))
	AND (&inCRGCODE.	IN	("13"))
	THEN &outACCT.="133351";
IF (&inACCLSS.	IN	("133510"))
	AND (&inCRGCODE.	IN	("13"))
	THEN &outACCT.="133551";
IF (&inACCLSS.	IN	("133732"))
	AND (&inCRGCODE.	IN	("13"))
	THEN &outACCT.="133733";
IF (&inACCLSS.	IN	("133503"))
	AND (&inCRGCODE.	IN	("13"))
	THEN &outACCT.="133551";
IF (&inACCLSS.	IN	("133701"))
	AND (&inCRGCODE.	IN	("13"))
	THEN &outACCT.="133705";
IF (&inACCLSS.	IN	("132501"))
	AND (&inCRGCODE.	IN	("13"))
	THEN &outACCT.="132565";
IF (&inACCLSS.	IN	("133731"))
	AND (&inCRGCODE.	IN	("13"))
	THEN &outACCT.="133740";
IF (&inACCLSS.	IN	("133557"))
	AND (&inCRGCODE.	IN	("13"))
	THEN &outACCT.="133559";
IF (&inACCLSS.	IN	("133736"))
	AND (&inCRGCODE.	IN	("14"))
	THEN &outACCT.="133740";
IF (&inACCLSS.	IN	("133562"))
	AND (&inCRGCODE.	IN	("13"))
	THEN &outACCT.="133559";
IF (&inACCLSS.	IN	("431001"))
	AND (&inPDTCODE.	IN	("287"))
	THEN &outACCT.="431103";
IF (&inACCLSS.	IN	("267501"))
	AND (&inPDTCODE.	IN	("287"))
	THEN &outACCT.="267603";
IF (&inACCLSS.	IN	("267501"))
	AND (&inPDTCODE.	IN	("285"))
	THEN &outACCT.="267603";
IF (&inACCLSS.	IN	("431001"))
	AND (&inPDTCODE.	IN	("285"))
	THEN &outACCT.="431103";
IF (&inACCLSS.	IN	("267523"))
	AND (&inPDTCODE.	IN	("517"))
	THEN &outACCT.="267605";
IF (&inACCLSS.	IN	("433105"))
	AND (&inPDTCODE.	IN	("517"))
	THEN &outACCT.="433191";
IF (&inACCLSS.	IN	("267501"))
	AND (&inPDTCODE.	IN	("283"))
	THEN &outACCT.="267603";
IF (&inACCLSS.	IN	("431001"))
	AND (&inPDTCODE.	IN	("283"))
	THEN &outACCT.="431103";
IF (&inACCLSS.	IN	("233105"))
	AND (&inPDTCODE.	IN	("517"))
	THEN &outACCT.="233191";
IF (&inACCLSS.	IN	("233105"))
	AND (&inPDTCODE.	IN	("516"))
	THEN &outACCT.="233191";
IF (&inACCLSS.	IN	("431001"))
	AND (&inPDTCODE.	IN	("282"))
	THEN &outACCT.="431103";
IF (&inACCLSS.	IN	("267501"))
	AND (&inPDTCODE.	IN	("282"))
	THEN &outACCT.="267603";
IF (&inACCLSS.	IN	("433105"))
	AND (&inPDTCODE.	IN	("516"))
	THEN &outACCT.="433191";
IF (&inACCLSS.	IN	("267523"))
	AND (&inPDTCODE.	IN	("516"))
	THEN &outACCT.="267605";
IF (&inACCLSS.	IN	("233105"))
	AND (&inPDTCODE.	IN	("515"))
	THEN &outACCT.="233191";
IF (&inACCLSS.	IN	("267523"))
	AND (&inPDTCODE.	IN	("515"))
	THEN &outACCT.="267605";
IF (&inACCLSS.	IN	("431001"))
	AND (&inPDTCODE.	IN	("281"))
	THEN &outACCT.="431103";
IF (&inACCLSS.	IN	("433105"))
	AND (&inPDTCODE.	IN	("515"))
	THEN &outACCT.="433191";
IF (&inACCLSS.	IN	("267501"))
	AND (&inPDTCODE.	IN	("281"))
	THEN &outACCT.="267603";
IF (&inACCLSS.	IN	("231001"))
	AND (&inPEBAL.	GE	(0))
	THEN &outACCT.="231001";
IF (&inACCLSS.	IN	("267523"))
	AND (&inPDTCODE.	IN	("514"))
	THEN &outACCT.="267605";
IF (&inACCLSS.	IN	("267511"))
	AND (&inPDTCODE.	IN	("286"))
	THEN &outACCT.="267604";
IF (&inACCLSS.	IN	("433105"))
	AND (&inPDTCODE.	IN	("514"))
	THEN &outACCT.="433191";
IF (&inACCLSS.	IN	("431001"))
	AND (&inPDTCODE.	IN	("235"))
	THEN &outACCT.="431103";
IF (&inACCLSS.	IN	("267501"))
	AND (&inPDTCODE.	IN	("235"))
	THEN &outACCT.="267603";
IF (&inACCLSS.	IN	("432011"))
	AND (&inPDTCODE.	IN	("286"))
	THEN &outACCT.="432067";
IF (&inACCLSS.	IN	("233105"))
	AND (&inPDTCODE.	IN	("514"))
	THEN &outACCT.="233191";
IF (&inACCLSS.	IN	("232011"))
	AND (&inPDTCODE.	IN	("286"))
	THEN &outACCT.="232067";
IF (&inACCLSS.	IN	("431001"))
	AND (&inPDTCODE.	IN	("232"))
	THEN &outACCT.="431103";
IF (&inACCLSS.	IN	("267511"))
	AND (&inPDTCODE.	IN	("282"))
	THEN &outACCT.="267604";
IF (&inACCLSS.	IN	("267526"))
	AND (&inPDTCODE.	IN	("518"))
	THEN &outACCT.="267606";
IF (&inACCLSS.	IN	("433105"))
	AND (&inPDTCODE.	IN	("513"))
	THEN &outACCT.="433191";
IF (&inACCLSS.	IN	("267523"))
	AND (&inPDTCODE.	IN	("513"))
	THEN &outACCT.="267605";
IF (&inACCLSS.	IN	("233201"))
	AND (&inPDTCODE.	IN	("518"))
	THEN &outACCT.="233251";
IF (&inACCLSS.	IN	("432011"))
	AND (&inPDTCODE.	IN	("282"))
	THEN &outACCT.="432067";
IF (&inACCLSS.	IN	("433201"))
	AND (&inPDTCODE.	IN	("518"))
	THEN &outACCT.="433253";
IF (&inACCLSS.	IN	("267501"))
	AND (&inPDTCODE.	IN	("232"))
	THEN &outACCT.="267603";
IF (&inACCLSS.	IN	("232011"))
	AND (&inPDTCODE.	IN	("282"))
	THEN &outACCT.="232067";
IF (&inACCLSS.	IN	("233105"))
	AND (&inPDTCODE.	IN	("513"))
	THEN &outACCT.="233191";
IF (&inACCLSS.	IN	("931001"))
	AND (&inPEBAL.	LE	(0))
	THEN &outACCT.="133701";
IF (&inACCLSS.	IN	("231004"))
	AND (&inPEBAL.	LE	(0))
	THEN &outACCT.="133701";
IF (&inACCLSS.	IN	("231001"))
	AND (&inPDTCODE.	IN	("231","232","281","282","283","285","287","235"))
	THEN &outACCT.="231013";
IF (&inACCLSS.	IN	("231001"))
	AND (&inPEBAL.	LT	(0))
	THEN &outACCT.="133701";
IF (&inACCLSS.	IN	("267523"))
	AND (&inPDTCODE.	IN	("512"))
	THEN &outACCT.="267605";
IF (&inACCLSS.	IN	("433174"))
	AND (&inPDTCODE.	IN	("618"))
	THEN &outACCT.="433124";
IF (&inACCLSS.	IN	("233201"))
	AND (&inPDTCODE.	IN	("511"))
	THEN &outACCT.="233251";
IF (&inACCLSS.	IN	("232011"))
	AND (&inPDTCODE.	IN	("233"))
	THEN &outACCT.="232067";
IF (&inACCLSS.	IN	("333705"))
	AND (&inPDTCODE.	IN	("340"))
	THEN &outACCT.="333701";
IF (&inACCLSS.	IN	("267526"))
	AND (&inPDTCODE.	IN	("511"))
	THEN &outACCT.="267606";
IF (&inACCLSS.	IN	("233161"))
	AND (&inPDTCODE.	IN	("618"))
	THEN &outACCT.="233124";
IF (&inACCLSS.	IN	("233105"))
	AND (&inPDTCODE.	IN	("512"))
	THEN &outACCT.="233191";
IF (&inACCLSS.	IN	("267511"))
	AND (&inPDTCODE.	IN	("233"))
	THEN &outACCT.="267604";
IF (&inACCLSS.	IN	("267538"))
	AND (&inPDTCODE.	IN	("618"))
	THEN &outACCT.="267664";
IF (&inACCLSS.	IN	("433201"))
	AND (&inPDTCODE.	IN	("511"))
	THEN &outACCT.="433253";
IF (&inACCLSS.	IN	("431001"))
	AND (&inPDTCODE.	IN	("231"))
	THEN &outACCT.="431103";
IF (&inACCLSS.	IN	("433105"))
	AND (&inPDTCODE.	IN	("512"))
	THEN &outACCT.="433191";
IF (&inACCLSS.	IN	("267501"))
	AND (&inPDTCODE.	IN	("231"))
	THEN &outACCT.="267603";
IF (&inACCLSS.	IN	("432011"))
	AND (&inPDTCODE.	IN	("233"))
	THEN &outACCT.="432067";
IF (&inACCLSS.	IN	("431002"))
	AND (&inPDTCODE.	IN	("340"))
	THEN &outACCT.="431001";
IF (&inACCLSS.	IN	("231004"))
	AND (&inPEBAL.	GE	(0))
	THEN &outACCT.="231001";
IF (&inACCLSS.	IN	("931001"))
	AND (&inPEBAL.	GE	(0))
	THEN &outACCT.="231001";
%mend cdwmap_ACCLSS_EBBStoPSGL;
