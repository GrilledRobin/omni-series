%macro cdwmap_PDT_DTPBilltoPSGL(
	inBilCat	=
	,outPDTCODE	=
);
if &inBilCat.="AP" then &outPDTCODE.="521";
if &inBilCat.="BR" then &outPDTCODE.="450";
if &inBilCat.="CBC" then &outPDTCODE.="551";
if &inBilCat.="EBC" then &outPDTCODE.="550";
if &inBilCat.="IBC" then &outPDTCODE.="555";
if &inBilCat.="EPL2" then &outPDTCODE.="460";
if &inBilCat.="PB" then &outPDTCODE.="521";
if &inBilCat.="T" then &outPDTCODE.="500";
if &inBilCat.="XT" then &outPDTCODE.="521";

%*Below are from PMI project.;
if &inBilCat.="ACLC" then &outPDTCODE.= "531";
if &inBilCat.="BCLC" then &outPDTCODE.= "555";
if &inBilCat.="BRC" then &outPDTCODE.= "450";
if &inBilCat.="BRF" then &outPDTCODE.= "450";
if &inBilCat.="CBC" then &outPDTCODE.= "551";
if &inBilCat.="CBNNCC" then &outPDTCODE.= "471";
if &inBilCat.="CBNNF" then &outPDTCODE.= "471";
if &inBilCat.="CBNNC" then &outPDTCODE.= "471";
if &inBilCat.="CBNNFC" then &outPDTCODE.= "471";
if &inBilCat.="CBNNFF" then &outPDTCODE.= "471";
if &inBilCat.="CBNYC" then &outPDTCODE.= "470";
if &inBilCat.="CBNYCC" then &outPDTCODE.= "470";
if &inBilCat.="CBNYF" then &outPDTCODE.= "470";
if &inBilCat.="CBNYFC" then &outPDTCODE.= "470";
if &inBilCat.="CCBC" then &outPDTCODE.= "533";
if &inBilCat.="CGTAP" then &outPDTCODE.= "521";
if &inBilCat.="CGTNT" then &outPDTCODE.= "521";
if &inBilCat.="CGTPB" then &outPDTCODE.= "521";
if &inBilCat.="CGTXT" then &outPDTCODE.= "521";
if &inBilCat.="EBC" then &outPDTCODE.= "550";
if &inBilCat.="EPLC" then &outPDTCODE.= "460";
if &inBilCat.="IBC" then &outPDTCODE.= "555";
if &inBilCat.="ILC1S" then &outPDTCODE.= "509";
if &inBilCat.="ILC1UH" then &outPDTCODE.= "509";
if &inBilCat.="ILC1UL" then &outPDTCODE.= "509";
if &inBilCat.="ILC1ULZ" then &outPDTCODE.= "509";
if &inBilCat.="ILCTS" then &outPDTCODE.= "500";
if &inBilCat.="ILCTU" then &outPDTCODE.= "501";
if &inBilCat.="IMLCZ" then &outPDTCODE.= "449";
if &inBilCat.="IMLF" then &outPDTCODE.= "449";
if &inBilCat.="IMLFZ" then &outPDTCODE.= "449";
if &inBilCat.="LATRC" then &outPDTCODE.= "440";
if &inBilCat.="LATRF" then &outPDTCODE.= "440";

if &inBilCat.="LBDR" then &outPDTCODE.= "490";
if &inBilCat.="LBDW" then &outPDTCODE.= "490";
if &inBilCat.="OTRMBD" then &outPDTCODE.= "490";
if &inBilCat.="BRBA" then &outPDTCODE.= "450";
%mend cdwmap_PDT_DTPBilltoPSGL;