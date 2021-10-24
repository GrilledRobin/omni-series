/* Coefficient of determination (R-square) and partial R-square for generalized linear 
   models 

   Zhang, D., (2016), "A coefficient of determination for generalized linear models," The American Statistician, tentatively accepted.

*/

%macro RsquareV(version, data=_LAST_, response=, trials=, dist=, freq=,
                pfull=, nparmfull=, psub=, nparmsub=1, k=, twpower=);

%let time = %sysfunc(datetime());
%let _version=1.0;
%if &version ne %then %put &sysmacroname macro Version &_version;

%if &data=_last_ %then %let data=&syslast;
%let _opts = %sysfunc(getoption(notes)) 
            _last_=%sysfunc(getoption(_last_));
%if &version ne debug %then %str(options nonotes;);

/* Check for newer version */
 %if %sysevalf(&sysver >= 8.2) %then %do;
  %let _notfound=0;
  filename _ver url 'http://ftp.sas.com/techsup/download/stat/versions.dat' termstr=crlf;
  data _null_;
    infile _ver end=_eof;
    input name:$15. ver;
    if upcase(name)="&sysmacroname" then do;
       call symput("_newver",ver); stop;
    end;
    if _eof then call symput("_notfound",1);
    run;
  %if &syserr ne 0 or &_notfound=1 %then
    %put &sysmacroname: Unable to check for newer version;
  %else %if %sysevalf(&_newver > &_version) %then %do;
    %put &sysmacroname: A newer version of the &sysmacroname macro is available.;
    %put %str(         ) You can get the newer version at this location:;
    %put %str(         ) http://support.sas.com/;
  %end;
 %end;

/* -------------- Check inputs --------------- */
/* DATA= must be specified and data set must exist */
%if &data= or %sysfunc(exist(&data)) ne 1 %then %do;
  %put ERROR: DATA= data set not specified or not found.;
  %goto exit;
%end;
/* Check required and optional variables exist */
%let status=ok;
%let dsid=%sysfunc(open(&data));
%if &dsid %then %do;

  /* REQUIRED VARIABLES */
  %if %quote(&response)= %then %do;
    %put ERROR: The RESPONSE= option is required.;
    %let status=input_err;
  %end;
  %else %if %sysfunc(varnum(&dsid,%upcase(&response)))=0 %then %do;
    %put ERROR: RESPONSE= variable &response not found.;
    %let status=input_err;
  %end;
  %if %quote(&pfull)= %then %do;
    %put ERROR: The PFULL= option is required.;
    %let status=input_err;
  %end;
  %else %if %sysfunc(varnum(&dsid,%upcase(&pfull)))=0 %then %do;
    %put ERROR: PFULL= variable &pfull not found.;
    %let status=input_err;
  %end;
  %if %quote(&psub)= %then %do;
    %put ERROR: The PSUB= option is required.;
    %let status=input_err;
  %end;
  %else %if %sysfunc(varnum(&dsid,%upcase(&psub)))=0 %then %do;
    %put ERROR: PSUB= variable &psub not found.;
    %let status=input_err;
  %end;

  /* OPTIONAL VARIABLES */
  %if &trials ne %then %do;
  %if %sysfunc(varnum(&dsid,%upcase(&trials)))=0 %then %do;
    %put ERROR: TRIALS= variable &trials not found.;
    %let status=input_err;
  %end; %end;
  %if &freq ne %then %do;
  %if %sysfunc(varnum(&dsid,%upcase(&freq)))=0 %then %do;
    %put ERROR: FREQ= variable &freq not found.;
    %let status=input_err;
  %end; %end;
  
  %let rc=%sysfunc(close(&dsid));
  %if &status=input_err %then %goto exit;
%end;
%else %do;
  %put ERROR: Could not open DATA= data set.;
  %goto exit;
%end;
/* DIST= is required. check for valid value */
%if %quote(&dist)= %then %do;
  %put ERROR: DIST= is required.;
  %goto exit;
%end;
%if %length(&dist)<2 %then %let dist=BAD;
%let d=%substr(%upcase(&dist),1,2);
%if %quote(&d) ne PO and %quote(&d) ne BI and %quote(&d) ne %quote(NO) and 
    %quote(&d) ne GA and %quote(&d) ne %quote(NE) and %quote(&d) ne %quote(NB) and %quote(&d) ne %quote(GE) and %quote(&d) ne IG and %quote(&d) ne %quote(IN) and %quote(&d) ne %quote(TW) %then %do;
  %put ERROR: DIST= must be one of: POISSON, BINOMIAL, NORMAL, GAMMA, NEGBIN, GEOMETRIC, IGAUSS, or TWEEDIE.;
  %goto exit;
