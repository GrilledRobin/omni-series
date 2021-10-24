%macro cdwfmt_SASMAP_CityToProvID;
	%*100.	SAS original map.;
	*******************************************************
	format for City to Province Code mapping in SAS map
	*******************************************************
	;
	value $SASMAP_CtyToProv_a
		'BJG'		=	22
		'CDU'		=	32
		'CHQ'		=	33
		'CHS'		=	11
		'DLN'		=	19
		'FSN'		=	30
		'GZU'		=	30
		'HGZ'		=	2
		'HHT'		=	20
		'JNA'		=	25
		'NCH'		=	3
		'NGB'		=	2
		'NJG'		=	4
		'QGD'		=	25
		'SHA'		=	23
		'SHZ'		=	30
		'SUZ'		=	4
		'TJN'		=	28
		'WHN'		=	12
		'XAN'		=	26
		'XMN'		=	7
		'ZHA'		=	30
		other		=	0
	;

	value $SASMAP_CtyToProv_b
		'BEIJING'	=	22
		'CHENGDU'	=	32
		'CHONGQING'	=	33
		'CHANGSHA'	=	11
		'DALIAN'	=	19
		'FOSHAN'	=	30
		'GUANGZHOU'	=	30
		'HANGZHOU'	=	2
		'HUHEHAOTE'	=	20
		'NANCHANG'	=	3
		'NANJING'	=	4
		'NINGBO'	=	2
		'QINGDAO'	=	25
		'SHANGHAI'	=	23
		'SHENZHEN'	=	30
		'SUZHOU'	=	4
		'TIANJIN'	=	28
		'WUHAN'		=	12
		'XIAN'		=	26
		'XIAMEN'	=	7
		'ZHUHAI'	=	30
		other		=	0
	;

	%*200.	SAS GFK map (imported).;
	*******************************************************
	format for City to Province Code mapping in SAS/GFK map
	*******************************************************
	;
	value $SASMAP_CtyToGFKProv_a
		'BJG'		=	"CN-11"
		'CDU'		=	"CN-51"
		'CHQ'		=	"CN-50"
		'DLN'		=	"CN-21"
		'GZU'		=	"CN-44"
		'HGZ'		=	"CN-33"
		'HHT'		=	"CN-15"
		'NCH'		=	"CN-36"
		'NGB'		=	"CN-33"
		'NJG'		=	"CN-32"
		'QGD'		=	"CN-37"
		'SHA'		=	"CN-31"
		'SHZ'		=	"CN-44"
		'SUZ'		=	"CN-32"
		'TJN'		=	"CN-12"
		'WHN'		=	"CN-42"
		'XAN'		=	"CN-61"
		'XMN'		=	"CN-35"
		'ZHA'		=	"CN-44"
		other		=	0
	;

	value $SASMAP_CtyToGFKProv_b
		'BEIJING'	=	"CN-11"
		'CHENGDU'	=	"CN-51"
		'CHONGQING'	=	"CN-50"
		'DALIAN'	=	"CN-21"
		'GUANGZHOU'	=	"CN-44"
		'HANGZHOU'	=	"CN-33"
		'HHT'		=	"CN-15"
		'NANCHANG'	=	"CN-36"
		'NANJING'	=	"CN-32"
		'NINGBO'	=	"CN-33"
		'QINGDAO'	=	"CN-37"
		'SHANGHAI'	=	"CN-31"
		'SHENZHEN'	=	"CN-44"
		'SUZHOU'	=	"CN-32"
		'TIANJIN'	=	"CN-12"
		'WUHAN'		=	"CN-42"
		'XIAN'		=	"CN-61"
		'XIAMEN'	=	"CN-35"
		'ZHUHAI'	=	"CN-44"
		other		=	" "
	;
%mend cdwfmt_SASMAP_CityToProvID;