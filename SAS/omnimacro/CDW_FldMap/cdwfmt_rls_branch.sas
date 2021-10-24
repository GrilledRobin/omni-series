%macro cdwfmt_rls_branch;
	*******************************************************
	format for Branche code Mapping by Application branch
	*******************************************************
	;

	value $cdwfmt_rls_branch(min=32)
		'0077'				=	'99999'		   /*LOAN CENTRE*/  
		'0100'				=	'10000'		   /*CB SHA-PUDONG BRANCH - FCY*/
		'0101'				=	'10030'        /*CB SHA-PUXI SUB BRANCH - FCY*/
		'0106'				=	'10050'        /*CB SHA HONGQIAO SUB BRANCH - FCY*/
		'0109'				=	'10010'		   /*CB SHA-PUDONG BRANCH - RMB*/
		'0110'				=	'21010'		   /*CB CHENGDU BRANCH - FCY*/
		'0119'				=	'21020'        /*CB CHENGDU BRANCH - RMB */
		'0120'				=	'29010'        /*CB HANGZHOU BRANCH - FCY*/
		'0129'				=	'29020'        /*CB HANGZHOU BRANCH - RMB*/
		'0130'				=	'22010'        /*CB SUZHOU BRANCH - FCY*/
		'0139'				=	'22020'        /*CB SUZHOU BRANCH - RMB*/
		'0140'				=	'12000'        /*CB NANJING BRANCH  - FCY*/
		'0149'				=	'12010'        /*CB NANJING BRANCH  - RMB*/
		'0150'				=	'26530'        /*CB QINGDAO HONG KONG MIDDLE ROAD SUB-BRANCH - FCY*/
		'0159'				=	'26540'        /*CB QINGDAO HONG KANG MIDDLE ROAD SUB-BRANCH - RMB*/
		'0160'				=	'16010'        /*CB ZHUHAI BRANCH - FCY*/
		'0169'				=	'16020'        /*CB ZHUHAI BRANCH - RMB*/
		'0170'				=	'15010'        /*CB XIAMEN BRANCH - FCY*/
		'0179'				=	'15020'        /*CB XIAMEN BRANCH - RMB*/
		'0180'				=	'28010'        /*CB CHONGQING BRANCH - FCY*/
		'0189'				=	'28020'        /*CB CHONGQING BRANCH - RMB*/
		'0190'				=	'31010'        /*CB NANCHANG BRANCH - FCY*/
		'0199'				=	'31020'        /*CB NANCHANG BRANCH - RMB*/
		'0200'				=	'13010'        /*CB SHZ-SHENZHEN BRANCH - FCY*/
		'0209'				=	'13020'        /*CB SHZ-SHENZHEN BRANCH - RMB*/
		'0210'				=	'30010'        /*CB DALIAN BRANCH - FCY*/
		'0219'				=	'30020'        /*CB DALIAN BRANCH - RMB*/
		'0220'				=	'32010'        /*CB NINGBO BRANCH - FCY*/
		'0229'				=	'32020'        /*CB NINGBO BRANCH - RMB*/
		'0230'				=	'33010'        /*CB HOHHOT BRANCH-FCY*/
		'0239'				=	'33020'        /*CB HOHHOT BRANCH-RMB*/
		'0240'				=	'34010'        /*CB WUHAN BRANCH-FCY*/
		'0249'				=	'34020'        /*CB WUHAN BRANCH-RMB*/
		'0250'				=	'35010'			/*FO SHAN BRANCH (FCY)*/
		'0259'				=	'35020'			/*FO SHAN BRANCH (RMB)*/
		'0260'				=	'36010'			/*XI AN BRANCH (FCY)*/
		'0269'				=	'36020'			/*XI AN BRANCH (RMB)*/
		'0270'				=	'22710'			/*KUN SHAN SUB-BRANCH (FCY)*/
		'0279'				=	'22720'			/*KUN SHAN SUB-BRANCH (RMB)*/
		'0370'				=	'99999'        /*CONSUMER LOAN PROCESSING CTR*/
		'0280'				=	'37010'
		'0289'				=	'37020'

		'0400'				=	'20010'        /*CB-GZU GUANGZHOU BRANCH - FCY*/
		'0409'				=	'20020'        /*CB-GZU GUANGZHOU BRANCH - RMB*/
		'0500'				=	'18010'        /*CB-BJG BEIJING BRANCH - FCY*/
		'0509'				=	'18020'        /*CB-BJG BEIJING BRANCH - RMB*/
		'0801'				=	'17010'        /*CB TJN BRANCH - FCY*/
		'0803'				=	'99999'        /*CUSTOMER ASSISTANCE*/
		'0809'				=	'17020'        /*CB TJN BRANCH - RMB*/
		'9999'				=	'99999'        /*DEFAULT BRANCH*/
		other				=	'99999'
	;

	*******************************************************
	format for Branche code Mapping by Application branch
	*******************************************************
	;

	value $cdwfmt_rls_BU(min=32)
		'99999'		  =	'000' 
		'10010'		  =	'077' /*CB SHA-PUDONG BRANCH - FCY*/
		'10030'       =	'077' /*CB SHA-PUXI SUB BRANCH - FCY*/
		'10050'       =	'077' /*CB SHA HONGQIAO SUB BRANCH - FCY*/
		'10020'		  =	'077' /*CB SHA-PUDONG BRANCH - RMB*/
		'21010'		  =	'620' /*CB CHENGDU BRANCH - FCY*/
		'21020'       =	'620' /*CB CHENGDU BRANCH - RMB */
		'29010'       =	'628' /*CB HANGZHOU BRANCH - FCY*/
		'29020'       =	'628' /*CB HANGZHOU BRANCH - RMB*/
		'22010'       =	'621' /*CB SUZHOU BRANCH - FCY*/
		'22020'       =	'621' /*CB SUZHOU BRANCH - RMB*/
		'12010'       =	'616' /*CB NANJING BRANCH  - FCY*/
		'12020'       =	'616' /*CB NANJING BRANCH  - RMB*/
		'26530'       =	'626' /*CB QINGDAO HONG KONG MIDDLE ROAD SUB-BRANCH - FCY*/
		'26540'       =	'626' /*CB QINGDAO HONG KANG MIDDLE ROAD SUB-BRANCH - RMB*/
		'16010'       =	'615' /*CB ZHUHAI BRANCH - FCY*/
		'16020'       =	'615' /*CB ZHUHAI BRANCH - RMB*/
		'15010'       =	'614' /*CB XIAMEN BRANCH - FCY*/
		'15020'       =	'614' /*CB XIAMEN BRANCH - RMB*/
		'28010'       =	'627' /*CB CHONGQING BRANCH - FCY*/
		'28020'       =	'627' /*CB CHONGQING BRANCH - RMB*/
		'31010'       =	'661' /*CB NANCHANG BRANCH - FCY*/
		'31020'       =	'661' /*CB NANCHANG BRANCH - RMB*/
		'13010'       =	'613' /*CB SHZ-SHENZHEN BRANCH - FCY*/
		'13020'       =	'613' /*CB SHZ-SHENZHEN BRANCH - RMB*/
		'30010'       =	'629' /*CB DALIAN BRANCH - FCY*/
		'30020'       =	'629' /*CB DALIAN BRANCH - RMB*/
		'32010'       =	'668' /*CB NINGBO BRANCH - FCY*/
		'32020'       =	'668' /*CB NINGBO BRANCH - RMB*/
		'33010'       =	'669' /*CB HOHHOT BRANCH-FCY*/
		'33020'       =	'669' /*CB HOHHOT BRANCH-RMB*/
		'34010'       =	'670' /*CB WUHAN BRANCH-FCY*/
		'34020'       =	'670' /*CB WUHAN BRANCH-RMB*/
				             
		'20010'       =	'619' /*CB-GZU GUANGZHOU BRANCH - FCY*/
		'20020'       =	'619' /*CB-GZU GUANGZHOU BRANCH - RMB*/
		'18010'       =	'618' /*CB-BJG BEIJING BRANCH - FCY*/
		'18020'       =	'618' /*CB-BJG BEIJING BRANCH - RMB*/
		'17010'       =	'617' /*CB TJN BRANCH - FCY*/
		'17020'       =	'617' /*CB TJN BRANCH - RMB*/   
		other	    	=	'000'     
	
	;	                                 
	
	
	
%mend cdwfmt_rls_branch;