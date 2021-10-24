%macro cdwmap_channel(
	armbrnch=
	,armcode=
	,fixarmbrnch=
	,Chl=
	,f_reallocate=
	
	);
	
	 format &fixarmbrnch. $5. &Chl.  $10. &f_reallocate best12.;
		  &fixarmbrnch.=&armbrnch.;
          &Chl. = 'CE-BRANCH';
          &f_reallocate=0;
          
          if substr(&armcode., 1, 1) 	in ('U') then &Chl. = 'CE-RBM';
          if substr(&armbrnch., 3, 3) in ('999') and &armbrnch.^="99999" then  &Chl. = 'CE-DS';
          if substr(&armbrnch., 1, 3) in ('VDS') 
          OR substr(&armcode., 1, 2) in ( "ZB" "ZC" "ZM" "ZJ" "ZN" "ZP" "ZQ" "ZR" "ZS" "ZT" "ZO" "ZL" )
          then  &Chl. = 'PRB-HUB';   
          if substr(&armbrnch., 5, 1) in ('H') then  &Chl. = 'PRB-HUB';    
          if substr(&armbrnch., 5, 1) in ('R') then  &Chl. = 'CE-RBM';  
          
					if &armbrnch.='10999' then &fixarmbrnch.= '10000'  ; 
					if &armbrnch.='18999' then &fixarmbrnch.= '18010'  ; 
          if &armbrnch. in ('88888') then &Chl. = 'PVB';
          if &armbrnch. in ('77777') then &Chl. = 'MD';
          if &armbrnch. in ('77777') and substr(&armcode.,1,2) in ("ZE" "ZD") then  &Chl. = 'MD-CASA';     
          if &armbrnch. in ('77777') and substr(&armcode.,1,2) in ("N9" ) then  &Chl. = 'NB-Lend';  
          if &armbrnch. in ('55555') then &Chl. = 'CallCentre';
          if &armbrnch. in ('44444') then &Chl. = 'INBOUND';
          if &armbrnch. in ('33333') then &Chl. = 'CE-BRANCH';
          if &armbrnch. in ('66666') then &Chl. = 'TeleSales'; 
          if &armbrnch. in ('65555') then &Chl. = 'VRM'; 
          if &armbrnch. in ('75555') then  &Chl. = 'BCOT Lend';   
          if &armbrnch. in ('95555') then  &Chl. = 'Employee';  
          if &armbrnch. in ('99999') then  &Chl. = 'SYSTEM';   
	  			if &armbrnch. in ('DUMMY') then &Chl.  ='CE-BRANCH';
	  			if &armcode. in ('ZZZ')		 then &Chl.  ='SYSTEM';
	  			
		  		if substr(&armcode.,1,2)='ZH' then  &Chl.=  'BCOT Lend';
   		  	if substr(&armcode.,1,2) in ('ZJ')   then &Chl. = 'IRM-TW'; 
          if &armcode. in ('999' 'BSH' 'SC1' 'SC2' 'SC3' 'SSC')   then &Chl. = 'SYSTEM'; 
          
          if &armbrnch. ='VDS10' then &fixarmbrnch.='10000';
          if &armbrnch. ='VDS30' then &fixarmbrnch.='10070';  
          if substr(&armbrnch., 5, 1) in ('H') and &Chl. in ("PRB-HUB") then &fixarmbrnch.=tranwrd(&armbrnch.,"H","0");
          if substr(&armbrnch., 5, 1) in ('R') and &Chl. in ("CE-RBM") then &fixarmbrnch.=tranwrd(&armbrnch.,"R","0");

          if &Chl. in ( "PVB" "MD" "MD-CASA" 'NB-Lend' "CallCentre" "INBOUND" "TeleSales" "VRM" "Employee" "BCOT Lend" "SYSTEM" ) then &f_reallocate=1;
                                                                                                                 
%mend;
          
        

