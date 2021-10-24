%macro cdwmap_CUSTSEG_EBBStoPSGL(
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
	,outCUSTSEG=
);
IF (&inCUSTSEG.	IN	("021"))
	THEN &outCUSTSEG.="21";
IF (&inCUSTSEG.	IN	("112"))
	THEN &outCUSTSEG.="12";
IF (&inCUSTSEG.	IN	("120"))
	THEN &outCUSTSEG.="17";
IF (&inCUSTSEG.	IN	("022"))
	THEN &outCUSTSEG.="22";
IF (&inCUSTSEG.	IN	("016"))
	THEN &outCUSTSEG.="16";
IF (&inCUSTSEG.	IN	("116"))
	THEN &outCUSTSEG.="16";
IF (&inCUSTSEG.	IN	("113"))
	THEN &outCUSTSEG.="13";
IF (&inCUSTSEG.	IN	("121"))
	THEN &outCUSTSEG.="21";
IF (&inCUSTSEG.	IN	("114"))
	THEN &outCUSTSEG.="14";
IF (&inCUSTSEG.	IN	("029"))
	THEN &outCUSTSEG.="29";
IF (&inCUSTSEG.	IN	("122"))
	THEN &outCUSTSEG.="22";
IF (&inCUSTSEG.	IN	("110"))
	THEN &outCUSTSEG.="10";
IF (&inCUSTSEG.	IN	("115"))
	THEN &outCUSTSEG.="15";
IF (&inCUSTSEG.	IN	("015"))
	THEN &outCUSTSEG.="15";
IF (&inCUSTSEG.	IN	("111"))
	THEN &outCUSTSEG.="11";
IF (&inCUSTSEG.	IN	("123"))
	THEN &outCUSTSEG.="21";
IF (&inCUSTSEG.	IN	("014"))
	THEN &outCUSTSEG.="14";
IF (&inCUSTSEG.	IN	("305"))
	THEN &outCUSTSEG.="300";
IF (&inCUSTSEG.	IN	("460"))
	THEN &outCUSTSEG.="460";
IF (&inCUSTSEG.	IN	("505"))
	THEN &outCUSTSEG.="500";
IF (&inCUSTSEG.	IN	("420"))
	THEN &outCUSTSEG.="500";
IF (&inCUSTSEG.	IN	("655"))
	THEN &outCUSTSEG.="650";
IF (&inCUSTSEG.	IN	("960"))
	THEN &outCUSTSEG.="950";
IF (&inCUSTSEG.	IN	("124"))
	THEN &outCUSTSEG.="22";
IF (&inCUSTSEG.	IN	("659"))
	THEN &outCUSTSEG.="659";
IF (&inCUSTSEG.	IN	("970"))
	THEN &outCUSTSEG.="950";
IF (&inCUSTSEG.	IN	("010"))
	THEN &outCUSTSEG.="10";
IF (&inCUSTSEG.	IN	("950"))
	THEN &outCUSTSEG.="950";
IF (&inCUSTSEG.	IN	("658"))
	THEN &outCUSTSEG.="650";
IF (&inCUSTSEG.	IN	("026"))
	THEN &outCUSTSEG.="26";
IF (&inCUSTSEG.	IN	("609"))
	THEN &outCUSTSEG.="609";
IF (&inCUSTSEG.	IN	("508"))
	THEN &outCUSTSEG.="500";
IF (&inCUSTSEG.	IN	("468"))
	THEN &outCUSTSEG.="460";
IF (&inCUSTSEG.	IN	("440"))
	THEN &outCUSTSEG.="440";
IF (&inCUSTSEG.	IN	("428"))
	THEN &outCUSTSEG.="420";
IF (&inCUSTSEG.	IN	("409"))
	THEN &outCUSTSEG.="409";
IF (&inCUSTSEG.	IN	("400"))
	THEN &outCUSTSEG.="500";
IF (&inCUSTSEG.	IN	("359"))
	THEN &outCUSTSEG.="359";
IF (&inCUSTSEG.	IN	("358"))
	THEN &outCUSTSEG.="350";
IF (&inCUSTSEG.	IN	("350"))
	THEN &outCUSTSEG.="350";
