%macro cdwfmt_SASMAP_ProvToID;
%*001.	Introduction.;
%*This is for the ID configuration of Province Level data for SAS/GRAPH process for China Map.;

	%*100.	SAS original map.;
	value $SASMAP_ProvToID_a
		"����ʡ"			=	1
		"�㽭ʡ"			=	2
		"����ʡ"			=	3
		"����ʡ"			=	4
		"����ʡ"			=	5
		"�ຣʡ"			=	6
		"����ʡ"			=	7
		"������ʡ"			=	8
		"����ʡ"			=	9
		"�ӱ�ʡ"			=	10
		"����ʡ"			=	11
		"����ʡ"			=	12
		"�½�ά���������"	=	13
		"����������"		=	14
		"����ʡ"			=	15
		"����׳��������"	=	16
		"����ʡ"			=	18
		"����ʡ"			=	19
		"���ɹ�������"		=	20
		"���Ļ���������"	=	21
		"������"			=	22
		"�Ϻ���"			=	23
		"ɽ��ʡ"			=	24
		"ɽ��ʡ"			=	25
		"����ʡ"			=	26
		"�����"			=	28
		"����ʡ"			=	29
		"�㶫ʡ"			=	30
		"����ʡ"			=	31
		"�Ĵ�ʡ"			=	32
		"������"			=	33
		"����ر�������"	=	34
		"�����ر�������"	=	35
		"̨��ʡ"			=	36
	;

	value $SASMAP_ProvToID_b
		"ANHUI"			=	1
		"ZHEJIANG"		=	2
		"JIANGXI"		=	3
		"JIANGSU"		=	4
		"JILIN"			=	5
		"QINGHAI"		=	6
		"FUJIAN"		=	7
		"HEILONGJIANG"	=	8
		"HENAN"			=	9
		"HEBEI"			=	10
		"HUNAN"			=	11
		"HUBEI"			=	12
		"XINJIANG"		=	13
		"XIZANG"		=	14
		"GANSU"			=	15
		"GUANGXI"		=	16
		"GUIZHOU"		=	18
		"LIAONING"		=	19
		"NEIMENGGU"		=	20
		"NINGXIA"		=	21
		"BEIJING"		=	22
		"SHANGHAI"		=	23
		"SHANXI"		=	24
		"SHANDONG"		=	25
		"SHAANXI"		=	26
		"TIANJIN"		=	28
		"YUNNAN"		=	29
		"GUANGDONG"		=	30
		"HAINAN"		=	31
		"SICHUAN"		=	32
		"CHONGQING"		=	33
		"HONGKONG"		=	34
		"MACAU"			=	35
		"TAIWAN"		=	36
	;

	%*200.	SAS GFK map (imported).;
	value $SASMAP_ProvToGFKID_a
		"����ʡ"			=	"CN-34"
		"�����ر�������"	=	"CN-82"
		"������"			=	"CN-11"
		"����ʡ"			=	"CN-35"
		"����ʡ"			=	"CN-62"
		"�㶫ʡ"			=	"CN-44"
		"����׳��������"	=	"CN-45"
		"����ʡ"			=	"CN-52"
		"����ʡ"			=	"CN-46"
		"�ӱ�ʡ"			=	"CN-13"
		"����ʡ"			=	"CN-41"
		"������ʡ"			=	"CN-23"
		"����ʡ"			=	"CN-42"
		"����ʡ"			=	"CN-43"
		"����ʡ"			=	"CN-22"
		"����ʡ"			=	"CN-32"
		"����ʡ"			=	"CN-36"
		"����ʡ"			=	"CN-21"
		"���ɹ�������"		=	"CN-15"
		"���Ļ���������"	=	"CN-64"
		"�ຣʡ"			=	"CN-63"
		"ɽ��ʡ"			=	"CN-37"
		"ɽ��ʡ"			=	"CN-14"
		"����ʡ"			=	"CN-61"
		"�Ϻ���"			=	"CN-31"
		"�Ĵ�ʡ"			=	"CN-51"
		"�����"			=	"CN-12"
		"����������"		=	"CN-54"
		"����ر�������"	=	"CN-81"
		"�½�ά���������"	=	"CN-65"
		"����ʡ"			=	"CN-53"
		"�㽭ʡ"			=	"CN-33"
		"������"			=	"CN-50"
		"̨��ʡ"			=	"CN-83"
	;

	value $SASMAP_ProvToGFKID_b
		"BEIJING"		=	"CN-11"
		"TIANJIN"		=	"CN-12"
		"HEBEI"			=	"CN-13"
		"SHANXI"		=	"CN-14"
		"NEIMENGGU"		=	"CN-15"
		"LIAONING"		=	"CN-21"
		"JILIN"			=	"CN-22"
		"HEILONGJIANG"	=	"CN-23"
		"SHANGHAI"		=	"CN-31"
		"JIANGSU"		=	"CN-32"
		"ZHEJIANG"		=	"CN-33"
		"ANHUI"			=	"CN-34"
		"FUJIAN"		=	"CN-35"
		"JIANGXI"		=	"CN-36"
		"SHANDONG"		=	"CN-37"
		"HENAN"			=	"CN-41"
		"HUBEI"			=	"CN-42"
		"HUNAN"			=	"CN-43"
		"GUANGDONG"		=	"CN-44"
		"GUANGXI"		=	"CN-45"
		"HAINAN"		=	"CN-46"
		"CHONGQING"		=	"CN-50"
		"SICHUANG"		=	"CN-51"
		"GUIZHOU"		=	"CN-52"
		"YUNNAN"		=	"CN-53"
		"XIZANG"		=	"CN-54"
		"SHAANXI"		=	"CN-61"
		"GANSU"			=	"CN-62"
		"QINGHAI"		=	"CN-63"
		"NINGXIA"		=	"CN-64"
		"XINJIANG"		=	"CN-65"
		"KUIQING"		=	"CN-81"
		"HONGKONG"		=	"CN-81"
		"MACAO"			=	"CN-82"
		"TAIWAN"		=	"CN-83"
	;
%mend cdwfmt_SASMAP_ProvToID;
