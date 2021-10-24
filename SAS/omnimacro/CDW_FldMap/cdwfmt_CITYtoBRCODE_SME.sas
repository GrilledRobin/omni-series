%macro cdwfmt_CITYtoBRCODE_SME;
	*******************************************************
	format for City to Branch Code mapping
	*******************************************************
	;
	value $cdwfmt_CtyNMtoBR_SME
		'BJG'		=	'18010'
		'CDU'		=	'21010'
		'CHQ'		=	'28010'
		'CHQ-NNZ'	=	'28710'
		'DLN'		=	'30010'
		'GZU'		=	'20010'
		'HGZ'		=	'29010'
		'HGZ-XS'	=	'29710'
		'HHT'		=	'33010'
		'NCH'		=	'31010'
		'NGB'		=	'32010'
		'NJG'		=	'12000'
		'QGD'		=	'26010'
		'QGD-HER'	=	'26710'
		'SHA'		=	'10000'
		'SHA-MHN'	=	'10710'
		'SHZ'		=	'13010'
		'SUZ'		=	'22010'
		'SUZ-KSN'	=	'22710'
		'TJN'		=	'17010'
		'WHN'		=	'34010'
		'XAN'		=	'36010'
		'XMN'		=	'15010'
		'ZHA'		=	'16010'
		other		=	'99999'
	;

	value $cdwfmt_CtyLongtoBR_SME
		'BEIJING'	=	'18010'
		'CHENGDU'	=	'21010'
		'CHONGQING'	=	'28010'
		'DALIAN'	=	'30010'
		'GUANGZHOU'	=	'20010'
		'HANGZHOU'	=	'29010'
		'HHT'		=	'33010'
		'NANCHANG'	=	'31010'
		'NANJING'	=	'12000'
		'NBO'		=	'32010'
		'NINGBO'	=	'32010'
		'QINGDAO'	=	'26010'
		'SHANGHAI'	=	'10000'
		'SHENZHEN'	=	'13010'
		'SUZHOU'	=	'22010'
		'TIANJIN'	=	'17010'
		'WUH'		=	'34010'
		'WUHAN'		=	'34010'
		'XAN'		=	'36010'
		'XIAMEN'	=	'15010'
		'ZHUHAI'	=	'16010'
		other		=	'99999'
	;
%mend cdwfmt_CITYtoBRCODE_SME;