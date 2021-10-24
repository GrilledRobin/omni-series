%macro cdwfmt_PDT_Type;
	*******************************************************
	format for Product Type Mapping by Loan Product
	*******************************************************
	;
%*NOTE: Here the 2-digit product codes are from RLS SECTOR CODE;
	value $cdwfmt_LNTP_b(min=16)
		'30'				=	'Equity Loan'
		'31'				=	'Equity Loan'
		'32'				=	'Equity Loan'
		'40'				=	'Equity Loan'
		'41'				=	'Equity Loan'
		'42'				=	'Equity Loan'
		'45'				=	'Equity Loan'
		'70'				=	'Equity Loan'
		'88'				=	'BIL'
		'89'				=	'LAP'
		'90'	-	'92'	=	'RLS CPML'
		'93'	-	'96'	=	'RLS TermLoan'
		other				=	'Others'
	;

	*******************************************************
	format for Product Type Mapping by Product Code
	*******************************************************
	;
	value $cdwfmt_PDTTP_non
		'201'	-<	'204'	=	'Basic A/C'
		'204'	-<	'208'	=	'General A/C'
		'208'	-<	'241'	=	'Others'
		'241'	-<	'245'	=	'Capital A/C'
		'245'	-<	'249'	=	'Settlement A/C'
		'252'				=	'Loan A/C'
		'254'				=	'Foreign A/C'
		other				=	'Others'
	;

%*20110101;
	value $cdwfmt_PDTTP_a(min=16)
		'201'	-	'319'	=	'CASA'
		'501'	-	'618'	=	'TD'
		'705'	-	'718'	=	'EBBS TermLoan'
		'719'	-	'722'	=	'EBBS CPML'
		other				=	'Others'
	;
%*20110226;
%*	value $cdwfmt_PDTTP_a(min=16)
		'105'	-	'117'	=	'EBBS TermLoan'
		'119'				=	'EBBS CPML'
		'120'				=	'EBBS CPML'
		'122'				=	'EBBS TermLoan'
		'123'				=	'EBBS TermLoan'
		'141'				=	'EBBS TermLoan'
		'142'				=	'EBBS TermLoan'
		'144'				=	'EBBS TermLoan'
		'163'				=	'EBBS TermLoan'
		'201'	-	'290'	=	'CASA'
		'301'	-	'308'	=	'TD'
		'309'				=	'CASA'
		'311'	-	'318'	=	'TD'
		'319'				=	'CASA'
		'351'	-	'366'	=	'CASA'
		'501'	-	'618'	=	'TD'
		'643'				=	'EBBS TermLoan'
		'653'				=	'TD'
		'701'				=	'EBBS TermLoan'
		'702'				=	'EBBS TermLoan'
		'705'	-	'718'	=	'EBBS TermLoan'
		'719'	-	'722'	=	'EBBS CPML'
		'812'				=	'EBBS TermLoan'
		'813'				=	'EBBS TermLoan'
		'814'				=	'EBBS TermLoan'
		other				=	'Others'
	;

	%*At below level, the segments match those in PSGL.;
	value $cdwfmt_PDTTP_b(min=16)
		'CD'			=	'CASA'
		'CASA AMS'		=	'CASA'
		'RLS CPML'		=	'CPML'
		'EBBS CPML'		=	'CPML'
		'CBN'			=	'IMEXDTP'
		'CBW'			=	'IMEXDTP'
		'BAD'			=	'IMEXDTP'
		'Excl. CBN'		=	'IMEXDTP'
		'BNC Biz'		=	'BANCA'
		'BNC Life'		=	'BANCA'
	;

	value $cdwfmt_PDTTP_c(min=16)
		'TD'			=	'Deal Deposit'
		'SD'			=	'Deal Deposit'
		'RLS TermLoan'	=	'TermLoan'
		'EBBS TermLoan'	=	'TermLoan'
		'IMEXDTP'		=	'Trade'
		'OTP'			=	'Trade'
	;

	*******************************************************
	format for Product Category Mapping by Product Code
	*******************************************************
	;
	value $cdwfmt_PDTCAT_a(min=16)
		'BIL'			=	'Loan'
		'LAP'			=	'Loan'
		'CPML'			=	'Loan'
		'BMOA'			=	'Loan'
		'CASA'			=	'Deposit'
		'Deal Deposit'	=	'Deposit'
		'TermLoan'		=	'TWCL'
		'Trade'			=	'TWCL'
		'BANCA'			=	'OffBal'
		'FX'			=	'OffBal'
	;

	*******************************************************
	format for PSGL Mapping by Product Code
	*******************************************************
	;
	value $cdwfmt_PSGLTP_a(min=16)