IF (&inCUSTSEG.	IN	("309"))
	THEN &outCUSTSEG.="309";
IF (&inCUSTSEG.	IN	("308"))
	THEN &outCUSTSEG.="300";
IF (&inCUSTSEG.	IN	("300"))
	THEN &outCUSTSEG.="300";
IF (&inCUSTSEG.	IN	("028"))
	THEN &outCUSTSEG.="28";
IF (&inCUSTSEG.	IN	("027"))
	THEN &outCUSTSEG.="26";
IF (&inCUSTSEG.	IN	("025"))
	THEN &outCUSTSEG.="25";
IF (&inCUSTSEG.	IN	("020"))
	THEN &outCUSTSEG.="17";
IF (&inCUSTSEG.	IN	("013"))
	THEN &outCUSTSEG.="13";
IF (&inCUSTSEG.	IN	("011"))
	THEN &outCUSTSEG.="11";
IF (&inCUSTSEG.	IN	("012"))
	THEN &outCUSTSEG.="12";
IF (&inCUSTSEG.	IN	("355"))
	THEN &outCUSTSEG.="350";
IF (&inCUSTSEG.	IN	("500"))
	THEN &outCUSTSEG.="500";
IF (&inCUSTSEG.	IN	("469"))
	THEN &outCUSTSEG.="469";
IF (&inCUSTSEG.	IN	("024"))
	THEN &outCUSTSEG.="22";
IF (&inCUSTSEG.	IN	("448"))
	THEN &outCUSTSEG.="440";
IF (&inCUSTSEG.	IN	("600"))
	THEN &outCUSTSEG.="600";
IF (&inCUSTSEG.	IN	("509"))
	THEN &outCUSTSEG.="509";
IF (&inCUSTSEG.	IN	("608"))
	THEN &outCUSTSEG.="600";
IF (&inCUSTSEG.	IN	("650"))
	THEN &outCUSTSEG.="650";
IF (&inCUSTSEG.	IN	("449"))
	THEN &outCUSTSEG.="449";
IF (&inCUSTSEG.	IN	("429"))
	THEN &outCUSTSEG.="429";
IF (&inCUSTSEG.	IN	("630"))
	THEN &outCUSTSEG.="630";
IF (&inCUSTSEG.	IN	("097"))
	THEN &outCUSTSEG.="98";
IF (&inCUSTSEG.	IN	("098"))
	THEN &outCUSTSEG.="98";
IF (&inCUSTSEG.	IN	("099"))
	THEN &outCUSTSEG.="98";
IF (&inCUSTSEG.	IN	("408"))
	THEN &outCUSTSEG.="400";
IF (&inCUSTSEG.	IN	("023"))
	THEN &outCUSTSEG.="21";
IF (&inACCLSS.	IN	("191701"))
	AND (&inPDTCODE.	IN	("642"))
	THEN &outCUSTSEG.="26";
IF (&inACCLSS.	IN	("291756"))
	AND (&inPDTCODE.	IN	("642"))
	THEN &outCUSTSEG.="26";
IF (&inACCLSS.	IN	("191858"))
	AND (&inPDTCODE.	IN	("642"))
	THEN &outCUSTSEG.="26";
IF (&inACCLSS.	IN	("192701"))
	AND (&inPDTCODE.	IN	("642"))
	THEN &outCUSTSEG.="26";
IF (&inACCLSS.	IN	("123001"))
	AND (&inPDTCODE.	IN	("642"))
	THEN &outCUSTSEG.="26";
IF (&inACCLSS.	IN	("122005"))
	AND (&inPDTCODE.	IN	("642"))
	THEN &outCUSTSEG.="26";
IF (&inACCLSS.	IN	("122001"))
	AND (&inPDTCODE.	IN	("642"))
	THEN &outCUSTSEG.="26";
IF (&inACCLSS.	IN	("288899"))
	THEN &outCUSTSEG.="98";
IF (&inACCLSS.	IN	("122001"))
	AND (&inPDTCODE.	IN	("644"))
	THEN &outCUSTSEG.="950";
IF (&inACCLSS.	IN	("191858"))
	AND (&inPDTCODE.	IN	("644"))
	THEN &outCUSTSEG.="10";