%end;
/* Verify NPARMFULL= is a positive integer */
%if %sysevalf(&nparmfull ne) %then 
  %if %sysevalf(&nparmfull<=0) %then %do;
    %put ERROR: The NPARMFULL= value must be an integer value greater than zero.;
    %goto exit;
  %end;
/* Verify NPARMSUB= is a positive integer */
%if %sysevalf(&nparmsub ne) %then 
  %if %sysevalf(&nparmsub<=0) %then %do;
    %put ERROR: The NPARMSUB= value must be an integer value greater than zero.;
    %goto exit;
  %end;
/* Verify K= is specified for negbin and is positive */
%if (%quote(&d)=%quote(NE) or %quote(&d)=%quote(NB)) and %sysevalf(&k= or &k<=0) %then %do;
    %put ERROR: With DIST=NEGBIN, K= is required and must be greater than zero.;
    %goto exit;
%end;
/* Verify TWPOWER= is specified for Tweedie and is valid */
%if %quote(&d)=%quote(TW) and %sysevalf(not(&twpower=0 or &twpower=1 or 
    (&twpower>=1.1 and &twpower<=3))) %then %do;
    %put ERROR: With DIST=TWEEDIE, TWPOWER= is required and must be 0, 1 or between 1.1 and 3.;
    %goto exit;
%end;

/* --------------- Variance Function Coefficients ---------------- */
%let v5=0; %let v4=0; %let v3=0; %let v2=0; %let v1=0;
%if       %quote(&d)=%quote(PO) %then %let v1=1; 
%else %if %quote(&d)=%quote(BI) %then %do; 
  %let v2=-1; %let v1=1; 
%end;
%else %if %quote(&d)=%quote(GA) %then %let v2=1;
%else %if %quote(&d)=%quote(NE) or %quote(&d)=%quote(NB) %then %do; 
  %let v2=&k; %let v1=1; 
%end;
%else %if %quote(&d)=%quote(GE) %then %do; 
  %let v2=1; %let v1=1; 
%end;
%else %if %quote(&d)=%quote(IG) or %quote(&d)=%quote(IN) %then %do; 
  %let v3=1; %let v1=1; 
%end;
%else %if %quote(&d)=%quote(TW) %then %let v4=&twpower;

/* ----------------- Prepare data ----------------- */
data _dv; 
 set &data;
 keep &response &pfull &psub _freq;
 %if %quote(&d)=%quote(BI) and &trials ne %then %do;
  %if &freq= %then %let freq=1;
  do _level="event   ","nonevent"; 
    if _level="event   " then do; _freq=&freq*&response; _numevents=&response; &response=1; end;
    if _level="nonevent" then do; _freq=&freq*(&trials-&response); &response=0; end;
 %end;
 %else %do; 
  %if &freq= %then %str(_freq=1;); 
  %else %str(_freq=&freq;);
 %end;
 %if %quote(&d)=%quote(GA) or %quote(&d)=%quote(IG) or %quote(&d)=%quote(IN) %then %do;
  if &response=0 then delete;
 %end;
 %if &trials ne %then %do; 
   output; &response=_numevents; end;   
 %end;
 %else output;;
 run;
 
/* ------------------ Compute R_v**2 ------------------- */
/* -------------------- Use SAS/IML -------------------- */
%if %sysprod(iml)=1 %then %do;
proc iml;
  start fun(t);
   v = sqrt(1 + (&v4*t**(&v4-1) + 3*&v3*t**2 + 2*&v2*t + &v1)**2);
   return(v);
  finish;
use _dv where(&response ^= .);
read all var {&response &pfull &psub} into x;
read all var {_freq} into f;
close _dv;
dv=J(nrow(x),2,.);
do i=1 to nrow(x);
 lims=x[i,{1 2}];
 call quad(varlenyx, "fun", lims);
 dv[i,1]=varlenyx**2;
 lims=x[i,{1 3}];
 call quad(varleny1, "fun", lims);
 dv[i,2]=varleny1**2;
 if varlenyx=. | varleny1=. then do;
  dv[i,1]=.; dv[i,2]=.;
 end;
