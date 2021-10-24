%macro cdwfmt_SASMAP_ProvToID;
%*001.	Introduction.;
%*This is for the ID configuration of Province Level data for SAS/GRAPH process for China Map.;

	%*100.	SAS original map.;
	value $SASMAP_ProvToID_a
		"安徽省"			=	1
		"浙江省"			=	2
		"江西省"			=	3
		"江苏省"			=	4
		"吉林省"			=	5
		"青海省"			=	6
		"福建省"			=	7
		"黑龙江省"			=	8
		"河南省"			=	9
		"河北省"			=	10
		"湖南省"			=	11
		"湖北省"			=	12
		"新疆维吾尔自治区"	=	13
		"西藏自治区"		=	14
		"甘肃省"			=	15
		"广西壮族自治区"	=	16
		"贵州省"			=	18
		"辽宁省"			=	19
		"内蒙古自治区"		=	20
		"宁夏回族自治区"	=	21
		"北京市"			=	22
		"上海市"			=	23
		"山西省"			=	24
		"山东省"			=	25
		"陕西省"			=	26
		"天津市"			=	28
		"云南省"			=	29
		"广东省"			=	30
		"海南省"			=	31
		"四川省"			=	32
		"重庆市"			=	33
		"香港特别行政区"	=	34
		"澳门特别行政区"	=	35
		"台湾省"			=	36
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
		"安徽省"			=	"CN-34"
		"澳门特别行政区"	=	"CN-82"
		"北京市"			=	"CN-11"
		"福建省"			=	"CN-35"
		"甘肃省"			=	"CN-62"
		"广东省"			=	"CN-44"
		"广西壮族自治区"	=	"CN-45"
		"贵州省"			=	"CN-52"
		"海南省"			=	"CN-46"
		"河北省"			=	"CN-13"
		"河南省"			=	"CN-41"
		"黑龙江省"			=	"CN-23"
		"湖北省"			=	"CN-42"
		"湖南省"			=	"CN-43"
		"吉林省"			=	"CN-22"
		"江苏省"			=	"CN-32"
		"江西省"			=	"CN-36"
		"辽宁省"			=	"CN-21"
		"内蒙古自治区"		=	"CN-15"
		"宁夏回族自治区"	=	"CN-64"
		"青海省"			=	"CN-63"
		"山东省"			=	"CN-37"
		"山西省"			=	"CN-14"
		"陕西省"			=	"CN-61"
		"上海市"			=	"CN-31"
		"四川省"			=	"CN-51"
		"天津市"			=	"CN-12"
		"西藏自治区"		=	"CN-54"
		"香港特别行政区"	=	"CN-81"
		"新疆维吾尔自治区"	=	"CN-65"
		"云南省"			=	"CN-53"
		"浙江省"			=	"CN-33"
		"重庆市"			=	"CN-50"
		"台湾省"			=	"CN-83"
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
