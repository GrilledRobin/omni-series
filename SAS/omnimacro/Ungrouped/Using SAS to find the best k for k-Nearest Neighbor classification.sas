/*******************READ ME*********************************************
* - USING SAS TO FIND THE BEST K FOR K-NEAREST NEIGHBOR CLASSIFICATION -
*
* VERSION:     SAS 9.2(ts2m0), windows 64bit
* DATE:        07apr2011
* AUTHOR:      hchao8@gmail.com
*
****************END OF READ ME*****************************************/

****************(1) MODULE-BUILDING STEP******************;
******(1.1) CREATE A SAMPLING MACRO*************;
%macro partbyprop(dsin = , targetv = , samprate = , seed = );
   /**************************************************************
   *  MACRO:      partbyprop()
   *  OBJECTIVE:  partition dataset by target variable's proportion
   *  PARAMETERS: dsin     = input dataset
   *              targetv  = target variable
   *              samprate = ratio of train v.s. score datasets
   *              seed     = random seed for sampling
   **************************************************************/
   title "Test on SAS dataset: &dsin";
   proc sort data = &dsin out = _tmp1;
      by &targetv;
   run;

   proc surveyselect data = _tmp1 samprate = &samprate  
      out = _tmp2 seed = &seed outall noprint;
      strata &targetv / alloc = prop;
   run;

   data train score;   
      set _tmp2;
      if selected = 0 then output train;
      else output score;
   run;

   proc datasets nolist;
      delete _:;
   quit;
%mend;

******(1.2) CREATE A MACRO FOR KNN CLASSIFICATION*************;
option mstored sasmstore = sasuser;
%macro knn_macro / store source;
   /***********************************************************
   *  MACRO:      knn_macro()
   *  OBJECTIVE:  a knn classification macro by proc discrim
   *              which also calculates misclassification rate   
   *  PARAMETERS: k = number of nearest neighbours
   *              targetv = target variable
   ***********************************************************/
   %let k = %sysfunc(dequote(&k));
   %let targetv = %sysfunc(dequote(&targetv));
   %let input = %sysfunc(dequote(&input));

   %let error = 0; 
      %if %length(&k) = 0 %then %do; 
         %put ERROR: Value for K is missing ; 
         %let error = 1; 
      %end; 
      %if %length(&targetv) = 0 %then %do; 
         %put ERROR: Value for TARGETV is missing ; 
         %let error = 1; 
      %end; 
      %if %length(&input) = 0 %then %do; 
         %put ERROR: Value for INPUT is missing ; 
         %let error = 1; 
      %end; 
      %if %sysfunc(exist(train)) = 0 %then %do; 
         %put ERROR: Dataset TRAIN does not exist ; 
         %let error = 1; 
      %end; 
      %if %sysfunc(exist(score)) = 0 %then %do; 
         %put ERROR: Dataset SCORE does not exist ; 
         %let error = 1; 
      %end; 
   %if &error = 1 %then %goto finish; 

   proc discrim data = train test = score testout = _scored
         method = npar k = &k noprint; 
         class &targetv; 
         var &input; 
   run; 

   data _null_;
      set _scored nobs = nobs end = eof;
      retain count; 
      if &targetv ne _into_ then count + 1;
      if eof then do;
         misc = count / nobs;
         call symput('misc', misc);
      end;
   run;

   %finish: ; 
%mend;

******(1.3) COMPILE FUNCTION TO EMBED THE MACRO ABOVE*********;
proc fcmp outlib = sasuser.knn.funcs;
   function knn(k, targetv $, input $);
   /***********************************************************
   *   FUNCTION:    misc = knn(k, targetv, input)
   *   OBJECTIVE:   pass values to macro and get return
   *      INPUT:    k = number of nearest neighbours 
   *                targetv = target variable
   *                input = input variable   
   *     OUTPUT:    misc = misclassification rate 
   ***********************************************************/
      rc = run_macro('knn_macro', k, targetv, input, misc);
      if rc eq 0 then return(misc);
      else return(.);
   endsub;
run;

******(1.4) CREATE A TESTING MACRO*************;
%macro findk(targetv = , input = , maxiter = , plotpath = );
   /***********************************************************
   *  MACRO:      findk()
   *  OBJECTIVE:  iterate and plot 
   *  PARAMETERS: targetv = target variable
   *              input = input variable
   *              maxiter = maximum number of k value
   *              plotpath = output path for ods images
   ***********************************************************/
   option cmplib = (sasuser.knn) mstored sasmstore = sasuser;
   data _test;
      targetv = "&targetv";
      input = "&input";
      do k = 1 to &maxiter;
         misc_rate = knn(k, targetv, input);
         output;
      end;
   run;
   
   proc sql noprint;
      select min(misc_rate) into: min_misc
      from _test;
      select k into: bestk separated by ', '
      from _test
      having misc_rate = min(misc_rate);
   ;quit;
 
   ods html style = harvest gpath = "&plotpath";
   proc sgplot data = _test;
      series x = k y = misc_rate;
      xaxis grid values = ( 1 to &maxiter by 2) 
            label = 'kth neareast neighbours';
      yaxis grid values = ( 0 to 0.5 by 0.1)  
            label = 'Misclassification rate';
      refline &min_misc / transparency = 0.3
            label = "k = &bestk";
   run;
   ods html close;
%mend;

****************END OF STEP (1)******************;

****************(2) TESTING STEP******************;
******(1.1) TEST THE DIFFICULT DATASET*************;
%partbyprop(dsin = sashelp.cars, targetv = origin, samprate = 0.5, seed = 20110406);
%findk(targetv = origin, input = invoice wheelbase length , maxiter = 40,
       plotpath = h:\);

******(1.2) TEST THE EASY DATASET*************;
%partbyprop(dsin = sashelp.iris, targetv = species, samprate = 0.5, seed = 20110406);
%findk(targetv = species, input = petallength petalwidth sepallength sepalwidth , 
       maxiter = 40, plotpath = h:\);

****************END OF STEP (2)******************;

****************(3) VALIDATION STEP******************;
proc modeclus data = sashelp.iris m = 1 k = 13 out = _test1 neighbor;
    var petallength petalwidth sepallength sepalwidth;
run;

ods html style = navy gpath = 'h:\';
proc sgplot data = _test1;
    scatter y = petallength  x = petalwidth 
            / group = species markerchar = cluster;
run;
ods html close;

****************END OF STEP (3)******************;
****************END OF ALL CODING***************************************;