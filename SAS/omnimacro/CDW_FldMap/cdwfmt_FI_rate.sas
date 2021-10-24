%macro cdwfmt_FI_rate;
	*******************************************************
	format for Financial Institute Share Rate mapping
	*******************************************************
	;
%*Before 201206;
%*	value $cdwfmt_FIrate_byName
		'AGRICULTURAL BANK OF CHINA LIMITED'			=	0.007
		'AGRICULTURAL DEVELOPMENT BANK OF CHINA'		=	0.01
		'BANK OF BEIJING CO. LTD'						=	0.012
		'BANK OF CHINA'									=	0.007
		'BANK OF COMMUNICATIONS CO., LTD.'				=	0.0075
		'BANK OF HANGZHOU CO LTD'						=	0
		'BANK OF JIANGSU CO LTD'						=	0
		'BANK OF SHANGHAI CO., LTD.'					=	0.0121
		'BANK OF TOKYO-MITSUBISHI UFJ (CHINA), LTD.'	=	0
		'CHINA CITIC BANK'								=	0.0095
		'CHINA CONSTRUCTION BANK CORPORATION'			=	0.007
		'CHINA DEVELOPMENT BANK CORPORATION'			=	0.01
		'CHINA EVERBRIGHT BANK CO., LTD.'				=	0.011
		'China Guangfa Bank Co., Ltd'					=	0.0217
		'CHINA MERCHANTS BANK'							=	0.0075
		'CHINA MINSHENG BANKING CORPORATION'			=	0.011
		'INDUSTRIAL AND COMMERCIAL BANK OF CHINA'		=	0.007
		'INDUSTRIAL BANK CO LTD'						=	0.0122
		'PING AN BANK CO., LTD.	'						=	0.0217
		'SHANGHAI PUDONG DEVELOPMENT BANK'				=	0.01
		'SHENZHEN DEVELOPMENT BANK CO., LTD.'			=	0.0177
		'THE BANK OF EAST ASIA (CHINA) LTD'				=	0
		'XIAMEN INTERNATIONAL BANK'						=	0
		other	=	0
	;

%*From 201206;
	value $cdwfmt_FIrate_byName
		'AGRICULTURAL BANK OF CHINA LIMITED'			=	0.007
		'BANK OF CHINA'									=	0.005
		'CHINA CONSTRUCTION BANK CORPORATION'			=	0.005
		'INDUSTRIAL AND COMMERCIAL BANK OF CHINA'		=	0.005
		'AGRICULTURAL DEVELOPMENT BANK OF CHINA'		=	0.005
		'CHINA DEVELOPMENT BANK CORPORATION'			=	0.005
		'Export-Import bank of China'					=	0.005
		'BANK OF COMMUNICATIONS CO., LTD.'				=	0.005
		'CHINA CITIC BANK'								=	0.007
		'CHINA MERCHANTS BANK'							=	0.007
		'CHINA MINSHENG BANKING CORPORATION'			=	0.007
		'CHINA EVERBRIGHT BANK CO., LTD.'				=	0.007
		'China Guangfa Bank Co., Ltd'					=	0.007
		'HUA XIA BANK CO., LIMITED'						=	0.007
		'INDUSTRIAL BANK CO LTD'						=	0.007
		'SHANGHAI PUDONG DEVELOPMENT BANK'				=	0.007
		'SHENZHEN DEVELOPMENT BANK CO., LTD.'			=	0.007
		'China Bohai Bank '								=	0.009
		'Bank of Ningbo'								=	0.009
		'BANK OF JIANGSU CO LTD'						=	0.009
		'BANK OF SHANGHAI CO., LTD.'					=	0.009
		'BANK OF BEIJING CO. LTD'						=	0.009
		'XIAMEN INTERNATIONAL BANK'						=	0.0121
		other	=	0
	;
%mend cdwfmt_FI_rate;