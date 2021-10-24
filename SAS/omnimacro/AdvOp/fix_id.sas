*computer the last digit of id;
%macro fixid;
   %do i=1 %to 17;
       in&i.=substr(var1, &i., 1)*w&i.;
   %end;
%mend;

%macro fix_id(var_id);
    array wt{*} w1-w17 (7,9,10,5,8,4,2,1,6,3,7,9,10,5,8,4,2);
    array atch{*} ot1-ot11 (1,0,10,9,8,7,6,5,4,3,2);
    length dix $2.;
    length dix2 $2.;

    if verify(substr(&var_id,1,15),'1','2','3','4','5','6','7','8','9','0')=0
       and
       verify(substr(&var_id,1,16),'1','2','3','4','5','6','7','8','9','0')^=0
    then var1 = substr(&var_id, 1, 6)||'19'||substr(&var_id, 7, 9); 
    
    if verify(substr(&var_id,1,16),'1','2','3','4','5','6','7','8','9','0','x','X')=0
       and
       verify(substr(&var_id,1,17),'1','2','3','4','5','6','7','8','9','0','x','X')^=0
    then do;
       var1 = substr(&var_id, 1, 6)||'19'||substr(&var_id, 7, 10);   
       &var_id = var1;
    end;   
       
    if verify(substr(var1,1,17),'1','2','3','4','5','6','7','8','9','0')=0
       and
       verify(substr(var1,1,18),'1','2','3','4','5','6','7','8','9','0','x','X')^=0
       then do; 
         
         %fixid;
         sm=sum (of in1-in17);         
         y=mod(sm, 11); 
         
         do i=1 to 11; 
             if y=i-1 then dix=atch{i}; 
         end;
         
         dix2=dix;
         if dix='0'  then dix2='0';
         if dix='10' then dix2='X';
         if dix^=''  then &var_id = trim(var1)||compress(dix2);
    end; 
     
    if substr(&var_id, 18, 1) = 'x'  then &var_id = compress(substr(&var_id, 1, 17)||'X');
  
%mend;
