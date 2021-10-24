libname	ybiz	"X:\SME_Data\Source\Business\Monthly";

proc format;
	value $cdwfmt_BR_Unify
		'10010'	=	'10000'
		'10040'	=	'10030'
		'10060'	=	'10050'
		'10080'	=	'10070'
		'10100'	=	'10090'
		'10120'	=	'10110'
		'10140'	=	'10130'
		'10160'	=	'10150'
		'10180'	=	'10170'
		'10200'	=	'10190'

		'12010'	=	'12000'
		'12020'	=	'12000'
		'12040'	=	'12030'
		'12060'	=	'12050'
		'12080'	=	'12070'

		'13020'	=	'13010'
		'13040'	=	'13030'
		'13060'	=	'13050'
		'13080'	=	'13070'
		'13100'	=	'13090'
		'13120'	=	'13110'
		'13140'	=	'13130'
		'13160'	=	'13150'

		'15020'	=	'15010'
		'15040'	=	'15030'
		'15060'	=	'15050'
		'15080'	=	'15070'
		'15100'	=	'15090'

		'16020'	=	'16010'
		'16040'	=	'16030'
		'16060'	=	'16050'

		'17020'	=	'17010'
		'17040'	=	'17030'
		'17060'	=	'17050'
		'17080'	=	'17070'
		'17100'	=	'17090'
		'17120'	=	'17110'
		'17140'	=	'17130'

		'18020'	=	'18010'
		'18040'	=	'18030'
		'18060'	=	'18050'
		'18080'	=	'18070'
		'18100'	=	'18090'
		'18120'	=	'18110'
		'18140'	=	'18130'
		'18160'	=	'18150'
		'18180'	=	'18170'

		'20020'	=	'20010'
		'20040'	=	'20030'
		'20060'	=	'20050'
		'20080'	=	'20070'
		'20100'	=	'20090'

		'21020'	=	'21010'
		'21040'	=	'21030'
		'21060'	=	'21050'
		'21080'	=	'21070'

		'22020'	=	'22010'
		'22040'	=	'22030'
		'22060'	=	'22050'
		'22080'	=	'22070'
		'22100'	=	'22090'

		'26020'	=	'26010'
		'26520'	=	'26510'
		'26540'	=	'26530'
		'26560'	=	'26550'
		'26580'	=	'26570'

		'28020'	=	'28010'
		'28040'	=	'28030'
		'28060'	=	'28050'
		'28080'	=	'28070'

		'29020'	=	'29010'
		'29040'	=	'29030'
		'29060'	=	'29050'

		'30020'	=	'30010'
		'30040'	=	'30030'
		'30060'	=	'30050'

		'31020'	=	'31010'

		'32020'	=	'32010'
		'32040'	=	'32030'

		'33020'	=	'33010'

		'34020'	=	'34010'

		'35020'	=	'35010'

		'36020'	=	'36010'
	;

    value $cbrnch(min=32)
        '10000'='Shanghai Main                 '    
        '10030'='Shanghai Puxi                 '    
        '10050'='Shanghai Hongqiao             '    
        '10070'='Shanghai Xin Tian Di          '    
        '10090'='Shanghai Xu Jia Hui           '    
        '10110'='Shanghai UCT                  '    
        '10130'='Shanghai Zhong Shan Park      '
        '10150'='Shanghai Gu Bei               '            
        '10170'='Shanghai Jing An              '
        '10190'='Shanghai Huaihai Lu           '
        '12000'='Nanjing Branch                '    
        '12030'='Nanjing Xin Jie Kou           '    
        '12050'='Nanjing Longjiang             '    
        '12070'='Nanjing Zhongyang Lu          '
        '13010'='Shenzhen Main                 '    
        '13030'='Shenzhen Futian               '    
        '13050'='Shenzhen Long Gang/Long Cheng '    
        '13070'='Shenzhen Nanshan Central      '    
        '13090'='Shenzhen Hua Qiang Bei        '    
        '13110'='Shenzhen Luohu                '    
        '13130'='Shenzhen Huaqiaocheng         '
        '13150'='Shenzhen Hu Bei               '
        '15010'='Xiamen Branch                 '    
        '15030'='Xiamen JH                     '    
        '15050'='Xiamen Binbe                  ' 
        '15070'='Xiamen Xiahe                  '   
        '15090'='Xiamen Rui Jin                '   
        '16010'='Zhuhai Branch                 '    
        '16030'='Zhuhai Jinshan                '    
        '16050'='Zhuhai Gongbei                '    
        '17010'='Tianjin Branch                '    
        '17050'='Tianjin Binhai                '    
        '17070'='Tianjin Nankai                '    
        '17090'='Tianjin Hai Guang Si          '    
        '17110'='Tianjin You Yi Lu             '    
        '17130'='Tianjin Ao Cheng              '    
        '18010'='Beijing Branch                '    
        '18030'='Beijing Lufthansa             '    
        '18050'='Beijing Zhong Guan Cun        '    
        '18070'='Beijing Huamao                '    
        '18090'='Beijing Oriental Plaza        '    
        '18110'='Beijing Yayuncun Plaza        ' 
        '18130'='Beijing Zizhu                 '           
        '18150'='Beijing Dong Zhi Men          '
        '18170'='Beijing Jin Rong Jie          '
        '20010'='Guangzhou Branch              '    
        '20030'='Guangzhou Tianhe              '    
        '20050'='Guangzhou Taojin              '    
        '20070'='Guangzhou Binjiangdong        '
        '20090'='Guangzhou Liwan               '    
        '21010'='Chengdu Branch                '    
        '21030'='Chengdu Waltz                 '    
        '21050'='Chengdu Zong Fu               '    
        '21070'='Chengdu Guang Hua             '
        '22010'='Suzhou Branch                 '    
        '22030'='Suzhou Leqiao                 '    
        '22050'='Suzhou New District           '     
        '22070'='Suzhou Wu Zhong               '     
        '22090'='Suzhou Kun Shan               '     
        '26010'='Qingdao Branch                '    
        '26530'='Qingdao Middle Hong Kang Road '     
        '26550'='Qingdao Huang Guan            '
        '26570'='Qingdao Qin Ling Lu           '
        '28010'='Chongqing Branch              '
        '28030'='Chongqing Yubei               '    
        '28050'='Chongqing Jiangbei            '
        '28070'='Chongqing Nan An              '
        '29010'='Hangzhou Branch               '    
        '29030'='Hangzhou Wulin                '    
        '29050'='Hangzhou Huang Long           '
        '30010'='Dalian Branch                 '
        '30030'='Dalian Wanda Plaza            '
        '30050'='Dalian Xing Hai               '
        '31010'='Nanchang Branch               '
        '32010'='Ningbo Branch                 '
        '32030'='Ningbo IFSC                   '
        '33010'='Huhehaote Branch              '
        '34010'='Wuhan Branch                  '
        '35010'='Foshan Branch                 '
        '36010'='XiAn Branch                   '
        '10999'='Shanghai DS                   '
        '18999'='Beijing DS                    '
        '55555'='CCC                           ' 
        '77777'='MD                            '
        '88888'='PVB                           '
    	'VDS10'='PmB CRM Hub#1                 '
	    'VDS30'='PmB CRM Hub#2                 '
        '80010'='N/A Branch                    '  
        other='---'                                 
        ;

	value $cdwfmt_CitytoBU
		"10"="077"
		"13"="613"
		"15"="614"
		"16"="615"
		"12"="616"
		"17"="617"
		"18"="618"
		"20"="619"
		"21"="620"
		"22"="621"
		"26"="626"
		"28"="627"
		"29"="628"
		"30"="629"
		"31"="661"
		"32"="668"
		"33"="669"
		"34"="670"
		"35"="671"
		"36"="672"
	;

	value $cdwfmt_EBBSBRtoRLSBR
		'10000'='0100'
		'10030'='0101'
		'10050'='0106'
		'10010'='0109'
		'21010'='0110'
		'21020'='0119'
		'29010'='0120'
		'29020'='0129'
		'22010'='0130'
		'22020'='0139'
		'12000'='0140'
		'12010'='0149'
		'26530'='0150'
		'26540'='0159'
		'16010'='0160'
		'16020'='0169'
		'15010'='0170'
		'15020'='0179'
		'28010'='0180'
		'28020'='0189'
		'31010'='0190'
		'31020'='0199'
		'13010'='0200'
		'13020'='0209'
		'30010'='0210'
		'30020'='0219'
		'32010'='0220'
		'32020'='0229'
		'33010'='0230'
		'33020'='0239'
		'34010'='0240'
		'34020'='0249'
		'20010'='0400'
		'20020'='0409'
		'18010'='0500'
		'18020'='0509'
		'17010'='0801'
		'17020'='0809'
		other=' '
	;
