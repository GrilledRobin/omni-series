%macro cdwfmt_PSGL_PDT_Type;
	*******************************************************
	format for Product Type Mapping by PSGL Product
	*******************************************************
	;
	value $cdwfmt_PSGLPDTDesc(min=32)
		"100"="Credit Card - Issuing"
		"101"="Credit Card - Acquiring"
		"110"="Instalment Loans"
		"120"="Revolving Credit"
		"130"="Personal Overdrafts - Ret"
		"131"="BFS Overdrafts"
		"132"="Unsecured Overdrafts"
		"139"="Other Unsecured Lending"
		"140"="Securitised Mortgage"
		"150"="M2 Loan"
		"151"="M2 Deposits CA (Netting)"
		"153"="M2 Deposits CA (Non Netting)"
		"156"="OREO Property"
		"157"="MOA - Partial Offset"
		"160"="Auto Loan"
		"169"="Mortgage Loan - MLT Quota"
		"170"="Mortgag Lns-Residentl(Private)"
		"171"="Mortgage Lns - Commercial"
		"172"="Mortgage One Account(Private)"
		"173"="Mortgage Overdraft"
		"174"="Mortgage Related Lending"
		"177"="SMI One Account"
		"178"="Index Linked Mortgage"
		"179"="Mortgage Loans-Second Mortgage"
		"180"="Sec Backed Installment Ln"
		"181"="Sec Backed Revolving O/D"
		"188"="Unsecured Biz Revolving OD"
		"192"="SME Ln-With Credit Guarantee"
		"193"="SME Ln-Outside Cr Guarantee"
		"200"="Term Lns-N/Trd-Fixed"
		"201"="Term Lns-N/Trd-Prime"
		"202"="Term Lns-N/Trd-M/M"
		"203"="Bankers Guarantee"
		"204"="Loans Against Property"
		"207"="BEF-Installment Loan"
		"208"="Secured BIL"
		"209"="Other Term Loans"
		"210"="Money Market Loan- Pvt Bk"
		"220"="Interest Bearing C/A - Ret"
		"225"="Non-Interest Bearing C/A - Ret"
		"230"="Savings Accounts - Ret"
		"240"="Time Deposits - Ret"
		"241"="Time Deposit - Other"
		"242"="Money Market Deposit -Pvt Bk"
		"244"="Time Deposits - SME"
		"245"="Fiduciary Dep.-P/Clients"
		"246"="FCNR Deposits"
		"247"="NR Term Deposits"
		"249"="Safe Deposit Box"
		"250"="Payment Services - Ret"
		"251"="ATM - Debit Card"
		"255"="Other Branch and Banking Fees"
		"259"="AMS services"
		"260"="Rate Linked Deposit"
		"262"="Equity Linked Deposit"
		"265"="Equity Linked Notes"
		"266"="Prem Curr Investment-Cnsmr Bk"
		"270"="Unit Trusts"
		"271"="Trust Services"
		"272"="Fund Management Services"
		"273"="Regular Savings Plan"
		"274"="Mandatory Provident Funds"
		"275"="Security Services"
		"276"="Structured Funds"
		"277"="Structured Notes"
		"279"="Other Investmt Mgmt Products"
		"281"="Discretionary Portfolios"
		"282"="Client Direct Wrap"
		"285"="Term Lns - N/Trd -Fixed -N/Ret"
		"286"="Term Lns - N/Trd -Prime -N/Ret"
		"287"="Term Lns - N/Trd - M/M - N/Ret"
		"288"="Asset Backed Financing"
		"295"="Overdrafts - N/Ret"
		"296"="Vostro Debit"
		"300"="Financial Guarantees"
		"301"="ALM Sales - Others"
		"305"="Project Finance"
		"307"="Intergroup Indemnities"
		"311"="Other Corp/Inst Products"
		"312"="IPOs"
		"314"="Lending Debt. Prov."
		"316"="Administrative Services"
		"317"="Compliance Services"
		"318"="Cayman Trust"
		"319"="Other Corporate Finance"
		"320"="CRE Term Loan"
		"321"="CRE Revolving Term Loan"
		"322"="ABF Term Loan"
		"323"="ABF Revolving Term Loan"
		"324"="ABF Financial Lease"
		"325"="CandI Term Loan"
		"326"="CandI Short Term Loans"
		"327"="CandI Revolving Term Loan"
		"328"="CandI Financial Lease"
		"329"="Corporate Trust"
		"330"="Corp Int Bearing Current A/c"
		"331"="Premium Saving Accounts"
		"332"="Corp Savings A/c"
		"333"="Corporate Time Deposits"
		"334"="Clearing-OG CT Mthend Fee"
		"335"="Clearing-OG CT Same Day Fee"
		"336"="CIM Term Loan"
		"337"="CIM Revolving Term Loan"
		"338"="Lendg Con/UnFunded Risk Parcpn"
		"339"="Operating Leases"
		"340"="Cash Concentration"
		"341"="Client Account Services"
		"343"="Corp Non-Int Bearing Curr A/c"
		"344"="Cash Collection Courier"
		"345"="Liquidity Investment Services"
		"346"="Investment Products"
		"347"="TB Call Deposits"
		"348"="Cash Escrow"
		"349"="Other Account Services Product"
		"350"="Clearing-OG FIT Mthend fee"
		"351"="Clearing-OG CT BenDeduct"
		"352"="Clearing-OG CT BenShare"
		"353"="Clearing-OG FIT BenTrade"
		"354"="Clearing-IC CT CreditDeduct"
		"355"="Clearing-Export Bill"
		"356"="Clearing-IC CT Mthend fee"
		"357"="Clearing-IC FIT Mthend fee"
		"358"="Clearing-IC FIT RecTrade"
		"359"="Clearing-Standing Orders"
		"360"="Inward T/Ts - N/Ret"
		"361"="Local Cheque Collections"
		"362"="Inward Local Bank Transfers"
		"363"="RCMS Credit Cards"
		"364"="Cheque Purchased"
		"365"="Direct Debit Collections"
		"366"="Cash Collections"
		"367"="Collection Services (CS)-Other"
		"368"="Retail Lock Box"
		"369"="Wholesale Lock Box"
		"370"="Inward ACH / GIRO"
		"371"="Upcountry Cheque Collection"
		"372"="Local Clrng Chq Purchase"
		"373"="Local Clrng Guarantee Cr"
		"374"="Local Clrng Cleared Funds"
		"375"="Upcountry Cheque Purchase"
		"376"="Upcountry Guarantee Cr"
		"377"="Upcountry Cleared Funds"
		"378"="Upcountry Foreign Ccy"
		"379"="Other Collections"
		"380"="Direct Clrng Chq Purchase"
		"381"="Direct Clrng Guarantee Cr"
		"382"="Direct Clrng Cleared Fund"
		"383"="Incoming Direct Credits"
		"384"="Outward Direct Debit"
		"385"="Virtual Accounts"
		"386"="TB Fixed Deposit"
		"387"="Post-Dated Cheque Discounting"
		"388"="Global Custody"
		"389"="Depository Receipts"
		"390"="Outward T/Ts - N/Ret"
		"391"="Cashier Orders"
		"392"="ACH Payments"
		"393"="RTGS"
		"394"="Book Transfers"
		"395"="Intl. Bank Cheques"
		"396"="Customer Cheques"
		"397"="STS - Other"
		"398"="Electronic Outward T/Ts -N/Ret"
		"399"="Other Outward Payments - N/Ret"
		"400"="Electronic Cashier Orders"
		"401"="Electronic ACH payments"
		"402"="Electronic RTGS"
		"403"="Electronic Book Transfers"
		"404"="Electronic Intl Bank Cheques"
		"405"="Electronic customer cheques"
		"406"="Electronic Payroll payments"
		"407"="Electronic Corporate Cheques"
		"408"="MT101"
		"409"="Account Operator Clearing"
		"410"="Clearing Accounts"
		"411"="Vostro Credit"
		"412"="Swift Payments"
		"415"="3rd Party Clearing"
		"419"="Other Clearing Products"
		"420"="Cross Border IS CHQ"
		"421"="Cross-Border TT"
		"422"="Cross-Border DC"
		"423"="Cross-Border PAY"
		"424"="Cross-Border RTS"
		"425"="Cross-Border BT"
		"426"="Cross-Border CHQ"
		"428"="Islamic - Other Custodial Serv"
		"429"="Islamic - Custodial Payments"
		"430"="Islamic - Other Outward Paymen"
		"431"="Islamic - Cash Concentration"
		"433"="Islamic - Vostro Credit"
		"434"="Islamic - Other Clearing Produ"
		"435"="Islamic FX Options Structured"
		"436"="Islamic - AMS Services"
		"437"="Islamic - Other Collections"
		"438"="Islamic - Outward T/Ts - N/Ret"
		"439"="Islamic - Upcountry Foreign Cc"
		"440"="Loans Against Trust Receipts"
		"441"="Loans Against Import"
		"442"="Import Invoice Financing"
		"443"="Import LC Re-Financing"
		"444"="Intermediary Finance"
		"445"="Input Finance"
		"446"="Disc Prepayment of Own Iss L/C"
		"447"="Refinancing under Reimburse"
		"448"="Trade Advances"
		"449"="Import Loans"
		"450"="Bills Receivable"
		"452"="Islamic Exp invoice Financing"
		"454"="Islamic Export Bills for Colle"
		"455"="Islamic - Receivable Serv with"
		"460"="Preshipment Loans"
		"461"="Pre-Export Finance for FI"
		"462"="Islamic - Import LCs Secured"
		"463"="Islamic - Acceptance Under LCs"
		"464"="Islamic - Import Bills for Col"
		"465"="Islamic - Trade Facility Fees"
		"466"="Islamic - Financial Guarantees"
		"467"="Islamic-Bills Re-Discounted"
		"469"="Islamic - Bonds and Guarantees"
		"470"="CBN - Discrepancy"
		"471"="CBN - W/O Discrepancy"
		"472"="L/C Re-Negotiation"
		"473"="Islamic - Other Drafts Accepte"
		"475"="Islamic-Non Profit bearing C/A"
		"476"="Finance Against Whouse Receipt"
		"477"="Borrowing Base Trade Loan"
		"478"="Vendor Prepay Financing"
		"479"="Islamic-Export Bill Discount"
		"480"="Export Bill Discounting"
		"481"="Export Invoice Financing"
		"482"="OIF - Financing"
		"483"="Bill Dis against Buyer Risk"
		"485"="Other Export Loans"
		"486"="FI Post Ship Exp Fin-LCsandColl"
		"487"="FI Post Ship Exp Fin-Inv Fin"
		"488"="Islamic - Bills Dis against Bu"
		"489"="Islamic - Other Export Finance"
		"490"="Disc of Bank Accp Dft-Local"
		"491"="Disc of Avalised Drafts (FCY)"
		"492"="Dis of Avalised Draf under IBC"
		"493"="Recv'ble on a/c of Grntee/SBLC"
		"494"="Receivable Serv w/o Recourse"
		"495"="Receivable Serv with Recourse"
		"496"="Portfolio RS with Recourse"
		"497"="Portfolio RS without Recourse"
		"498"="Import Factoring"
		"499"="Islamic - Receivable Serv w/o"
		"500"="Transfer LCs Secured"
		"501"="Transfer LCs Unsecured"
		"502"="Back-to-back LCs Secured"
		"503"="Back-to-back LCs Unsecured"
		"504"="Import LCs Secured"
		"507"="Islamic-Back-to-back LCs Secd"
		"509"="Import LCs Unsecured"
		"515"="Confirmed Export LCs"
		"516"="Agrmt to negotiate(SlntLCConf)"
		"520"="Shipping Guarantees"
		"521"="Bonds and Guarantees"
		"522"="Letter of Indemnity"
		"523"="Other Guarantees"
		"525"="Commercial Standby/G'tees"
		"528"="Avalisation Draft under IBC"
		"530"="Bills Re-Discounted"
		"531"="Acceptance Under LCs"
		"533"="Acceptance under Export LCs"
		"535"="Other Drafts Accepted"
		"539"="Islamic - LC Advising"
		"540"="LC Advising"
		"541"="Export LC Transfer"
		"545"="LC Reimbursements"
		"546"="Islamic - LC Reimbursements"
		"550"="Export Bills For Collection"
		"551"="CBC"
		"555"="Import Bills for Collection"
		"560"="Private Label"
		"561"="Silent Payment Gtee - OIF"
		"562"="Doc Prep"
		"563"="Trade Facility Fees"
		"565"="Trade Debt Prov."
		"566"="SilentPaymentGuarantee-NON OIF"
		"569"="Other Trade Products"
		"570"="Reimbursement Undertkgs"
		"580"="Parent Sub Model"
		"581"="Sub Custody"
		"582"="Custodial - Secs Lending"
		"583"="Custodial - Curr and Sav Accs"
		"584"="Custodial - Payments"
		"585"="Accounting Services"
		"586"="Regional Custody"
		"587"="Securities Escrow"
		"589"="Transfer Agency"
		"590"="Investment Trust"
		"591"="Domestic - Custody"
		"592"="Settlement Agent"
		"599"="Other Custodial Services"
		"600"="Structured Trade Finance"
		"602"="Structured Agri-Finance"
		"603"="Derivative Clearing"
		"604"="FXO Structured - Structured"
		"605"="Commercial Real Estate"
		"606"="FXO Structured - TRF"
		"607"="FXO Structured - Other"
		"608"="Equity Linked"
		"609"="GM Other GFX"
		"610"="Portfolio Management"
		"611"="Other Credit Portfolio"
		"612"="GM Other Rates"
		"613"="GM Other Credit"
		"614"="Syndications"
		"615"="FX Spot"
		"617"="Trade Bills"
		"618"="Bonds Fund"
		"619"="Corp Convertible Bonds-Listed"
		"620"="Call Deposits (On demand)"
		"621"="Call Loan"
		"622"="Certificates of Depo-Unlisted"
		"623"="Certificates of Deposit-Listed"
		"624"="Government Bonds"
		"625"="FX Forward"
		"629"="Islamic - Other Global Deriv"
		"631"="FX switch"
		"632"="Structured SandA"
		"633"="Rates-Structured"
		"634"="Rates-Swaps G10"
		"635"="Non-Deliverable Forwards"
		"636"="Covered Bonds"
		"639"="Call Deposits (Not on demand)"
		"640"="FX Margin Trading"
		"641"="FX Trading Proprietary"
		"649"="FX Others"
		"650"="FX-Train"
		"651"="FRN (Floating) - Unlisted"
		"653"="FRN (Floating) - Issued"
		"655"="Interest Rate Options"
		"656"="Cross-Currency Swaps"
		"658"="Interest Rate Swaps"
		"659"="IR Others"
		"660"="Fin Futures/Ccy Futures"
		"661"="Forward Rate Agreements"
		"662"="Equity Derivatives"
		"663"="Equity Options - ED"
		"664"="Equities"
		"665"="Equity Futures"
		"666"="Equity Swaps - ED"
		"667"="Equity Warrants"
		"669"="Other Global Derivatives"
		"673"="Equitiy Investment - Unlisted"
		"674"="Equitiy Investment - Listed"
		"675"="Global FX Options"
		"676"="Structured FXO"
		"678"="Cash Equities"
		"679"="GM Other Fixed Income"
		"680"="Debt Securities Govt."
		"685"="Debt Securities Corp."
		"686"="Corp Bonds Unlisted"
		"688"="Primary - Fees - Lcy"
		"690"="Fixed Income Others"
		"691"="FRN - Government"
		"692"="FRN (Floating) - Listed"
		"693"="FRN (Fixed) - Unlisted"
		"696"="FRN (Fixed) - Issued"
		"698"="FRN (Fixed)- Listed"
		"701"="Credit Linked Deposit"
		"702"="Credit Linked Notes"
		"703"="Credit Default Swaps"
		"704"="Asset Back Sec-Prim-Fees - Lcy"
		"705"="Asst Backed Sec-Sls and Trdg"
		"706"="Cash Coll Debt Oblig-Prim-Fees"
		"710"="Primary Arrangement Fees - Lcy"
		"712"="Govt Bonds - Listed"
		"714"="State Govt Bonds - Unlisted"
		"717"="Derivative Defaults"
		"718"="Rates Primary-Syn-Orig - G3"
		"719"="Rates Prim-Syndica-Distrib-G3"
		"721"="Bank Bonds - Listed"
		"722"="ABS PM - Impairment"
		"723"="SCB Bonds - Unlisted"
		"725"="Other Treasury Products"
		"726"="Mortgage Backed Securities-GM"
		"727"="MM Deposit"
		"728"="Money Market Loans"
		"729"="Medium Term Notes"
		"731"="Bank/Corp Bonds - Unlisted"
		"732"="Bank/Corp Bonds - Listed"
		"733"="Bank Bonds - Issued"
		"734"="Repo"
		"735"="Agency Fees - Lcy"
		"736"="Asian Currency Bond"
		"737"="Bond Others"
		"738"="Treasury Bill"
		"740"="GM Other Capital Mkts"
		"741"="Treasury Notes"
		"745"="Structured Finance"
		"748"="Corp Bills - UnListed"
		"749"="Corp Bills - Listed"
		"750"="Fund Mgt. Revenue"
		"752"="Capital Notes"
		"753"="GM Other Reg Mkts/ALM"
		"754"="ABS PM - Hedges"
		"755"="Time Deposits - N/Ret"
		"756"="Sub-W/sale Rate Deposits"
		"757"="Placements - Int/Bk"
		"758"="Borrowings - Int/Bk"
		"759"="Placements - Int/Grp"
		"760"="Borrowings - Int/Grp"
		"761"="Nostro Accounts"
		"762"="Certificates of Deposit Issued"
		"763"="Premium Currency Deposits"
		"764"="Other Leverage Trading Pdts"
		"765"="Net FTP Charge / Credit"
		"766"="Investment Portfolio"
		"771"="Bank Bonds - Unlisted"
		"774"="Zero Coupon Bonds"
		"775"="Other ALM Products"
		"777"="India Midcap"
		"778"="GM Other ABS and Deriv Def"
		"779"="FM Loans"
		"780"="Corporate Advisory Fee"
		"781"="Acquisition Finance"
		"784"="Repos and Collateral"
		"785"="ECA Finance"
		"786"="CM Syn - Cr Deriv - G3"
		"787"="CM Syn Others - G3"
		"788"="Statutory Reserves HO"
		"792"="Structured Hybrid Prod"
		"793"="Convertible Bonds-Prim-Dist-G3"
		"795"="Private Equity"
		"796"="GM Other CorpFin"
		"797"="GM Other PF"
		"798"="GM Other Comm Deriv"
		"799"="GM Other Equities"
		"800"="Corporate Treasury"
		"801"="Cash Collateral"
		"802"="Inflation Linked Bonds"
		"805"="Principal Finance"
		"807"="Asset Back Sec-Prim-Distrib-G3"
		"808"="CM ABS - Cr Derivatives - G3"
		"810"="CDS Swaption Instrument"
		"811"="CDS Swaption Notes"
		"812"="CMT Instrument"
		"813"="CMT Notes"
		"814"="Bond Linked Instrument"
		"815"="Bond Lindked Notes"
		"816"="Secondary Loan Trading"
		"817"="Convertible Bonds"
		"818"="Equity Swaps"
		"819"="Equity Options"
		"820"="Equity"
		"821"="Coll Debt Obligat-Structuring"
		"822"="Coll Debt Obligations S and T"
		"824"="Primary - Credit Deriv - G3"
		"825"="Convertible Bond-Prim-Fees-Lcy"
		"826"="Infrastructure"
		"829"="Delta 1"
		"833"="Equity Capital Markets"
		"835"="Investors Product"
		"837"="ALM Sales - Commercial Paper"
		"838"="ALM Sales - Certificate Depo"
		"839"="ALM Sales - Bonds"
		"841"="Convertible Bonds-ED"
		"842"="Reverse Repos"
		"843"="SBL"
		"844"="Structured Equity Derivatives"
		"845"="Equity Derivatives Others"
		"847"="ALM Sales - MM Loans"
		"848"="ABS PM"
		"849"="Non Performing Loan"
		"850"="Alternative Investments"
		"851"="Bond Options"
		"852"="IR Structured Notes"
		"853"="Total Return Swap"
		"854"="Caps/Floors"
		"855"="Futures Options"
		"856"="Commodities Futures Options"
		"857"="Commodity Asian"
		"858"="Commodity Forward"
		"859"="Commodity Future"
		"860"="Commodity Swap"
		"861"="Commodity Swaptions"
		"862"="Nds"
		"870"="Primary - Distribution - Lcy"
		"872"="Rates Prim-Fxd Inc-Orig - Lcy"
		"874"="Rates Primary -ABS -Orig - Lcy"
		"876"="Rates Primary-FI-Distrib - Lcy"
		"878"="Rates Prim -ABS - Distr - Lcy"
		"881"="Cash Coll Debt Oblig-Distr"
		"883"="Commodity  Derivatives"
		"894"="Rates JV Credit"
		"899"="ALM Sales - MTN"
		"900"="Insurance Services"
		"901"="Primary - Fees - G3"
		"910"="Other Defined Products"
		"915"="I-Credit Card-Issuing"
		"916"="I-Credit Card-Acquiring"
		"917"="Islamic - Instalment Finance"
		"918"="Islamic - Auto Finance"
		"919"="Islamic - Mortgage Finance"
		"920"="Islamic - Secured Fin - Oth"
		"921"="Islamic - Profit bearing C/A"
		"922"="I-Savings Account"
		"923"="I-Term Deposits"
		"924"="I-Unit Trust"
		"925"="I-FX"
		"926"="Islamic - BEF"
		"927"="Islamic CandI Short Term Finance"
		"928"="Islamic CandI Revolving Term Fin"
		"929"="Islamic CandI Financial Lease"
		"930"="Islamic Lendg ConUnFunded Ri P"
		"931"="Islamic Operating Leases"
		"932"="Islamic Non Performing Finance"
		"933"="Islamic Alternative Investment"
		"934"="Islamic ABF Financial Lease"
		"935"="Islamic Gtd Installment Fin"
		"936"="Islamic CandI Term Finance"
		"937"="Islamic - Bancassurance"
		"938"="Islamic FM Finance"
		"939"="Islamic - Unsecured Overdrafts"
		"940"="Islamic - Revolving Credit"
		"941"="Islamic - Mortgage Finance (Co"
		"942"="Islamic - Term Finance-N/Trd-P"
		"943"="Islamic - SME Finance Against"
		"944"="Islamic - Profit Rate Swaps"
		"945"="Islamic - Cap/Floors"
		"946"="Islamic - Profit Rate Options"
		"947"="Islamic FX Forward"
		"948"="Islamic - FX Others"
		"949"="Islamic - Forward Rate Agreeme"
		"950"="Islamic Import Finance"
		"952"="SplyChain-Dom/X Border SuprFin"
		"953"="Islamic Shipping Guarantee"
		"954"="Islamic Bill Discounting"
		"955"="Islamic Letter of Credit"
		"956"="Islamic - Credit Derivatives"
		"957"="Islamic Finance Against TR"
		"958"="Islamic Imp Invoice Financing"
		"959"="Islamic Term / Fixed Fin"
		"960"="Islamic Savings Account"
		"961"="Islamic Corp Fxd Dep/Term A/c"
		"962"="I Corp Non profit bearing C/A"
		"966"="Islamic Fixed Income"
		"967"="Islamic Syndications - Lcy"
		"968"="Islamic FX Spot"
		"969"="IslamicInterbk B'wing/Loan-CMP"
		"970"="Islamic Global Deriv Ccy-Swaps"
		"971"="Islamic Asset Backed Sec"
		"972"="Islamic - Conf Export LCs"
		"973"="Islamic CBN"
		"974"="Islamic Pre-shipment Finance"
		"975"="Islamic Commercial SBLC"
		"976"="Islamic Escrow"
		"977"="Islamic Overdrafts"
		"978"="Islamic Installment Finance"
		"979"="Islamic LC Issuance"
		"980"="Islamic Corp Bonds"
		"981"="Islamic CoMoney Market Paper"
		"982"="Islamic Govt Bonds"
		"983"="Islamic - Commodity Derivative"
		"984"="Islamic - ABS PM"
		"985"="Islamic - Investment Portfolio"
		"986"="Islamic Interbk Placement"
		"987"="Islamic - Other ALM Products"
		"988"="Islamic - Nostro Accounts"
		"989"="Islamic - Cert of Deposit Issu"
		"990"="Islamic Corpr Profit Bearing C"
		"991"="Islamic - Inward T/Ts - N/Ret"
		"993"="Islamic - Ass Backed Financing"
		"994"="Islamic CRE Term Finance"
		"995"="Islamic CRE Revolving Term Fin"
		"996"="Islamic - ABF Term Finance"
		"997"="Islamic ABF Revolving Term Fin"
		"998"="Islamic - CIM Term Finance"
		"999"="Islamic CIM Revolving Term Fin"
	;
%mend cdwfmt_PSGL_PDT_Type;