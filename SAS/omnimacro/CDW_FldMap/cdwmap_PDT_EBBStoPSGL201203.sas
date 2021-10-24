%macro cdwmap_PDT_EBBStoPSGL(
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
	,outPDTCODE=
);
IF (&inPDTCODE.	IN	("353"))
	THEN &outPDTCODE.="390";
IF (&inPDTCODE.	IN	("353"))
	AND (&inSEGCODE.	IN	("57"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("352"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("245"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("204"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("66"))
	AND (&inACCLSS.	IN	("515018","515001"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("245"))
	AND (&inACCLSS.	IN	("231004"))
	THEN &outPDTCODE.="340";
IF (&inPDTCODE.	IN	("204"))
	AND (&inACCLSS.	IN	("231004"))
	THEN &outPDTCODE.="340";
IF (&inPDTCODE.	IN	("215"))
	THEN &outPDTCODE.="587";
IF (&inPDTCODE.	IN	("353"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("65"))
	AND (&inACCLSS.	IN	("515018","515001"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("352"))
	THEN &outPDTCODE.="360";
IF (&inPDTCODE.	IN	("215"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("353"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("352"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("245"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("204"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("249"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("248"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("247"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("246"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("244"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("243"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("242"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("241"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("209"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("207"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("208"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("206"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("205"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("203"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("201"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("202"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("63"))
	AND (&inACCLSS.	IN	("515018","515001"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("501"))
	THEN &outPDTCODE.="347";
IF (&inPDTCODE.	IN	("205"))
	AND (&inACCLSS.	IN	("231004"))
	THEN &outPDTCODE.="340";
IF (&inPDTCODE.	IN	("206"))
	AND (&inACCLSS.	IN	("231004"))
	THEN &outPDTCODE.="340";
IF (&inPDTCODE.	IN	("207"))
	AND (&inACCLSS.	IN	("231004"))
	THEN &outPDTCODE.="340";
IF (&inPDTCODE.	IN	("201"))
	AND (&inACCLSS.	IN	("231004"))
	THEN &outPDTCODE.="340";
IF (&inPDTCODE.	IN	("209"))
	AND (&inACCLSS.	IN	("231004"))
	THEN &outPDTCODE.="340";
IF (&inPDTCODE.	IN	("203"))
	AND (&inACCLSS.	IN	("231004"))
	THEN &outPDTCODE.="340";
IF (&inPDTCODE.	IN	("202"))
	AND (&inACCLSS.	IN	("231004"))
	THEN &outPDTCODE.="340";
IF (&inPDTCODE.	IN	("208"))
	AND (&inACCLSS.	IN	("231004"))
	THEN &outPDTCODE.="340";
IF (&inPDTCODE.	IN	("241"))
	AND (&inACCLSS.	IN	("231004"))
	THEN &outPDTCODE.="340";
IF (&inPDTCODE.	IN	("249"))
	AND (&inACCLSS.	IN	("231004"))
	THEN &outPDTCODE.="340";
IF (&inPDTCODE.	IN	("242"))
	AND (&inACCLSS.	IN	("231004"))
	THEN &outPDTCODE.="340";
IF (&inPDTCODE.	IN	("248"))
	AND (&inACCLSS.	IN	("231004"))
	THEN &outPDTCODE.="340";
IF (&inPDTCODE.	IN	("247"))
	AND (&inACCLSS.	IN	("231004"))
	THEN &outPDTCODE.="340";
IF (&inPDTCODE.	IN	("246"))
	AND (&inACCLSS.	IN	("231004"))
	THEN &outPDTCODE.="340";
IF (&inPDTCODE.	IN	("244"))
	AND (&inACCLSS.	IN	("231004"))
	THEN &outPDTCODE.="340";
IF (&inPDTCODE.	IN	("243"))
	AND (&inACCLSS.	IN	("231004"))
	THEN &outPDTCODE.="340";
IF (&inPDTCODE.	IN	("258"))
	THEN &outPDTCODE.="587";
IF (&inPDTCODE.	IN	("501"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("215"))
	AND (&inSEGCODE.	IN	("57"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("353"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("352"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("210"))
	THEN &outPDTCODE.="331";
IF (&inPDTCODE.	IN	("308"))
	THEN &outPDTCODE.="347";
IF (&inPDTCODE.	IN	("301"))
	THEN &outPDTCODE.="347";
IF (&inPDTCODE.	IN	("257"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("256"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("255"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("254"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("253"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("252"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("251"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("250"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("245"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("277"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("326"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("280"))
	THEN &outPDTCODE.="349";
IF (&inPDTCODE.	IN	("307"))
	THEN &outPDTCODE.="386";
IF (&inPDTCODE.	IN	("306"))
	THEN &outPDTCODE.="386";
IF (&inPDTCODE.	IN	("305"))
	THEN &outPDTCODE.="386";
IF (&inPDTCODE.	IN	("304"))
	THEN &outPDTCODE.="386";
IF (&inPDTCODE.	IN	("303"))
	THEN &outPDTCODE.="386";
IF (&inPDTCODE.	IN	("214"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("213"))
	THEN &outPDTCODE.="349";
IF (&inPDTCODE.	IN	("212"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("211"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("204"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("302"))
	THEN &outPDTCODE.="386";
IF (&inPDTCODE.	IN	("368"))
	THEN &outPDTCODE.="349";
IF (&inPDTCODE.	IN	("355"))
	THEN &outPDTCODE.="349";
IF (&inPDTCODE.	IN	("643"))
	THEN &outPDTCODE.="761";
IF (&inPDTCODE.	IN	("501"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("368"))
	AND (&inACCLSS.	IN	("547703"))
	AND (&inSEGCODE.	IN	("52","54","55","56"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("355"))
	AND (&inACCLSS.	IN	("547703"))
	AND (&inSEGCODE.	IN	("52","54","55","56"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("353"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("352"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("210"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("503"))
	THEN &outPDTCODE.="386";
IF (&inPDTCODE.	IN	("308"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("307"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("306"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("305"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("304"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("303"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("513"))
	THEN &outPDTCODE.="386";
IF (&inPDTCODE.	IN	("302"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("301"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("280"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("258"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("257"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("256"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("255"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("254"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("253"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("252"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("251"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("250"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("249"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("248"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("247"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("246"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("244"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("243"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("242"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("241"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("215"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("277"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("326"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("643"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="209";
IF (&inPDTCODE.	IN	("213"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("214"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("212"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("282"))
	THEN &outPDTCODE.="343";
IF (&inPDTCODE.	IN	("204"))
	AND (&inSEGCODE.	IN	("57"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("211"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("209"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("208"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("207"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("206"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("205"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("203"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("202"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("201"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("245"))
	AND (&inSEGCODE.	IN	("57"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("264"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("232"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("61"))
	AND (&inACCLSS.	IN	("515018","515001"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("513"))
	AND (&inSEGCODE.	IN	("57"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("282"))
	AND (&inSEGCODE.	IN	("57"))
	THEN &outPDTCODE.="225";
IF (&inPDTCODE.	IN	("643"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="209";
IF (&inPDTCODE.	IN	("501"))
	AND (&inSEGCODE.	IN	("57"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("517"))
	THEN &outPDTCODE.="386";
IF (&inPDTCODE.	IN	("516"))
	THEN &outPDTCODE.="386";
IF (&inPDTCODE.	IN	("512"))
	THEN &outPDTCODE.="386";
IF (&inPDTCODE.	IN	("515"))
	THEN &outPDTCODE.="386";
IF (&inPDTCODE.	IN	("514"))
	THEN &outPDTCODE.="386";
IF (&inPDTCODE.	IN	("202"))
	AND (&inACCLSS.	IN	("231004"))
	THEN &outPDTCODE.="340";
IF (&inPDTCODE.	IN	("368"))
	AND (&inACCLSS.	IN	("547703"))
	THEN &outPDTCODE.="410";
IF (&inPDTCODE.	IN	("503"))
	AND (&inSEGCODE.	IN	("57"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("232"))
	AND (&inSEGCODE.	IN	("57"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("285"))
	THEN &outPDTCODE.="587";
IF (&inPDTCODE.	IN	("355"))
	AND (&inACCLSS.	IN	("547703"))
	THEN &outPDTCODE.="410";
IF (&inPDTCODE.	IN	("353"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("352"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("507"))
	THEN &outPDTCODE.="386";
IF (&inPDTCODE.	IN	("317"))
	THEN &outPDTCODE.="386";
IF (&inPDTCODE.	IN	("502"))
	THEN &outPDTCODE.="386";
IF (&inPDTCODE.	IN	("314"))
	THEN &outPDTCODE.="386";
IF (&inPDTCODE.	IN	("313"))
	THEN &outPDTCODE.="386";
IF (&inPDTCODE.	IN	("316"))
	THEN &outPDTCODE.="386";
IF (&inPDTCODE.	IN	("315"))
	THEN &outPDTCODE.="386";
IF (&inPDTCODE.	IN	("312"))
	THEN &outPDTCODE.="386";
IF (&inPDTCODE.	IN	("210"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("506"))
	THEN &outPDTCODE.="386";
IF (&inPDTCODE.	IN	("505"))
	THEN &outPDTCODE.="386";
IF (&inPDTCODE.	IN	("504"))
	THEN &outPDTCODE.="386";
IF (&inPDTCODE.	IN	("308"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("307"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("306"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("305"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("304"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("303"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("302"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("301"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("280"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("258"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("257"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("256"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("255"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("254"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("253"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("252"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("251"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("250"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("249"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("248"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("247"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("246"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("244"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("243"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("242"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("241"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("215"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("269"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("245"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("204"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("277"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("268"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("326"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("213"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("214"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("212"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("211"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("208"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("209"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("207"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("206"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("205"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("202"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("203"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("201"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("711"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("713"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("710"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("814"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("708"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("518"))
	THEN &outPDTCODE.="347";
IF (&inPDTCODE.	IN	("706"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("707"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("716"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("812"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("702"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("701"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("705"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("511"))
	THEN &outPDTCODE.="347";
IF (&inPDTCODE.	IN	("709"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("714"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("715"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("720"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("712"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("813"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("717"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("653"))
	THEN &outPDTCODE.="349";
IF (&inPDTCODE.	IN	("719"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("508"))
	THEN &outPDTCODE.="347";
IF (&inPDTCODE.	IN	("365"))
	THEN &outPDTCODE.="397";
IF (&inPDTCODE.	IN	("366"))
	THEN &outPDTCODE.="399";
IF (&inPDTCODE.	IN	("364"))
	THEN &outPDTCODE.="396";
IF (&inPDTCODE.	IN	("363"))
	THEN &outPDTCODE.="394";
IF (&inPDTCODE.	IN	("362"))
	THEN &outPDTCODE.="392";
IF (&inPDTCODE.	IN	("361"))
	THEN &outPDTCODE.="391";
IF (&inPDTCODE.	IN	("360"))
	THEN &outPDTCODE.="379";
IF (&inPDTCODE.	IN	("359"))
	THEN &outPDTCODE.="379";
IF (&inPDTCODE.	IN	("358"))
	THEN &outPDTCODE.="370";
IF (&inPDTCODE.	IN	("357"))
	THEN &outPDTCODE.="366";
IF (&inPDTCODE.	IN	("356"))
	THEN &outPDTCODE.="362";
IF (&inPDTCODE.	IN	("354"))
	THEN &outPDTCODE.="419";
IF (&inPDTCODE.	IN	("319"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("351"))
	THEN &outPDTCODE.="361";
IF (&inPDTCODE.	IN	("318"))
	THEN &outPDTCODE.="347";
IF (&inPDTCODE.	IN	("311"))
	THEN &outPDTCODE.="347";
IF (&inPDTCODE.	IN	("309"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("290"))
	THEN &outPDTCODE.="349";
IF (&inPDTCODE.	IN	("287"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("286"))
	THEN &outPDTCODE.="332";
IF (&inPDTCODE.	IN	("284"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("283"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("281"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("261"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("263"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("262"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("260"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("259"))
	THEN &outPDTCODE.="332";
IF (&inPDTCODE.	IN	("240"))
	THEN &outPDTCODE.="349";
IF (&inPDTCODE.	IN	("235"))
	THEN &outPDTCODE.="331";
IF (&inPDTCODE.	IN	("230"))
	THEN &outPDTCODE.="349";
IF (&inPDTCODE.	IN	("234"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("233"))
	THEN &outPDTCODE.="332";
IF (&inPDTCODE.	IN	("217"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("216"))
	THEN &outPDTCODE.="332";
IF (&inPDTCODE.	IN	("163"))
	THEN &outPDTCODE.="311";
IF (&inPDTCODE.	IN	("141"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("144"))
	THEN &outPDTCODE.="311";
IF (&inPDTCODE.	IN	("142"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("123"))
	THEN &outPDTCODE.="311";
IF (&inPDTCODE.	IN	("122"))
	THEN &outPDTCODE.="311";
IF (&inPDTCODE.	IN	("120"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("119"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("117"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("116"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("115"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("111"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("114"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("113"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("112"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("110"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("109"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("108"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("102"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("107"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("106"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("105"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("101"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("275"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("340"))
	THEN &outPDTCODE.="340";
IF (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("60"))
	AND (&inACCLSS.	IN	("515018","515001"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("340"))
	AND (&inACCLSS.	IN	("231003"))
	AND (&inPEBAL.	LT	(0))
	THEN &outPDTCODE.="341";
IF (&inPDTCODE.	IN	("368"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("275"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("814"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("813"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("812"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("720"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="171";
IF (&inPDTCODE.	IN	("719"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="171";
IF (&inPDTCODE.	IN	("717"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("716"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("715"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("714"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("713"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("712"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("711"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("710"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("709"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("708"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("707"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("706"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("705"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("702"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("701"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("653"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("643"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="209";
IF (&inPDTCODE.	IN	("518"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("517"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("516"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("515"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("514"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("513"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("512"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("511"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("508"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("507"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("506"))
	AND (&inSEGCODE.	IN	("56","58","59"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("505"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("504"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("503"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("502"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("501"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("366"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("365"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("364"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("363"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("362"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("361"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("360"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("359"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("358"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("357"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("356"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("355"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("354"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="569";
IF (&inPDTCODE.	IN	("353"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("352"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("351"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("319"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("318"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("317"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("316"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("315"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("314"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("313"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("312"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("311"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("309"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("290"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("287"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("286"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("285"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("284"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("283"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("282"))
	AND (&inSEGCODE.	IN	("56","58","59"))
	THEN &outPDTCODE.="225";
IF (&inPDTCODE.	IN	("281"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("264"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("263"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("262"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("261"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("260"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("259"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("240"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("235"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("234"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("233"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("232"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("230"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("144"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("123"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="209";
IF (&inPDTCODE.	IN	("122"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="209";
IF (&inPDTCODE.	IN	("217"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("216"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("210"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("163"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="209";
IF (&inPDTCODE.	IN	("142"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("141"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("120"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="171";
IF (&inPDTCODE.	IN	("119"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="171";
IF (&inPDTCODE.	IN	("117"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("116"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("115"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("114"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("113"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("112"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("111"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("110"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("109"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("108"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("107"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("106"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("105"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("102"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("101"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("269"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("277"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("268"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("326"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("308"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("307"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("306"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("305"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("304"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("303"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("302"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("301"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("280"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("258"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("257"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("256"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("255"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("254"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("253"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("252"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("251"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("250"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("249"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("248"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("247"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("246"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("245"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("243"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("242"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("241"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("215"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("214"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("213"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("212"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("211"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("209"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("208"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("207"))
	AND (&inSEGCODE.	IN	("56","57"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("206"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("205"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("204"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("203"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("202"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("201"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("244"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("340"))
	AND (&inACCLSS.	IN	("931001"))
	AND (&inPEBAL.	LE	(0))
	THEN &outPDTCODE.="341";
IF (&inPDTCODE.	IN	("368"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("269"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("277"))
	AND (&inSEGCODE.	IN	("53"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("326"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("268"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("712"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("711"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("710"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("719"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="171";
IF (&inPDTCODE.	IN	("814"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("707"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("702"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("812"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("701"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("713"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("716"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("518"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("709"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("517"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("511"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("715"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("813"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("164"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="203";
IF (&inPDTCODE.	IN	("161"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="203";
IF (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="110";
IF (&inPDTCODE.	IN	("720"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="171";
IF (&inPDTCODE.	IN	("717"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("706"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("714"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("708"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("512"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("508"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("507"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("505"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("504"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("503"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("502"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("501"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("362"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("365"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("361"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("357"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("353"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("316"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("318"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("314"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("309"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("305"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("290"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("301"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("286"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("285"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("281"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("264"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("263"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("262"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("258"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("254"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("253"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("252"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("251"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("255"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("250"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("256"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("257"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("249"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("248"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("259"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("260"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("247"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("243"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("246"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("261"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("245"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("244"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("280"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("242"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("241"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("282"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="225";
IF (&inPDTCODE.	IN	("283"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("240"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("284"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("235"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("234"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("233"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("287"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("232"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("215"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("230"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("217"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("302"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("303"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("216"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("304"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("214"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("213"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("306"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("307"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("308"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("212"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("211"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("311"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("210"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("312"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("209"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("313"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("208"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("315"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("207"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("206"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("317"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("205"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("319"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("204"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("351"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("203"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("352"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("202"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("201"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("354"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="569";
IF (&inPDTCODE.	IN	("355"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("163"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="209";
IF (&inPDTCODE.	IN	("356"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("358"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("144"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="209";
IF (&inPDTCODE.	IN	("142"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("359"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("360"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("120"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="171";
IF (&inPDTCODE.	IN	("141"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("123"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="209";
IF (&inPDTCODE.	IN	("363"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("122"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="209";
IF (&inPDTCODE.	IN	("364"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("119"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="171";
IF (&inPDTCODE.	IN	("366"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("117"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("116"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("115"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("114"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("113"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("112"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("108"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("111"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("110"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("109"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("107"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("106"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("105"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("102"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("101"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("705"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("653"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("643"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="209";
IF (&inPDTCODE.	IN	("516"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("515"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("514"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("513"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("506"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("275"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("817"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("340"))
	AND (&inACCLSS.	IN	("231004"))
	AND (&inPEBAL.	LE	(0))
	THEN &outPDTCODE.="341";
IF (&inPDTCODE.	IN	("275"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("817"))
	AND (&inACCLSS.	IN	("175101"))
	THEN &outPDTCODE.="761";
IF (&inPDTCODE.	IN	("368"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("269"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("277"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("326"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("268"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("712"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("711"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("719"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="171";
IF (&inPDTCODE.	IN	("710"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("237"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("708"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("814"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("707"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("702"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("713"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("812"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("701"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("716"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("518"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("517"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("511"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("715"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("706"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("709"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("813"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("164"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="203";
IF (&inPDTCODE.	IN	("161"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="203";
IF (&inPDTCODE.	IN	("714"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("720"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="171";
IF (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("717"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("705"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("506"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("502"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("366"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("365"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("364"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("363"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("362"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("361"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("360"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("359"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("357"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("356"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("355"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("354"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="569";
IF (&inPDTCODE.	IN	("353"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("352"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("351"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("319"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("318"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("317"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("316"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("315"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("314"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("313"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("311"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("309"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("308"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("307"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("306"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("305"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("304"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("303"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("302"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("301"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("290"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("287"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("286"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("285"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("283"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("282"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="225";
IF (&inPDTCODE.	IN	("281"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("280"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("264"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("262"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("261"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("260"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("259"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("258"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("254"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("257"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("256"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("255"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("253"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("252"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("251"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("250"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("249"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("248"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("247"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("246"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("245"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("244"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("243"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("235"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("242"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("241"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("240"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("234"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("233"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("232"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("284"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("230"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("217"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("216"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("215"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("211"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("214"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("213"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("212"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("210"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("209"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("208"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("207"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("312"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("206"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("205"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("204"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("163"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="209";
IF (&inPDTCODE.	IN	("203"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("202"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("201"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("144"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="209";
IF (&inPDTCODE.	IN	("142"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("141"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("123"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="209";
IF (&inPDTCODE.	IN	("358"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("122"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="209";
IF (&inPDTCODE.	IN	("120"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="171";
IF (&inPDTCODE.	IN	("119"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="171";
IF (&inPDTCODE.	IN	("117"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("116"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("115"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("114"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("113"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("112"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("111"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("110"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("501"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("109"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("108"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("503"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("504"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("107"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("505"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("106"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("507"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("105"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("102"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("508"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("101"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("512"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("643"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="209";
IF (&inPDTCODE.	IN	("653"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("263"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("516"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("515"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("514"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("513"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("391"))
	THEN &outPDTCODE.="349";
IF (&inPDTCODE.	IN	("388"))
	THEN &outPDTCODE.="251";
IF (&inPDTCODE.	IN	("275"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("340"))
	AND (&inACCLSS.	IN	("231001"))
	AND (&inPEBAL.	LT	(0))
	THEN &outPDTCODE.="341";
IF (&inPDTCODE.	IN	("391"))
	AND (&inSEGCODE.	IN	("52","54","55","56","58","59"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("817"))
	AND (&inACCLSS.	IN	("175153"))
	THEN &outPDTCODE.="761";
IF (&inPDTCODE.	IN	("388"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("344"))
	THEN &outPDTCODE.="587";
IF (&inPDTCODE.	IN	("343"))
	THEN &outPDTCODE.="591";
IF (&inPDTCODE.	IN	("631"))
	THEN &outPDTCODE.="761";
IF (&inPDTCODE.	IN	("342"))
	THEN &outPDTCODE.="599";
IF (&inPDTCODE.	IN	("341"))
	THEN &outPDTCODE.="586";
IF (&inPDTCODE.	IN	("298"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("626"))
	THEN &outPDTCODE.="325";
IF (&inPDTCODE.	IN	("628"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("670"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("279"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("629"))
	THEN &outPDTCODE.="411";
IF (&inPDTCODE.	IN	("267"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("368"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("278"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("389"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("382"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("666"))
	THEN &outPDTCODE.="349";
IF (&inPDTCODE.	IN	("394"))
	THEN &outPDTCODE.="351";
IF (&inPDTCODE.	IN	("732"))
	THEN &outPDTCODE.="325";
IF (&inPDTCODE.	IN	("821"))
	THEN &outPDTCODE.="569";
IF (&inPDTCODE.	IN	("239"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("381"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("383"))
	THEN &outPDTCODE.="599";
IF (&inPDTCODE.	IN	("522"))
	THEN &outPDTCODE.="333";
IF (&inPDTCODE.	IN	("521"))
	THEN &outPDTCODE.="333";
IF (&inPDTCODE.	IN	("379"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("496"))
	THEN &outPDTCODE.="449";
IF (&inPDTCODE.	IN	("495"))
	THEN &outPDTCODE.="440";
IF (&inPDTCODE.	IN	("494"))
	THEN &outPDTCODE.="442";
IF (&inPDTCODE.	IN	("276"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("218"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("493"))
	THEN &outPDTCODE.="446";
IF (&inPDTCODE.	IN	("492"))
	THEN &outPDTCODE.="446";
IF (&inPDTCODE.	IN	("393"))
	THEN &outPDTCODE.="446";
IF (&inPDTCODE.	IN	("238"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("371"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("576"))
	THEN &outPDTCODE.="277";
IF (&inPDTCODE.	IN	("392"))
	THEN &outPDTCODE.="446";
IF (&inPDTCODE.	IN	("370"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("729"))
	THEN &outPDTCODE.="288";
IF (&inPDTCODE.	IN	("129"))
	THEN &outPDTCODE.="288";
IF (&inPDTCODE.	IN	("269"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("229"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("323"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("850"))
	THEN &outPDTCODE.="349";
IF (&inPDTCODE.	IN	("322"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("130"))
	THEN &outPDTCODE.="325";
IF (&inPDTCODE.	IN	("730"))
	THEN &outPDTCODE.="325";
IF (&inPDTCODE.	IN	("731"))
	THEN &outPDTCODE.="703";
IF (&inPDTCODE.	IN	("220"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("321"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("277"))
	AND (&inSEGCODE.	IN	("51"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("560"))
	THEN &outPDTCODE.="560";
IF (&inPDTCODE.	IN	("320"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("326"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("219"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("299"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("348"))
	THEN &outPDTCODE.="585";
IF (&inPDTCODE.	IN	("347"))
	THEN &outPDTCODE.="589";
IF (&inPDTCODE.	IN	("491"))
	THEN &outPDTCODE.="495";
IF (&inPDTCODE.	IN	("346"))
	THEN &outPDTCODE.="585";
IF (&inPDTCODE.	IN	("345"))
	THEN &outPDTCODE.="592";
IF (&inPDTCODE.	IN	("449"))
	THEN &outPDTCODE.="449";
IF (&inPDTCODE.	IN	("753"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("712"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("154"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("153"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("910"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("754"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("719"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="171";
IF (&inPDTCODE.	IN	("831"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("274"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("273"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("711"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("272"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("271"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("270"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("829"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("826"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("710"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("563"))
	THEN &outPDTCODE.="563";
IF (&inPDTCODE.	IN	("659"))
	THEN &outPDTCODE.="883";
IF (&inPDTCODE.	IN	("145"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("708"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("237"))
	AND (&inSEGCODE.	IN	("51","52","53","54","55","56","60","65","66"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("814"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("830"))
	THEN &outPDTCODE.="272";
IF (&inPDTCODE.	IN	("236"))
	THEN &outPDTCODE.="599";
IF (&inPDTCODE.	IN	("713"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("718"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("707"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("702"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("741"))
	THEN &outPDTCODE.="325";
IF (&inPDTCODE.	IN	("295"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("225"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("137"))
	THEN &outPDTCODE.="173";
IF (&inPDTCODE.	IN	("135"))
	THEN &outPDTCODE.="173";
IF (&inPDTCODE.	IN	("125"))
	THEN &outPDTCODE.="173";
IF (&inPDTCODE.	IN	("134"))
	THEN &outPDTCODE.="181";
IF (&inPDTCODE.	IN	("124"))
	THEN &outPDTCODE.="172";
IF (&inPDTCODE.	IN	("133"))
	THEN &outPDTCODE.="170";
IF (&inPDTCODE.	IN	("991"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("990"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("575"))
	THEN &outPDTCODE.="763";
IF (&inPDTCODE.	IN	("574"))
	THEN &outPDTCODE.="763";
IF (&inPDTCODE.	IN	("573"))
	THEN &outPDTCODE.="763";
IF (&inPDTCODE.	IN	("572"))
	THEN &outPDTCODE.="260";
IF (&inPDTCODE.	IN	("571"))
	THEN &outPDTCODE.="260";
IF (&inPDTCODE.	IN	("385"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("384"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("378"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("377"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("376"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("375"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("374"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("367"))
	THEN &outPDTCODE.="325";
IF (&inPDTCODE.	IN	("226"))
	THEN &outPDTCODE.="225";
IF (&inPDTCODE.	IN	("294"))
	THEN &outPDTCODE.="225";
IF (&inPDTCODE.	IN	("224"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("293"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("716"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("292"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("291"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("223"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("222"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("701"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("221"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("548"))
	THEN &outPDTCODE.="758";
IF (&inPDTCODE.	IN	("547"))
	THEN &outPDTCODE.="758";
IF (&inPDTCODE.	IN	("017"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("518"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("811"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("706"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("725"))
	THEN &outPDTCODE.="710";
IF (&inPDTCODE.	IN	("825"))
	THEN &outPDTCODE.="";
IF (&inPDTCODE.	IN	("625"))
	THEN &outPDTCODE.="787";
IF (&inPDTCODE.	IN	("517"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("805"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("804"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("511"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("715"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("803"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("136"))
	THEN &outPDTCODE.="173";
IF (&inPDTCODE.	IN	("802"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("020"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("019"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("801"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("018"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("002"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("762"))
	THEN &outPDTCODE.="349";
IF (&inPDTCODE.	IN	("016"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("015"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("709"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("752"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("014"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("013"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("165"))
	THEN &outPDTCODE.="349";
IF (&inPDTCODE.	IN	("751"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("012"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("011"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("010"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("009"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("723"))
	THEN &outPDTCODE.="737";
IF (&inPDTCODE.	IN	("008"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("007"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("167"))
	THEN &outPDTCODE.="349";
IF (&inPDTCODE.	IN	("714"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("006"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("166"))
	THEN &outPDTCODE.="349";
IF (&inPDTCODE.	IN	("005"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("654"))
	THEN &outPDTCODE.="100";
IF (&inPDTCODE.	IN	("720"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="171";
IF (&inPDTCODE.	IN	("004"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("813"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("728"))
	THEN &outPDTCODE.="204";
IF (&inPDTCODE.	IN	("727"))
	THEN &outPDTCODE.="110";
IF (&inPDTCODE.	IN	("003"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("164"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="203";
IF (&inPDTCODE.	IN	("772"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("161"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="203";
IF (&inPDTCODE.	IN	("812"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("771"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("816"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("443"))
	THEN &outPDTCODE.="443";
IF (&inPDTCODE.	IN	("001"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("815"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("642"))
	THEN &outPDTCODE.="569";
IF (&inPDTCODE.	IN	("726"))
	THEN &outPDTCODE.="850";
IF (&inPDTCODE.	IN	("373"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("297"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="171";
IF (&inPDTCODE.	IN	("228"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("296"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("372"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("999"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("227"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("265"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("266"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("717"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("998"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("390"))
	THEN &outPDTCODE.="101";
IF (&inPDTCODE.	IN	("724"))
	THEN &outPDTCODE.="325";
IF (&inPDTCODE.	IN	("705"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("997"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("630"))
	THEN &outPDTCODE.="411";
IF (&inPDTCODE.	IN	("508"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("507"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("506"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("505"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("504"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("503"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("502"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("428"))
	THEN &outPDTCODE.="509";
IF (&inPDTCODE.	IN	("501"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("439"))
	THEN &outPDTCODE.="555";
IF (&inPDTCODE.	IN	("438"))
	THEN &outPDTCODE.="531";
IF (&inPDTCODE.	IN	("436"))
	THEN &outPDTCODE.="525";
IF (&inPDTCODE.	IN	("435"))
	THEN &outPDTCODE.="520";
IF (&inPDTCODE.	IN	("434"))
	THEN &outPDTCODE.="515";
IF (&inPDTCODE.	IN	("431"))
	THEN &outPDTCODE.="535";
IF (&inPDTCODE.	IN	("429"))
	THEN &outPDTCODE.="535";
IF (&inPDTCODE.	IN	("410"))
	THEN &outPDTCODE.="490";
IF (&inPDTCODE.	IN	("427"))
	THEN &outPDTCODE.="442";
IF (&inPDTCODE.	IN	("425"))
	THEN &outPDTCODE.="569";
IF (&inPDTCODE.	IN	("423"))
	THEN &outPDTCODE.="555";
IF (&inPDTCODE.	IN	("422"))
	THEN &outPDTCODE.="551";
IF (&inPDTCODE.	IN	("420"))
	THEN &outPDTCODE.="545";
IF (&inPDTCODE.	IN	("419"))
	THEN &outPDTCODE.="540";
IF (&inPDTCODE.	IN	("418"))
	THEN &outPDTCODE.="531";
IF (&inPDTCODE.	IN	("416"))
	THEN &outPDTCODE.="525";
IF (&inPDTCODE.	IN	("415"))
	THEN &outPDTCODE.="520";
IF (&inPDTCODE.	IN	("414"))
	THEN &outPDTCODE.="515";
IF (&inPDTCODE.	IN	("411"))
	THEN &outPDTCODE.="481";
IF (&inPDTCODE.	IN	("408"))
	THEN &outPDTCODE.="481";
IF (&inPDTCODE.	IN	("407"))
	THEN &outPDTCODE.="480";
IF (&inPDTCODE.	IN	("406"))
	THEN &outPDTCODE.="472";
IF (&inPDTCODE.	IN	("405"))
	THEN &outPDTCODE.="471";
IF (&inPDTCODE.	IN	("404"))
	THEN &outPDTCODE.="470";
IF (&inPDTCODE.	IN	("402"))
	THEN &outPDTCODE.="441";
IF (&inPDTCODE.	IN	("401"))
	THEN &outPDTCODE.="440";
IF (&inPDTCODE.	IN	("665"))
	THEN &outPDTCODE.="349";
IF (&inPDTCODE.	IN	("366"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("365"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("364"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("363"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("362"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("361"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("360"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("359"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("358"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("354"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="569";
IF (&inPDTCODE.	IN	("357"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("356"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("355"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("353"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("818"))
	THEN &outPDTCODE.="910";
IF (&inPDTCODE.	IN	("352"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("351"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="250";
IF (&inPDTCODE.	IN	("319"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("318"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("317"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("316"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("315"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("314"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("313"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("312"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("307"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("311"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("309"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("308"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("306"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("305"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("304"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("303"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("302"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("301"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("290"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("287"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("286"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("285"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("284"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("280"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("283"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("282"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="225";
IF (&inPDTCODE.	IN	("281"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("264"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("263"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("262"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("261"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("260"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("259"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("257"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("256"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("255"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("254"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("250"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("253"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("252"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("251"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("249"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("248"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("258"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("247"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("246"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("245"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("244"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("243"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("242"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("241"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("240"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("235"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("234"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("233"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("232"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("231"))
	THEN &outPDTCODE.="599";
IF (&inPDTCODE.	IN	("230"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("217"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("216"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("215"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("214"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("213"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("212"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("211"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("207"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("210"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("209"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("208"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("206"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("205"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("204"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("203"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("202"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("201"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("164"))
	THEN &outPDTCODE.="300";
IF (&inPDTCODE.	IN	("163"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="209";
IF (&inPDTCODE.	IN	("162"))
	THEN &outPDTCODE.="349";
IF (&inPDTCODE.	IN	("161"))
	THEN &outPDTCODE.="300";
IF (&inPDTCODE.	IN	("152"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("151"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("144"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="209";
IF (&inPDTCODE.	IN	("143"))
	THEN &outPDTCODE.="349";
IF (&inPDTCODE.	IN	("142"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("141"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("123"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="209";
IF (&inPDTCODE.	IN	("122"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="209";
IF (&inPDTCODE.	IN	("120"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="171";
IF (&inPDTCODE.	IN	("115"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("119"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="171";
IF (&inPDTCODE.	IN	("118"))
	THEN &outPDTCODE.="170";
IF (&inPDTCODE.	IN	("117"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("380"))
	THEN &outPDTCODE.="580";
IF (&inPDTCODE.	IN	("403"))
	THEN &outPDTCODE.="460";
IF (&inPDTCODE.	IN	("116"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("412"))
	THEN &outPDTCODE.="500";
IF (&inPDTCODE.	IN	("114"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("417"))
	THEN &outPDTCODE.="530";
IF (&inPDTCODE.	IN	("113"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("421"))
	THEN &outPDTCODE.="550";
IF (&inPDTCODE.	IN	("112"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("111"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("433"))
	THEN &outPDTCODE.="500";
IF (&inPDTCODE.	IN	("437"))
	THEN &outPDTCODE.="530";
IF (&inPDTCODE.	IN	("110"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("109"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("108"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("107"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("106"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("105"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("104"))
	THEN &outPDTCODE.="295";
IF (&inPDTCODE.	IN	("103"))
	THEN &outPDTCODE.="295";
IF (&inPDTCODE.	IN	("102"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("101"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inPDTCODE.	IN	("268"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("827"))
	THEN &outPDTCODE.="";
IF (&inPDTCODE.	IN	("704"))
	THEN &outPDTCODE.="295";
IF (&inPDTCODE.	IN	("703"))
	THEN &outPDTCODE.="295";
IF (&inPDTCODE.	IN	("658"))
	THEN &outPDTCODE.="635";
IF (&inPDTCODE.	IN	("656"))
	THEN &outPDTCODE.="758";
IF (&inPDTCODE.	IN	("655"))
	THEN &outPDTCODE.="669";
IF (&inPDTCODE.	IN	("652"))
	THEN &outPDTCODE.="760";
IF (&inPDTCODE.	IN	("650"))
	THEN &outPDTCODE.="759";
IF (&inPDTCODE.	IN	("649"))
	THEN &outPDTCODE.="759";
IF (&inPDTCODE.	IN	("648"))
	THEN &outPDTCODE.="758";
IF (&inPDTCODE.	IN	("647"))
	THEN &outPDTCODE.="758";
IF (&inPDTCODE.	IN	("646"))
	THEN &outPDTCODE.="757";
IF (&inPDTCODE.	IN	("645"))
	THEN &outPDTCODE.="757";
IF (&inPDTCODE.	IN	("644"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("643"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="209";
IF (&inPDTCODE.	IN	("621"))
	THEN &outPDTCODE.="680";
IF (&inPDTCODE.	IN	("640"))
	THEN &outPDTCODE.="766";
IF (&inPDTCODE.	IN	("639"))
	THEN &outPDTCODE.="757";
IF (&inPDTCODE.	IN	("638"))
	THEN &outPDTCODE.="780";
IF (&inPDTCODE.	IN	("636"))
	THEN &outPDTCODE.="761";
IF (&inPDTCODE.	IN	("635"))
	THEN &outPDTCODE.="760";
IF (&inPDTCODE.	IN	("634"))
	THEN &outPDTCODE.="759";
IF (&inPDTCODE.	IN	("633"))
	THEN &outPDTCODE.="758";
IF (&inPDTCODE.	IN	("632"))
	THEN &outPDTCODE.="757";
IF (&inPDTCODE.	IN	("624"))
	THEN &outPDTCODE.="710";
IF (&inPDTCODE.	IN	("623"))
	THEN &outPDTCODE.="704";
IF (&inPDTCODE.	IN	("604"))
	THEN &outPDTCODE.="625";
IF (&inPDTCODE.	IN	("620"))
	THEN &outPDTCODE.="675";
IF (&inPDTCODE.	IN	("619"))
	THEN &outPDTCODE.="658";
IF (&inPDTCODE.	IN	("618"))
	THEN &outPDTCODE.="669";
IF (&inPDTCODE.	IN	("617"))
	THEN &outPDTCODE.="655";
IF (&inPDTCODE.	IN	("616"))
	THEN &outPDTCODE.="675";
IF (&inPDTCODE.	IN	("615"))
	THEN &outPDTCODE.="669";
IF (&inPDTCODE.	IN	("622"))
	THEN &outPDTCODE.="685";
IF (&inPDTCODE.	IN	("614"))
	THEN &outPDTCODE.="658";
IF (&inPDTCODE.	IN	("612"))
	THEN &outPDTCODE.="655";
IF (&inPDTCODE.	IN	("611"))
	THEN &outPDTCODE.="635";
IF (&inPDTCODE.	IN	("610"))
	THEN &outPDTCODE.="625";
IF (&inPDTCODE.	IN	("609"))
	THEN &outPDTCODE.="625";
IF (&inPDTCODE.	IN	("608"))
	THEN &outPDTCODE.="615";
IF (&inPDTCODE.	IN	("607"))
	THEN &outPDTCODE.="615";
IF (&inPDTCODE.	IN	("606"))
	THEN &outPDTCODE.="615";
IF (&inPDTCODE.	IN	("637"))
	THEN &outPDTCODE.="775";
IF (&inPDTCODE.	IN	("516"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("603"))
	THEN &outPDTCODE.="625";
IF (&inPDTCODE.	IN	("641"))
	THEN &outPDTCODE.="325";
IF (&inPDTCODE.	IN	("602"))
	THEN &outPDTCODE.="615";
IF (&inPDTCODE.	IN	("601"))
	THEN &outPDTCODE.="615";
IF (&inPDTCODE.	IN	("552"))
	THEN &outPDTCODE.="760";
IF (&inPDTCODE.	IN	("551"))
	THEN &outPDTCODE.="760";
IF (&inPDTCODE.	IN	("550"))
	THEN &outPDTCODE.="759";
IF (&inPDTCODE.	IN	("549"))
	THEN &outPDTCODE.="759";
IF (&inPDTCODE.	IN	("546"))
	THEN &outPDTCODE.="757";
IF (&inPDTCODE.	IN	("545"))
	THEN &outPDTCODE.="757";
IF (&inPDTCODE.	IN	("535"))
	THEN &outPDTCODE.="760";
IF (&inPDTCODE.	IN	("534"))
	THEN &outPDTCODE.="759";
IF (&inPDTCODE.	IN	("651"))
	THEN &outPDTCODE.="760";
IF (&inPDTCODE.	IN	("533"))
	THEN &outPDTCODE.="758";
IF (&inPDTCODE.	IN	("532"))
	THEN &outPDTCODE.="757";
IF (&inPDTCODE.	IN	("653"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("657"))
	THEN &outPDTCODE.="758";
IF (&inPDTCODE.	IN	("515"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("514"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("513"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("512"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="240";
IF (&inPDTCODE.	IN	("368"))
	AND (&inACCLSS.	IN	("547703"))
	AND (&inCUSTSEG.	IN	("010","011","012","013","014","015","016","021","022","110","111","112","113","114","115","116","121","122"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("355"))
	AND (&inACCLSS.	IN	("547703"))
	AND (&inCUSTSEG.	IN	("010","011","012","013","014","015","016","021","022","110","111","112","113","114","115","116","121","122"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("355"))
	AND (&inCUSTSEG.	IN	("124"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("368"))
	AND (&inCUSTSEG.	IN	("124"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("355"))
	AND (&inCUSTSEG.	IN	("123"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("368"))
	AND (&inCUSTSEG.	IN	("123"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("355"))
	AND (&inCUSTSEG.	IN	("116"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("368"))
	AND (&inCUSTSEG.	IN	("116"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("355"))
	AND (&inCUSTSEG.	IN	("115"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("368"))
	AND (&inCUSTSEG.	IN	("115"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("355"))
	AND (&inCUSTSEG.	IN	("114"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("368"))
	AND (&inCUSTSEG.	IN	("114"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("355"))
	AND (&inCUSTSEG.	IN	("113"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("368"))
	AND (&inCUSTSEG.	IN	("113"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("355"))
	AND (&inCUSTSEG.	IN	("112"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("368"))
	AND (&inCUSTSEG.	IN	("112"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("355"))
	AND (&inCUSTSEG.	IN	("111"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("368"))
	AND (&inCUSTSEG.	IN	("111"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("355"))
	AND (&inCUSTSEG.	IN	("110"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("368"))
	AND (&inCUSTSEG.	IN	("110"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("289"))
	THEN &outPDTCODE.="386";
IF (&inPDTCODE.	IN	("289"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("355"))
	AND (&inCUSTSEG.	IN	("024"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("368"))
	AND (&inCUSTSEG.	IN	("024"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("289"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("355"))
	AND (&inCUSTSEG.	IN	("023"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("368"))
	AND (&inCUSTSEG.	IN	("023"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("289"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("355"))
	AND (&inCUSTSEG.	IN	("016"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("368"))
	AND (&inCUSTSEG.	IN	("016"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("289"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="230";
IF (&inPDTCODE.	IN	("355"))
	AND (&inCUSTSEG.	IN	("015"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("288"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("368"))
	AND (&inCUSTSEG.	IN	("015"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("355"))
	AND (&inCUSTSEG.	IN	("014"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("288"))
	AND (&inCUSTSEG.	IN	("029"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("368"))
	AND (&inCUSTSEG.	IN	("014"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("325"))
	THEN &outPDTCODE.="386";
IF (&inPDTCODE.	IN	("289"))
	AND (&inCUSTSEG.	IN	("029"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("712"))
	AND (&inCUSTSEG.	IN	("655"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("812"))
	AND (&inCUSTSEG.	IN	("655"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("709"))
	AND (&inCUSTSEG.	IN	("655"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("716"))
	AND (&inCUSTSEG.	IN	("655"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("710"))
	AND (&inCUSTSEG.	IN	("655"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("715"))
	AND (&inCUSTSEG.	IN	("655"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("714"))
	AND (&inCUSTSEG.	IN	("655"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("711"))
	AND (&inCUSTSEG.	IN	("655"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("713"))
	AND (&inCUSTSEG.	IN	("655"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("355"))
	AND (&inCUSTSEG.	IN	("013"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("288"))
	AND (&inCUSTSEG.	IN	("028"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("820"))
	AND (&inCUSTSEG.	IN	("655"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("815"))
	AND (&inCUSTSEG.	IN	("655"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("144"))
	AND (&inCUSTSEG.	IN	("655"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("122"))
	AND (&inCUSTSEG.	IN	("655"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("368"))
	AND (&inCUSTSEG.	IN	("013"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("325"))
	AND (&inCUSTSEG.	IN	("029"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("324"))
	THEN &outPDTCODE.="330";
IF (&inPDTCODE.	IN	("289"))
	AND (&inCUSTSEG.	IN	("028"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("712"))
	AND (&inCUSTSEG.	IN	("505"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("711"))
	AND (&inCUSTSEG.	IN	("505"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("710"))
	AND (&inCUSTSEG.	IN	("505"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("709"))
	AND (&inCUSTSEG.	IN	("505"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("812"))
	AND (&inCUSTSEG.	IN	("505"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("716"))
	AND (&inCUSTSEG.	IN	("505"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("715"))
	AND (&inCUSTSEG.	IN	("505"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("714"))
	AND (&inCUSTSEG.	IN	("505"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("713"))
	AND (&inCUSTSEG.	IN	("505"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("355"))
	AND (&inCUSTSEG.	IN	("012"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("289"))
	AND (&inCUSTSEG.	IN	("027"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("288"))
	AND (&inCUSTSEG.	IN	("027"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("820"))
	AND (&inCUSTSEG.	IN	("505"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("815"))
	AND (&inCUSTSEG.	IN	("505"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("144"))
	AND (&inCUSTSEG.	IN	("505"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("122"))
	AND (&inCUSTSEG.	IN	("505"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("368"))
	AND (&inCUSTSEG.	IN	("012"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("325"))
	AND (&inCUSTSEG.	IN	("027"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("324"))
	AND (&inCUSTSEG.	IN	("027"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("204"))
	AND (&inCUSTSEG.	IN	("027"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("245"))
	AND (&inCUSTSEG.	IN	("027"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("712"))
	AND (&inCUSTSEG.	IN	("355"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("711"))
	AND (&inCUSTSEG.	IN	("355"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("716"))
	AND (&inCUSTSEG.	IN	("355"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("710"))
	AND (&inCUSTSEG.	IN	("355"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("709"))
	AND (&inCUSTSEG.	IN	("355"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("812"))
	AND (&inCUSTSEG.	IN	("355"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("715"))
	AND (&inCUSTSEG.	IN	("355"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("714"))
	AND (&inCUSTSEG.	IN	("355"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("713"))
	AND (&inCUSTSEG.	IN	("355"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("355"))
	AND (&inCUSTSEG.	IN	("011"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("289"))
	AND (&inCUSTSEG.	IN	("026"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("288"))
	AND (&inCUSTSEG.	IN	("026"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("820"))
	AND (&inCUSTSEG.	IN	("355"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("815"))
	AND (&inCUSTSEG.	IN	("355"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("144"))
	AND (&inCUSTSEG.	IN	("355"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("122"))
	AND (&inCUSTSEG.	IN	("355"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("368"))
	AND (&inCUSTSEG.	IN	("011"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("325"))
	AND (&inCUSTSEG.	IN	("026"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("324"))
	AND (&inCUSTSEG.	IN	("026"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("705"))
	AND (&inCUSTSEG.	IN	("505"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("705"))
	AND (&inCUSTSEG.	IN	("305"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("245"))
	AND (&inCUSTSEG.	IN	("026"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("204"))
	AND (&inCUSTSEG.	IN	("026"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("711"))
	AND (&inCUSTSEG.	IN	("305"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("712"))
	AND (&inCUSTSEG.	IN	("305"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("710"))
	AND (&inCUSTSEG.	IN	("305"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("709"))
	AND (&inCUSTSEG.	IN	("305"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("812"))
	AND (&inCUSTSEG.	IN	("305"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("716"))
	AND (&inCUSTSEG.	IN	("305"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("715"))
	AND (&inCUSTSEG.	IN	("305"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("714"))
	AND (&inCUSTSEG.	IN	("305"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("713"))
	AND (&inCUSTSEG.	IN	("305"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("355"))
	AND (&inCUSTSEG.	IN	("010"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("820"))
	AND (&inCUSTSEG.	IN	("305"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("289"))
	AND (&inCUSTSEG.	IN	("025"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("288"))
	AND (&inCUSTSEG.	IN	("025"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("109"))
	AND (&inCUSTSEG.	IN	("655"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("266"))
	AND (&inCUSTSEG.	IN	("26","27","52","54","55","56"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("815"))
	AND (&inCUSTSEG.	IN	("305"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("144"))
	AND (&inCUSTSEG.	IN	("305"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("122"))
	AND (&inCUSTSEG.	IN	("305"))
	THEN &outPDTCODE.="605";
IF (&inPDTCODE.	IN	("267"))
	AND (&inCUSTSEG.	IN	("010","011","012","013","014","015","016","020","021","022","023","024","025","026","027","028","029","110","111","112","113",
"114","115","116","117","118","119","120","121","122","123","124"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("368"))
	AND (&inCUSTSEG.	IN	("010"))
	THEN &outPDTCODE.="259";
IF (&inPDTCODE.	IN	("824"))
	AND (&inCUSTSEG.	NOT IN	("010","011","012","013","014","015","016","020","021","022","023","024","025","026","027","028","029","110","111","112","113",
"114","115","116","117","118","119","120","121","122","123","124"))
	THEN &outPDTCODE.="285";
IF (&inPDTCODE.	IN	("447"))
	THEN &outPDTCODE.="446";
IF (&inPDTCODE.	IN	("446"))
	THEN &outPDTCODE.="446";
IF (&inPDTCODE.	IN	("325"))
	AND (&inCUSTSEG.	IN	("025"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("324"))
	AND (&inCUSTSEG.	IN	("025"))
	THEN &outPDTCODE.="220";
IF (&inPDTCODE.	IN	("752"))
	AND (&inCUSTSEG.	IN	("655"))
	THEN &outPDTCODE.="605";
IF (&inACCLSS.	IN	("288870"))
	THEN &outPDTCODE.="910";
IF (&inACCLSS.	IN	("288899"))
	THEN &outPDTCODE.="910";
IF (&inACCLSS.	IN	("555003"))
	THEN &outPDTCODE.="615";
IF (&inACCLSS.	IN	("188001"))
	THEN &outPDTCODE.="615";
IF (&inACCLSS.	IN	("175508"))
	THEN &outPDTCODE.="728";
IF (&inACCLSS.	IN	("291701"))
	AND (&inCUSTSEG.	IN	("010","011","012","013","014","015","016","020","021","022","023","024","025","026","027","028","029","110","111","112","113",
"114","115","116","121","122","123","124"))
	THEN &outPDTCODE.="225";
IF (&inACCLSS.	IN	("289173"))
	THEN &outPDTCODE.="225";
IF (&inACCLSS.	IN	("288881"))
	THEN &outPDTCODE.="910";
IF (&inACCLSS.	IN	("288880"))
	THEN &outPDTCODE.="910";
IF (&inACCLSS.	IN	("288879"))
	THEN &outPDTCODE.="910";
IF (&inACCLSS.	IN	("288878"))
	THEN &outPDTCODE.="910";
IF (&inACCLSS.	IN	("288820"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("288804"))
	THEN &outPDTCODE.="910";
IF (&inACCLSS.	IN	("867002"))
	THEN &outPDTCODE.="625";
IF (&inACCLSS.	IN	("866502"))
	THEN &outPDTCODE.="625";
IF (&inACCLSS.	IN	("895001"))
	THEN &outPDTCODE.="615";
IF (&inACCLSS.	IN	("188011"))
	THEN &outPDTCODE.="615";
IF (&inACCLSS.	IN	("875501"))
	THEN &outPDTCODE.="260";
IF (&inACCLSS.	IN	("875001"))
	THEN &outPDTCODE.="260";
IF (&inACCLSS.	IN	("865001"))
	THEN &outPDTCODE.="260";
IF (&inACCLSS.	IN	("864501"))
	THEN &outPDTCODE.="260";
IF (&inACCLSS.	IN	("576053"))
	AND (&inPDTCODE.	IN	("822"))
	THEN &outPDTCODE.="900";
IF (&inACCLSS.	IN	("504158"))
	AND (&inPDTCODE.	IN	("822"))
	THEN &outPDTCODE.="900";
IF (&inACCLSS.	IN	("289276"))
	THEN &outPDTCODE.="910";
IF (&inACCLSS.	IN	("175501"))
	THEN &outPDTCODE.="728";
IF (&inACCLSS.	IN	("322001"))
	AND (&inPDTCODE.	IN	("829"))
	THEN &outPDTCODE.="761";
IF (&inACCLSS.	IN	("122001"))
	AND (&inPDTCODE.	IN	("644"))
	THEN &outPDTCODE.="761";
IF (&inACCLSS.	IN	("175506"))
	THEN &outPDTCODE.="728";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("029"))
	THEN &outPDTCODE.="200";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("028"))
	THEN &outPDTCODE.="200";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("027"))
	THEN &outPDTCODE.="200";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("659"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("659"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("659"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("658"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("658"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("658"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("655"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("659"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("655"))
	THEN &outPDTCODE.="605";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("655"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("658"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("650"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("650"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("650"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("630"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("630"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("655"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("630"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("609"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("650"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("609"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("609"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("608"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("630"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("608"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("608"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("609"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("600"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("600"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("600"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("509"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("509"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("608"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("509"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("600"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("508"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("508"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("508"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("505"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("509"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("505"))
	THEN &outPDTCODE.="605";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("505"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("508"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("500"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("500"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("500"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("469"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("505"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("469"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("469"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("500"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("468"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("468"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("468"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("469"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("460"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("460"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("460"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("468"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("449"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("449"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("449"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("460"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("448"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("448"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("448"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("449"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("440"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("440"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("440"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("429"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("448"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("429"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("429"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("440"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("428"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("428"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("428"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("420"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("420"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("429"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("420"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("428"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("409"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("409"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("409"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("420"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("408"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("408"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("408"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("409"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("400"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("400"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("400"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("359"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("408"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("359"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("359"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("400"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("358"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("358"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("358"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("359"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("355"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("355"))
	THEN &outPDTCODE.="605";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("355"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("358"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("350"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("350"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("350"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("309"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("355"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("309"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("309"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("350"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("308"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("308"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("308"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("309"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("305"))
	THEN &outPDTCODE.="605";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("305"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("305"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("133732"))
	AND (&inCUSTSEG.	IN	("655"))
	THEN &outPDTCODE.="605";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("300"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("308"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("300"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("300"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("133732"))
	AND (&inCUSTSEG.	IN	("505"))
	THEN &outPDTCODE.="605";
IF (&inACCLSS.	IN	("515072"))
	AND (&inSEGCODE.	IN	("60","61","65","66"))
	THEN &outPDTCODE.="277";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("305"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("026"))
	THEN &outPDTCODE.="200";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("026"))
	THEN &outPDTCODE.="209";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("026"))
	THEN &outPDTCODE.="209";
IF (&inACCLSS.	IN	("133732"))
	AND (&inCUSTSEG.	IN	("355"))
	THEN &outPDTCODE.="605";
IF (&inACCLSS.	IN	("122131"))
	AND (&inCUSTSEG.	IN	("110"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("111155"))
	AND (&inCUSTSEG.	IN	("110"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("111103"))
	AND (&inCUSTSEG.	IN	("110"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("291756"))
	AND (&inCUSTSEG.	IN	("110"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("555002"))
	AND (&inSEGCODE.	IN	("60","61","65","66"))
	THEN &outPDTCODE.="277";
IF (&inACCLSS.	IN	("231003"))
	AND (&inCUSTSEG.	IN	("010"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("546001"))
	AND (&inCUSTSEG.	IN	("112"))
	THEN &outPDTCODE.="270";
IF (&inACCLSS.	IN	("231001"))
	AND (&inCUSTSEG.	IN	("010"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("231001"))
	AND (&inPDTCODE.	NOT IN	("340"))
	AND (&inPEBAL.	LE	(0))
	AND (&inCUSTSEG.	NOT IN	("010","011","012","013","014","015","016","020","021","022","023","024","025","026","027","028","029","110","111","112","113",
"114","115","116","121","122","123","124"))
	THEN &outPDTCODE.="295";
IF (&inACCLSS.	IN	("291701"))
	AND (&inPDTCODE.	IN	("630"))
	AND (&inPEBAL.	LE	(0))
	THEN &outPDTCODE.="296";
IF (&inACCLSS.	IN	("515072"))
	AND (&inCUSTSEG.	IN	("112"))
	THEN &outPDTCODE.="270";
IF (&inACCLSS.	IN	("177301"))
	AND (&inCUSTSEG.	IN	("300"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("177732"))
	AND (&inCUSTSEG.	IN	("025"))
	THEN &outPDTCODE.="200";
IF (&inACCLSS.	IN	("175521"))
	AND (&inCUSTSEG.	IN	("025"))
	THEN &outPDTCODE.="209";
IF (&inACCLSS.	IN	("175509"))
	AND (&inCUSTSEG.	IN	("025"))
	THEN &outPDTCODE.="209";
IF (&inACCLSS.	IN	("133732"))
	AND (&inCUSTSEG.	IN	("305"))
	THEN &outPDTCODE.="605";
IF (&inACCLSS.	IN	("291756"))
	AND (&inCUSTSEG.	IN	("010"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("122131"))
	AND (&inCUSTSEG.	IN	("010"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("111155"))
	AND (&inCUSTSEG.	IN	("010"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("111103"))
	AND (&inCUSTSEG.	IN	("010"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("504505"))
	AND (&inSEGCODE.	IN	("60","61","65","66"))
	THEN &outPDTCODE.="277";
IF (&inACCLSS.	IN	("504506"))
	AND (&inSEGCODE.	IN	("60","61","65","66"))
	THEN &outPDTCODE.="277";
IF (&inACCLSS.	IN	("515068"))
	AND (&inSEGCODE.	IN	("60","61","65","66"))
	THEN &outPDTCODE.="271";
IF (&inACCLSS.	IN	("231004"))
	THEN &outPDTCODE.="340";
IF (&inACCLSS.	IN	("267501"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="220";
IF (&inACCLSS.	IN	("231013"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="225";
IF (&inACCLSS.	IN	("555002"))
	AND (&inCUSTSEG.	IN	("112"))
	THEN &outPDTCODE.="270";
IF (&inACCLSS.	IN	("547901"))
	AND (&inCUSTSEG.	IN	("110"))
	THEN &outPDTCODE.="260";
IF (&inACCLSS.	IN	("546001"))
	AND (&inCUSTSEG.	IN	("110"))
	THEN &outPDTCODE.="277";
IF (&inACCLSS.	IN	("931001"))
	THEN &outPDTCODE.="332";
IF (&inACCLSS.	IN	("292701"))
	AND (&inPDTCODE.	IN	("630"))
	AND (&inPEBAL.	LE	(0))
	THEN &outPDTCODE.="296";
IF (&inACCLSS.	IN	("221051"))
	AND (&inPDTCODE.	IN	("630"))
	AND (&inPEBAL.	LE	(0))
	THEN &outPDTCODE.="296";
IF (&inBRCODE.	IN	("13030"))
	AND (&inPDTCODE.	IN	("517"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13010"))
	AND (&inPDTCODE.	IN	("517"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10070"))
	AND (&inPDTCODE.	IN	("517"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10050"))
	AND (&inPDTCODE.	IN	("517"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10030"))
	AND (&inPDTCODE.	IN	("517"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10000"))
	AND (&inPDTCODE.	IN	("517"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13030"))
	AND (&inPDTCODE.	IN	("516"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13010"))
	AND (&inPDTCODE.	IN	("516"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10070"))
	AND (&inPDTCODE.	IN	("516"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10050"))
	AND (&inPDTCODE.	IN	("516"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10030"))
	AND (&inPDTCODE.	IN	("516"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10000"))
	AND (&inPDTCODE.	IN	("516"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13030"))
	AND (&inPDTCODE.	IN	("515"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13010"))
	AND (&inPDTCODE.	IN	("515"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10070"))
	AND (&inPDTCODE.	IN	("515"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10050"))
	AND (&inPDTCODE.	IN	("515"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10030"))
	AND (&inPDTCODE.	IN	("515"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10000"))
	AND (&inPDTCODE.	IN	("515"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13030"))
	AND (&inPDTCODE.	IN	("514"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13010"))
	AND (&inPDTCODE.	IN	("514"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10070"))
	AND (&inPDTCODE.	IN	("514"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10050"))
	AND (&inPDTCODE.	IN	("514"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10030"))
	AND (&inPDTCODE.	IN	("514"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10000"))
	AND (&inPDTCODE.	IN	("514"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13030"))
	AND (&inPDTCODE.	IN	("513"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13010"))
	AND (&inPDTCODE.	IN	("513"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10070"))
	AND (&inPDTCODE.	IN	("513"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10050"))
	AND (&inPDTCODE.	IN	("513"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10030"))
	AND (&inPDTCODE.	IN	("513"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10000"))
	AND (&inPDTCODE.	IN	("513"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13030"))
	AND (&inPDTCODE.	IN	("512"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13010"))
	AND (&inPDTCODE.	IN	("512"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10070"))
	AND (&inPDTCODE.	IN	("512"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10050"))
	AND (&inPDTCODE.	IN	("512"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10030"))
	AND (&inPDTCODE.	IN	("512"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10000"))
	AND (&inPDTCODE.	IN	("512"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13030"))
	AND (&inPDTCODE.	IN	("507"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13010"))
	AND (&inPDTCODE.	IN	("507"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10070"))
	AND (&inPDTCODE.	IN	("507"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10050"))
	AND (&inPDTCODE.	IN	("507"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10030"))
	AND (&inPDTCODE.	IN	("507"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10000"))
	AND (&inPDTCODE.	IN	("507"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13030"))
	AND (&inPDTCODE.	IN	("506"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13010"))
	AND (&inPDTCODE.	IN	("506"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10070"))
	AND (&inPDTCODE.	IN	("506"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10050"))
	AND (&inPDTCODE.	IN	("506"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10030"))
	AND (&inPDTCODE.	IN	("506"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10000"))
	AND (&inPDTCODE.	IN	("506"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13030"))
	AND (&inPDTCODE.	IN	("505"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13010"))
	AND (&inPDTCODE.	IN	("505"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10070"))
	AND (&inPDTCODE.	IN	("505"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10050"))
	AND (&inPDTCODE.	IN	("505"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10030"))
	AND (&inPDTCODE.	IN	("505"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10000"))
	AND (&inPDTCODE.	IN	("505"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13030"))
	AND (&inPDTCODE.	IN	("504"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13010"))
	AND (&inPDTCODE.	IN	("504"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10070"))
	AND (&inPDTCODE.	IN	("504"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10050"))
	AND (&inPDTCODE.	IN	("504"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10030"))
	AND (&inPDTCODE.	IN	("504"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10000"))
	AND (&inPDTCODE.	IN	("504"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13030"))
	AND (&inPDTCODE.	IN	("503"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13010"))
	AND (&inPDTCODE.	IN	("503"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10070"))
	AND (&inPDTCODE.	IN	("503"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10050"))
	AND (&inPDTCODE.	IN	("503"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10030"))
	AND (&inPDTCODE.	IN	("503"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10000"))
	AND (&inPDTCODE.	IN	("503"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13030"))
	AND (&inPDTCODE.	IN	("502"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13010"))
	AND (&inPDTCODE.	IN	("502"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10070"))
	AND (&inPDTCODE.	IN	("502"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10050"))
	AND (&inPDTCODE.	IN	("502"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10030"))
	AND (&inPDTCODE.	IN	("502"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10000"))
	AND (&inPDTCODE.	IN	("502"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13030"))
	AND (&inPDTCODE.	IN	("317"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13010"))
	AND (&inPDTCODE.	IN	("317"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10070"))
	AND (&inPDTCODE.	IN	("317"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10050"))
	AND (&inPDTCODE.	IN	("317"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10030"))
	AND (&inPDTCODE.	IN	("317"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10000"))
	AND (&inPDTCODE.	IN	("317"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13030"))
	AND (&inPDTCODE.	IN	("316"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13010"))
	AND (&inPDTCODE.	IN	("316"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10070"))
	AND (&inPDTCODE.	IN	("316"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10050"))
	AND (&inPDTCODE.	IN	("316"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10030"))
	AND (&inPDTCODE.	IN	("316"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10000"))
	AND (&inPDTCODE.	IN	("316"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10000"))
	AND (&inPDTCODE.	IN	("315"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13030"))
	AND (&inPDTCODE.	IN	("315"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13010"))
	AND (&inPDTCODE.	IN	("315"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10070"))
	AND (&inPDTCODE.	IN	("315"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10050"))
	AND (&inPDTCODE.	IN	("315"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10030"))
	AND (&inPDTCODE.	IN	("315"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10000"))
	AND (&inPDTCODE.	IN	("314"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13030"))
	AND (&inPDTCODE.	IN	("314"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13010"))
	AND (&inPDTCODE.	IN	("314"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10070"))
	AND (&inPDTCODE.	IN	("314"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10050"))
	AND (&inPDTCODE.	IN	("314"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10030"))
	AND (&inPDTCODE.	IN	("314"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10000"))
	AND (&inPDTCODE.	IN	("313"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13030"))
	AND (&inPDTCODE.	IN	("313"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13010"))
	AND (&inPDTCODE.	IN	("313"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10070"))
	AND (&inPDTCODE.	IN	("313"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10050"))
	AND (&inPDTCODE.	IN	("313"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10030"))
	AND (&inPDTCODE.	IN	("313"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10000"))
	AND (&inPDTCODE.	IN	("312"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13030"))
	AND (&inPDTCODE.	IN	("312"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13010"))
	AND (&inPDTCODE.	IN	("312"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10070"))
	AND (&inPDTCODE.	IN	("312"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10050"))
	AND (&inPDTCODE.	IN	("312"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10030"))
	AND (&inPDTCODE.	IN	("312"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13030"))
	AND (&inPDTCODE.	IN	("307"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10000"))
	AND (&inPDTCODE.	IN	("307"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13010"))
	AND (&inPDTCODE.	IN	("307"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10070"))
	AND (&inPDTCODE.	IN	("307"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10050"))
	AND (&inPDTCODE.	IN	("307"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10030"))
	AND (&inPDTCODE.	IN	("307"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13030"))
	AND (&inPDTCODE.	IN	("306"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13010"))
	AND (&inPDTCODE.	IN	("306"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10000"))
	AND (&inPDTCODE.	IN	("306"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10070"))
	AND (&inPDTCODE.	IN	("306"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10050"))
	AND (&inPDTCODE.	IN	("306"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10030"))
	AND (&inPDTCODE.	IN	("306"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13030"))
	AND (&inPDTCODE.	IN	("305"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13010"))
	AND (&inPDTCODE.	IN	("305"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10070"))
	AND (&inPDTCODE.	IN	("305"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10050"))
	AND (&inPDTCODE.	IN	("305"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10000"))
	AND (&inPDTCODE.	IN	("305"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10030"))
	AND (&inPDTCODE.	IN	("305"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13030"))
	AND (&inPDTCODE.	IN	("304"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13010"))
	AND (&inPDTCODE.	IN	("304"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10070"))
	AND (&inPDTCODE.	IN	("304"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10050"))
	AND (&inPDTCODE.	IN	("304"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10030"))
	AND (&inPDTCODE.	IN	("304"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10000"))
	AND (&inPDTCODE.	IN	("304"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13030"))
	AND (&inPDTCODE.	IN	("303"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13010"))
	AND (&inPDTCODE.	IN	("303"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10070"))
	AND (&inPDTCODE.	IN	("303"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10050"))
	AND (&inPDTCODE.	IN	("303"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10030"))
	AND (&inPDTCODE.	IN	("303"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10000"))
	AND (&inPDTCODE.	IN	("303"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10000"))
	AND (&inPDTCODE.	IN	("302"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13030"))
	AND (&inPDTCODE.	IN	("302"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("13010"))
	AND (&inPDTCODE.	IN	("302"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10070"))
	AND (&inPDTCODE.	IN	("302"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10050"))
	AND (&inPDTCODE.	IN	("302"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inBRCODE.	IN	("10030"))
	AND (&inPDTCODE.	IN	("302"))
	AND (&inCUSTSEG.	NOT IN	("026","027"))
	THEN &outPDTCODE.="755";
IF (&inACCLSS.	IN	("503001"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("503001"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="110";
IF (&inACCLSS.	IN	("503001"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="110";
IF (&inACCLSS.	IN	("546059"))
	AND (&inPDTCODE.	IN	("822"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("503001"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="110";
IF (&inACCLSS.	IN	("546059"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="172";
IF (&inACCLSS.	IN	("546001"))
	AND (&inPDTCODE.	IN	("215"))
	AND (&inSEGCODE.	IN	("59"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("503001"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="110";
IF (&inACCLSS.	IN	("546059"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="172";
IF (&inACCLSS.	IN	("546001"))
	AND (&inPDTCODE.	IN	("215"))
	AND (&inSEGCODE.	IN	("58"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("546060"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("503005"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("535001"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("503001"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="110";
IF (&inACCLSS.	IN	("546059"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="172";
IF (&inACCLSS.	IN	("546001"))
	AND (&inPDTCODE.	IN	("215"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("546060"))
	AND (&inPDTCODE.	IN	("822"))
	THEN &outPDTCODE.="361";
IF (&inACCLSS.	IN	("535001"))
	AND (&inPDTCODE.	IN	("822"))
	THEN &outPDTCODE.="349";
IF (&inACCLSS.	IN	("503005"))
	AND (&inPDTCODE.	IN	("822"))
	THEN &outPDTCODE.="285";
IF (&inACCLSS.	IN	("503001"))
	AND (&inPDTCODE.	IN	("822"))
	THEN &outPDTCODE.="285";
IF (&inACCLSS.	IN	("546059"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="172";
IF (&inACCLSS.	IN	("546059"))
	AND (&inPDTCODE.	IN	("829"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="172";
IF (&inACCLSS.	IN	("546001"))
	AND (&inPDTCODE.	IN	("215"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("503001"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("546060"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("535001"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("503005"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("546059"))
	AND (&inPDTCODE.	IN	("829"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="172";
IF (&inACCLSS.	IN	("546001"))
	AND (&inPDTCODE.	IN	("215"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("177732"))
	AND (&inPDTCODE.	IN	("730"))
	THEN &outPDTCODE.="325";
IF (&inACCLSS.	IN	("503005"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("503001"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("535001"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("546060"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("546059"))
	AND (&inPDTCODE.	IN	("829"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="172";
IF (&inACCLSS.	IN	("546001"))
	AND (&inPDTCODE.	IN	("215"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("177732"))
	AND (&inPDTCODE.	IN	("724"))
	THEN &outPDTCODE.="325";
IF (&inACCLSS.	IN	("503050"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("285001"))
	AND (&inPDTCODE.	IN	("387"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="255";
IF (&inACCLSS.	IN	("546060"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("535001"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("503005"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("503001"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("547701"))
	AND (&inPDTCODE.	IN	("822"))
	THEN &outPDTCODE.="399";
IF (&inACCLSS.	IN	("546059"))
	AND (&inPDTCODE.	IN	("829"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="172";
IF (&inACCLSS.	IN	("547701"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("60","61","65","66"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("559025"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="260";
IF (&inACCLSS.	IN	("177732"))
	AND (&inPDTCODE.	IN	("725"))
	THEN &outPDTCODE.="710";
IF (&inACCLSS.	IN	("547905"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("504301"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="100";
IF (&inACCLSS.	IN	("503002"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("289130"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("289036"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("288859"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("287667"))
	AND (&inPDTCODE.	IN	("386"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="230";
IF (&inACCLSS.	IN	("287601"))
	AND (&inPDTCODE.	IN	("386"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="240";
IF (&inACCLSS.	IN	("133876"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("122131"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("067526"))
	AND (&inPDTCODE.	IN	("816"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="230";
IF (&inACCLSS.	IN	("067511"))
	AND (&inPDTCODE.	IN	("816"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="230";
IF (&inACCLSS.	IN	("067501"))
	AND (&inPDTCODE.	IN	("816"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="220";
IF (&inACCLSS.	IN	("503050"))
	AND (&inPDTCODE.	IN	("822"))
	THEN &outPDTCODE.="525";
IF (&inACCLSS.	IN	("285001"))
	AND (&inPDTCODE.	IN	("818"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("287669"))
	AND (&inPDTCODE.	IN	("386"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="240";
IF (&inACCLSS.	IN	("267538"))
	AND (&inPDTCODE.	IN	("816"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="260";
IF (&inACCLSS.	IN	("332551"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("067523"))
	AND (&inPDTCODE.	IN	("816"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="241";
IF (&inACCLSS.	IN	("503061"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("547901"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("63"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("546060"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("503005"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("503001"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("535001"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("503049"))
	AND (&inPDTCODE.	IN	("822"))
	THEN &outPDTCODE.="285";
IF (&inACCLSS.	IN	("515002"))
	AND (&inPDTCODE.	IN	("822"))
	THEN &outPDTCODE.="360";
IF (&inACCLSS.	IN	("503013"))
	AND (&inPDTCODE.	IN	("822"))
	THEN &outPDTCODE.="285";
IF (&inACCLSS.	IN	("515003"))
	AND (&inPDTCODE.	IN	("822"))
	THEN &outPDTCODE.="390";
IF (&inACCLSS.	IN	("515005"))
	AND (&inPDTCODE.	IN	("822"))
	THEN &outPDTCODE.="361";
IF (&inACCLSS.	IN	("515017"))
	AND (&inPDTCODE.	IN	("822"))
	THEN &outPDTCODE.="361";
IF (&inACCLSS.	IN	("546056"))
	AND (&inPDTCODE.	IN	("822"))
	THEN &outPDTCODE.="330";
IF (&inACCLSS.	IN	("546001"))
	AND (&inPDTCODE.	IN	("822"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("503001"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inACCLSS.	IN	("503005"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inACCLSS.	IN	("535001"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("546060"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("547701"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("546059"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="209";
IF (&inACCLSS.	IN	("546056"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="220";
IF (&inACCLSS.	IN	("546001"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="209";
IF (&inACCLSS.	IN	("515017"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("515005"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("515003"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("503013"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inACCLSS.	IN	("515002"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("503049"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="200";
IF (&inACCLSS.	IN	("515001"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="230";
IF (&inACCLSS.	IN	("288843"))
	AND (&inPDTCODE.	IN	("829"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("177732"))
	AND (&inPDTCODE.	IN	("723"))
	THEN &outPDTCODE.="700";
IF (&inACCLSS.	IN	("559025"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="260";
IF (&inACCLSS.	IN	("267538"))
	AND (&inPDTCODE.	IN	("816"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="260";
IF (&inACCLSS.	IN	("547905"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("547901"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("504301"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="100";
IF (&inACCLSS.	IN	("503061"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("503050"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("503002"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("332551"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("289130"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("285001"))
	AND (&inPDTCODE.	IN	("387"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="255";
IF (&inACCLSS.	IN	("289036"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("288859"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("122131"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("287601"))
	AND (&inPDTCODE.	IN	("386"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="240";
IF (&inACCLSS.	IN	("287669"))
	AND (&inPDTCODE.	IN	("386"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="240";
IF (&inACCLSS.	IN	("287667"))
	AND (&inPDTCODE.	IN	("386"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="230";
IF (&inACCLSS.	IN	("067526"))
	AND (&inPDTCODE.	IN	("816"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="230";
IF (&inACCLSS.	IN	("067523"))
	AND (&inPDTCODE.	IN	("816"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="241";
IF (&inACCLSS.	IN	("067511"))
	AND (&inPDTCODE.	IN	("816"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="230";
IF (&inACCLSS.	IN	("067501"))
	AND (&inPDTCODE.	IN	("816"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="220";
IF (&inACCLSS.	IN	("133876"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("288843"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="230";
IF (&inACCLSS.	IN	("546057"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("66"))
	THEN &outPDTCODE.="763";
IF (&inACCLSS.	IN	("515001"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="230";
IF (&inACCLSS.	IN	("559025"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="260";
IF (&inACCLSS.	IN	("288123"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("287667"))
	AND (&inPDTCODE.	IN	("386"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="230";
IF (&inACCLSS.	IN	("287669"))
	AND (&inPDTCODE.	IN	("386"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="240";
IF (&inACCLSS.	IN	("287601"))
	AND (&inPDTCODE.	IN	("386"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="240";
IF (&inACCLSS.	IN	("289036"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("285001"))
	AND (&inPDTCODE.	IN	("387"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="255";
IF (&inACCLSS.	IN	("288859"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("332551"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("503001"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inACCLSS.	IN	("503002"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("267538"))
	AND (&inPDTCODE.	IN	("816"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="260";
IF (&inACCLSS.	IN	("547905"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("547901"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("546060"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("503005"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inACCLSS.	IN	("535001"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("504301"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="100";
IF (&inACCLSS.	IN	("503061"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("289130"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("122131"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("067526"))
	AND (&inPDTCODE.	IN	("816"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="230";
IF (&inACCLSS.	IN	("503050"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("133876"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("067501"))
	AND (&inPDTCODE.	IN	("816"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="220";
IF (&inACCLSS.	IN	("067511"))
	AND (&inPDTCODE.	IN	("816"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="230";
IF (&inACCLSS.	IN	("067523"))
	AND (&inPDTCODE.	IN	("816"))
	AND (&inSEGCODE.	IN	("65"))
	THEN &outPDTCODE.="241";
IF (&inACCLSS.	IN	("515017"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("515005"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("515002"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("503013"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inACCLSS.	IN	("503049"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="200";
IF (&inACCLSS.	IN	("547701"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("546059"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="209";
IF (&inACCLSS.	IN	("546056"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="220";
IF (&inACCLSS.	IN	("546001"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="209";
IF (&inACCLSS.	IN	("515003"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("55"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("177732"))
	AND (&inPDTCODE.	IN	("731"))
	THEN &outPDTCODE.="703";
IF (&inACCLSS.	IN	("177732"))
	AND (&inPDTCODE.	IN	("741"))
	THEN &outPDTCODE.="325";
IF (&inACCLSS.	IN	("546057"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="763";
IF (&inACCLSS.	IN	("504157"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="900";
IF (&inACCLSS.	IN	("504102"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="900";
IF (&inACCLSS.	IN	("288831"))
	AND (&inPDTCODE.	IN	("910"))
	AND (&inSEGCODE.	IN	("98"))
	THEN &outPDTCODE.="910";
IF (&inACCLSS.	IN	("288843"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="101";
IF (&inACCLSS.	IN	("515001"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="230";
IF (&inACCLSS.	IN	("559025"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="260";
IF (&inACCLSS.	IN	("288201"))
	AND (&inPDTCODE.	IN	("818"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("288157"))
	AND (&inPDTCODE.	IN	("818"))
	THEN &outPDTCODE.="349";
IF (&inACCLSS.	IN	("288132"))
	AND (&inPDTCODE.	IN	("818"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("288101"))
	AND (&inPDTCODE.	IN	("818"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("285005"))
	AND (&inPDTCODE.	IN	("818"))
	THEN &outPDTCODE.="349";
IF (&inACCLSS.	IN	("268502"))
	AND (&inPDTCODE.	IN	("818"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("503050"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("503005"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inACCLSS.	IN	("503002"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("503001"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inACCLSS.	IN	("332551"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("289130"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("285001"))
	AND (&inPDTCODE.	IN	("387"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="255";
IF (&inACCLSS.	IN	("289036"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("288859"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("122131"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("287601"))
	AND (&inPDTCODE.	IN	("386"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="240";
IF (&inACCLSS.	IN	("287669"))
	AND (&inPDTCODE.	IN	("386"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="240";
IF (&inACCLSS.	IN	("287667"))
	AND (&inPDTCODE.	IN	("386"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="230";
IF (&inACCLSS.	IN	("067526"))
	AND (&inPDTCODE.	IN	("816"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="230";
IF (&inACCLSS.	IN	("067523"))
	AND (&inPDTCODE.	IN	("816"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="241";
IF (&inACCLSS.	IN	("067511"))
	AND (&inPDTCODE.	IN	("816"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="230";
IF (&inACCLSS.	IN	("067501"))
	AND (&inPDTCODE.	IN	("816"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="220";
IF (&inACCLSS.	IN	("503061"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("133876"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("504301"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="100";
IF (&inACCLSS.	IN	("535001"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("546060"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("547901"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("547905"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("267538"))
	AND (&inPDTCODE.	IN	("816"))
	AND (&inSEGCODE.	IN	("61"))
	THEN &outPDTCODE.="260";
IF (&inACCLSS.	IN	("287666"))
	AND (&inPDTCODE.	IN	("818"))
	THEN &outPDTCODE.="349";
IF (&inACCLSS.	IN	("288123"))
	AND (&inPDTCODE.	IN	("818"))
	THEN &outPDTCODE.="311";
IF (&inACCLSS.	IN	("503013"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inACCLSS.	IN	("503049"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inACCLSS.	IN	("515003"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("515005"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("515002"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("547701"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("546059"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="209";
IF (&inACCLSS.	IN	("546056"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="220";
IF (&inACCLSS.	IN	("546001"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="209";
IF (&inACCLSS.	IN	("515017"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("177732"))
	AND (&inPDTCODE.	IN	("726"))
	THEN &outPDTCODE.="850";
IF (&inACCLSS.	IN	("546057"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="763";
IF (&inACCLSS.	IN	("504157"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="900";
IF (&inACCLSS.	IN	("504102"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="900";
IF (&inACCLSS.	IN	("289201"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("288831"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="669";
IF (&inACCLSS.	IN	("170212"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("170211"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("431002"))
	AND (&inPDTCODE.	IN	("821"))
	THEN &outPDTCODE.="340";
IF (&inACCLSS.	IN	("333705"))
	AND (&inPDTCODE.	IN	("820"))
	THEN &outPDTCODE.="340";
IF (&inACCLSS.	IN	("267506"))
	AND (&inPDTCODE.	IN	("816"))
	THEN &outPDTCODE.="340";
IF (&inACCLSS.	IN	("177712"))
	AND (&inPDTCODE.	IN	("815"))
	THEN &outPDTCODE.="340";
IF (&inACCLSS.	IN	("122532"))
	AND (&inPDTCODE.	IN	("388"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("122321"))
	AND (&inPDTCODE.	IN	("388"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("515001"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="230";
IF (&inACCLSS.	IN	("559025"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="260";
IF (&inACCLSS.	IN	("170203"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("289169"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="900";
IF (&inACCLSS.	IN	("288201"))
	AND (&inPDTCODE.	IN	("818"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="209";
IF (&inACCLSS.	IN	("288132"))
	AND (&inPDTCODE.	IN	("818"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="209";
IF (&inACCLSS.	IN	("288126"))
	AND (&inPDTCODE.	IN	("818"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("288123"))
	AND (&inPDTCODE.	IN	("818"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="209";
IF (&inACCLSS.	IN	("288101"))
	AND (&inPDTCODE.	IN	("818"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="209";
IF (&inACCLSS.	IN	("287666"))
	AND (&inPDTCODE.	IN	("818"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("285005"))
	AND (&inPDTCODE.	IN	("818"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("268502"))
	AND (&inPDTCODE.	IN	("818"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="209";
IF (&inACCLSS.	IN	("268501"))
	AND (&inPDTCODE.	IN	("818"))
	THEN &outPDTCODE.="569";
IF (&inACCLSS.	IN	("288899"))
	AND (&inPDTCODE.	IN	("990"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("267538"))
	AND (&inPDTCODE.	IN	("816"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="260";
IF (&inACCLSS.	IN	("547905"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("547901"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("546060"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("535001"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("504301"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="100";
IF (&inACCLSS.	IN	("503061"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("503050"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("503005"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inACCLSS.	IN	("503002"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("503001"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("52"))
	THEN &outPDTCODE.="200";
IF (&inACCLSS.	IN	("332551"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="170";
IF (&inACCLSS.	IN	("289130"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("285001"))
	AND (&inPDTCODE.	IN	("387"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="255";
IF (&inACCLSS.	IN	("289036"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("288859"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("122131"))
	AND (&inPDTCODE.	IN	("826"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("287601"))
	AND (&inPDTCODE.	IN	("386"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="240";
IF (&inACCLSS.	IN	("287669"))
	AND (&inPDTCODE.	IN	("386"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="240";
IF (&inACCLSS.	IN	("287667"))
	AND (&inPDTCODE.	IN	("386"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="230";
IF (&inACCLSS.	IN	("067526"))
	AND (&inPDTCODE.	IN	("816"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="230";
IF (&inACCLSS.	IN	("067523"))
	AND (&inPDTCODE.	IN	("816"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="241";
IF (&inACCLSS.	IN	("067511"))
	AND (&inPDTCODE.	IN	("816"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="230";
IF (&inACCLSS.	IN	("067501"))
	AND (&inPDTCODE.	IN	("816"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="220";
IF (&inACCLSS.	IN	("133876"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("60"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("288157"))
	AND (&inPDTCODE.	IN	("818"))
	AND (&inSEGCODE.	IN	("56"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("288843"))
	AND (&inPDTCODE.	IN	("133"))
	THEN &outPDTCODE.="259";
IF (&inACCLSS.	IN	("515002"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("503019"))
	AND (&inPDTCODE.	IN	("822"))
	THEN &outPDTCODE.="285";
IF (&inACCLSS.	IN	("503013"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inACCLSS.	IN	("208301"))
	AND (&inPDTCODE.	IN	("831"))
	THEN &outPDTCODE.="910";
IF (&inACCLSS.	IN	("299172"))
	AND (&inPDTCODE.	IN	("828"))
	THEN &outPDTCODE.="910";
IF (&inACCLSS.	IN	("503003"))
	AND (&inPDTCODE.	IN	("822"))
	THEN &outPDTCODE.="285";
IF (&inACCLSS.	IN	("503017"))
	AND (&inPDTCODE.	IN	("822"))
	THEN &outPDTCODE.="285";
IF (&inACCLSS.	IN	("503049"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="200";
IF (&inACCLSS.	IN	("504312"))
	AND (&inPDTCODE.	IN	("822"))
	THEN &outPDTCODE.="101";
IF (&inACCLSS.	IN	("510002"))
	AND (&inPDTCODE.	IN	("822"))
	THEN &outPDTCODE.="520";
IF (&inACCLSS.	IN	("515003"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("515005"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("515017"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("505020"))
	AND (&inPDTCODE.	IN	("822"))
	THEN &outPDTCODE.="349";
IF (&inACCLSS.	IN	("547701"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="250";
IF (&inACCLSS.	IN	("555019"))
	AND (&inPDTCODE.	IN	("822"))
	THEN &outPDTCODE.="615";
IF (&inACCLSS.	IN	("333717"))
	AND (&inPDTCODE.	IN	("820"))
	THEN &outPDTCODE.="171";
IF (&inACCLSS.	IN	("546059"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="209";
IF (&inACCLSS.	IN	("177717"))
	AND (&inPDTCODE.	IN	("815"))
	THEN &outPDTCODE.="209";
IF (&inACCLSS.	IN	("546056"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="220";
IF (&inACCLSS.	IN	("546001"))
	AND (&inPDTCODE.	IN	("822"))
	AND (&inSEGCODE.	IN	("54"))
	THEN &outPDTCODE.="209";
%mend cdwmap_PDT_EBBStoPSGL;