end;
dv=dv#f;
sumdv=dv[+,];
n=f[+,];
r2v=1-sumdv[1,1]/sumdv[1,2];
%if &version=debug %then print sumdv n r2v;;
%if %sysevalf(&nparmfull ne) %then %do;
 r2v_adj=1-(sumdv[1,1]/(n-&nparmfull))/(sumdv[1,2]/(n-&nparmsub));;
 rsq=j(1,2,.);
 rsq[1,1]=r2v; rsq[1,2]=r2v_adj;
 create 
   %if &version ne debug %then _rsq; %else _rsqiml;
 from rsq[colname={"Rsquare_v" "Rsquare_v_adj"}];
 append from rsq;
%end;
%else %do;
 rsq=r2v;
 create 
   %if &version ne debug %then _rsq; %else _rsqiml;
 from rsq[colname="Rsquare_v"];
 append from rsq;
%end;
quit;
%end;

/* ------------------- Use Base SAS -------------------- */
%if %sysprod(iml) ne 1 or &version=debug %then %do;
%if &v3 ne 0 or &v4 ne 0 %then %do;
  %put ERROR: The Tweedie and Inverse Gaussian distributions require SAS/IML.;
  %goto exit;
%end; 
data _dv; 
 set _dv;
 _v1=&v1; _v2=&v2;
 if _v2 ne 0 then do;
  _dervx=2*_v2*&pfull+_v1;
  _dervy=2*_v2*&response+_v1;
  _derv1=2*_v2*&psub+_v1;
  _srtx=sqrt(1+_dervx**2);
  _srty=sqrt(1+_dervy**2);
  _srt1=sqrt(1+_derv1**2);
  _dvymux=(log((_dervx+_srtx)/(_dervy+_srty))+_dervx*_srtx-_dervy*_srty)**2/(16*_v2**2);
  _dvymu1=(log((_derv1+_srt1)/(_dervy+_srty))+_derv1*_srt1-_dervy*_srty)**2/(16*_v2**2);
 end;
 else do;
  _dvymux=(1+_v1**2)*(&pfull-&response)**2;
  _dvymu1=(1+_v1**2)*(&psub-&response)**2;
 end;
 run;
proc summary data=_dv;
 freq _freq;
 var _dvymux _dvymu1;
 output out=_dvsums sum=sumdvymux sumdvymu1 n=nx ny;
 run;
data %if &version ne debug %then _rsq; %else _rsqbase;;
 set _dvsums;
 drop _:;
 v1=&v1; v2=&v2; v3=&v3;
 n=min(nx,ny);
 Rsquare_v = 1-sumdvymux/sumdvymu1;
 %if %sysevalf(&nparmfull ne) %then %do;
  nparmfull=&nparmfull; nparmsub=&nparmsub;
  Rsquare_v_adj = 1-(sumdvymux/(n-&nparmfull))/(sumdvymu1/(n-&nparmsub));
  label Rsquare_v_adj = "Penalized/Rsquare_v";
 %end;
 %if &version ne debug %then keep r2:;;
 run;
%end;

/* ----------------- Print R-square --------------- */
ods escapechar='^';
%let pen=;
%if %sysevalf(&nparmfull ne) %then 
  %let pen=%quote(and Penalized R^{sub v}^{super 2});
title "R^{sub v}^{super 2} &pen";
%if &version ne debug %then %do;
  proc print data=_rsq noobs label split='/';
   %if %sysevalf(&nparmfull ne) %then
     label Rsquare_v_adj = "Penalized/Rsquare_v";;
   run;
%end; %else %do;
  proc print data=_rsqiml noobs label split='/';
   %if %sysevalf(&nparmfull ne) %then
     label Rsquare_v_adj = "Penalized/Rsquare_v";;
   title2 "IML";
   run;
  proc print data=_rsqbase noobs label split='/';
   %if %sysevalf(&nparmfull ne) %then
     label Rsquare_v_adj = "Penalized/Rsquare_v";;
   title2 "Base";
   run;
%end;
title;
 
%exit:
 options &_opts;
 %let time = %sysfunc(round(%sysevalf(%sysfunc(datetime()) - &time), 0.01));
 %put NOTE: The &sysmacroname macro used &time seconds.;
%mend;