run;

data ybiz.Branch_Code_Control201108(compress=yes);
	set bb;
	format
		D_TABLE			yymmddD10.
		C_BRCODE_UNIFY	$8.
		C_BRCODE_EBBS_FCY	$8.
		C_BRCODE_EBBS_BCY	$8.
		C_BRNAME_CN		$32.
		C_BRNAME_EN		$32.
		C_OU_FCY			$4.
		C_OU_BCY			$4.
		C_Business_Unit		$4.
		C_BRCODE_RLS_FCY	$4.
		C_BRCODE_RLS_BCY	$4.
	;
	length
		C_BRCODE_UNIFY	$8.
		C_BRCODE_EBBS_FCY	$8.
		C_BRCODE_EBBS_BCY	$8.
		C_BRNAME_CN		$32.
		C_BRNAME_EN		$32.
		C_OU_FCY			$4.
		C_OU_BCY			$4.
		C_Business_Unit		$4.
		C_BRCODE_RLS_FCY	$4.
		C_BRCODE_RLS_BCY	$4.
	;
	D_TABLE			=	mdy(8,23,2011);
	C_BRCODE_EBBS_BCY	=	cats(F1);
	C_BRCODE_EBBS_FCY	=	put(C_BRCODE_EBBS_BCY,cdwfmt_BR_Unify.);
	C_BRNAME_CN		=	cats(F2);
	C_BRNAME_EN		=	put(C_BRCODE_EBBS_FCY,cbrnch.);
	C_OU_FCY			=	substr(C_BRCODE_EBBS_FCY,1,4);
	C_OU_BCY			=	substr(C_BRCODE_EBBS_BCY,1,4);
	C_Business_Unit		=	put(substr(C_BRCODE_EBBS_FCY,1,2),cdwfmt_CitytoBU.);
	C_BRCODE_RLS_FCY	=	put(C_BRCODE_EBBS_FCY,cdwfmt_EBBSBRtoRLSBR.);
	C_BRCODE_RLS_BCY	=	put(C_BRCODE_EBBS_BCY,cdwfmt_EBBSBRtoRLSBR.);
	C_BRCODE_UNIFY	=	C_BRCODE_EBBS_FCY;
	drop
		F1
		F2
	;
run;