%*-> 20130617 Added by Lu Robin Bin.;
		'101'='CASA'			%*This is from NFIEOM, which seems incorrect.;
%*<- 20130617 Added by Lu Robin Bin.;
		'110'='BIL'
		'170'='CPML'
		'171'='CPML'
		'172'='BMOA'
		'174'='CPML'
		'200'='EBBS TermLoan'
		'201'='RLS TermLoan'
		'202'='RLS TermLoan'
		'204'='LAP'
		'209'='RLS TermLoan'
		'220'='CASA'			%*In Dealdeposits, it represents CD;
		'225'='CASA'
		'230'='CASA'
		'240'='TD'				%*Retail TD;
		'250'='CASA'			%*Fee Income;
		'255'='CASA AMS'		%*Fee Income;
		'259'='CASA AMS'		%*Fee Income;
		'260'='RLI'				%*Rate Link Deposit;
		'285'='CASA'
		'295'='CASA-OD'
		'300'='GTEE'
		'311'='CASA'
		'330'='CASA'			%*Corporate Interest Bearing CA;
		'340'='CASA'
		'343'='CASA'
		'347'='CD'
		'349'='Others'			%*Currently including Entrustment Loan;
		'360'='CASA'
		'361'='CASA'
		'374'='CASA'
		'379'='CASA'
		'390'='CASA'
		'393'='CASA AMS'
		'398'='CASA'
		'399'='CASA'
		'401'='CASA AMS'
		'402'='CASA AMS'
		'403'='CASA AMS'
		'406'='CASA AMS'
		'440'='TradeLoan'
		'441'='TradeLoan'
		'442'='Imp.Inv.'
		'443'='TradeLoan'
		'449'='TradeLoan'
		'450'='Rec.Svc.'
		'460'='TradeLoan'
		'470'='CBN'				%*TradeLoan;
		'471'='CBW'				%*TradeLoan;
		'472'='LC'
		'480'='OB'
		'481'='Exp.Inv.'
		'483'='TradeLoan'
		'490'='BAD Disc.'
		'494'='Rec.Svc.'
		'495'='Rec.Svc.'
		'500'='LC'
		'501'='LC'
		'509'='Imp.LC.Unsec.'
		'515'='LC'
		'520'='GTEE'
		'521'='GTEE'
		'525'='GTEE'
		'530'='LBD'
		'531'='BAD'
		'533'='BAD'
		'535'='BAD'
		'540'='LC'
		'545'='LC'
		'550'='EBC'
		'551'='CBC'
		'555'='IBC'
		'563'='FF'				%*Facility Fee;
		'569'='Trade'
		'615'='FXS'				%*20141126 Changed from the previous "FXO" as the definition was inappropriate;
		'625'='FXF'
		'658'='IRS'
		'669'='PCD'
		'675'='FXO'
		'710'='CASA'			%*Primary Arrangement Fee;
		'755'='TD'				%*ALM TD;
		'760'='CASA AMS'		%*Borrowings - Int/Grp;
		'763'='PCI'				%*ALM PCI;
		'900'='BANCA'
	;
	value $cdwfmt_PSGLTP_b(min=16)
		'CASA AMS'		=	'CASA'
		'CASA-OD'		=	'CASA'
		'CD'			=	'CASA'
		'RLS TermLoan'	=	'TermLoan'
		'EBBS TermLoan'	=	'TermLoan'
		'TradeLoan'		=	'Trade'
		'BR'			=	'Trade'
		'CBN'			=	'Trade'
		'CBW'			=	'Trade'
		'LC'			=	'Trade'
		'OB'			=	'Trade'
		'GTEE'			=	'Trade'
		'LBD'			=	'Trade'
		'BAD'			=	'Trade'
		'EBC'			=	'Trade'
		'CBC'			=	'Trade'
		'IBC'			=	'Trade'
		'FF'			=	'Trade'
		'Rec.Svc.'		=	'Trade'
		'Imp.LC.Unsec.'	=	'Trade'
		'BAD Disc.'		=	'Trade'
		'Imp.Inv.'		=	'Trade'
		'Exp.Inv.'		=	'Trade'
		'FXF'			=	'FX'
		'FXO'			=	'FX'
		'FXS'			=	'FX'
		'IRS'			=	'FX'		%*20141126 Currently set as FX for management reporting.;
		'PCD'			=	'SD'
		'RLI'			=	'SD'
	;

