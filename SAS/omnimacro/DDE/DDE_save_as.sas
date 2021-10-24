/******************************************************************************
** PROGRAM:  MACRO.DDE_SAVE_AS.SAS
**
** DESCRIPTION: SAVES THE CURRENT EXCEL FILE.  IF THE FILE
**              ALREADY EXISTS IT WILL BE OVERWRITTEN.
**
** PARAMETERS: iSAVEAS: THE DESTINATION FILENAME TO SAVE TO.
**             iType  : (OPTIONAL. DEFAULT=BLANK). 
**                      BLANK = XL DEFAULT SAVE TYPE
**                          1 = XLS DOC - OLD SCHOOL! PRE OFFICE 2007?
**                         44 = HTML - PRETTY COOL! CHECK IT OUT... 
**                         51 = XLSX DOC - OFFICE 2007 ONWARDS COMPATIBLE?
**                         57 = PDF
** 
** NOTES:  IF YOU ARE GETTING A DDE ERROR WHEN RUNNING THIS MACRO THEN DOUBLE
**         CHECK YOU HAVE PERMISSIONS TO SAVE WHERE YOU ARE TRYING TO SAVE THE
**         FILE.
** 
*******************************************************************************
** VERSION:
** 1.0 ON: 01APR10 BY: RP
**     CREATED.  
******************************************************************************/

%macro DDE_save_as(iSaveAs=,iType=);
  %local iDocTypeClause;

  %let iDocTypeClause=;
  %if "&iType" ne "" %then %do;
    %let iDocTypeClause=,&iType;
  %end;

  filename cmdexcel dde 'excel|system';
  data _null_;
    file cmdexcel;
    put '[error(false)]';
    put "%str([save.as(%"&iSaveAs%"&iDocTypeClause)])";
    put '[error(true)]';
  run;
  filename cmdexcel clear;

%mend DDE_save_as;
/*%dde_save_as(iSaveAs=d:\rrobxltest, iType=44);*/