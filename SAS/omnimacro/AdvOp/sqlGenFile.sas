%macro sqlGenFile(inroot=,flnm=,incomponent=);
/*Gets rid of the last backslash in each path, if one is included.;*/
	%if	("%substr(&inroot,%length(&inroot),1)"="\")
		or ("%substr(&inroot,%length(&inroot),1)"="/")
		%then %let inroot	=	%substr(&inroot,1,%eval(%length(&inroot)-1));
	%let	inroot	=	&inroot.\;
	data _NULL_;
		file	"&inroot.&flnm.";
		%sqlcomponent_&incomponent.

	run;
%mend;