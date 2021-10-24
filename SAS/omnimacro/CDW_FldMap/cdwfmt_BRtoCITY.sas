%macro cdwfmt_BRtoCITY;
value $cdwfmt_BRtoCITY
	'10'='SHA'
	'12'='NJG'
	'13'='SHZ'
	'15'='XMN'
	'16'='ZHA'
	'17'='TJN'
	'18'='BJG'
	'20'='GZU'
	'21'='CDU'
	'22'='SUZ'
	'26'='QGD'
	'28'='CHQ'
	'29'='HGZ'
	'30'='DLN'
	'31'='NCH'
	'32'='NGB'
	'33'='HHT'
	'34'='WHN'
	'35'='FSN'
	'36'='XAN'
	'37'='JNN'
	'80'='N/A'
	other=' '
;


value $cdwfmt_BRtoCITY_s

		"10" = "SH" 
		"12" = "NJ" 
		"13" = "SZ" 
		"15" = "XM" 
		"16" = "ZH" 
		"17" = "TJ" 
		"18" = "BJ" 
		"20" = "GZ" 
		"21" = "CD" 
		"22" = "SuZ"
		"26" = "QD" 
		"28" = "CQ" 
		"29" = "HZ" 
		"30" = "DL" 
		"31" = "NC" 
		"32" = "NB" 
		"33" = "HHT"
		"34" = "WH" 
		"35" = "FS" 
		"36" = "XA" 
		"37" = "JN" 
		"38" = "CS" 
			other=' '
		;
%mend cdwfmt_BRtoCITY;

/*
This macro is to map the City short name by the first two figures of the Branch Code.
*/