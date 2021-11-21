%*100.	Find and run necessary SAS programs.;
%*Below macro is from "&macroot.\900Modules";
%IncludeProcBySeq(
	FdrProc		=	%nrbquote(
						&curroot.
					)
	,CodePfx	=	3
)
%*Please note that the "&CodePfx." should only contain the first digit of the file name.;
%*For more information please find in the macro definition.;