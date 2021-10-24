%* For background info, see info.sas, in the macro subdirectory;

%macro exportToXL(
	tmplpath	=
	,tmplname	=
	,deletetmplsheet	= no
	,savepath	= c:\temp
	,savename	= exportToExcel Output
	,wsformat	= none
	,lang		= en
	,exporttmplifempty	= no
	,endclose	= yes
	,varheader	= Gvar
	,rptWSSuffix	=
);
/*
               libin = work,
               dsin = ,
               cell1row = 1,
               cell1col = 1,
               nrows = ,
               ncols = ,
               sumvars = ,
               statvars = ,
               weightvar = ,
               mergeacross = 1,
               mergedown = 1,
               exportheaders = yes,
               exportvarfmts = yes,
*/

	%local libin dsin cell1row cell1col nrows ncols sumvars statvars weightvar mergeacross mergedown exportheaders exportvarfmts sheet;

	/*Previous %setTemplate*/
	%local shxists tshxists nsheets oldshnam;
	%let shxists = 0;
	%let tshxists = 0;
	%let nsheets = 0;
	%let oldshnam = ;
	%local tmplsheet;

	%local misspar missparexptmpl cnotes csource csource2 cmlogic csymbolg cmprint 
		tab ulrowlab ulcollab lrrowlab lrcollab ulrowdat ulcoldat lrrowdat lrcoldat 
		ulrowstat ulcolstat lrrowstat lrcolstat lrecl types vars i colind  closeExcel 
		weightvar crash maxmrow printHeaders macrosheet sasnote saswarning saserror
		c r alignment appactivate appmaximize average border clear columnwidth copy editcolor error 
		false fileclose filter fontproperties formatfont formatnumber formulareplace freezepanes 
		getdocument getworkbook halt max median min new open pastespecial patterns percentile 
		quit rowheight run saveas select selection sendkeys sendkeycmd setname setvalue 
		sheetname sum sumproduct true windowmaximize workbookactivate workbookcopy 
		workbookdelete workbookinsert workbookmove workbookname workbooknext;

	%info;
	%* Gives basic information about how to use EXPORTTOEXCEL.;

	%setVariables;
	%* Initializes many of the local macro variables listed above.;

	%checkParms;
	%* Checks the parameters.;

	%if &misspar %then %goto mquit;

	%openDDE;
	%* Opens Excel and sets up a DDE dialogue with it.;

	%setTemplate;
	%* Sets up the template and gathers information about it.;

	%if &missparexptmpl %then %goto mquit;

	%DumpTTL(
		varhdr=&varheader.
		,vardat=xlvartbl
	);
	%* Pours the data in.;

	%if &misspar %then %goto mquit;

	%*if &wsformat ne none %then %format_&wsformat;
	%* Formats the Excel spreadsheet if formatting is desired.;

	%mquit:

	%closeDDE;
	%* Closes the file and the DDE connection.;

%mend exportToXL;