%*"amo" -> Amotization.;
%*NOTE: Here the IMEXDTP and OTP are not properly identified, please truncate these parts during calculation.;
	value $cdwfmt_PSGLamoTP_b(min=16)
		'110'='BIL'
		'130'='CASA'
		'131'='CASA'
		'170'='CPML'
		'174'='CPML'
		'171'='CPML'
		'172'='CPML'
		'200'='EBBS TermLoan'
		'201'='RLS TermLoan'
		'202'='EBBS TermLoan'
		'203'='EBBS TermLoan'		%*Bankers Guarantee;
		'204'='LAP'
		'209'='EBBS TermLoan'
		'220'='CASA'
		'225'='CASA'
		'230'='CASA'
		'240'='TD'				%*Retail TD;
		'250'='CASA'			%*Fee Income;
		'255'='CASA'			%*Fee Income;
		'256'='CASA'			%*Fee Income;
		'259'='CASA'			%*Fee Income;
		'260'='CASA'			%*Rate Link Deposit;
		'330'='CASA'			%*Corporate Interest Bearing CA;
		'333'='TD'				%*Corporate TD;
		'347'='CASA'			%*This used to be CD;
		'349'='CASA'
		'386'='TD'				%*TB Fixed Deposit;
		'440'='IMEXDTP'
		'441'='IMEXDTP'
		'442'='IMEXDTP'
		'443'='IMEXDTP'
		'449'='IMEXDTP'
		'450'='IMEXDTP'
		'460'='IMEXDTP'
		'470'='IMEXDTP'
		'471'='IMEXDTP'
		'472'='IMEXDTP'
		'480'='IMEXDTP'
		'481'='IMEXDTP'
		'490'='IMEXDTP'
		'494'='OTP'
		'495'='OTP'
		'500'='IMEXDTP'			%*LC;
		'509'='IMEXDTP'			%*LC;
		'515'='IMEXDTP'			%*LC;
		'520'='IMEXDTP'			%*Guarantee;
		'521'='IMEXDTP'			%*Guarantee;
		'525'='IMEXDTP'			%*Guarantee;
		'530'='IMEXDTP'
		'531'='IMEXDTP'			%*Acceptance;
		'533'='IMEXDTP'			%*Acceptance;
		'535'='IMEXDTP'			%*Acceptance;
		'540'='IMEXDTP'			%*LC;
		'545'='IMEXDTP'			%*LC;
		'550'='IMEXDTP'			%*EBC;
		'551'='IMEXDTP'			%*CBC;
		'555'='IMEXDTP'			%*IBC;
		'563'='IMEXDTP'			%*Facility Fee;
		'564'='IMEXDTP'			%*Trade Services - Insurance;
		'569'='IMEXDTP'
		'615'='FX'				%*FX Spot;
		'625'='FX'				%*FX Forward;
		'658'='FX'				%*Interest Rate Swap;
		'659'='IMEXDTP'			%*IR rates;
		'669'='IMEXDTP'			%*Other Global Derivatives;
		'675'='FX'				%*Global FX Options;
		'676'='SD'				%*Structured FXO;
		'705'='EBBS TermLoan'	%*Asset Back;
		'710'='CASA'			%*Primary Arrangement Fee;
		'755'='TD'				%*ALM TD;
		'763'='PCI'				%*ALM PCI;
		'900'='BANCA'
	;
	*******************************************************
	format for PSGL FTP by Product Code
	*******************************************************
	;
	value $cdwfmt_FTPamoTP_b(min=16)
		'259'='IMEXCCC'
		'569'='IMEXCCC'
	;

	*******************************************************
	format for Account Class Mapping by Product Code
	*******************************************************
	;
	value $cdwfmt_ACCCLSS_a
		'88'				=	'000000'
		'89'				=	'000000'
		'90'				=	'000000'
		'93'	-	'96'	=	'000000'
	;
%*NOTE: Here we do not use the "other" operand, for there are much more codes that we cannot define but only retain them to the new field;
%mend cdwfmt_PDT_Type;
