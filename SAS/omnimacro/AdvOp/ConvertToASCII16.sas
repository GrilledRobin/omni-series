%macro ConvertToASCII16(
	string	=
	,outSTR	=
);
%local
	ASCi
	loopvar
;
%let	outSTR	=;
%do	ASCi=1	%to	%length(%nrbquote(&string.));
	%let	loopvar	=	%qsubstr(%nrbquote(&string.),&ASCi.,1);
	%let	outSTR	=	&outSTR.%nrbquote(%)%qsysfunc(putc(&loopvar.,hex2.));
%end;
%*put &outSTR.;
%mend ConvertToASCII16;
%*ConvertToASCII16(string=mypassword);

%*let pw=%sysfunc(urldecode(%6D%79%70%61%73%73%77%6F%72%64));
%*put &pw;