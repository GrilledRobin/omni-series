%macro cdwmap_Armbrnch(
	armbrnch=
	,armcode=
	,fmt=$ce_arm.
	);
	
	 format &armbrnch. $5. ;
	   &armbrnch.=put(upcase(substr(trim(&armcode.),1,2)),&fmt. );
	    if substr(&armcode., 1, 2) in ('N1','N2','N3','N4','N5','N6','N7','N8','N9') or 
         substr(&armcode., 1, 1) in ('R' 'O' 'P')  then &armbrnch. = '77777'; 
     /* if substr(&armcode., 1, 2) in ('UA') then &armbrnch. = '12030';
      if substr(&armcode., 1, 2) in ('UB') then &armbrnch. = '22050';
		  if substr(&armcode., 1, 2) in ('UC') then &armbrnch. = '15050';
      if substr(&armcode., 1, 2) in ('UD') then &armbrnch. = '21030';
		  if substr(&armcode., 1, 2) in ('UE') then &armbrnch. = '28030';
      if substr(&armcode., 1, 2) in ('UF') then &armbrnch. = '10000';
		  if substr(&armcode., 1, 2) in ('UG') then &armbrnch. = '10190';
      if substr(&armcode., 1, 2) in ('UH') then &armbrnch. = '10030';
		  if substr(&armcode., 1, 2) in ('UI') then &armbrnch. = '';
		  if substr(&armcode., 1, 2) in ('UJ') then &armbrnch. = '10030';
		  if substr(&armcode., 1, 2) in ('UK') then &armbrnch. = ''; 
		  
	    if substr(&armcode., 1, 2) in ('ZB') then &armbrnch. = '10000';
      if substr(&armcode., 1, 2) in ('ZC') then &armbrnch. = '10070';
		  if substr(&armcode., 1, 2) in ('ZM') then &armbrnch. = '10000';
      if substr(&armcode., 1, 2) in ('ZJ') then &armbrnch. = '10050';
		  if substr(&armcode., 1, 2) in ('ZN') then &armbrnch. = '10030';
      if substr(&armcode., 1, 2) in ('ZP') then &armbrnch. = '10050';
		  if substr(&armcode., 1, 2) in ('ZQ') then &armbrnch. = '18010';
      if substr(&armcode., 1, 2) in ('ZR') then &armbrnch. = '18090';
		  if substr(&armcode., 1, 2) in ('ZS') then &armbrnch. = '18030';
		  if substr(&armcode., 1, 2) in ('ZT') then &armbrnch. = '13030';
		  if substr(&armcode., 1, 2) in ('ZO') then &armbrnch. = '13110'; 	  
		  if substr(&armcode., 1, 2) in ('ZL') then &armbrnch. = '13110'; 	  */
           
	
%mend;