IF (&inACCLSS.	IN	("291756"))
	AND (&inPDTCODE.	IN	("644"))
	THEN &outCUSTSEG.="10";
IF (&inACCLSS.	IN	("188001"))
	THEN &outCUSTSEG.="950";
IF (&inACCLSS.	IN	("192701"))
	AND (&inPDTCODE.	IN	("644"))
	THEN &outCUSTSEG.="10";
IF (&inACCLSS.	IN	("191701"))
	AND (&inPDTCODE.	IN	("644"))
	THEN &outCUSTSEG.="10";
IF (&inACCLSS.	IN	("123001"))
	AND (&inPDTCODE.	IN	("644"))
	THEN &outCUSTSEG.="10";
IF (&inACCLSS.	IN	("122005"))
	AND (&inPDTCODE.	IN	("644"))
	THEN &outCUSTSEG.="10";
IF (&inACCLSS.	IN	("288870"))
	THEN &outCUSTSEG.="98";
IF (&inACCLSS.	IN	("555003"))
	THEN &outCUSTSEG.="950";
IF (&inACCLSS.	IN	("188011"))
	THEN &outCUSTSEG.="950";
IF (&inACCLSS.	IN	("895001"))
	THEN &outCUSTSEG.="950";
IF (&inACCLSS.	IN	("860009"))
	AND (&inPDTCODE.	IN	("827"))
	THEN &outCUSTSEG.="";
IF (&inACCLSS.	IN	("175501"))
	THEN &outCUSTSEG.="950";
IF (&inACCLSS.	IN	("289276"))
	THEN &outCUSTSEG.="98";
IF (&inACCLSS.	IN	("175506"))
	THEN &outCUSTSEG.="950";
IF (&inACCLSS.	IN	("175508"))
	THEN &outCUSTSEG.="950";
IF (&inACCLSS.	IN	("322001"))
	AND (&inPDTCODE.	IN	("829"))
	THEN &outCUSTSEG.="950";
IF (&inACCLSS.	IN	("288101"))
	AND (&inPDTCODE.	IN	("576"))
	THEN &outCUSTSEG.="10";
IF (&inPDTCODE.	IN	("817"))
	THEN &outCUSTSEG.="98";
IF (&inPDTCODE.	IN	("817"))
	AND (&inACCLSS.	IN	("175101"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("817"))
	AND (&inACCLSS.	IN	("175153"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("551"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("818"))
	THEN &outCUSTSEG.="98";
IF (&inPDTCODE.	IN	("632"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("645"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("633"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("647"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("648"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("649"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("652"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("636"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("639"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("546"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("650"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("533"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("548"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("549"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("998"))
	THEN &outCUSTSEG.="98";
IF (&inPDTCODE.	IN	("552"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("805"))
	THEN &outCUSTSEG.="98";
IF (&inPDTCODE.	IN	("816"))
	THEN &outCUSTSEG.="98";
IF (&inPDTCODE.	IN	("815"))
	THEN &outCUSTSEG.="98";
IF (&inPDTCODE.	IN	("772"))
	THEN &outCUSTSEG.="98";
IF (&inPDTCODE.	IN	("801"))
	THEN &outCUSTSEG.="98";
IF (&inPDTCODE.	IN	("653"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("802"))
	THEN &outCUSTSEG.="98";
IF (&inPDTCODE.	IN	("804"))
	THEN &outCUSTSEG.="98";
IF (&inPDTCODE.	IN	("999"))
	THEN &outCUSTSEG.="98";
IF (&inPDTCODE.	IN	("803"))
	THEN &outCUSTSEG.="98";
IF (&inPDTCODE.	IN	("643"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("771"))
	THEN &outCUSTSEG.="98";
IF (&inPDTCODE.	IN	("635"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("535"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("550"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("534"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("547"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("532"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("651"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("634"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("646"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("545"))
	THEN &outCUSTSEG.="950";
IF (&inPDTCODE.	IN	("718"))
	THEN &outCUSTSEG.="98";
IF (&inPDTCODE.	IN	("811"))
	THEN &outCUSTSEG.="10";
IF (&inPDTCODE.	IN	("340"))
	THEN &outCUSTSEG.="500";
%mend cdwmap_CUSTSEG_EBBStoPSGL;
